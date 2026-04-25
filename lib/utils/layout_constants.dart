import 'package:flutter/widgets.dart';

/// Layout and sizing constants used throughout the application
/// Screen width breakpoints for responsive design
class ScreenBreakpoints {
  /// Breakpoint for mobile devices (< 600px)
  static const double mobile = 600;

  /// Breakpoint for wide tablets / small desktops (900px)
  /// Used for intermediate responsive layouts
  static const double wideTablet = 900;

  /// Breakpoint for desktop devices (1200px)
  static const double desktop = 1200;

  /// Breakpoint for large desktop devices (1600px)
  static const double largeDesktop = 1600;

  // Legacy alias for backward compatibility
  static const double tablet = mobile;

  /// Whether width is mobile-sized (< 600px)
  static bool isMobile(double width) => width < mobile;

  /// Whether width is tablet-sized (600px - 1199px)
  static bool isTablet(double width) => width >= mobile && width < desktop;

  /// Whether width is wide tablet (900px - 1199px)
  /// Useful for layouts that need more columns than phone but less than desktop
  static bool isWideTablet(double width) => width >= wideTablet && width < desktop;

  /// Whether width is desktop-sized (1200px - 1599px)
  static bool isDesktop(double width) => width >= desktop && width < largeDesktop;

  /// Whether width is large desktop-sized (>= 1600px)
  static bool isLargeDesktop(double width) => width >= largeDesktop;

  /// Whether width is desktop or larger (>= 1200px)
  static bool isDesktopOrLarger(double width) => width >= desktop;

  /// Whether width is wide tablet or larger (>= 900px)
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

/// Grid layout constants
class GridLayoutConstants {
  /// Default aspect ratio for media card grid cells (poster + text)
  static const double posterAspectRatio = 2 / 3.3;

  /// Aspect ratio for episode thumbnail image (16:9)
  static const double episodeThumbnailAspectRatio = 16 / 9;

  /// Aspect ratio for episode thumbnail grid cells (16:9 image + text area)
  /// This is wider than posterAspectRatio but accounts for ~60px text below
  static const double episodeGridCellAspectRatio = 1.4;

  /// Grid spacing (edge-to-edge cards)
  static const double crossAxisSpacing = 0;
  static const double mainAxisSpacing = 0;

  /// Standard grid padding
  static EdgeInsets get gridPadding => const EdgeInsets.only(left: 2, right: 2, bottom: 2);
}
