import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/app_menu.dart';
import 'package:plezy/widgets/focusable_popup_menu_button.dart';

void main() {
  testWidgets('D-pad select opens the popup menu', (tester) async {
    final focusNode = FocusNode(debugLabel: 'test_popup_menu');
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(dark: true),
        home: Scaffold(
          body: Center(
            child: FocusablePopupMenuButton<String>(
              focusNode: focusNode,
              icon: const Icon(Icons.more_vert),
              itemBuilder: (_) => const [AppMenuItem(value: 'one', label: 'One')],
            ),
          ),
        ),
      ),
    );

    expect(find.text('One'), findsNothing);

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('One'), findsOneWidget);
  });

  testWidgets('forwards a scalar value on one icon-only menu node', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusablePopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            semanticLabel: 'Choose source',
            semanticValue: 'Trakt',
            itemBuilder: (_) => const [AppMenuItem(value: 'one', label: 'One')],
          ),
        ),
      ),
    );

    final finder = find.bySemanticsLabel('Choose source');
    expect(finder, findsOneWidget);
    final data = tester.getSemantics(finder).getSemanticsData();
    expect(data.value, 'Trakt');
    expect(data.flagsCollection.isButton, isTrue);
    expect(_semanticTapNodeCount(tester), 1);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(find.bySemanticsLabel('Trakt'), findsNothing);
    semantics.dispose();
  });
}

int _semanticTapNodeCount(WidgetTester tester) {
  var count = 0;
  void visit(SemanticsNode node) {
    if (node.getSemanticsData().hasAction(SemanticsAction.tap)) count++;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.renderViews.single.owner!.semanticsOwner!.rootSemanticsNode!);
  return count;
}
