import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:universal_gamepad/universal_gamepad.dart';
import 'package:window_manager/window_manager.dart';

import '../focus/input_mode_tracker.dart';
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

/// Receives the original controller event while an interactive workspace
/// session owns gamepad input.
typedef GamepadInputEventHandler = void Function(GamepadEvent event);

/// Receives a native key event captured by an interactive workspace session.
typedef WorkspaceNativeKeyEventHandler = void Function(KeyEvent event);

/// Clears held controls in an interactive workspace session when its gamepad
/// input is interrupted.
typedef GamepadInputResetHandler = void Function(WorkspaceGameInputResetReason reason);

/// Why a workspace gamepad adapter must release its held controls.
enum WorkspaceGameInputResetReason {
  leaseReleased,
  windowFocusLost,
  applicationInactive,
  controllerDisconnected,
}

class _WorkspaceInputRegistration {
  const _WorkspaceInputRegistration({required this.onEvent, this.onNativeKeyEvent, this.onReset});

  final GamepadInputEventHandler onEvent;
  final WorkspaceNativeKeyEventHandler? onNativeKeyEvent;
  final GamepadInputResetHandler? onReset;
}

/// Suppresses synthetic gamepad key events when the OS has just delivered an
/// equivalent native key event, which happens when Steam Input's desktop layout
/// injects keyboard keys on Windows and Linux while the physical controller
/// stays readable.
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

@visibleForTesting
bool isTvosEngineOwnedGamepadButton({required bool isAppleTV, required GamepadButton button}) {
  if (!isAppleTV) return false;
  return switch (button) {
    GamepadButton.dpadUp ||
    GamepadButton.dpadDown ||
    GamepadButton.dpadLeft ||
    GamepadButton.dpadRight ||
    GamepadButton.a ||
    GamepadButton.b => true,
    _ => false,
  };
}

/// Service that bridges gamepad input to Flutter's focus navigation system.
///
/// Listens to gamepad events from the `universal_gamepad` package and translates
/// them into focus navigation actions and key events that integrate with the
/// existing keyboard navigation system.
class GamepadService with WindowListener, WidgetsBindingObserver {
  static final Map<GamepadButton, LogicalKeyboardKey> _syntheticKeyByButton = {
    GamepadButton.dpadUp: LogicalKeyboardKey.arrowUp,
    GamepadButton.dpadDown: LogicalKeyboardKey.arrowDown,
    GamepadButton.dpadLeft: LogicalKeyboardKey.arrowLeft,
    GamepadButton.dpadRight: LogicalKeyboardKey.arrowRight,
    GamepadButton.a: LogicalKeyboardKey.enter,
    GamepadButton.b: LogicalKeyboardKey.gameButtonB,
    GamepadButton.x: LogicalKeyboardKey.gameButtonX,
  };

  static const Map<GamepadButton, TraversalDirection> _directionByDpadButton = {
    GamepadButton.dpadUp: TraversalDirection.up,
    GamepadButton.dpadDown: TraversalDirection.down,
    GamepadButton.dpadLeft: TraversalDirection.left,
    GamepadButton.dpadRight: TraversalDirection.right,
  };

  /// Derived from [_syntheticKeyByButton] so a direction repeats the same key
  /// the duplicate guard checks for its D-pad button.
  static final Map<TraversalDirection, LogicalKeyboardKey> _syntheticKeyByDirection = {
    for (final MapEntry(key: button, value: direction) in _directionByDpadButton.entries)
      direction: _syntheticKeyByButton[button]!,
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
  final Map<Object, _WorkspaceInputRegistration> _workspaceInputHandlers = {};
  final Map<LogicalKeyboardKey, DateTime> _workspaceRawKeyEvents = {};
  final Set<LogicalKeyboardKey> _workspaceRawKeysHeld = {};
  Object? _workspaceInputOwner;

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

  static const double _stickDeadzone = 0.5;

  static const Duration _repeatInitialDelay = Duration(milliseconds: 400);
  static const Duration _repeatInterval = Duration(milliseconds: 80);

  key_sim.KeyEventSimulatorController? _keyEventSimulator;

  TraversalDirection? _leftStickYLatch;
  TraversalDirection? _leftStickXLatch;

  final Set<GamepadButton> _pressedButtons = {};
  final Set<GamepadButton> _suppressedButtons = {};
  bool _windowFocused = true;
  bool _nativeKeyHandlerRegistered = false;
  bool _appLifecycleObserverRegistered = false;
  bool _nativeTextInputFocused = false;

  @visibleForTesting
  static Future<void> Function(bool focused)? debugNativeTextInputFocusHandler;

  GamepadService._({GamepadDuplicateInputGuard? duplicateInputGuard})
    : _duplicateInputGuard = duplicateInputGuard ?? GamepadDuplicateInputGuard(enabled: _steamInputInjectsKeys);

  /// Steam Input can emit keyboard keys alongside controller events on
  /// Windows and Linux; macOS reads gamepads through GameController.
  @visibleForTesting
  static bool? debugSteamInputInjectsKeys;

  static bool _steamInputInjectsKeys() => debugSteamInputInjectsKeys ?? (Platform.isWindows || Platform.isLinux);

  /// Standalone instance for tests; never wired to the platform stream.
  @visibleForTesting
  factory GamepadService.forTesting({GamepadDuplicateInputGuard? duplicateInputGuard}) = GamepadService._;

  /// Registers an interactive workspace surface that can consume raw
  /// button, axis, and connection events. Only the owner selected by
  /// [setWorkspaceInputOwner] receives them.
  void registerWorkspaceInputHandler(
    Object owner,
    GamepadInputEventHandler handler, {
    WorkspaceNativeKeyEventHandler? onNativeKeyEvent,
    GamepadInputResetHandler? onReset,
  }) {
    _workspaceInputHandlers[owner] = _WorkspaceInputRegistration(
      onEvent: handler,
      onNativeKeyEvent: onNativeKeyEvent,
      onReset: onReset,
    );
  }

  /// Removes a workspace input handler and releases it if it currently owns
  /// input. This also stops any app-navigation keys left held at handoff.
  void unregisterWorkspaceInputHandler(Object owner) {
    if (_workspaceInputOwner == owner) setWorkspaceInputOwner(null);
    _workspaceInputHandlers.remove(owner);
  }

  /// Routes gamepad events to one interactive workspace surface. A missing
  /// handler for a non-null owner still consumes input, so events cannot leak
  /// into app navigation while an interactive surface is meant to own them.
  void setWorkspaceInputOwner(Object? owner) {
    if (owner != null && !_workspaceInputHandlers.containsKey(owner)) {
      throw ArgumentError.value(owner, 'owner', 'must have a registered workspace input handler');
    }
    if (_workspaceInputOwner == owner) return;
    final previousOwner = _workspaceInputOwner;
    if (previousOwner != null) {
      _notifyWorkspaceInputReset(previousOwner, WorkspaceGameInputResetReason.leaseReleased);
    }
    _releaseHeldInputState();
    _workspaceInputOwner = owner;
  }

  /// Releases [owner] only when it currently holds the input lease.
  ///
  /// Workspace registration sends an initial `false` callback to every
  /// non-focused game surface. That callback must not release a different
  /// game's active lease.
  void releaseWorkspaceInputOwner(Object owner) {
    if (_workspaceInputOwner == owner) setWorkspaceInputOwner(null);
  }

  bool _routeToWorkspaceInputOwner(GamepadEvent event) {
    final owner = _workspaceInputOwner;
    if (owner == null || !_windowFocused) return false;
    if (event is GamepadButtonEvent &&
        isTvosEngineOwnedGamepadButton(isAppleTV: PlatformDetector.isAppleTV(), button: event.button)) {
      return false;
    }

    if (event is GamepadButtonEvent && _steamInputInjectsKeys()) {
      final button = event;
      final key = _syntheticKeyByButton[button.button];
      if (key != null) {
        // If a Steam key arrived first and this adapter accepts keyboard
        // input, keep that event as the single representation. Otherwise the
        // raw controller event remains authoritative. The reverse order is
        // handled in [_handleNativeKeyEvent].
        if (_workspaceInputHandlers[owner]?.onNativeKeyEvent != null &&
            _duplicateInputGuard.shouldSuppressSyntheticKey(key)) {
          return true;
        }
        _workspaceRawKeyEvents[key] = DateTime.now();
        if (button.pressed) {
          _workspaceRawKeysHeld.add(key);
        } else {
          _workspaceRawKeysHeld.remove(key);
        }
      }
    }

    if (event is GamepadButtonEvent && event.pressed) {
      InputModeTracker.reportNonPointerInput();
    } else if (event is GamepadAxisEvent && event.value.abs() > _stickDeadzone) {
      InputModeTracker.reportNonPointerInput();
    } else if (event is GamepadConnectionEvent && !event.connected) {
      _notifyWorkspaceInputReset(owner, WorkspaceGameInputResetReason.controllerDisconnected);
      _releaseHeldInputState();
    }

    final registration = _workspaceInputHandlers[owner];
    if (registration != null) {
      try {
        registration.onEvent(event);
      } catch (error, stackTrace) {
        appLogger.e('GamepadService: Workspace input handler failed', error: error, stackTrace: stackTrace);
      }
    }
    return true;
  }

  void _notifyWorkspaceInputReset(Object owner, WorkspaceGameInputResetReason reason) {
    final handler = _workspaceInputHandlers[owner]?.onReset;
    if (handler == null) return;
    try {
      handler(reason);
    } catch (error, stackTrace) {
      appLogger.e('GamepadService: Workspace input reset handler failed', error: error, stackTrace: stackTrace);
    }
  }

  @visibleForTesting
  void debugSetWindowFocused(bool focused) {
    _setInputWindowFocused(focused);
  }

  void _setInputWindowFocused(
    bool focused, {
    WorkspaceGameInputResetReason resetReason = WorkspaceGameInputResetReason.windowFocusLost,
  }) {
    if (_windowFocused == focused) return;
    _windowFocused = focused;
    if (!focused) {
      final owner = _workspaceInputOwner;
      if (owner != null) _notifyWorkspaceInputReset(owner, resetReason);
      _releaseHeldInputState();
    }
  }

  /// Feeds [event] through the production event handler.
  @visibleForTesting
  void debugHandleGamepadEvent(GamepadEvent event) => _handleGamepadEvent(event);

  /// Feeds a native keyboard event through the duplicate-input guard.
  @visibleForTesting
  bool debugHandleNativeKeyEvent(KeyEvent event) => _handleNativeKeyEvent(event);

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
    if (!_appLifecycleObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _appLifecycleObserverRegistered = true;
    }
    _registerNativeKeyHandler();

    unawaited(_subscription?.cancel());
    _subscription = Gamepad.instance.events.listen(
      _handleGamepadEvent,
      onError: (e) => appLogger.e('GamepadService: Stream error', error: e),
    );
    appLogger.i('GamepadService: Listening for gamepad events');
  }

  @override
  void onWindowFocus() {
    debugSetWindowFocused(true);
    _duplicateInputGuard.clear();
    Gamepad.instance.resume();
  }

  @override
  void onWindowBlur() {
    debugSetWindowFocused(false);

    // Release native device handles so other apps can use the gamepad.
    Gamepad.instance.pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isDesktop) _setInputWindowFocused(true);
        break;
      case AppLifecycleState.inactive || AppLifecycleState.hidden || AppLifecycleState.paused:
        _setInputWindowFocused(false, resetReason: WorkspaceGameInputResetReason.applicationInactive);
        break;
      case AppLifecycleState.detached:
        _setInputWindowFocused(false, resetReason: WorkspaceGameInputResetReason.applicationInactive);
        break;
    }
  }

  /// Stops direction repeat and clears every held button and stick latch.
  ///
  /// Held-input state is global, not per-controller: any single gamepad
  /// disconnecting (or the window blurring) clears held state for all
  /// controllers.
  void _releaseHeldInputState() {
    _stopDirectionRepeat();

    // Release all face buttons in one frame so held widget state cannot stick.
    _simulator.releaseKeys([
      if (_pressedButtons.contains(GamepadButton.a)) LogicalKeyboardKey.enter,
      if (_pressedButtons.contains(GamepadButton.x)) LogicalKeyboardKey.gameButtonX,
    ]);
    _pressedButtons.clear();
    _suppressedButtons.clear();
    _duplicateInputGuard.clear();
    _workspaceRawKeyEvents.clear();
    _workspaceRawKeysHeld.clear();

    // Reset analog stick state so re-focus doesn't inherit stale direction
    _leftStickYLatch = null;
    _leftStickXLatch = null;
  }

  void _registerNativeKeyHandler() {
    if (_nativeKeyHandlerRegistered || !_steamInputInjectsKeys()) return;
    HardwareKeyboard.instance.addHandler(_handleNativeKeyEvent);
    _nativeKeyHandlerRegistered = true;
  }

  bool _handleNativeKeyEvent(KeyEvent event) {
    final owner = _workspaceInputOwner;
    if (owner != null && _steamInputInjectsKeys()) {
      final workspaceKey = _workspaceSyntheticKeyForNativeKey(event.logicalKey);
      if (workspaceKey != null) {
        if (_workspaceRawKeysHeld.contains(workspaceKey)) return true;
        final lastRawEvent = _workspaceRawKeyEvents[workspaceKey];
        if (lastRawEvent != null &&
            DateTime.now().difference(lastRawEvent) <= _duplicateInputGuard.suppressionWindow) {
          return true;
        }
        final registration = _workspaceInputHandlers[owner];
        final nativeKeyHandler = registration?.onNativeKeyEvent;
        if (nativeKeyHandler != null) {
          _duplicateInputGuard.handleNativeKeyEvent(event);
          try {
            nativeKeyHandler(event);
          } catch (error, stackTrace) {
            appLogger.e('GamepadService: Workspace keyboard handler failed', error: error, stackTrace: stackTrace);
          }
        }
        // Prevent desktop-layout keys from navigating the app while an
        // interactive surface owns input. If that surface only consumes raw
        // controller events, its matching raw event still passes through.
        return true;
      }
    }
    return _duplicateInputGuard.handleNativeKeyEvent(event);
  }

  LogicalKeyboardKey? _workspaceSyntheticKeyForNativeKey(LogicalKeyboardKey nativeKey) {
    for (final entry in GamepadDuplicateInputGuard._nativeAliasesBySyntheticKey.entries) {
      if (entry.value.contains(nativeKey)) return entry.key;
    }
    return null;
  }

  Future<void> _setNativeTextInputFocused(bool focused) async {
    if (TextInputDiagnostics.enabled) {
      _logGamepadDiag('setNativeTextInputFocused requested focused=$focused current=$_nativeTextInputFocused');
    }
    if (_nativeTextInputFocused == focused) {
      if (TextInputDiagnostics.enabled) _logGamepadDiag('setNativeTextInputFocused no-op focused=$focused');
      return;
    }
    _nativeTextInputFocused = focused;

    if (focused) {
      if (TextInputDiagnostics.enabled) {
        _logGamepadDiag('native text input focused; clearing repeat/buttons/duplicate guard before pause');
      }
      _stopDirectionRepeat();
      _pressedButtons.clear();
      _suppressedButtons.clear();
      _keyEventSimulator?.clearHeldKeys();
      _duplicateInputGuard.clear();
    }

    final debugHandler = debugNativeTextInputFocusHandler;
    if (debugHandler != null) {
      if (TextInputDiagnostics.enabled) {
        _logGamepadDiag('setNativeTextInputFocused using debug handler focused=$focused');
      }
      await debugHandler(focused);
      return;
    }

    try {
      if (focused) {
        if (TextInputDiagnostics.enabled) _logGamepadDiag('calling Gamepad.pause for native text input');
        await Gamepad.instance.pause();
        if (TextInputDiagnostics.enabled) _logGamepadDiag('Gamepad.pause completed for native text input');
      } else {
        if (TextInputDiagnostics.enabled) _logGamepadDiag('calling Gamepad.resume after native text input');
        await Gamepad.instance.resume();
        if (TextInputDiagnostics.enabled) _logGamepadDiag('Gamepad.resume completed after native text input');
      }
    } catch (e) {
      appLogger.e('GamepadService: Failed to ${focused ? "pause" : "resume"} for native text input', error: e);
    }
  }

  void _handleGamepadEvent(GamepadEvent event) {
    if (TextInputDiagnostics.enabled) {
      _logGamepadDiag('event received type=${event.runtimeType} nativeTextInputFocused=$_nativeTextInputFocused');
    }
    if (_routeToWorkspaceInputOwner(event)) return;
    switch (event) {
      case final GamepadConnectionEvent e:
        appLogger.i('GamepadService: Gamepad ${e.connected ? "connected" : "disconnected"}: ${e.info.name}');
        if (TextInputDiagnostics.enabled) {
          _logGamepadDiag('connection connected=${e.connected} info=${e.info.name}/${e.info.id}');
        }
        // A controller that vanishes mid-hold never sends its releases: drop
        // the repeat timer and held keys so navigation cannot run away. The
        // plugin stays live for any remaining controllers.
        if (!e.connected) _releaseHeldInputState();
      case final GamepadButtonEvent e:
        _handleButton(e);
      case final GamepadAxisEvent e:
        _handleAxis(e);
    }
  }

  void _handleButton(GamepadButtonEvent event) {
    if (TextInputDiagnostics.enabled) {
      _logGamepadDiag(
        'button received ${_describeGamepadButton(event)} windowFocused=$_windowFocused nativeTextInputFocused=$_nativeTextInputFocused',
      );
    }
    if (!_windowFocused) {
      if (TextInputDiagnostics.enabled) {
        _logGamepadDiag('button ignored because window is not focused ${_describeGamepadButton(event)}');
      }
      return;
    }
    if (isTvosEngineOwnedGamepadButton(isAppleTV: PlatformDetector.isAppleTV(), button: event.button)) {
      if (TextInputDiagnostics.enabled) {
        _logGamepadDiag('button ignored because tvOS engine owns its key lifecycle ${_describeGamepadButton(event)}');
      }
      return;
    }

    // Switch to keyboard mode on any button press
    if (event.pressed) {
      InputModeTracker.reportNonPointerInput();
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
        if (TextInputDiagnostics.enabled) {
          _logGamepadDiag('button suppressed by duplicate guard ${_describeGamepadButton(event)}');
        }
        _suppressedButtons.add(event.button);
        return;
      }

      // D-pad — navigate with auto-repeat while held
      final direction = _directionByDpadButton[event.button];
      if (direction != null) {
        if (TextInputDiagnostics.enabled) {
          _logGamepadDiag('button starts direction repeat ${direction.name} ${_describeGamepadButton(event)}');
        }
        _startDirectionRepeat(direction);
        return;
      }

      switch (event.button) {
        // Face buttons — send KeyDown on press, KeyUp on release
        // so widget-level long-press timers work naturally
        case GamepadButton.a:
          if (TextInputDiagnostics.enabled) {
            _logGamepadDiag('button simulates key down enter ${_describeGamepadButton(event)}');
          }
          _simulator.simulateKeyDown(LogicalKeyboardKey.enter);
        case GamepadButton.x:
          if (TextInputDiagnostics.enabled) {
            _logGamepadDiag('button simulates key down context/menu ${_describeGamepadButton(event)}');
          }
          _simulator.simulateKeyDown(LogicalKeyboardKey.gameButtonX);
        // Immediate actions on press
        case GamepadButton.b:
          if (TextInputDiagnostics.enabled) {
            _logGamepadDiag('button simulates key press back ${_describeGamepadButton(event)}');
          }
          _simulator.simulateKeyPress(LogicalKeyboardKey.gameButtonB);
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
        if (TextInputDiagnostics.enabled) {
          _logGamepadDiag('button release consumed by suppressed set ${_describeGamepadButton(event)}');
        }
        return;
      }

      // D-pad release — stop repeat
      switch (event.button) {
        case GamepadButton.dpadUp:
        case GamepadButton.dpadDown:
        case GamepadButton.dpadLeft:
        case GamepadButton.dpadRight:
          if (TextInputDiagnostics.enabled) {
            _logGamepadDiag('button stops direction repeat ${_describeGamepadButton(event)}');
          }
          _stopDirectionRepeat();
        // Face button release — send KeyUp
        case GamepadButton.a:
          if (TextInputDiagnostics.enabled) {
            _logGamepadDiag('button simulates key up enter ${_describeGamepadButton(event)}');
          }
          _simulator.simulateKeyUp(LogicalKeyboardKey.enter);
        case GamepadButton.x:
          if (TextInputDiagnostics.enabled) {
            _logGamepadDiag('button simulates key up context/menu ${_describeGamepadButton(event)}');
          }
          _simulator.simulateKeyUp(LogicalKeyboardKey.gameButtonX);
        default:
          break;
      }
    }
  }

  bool _shouldSuppressButton(GamepadButton button) {
    final syntheticKey = _syntheticKeyByButton[button];
    final suppressed = syntheticKey != null && _duplicateInputGuard.shouldSuppressSyntheticKey(syntheticKey);
    if (TextInputDiagnostics.enabled) {
      _logGamepadDiag('duplicate guard button=$button syntheticKey=$syntheticKey suppressed=$suppressed');
    }
    return suppressed;
  }

  void _handleAxis(GamepadAxisEvent event) {
    if (TextInputDiagnostics.enabled) {
      _logGamepadDiag(
        'axis received ${_describeGamepadAxis(event)} windowFocused=$_windowFocused nativeTextInputFocused=$_nativeTextInputFocused',
      );
    }
    if (!_windowFocused) {
      if (TextInputDiagnostics.enabled) {
        _logGamepadDiag('axis ignored because window is not focused ${_describeGamepadAxis(event)}');
      }
      return;
    }

    // Promotion must fire on the same event that navigates: gating below the
    // real deadzone would let analog-stick drift hide the desktop cursor.
    if (event.value.abs() > _stickDeadzone) {
      InputModeTracker.reportNonPointerInput();
    }

    switch (event.axis) {
      // W3C: leftStickY -1.0 = up, 1.0 = down
      case GamepadAxis.leftStickY:
        _leftStickYLatch = _latchStickAxis(
          event.value,
          _leftStickYLatch,
          negative: TraversalDirection.up,
          positive: TraversalDirection.down,
        );
      case GamepadAxis.leftStickX:
        _leftStickXLatch = _latchStickAxis(
          event.value,
          _leftStickXLatch,
          negative: TraversalDirection.left,
          positive: TraversalDirection.right,
        );
      default:
        break;
    }
  }

  /// Fire [direction] immediately, then auto-repeat after an initial delay.
  void _startDirectionRepeat(TraversalDirection direction) {
    if (TextInputDiagnostics.enabled) _logGamepadDiag('startDirectionRepeat direction=$direction');
    _stopDirectionRepeat();
    final logicalKey = _syntheticKeyByDirection[direction]!;
    if (TextInputDiagnostics.enabled) {
      _logGamepadDiag(
        'moveFocus direction=$direction logicalKey=${logicalKey.keyLabel}/${logicalKey.keyId} nativeTextInputFocused=$_nativeTextInputFocused',
      );
    }
    _simulator.startKeyRepeat(logicalKey, initialDelay: _repeatInitialDelay, interval: _repeatInterval);
  }

  void _stopDirectionRepeat() {
    if (_keyEventSimulator?.isRepeating ?? false) {
      if (TextInputDiagnostics.enabled) _logGamepadDiag('stopDirectionRepeat');
    }
    _keyEventSimulator?.stopKeyRepeat();
  }

  /// Latches one stick axis to the direction it is deflected past the
  /// deadzone. A fresh deflection starts the repeat, holding it past the
  /// deadzone is ignored so the repeat is not restarted, and re-centring stops
  /// it. Returns the axis's new latch; [held] is its previous one.
  TraversalDirection? _latchStickAxis(
    double value,
    TraversalDirection? held, {
    required TraversalDirection negative,
    required TraversalDirection positive,
  }) {
    if (value > _stickDeadzone) {
      if (held != positive) _startDirectionRepeat(positive);
      return positive;
    }
    if (value < -_stickDeadzone) {
      if (held != negative) _startDirectionRepeat(negative);
      return negative;
    }
    if (held != null) _stopDirectionRepeat();
    return null;
  }
}
