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

/// Pagination constants
class PaginationConstants {
  /// Default page size for library items
  static const int defaultPageSize = 1000;

  /// Page size for search results
  static const int searchPageSize = 50;
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

/// Padding and spacing constants
class SpacingConstants {
  /// Extra small spacing (4px)
  static const double xs = 4;

  /// Small spacing (8px)
  static const double sm = 8;

  /// Medium spacing (12px)
  static const double md = 12;

  /// Large spacing (16px)
  static const double lg = 16;

  /// Extra large spacing (24px)
  static const double xl = 24;

  /// Double extra large spacing (32px)
  static const double xxl = 32;
}

/// Icon size constants
class IconSizeConstants {
  /// Small icon size (16px)
  static const double sm = 16;

  /// Medium icon size (24px)
  static const double md = 24;

  /// Large icon size (32px)
  static const double lg = 32;

  /// Extra large icon size (48px)
  static const double xl = 48;
}

/// Border radius constants
class BorderRadiusConstants {
  /// Small border radius (4px)
  static const double sm = 4;

  /// Medium border radius (8px)
  static const double md = 8;

  /// Large border radius (12px)
  static const double lg = 12;

  /// Extra large border radius (16px)
  static const double xl = 16;
}
