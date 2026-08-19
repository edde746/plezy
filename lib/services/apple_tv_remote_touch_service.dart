import 'dart:async';

import 'package:flutter/services.dart';

import '../focus/input_mode_tracker.dart';
import '../utils/app_logger.dart';
import '../utils/key_event_simulator.dart' as key_sim;
import 'gamepad_service.dart';

enum _SwipeAxis { horizontal, vertical }

class AppleTvRemotePlayPauseAction {
  final String source;
  final String? detail;

  const AppleTvRemotePlayPauseAction({required this.source, this.detail});
}

const double _axisSwitchDominanceRatio = 1.5;
// Retuned against the native tvOS focus engine, measured on-device on an
// Apple TV 4K (issue #2006), poster grid 230x345:
// - one focus step per ~400pt of indirect-touch travel (UITouch points — the
//   same accelerated space the engine reports on this channel), measured
//   identical for the 230pt and 345pt axes: the step distance does NOT
//   follow the focused item's extent;
// - steps repeat every ~60ms (native median) during a committed drag;
// - a fast lift glides on: one extra step past ~2000pt/s, two past ~8000pt/s,
//   landing within ~130ms of the lift.
// Small extents (chips, list rows) are unmeasured; the fixed step distance
// extrapolates the measured axis-independence to them.
const Duration _swipeRepeatInterval = Duration(milliseconds: 60);
const double _swipeStepDistance = 400;
const Duration _glideStepInterval = Duration(milliseconds: 70);
const double _glideVelocity = 2000;
const double _glideDoubleStepVelocity = 8000;
const Duration _liftVelocityWindow = Duration(milliseconds: 100);

/// Bridges tvOS touch-surface events (Siri Remote and Apple's iOS Remote app)
/// into the focus-tree key events Plezy already handles for D-pad navigation.
///
/// One focus step costs a fixed [swipeThreshold] of touch travel regardless
/// of the focused control's size, steps repeat on a short cadence during a
/// sustained drag, and a fast lift "glides" one or two further steps — all
/// three tuned to on-device measurements of the native focus engine.
class AppleTvRemoteTouchService {
  static const String _channelName = 'flutter/gamepadtouchevent';

  static final AppleTvRemoteTouchService instance = AppleTvRemoteTouchService();

  final BasicMessageChannel<dynamic> _channel = const BasicMessageChannel<dynamic>(_channelName, JSONMessageCodec());
  final void Function(LogicalKeyboardKey logicalKey) _simulateKeyPress;
  final VoidCallback _scheduleFrame;
  final DateTime Function() _now;
  final GamepadDuplicateInputGuard _duplicateInputGuard;

  final StreamController<AppleTvRemotePlayPauseAction> _playPauseController =
      StreamController<AppleTvRemotePlayPauseAction>.broadcast();

  /// Touch travel that prices one focus step.
  final double swipeThreshold;

  bool _listening = false;
  bool _nativeKeyHandlerRegistered = false;
  bool _touchActive = false;
  double _startX = 0;
  double _startY = 0;
  double _anchorX = 0;
  double _anchorY = 0;
  _SwipeAxis? _lastSwipeAxis;
  DateTime? _lastSwipeAt;
  LogicalKeyboardKey? _lastSwipeKey;
  final List<({DateTime t, double x, double y})> _moveSamples = [];
  Timer? _glideTimer;

  AppleTvRemoteTouchService({
    void Function(LogicalKeyboardKey logicalKey)? simulateKeyPress,
    VoidCallback? scheduleFrame,
    DateTime Function()? now,
    this.swipeThreshold = _swipeStepDistance,
  }) : _simulateKeyPress = simulateKeyPress ?? key_sim.simulateKeyPress,
       _scheduleFrame = scheduleFrame ?? key_sim.scheduleFrameIfIdle,
       _now = now ?? DateTime.now,
       _duplicateInputGuard = GamepadDuplicateInputGuard(now: now);

  Stream<AppleTvRemotePlayPauseAction> get playPauseActions => _playPauseController.stream;

  void start() {
    if (_listening) return;
    _channel.setMessageHandler(handleMessage);
    _registerNativeKeyHandler();
    _listening = true;
    appLogger.i('AppleTvRemoteTouchService: Listening for tvOS touch remote events');
  }

  void stop() {
    if (!_listening) return;
    _channel.setMessageHandler(null);
    _cancelGlide();
    _unregisterNativeKeyHandler();
    _duplicateInputGuard.clear();
    _resetTouch();
    _listening = false;
  }

  bool handleNativeKeyEvent(KeyEvent event) {
    _log('native ${_eventTypeName(event)} logical=${_keyName(event.logicalKey)}');
    if (_isMediaPlaybackKey(event.logicalKey)) {
      _log('consume native media key reason=direct-playback-action');
      return true;
    }
    return _duplicateInputGuard.handleNativeKeyEvent(event);
  }

  Future<void> handleMessage(dynamic arguments) async {
    if (arguments is! Map) {
      _log('ignore message reason=not-map valueType=${arguments.runtimeType}');
      return;
    }

    final type = arguments['type'];
    if (type is! String) {
      _log('ignore message reason=missing-type args=$arguments');
      return;
    }

    _logTouch(type, arguments);

    switch (type) {
      case 'started':
        final position = _positionFrom(arguments);
        if (position == null) return;
        _startTouch(position.$1, position.$2);
      case 'move':
        final position = _positionFrom(arguments);
        if (position == null) return;
        _moveTouch(position.$1, position.$2);
      case 'ended':
        // Drop the lift frame position: it is unreliable on the Siri Remote —
        // a natural finger pivot during lift can register enough delta from
        // the post-last-swipe anchor to fire a stray opposite-direction
        // swipe. The gesture's recorded move samples still price a post-lift
        // glide.
        _endTouch();
      case 'cancelled':
        _resetTouch();
      case 'play_pause':
        final source = arguments['source'] is String ? arguments['source'] as String : 'native';
        final detail = arguments['detail'] is String ? arguments['detail'] as String : null;
        _log('emit action=play_pause source=$source${detail == null ? '' : ' detail=$detail'}');
        _playPauseController.add(AppleTvRemotePlayPauseAction(source: source, detail: detail));
      case 'loc':
        break;
      default:
        break;
    }
  }

  (double, double)? _positionFrom(Map<dynamic, dynamic> arguments) {
    final x = _toDouble(arguments['x']);
    final y = _toDouble(arguments['y']);
    if (x == null || y == null) return null;
    return (x, y);
  }

  double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return null;
  }

  void _startTouch(double x, double y) {
    _cancelGlide();
    _touchActive = true;
    _startX = x;
    _startY = y;
    _anchorX = x;
    _anchorY = y;
    _lastSwipeAxis = null;
    _lastSwipeAt = null;
    _lastSwipeKey = null;
    _moveSamples
      ..clear()
      ..add((t: _now(), x: x, y: y));
  }

  void _moveTouch(double x, double y) {
    if (!_touchActive) {
      _log('ignore touch-move reason=no-active-touch x=${_formatDouble(x)} y=${_formatDouble(y)}');
      return;
    }

    final deltaX = _anchorX - x;
    final deltaY = _anchorY - y;

    final now = _now();
    _recordMoveSample(now, x, y);
    final lastSwipeAt = _lastSwipeAt;
    if (lastSwipeAt != null && now.difference(lastSwipeAt) < _swipeRepeatInterval) {
      // Travel during the repeat cooldown never counts toward the next step:
      // re-anchor on every frame so a fast flick's deceleration tail is
      // discarded instead of banked. Without this, the first post-cooldown
      // move frame — even a stationary or lift-drift one — released the
      // banked delta as a second focus step for a single intentional swipe.
      // A deliberate continuous drag still repeats because it covers a fresh
      // swipe threshold after each cooldown expires.
      _anchorX = x;
      _anchorY = y;
      final age = now.difference(lastSwipeAt).inMilliseconds;
      _log(
        'suppress swipe reason=repeat-cooldown age=${age}ms dx=${_formatDouble(deltaX)} dy=${_formatDouble(deltaY)}',
      );
      return;
    }

    final axis = _resolveSwipeAxis(x: x, y: y, deltaX: deltaX, deltaY: deltaY);
    if (axis == null) return;

    final logicalKey = axis == _SwipeAxis.horizontal
        ? (deltaX >= 0 ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight)
        : (deltaY >= 0 ? LogicalKeyboardKey.arrowUp : LogicalKeyboardKey.arrowDown);

    _emitKey(
      logicalKey,
      source: 'swipe',
      detail:
          'dx=${_formatDouble(deltaX)} dy=${_formatDouble(deltaY)} '
          'th=${_formatDouble(swipeThreshold)}',
    );
    _anchorX = x;
    _anchorY = y;
    _lastSwipeAxis = axis;
    _lastSwipeAt = now;
    _lastSwipeKey = logicalKey;
  }

  /// Resolves which axis, if any, covered a full step distance, with
  /// hysteresis so incidental drift does not zig-zag an established swipe.
  _SwipeAxis? _resolveSwipeAxis({
    required double x,
    required double y,
    required double deltaX,
    required double deltaY,
  }) {
    final progressX = deltaX.abs() / swipeThreshold;
    final progressY = deltaY.abs() / swipeThreshold;
    if (progressX < 1 && progressY < 1) return null;

    final candidate = progressX >= progressY ? _SwipeAxis.horizontal : _SwipeAxis.vertical;
    final lastAxis = _lastSwipeAxis;
    if (lastAxis == null || candidate == lastAxis) return candidate;

    final totalProgressX = (_startX - x).abs() / swipeThreshold;
    final totalProgressY = (_startY - y).abs() / swipeThreshold;
    final candidateTotal = _axisValue(candidate, totalProgressX, totalProgressY);
    final lastAxisTotal = _axisValue(lastAxis, totalProgressX, totalProgressY);
    final candidateSegment = _axisValue(candidate, progressX, progressY);
    final lastAxisSegment = _axisValue(lastAxis, progressX, progressY);
    if (candidateTotal >= lastAxisTotal * _axisSwitchDominanceRatio &&
        candidateSegment >= lastAxisSegment * _axisSwitchDominanceRatio) {
      return candidate;
    }

    return lastAxisSegment >= 1 ? lastAxis : null;
  }

  double _axisValue(_SwipeAxis axis, double horizontal, double vertical) {
    return axis == _SwipeAxis.horizontal ? horizontal : vertical;
  }

  void _recordMoveSample(DateTime now, double x, double y) {
    _moveSamples.add((t: now, x: x, y: y));
    final cutoff = now.subtract(_liftVelocityWindow);
    while (_moveSamples.isNotEmpty && _moveSamples.first.t.isBefore(cutoff)) {
      _moveSamples.removeAt(0);
    }
  }

  void _endTouch() {
    final glideKey = _lastSwipeKey;
    final glideSteps = _liftGlideSteps();
    _resetTouch();
    if (glideKey != null && glideSteps > 0) _startGlide(glideKey, glideSteps);
  }

  /// Prices the post-lift glide from the finger's velocity over the last
  /// [_liftVelocityWindow] of the gesture, measured along the established
  /// swipe axis. A gesture that never produced a step has no established
  /// direction and never glides; neither does a lift moving against the last
  /// step (a reversal pivot).
  int _liftGlideSteps() {
    final key = _lastSwipeKey;
    final axis = _lastSwipeAxis;
    if (key == null || axis == null || _moveSamples.length < 2) return 0;
    final first = _moveSamples.first;
    final last = _moveSamples.last;
    final dt = last.t.difference(first.t).inMicroseconds / Duration.microsecondsPerSecond;
    if (dt <= 0) return 0;
    final velocity = axis == _SwipeAxis.horizontal ? (last.x - first.x) / dt : (last.y - first.y) / dt;
    final towardKey = axis == _SwipeAxis.horizontal
        ? (velocity < 0 ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight)
        : (velocity < 0 ? LogicalKeyboardKey.arrowUp : LogicalKeyboardKey.arrowDown);
    if (towardKey != key) return 0;
    final speed = velocity.abs();
    if (speed < _glideVelocity) return 0;
    return speed >= _glideDoubleStepVelocity ? 2 : 1;
  }

  void _startGlide(LogicalKeyboardKey key, int steps) {
    _cancelGlide();
    var remaining = steps;
    _log('start glide key=${_keyName(key)} steps=$steps');
    _glideTimer = Timer.periodic(_glideStepInterval, (timer) {
      _emitKey(key, source: 'glide');
      remaining -= 1;
      if (remaining <= 0) {
        timer.cancel();
        if (identical(_glideTimer, timer)) _glideTimer = null;
      }
    });
  }

  void _cancelGlide() {
    _glideTimer?.cancel();
    _glideTimer = null;
  }

  bool _emitKey(LogicalKeyboardKey logicalKey, {required String source, String? detail}) {
    if (_duplicateInputGuard.shouldSuppressSyntheticKey(logicalKey)) {
      _log('suppress key=${_keyName(logicalKey)} source=$source reason=recent-native');
      return false;
    }

    InputModeTracker.reportNonPointerInput();
    _scheduleFrame();
    _log('emit key=${_keyName(logicalKey)} source=$source${detail == null ? '' : ' $detail'}');
    _simulateKeyPress(logicalKey);
    return true;
  }

  void _resetTouch() {
    _touchActive = false;
    _lastSwipeAxis = null;
    _lastSwipeAt = null;
    _lastSwipeKey = null;
    _moveSamples.clear();
  }

  void _registerNativeKeyHandler() {
    if (_nativeKeyHandlerRegistered) return;
    HardwareKeyboard.instance.addHandler(handleNativeKeyEvent);
    _nativeKeyHandlerRegistered = true;
  }

  void _unregisterNativeKeyHandler() {
    if (!_nativeKeyHandlerRegistered) return;
    HardwareKeyboard.instance.removeHandler(handleNativeKeyEvent);
    _nativeKeyHandlerRegistered = false;
  }

  void _logTouch(String type, Map<dynamic, dynamic> arguments) {
    final x = _toDouble(arguments['x']);
    final y = _toDouble(arguments['y']);
    _log('touch type=$type x=${_formatDouble(x)} y=${_formatDouble(y)} active=$_touchActive');
  }

  void _log(String message) {
    appLogger.d('AppleTvRemoteTouchService: $message');
  }

  String _eventTypeName(KeyEvent event) {
    if (event is KeyDownEvent) return 'keydown';
    if (event is KeyRepeatEvent) return 'keyrepeat';
    if (event is KeyUpEvent) return 'keyup';
    return event.runtimeType.toString();
  }

  String _keyName(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp) return 'arrowUp';
    if (key == LogicalKeyboardKey.arrowDown) return 'arrowDown';
    if (key == LogicalKeyboardKey.arrowLeft) return 'arrowLeft';
    if (key == LogicalKeyboardKey.arrowRight) return 'arrowRight';
    if (key == LogicalKeyboardKey.enter) return 'enter';
    if (key.keyId == 0x0d) return 'rawEnter';
    if (key == LogicalKeyboardKey.numpadEnter) return 'numpadEnter';
    if (key == LogicalKeyboardKey.select) return 'select';
    if (key == LogicalKeyboardKey.gameButtonA) return 'gameButtonA';
    if (key == LogicalKeyboardKey.escape) return 'escape';
    if (key == LogicalKeyboardKey.mediaPlay) return 'mediaPlay';
    if (key == LogicalKeyboardKey.mediaPause) return 'mediaPause';
    if (key == LogicalKeyboardKey.mediaPlayPause) return 'mediaPlayPause';
    return '0x${key.keyId.toRadixString(16)}';
  }

  bool _isMediaPlaybackKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause;
  }

  String _formatDouble(double? value) {
    if (value == null) return 'n/a';
    return value.toStringAsFixed(1);
  }
}
