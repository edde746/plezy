import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/playback_timeline.dart';

void main() {
  test('seek detection uses one shared strict threshold', () {
    final timeline = PlaybackTimeline();

    expect(timeline.updatePosition(const Duration(seconds: 5)), isFalse);
    expect(timeline.updatePosition(const Duration(seconds: 11)), isTrue);
    expect(timeline.position, const Duration(seconds: 11));
  });

  test('watched threshold accepts the exact boundary', () {
    final timeline = PlaybackTimeline(duration: const Duration(seconds: 100), watchedThreshold: 0.9);

    timeline.updatePosition(const Duration(seconds: 90));

    expect(timeline.watchedThresholdReached, isTrue);
  });

  test('unknown duration is not watched and reports zero progress', () {
    final timeline = PlaybackTimeline(position: const Duration(seconds: 30));

    expect(timeline.updateDuration(Duration.zero), isFalse);
    expect(timeline.watchedThresholdReached, isFalse);
    expect(timeline.progressPercent, 0);
  });

  test('progress is clamped and reset clears prior playback timing', () {
    final timeline = PlaybackTimeline(position: const Duration(seconds: 120), duration: const Duration(seconds: 100));

    expect(timeline.progressPercent, 100);

    timeline.reset(watchedThreshold: 0.8);

    expect(timeline.position, Duration.zero);
    expect(timeline.duration, isNull);
    expect(timeline.watchedThreshold, 0.8);
    expect(timeline.watchedThresholdReached, isFalse);
  });
}
