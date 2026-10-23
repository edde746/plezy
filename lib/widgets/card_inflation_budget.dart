import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'skeleton_media_card.dart';
import 'sliver_child_memo.dart';

/// Global per-frame budget for inflating fresh media cards while scrolling.
///
/// Inflating a card (build + first layout + first paint) costs ~8ms on
/// low-end hardware, and a grid row entering the viewport inflates a whole
/// row of them in one frame — a guaranteed dropped frame. Callers ask
/// [tryTake] for a slot before inflating a *new* card during an active
/// scroll; when the budget is spent they render a [SkeletonMediaCard]
/// instead and upgrade it on a following frame (see
/// [SkeletonUpgradeScheduler]).
///
/// The budget is global, not per-list, so several hub rows entering in the
/// same frame share one cap instead of multiplying it. Cards that are
/// already built (memo hits) never consume a slot.
abstract final class CardInflationBudget {
  /// One fresh card per frame: a card costs ~8ms and an upgrade frame also
  /// pays the delegate walk, so two would already blow a 60Hz budget on the
  /// devices this exists for. Typical fling entry rate on a 3-column grid is
  /// under one card per frame, so the backlog stays near zero.
  static const int maxPerFrame = 1;

  static int _taken = 0;
  static bool _resetScheduled = false;

  /// Claims an inflation slot for the current frame. Returns false when the
  /// frame's budget is already spent.
  static bool tryTake() {
    if (_taken >= maxPerFrame) return false;
    _taken++;
    if (!_resetScheduled) {
      _resetScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _resetScheduled = false;
        _taken = 0;
      });
    }
    return true;
  }

  @visibleForTesting
  static void reset() {
    _taken = 0;
    _resetScheduled = false;
  }

  /// Whether an enclosing scrollable is actively scrolling — the condition
  /// under which fresh inflations should be budgeted. Checks the nearest
  /// scrollable and the nearest vertical one: a card in a horizontal hub row
  /// enters either because its own row scrolls or because the vertical list
  /// carrying the row does.
  static bool isScrollingContext(BuildContext context) {
    if (Scrollable.maybeOf(context)?.position.isScrollingNotifier.value ?? false) {
      return true;
    }
    return Scrollable.maybeOf(context, axis: Axis.vertical)?.position.isScrollingNotifier.value ?? false;
  }
}

/// Re-arms a post-frame rebuild while budgeted skeletons are pending, so
/// every skeleton is upgraded to its real card within a frame or two of the
/// budget freeing up. The chain stops by itself: a build that emits no
/// skeleton schedules nothing.
mixin SkeletonUpgradeScheduler<T extends StatefulWidget> on State<T> {
  bool _skeletonUpgradeScheduled = false;

  void scheduleSkeletonUpgrade() {
    if (_skeletonUpgradeScheduled) return;
    _skeletonUpgradeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _skeletonUpgradeScheduled = false;
      if (mounted) setState(() {});
    });
  }

  /// Memoized card for [index], or a budgeted [skeleton] when [memo] misses
  /// while an enclosing scrollable is moving and this frame's
  /// [CardInflationBudget] is spent (the skeleton upgrades a frame later).
  ///
  /// Keyboard mode never shows a skeleton where the user can see it — focus
  /// moves onto whatever is on screen. With [isOnScreen], cells realized off
  /// screen (the cache extent a D-pad step scrolls a row into) still spread
  /// their inflation over frames through [BudgetedCard]; without it keyboard
  /// mode builds at once.
  Widget realizeBudgeted<I extends Object>(
    SliverChildMemo<I> memo,
    BuildContext context,
    int index,
    I item, {
    required Object epoch,
    Object? salt,
    required bool keyboardMode,
    bool Function()? isOnScreen,
    required Widget Function() build,
    Widget Function() skeleton = _plainSkeleton,
  }) {
    final cached = memo.tryGet(index, item, epoch: epoch, salt: salt);
    if (cached != null) return cached;
    if (keyboardMode) {
      if (isOnScreen == null) return memo.widgetFor(index, item, epoch: epoch, salt: salt, build: build);
      return memo.widgetFor(
        index,
        item,
        epoch: epoch,
        salt: salt,
        build: () => BudgetedCard(urgent: isOnScreen, placeholder: skeleton(), builder: (_) => build()),
      );
    }
    if (CardInflationBudget.isScrollingContext(context) && !CardInflationBudget.tryTake()) {
      scheduleSkeletonUpgrade();
      return skeleton();
    }
    return memo.widgetFor(index, item, epoch: epoch, salt: salt, build: build);
  }
}

/// A card realized ahead of need — in a scrollable's cache extent, where a
/// row entering it would otherwise inflate all its cards in one frame — that
/// inflates on the first frame with a free [CardInflationBudget] slot. Until
/// then it shows [placeholder] and retries every frame, rebuilding only
/// itself. [urgent] is asked on every attempt: while it returns true (the card
/// is, or is about to be, on screen) the card builds at once regardless of the
/// budget.
///
/// Hand it out as a stable widget (a [SliverChildMemo] entry): a new instance
/// of an already-built card rebuilds immediately, which is the unbudgeted
/// behavior.
class BudgetedCard extends StatefulWidget {
  const BudgetedCard({
    super.key,
    required this.urgent,
    required this.builder,
    this.placeholder = const SizedBox.shrink(),
  });

  final bool Function() urgent;
  final WidgetBuilder builder;
  final Widget placeholder;

  @override
  State<BudgetedCard> createState() => _BudgetedCardState();
}

class _BudgetedCardState extends State<BudgetedCard> {
  bool _built = false;
  bool _retryScheduled = false;

  @override
  Widget build(BuildContext context) {
    if (!_built) {
      // The slot is claimed even for urgent cards so deferred ones in the same
      // frame wait for the next.
      if (!CardInflationBudget.tryTake() && !widget.urgent()) {
        _scheduleRetry();
        return widget.placeholder;
      }
      _built = true;
    }
    return widget.builder(context);
  }

  void _scheduleRetry() {
    if (_retryScheduled) return;
    _retryScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _retryScheduled = false;
      if (mounted && !_built) setState(() {});
    });
  }
}

Widget _plainSkeleton() => const SkeletonMediaCard();
