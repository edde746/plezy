import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Scroll the nearest scrollable ancestor so [context] is centered.
///
/// Uses [Scrollable.ensureVisible] with alignment 0.5 (center).
/// Runs in a post-frame callback to ensure layout is complete.
void scrollContextToCenter(BuildContext? context) {
  if (context == null || !context.mounted) return;

  final selectedRenderObject = context.findRenderObject();
  if (selectedRenderObject == null || !selectedRenderObject.attached) return;

  final selectedScrollables = _scrollableAncestorsOf(context);
  if (selectedScrollables.isEmpty) return;

  final selectedRelationships = _captureScrollableRelationships(selectedRenderObject, selectedScrollables);
  if (selectedRelationships == null) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;

    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached || !identical(renderObject, selectedRenderObject)) {
      return;
    }

    final currentScrollables = _scrollableAncestorsOf(context);
    if (!_sameScrollables(selectedScrollables, currentScrollables)) return;

    final currentRelationships = _captureScrollableRelationships(renderObject, currentScrollables);
    if (currentRelationships == null || !_sameRenderRelationships(selectedRelationships, currentRelationships)) {
      return;
    }

    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  });
}

List<ScrollableState> _scrollableAncestorsOf(BuildContext context) {
  final scrollables = <ScrollableState>[];
  var currentContext = context;
  ScrollableState? scrollable;
  while ((scrollable = Scrollable.maybeOf(currentContext)) != null) {
    scrollables.add(scrollable!);
    currentContext = scrollable.context;
  }
  return scrollables;
}

bool _sameScrollables(List<ScrollableState> selected, List<ScrollableState> current) {
  if (selected.length != current.length) return false;
  for (var index = 0; index < selected.length; index++) {
    if (!identical(selected[index], current[index])) return false;
  }
  return true;
}

class _ScrollableRenderRelationship {
  const _ScrollableRenderRelationship({
    required this.revealTarget,
    required this.viewport,
    required this.scrollableRenderObject,
    required this.ancestorsToViewport,
  });

  final RenderObject revealTarget;
  final RenderAbstractViewport viewport;
  final RenderObject scrollableRenderObject;
  final List<RenderObject> ancestorsToViewport;
}

List<_ScrollableRenderRelationship>? _captureScrollableRelationships(
  RenderObject target,
  List<ScrollableState> scrollables,
) {
  final relationships = <_ScrollableRenderRelationship>[];
  var revealTarget = target;
  for (var index = 0; index < scrollables.length; index++) {
    final scrollable = scrollables[index];
    if (!scrollable.mounted) return null;

    final viewport = RenderAbstractViewport.maybeOf(revealTarget);
    if (viewport == null || !viewport.attached || viewport.parent == null) return null;

    final ancestorsToViewport = <RenderObject>[];
    RenderObject? ancestor = revealTarget.parent;
    while (ancestor != null) {
      ancestorsToViewport.add(ancestor);
      if (identical(ancestor, viewport)) break;
      ancestor = ancestor.parent;
    }
    if (ancestorsToViewport.isEmpty || !identical(ancestorsToViewport.last, viewport)) return null;

    final position = scrollable.position;
    final notificationContext = scrollable.notificationContext;
    if (!position.hasPixels ||
        !position.hasContentDimensions ||
        notificationContext == null ||
        !notificationContext.mounted) {
      return null;
    }

    final scrollableRenderObject = notificationContext.findRenderObject();
    if (scrollableRenderObject == null ||
        !scrollableRenderObject.attached ||
        !_isAncestorOf(scrollableRenderObject, revealTarget)) {
      return null;
    }

    relationships.add(
      _ScrollableRenderRelationship(
        revealTarget: revealTarget,
        viewport: viewport,
        scrollableRenderObject: scrollableRenderObject,
        ancestorsToViewport: ancestorsToViewport,
      ),
    );

    if (index + 1 < scrollables.length) {
      final nextTarget = scrollable.context.findRenderObject();
      if (nextTarget == null || !nextTarget.attached) return null;
      revealTarget = nextTarget;
    }
  }
  return relationships;
}

bool _sameRenderRelationships(
  List<_ScrollableRenderRelationship> selected,
  List<_ScrollableRenderRelationship> current,
) {
  if (selected.length != current.length) return false;
  for (var index = 0; index < selected.length; index++) {
    final selectedRelationship = selected[index];
    final currentRelationship = current[index];
    if (!identical(selectedRelationship.revealTarget, currentRelationship.revealTarget) ||
        !identical(selectedRelationship.viewport, currentRelationship.viewport) ||
        !identical(selectedRelationship.scrollableRenderObject, currentRelationship.scrollableRenderObject) ||
        selectedRelationship.ancestorsToViewport.length != currentRelationship.ancestorsToViewport.length) {
      return false;
    }
    for (var ancestorIndex = 0; ancestorIndex < selectedRelationship.ancestorsToViewport.length; ancestorIndex++) {
      if (!identical(
        selectedRelationship.ancestorsToViewport[ancestorIndex],
        currentRelationship.ancestorsToViewport[ancestorIndex],
      )) {
        return false;
      }
    }
  }
  return true;
}

bool _isAncestorOf(RenderObject ancestor, RenderObject descendant) {
  RenderObject? current = descendant;
  while (current != null) {
    if (identical(current, ancestor)) return true;
    current = current.parent;
  }
  return false;
}

/// Jump a vertical [ListView] so that [currentIndex] is visible.
///
/// Measures the first item (via [firstItemKey]) to get the real item height,
/// then scrolls to `currentIndex * itemHeight`, clamped to max extent.
/// Call once after the first build; the callback is a no-op if the key or
/// controller aren't ready yet.
void scrollToCurrentItem(
  ScrollController controller,
  GlobalKey firstItemKey,
  int currentIndex, {
  bool Function()? isCurrent,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (isCurrent?.call() == false || !controller.hasClients) return;
    final itemHeight = (firstItemKey.currentContext?.findRenderObject() as RenderBox?)?.size.height;
    if (itemHeight == null) return;
    final maxExtent = controller.position.maxScrollExtent;
    if (!maxExtent.isFinite) return;
    final target = (currentIndex * itemHeight).clamp(0.0, maxExtent);
    controller.jumpTo(target);
  });
}

/// Owns the boilerplate for one-time initial scrolling in selectable lists.
class InitialItemScrollController {
  final GlobalKey firstItemKey = GlobalKey();
  final ScrollController controller = ScrollController();
  bool _didInitialScroll = false;

  void maybeScrollTo(int? selectedIndex) {
    if (_didInitialScroll || selectedIndex == null || selectedIndex <= 0) return;
    _didInitialScroll = true;
    scrollToCurrentItem(controller, firstItemKey, selectedIndex);
  }

  void dispose() => controller.dispose();
}

/// Scroll a horizontal list to center the item at the given index.
///
/// Assumes items are laid out with [leadingPadding] before the first item,
/// and each item occupies [itemExtent] pixels (including per-item padding).
void scrollListToIndex(
  ScrollController controller,
  int index, {
  required double itemExtent,
  double leadingPadding = 12.0,
  bool animate = true,
  Duration duration = const Duration(milliseconds: 150),
  Curve curve = Curves.easeOut,
}) {
  if (controller.positions.length != 1 || itemExtent <= 0) return;

  final viewport = controller.position.viewportDimension;
  final maxExtent = controller.position.maxScrollExtent;
  if (!viewport.isFinite || !maxExtent.isFinite) return;
  final targetCenter = leadingPadding + (index * itemExtent) + (itemExtent / 2);
  final desiredOffset = (targetCenter - (viewport / 2)).clamp(0.0, maxExtent);

  if (animate) {
    unawaited(controller.animateTo(desiredOffset, duration: duration, curve: curve));
  } else {
    controller.jumpTo(desiredOffset);
  }
}

/// Scroll a vertical list so the row at [index] is fully visible, parking it
/// [alignment] of the viewport below the top edge when it has to move.
///
/// Geometry is read back from the laid-out sliver children instead of assumed:
/// a `ListTile` row is 56dp without a subtitle and 72dp with one, and visual
/// density, text scale and list padding move both numbers. A row outside the
/// built range is extrapolated from the rows that are laid out.
///
/// Expects a single scroll position whose viewport holds one lazy list sliver;
/// nothing happens when the list has not been laid out yet.
void scrollIndexIntoView(
  ScrollController controller,
  int index, {
  double alignment = 0.25,
  Duration duration = const Duration(milliseconds: 150),
  Curve curve = Curves.easeOut,
}) {
  if (controller.positions.length != 1) return;

  final position = controller.position;
  if (position.axis != Axis.vertical) return;

  final viewportHeight = position.viewportDimension;
  if (!viewportHeight.isFinite || !position.maxScrollExtent.isFinite) return;

  final row = _listRowPlacement(position, index);
  if (row == null) return;

  final viewportTop = position.pixels;
  if (row.top >= viewportTop && row.top + row.extent <= viewportTop + viewportHeight) return;

  final desiredOffset = (row.top - viewportHeight * alignment).clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  unawaited(controller.animateTo(desiredOffset, duration: duration, curve: curve));
}

/// Scroll offset that would align row [index] with the viewport's leading edge,
/// plus that row's extent. Null while no row is laid out.
({double top, double extent})? _listRowPlacement(ScrollPosition position, int index) {
  final sliver = _findLazyListSliver(position.context.storageContext.findRenderObject());
  if (sliver == null) return null;

  RenderBox? anchor;
  var anchorIndex = 0;
  var extentSum = 0.0;
  var laidOutRows = 0;

  for (RenderBox? child = sliver.firstChild; child != null; child = sliver.childAfter(child)) {
    final parentData = child.parentData;
    if (parentData is! SliverMultiBoxAdaptorParentData) continue;
    final childIndex = parentData.index;
    if (childIndex == null || !child.hasSize) continue;

    if (childIndex == index) {
      final reveal = RenderAbstractViewport.maybeOf(child)?.getOffsetToReveal(child, 0.0);
      return reveal == null ? null : (top: reveal.offset, extent: child.size.height);
    }
    if (anchor == null) {
      anchor = child;
      anchorIndex = childIndex;
    }
    extentSum += child.size.height;
    laidOutRows++;
  }

  final anchorRow = anchor;
  if (anchorRow == null) return null;
  final anchorReveal = RenderAbstractViewport.maybeOf(anchorRow)?.getOffsetToReveal(anchorRow, 0.0);
  if (anchorReveal == null) return null;

  // The row is beyond the cache extent: step from a real row by the average
  // laid-out row extent rather than by a guessed constant.
  final rowExtent = extentSum / laidOutRows;
  return (top: anchorReveal.offset + (index - anchorIndex) * rowExtent, extent: rowExtent);
}

RenderSliverMultiBoxAdaptor? _findLazyListSliver(RenderObject? node) {
  if (node == null) return null;
  if (node is RenderSliverMultiBoxAdaptor) return node;
  RenderSliverMultiBoxAdaptor? found;
  node.visitChildren((child) {
    found ??= _findLazyListSliver(child);
  });
  return found;
}

/// Scroll a horizontal list so the keyed child is centered using its real layout
/// bounds. This corrects small per-item extent drift in long carousels.
void scrollKeyedChildToHorizontalCenter(
  ScrollController controller,
  GlobalKey key, {
  bool animate = true,
  int maxAttempts = 2,
  bool Function()? isCurrent,
  Duration duration = const Duration(milliseconds: 150),
  Curve curve = Curves.easeOut,
}) {
  void schedule(int attempt) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isCurrent?.call() == false) return;

      final context = key.currentContext;
      if (context == null) {
        if (attempt < maxAttempts) schedule(attempt + 1);
        return;
      }

      final didResolve = _scrollContextToHorizontalCenterNow(
        controller,
        context,
        animate: animate,
        duration: duration,
        curve: curve,
      );
      if (!didResolve && attempt < maxAttempts) schedule(attempt + 1);
    });
  }

  schedule(0);
}

bool _scrollContextToHorizontalCenterNow(
  ScrollController controller,
  BuildContext context, {
  required bool animate,
  required Duration duration,
  required Curve curve,
}) {
  if (!context.mounted || controller.positions.length != 1) return false;

  final position = controller.position;
  if (position.axis != Axis.horizontal) return true;

  final scrollable = Scrollable.maybeOf(context);
  if (scrollable == null || !identical(scrollable.position, position)) return false;

  final renderObject = context.findRenderObject();
  if (renderObject == null ||
      !renderObject.attached ||
      _captureScrollableRelationships(renderObject, <ScrollableState>[scrollable]) == null) {
    return false;
  }

  final viewport = RenderAbstractViewport.maybeOf(renderObject);
  if (viewport == null) return false;

  final target = viewport
      .getOffsetToReveal(renderObject, 0.5)
      .offset
      .clamp(position.minScrollExtent, position.maxScrollExtent)
      .toDouble();
  if ((target - position.pixels).abs() < 0.5) return true;

  if (animate) {
    unawaited(controller.animateTo(target, duration: duration, curve: curve));
  } else {
    controller.jumpTo(target);
  }
  return true;
}
