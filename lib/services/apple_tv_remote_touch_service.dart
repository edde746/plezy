import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../focus/focus_navigation_intent.dart';
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
// Tuned against the native tvOS focus engine. Two instrumentation passes on
// an Apple TV 4K (issue #2006):
//  1. committed-move telemetry through the experimental UIFocusItem bridge
//     (branch feat/tvos-native-focus-bridge);
//  2. a dedicated native probe app logging every touch sample, pan velocity,
//     engine hint, and focus step across 101 swipe sessions on 160/230/300pt
//     tiles (FocusProbe, 2026-08).
// Findings these constants encode:
//  - one focus step prices at the focused item's extent along the swipe axis
//    plus ~155pt of indirect-touch travel (UITouch points — the accelerated
//    space this channel reports): measured 314pt on a 160pt tile, 391pt on a
//    230pt poster, 410pt on a 300pt rail card. The earlier "fixed 400pt"
//    reading came from a single poster grid whose two extents both happened
//    to price near 400.
//  - steps repeat at 40-120ms (mode ~80ms) during a committed drag; the 60ms
//    cooldown only floors that cadence, travel does the pricing.
//  - a lift never coasts more than ONE step: sessions with lift velocities
//    up to ~11400pt/s produced 95 zero-coast lifts and 6 single-step coasts
//    landing 4-101ms after the lift. Long flat-cadence step bursts in
//    earlier logs were dpad hold-repeat key events, not swipe inertia. Do
//    not reintroduce a multi-step momentum law.
const Duration _swipeRepeatInterval = Duration(milliseconds: 60);
// Fallback step travel when no usable focus geometry exists (a bare focus
// scope, the player's screen-sized catch-all surfaces, a detached node).
const double _swipeStepDistance = 400;
// Travel added to the focused item's extent to price one step.
const double _swipeStepExtraTravel = 155;
// Guards, not tuning: measured extents span 90-345pt; anything outside
// prices within sane bounds instead of extrapolating the affine law.
const double _minSwipeStepTravel = 200;
const double _maxSwipeStepTravel = 700;
const Duration _glideStepInterval = Duration(milliseconds: 70);
const double _glideVelocity = 2000;
const Duration _liftVelocityWindow = Duration(milliseconds: 100);
// A glide only ever extends a sustained drag: the gesture must already have
// emitted this many consecutive steps in the lift direction. The velocity
// estimator runs in the same accelerated space as the step distance, and an
// ordinary discrete flick covers one step's travel at well past
// [_glideVelocity] there — ungated, every deliberate single swipe glided
// into a second step (issue #2006 follow-up reports).
const int _glideMinConsecutiveSteps = 2;

/// Bridges tvOS touch-surface events (Siri Remote and Apple's iOS Remote app)
/// into the focus-tree key events Plezy already handles for D-pad navigation.
///
/// Like the native focus engine, one focus step prices by on-screen geometry:
/// the focused control's extent along the swipe axis plus a fixed travel
/// margin, falling back to [swipeThreshold] when no usable geometry exists.
/// Steps repeat on a short cadence during a sustained drag, and a fast lift
/// "glides" at most one further step — never more; the native engine has no
/// multi-step swipe inertia. A glide only extends a drag that already covered
/// [_glideMinConsecutiveSteps] steps in that direction, so a discrete flick
/// moves exactly one item.
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

  /// Fallback touch travel that prices one focus step when no usable focus
  /// geometry exists.
  final double swipeThreshold;

  /// Global rect of the control that prices a focus step, or null when no
  /// usable geometry exists. Injected so tests can supply fake geometry.
  final Rect? Function() _focusedItemRect;

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
  int _consecutiveStepCount = 0;
  final List<({DateTime t, double x, double y})> _moveSamples = [];
  Timer? _glideTimer;

  AppleTvRemoteTouchService({
    void Function(LogicalKeyboardKey logicalKey)? simulateKeyPress,
    VoidCallback? scheduleFrame,
    DateTime Function()? now,
    this.swipeThreshold = _swipeStepDistance,
    Rect? Function()? focusedItemRect,
  }) : _simulateKeyPress = simulateKeyPress ?? key_sim.simulateKeyPress,
       _scheduleFrame = scheduleFrame ?? key_sim.scheduleFrameIfIdle,
       _now = now ?? DateTime.now,
       _focusedItemRect = focusedItemRect ?? _defaultFocusedItemRect,
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
    _consecutiveStepCount = 0;
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

    final thresholds = _stepThresholds();
    final axis = _resolveSwipeAxis(x: x, y: y, deltaX: deltaX, deltaY: deltaY, thresholds: thresholds);
    if (axis == null) return;

    final logicalKey = axis == _SwipeAxis.horizontal
        ? (deltaX >= 0 ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight)
        : (deltaY >= 0 ? LogicalKeyboardKey.arrowUp : LogicalKeyboardKey.arrowDown);

    _emitKey(
      logicalKey,
      source: 'swipe',
      detail:
          'dx=${_formatDouble(deltaX)} dy=${_formatDouble(deltaY)} '
          'thX=${_formatDouble(thresholds.horizontal)} thY=${_formatDouble(thresholds.vertical)}',
    );
    _anchorX = x;
    _anchorY = y;
    _lastSwipeAxis = axis;
    _lastSwipeAt = now;
    _consecutiveStepCount = logicalKey == _lastSwipeKey ? _consecutiveStepCount + 1 : 1;
    _lastSwipeKey = logicalKey;
  }

  /// Resolves which axis, if any, covered a full step, with hysteresis so
  /// incidental drift does not zig-zag an established swipe.
  ///
  /// Distances are normalized by the per-axis thresholds so that, like the
  /// native focus engine, a wide-flat control steps vertically once the
  /// finger covers its height even while the raw horizontal delta is larger.
  _SwipeAxis? _resolveSwipeAxis({
    required double x,
    required double y,
    required double deltaX,
    required double deltaY,
    required ({double horizontal, double vertical}) thresholds,
  }) {
    final progressX = deltaX.abs() / thresholds.horizontal;
    final progressY = deltaY.abs() / thresholds.vertical;
    if (progressX < 1 && progressY < 1) return null;

    final candidate = progressX >= progressY ? _SwipeAxis.horizontal : _SwipeAxis.vertical;
    final lastAxis = _lastSwipeAxis;
    if (lastAxis == null || candidate == lastAxis) return candidate;

    final totalProgressX = (_startX - x).abs() / thresholds.horizontal;
    final totalProgressY = (_startY - y).abs() / thresholds.vertical;
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

  ({double horizontal, double vertical}) _stepThresholds() {
    final rect = _focusedItemRect();
    if (rect == null) return (horizontal: swipeThreshold, vertical: swipeThreshold);
    return (horizontal: _thresholdForExtent(rect.width), vertical: _thresholdForExtent(rect.height));
  }

  double _thresholdForExtent(double extent) {
    if (!extent.isFinite || extent <= 0) return swipeThreshold;
    return (extent + _swipeStepExtraTravel).clamp(_minSwipeStepTravel, _maxSwipeStepTravel).toDouble();
  }

  /// Reads the primary focus geometry, rejecting nodes whose rect cannot
  /// meaningfully price a step: bare scopes (nothing real is focused yet) and
  /// the player's catch-all [DirectionalShortcutFocusNode] surfaces are
  /// screen-sized, and a detached or unlaid-out node has no rect at all. A
  /// locked-focus row's node is also row-sized; it vends the selected item's
  /// rect instead ([LockedFocusRowNode]).
  static Rect? _defaultFocusedItemRect() {
    final node = FocusManager.instance.primaryFocus;
    if (node == null || node is FocusScopeNode || node is DirectionalShortcutFocusNode) return null;
    if (node is LockedFocusRowNode) return _validRectOrNull(node.focusedItemRect());
    final context = node.context;
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached || !renderObject.hasSize) return null;
    return _validRectOrNull(node.rect);
  }

  static Rect? _validRectOrNull(Rect? rect) {
    if (rect == null || !rect.isFinite || rect.isEmpty) return null;
    return rect;
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
    final shouldGlide = _liftShouldGlide();
    _resetTouch();
    if (glideKey != null && shouldGlide) _startGlide(glideKey);
  }

  /// Decides whether the lift glides one — and only one — further step, from
  /// the finger's velocity over the last [_liftVelocityWindow] of the
  /// gesture, measured along the established swipe axis. Only a sustained
  /// drag glides: the gesture must already have emitted
  /// [_glideMinConsecutiveSteps] consecutive steps in the lift direction, so
  /// a discrete one-step flick never overshoots its target. A gesture that
  /// never produced a step has no established direction and never glides;
  /// neither does a lift moving against the last step (a reversal pivot).
  bool _liftShouldGlide() {
    final key = _lastSwipeKey;
    final axis = _lastSwipeAxis;
    if (key == null || axis == null || _moveSamples.length < 2) return false;
    if (_consecutiveStepCount < _glideMinConsecutiveSteps) return false;
    final first = _moveSamples.first;
    final last = _moveSamples.last;
    final dt = last.t.difference(first.t).inMicroseconds / Duration.microsecondsPerSecond;
    if (dt <= 0) return false;
    final velocity = axis == _SwipeAxis.horizontal ? (last.x - first.x) / dt : (last.y - first.y) / dt;
    final towardKey = axis == _SwipeAxis.horizontal
        ? (velocity < 0 ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight)
        : (velocity < 0 ? LogicalKeyboardKey.arrowUp : LogicalKeyboardKey.arrowDown);
    if (towardKey != key) return false;
    return velocity.abs() >= _glideVelocity;
  }

  void _startGlide(LogicalKeyboardKey key) {
    _cancelGlide();
    _log('start glide key=${_keyName(key)}');
    _glideTimer = Timer(_glideStepInterval, () {
      _glideTimer = null;
      _emitKey(key, source: 'glide');
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
    _consecutiveStepCount = 0;
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
