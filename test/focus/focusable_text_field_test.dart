import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_text_field.dart';

void main() {
  testWidgets('unwired single-line fields traverse with arrow keys', (tester) async {
    final first = FocusNode(debugLabel: 'first');
    final second = FocusNode(debugLabel: 'second');
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    addTearDown(c1.dispose);
    addTearDown(c2.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableTextField(controller: c1, focusNode: first, enableTvKeyboard: false),
              FocusableTextField(controller: c2, focusNode: second, enableTvKeyboard: false),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    first.requestFocus();
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'first');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'second');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'first');
  });

  testWidgets('unwired multiline field keeps arrow keys for the caret', (tester) async {
    final first = FocusNode(debugLabel: 'multiline');
    final second = FocusNode(debugLabel: 'below');
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final c1 = TextEditingController(text: 'line1\nline2');
    final c2 = TextEditingController();
    addTearDown(c1.dispose);
    addTearDown(c2.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableTextField(controller: c1, focusNode: first, maxLines: 4, enableTvKeyboard: false),
              FocusableTextField(controller: c2, focusNode: second, enableTvKeyboard: false),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    first.requestFocus();
    c1.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'multiline');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'multiline');
  });
}
