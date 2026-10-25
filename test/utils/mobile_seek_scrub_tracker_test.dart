import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/video_controls/helpers/mobile_seek_scrub_tracker.dart';

void main() {
  const size = Size(400, 300);

  group('seekScrubSpanFor', () {
    test('returns zero without a duration', () {
      expect(seekScrubSpanFor(Duration.zero), Duration.zero);
      expect(seekScrubSpanFor(const Duration(seconds: -5)), Duration.zero);
    });

    test('scales a quarter of the running time', () {
      expect(seekScrubSpanFor(const Duration(minutes: 10)), const Duration(seconds: 150));
    });

    test('clamps short media up and long media down', () {
      expect(seekScrubSpanFor(const Duration(minutes: 1)), const Duration(seconds: 20));
      expect(seekScrubSpanFor(const Duration(hours: 2)), const Duration(seconds: 300));
      expect(seekScrubSpanFor(const Duration(minutes: 40)), const Duration(seconds: 300));
    });
  });

  group('MobileSeekScrubTracker', () {
    MobileSeekScrubTracker tracker() => MobileSeekScrubTracker(slop: 10, horizontalDominance: 1.5);

    test('declines a gesture the caller disallowed', () {
      final t = tracker();
      expect(t.pointerDown(1, const Offset(10, 10), size, allowed: false).type, MobileSeekScrubEventType.none);
      expect(t.pointerMove(1, const Offset(200, 10)).type, MobileSeekScrubEventType.none);
      expect(t.isActive, isFalse);
    });

    test('activates on horizontal travel and reports width fraction', () {
      final t = tracker();
      expect(t.pointerDown(1, const Offset(100, 150), size).type, MobileSeekScrubEventType.candidate);

      final activated = t.pointerMove(1, const Offset(180, 150));
      expect(activated.type, MobileSeekScrubEventType.activated);
      expect(activated.deltaFraction, closeTo(0.2, 1e-9));

      final update = t.pointerMove(1, const Offset(20, 150));
      expect(update.type, MobileSeekScrubEventType.update);
      expect(update.deltaFraction, closeTo(-0.2, 1e-9));
      expect(t.isActive, isTrue);
    });

    test('waits below the slop threshold', () {
      final t = tracker();
      t.pointerDown(1, const Offset(100, 150), size);
      expect(t.pointerMove(1, const Offset(105, 150)).type, MobileSeekScrubEventType.none);
      expect(t.isActive, isFalse);
    });

    test('cancels when the drag leans vertical so the edge swipes keep it', () {
      final t = tracker();
      t.pointerDown(1, const Offset(100, 100), size);
      final event = t.pointerMove(1, const Offset(105, 80));
      expect(event.type, MobileSeekScrubEventType.cancelled);
      expect(event.wasActive, isFalse);
      expect(t.isActive, isFalse);
    });

    test('keeps waiting while the axis is ambiguous', () {
      final t = tracker();
      t.pointerDown(1, const Offset(100, 100), size);
      expect(t.pointerMove(1, const Offset(112, 110)).type, MobileSeekScrubEventType.none);
      expect(t.isActive, isFalse);
      // Once it clearly leans horizontal the same gesture becomes a seek.
      expect(t.pointerMove(1, const Offset(160, 112)).type, MobileSeekScrubEventType.activated);
    });

    test('commits on release with the travel at lift-off', () {
      final t = tracker();
      t.pointerDown(1, const Offset(100, 150), size);
      t.pointerMove(1, const Offset(200, 150));
      final ended = t.pointerUp(1, const Offset(300, 150));
      expect(ended.type, MobileSeekScrubEventType.ended);
      expect(ended.deltaFraction, closeTo(0.5, 1e-9));
      expect(t.isActive, isFalse);
    });

    test('a release that never activated reports nothing', () {
      final t = tracker();
      t.pointerDown(1, const Offset(100, 150), size);
      expect(t.pointerUp(1, const Offset(104, 152)).type, MobileSeekScrubEventType.none);
    });

    test('cancels with wasActive so the caller can tell a live drag happened', () {
      final t = tracker();
      t.pointerDown(1, const Offset(100, 150), size);
      t.pointerMove(1, const Offset(200, 150));
      final event = t.cancel();
      expect(event.type, MobileSeekScrubEventType.cancelled);
      expect(event.wasActive, isTrue);
    });

    test('a second finger cancels and blocks until every finger is up', () {
      final t = tracker();
      t.pointerDown(1, const Offset(100, 150), size);
      t.pointerMove(1, const Offset(200, 150));

      final chorded = t.pointerDown(2, const Offset(300, 150), size);
      expect(chorded.type, MobileSeekScrubEventType.cancelled);
      expect(chorded.wasActive, isTrue);

      // Still blocked while the first finger is down.
      expect(t.pointerDown(3, const Offset(100, 150), size).type, MobileSeekScrubEventType.none);

      t.pointerUp(1, const Offset(100, 150));
      t.pointerUp(2, const Offset(300, 150));
      t.pointerUp(3, const Offset(100, 150));
      // Every finger up: the surface accepts a new gesture.
      expect(t.pointerDown(4, const Offset(100, 150), size).type, MobileSeekScrubEventType.candidate);
    });

    test('ignores extra pointers once one is being tracked', () {
      final t = tracker();
      t.pointerDown(1, const Offset(100, 150), size);
      // A second down cancels the tracked gesture rather than averaging pointers.
      expect(t.pointerDown(2, const Offset(380, 150), size).type, MobileSeekScrubEventType.cancelled);
      expect(t.pointerMove(2, const Offset(20, 150)).type, MobileSeekScrubEventType.none);
    });

    test('a degenerate width cannot produce a fraction', () {
      final t = tracker();
      t.pointerDown(1, const Offset(0, 10), const Size(0, 100));
      final event = t.pointerMove(1, const Offset(200, 10));
      expect(event.type, MobileSeekScrubEventType.none);
    });
  });
}
