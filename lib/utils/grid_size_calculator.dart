import 'package:flutter/material.dart';
import '../services/settings_service.dart' show LibraryDensity;
import 'layout_constants.dart';

/// Utility class for calculating consistent grid sizes across the app
class GridSizeCalculator {
  /// Screen width breakpoint for tablet devices
  static const double tabletBreakpoint = ScreenBreakpoints.tablet;

  /// Screen width breakpoint for desktop devices
  static const double desktopBreakpoint = ScreenBreakpoints.desktop;

  /// Calculates the maximum cross-axis extent for grid items based on screen size and density
  static double getMaxCrossAxisExtent(
    BuildContext context,
    LibraryDensity density,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > desktopBreakpoint;
    final isTablet =
        screenWidth > tabletBreakpoint && screenWidth <= desktopBreakpoint;

    switch (density) {
      case LibraryDensity.comfortable:
        if (isDesktop) return GridLayoutConstants.comfortableDesktop;
        if (isTablet) return GridLayoutConstants.comfortableTablet;
        return GridLayoutConstants.comfortableMobile;
      case LibraryDensity.compact:
        if (isDesktop) return GridLayoutConstants.compactDesktop;
        if (isTablet) return GridLayoutConstants.compactTablet;
        return GridLayoutConstants.compactMobile;
      case LibraryDensity.normal:
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

    if (ScreenBreakpoints.isWideTabletOrLarger(screenWidth)) {
      // Wide screens (desktop/large tablet landscape): Responsive division
      double divisor;
      double maxItemWidth;

      switch (density) {
        case LibraryDensity.comfortable:
          divisor = 6.5;
          maxItemWidth = 280;
        case LibraryDensity.normal:
          divisor = 8.0;
          maxItemWidth = 200;
        case LibraryDensity.compact:
          divisor = 10.0;
          maxItemWidth = 160;
      }

      return (availableWidth / divisor).clamp(0, maxItemWidth);
    } else if (ScreenBreakpoints.isTablet(screenWidth)) {
      // Medium screens (tablets): Fixed 4-5-6 items
      int targetItemCount = switch (density) {
        LibraryDensity.comfortable => 4,
        LibraryDensity.normal => 5,
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
}
