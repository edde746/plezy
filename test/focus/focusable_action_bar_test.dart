import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/focus/input_mode_tracker.dart';

void main() {
  Future<void> pumpBar(WidgetTester tester, List<FocusableAction> actions, {double spacing = 12}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FocusableActionBar(actions: actions, spacing: spacing),
          ),
        ),
      ),
    );
  }

  testWidgets('spacingBefore tightens one gap while the rest keep the row spacing', (tester) async {
    // The detail screen's split Play button relies on this: the chevron
    // segment sits a hairline from the play segment while the remaining
    // actions keep the uniform row gap.
    await pumpBar(tester, [
      FocusableAction(icon: Symbols.play_arrow_rounded, debugLabel: 'play', onPressed: () {}),
      FocusableAction(
        icon: Symbols.keyboard_arrow_down_rounded,
        debugLabel: 'version',
        onPressed: () {},
        spacingBefore: 2,
      ),
      FocusableAction(icon: Symbols.shuffle_rounded, debugLabel: 'shuffle', onPressed: () {}),
    ]);

    final buttons = find.byType(IconButton);
    expect(buttons, findsNWidgets(3));

    final play = tester.getRect(buttons.at(0));
    final version = tester.getRect(buttons.at(1));
    final shuffle = tester.getRect(buttons.at(2));

    expect(version.left - play.right, 2);
    expect(shuffle.left - version.right, 12);
  });

  Future<void> pumpTrackedBar(WidgetTester tester, List<FocusableAction> actions, List<bool> rowFocusChanges) async {
    await tester.pumpWidget(
      InputModeTracker(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: FocusableActionBar(actions: actions, onFocusChange: rowFocusChanges.add),
            ),
          ),
        ),
      ),
    );
  }

  FocusableActionBarState barState(WidgetTester tester) =>
      tester.state<FocusableActionBarState>(find.byType(FocusableActionBar));

  testWidgets('focused action keeps D-pad focus when an action is inserted before it', (tester) async {
    // Watchlist-arrival shape: on media detail the action list grows
    // asynchronously once tracker candidates resolve, inserting an action
    // before the one the user is standing on. That count change used to
    // dispose every node and silently drop focus.
    final rowFocusChanges = <bool>[];
    FocusableAction action(String label) => FocusableAction(debugLabel: label, onPressed: () {});

    await pumpTrackedBar(tester, [action('play'), action('watched')], rowFocusChanges);

    barState(tester).getFocusNode(1)!.requestFocus();
    await tester.pump();
    // Enter keyboard mode; RIGHT is trapped at the row edge so focus stays put.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'watched');
    expect(rowFocusChanges, [true]);

    await pumpTrackedBar(tester, [action('play'), action('watchlist'), action('watched')], rowFocusChanges);
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'watched');
    expect(rowFocusChanges, [true], reason: 'a surviving focused action must not report a row-focus loss');

    // Index wiring was rebuilt for the new slots: LEFT lands on the insertion.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'watchlist');
  });

  testWidgets('removing the focused action notifies the host of the row-focus loss', (tester) async {
    final rowFocusChanges = <bool>[];
    FocusableAction action(String label) => FocusableAction(debugLabel: label, onPressed: () {});

    await pumpTrackedBar(tester, [action('play'), action('watched')], rowFocusChanges);

    barState(tester).getFocusNode(1)!.requestFocus();
    await tester.pump();
    expect(rowFocusChanges, [true]);

    await pumpTrackedBar(tester, [action('play')], rowFocusChanges);
    await tester.pump();

    // The disposed node's listener is gone; the bar itself must report the
    // genuine loss so hosts like the TV detail row can unlatch.
    expect(rowFocusChanges, [true, false]);
    expect(FocusManager.instance.primaryFocus?.debugLabel, isNot('watched'));
  });

  testWidgets('inserting an unlabeled action does not retarget the focused binding onto it', (tester) async {
    // Catalog detail's enrichment shape: unlabeled Request appears before a
    // focused unlabeled Trailer. Positional reuse across the insertion used
    // to hand Trailer's focused binding to Request, so the next Select drove
    // the wrong action.
    final rowFocusChanges = <bool>[];
    var requestPresses = 0;
    var trailerPresses = 0;
    FocusableAction unlabeled(VoidCallback onPressed) =>
        FocusableAction(icon: Symbols.circle_rounded, onPressed: onPressed);

    final watchlist = unlabeled(() {});
    final trailer = unlabeled(() => trailerPresses++);
    await pumpTrackedBar(tester, [watchlist, trailer], rowFocusChanges);

    barState(tester).getFocusNode(1)!.requestFocus();
    await tester.pump();
    expect(rowFocusChanges, [true]);
    final trailerNode = barState(tester).getFocusNode(1);

    final request = unlabeled(() => requestPresses++);
    await pumpTrackedBar(tester, [watchlist, request, trailer], rowFocusChanges);
    await tester.pump();

    // The shape changed, so the focused binding must not be reused for the
    // inserted action; losing focus outright is the correct outcome.
    expect(barState(tester).getFocusNode(1), isNot(same(trailerNode)));
    expect(barState(tester).getFocusNode(1)!.hasFocus, isFalse);
    expect(rowFocusChanges, [true, false]);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(requestPresses, 0, reason: 'Select after the insertion must not drive the inserted action');
    expect(trailerPresses, 0);
  });

  testWidgets('equal-shape rebuild still preserves an unlabeled action focus positionally', (tester) async {
    final rowFocusChanges = <bool>[];
    FocusableAction unlabeled() => FocusableAction(icon: Symbols.circle_rounded, onPressed: () {});
    FocusableAction labeled(String label) => FocusableAction(debugLabel: label, onPressed: () {});

    await pumpTrackedBar(tester, [labeled('play'), unlabeled()], rowFocusChanges);

    barState(tester).getFocusNode(1)!.requestFocus();
    await tester.pump();
    final focusedNode = barState(tester).getFocusNode(1);

    // A label change at another slot forces a rebind without changing the
    // list shape: the unlabeled slot is provably stable and keeps its node.
    await pumpTrackedBar(tester, [labeled('play_version'), unlabeled()], rowFocusChanges);
    await tester.pump();

    expect(barState(tester).getFocusNode(1), same(focusedNode));
    expect(focusedNode!.hasFocus, isTrue);
    expect(rowFocusChanges, [true], reason: 'a positionally surviving action must not report a row-focus loss');
  });
}
