import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/utils/key_event_simulator.dart';

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

  testWidgets('simulateKeyUp returns to the key-down focus when focus changes', (tester) async {
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

    secondNode.requestFocus();
    await tester.pump();
    expect(secondNode.hasPrimaryFocus, isTrue);

    simulateKeyUp(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(firstEvents, hasLength(2));
    expect(firstEvents.last, isA<KeyUpEvent>());
    expect(secondEvents, isEmpty);
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
