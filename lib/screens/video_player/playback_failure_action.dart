import '../../mpv/models.dart';

/// Highest fallback level the live-TV ladder will climb before giving up.
const int maxLiveFallbackLevel = 2;

/// What the player screen should do about one playback error.
enum PlaybackFailureAction {
  /// Server refused this account or connection with HTTP 403.
  playbackNotAllowedDialog,

  /// Server rejected the session with HTTP 500 — a bandwidth/transcoding limit.
  serverLimitDialog,

  /// Server could not read the file behind the item (HTTP 404).
  mediaUnreadableDialog,

  /// Server kept refusing the stream with HTTP 503 for the whole open phase.
  serverBusyDialog,

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
/// treats 404 as terminal, where it does mean the file is unreadable. 403 takes
/// the same split: on-demand it is a refusal of this account or connection
/// (#2510), while live TV has no observed 403 cause worth abandoning the bounded
/// ladder for. It outranks every other status latched on the same open — until
/// the server lets this account stream, what it says about the file or session
/// is moot. 500 stays terminal for both — a limit rejection is not something a
/// retry clears. 503 arrives only as the open-phase watchdog's cause tag (it
/// never latches into [fatalHttpStatuses]); by then the reconnect loop has had
/// its chances, so on-demand playback surfaces it while live TV keeps its
/// ladder.
///
/// An audio-output failure is checked first: the device stopped taking audio,
/// so a latched status or the live ladder would only re-open a stream into the
/// same dead output.
///
/// [PlayerError.openTimedOut] and [PlayerError.streamInitFailed] name no
/// status and no device fault, so they take the default path like any other
/// failed open: live TV climbs its ladder (a different stream may well decode),
/// on-demand playback is fatal.
PlaybackFailureAction resolvePlaybackFailureAction({
  required String? cause,
  required Set<int> fatalHttpStatuses,
  required bool isLive,
  required bool liveRetrying,
  required int liveFallbackLevel,
  required bool liveRetryFailed,
}) {
  if (cause == PlayerError.audioOutputFailed) return PlaybackFailureAction.fatal;

  if (!isLive && fatalHttpStatuses.contains(403)) return PlaybackFailureAction.playbackNotAllowedDialog;

  if (cause == PlayerError.serverHttp500 || fatalHttpStatuses.contains(500)) {
    return PlaybackFailureAction.serverLimitDialog;
  }

  if (!isLive && (cause == PlayerError.serverHttp404 || fatalHttpStatuses.contains(404))) {
    return PlaybackFailureAction.mediaUnreadableDialog;
  }

  if (!isLive && cause == PlayerError.serverHttp503) {
    return PlaybackFailureAction.serverBusyDialog;
  }

  if (isLive) {
    if (liveRetrying) return PlaybackFailureAction.ignore;
    if (liveFallbackLevel < maxLiveFallbackLevel) return PlaybackFailureAction.liveRetry;
    if (liveRetryFailed) return PlaybackFailureAction.liveInterrupted;
  }

  return PlaybackFailureAction.fatal;
}

/// Whether a failed on-demand open may move on to another version of the item
/// instead of surfacing [action].
///
/// Only failures that can belong to one file qualify: the server could not
/// read it (404), kept refusing its stream (503), or the open failed or timed
/// out with no status at all. A 403 refuses the account and a 500 is a server
/// limit, so every version would meet the same answer; an audio-output fault
/// or a core that failed to start is the device, not the file.
bool failureAllowsVersionFallback({required PlaybackFailureAction action, required String? cause}) {
  return switch (action) {
    PlaybackFailureAction.mediaUnreadableDialog || PlaybackFailureAction.serverBusyDialog => true,
    PlaybackFailureAction.fatal => cause != PlayerError.audioOutputFailed && cause != PlayerError.playerInitFailed,
    _ => false,
  };
}

/// The version to try after a failed open: the first, in list order, that this
/// item has not tried yet. Null once every version has been tried.
///
/// List order is the order the version picker shows, which is also the order
/// the server ranks them in.
int? nextVersionFallbackIndex({required int versionCount, required Set<int> attempted}) {
  for (var i = 0; i < versionCount; i++) {
    if (!attempted.contains(i)) return i;
  }
  return null;
}
