import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'text_input_diagnostics.dart';

void _logKeySimulator(String message) {
  TextInputDiagnostics.log('KeySimulator', message);
}

final KeyEventSimulatorController _defaultSimulator = KeyEventSimulatorController();

/// Shared utility for simulating key press events through the framework's key
/// pipeline.
///
/// Used by companion remotes, Apple TV touch input, and gamepad services to
/// translate external input into key events that behave exactly like hardware
/// keys.
void simulateKeyPress(LogicalKeyboardKey logicalKey) {
  _defaultSimulator.simulateKeyPress(logicalKey);
}

/// Simulate only key down. Pair with [simulateKeyUp] for held buttons.
void simulateKeyDown(LogicalKeyboardKey logicalKey) {
  _defaultSimulator.simulateKeyDown(logicalKey);
}

/// Simulate only key up. The release half of [simulateKeyDown].
void simulateKeyUp(LogicalKeyboardKey logicalKey) {
  _defaultSimulator.simulateKeyUp(logicalKey);
}

/// Simulates key events for one external input source.
///
/// Every event enters the engine's own key entry point,
/// [ui.PlatformDispatcher.onKeyData], so it runs the complete framework
/// pipeline a hardware key does: [HardwareKeyboard] pressed-key state and every
/// registered hardware handler (input-mode tracking, transport keys, the hotkey
/// recorder), then the focus system's early handlers, the focus chain from the
/// primary focus upward, and its late handlers. A synthetic press is therefore
/// indistinguishable from a hardware press to every consumer, including a KeyUp
/// that lands on whatever holds focus at release time.
///
/// Events are marked [ui.KeyData.synthesized] because that is the framework's
/// documented shape for a key event with no native counterpart: it is
/// dispatched at once instead of being held for the raw-key message that
/// follows every native event. No key consumer in the framework or this app
/// reads the flag.
///
/// The stream is regularized against [HardwareKeyboard]'s pressed state so two
/// sources sharing a physical key cannot produce a double KeyDown or an
/// unmatched KeyUp: a KeyDown for a pressed key becomes a repeat, a KeyUp for
/// an unpressed key is dropped.
///
/// Separate instances isolate repeat timers when multiple input sources are
/// active.
class KeyEventSimulatorController {
  final ui.KeyEventDeviceType deviceType;
  final Map<LogicalKeyboardKey, PhysicalKeyboardKey> physicalKeyByLogicalKey;
  final void Function(String) _log;

  final Set<LogicalKeyboardKey> _heldKeys = {};
  Timer? _repeatTimer;
  bool _disposed = false;

  KeyEventSimulatorController({
    this.deviceType = ui.KeyEventDeviceType.directionalPad,
    this.physicalKeyByLogicalKey = const {},
    void Function(String)? log,
  }) : _log = log ?? _logKeySimulator;

  bool get isRepeating => _repeatTimer != null;

  /// Simulates a full key press (down and up) in one frame.
  void simulateKeyPress(LogicalKeyboardKey logicalKey) {
    if (_disposed) return;
    if (TextInputDiagnostics.enabled) {
      _log('simulateKeyPress scheduled logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
    }
    _schedule(() {
      _dispatchKeyDown(logicalKey);
      _dispatchKeyUp(logicalKey);
    });
  }

  /// Simulates key down; the key stays pressed until [simulateKeyUp].
  void simulateKeyDown(LogicalKeyboardKey logicalKey) {
    if (_disposed) return;
    if (TextInputDiagnostics.enabled) {
      _log('simulateKeyDown scheduled logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
    }
    _schedule(() {
      _heldKeys.add(logicalKey);
      _dispatchKeyDown(logicalKey);
    });
  }

  /// Simulates key up, delivered to whatever holds focus at release time.
  void simulateKeyUp(LogicalKeyboardKey logicalKey) {
    if (_disposed) return;
    if (TextInputDiagnostics.enabled) {
      _log('simulateKeyUp scheduled logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
    }
    _schedule(() {
      _heldKeys.remove(logicalKey);
      _dispatchKeyUp(logicalKey);
    });
  }

  /// Releases [logicalKeys] together after previously scheduled key downs.
  ///
  /// Any key this source still holds afterwards is released as well, so a
  /// disconnecting device cannot leave the framework's pressed state stale.
  void releaseKeys(Iterable<LogicalKeyboardKey> logicalKeys) {
    if (_disposed) return;
    final keys = logicalKeys.toList(growable: false);
    _schedule(() {
      for (final logicalKey in keys) {
        _heldKeys.remove(logicalKey);
        _dispatchKeyUp(logicalKey);
      }
      _releaseHeldKeys();
    });
  }

  /// Starts with an immediate press, then repeats after [initialDelay].
  void startKeyRepeat(LogicalKeyboardKey logicalKey, {required Duration initialDelay, required Duration interval}) {
    if (_disposed) return;
    stopKeyRepeat();
    simulateKeyPress(logicalKey);
    _repeatTimer = Timer(initialDelay, () {
      if (_disposed) return;
      _repeatTimer = Timer.periodic(interval, (_) => simulateKeyPress(logicalKey));
    });
  }

  void stopKeyRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  /// Releases every key this source still holds.
  void clearHeldKeys() {
    if (_disposed || _heldKeys.isEmpty) return;
    _schedule(_releaseHeldKeys);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopKeyRepeat();
    // Held keys are released synchronously: a post-frame callback would be
    // skipped by the disposed guard.
    _releaseHeldKeys();
  }

  /// Frames an event may wait for primary focus to leave a route that is no
  /// longer current. A route pushed by the previous event takes focus in the
  /// frame that first builds it; the second frame is slack for a nested
  /// navigator's cover exclusion. The cap keeps a route that never takes focus
  /// from swallowing input: past it, the event goes where a hardware key would.
  static const _maxFocusSettleFrames = 2;

  void _schedule(VoidCallback dispatch) {
    // Post-frame dispatch lets focus settle. Requesting a frame is essential
    // when external input arrives while Flutter is otherwise idle.
    scheduleFrameIfIdle();
    _afterFocusSettles(dispatch);
  }

  /// Runs [dispatch] in a post-frame callback once focus has settled.
  ///
  /// Every event queued for a frame runs in that frame's post-frame pass, but
  /// the focus moves requested by the frame's build — or by an earlier event in
  /// the same pass — wait for a microtask that runs only after the pass. Read
  /// then, primary focus is where it stood before those moves: a second back
  /// after a pop lands on the closing route and pops the screen beneath it,
  /// until the emptied navigator throws (#2937, #2370); a select after a push
  /// acts on the route the push covered (#3197). So pending changes are applied
  /// first, and an event that would go to a focus left in a route that is no
  /// longer current waits for the route above to take focus.
  void _afterFocusSettles(VoidCallback dispatch, {int waitedFrames = 0}) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      FocusManager.instance.applyFocusChangesIfNeeded();
      final focusNode = FocusManager.instance.primaryFocus;
      if (waitedFrames < _maxFocusSettleFrames && focusNode != null && _isInNonCurrentRoute(focusNode)) {
        if (TextInputDiagnostics.enabled) {
          _log('dispatch deferred: focus=${focusNode.debugLabel} is in a route that is not current');
        }
        // Re-queued callbacks keep their order, so a release still follows its
        // press. A post-frame callback does not request the frame it waits for.
        _afterFocusSettles(dispatch, waitedFrames: waitedFrames + 1);
        SchedulerBinding.instance.scheduleFrame();
        return;
      }
      dispatch();
    });
  }

  void _releaseHeldKeys() {
    if (_heldKeys.isEmpty) return;
    final held = _heldKeys.toList(growable: false);
    _heldKeys.clear();
    for (final logicalKey in held) {
      _dispatchKeyUp(logicalKey);
    }
  }

  void _dispatchKeyDown(LogicalKeyboardKey logicalKey) {
    final physicalKey = _physicalKeyFor(logicalKey);
    final alreadyPressed = HardwareKeyboard.instance.physicalKeysPressed.contains(physicalKey);
    _dispatch(alreadyPressed ? ui.KeyEventType.repeat : ui.KeyEventType.down, logicalKey, physicalKey);
  }

  void _dispatchKeyUp(LogicalKeyboardKey logicalKey) {
    final physicalKey = _physicalKeyFor(logicalKey);
    if (!HardwareKeyboard.instance.physicalKeysPressed.contains(physicalKey)) {
      if (TextInputDiagnostics.enabled) {
        _log('simulateKeyUp dropped unpressed logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
      }
      return;
    }
    _dispatch(ui.KeyEventType.up, logicalKey, physicalKey);
  }

  void _dispatch(ui.KeyEventType type, LogicalKeyboardKey logicalKey, PhysicalKeyboardKey physicalKey) {
    final data = ui.KeyData(
      timeStamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
      type: type,
      physical: physicalKey.usbHidUsage,
      logical: logicalKey.keyId,
      character: null,
      synthesized: true,
      deviceType: deviceType,
    );
    if (TextInputDiagnostics.enabled) {
      _log(
        'dispatch type=$type focus=${FocusManager.instance.primaryFocus?.debugLabel} '
        'logical=${logicalKey.keyLabel}/${logicalKey.keyId} physical=${physicalKey.usbHidUsage} deviceType=$deviceType',
      );
    }
    final handled = ui.PlatformDispatcher.instance.onKeyData?.call(data) ?? false;
    if (TextInputDiagnostics.enabled) {
      _log('dispatch done type=$type handled=$handled logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
    }
  }

  PhysicalKeyboardKey _physicalKeyFor(LogicalKeyboardKey logicalKey) {
    return physicalKeyByLogicalKey[logicalKey] ?? _getPhysicalKey(logicalKey);
  }
}

/// Whether [node] is in a route that is not the visible one: covered by a route
/// pushed above it, or popped and animating out.
///
/// Walks out through enclosing navigators, because a route pushed on an outer
/// navigator covers a nested stack whose own top route still reports current.
bool _isInNonCurrentRoute(FocusNode node) {
  var context = node.context;
  while (context != null && context.mounted) {
    final route = ModalRoute.of(context);
    if (route == null) return false;
    if (!route.isCurrent) return true;
    context = route.navigator?.focusNode.context;
  }
  return false;
}

/// Force a frame when the engine is idle so focus visuals update immediately
/// on external input (desktop may not wake up without mouse/keyboard activity).
void scheduleFrameIfIdle() {
  if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
    SchedulerBinding.instance.scheduleFrame();
  }
}

PhysicalKeyboardKey _getPhysicalKey(LogicalKeyboardKey logicalKey) {
  if (logicalKey == LogicalKeyboardKey.arrowUp) return PhysicalKeyboardKey.arrowUp;
  if (logicalKey == LogicalKeyboardKey.arrowDown) return PhysicalKeyboardKey.arrowDown;
  if (logicalKey == LogicalKeyboardKey.arrowLeft) return PhysicalKeyboardKey.arrowLeft;
  if (logicalKey == LogicalKeyboardKey.arrowRight) return PhysicalKeyboardKey.arrowRight;
  if (logicalKey == LogicalKeyboardKey.enter) return PhysicalKeyboardKey.enter;
  if (logicalKey == LogicalKeyboardKey.select) return PhysicalKeyboardKey.select;
  if (logicalKey == LogicalKeyboardKey.escape) return PhysicalKeyboardKey.escape;
  if (logicalKey == LogicalKeyboardKey.space) return PhysicalKeyboardKey.space;
  if (logicalKey == LogicalKeyboardKey.contextMenu) return PhysicalKeyboardKey.contextMenu;
  if (logicalKey == LogicalKeyboardKey.audioVolumeUp) return PhysicalKeyboardKey.audioVolumeUp;
  if (logicalKey == LogicalKeyboardKey.audioVolumeDown) return PhysicalKeyboardKey.audioVolumeDown;
  if (logicalKey == LogicalKeyboardKey.audioVolumeMute) return PhysicalKeyboardKey.audioVolumeMute;
  if (logicalKey == LogicalKeyboardKey.keyF) return PhysicalKeyboardKey.keyF;
  if (logicalKey == LogicalKeyboardKey.gameButtonA) return PhysicalKeyboardKey.gameButtonA;
  if (logicalKey == LogicalKeyboardKey.gameButtonB) return PhysicalKeyboardKey.gameButtonB;
  if (logicalKey == LogicalKeyboardKey.gameButtonX) return PhysicalKeyboardKey.gameButtonX;
  return PhysicalKeyboardKey.enter;
}
