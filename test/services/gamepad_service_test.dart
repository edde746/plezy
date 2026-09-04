import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/gamepad_service.dart';
import 'package:universal_gamepad/universal_gamepad.dart';

void main() {
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
