import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
    _log('simulateKeyPress scheduled logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
    _schedule((focusNode) {
      final physicalKey = _physicalKeyFor(logicalKey);
      _dispatchKeyEvent(focusNode, _keyDownEvent(logicalKey, physicalKey));
      _dispatchKeyEvent(focusNode, _keyUpEvent(logicalKey, physicalKey));
    });
  }

  /// Simulates key down and remembers its focus until key up.
  void simulateKeyDown(LogicalKeyboardKey logicalKey) {
    if (_disposed) return;
    _log('simulateKeyDown scheduled logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
    _schedule((focusNode) {
      _heldFocusNodes[logicalKey] = focusNode;
      _dispatchKeyEvent(focusNode, _keyDownEvent(logicalKey, _physicalKeyFor(logicalKey)));
    });
  }

  /// Simulates key up on the focus that received the matching key down.
  void simulateKeyUp(LogicalKeyboardKey logicalKey) {
    if (_disposed) return;
    _log('simulateKeyUp scheduled logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
    scheduleFrameIfIdle();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) _dispatchKeyUp(logicalKey);
    });
  }

  /// Releases [logicalKeys] together after previously scheduled key downs.
  ///
  /// Any remaining held state is cleared after the release burst.
  void releaseKeys(Iterable<LogicalKeyboardKey> logicalKeys) {
    if (_disposed) return;
    final keys = logicalKeys.toList(growable: false);
    scheduleFrameIfIdle();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      for (final logicalKey in keys) {
        _dispatchKeyUp(logicalKey);
      }
      _heldFocusNodes.clear();
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
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      final focusNode = FocusManager.instance.primaryFocus;
      if (focusNode != null) dispatch(focusNode);
    });
  }

  void _dispatchKeyUp(LogicalKeyboardKey logicalKey) {
    final heldFocusNode = _heldFocusNodes.remove(logicalKey);
    final focusNode = heldFocusNode ?? FocusManager.instance.primaryFocus;
    if (focusNode == null) return;
    if (heldFocusNode != null && heldFocusNode.context == null) {
      _log('simulateKeyUp dropped detached held focus logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
      return;
    }

    _dispatchKeyEvent(focusNode, _keyUpEvent(logicalKey, _physicalKeyFor(logicalKey)));
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
    _log('dispatch start focus=${focusNode.debugLabel} key=(${_describeSimulatedKey(event)})');
    FocusNode? node = focusNode;
    while (node != null) {
      if (node.onKeyEvent != null) {
        final result = node.onKeyEvent!(node, event);
        _log('dispatch node=${node.debugLabel} result=$result key=(${_describeSimulatedKey(event)})');
        if (result != KeyEventResult.ignored) {
          _log('dispatch stopped node=${node.debugLabel} result=$result');
          break;
        }
      }
      node = node.parent;
    }
    if (node == null) {
      _log('dispatch reached root ignored key=(${_describeSimulatedKey(event)})');
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
