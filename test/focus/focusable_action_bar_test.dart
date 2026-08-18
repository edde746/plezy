import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/focusable_action_bar.dart';

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
}
