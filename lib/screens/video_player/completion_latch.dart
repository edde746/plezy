/// What a position tick means for the end-of-video prompt flow.
enum CompletionLatchSignal {
  /// Nothing to do.
  none,

  /// Playback just entered the end-of-video window and the latch is clear —
  /// the caller should run its completion handling (which latches on
  /// success via [CompletionLatch.latch]).
  completed,

  /// Playback moved back out of the end region and the latch re-armed.
  rearmed,
}

/// End-of-video latch with rearm hysteresis for the Play Next / completion
/// prompts.
///
/// The prompt fires when playback enters the last [triggerWindowMs] of the
/// item and must not re-fire on every subsequent position tick — the latch
/// stays set while playback is parked inside the end region. It re-arms only
/// once playback moves back out past [rearmWindowMs] (a larger window, so a
/// position oscillating at the boundary can't flap), and never while a
/// prompt is visible or an auto-play countdown owns the screen.
///
/// Latching is the *caller's* move ([latch]), not [classifyPosition]'s: the
/// completion handler has its own bail-outs (live TV, in-flight media swap)
/// and a tick that bails must stay un-latched so the next tick retries.
class CompletionLatch {
  CompletionLatch({required this.triggerWindowMs, required this.rearmWindowMs})
    : assert(rearmWindowMs > triggerWindowMs, 'rearm window must exceed trigger window for hysteresis');

  /// Fire when within this many ms of the end.
  final int triggerWindowMs;

  /// Re-arm only after moving back out past this many ms from the end.
  final int rearmWindowMs;

  bool _triggered = false;

  /// Whether the end-of-video handling already ran for this approach to
  /// the end region.
  bool get triggered => _triggered;

  /// Mark the completion handling as done for this approach to the end.
  void latch() => _triggered = true;

  /// Clear unconditionally — new media was loaded.
  void reset() => _triggered = false;

  /// Re-arm so the prompt can fire again — but only when no prompt is
  /// visible and no auto-play countdown is running, so an active dialog is
  /// never clobbered. Callers decide *when* re-arming is safe (media
  /// reloaded, or playback moved back out of the end region).
  void rearmIfClear({required bool promptVisible, required bool countdownActive}) {
    if (_triggered && !promptVisible && !countdownActive) _triggered = false;
  }

  /// Classify a position tick against the trigger/rearm windows.
  CompletionLatchSignal classifyPosition({
    required int positionMs,
    required int durationMs,
    required bool promptVisible,
    required bool countdownActive,
  }) {
    if (durationMs <= 0) return CompletionLatchSignal.none;
    if (positionMs >= durationMs - triggerWindowMs) {
      if (!promptVisible && !_triggered) return CompletionLatchSignal.completed;
      return CompletionLatchSignal.none;
    }
    if (positionMs < durationMs - rearmWindowMs) {
      final wasLatched = _triggered;
      rearmIfClear(promptVisible: promptVisible, countdownActive: countdownActive);
      if (wasLatched && !_triggered) return CompletionLatchSignal.rearmed;
    }
    return CompletionLatchSignal.none;
  }
}
