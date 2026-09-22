import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/widgets/focusable_filter_chip.dart';
import 'package:plezy/widgets/options_chips_bar.dart';

import '../test_helpers/theme.dart';

void main() {
  OptionsChipDescriptor chip(String label, FocusNode node, {GlobalKey? anchor}) => OptionsChipDescriptor(
    icon: Symbols.category_rounded,
    label: label,
    onPressed: () {},
    focusNode: node,
    anchorKey: anchor,
  );

  testWidgets('chips render and dpad traversal follows adjacency with edge handoff', (tester) async {
    final nodes = [FocusNode(), FocusNode(), FocusNode()];
    addTearDown(() {
      for (final n in nodes) {
        n.dispose();
      }
    });
    var edgeLeft = 0;
    var down = 0;
    var up = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [testMonoTokens]),
        home: Scaffold(
          body: OptionsChipsBar(
            chips: [chip('Grouping', nodes[0]), chip('Filters', nodes[1]), chip('Sort', nodes[2])],
            onNavigateLeftEdge: () => edgeLeft++,
            onNavigateDown: () => down++,
            onNavigateUp: () => up++,
          ),
        ),
      ),
    );

    expect(find.byType(FocusableFilterChip), findsNWidgets(3));
    expect(find.text('Grouping'), findsOneWidget);

    nodes[0].requestFocus();
    await tester.pump();
    expect(nodes[0].hasFocus, isTrue);

    // RIGHT walks forward through the chips.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(nodes[1].hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(nodes[2].hasFocus, isTrue);
    // RIGHT on the last chip is consumed without moving.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(nodes[2].hasFocus, isTrue);

    // LEFT walks back; LEFT on the first chip hits the edge callback.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(nodes[1].hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(nodes[0].hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(edgeLeft, 1);

    // DOWN/UP hand off to the bar-level callbacks.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(down, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(up, 1);
  });

  test('delegate reports fixed extents', () {
    final delegate = OptionsChipsBarDelegate(builder: (_) => const SizedBox());
    expect(delegate.minExtent, optionsChipsBarHeight);
    expect(delegate.maxExtent, optionsChipsBarHeight);
  });
}
