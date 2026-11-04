import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';

void main() {
  testWidgets('switch tile toggles once from SELECT', (tester) async {
    final focusNode = FocusNode(debugLabel: 'switch');
    addTearDown(focusNode.dispose);
    var value = false;
    var changes = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FocusableSwitchListTile(
              focusNode: focusNode,
              value: value,
              title: const Text('Switch'),
              onChanged: (next) {
                changes++;
                setState(() => value = next);
              },
            ),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(value, isTrue);
    expect(changes, 1);
  });

  testWidgets('checkbox tile toggles once from SELECT', (tester) async {
    final focusNode = FocusNode(debugLabel: 'checkbox');
    addTearDown(focusNode.dispose);
    var value = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FocusableCheckboxListTile(
              focusNode: focusNode,
              value: value,
              title: const Text('Checkbox'),
              onChanged: (next) => setState(() => value = next ?? false),
            ),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(value, isTrue);
  });

  testWidgets('disabled switch tile cannot be focused or activated', (tester) async {
    final focusNode = FocusNode(debugLabel: 'disabled switch');
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableSwitchListTile(
            focusNode: focusNode,
            value: false,
            title: const Text('Disabled'),
            onChanged: null,
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });

  Widget buildScrollableTiles({required ScrollController controller, required FocusNode bottomNode}) {
    return InputModeTracker(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                for (var i = 0; i < 30; i++) const SizedBox(height: 56, width: 100),
                FocusableListTile(focusNode: bottomNode, title: const Text('Target'), onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('pointer-mode focus gain does not reveal the tile', (tester) async {
    final bottomNode = FocusNode(debugLabel: 'tile');
    final controller = ScrollController();
    addTearDown(bottomNode.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildScrollableTiles(controller: controller, bottomNode: bottomNode));

    // Programmatic focus without a keyboard session (e.g. a context menu
    // restoring focus on close, issue #2031) must not move the viewport.
    bottomNode.requestFocus();
    await tester.pumpAndSettle();

    expect(bottomNode.hasFocus, isTrue);
    expect(controller.offset, 0);
  });

  testWidgets('keyboard-mode focus gain centers the tile', (tester) async {
    final bottomNode = FocusNode(debugLabel: 'tile');
    final controller = ScrollController();
    addTearDown(bottomNode.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildScrollableTiles(controller: controller, bottomNode: bottomNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    bottomNode.requestFocus();
    await tester.pumpAndSettle();

    expect(bottomNode.hasFocus, isTrue);
    expect(controller.offset, greaterThan(0));
  });

  group('onLongPress via D-pad', () {
    // Keyboard mode matches a TV session: the focus highlight and the
    // reveal-on-focus behaviour only apply there.
    Future<void> enterKeyboardMode(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }

    Future<(FocusNode, List<String>)> pumpTile(WidgetTester tester) async {
      final node = FocusNode(debugLabel: 'long-press tile');
      addTearDown(node.dispose);
      final events = <String>[];
      await tester.pumpWidget(
        InputModeTracker(
          child: MaterialApp(
            home: Scaffold(
              body: FocusableListTile(
                focusNode: node,
                title: const Text('Track'),
                onTap: () => events.add('tap'),
                onLongPress: () => events.add('long'),
              ),
            ),
          ),
        ),
      );
      await enterKeyboardMode(tester);
      node.requestFocus();
      await tester.pump();
      return (node, events);
    }

    testWidgets('short SELECT taps once', (tester) async {
      final (_, events) = await pumpTile(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(events, ['tap']);
    });

    testWidgets('holding SELECT long-presses without a tap', (tester) async {
      final (_, events) = await pumpTile(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(events, ['long']);
    });

    testWidgets('context-menu key long-presses', (tester) async {
      final (_, events) = await pumpTile(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
      await tester.pump();
      expect(events, ['long']);
    });

    testWidgets('toggling onLongPress on a focused tile keeps its focus highlight', (tester) async {
      final node = FocusNode(debugLabel: 'toggle tile');
      addTearDown(node.dispose);
      late StateSetter setOuter;
      var withLongPress = false;
      await tester.pumpWidget(
        InputModeTracker(
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  setOuter = setState;
                  return FocusableListTile(
                    focusNode: node,
                    title: const Text('Off'),
                    onTap: () {},
                    onLongPress: withLongPress ? () {} : null,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await enterKeyboardMode(tester);
      node.requestFocus();
      await tester.pump();

      // InkWell's stateful core is a private widget, so find it by name.
      State inkState() => tester.state(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == '_InkResponseStateWidget'),
        ),
      );

      // The ink highlight lives in the InkWell's State; remounting the subtree
      // (as happens when the wrapper appears/disappears) drops it even though
      // the node keeps focus.
      final inkBefore = inkState();
      setOuter(() => withLongPress = true);
      await tester.pump();
      final inkAfter = inkState();
      setOuter(() => withLongPress = false);
      await tester.pump();
      final inkBack = inkState();

      expect(node.hasFocus, isTrue);
      expect(identical(inkBefore, inkAfter), isTrue, reason: 'gaining onLongPress must not remount the tile');
      expect(identical(inkBefore, inkBack), isTrue, reason: 'losing onLongPress must not remount the tile');
    });

    testWidgets('moving focus mid-hold cancels the pending long-press and keeps the next press working', (
      tester,
    ) async {
      final nodeA = FocusNode(debugLabel: 'A');
      final nodeB = FocusNode(debugLabel: 'B');
      addTearDown(nodeA.dispose);
      addTearDown(nodeB.dispose);
      final events = <String>[];
      await tester.pumpWidget(
        InputModeTracker(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  FocusableListTile(
                    focusNode: nodeA,
                    title: const Text('A'),
                    onTap: () => events.add('tapA'),
                    onLongPress: () => events.add('longA'),
                  ),
                  FocusableListTile(
                    focusNode: nodeB,
                    title: const Text('B'),
                    onTap: () => events.add('tapB'),
                    onLongPress: () => events.add('longB'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await enterKeyboardMode(tester);
      nodeA.requestFocus();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      nodeB.requestFocus();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(events, isEmpty, reason: 'A must not long-press after losing focus');

      // The abandoned press must not leave global SELECT suppression armed.
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(events, ['tapB']);
    });

    testWidgets('long-press runs the callback current at fire time, not at key-down', (tester) async {
      final node = FocusNode(debugLabel: 'stale tile');
      addTearDown(node.dispose);
      final events = <String>[];
      late StateSetter setOuter;
      var generation = 1;
      await tester.pumpWidget(
        InputModeTracker(
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  setOuter = setState;
                  final current = generation;
                  return FocusableListTile(
                    focusNode: node,
                    title: const Text('Track'),
                    onTap: () {},
                    onLongPress: () => events.add('long$current'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await enterKeyboardMode(tester);
      node.requestFocus();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      setOuter(() => generation = 2);
      await tester.pump(); // rebuild mid-hold, before the 500 ms timer fires
      await tester.pump(const Duration(milliseconds: 600));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pump();

      expect(events, ['long2']);
    });
  });
}
