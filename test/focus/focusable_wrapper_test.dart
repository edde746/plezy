import 'dart:async' show unawaited;
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
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

  Widget buildScrollableWrappers({
    required ScrollController controller,
    required FocusNode topNode,
    required FocusNode bottomNode,
  }) {
    return InputModeTracker(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                FocusableWrapper(focusNode: topNode, onSelect: () {}, child: const SizedBox(width: 100, height: 100)),
                for (var i = 0; i < 20; i++) const SizedBox(width: 100, height: 100),
                FocusableWrapper(
                  focusNode: bottomNode,
                  onSelect: () {},
                  child: const SizedBox(width: 100, height: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('pointer-mode focus gain does not auto-scroll', (tester) async {
    final topNode = FocusNode(debugLabel: 'top');
    final bottomNode = FocusNode(debugLabel: 'bottom');
    final controller = ScrollController();
    addTearDown(topNode.dispose);
    addTearDown(bottomNode.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildScrollableWrappers(controller: controller, topNode: topNode, bottomNode: bottomNode));

    // Programmatic focus parking without a keyboard session (the media-detail
    // entry pattern) must not move the viewport.
    bottomNode.requestFocus();
    await tester.pumpAndSettle();

    expect(bottomNode.hasFocus, isTrue);
    expect(controller.offset, 0);
  });

  testWidgets('keyboard-mode focus gain auto-scrolls into view', (tester) async {
    final topNode = FocusNode(debugLabel: 'top');
    final bottomNode = FocusNode(debugLabel: 'bottom');
    final controller = ScrollController();
    addTearDown(topNode.dispose);
    addTearDown(bottomNode.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildScrollableWrappers(controller: controller, topNode: topNode, bottomNode: bottomNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    bottomNode.requestFocus();
    await tester.pumpAndSettle();

    expect(bottomNode.hasFocus, isTrue);
    expect(controller.offset, greaterThan(0));
  });

  testWidgets('dialog close restoring pointer-parked focus keeps the scroll position', (tester) async {
    // Issue #2031: entry code parks focus on an item, the user scrolls away by
    // touch/mouse, and closing a context menu (a dialog route) hands focus back
    // to the parked node — which must not scroll itself back into view.
    final topNode = FocusNode(debugLabel: 'top');
    final bottomNode = FocusNode(debugLabel: 'bottom');
    final controller = ScrollController();
    addTearDown(topNode.dispose);
    addTearDown(bottomNode.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildScrollableWrappers(controller: controller, topNode: topNode, bottomNode: bottomNode));

    topNode.requestFocus();
    await tester.pumpAndSettle();
    controller.jumpTo(1200);
    await tester.pump();

    final navContext = tester.element(find.byType(SingleChildScrollView));
    // Deliberately unawaited: the future completes when the dialog pops below.
    unawaited(
      showDialog<void>(
        context: navContext,
        builder: (_) => const AlertDialog(title: Text('menu')),
      ),
    );
    await tester.pumpAndSettle();
    expect(topNode.hasFocus, isFalse);

    Navigator.of(navContext).pop();
    await tester.pumpAndSettle();

    expect(topNode.hasFocus, isTrue);
    expect(controller.offset, 1200);
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

  testWidgets('semantic label replaces child semantics by default', (tester) async {
    final semantics = tester.ensureSemantics();
    var activations = 0;
    var childActivations = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableWrapper(
            semanticLabel: 'Open details',
            semanticValue: 'Ready',
            onSelect: () => activations++,
            child: Semantics(
              label: 'Decorative artwork',
              value: 'Decorative state',
              button: true,
              onTap: () => childActivations++,
              child: const Text('Poster'),
            ),
          ),
        ),
      ),
    );

    final finder = find.bySemanticsLabel('Open details');
    expect(finder, findsOneWidget);
    expect(find.bySemanticsLabel('Decorative artwork'), findsNothing);
    expect(find.bySemanticsLabel('Poster'), findsNothing);

    final node = tester.getSemantics(finder);
    final data = node.getSemanticsData();
    expect(data.value, 'Ready');
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(_semanticTapNodeCount(tester), 1);

    node.owner!.performAction(node.id, SemanticsAction.tap);
    expect(activations, 1);
    expect(childActivations, 0);
    semantics.dispose();
  });

  testWidgets('merge mode supplements non-interactive child semantics', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableWrapper(
            semanticLabel: 'Expand',
            excludeChildSemantics: false,
            onSelect: () {},
            child: Semantics(value: 'Available offline', child: const Text('Visible synopsis')),
          ),
        ),
      ),
    );

    final finder = find.bySemanticsLabel(RegExp('Expand'));
    expect(finder, findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Visible synopsis')), findsOneWidget);

    final data = tester.getSemantics(finder).getSemanticsData();
    expect(data.label, contains('Expand'));
    expect(data.label, contains('Visible synopsis'));
    expect(data.value, 'Available offline');
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(_semanticTapNodeCount(tester), 1);
    semantics.dispose();
  });
}

int _semanticTapNodeCount(WidgetTester tester) {
  var count = 0;
  void visit(SemanticsNode node) {
    if (node.getSemanticsData().hasAction(SemanticsAction.tap)) count++;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.renderViews.single.owner!.semanticsOwner!.rootSemanticsNode!);
  return count;
}
