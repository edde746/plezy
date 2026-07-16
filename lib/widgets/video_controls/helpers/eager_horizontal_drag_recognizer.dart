import 'package:flutter/gestures.dart';

/// A [HorizontalDragGestureRecognizer] that claims the gesture arena the
/// moment a pointer lands on it, instead of waiting for horizontal movement
/// to exceed the touch slop.
///
/// Scrubbers must own any touch that starts on them (standard video-player
/// behavior). With slop-based recognition, competing recognizers higher in
/// the tree — the content-strip vertical drag or the long-press 2x-speed
/// handler — can win the arena and silently eat the gesture, making the
/// timeline appear to "stick" (#1302).
///
/// Tracks a single pointer: additional fingers placed on the scrubber
/// mid-drag are ignored rather than averaged into the drag.
class EagerHorizontalDragGestureRecognizer extends HorizontalDragGestureRecognizer {
  EagerHorizontalDragGestureRecognizer({super.debugOwner});

  int? _activePointer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_activePointer != null) return;
    _activePointer = event.pointer;
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    super.didStopTrackingLastPointer(pointer);
    _activePointer = null;
  }
}
