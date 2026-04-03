import 'package:flutter/material.dart';
import '../services/settings_service.dart' show LibraryDensity;
import 'layout_constants.dart';
import 'platform_detector.dart';

/// Utility class for calculating consistent grid sizes across the app
class GridSizeCalculator {
  static double _lerp(double min, double max, double t) => min + (max - min) * t;

  /// Calculates the maximum cross-axis extent for grid items based on screen size and density.
  /// [density] is an int 1–5 (1 = most compact, 5 = most comfortable).
  static double getMaxCrossAxisExtent(BuildContext context, int density) {
    final screenWidth = MediaQuery.of(context).size.width;
    final f = LibraryDensity.factor(density);

    if (PlatformDetector.isTV()) return _lerp(120, 220, f);
    if (ScreenBreakpoints.isDesktopOrLarger(screenWidth)) return _lerp(140, 280, f);
    if (ScreenBreakpoints.isTablet(screenWidth)) return _lerp(120, 230, f);
    return _lerp(100, 200, f);
  }

  /// Calculates the max cross-axis extent accounting for outer padding.
  /// [density] is an int 1–5.
  static double getMaxCrossAxisExtentWithPadding(
    BuildContext context,
    int density,
    double horizontalPadding,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - horizontalPadding;
    final f = LibraryDensity.factor(density);

    // TV-specific sizing for 10ft viewing distance
    if (PlatformDetector.isTV()) {
      final divisor = _lerp(12, 6, f);
      final maxItemWidth = _lerp(140, 240, f);
      return (availableWidth / divisor).clamp(0, maxItemWidth);
    }

    if (ScreenBreakpoints.isWideTabletOrLarger(screenWidth)) {
      final divisor = _lerp(10, 5, f);
      final maxItemWidth = _lerp(140, 280, f);
      return (availableWidth / divisor).clamp(0, maxItemWidth);
    } else if (ScreenBreakpoints.isTablet(screenWidth)) {
      final targetItemCount = _lerp(6, 3, f);
      return availableWidth / targetItemCount;
    } else {
      final targetItemCount = _lerp(5, 2, f);
      return availableWidth / targetItemCount;
    }
  }

  /// Calculates the number of columns for a given available width.
  ///
  /// Uses the same formula as Flutter's SliverGridDelegateWithMaxCrossAxisExtent:
  /// `((crossAxisExtent + crossAxisSpacing) / (maxCrossAxisExtent + crossAxisSpacing)).ceil()`
  ///
  /// [crossAxisExtent] should come from layout constraints (e.g. `SliverLayoutBuilder`
  /// or `LayoutBuilder`), not from `MediaQuery`, to account for sidebars or other
  /// elements that reduce the grid's actual width.
  static int getColumnCount(double crossAxisExtent, double maxCrossAxisExtent) {
    final crossAxisSpacing = GridLayoutConstants.crossAxisSpacing;
    return ((crossAxisExtent + crossAxisSpacing) / (maxCrossAxisExtent + crossAxisSpacing)).ceil().clamp(1, 100);
  }

  /// Computes the actual cell width that a grid with [getMaxCrossAxisExtent] would produce
  /// for the given [availableWidth]. This matches SliverGridDelegateWithMaxCrossAxisExtent's
  /// internal calculation, so horizontal scroll lists can use the same width as grids.
  static double getCellWidth(double availableWidth, BuildContext context, int density) {
    final maxExtent = getMaxCrossAxisExtent(context, density);
    final columns = getColumnCount(availableWidth, maxExtent);
    return availableWidth / columns;
  }

  /// Check if the given index is in the first row of a grid with given column count.
  static bool isFirstRow(int index, int columnCount) {
    return index < columnCount;
  }

  /// Check if the given index is in the first column of a grid with given column count.
  static bool isFirstColumn(int index, int columnCount) {
    return index % columnCount == 0;
  }
}
