import 'package:flutter/widgets.dart';

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
  if (!controller.hasClients || itemExtent <= 0) return;

  final viewport = controller.position.viewportDimension;
  final targetCenter = leadingPadding + (index * itemExtent) + (itemExtent / 2);
  final desiredOffset = (targetCenter - (viewport / 2)).clamp(0.0, controller.position.maxScrollExtent);

  if (animate) {
    controller.animateTo(desiredOffset, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
  } else {
    controller.jumpTo(desiredOffset);
  }
}
