import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../focus/dpad_navigator.dart';
import 'text_input_diagnostics.dart';

String _describeSimulatedKey(KeyEvent event) {
  return 'type=${event.runtimeType} logical=${event.logicalKey.keyLabel}/${event.logicalKey.keyId} '
      'physical=${event.physicalKey.usbHidUsage} deviceType=${event.deviceType}';
}

void _logKeySimulator(String message) {
  TextInputDiagnostics.log('KeySimulator', message);
}

final KeyEventSimulatorController _defaultSimulator = KeyEventSimulatorController();

/// Shared utility for simulating key press events through the focus tree.
///
/// Used by companion remotes, Apple TV touch input, and gamepad services to
/// translate external input into focus-tree key events.
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
/// Separate instances isolate held keys and repeat timers when multiple input
/// sources are active.
class KeyEventSimulatorController {
  final ui.KeyEventDeviceType deviceType;
  final Map<LogicalKeyboardKey, PhysicalKeyboardKey> physicalKeyByLogicalKey;
  final void Function(String) _log;

  /// Frames an event may wait for primary focus to leave a route that is no
  /// longer current. A route pushed by the previous event takes focus in the
  /// frame that first builds it; the second frame is slack for a nested
  /// navigator's cover exclusion. The cap keeps a route that never takes focus
  /// from swallowing input: past it, the event goes where a hardware key would.
  static const _maxFocusSettleFrames = 2;

  final Map<LogicalKeyboardKey, FocusNode> _heldFocusNodes = {};
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
    _schedule((focusNode) {
      final physicalKey = _physicalKeyFor(logicalKey);
      _dispatchKeyEvent(focusNode, _keyDownEvent(logicalKey, physicalKey));
      _dispatchKeyEvent(focusNode, _keyUpEvent(logicalKey, physicalKey));
    });
  }

  /// Simulates key down and remembers its focus until key up.
  void simulateKeyDown(LogicalKeyboardKey logicalKey) {
    if (_disposed) return;
    if (TextInputDiagnostics.enabled) {
      _log('simulateKeyDown scheduled logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
    }
    _schedule((focusNode) {
      _heldFocusNodes[logicalKey] = focusNode;
      _dispatchKeyEvent(focusNode, _keyDownEvent(logicalKey, _physicalKeyFor(logicalKey)));
    });
  }

  /// Simulates key up on the focus that received the matching key down.
  void simulateKeyUp(LogicalKeyboardKey logicalKey) {
    if (_disposed) return;
    if (TextInputDiagnostics.enabled) {
      _log('simulateKeyUp scheduled logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
    }
    scheduleFrameIfIdle();
    _afterFocusSettles(
      () => _dispatchKeyUp(logicalKey),
      targetsPrimaryFocus: () => !_heldFocusNodes.containsKey(logicalKey),
    );
  }

  /// Releases [logicalKeys] together after previously scheduled key downs.
  ///
  /// Any remaining held state is cleared after the release burst.
  void releaseKeys(Iterable<LogicalKeyboardKey> logicalKeys) {
    if (_disposed) return;
    final keys = logicalKeys.toList(growable: false);
    scheduleFrameIfIdle();
    _afterFocusSettles(() {
      for (final logicalKey in keys) {
        _dispatchKeyUp(logicalKey);
      }
      _heldFocusNodes.clear();
    }, targetsPrimaryFocus: () => !keys.every(_heldFocusNodes.containsKey));
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

  void clearHeldKeys() {
    _heldFocusNodes.clear();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopKeyRepeat();
    _heldFocusNodes.clear();
  }

  void _schedule(void Function(FocusNode focusNode) dispatch) {
    // Post-frame dispatch lets focus settle. Requesting a frame is essential
    // when external input arrives while Flutter is otherwise idle.
    scheduleFrameIfIdle();
    _afterFocusSettles(() {
      final focusNode = FocusManager.instance.primaryFocus;
      if (focusNode != null) dispatch(focusNode);
    });
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
  /// longer current waits for the route above to take focus. [targetsPrimaryFocus]
  /// is false for a release whose press is held: it returns to the press's node.
  void _afterFocusSettles(VoidCallback dispatch, {bool Function()? targetsPrimaryFocus, int waitedFrames = 0}) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      FocusManager.instance.applyFocusChangesIfNeeded();
      final focusNode = FocusManager.instance.primaryFocus;
      if (waitedFrames < _maxFocusSettleFrames &&
          focusNode != null &&
          (targetsPrimaryFocus?.call() ?? true) &&
          _isInNonCurrentRoute(focusNode)) {
        if (TextInputDiagnostics.enabled) {
          _log('dispatch deferred: focus=${focusNode.debugLabel} is in a route that is not current');
        }
        // Re-queued callbacks keep their order, so a release still follows its
        // press. A post-frame callback does not request the frame it waits for.
        _afterFocusSettles(dispatch, targetsPrimaryFocus: targetsPrimaryFocus, waitedFrames: waitedFrames + 1);
        SchedulerBinding.instance.scheduleFrame();
        return;
      }
      dispatch();
    });
  }

  void _dispatchKeyUp(LogicalKeyboardKey logicalKey) {
    final heldFocusNode = _heldFocusNodes.remove(logicalKey);
    final focusNode = heldFocusNode ?? FocusManager.instance.primaryFocus;
    final event = _keyUpEvent(logicalKey, _physicalKeyFor(logicalKey));
    if (focusNode == null || (heldFocusNode != null && heldFocusNode.context == null)) {
      if (heldFocusNode != null && TextInputDiagnostics.enabled) {
        _log('simulateKeyUp dropped detached held focus logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
      }
      // Undelivered, but the release still happened.
      observeSimulatedKeyEvent(event);
      return;
    }

    _dispatchKeyEvent(focusNode, event);
  }

  KeyDownEvent _keyDownEvent(LogicalKeyboardKey logicalKey, PhysicalKeyboardKey physicalKey) {
    return KeyDownEvent(
      physicalKey: physicalKey,
      logicalKey: logicalKey,
      timeStamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
      deviceType: deviceType,
    );
  }

  KeyUpEvent _keyUpEvent(LogicalKeyboardKey logicalKey, PhysicalKeyboardKey physicalKey) {
    return KeyUpEvent(
      physicalKey: physicalKey,
      logicalKey: logicalKey,
      timeStamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
      deviceType: deviceType,
    );
  }

  void _dispatchKeyEvent(FocusNode focusNode, KeyEvent event) {
    if (TextInputDiagnostics.enabled) {
      _log('dispatch start focus=${focusNode.debugLabel} key=(${_describeSimulatedKey(event)})');
    }
    // The HardwareKeyboard phase this dispatch bypasses: suppressors end an
    // armed press on its release there.
    observeSimulatedKeyEvent(event);
    FocusNode? node = focusNode;
    while (node != null) {
      if (node.onKeyEvent != null) {
        final result = node.onKeyEvent!(node, event);
        if (TextInputDiagnostics.enabled) {
          _log('dispatch node=${node.debugLabel} result=$result key=(${_describeSimulatedKey(event)})');
        }
        if (result != KeyEventResult.ignored) {
          if (TextInputDiagnostics.enabled) _log('dispatch stopped node=${node.debugLabel} result=$result');
          break;
        }
      }
      node = node.parent;
    }
    if (node == null) {
      if (TextInputDiagnostics.enabled) {
        _log('dispatch reached root ignored key=(${_describeSimulatedKey(event)})');
      }
    }
  }

  PhysicalKeyboardKey _physicalKeyFor(LogicalKeyboardKey logicalKey) {
    return physicalKeyByLogicalKey[logicalKey] ?? _getPhysicalKey(logicalKey);
  }
}

/// Force a frame when the engine is idle so focus visuals update immediately
/// on external input (desktop may not wake up without mouse/keyboard activity).
void scheduleFrameIfIdle() {
  if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
    SchedulerBinding.instance.scheduleFrame();
  }
}

/// Whether [node] is in a route that is not the visible one: covered by a route
/// pushed above it, or popped and animating out.
///
/// Walks out through enclosing navigators, because a route pushed on an outer
/// navigator covers a nested stack whose own top route still reports current.
/// The lookup subscribes [node]'s element, then the navigator's own focus
/// element (cheap to rebuild, unlike the navigator, which rebuilds every route
/// page on a dependency change), to route status — sanctioned for event
/// handlers that read the value once.
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
