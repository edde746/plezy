import '../../media/live_tv_support.dart';

/// Whether backgrounding may release the native video pipeline after its
/// grace period.
///
/// Retained live sessions stay paused with their player open because stopping
/// one would discard its capture buffer and time-shift position.
bool shouldSuspendPlayerForTvBackground({
  required bool isAndroid,
  required bool isTv,
  required bool isLive,
  required bool alreadySuspended,
}) {
  return isAndroid && isTv && !isLive && !alreadySuspended;
}

/// Whether the current TV live session must be closed before suspension.
bool shouldStopLiveSessionForTvBackground({required bool isTv, required LiveTvBackgroundPolicy? policy}) {
  return isTv && policy == LiveTvBackgroundPolicy.stopAndExit;
}
