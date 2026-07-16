import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/dialog_action_button.dart';

void main() {
  testWidgets('autofocus and back routing are forwarded to the focus wrapper', (tester) async {
    final focusNode = FocusNode(debugLabel: 'dialog action');
    addTearDown(focusNode.dispose);
    var backed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DialogActionButton(
            focusNode: focusNode,
            autofocus: true,
            onPressed: () {},
            onBack: () => backed++,
            label: 'Save',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(backed, 1);
  });

  testWidgets('nullable callback keeps its graph position while disabling activation', (tester) async {
    final focusNode = FocusNode(debugLabel: 'disabled dialog action');
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DialogActionButton(
            focusNode: focusNode,
            autofocus: true,
            onPressed: null,
            label: 'Unavailable',
            isPrimary: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(focusNode.hasFocus, isTrue);
  });
}
