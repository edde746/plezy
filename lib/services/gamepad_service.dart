import 'dart:async';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:gamepads/gamepads.dart';

import '../utils/app_logger.dart';

/// Service that bridges gamepad input to Flutter's focus navigation system.
///
/// Listens to gamepad events from the `gamepads` package and translates them
/// into focus navigation actions and key events that integrate with the
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

  // Track D-pad state to avoid repeated navigation events
  bool _dpadUp = false;
  bool _dpadDown = false;
  bool _dpadLeft = false;
  bool _dpadRight = false;

  // Track stick state to avoid repeated navigation events
  bool _leftStickUp = false;
  bool _leftStickDown = false;
  bool _leftStickLeft = false;
  bool _leftStickRight = false;

  // Track button states to prevent repeated events from button holds
  final Set<String> _pressedButtons = {};

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
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

    appLogger.i('GamepadService: Starting on ${Platform.operatingSystem}');

    // List connected gamepads
    try {
      final gamepads = await Gamepads.list();
      appLogger.i('GamepadService: Found ${gamepads.length} gamepad(s)');
      for (final gamepad in gamepads) {
        appLogger.i('  - ${gamepad.name} (id: ${gamepad.id})');
      }
    } catch (e) {
      appLogger.e('GamepadService: Error listing gamepads', error: e);
    }

    _subscription?.cancel();
    _subscription = Gamepads.events.listen(
      _handleGamepadEvent,
      onError: (e) => appLogger.e('GamepadService: Stream error', error: e),
    );
    appLogger.i('GamepadService: Listening for gamepad events');
  }

  /// Stop listening to gamepad events.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _handleGamepadEvent(GamepadEvent event) {
    final key = event.key.toLowerCase();
    final value = event.value;

    // Switch to keyboard mode on any significant gamepad input
    if (value.abs() > 0.3) {
      onGamepadInput?.call();
      _setTraditionalFocusHighlight();
      _scheduleFrameIfIdle();
    }

    // Handle D-pad (reported as axes on macOS)
    if (_isDpadYAxis(key)) {
      _handleDpadY(value);
      return;
    }
    if (_isDpadXAxis(key)) {
      _handleDpadX(value);
      return;
    }

    // Handle face buttons
    final isPressed = value > 0.5;
    final wasPressed = _pressedButtons.contains(key);

    if (isPressed && !wasPressed) {
      _pressedButtons.add(key);

      if (_isButtonA(key)) {
        // Use enter instead of gameButtonA so it works with Flutter's built-in
        // widgets (buttons, list tiles, etc.) which listen for enter
        _simulateKeyPress(LogicalKeyboardKey.enter);
      } else if (_isButtonB(key)) {
        // Use escape instead of gameButtonB so it works with Flutter's built-in
        // widgets (bottom sheets, dialogs, menus) which only listen for escape
        _simulateKeyPress(LogicalKeyboardKey.escape);
      } else if (_isButtonX(key)) {
        _simulateKeyPress(LogicalKeyboardKey.gameButtonX);
      } else if (_isL1(key)) {
        onL1Pressed?.call();
      } else if (_isR1(key)) {
        onR1Pressed?.call();
      }
    } else if (!isPressed && wasPressed) {
      _pressedButtons.remove(key);
    }

    // Handle left analog stick
    if (_isLeftStickY(key)) {
      _handleLeftStickY(value);
      return;
    }
    if (_isLeftStickX(key)) {
      _handleLeftStickX(value);
      return;
    }
  }

  void _moveFocus(TraversalDirection direction) {
    // Convert direction to arrow key and simulate a key press
    // This allows widgets like HubSection that intercept key events to handle navigation
    final logicalKey = _directionToKey(direction);
    _simulateKeyPress(logicalKey);
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

  void _simulateKeyPress(LogicalKeyboardKey logicalKey) {
    // Schedule on next frame to ensure we're on the main thread
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final focusNode = FocusManager.instance.primaryFocus;
      if (focusNode == null) return;

      // Create a synthetic key down event
      final keyDownEvent = KeyDownEvent(
        physicalKey: _getPhysicalKey(logicalKey),
        logicalKey: logicalKey,
        timeStamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
      );

      // Dispatch through the focus system by walking up the focus tree
      // and calling each node's onKeyEvent handler
      FocusNode? node = focusNode;
      KeyEventResult result = KeyEventResult.ignored;

      while (node != null && result != KeyEventResult.handled) {
        // The Focus widget stores its handler in onKeyEvent
        if (node.onKeyEvent != null) {
          result = node.onKeyEvent!(node, keyDownEvent);
        }
        node = node.parent;
      }

      // Send key up event
      final keyUpEvent = KeyUpEvent(
        physicalKey: _getPhysicalKey(logicalKey),
        logicalKey: logicalKey,
        timeStamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
      );

      node = focusNode;
      while (node != null) {
        if (node.onKeyEvent != null) {
          final upResult = node.onKeyEvent!(node, keyUpEvent);
          if (upResult == KeyEventResult.handled) break;
        }
        node = node.parent;
      }
    });
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

  // macOS DualSense key matching
  // D-pad reports as axes: dpad - xaxis, dpad - yaxis
  bool _isDpadYAxis(String key) => key == 'dpad - yaxis';
  bool _isDpadXAxis(String key) => key == 'dpad - xaxis';

  // Face buttons - macOS uses SF Symbol names for PlayStation controllers
  bool _isButtonA(String key) => key == 'xmark.circle'; // Cross/X button (bottom)
  bool _isButtonB(String key) => key == 'circle.circle'; // Circle/O button (right)
  bool _isButtonX(String key) => key == 'square.circle'; // Square button (left)

  // Analog sticks
  bool _isLeftStickX(String key) => key == 'l.joystick - xaxis';
  bool _isLeftStickY(String key) => key == 'l.joystick - yaxis';

  // Bumper buttons
  bool _isL1(String key) => key == 'l1.rectangle.roundedbottom';
  bool _isR1(String key) => key == 'r1.rectangle.roundedbottom';

  // D-pad Y axis: -1 = down (visually up on controller), 1 = up (visually down)
  // Inverted because macOS reports opposite of expected
  void _handleDpadY(double value) {
    if (value < -0.5 && !_dpadDown) {
      _dpadDown = true;
      _dpadUp = false;
      _moveFocus(TraversalDirection.down);
    } else if (value > 0.5 && !_dpadUp) {
      _dpadUp = true;
      _dpadDown = false;
      _moveFocus(TraversalDirection.up);
    } else if (value == 0) {
      _dpadUp = false;
      _dpadDown = false;
    }
  }

  // D-pad X axis: -1 = left, 1 = right, 0 = released
  void _handleDpadX(double value) {
    if (value < -0.5 && !_dpadLeft) {
      _dpadLeft = true;
      _dpadRight = false;
      _moveFocus(TraversalDirection.left);
    } else if (value > 0.5 && !_dpadRight) {
      _dpadRight = true;
      _dpadLeft = false;
      _moveFocus(TraversalDirection.right);
    } else if (value == 0) {
      _dpadLeft = false;
      _dpadRight = false;
    }
  }

  // Left stick Y axis - inverted like D-pad
  void _handleLeftStickY(double value) {
    if (value < -_stickDeadzone && !_leftStickDown) {
      _leftStickDown = true;
      _leftStickUp = false;
      _moveFocus(TraversalDirection.down);
    } else if (value > _stickDeadzone && !_leftStickUp) {
      _leftStickUp = true;
      _leftStickDown = false;
      _moveFocus(TraversalDirection.up);
    } else if (value.abs() <= _stickDeadzone) {
      _leftStickUp = false;
      _leftStickDown = false;
    }
  }

  void _handleLeftStickX(double value) {
    if (value < -_stickDeadzone && !_leftStickLeft) {
      _leftStickLeft = true;
      _leftStickRight = false;
      _moveFocus(TraversalDirection.left);
    } else if (value > _stickDeadzone && !_leftStickRight) {
      _leftStickRight = true;
      _leftStickLeft = false;
      _moveFocus(TraversalDirection.right);
    } else if (value.abs() <= _stickDeadzone) {
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

  // Force a frame when the engine is idle so focus visuals update immediately
  // on gamepad input (desktop may not wake up without mouse/keyboard activity).
  void _scheduleFrameIfIdle() {
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase == SchedulerPhase.idle) {
      scheduler.scheduleFrame();
    }
  }
}
