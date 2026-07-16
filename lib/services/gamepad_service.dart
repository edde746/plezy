import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:universal_gamepad/universal_gamepad.dart';
import 'package:window_manager/window_manager.dart';

import '../utils/app_logger.dart';
import '../utils/key_event_simulator.dart' as key_sim;
import '../utils/platform_detector.dart';
import '../utils/text_input_diagnostics.dart';

String _describeGamepadButton(GamepadButtonEvent event) {
  return 'button=${event.button} pressed=${event.pressed} value=${event.value} gamepad=${event.gamepadId}';
}

String _describeGamepadAxis(GamepadAxisEvent event) {
  return 'axis=${event.axis} value=${event.value} gamepad=${event.gamepadId}';
}

void _logGamepadDiag(String message) {
  TextInputDiagnostics.log('GamepadService', message);
}

/// Suppresses synthetic gamepad key events when the OS has just delivered an
/// equivalent native key event, which happens with Steam Input on Windows.
class GamepadDuplicateInputGuard {
  static const defaultSuppressionWindow = Duration(milliseconds: 120);
  static const LogicalKeyboardKey _rawEnterKey = LogicalKeyboardKey(0x0d);

  static final Map<LogicalKeyboardKey, Set<LogicalKeyboardKey>> _nativeAliasesBySyntheticKey = {
    LogicalKeyboardKey.arrowUp: {LogicalKeyboardKey.arrowUp},
    LogicalKeyboardKey.arrowDown: {LogicalKeyboardKey.arrowDown},
    LogicalKeyboardKey.arrowLeft: {LogicalKeyboardKey.arrowLeft},
    LogicalKeyboardKey.arrowRight: {LogicalKeyboardKey.arrowRight},
    LogicalKeyboardKey.enter: {
      LogicalKeyboardKey.enter,
      _rawEnterKey,
      LogicalKeyboardKey.numpadEnter,
      LogicalKeyboardKey.select,
      LogicalKeyboardKey.gameButtonA,
    },
    LogicalKeyboardKey.gameButtonB: {
      LogicalKeyboardKey.escape,
      LogicalKeyboardKey.goBack,
      LogicalKeyboardKey.browserBack,
      LogicalKeyboardKey.gameButtonB,
    },
    LogicalKeyboardKey.gameButtonX: {LogicalKeyboardKey.gameButtonX, LogicalKeyboardKey.contextMenu},
  };

  static final Set<LogicalKeyboardKey> _trackedNativeKeys = _nativeAliasesBySyntheticKey.values
      .expand((keys) => keys)
      .toSet();

  final DateTime Function() _now;
  final bool Function()? _enabled;
  final Duration suppressionWindow;
  final Map<LogicalKeyboardKey, DateTime> _lastNativeEvents = {};
  final Set<LogicalKeyboardKey> _nativeKeysPressed = {};

  GamepadDuplicateInputGuard({
    DateTime Function()? now,
    this._enabled,
    this.suppressionWindow = defaultSuppressionWindow,
  }) : _now = now ?? DateTime.now;

  bool get _isEnabled => _enabled?.call() ?? true;

  bool handleNativeKeyEvent(KeyEvent event) {
    if (!_isEnabled || !_trackedNativeKeys.contains(event.logicalKey)) return false;

    final now = _now();
    _lastNativeEvents[event.logicalKey] = now;
    if (event is KeyUpEvent) {
      _nativeKeysPressed.remove(event.logicalKey);
    } else {
      _nativeKeysPressed.add(event.logicalKey);
    }
    _prune(now);
    return false;
  }

  bool shouldSuppressSyntheticKey(LogicalKeyboardKey logicalKey) {
    if (!_isEnabled) return false;

    final now = _now();
    _prune(now);
    for (final key in _nativeAliasesBySyntheticKey[logicalKey] ?? {logicalKey}) {
      if (_nativeKeysPressed.contains(key)) return true;

      final lastNativeEvent = _lastNativeEvents[key];
      if (lastNativeEvent != null && now.difference(lastNativeEvent) <= suppressionWindow) {
        return true;
      }
    }
    return false;
  }

  void clear() {
    _lastNativeEvents.clear();
    _nativeKeysPressed.clear();
  }

  void _prune(DateTime now) {
    _lastNativeEvents.removeWhere((_, timestamp) => now.difference(timestamp) > suppressionWindow);
  }
}

/// Service that bridges gamepad input to Flutter's focus navigation system.
///
/// Listens to gamepad events from the `universal_gamepad` package and translates
/// them into focus navigation actions and key events that integrate with the
/// existing keyboard navigation system.
class GamepadService with WindowListener {
  static final Map<GamepadButton, LogicalKeyboardKey> _syntheticKeyByButton = {
    GamepadButton.dpadUp: LogicalKeyboardKey.arrowUp,
    GamepadButton.dpadDown: LogicalKeyboardKey.arrowDown,
    GamepadButton.dpadLeft: LogicalKeyboardKey.arrowLeft,
    GamepadButton.dpadRight: LogicalKeyboardKey.arrowRight,
    GamepadButton.a: LogicalKeyboardKey.enter,
    GamepadButton.b: LogicalKeyboardKey.gameButtonB,
    GamepadButton.x: LogicalKeyboardKey.gameButtonX,
  };

  static final Map<LogicalKeyboardKey, PhysicalKeyboardKey> _gamepadPhysicalKeyByLogicalKey = {
    LogicalKeyboardKey.arrowUp: PhysicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown: PhysicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft: PhysicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight: PhysicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.enter: PhysicalKeyboardKey.enter,
    LogicalKeyboardKey.escape: PhysicalKeyboardKey.escape,
    LogicalKeyboardKey.gameButtonA: PhysicalKeyboardKey.gameButtonA,
    LogicalKeyboardKey.gameButtonB: PhysicalKeyboardKey.gameButtonB,
    LogicalKeyboardKey.gameButtonX: PhysicalKeyboardKey.gameButtonX,
  };

  static GamepadService? _instance;
  StreamSubscription<GamepadEvent>? _subscription;
  final GamepadDuplicateInputGuard _duplicateInputGuard;

  /// Callback to switch InputModeTracker to keyboard mode.
  /// Set by InputModeTracker when it initializes.
  static VoidCallback? onGamepadInput;

  static final Map<Object, ({VoidCallback previous, VoidCallback next, bool Function() isActive})>
  _tabNavigationHandlers = {};

  /// Registers owner-scoped bumper navigation. Multiple tab screens can stay
  /// mounted; only the handler whose screen is currently visible runs.
  static void registerTabNavigation(
    Object owner, {
    required VoidCallback previous,
    required VoidCallback next,
    required bool Function() isActive,
  }) {
    _tabNavigationHandlers[owner] = (previous: previous, next: next, isActive: isActive);
  }

  static void unregisterTabNavigation(Object owner) {
    _tabNavigationHandlers.remove(owner);
  }

  static void _dispatchTabNavigation({required bool previous}) {
    for (final handler in _tabNavigationHandlers.values) {
      if (!handler.isActive()) continue;
      previous ? handler.previous() : handler.next();
      return;
    }
  }

  @visibleForTesting
  static void debugDispatchTabNavigation({required bool previous}) {
    _dispatchTabNavigation(previous: previous);
  }

  @visibleForTesting
  static void debugClearTabNavigationHandlers() {
    _tabNavigationHandlers.clear();
  }

  // Deadzone for analog sticks (0.0 to 1.0)
  static const double _stickDeadzone = 0.5;

  // Auto-repeat timing for held directional inputs (D-pad / stick)
  static const Duration _repeatInitialDelay = Duration(milliseconds: 400);
  static const Duration _repeatInterval = Duration(milliseconds: 80);

  key_sim.KeyEventSimulatorController? _keyEventSimulator;

  // Track stick state to detect deadzone crossings
  bool _leftStickUp = false;
  bool _leftStickDown = false;
  bool _leftStickLeft = false;
  bool _leftStickRight = false;

  // Track button states to prevent repeated events from button holds
  final Set<GamepadButton> _pressedButtons = {};
  final Set<GamepadButton> _suppressedButtons = {};
  // Whether the app window is currently focused — ignore gamepad input when false
  bool _windowFocused = true;
  bool _nativeKeyHandlerRegistered = false;
  bool _nativeTextInputFocused = false;

  @visibleForTesting
  static Future<void> Function(bool focused)? debugNativeTextInputFocusHandler;

  GamepadService._({GamepadDuplicateInputGuard? duplicateInputGuard})
    : _duplicateInputGuard = duplicateInputGuard ?? GamepadDuplicateInputGuard(enabled: () => Platform.isWindows);

  key_sim.KeyEventSimulatorController get _simulator {
    return _keyEventSimulator ??= key_sim.KeyEventSimulatorController(
      deviceType: ui.KeyEventDeviceType.gamepad,
      physicalKeyByLogicalKey: _gamepadPhysicalKeyByLogicalKey,
      log: _logGamepadDiag,
    );
  }

  static GamepadService get instance {
    _instance ??= GamepadService._();
    return _instance!;
  }

  static Future<void> setNativeTextInputFocused(bool focused) {
    return instance._setNativeTextInputFocused(focused);
  }

  /// Start listening to gamepad events.
  /// Only active on desktop platforms (macOS, Windows, Linux).
  static bool get _isDesktop => PlatformDetector.isDesktopOS();

  void start() async {
    appLogger.i('GamepadService: Starting on ${Platform.operatingSystem}');

    try {
      final gamepads = await Gamepad.instance.listGamepads();
      appLogger.i('GamepadService: Found ${gamepads.length} gamepad(s)');
      for (final gamepad in gamepads) {
        appLogger.i('  - ${gamepad.name} (id: ${gamepad.id})');
      }
    } catch (e) {
      appLogger.e('GamepadService: Error listing gamepads', error: e);
    }

    // Track window focus so we ignore gamepad input when another app is active
    // (window_manager is desktop-only)
    if (_isDesktop) {
      windowManager.addListener(this);
      _windowFocused = await windowManager.isFocused();
    }
    _registerNativeKeyHandler();

    unawaited(_subscription?.cancel());
    _subscription = Gamepad.instance.events.listen(
      _handleGamepadEvent,
      onError: (e) => appLogger.e('GamepadService: Stream error', error: e),
    );
    appLogger.i('GamepadService: Listening for gamepad events');
  }

  void stop() {
    _stopDirectionRepeat();
    _unregisterNativeKeyHandler();
    _subscription?.cancel();
    _subscription = null;
    _duplicateInputGuard.clear();
    _suppressedButtons.clear();
    _keyEventSimulator?.dispose();
    _keyEventSimulator = null;
    if (_isDesktop) {
      windowManager.removeListener(this);
    }
    Gamepad.instance.dispose();
  }

  @override
  void onWindowFocus() {
    _windowFocused = true;
    _duplicateInputGuard.clear();
    Gamepad.instance.resume();
  }

  @override
  void onWindowBlur() {
    _windowFocused = false;
    _stopDirectionRepeat();

    // Release all face buttons in one frame so held widget state cannot stick.
    _simulator.releaseKeys([
      if (_pressedButtons.contains(GamepadButton.a)) LogicalKeyboardKey.enter,
      if (_pressedButtons.contains(GamepadButton.x)) LogicalKeyboardKey.gameButtonX,
    ]);
    _pressedButtons.clear();
    _suppressedButtons.clear();
    _duplicateInputGuard.clear();

    // Reset analog stick state so re-focus doesn't inherit stale direction
    _leftStickUp = false;
    _leftStickDown = false;
    _leftStickLeft = false;
    _leftStickRight = false;

    // Release native device handles so other apps can use the gamepad.
    Gamepad.instance.pause();
  }

  void _registerNativeKeyHandler() {
    if (_nativeKeyHandlerRegistered || !Platform.isWindows) return;
    HardwareKeyboard.instance.addHandler(_handleNativeKeyEvent);
    _nativeKeyHandlerRegistered = true;
  }

  void _unregisterNativeKeyHandler() {
    if (!_nativeKeyHandlerRegistered) return;
    HardwareKeyboard.instance.removeHandler(_handleNativeKeyEvent);
    _nativeKeyHandlerRegistered = false;
  }

  bool _handleNativeKeyEvent(KeyEvent event) {
    return _duplicateInputGuard.handleNativeKeyEvent(event);
  }

  Future<void> _setNativeTextInputFocused(bool focused) async {
    _logGamepadDiag('setNativeTextInputFocused requested focused=$focused current=$_nativeTextInputFocused');
    if (_nativeTextInputFocused == focused) {
      _logGamepadDiag('setNativeTextInputFocused no-op focused=$focused');
      return;
    }
    _nativeTextInputFocused = focused;

    if (focused) {
      _logGamepadDiag('native text input focused; clearing repeat/buttons/duplicate guard before pause');
      _stopDirectionRepeat();
      _pressedButtons.clear();
      _suppressedButtons.clear();
      _keyEventSimulator?.clearHeldKeys();
      _duplicateInputGuard.clear();
    }

    final debugHandler = debugNativeTextInputFocusHandler;
    if (debugHandler != null) {
      _logGamepadDiag('setNativeTextInputFocused using debug handler focused=$focused');
      await debugHandler(focused);
      return;
    }

    try {
      if (focused) {
        _logGamepadDiag('calling Gamepad.pause for native text input');
        await Gamepad.instance.pause();
        _logGamepadDiag('Gamepad.pause completed for native text input');
      } else {
        _logGamepadDiag('calling Gamepad.resume after native text input');
        await Gamepad.instance.resume();
        _logGamepadDiag('Gamepad.resume completed after native text input');
      }
    } catch (e) {
      appLogger.e('GamepadService: Failed to ${focused ? "pause" : "resume"} for native text input', error: e);
    }
  }

  void _handleGamepadEvent(GamepadEvent event) {
    _logGamepadDiag('event received type=${event.runtimeType} nativeTextInputFocused=$_nativeTextInputFocused');
    switch (event) {
      case final GamepadConnectionEvent e:
        appLogger.i('GamepadService: Gamepad ${e.connected ? "connected" : "disconnected"}: ${e.info.name}');
        _logGamepadDiag('connection connected=${e.connected} info=${e.info.name}/${e.info.id}');
      case final GamepadButtonEvent e:
        _handleButton(e);
      case final GamepadAxisEvent e:
        _handleAxis(e);
    }
  }

  void _handleButton(GamepadButtonEvent event) {
    _logGamepadDiag(
      'button received ${_describeGamepadButton(event)} windowFocused=$_windowFocused nativeTextInputFocused=$_nativeTextInputFocused',
    );
    if (!_windowFocused) {
      _logGamepadDiag('button ignored because window is not focused ${_describeGamepadButton(event)}');
      return;
    }

    // Switch to keyboard mode on any button press
    if (event.pressed) {
      onGamepadInput?.call();
      _setTraditionalFocusHighlight();
    }
    // Ensure a frame is scheduled so addPostFrameCallback-based key
    // simulation fires promptly. Without this, key-up events can be
    // delayed indefinitely when the app is idle, causing the long-press
    // timer to fire before the release is delivered.
    key_sim.scheduleFrameIfIdle();

    final wasPressed = _pressedButtons.contains(event.button);

    if (event.pressed && !wasPressed) {
      _pressedButtons.add(event.button);
      if (_shouldSuppressButton(event.button)) {
        _logGamepadDiag('button suppressed by duplicate guard ${_describeGamepadButton(event)}');
        _suppressedButtons.add(event.button);
        return;
      }

      // D-pad — navigate with auto-repeat while held
      switch (event.button) {
        case GamepadButton.dpadUp:
          _logGamepadDiag('button starts direction repeat up ${_describeGamepadButton(event)}');
          _startDirectionRepeat(TraversalDirection.up);
          return;
        case GamepadButton.dpadDown:
          _logGamepadDiag('button starts direction repeat down ${_describeGamepadButton(event)}');
          _startDirectionRepeat(TraversalDirection.down);
          return;
        case GamepadButton.dpadLeft:
          _logGamepadDiag('button starts direction repeat left ${_describeGamepadButton(event)}');
          _startDirectionRepeat(TraversalDirection.left);
          return;
        case GamepadButton.dpadRight:
          _logGamepadDiag('button starts direction repeat right ${_describeGamepadButton(event)}');
          _startDirectionRepeat(TraversalDirection.right);
          return;
        // Face buttons — send KeyDown on press, KeyUp on release
        // so widget-level long-press timers work naturally
        case GamepadButton.a:
          _logGamepadDiag('button simulates key down enter ${_describeGamepadButton(event)}');
          _simulateKeyDown(LogicalKeyboardKey.enter);
        case GamepadButton.x:
          _logGamepadDiag('button simulates key down context/menu ${_describeGamepadButton(event)}');
          _simulateKeyDown(LogicalKeyboardKey.gameButtonX);
        // Immediate actions on press
        case GamepadButton.b:
          _logGamepadDiag('button simulates key press back ${_describeGamepadButton(event)}');
          _simulateKeyPress(LogicalKeyboardKey.gameButtonB);
        case GamepadButton.leftShoulder:
          _dispatchTabNavigation(previous: true);
        case GamepadButton.rightShoulder:
          _dispatchTabNavigation(previous: false);
        default:
          break;
      }
    } else if (!event.pressed && wasPressed) {
      _pressedButtons.remove(event.button);
      if (_suppressedButtons.remove(event.button)) {
        _logGamepadDiag('button release consumed by suppressed set ${_describeGamepadButton(event)}');
        return;
      }

      // D-pad release — stop repeat
      switch (event.button) {
        case GamepadButton.dpadUp:
        case GamepadButton.dpadDown:
        case GamepadButton.dpadLeft:
        case GamepadButton.dpadRight:
          _logGamepadDiag('button stops direction repeat ${_describeGamepadButton(event)}');
          _stopDirectionRepeat();
        // Face button release — send KeyUp
        case GamepadButton.a:
          _logGamepadDiag('button simulates key up enter ${_describeGamepadButton(event)}');
          _simulateKeyUp(LogicalKeyboardKey.enter);
        case GamepadButton.x:
          _logGamepadDiag('button simulates key up context/menu ${_describeGamepadButton(event)}');
          _simulateKeyUp(LogicalKeyboardKey.gameButtonX);
        default:
          break;
      }
    }
  }

  bool _shouldSuppressButton(GamepadButton button) {
    final syntheticKey = _syntheticKeyByButton[button];
    final suppressed = syntheticKey != null && _duplicateInputGuard.shouldSuppressSyntheticKey(syntheticKey);
    _logGamepadDiag('duplicate guard button=$button syntheticKey=$syntheticKey suppressed=$suppressed');
    return suppressed;
  }

  void _handleAxis(GamepadAxisEvent event) {
    _logGamepadDiag(
      'axis received ${_describeGamepadAxis(event)} windowFocused=$_windowFocused nativeTextInputFocused=$_nativeTextInputFocused',
    );
    if (!_windowFocused) {
      _logGamepadDiag('axis ignored because window is not focused ${_describeGamepadAxis(event)}');
      return;
    }

    // Switch to keyboard mode on significant axis input. Navigation itself
    // schedules frames only when the stick crosses the real deadzone.
    if (event.value.abs() > 0.3) {
      onGamepadInput?.call();
      _setTraditionalFocusHighlight();
    }

    switch (event.axis) {
      case GamepadAxis.leftStickY:
        _handleLeftStickY(event.value);
      case GamepadAxis.leftStickX:
        _handleLeftStickX(event.value);
      default:
        break;
    }
  }

  /// Fire [direction] immediately, then auto-repeat after an initial delay.
  void _startDirectionRepeat(TraversalDirection direction) {
    _logGamepadDiag('startDirectionRepeat direction=$direction');
    _stopDirectionRepeat();
    final logicalKey = _directionToKey(direction);
    _logGamepadDiag(
      'moveFocus direction=$direction logicalKey=${logicalKey.keyLabel}/${logicalKey.keyId} nativeTextInputFocused=$_nativeTextInputFocused',
    );
    _simulator.startKeyRepeat(logicalKey, initialDelay: _repeatInitialDelay, interval: _repeatInterval);
  }

  void _stopDirectionRepeat() {
    if (_keyEventSimulator?.isRepeating ?? false) {
      _logGamepadDiag('stopDirectionRepeat');
    }
    _keyEventSimulator?.stopKeyRepeat();
  }

  LogicalKeyboardKey _directionToKey(TraversalDirection direction) {
    switch (direction) {
      case TraversalDirection.up:
        return LogicalKeyboardKey.arrowUp;
      case TraversalDirection.down:
        return LogicalKeyboardKey.arrowDown;
      case TraversalDirection.left:
        return LogicalKeyboardKey.arrowLeft;
      case TraversalDirection.right:
        return LogicalKeyboardKey.arrowRight;
    }
  }

  /// Simulate a full key press (down + up) in a single frame.
  void _simulateKeyPress(LogicalKeyboardKey logicalKey) {
    _simulator.simulateKeyPress(logicalKey);
  }

  /// Simulate only key down — pair with [_simulateKeyUp] on release
  /// so widget-level long-press timers see real hold duration.
  void _simulateKeyDown(LogicalKeyboardKey logicalKey) {
    _simulator.simulateKeyDown(logicalKey);
  }

  /// Simulate only key up — the release half of [_simulateKeyDown].
  void _simulateKeyUp(LogicalKeyboardKey logicalKey) {
    _simulator.simulateKeyUp(logicalKey);
  }

  // W3C: leftStickY -1.0 = up, 1.0 = down
  void _handleLeftStickY(double value) {
    if (value > _stickDeadzone && !_leftStickDown) {
      _leftStickDown = true;
      _leftStickUp = false;
      _startDirectionRepeat(TraversalDirection.down);
    } else if (value < -_stickDeadzone && !_leftStickUp) {
      _leftStickUp = true;
      _leftStickDown = false;
      _startDirectionRepeat(TraversalDirection.up);
    } else if (value.abs() <= _stickDeadzone) {
      if (_leftStickUp || _leftStickDown) _stopDirectionRepeat();
      _leftStickUp = false;
      _leftStickDown = false;
    }
  }

  void _handleLeftStickX(double value) {
    if (value < -_stickDeadzone && !_leftStickLeft) {
      _leftStickLeft = true;
      _leftStickRight = false;
      _startDirectionRepeat(TraversalDirection.left);
    } else if (value > _stickDeadzone && !_leftStickRight) {
      _leftStickRight = true;
      _leftStickLeft = false;
      _startDirectionRepeat(TraversalDirection.right);
    } else if (value.abs() <= _stickDeadzone) {
      if (_leftStickLeft || _leftStickRight) _stopDirectionRepeat();
      _leftStickLeft = false;
      _leftStickRight = false;
    }
  }

  // Ensure Material uses traditional (keyboard) focus highlights when navigating
  // via gamepad. Synthetic key events we dispatch below don't go through the
  // platform key pipeline, so Flutter won't automatically flip highlight mode.
  void _setTraditionalFocusHighlight() {
    if (FocusManager.instance.highlightStrategy != FocusHighlightStrategy.alwaysTraditional) {
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    }
  }
}
