import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'grid_size_calculator.dart';
import 'layout_constants.dart';

/// Builds an adaptive Sliver widget that switches between grid and list
/// based on the current view mode setting.
///
/// This helper consolidates the list vs grid Sliver builders to keep
/// padding and density logic in sync across different screens.
Widget buildAdaptiveMediaSliverBuilder<T>({
  required BuildContext context,
  required List<T> items,
  required Widget Function(BuildContext context, T item, int index) itemBuilder,
  required ViewMode viewMode,
  required LibraryDensity density,
  EdgeInsets? padding,
  double? childAspectRatio,
  double? crossAxisSpacing,
  double? mainAxisSpacing,
}) {
  final effectivePadding = padding ?? GridLayoutConstants.gridPadding;
  final effectiveAspectRatio = childAspectRatio ?? GridLayoutConstants.posterAspectRatio;
  final effectiveCrossAxisSpacing = crossAxisSpacing ?? GridLayoutConstants.crossAxisSpacing;
  final effectiveMainAxisSpacing = mainAxisSpacing ?? GridLayoutConstants.mainAxisSpacing;

  if (viewMode == ViewMode.list) {
    return SliverPadding(
      padding: effectivePadding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return itemBuilder(context, item, index);
        }, childCount: items.length),
      ),
    );
  } else {
    return SliverPadding(
      padding: effectivePadding,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: GridSizeCalculator.getMaxCrossAxisExtent(context, density),
          childAspectRatio: effectiveAspectRatio,
          crossAxisSpacing: effectiveCrossAxisSpacing,
          mainAxisSpacing: effectiveMainAxisSpacing,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return itemBuilder(context, item, index);
        }, childCount: items.length),
      ),
    );
  }
}
