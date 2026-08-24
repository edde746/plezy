import 'dart:async';

import '../../mpv/mpv.dart';

/// What the restore path needs from a consumed TV background suspend: the
/// latched position and track selections captured before `stop()` reset the
/// native player state.
typedef TvBackgroundRestoreSnapshot = ({
  Duration? position,
  AudioTrack? audioTrack,
  SubtitleTrack? subtitleTrack,
  SubtitleTrack? secondarySubtitleTrack,
});

/// State of the Android TV background player suspend (#1911): the grace
/// timer armed on backgrounding, the suspended latch, and the
/// position/track snapshot the restore reload reads after the native state
/// is gone.
///
/// The pure eligibility predicates live in tv_background_suspend_policy.dart;
/// the lifecycle part owns orchestration. This object guarantees the latch
/// invariants: the four snapshot fields are set, cleared, and consumed
/// together, and [consumeForRestore] drops the suspended latch before the
/// caller rebuilds a session — so the bounded stop-report redelivery can
/// never report the rebuilt session stopped.
class TvBackgroundSuspendState {
  /// How long a pause may sit backgrounded before the native pipeline is
  /// released on TV hardware with shared decoders.
  static const Duration playerSuspendGrace = Duration(seconds: 30);

  /// Redelivery schedule for the suspend-time stopped report. Standby entry
  /// can drop Wi-Fi into power-save and stall exactly that connect, and
  /// mutations deliberately never fail over, so the terminal report gets a
  /// bounded retry loop instead of a single fail-fast attempt.
  static const Duration stopReportRetryDelay = Duration(seconds: 10);
  static const int stopReportMaxRetries = 5;

  Timer? _graceTimer;
  bool _suspended = false;
  Duration? _position;
  AudioTrack? _audioTrack;
  SubtitleTrack? _subtitleTrack;
  SubtitleTrack? _secondarySubtitleTrack;

  /// Whether the player is currently suspended for TV background.
  bool get suspended => _suspended;

  /// (Re-)arm the grace timer; [onExpired] runs once when the grace elapses
  /// while still backgrounded.
  void armGrace(void Function() onExpired) {
    _graceTimer?.cancel();
    _graceTimer = Timer(playerSuspendGrace, () {
      _graceTimer = null;
      onExpired();
    });
  }

  void cancelGrace() {
    _graceTimer?.cancel();
    _graceTimer = null;
  }

  /// Latch the pre-stop player state and mark the suspend standing.
  void latch({
    required Duration position,
    required AudioTrack? audioTrack,
    required SubtitleTrack? subtitleTrack,
    required SubtitleTrack? secondarySubtitleTrack,
  }) {
    _position = position;
    _audioTrack = audioTrack;
    _subtitleTrack = subtitleTrack;
    _secondarySubtitleTrack = secondarySubtitleTrack;
    _suspended = true;
  }

  /// Roll the latch back — the native stop failed, so the player still holds
  /// its state and no restore will run.
  void clear() {
    _suspended = false;
    _position = null;
    _audioTrack = null;
    _subtitleTrack = null;
    _secondarySubtitleTrack = null;
  }

  /// Drop the suspended latch and hand the snapshot to the restore reload.
  /// Clearing [suspended] first is load-bearing: a late stop-report retry
  /// re-checks it and must not report the rebuilt session stopped.
  TvBackgroundRestoreSnapshot consumeForRestore() {
    final snapshot = (
      position: _position,
      audioTrack: _audioTrack,
      subtitleTrack: _subtitleTrack,
      secondarySubtitleTrack: _secondarySubtitleTrack,
    );
    clear();
    return snapshot;
  }

  void dispose() {
    cancelGrace();
  }
}
