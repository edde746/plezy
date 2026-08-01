import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/stepped_seek.dart';

void main() {
  test('stepped multiplier preserves shared acceleration tiers', () {
    expect(steppedSeekMultiplier(0), 1.5);
    expect(steppedSeekMultiplier(5), 1.5);
    expect(steppedSeekMultiplier(6), 3.0);
    expect(steppedSeekMultiplier(15), 3.0);
    expect(steppedSeekMultiplier(16), 6.0);
    expect(steppedSeekMultiplier(30), 6.0);
    expect(steppedSeekMultiplier(31), 10.0);
  });

  test('rapid steps accumulate and debounce into one seek', () {
    fakeAsync((async) {
      var position = const Duration(seconds: 20);
      final seeks = <Duration>[];
      final accumulator = DebouncedSeekAccumulator(
        currentPosition: () => position,
        duration: () => const Duration(minutes: 2),
        seek: seeks.add,
      );

      accumulator.seekBy(const Duration(seconds: 10));
      accumulator.seekBy(const Duration(seconds: 15));
      accumulator.seekBy(const Duration(seconds: -5));

      expect(accumulator.pendingPosition, const Duration(seconds: 40));
      async.elapse(const Duration(milliseconds: 799));
      expect(seeks, isEmpty);
      async.elapse(const Duration(milliseconds: 1));
      expect(seeks, [const Duration(seconds: 40)]);

      // A slow player still reports the old position. The next burst must use
      // the pinned target rather than silently dropping the committed seek.
      accumulator.seekBy(const Duration(seconds: 10));
      accumulator.flush();
      expect(seeks, [const Duration(seconds: 40), const Duration(seconds: 50)]);

      position = const Duration(seconds: 50);
      async.elapse(const Duration(seconds: 2));
      expect(accumulator.pendingPosition, isNull);
      accumulator.dispose();
    });
  });

  test('clamps targets and cancel prevents a pending seek', () {
    fakeAsync((async) {
      final seeks = <Duration>[];
      final accumulator = DebouncedSeekAccumulator(
        currentPosition: () => const Duration(seconds: 5),
        duration: () => const Duration(seconds: 30),
        seek: seeks.add,
      );

      accumulator.seekBy(const Duration(minutes: 1));
      expect(accumulator.pendingPosition, const Duration(seconds: 30));
      accumulator.cancel();
      async.elapse(const Duration(seconds: 1));
      expect(seeks, isEmpty);
      expect(accumulator.pendingPosition, isNull);
      accumulator.dispose();
    });
  });
}
