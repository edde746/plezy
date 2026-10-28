/// A two-anchor fit for subtitle tracks whose timing drifts over the runtime.
///
/// mpv applies subtitle timestamps as `sourceTime * timestampMultiplier + delay`.
/// Given two subtitle cue times and the playback times those cues should match,
/// this solves the linear correction without modifying the subtitle file.
final class SubtitleSyncCalibration {
  const SubtitleSyncCalibration({required this.timestampMultiplier, required this.delayMs});

  static const minimumAnchorSpanSeconds = 60.0;
  static const minimumTimestampMultiplier = 0.8;
  static const maximumTimestampMultiplier = 1.25;
  static const minimumDelayMs = -60000;
  static const maximumDelayMs = 60000;

  final double timestampMultiplier;
  final int delayMs;

  factory SubtitleSyncCalibration.fromAnchors({
    required double subtitleTime1Seconds,
    required double playbackTime1Seconds,
    required double subtitleTime2Seconds,
    required double playbackTime2Seconds,
  }) {
    final values = [
      subtitleTime1Seconds,
      playbackTime1Seconds,
      subtitleTime2Seconds,
      playbackTime2Seconds,
    ];
    if (values.any((value) => !value.isFinite || value < 0)) {
      throw ArgumentError('Anchor times must be finite, non-negative values.');
    }

    final subtitleSpan = subtitleTime2Seconds - subtitleTime1Seconds;
    final playbackSpan = playbackTime2Seconds - playbackTime1Seconds;
    if (subtitleSpan < minimumAnchorSpanSeconds || playbackSpan < minimumAnchorSpanSeconds) {
      throw ArgumentError('Choose increasing anchors at least 60 seconds apart.');
    }

    final multiplier = playbackSpan / subtitleSpan;
    if (!multiplier.isFinite ||
        multiplier < minimumTimestampMultiplier ||
        multiplier > maximumTimestampMultiplier) {
      throw RangeError.range(
        multiplier,
        minimumTimestampMultiplier,
        maximumTimestampMultiplier,
        'timestampMultiplier',
      );
    }

    final delayMs = ((playbackTime1Seconds - multiplier * subtitleTime1Seconds) * 1000).round();
    if (delayMs < minimumDelayMs || delayMs > maximumDelayMs) {
      throw RangeError.range(delayMs, minimumDelayMs, maximumDelayMs, 'delayMs');
    }

    return SubtitleSyncCalibration(timestampMultiplier: multiplier, delayMs: delayMs);
  }
}
