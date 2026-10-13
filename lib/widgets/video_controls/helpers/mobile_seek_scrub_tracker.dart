import 'dart:ui' show Offset, Size;

import 'package:flutter/gestures.dart' show kTouchSlop;

/// How far a full-width swipe scrubs.
///
/// A quarter of the running time keeps a long film feeling proportional, and
/// the clamps stop a two-hour movie from jumping half an hour on one gesture
/// while keeping a short clip from being un-draggable.
Duration seekScrubSpanFor(Duration duration) {
  if (duration <= Duration.zero) return Duration.zero;
  final quarter = (duration.inMilliseconds * 0.25).round();
  return Duration(milliseconds: quarter.clamp(20000, 300000));
}

enum MobileSeekScrubEventType { none, candidate, activated, update, ended, cancelled }

class MobileSeekScrubEvent {
  const MobileSeekScrubEvent._(this.type, {this.deltaFraction = 0.0, this.wasActive = false});

  const MobileSeekScrubEvent.none() : this._(MobileSeekScrubEventType.none);

  const MobileSeekScrubEvent.candidate() : this._(MobileSeekScrubEventType.candidate);

  const MobileSeekScrubEvent.activated(double deltaFraction)
    : this._(MobileSeekScrubEventType.activated, deltaFraction: deltaFraction);

  const MobileSeekScrubEvent.update(double deltaFraction)
    : this._(MobileSeekScrubEventType.update, deltaFraction: deltaFraction);

  const MobileSeekScrubEvent.ended(double deltaFraction)
    : this._(MobileSeekScrubEventType.ended, deltaFraction: deltaFraction);

  const MobileSeekScrubEvent.cancelled({bool wasActive = false})
    : this._(MobileSeekScrubEventType.cancelled, wasActive: wasActive);

  final MobileSeekScrubEventType type;

  /// Signed travel as a fraction of the surface width; positive is forward.
  final double deltaFraction;

  final bool wasActive;
}

/// Horizontal swipe-to-seek on the player surface.
///
/// Sibling of [MobileEdgeAdjustmentTracker], with the same raw-pointer contract
/// the player's root `Listener` already feeds: single tracked pointer, and a
/// "block until every finger is up" guard so a two-finger tap or pinch chord
/// cannot leave a half-finished seek behind.
///
/// This tracker owns the horizontal axis only. Vertical movement — the
/// brightness/volume edge swipes and the content-strip drag — stays with the
/// recognizers that already hold it, and any drag that leans vertical is
/// cancelled here rather than fought over.
///
/// The caller decides whether a horizontal gesture may start at all (platform,
/// live TV, the timeline band, an active long-press). Those are policy, not
/// geometry, so they stay out of this class and in the widget.
class MobileSeekScrubTracker {
  MobileSeekScrubTracker({this.slop = kTouchSlop, this.horizontalDominance = 1.5});

  final double slop;

  /// How much wider than tall a drag must be before it counts as a seek.
  final double horizontalDominance;

  final Set<int> _activePointers = <int>{};
  int? _trackedPointer;
  Offset? _startPosition;
  Size? _size;
  bool _active = false;
  bool _blockedUntilAllPointersUp = false;

  bool get isActive => _active;

  MobileSeekScrubEvent pointerDown(int pointer, Offset position, Size size, {bool allowed = true}) {
    _activePointers.add(pointer);
    if (_blockedUntilAllPointersUp) return const MobileSeekScrubEvent.none();
    if (_activePointers.length > 1) return _cancelTracking(clearPointers: false, blockUntilAllPointersUp: true);
    if (_trackedPointer != null) return const MobileSeekScrubEvent.none();
    if (!allowed) return const MobileSeekScrubEvent.none();

    _trackedPointer = pointer;
    _startPosition = position;
    _size = size;
    _active = false;
    return const MobileSeekScrubEvent.candidate();
  }

  MobileSeekScrubEvent pointerMove(int pointer, Offset position) {
    if (pointer != _trackedPointer) return const MobileSeekScrubEvent.none();
    final start = _startPosition;
    if (start == null) return const MobileSeekScrubEvent.none();

    final delta = position - start;
    final absDx = delta.dx.abs();
    final absDy = delta.dy.abs();

    if (!_active) {
      // Vertical movement belongs to the edge swipes and the content strip.
      if (absDy >= slop && absDy > absDx * horizontalDominance) {
        return _cancelTracking(clearPointers: false, blockUntilAllPointersUp: true);
      }
      if (absDx < slop) return const MobileSeekScrubEvent.none();
      if (absDx <= absDy * horizontalDominance) return const MobileSeekScrubEvent.none();
      // Without a width there is nothing to express the travel as a fraction
      // of, so a degenerate surface never starts a gesture.
      if ((_size?.width ?? 0.0) <= 0) return const MobileSeekScrubEvent.none();
      _active = true;
      return MobileSeekScrubEvent.activated(_deltaFraction(position));
    }

    return MobileSeekScrubEvent.update(_deltaFraction(position));
  }

  MobileSeekScrubEvent pointerUp(int pointer, Offset position) {
    _activePointers.remove(pointer);
    if (_activePointers.isEmpty) _blockedUntilAllPointersUp = false;
    if (pointer != _trackedPointer) return const MobileSeekScrubEvent.none();

    final wasActive = _active;
    final deltaFraction = wasActive ? _deltaFraction(position) : 0.0;
    _resetTracking(clearPointers: false);

    if (!wasActive) return const MobileSeekScrubEvent.none();
    return MobileSeekScrubEvent.ended(deltaFraction);
  }

  MobileSeekScrubEvent pointerCancel(int pointer) {
    _activePointers.remove(pointer);
    if (_activePointers.isEmpty) _blockedUntilAllPointersUp = false;
    if (pointer != _trackedPointer) return const MobileSeekScrubEvent.none();
    return _cancelTracking(clearPointers: false, blockUntilAllPointersUp: _activePointers.isNotEmpty);
  }

  MobileSeekScrubEvent cancel() => _cancelTracking(clearPointers: true, blockUntilAllPointersUp: false);

  MobileSeekScrubEvent _cancelTracking({required bool clearPointers, required bool blockUntilAllPointersUp}) {
    final hadTracking = _trackedPointer != null;
    final wasActive = _active;
    _resetTracking(clearPointers: clearPointers);
    if (blockUntilAllPointersUp && _activePointers.isNotEmpty) _blockedUntilAllPointersUp = true;
    if (!hadTracking) return const MobileSeekScrubEvent.none();
    return MobileSeekScrubEvent.cancelled(wasActive: wasActive);
  }

  double _deltaFraction(Offset position) {
    final start = _startPosition;
    final size = _size;
    if (start == null || size == null || size.width <= 0) return 0.0;
    return (position.dx - start.dx) / size.width;
  }

  void _resetTracking({required bool clearPointers}) {
    _trackedPointer = null;
    _startPosition = null;
    _size = null;
    _active = false;
    if (clearPointers) {
      _activePointers.clear();
      _blockedUntilAllPointersUp = false;
    }
  }
}
