import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/dpad_navigator.dart';
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

  testWidgets('a simulated release ends a select suppression no focus handler consumed', (tester) async {
    await _pumpKeyEventRecorder(tester);
    final simulator = KeyEventSimulatorController();
    addTearDown(simulator.dispose);
    addTearDown(SelectKeyUpSuppressor.clearSuppression);

    simulator.simulateKeyDown(LogicalKeyboardKey.enter);
    await tester.pump();
    // A long press arms the suppressor and moves focus into a menu, so the
    // release (delivered to the key-down node) reaches no consumer of it.
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    simulator.simulateKeyUp(LogicalKeyboardKey.enter);
    await tester.pump();

    const nextPress = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.enter,
      logicalKey: LogicalKeyboardKey.enter,
      timeStamp: Duration.zero,
    );
    expect(SelectKeyUpSuppressor.consumeIfSuppressed(nextPress), isFalse, reason: 'the next press must not be eaten');
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

  testWidgets('dispose cancels queued dispatch and repeat timers', (tester) async {
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
    expect(events, hasLength(1));
    expect(events.single, isA<KeyDownEvent>());
  });

  group('events queued for one frame wait for focus to settle', () {
    testWidgets('presses behind a pop reach the uncovered route instead of popping it (#2937)', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final homeNode = FocusNode(debugLabel: 'home');
      final detailNode = FocusNode(debugLabel: 'detail');
      addTearDown(homeNode.dispose);
      addTearDown(detailNode.dispose);
      final homeKeyDowns = <KeyEvent>[];
      var detailPops = 0;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Focus(
            focusNode: homeNode,
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent) homeKeyDowns.add(event);
              return KeyEventResult.handled;
            },
            child: const Text('home'),
          ),
        ),
      );
      homeNode.requestFocus();
      await tester.pump();
      unawaited(
        navigatorKey.currentState!.push(
          MaterialPageRoute<void>(
            builder: (context) => Focus(
              focusNode: detailNode,
              // Leaves with a blind pop, as the detail screen's back did.
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent) {
                  detailPops++;
                  Navigator.pop(context);
                }
                return KeyEventResult.handled;
              },
              child: const Text('detail'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      detailNode.requestFocus();
      await tester.pump();

      final simulator = KeyEventSimulatorController(deviceType: ui.KeyEventDeviceType.gamepad);
      addTearDown(simulator.dispose);
      // Presses that arrive while a frame is stalled all dispatch in the next
      // frame's post-frame pass. Read unsettled, the second popped home and the
      // third threw "Bad state: No element" on the emptied navigator.
      for (var i = 0; i < 3; i++) {
        simulator.simulateKeyPress(LogicalKeyboardKey.enter);
      }
      await tester.pumpAndSettle();

      expect(detailPops, 1);
      expect(homeKeyDowns, hasLength(2));
      expect(find.text('home'), findsOneWidget);
      expect(navigatorKey.currentState!.canPop(), isFalse);
    });

    testWidgets('a press behind a push reaches the pushed route, not the one it covers (#3197)', (tester) async {
      final openerNode = FocusNode(debugLabel: 'opener');
      addTearDown(openerNode.dispose);
      final pushedEvents = <KeyEvent>[];
      var opens = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Focus(
              focusNode: openerNode,
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent) {
                  opens++;
                  unawaited(
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Focus(
                          autofocus: true,
                          onKeyEvent: (_, event) {
                            pushedEvents.add(event);
                            return KeyEventResult.handled;
                          },
                          child: const Text('pushed'),
                        ),
                      ),
                    ),
                  );
                }
                return KeyEventResult.handled;
              },
              child: const Text('opener'),
            ),
          ),
        ),
      );
      openerNode.requestFocus();
      await tester.pump();

      final simulator = KeyEventSimulatorController(deviceType: ui.KeyEventDeviceType.gamepad);
      addTearDown(simulator.dispose);
      simulator.simulateKeyPress(LogicalKeyboardKey.enter);
      // The pushed route takes focus only once built, a frame later; the held
      // press and its release wait for it, in order.
      simulator.simulateKeyDown(LogicalKeyboardKey.enter);
      simulator.simulateKeyUp(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(opens, 1);
      expect(pushedEvents.map((event) => event.runtimeType), [KeyDownEvent, KeyUpEvent]);
      expect(find.text('pushed'), findsOneWidget);
    });

    testWidgets('a press behind an outer-navigator push skips the nested route it covers', (tester) async {
      final openerNode = FocusNode(debugLabel: 'nested_opener');
      addTearDown(openerNode.dispose);
      final coverKeyDowns = <KeyEvent>[];
      var opens = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) => Focus(
                focusNode: openerNode,
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent) {
                    opens++;
                    unawaited(
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute<void>(
                          builder: (_) => Focus(
                            autofocus: true,
                            onKeyEvent: (_, event) {
                              if (event is KeyDownEvent) coverKeyDowns.add(event);
                              return KeyEventResult.handled;
                            },
                            child: const Text('cover'),
                          ),
                        ),
                      ),
                    );
                  }
                  return KeyEventResult.handled;
                },
                child: const Text('nested'),
              ),
            ),
          ),
        ),
      );
      openerNode.requestFocus();
      await tester.pump();

      final simulator = KeyEventSimulatorController(deviceType: ui.KeyEventDeviceType.gamepad);
      addTearDown(simulator.dispose);
      // The nested route stays current in its own navigator; only the route
      // hosting that navigator is covered.
      simulator.simulateKeyPress(LogicalKeyboardKey.enter);
      simulator.simulateKeyPress(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(opens, 1);
      expect(coverKeyDowns, hasLength(1));
      expect(find.text('cover'), findsOneWidget);
    });
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
