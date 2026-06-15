import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter/gestures.dart' show kTouchSlop;

import '../widgets/mobile_skip_zones.dart';

enum MobileEdgeAdjustmentSide { left, right }

enum MobileEdgeAdjustmentEventType { none, candidate, activated, update, ended, cancelled }

class MobileEdgeAdjustmentEvent {
  const MobileEdgeAdjustmentEvent._(this.type, {this.side, this.deltaFraction = 0.0, this.wasActive = false});

  const MobileEdgeAdjustmentEvent.none() : this._(MobileEdgeAdjustmentEventType.none);

  const MobileEdgeAdjustmentEvent.candidate(MobileEdgeAdjustmentSide side)
    : this._(MobileEdgeAdjustmentEventType.candidate, side: side);

  const MobileEdgeAdjustmentEvent.activated(MobileEdgeAdjustmentSide side, double deltaFraction)
    : this._(MobileEdgeAdjustmentEventType.activated, side: side, deltaFraction: deltaFraction);

  const MobileEdgeAdjustmentEvent.update(MobileEdgeAdjustmentSide side, double deltaFraction)
    : this._(MobileEdgeAdjustmentEventType.update, side: side, deltaFraction: deltaFraction);

  const MobileEdgeAdjustmentEvent.ended(MobileEdgeAdjustmentSide side, double deltaFraction)
    : this._(MobileEdgeAdjustmentEventType.ended, side: side, deltaFraction: deltaFraction);

  const MobileEdgeAdjustmentEvent.cancelled(MobileEdgeAdjustmentSide? side, {bool wasActive = false})
    : this._(MobileEdgeAdjustmentEventType.cancelled, side: side, wasActive: wasActive);

  final MobileEdgeAdjustmentEventType type;
  final MobileEdgeAdjustmentSide? side;
  final double deltaFraction;
  final bool wasActive;
}

double mobileEdgeAdjustmentZoneWidth(Size size) {
  final preferredWidth = math.max(48.0, math.min(size.width * 0.14, 96.0));
  return math.min(preferredWidth, size.width / 2);
}

MobileEdgeAdjustmentSide? mobileEdgeAdjustmentZoneForPosition({required Offset position, required Size size}) {
  final dimensions = mobileSkipZoneDimensions(size);
  final inVerticalRange = position.dy > dimensions.topExclude && position.dy < (size.height - dimensions.bottomExclude);
  if (!inVerticalRange) return null;

  final edgeWidth = mobileEdgeAdjustmentZoneWidth(size);
  if (position.dx < edgeWidth) return MobileEdgeAdjustmentSide.left;
  if (position.dx > size.width - edgeWidth) return MobileEdgeAdjustmentSide.right;
  return null;
}

class MobileEdgeAdjustmentTracker {
  MobileEdgeAdjustmentTracker({this.verticalSlop = kTouchSlop, this.verticalDominance = 1.5});

  final double verticalSlop;
  final double verticalDominance;

  final Set<int> _activePointers = <int>{};
  int? _trackedPointer;
  Offset? _startPosition;
  Size? _size;
  MobileEdgeAdjustmentSide? _side;
  bool _active = false;
  bool _blockedUntilAllPointersUp = false;

  bool get isActive => _active;
  MobileEdgeAdjustmentSide? get side => _side;

  MobileEdgeAdjustmentEvent pointerDown(int pointer, Offset position, Size size) {
    _activePointers.add(pointer);
    if (_blockedUntilAllPointersUp) return const MobileEdgeAdjustmentEvent.none();
    if (_activePointers.length > 1) return _cancelTracking(clearPointers: false, blockUntilAllPointersUp: true);
    if (_trackedPointer != null) return const MobileEdgeAdjustmentEvent.none();

    final side = mobileEdgeAdjustmentZoneForPosition(position: position, size: size);
    if (side == null) return const MobileEdgeAdjustmentEvent.none();

    _trackedPointer = pointer;
    _startPosition = position;
    _size = size;
    _side = side;
    _active = false;
    return MobileEdgeAdjustmentEvent.candidate(side);
  }

  MobileEdgeAdjustmentEvent pointerMove(int pointer, Offset position) {
    if (pointer != _trackedPointer) return const MobileEdgeAdjustmentEvent.none();
    final start = _startPosition;
    final size = _size;
    final side = _side;
    if (start == null || size == null || side == null) return const MobileEdgeAdjustmentEvent.none();

    final delta = position - start;
    final absDx = delta.dx.abs();
    final absDy = delta.dy.abs();

    if (!_active) {
      if (absDx >= verticalSlop && absDx > absDy * verticalDominance) {
        return _cancelTracking(clearPointers: false, blockUntilAllPointersUp: true);
      }
      if (absDy < verticalSlop) return const MobileEdgeAdjustmentEvent.none();
      if (absDy <= absDx * verticalDominance) {
        return _cancelTracking(clearPointers: false, blockUntilAllPointersUp: true);
      }
      _active = true;
      return MobileEdgeAdjustmentEvent.activated(side, _deltaFraction(position));
    }

    return MobileEdgeAdjustmentEvent.update(side, _deltaFraction(position));
  }

  MobileEdgeAdjustmentEvent pointerUp(int pointer, Offset position) {
    _activePointers.remove(pointer);
    if (_activePointers.isEmpty) _blockedUntilAllPointersUp = false;
    if (pointer != _trackedPointer) return const MobileEdgeAdjustmentEvent.none();

    final side = _side;
    final wasActive = _active;
    final deltaFraction = wasActive ? _deltaFraction(position) : 0.0;
    _resetTracking(clearPointers: false);

    if (!wasActive || side == null) return const MobileEdgeAdjustmentEvent.none();
    return MobileEdgeAdjustmentEvent.ended(side, deltaFraction);
  }

  MobileEdgeAdjustmentEvent pointerCancel(int pointer) {
    _activePointers.remove(pointer);
    if (_activePointers.isEmpty) _blockedUntilAllPointersUp = false;
    if (pointer != _trackedPointer) return const MobileEdgeAdjustmentEvent.none();
    return _cancelTracking(clearPointers: false, blockUntilAllPointersUp: _activePointers.isNotEmpty);
  }

  MobileEdgeAdjustmentEvent cancel() => _cancelTracking(clearPointers: true, blockUntilAllPointersUp: false);

  MobileEdgeAdjustmentEvent _cancelTracking({required bool clearPointers, required bool blockUntilAllPointersUp}) {
    final side = _side;
    final hadTracking = _trackedPointer != null;
    final wasActive = _active;
    _resetTracking(clearPointers: clearPointers);
    if (blockUntilAllPointersUp && _activePointers.isNotEmpty) _blockedUntilAllPointersUp = true;
    if (!hadTracking) return const MobileEdgeAdjustmentEvent.none();
    return MobileEdgeAdjustmentEvent.cancelled(side, wasActive: wasActive);
  }

  double _deltaFraction(Offset position) {
    final start = _startPosition;
    final size = _size;
    if (start == null || size == null) return 0.0;

    final dimensions = mobileSkipZoneDimensions(size);
    final activeHeight = math.max(1.0, size.height - dimensions.topExclude - dimensions.bottomExclude);
    return (start.dy - position.dy) / activeHeight;
  }

  void _resetTracking({required bool clearPointers}) {
    _trackedPointer = null;
    _startPosition = null;
    _size = null;
    _side = null;
    _active = false;
    if (clearPointers) {
      _activePointers.clear();
      _blockedUntilAllPointersUp = false;
    }
  }
}
