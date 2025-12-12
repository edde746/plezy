import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../utils/grid_size_calculator.dart';
import '../utils/layout_constants.dart';

/// Shared grid delegate configuration for media item grids
/// Maintains consistent spacing (2/3.3 aspect ratio, 0 spacing) across all media grids
class MediaGridDelegate {
  /// Creates a standard grid delegate for media items
  ///
  /// Uses [GridSizeCalculator.getMaxCrossAxisExtent] by default.
  /// Set [usePaddingAware] to true to use [GridSizeCalculator.getMaxCrossAxisExtentWithPadding] instead.
  static SliverGridDelegateWithMaxCrossAxisExtent createDelegate({
    required BuildContext context,
    required LibraryDensity density,
    bool usePaddingAware = false,
    double horizontalPadding = 16,
  }) {
    final maxCrossAxisExtent = usePaddingAware
        ? GridSizeCalculator.getMaxCrossAxisExtentWithPadding(
            context,
            density,
            horizontalPadding,
          )
        : GridSizeCalculator.getMaxCrossAxisExtent(context, density);

    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxCrossAxisExtent,
      childAspectRatio: GridLayoutConstants.posterAspectRatio,
      crossAxisSpacing: GridLayoutConstants.crossAxisSpacing,
      mainAxisSpacing: GridLayoutConstants.mainAxisSpacing,
    );
  }
}
