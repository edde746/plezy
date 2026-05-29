import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/media_detail/detail_actions_row.dart';

void main() {
  // The button widths used here are tuned so the four user-facing
  // breakpoints (600 / 380 / 320 / 280) cleanly partition the four
  // drop states: all visible → drop Watched → drop Trailer → drop Random.
  //
  // play=124, icon=48, gap=12 produces:
  //   6 buttons (full): 124 + 48*5 + 12*5 = 424  (fits 600, not 380)
  //   5 (no watched):   124 + 48*4 + 12*4 = 364  (fits 380, not 320)
  //   4 (no trailer):   124 + 48*3 + 12*3 = 304  (fits 320, not 280)
  //   3 (no random):    124 + 48*2 + 12*2 = 244  (fits 280)
  const double playWidth = 124;
  const double iconWidth = 48;
  const double gap = 12;

  /// Build the canonical full set of 6 actions in render order. Each carries
  /// the priority the production widget uses (higher value drops first):
  ///   Play / Download / More  → 0  (never dropped)
  ///   Watched                 → 3  (dropped first)
  ///   Trailer                 → 2
  ///   Play random             → 1  (dropped last among the three)
  List<DetailAction> fullActionSet() => const [
    DetailAction(
      child: SizedBox.shrink(key: ValueKey('play')),
      predictedWidth: playWidth,
      dropPriority: 0,
      debugId: 'play',
    ),
    DetailAction(
      child: SizedBox.shrink(key: ValueKey('trailer')),
      predictedWidth: iconWidth,
      dropPriority: 2,
      debugId: 'trailer',
    ),
    DetailAction(
      child: SizedBox.shrink(key: ValueKey('random')),
      predictedWidth: iconWidth,
      dropPriority: 1,
      debugId: 'random',
    ),
    DetailAction(
      child: SizedBox.shrink(key: ValueKey('download')),
      predictedWidth: iconWidth,
      dropPriority: 0,
      debugId: 'download',
    ),
    DetailAction(
      child: SizedBox.shrink(key: ValueKey('watched')),
      predictedWidth: iconWidth,
      dropPriority: 3,
      debugId: 'watched',
    ),
    DetailAction(
      child: SizedBox.shrink(key: ValueKey('more')),
      predictedWidth: iconWidth,
      dropPriority: 0,
      debugId: 'more',
    ),
  ];

  Future<void> pumpAtWidth(WidgetTester tester, double width) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: DetailActionsRow(actions: fullActionSet(), gap: gap),
            ),
          ),
        ),
      ),
    );
  }

  group('DetailActionsRow — visibility at width tiers', () {
    testWidgets('600px shows all six buttons', (tester) async {
      await pumpAtWidth(tester, 600);
      expect(find.byKey(const ValueKey('play')), findsOneWidget);
      expect(find.byKey(const ValueKey('trailer')), findsOneWidget);
      expect(find.byKey(const ValueKey('random')), findsOneWidget);
      expect(find.byKey(const ValueKey('download')), findsOneWidget);
      expect(find.byKey(const ValueKey('watched')), findsOneWidget);
      expect(find.byKey(const ValueKey('more')), findsOneWidget);
    });

    testWidgets('380px hides Mark watched first', (tester) async {
      await pumpAtWidth(tester, 380);
      expect(find.byKey(const ValueKey('play')), findsOneWidget);
      expect(find.byKey(const ValueKey('trailer')), findsOneWidget);
      expect(find.byKey(const ValueKey('random')), findsOneWidget);
      expect(find.byKey(const ValueKey('download')), findsOneWidget);
      expect(find.byKey(const ValueKey('watched')), findsNothing);
      expect(find.byKey(const ValueKey('more')), findsOneWidget);
    });

    testWidgets('320px additionally hides Trailer', (tester) async {
      await pumpAtWidth(tester, 320);
      expect(find.byKey(const ValueKey('play')), findsOneWidget);
      expect(find.byKey(const ValueKey('trailer')), findsNothing);
      expect(find.byKey(const ValueKey('random')), findsOneWidget);
      expect(find.byKey(const ValueKey('download')), findsOneWidget);
      expect(find.byKey(const ValueKey('watched')), findsNothing);
      expect(find.byKey(const ValueKey('more')), findsOneWidget);
    });

    testWidgets('280px additionally hides Play random', (tester) async {
      await pumpAtWidth(tester, 280);
      expect(find.byKey(const ValueKey('play')), findsOneWidget);
      expect(find.byKey(const ValueKey('trailer')), findsNothing);
      expect(find.byKey(const ValueKey('random')), findsNothing);
      expect(find.byKey(const ValueKey('download')), findsOneWidget);
      expect(find.byKey(const ValueKey('watched')), findsNothing);
      expect(find.byKey(const ValueKey('more')), findsOneWidget);
    });
  });

  group('selectVisibleActions — pure selection', () {
    test('preserves order of survivors', () {
      // Even though the highest-priority entries sit in the middle of the
      // list, what survives must stay in original left-to-right order.
      final result = selectVisibleActions(fullActionSet(), 320, gap);
      expect(result.map((a) => a.debugId).toList(), ['play', 'random', 'download', 'more']);
    });

    test('returns full set unchanged when everything fits', () {
      final result = selectVisibleActions(fullActionSet(), 1000, gap);
      expect(result.length, 6);
      expect(result.map((a) => a.debugId), fullActionSet().map((a) => a.debugId));
    });

    test('stops dropping once every survivor is non-droppable', () {
      // Force a very narrow constraint. Priority-0 buttons (Play / Download
      // / More) must remain even if the total still overflows — the row
      // would visually overflow rather than disappear entirely.
      final result = selectVisibleActions(fullActionSet(), 10, gap);
      expect(result.map((a) => a.debugId).toList(), ['play', 'download', 'more']);
    });
  });
}
