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
}) {
  if (controller.positions.length != 1 || itemExtent <= 0) return;

  final viewport = controller.position.viewportDimension;
  final maxExtent = controller.position.maxScrollExtent;
  if (!viewport.isFinite || !maxExtent.isFinite) return;
  final targetCenter = leadingPadding + (index * itemExtent) + (itemExtent / 2);
  final desiredOffset = (targetCenter - (viewport / 2)).clamp(0.0, maxExtent);

  if (animate) {
    unawaited(controller.animateTo(desiredOffset, duration: const Duration(milliseconds: 150), curve: Curves.easeOut));
  } else {
    controller.jumpTo(desiredOffset);
  }
}

/// Scroll a horizontal list so the keyed child is centered using its real layout
/// bounds. This corrects small per-item extent drift in long carousels.
void scrollKeyedChildToHorizontalCenter(
  ScrollController controller,
  GlobalKey key, {
  bool animate = true,
  int maxAttempts = 2,
  bool Function()? isCurrent,
}) {
  void schedule(int attempt) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isCurrent?.call() == false) return;

      final context = key.currentContext;
      if (context == null) {
        if (attempt < maxAttempts) schedule(attempt + 1);
        return;
      }

      final didResolve = _scrollContextToHorizontalCenterNow(controller, context, animate: animate);
      if (!didResolve && attempt < maxAttempts) schedule(attempt + 1);
    });
  }

  schedule(0);
}

bool _scrollContextToHorizontalCenterNow(ScrollController controller, BuildContext context, {required bool animate}) {
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
    unawaited(controller.animateTo(target, duration: const Duration(milliseconds: 150), curve: Curves.easeOut));
  } else {
    controller.jumpTo(target);
  }
  return true;
}
