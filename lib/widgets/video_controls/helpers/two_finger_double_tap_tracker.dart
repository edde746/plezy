import 'dart:ui' show Offset;

import 'package:flutter/gestures.dart' show kDoubleTapSlop, kDoubleTapTimeout, kDoubleTapTouchSlop;

class TwoFingerDoubleTapTracker {
  TwoFingerDoubleTapTracker({
    DateTime Function()? now,
    this.tapTimeout = kDoubleTapTimeout,
    this.doubleTapTimeout = kDoubleTapTimeout,
    this.tapSlop = kDoubleTapTouchSlop,
    this.doubleTapSlop = kDoubleTapSlop,
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Duration tapTimeout;
  final Duration doubleTapTimeout;
  final double tapSlop;
  final double doubleTapSlop;

  final Map<int, _TrackedTouch> _activeTouches = {};
  DateTime? _candidateStartTime;
  Offset? _candidateFocalPoint;
  bool _candidateActive = false;
  bool _candidateInvalid = false;
  DateTime? _lastTapTime;
  Offset? _lastTapFocalPoint;

  bool get isChordActive => _activeTouches.length > 1 || _candidateActive;

  void pointerDown(int pointer, Offset position) {
    _activeTouches[pointer] = _TrackedTouch(start: position, current: position, downTime: _now());

    if (_activeTouches.length == 2) {
      _candidateActive = true;
      _candidateInvalid = false;
      _candidateStartTime = _earliestActiveDownTime();
      _candidateFocalPoint = _activeFocalPoint();
    } else if (_activeTouches.length > 2) {
      _candidateInvalid = true;
    }
  }

  void pointerMove(int pointer, Offset position) {
    final touch = _activeTouches[pointer];
    if (touch == null) return;

    touch.current = position;
    if ((position - touch.start).distance > tapSlop) {
      _candidateInvalid = true;
    }
  }

  bool pointerUp(int pointer, Offset position) {
    final touch = _activeTouches[pointer];
    if (touch == null) return false;

    touch.current = position;
    if ((position - touch.start).distance > tapSlop) {
      _candidateInvalid = true;
    }
    _activeTouches.remove(pointer);

    if (_activeTouches.isNotEmpty) return false;

    final startTime = _candidateStartTime;
    final focalPoint = _candidateFocalPoint;
    final isTap =
        _candidateActive &&
        !_candidateInvalid &&
        startTime != null &&
        focalPoint != null &&
        _now().difference(startTime) <= tapTimeout;

    _clearCandidate();
    if (!isTap) return false;
    return _recordTwoFingerTap(focalPoint);
  }

  void pointerCancel(int pointer) {
    _activeTouches.remove(pointer);
    _candidateInvalid = true;
    if (_activeTouches.isEmpty) _clearCandidate();
  }

  void resetSeries() {
    _lastTapTime = null;
    _lastTapFocalPoint = null;
  }

  DateTime _earliestActiveDownTime() {
    return _activeTouches.values.map((touch) => touch.downTime).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  Offset _activeFocalPoint() {
    var sum = Offset.zero;
    for (final touch in _activeTouches.values) {
      sum += touch.current;
    }
    return sum / _activeTouches.length.toDouble();
  }

  bool _recordTwoFingerTap(Offset focalPoint) {
    final now = _now();
    final lastTapTime = _lastTapTime;
    final lastTapFocalPoint = _lastTapFocalPoint;
    final isDoubleTap =
        lastTapTime != null &&
        lastTapFocalPoint != null &&
        now.difference(lastTapTime) <= doubleTapTimeout &&
        (focalPoint - lastTapFocalPoint).distance <= doubleTapSlop;

    if (isDoubleTap) {
      resetSeries();
      return true;
    }

    _lastTapTime = now;
    _lastTapFocalPoint = focalPoint;
    return false;
  }

  void _clearCandidate() {
    _candidateStartTime = null;
    _candidateFocalPoint = null;
    _candidateActive = false;
    _candidateInvalid = false;
  }
}

class _TrackedTouch {
  _TrackedTouch({required this.start, required this.current, required this.downTime});

  final Offset start;
  Offset current;
  final DateTime downTime;
}
