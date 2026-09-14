import 'dart:async';

import '../../i18n/strings.g.dart';
import '../../media/media_item.dart';
import '../../mpv/mpv.dart';
import '../../utils/app_logger.dart';
import '../../utils/snackbar_helper.dart';
import 'completion_latch.dart';
import 'media_reload_outcome.dart';
import 'playback_transition_gate.dart';
import 'wakelock_controller.dart';

/// Recovery from spurious EOFs — a network stream dying mid-file that libmpv
/// reports as a clean end-of-file (#1520).
///
/// Owns the bounded automatic-recovery budget, the progress baseline that
/// refills it, and the parked latch playback sits on once the budget is
/// spent. Exits from a park: user play/seek (always allowed, never consume
/// the budget) or the server-status monitor seeing the server come back
/// online. Plain State-owned helper in the established player pattern.
class SpuriousEofRecovery {
  SpuriousEofRecovery({
    required this.isLive,
    required this._isOffline,
    required this._transitionGate,
    required this._player,
    required this._metadata,
    required this._reload,
    required this._wakelock,
  });

  static const int maxAttempts = 2;
  static const int progressResetMs = 30000;

  final bool isLive;
  final bool Function() _isOffline;
  final PlaybackTransitionGate _transitionGate;
  final Player? Function() _player;
  final MediaItem Function() _metadata;
  final Future<MediaReloadOutcome> Function({required Duration resumePosition, required String reason}) _reload;
  final WakelockController _wakelock;

  int _attempts = 0;
  int? _baselineMs;
  bool _parked = false;

  /// Playback is parked mid-file on a dead stream: automatic recovery failed
  /// or its budget is spent.
  bool get parked => _parked;

  /// Any freshly opened stream ends a dead-stream park (#1520).
  void clearPark() {
    _parked = false;
  }

  /// An item change starts a fresh automatic-recovery budget (loop guard).
  void resetBudget() {
    _attempts = 0;
    _baselineMs = null;
  }

  /// Sustained progress past the recovery baseline proves the rebuilt stream
  /// is healthy; refill the automatic budget for the next stream death.
  void onPositionAdvanced(int positionMs) {
    final baselineMs = _baselineMs;
    if (baselineMs != null && positionMs >= baselineMs + progressResetMs) {
      _attempts = 0;
      _baselineMs = null;
    }
  }

  /// The player reports a clean EOF when a network stream dies mid-file
  /// (#1520) — no libmpv signal distinguishes it from the real end, so
  /// position vs best-known duration is the only discriminator (see
  /// [classifyEofSignal]). Returns true when the signal was spurious and
  /// handled here (recovery started, or playback stays parked); false lets
  /// the caller run the normal completion flow.
  bool interceptEof(Player currentPlayer) {
    // Live EOFs have their own handling, an offline file can't lose its
    // stream, and in-flight transitions already produce expected EOFs that
    // the completion flow ignores — all fall through untouched.
    if (isLive || _isOffline()) return false;
    if (_transitionGate.transition != PlaybackTransition.idle) return false;
    // Already parked: swallow duplicate EOF signals without burning budget
    // or re-toasting.
    if (_parked) return true;

    final positionMs = currentPlayer.state.position.inMilliseconds;
    final playerDurationMs = currentPlayer.state.duration.inMilliseconds;
    final metadataDurationMs = _metadata().durationMs;
    final signal = classifyEofSignal(
      positionMs: positionMs,
      playerDurationMs: playerDurationMs,
      metadataDurationMs: metadataDurationMs,
    );
    if (signal != EofSignalClass.spurious) return false;

    appLogger.w(
      'Spurious EOF at ${positionMs}ms (playerDuration=${playerDurationMs}ms, '
      'metadataDuration=${metadataDurationMs}ms, '
      'cacheEnd=${currentPlayer.state.buffer.inMilliseconds}ms), '
      'recovery attempt ${_attempts + 1}/$maxAttempts',
    );

    if (_attempts >= maxAttempts) {
      _park();
      return true;
    }
    _attempts++;
    _baselineMs = positionMs;
    unawaited(_recover(currentPlayer));
    return true;
  }

  /// Leave playback parked on the dead stream: no auto-exit — the user keeps
  /// their place and the snackbar names the actions that actually rebuild the
  /// stream (play/seek route to [retry] while parked).
  void _park() {
    _parked = true;
    unawaited(_wakelock.setEnabled(false));
    showGlobalErrorSnackBar(t.messages.streamInterrupted);
  }

  /// Recover from a spurious EOF by re-running the full playback decision in
  /// place — the same path as the TV background suspend restore, because the
  /// failure is the same: the server-side stream is gone and only a fresh
  /// resolve replaces it (a seek-in-place lands inside the dead cache, and a
  /// same-session transcode seek can hit the reaped session).
  Future<void> _recover(Player currentPlayer) async {
    final outcome = await _reload(resumePosition: currentPlayer.state.position, reason: 'spurious EOF recovery');
    if (outcome == MediaReloadOutcome.failed) _park();
    // rejected/superseded: another flow owns the player and will commit
    // fresh media (clearing any park). opened: recovered — the budget
    // resets via 30s of progress or an item change.
  }

  /// Rebuild the dead stream after playback parked on a spurious EOF.
  /// User actions and the server-online monitor land here; these retries are
  /// always allowed and never consume the automatic budget.
  Future<void> retry({required String reason, Duration? resumePosition}) async {
    final currentPlayer = _player();
    if (currentPlayer == null || _transitionGate.transition != PlaybackTransition.idle) return;
    appLogger.i('Retrying dead-stream recovery ($reason)');
    _parked = false;
    final outcome = await _reload(
      resumePosition: resumePosition ?? currentPlayer.state.position,
      reason: 'stream recovery ($reason)',
    );
    if (outcome == MediaReloadOutcome.failed) _park();
  }
}
