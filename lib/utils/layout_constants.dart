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

  static const double fullCardPosterAspectRatio = 2 / 3;

  static const double episodeThumbnailAspectRatio = 16 / 9;

  static const double episodeGridCellAspectRatio = 1.4;

  static const double crossAxisSpacing = 0;
  static const double mainAxisSpacing = 0;

  static double fullCardGridSpacingForScale(double scale) => (12 * scale).clamp(8, 18).toDouble();

  /// Standard grid padding
  static EdgeInsets get gridPadding => const EdgeInsets.only(left: 2, right: 2, bottom: 2);
}

class TvLayoutConstants {
  static const double horizontalInset = 72;
  static const double shelfHorizontalInset = 56;
  static const double shelfVerticalGap = 32;
  static const double heroContentMaxWidth = 760;
  static const double heroLogoWidth = 520;
  static const double heroLogoHeight = 150;
  static const double compactHeroLogoWidth = 420;
  static const double compactHeroLogoHeight = 112;

  static double scaleForHeight(double height) => (height / 1080).clamp(0.85, 1.35).toDouble();

  static double scaleForSize(Size size) => scaleForHeight(size.height);

  static double scaleOf(BuildContext context) => scaleForSize(MediaQuery.sizeOf(context));
}
