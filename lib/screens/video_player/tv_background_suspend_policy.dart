/// Whether backgrounding may release the native video pipeline after its
/// grace period.
///
/// Live TV deliberately stays paused with its player open: the tuned session
/// owns the capture buffer, so stopping it would lose both the time-shift
/// position and the user's paused/playing intent when playback is rebuilt.
bool shouldSuspendPlayerForTvBackground({
  required bool isAndroid,
  required bool isTv,
  required bool isLive,
  required bool alreadySuspended,
}) {
  return isAndroid && isTv && !isLive && !alreadySuspended;
}
