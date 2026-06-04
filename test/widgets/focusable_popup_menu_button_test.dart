import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/app_menu.dart';
import 'package:plezy/widgets/focusable_popup_menu_button.dart';

void main() {
  testWidgets('D-pad select opens the popup menu', (tester) async {
    final focusNode = FocusNode(debugLabel: 'test_popup_menu');
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
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
}
