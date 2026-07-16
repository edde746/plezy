import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/focusable_tab_chip.dart';

void main() {
  testWidgets('losing focus cancels a pending chip long press', (tester) async {
    final firstNode = FocusNode(debugLabel: 'first');
    final secondNode = FocusNode(debugLabel: 'second');
    addTearDown(firstNode.dispose);
    addTearDown(secondNode.dispose);
    var longPressed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              FocusableTabChip(
                label: 'First',
                isSelected: true,
                focusNode: firstNode,
                onSelect: () {},
                onLongPress: () => longPressed++,
              ),
              FocusableTabChip(label: 'Second', isSelected: false, focusNode: secondNode, onSelect: () {}),
            ],
          ),
        ),
      ),
    );
    firstNode.requestFocus();
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    secondNode.requestFocus();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);

    expect(longPressed, 0);
  });
}
