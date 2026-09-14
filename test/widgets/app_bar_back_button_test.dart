import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/widgets/app_bar_back_button.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, {required FocusNode focusNode, required VoidCallback onPressed}) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: InputModeTracker(
            child: Scaffold(
              body: AppBarBackButton(focusNode: focusNode, onPressed: onPressed),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('pointer, D-pad select, and Space activate exactly once', (tester) async {
    final focusNode = FocusNode(debugLabel: 'back_button_test');
    addTearDown(focusNode.dispose);
    var activations = 0;

    await pumpButton(tester, focusNode: focusNode, onPressed: () => activations++);

    await tester.tap(find.byType(AppBarBackButton));
    expect(activations, 1);

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(activations, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(activations, 3);
  });

  testWidgets('exposes one localized operable button node', (tester) async {
    final semantics = tester.ensureSemantics();
    final focusNode = FocusNode(debugLabel: 'back_button_semantics');
    addTearDown(focusNode.dispose);

    await pumpButton(tester, focusNode: focusNode, onPressed: () {});

    final finder = find.bySemanticsLabel(t.common.back);
    expect(finder, findsOneWidget);
    final data = tester.getSemantics(finder).getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });
}
