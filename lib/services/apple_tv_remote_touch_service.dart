import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
class AppleTvRemoteTouchService {
  static const String _channelName = 'flutter/gamepadtouchevent';
  static const double defaultSwipeThreshold = 180;
  static const double defaultAxisSwitchDominanceRatio = 1.5;
  static const Duration defaultSwipeRepeatInterval = Duration(milliseconds: 140);
  static const Duration defaultClickAfterDirectionSuppression = Duration(milliseconds: 220);

  static final AppleTvRemoteTouchService instance = AppleTvRemoteTouchService();

  final BasicMessageChannel<dynamic> _channel;
  final void Function(LogicalKeyboardKey logicalKey) _simulateKeyPress;
  final void Function(LogicalKeyboardKey logicalKey) _simulateKeyDown;
  final void Function(LogicalKeyboardKey logicalKey) _simulateKeyUp;
  final VoidCallback _scheduleFrame;
  final DateTime Function() _now;
  final GamepadDuplicateInputGuard _duplicateInputGuard;
  final StreamController<AppleTvRemotePlayPauseAction> _playPauseController =
      StreamController<AppleTvRemotePlayPauseAction>.broadcast();
  final double swipeThreshold;
  final double axisSwitchDominanceRatio;
  final Duration swipeRepeatInterval;
  final Duration clickAfterDirectionSuppression;

  bool _listening = false;
  bool _nativeKeyHandlerRegistered = false;
  bool _touchActive = false;
  double _startX = 0;
  double _startY = 0;
  double _anchorX = 0;
  double _anchorY = 0;
  _SwipeAxis? _lastSwipeAxis;
  DateTime? _lastSwipeAt;
  DateTime? _lastDirectionalInputAt;
  DateTime? _lastSyntheticSelectAt;
  DateTime? _lastAcceptedNativeSelectDownAt;
  DateTime? _lastAcceptedNativeSelectUpAt;
  int _suppressedNativeSelectDowns = 0;
  bool _nativeSelectPressed = false;
  bool _selectPressedFromClick = false;

  AppleTvRemoteTouchService({
    BasicMessageChannel<dynamic>? channel,
    void Function(LogicalKeyboardKey logicalKey)? simulateKeyPress,
    void Function(LogicalKeyboardKey logicalKey)? simulateKeyDown,
    void Function(LogicalKeyboardKey logicalKey)? simulateKeyUp,
    VoidCallback? scheduleFrame,
    DateTime Function()? now,
    GamepadDuplicateInputGuard? duplicateInputGuard,
    Duration duplicateSuppressionWindow = GamepadDuplicateInputGuard.defaultSuppressionWindow,
    this.swipeThreshold = defaultSwipeThreshold,
    this.axisSwitchDominanceRatio = defaultAxisSwitchDominanceRatio,
    this.swipeRepeatInterval = defaultSwipeRepeatInterval,
    this.clickAfterDirectionSuppression = defaultClickAfterDirectionSuppression,
  }) : assert(axisSwitchDominanceRatio >= 1),
       _channel = channel ?? const BasicMessageChannel<dynamic>(_channelName, JSONMessageCodec()),
       _simulateKeyPress = simulateKeyPress ?? key_sim.simulateKeyPress,
       _simulateKeyDown = simulateKeyDown ?? key_sim.simulateKeyDown,
       _simulateKeyUp = simulateKeyUp ?? key_sim.simulateKeyUp,
       _scheduleFrame = scheduleFrame ?? key_sim.scheduleFrameIfIdle,
       _now = now ?? DateTime.now,
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
    _resetNativeSelectBurstState();
    _releaseSelectFromClick(source: 'stop');
    _resetTouch();
    _listening = false;
  }

  bool handleNativeKeyEvent(KeyEvent event) {
    _log('native ${_eventTypeName(event)} logical=${_keyName(event.logicalKey)}');
    if (_isMediaPlaybackKey(event.logicalKey)) {
      _log('consume native media key reason=direct-playback-action');
      return true;
    }
    if (_shouldConsumeNativeSelectDuplicate(event)) {
      return true;
    }
    if (event is KeyDownEvent && _isDirectionalKey(event.logicalKey)) {
      _lastDirectionalInputAt = _now();
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
      case 'click_e':
        _releaseSelectFromClick(source: 'click_e');
      case 'click_s':
        _pressSelectFromClick();
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
    final axis = _resolveSwipeAxis(x: x, y: y, deltaX: deltaX, deltaY: deltaY);
    if (axis == null) return;

    final now = _now();
    final lastSwipeAt = _lastSwipeAt;
    if (lastSwipeAt != null && now.difference(lastSwipeAt) < swipeRepeatInterval) {
      final age = now.difference(lastSwipeAt).inMilliseconds;
      _log(
        'suppress swipe reason=repeat-cooldown age=${age}ms dx=${_formatDouble(deltaX)} dy=${_formatDouble(deltaY)}',
      );
      return;
    }

    final logicalKey = axis == _SwipeAxis.horizontal
        ? (deltaX >= 0 ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight)
        : (deltaY >= 0 ? LogicalKeyboardKey.arrowUp : LogicalKeyboardKey.arrowDown);

    _emitKey(logicalKey, source: 'swipe', detail: 'dx=${_formatDouble(deltaX)} dy=${_formatDouble(deltaY)}');
    _anchorX = x;
    _anchorY = y;
    _lastSwipeAxis = axis;
    _lastSwipeAt = now;
  }

  _SwipeAxis? _resolveSwipeAxis({
    required double x,
    required double y,
    required double deltaX,
    required double deltaY,
  }) {
    final absX = deltaX.abs();
    final absY = deltaY.abs();
    if (absX < swipeThreshold && absY < swipeThreshold) return null;

    final candidate = absX >= absY ? _SwipeAxis.horizontal : _SwipeAxis.vertical;
    final lastAxis = _lastSwipeAxis;
    if (lastAxis == null || candidate == lastAxis) return candidate;

    final totalX = (_startX - x).abs();
    final totalY = (_startY - y).abs();
    final candidateTotal = _axisDistance(candidate, totalX, totalY);
    final lastAxisTotal = _axisDistance(lastAxis, totalX, totalY);
    final candidateSegment = _axisDistance(candidate, absX, absY);
    final lastAxisSegment = _axisDistance(lastAxis, absX, absY);
    if (candidateTotal >= lastAxisTotal * axisSwitchDominanceRatio &&
        candidateSegment >= lastAxisSegment * axisSwitchDominanceRatio) {
      return candidate;
    }

    return lastAxisSegment >= swipeThreshold ? lastAxis : null;
  }

  double _axisDistance(_SwipeAxis axis, double horizontal, double vertical) {
    return axis == _SwipeAxis.horizontal ? horizontal : vertical;
  }

  void _pressSelectFromClick() {
    final now = _now();
    final lastDirectionalInputAt = _lastDirectionalInputAt;
    if (lastDirectionalInputAt != null && now.difference(lastDirectionalInputAt) <= clickAfterDirectionSuppression) {
      final age = now.difference(lastDirectionalInputAt).inMilliseconds;
      _log('suppress key=${_keyName(LogicalKeyboardKey.enter)} source=click_s reason=recent-direction age=${age}ms');
      return;
    }

    final lastSyntheticSelectAt = _lastSyntheticSelectAt;
    if (lastSyntheticSelectAt != null && now.difference(lastSyntheticSelectAt).abs() <= duplicateSuppressionWindow) {
      final age = now.difference(lastSyntheticSelectAt).abs().inMilliseconds;
      _log(
        'suppress key=${_keyName(LogicalKeyboardKey.enter)} source=click_s reason=recent-synthetic-select age=${age}ms',
      );
      return;
    }

    if (_duplicateInputGuard.shouldSuppressSyntheticKey(LogicalKeyboardKey.enter)) {
      _log('suppress key=${_keyName(LogicalKeyboardKey.enter)} source=click_s reason=recent-native');
      return;
    }

    _setTraditionalFocusHighlight();
    _scheduleFrame();
    _selectPressedFromClick = true;
    _log('emit keydown=${_keyName(LogicalKeyboardKey.enter)} source=click_s');
    _simulateKeyDown(LogicalKeyboardKey.enter);
  }

  void _releaseSelectFromClick({required String source}) {
    if (!_selectPressedFromClick) {
      _log('ignore keyup=${_keyName(LogicalKeyboardKey.enter)} source=$source reason=no-click-select-down');
      return;
    }

    _setTraditionalFocusHighlight();
    _scheduleFrame();
    _selectPressedFromClick = false;
    _lastSyntheticSelectAt = _now();
    _log('emit keyup=${_keyName(LogicalKeyboardKey.enter)} source=$source');
    _simulateKeyUp(LogicalKeyboardKey.enter);
  }

  bool _shouldConsumeNativeSelectDuplicate(KeyEvent event) {
    if (!_isSelectKey(event.logicalKey)) return false;

    final now = _now();
    if (_selectPressedFromClick) {
      _log(
        'consume native ${_eventTypeName(event)} logical=${_keyName(event.logicalKey)} '
        'reason=synthetic-select-in-flight',
      );
      if (event is KeyUpEvent) {
        _releaseSelectFromClick(source: 'native_select');
      }
      return true;
    }

    final lastSyntheticSelectAt = _lastSyntheticSelectAt;
    if (lastSyntheticSelectAt != null && now.difference(lastSyntheticSelectAt).abs() <= duplicateSuppressionWindow) {
      final age = now.difference(lastSyntheticSelectAt).abs().inMilliseconds;
      _log(
        'consume native ${_eventTypeName(event)} logical=${_keyName(event.logicalKey)} '
        'reason=recent-synthetic-select age=${age}ms',
      );
      return true;
    }

    if (event is KeyDownEvent) {
      final lastAcceptedNativeSelectUpAt = _lastAcceptedNativeSelectUpAt;
      final duplicateCompletedPress =
          lastAcceptedNativeSelectUpAt != null &&
          now.difference(lastAcceptedNativeSelectUpAt).abs() <= duplicateSuppressionWindow;
      if (_nativeSelectPressed || duplicateCompletedPress) {
        _suppressedNativeSelectDowns++;
        final reason = _nativeSelectPressed ? 'native-select-already-down' : 'recent-native-select';
        _log(
          'consume native ${_eventTypeName(event)} logical=${_keyName(event.logicalKey)} '
          'reason=$reason',
        );
        return true;
      }

      _nativeSelectPressed = true;
      _lastAcceptedNativeSelectDownAt = now;
      return false;
    }

    if (event is KeyRepeatEvent) {
      if (_nativeSelectPressed) return false;
      final lastAcceptedNativeSelectDownAt = _lastAcceptedNativeSelectDownAt;
      if (lastAcceptedNativeSelectDownAt != null &&
          now.difference(lastAcceptedNativeSelectDownAt).abs() <= duplicateSuppressionWindow) {
        _log(
          'consume native ${_eventTypeName(event)} logical=${_keyName(event.logicalKey)} '
          'reason=recent-native-select',
        );
        return true;
      }
      return false;
    }

    if (event is KeyUpEvent) {
      if (_suppressedNativeSelectDowns > 0) {
        _suppressedNativeSelectDowns--;
        _log(
          'consume native ${_eventTypeName(event)} logical=${_keyName(event.logicalKey)} '
          'reason=suppressed-native-select-down',
        );
        return true;
      }

      if (!_nativeSelectPressed) {
        final lastAcceptedNativeSelectUpAt = _lastAcceptedNativeSelectUpAt;
        if (lastAcceptedNativeSelectUpAt != null &&
            now.difference(lastAcceptedNativeSelectUpAt).abs() <= duplicateSuppressionWindow) {
          _log(
            'consume native ${_eventTypeName(event)} logical=${_keyName(event.logicalKey)} '
            'reason=recent-native-select-up',
          );
          return true;
        }
        return false;
      }

      _nativeSelectPressed = false;
      _lastAcceptedNativeSelectUpAt = now;
      return false;
    }

    return false;
  }

  void _resetNativeSelectBurstState() {
    _lastAcceptedNativeSelectDownAt = null;
    _lastAcceptedNativeSelectUpAt = null;
    _suppressedNativeSelectDowns = 0;
    _nativeSelectPressed = false;
  }

  bool _emitKey(LogicalKeyboardKey logicalKey, {required String source, String? detail}) {
    if (_duplicateInputGuard.shouldSuppressSyntheticKey(logicalKey)) {
      _log('suppress key=${_keyName(logicalKey)} source=$source reason=recent-native');
      return false;
    }

    _setTraditionalFocusHighlight();
    _scheduleFrame();
    _log('emit key=${_keyName(logicalKey)} source=$source${detail == null ? '' : ' $detail'}');
    if (_isDirectionalKey(logicalKey)) {
      _lastDirectionalInputAt = _now();
    }
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

  void _setTraditionalFocusHighlight() {
    if (FocusManager.instance.highlightStrategy != FocusHighlightStrategy.alwaysTraditional) {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    }
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

  bool _isDirectionalKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight;
  }

  bool _isSelectKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key.keyId == 0x0d ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.gameButtonA;
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
