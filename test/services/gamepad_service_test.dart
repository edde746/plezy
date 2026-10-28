import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/multiview/workspace_game_input.dart';
import 'package:plezy/services/gamepad_service.dart';
import 'package:universal_gamepad/universal_gamepad.dart';

void main() {
  testWidgets('workspace game input receives raw controller events without app navigation keys', (tester) async {
    final keyEvents = await _pumpKeyEventRecorder(tester);
    final service = GamepadService.forTesting(duplicateInputGuard: GamepadDuplicateInputGuard(enabled: () => false));
    final routed = <GamepadEvent>[];
    final resets = <WorkspaceGameInputResetReason>[];
    final binding = WorkspaceGameInputBinding(service: service, onEvent: routed.add, onInputReset: resets.add);
    addTearDown(binding.dispose);

    binding.setEnabled(true);
    service.debugHandleGamepadEvent(_button(GamepadButton.a, pressed: true));
    service.debugHandleGamepadEvent(_axis(GamepadAxis.leftStickX, 0.8));
    service.debugHandleGamepadEvent(_button(GamepadButton.a, pressed: false));
    service.debugHandleGamepadEvent(_disconnect());
    await tester.pump();

    expect(routed, hasLength(4));
    expect(routed[0], isA<GamepadButtonEvent>());
    expect(routed[1], isA<GamepadAxisEvent>());
    expect(routed[2], isA<GamepadButtonEvent>());
    expect(routed[3], isA<GamepadConnectionEvent>());
    expect(resets, [WorkspaceGameInputResetReason.controllerDisconnected]);
    expect(keyEvents, isEmpty);

    binding.setEnabled(false);
    expect(resets, [WorkspaceGameInputResetReason.controllerDisconnected, WorkspaceGameInputResetReason.leaseReleased]);
    service.debugHandleGamepadEvent(_button(GamepadButton.a, pressed: true));
    await tester.pump();
    expect(_downCount(keyEvents, LogicalKeyboardKey.enter), 1);
    service.debugHandleGamepadEvent(_button(GamepadButton.a, pressed: false));
    await tester.pump();
  });

  test('window focus loss asks the workspace game to release held controls', () {
    final service = GamepadService.forTesting(duplicateInputGuard: GamepadDuplicateInputGuard(enabled: () => false));
    final resets = <WorkspaceGameInputResetReason>[];
    final binding = WorkspaceGameInputBinding(service: service, onEvent: (_) {}, onInputReset: resets.add);
    addTearDown(binding.dispose);

    binding.setEnabled(true);
    service.debugSetWindowFocused(false);
    service.debugSetWindowFocused(false);
    service.debugSetWindowFocused(true);

    expect(resets, [WorkspaceGameInputResetReason.windowFocusLost]);
  });

  test('application backgrounding asks the workspace game to release held controls', () {
    final service = GamepadService.forTesting(duplicateInputGuard: GamepadDuplicateInputGuard(enabled: () => false));
    final resets = <WorkspaceGameInputResetReason>[];
    final binding = WorkspaceGameInputBinding(service: service, onEvent: (_) {}, onInputReset: resets.add);
    addTearDown(binding.dispose);

    binding.setEnabled(true);
    service.didChangeAppLifecycleState(AppLifecycleState.inactive);

    expect(resets, [WorkspaceGameInputResetReason.applicationInactive]);
  });

  testWidgets('a non-focused game cannot release another surface input lease', (tester) async {
    final keyEvents = await _pumpKeyEventRecorder(tester);
    final service = GamepadService.forTesting(duplicateInputGuard: GamepadDuplicateInputGuard(enabled: () => false));
    final firstEvents = <GamepadEvent>[];
    final secondEvents = <GamepadEvent>[];
    final first = WorkspaceGameInputBinding(service: service, onEvent: firstEvents.add);
    final second = WorkspaceGameInputBinding(service: service, onEvent: secondEvents.add);
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    first.setEnabled(true);
    second.setEnabled(false);
    service.debugHandleGamepadEvent(_button(GamepadButton.a, pressed: true));
    service.debugHandleGamepadEvent(_button(GamepadButton.a, pressed: false));
    await tester.pump();

    expect(firstEvents, hasLength(2));
    expect(secondEvents, isEmpty);
    expect(keyEvents, isEmpty);
  });

  testWidgets('workspace game input consumes Steam key mirrors when controller events arrive first', (tester) async {
    GamepadService.debugSteamInputInjectsKeys = true;
    addTearDown(() => GamepadService.debugSteamInputInjectsKeys = null);
    final service = GamepadService.forTesting(duplicateInputGuard: GamepadDuplicateInputGuard(enabled: () => true));
    final routed = <GamepadEvent>[];
    final binding = WorkspaceGameInputBinding(service: service, onEvent: routed.add);
    addTearDown(binding.dispose);

    binding.setEnabled(true);
    service.debugHandleGamepadEvent(_button(GamepadButton.a, pressed: true));
    expect(service.debugHandleNativeKeyEvent(_keyDown(LogicalKeyboardKey.enter)), isTrue);
    service.debugHandleGamepadEvent(_button(GamepadButton.a, pressed: false));
    expect(service.debugHandleNativeKeyEvent(_keyUp(LogicalKeyboardKey.enter)), isTrue);

    expect(routed, hasLength(2));
    expect(routed.every((event) => event is GamepadButtonEvent), isTrue);
  });

  testWidgets('raw controller input is preserved when Steam keys arrive first without a keyboard handler', (
    tester,
  ) async {
    GamepadService.debugSteamInputInjectsKeys = true;
    addTearDown(() => GamepadService.debugSteamInputInjectsKeys = null);
    final service = GamepadService.forTesting(duplicateInputGuard: GamepadDuplicateInputGuard(enabled: () => true));
    final routed = <GamepadEvent>[];
    final binding = WorkspaceGameInputBinding(service: service, onEvent: routed.add);
    addTearDown(binding.dispose);

    binding.setEnabled(true);
    expect(service.debugHandleNativeKeyEvent(_keyDown(LogicalKeyboardKey.enter)), isTrue);
    service.debugHandleGamepadEvent(_button(GamepadButton.a, pressed: true));
    expect(service.debugHandleNativeKeyEvent(_keyUp(LogicalKeyboardKey.enter)), isTrue);
    service.debugHandleGamepadEvent(_button(GamepadButton.a, pressed: false));

    expect(routed, hasLength(2));
    expect(routed.every((event) => event is GamepadButtonEvent), isTrue);
  });

  testWidgets('Steam key first is routed once when the workspace also accepts keyboard input', (tester) async {
    GamepadService.debugSteamInputInjectsKeys = true;
    addTearDown(() => GamepadService.debugSteamInputInjectsKeys = null);
    final service = GamepadService.forTesting(duplicateInputGuard: GamepadDuplicateInputGuard(enabled: () => true));
    final routed = <GamepadEvent>[];
    final keyboardEvents = <KeyEvent>[];
    final binding = WorkspaceGameInputBinding(
      service: service,
      onEvent: routed.add,
      onNativeKeyEvent: keyboardEvents.add,
    );
    addTearDown(binding.dispose);

    binding.setEnabled(true);
    expect(service.debugHandleNativeKeyEvent(_keyDown(LogicalKeyboardKey.enter)), isTrue);
    service.debugHandleGamepadEvent(_button(GamepadButton.a, pressed: true));
    expect(service.debugHandleNativeKeyEvent(_keyUp(LogicalKeyboardKey.enter)), isTrue);
    service.debugHandleGamepadEvent(_button(GamepadButton.a, pressed: false));

    expect(routed, isEmpty);
    expect(keyboardEvents, hasLength(2));
  });

  test('workspace captures letter keys without Steam desktop-layout emulation', () {
    GamepadService.debugSteamInputInjectsKeys = false;
    addTearDown(() => GamepadService.debugSteamInputInjectsKeys = null);
    final service = GamepadService.forTesting();
    final events = <KeyEvent>[];
    final binding = WorkspaceGameInputBinding(service: service, onEvent: (_) {}, onNativeKeyEvent: events.add);
    addTearDown(binding.dispose);
    binding.setEnabled(true);
    expect(service.debugHandleNativeKeyEvent(_keyDown(LogicalKeyboardKey.keyW)), isTrue);
    expect(service.debugHandleNativeKeyEvent(_keyUp(LogicalKeyboardKey.keyW)), isTrue);
    service.debugSetWindowFocused(false);
    expect(service.debugHandleNativeKeyEvent(_keyDown(LogicalKeyboardKey.keyA)), isFalse);
    service.debugSetWindowFocused(true);
    binding.setEnabled(false);
    expect(service.debugHandleNativeKeyEvent(_keyDown(LogicalKeyboardKey.keyD)), isFalse);
    expect(events.map((event) => event.logicalKey), [LogicalKeyboardKey.keyW, LogicalKeyboardKey.keyW]);
  });

  testWidgets('Shift Escape remains available to release the workspace input lease', (tester) async {
    final service = GamepadService.forTesting();
    final events = <KeyEvent>[];
    final binding = WorkspaceGameInputBinding(service: service, onEvent: (_) {}, onNativeKeyEvent: events.add);
    addTearDown(binding.dispose);
    binding.setEnabled(true);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    expect(service.debugHandleNativeKeyEvent(_keyDown(LogicalKeyboardKey.escape)), isFalse);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(events, isEmpty);
  });

  testWidgets('taking gamepad ownership releases app navigation repeats', (tester) async {
    final keyEvents = await _pumpKeyEventRecorder(tester);
    final service = GamepadService.forTesting(duplicateInputGuard: GamepadDuplicateInputGuard(enabled: () => false));
    final binding = WorkspaceGameInputBinding(service: service, onEvent: (_) {});
    addTearDown(binding.dispose);

    service.debugHandleGamepadEvent(_button(GamepadButton.dpadRight, pressed: true));
    await tester.pump();
    expect(_downCount(keyEvents, LogicalKeyboardKey.arrowRight), 1);

    binding.setEnabled(true);
    await tester.pump();
    expect(_upCount(keyEvents, LogicalKeyboardKey.arrowRight), 1);
    final repeatsAfterHandoff = _downCount(keyEvents, LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(_downCount(keyEvents, LogicalKeyboardKey.arrowRight), repeatsAfterHandoff);
  });

  testWidgets('gamepad disconnect stops held-direction repeat and releases held keys', (tester) async {
    final events = await _pumpKeyEventRecorder(tester);
    final service = GamepadService.forTesting(duplicateInputGuard: GamepadDuplicateInputGuard(enabled: () => false));

    service.debugHandleGamepadEvent(_button(GamepadButton.dpadRight, pressed: true));
    service.debugHandleGamepadEvent(_button(GamepadButton.a, pressed: true));
    await tester.pump();

    expect(_downCount(events, LogicalKeyboardKey.arrowRight), 1);
    expect(_downCount(events, LogicalKeyboardKey.enter), 1);

    // Let the auto-repeat engage: 400ms initial delay, then 80ms intervals.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump();
    expect(_downCount(events, LogicalKeyboardKey.arrowRight), greaterThan(1));

    service.debugHandleGamepadEvent(_disconnect());
    await tester.pump();

    // The held A key was released by the disconnect teardown.
    expect(_upCount(events, LogicalKeyboardKey.enter), 1);

    final repeatsAtDisconnect = _downCount(events, LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(
      _downCount(events, LogicalKeyboardKey.arrowRight),
      repeatsAtDisconnect,
      reason: 'no synthesized repeats may fire after the controller disconnects',
    );

    // Held-button state was cleared: the release that never arrived from the
    // dead controller cannot double-fire when a reconnected pad sends it.
    service.debugHandleGamepadEvent(_button(GamepadButton.a, pressed: false));
    await tester.pump();
    expect(_upCount(events, LogicalKeyboardKey.enter), 1);
  });

  testWidgets('gamepad disconnect clears stick latches so a reconnected stick navigates again', (tester) async {
    final events = await _pumpKeyEventRecorder(tester);
    final service = GamepadService.forTesting(duplicateInputGuard: GamepadDuplicateInputGuard(enabled: () => false));

    service.debugHandleGamepadEvent(_axis(GamepadAxis.leftStickY, 1.0));
    await tester.pump();
    expect(_downCount(events, LogicalKeyboardKey.arrowDown), 1);

    service.debugHandleGamepadEvent(_disconnect());
    await tester.pump();

    final repeatsAtDisconnect = _downCount(events, LogicalKeyboardKey.arrowDown);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(_downCount(events, LogicalKeyboardKey.arrowDown), repeatsAtDisconnect);

    // The latch was cleared, so a fresh deflection navigates immediately
    // without first passing back through the deadzone.
    service.debugHandleGamepadEvent(_axis(GamepadAxis.leftStickY, 1.0));
    await tester.pump();
    expect(_downCount(events, LogicalKeyboardKey.arrowDown), repeatsAtDisconnect + 1);

    // Return the stick to the deadzone so the new repeat timer is cancelled.
    service.debugHandleGamepadEvent(_axis(GamepadAxis.leftStickY, 0.0));
    await tester.pump();
  });
}

GamepadButtonEvent _button(GamepadButton button, {required bool pressed}) {
  return GamepadButtonEvent(gamepadId: 1, timestamp: 0, button: button, pressed: pressed, value: pressed ? 1.0 : 0.0);
}

GamepadAxisEvent _axis(GamepadAxis axis, double value) {
  return GamepadAxisEvent(gamepadId: 1, timestamp: 0, axis: axis, value: value);
}

GamepadConnectionEvent _disconnect() {
  return GamepadConnectionEvent(
    gamepadId: 1,
    timestamp: 0,
    connected: false,
    info: const GamepadInfo(id: 1, name: 'Test Pad'),
  );
}

KeyDownEvent _keyDown(LogicalKeyboardKey logicalKey) {
  return KeyDownEvent(
    physicalKey: logicalKey == LogicalKeyboardKey.enter ? PhysicalKeyboardKey.enter : PhysicalKeyboardKey.arrowRight,
    logicalKey: logicalKey,
    timeStamp: const Duration(milliseconds: 1),
  );
}

KeyUpEvent _keyUp(LogicalKeyboardKey logicalKey) {
  return KeyUpEvent(
    physicalKey: logicalKey == LogicalKeyboardKey.enter ? PhysicalKeyboardKey.enter : PhysicalKeyboardKey.arrowRight,
    logicalKey: logicalKey,
    timeStamp: const Duration(milliseconds: 1),
  );
}

int _downCount(List<KeyEvent> events, LogicalKeyboardKey key) {
  return events.whereType<KeyDownEvent>().where((e) => e.logicalKey == key).length;
}

int _upCount(List<KeyEvent> events, LogicalKeyboardKey key) {
  return events.whereType<KeyUpEvent>().where((e) => e.logicalKey == key).length;
}

Future<List<KeyEvent>> _pumpKeyEventRecorder(WidgetTester tester) async {
  final events = <KeyEvent>[];
  late BuildContext focusContext;

  await tester.pumpWidget(
    MaterialApp(
      home: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          events.add(event);
          return KeyEventResult.handled;
        },
        child: Builder(
          builder: (context) {
            focusContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  Focus.of(focusContext).requestFocus();
  await tester.pump();
  expect(Focus.of(focusContext).hasPrimaryFocus, isTrue);
  return events;
}
