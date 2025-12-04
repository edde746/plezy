/// Layout and sizing constants used throughout the application
/// Screen width breakpoints for responsive design
class ScreenBreakpoints {
  /// Breakpoint for tablet devices (600px)
  static const double tablet = 600;

  /// Breakpoint for desktop devices (1200px)
  static const double desktop = 1200;

  /// Breakpoint for large desktop devices (1600px)
  static const double largeDesktop = 1600;
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

  /// Grid spacing
  static const double crossAxisSpacing = 0;
  static const double mainAxisSpacing = 0;
}
