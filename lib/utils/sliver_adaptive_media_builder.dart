import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'grid_size_calculator.dart';

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
  EdgeInsets padding = const EdgeInsets.all(16),
  double childAspectRatio = 2 / 3.3,
  double crossAxisSpacing = 8,
  double mainAxisSpacing = 8,
}) {
  if (viewMode == ViewMode.list) {
    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return itemBuilder(context, item, index);
        }, childCount: items.length),
      ),
    );
  } else {
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: GridSizeCalculator.getMaxCrossAxisExtent(
            context,
            density,
          ),
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          return itemBuilder(context, item, index);
        }, childCount: items.length),
      ),
    );
  }
}
