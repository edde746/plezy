import 'dart:async';
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

  testWidgets('without onPressed it pops like a system back: a PopScope can veto it', (tester) async {
    var blocked = 0;
    var allowPop = false;
    late StateSetter setGuard;
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => StatefulBuilder(
                    builder: (context, setState) {
                      setGuard = setState;
                      return PopScope(
                        canPop: allowPop,
                        onPopInvokedWithResult: (didPop, _) {
                          if (!didPop) blocked++;
                        },
                        child: const Scaffold(body: AppBarBackButton()),
                      );
                    },
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppBarBackButton));
    await tester.pumpAndSettle();
    expect(blocked, 1);
    expect(find.byType(AppBarBackButton), findsOneWidget);

    setGuard(() => allowPop = true);
    await tester.pump();
    await tester.tap(find.byType(AppBarBackButton));
    await tester.pumpAndSettle();
    expect(blocked, 1);
    expect(find.byType(AppBarBackButton), findsNothing);
  });

  testWidgets('a select reaching it under a covering route does nothing', (tester) async {
    final focusNode = FocusNode(debugLabel: 'covered_back_button');
    addTearDown(focusNode.dispose);
    var activations = 0;

    await pumpButton(tester, focusNode: focusNode, onPressed: () => activations++);
    unawaited(
      showDialog<void>(
        context: tester.element(find.byType(AppBarBackButton)),
        builder: (_) => const AlertDialog(content: Text('cover')),
      ),
    );
    await tester.pumpAndSettle();
    // Focus left under the dialog, where a synthesized select landed (#2937);
    // a press there would have popped the dialog instead of this route.
    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(activations, 0);
    expect(find.text('cover'), findsOneWidget);

    Navigator.of(tester.element(find.text('cover'))).pop();
    await tester.pumpAndSettle();
    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(activations, 1);
  });
}
