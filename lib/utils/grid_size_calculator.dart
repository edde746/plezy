import 'package:flutter/material.dart';
import '../services/settings_service.dart' show LibraryDensity;
import 'layout_constants.dart';
import 'platform_detector.dart';

/// Utility class for calculating consistent grid sizes across the app
class GridSizeCalculator {
  /// Screen width breakpoint for tablet devices
  static const double tabletBreakpoint = ScreenBreakpoints.tablet;

  /// Screen width breakpoint for desktop devices
  static const double desktopBreakpoint = ScreenBreakpoints.desktop;

  /// Calculates the maximum cross-axis extent for grid items based on screen size and density
  static double getMaxCrossAxisExtent(BuildContext context, LibraryDensity density) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = PlatformDetector.isTV();
    final isDesktop = screenWidth > desktopBreakpoint;
    final isTablet = screenWidth > tabletBreakpoint && screenWidth <= desktopBreakpoint;

    switch (density) {
      case LibraryDensity.comfortable:
        if (isTV) return GridLayoutConstants.comfortableTV;
        if (isDesktop) return GridLayoutConstants.comfortableDesktop;
        if (isTablet) return GridLayoutConstants.comfortableTablet;
        return GridLayoutConstants.comfortableMobile;
      case LibraryDensity.compact:
        if (isTV) return GridLayoutConstants.compactTV;
        if (isDesktop) return GridLayoutConstants.compactDesktop;
        if (isTablet) return GridLayoutConstants.compactTablet;
        return GridLayoutConstants.compactMobile;
      case LibraryDensity.normal:
        if (isTV) return GridLayoutConstants.normalTV;
        if (isDesktop) return GridLayoutConstants.normalDesktop;
        if (isTablet) return GridLayoutConstants.normalTablet;
        return GridLayoutConstants.normalMobile;
    }
  }

  /// Calculates the max cross-axis extent accounting for outer padding.
  ///
  /// Uses responsive strategies:
  /// - Wide screens (>=900px): Divisor-based calculation with max item width
  /// - Medium screens (600-899px): Fixed item count (4-6 items based on density)
  /// - Small screens (<600px): Fixed item count (2-4 items based on density)
  static double getMaxCrossAxisExtentWithPadding(
    BuildContext context,
    LibraryDensity density,
    double horizontalPadding,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - horizontalPadding;

    // TV-specific sizing for 10ft viewing distance
    if (PlatformDetector.isTV()) {
      double divisor;
      double maxItemWidth;
      switch (density) {
        case LibraryDensity.comfortable:
          divisor = 7.0;
          maxItemWidth = 220;
        case LibraryDensity.normal:
          divisor = 9.0;
          maxItemWidth = 190;
        case LibraryDensity.compact:
          divisor = 11.0;
          maxItemWidth = 160;
      }
      return (availableWidth / divisor).clamp(0, maxItemWidth);
    }

    if (ScreenBreakpoints.isWideTabletOrLarger(screenWidth)) {
      // Wide screens (desktop/large tablet landscape): Responsive division
      double divisor;
      double maxItemWidth;

      switch (density) {
        case LibraryDensity.comfortable:
          divisor = 5.5;
          maxItemWidth = 260;
        case LibraryDensity.normal:
          divisor = 6.5;
          maxItemWidth = 230;
        case LibraryDensity.compact:
          divisor = 9.0;
          maxItemWidth = 160;
      }

      return (availableWidth / divisor).clamp(0, maxItemWidth);
    } else if (ScreenBreakpoints.isTablet(screenWidth)) {
      // Medium screens (tablets): Fixed 3-4-6 items
      int targetItemCount = switch (density) {
        LibraryDensity.comfortable => 3,
        LibraryDensity.normal => 4,
        LibraryDensity.compact => 6,
      };
      return availableWidth / targetItemCount;
    } else {
      // Small screens (phones): Fixed 2-3-4 items
      int targetItemCount = switch (density) {
        LibraryDensity.comfortable => 2,
        LibraryDensity.normal => 3,
        LibraryDensity.compact => 4,
      };
      return availableWidth / targetItemCount;
    }
  }

  /// Returns whether the current screen is a desktop-sized screen
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > desktopBreakpoint;
  }

  /// Returns whether the current screen is a tablet-sized screen
  static bool isTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > tabletBreakpoint && screenWidth <= desktopBreakpoint;
  }

  /// Returns whether the current screen is a mobile-sized screen
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= tabletBreakpoint;
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

  /// Check if the given index is in the first row of a grid with given column count.
  static bool isFirstRow(int index, int columnCount) {
    return index < columnCount;
  }

  /// Check if the given index is in the first column of a grid with given column count.
  static bool isFirstColumn(int index, int columnCount) {
    return index % columnCount == 0;
  }
}
