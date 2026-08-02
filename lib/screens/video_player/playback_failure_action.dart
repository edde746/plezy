import '../../mpv/models.dart';

/// Highest fallback level the live-TV ladder will climb before giving up.
const int maxLiveFallbackLevel = 2;

/// What the player screen should do about one playback error.
enum PlaybackFailureAction {
  /// Server rejected the session with HTTP 500 — a bandwidth/transcoding limit.
  serverLimitDialog,

  /// Server could not read the file behind the item (HTTP 404).
  mediaUnreadableDialog,

  /// A live retry already owns the player and its error UI.
  ignore,

  /// Climb one rung of the live-TV fallback ladder.
  liveRetry,

  /// Live ladder is exhausted and its last retry failed.
  liveInterrupted,

  /// Show the raw player error and leave the route.
  fatal,
}

/// Decides what [cause] plus the statuses seen on this open mean for playback.
///
/// Pure so the policy is testable without a live player screen, mirroring
/// [runLiveStreamRetry]. [fatalHttpStatuses] is the set of
/// [fatalPlaybackHttpStatuses] entries the player's log stream reported.
///
/// Live TV deliberately diverges on 404: an HLS segment that has rolled off the
/// playlist, or a transcode session restarting under us, answers 404 mid-stream,
/// and the bounded ladder exists to ride that out. Only on-demand playback
/// treats 404 as terminal, where it does mean the file is unreadable. 500 stays
/// terminal for both — a limit rejection is not something a retry clears.
PlaybackFailureAction resolvePlaybackFailureAction({
  required String? cause,
  required Set<int> fatalHttpStatuses,
  required bool isLive,
  required bool liveRetrying,
  required int liveFallbackLevel,
  required bool liveRetryFailed,
}) {
  if (cause == PlayerError.serverHttp500 || fatalHttpStatuses.contains(500)) {
    return PlaybackFailureAction.serverLimitDialog;
  }

  if (!isLive && (cause == PlayerError.serverHttp404 || fatalHttpStatuses.contains(404))) {
    return PlaybackFailureAction.mediaUnreadableDialog;
  }

  if (isLive) {
    if (liveRetrying) return PlaybackFailureAction.ignore;
    if (liveFallbackLevel < maxLiveFallbackLevel) return PlaybackFailureAction.liveRetry;
    if (liveRetryFailed) return PlaybackFailureAction.liveInterrupted;
  }

  return PlaybackFailureAction.fatal;
}
