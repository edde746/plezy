import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/platform_helper.dart';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:universal_gamepad/universal_gamepad.dart';

import '../utils/app_logger.dart';
import '../utils/key_event_simulator.dart' as key_sim;

/// Service that bridges gamepad input to Flutter's focus navigation system.
///
/// Listens to gamepad events from the `universal_gamepad` package and translates
/// them into focus navigation actions and key events that integrate with the
/// existing keyboard navigation system.
class GamepadService {
  static GamepadService? _instance;
  StreamSubscription<GamepadEvent>? _subscription;

  /// Callback to switch InputModeTracker to keyboard mode.
  /// Set by InputModeTracker when it initializes.
  static VoidCallback? onGamepadInput;

  /// Callback for L1 bumper press (previous tab).
  /// Screens with tabs can listen to this.
  static VoidCallback? onL1Pressed;

  /// Callback for R1 bumper press (next tab).
  /// Screens with tabs can listen to this.
  static VoidCallback? onR1Pressed;

  // Deadzone for analog sticks (0.0 to 1.0)
  static const double _stickDeadzone = 0.5;

  // Auto-repeat timing for held directional inputs (D-pad / stick)
  static const Duration _repeatInitialDelay = Duration(milliseconds: 400);
  static const Duration _repeatInterval = Duration(milliseconds: 80);

  Timer? _repeatTimer;

  // Track stick state to detect deadzone crossings
  bool _leftStickUp = false;
  bool _leftStickDown = false;
  bool _leftStickLeft = false;
  bool _leftStickRight = false;

  // Track button states to prevent repeated events from button holds
  final Set<GamepadButton> _pressedButtons = {};

  GamepadService._();

  /// Get the singleton instance.
  static GamepadService get instance {
    _instance ??= GamepadService._();
    return _instance!;
  }

  /// Start listening to gamepad events.
  /// Only active on desktop platforms (macOS, Windows, Linux).
  void start() async {
    // Only enable on desktop platforms
    if (kIsWeb || (!AppPlatform.isMacOS && !AppPlatform.isWindows && !AppPlatform.isLinux)) return;

    appLogger.i('GamepadService: Starting on desktop');

    // List connected gamepads
    try {
      final gamepads = await Gamepad.instance.listGamepads();
      appLogger.i('GamepadService: Found ${gamepads.length} gamepad(s)');
      for (final gamepad in gamepads) {
        appLogger.i('  - ${gamepad.name} (id: ${gamepad.id})');
      }
    } catch (e) {
      appLogger.e('GamepadService: Error listing gamepads', error: e);
    }

    _subscription?.cancel();
    _subscription = Gamepad.instance.events.listen(
      _handleGamepadEvent,
      onError: (e) => appLogger.e('GamepadService: Stream error', error: e),
    );
    appLogger.i('GamepadService: Listening for gamepad events');
  }

  /// Stop listening to gamepad events.
  void stop() {
    _stopDirectionRepeat();
    _subscription?.cancel();
    _subscription = null;
    Gamepad.instance.dispose();
  }

  void _handleGamepadEvent(GamepadEvent event) {
    switch (event) {
      case GamepadConnectionEvent e:
        appLogger.i('GamepadService: Gamepad ${e.connected ? "connected" : "disconnected"}: ${e.info.name}');
      case GamepadButtonEvent e:
        _handleButton(e);
      case GamepadAxisEvent e:
        _handleAxis(e);
    }
  }

  void _handleButton(GamepadButtonEvent event) {
    // Switch to keyboard mode on any button press
    if (event.pressed) {
      onGamepadInput?.call();
      _setTraditionalFocusHighlight();
      key_sim.scheduleFrameIfIdle();
    }

    final wasPressed = _pressedButtons.contains(event.button);

    if (event.pressed && !wasPressed) {
      _pressedButtons.add(event.button);

      // D-pad — navigate with auto-repeat while held
      switch (event.button) {
        case GamepadButton.dpadUp:
          _startDirectionRepeat(TraversalDirection.up);
          return;
        case GamepadButton.dpadDown:
          _startDirectionRepeat(TraversalDirection.down);
          return;
        case GamepadButton.dpadLeft:
          _startDirectionRepeat(TraversalDirection.left);
          return;
        case GamepadButton.dpadRight:
          _startDirectionRepeat(TraversalDirection.right);
          return;
        // Face buttons — send KeyDown on press, KeyUp on release
        // so widget-level long-press timers work naturally
        case GamepadButton.a:
          _simulateKeyDown(LogicalKeyboardKey.enter);
        case GamepadButton.x:
          _simulateKeyDown(LogicalKeyboardKey.gameButtonX);
        // Immediate actions on press
        case GamepadButton.b:
          _simulateKeyPress(LogicalKeyboardKey.escape);
        case GamepadButton.leftShoulder:
          onL1Pressed?.call();
        case GamepadButton.rightShoulder:
          onR1Pressed?.call();
        default:
          break;
      }
    } else if (!event.pressed && wasPressed) {
      _pressedButtons.remove(event.button);

      switch (event.button) {
        // D-pad release — stop repeat
        case GamepadButton.dpadUp:
        case GamepadButton.dpadDown:
        case GamepadButton.dpadLeft:
        case GamepadButton.dpadRight:
          _stopDirectionRepeat();
        // Face button release — send KeyUp
        case GamepadButton.a:
          _simulateKeyUp(LogicalKeyboardKey.enter);
        case GamepadButton.x:
          _simulateKeyUp(LogicalKeyboardKey.gameButtonX);
        default:
          break;
      }
    }
  }

  void _handleAxis(GamepadAxisEvent event) {
    // Switch to keyboard mode on significant axis input
    if (event.value.abs() > 0.3) {
      onGamepadInput?.call();
      _setTraditionalFocusHighlight();
      SchedulerBinding.instance.ensureVisualUpdate();
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

  void _moveFocus(TraversalDirection direction) {
    // Convert direction to arrow key and simulate a key press
    // This allows widgets like HubSection that intercept key events to handle navigation
    final logicalKey = _directionToKey(direction);
    _simulateKeyPress(logicalKey);
  }

  /// Fire [direction] immediately, then auto-repeat after an initial delay.
  void _startDirectionRepeat(TraversalDirection direction) {
    _stopDirectionRepeat();
    _moveFocus(direction);
    _repeatTimer = Timer(_repeatInitialDelay, () {
      _repeatTimer = Timer.periodic(_repeatInterval, (_) {
        _moveFocus(direction);
      });
    });
  }

  void _stopDirectionRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
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
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _dispatchKeyDown(logicalKey);
      _dispatchKeyUp(logicalKey);
    });
  }

  /// Simulate only key down — pair with [_simulateKeyUp] on release
  /// so widget-level long-press timers see real hold duration.
  void _simulateKeyDown(LogicalKeyboardKey logicalKey) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _dispatchKeyDown(logicalKey);
    });
  }

  /// Simulate only key up — the release half of [_simulateKeyDown].
  void _simulateKeyUp(LogicalKeyboardKey logicalKey) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _dispatchKeyUp(logicalKey);
    });
  }

  void _dispatchKeyDown(LogicalKeyboardKey logicalKey) {
    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode == null) return;

    final event = KeyDownEvent(
      physicalKey: _getPhysicalKey(logicalKey),
      logicalKey: logicalKey,
      timeStamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
    );

    FocusNode? node = focusNode;
    while (node != null) {
      if (node.onKeyEvent != null) {
        if (node.onKeyEvent!(node, event) == KeyEventResult.handled) break;
      }
      node = node.parent;
    }
  }

  void _dispatchKeyUp(LogicalKeyboardKey logicalKey) {
    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode == null) return;

    final event = KeyUpEvent(
      physicalKey: _getPhysicalKey(logicalKey),
      logicalKey: logicalKey,
      timeStamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
    );

    FocusNode? node = focusNode;
    while (node != null) {
      if (node.onKeyEvent != null) {
        if (node.onKeyEvent!(node, event) == KeyEventResult.handled) break;
      }
      node = node.parent;
    }
  }

  PhysicalKeyboardKey _getPhysicalKey(LogicalKeyboardKey logicalKey) {
    if (logicalKey == LogicalKeyboardKey.gameButtonA) {
      return PhysicalKeyboardKey.gameButtonA;
    } else if (logicalKey == LogicalKeyboardKey.gameButtonB) {
      return PhysicalKeyboardKey.gameButtonB;
    } else if (logicalKey == LogicalKeyboardKey.gameButtonX) {
      return PhysicalKeyboardKey.gameButtonX;
    } else if (logicalKey == LogicalKeyboardKey.arrowUp) {
      return PhysicalKeyboardKey.arrowUp;
    } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
      return PhysicalKeyboardKey.arrowDown;
    } else if (logicalKey == LogicalKeyboardKey.arrowLeft) {
      return PhysicalKeyboardKey.arrowLeft;
    } else if (logicalKey == LogicalKeyboardKey.arrowRight) {
      return PhysicalKeyboardKey.arrowRight;
    } else if (logicalKey == LogicalKeyboardKey.escape) {
      return PhysicalKeyboardKey.escape;
    }
    return PhysicalKeyboardKey.enter;
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
