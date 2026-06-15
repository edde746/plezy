import '../mpv/mpv.dart';

const restartBeforePreviousItemThreshold = Duration(seconds: 3);
const plexTranscodeSeekRangeStartTolerance = Duration(milliseconds: 500);
const plexTranscodeSeekRangeEndGuard = Duration(milliseconds: 500);
const plexTranscodeSeekNoopTolerance = Duration(seconds: 1);

enum PlexTranscodeSeekAction { nativeSeek, restartTranscode }

bool shouldRestartBeforePreviousItem(Duration position) {
  return position > restartBeforePreviousItemThreshold;
}

Duration clampSeekPosition(Player player, Duration position) {
  final duration = player.state.duration;
  if (position.isNegative) return Duration.zero;
  if (duration > Duration.zero && position > duration) return duration;
  return position;
}

/// Plex MKV-over-HTTP transcodes are only native-seeked inside ranges the
/// player reports as locally seekable. Anything outside those ranges needs a
/// server-offset transcode restart.
PlexTranscodeSeekAction resolvePlexTranscodeSeekAction({
  required Duration currentPosition,
  required Duration target,
  required List<BufferRange> bufferRanges,
  bool allowBufferedNativeSeek = true,
  Duration rangeStartTolerance = plexTranscodeSeekRangeStartTolerance,
  Duration rangeEndGuard = plexTranscodeSeekRangeEndGuard,
  Duration noopTolerance = plexTranscodeSeekNoopTolerance,
}) {
  final validRanges = bufferRanges.where((range) => range.end >= range.start).toList();
  if (allowBufferedNativeSeek &&
      _isInAnyBufferedSeekRange(target, validRanges, startTolerance: rangeStartTolerance, endGuard: rangeEndGuard)) {
    return PlexTranscodeSeekAction.nativeSeek;
  }

  if ((target - currentPosition).abs() <= noopTolerance) {
    return PlexTranscodeSeekAction.nativeSeek;
  }

  return PlexTranscodeSeekAction.restartTranscode;
}

bool _isInAnyBufferedSeekRange(
  Duration target,
  List<BufferRange> ranges, {
  required Duration startTolerance,
  required Duration endGuard,
}) {
  for (final range in ranges) {
    if (target >= range.start - startTolerance && target <= range.end - endGuard) return true;
  }
  return false;
}
