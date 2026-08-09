import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../focus/focus_navigation_intent.dart';
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

/// Bridges tvOS touch-surface events from Apple's iOS Remote app into the
/// focus-tree key events Plezy already handles for D-pad navigation.
///
/// Like the native focus engine, the pan distance for one focus step follows
/// the focused control's on-screen size: small chips traverse quickly, large
/// cards demand a longer swipe. When no usable geometry exists (a bare focus
/// scope, the video player's screen-sized catch-all surfaces) the step falls
/// back to a fixed threshold.
class AppleTvRemoteTouchService {
  static const String _channelName = 'flutter/gamepadtouchevent';
  static const double defaultSwipeThreshold = 180;
  static const double defaultAxisSwitchDominanceRatio = 1.5;
  static const Duration defaultSwipeRepeatInterval = Duration(milliseconds: 140);
  // Device-tuned on an Apple TV 4K against native focus feel: UIKit's
  // indirect-touch acceleration means roughly half an item's extent of
  // reported travel already reads as "one deliberate swipe".
  static const double defaultSwipeExtentGain = 0.55;
  static const double defaultMinSwipeThreshold = 50;
  static const double defaultMaxSwipeThreshold = 180;

  static final AppleTvRemoteTouchService instance = AppleTvRemoteTouchService();

  final BasicMessageChannel<dynamic> _channel;
  final void Function(LogicalKeyboardKey logicalKey) _simulateKeyPress;
  final VoidCallback _scheduleFrame;
  final DateTime Function() _now;
  final GamepadDuplicateInputGuard _duplicateInputGuard;

  /// Announces that a pointerless device produced input. Injected so tests can
  /// observe it without a widget tree; defaults to the app-wide tracker.
  final void Function() reportNonPointerInput;
  final StreamController<AppleTvRemotePlayPauseAction> _playPauseController =
      StreamController<AppleTvRemotePlayPauseAction>.broadcast();

  /// Fallback step distance when no usable focus geometry exists.
  final double swipeThreshold;
  final double axisSwitchDominanceRatio;
  final Duration swipeRepeatInterval;

  /// Multiplier from the focused control's extent to the pan distance for one
  /// step. Empirical; see the default constants for the device calibration.
  final double swipeExtentGain;
  final double minSwipeThreshold;
  final double maxSwipeThreshold;

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

  AppleTvRemoteTouchService({
    BasicMessageChannel<dynamic>? channel,
    void Function(LogicalKeyboardKey logicalKey)? simulateKeyPress,
    VoidCallback? scheduleFrame,
    DateTime Function()? now,
    GamepadDuplicateInputGuard? duplicateInputGuard,
    this.reportNonPointerInput = InputModeTracker.reportNonPointerInput,
    Duration duplicateSuppressionWindow = GamepadDuplicateInputGuard.defaultSuppressionWindow,
    this.swipeThreshold = defaultSwipeThreshold,
    this.axisSwitchDominanceRatio = defaultAxisSwitchDominanceRatio,
    this.swipeRepeatInterval = defaultSwipeRepeatInterval,
    this.swipeExtentGain = defaultSwipeExtentGain,
    this.minSwipeThreshold = defaultMinSwipeThreshold,
    this.maxSwipeThreshold = defaultMaxSwipeThreshold,
    Rect? Function()? focusedItemRect,
  }) : assert(axisSwitchDominanceRatio >= 1),
       assert(swipeExtentGain > 0),
       assert(minSwipeThreshold > 0 && minSwipeThreshold <= maxSwipeThreshold),
       _channel = channel ?? const BasicMessageChannel<dynamic>(_channelName, JSONMessageCodec()),
       _simulateKeyPress = simulateKeyPress ?? key_sim.simulateKeyPress,
       _scheduleFrame = scheduleFrame ?? key_sim.scheduleFrameIfIdle,
       _now = now ?? DateTime.now,
       _focusedItemRect = focusedItemRect ?? _defaultFocusedItemRect,
       _duplicateInputGuard =
           duplicateInputGuard ?? GamepadDuplicateInputGuard(now: now, suppressionWindow: duplicateSuppressionWindow);

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
        // Drop the lift frame: the final position on touchesEnded is
        // unreliable on the Siri Remote — a natural finger pivot during
        // lift can register enough delta from the post-last-swipe anchor
        // to fire a stray opposite-direction swipe. In-gesture 'move'
        // events have already covered any legitimate swipe motion.
        _resetTouch();
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
    _touchActive = true;
    _startX = x;
    _startY = y;
    _anchorX = x;
    _anchorY = y;
    _lastSwipeAxis = null;
    _lastSwipeAt = null;
  }

  void _moveTouch(double x, double y) {
    if (!_touchActive) {
      _log('ignore touch-move reason=no-active-touch x=${_formatDouble(x)} y=${_formatDouble(y)}');
      return;
    }

    final deltaX = _anchorX - x;
    final deltaY = _anchorY - y;

    final now = _now();
    final lastSwipeAt = _lastSwipeAt;
    if (lastSwipeAt != null && now.difference(lastSwipeAt) < swipeRepeatInterval) {
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
  }

  /// Resolves which axis, if any, crossed its step threshold.
  ///
  /// Distances are normalized by the per-axis thresholds so that, like the
  /// native focus engine, a wide-flat control steps vertically once the finger
  /// covers the item's height even while the raw horizontal delta is larger.
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
    if (candidateTotal >= lastAxisTotal * axisSwitchDominanceRatio &&
        candidateSegment >= lastAxisSegment * axisSwitchDominanceRatio) {
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
    return (extent * swipeExtentGain).clamp(minSwipeThreshold, maxSwipeThreshold).toDouble();
  }

  /// Reads the primary focus geometry, rejecting nodes whose rect cannot
  /// meaningfully price a step: bare scopes (nothing real is focused yet) and
  /// the player's catch-all [DirectionalShortcutFocusNode] surfaces are
  /// screen-sized, and a detached or unlaid-out node has no rect at all.
  static Rect? _defaultFocusedItemRect() {
    final node = FocusManager.instance.primaryFocus;
    if (node == null || node is FocusScopeNode || node is DirectionalShortcutFocusNode) return null;
    final context = node.context;
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached || !renderObject.hasSize) return null;
    final rect = node.rect;
    if (!rect.isFinite || rect.isEmpty) return null;
    return rect;
  }

  bool _emitKey(LogicalKeyboardKey logicalKey, {required String source, String? detail}) {
    if (_duplicateInputGuard.shouldSuppressSyntheticKey(logicalKey)) {
      _log('suppress key=${_keyName(logicalKey)} source=$source reason=recent-native');
      return false;
    }

    reportNonPointerInput();
    _scheduleFrame();
    _log('emit key=${_keyName(logicalKey)} source=$source${detail == null ? '' : ' $detail'}');
    _simulateKeyPress(logicalKey);
    return true;
  }

  Duration get duplicateSuppressionWindow => _duplicateInputGuard.suppressionWindow;

  void _resetTouch() {
    _touchActive = false;
    _lastSwipeAxis = null;
    _lastSwipeAt = null;
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
