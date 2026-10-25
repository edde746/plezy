import '../../media/live_tv_support.dart';
import '../../models/livetv_capture_buffer.dart';
import '../../media/media_source_info.dart';

enum LiveTvSeekOutcome { opened, failed, superseded }

/// Shared seek/reopen path. Resolving a URL can await server-side work; only
/// its session and latest user intent may subsequently replace the player.
/// Recheck the moving window after resolution. A second expiration aborts
/// rather than opening a known-invalid target in a continually moving window.
Future<LiveTvSeekOutcome> runLiveTvSeek({
  required LiveTvTimeshiftSession session,
  required double? targetEpoch,
  required CaptureBuffer? Function() currentBuffer,
  required bool Function() isCurrent,
  required Future<bool> Function(LiveTvSeekRequest request) open,
  MediaSubtitleTrack? subtitleTrack,
}) async {
  for (var attempt = 0; attempt < 2; attempt++) {
    if (!isCurrent()) return LiveTvSeekOutcome.superseded;
    final buffer = currentBuffer();
    if (buffer == null) return LiveTvSeekOutcome.failed;
    final request = await session.resolveSeek(targetEpoch: targetEpoch, buffer: buffer, subtitleTrack: subtitleTrack);
    if (!isCurrent()) return LiveTvSeekOutcome.superseded;
    if (request == null) return LiveTvSeekOutcome.failed;
    final latest = currentBuffer();
    if (latest == null) return LiveTvSeekOutcome.failed;
    if (targetEpoch != null) {
      final effective = request.effectiveTargetEpoch;
      if (effective == null || session.seekWindow(latest)?.target(effective) != effective) continue;
    }
    final opened = await open(request);
    if (!isCurrent()) return LiveTvSeekOutcome.superseded;
    return opened ? LiveTvSeekOutcome.opened : LiveTvSeekOutcome.failed;
  }
  return LiveTvSeekOutcome.failed;
}
