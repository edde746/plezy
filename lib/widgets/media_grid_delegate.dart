import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../utils/grid_size_calculator.dart';
import '../utils/grid_cross_axis_extent.dart';

/// Shared grid delegate configuration for media item grids
/// Maintains consistent spacing (2/3.3 aspect ratio, 0 spacing) across all media grids
class MediaGridDelegate {
  /// Standard aspect ratio for media cards (poster aspect)
  static const double aspectRatio = 2 / 3.3;

  /// Standard cross-axis spacing between grid items
  static const double crossAxisSpacing = 0;

  /// Standard main-axis spacing between grid items
  static const double mainAxisSpacing = 0;

  /// Creates a standard grid delegate for media items
  ///
  /// Uses [GridSizeCalculator.getMaxCrossAxisExtent] by default.
  /// Set [usePaddingAware] to true to use [getMaxCrossAxisExtentWithPadding] instead.
  static SliverGridDelegateWithMaxCrossAxisExtent createDelegate({
    required BuildContext context,
    required LibraryDensity density,
    bool usePaddingAware = false,
    double horizontalPadding = 16,
  }) {
    final maxCrossAxisExtent = usePaddingAware
        ? getMaxCrossAxisExtentWithPadding(context, density, horizontalPadding)
        : GridSizeCalculator.getMaxCrossAxisExtent(context, density);

    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxCrossAxisExtent,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }
}
