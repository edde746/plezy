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
  static bool isWideTablet(double width) =>
      width >= wideTablet && width < desktop;

  /// Whether width is desktop-sized (1200px - 1599px)
  static bool isDesktop(double width) =>
      width >= desktop && width < largeDesktop;

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

/// Layout constants for spacing and corner radius
class LayoutConstants {
  /// Spacing constants
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 24.0;

  /// Corner radius constants
  static const double cornerRadiusSmall = 6.0;
  static const double cornerRadiusMedium = 8.0;
  static const double cornerRadiusLarge = 12.0;

  /// Convenience getters for EdgeInsets
  static EdgeInsets get paddingXSmall => const EdgeInsets.all(spacingXSmall);
  static EdgeInsets get paddingSmall => const EdgeInsets.all(spacingSmall);
  static EdgeInsets get paddingMedium => const EdgeInsets.all(spacingMedium);
  static EdgeInsets get paddingLarge => const EdgeInsets.all(spacingLarge);
  static EdgeInsets get paddingXLarge => const EdgeInsets.all(spacingXLarge);

  /// Convenience getters for horizontal EdgeInsets
  static EdgeInsets get paddingHorizontalXSmall =>
      const EdgeInsets.symmetric(horizontal: spacingXSmall);
  static EdgeInsets get paddingHorizontalSmall =>
      const EdgeInsets.symmetric(horizontal: spacingSmall);
  static EdgeInsets get paddingHorizontalMedium =>
      const EdgeInsets.symmetric(horizontal: spacingMedium);
  static EdgeInsets get paddingHorizontalLarge =>
      const EdgeInsets.symmetric(horizontal: spacingLarge);
  static EdgeInsets get paddingHorizontalXLarge =>
      const EdgeInsets.symmetric(horizontal: spacingXLarge);

  /// Convenience getters for vertical EdgeInsets
  static EdgeInsets get paddingVerticalXSmall =>
      const EdgeInsets.symmetric(vertical: spacingXSmall);
  static EdgeInsets get paddingVerticalSmall =>
      const EdgeInsets.symmetric(vertical: spacingSmall);
  static EdgeInsets get paddingVerticalMedium =>
      const EdgeInsets.symmetric(vertical: spacingMedium);
  static EdgeInsets get paddingVerticalLarge =>
      const EdgeInsets.symmetric(vertical: spacingLarge);
  static EdgeInsets get paddingVerticalXLarge =>
      const EdgeInsets.symmetric(vertical: spacingXLarge);

  /// Convenience getters for BorderRadius
  static BorderRadius get borderRadiusSmall =>
      BorderRadius.circular(cornerRadiusSmall);
  static BorderRadius get borderRadiusMedium =>
      BorderRadius.circular(cornerRadiusMedium);
  static BorderRadius get borderRadiusLarge =>
      BorderRadius.circular(cornerRadiusLarge);
}
