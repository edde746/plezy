import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_wrapper.dart';
import 'package:plezy/widgets/focusable_tab_chip.dart';

void main() {
  // FocusableWrapper and FocusableChipStateMixin run the same d-pad activation
  // sequence under opposite consume policies. These pin the two differences that
  // keep the handlers separate.
  group('d-pad activation policies', () {
    Future<List<LogicalKeyboardKey>> escapedKeysFor(
      WidgetTester tester,
      FocusNode node,
      Widget child,
      LogicalKeyboardKey key,
    ) async {
      final escaped = <LogicalKeyboardKey>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Focus(
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent) escaped.add(event.logicalKey);
                return KeyEventResult.handled;
              },
              child: child,
            ),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(key);
      await tester.pump();
      return escaped;
    }

    testWidgets('wrapper consumes the context menu key with no onLongPress', (tester) async {
      final node = FocusNode(debugLabel: 'card');
      addTearDown(node.dispose);

      final escaped = await escapedKeysFor(
        tester,
        node,
        FocusableWrapper(focusNode: node, onSelect: () {}, child: const SizedBox(width: 10, height: 10)),
        LogicalKeyboardKey.contextMenu,
      );

      expect(escaped, isEmpty);
    });

    testWidgets('chip leaves the context menu key to its ancestors with no onLongPress', (tester) async {
      final node = FocusNode(debugLabel: 'chip');
      addTearDown(node.dispose);

      final escaped = await escapedKeysFor(
        tester,
        node,
        FocusableTabChip(label: 'Tab', isSelected: true, focusNode: node, onSelect: () {}),
        LogicalKeyboardKey.contextMenu,
      );

      expect(escaped, [LogicalKeyboardKey.contextMenu]);
    });

    testWidgets('wrapper passes unmapped RIGHT/DOWN through to the framework', (tester) async {
      final node = FocusNode(debugLabel: 'card');
      addTearDown(node.dispose);
      Widget card() => FocusableWrapper(focusNode: node, onSelect: () {}, child: const SizedBox(width: 10, height: 10));

      expect(await escapedKeysFor(tester, node, card(), LogicalKeyboardKey.arrowRight), [
        LogicalKeyboardKey.arrowRight,
      ]);
      expect(await escapedKeysFor(tester, node, card(), LogicalKeyboardKey.arrowDown), [LogicalKeyboardKey.arrowDown]);
    });

    testWidgets('chip traps unmapped RIGHT/DOWN so focus cannot escape the strip', (tester) async {
      final node = FocusNode(debugLabel: 'chip');
      addTearDown(node.dispose);
      Widget chip() => FocusableTabChip(label: 'Tab', isSelected: true, focusNode: node, onSelect: () {});

      expect(await escapedKeysFor(tester, node, chip(), LogicalKeyboardKey.arrowRight), isEmpty);
      expect(await escapedKeysFor(tester, node, chip(), LogicalKeyboardKey.arrowDown), isEmpty);
    });
  });
}
