import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_wrapper.dart';
import 'package:plezy/focus/input_mode_tracker.dart';

/// The wrapper's focus chrome (scale Transform + border AnimatedContainer)
/// must only exist in keyboard/d-pad mode: on touch it is pure dead weight
/// multiplied by every card in a grid (see library scroll jank).
void main() {
  Finder chromeIn(Type type) => find.descendant(of: find.byType(FocusableWrapper), matching: find.byType(type));

  Widget buildWrapper() => Scaffold(
    body: FocusableWrapper(onSelect: () {}, child: const SizedBox(width: 10, height: 10)),
  );

  testWidgets('pointer mode builds no focus chrome around the child', (tester) async {
    await tester.pumpWidget(MaterialApp(home: buildWrapper()));

    expect(chromeIn(Transform), findsNothing);
    expect(chromeIn(AnimatedContainer), findsNothing);
    // The Focus node stays mounted so d-pad traversal finds the card the
    // moment keyboard mode activates.
    expect(chromeIn(Focus), findsWidgets);
  });

  testWidgets('keyboard mode builds the scale/border chrome', (tester) async {
    await tester.pumpWidget(InputModeTracker(child: MaterialApp(home: buildWrapper())));

    // A navigation key press flips the tracker into keyboard mode.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(chromeIn(Transform), findsOneWidget);
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
}
