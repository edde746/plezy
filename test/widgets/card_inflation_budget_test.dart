import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/card_inflation_budget.dart';

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
}
