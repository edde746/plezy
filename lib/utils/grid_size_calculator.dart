import 'package:flutter/material.dart';
import '../services/settings_service.dart' show LibraryDensity;
import 'layout_constants.dart';
import 'platform_detector.dart';

class GridSizeCalculator {
  static double _lerp(double min, double max, double t) => min + (max - min) * t;

  /// Calculates the maximum cross-axis extent for grid items based on screen size and density.
  /// [density] is an int 1–5 (1 = most compact, 5 = most comfortable).
  static double getMaxCrossAxisExtent(BuildContext context, int density) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final f = LibraryDensity.factor(density);

    if (PlatformDetector.isTV()) return _lerp(120, 220, f);
    if (ScreenBreakpoints.isDesktopOrLarger(screenWidth)) return _lerp(140, 280, f);
    if (ScreenBreakpoints.isTablet(screenWidth)) return _lerp(120, 230, f);
    return _lerp(100, 200, f);
  }

  /// Calculates the number of columns for a given available width.
  ///
  /// Matches Flutter's SliverGridDelegateWithMaxCrossAxisExtent exactly (see
  /// rendering/sliver_grid.dart), so this navigation column count equals the
  /// number of columns the grid actually renders. A mismatch makes dpad "down"
  /// (`index + columnCount`) land diagonally — see issue #1288. Note the spacing
  /// is added to the denominator only, not the numerator:
  /// `(crossAxisExtent / (maxCrossAxisExtent + crossAxisSpacing)).ceil()`
  ///
  /// [crossAxisExtent] should come from layout constraints (e.g.
  /// `SliverCrossAxisLayoutBuilder` or `LayoutBuilder`), not from `MediaQuery`,
  /// to account for sidebars or other elements that reduce the grid's actual
  /// width. Never use a plain `SliverLayoutBuilder` for this: its constraints
  /// include the scroll offset, so it rebuilds the whole grid every scroll tick.
  static int getColumnCount(double crossAxisExtent, double maxCrossAxisExtent, {double? crossAxisSpacing}) {
    final effectiveSpacing = crossAxisSpacing ?? GridLayoutConstants.crossAxisSpacing;
    return (crossAxisExtent / (maxCrossAxisExtent + effectiveSpacing)).ceil().clamp(1, 100);
  }

  static double getCellWidthForColumnCount(double crossAxisExtent, int columnCount, {double? crossAxisSpacing}) {
    final effectiveSpacing = crossAxisSpacing ?? GridLayoutConstants.crossAxisSpacing;
    return (crossAxisExtent - (effectiveSpacing * (columnCount - 1))) / columnCount;
  }

  /// Computes the actual cell width that a grid with [getMaxCrossAxisExtent] would produce
  /// for the given [availableWidth]. This matches SliverGridDelegateWithMaxCrossAxisExtent's
  /// internal calculation, so horizontal scroll lists can use the same width as grids.
  static double getCellWidth(double availableWidth, BuildContext context, int density) {
    final maxExtent = getMaxCrossAxisExtent(context, density);
    final columns = getColumnCount(availableWidth, maxExtent);
    return getCellWidthForColumnCount(availableWidth, columns);
  }

  static bool isFirstRow(int index, int columnCount) {
    return index < columnCount;
  }

  static bool isFirstColumn(int index, int columnCount) {
    return index % columnCount == 0;
  }
}
