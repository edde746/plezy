import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/key_event_simulator.dart';

void main() {
  testWidgets('simulateKeyPress dispatches directional pad key events', (tester) async {
    final events = await _pumpKeyEventRecorder(tester);

    scheduleFrameIfIdle();
    simulateKeyPress(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();

    expect(events, hasLength(2));
    expect(events.map((event) => event.deviceType), everyElement(ui.KeyEventDeviceType.directionalPad));
  });

  testWidgets('simulateKeyDown and simulateKeyUp dispatch held directional pad events', (tester) async {
    final events = await _pumpKeyEventRecorder(tester);

    simulateKeyDown(LogicalKeyboardKey.enter);
    simulateKeyUp(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();

    expect(events, hasLength(2));
    expect(events[0], isA<KeyDownEvent>());
    expect(events[1], isA<KeyUpEvent>());
    expect(events.map((event) => event.deviceType), everyElement(ui.KeyEventDeviceType.directionalPad));
  });

  testWidgets('custom simulator preserves gamepad device and physical key mapping', (tester) async {
    final events = await _pumpKeyEventRecorder(tester);
    final simulator = KeyEventSimulatorController(
      deviceType: ui.KeyEventDeviceType.gamepad,
      physicalKeyByLogicalKey: {LogicalKeyboardKey.enter: PhysicalKeyboardKey.gameButtonA},
    );
    addTearDown(simulator.dispose);

    simulator.simulateKeyPress(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(events, hasLength(2));
    expect(events.map((event) => event.deviceType), everyElement(ui.KeyEventDeviceType.gamepad));
    expect(events.map((event) => event.physicalKey), everyElement(PhysicalKeyboardKey.gameButtonA));
  });

  testWidgets('key repeat waits for the initial delay and then uses the repeat interval', (tester) async {
    final events = await _pumpKeyEventRecorder(tester);
    final simulator = KeyEventSimulatorController();
    addTearDown(simulator.dispose);

    simulator.startKeyRepeat(
      LogicalKeyboardKey.arrowDown,
      initialDelay: const Duration(milliseconds: 400),
      interval: const Duration(milliseconds: 80),
    );
    await tester.pump();

    expect(events, hasLength(2));
    expect(simulator.isRepeating, isTrue);

    await tester.pump(const Duration(milliseconds: 400));
    expect(events, hasLength(2));

    await tester.pump(const Duration(milliseconds: 79));
    expect(events, hasLength(2));

    await tester.pump(const Duration(milliseconds: 1));
    expect(events, hasLength(4));

    simulator.stopKeyRepeat();
    await tester.pump(const Duration(milliseconds: 160));
    expect(events, hasLength(4));
    expect(simulator.isRepeating, isFalse);
  });

  testWidgets('releaseKeys dispatches a held-key release burst after pending downs', (tester) async {
    final events = await _pumpKeyEventRecorder(tester);
    final simulator = KeyEventSimulatorController(deviceType: ui.KeyEventDeviceType.gamepad);
    addTearDown(simulator.dispose);

    simulator.simulateKeyDown(LogicalKeyboardKey.enter);
    simulator.simulateKeyDown(LogicalKeyboardKey.gameButtonX);
    simulator.releaseKeys([LogicalKeyboardKey.enter, LogicalKeyboardKey.gameButtonX]);
    await tester.pump();

    expect(events, hasLength(4));
    expect(events.map((event) => event.runtimeType), [KeyDownEvent, KeyDownEvent, KeyUpEvent, KeyUpEvent]);
    expect(events.map((event) => event.logicalKey), [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.gameButtonX,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.gameButtonX,
    ]);
    expect(events.map((event) => event.deviceType), everyElement(ui.KeyEventDeviceType.gamepad));
  });

  testWidgets('simulateKeyUp is delivered to the current focus, like a hardware release', (tester) async {
    final firstNode = FocusNode(debugLabel: 'first');
    final secondNode = FocusNode(debugLabel: 'second');
    addTearDown(firstNode.dispose);
    addTearDown(secondNode.dispose);

    final firstEvents = <KeyEvent>[];
    final secondEvents = <KeyEvent>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Focus(
              focusNode: firstNode,
              onKeyEvent: (_, event) {
                firstEvents.add(event);
                return KeyEventResult.handled;
              },
              child: const SizedBox(width: 10, height: 10),
            ),
            Focus(
              focusNode: secondNode,
              onKeyEvent: (_, event) {
                secondEvents.add(event);
                return KeyEventResult.handled;
              },
              child: const SizedBox(width: 10, height: 10),
            ),
          ],
        ),
      ),
    );
    firstNode.requestFocus();
    await tester.pump();

    simulateKeyDown(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(firstEvents, hasLength(1));
    expect(firstEvents.single, isA<KeyDownEvent>());
    expect(HardwareKeyboard.instance.logicalKeysPressed, contains(LogicalKeyboardKey.enter));

    secondNode.requestFocus();
    await tester.pump();
    expect(secondNode.hasPrimaryFocus, isTrue);

    simulateKeyUp(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(firstEvents, hasLength(1));
    expect(secondEvents.single, isA<KeyUpEvent>());
    expect(HardwareKeyboard.instance.logicalKeysPressed, isNot(contains(LogicalKeyboardKey.enter)));
  });

  testWidgets('synthetic keys reach HardwareKeyboard handlers and regularize against pressed state', (tester) async {
    final events = await _pumpKeyEventRecorder(tester);
    final hardwareEvents = <KeyEvent>[];
    bool observe(KeyEvent event) {
      hardwareEvents.add(event);
      return false;
    }

    HardwareKeyboard.instance.addHandler(observe);
    addTearDown(() => HardwareKeyboard.instance.removeHandler(observe));

    // A hardware press is already holding the key.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    hardwareEvents.clear();
    events.clear();

    simulateKeyDown(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(hardwareEvents.single, isA<KeyRepeatEvent>());
    expect(events.single, isA<KeyRepeatEvent>());

    simulateKeyUp(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(hardwareEvents.last, isA<KeyUpEvent>());
    expect(HardwareKeyboard.instance.logicalKeysPressed, isNot(contains(LogicalKeyboardKey.arrowLeft)));

    // A release for a key nobody holds is dropped rather than desynchronizing state.
    simulateKeyUp(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(hardwareEvents, hasLength(2));
  });

  testWidgets('simulateKeyPress stops at skipRemainingHandlers', (tester) async {
    final childEvents = <KeyEvent>[];
    final parentEvents = <KeyEvent>[];
    late BuildContext childContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          onKeyEvent: (_, event) {
            parentEvents.add(event);
            return KeyEventResult.handled;
          },
          child: Focus(
            autofocus: true,
            onKeyEvent: (_, event) {
              childEvents.add(event);
              return KeyEventResult.skipRemainingHandlers;
            },
            child: Builder(
              builder: (context) {
                childContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    Focus.of(childContext).requestFocus();
    await tester.pump();

    simulateKeyPress(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();

    expect(childEvents, hasLength(2));
    expect(parentEvents, isEmpty);
  });

  testWidgets('dispose releases held keys and cancels repeat timers', (tester) async {
    final events = await _pumpKeyEventRecorder(tester);
    final simulator = KeyEventSimulatorController();

    simulator.simulateKeyDown(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(events, hasLength(1));

    simulator.startKeyRepeat(
      LogicalKeyboardKey.arrowRight,
      initialDelay: const Duration(milliseconds: 400),
      interval: const Duration(milliseconds: 80),
    );
    simulator.dispose();
    simulator.simulateKeyUp(LogicalKeyboardKey.enter);

    await tester.pump(const Duration(seconds: 1));
    expect(events, hasLength(2));
    expect(events.first, isA<KeyDownEvent>());
    expect(events.last, isA<KeyUpEvent>());
    expect(events.last.logicalKey, LogicalKeyboardKey.enter);
    expect(HardwareKeyboard.instance.logicalKeysPressed, isEmpty);
  });
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
