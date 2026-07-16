import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
