import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app_logger.dart';
import 'platform_detector.dart';

String _describeSimulatedKey(KeyEvent event) {
  return 'type=${event.runtimeType} logical=${event.logicalKey.keyLabel}/${event.logicalKey.keyId} '
      'physical=${event.physicalKey.usbHidUsage} deviceType=${event.deviceType}';
}

void _logKeySimulator(String message) {
  if (!PlatformDetector.isTV()) return;
  appLogger.i('TextInputDiag KeySimulator: $message');
}

/// Shared utility for simulating key press events through the focus tree.
///
/// Used by companion remotes, Apple TV touch input, and gamepad services to
/// translate external input into focus-tree key events.
void simulateKeyPress(LogicalKeyboardKey logicalKey) {
  _logKeySimulator('simulateKeyPress scheduled logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
  // The dispatch below is deferred via addPostFrameCallback to ensure the
  // focus tree is settled before we walk it. That post-frame callback only
  // fires after a frame actually renders — and when Flutter is idle (no
  // animations, no rebuilds), the engine will never schedule one on its
  // own, so the callback hangs indefinitely. Force a frame so external
  // input (gamepad, tvOS remote, companion remote) always advances focus
  // immediately rather than batching until something else wakes the engine.
  scheduleFrameIfIdle();
  SchedulerBinding.instance.addPostFrameCallback((_) {
    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode == null) return;

    final physicalKey = _getPhysicalKey(logicalKey);

    final keyDownEvent = KeyDownEvent(
      physicalKey: physicalKey,
      logicalKey: logicalKey,
      timeStamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
      deviceType: ui.KeyEventDeviceType.directionalPad,
    );

    _dispatchKeyEvent(focusNode, keyDownEvent);

    final keyUpEvent = KeyUpEvent(
      physicalKey: physicalKey,
      logicalKey: logicalKey,
      timeStamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
      deviceType: ui.KeyEventDeviceType.directionalPad,
    );

    _dispatchKeyEvent(focusNode, keyUpEvent);
  });
}

/// Simulate only key down. Pair with [simulateKeyUp] for held buttons.
void simulateKeyDown(LogicalKeyboardKey logicalKey) {
  _logKeySimulator('simulateKeyDown scheduled logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
  scheduleFrameIfIdle();
  SchedulerBinding.instance.addPostFrameCallback((_) {
    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode == null) return;

    _dispatchKeyEvent(
      focusNode,
      KeyDownEvent(
        physicalKey: _getPhysicalKey(logicalKey),
        logicalKey: logicalKey,
        timeStamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
        deviceType: ui.KeyEventDeviceType.directionalPad,
      ),
    );
  });
}

/// Simulate only key up. The release half of [simulateKeyDown].
void simulateKeyUp(LogicalKeyboardKey logicalKey) {
  _logKeySimulator('simulateKeyUp scheduled logical=${logicalKey.keyLabel}/${logicalKey.keyId}');
  scheduleFrameIfIdle();
  SchedulerBinding.instance.addPostFrameCallback((_) {
    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode == null) return;

    _dispatchKeyEvent(
      focusNode,
      KeyUpEvent(
        physicalKey: _getPhysicalKey(logicalKey),
        logicalKey: logicalKey,
        timeStamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
        deviceType: ui.KeyEventDeviceType.directionalPad,
      ),
    );
  });
}

void _dispatchKeyEvent(FocusNode focusNode, KeyEvent event) {
  _logKeySimulator('dispatch start focus=${focusNode.debugLabel} key=(${_describeSimulatedKey(event)})');
  FocusNode? node = focusNode;
  while (node != null) {
    if (node.onKeyEvent != null) {
      final result = node.onKeyEvent!(node, event);
      _logKeySimulator('dispatch node=${node.debugLabel} result=$result key=(${_describeSimulatedKey(event)})');
      if (result != KeyEventResult.ignored) {
        _logKeySimulator('dispatch stopped node=${node.debugLabel} result=$result');
        break;
      }
    }
    node = node.parent;
  }
  if (node == null) {
    _logKeySimulator('dispatch reached root ignored key=(${_describeSimulatedKey(event)})');
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
