import 'package:flutter/widgets.dart';

/// Layout and sizing constants used throughout the application
/// Screen width breakpoints for responsive design
class ScreenBreakpoints {
  static const double mobile = 600;

  static const double wideTablet = 900;

  static const double desktop = 1200;

  static const double largeDesktop = 1600;

  // Legacy alias for backward compatibility
  static const double tablet = mobile;

  static bool isMobile(double width) => width < mobile;

  static bool isTablet(double width) => width >= mobile && width < desktop;

  static bool isWideTablet(double width) => width >= wideTablet && width < desktop;

  static bool isDesktop(double width) => width >= desktop && width < largeDesktop;

  static bool isLargeDesktop(double width) => width >= largeDesktop;

  static bool isDesktopOrLarger(double width) => width >= desktop;

  static bool isWideTabletOrLarger(double width) => width >= wideTablet;
}

/// Animation and notification durations.
class AppDurations {
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration snackBarDefault = Duration(seconds: 3);
  static const Duration snackBarLong = Duration(seconds: 4);
}

class GridLayoutConstants {
  static const double posterAspectRatio = 2 / 3.3;

  static const double episodeThumbnailAspectRatio = 16 / 9;

  static const double episodeGridCellAspectRatio = 1.4;

  static const double crossAxisSpacing = 0;
  static const double mainAxisSpacing = 0;

  /// Standard grid padding
  static EdgeInsets get gridPadding => const EdgeInsets.only(left: 2, right: 2, bottom: 2);
}
