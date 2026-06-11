import 'dart:async';
import 'dart:math';

import '../../utils/app_logger.dart';
import '../models/playback_state.dart';
import '../models/watch_session.dart';
import 'attached_player.dart';

/// Callbacks the coordinator surfaces to the provider/UI layer.
class HostCoordinatorCallbacks {
  /// Phase transitions (drives the waiting pill and chrome).
  final void Function(PlaybackPhase phase)? onPhaseChanged;

  /// The set of peers the room is waiting on changed.
  final void Function(List<String> peerIds)? onWaitingOnChanged;

  /// The safety timeout excused these peers and the room resumed.
  final void Function(List<String> peerIds)? onResumedWithout;

  /// A guest's control request was applied (drives action toasts).
  final void Function(String peerId, PlaybackActionHint hint)? onRemoteAction;

  const HostCoordinatorCallbacks({
    this.onPhaseChanged,
    this.onWaitingOnChanged,
    this.onResumedWithout,
    this.onRemoteAction,
  });
}

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
    this._callbacks = const HostCoordinatorCallbacks(),
    int Function()? nowMs,
  }) : _nowMs = nowMs ?? _systemNowMs;

  static int _systemNowMs() => DateTime.now().millisecondsSinceEpoch;

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

  final String myPeerId;
  final void Function(PlaybackState state, {String? toPeerId}) _sendState;
  final HostCoordinatorCallbacks _callbacks;
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
  final List<StreamSubscription<dynamic>> _playerSubscriptions = [];
  bool _localReady = false;
  bool _startupHoldResolved = true;
  bool _localStalled = false;
  bool _recoveringFromSelfStall = false;

  // Room state.
  PlaybackPhase _phase = PlaybackPhase.loading;
  bool _intendedPlaying = false;
  double _rate = 1.0;
  bool _firstStartCompleted = false;
  int _seq = 0;
  PlaybackState? _lastBroadcast;
  bool _backgrounded = false;

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
  Timer? _heartbeatTimer;
  Timer? _pendingStartTimer;
  int? _pendingStartAtMs;
  int? _pendingStartPositionMs;
  Timer? _seekDebounceTimer;
  int? _pendingSeekTargetMs;
  String? _pendingActor;
  bool _disposed = false;

  PlaybackPhase get phase => _phase;
  Set<String> get incompatiblePeers => Set.unmodifiable(_incompatiblePeers);

  // ---------------------------------------------------------------------
  // Public inputs
  // ---------------------------------------------------------------------

  /// Host switched (or initially picked) media — a new epoch. Safe to call
  /// repeatedly with the same media; only an actual change broadcasts.
  void setLocalMedia({required String ratingKey, required String serverId, String? mediaTitle}) {
    final newKey = PlaybackState.mediaKeyFor(ratingKey: ratingKey, serverId: serverId);
    if (newKey == _mediaKey) {
      if (mediaTitle != null && mediaTitle != _mediaTitle) _mediaTitle = mediaTitle;
      return;
    }

    _ratingKey = ratingKey;
    _serverId = serverId;
    _mediaTitle = mediaTitle;
    _localReady = false;
    _localStalled = false;
    _recoveringFromSelfStall = false;
    _firstStartCompleted = false;
    _intendedPlaying = true; // Opening media implies the room wants to play.
    _excused.clear();
    _stalledPeers.clear();
    _cancelPendingStart();
    _cancelSafety();
    _cancelStallTimers();
    _setPhase(PlaybackPhase.loading);
    _broadcast(hint: PlaybackActionHint.mediaSwitch, actor: myPeerId);
    appLogger.d('WatchTogether: Host epoch -> $newKey');
  }

  /// Attach the host's player for the given media. [hasFirstFrame] is the
  /// screen's first-frame snapshot (covers attaching to an already-rendering
  /// player); [startupHold] delays readiness past platform startup gates
  /// (e.g. the Android frame-rate switch).
  void attach(
    AttachedPlayer player, {
    required String ratingKey,
    required String serverId,
    String? mediaTitle,
    bool hasFirstFrame = false,
    Future<void>? startupHold,
  }) {
    detachPlayer();
    final sameEpoch =
        hasActiveEpoch && PlaybackState.mediaKeyFor(ratingKey: ratingKey, serverId: serverId) == _mediaKey;
    setLocalMedia(ratingKey: ratingKey, serverId: serverId, mediaTitle: mediaTitle);

    _player = player;
    _rate = player.rate;

    // Same-media re-attach with a reloading player (quality/version switch):
    // group-wait at the last known spot until we render again, then the
    // normal all-ready resolution resumes the room.
    if (sameEpoch && !hasFirstFrame && _phase == PlaybackPhase.playing) {
      _intendedPlaying = true;
      _cancelPendingStart();
      _setPhase(PlaybackPhase.waitingForPeers);
      _broadcast(anchorPositionOverrideMs: _lastBroadcast?.anchorPositionMs);
      _armSafetyIfGated();
    }

    _startupHoldResolved = startupHold == null;
    if (startupHold != null) {
      startupHold.then((_) {
        if (_disposed || !identical(_player, player)) return;
        _startupHoldResolved = true;
        _maybeLocalLoaded();
      });
    }

    _playerSubscriptions.add(player.loadedSignals.listen((_) => _onLoadedSignal()));
    _playerSubscriptions.add(player.bufferingChanges.listen(_onSelfBuffering));
    _playerSubscriptions.add(player.playingIntents.listen(_onLocalPlayingIntent));
    _playerSubscriptions.add(player.rateIntents.listen(_onLocalRateIntent));

    if (hasFirstFrame) {
      _localReady = true;
      _maybeLocalLoaded();
    }
    _restartHeartbeat();
  }

  /// Detach the player (episode switch keeps the session; [exiting] ends the
  /// epoch because the host left the video player).
  void detachPlayer({bool exiting = false}) {
    for (final subscription in _playerSubscriptions) {
      unawaited(subscription.cancel());
    }
    _playerSubscriptions.clear();
    _player = null;
    _localReady = false;
    _localStalled = false;
    _recoveringFromSelfStall = false;
    _startupHoldResolved = true;
    _cancelPendingStart();
    _cancelStallTimers();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    if (exiting) {
      _ratingKey = null;
      _serverId = null;
      _mediaTitle = null;
      _cancelSafety();
      _setPhase(PlaybackPhase.loading);
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

  /// User seek on the host (the screen already executed it on the player).
  void onLocalSeekIntent(Duration position) {
    if (!hasActiveEpoch) return;
    _pendingSeekTargetMs = position.inMilliseconds;
    _seekDebounceTimer?.cancel();
    _seekDebounceTimer = Timer(const Duration(milliseconds: seekDebounceMs), () {
      final target = _pendingSeekTargetMs;
      _pendingSeekTargetMs = null;
      if (target == null || !hasActiveEpoch) return;
      _afterHostSeek(target, actor: myPeerId);
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
    _disposed = true;
    detachPlayer(exiting: true);
    _allReadyCheckTimer?.cancel();
    _seekDebounceTimer?.cancel();
    _peerStatuses.clear();
    _knownPeers.clear();
  }

  // ---------------------------------------------------------------------
  // Local player signals
  // ---------------------------------------------------------------------

  void _onLoadedSignal() {
    if (_localReady) return;
    _localReady = true;
    _maybeLocalLoaded();
  }

  void _maybeLocalLoaded() {
    if (!_localReady || !_startupHoldResolved || !hasActiveEpoch) return;
    final player = _player;
    if (player == null) return;

    appLogger.d('WatchTogether: Host player ready for $_mediaKey');

    if (_phase == PlaybackPhase.loading) {
      // The sync layer owns the start — undo anything that slipped into play.
      if (player.playing) {
        unawaited(player.pause());
      }
      _setPhase(PlaybackPhase.waitingForPeers);
      _broadcast();
      _armSafetyIfGated();
    }
    _scheduleAllReadyCheck(0);

    // A play latched while we were loading (paused room) resumes now.
    if (_phase == PlaybackPhase.paused && _intendedPlaying) {
      _requestPlay(actor: _pendingActor ?? myPeerId);
    }
  }

  void _onSelfBuffering(bool buffering) {
    if (!_localReady) return; // Pre-ready buffering is the loading flow.

    if (buffering) {
      _recoveringFromSelfStall = false;
      if (_phase != PlaybackPhase.playing || _localStalled) return;
      _selfStallGraceTimer?.cancel();
      _selfStallGraceTimer = Timer(const Duration(milliseconds: stallGraceMs), () {
        final player = _player;
        if (player == null || !player.buffering || _phase != PlaybackPhase.playing) return;
        _localStalled = true;
        // Unlike a remote stall we leave the host player unpaused so mpv can
        // refill its cache and recover on its own; its clock is frozen anyway.
        _enterWaiting();
      });
    } else {
      _selfStallGraceTimer?.cancel();
      _selfStallGraceTimer = null;
      if (_localStalled) {
        _localStalled = false;
        _recoveringFromSelfStall = true;
        _scheduleAllReadyCheck(recoveryHysteresisMs);
      }
    }
  }

  void _onLocalPlayingIntent(bool playing) {
    if (!hasActiveEpoch) return;
    if (playing) {
      _requestPlay(actor: myPeerId);
    } else {
      _requestPause(actor: myPeerId);
    }
  }

  void _onLocalRateIntent(double rate) {
    if (!hasActiveEpoch) return;
    _rate = rate;
    _broadcast(hint: PlaybackActionHint.rate, actor: myPeerId);
  }

  // ---------------------------------------------------------------------
  // Play / pause / seek / rate policy
  // ---------------------------------------------------------------------

  void _requestPlay({required String actor}) {
    if (_phase == PlaybackPhase.playing) return;
    _intendedPlaying = true;
    _pendingActor = actor;
    if (actor != myPeerId) _callbacks.onRemoteAction?.call(actor, PlaybackActionHint.play);

    final player = _player;
    if (!_localReady) {
      // Still loading: latch the intent, undo any local unpause, and stay in
      // the loading phase — its anchor would be meaningless to guests.
      if (player != null && player.playing) {
        unawaited(player.pause());
      }
      return;
    }

    final gating = _gatingPeers();
    if (gating.isEmpty) {
      _scheduleStart(actor: actor);
    } else {
      // Want to play but can't yet — hold (and undo a local unpause).
      if (player != null && player.playing) {
        unawaited(player.pause());
      }
      if (_phase != PlaybackPhase.waitingForPeers) {
        _setPhase(PlaybackPhase.waitingForPeers);
        _broadcast(actor: actor);
        _armSafetyIfGated();
      }
    }
  }

  void _requestPause({required String actor}) {
    _intendedPlaying = false;
    _pendingActor = null;
    _cancelPendingStart();
    _cancelSafety();
    if (actor != myPeerId) _callbacks.onRemoteAction?.call(actor, PlaybackActionHint.pause);

    final player = _player;
    if (player != null && player.playing) {
      unawaited(player.pause());
    }
    // While loading, only latch the intent — the all-ready resolution after
    // local readiness lands on paused because _intendedPlaying is false.
    if (_phase == PlaybackPhase.loading) return;
    _setPhase(PlaybackPhase.paused);
    _broadcast(hint: PlaybackActionHint.pause, actor: actor);
  }

  void _applyRemoteSeek(int targetMs, {required String actor}) {
    final player = _player;
    if (player == null) return;
    _callbacks.onRemoteAction?.call(actor, PlaybackActionHint.seek);
    unawaited(
      player.seek(Duration(milliseconds: targetMs)).then((didSeek) {
        if (didSeek) _afterHostSeek(targetMs, actor: actor);
      }),
    );
  }

  void _afterHostSeek(int targetMs, {required String actor}) {
    // Re-anchor at the seek target. If a scheduled start is pending, move
    // its position too so the start fires from the new spot.
    if (_pendingStartAtMs != null) {
      _pendingStartPositionMs = targetMs;
    }
    _broadcast(hint: PlaybackActionHint.seek, actor: actor, anchorPositionOverrideMs: targetMs);
  }

  void _applyRemoteRate(double rate, {required String actor}) {
    final player = _player;
    if (player == null) return;
    _callbacks.onRemoteAction?.call(actor, PlaybackActionHint.rate);
    unawaited(
      player.setRate(rate).then((didSet) {
        if (!didSet) return;
        _rate = rate;
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
    if (!_localReady || _localStalled) gating.add(myPeerId);
    return gating;
  }

  void _enterWaiting() {
    if (_phase == PlaybackPhase.waitingForPeers) return;
    final player = _player;
    // Anchor where the room stops. Pause our player unless the stall is our
    // own (mpv recovers paused-for-cache by itself).
    if (player != null && player.playing && !_localStalled) {
      unawaited(player.pause());
    }
    _intendedPlaying = true; // A stall interrupts playback we intend to resume.
    _setPhase(PlaybackPhase.waitingForPeers);
    _broadcast();
    _armSafetyIfGated();
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
      _broadcastIfWaitingOnChanged(gating);
      return;
    }

    // After our own stall, require some cache headroom before resuming so we
    // don't immediately drag the room back into a stall.
    final player = _player;
    if (_recoveringFromSelfStall && player != null) {
      if (player.buffering) return; // A new stall event will re-drive us.
      final ahead = player.bufferAhead;
      if (ahead != null && ahead.inMilliseconds < selfRecoveryMinBufferAheadMs) {
        _scheduleAllReadyCheck(500);
        return;
      }
    }
    _recoveringFromSelfStall = false;
    _resolveAllReady();
  }

  void _resolveAllReady() {
    _cancelSafety();
    if (_intendedPlaying) {
      _scheduleStart(actor: _pendingActor ?? myPeerId);
    } else {
      _setPhase(PlaybackPhase.paused);
      _broadcast();
    }
    _pendingActor = null;
  }

  void _scheduleStart({required String actor}) {
    final player = _player;
    if (player == null || !_localReady) return;
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
      if (startPos != null && (currentPlayer.position.inMilliseconds - startPos).abs() > 250) {
        unawaited(currentPlayer.seek(Duration(milliseconds: startPos)).then((_) => currentPlayer.play()));
      } else {
        unawaited(currentPlayer.play());
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
    _cancelSafety();
    if (_gatingPeers().difference({myPeerId}).isEmpty) return;
    _safetyTimer = Timer(const Duration(milliseconds: safetyTimeoutMs), () {
      if (_phase != PlaybackPhase.waitingForPeers) return;
      final gating = _gatingPeers()..remove(myPeerId);
      if (gating.isEmpty) return;
      _excused.addAll(gating);
      _stalledPeers.removeAll(gating);
      appLogger.w('WatchTogether: Resuming without ${gating.join(', ')} after ${safetyTimeoutMs ~/ 1000}s');
      _callbacks.onResumedWithout?.call(gating.toList()..sort());
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
    if (_player == null) return;
    final interval = _phase == PlaybackPhase.playing ? heartbeatPlayingMs : heartbeatIdleMs;
    _heartbeatTimer = Timer.periodic(Duration(milliseconds: interval), (_) => _onHeartbeat());
  }

  void _onHeartbeat() {
    if (_backgrounded || _disposed || !hasActiveEpoch) return;
    final player = _player;
    if (player == null) return;

    // Implicit-jump detection: a position far from where the last broadcast
    // predicts, with no seek intent in flight, means something seeked the
    // player behind our back (OS remote, EOF jump) — re-anchor with a seek
    // hint so guests snap instead of nudging.
    PlaybackActionHint? hint;
    final last = _lastBroadcast;
    if (last != null && _pendingStartAtMs == null && _pendingSeekTargetMs == null && !player.buffering) {
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
    if (_phase == phase) return;
    _phase = phase;
    _callbacks.onPhaseChanged?.call(phase);
    _restartHeartbeat();
  }

  void _broadcast({PlaybackActionHint? hint, String? actor, String? toPeerId, int? anchorPositionOverrideMs}) {
    if (_disposed || !hasActiveEpoch) return;

    final player = _player;
    int anchorPositionMs;
    int anchorHostTimeMs;
    if (_pendingStartAtMs != null && _phase == PlaybackPhase.playing) {
      anchorPositionMs = _pendingStartPositionMs ?? player?.position.inMilliseconds ?? 0;
      anchorHostTimeMs = _pendingStartAtMs!;
    } else {
      anchorPositionMs = anchorPositionOverrideMs ?? player?.position.inMilliseconds ?? 0;
      anchorHostTimeMs = _nowMs();
    }

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
      if (!_listEquals(previousWaiting, waitingOn)) {
        _callbacks.onWaitingOnChanged?.call(waitingOn);
      }
    }
    _sendState(state, toPeerId: toPeerId);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
