import '../media/media_item.dart' show CardShape;
import '../services/settings_service.dart' show LibraryDensity;

/// Shared sizing math for media cards rendered in list mode.
class MediaCardListLayout {
  static const double padding = 8.0;

  static double basePosterWidth(int density) {
    return 70 + LibraryDensity.factor(density) * 50;
  }

  /// [shape] wins over [usesWideAspectRatio] when provided.
  static double posterWidth({required int density, bool usesWideAspectRatio = false, CardShape? shape}) {
    final base = basePosterWidth(density);
    return _resolveShape(shape, usesWideAspectRatio) == CardShape.wide ? base * 1.6 : base;
  }

  static double posterHeight({required int density, bool usesWideAspectRatio = false, CardShape? shape}) {
    final base = basePosterWidth(density);
    return switch (_resolveShape(shape, usesWideAspectRatio)) {
      CardShape.wide => base * 0.9,
      CardShape.square => base,
      CardShape.poster => base * 1.5,
    };
  }

  static double estimatedRowHeight({required int density, bool usesWideAspectRatio = false, CardShape? shape}) {
    final poster = posterHeight(density: density, usesWideAspectRatio: usesWideAspectRatio, shape: shape);
    return poster + padding * 2;
  }

  static CardShape _resolveShape(CardShape? shape, bool usesWideAspectRatio) =>
      shape ?? (usesWideAspectRatio ? CardShape.wide : CardShape.poster);
}
