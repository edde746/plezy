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

/// Grid layout constants
class GridLayoutConstants {
  /// Maximum cross-axis extent for grid items in comfortable density mode
  static const double comfortableDesktop = 280;
  static const double comfortableTablet = 240;
  static const double comfortableMobile = 200;

  /// Maximum cross-axis extent for grid items in compact density mode
  static const double compactDesktop = 200;
  static const double compactTablet = 170;
  static const double compactMobile = 140;

  /// Maximum cross-axis extent for grid items in normal density mode
  static const double normalDesktop = 240;
  static const double normalTablet = 200;
  static const double normalMobile = 170;

  /// Default aspect ratio for media cards (poster)
  static const double posterAspectRatio = 2 / 3.3;

  /// Grid spacing (edge-to-edge cards)
  static const double crossAxisSpacing = 0;
  static const double mainAxisSpacing = 0;

  /// Standard grid padding
  static EdgeInsets get gridPadding => const EdgeInsets.fromLTRB(8, 0, 8, 8);
}
