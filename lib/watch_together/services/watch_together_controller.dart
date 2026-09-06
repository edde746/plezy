import 'dart:async';

import '../../mpv/mpv.dart';
import '../../utils/app_logger.dart';
import '../../utils/serial_future_queue.dart';
import '../models/playback_state.dart';
import '../models/sync_message.dart';
import '../models/watch_session.dart';
import '../primitives.dart';
import 'attached_player.dart';
import 'clock_sync.dart';
import 'guest_playback_reconciler.dart';
import 'host_playback_coordinator.dart';
import 'watch_together_peer_service.dart';

/// Authority captured when screen work starts, not after its asynchronous open.
/// Room-driven work survives a promotion; local selections require the same role.
class WatchPlaybackLease {
  WatchPlaybackLease._(this._owner, this._mediaGeneration, this._roleGeneration, this.canSelect);
  final WatchTogetherController _owner;
  int _mediaGeneration;
  final int? _roleGeneration;
  final bool canSelect;
  bool get isCurrent =>
      !_owner._disposed &&
      _mediaGeneration == _owner._mediaGeneration &&
      (_roleGeneration == null || _roleGeneration == _owner._roleGeneration);
  bool belongsTo(WatchTogetherController? controller) => identical(_owner, controller) && isCurrent;
  bool belongsToSession(WatchTogetherController? controller) => identical(_owner, controller) && !_owner._disposed;
}

/// Session-scoped playback-sync controller.
///
/// Lives for the whole Watch Together session (created at create/join, not
/// at player attach), so no sync message is ever dropped during episode
/// switches or other attach gaps — the player attachment is just an output
/// binding the role engine reconciles against.
///
/// Routes the v3 protocol between the relay and the role engine:
/// host → [HostPlaybackCoordinator] (single writer of [PlaybackState]),
/// guest → [GuestPlaybackReconciler] (+ [ClockSync] against the host).
class WatchTogetherController {
  WatchTogetherController({
    required WatchTogetherPeerService peerService,
    required WatchSession session,
    int Function()? nowMs,
  }) : _peerService = peerService,
       _session = session,
       _nowMs = nowMs ?? watchTogetherSystemNowMs {
    if (session.isHost) {
      _createCoordinator();
    } else {
      _createReconciler();
    }

    _subscriptions.add(peerService.onMessageReceived.listen(_enqueueMessage));
    _subscriptions.add(peerService.onPeerDisconnected.listen(_handlePeerDisconnected));
  }

  void _createCoordinator() {
    _coordinator = HostPlaybackCoordinator(
      myPeerId: _peerService.myPeerId ?? '',
      controlMode: _session.controlMode,
      sendState: _sendState,
      onPhaseChanged: (phase) => onPhaseChanged?.call(phase),
      onWaitingOnChanged: (peers) => onWaitingOnChanged?.call(peers),
      onResumedWithout: (peers) => onResumedWithout?.call(peers),
      onRemoteAction: (peer, hint) => onRemoteAction?.call(peer, hint),
      onMediaSwitchNeeded: (ratingKey, serverId, title) => onMediaStateReceived?.call(ratingKey, serverId, title),
      nowMs: _nowMs,
    );
    // Seed the roster before anything can attach a player: the first epoch
    // resolves readiness synchronously, so a coordinator that learns the room
    // afterwards has already decided the room is empty and started alone.
    for (final entry in _peerVersions.entries) {
      if (entry.key == _peerService.myPeerId) continue;
      _coordinator!.onPeerJoined(entry.key, compatible: entry.value == SyncMessage.protocolVersion);
    }
  }

  void _createReconciler() {
    _clockSync = ClockSync(sendPing: _sendClockPing, nowMs: _nowMs);
    _reconciler = GuestPlaybackReconciler(
      myPeerId: _peerService.myPeerId ?? '',
      sendToHost: _sendToHost,
      clockSync: _clockSync!,
      onMediaSwitchNeeded: (ratingKey, serverId, title) => onMediaStateReceived?.call(ratingKey, serverId, title),
      onControlModeChanged: (mode) => onControlModeReceived?.call(mode),
      onPhaseChanged: (phase) => onPhaseChanged?.call(phase),
      onWaitingOnChanged: (peers) => onWaitingOnChanged?.call(peers),
      onCorrectingChanged: (correcting) => onCorrectingChanged?.call(correcting),
      onRemoteAction: (peer, hint) => onRemoteAction?.call(peer, hint),
      nowMs: _nowMs,
    );
    _clockSync!.start();
  }

  final WatchTogetherPeerService _peerService;
  final int Function() _nowMs;
  WatchSession _session;

  HostPlaybackCoordinator? _coordinator;
  GuestPlaybackReconciler? _reconciler;
  ClockSync? _clockSync;

  AttachedPlayer? _attachedPlayer;
  AttachedPlayer? _retainedPlayer;
  Object? _bindingOwner;
  int _mediaGeneration = 0;
  int _roleGeneration = 0;
  String? _roomMediaKey;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final SerialFutureQueue _messageQueue = SerialFutureQueue();
  bool _disposed = false;

  /// Protocol versions learned from join messages (absent ⇒ v1).
  final Map<String, int> _peerVersions = {};

  final Set<String> _updateToastShown = {};

  // Provider-facing callbacks.
  void Function(PlaybackPhase phase)? onPhaseChanged;
  void Function(List<String> peerIds)? onWaitingOnChanged;
  void Function(bool correcting)? onCorrectingChanged;
  void Function(ControlMode mode)? onControlModeReceived;
  void Function(String ratingKey, String serverId, String? mediaTitle)? onMediaStateReceived;
  void Function()? onHostExitedPlayer;
  void Function(String peerId, PlaybackActionHint hint)? onRemoteAction;
  void Function(String peerId)? onPeerNeedsUpdate;
  void Function(List<String> peerIds)? onResumedWithout;

  bool get hasPlayer => _attachedPlayer != null;
  bool ownsBinding(Object binding) => identical(binding, _bindingOwner);
  Future<void> get pendingRateCommands => _retainedPlayer?.pendingRateCommands ?? Future<void>.value();

  WatchPlaybackLease capturePlaybackLease({bool selection = false}) =>
      WatchPlaybackLease._(this, _mediaGeneration, selection ? _roleGeneration : null, selection && _session.isHost);

  void _observeRoomMedia(String ratingKey, String serverId) {
    final key = PlaybackState.mediaKeyFor(ratingKey: ratingKey, serverId: serverId);
    if (_roomMediaKey == key) return;
    _roomMediaKey = key;
    _mediaGeneration++;
  }

  PlaybackPhase? get phase => _session.isHost ? _coordinator?.phase : _reconciler?.latestState?.phase;

  /// The room's current playback rate, or null before the room has one.
  double? get roomRate => _session.isHost ? _coordinator?.rate : _reconciler?.latestState?.rate;

  /// Whether the sync layer is temporarily driving the player's rate (a
  /// guest drift nudge). Player rate events are not user feedback while true.
  bool get syncOwnsRate => _reconciler?.nudging ?? false;

  /// Update the session (e.g. when the control mode changes).
  void updateSession(WatchSession session) {
    _session = session;
    _coordinator?.updateControlMode(session.controlMode);
  }

  /// The relay reassigned host authority: swap the role engine while keeping
  /// the session, message queue, peer knowledge, and player attachment.
  ///
  /// [session] already carries the new role and host peer ID.
  void applyHostChange(WatchSession session) {
    final wasHost = _session.isHost;
    _roleGeneration++;
    _session = session;

    if (wasHost == session.isHost) {
      if (!session.isHost) {
        // Still a guest, but the authority (and its clock) moved: discard
        // offsets and sequence numbering learned from the old host and
        // re-converge against the new one.
        _clockSync?.reset();
        _reconciler?.resetSequence();
        requestState();
      }
      return;
    }

    final attached = _attachedPlayer;
    if (session.isHost) {
      // Promotion: adopt the room where the old host left it, whether or not
      // a player is bound right now (a reload gap, the lobby, an episode
      // switch). The position is read on the old host's clock before that
      // clock is discarded — the reconciler's own player may be
      // mid-correction, and a stale local snapshot would become the room's
      // authoritative anchor. A player bound later for the same media rebinds
      // into the adopted epoch instead of opening a new one.
      final lastState = _reconciler?.latestState;
      final transitionAnchorMs = lastState?.targetPositionMs(_clockSync?.hostNowMs() ?? _nowMs());
      _clockSync?.stop();
      _clockSync = null;
      _reconciler?.dispose();
      _reconciler = null;
      _createCoordinator();
      if (lastState != null) _coordinator!.adoptRoom(lastState, anchorMs: transitionAnchorMs);
      if (attached != null && attached.ratingKey != null && attached.serverId != null) {
        _coordinator!.attach(
          attached,
          ratingKey: attached.ratingKey!,
          serverId: attached.serverId!,
          hasFirstFrame: attached.firstFrameSeen,
          startupHold: attached.startupHold,
        );
      }
    } else {
      // Demotion: hand the room to the new host and fall in line.
      _coordinator?.dispose();
      _coordinator = null;
      _createReconciler();
      if (attached != null && attached.ratingKey != null && attached.serverId != null) {
        _reconciler!.attach(
          attached,
          ratingKey: attached.ratingKey!,
          serverId: attached.serverId!,
          hasFirstFrame: attached.firstFrameSeen,
          startupHold: attached.startupHold,
        );
      }
      requestState();
    }
    appLogger.d('WatchTogether: Host change applied (host: ${session.isHost})');
  }

  // ---------------------------------------------------------------------
  // Player attachment
  // ---------------------------------------------------------------------

  /// Bind the successfully opened source. This never selects room media.
  Object bindPlayer(
    Player player, {
    required String ratingKey,
    required String serverId,
    String? mediaTitle,
    bool hasFirstFrame = false,
    Future<void>? startupHold,
    Future<void> Function(Duration target)? remoteSeek,
  }) {
    unbindPlayer();
    var attached = _retainedPlayer;
    if (attached == null || !attached.wraps(player) || !attached.usable) {
      if (attached != null) unawaited(attached.dispose());
      late final AttachedPlayer replacement;
      replacement = AttachedPlayer(
        player: player,
        onLost: () {
          if (identical(_attachedPlayer, replacement)) unbindPlayer();
        },
        nowMs: _nowMs,
      );
      attached = replacement;
      _retainedPlayer = attached;
    }
    attached.observeBinding(
      ratingKey: ratingKey,
      serverId: serverId,
      mediaTitle: mediaTitle,
      hasFirstFrame: hasFirstFrame,
      startupHold: startupHold,
      remoteSeek: remoteSeek,
    );
    _attachedPlayer = attached;
    final owner = Object();
    _bindingOwner = owner;
    if (_session.isHost) {
      _coordinator!.attach(
        attached,
        ratingKey: ratingKey,
        serverId: serverId,
        hasFirstFrame: hasFirstFrame,
        startupHold: startupHold,
      );
    } else {
      _reconciler!.attach(
        attached,
        ratingKey: ratingKey,
        serverId: serverId,
        hasFirstFrame: hasFirstFrame,
        startupHold: startupHold,
      );
    }
    return owner;
  }

  /// Revoke output observations, retaining its ledger and the room's epoch.
  void unbindPlayer({Object? expectedBinding}) {
    if (expectedBinding != null && !ownsBinding(expectedBinding)) return;
    final attached = _attachedPlayer;
    _coordinator?.detachPlayer();
    _reconciler?.detachPlayer();
    _attachedPlayer = null;
    attached?.unbind();
  }

  /// End even during an unbound reload gap. A replaced route cannot end its successor.
  bool endMedia({Object? expectedBinding}) {
    if (expectedBinding != null && !ownsBinding(expectedBinding)) return false;
    final hadMedia = _roomMediaKey != null;
    unbindPlayer();
    _bindingOwner = null;
    _mediaGeneration++;
    _roomMediaKey = null;
    _coordinator?.endMedia();
    _reconciler?.endEpoch();
    final retained = _retainedPlayer;
    _retainedPlayer = null;
    if (retained != null) unawaited(retained.dispose());
    return hadMedia;
  }

  /// Pause a guest's player without telling the room.
  ///
  /// For a pause the environment forces on this peer alone — a vehicle that starts requiring
  /// distraction optimization. Routing it through the attachment records the expectation, so the
  /// resulting event is consumed as an acknowledgement instead of being published as a user intent
  /// that would pause everybody.
  ///
  /// A host is refused, and must pause the room the ordinary way. It is the room's clock: swallowing
  /// its intent would leave the coordinator in a playing phase while its own player was frozen, and
  /// every heartbeat would then publish that frozen position as the room's anchor — stalling or
  /// rewinding the guests it was meant to protect. Returns false when there is nothing local to do.
  Future<bool> pauseLocallyForSystem() async {
    final attached = _attachedPlayer;
    if (attached == null || _session.isHost) return false;
    // Only a player that is actually playing will report the transition this acknowledgement is
    // for. Recording one for a paused player — or one sitting at end of file, where mpv leaves the
    // raw pause flag false but no further event is coming — would leave it in the ledger, where the
    // user's next real pause would consume it and never reach the room.
    if (!attached.playing || attached.completed) return attached.pauseWithoutAck();
    return attached.pause();
  }

  // ---------------------------------------------------------------------
  // Provider inputs
  // ---------------------------------------------------------------------

  /// Commit local selection only under its originating session/role lease.
  bool selectMedia({
    required String ratingKey,
    required String serverId,
    String? mediaTitle,
    required Duration position,
    required double rate,
    required WatchPlaybackLease lease,
  }) {
    if (!lease.belongsTo(this) || !lease.canSelect || !_session.isHost) return false;
    final previousGeneration = _mediaGeneration;
    _coordinator!.selectMedia(
      ratingKey: ratingKey,
      serverId: serverId,
      mediaTitle: mediaTitle,
      position: position,
      rate: rate,
    );
    if (_mediaGeneration == previousGeneration) _mediaGeneration++;
    lease._mediaGeneration = _mediaGeneration;
    return true;
  }

  /// User seek executed locally (screen hook).
  void onLocalSeek(Duration position) {
    if (_session.isHost) {
      _coordinator?.onLocalSeekIntent(position);
    } else {
      _reconciler?.onLocalSeekIntent(position);
    }
  }

  /// User rate change applied locally (screen hook). The only way a rate
  /// change reaches the room: the sync layer never infers rate intent from
  /// the player's rate stream.
  void onLocalRate(double rate) {
    if (_session.isHost) {
      _coordinator?.onLocalRateIntent(rate);
    } else {
      _reconciler?.onLocalRateIntent(rate);
    }
  }

  void setBackgrounded(bool value) {
    _coordinator?.setBackgrounded(value);
    _reconciler?.setBackgrounded(value);
  }

  void announceJoin(String displayName) {
    final peerId = _peerService.myPeerId;
    if (peerId == null) return;
    _peerService.broadcast(
      SyncMessage.join(
        peerId: peerId,
        displayName: displayName,
        isHost: _session.isHost,
        controlMode: _session.isHost ? _session.controlMode : null,
      ),
    );
  }

  void announceLeave() {
    final peerId = _peerService.myPeerId;
    if (peerId == null) return;
    _peerService.broadcast(SyncMessage.leave(peerId: peerId));
  }

  /// Ask the host to (re-)send its current state.
  void requestState() {
    if (_session.isHost) return;
    final request = SyncMessage.requestState(peerId: _peerService.myPeerId);
    final hostPeerId = _session.hostPeerId;
    if (hostPeerId != null) {
      _peerService.sendTo(hostPeerId, request);
    } else {
      _peerService.broadcast(request);
    }
  }

  /// Relay reconnect completed: re-establish mutual state.
  void onReconnected() {
    if (_session.isHost) {
      _coordinator?.onReconnected();
    } else {
      _reconciler?.onReconnected();
      requestState();
    }
  }

  void dispose() {
    _disposed = true;
    endMedia();
    for (final subscription in _subscriptions) {
      unawaited(
        subscription.cancel().catchError((Object error, StackTrace stackTrace) {
          appLogger.e('WatchTogether: Failed to cancel controller subscription', error: error, stackTrace: stackTrace);
        }),
      );
    }
    _subscriptions.clear();
    _clockSync?.stop();
    _coordinator?.dispose();
    _reconciler?.dispose();
  }

  // ---------------------------------------------------------------------
  // Transport plumbing
  // ---------------------------------------------------------------------

  void _sendState(PlaybackState state, {String? toPeerId}) {
    if (_disposed) return;
    _observeRoomMedia(state.ratingKey, state.serverId);
    final message = SyncMessage.state(state, peerId: _peerService.myPeerId);
    if (toPeerId != null) {
      _peerService.sendTo(toPeerId, message);
    } else {
      _peerService.broadcast(message);
    }
  }

  void _sendToHost(SyncMessage message) {
    if (_disposed) return;
    final hostPeerId = _session.hostPeerId;
    if (hostPeerId != null) {
      _peerService.sendTo(hostPeerId, message);
    } else {
      _peerService.broadcast(message);
    }
  }

  void _sendClockPing(int pingId) {
    _sendToHost(SyncMessage.ping(pingId, peerId: _peerService.myPeerId));
  }

  void _enqueueMessage(SyncMessage message) {
    unawaited(
      _messageQueue.run(() => _handleMessage(message)).catchError((Object error, StackTrace stackTrace) {
        appLogger.e(
          'WatchTogether: Failed to handle ${message.type.name} message',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  Future<void> _handleMessage(SyncMessage message) async {
    if (_disposed) return;
    final senderId = message.peerId;
    if (senderId == null || senderId == _peerService.myPeerId) return;

    switch (message.type) {
      case SyncMessageType.state:
        // Only the host may author room state.
        if (_session.isHost || senderId != _session.hostPeerId) return;
        final state = message.state;
        if (state != null && state.seq > (_reconciler?.latestState?.seq ?? -1)) {
          _observeRoomMedia(state.ratingKey, state.serverId);
          _reconciler?.onState(state);
        }
        break;

      case SyncMessageType.status:
        final status = message.status;
        if (_session.isHost && status != null) {
          _coordinator?.onPeerStatus(senderId, status);
        }
        break;

      case SyncMessageType.control:
        if (!_session.isHost) return;
        // In host-only mode nobody else gets a say.
        if (_session.controlMode == ControlMode.hostOnly) return;
        if (_isIncompatible(senderId)) return;
        final control = message.control;
        if (control != null) _coordinator?.onControlRequest(senderId, control);
        break;

      case SyncMessageType.requestState:
        if (_session.isHost) _coordinator?.onStateRequested(senderId);
        break;

      case SyncMessageType.ping:
        if (message.pingId != null) {
          // The pong timestamp is "host clock now" for the guest's offset
          // math — it must come from the same clock as the state anchors.
          _peerService.sendTo(
            senderId,
            SyncMessage(
              type: SyncMessageType.pong,
              timestamp: _nowMs(),
              pingId: message.pingId,
              peerId: _peerService.myPeerId,
            ),
          );
        }
        break;

      case SyncMessageType.pong:
        if (!_session.isHost && senderId == _session.hostPeerId && message.pingId != null) {
          _clockSync?.onPong(message.pingId!, message.timestamp);
        }
        break;

      case SyncMessageType.join:
        _handleJoin(senderId, message);
        break;

      case SyncMessageType.leave:
        _forgetPeer(senderId);
        _coordinator?.onPeerLeft(senderId);
        break;

      case SyncMessageType.hostExitedPlayer:
        // Rides the ordered queue so it can't locally overtake state
        // messages that preceded it on the wire. Only the host may end the
        // media epoch.
        if (!_session.isHost && senderId == _session.hostPeerId) {
          _mediaGeneration++;
          _roomMediaKey = null;
          _reconciler?.endEpoch();
          onHostExitedPlayer?.call();
        }
        break;
    }
  }

  bool _isIncompatible(String peerId) => (_peerVersions[peerId] ?? 1) != SyncMessage.protocolVersion;

  void _handleJoin(String senderId, SyncMessage message) {
    final version = message.version ?? 1;
    final firstSighting = !_peerVersions.containsKey(senderId);
    _peerVersions[senderId] = version;
    final compatible = version == SyncMessage.protocolVersion;

    if (!compatible && _updateToastShown.add(senderId)) {
      appLogger.w('WatchTogether: Peer $senderId speaks protocol v$version (ours: ${SyncMessage.protocolVersion})');
      onPeerNeedsUpdate?.call(senderId);
    }

    if (_session.isHost) {
      _coordinator?.onPeerJoined(senderId, compatible: compatible);
      return;
    }

    if (senderId != _session.hostPeerId) return;
    // The host's join carries the room's control mode — the lobby-safe
    // carrier, since PlaybackState only flows once a media epoch exists.
    // Authenticated by the relay-derived host peer ID, not the join's own
    // spoofable isHost flag.
    final controlMode = message.controlMode;
    if (controlMode != null) onControlModeReceived?.call(controlMode);
    if (firstSighting) {
      // A fresh host join can mean a restarted host app with a reset
      // sequence counter — accept its numbering from scratch.
      _reconciler?.resetSequence();
    }
  }

  void _handlePeerDisconnected(String peerId) {
    _forgetPeer(peerId);
    _updateToastShown.remove(peerId);
    _coordinator?.onPeerLeft(peerId);
  }

  void _forgetPeer(String peerId) {
    _peerVersions.remove(peerId);
  }
}
