import 'package:flutter/material.dart';

/// One button entry in the [DetailActionsRow].
///
/// `predictedWidth` is the laid-out width the caller expects this button to
/// consume (icon buttons are fixed-size; the play button needs to be
/// measured with a `TextPainter` against its label first). Selection is
/// done from these predicted widths so the row can decide what to drop
/// *before* laying anything out — avoiding a frame of overflow.
///
/// `dropPriority`:
/// - `0` — never dropped (Play, Download, More).
/// - Higher integers — dropped first. The action row currently uses
///   `3` for Mark watched (drops first), `2` for Trailer, `1` for Play
///   random (drops last among the three).
class DetailAction {
  final Widget child;
  final double predictedWidth;
  final int dropPriority;

  /// Optional id used by widget tests to assert visibility per button.
  final String? debugId;

  const DetailAction({
    required this.child,
    required this.predictedWidth,
    this.dropPriority = 0,
    this.debugId,
  });
}

/// A horizontal row of detail-screen action buttons that drops items in
/// priority order when the available width is too narrow to fit them all.
///
/// Used by `_buildActionButtons` on the media-detail screen so the Play /
/// Trailer / Random / Download / Watched / More cluster doesn't overflow
/// the viewport on small phones (or narrow tablet split layouts).
///
/// The drop algorithm is pure (see [selectVisibleActions]) so the priority
/// contract is locked by unit-style widget tests against known widths.
class DetailActionsRow extends StatelessWidget {
  /// Buttons in the visual left-to-right order they should be rendered.
  /// The selection logic preserves this order — only removal happens.
  final List<DetailAction> actions;

  /// Horizontal gap inserted *between* visible buttons. Dropped buttons
  /// take their trailing gap with them, so a 3-button visible set has 2
  /// gaps, never 5.
  final double gap;

  const DetailActionsRow({super.key, required this.actions, required this.gap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final visible = selectVisibleActions(actions, constraints.maxWidth, gap);

        if (visible.isEmpty) return const SizedBox.shrink();

        final children = <Widget>[];
        for (var i = 0; i < visible.length; i++) {
          children.add(visible[i].child);
          if (i < visible.length - 1) {
            children.add(SizedBox(width: gap));
          }
        }
        return Row(children: children);
      },
    );
  }
}

/// Pure selection of which [DetailAction]s fit within [maxWidth].
///
/// Drops one entry at a time, highest [DetailAction.dropPriority] first
/// (ties broken by later visual position), until the predicted total
/// width plus gaps is `<= maxWidth` or there are no droppable candidates
/// left. Order of the survivors is preserved.
@visibleForTesting
List<DetailAction> selectVisibleActions(
  List<DetailAction> all,
  double maxWidth,
  double gap,
) {
  final visible = List<DetailAction>.from(all);

  double totalWidth(List<DetailAction> entries) {
    if (entries.isEmpty) return 0;
    final widthSum = entries.fold<double>(0, (sum, e) => sum + e.predictedWidth);
    return widthSum + (entries.length - 1) * gap;
  }

  while (totalWidth(visible) > maxWidth) {
    // Pick the highest-priority candidate. Walk back-to-front so that on
    // ties the rightmost entry drops first — a more natural reading order
    // for users scanning left-to-right.
    var dropIndex = -1;
    var highestPriority = 0;
    for (var i = visible.length - 1; i >= 0; i--) {
      final p = visible[i].dropPriority;
      if (p > highestPriority) {
        highestPriority = p;
        dropIndex = i;
      }
    }
    if (dropIndex == -1) break; // every survivor is non-droppable; give up
    visible.removeAt(dropIndex);
  }

  return visible;
}
