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

  testWidgets('nullable callback disables activation and removes the action from traversal', (tester) async {
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

    expect(focusNode.canRequestFocus, isFalse);
    expect(focusNode.hasFocus, isFalse);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });
}
