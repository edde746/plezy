import 'package:flutter/widgets.dart';

/// Scroll the nearest scrollable ancestor so [context] is centered.
///
/// Uses [Scrollable.ensureVisible] with alignment 0.5 (center).
/// Runs in a post-frame callback to ensure layout is complete.
void scrollContextToCenter(BuildContext? context) {
  if (context == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  });
}

/// Jump a vertical [ListView] so that [currentIndex] is visible.
///
/// Measures the first item (via [firstItemKey]) to get the real item height,
/// then scrolls to `currentIndex * itemHeight`, clamped to max extent.
/// Call once after the first build; the callback is a no-op if the key or
/// controller aren't ready yet.
void scrollToCurrentItem(ScrollController controller, GlobalKey firstItemKey, int currentIndex) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!controller.hasClients) return;
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
    controller.animateTo(desiredOffset, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
  } else {
    controller.jumpTo(desiredOffset);
  }
}
