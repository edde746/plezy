import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/collapsible_text.dart';

void main() {
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
