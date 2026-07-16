import 'package:flutter/material.dart';
import '../media/media_item.dart' show CardShape;
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
  /// Pass [shape] to select the cell silhouette directly — it wins over
  /// [useWideAspectRatio]; square cells keep the poster max extent.
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
    CardShape? shape,
    double? maxCrossAxisExtentOverride,
  }) {
    final aspectRatio = aspectRatioFor(
      useWideAspectRatio: useWideAspectRatio,
      fullBleedImage: fullBleedImage,
      shape: shape,
    );
    final spacing = spacingFor(context: context, fullBleedImage: fullBleedImage);

    final maxCrossAxisExtent =
        maxCrossAxisExtentOverride ??
        _maxCrossAxisExtentFor(
          context: context,
          density: density,
          usePaddingAware: usePaddingAware,
          horizontalPadding: horizontalPadding,
          useWideAspectRatio: useWideAspectRatio,
          shape: shape,
        );

    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxCrossAxisExtent,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
    );
  }

  /// Resolves the shape from the optional [shape] parameter, falling back to
  /// the legacy wide-vs-poster bool so existing call sites are byte-identical.
  static CardShape _resolveShape(CardShape? shape, bool useWideAspectRatio) =>
      shape ?? (useWideAspectRatio ? CardShape.wide : CardShape.poster);

  /// Resolves the max cross-axis extent the way [createDelegate] does,
  /// including the 1.8x widening for 16:9 episode thumbnails. Square cells
  /// keep the poster extent so column counts match the poster grid.
  static double _maxCrossAxisExtentFor({
    required BuildContext context,
    required int density,
    required bool usePaddingAware,
    required double horizontalPadding,
    required bool useWideAspectRatio,
    CardShape? shape,
  }) {
    var maxCrossAxisExtent = usePaddingAware
        ? GridSizeCalculator.getMaxCrossAxisExtentWithPadding(context, density, horizontalPadding)
        : GridSizeCalculator.getMaxCrossAxisExtent(context, density);

    // For wide aspect ratio (16:9), increase max extent so items are larger
    // and there are fewer per row (roughly 1.8x wider to maintain similar visual area)
    if (_resolveShape(shape, useWideAspectRatio) == CardShape.wide) {
      maxCrossAxisExtent *= 1.8;
    }
    return maxCrossAxisExtent;
  }

  static double spacingFor({required BuildContext context, bool fullBleedImage = false}) {
    if (!fullBleedImage) return GridLayoutConstants.crossAxisSpacing;
    return GridLayoutConstants.fullCardGridSpacingForScale(TvLayoutConstants.scaleOf(context));
  }

  static double aspectRatioFor({bool useWideAspectRatio = false, bool fullBleedImage = false, CardShape? shape}) {
    final resolved = _resolveShape(shape, useWideAspectRatio);
    if (fullBleedImage) {
      return switch (resolved) {
        CardShape.wide => GridLayoutConstants.episodeThumbnailAspectRatio,
        CardShape.square => GridLayoutConstants.squareAspectRatio,
        CardShape.poster => GridLayoutConstants.fullCardPosterAspectRatio,
      };
    }

    return switch (resolved) {
      CardShape.wide => GridLayoutConstants.episodeGridCellAspectRatio,
      CardShape.square => GridLayoutConstants.squareGridCellAspectRatio,
      CardShape.poster => GridLayoutConstants.posterAspectRatio,
    };
  }
}

/// The grid layout a media grid will render for a given cross-axis extent:
/// column count, cell size, spacing, and the matching delegate.
///
/// Use with `SliverCrossAxisLayoutBuilder` so this is resolved once per
/// width/settings change — never per scroll tick. [columnCount] follows the
/// same formula [SliverGridDelegateWithMaxCrossAxisExtent] uses at layout
/// time (see [GridSizeCalculator.getColumnCount], issue #1288), so d-pad row
/// math and the rendered grid always agree.
class MediaGridGeometry {
  final int columnCount;
  final double itemWidth;
  final double itemHeight;
  final double spacing;
  final SliverGridDelegateWithMaxCrossAxisExtent delegate;

  const MediaGridGeometry._({
    required this.columnCount,
    required this.itemWidth,
    required this.itemHeight,
    required this.spacing,
    required this.delegate,
  });

  /// Resolves the geometry for a grid laid out in [crossAxisExtent] (the
  /// sliver's width AFTER any wrapping [SliverPadding]).
  ///
  /// [crossAxisExtentForColumnCount], when non-null, computes the column
  /// count from that width instead, and pins the delegate's cell width to the
  /// resulting [itemWidth] — used by the library browse grid so the alpha
  /// jump bar's reservation doesn't repack the grid into fewer columns.
  static MediaGridGeometry resolve({
    required BuildContext context,
    required double crossAxisExtent,
    required int density,
    double? crossAxisExtentForColumnCount,
    bool usePaddingAware = false,
    double horizontalPadding = 16,
    bool useWideAspectRatio = false,
    bool fullBleedImage = false,
    CardShape? shape,
  }) {
    final spacing = MediaGridDelegate.spacingFor(context: context, fullBleedImage: fullBleedImage);
    final aspectRatio = MediaGridDelegate.aspectRatioFor(
      useWideAspectRatio: useWideAspectRatio,
      fullBleedImage: fullBleedImage,
      shape: shape,
    );
    final maxCrossAxisExtent = MediaGridDelegate._maxCrossAxisExtentFor(
      context: context,
      density: density,
      usePaddingAware: usePaddingAware,
      horizontalPadding: horizontalPadding,
      useWideAspectRatio: useWideAspectRatio,
      shape: shape,
    );

    final columnCount = GridSizeCalculator.getColumnCount(
      crossAxisExtentForColumnCount ?? crossAxisExtent,
      maxCrossAxisExtent,
      crossAxisSpacing: spacing,
    );
    final itemWidth = GridSizeCalculator.getCellWidthForColumnCount(
      crossAxisExtent,
      columnCount,
      crossAxisSpacing: spacing,
    );

    return MediaGridGeometry._(
      columnCount: columnCount,
      itemWidth: itemWidth,
      itemHeight: itemWidth / aspectRatio,
      spacing: spacing,
      delegate: SliverGridDelegateWithMaxCrossAxisExtent(
        // When the column count is pinned to a different basis width, the
        // delegate must pack exactly [columnCount] columns into the real
        // extent, so cap cells at the derived width instead.
        maxCrossAxisExtent: crossAxisExtentForColumnCount != null ? itemWidth : maxCrossAxisExtent,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
    );
  }
}
