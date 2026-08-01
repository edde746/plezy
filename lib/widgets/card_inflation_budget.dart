import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

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
}
