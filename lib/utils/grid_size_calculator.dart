import 'package:flutter/material.dart';
import '../services/settings_service.dart' show LibraryDensity;
import '../constants/layout_constants.dart';

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
    final isTablet = screenWidth > tabletBreakpoint && screenWidth <= desktopBreakpoint;

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
