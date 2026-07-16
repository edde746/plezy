import 'dart:math' as math;

/// Position must be within this many ms of the best-known duration for a
/// player EOF signal to count as the real end of the media.
///
/// Wide enough that a transcode container ending a couple of seconds short
/// of the server metadata duration still classifies as genuine, yet a
/// spurious EOF that slips through inside the window lands where servers
/// already mark the item watched (~90%), so the user outcome is unchanged.
/// The failure this guards against (#1520) parks playback minutes short.
const int spuriousEofToleranceMs = 10000;

/// How a player EOF signal should be interpreted.
enum EofSignalClass { genuine, spurious, unknown }

/// Classify a player EOF signal against the best-known media duration.
///
/// mpv reports a clean EOF when a network stream dies mid-file (a reaped
/// transcode session or an idle connection closed during a long pause), so
/// the signal alone cannot be trusted — position is the only discriminator.
///
/// [playerDurationMs] alone is not trustworthy either: on chunked transcode
/// streams the player's duration can be unknown or track the growing demuxer
/// cache (i.e. equal the parked position), making every spurious EOF look
/// genuine. [metadataDurationMs] (the server's item duration) anchors the
/// comparison; max() of the two also covers the opposite failure — server
/// metadata understating the real file length.
EofSignalClass classifyEofSignal({
  required int positionMs,
  required int playerDurationMs,
  required int? metadataDurationMs,
  int toleranceMs = spuriousEofToleranceMs,
}) {
  final effectiveDurationMs = math.max(playerDurationMs, metadataDurationMs ?? 0);
  if (effectiveDurationMs <= 0) return EofSignalClass.unknown;
  return positionMs >= effectiveDurationMs - toleranceMs ? EofSignalClass.genuine : EofSignalClass.spurious;
}

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
