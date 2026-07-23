import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/dpad_navigator.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/focus/key_event_utils.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
    BackKeyUpSuppressor.clearSuppression();
    BackKeyCoordinator.clear();
  });

  testWidgets('tvOS physical keyboard back runs on key down and suppresses key up', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    var backs = 0;

    final downResult = handleBackKeyAction(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.keyboard,
      ),
      () => backs++,
    );

    final upResult = handleBackKeyAction(
      const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.keyboard,
      ),
      () => backs++,
    );

    expect(downResult, KeyEventResult.handled);
    expect(upResult, KeyEventResult.handled);
    expect(backs, 1);
    await tester.pump();
  });

  testWidgets('tvOS remote back runs on key down for non-keyboard device types', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    var backs = 0;

    final downResult = handleBackKeyAction(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.directionalPad,
      ),
      () => backs++,
    );

    final upResult = handleBackKeyAction(
      const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
        deviceType: ui.KeyEventDeviceType.directionalPad,
      ),
      () => backs++,
    );

    expect(downResult, KeyEventResult.handled);
    expect(upResult, KeyEventResult.handled);
    expect(backs, 1);
    await tester.pump();
  });

  test('one-shot select consumes every phase and activates only on key down', () {
    var activations = 0;
    const down = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.select,
      logicalKey: LogicalKeyboardKey.select,
      timeStamp: Duration.zero,
    );
    const repeat = KeyRepeatEvent(
      physicalKey: PhysicalKeyboardKey.select,
      logicalKey: LogicalKeyboardKey.select,
      timeStamp: Duration(milliseconds: 100),
    );
    const up = KeyUpEvent(
      physicalKey: PhysicalKeyboardKey.select,
      logicalKey: LogicalKeyboardKey.select,
      timeStamp: Duration(milliseconds: 200),
    );
    const unrelated = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.f12,
      logicalKey: LogicalKeyboardKey.f12,
      timeStamp: Duration.zero,
    );

    expect(handleOneShotSelect(down, () => activations++), KeyEventResult.handled);
    expect(handleOneShotSelect(repeat, () => activations++), KeyEventResult.handled);
    expect(handleOneShotSelect(up, () => activations++), KeyEventResult.handled);
    expect(handleOneShotSelect(unrelated, () => activations++), KeyEventResult.ignored);
    expect(activations, 1);
  });
  group('BackKeyCoordinator', () {
    testWidgets('suppresses one parallel back dispatch in the current frame', (tester) async {
      BackKeyCoordinator.markHandled();

      expect(BackKeyCoordinator.consumeIfHandled(), isTrue);
      expect(BackKeyCoordinator.consumeIfHandled(), isFalse);
      await tester.pump();
    });

    testWidgets('does not suppress an independent system back in a later frame', (tester) async {
      BackKeyCoordinator.markHandled();
      await tester.pump();

      expect(BackKeyCoordinator.consumeIfHandled(), isFalse);
    });

    testWidgets('clear discards a pending duplicate marker', (tester) async {
      BackKeyCoordinator.markHandled();
      BackKeyCoordinator.clear();

      expect(BackKeyCoordinator.consumeIfHandled(), isFalse);
      await tester.pump();
    });
  });

  group('dpadKeyHandler trapHorizontalEdges', () {
    testWidgets('consumes edge LEFT/RIGHT so focus cannot escape the group', (tester) async {
      final trapped = FocusNode(debugLabel: 'trapped');
      final outside = FocusNode(debugLabel: 'outside');
      addTearDown(trapped.dispose);
      addTearDown(outside.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Focus(
                  focusNode: trapped,
                  onKeyEvent: dpadKeyHandler(trapHorizontalEdges: true),
                  child: const SizedBox(width: 50, height: 50),
                ),
                Focus(focusNode: outside, child: const SizedBox(width: 50, height: 50)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      trapped.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'trapped');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'trapped');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'trapped');
    });

    testWidgets('default (no trap) still lets edge RIGHT pass through to the framework', (tester) async {
      final node = FocusNode(debugLabel: 'node');
      final outside = FocusNode(debugLabel: 'outside');
      addTearDown(node.dispose);
      addTearDown(outside.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Focus(focusNode: node, onKeyEvent: dpadKeyHandler(), child: const SizedBox(width: 50, height: 50)),
                Focus(focusNode: outside, child: const SizedBox(width: 50, height: 50)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'outside');
    });
  });

  group('FocusableActionBar edge trapping', () {
    testWidgets('traps LEFT/RIGHT at row edges when no horizontal nav is wired', (tester) async {
      final key = GlobalKey<FocusableActionBarState>();
      final outside = FocusNode(debugLabel: 'outside');
      addTearDown(outside.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                FocusableActionBar(
                  key: key,
                  actions: [
                    FocusableAction(icon: Icons.add, onPressed: () {}),
                    FocusableAction(icon: Icons.remove, onPressed: () {}),
                  ],
                ),
                Focus(focusNode: outside, child: const SizedBox(width: 50, height: 50)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState!.requestFocusOnFirst();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');

      // Interior RIGHT moves to the next button.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[1]');

      // RIGHT at the last button is trapped — must NOT escape to 'outside'.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[1]');

      // LEFT back to the first, then LEFT again is trapped.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');
    });

    testWidgets('skips disabled actions for entry and horizontal traversal', (tester) async {
      final key = GlobalKey<FocusableActionBarState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FocusableActionBar(
              key: key,
              actions: [
                const FocusableAction(icon: Icons.block),
                FocusableAction(icon: Icons.add, onPressed: () {}),
                const FocusableAction(icon: Icons.block),
                FocusableAction(icon: Icons.remove, onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState!.requestFocusOnFirst();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[1]');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[3]');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[1]');
    });

    testWidgets('dynamic callback changes remove a disabled action from focus', (tester) async {
      final key = GlobalKey<FocusableActionBarState>();
      late StateSetter rebuild;
      var firstEnabled = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return FocusableActionBar(
                  key: key,
                  actions: [
                    FocusableAction(icon: Icons.add, onPressed: firstEnabled ? () {} : null),
                    FocusableAction(icon: Icons.remove, onPressed: () {}),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState!.requestFocusOnFirst();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');

      rebuild(() => firstEnabled = false);
      await tester.pump();
      expect(key.currentState!.getFocusNode(0)!.canRequestFocus, isFalse);
      expect(key.currentState!.getFocusNode(0)!.hasFocus, isFalse);

      key.currentState!.requestFocusOnFirst();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[1]');
    });
    testWidgets('still invokes onNavigateLeft at the left edge when wired', (tester) async {
      final key = GlobalKey<FocusableActionBarState>();
      final leftTarget = FocusNode(debugLabel: 'left-target');
      addTearDown(leftTarget.dispose);
      var navigatedLeft = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Focus(focusNode: leftTarget, child: const SizedBox(width: 50, height: 50)),
                FocusableActionBar(
                  key: key,
                  onNavigateLeft: () {
                    navigatedLeft = true;
                    leftTarget.requestFocus();
                  },
                  actions: [FocusableAction(icon: Icons.add, onPressed: () {})],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState!.requestFocusOnFirst();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(navigatedLeft, isTrue);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'left-target');
    });

    testWidgets('invokes custom child action on select', (tester) async {
      final key = GlobalKey<FocusableActionBarState>();
      var activations = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FocusableActionBar(
              key: key,
              actions: [FocusableAction(onPressed: () => activations++, child: const SizedBox(width: 48, height: 48))],
            ),
          ),
        ),
      );
      await tester.pump();

      key.currentState!.requestFocusOnFirst();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pump();

      expect(activations, 1);
    });
  });

  group('expandToGraphemeRange', () {
    for (final grapheme in ['😀', 'e\u0301', '🇯🇵', '👨‍👩‍👧‍👦']) {
      test('expands partial ${grapheme.runes.length}-scalar ranges', () {
        final text = 'A${grapheme}B';
        final graphemeEnd = 1 + grapheme.length;
        final expected = TextRange(start: 1, end: graphemeEnd);

        expect(expandToGraphemeRange(text, const TextRange(start: 1, end: 2)), expected);
        expect(expandToGraphemeRange(text, TextRange(start: graphemeEnd - 1, end: graphemeEnd)), expected);
        expect(expandToGraphemeRange(text, TextSelection(baseOffset: graphemeEnd - 1, extentOffset: 1)), expected);
        expect(expandToGraphemeRange(text, TextRange(start: graphemeEnd - 1, end: 1)), expected);
      });
    }

    test('preserves document edges and empty ranges', () {
      expect(expandToGraphemeRange('abc', const TextRange(start: 0, end: 1)), const TextRange(start: 0, end: 1));
      expect(expandToGraphemeRange('abc', const TextRange(start: 3, end: 3)), const TextRange.collapsed(3));
      expect(expandToGraphemeRange('', const TextRange(start: 0, end: 1)), TextRange.empty);
    });
  });
}
