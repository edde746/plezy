import 'dart:ui' show Offset;

import 'package:flutter/gestures.dart' show kDoubleTapTimeout, kDoubleTapTouchSlop;

/// Detects a two-finger tap on the player surface from raw pointer events.
///
/// The player deliberately avoids Flutter's multi-pointer recognizers here: the
/// root `Listener` is translucent and must observe the chord without entering
/// the gesture arena, so the single-finger tap layers below keep working.
///
/// A candidate arms when exactly two touches are down and completes when the
/// last one lifts within [tapTimeout] having moved less than [tapSlop]. A third
/// finger or any slop-exceeding movement invalidates it — a pinch is not a tap.
///
/// There is deliberately no double-tap notion here. The chord's only meaning is
/// "toggle playback", and it fires the moment it resolves so the viewer keeps
/// the frame they aimed at (#1505); recognising a pair would mean holding the
/// toggle back for [kDoubleTapTimeout] first.
class TwoFingerTapTracker {
  TwoFingerTapTracker({
    DateTime Function()? now,
    this.tapTimeout = kDoubleTapTimeout,
    this.tapSlop = kDoubleTapTouchSlop,
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Duration tapTimeout;
  final double tapSlop;

  final Map<int, _TrackedTouch> _activeTouches = {};
  DateTime? _candidateStartTime;
  bool _candidateActive = false;
  bool _candidateInvalid = false;

  bool get isChordActive => _activeTouches.length > 1 || _candidateActive;

  void pointerDown(int pointer, Offset position) {
    _activeTouches[pointer] = _TrackedTouch(start: position, current: position, downTime: _now());

    if (_activeTouches.length == 2) {
      _candidateActive = true;
      _candidateInvalid = false;
      _candidateStartTime = _earliestActiveDownTime();
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

  /// Returns true when this lift completes a two-finger tap.
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
    final isTap =
        _candidateActive && !_candidateInvalid && startTime != null && _now().difference(startTime) <= tapTimeout;

    _clearCandidate();
    return isTap;
  }

  void pointerCancel(int pointer) {
    _activeTouches.remove(pointer);
    _candidateInvalid = true;
    if (_activeTouches.isEmpty) _clearCandidate();
  }

  DateTime _earliestActiveDownTime() {
    return _activeTouches.values.map((touch) => touch.downTime).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  void _clearCandidate() {
    _candidateStartTime = null;
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
