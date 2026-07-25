import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/widgets/collapsible_text.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('select expands overflowing focused text', (tester) async {
    final focusNode = FocusNode(debugLabel: 'test_collapsible_text');
    addTearDown(focusNode.dispose);

    const text =
        'This program summary is intentionally long enough to overflow a narrow details sheet and require expansion.';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              child: CollapsibleText(text: text, maxLines: 1, focusNode: focusNode),
            ),
          ),
        ),
      ),
    );

    expect(_collapsiblePlainText(tester), isNot(text));

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(_collapsiblePlainText(tester), text);
    expect(focusNode.skipTraversal, isTrue);
  });

  testWidgets('short focused text keeps navigation without an expand action', (tester) async {
    final semantics = tester.ensureSemantics();
    final focusNode = FocusNode(debugLabel: 'short_collapsible_text');
    addTearDown(focusNode.dispose);
    var downCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: CollapsibleText(
              text: 'Short overview',
              maxLines: 2,
              focusNode: focusNode,
              skipTraversal: false,
              onNavigateDown: () => downCount++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(focusNode.context, isNotNull);
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    final node = tester.getSemantics(find.text('Short overview'));
    expect(node.label, 'Short overview');
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(downCount, 1);
    semantics.dispose();
  });

  testWidgets('overflowing synopsis merges visible text with one expand action', (tester) async {
    final semantics = tester.ensureSemantics();
    const text =
        'This program summary is intentionally long enough to overflow a narrow details sheet and reveal more detail.';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 120, child: CollapsibleText(text: text, maxLines: 1)),
        ),
      ),
    );

    final collapsedSynopsis = _visibleSynopsis(tester);
    expect(collapsedSynopsis, isNotEmpty);
    expect(collapsedSynopsis, isNot(text));

    var annotation = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == t.accessibility.expandText,
    );
    expect(annotation, findsOneWidget);
    var node = tester.getSemantics(annotation);
    var data = node.getSemanticsData();
    expect(data.label, contains(collapsedSynopsis));
    expect(data.label, contains(t.accessibility.expandText));
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(_semanticTapNodeCount(tester), 1);

    node.owner!.performAction(node.id, SemanticsAction.tap);
    await tester.pump();

    expect(_visibleSynopsis(tester), text);
    annotation = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == t.accessibility.collapseText,
    );
    expect(annotation, findsOneWidget);
    node = tester.getSemantics(annotation);
    data = node.getSemanticsData();
    expect(data.label, contains(text));
    expect(data.label, contains(t.accessibility.collapseText));
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(_semanticTapNodeCount(tester), 1);
    semantics.dispose();
  });

  testWidgets('reports whether text overflows', (tester) async {
    bool? overflows;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            child: CollapsibleText(
              text: 'This summary is long enough to overflow in this narrow box.',
              maxLines: 1,
              onOverflowChanged: (value) => overflows = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(overflows, isTrue);
  });
}

String _collapsiblePlainText(WidgetTester tester) {
  final textFinder = find.byWidgetPredicate((widget) => widget is Text && widget.textSpan != null);
  return tester.widget<Text>(textFinder).textSpan!.toPlainText();
}

String _visibleSynopsis(WidgetTester tester) {
  final textFinder = find.byWidgetPredicate((widget) => widget is Text && widget.textSpan != null);
  final span = tester.widget<Text>(textFinder).textSpan! as TextSpan;
  return (span.children!.first as TextSpan).text!;
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
