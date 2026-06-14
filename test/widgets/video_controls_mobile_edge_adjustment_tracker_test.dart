import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/video_controls/helpers/mobile_edge_adjustment_tracker.dart';

void main() {
  const size = Size(1000, 600);

  test('classifies narrow left and right edge zones', () {
    expect(
      mobileEdgeAdjustmentZoneForPosition(position: const Offset(40, 300), size: size),
      MobileEdgeAdjustmentSide.left,
    );
    expect(
      mobileEdgeAdjustmentZoneForPosition(position: const Offset(960, 300), size: size),
      MobileEdgeAdjustmentSide.right,
    );
    expect(mobileEdgeAdjustmentZoneForPosition(position: const Offset(200, 300), size: size), isNull);
  });

  test('respects top and bottom exclusion bands', () {
    expect(mobileEdgeAdjustmentZoneForPosition(position: const Offset(40, 20), size: size), isNull);
    expect(mobileEdgeAdjustmentZoneForPosition(position: const Offset(960, 580), size: size), isNull);
  });

  test('activates only after vertically dominant movement', () {
    final tracker = MobileEdgeAdjustmentTracker(verticalSlop: 10, verticalDominance: 1.5);
    expect(tracker.pointerDown(1, const Offset(40, 300), size).type, MobileEdgeAdjustmentEventType.candidate);

    expect(tracker.pointerMove(1, const Offset(43, 292)).type, MobileEdgeAdjustmentEventType.none);

    final event = tracker.pointerMove(1, const Offset(44, 280));
    expect(event.type, MobileEdgeAdjustmentEventType.activated);
    expect(event.side, MobileEdgeAdjustmentSide.left);
    expect(event.deltaFraction, greaterThan(0));
  });

  test('cancels horizontal movement from the edge', () {
    final tracker = MobileEdgeAdjustmentTracker(verticalSlop: 10, verticalDominance: 1.5);
    tracker.pointerDown(1, const Offset(40, 300), size);

    final event = tracker.pointerMove(1, const Offset(70, 304));
    expect(event.type, MobileEdgeAdjustmentEventType.cancelled);
    expect(event.wasActive, isFalse);
    expect(tracker.isActive, isFalse);
  });

  test('upward movement increases and downward movement decreases', () {
    final tracker = MobileEdgeAdjustmentTracker(verticalSlop: 10, verticalDominance: 1.5);
    tracker.pointerDown(1, const Offset(960, 300), size);

    final up = tracker.pointerMove(1, const Offset(958, 250));
    expect(up.type, MobileEdgeAdjustmentEventType.activated);
    expect(up.deltaFraction, greaterThan(0));

    final down = tracker.pointerMove(1, const Offset(958, 350));
    expect(down.type, MobileEdgeAdjustmentEventType.update);
    expect(down.deltaFraction, lessThan(0));
  });

  test('second pointer cancels tracking', () {
    final tracker = MobileEdgeAdjustmentTracker(verticalSlop: 10, verticalDominance: 1.5);
    tracker.pointerDown(1, const Offset(40, 300), size);

    final event = tracker.pointerDown(2, const Offset(80, 300), size);
    expect(event.type, MobileEdgeAdjustmentEventType.cancelled);
    expect(event.wasActive, isFalse);
    expect(tracker.isActive, isFalse);
  });

  test('does not reactivate after multitouch cancel until all pointers lift', () {
    final tracker = MobileEdgeAdjustmentTracker(verticalSlop: 10, verticalDominance: 1.5);
    tracker.pointerDown(1, const Offset(40, 300), size);
    tracker.pointerDown(2, const Offset(80, 300), size);

    expect(tracker.pointerDown(3, const Offset(40, 300), size).type, MobileEdgeAdjustmentEventType.none);
    expect(tracker.pointerUp(1, const Offset(40, 300)).type, MobileEdgeAdjustmentEventType.none);
    expect(tracker.pointerDown(4, const Offset(40, 300), size).type, MobileEdgeAdjustmentEventType.none);
    expect(tracker.pointerUp(2, const Offset(80, 300)).type, MobileEdgeAdjustmentEventType.none);
    expect(tracker.pointerUp(3, const Offset(40, 300)).type, MobileEdgeAdjustmentEventType.none);
    expect(tracker.pointerUp(4, const Offset(40, 300)).type, MobileEdgeAdjustmentEventType.none);

    expect(tracker.pointerDown(5, const Offset(40, 300), size).type, MobileEdgeAdjustmentEventType.candidate);
  });

  test('activated cancel reports active cancellation', () {
    final tracker = MobileEdgeAdjustmentTracker(verticalSlop: 10, verticalDominance: 1.5);
    tracker.pointerDown(1, const Offset(40, 300), size);
    expect(tracker.pointerMove(1, const Offset(40, 260)).type, MobileEdgeAdjustmentEventType.activated);

    final event = tracker.cancel();
    expect(event.type, MobileEdgeAdjustmentEventType.cancelled);
    expect(event.wasActive, isTrue);
  });

  test('candidate pointer up without activation is ignored', () {
    final tracker = MobileEdgeAdjustmentTracker(verticalSlop: 10, verticalDominance: 1.5);
    tracker.pointerDown(1, const Offset(40, 300), size);

    expect(tracker.pointerUp(1, const Offset(42, 302)).type, MobileEdgeAdjustmentEventType.none);
  });
}
