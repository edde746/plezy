/// What a position tick means for the end-of-video prompt flow.
enum CompletionLatchSignal {
  /// Nothing to do.
  none,

  /// Playback moved back out of the end region and the latch re-armed.
  rearmed,
}

/// End-of-video latch with rearm hysteresis for the Play Next / completion
/// prompts.
///
/// Completion itself comes from the player's EOF signal. The latch prevents
/// that handling from re-running while playback is parked at EOF, and re-arms
/// only once playback moves back out past [rearmWindowMs] from the end. It
/// never re-arms while a prompt is visible or an auto-play countdown owns the
/// screen.
///
/// Latching is the *caller's* move ([latch]), not [classifyPosition]'s: the EOF
/// handler has its own bail-outs (live TV, in-flight media swap) and a signal
/// that bails must stay un-latched so the next EOF signal retries.
class CompletionLatch {
  CompletionLatch({required this.rearmWindowMs});

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
    if (positionMs < durationMs - rearmWindowMs) {
      final wasLatched = _triggered;
      rearmIfClear(promptVisible: promptVisible, countdownActive: countdownActive);
      if (wasLatched && !_triggered) return CompletionLatchSignal.rearmed;
    }
    return CompletionLatchSignal.none;
  }
}
