import 'watch_progress.dart';

/// Position jump used by playback integrations to distinguish normal ticks
/// from seeks.
const playbackSeekDetectionThreshold = Duration(seconds: 5);

/// Mutable timing state shared by playback integrations.
///
/// This keeps seek classification, progress clamping, and watched-threshold
/// semantics identical without coupling backend-specific lifecycle calls.
class PlaybackTimeline {
  PlaybackTimeline({this.position = Duration.zero, this.duration, this.watchedThreshold = 0.9});

  Duration position;
  Duration? duration;
  double watchedThreshold;

  void reset({Duration position = Duration.zero, Duration? duration, double? watchedThreshold}) {
    this.position = position;
    this.duration = duration;
    if (watchedThreshold != null) this.watchedThreshold = watchedThreshold;
  }

  /// Stores [next] and reports whether it jumped farther than [seekThreshold].
  bool updatePosition(Duration next, {Duration seekThreshold = playbackSeekDetectionThreshold}) {
    final isSeek = (next - position).abs() > seekThreshold;
    position = next;
    return isSeek;
  }

  /// Stores a known duration. Zero/negative values remain unknown by default.
  bool updateDuration(Duration next, {bool ignoreNonPositive = true}) {
    if (ignoreNonPositive && next.inMilliseconds <= 0) return false;
    if (duration == next) return false;
    duration = next;
    return true;
  }

  bool get watchedThresholdReached {
    final total = duration;
    return total != null &&
        isWatchedProgress(
          positionMs: position.inMilliseconds,
          durationMs: total.inMilliseconds,
          threshold: watchedThreshold,
        );
  }

  double get progressPercent {
    final totalMs = duration?.inMilliseconds ?? 0;
    if (totalMs <= 0) return 0;
    return ((position.inMilliseconds / totalMs) * 100).clamp(0.0, 100.0);
  }
}
