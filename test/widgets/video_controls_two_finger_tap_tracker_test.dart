import 'package:flutter/gestures.dart' show kDoubleTapTimeout, kDoubleTapTouchSlop;
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/video_controls/helpers/two_finger_tap_tracker.dart';

/// A two-finger tap toggles playback with the chrome left down (#1505), and it
/// fires the moment the chord resolves — pausing late is pausing on the wrong
/// frame, so there is no pairing window to wait out.
///
/// The tracker owns the whole accept/reject decision, so it must take a
/// deliberate two-finger tap and refuse everything a viewer does by accident: a
/// pinch, a drag, a palm, two fingers resting on the screen.
void main() {
  late DateTime now;
  late TwoFingerTapTracker tracker;

  void advance(Duration duration) {
    now = now.add(duration);
  }

  setUp(() {
    now = DateTime(2026);
    tracker = TwoFingerTapTracker(now: () => now);
  });

  test('detects a two-finger tap on the last lift', () {
    tracker.pointerDown(1, const Offset(100, 100));
    tracker.pointerDown(2, const Offset(140, 100));

    expect(tracker.pointerUp(1, const Offset(100, 100)), isFalse, reason: 'one finger is still down');
    expect(tracker.pointerUp(2, const Offset(140, 100)), isTrue);
  });

  test('every two-finger tap reports independently, however fast they come', () {
    for (var pointer = 1; pointer <= 7; pointer += 2) {
      tracker.pointerDown(pointer, const Offset(100, 100));
      tracker.pointerDown(pointer + 1, const Offset(140, 100));
      expect(tracker.pointerUp(pointer, const Offset(100, 100)), isFalse);
      expect(
        tracker.pointerUp(pointer + 1, const Offset(140, 100)),
        isTrue,
        reason: 'tap $pointer must stand alone — no pair is ever swallowed',
      );
      advance(const Duration(milliseconds: 20));
    }
  });

  test('does not detect a one-finger tap', () {
    tracker.pointerDown(1, const Offset(100, 100));
    expect(tracker.pointerUp(1, const Offset(100, 100)), isFalse);

    advance(const Duration(milliseconds: 120));

    tracker.pointerDown(2, const Offset(100, 100));
    expect(tracker.pointerUp(2, const Offset(100, 100)), isFalse);
  });

  test('movement beyond the slop invalidates the tap', () {
    tracker.pointerDown(1, const Offset(100, 100));
    tracker.pointerDown(2, const Offset(140, 100));
    tracker.pointerMove(1, const Offset(140, 140));

    expect(tracker.pointerUp(1, const Offset(140, 140)), isFalse);
    expect(tracker.pointerUp(2, const Offset(140, 100)), isFalse);
  });

  test('movement within the slop still taps', () {
    const drift = Offset(100 + kDoubleTapTouchSlop / 2, 100);
    tracker.pointerDown(1, const Offset(100, 100));
    tracker.pointerDown(2, const Offset(140, 100));
    tracker.pointerMove(1, drift);

    expect(tracker.pointerUp(1, drift), isFalse);
    expect(tracker.pointerUp(2, const Offset(140, 100)), isTrue);
  });

  test('a pinch is not a tap even when both fingers land back near their start', () {
    tracker.pointerDown(1, const Offset(100, 100));
    tracker.pointerDown(2, const Offset(140, 100));
    tracker.pointerMove(1, const Offset(40, 100));
    tracker.pointerMove(2, const Offset(200, 100));
    tracker.pointerMove(1, const Offset(100, 100));
    tracker.pointerMove(2, const Offset(140, 100));

    expect(tracker.pointerUp(1, const Offset(100, 100)), isFalse);
    expect(tracker.pointerUp(2, const Offset(140, 100)), isFalse);
  });

  test('a third finger invalidates the tap', () {
    tracker.pointerDown(1, const Offset(100, 100));
    tracker.pointerDown(2, const Offset(140, 100));
    tracker.pointerDown(3, const Offset(180, 100));

    expect(tracker.pointerUp(1, const Offset(100, 100)), isFalse);
    expect(tracker.pointerUp(2, const Offset(140, 100)), isFalse);
    expect(tracker.pointerUp(3, const Offset(180, 100)), isFalse);
  });

  test('two fingers resting past the tap timeout do not tap', () {
    tracker.pointerDown(1, const Offset(100, 100));
    tracker.pointerDown(2, const Offset(140, 100));

    advance(kDoubleTapTimeout + const Duration(milliseconds: 1));

    expect(tracker.pointerUp(1, const Offset(100, 100)), isFalse);
    expect(tracker.pointerUp(2, const Offset(140, 100)), isFalse);
  });

  test('the timeout runs from the earliest finger down, not the latest', () {
    tracker.pointerDown(1, const Offset(100, 100));
    advance(kDoubleTapTimeout - const Duration(milliseconds: 20));
    tracker.pointerDown(2, const Offset(140, 100));
    advance(const Duration(milliseconds: 40));

    expect(tracker.pointerUp(1, const Offset(100, 100)), isFalse);
    expect(tracker.pointerUp(2, const Offset(140, 100)), isFalse);
  });

  test('a cancelled pointer invalidates the tap', () {
    tracker.pointerDown(1, const Offset(100, 100));
    tracker.pointerDown(2, const Offset(140, 100));
    tracker.pointerCancel(1);

    expect(tracker.pointerUp(2, const Offset(140, 100)), isFalse);
  });

  test('reports the chord while two fingers are down', () {
    expect(tracker.isChordActive, isFalse);

    tracker.pointerDown(1, const Offset(100, 100));
    expect(tracker.isChordActive, isFalse, reason: 'one finger is not a chord');

    tracker.pointerDown(2, const Offset(140, 100));
    expect(tracker.isChordActive, isTrue);

    tracker.pointerUp(1, const Offset(100, 100));
    expect(tracker.isChordActive, isTrue, reason: 'the candidate outlives the first lift');

    tracker.pointerUp(2, const Offset(140, 100));
    expect(tracker.isChordActive, isFalse);
  });
}
