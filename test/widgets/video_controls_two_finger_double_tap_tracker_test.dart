import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/video_controls/helpers/two_finger_double_tap_tracker.dart';

void main() {
  late DateTime now;
  late TwoFingerDoubleTapTracker tracker;

  void advance(Duration duration) {
    now = now.add(duration);
  }

  setUp(() {
    now = DateTime(2026);
    tracker = TwoFingerDoubleTapTracker(now: () => now);
  });

  test('detects two two-finger taps as double tap', () {
    tracker.pointerDown(1, const Offset(100, 100));
    tracker.pointerDown(2, const Offset(140, 100));
    expect(tracker.pointerUp(1, const Offset(100, 100)), isFalse);
    expect(tracker.pointerUp(2, const Offset(140, 100)), isFalse);

    advance(const Duration(milliseconds: 120));

    tracker.pointerDown(3, const Offset(102, 102));
    tracker.pointerDown(4, const Offset(142, 102));
    expect(tracker.pointerUp(3, const Offset(102, 102)), isFalse);
    expect(tracker.pointerUp(4, const Offset(142, 102)), isTrue);
  });

  test('does not detect one-finger double tap', () {
    tracker.pointerDown(1, const Offset(100, 100));
    expect(tracker.pointerUp(1, const Offset(100, 100)), isFalse);

    advance(const Duration(milliseconds: 120));

    tracker.pointerDown(2, const Offset(100, 100));
    expect(tracker.pointerUp(2, const Offset(100, 100)), isFalse);
  });

  test('movement invalidates a candidate two-finger tap', () {
    tracker.pointerDown(1, const Offset(100, 100));
    tracker.pointerDown(2, const Offset(140, 100));
    tracker.pointerMove(1, const Offset(140, 140));
    expect(tracker.pointerUp(1, const Offset(140, 140)), isFalse);
    expect(tracker.pointerUp(2, const Offset(140, 100)), isFalse);

    advance(const Duration(milliseconds: 120));

    tracker.pointerDown(3, const Offset(100, 100));
    tracker.pointerDown(4, const Offset(140, 100));
    expect(tracker.pointerUp(3, const Offset(100, 100)), isFalse);
    expect(tracker.pointerUp(4, const Offset(140, 100)), isFalse);
  });

  test('third finger invalidates a candidate two-finger tap', () {
    tracker.pointerDown(1, const Offset(100, 100));
    tracker.pointerDown(2, const Offset(140, 100));
    tracker.pointerDown(3, const Offset(180, 100));
    expect(tracker.pointerUp(1, const Offset(100, 100)), isFalse);
    expect(tracker.pointerUp(2, const Offset(140, 100)), isFalse);
    expect(tracker.pointerUp(3, const Offset(180, 100)), isFalse);

    advance(const Duration(milliseconds: 120));

    tracker.pointerDown(4, const Offset(100, 100));
    tracker.pointerDown(5, const Offset(140, 100));
    expect(tracker.pointerUp(4, const Offset(100, 100)), isFalse);
    expect(tracker.pointerUp(5, const Offset(140, 100)), isFalse);
  });
}
