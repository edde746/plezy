import 'dart:async';
import 'dart:math';

import '../../media/playback_rate.dart';
import '../../utils/app_logger.dart';
import '../models/playback_state.dart';
import '../models/watch_session.dart';
import '../primitives.dart';
import 'attached_player.dart';

/// Host-side policy engine: owns the authoritative [PlaybackState].
///
/// Inputs are local player signals (via [AttachedPlayer]'s intent-classified
/// streams), peer status reports, control requests, and roster changes; the
/// output is a state broadcast through [sendState] plus commands to the
/// host's own player (the host delays its own start to the scheduled moment
/// just like every guest).
///
/// Pure Dart and clock-injected so the full scenario matrix runs under
/// `fakeAsync`.
class HostPlaybackCoordinator {
  HostPlaybackCoordinator({
    required this.myPeerId,
    required this._controlMode,
    required this._sendState,
    this.onPhaseChanged,
    this.onWaitingOnChanged,
    this.onResumedWithout,
    this.onRemoteAction,
    this.onMediaSwitchNeeded,
    int Function()? nowMs,
  }) : _nowMs = nowMs ?? watchTogetherSystemNowMs;

  /// Phase transitions (drives the waiting pill and chrome).
  final void Function(PlaybackPhase phase)? onPhaseChanged;

  /// The set of peers the room is waiting on changed.
  final void Function(List<String> peerIds)? onWaitingOnChanged;

  /// The safety timeout excused these peers and the room resumed.
  final void Function(List<String> peerIds)? onResumedWithout;

  /// A guest's control request was applied (drives action toasts).
  final void Function(String peerId, PlaybackActionHint hint)? onRemoteAction;
  final void Function(String ratingKey, String serverId, String? title)? onMediaSwitchNeeded;

  // Tuning constants.
  static const int stallGraceMs = 500;
  static const int recoveryHysteresisMs = 400;
  static const int safetyTimeoutMs = 15000;
  static const int heartbeatPlayingMs = 2000;
  static const int heartbeatIdleMs = 5000;
  static const int startDelayMinMs = 750;
  static const int startDelayMaxMs = 2000;
  static const int defaultPeerRttMs = 500;
  static const int seekDebounceMs = 200;
  static const int implicitJumpThresholdMs = 1500;
  static const int selfRecoveryMinBufferAheadMs = 2000;

  /// How close the promoted host's player must sit to the room position it
  /// inherited before that player's own position becomes the room's. Matches
  /// the guest's paused alignment threshold so the handover asks no more of
  /// the new host than the room asked of it as a guest.
  static const int transitionAlignToleranceMs = 500;

  /// Longest the promoted host holds the inherited position waiting for its
  /// alignment seek to render. A backend that never reports the seek would
  /// otherwise pin the room on an anchor its host is not at.
  static const int transitionAlignTimeoutMs = 5000;

  /// After a self stall, the room resumes only once the host has buffered
  /// this many times the stall's length (bounded by
  /// [selfRecoveryMaxHeadroomMs], and by the media left to buffer). Resuming
  /// with a fixed second of data on a link that just starved for four is a
  /// guaranteed second stall, and every stall is a pause plus a group restart
  /// for every guest.
  static const int selfRecoveryHeadroomFactor = 3;
  static const int selfRecoveryMaxHeadroomMs = 15000;

  /// Longest the room waits for that headroom, measured from the stall's
  /// end. The cache is an external quantity — a link that cannot refill in
  /// this long will stall again whatever we do, and a room held paused with
  /// no feedback is the worse failure. Also the bound when the backend
  /// reports no cache position at all.
  static const int selfRecoveryMaxWaitMs = 15000;

  /// Slack for a cache that ends a few frames shy of the reported duration
  /// once everything left has been demuxed.
  static const int selfRecoveryEofSlackMs = 1000;

  /// mpv's own `cache-pause-wait` while hosting: how much it refills before
  /// leaving `paused-for-cache` (default 1 s). Raised so a starved host does
  /// not flap in and out of buffering on its own timetable.
  static const Duration hostCachePauseWait = Duration(seconds: 4);
  static const double _minimumRemoteRate = minimumPlaybackRate;
  static const double _maximumRemoteRate = maximumPlaybackRate;

  final String myPeerId;
  final void Function(PlaybackState state, {String? toPeerId}) _sendState;
  final int Function() _nowMs;

  ControlMode _controlMode;

  // Media epoch.
  String? _ratingKey;
  String? _serverId;
  String? _mediaTitle;
  bool get hasActiveEpoch => _ratingKey != null && _serverId != null;
  String? get _mediaKey =>
      hasActiveEpoch ? PlaybackState.mediaKeyFor(ratingKey: _ratingKey!, serverId: _serverId!) : null;

  // Player attachment.
  AttachedPlayer? _player;
  String? _boundMediaKey;
  bool get _matchingPlayer => _player != null && _boundMediaKey == _mediaKey;
  final List<StreamSubscription<dynamic>> _playerSubscriptions = [];
  bool _localReady = false;
  bool _startupHoldResolved = true;
  bool _localStalled = false;
  bool _recoveringFromSelfStall = false;
  int? _selfStallStartedMs;
  int _selfStallEndedMs = 0;
  int _lastSelfStallMs = 0;

  // Room state.
  PlaybackPhase _phase = PlaybackPhase.loading;
  int _timelinePositionMs = 0;
  double _rate = 1.0;
  bool _firstStartCompleted = false;
  int _seq = 0;
  PlaybackState? _lastBroadcast;
  bool _backgrounded = false;

  // Host-transfer handover: the room position inherited from the previous
  // host, held until the promoted player has aligned to it (see [adoptRoom]).
  int? _transitionAnchorMs;
  bool _transitionAlignSeekInFlight = false;
  Timer? _transitionAlignTimer;

  /// Generation of this engine's authority over its player and epoch.
  /// Bumped whenever what an in-flight command was issued against no longer
  /// holds — attach, detach, epoch change, room adoption, disposal. Every
  /// async continuation captures it before its await and bails when stale:
  /// the one fence for commands outliving the binding they were issued on.
  int _authority = 0;
  int _bindingGeneration = 0;
  int _timelineOperation = 0;
  int _playOperation = 0;
  int _rateOperation = 0;

  // Peer tracking.
  final Set<String> _knownPeers = {};
  final Set<String> _incompatiblePeers = {};
  final Set<String> _excused = {};
  final Set<String> _stalledPeers = {};
  final Map<String, PeerStatus> _peerStatuses = {};
  final Map<String, Timer> _peerStallGraceTimers = {};

  // Pending actions.
  Timer? _selfStallGraceTimer;
  Timer? _allReadyCheckTimer;
  Timer? _safetyTimer;
  int? _safetyDeadlineMs;
  Timer? _heartbeatTimer;
  Timer? _pendingStartTimer;
  int? _pendingStartAtMs;
  int? _pendingStartPositionMs;
  Timer? _seekDebounceTimer;
  int? _pendingSeekTargetMs;
  String? _pendingActor;
  bool _disposed = false;

  PlaybackPhase get phase => _phase;

  /// The room's current playback rate (what the last broadcast carried).
  double get rate => _rate;

  // ---------------------------------------------------------------------
  // Public inputs
  // ---------------------------------------------------------------------

  /// Commit a successful local open. Binding an output never selects media.
  void selectMedia({
    required String ratingKey,
    required String serverId,
    String? mediaTitle,
    required Duration position,
    required double rate,
  }) {
    _ratingKey = ratingKey;
    _serverId = serverId;
    _mediaTitle = mediaTitle;
    _authority++;
    _timelineOperation++;
    _playOperation++;
    _rateOperation++;
    _clearTransitionAnchor();
    _timelinePositionMs = position.inMilliseconds;
    _transitionAnchorMs = _timelinePositionMs;
    _rate = rate;
    _seekDebounceTimer?.cancel();
    _pendingSeekTargetMs = null;
    _pendingActor = null;
    _allReadyCheckTimer?.cancel();
    _lastBroadcast = null;
    _localReady = false;
    _localStalled = false;
    _recoveringFromSelfStall = false;
    _firstStartCompleted = false;
    _excused.clear();
    _stalledPeers.clear();
    _cancelPendingStart();
    _cancelSafety();
    _cancelStallTimers();
    _setPhase(PlaybackPhase.loading);
    _broadcast(hint: PlaybackActionHint.mediaSwitch, actor: myPeerId);
    appLogger.d('WatchTogether: Host epoch -> $_mediaKey');
  }

  /// Take over a room where the previous host left it: epoch identity, rate,
  /// intent, phase, and the room's position at this moment ([anchorMs], on
  /// the old host's clock). Independent of a player binding — a peer promoted
  /// while detached still becomes the room's authority and answers for it —
  /// and broadcast at once so every guest learns the new author. A later
  /// [attach] supplies an output only; stale media never replaces the room.
  ///
  /// The inherited position is held until the promoted player has rendered,
  /// passed its startup hold, and aligned to it through the normal seek path
  /// (readiness and alignment are different states: the player may sit mid
  /// correction or at a stale pre-seek spot). Until then every broadcast
  /// carries the anchor and this host gates the room; only then does its
  /// local position become the room's. Loading retains its selected start
  /// target too, so a pause before readiness has a meaningful wire anchor.
  void adoptRoom(PlaybackState state, {int? anchorMs}) {
    _authority++;
    _timelineOperation++;
    _playOperation++;
    _rateOperation++;
    _cancelPendingStart();
    _cancelSafety();
    _cancelStallTimers();
    _allReadyCheckTimer?.cancel();
    _seekDebounceTimer?.cancel();
    _pendingSeekTargetMs = null;
    _pendingActor = null;
    _excused.clear();
    _stalledPeers.clear();
    _ratingKey = state.ratingKey;
    _serverId = state.serverId;
    _mediaTitle = state.mediaTitle;
    // The room's rate, not this player's: it may be mid-nudge.
    _rate = state.rate;
    _timelinePositionMs = anchorMs ?? state.anchorPositionMs;
    // Whether the room has started once decides who gates the next start:
    // a room caught playing has, and its remaining peers are mid-session
    // followers; a room stopped anywhere else re-gates on everyone it knows.
    _firstStartCompleted = state.phase == PlaybackPhase.playing;
    _clearTransitionAnchor();
    _transitionAnchorMs = _timelinePositionMs;
    _setPhase(switch (state.phase) {
      PlaybackPhase.paused => PlaybackPhase.paused,
      PlaybackPhase.loading => PlaybackPhase.loading,
      PlaybackPhase.waitingForPeers || PlaybackPhase.playing => PlaybackPhase.waitingForPeers,
    });
    if (_player?.playing ?? false) unawaited(_player!.pause());
    if (_matchingPlayer && (_player!.rate - _rate).abs() > 0.001) unawaited(_player!.setRate(_rate));
    _broadcast();
    if (_matchingPlayer) _maybeLocalLoaded();
    _requestMatchingMedia();
    appLogger.d('WatchTogether: Adopted room $_mediaKey (${state.phase.name}, rate $_rate, anchor ${anchorMs}ms)');
  }

  /// Bind an output without changing selected media, rate, or timeline.
  /// Same-media source reloads retain alignment obligations and wait deadlines.
  void attach(
    AttachedPlayer player, {
    required String ratingKey,
    required String serverId,
    bool hasFirstFrame = false,
    Future<void>? startupHold,
  }) {
    detachPlayer();
    _boundMediaKey = PlaybackState.mediaKeyFor(ratingKey: ratingKey, serverId: serverId);
    _player = player;
    if (_matchingPlayer && (player.rate - _rate).abs() > 0.001) {
      unawaited(player.setRate(_rate));
    }
    final bindingGeneration = _bindingGeneration;
    _startupHoldResolved = startupHold == null;
    if (startupHold != null) {
      startupHold.then((_) {
        if (bindingGeneration != _bindingGeneration || _disposed) return;
        _startupHoldResolved = true;
        _maybeLocalLoaded();
      });
    }
    _playerSubscriptions.add(player.loadedSignals.listen((_) => _onLoadedSignal()));
    _playerSubscriptions.add(player.bufferingChanges.listen(_onSelfBuffering));
    _playerSubscriptions.add(player.playingIntents.listen(_onLocalPlayingIntent));
    _playerSubscriptions.add(player.playingAcks.listen(_onAcknowledgedPlaying));
    unawaited(player.setCachePauseWait(hostCachePauseWait));
    if (hasFirstFrame) {
      player.firstFrameSeen = true;
      _localReady = true;
      _maybeLocalLoaded();
    }
    if (!_matchingPlayer) _requestMatchingMedia();
    if (_phase != PlaybackPhase.playing && player.playing) unawaited(player.pause());
    if (_phase == PlaybackPhase.waitingForPeers) _checkAllReady();
    _restartHeartbeat();
  }

  /// Unbind an output. The selected timeline and alignment target outlive it.
  void detachPlayer() {
    _authority++;
    _bindingGeneration++;
    if (_matchingPlayer && _transitionAnchorMs == null) {
      _timelinePositionMs = _pendingStartPositionMs ?? _player!.position.inMilliseconds;
      _transitionAnchorMs = _timelinePositionMs;
    }
    for (final subscription in _playerSubscriptions) {
      unawaited(subscription.cancel());
    }
    _playerSubscriptions.clear();
    _player = null;
    _boundMediaKey = null;
    _localReady = false;
    _localStalled = false;
    _recoveringFromSelfStall = false;
    _selfStallStartedMs = null;
    _lastSelfStallMs = 0;
    _startupHoldResolved = true;
    _cancelAlignmentAttempt();
    _cancelPendingStart();
    _cancelStallTimers();
    if (hasActiveEpoch && _phase == PlaybackPhase.playing) {
      _setPhase(PlaybackPhase.waitingForPeers);
      _broadcast();
    }
    _restartHeartbeat();
  }

  void endMedia() {
    detachPlayer();
    _timelineOperation++;
    _playOperation++;
    _rateOperation++;
    _ratingKey = null;
    _serverId = null;
    _mediaTitle = null;
    _timelinePositionMs = 0;
    _lastBroadcast = null;
    _clearTransitionAnchor();
    _cancelSafety();
    _allReadyCheckTimer?.cancel();
    _seekDebounceTimer?.cancel();
    _pendingSeekTargetMs = null;
    _pendingActor = null;
    _heartbeatTimer?.cancel();
    _setPhase(PlaybackPhase.loading);
  }

  void _requestMatchingMedia() {
    if (hasActiveEpoch && !_matchingPlayer) {
      onMediaSwitchNeeded?.call(_ratingKey!, _serverId!, _mediaTitle);
    }
  }

  void setBackgrounded(bool value) {
    if (_backgrounded == value) return;
    _backgrounded = value;
    if (!value && hasActiveEpoch && _player != null) {
      _onHeartbeat();
    }
  }

  void updateControlMode(ControlMode mode) {
    if (_controlMode == mode) return;
    _controlMode = mode;
    if (hasActiveEpoch) _broadcast();
  }

  void onPeerJoined(String peerId, {required bool compatible}) {
    if (peerId == myPeerId) return;
    if (!compatible) {
      _incompatiblePeers.add(peerId);
      _knownPeers.remove(peerId);
      return;
    }
    _incompatiblePeers.remove(peerId);
    _knownPeers.add(peerId);
    if (hasActiveEpoch) {
      _broadcast(toPeerId: peerId);
      if (_phase == PlaybackPhase.waitingForPeers) _checkAllReady();
    }
  }

  void onPeerLeft(String peerId) {
    _knownPeers.remove(peerId);
    _incompatiblePeers.remove(peerId);
    _excused.remove(peerId);
    _stalledPeers.remove(peerId);
    _peerStatuses.remove(peerId);
    _peerStallGraceTimers.remove(peerId)?.cancel();
    _scheduleAllReadyCheck(0);
  }

  void onPeerStatus(String peerId, PeerStatus status) {
    if (peerId == myPeerId || _incompatiblePeers.contains(peerId)) return;
    _knownPeers.add(peerId);
    final previous = _peerStatuses[peerId];
    _peerStatuses[peerId] = status;

    final onCurrentEpoch = status.mediaKey == _mediaKey;

    // A previously-excused peer that is healthy again rejoins the gate set.
    if (onCurrentEpoch && status.ready && !status.buffering) {
      _excused.remove(peerId);
    }

    if (!onCurrentEpoch) {
      _peerStallGraceTimers.remove(peerId)?.cancel();
      _stalledPeers.remove(peerId);
      _scheduleAllReadyCheck(0);
      return;
    }

    // Stall detection: a ready peer that reports buffering while the room
    // plays gets a short grace window before pausing everyone.
    if (status.ready && status.buffering) {
      if (_phase == PlaybackPhase.playing && !_stalledPeers.contains(peerId)) {
        _peerStallGraceTimers[peerId] ??= Timer(const Duration(milliseconds: stallGraceMs), () {
          _peerStallGraceTimers.remove(peerId);
          final latest = _peerStatuses[peerId];
          if (latest == null || !latest.buffering || latest.mediaKey != _mediaKey) return;
          if (_phase != PlaybackPhase.playing) return;
          _stalledPeers.add(peerId);
          _enterWaiting();
        });
      } else if (_phase == PlaybackPhase.waitingForPeers && !_stalledPeers.contains(peerId)) {
        // Already waiting on someone else — fold this stall in immediately.
        _stalledPeers.add(peerId);
        _scheduleAllReadyCheck(0);
      }
    } else {
      _peerStallGraceTimers.remove(peerId)?.cancel();
      final wasStalled = _stalledPeers.remove(peerId);
      final becameReady = status.ready && (previous == null || !previous.ready || previous.mediaKey != _mediaKey);
      if (wasStalled) {
        _scheduleAllReadyCheck(recoveryHysteresisMs);
      } else if (becameReady) {
        _scheduleAllReadyCheck(0);
      }
    }
  }

  void onControlRequest(String peerId, ControlRequest request) {
    if (!hasActiveEpoch) return;
    appLogger.d(
      'WatchTogether: Control ${request.kind.name} from $peerId (${request.positionMs ?? request.rate ?? ''})',
    );
    switch (request.kind) {
      case ControlRequestKind.play:
        _requestPlay(actor: peerId);
        break;
      case ControlRequestKind.pause:
        _requestPause(actor: peerId);
        break;
      case ControlRequestKind.seek:
        if (request.positionMs != null) {
          _applyRemoteSeek(request.positionMs!, actor: peerId);
        }
        break;
      case ControlRequestKind.rate:
        if (request.rate != null) {
          _applyRemoteRate(request.rate!, actor: peerId);
        }
        break;
    }
  }

  /// Accepted user intent precedes the native seek, which may reload the binding.
  void onLocalSeekIntent(Duration position) {
    if (!hasActiveEpoch || !_matchingPlayer) return;
    _setSeekTarget(position.inMilliseconds);
    final operation = _timelineOperation;
    _seekDebounceTimer?.cancel();
    _seekDebounceTimer = Timer(const Duration(milliseconds: seekDebounceMs), () {
      if (operation != _timelineOperation || _disposed || !hasActiveEpoch) return;
      _afterHostSeek(position.inMilliseconds, actor: myPeerId);
    });
  }

  void onStateRequested(String peerId) {
    if (!hasActiveEpoch) return;
    _broadcast(toPeerId: peerId);
  }

  void onReconnected() {
    if (hasActiveEpoch) _broadcast();
  }

  void dispose() {
    // Revoke first: continuations still in flight must find the authority
    // gone before anything below tears down what they would touch.
    _authority++;
    _disposed = true;
    endMedia();
    _allReadyCheckTimer?.cancel();
    _seekDebounceTimer?.cancel();
    _peerStatuses.clear();
    _knownPeers.clear();
  }

  // ---------------------------------------------------------------------
  // Local player signals
  // ---------------------------------------------------------------------

  void _onLoadedSignal() {
    if (!_matchingPlayer) return;
    if (_transitionAlignSeekInFlight &&
        (_player!.position.inMilliseconds - _transitionAnchorMs!).abs() <= transitionAlignToleranceMs) {
      _finishTransitionAlignment(reason: 'seek rendered at target');
      return;
    }
    if (_localReady) return;
    _localReady = true;
    _maybeLocalLoaded();
  }

  void _maybeLocalLoaded() {
    if (!_matchingPlayer || !_localReady || !_startupHoldResolved || !hasActiveEpoch) return;
    final player = _player!;
    if (_phase != PlaybackPhase.playing && player.playing) unawaited(player.pause());
    _alignToTransitionAnchor(player);
    if (_phase == PlaybackPhase.loading) {
      _setPhase(PlaybackPhase.waitingForPeers);
      _broadcast();
    }
    _scheduleAllReadyCheck(0);
  }

  /// Bring a promoted host's player to the position the room was at when it
  /// took over, through the normal seek path. Until this resolves the room
  /// broadcasts the inherited anchor and this host gates the start.
  void _alignToTransitionAnchor(AttachedPlayer player) {
    final anchorMs = _transitionAnchorMs;
    if (anchorMs == null || _transitionAlignSeekInFlight) return;
    if (!player.seekable) {
      // Live: there is no timeline to align; play/pause is all the room has.
      _finishTransitionAlignment(reason: 'not seekable');
      return;
    }
    if ((player.position.inMilliseconds - anchorMs).abs() <= transitionAlignToleranceMs) {
      _finishTransitionAlignment(reason: 'already aligned');
      return;
    }
    appLogger.d('WatchTogether: Promoted host aligning to inherited ${anchorMs}ms');
    _transitionAlignSeekInFlight = true;
    _transitionAlignTimer?.cancel();
    final authority = _authority;
    final operation = _timelineOperation;
    _transitionAlignTimer = Timer(const Duration(milliseconds: transitionAlignTimeoutMs), () {
      _transitionAlignTimer = null;
      if (authority == _authority &&
          operation == _timelineOperation &&
          _matchingPlayer &&
          player.usable &&
          _transitionAlignSeekInFlight) {
        _finishTransitionAlignment(reason: 'seek render timeout');
      }
    });
    unawaited(
      player.seek(Duration(milliseconds: anchorMs)).then((didSeek) {
        if (authority != _authority || operation != _timelineOperation || !_transitionAlignSeekInFlight) return;
        if (!didSeek) {
          // The seek was refused: publishing a position this host is not at
          // would pin every guest to it. Its real position takes over and the
          // ordinary corrections carry the room from there.
          _finishTransitionAlignment(reason: 'seek refused');
        }
      }),
    );
  }

  /// The inherited position has served its purpose (or cannot be reached):
  /// the promoted player's own position is the room's from here on.
  void _finishTransitionAlignment({required String reason}) {
    if (_transitionAnchorMs == null) return;
    if (!_matchingPlayer || !_player!.usable) return;
    _timelinePositionMs = _player!.position.inMilliseconds;
    appLogger.d('WatchTogether: Promoted host owns the timeline ($reason)');
    _clearTransitionAnchor();
    if (_phase == PlaybackPhase.waitingForPeers) {
      // The anchor is gone: publish where this host actually is before the
      // group start is scheduled from it.
      _broadcast();
      _scheduleAllReadyCheck(0);
    }
    if (_phase == PlaybackPhase.playing && !_player!.playing && _pendingStartAtMs == null) {
      _scheduleStart(actor: _pendingActor ?? myPeerId);
    }
  }

  void _clearTransitionAnchor() {
    _transitionAnchorMs = null;
    _cancelAlignmentAttempt();
  }

  void _cancelAlignmentAttempt() {
    _transitionAlignSeekInFlight = false;
    _transitionAlignTimer?.cancel();
    _transitionAlignTimer = null;
  }

  void _onSelfBuffering(bool buffering) {
    if (!_matchingPlayer || !_localReady) return;

    if (buffering) {
      _recoveringFromSelfStall = false;
      _selfStallStartedMs ??= _nowMs();
      if (_phase != PlaybackPhase.playing || _localStalled) return;
      _selfStallGraceTimer?.cancel();
      _selfStallGraceTimer = Timer(const Duration(milliseconds: stallGraceMs), () {
        _selfStallGraceTimer = null;
        final player = _player;
        if (player == null || !player.buffering || _phase != PlaybackPhase.playing) return;
        _localStalled = true;
        appLogger.d('WatchTogether: Host stalled at ${player.position.inMilliseconds}ms, pausing the room');
        _enterWaiting();
      });
    } else {
      _selfStallGraceTimer?.cancel();
      _selfStallGraceTimer = null;
      final startedAt = _selfStallStartedMs;
      _selfStallStartedMs = null;
      if (startedAt != null) {
        _selfStallEndedMs = _nowMs();
        _lastSelfStallMs = _selfStallEndedMs - startedAt;
      }
      if (_localStalled) {
        _localStalled = false;
        _recoveringFromSelfStall = true;
        appLogger.d('WatchTogether: Host stall ended after ${_lastSelfStallMs}ms, holding for headroom');
        _scheduleAllReadyCheck(recoveryHysteresisMs);
      } else if (_phase == PlaybackPhase.waitingForPeers) {
        // Buffering that started during someone else's stall gates the
        // resume too; re-evaluate now that it cleared.
        _scheduleAllReadyCheck(0);
      }
    }
  }

  void _onLocalPlayingIntent(bool playing) {
    if (!hasActiveEpoch || !_matchingPlayer) return;
    if (playing) {
      _requestPlay(actor: myPeerId);
    } else {
      _requestPause(actor: myPeerId);
    }
  }

  /// A play this attachment commanded was acknowledged. The command may have
  /// been issued by the engine this one replaced (a guest reconciler mid
  /// correction when authority moved): a host player running under a stopped
  /// room would broadcast a moving position every heartbeat, so the room's
  /// phase wins and the player is put back.
  void _onAcknowledgedPlaying(bool playing) {
    if (!_matchingPlayer || !playing || _phase == PlaybackPhase.playing) return;
    final player = _player;
    if (player == null || !player.playing) return;
    appLogger.d('WatchTogether: Late play acknowledged while ${_phase.name}; pausing');
    unawaited(player.pause());
  }

  /// User rate change on the host (the screen already applied it locally).
  /// Declared by the screen, never inferred from the player's rate stream.
  void onLocalRateIntent(double rate) {
    if (!hasActiveEpoch || !_matchingPlayer) return;
    if (!rate.isFinite || rate < _minimumRemoteRate || rate > _maximumRemoteRate) return;
    _rateOperation++;
    if (_rate == rate) return;
    _rate = rate;
    appLogger.d('WatchTogether: Host set room rate $rate');
    _broadcast(hint: PlaybackActionHint.rate, actor: myPeerId);
  }

  // ---------------------------------------------------------------------
  // Play / pause / seek / rate policy
  // ---------------------------------------------------------------------

  void _requestPlay({required String actor}) {
    if (_phase == PlaybackPhase.playing) return;
    _playOperation++;
    _pendingActor = actor;
    if (actor != myPeerId) onRemoteAction?.call(actor, PlaybackActionHint.play);
    if (!_matchingPlayer || !_localReady || !_startupHoldResolved) {
      _setPhase(PlaybackPhase.loading);
      if (_matchingPlayer && _player!.playing) unawaited(_player!.pause());
      _broadcast(actor: actor);
      return;
    }
    _enterWaiting();
  }

  void _requestPause({required String actor}) {
    _playOperation++;
    _pendingActor = null;
    _cancelPendingStart();
    _cancelSafety();
    if (actor != myPeerId) onRemoteAction?.call(actor, PlaybackActionHint.pause);

    final player = _matchingPlayer ? _player : null;
    if (player != null && player.playing) {
      unawaited(player.pause());
    }
    _setPhase(PlaybackPhase.paused);
    _broadcast(hint: PlaybackActionHint.pause, actor: actor);
  }

  void _applyRemoteSeek(int targetMs, {required String actor}) {
    final player = _matchingPlayer ? _player : null;
    if (player == null || !player.seekable) return;
    final durationMs = player.duration.inMilliseconds;
    if (durationMs <= 0 || targetMs < 0 || targetMs > durationMs) return;
    onRemoteAction?.call(actor, PlaybackActionHint.seek);
    _setSeekTarget(targetMs);
    final operation = _timelineOperation;
    _broadcast(hint: PlaybackActionHint.seek, actor: actor);
    unawaited(
      player.seek(Duration(milliseconds: targetMs)).then((didSeek) {
        if (_disposed || operation != _timelineOperation) return;
        if (didSeek) _afterHostSeek(targetMs, actor: actor);
      }),
    );
  }

  void _setSeekTarget(int targetMs) {
    _timelineOperation++;
    _playOperation++;
    _clearTransitionAnchor();
    _timelinePositionMs = targetMs;
    _transitionAnchorMs = targetMs;
    _pendingSeekTargetMs = targetMs;
    _seekDebounceTimer?.cancel();
    if (_pendingStartAtMs != null) _pendingStartPositionMs = targetMs;
  }

  void _afterHostSeek(int targetMs, {required String actor}) {
    _pendingSeekTargetMs = null;
    if (_matchingPlayer && _localReady && _startupHoldResolved) _alignToTransitionAnchor(_player!);
    // Re-anchor at the seek target. If a scheduled start is pending, move
    // its position too so the start fires from the new spot.
    if (_pendingStartAtMs != null) {
      _pendingStartPositionMs = targetMs;
    }
    _broadcast(hint: PlaybackActionHint.seek, actor: actor, anchorPositionOverrideMs: targetMs);
  }

  void _applyRemoteRate(double rate, {required String actor}) {
    final player = _matchingPlayer ? _player : null;
    if (player == null || !rate.isFinite || rate < _minimumRemoteRate || rate > _maximumRemoteRate) return;
    final authority = _authority;
    final operation = ++_rateOperation;
    unawaited(
      player.setRate(rate).then((didSet) {
        if (!didSet || authority != _authority || operation != _rateOperation) return;
        _rate = rate;
        appLogger.d('WatchTogether: Room rate $rate applied for $actor');
        // Reported after the rate is committed so listeners reading [rate]
        // see the value the action refers to.
        onRemoteAction?.call(actor, PlaybackActionHint.rate);
        _broadcast(hint: PlaybackActionHint.rate, actor: actor);
      }),
    );
  }

  // ---------------------------------------------------------------------
  // Readiness / group-wait machinery
  // ---------------------------------------------------------------------

  /// Peers (including self) the room cannot play without right now.
  Set<String> _gatingPeers() {
    final gating = <String>{};
    final mediaKey = _mediaKey;
    if (mediaKey == null) return gating;

    for (final peerId in _knownPeers) {
      if (_excused.contains(peerId)) continue;
      final status = _peerStatuses[peerId];
      if (status == null || status.mediaKey != mediaKey) {
        // Never reported for this epoch: gate only the initial start —
        // mid-session they're late joiners who catch up on their own.
        if (!_firstStartCompleted) gating.add(peerId);
        continue;
      }
      if (!status.ready) {
        if (!_firstStartCompleted) gating.add(peerId);
        continue;
      }
      if (_stalledPeers.contains(peerId)) gating.add(peerId);
    }
    // A host that is buffering gates the room whether or not it was the one
    // that stopped it: resuming into an empty cache is the next stall. A
    // promoted host still aligning to the inherited position gates too:
    // readiness is not alignment.
    if (!_matchingPlayer ||
        !_localReady ||
        !_startupHoldResolved ||
        _localStalled ||
        _transitionAnchorMs != null ||
        (_player?.buffering ?? false)) {
      gating.add(myPeerId);
    }
    return gating;
  }

  void _enterWaiting() {
    _setPhase(PlaybackPhase.waitingForPeers);
    _broadcast();
    _checkAllReady();
  }

  void _scheduleAllReadyCheck(int delayMs) {
    _allReadyCheckTimer?.cancel();
    _allReadyCheckTimer = null;
    if (delayMs <= 0) {
      _checkAllReady();
    } else {
      _allReadyCheckTimer = Timer(Duration(milliseconds: delayMs), _checkAllReady);
    }
  }

  void _checkAllReady() {
    if (_disposed || _phase != PlaybackPhase.waitingForPeers) return;
    final gating = _gatingPeers();
    if (gating.isNotEmpty) {
      _armSafetyIfGated();
      _broadcastIfWaitingOnChanged(gating);
      return;
    }

    // After our own stall, require cache headroom before resuming so we
    // don't immediately drag the room back into a stall. The requirement
    // scales with the stall we just had, capped by the media left to buffer
    // — near the end nothing more can arrive — and the wait itself is
    // bounded, since the cache may simply never grow.
    final player = _player;
    if (_recoveringFromSelfStall && player != null) {
      if (player.buffering) return; // A new stall event will re-drive us.
      final waitedMs = _nowMs() - _selfStallEndedMs;
      final neededMs = _selfRecoveryHeadroomMs(player);
      final ahead = player.bufferAhead;
      // No cache position from this backend: hold for the time the cache
      // would take to fill instead.
      final satisfied = ahead != null ? ahead.inMilliseconds >= neededMs : waitedMs >= neededMs;
      if (!satisfied && waitedMs < selfRecoveryMaxWaitMs) {
        final untilDeadlineMs = selfRecoveryMaxWaitMs - waitedMs;
        _scheduleAllReadyCheck(ahead != null ? min(500, untilDeadlineMs) : min(neededMs - waitedMs, untilDeadlineMs));
        return;
      }
    }
    _recoveringFromSelfStall = false;
    _resolveAllReady();
  }

  int _selfRecoveryHeadroomMs(AttachedPlayer player) {
    final scaled = (_lastSelfStallMs * selfRecoveryHeadroomFactor).clamp(
      selfRecoveryMinBufferAheadMs,
      selfRecoveryMaxHeadroomMs,
    );
    final durationMs = player.duration.inMilliseconds;
    if (durationMs <= 0) return scaled; // Live or unknown length: nothing to cap against.
    final remainingMs = durationMs - player.position.inMilliseconds - selfRecoveryEofSlackMs;
    return remainingMs < scaled ? max(0, remainingMs) : scaled;
  }

  void _resolveAllReady() {
    _scheduleStart(actor: _pendingActor ?? myPeerId);
    _pendingActor = null;
  }

  void _scheduleStart({required String actor}) {
    final player = _player;
    if (player == null || !_matchingPlayer || !_localReady || !_startupHoldResolved) return;
    _cancelPendingStart();

    final otherPeers = _knownPeers.where((p) => !_excused.contains(p)).toList();
    int delayMs;
    if (otherPeers.isEmpty) {
      delayMs = 0;
    } else {
      var maxRtt = 0;
      for (final peerId in otherPeers) {
        maxRtt = max(maxRtt, _peerStatuses[peerId]?.rttMs ?? defaultPeerRttMs);
      }
      delayMs = max(startDelayMinMs, min((maxRtt * 1.5).round(), startDelayMaxMs));
    }

    final startAt = _nowMs() + delayMs;
    final startPositionMs = player.position.inMilliseconds;
    _pendingStartAtMs = startAt;
    _pendingStartPositionMs = startPositionMs;
    _firstStartCompleted = true;
    _setPhase(PlaybackPhase.playing);
    _broadcast(hint: PlaybackActionHint.play, actor: actor);

    void fireStart() {
      _pendingStartTimer = null;
      _pendingStartAtMs = null;
      final startPos = _pendingStartPositionMs;
      _pendingStartPositionMs = null;
      final currentPlayer = _player;
      if (currentPlayer == null || _phase != PlaybackPhase.playing) return;
      final authority = _authority;
      final playOperation = _playOperation;
      // A vehicle that requires distraction optimization refuses the play. The room would
      // otherwise sit in a playing phase the host is not honouring, with nothing to correct it, so
      // put it back to paused: the host is the authority on what it is actually doing.
      void settle(bool started) {
        // Only this attachment's own refusal counts. A reload detaches mid-flight and its disposed
        // player also answers false, but that pause belongs to the source switch, which deliberately
        // holds the phase so the replacement can pick the room up again.
        if (started || authority != _authority || playOperation != _playOperation || _phase != PlaybackPhase.playing) {
          return;
        }
        _setPhase(PlaybackPhase.paused);
        _broadcast();
      }

      if (startPos != null && (currentPlayer.position.inMilliseconds - startPos).abs() > 250) {
        unawaited(
          currentPlayer
              .seek(Duration(milliseconds: startPos))
              // The seek outlived this engine's authority (a demotion, a reload): the play it was
              // leading into belongs to nobody now.
              .then(
                (didSeek) =>
                    didSeek &&
                        authority == _authority &&
                        playOperation == _playOperation &&
                        _phase == PlaybackPhase.playing
                    ? currentPlayer.play()
                    : Future.value(false),
              )
              .then(settle),
        );
      } else {
        unawaited(currentPlayer.play().then(settle));
      }
    }

    if (delayMs <= 0 && player.playing) {
      // Solo resume of an already-playing player: nothing to do.
      _pendingStartTimer = null;
      _pendingStartAtMs = null;
      _pendingStartPositionMs = null;
    } else {
      // The host waits for the group moment like everyone else — undo a
      // user-initiated unpause until the scheduled start fires.
      if (player.playing) {
        unawaited(player.pause());
      }
      _pendingStartTimer = Timer(Duration(milliseconds: delayMs), fireStart);
    }
  }

  void _armSafetyIfGated() {
    if (_phase != PlaybackPhase.waitingForPeers || _safetyTimer != null) return;
    if (_gatingPeers().difference({myPeerId}).isEmpty) return;
    _safetyDeadlineMs ??= _nowMs() + safetyTimeoutMs;
    _safetyTimer = Timer(Duration(milliseconds: max(0, _safetyDeadlineMs! - _nowMs())), () {
      _safetyTimer = null;
      if (_disposed || _phase != PlaybackPhase.waitingForPeers) return;
      final gating = _gatingPeers()..remove(myPeerId);
      if (gating.isEmpty) return;
      _excused.addAll(gating);
      _stalledPeers.removeAll(gating);
      appLogger.w('WatchTogether: Resuming without ${gating.join(', ')} after ${safetyTimeoutMs ~/ 1000}s');
      onResumedWithout?.call(gating.toList()..sort());
      _scheduleAllReadyCheck(0);
    });
  }

  void _cancelPendingStart() {
    _pendingStartTimer?.cancel();
    _pendingStartTimer = null;
    _pendingStartAtMs = null;
    _pendingStartPositionMs = null;
  }

  void _cancelSafety() {
    _safetyTimer?.cancel();
    _safetyTimer = null;
    _safetyDeadlineMs = null;
  }

  void _cancelStallTimers() {
    _selfStallGraceTimer?.cancel();
    _selfStallGraceTimer = null;
    for (final timer in _peerStallGraceTimers.values) {
      timer.cancel();
    }
    _peerStallGraceTimers.clear();
  }

  // ---------------------------------------------------------------------
  // Heartbeat & broadcasting
  // ---------------------------------------------------------------------

  void _restartHeartbeat() {
    _heartbeatTimer?.cancel();
    if (_disposed || !hasActiveEpoch) return;
    final interval = _phase == PlaybackPhase.playing ? heartbeatPlayingMs : heartbeatIdleMs;
    _heartbeatTimer = Timer.periodic(Duration(milliseconds: interval), (_) => _onHeartbeat());
  }

  void _onHeartbeat() {
    if (_backgrounded || _disposed || !hasActiveEpoch) return;
    final player = _matchingPlayer ? _player : null;
    _requestMatchingMedia();
    if (_phase == PlaybackPhase.waitingForPeers) _checkAllReady();
    // Already-dispatched native rate commands cannot be retracted at a role
    // swap; the current owner repairs any late effect, never adopts it.
    if (player != null && (player.rate - _rate).abs() > 0.001) unawaited(player.setRate(_rate));

    // Implicit-jump detection: a position far from where the last broadcast
    // predicts, with no seek intent in flight, means something seeked the
    // player behind our back (OS remote, EOF jump) — re-anchor with a seek
    // hint so guests snap instead of nudging.
    PlaybackActionHint? hint;
    final last = _lastBroadcast;
    // While an inherited anchor is held this player is expected elsewhere;
    // its distance from the anchor is the alignment in progress, not a jump.
    if (last != null &&
        player != null &&
        _transitionAnchorMs == null &&
        _pendingStartAtMs == null &&
        _pendingSeekTargetMs == null &&
        !player.buffering) {
      final expected = last.targetPositionMs(_nowMs());
      if ((player.position.inMilliseconds - expected).abs() > implicitJumpThresholdMs) {
        hint = PlaybackActionHint.seek;
      }
    }
    _broadcast(hint: hint, actor: hint != null ? myPeerId : null);
  }

  void _broadcastIfWaitingOnChanged(Set<String> gating) {
    final last = _lastBroadcast;
    if (last == null) return;
    final current = gating.toList()..sort();
    if (current.length == last.waitingOn.length && last.waitingOn.toSet().containsAll(current)) return;
    _broadcast();
  }

  void _setPhase(PlaybackPhase phase) {
    final changed = _phase != phase;
    _phase = phase;
    if (phase == PlaybackPhase.waitingForPeers) {
      if (_matchingPlayer && _player!.playing) unawaited(_player!.pause());
      _armSafetyIfGated();
    } else {
      _cancelSafety();
    }
    if (changed) onPhaseChanged?.call(phase);
    _restartHeartbeat();
  }

  void _broadcast({PlaybackActionHint? hint, String? actor, String? toPeerId, int? anchorPositionOverrideMs}) {
    if (_disposed || !hasActiveEpoch) return;

    final player = _matchingPlayer && _localReady && _startupHoldResolved ? _player : null;
    final last = _lastBroadcast;
    int anchorPositionMs;
    int anchorHostTimeMs;
    if (_pendingStartAtMs != null && _phase == PlaybackPhase.playing) {
      anchorPositionMs = _pendingStartPositionMs ?? player?.position.inMilliseconds ?? 0;
      anchorHostTimeMs = _pendingStartAtMs!;
    } else if (hint == null &&
        anchorPositionOverrideMs == null &&
        _phase == PlaybackPhase.playing &&
        player != null &&
        player.buffering &&
        last != null &&
        last.phase == PlaybackPhase.playing) {
      // A heartbeat during a stall shorter than the grace window: the player
      // position is frozen, but the room clock is not. Re-anchoring here
      // would move every guest back by the stall so far; keep extrapolating
      // the last anchor and let the stall handler re-anchor if it matures.
      anchorPositionMs = last.anchorPositionMs;
      anchorHostTimeMs = last.anchorHostTimeMs;
    } else {
      // Canonical room position survives a source-open gap independently of
      // emitted snapshots and of any stale or not-yet-ready binding.
      anchorPositionMs =
          anchorPositionOverrideMs ?? _transitionAnchorMs ?? player?.position.inMilliseconds ?? _timelinePositionMs;
      anchorHostTimeMs = _nowMs();
    }
    _timelinePositionMs = anchorPositionMs;

    final waitingOn = _phase == PlaybackPhase.waitingForPeers ? (_gatingPeers().toList()..sort()) : const <String>[];

    final state = PlaybackState(
      seq: ++_seq,
      ratingKey: _ratingKey!,
      serverId: _serverId!,
      mediaTitle: _mediaTitle,
      phase: _phase,
      anchorPositionMs: anchorPositionMs,
      anchorHostTimeMs: anchorHostTimeMs,
      rate: _rate,
      controlMode: _controlMode,
      waitingOn: waitingOn,
      actorPeerId: actor,
      actionHint: hint,
    );

    if (toPeerId == null) {
      final previousWaiting = _lastBroadcast?.waitingOn ?? const [];
      _lastBroadcast = state;
      if (!orderedStringListsEqual(previousWaiting, waitingOn)) {
        onWaitingOnChanged?.call(waitingOn);
      }
    }
    _sendState(state, toPeerId: toPeerId);
  }
}
