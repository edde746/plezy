import 'package:flutter/material.dart';
import '../utils/grid_size_calculator.dart';
import '../utils/layout_constants.dart';

/// Shared grid delegate configuration for media item grids
/// Maintains consistent aspect ratio and spacing across all media grids.
class MediaGridDelegate {
  /// Creates a standard grid delegate for media items
  ///
  /// Uses [GridSizeCalculator.getMaxCrossAxisExtent] by default.
  /// Set [usePaddingAware] to true to use [GridSizeCalculator.getMaxCrossAxisExtentWithPadding] instead.
  /// Set [useWideAspectRatio] to true to use 16:9 aspect ratio for episode thumbnails.
  /// Set [fullBleedImage] to true when the card is image-only and should not reserve text height.
  /// Pass [maxCrossAxisExtentOverride] to bypass the calculator and the wide-aspect multiplier —
  /// the caller is then responsible for providing a fully-resolved per-cell width.
  static SliverGridDelegateWithMaxCrossAxisExtent createDelegate({
    required BuildContext context,
    required int density,
    bool usePaddingAware = false,
    double horizontalPadding = 16,
    bool useWideAspectRatio = false,
    bool fullBleedImage = false,
    double? maxCrossAxisExtentOverride,
  }) {
    final aspectRatio = aspectRatioFor(useWideAspectRatio: useWideAspectRatio, fullBleedImage: fullBleedImage);
    final spacing = spacingFor(context: context, fullBleedImage: fullBleedImage);

    double maxCrossAxisExtent;
    if (maxCrossAxisExtentOverride != null) {
      maxCrossAxisExtent = maxCrossAxisExtentOverride;
    } else {
      maxCrossAxisExtent = usePaddingAware
          ? GridSizeCalculator.getMaxCrossAxisExtentWithPadding(context, density, horizontalPadding)
          : GridSizeCalculator.getMaxCrossAxisExtent(context, density);

      // For wide aspect ratio (16:9), increase max extent so items are larger
      // and there are fewer per row (roughly 1.8x wider to maintain similar visual area)
      if (useWideAspectRatio) {
        maxCrossAxisExtent *= 1.8;
      }
    }

    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxCrossAxisExtent,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );
  }

  static double spacingFor({required BuildContext context, bool fullBleedImage = false}) {
    if (!fullBleedImage) return GridLayoutConstants.crossAxisSpacing;
    return GridLayoutConstants.fullCardGridSpacingForScale(TvLayoutConstants.scaleOf(context));
  }

  static double aspectRatioFor({bool useWideAspectRatio = false, bool fullBleedImage = false}) {
    if (fullBleedImage) {
      return useWideAspectRatio
          ? GridLayoutConstants.episodeThumbnailAspectRatio
          : GridLayoutConstants.fullCardPosterAspectRatio;
    }

    return useWideAspectRatio ? GridLayoutConstants.episodeGridCellAspectRatio : GridLayoutConstants.posterAspectRatio;
  }
}
