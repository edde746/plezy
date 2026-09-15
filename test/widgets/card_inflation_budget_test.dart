import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/card_inflation_budget.dart';
import 'package:plezy/widgets/sliver_child_memo.dart';

class _UpgradeHost extends StatefulWidget {
  const _UpgradeHost();

  @override
  State<_UpgradeHost> createState() => _UpgradeHostState();
}

class _UpgradeHostState extends State<_UpgradeHost> with SkeletonUpgradeScheduler {
  int builds = 0;
  int pendingSkeletons = 2;

  @override
  Widget build(BuildContext context) {
    builds++;
    if (pendingSkeletons > 0) {
      pendingSkeletons--;
      scheduleSkeletonUpgrade();
    }
    return const SizedBox();
  }
}

class _Card extends StatelessWidget {
  const _Card();

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// A 100px-per-item list whose cards go through [realizeBudgeted]. With a
/// 600px test viewport and no cache extent exactly six items are realized
/// per screen, so a 300px scroll lets three fresh items enter.
class _BudgetedList extends StatefulWidget {
  const _BudgetedList({required this.controller, required this.keyboardMode});

  final ScrollController controller;
  final bool keyboardMode;

  @override
  State<_BudgetedList> createState() => _BudgetedListState();
}

class _BudgetedListState extends State<_BudgetedList> with SkeletonUpgradeScheduler {
  static final List<Object> _items = List.generate(30, (_) => Object());
  final SliverChildMemo<Object> _memo = SliverChildMemo<Object>();
  int cardBuilds = 0;
  int skeletonBuilds = 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ListView.builder(
        controller: widget.controller,
        scrollCacheExtent: const ScrollCacheExtent.pixels(0),
        itemExtent: 100,
        itemCount: _items.length,
        itemBuilder: (context, index) => realizeBudgeted(
          _memo,
          context,
          index,
          _items[index],
          epoch: 0,
          keyboardMode: widget.keyboardMode,
          build: () {
            cardBuilds++;
            return const _Card();
          },
          skeleton: () {
            skeletonBuilds++;
            return const _Skeleton();
          },
        ),
      ),
    );
  }
}

void _exhaustBudget() {
  while (CardInflationBudget.tryTake()) {}
}

void main() {
  setUp(CardInflationBudget.reset);

  testWidgets('budget grants maxPerFrame slots and resets on the next frame', (tester) async {
    await tester.pumpWidget(const SizedBox());

    for (var i = 0; i < CardInflationBudget.maxPerFrame; i++) {
      expect(CardInflationBudget.tryTake(), isTrue);
    }
    expect(CardInflationBudget.tryTake(), isFalse);

    // In production tryTake only runs during builds, where a frame is in
    // flight; here the takes happened between frames, so schedule one for
    // the post-frame reset to ride on.
    tester.binding.scheduleFrame();
    await tester.pump();

    expect(CardInflationBudget.tryTake(), isTrue);
  });

  testWidgets('skeleton upgrade chain re-arms per frame and stops when drained', (tester) async {
    await tester.pumpWidget(const _UpgradeHost());
    final state = tester.state<_UpgradeHostState>(find.byType(_UpgradeHost));
    expect(state.builds, 1);

    // Each pump runs the post-frame setState, upgrading one pending skeleton.
    await tester.pump();
    expect(state.builds, 2);
    await tester.pump();
    expect(state.builds, 3);

    // Drained: no reschedule, no further rebuilds.
    await tester.pump();
    expect(state.builds, 3);
  });

  group('realizeBudgeted', () {
    Future<_BudgetedListState> pumpList(
      WidgetTester tester,
      ScrollController controller, {
      bool keyboardMode = false,
    }) async {
      await tester.pumpWidget(_BudgetedList(controller: controller, keyboardMode: keyboardMode));
      return tester.state<_BudgetedListState>(find.byType(_BudgetedList));
    }

    /// Advances a 600px scroll animation to its midpoint (300px) with the
    /// frame budget already spent, so the three items entering the viewport
    /// are built while the scrollable still reports itself as scrolling.
    Future<void> scrollMidAnimationWithSpentBudget(WidgetTester tester, ScrollController controller) async {
      unawaited(controller.animateTo(600, duration: const Duration(milliseconds: 100), curve: Curves.linear));
      await tester.pump();
      _exhaustBudget();
      await tester.pump(const Duration(milliseconds: 50));
      expect(controller.offset, 300);
    }

    testWidgets('ignores a spent budget when nothing is scrolling', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      _exhaustBudget();

      final state = await pumpList(tester, controller);

      expect(state.cardBuilds, 6);
      expect(state.skeletonBuilds, 0);
    });

    testWidgets('emits skeletons for fresh items entering during a scroll, then upgrades them', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final state = await pumpList(tester, controller);
      state.cardBuilds = 0;

      await scrollMidAnimationWithSpentBudget(tester, controller);
      expect(state.skeletonBuilds, 3);
      expect(state.cardBuilds, 0);
      expect(find.byType(_Skeleton), findsNWidgets(3));

      // The upgrade chain realizes every skeleton once the scroll settles;
      // indices 6..11 end up on screen, each built as a card exactly once.
      await tester.pumpAndSettle();
      expect(find.byType(_Skeleton), findsNothing);
      expect(find.byType(_Card), findsNWidgets(6));
      expect(state.cardBuilds, 6);
    });

    testWidgets('never budgets in keyboard mode', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final state = await pumpList(tester, controller, keyboardMode: true);
      state.cardBuilds = 0;

      await scrollMidAnimationWithSpentBudget(tester, controller);
      expect(state.skeletonBuilds, 0);
      expect(state.cardBuilds, 3);
      expect(find.byType(_Skeleton), findsNothing);
    });
  });
}
