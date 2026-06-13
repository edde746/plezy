import 'dart:async';

import '../../mpv/mpv.dart';
import '../../utils/app_logger.dart';
import '../models/playback_state.dart';
import '../models/sync_message.dart';
import '../models/watch_session.dart';
import 'attached_player.dart';
import 'clock_sync.dart';
import 'guest_playback_reconciler.dart';
import 'host_playback_coordinator.dart';
import 'watch_together_peer_service.dart';

/// Session-scoped playback-sync controller.
///
/// Lives for the whole Watch Together session (created at create/join, not
/// at player attach), so no sync message is ever dropped during episode
/// switches or other attach gaps — the player attachment is just an output
/// binding the role engine reconciles against.
///
/// Routes the v2 protocol between the relay and the role engine:
/// host → [HostPlaybackCoordinator] (single writer of [PlaybackState]),
/// guest → [GuestPlaybackReconciler] (+ [ClockSync] against the host).
class WatchTogetherController {
  WatchTogetherController({
    required WatchTogetherPeerService peerService,
    required WatchSession session,
    int Function()? nowMs,
  }) : _peerService = peerService,
       _session = session,
       _nowMs = nowMs ?? _systemNowMs {
    if (session.isHost) {
      _coordinator = HostPlaybackCoordinator(
        myPeerId: peerService.myPeerId ?? '',
        controlMode: session.controlMode,
        sendState: _sendState,
        callbacks: HostCoordinatorCallbacks(
          onPhaseChanged: (phase) => onPhaseChanged?.call(phase),
          onWaitingOnChanged: (peers) => onWaitingOnChanged?.call(peers),
          onResumedWithout: (peers) => onResumedWithout?.call(peers),
          onRemoteAction: (peer, hint) => onRemoteAction?.call(peer, hint),
        ),
        nowMs: _nowMs,
      );
    } else {
      _clockSync = ClockSync(sendPing: _sendClockPing, nowMs: _nowMs);
      _reconciler = GuestPlaybackReconciler(
        myPeerId: peerService.myPeerId ?? '',
        sendToHost: _sendToHost,
        clockSync: _clockSync!,
        callbacks: GuestReconcilerCallbacks(
          onMediaSwitchNeeded: (ratingKey, serverId, title) => onMediaStateReceived?.call(ratingKey, serverId, title),
          onControlModeChanged: (mode) => onControlModeReceived?.call(mode),
          onPhaseChanged: (phase) => onPhaseChanged?.call(phase),
          onWaitingOnChanged: (peers) => onWaitingOnChanged?.call(peers),
          onCorrectingChanged: (correcting) => onCorrectingChanged?.call(correcting),
          onRemoteAction: (peer, hint) => onRemoteAction?.call(peer, hint),
        ),
        nowMs: _nowMs,
      );
      _clockSync!.start();
    }

    _subscriptions.add(peerService.onMessageReceived.listen(_enqueueMessage));
    _subscriptions.add(peerService.onPeerDisconnected.listen(_handlePeerDisconnected));
  }

  static int _systemNowMs() => DateTime.now().millisecondsSinceEpoch;

  final WatchTogetherPeerService _peerService;
  final int Function() _nowMs;
  WatchSession _session;

  HostPlaybackCoordinator? _coordinator;
  GuestPlaybackReconciler? _reconciler;
  ClockSync? _clockSync;

  AttachedPlayer? _attachedPlayer;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Future<void> _messageQueue = Future.value();
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
  void Function(String peerId, PlaybackActionHint hint)? onRemoteAction;
  void Function(String peerId)? onPeerNeedsUpdate;
  void Function(List<String> peerIds)? onResumedWithout;

  bool get hasPlayer => _attachedPlayer != null;

  PlaybackPhase? get phase => _session.isHost ? _coordinator?.phase : _reconciler?.latestState?.phase;

  /// Update the session (e.g. when the control mode changes).
  void updateSession(WatchSession session) {
    _session = session;
    _coordinator?.updateControlMode(session.controlMode);
  }

  // ---------------------------------------------------------------------
  // Player attachment
  // ---------------------------------------------------------------------

  /// Attach the local player for [ratingKey]/[serverId].
  ///
  /// [hasFirstFrame] is the screen's first-frame snapshot; [startupHold]
  /// delays readiness until platform startup gates (frame-rate switch)
  /// release; [remoteSeek] routes sync seeks through the screen's seek path
  /// (Plex transcode restarts).
  void attachPlayer(
    Player player, {
    required String ratingKey,
    required String serverId,
    String? mediaTitle,
    bool hasFirstFrame = false,
    Future<void>? startupHold,
    Future<void> Function(Duration target)? remoteSeek,
  }) {
    detachPlayer();

    final attached = AttachedPlayer(
      player: player,
      onLost: () {
        appLogger.w('WatchTogether: Player attachment lost, detaching from sync');
        detachPlayer();
      },
      remoteSeek: remoteSeek,
      nowMs: _nowMs,
    );
    _attachedPlayer = attached;

    if (_session.isHost) {
      _coordinator!.attach(
        attached,
        ratingKey: ratingKey,
        serverId: serverId,
        mediaTitle: mediaTitle,
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
    appLogger.d('WatchTogether: Player attached (host: ${_session.isHost})');
  }

  /// Detach the player. [exiting] means the user left the video player (the
  /// epoch ends); an episode switch keeps the session and epoch flow.
  void detachPlayer({bool exiting = false}) {
    final attached = _attachedPlayer;
    if (attached == null) return;
    _attachedPlayer = null;
    _coordinator?.detachPlayer(exiting: exiting);
    _reconciler?.detachPlayer();
    unawaited(attached.dispose());
    appLogger.d('WatchTogether: Player detached (exiting: $exiting)');
  }

  // ---------------------------------------------------------------------
  // Provider inputs
  // ---------------------------------------------------------------------

  /// Host switched media (also called right after attach with the same key,
  /// which is a no-op).
  void setCurrentMedia({required String ratingKey, required String serverId, String? mediaTitle}) {
    _coordinator?.setLocalMedia(ratingKey: ratingKey, serverId: serverId, mediaTitle: mediaTitle);
  }

  /// User seek executed locally (screen hook).
  void onLocalSeek(Duration position) {
    if (_session.isHost) {
      _coordinator?.onLocalSeekIntent(position);
    } else {
      _reconciler?.onLocalSeekIntent(position);
    }
  }

  void setBackgrounded(bool value) {
    _coordinator?.setBackgrounded(value);
    _reconciler?.setBackgrounded(value);
  }

  void announceJoin(String displayName) {
    final peerId = _peerService.myPeerId;
    if (peerId == null) return;
    _peerService.broadcast(SyncMessage.join(peerId: peerId, displayName: displayName, isHost: _session.isHost));
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
    detachPlayer(exiting: true);
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
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
    final message = SyncMessage.state(state, peerId: _peerService.myPeerId);
    if (toPeerId != null) {
      _peerService.sendTo(toPeerId, message);
    } else {
      _peerService.broadcast(message);
    }
  }

  void _sendToHost(SyncMessage message) {
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
    _messageQueue = _messageQueue.then((_) => _handleMessage(message)).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      appLogger.e('WatchTogether: Failed to handle ${message.type.name} message', error: error, stackTrace: stackTrace);
    });
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
        if (state != null) _reconciler?.onState(state);
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
        if (message.pingId != null && !_session.isHost) {
          _clockSync?.onPong(message.pingId!, message.timestamp);
        }
        break;

      case SyncMessageType.join:
        _handleJoin(senderId, message);
        break;

      case SyncMessageType.leave:
        _peerVersions.remove(senderId);
        _coordinator?.onPeerLeft(senderId);
        break;

      case SyncMessageType.hostExitedPlayer:
        // Handled at the provider level.
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
    } else if (senderId == _session.hostPeerId && firstSighting) {
      // A fresh host join can mean a restarted host app with a reset
      // sequence counter — accept its numbering from scratch.
      _reconciler?.resetSequence();
    }
  }

  void _handlePeerDisconnected(String peerId) {
    _peerVersions.remove(peerId);
    _updateToastShown.remove(peerId);
    _coordinator?.onPeerLeft(peerId);
  }
}
