import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/watch_progress.dart';

void main() {
  group('isWatchedProgress', () {
    test('false for zero or negative duration', () {
      expect(isWatchedProgress(positionMs: 1000, durationMs: 0, threshold: 0.9), isFalse);
      expect(isWatchedProgress(positionMs: 1000, durationMs: -1, threshold: 0.9), isFalse);
    });

    test('exact threshold counts as watched', () {
      expect(isWatchedProgress(positionMs: 90, durationMs: 100, threshold: 0.9), isTrue);
    });

    test('just below threshold is not watched', () {
      expect(isWatchedProgress(positionMs: 89, durationMs: 100, threshold: 0.9), isFalse);
    });

    test('position past duration is watched', () {
      expect(isWatchedProgress(positionMs: 110, durationMs: 100, threshold: 0.9), isTrue);
    });

    test('zero position is not watched', () {
      expect(isWatchedProgress(positionMs: 0, durationMs: 100, threshold: 0.9), isFalse);
    });
  });
}
