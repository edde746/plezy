import 'dart:async';

import '../../utils/app_logger.dart';
import '../models/playback_state.dart';
import '../models/sync_message.dart';
import '../models/watch_session.dart';
import 'attached_player.dart';
import 'clock_sync.dart';

/// Callbacks the reconciler surfaces to the provider/UI layer.
class GuestReconcilerCallbacks {
  /// The host's state names media we don't have loaded — navigate/reload.
  final void Function(String ratingKey, String serverId, String? mediaTitle)? onMediaSwitchNeeded;

  final void Function(ControlMode mode)? onControlModeChanged;
  final void Function(PlaybackPhase phase)? onPhaseChanged;
  final void Function(List<String> waitingOn)? onWaitingOnChanged;

  /// A hard correction is in flight (drives the syncing pill).
  final void Function(bool correcting)? onCorrectingChanged;

  /// Another peer caused a transition (drives action toasts).
  final void Function(String peerId, PlaybackActionHint hint)? onRemoteAction;

  const GuestReconcilerCallbacks({
    this.onMediaSwitchNeeded,
    this.onControlModeChanged,
    this.onPhaseChanged,
    this.onWaitingOnChanged,
    this.onCorrectingChanged,
    this.onRemoteAction,
  });
}

/// Guest-side reconciliation loop: converges the local player onto the
/// host's authoritative [PlaybackState].
///
/// Small drift is corrected invisibly with a brief playback-rate nudge
/// (skipped while audio passthrough is active — rate changes tear bitstream
/// output down); large drift hard-seeks with a post-seek settle window so we
/// never measure mid-seek positions. Local user actions become
/// [ControlRequest]s in anyone-mode (with a short optimistic window so the
/// next heartbeat doesn't undo them before the host confirms) and snap back
/// in host-only mode.
class GuestPlaybackReconciler {
  GuestPlaybackReconciler({
    required this.myPeerId,
    required this._sendToHost,
    required ClockSync clockSync,
    this._callbacks = const GuestReconcilerCallbacks(),
    int Function()? nowMs,
  }) : _clock = clockSync,
       _nowMs = nowMs ?? _systemNowMs;

  static int _systemNowMs() => DateTime.now().millisecondsSinceEpoch;

  // Tuning constants.
  static const int tickMs = 500;
  static const int deadbandMs = 350;
  static const int nudgeExitMs = 150;
  static const double nudgeFactor = 0.04;
  static const int hardSeekThresholdMs = 2000;
  static const int hardSeekLeadMs = 250;
  static const int hardSeekCooldownMs = 2000;
  static const int pausedSeekThresholdMs = 500;
  static const int settleExtraMs = 250;
  static const int settleTimeoutMs = 1500;
  static const int optimisticWindowMs = 2000;
  static const int nudgeConfirmMs = 500;
  static const int bufferingStatusRefreshMs = 5000;
  static const int eofClampMs = 200;
  static const int eofToleranceMs = 1000;

  final String myPeerId;
  final void Function(SyncMessage message) _sendToHost;
  final ClockSync _clock;
  final GuestReconcilerCallbacks _callbacks;
  final int Function() _nowMs;

  PlaybackState? _latestState;
  int _lastSeq = -1;
  PlaybackPhase? _reportedPhase;
  List<String> _reportedWaitingOn = const [];
  ControlMode? _reportedControlMode;

  AttachedPlayer? _player;
  final List<StreamSubscription<dynamic>> _playerSubscriptions = [];
  String? _attachedMediaKey;
  bool _localReady = false;
  bool _firstFrameSeen = false;
  bool _startupHoldResolved = true;

  Timer? _tickTimer;
  bool _backgrounded = false;
  bool _disposed = false;

  // Correction state.
  bool _settling = false;
  Timer? _settleTimer;
  bool _correcting = false;
  bool _nudging = false;
  bool _nudgeDisabled = false;
  bool _nudgeConfirmed = false;
  Timer? _nudgeConfirmTimer;
  int _lastHardSeekMs = -hardSeekCooldownMs;
  final List<int> _driftSamples = [];

  // Scheduled group start.
  Timer? _scheduledStartTimer;
  int? _scheduledStartSeq;

  // Optimistic window after sending a control request.
  int? _optimisticUntilSeq;
  int _optimisticDeadlineMs = 0;

  // Status reporting.
  PeerStatus? _lastSentStatus;
  Timer? _statusRefreshTimer;

  PlaybackState? get latestState => _latestState;
  bool get isCorrecting => _correcting;

  // ---------------------------------------------------------------------
  // Public inputs
  // ---------------------------------------------------------------------

  void attach(
    AttachedPlayer player, {
    required String ratingKey,
    required String serverId,
    bool hasFirstFrame = false,
    Future<void>? startupHold,
  }) {
    detachPlayer();
    _player = player;
    _attachedMediaKey = PlaybackState.mediaKeyFor(ratingKey: ratingKey, serverId: serverId);
    _firstFrameSeen = hasFirstFrame;
    _startupHoldResolved = startupHold == null;

    if (startupHold != null) {
      startupHold.then((_) {
        if (_disposed || !identical(_player, player)) return;
        _startupHoldResolved = true;
        _maybeBecomeReady();
      });
    }

    _playerSubscriptions.add(
      player.loadedSignals.listen((_) {
        if (_settling) {
          _settleTimer?.cancel();
          _settleTimer = Timer(const Duration(milliseconds: settleExtraMs), _endSettle);
        }
        if (!_firstFrameSeen) {
          _firstFrameSeen = true;
          _maybeBecomeReady();
        }
      }),
    );
    _playerSubscriptions.add(
      player.bufferingChanges.listen((_) {
        _sendStatus();
      }),
    );
    _playerSubscriptions.add(player.playingIntents.listen(_onLocalPlayingIntent));
    _playerSubscriptions.add(player.rateIntents.listen(_onLocalRateIntent));

    _tickTimer = Timer.periodic(const Duration(milliseconds: tickMs), (_) => _onTick());
    if (_firstFrameSeen && _startupHoldResolved) {
      _localReady = true;
      appLogger.d('WatchTogether: Guest player ready for $_attachedMediaKey');
    }
    _sendStatus();
    if (_localReady) _reconcile();
  }

  void _maybeBecomeReady() {
    if (_localReady || !_firstFrameSeen || !_startupHoldResolved) return;
    _localReady = true;
    appLogger.d('WatchTogether: Guest player ready for $_attachedMediaKey');
    _sendStatus();
    _reconcile();
  }

  void detachPlayer() {
    for (final subscription in _playerSubscriptions) {
      unawaited(subscription.cancel());
    }
    _playerSubscriptions.clear();

    // Tell the host we're no longer ready on this media (it re-gates us for
    // the next epoch start instead of waiting on a stale "ready").
    if (_player != null && _attachedMediaKey != null) {
      _lastSentStatus = null;
      _sendToHost(
        SyncMessage.status(
          PeerStatus(mediaKey: _attachedMediaKey!, ready: false, buffering: false, positionMs: 0),
          peerId: myPeerId,
        ),
      );
    }

    _player = null;
    _attachedMediaKey = null;
    _localReady = false;
    _firstFrameSeen = false;
    _startupHoldResolved = true;
    _tickTimer?.cancel();
    _tickTimer = null;
    _settleTimer?.cancel();
    _settleTimer = null;
    _settling = false;
    _nudging = false;
    _nudgeConfirmTimer?.cancel();
    _nudgeConfirmTimer = null;
    _scheduledStartTimer?.cancel();
    _scheduledStartTimer = null;
    _scheduledStartSeq = null;
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = null;
    _driftSamples.clear();
    _setCorrecting(false);
  }

  /// Latest authoritative state from the host (already host-authenticated).
  void onState(PlaybackState state) {
    if (state.seq <= _lastSeq) return; // Stale or reordered.
    _lastSeq = state.seq;
    final previous = _latestState;
    _latestState = state;

    if (state.controlMode != _reportedControlMode) {
      _reportedControlMode = state.controlMode;
      _callbacks.onControlModeChanged?.call(state.controlMode);
    }
    if (state.phase != _reportedPhase) {
      _reportedPhase = state.phase;
      _callbacks.onPhaseChanged?.call(state.phase);
    }
    if (!_listEquals(state.waitingOn, _reportedWaitingOn)) {
      _reportedWaitingOn = state.waitingOn;
      _callbacks.onWaitingOnChanged?.call(state.waitingOn);
    }
    if (state.actionHint != null && state.actorPeerId != null && state.actorPeerId != myPeerId) {
      _callbacks.onRemoteAction?.call(state.actorPeerId!, state.actionHint!);
    }

    // Close the optimistic window only on an explicit transition (the host
    // applied our request — or someone else's superseding one). A plain
    // heartbeat that was already in flight when we sent the request still
    // carries the pre-request anchor and must not yank us back.
    if (_optimisticUntilSeq != null && (state.actorPeerId == myPeerId || state.actionHint != null)) {
      _optimisticUntilSeq = null;
    }

    // Self-heal: the host thinks it's waiting on us but we're healthy.
    final player = _player;
    if (state.waitingOn.contains(myPeerId) && _localReady && player != null && !player.buffering) {
      _sendStatus(force: true);
    }

    // The host moved to media we don't have — hand off to the switch flow.
    if (_attachedMediaKey != null && state.mediaKey != _attachedMediaKey) {
      _callbacks.onMediaSwitchNeeded?.call(state.ratingKey, state.serverId, state.mediaTitle);
      return;
    }
    if (previous?.mediaKey != state.mediaKey && _attachedMediaKey == null) {
      // Not in the player yet — let the provider navigate.
      _callbacks.onMediaSwitchNeeded?.call(state.ratingKey, state.serverId, state.mediaTitle);
      return;
    }

    _reconcile();
  }

  /// User seek on this guest (the screen already executed it locally).
  void onLocalSeekIntent(Duration position) {
    if (_latestState == null) return;
    if (_canControl) {
      _sendControl(ControlRequest(kind: ControlRequestKind.seek, positionMs: position.inMilliseconds));
    } else {
      _reconcile(); // Snap back.
    }
  }

  void setBackgrounded(bool value) {
    if (_backgrounded == value) return;
    _backgrounded = value;
    if (!value) _reconcile();
  }

  /// Host session restarted (fresh join observed) — accept its new counter.
  void resetSequence() {
    _lastSeq = -1;
  }

  void onReconnected() {
    _sendStatus(force: true);
  }

  void dispose() {
    _disposed = true;
    detachPlayer();
  }

  // ---------------------------------------------------------------------
  // Local intents
  // ---------------------------------------------------------------------

  bool get _canControl => _latestState?.controlMode == ControlMode.anyone;

  void _onLocalPlayingIntent(bool playing) {
    if (_latestState == null) return;
    if (_canControl) {
      _sendControl(
        ControlRequest(
          kind: playing ? ControlRequestKind.play : ControlRequestKind.pause,
          positionMs: _player?.position.inMilliseconds,
        ),
      );
    } else {
      _reconcile(); // Snap back to the room state.
    }
  }

  void _onLocalRateIntent(double rate) {
    if (_latestState == null) return;
    if (_canControl) {
      _sendControl(ControlRequest(kind: ControlRequestKind.rate, rate: rate));
    } else {
      _reconcile();
    }
  }

  void _sendControl(ControlRequest request) {
    _sendToHost(SyncMessage.control(request, peerId: myPeerId));
    _optimisticUntilSeq = _lastSeq;
    _optimisticDeadlineMs = _nowMs() + optimisticWindowMs;
  }

  bool get _optimisticWindowActive => _optimisticUntilSeq != null && _nowMs() < _optimisticDeadlineMs;

  // ---------------------------------------------------------------------
  // Reconciliation
  // ---------------------------------------------------------------------

  void _onTick() {
    _reconcile();
    // Keep the host's view fresh while we're the one buffering.
    final player = _player;
    if (player != null && player.buffering && _statusRefreshTimer == null) {
      _statusRefreshTimer = Timer(const Duration(milliseconds: bufferingStatusRefreshMs), () {
        _statusRefreshTimer = null;
        if (_player?.buffering ?? false) _sendStatus(force: true);
      });
    }
  }

  void _reconcile() {
    if (_disposed || _backgrounded || _settling) return;
    final state = _latestState;
    final player = _player;
    if (state == null || player == null || !_localReady) return;
    if (state.mediaKey != _attachedMediaKey) return;
    if (_optimisticWindowActive) return;

    switch (state.phase) {
      case PlaybackPhase.loading:
        // Host is still loading — its anchor is meaningless. Just hold.
        _exitNudgeIfNeeded(state);
        _ensurePaused(player);
        break;

      case PlaybackPhase.waitingForPeers:
      case PlaybackPhase.paused:
        _exitNudgeIfNeeded(state);
        _ensurePaused(player);
        _alignWhileStopped(player, state);
        break;

      case PlaybackPhase.playing:
        _reconcilePlaying(player, state);
        break;
    }
  }

  void _reconcilePlaying(AttachedPlayer player, PlaybackState state) {
    final hostNow = _clock.hostNowMs();

    // Scheduled group start: hold at the anchor, then start on the dot.
    if (state.anchorHostTimeMs > hostNow) {
      if (_scheduledStartSeq != state.seq) {
        _scheduledStartTimer?.cancel();
        _scheduledStartSeq = state.seq;
        final delay = state.anchorHostTimeMs - hostNow;
        appLogger.d('WatchTogether: Group start in ${delay}ms at ${state.anchorPositionMs}ms');
        _scheduledStartTimer = Timer(Duration(milliseconds: delay), () {
          _scheduledStartTimer = null;
          _scheduledStartSeq = null;
          final currentPlayer = _player;
          if (currentPlayer == null || _latestState?.seq != state.seq) return;
          unawaited(currentPlayer.play());
        });
      }
      _exitNudgeIfNeeded(state);
      _ensurePaused(player);
      _alignWhileStopped(player, state);
      return;
    }
    if (_scheduledStartSeq != null && _scheduledStartSeq != state.seq) {
      _scheduledStartTimer?.cancel();
      _scheduledStartTimer = null;
      _scheduledStartSeq = null;
    }

    final durationMs = player.duration.inMilliseconds;
    var targetMs = state.targetPositionMs(hostNow);
    if (durationMs > 0 && targetMs > durationMs - eofClampMs) {
      targetMs = durationMs - eofClampMs;
    }

    // Both of us rolled into the credits — don't fight EOF.
    if (player.completed && durationMs > 0 && targetMs >= durationMs - eofToleranceMs) {
      return;
    }

    if (!player.playing) {
      if (player.completed) {
        // Fell off the end while the room plays on — rejoin via seek+play.
        if (player.seekable && _cooldownElapsed) {
          _hardSeek(player, targetMs, thenPlay: true);
        }
        return;
      }
      unawaited(player.play());
    }

    // Base rate alignment (never while nudging — the nudge owns the rate).
    if (!_nudging && (player.rate - state.rate).abs() > 0.001) {
      unawaited(player.setRate(state.rate));
    }

    if (!player.seekable) return; // Live: play/pause/rate only.

    final drift = _smoothedDrift(player.position.inMilliseconds - targetMs);
    if (drift == null) return;

    final magnitude = drift.abs();
    if (magnitude <= (_nudging ? nudgeExitMs : deadbandMs)) {
      _exitNudgeIfNeeded(state);
      return;
    }

    if (magnitude <= deadbandMs) return; // Inside deadband, still nudging.

    if (magnitude <= hardSeekThresholdMs) {
      _maybeNudge(player, state, drift);
      return;
    }

    // Hard correction.
    _exitNudgeIfNeeded(state);
    if (!_cooldownElapsed) return;
    _hardSeek(player, targetMs + hardSeekLeadMs);
  }

  bool get _cooldownElapsed => _nowMs() - _lastHardSeekMs >= hardSeekCooldownMs;

  void _hardSeek(AttachedPlayer player, int targetMs, {bool thenPlay = false}) {
    _lastHardSeekMs = _nowMs();
    _driftSamples.clear();
    _setCorrecting(true);
    _beginSettle();
    appLogger.d('WatchTogether: Hard sync seek to ${targetMs}ms');
    unawaited(
      player.seek(Duration(milliseconds: targetMs.clamp(0, 1 << 48))).then((didSeek) async {
        if (didSeek && thenPlay) await player.play();
      }),
    );
  }

  void _alignWhileStopped(AttachedPlayer player, PlaybackState state) {
    if (!player.seekable) return;
    final offBy = (player.position.inMilliseconds - state.anchorPositionMs).abs();
    if (offBy > pausedSeekThresholdMs && _cooldownElapsed) {
      _hardSeek(player, state.anchorPositionMs);
    }
  }

  void _ensurePaused(AttachedPlayer player) {
    if (player.playing) {
      unawaited(player.pause());
    }
  }

  void _maybeNudge(AttachedPlayer player, PlaybackState state, int drift) {
    if (_nudgeDisabled || player.passthroughActive) return; // Tolerate up to the seek band.

    // Ahead of the room → slow down; behind → speed up.
    final factor = drift > 0 ? (1 - nudgeFactor) : (1 + nudgeFactor);
    final targetRate = state.rate * factor;
    if (_nudging && (player.rate - targetRate).abs() < 0.001) return;

    _nudging = true;
    unawaited(player.setRate(targetRate));

    // Arm the capability check once per (un-confirmed) nudge episode — a
    // re-issued nudge must not keep pushing the deadline out.
    if (!_nudgeConfirmed && _nudgeConfirmTimer == null) {
      _nudgeConfirmTimer = Timer(const Duration(milliseconds: nudgeConfirmMs), () {
        _nudgeConfirmTimer = null;
        final currentPlayer = _player;
        if (currentPlayer == null || !_nudging) return;
        if ((currentPlayer.rate - targetRate).abs() > 0.005) {
          appLogger.w('WatchTogether: Rate nudges not taking effect — disabling for this session');
          _nudgeDisabled = true;
          _nudging = false;
          unawaited(currentPlayer.setRate(_latestState?.rate ?? 1.0));
        } else {
          _nudgeConfirmed = true;
        }
      });
    }
  }

  void _exitNudgeIfNeeded(PlaybackState state) {
    if (!_nudging) return;
    _nudging = false;
    final player = _player;
    if (player != null) {
      unawaited(player.setRate(state.rate));
    }
  }

  int? _smoothedDrift(int rawDrift) {
    _driftSamples.add(rawDrift);
    if (_driftSamples.length > 3) _driftSamples.removeAt(0);
    if (_driftSamples.length < 2) return null; // One sample can be a fluke.
    final sorted = List<int>.of(_driftSamples)..sort();
    return sorted[sorted.length ~/ 2];
  }

  void _beginSettle() {
    _settling = true;
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: settleTimeoutMs), _endSettle);
  }

  void _endSettle() {
    if (!_settling) return;
    _settling = false;
    _settleTimer?.cancel();
    _settleTimer = null;
    _driftSamples.clear();
    _setCorrecting(false);
  }

  void _setCorrecting(bool value) {
    if (_correcting == value) return;
    _correcting = value;
    _callbacks.onCorrectingChanged?.call(value);
  }

  // ---------------------------------------------------------------------
  // Status reporting
  // ---------------------------------------------------------------------

  void _sendStatus({bool force = false}) {
    final mediaKey = _attachedMediaKey;
    if (mediaKey == null || _disposed) return;
    final player = _player;
    final status = PeerStatus(
      mediaKey: mediaKey,
      ready: _localReady,
      buffering: player?.buffering ?? false,
      positionMs: player?.position.inMilliseconds ?? 0,
      rttMs: _clock.minRttMs,
    );
    final last = _lastSentStatus;
    if (!force &&
        last != null &&
        last.mediaKey == status.mediaKey &&
        last.ready == status.ready &&
        last.buffering == status.buffering) {
      return;
    }
    _lastSentStatus = status;
    _sendToHost(SyncMessage.status(status, peerId: myPeerId));
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
