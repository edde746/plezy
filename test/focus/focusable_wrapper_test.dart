import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/card_focus_scope.dart';
import 'package:plezy/focus/focusable_wrapper.dart';
import 'package:plezy/focus/input_mode_tracker.dart';

void main() {
  Finder chromeIn(Type type) => find.descendant(of: find.byType(FocusableWrapper), matching: find.byType(type));

  Widget buildWrapper() => Scaffold(
    body: FocusableWrapper(onSelect: () {}, child: const SizedBox(width: 10, height: 10)),
  );

  testWidgets('pointer mode builds no focus chrome around the child', (tester) async {
    await tester.pumpWidget(MaterialApp(home: buildWrapper()));

    expect(chromeIn(Transform), findsNothing);
    expect(chromeIn(AnimatedContainer), findsNothing);
    expect(chromeIn(Focus), findsWidgets);
  });

  testWidgets('keyboard mode builds the scale/border chrome', (tester) async {
    await tester.pumpWidget(InputModeTracker(child: MaterialApp(home: buildWrapper())));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(chromeIn(AnimatedBuilder), findsOneWidget);
    expect(chromeIn(AnimatedContainer), findsOneWidget);
  });

  testWidgets('focusing in pointer mode works without a pre-built controller', (tester) async {
    final node = FocusNode(debugLabel: 'card');
    addTearDown(node.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableWrapper(focusNode: node, onSelect: () {}, child: const SizedBox(width: 10, height: 10)),
        ),
      ),
    );

    // The AnimationController is created lazily on first focus; gaining and
    // losing focus in pointer mode must not throw.
    node.requestFocus();
    await tester.pump();
    node.unfocus();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('context menu key does not suppress the next select', (tester) async {
    final node = FocusNode(debugLabel: 'card');
    addTearDown(node.dispose);
    var selected = 0;
    var longPressed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableWrapper(
            focusNode: node,
            onSelect: () => selected++,
            onLongPress: () => longPressed++,
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(longPressed, 1);
    expect(selected, 1);
  });

  testWidgets('focus scale animation keeps child semantics geometry stable', (tester) async {
    final semantics = tester.ensureSemantics();
    final node = FocusNode(debugLabel: 'card');
    addTearDown(node.dispose);

    await tester.pumpWidget(
      InputModeTracker(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: FocusableWrapper(
                focusNode: node,
                focusScale: 1.2,
                delegateFocusBorder: true,
                child: CardFocusBorder(
                  child: Semantics(label: 'card content', child: SizedBox(width: 100, height: 100)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    node.unfocus();
    await tester.pumpAndSettle();
    node.requestFocus();
    await tester.pump();
    final semanticsOwner = tester.binding.rootPipelineOwner.semanticsOwner!;
    var semanticsUpdates = 0;
    void countSemanticsUpdate() => semanticsUpdates++;
    semanticsOwner.addListener(countSemanticsUpdate);

    await tester.pump(const Duration(milliseconds: 16));
    semanticsUpdates = 0;
    await tester.pump(const Duration(milliseconds: 16));

    expect(semanticsUpdates, 0);
    semanticsOwner.removeListener(countSemanticsUpdate);
    semantics.dispose();
  });
}
