import 'package:flutter/material.dart';

import '../media/media_item.dart';
import '../services/settings_service.dart';
import 'media_grid_delegate.dart';
import 'settings_builder.dart';
import 'sliver_cross_axis_layout_builder.dart';

@immutable
class MediaCardSliverPosition {
  const MediaCardSliverPosition({
    required this.index,
    required this.itemCount,
    required this.columnCount,
    required this.isGrid,
    this.layoutEpoch,
    this.isOnScreen,
  });

  final int index;
  final int itemCount;
  final int columnCount;
  final bool isGrid;
  final Object? layoutEpoch;

  /// Grid cells only: whether the cell intersects the grid's visible extent as
  /// of the grid's latest layout (cells realized in the cache extent do not).
  final bool Function()? isOnScreen;

  bool get isFirstRow => index < columnCount;
  bool get isFirstColumn => index % columnCount == 0;
  bool get isLastColumn => index % columnCount == columnCount - 1;
  bool get disableScale => !isGrid;
}

bool _gridCellOnScreen(BuildContext gridContext, SliverGridDelegate delegate, int index) {
  final constraints = gridContext.mounted ? SliverCrossAxisLayoutBuilder.latestConstraintsOf(gridContext) : null;
  if (constraints == null) return true;
  final cell = delegate.getLayout(constraints).getGeometryForChildIndex(index);
  return cell.scrollOffset < constraints.scrollOffset + constraints.remainingPaintExtent &&
      cell.trailingScrollOffset > constraints.scrollOffset;
}

typedef MediaCardSliverItemBuilder = Widget Function(BuildContext context, MediaCardSliverPosition position);

/// Shared list/grid sliver switch for media-card surfaces.
///
/// Consumers retain card construction and focus policy while this widget owns
/// the identical sliver wrappers, grid geometry, and delegate configuration.
class MediaCardSliverLayout extends StatelessWidget {
  const MediaCardSliverLayout({
    super.key,
    required this.viewMode,
    required this.itemCount,
    required this.density,
    required this.padding,
    required this.itemBuilder,
    this.findChildIndexCallback,
    this.fullBleedImage = false,
    this.useWideAspectRatio = false,
    this.shape,
    this.crossAxisExtentForColumnCount,
    this.onGridGeometry,
    this.listEpoch,
    this.gridEpochBuilder,
  });

  final ViewMode viewMode;
  final int itemCount;
  final int density;
  final EdgeInsetsGeometry padding;
  final MediaCardSliverItemBuilder itemBuilder;

  /// Maps a card's key to the index now holding its item, so a realized card
  /// follows its item when indices shift. Must return an index whose item
  /// builds a card with that key, or null.
  final ChildIndexGetter? findChildIndexCallback;
  final bool fullBleedImage;
  final bool useWideAspectRatio;
  final CardShape? shape;
  final double? Function(double crossAxisExtent)? crossAxisExtentForColumnCount;
  final ValueChanged<MediaGridGeometry>? onGridGeometry;
  final Object? listEpoch;
  final Object? Function(MediaGridGeometry geometry)? gridEpochBuilder;

  @override
  Widget build(BuildContext context) {
    if (viewMode == ViewMode.list) {
      return SliverPadding(
        padding: padding,
        sliver: SliverList.builder(
          addAutomaticKeepAlives: false,
          addSemanticIndexes: false,
          itemCount: itemCount,
          findChildIndexCallback: findChildIndexCallback,
          itemBuilder: (context, index) => _buildChild(
            context,
            MediaCardSliverPosition(
              index: index,
              itemCount: itemCount,
              columnCount: 1,
              isGrid: false,
              layoutEpoch: listEpoch,
            ),
          ),
        ),
      );
    }

    // Watched here — the single [MediaGridGeometry.resolve] call site — so
    // every grid re-lays out live when the grid-spacing setting changes,
    // without each screen adding the pref to its own watch list. The builder
    // ignores the value; resolve() reads it through the delegate's funnel.
    return SettingValueBuilder<GridSpacing>(
      pref: SettingsService.gridSpacing,
      builder: (context, _, _) => SliverPadding(
        padding: padding,
        sliver: SliverCrossAxisLayoutBuilder(
          builder: (context, crossAxisExtent) {
            final geometry = MediaGridGeometry.resolve(
              context: context,
              crossAxisExtent: crossAxisExtent,
              crossAxisExtentForColumnCount: crossAxisExtentForColumnCount?.call(crossAxisExtent),
              density: density,
              useWideAspectRatio: useWideAspectRatio,
              fullBleedImage: fullBleedImage,
              shape: shape,
            );
            onGridGeometry?.call(geometry);
            final layoutEpoch = gridEpochBuilder?.call(geometry);
            return SliverGrid.builder(
              addAutomaticKeepAlives: false,
              addSemanticIndexes: false,
              gridDelegate: geometry.delegate,
              itemCount: itemCount,
              findChildIndexCallback: findChildIndexCallback,
              itemBuilder: (context, index) => _buildChild(
                context,
                MediaCardSliverPosition(
                  index: index,
                  itemCount: itemCount,
                  columnCount: geometry.columnCount,
                  isGrid: true,
                  layoutEpoch: layoutEpoch,
                  isOnScreen: () => _gridCellOnScreen(context, geometry.delegate, index),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the card at [position], presenting its key only at the index
  /// [findChildIndexCallback] resolves that key to.
  ///
  /// On every rebuild the sliver moves each realized child to the index its
  /// key resolves to. Offset-paged data can hold one item at two indices (the
  /// server's order moved between page fetches); if both copies kept the key,
  /// a shift would move both into one slot and the displaced element would
  /// never unmount — its render box stays in the sliver with no layout offset
  /// and every later layout, paint, and hit test throws. Other copies are
  /// built unkeyed, which the sliver leaves at their own index.
  Widget _buildChild(BuildContext context, MediaCardSliverPosition position) {
    final child = itemBuilder(context, position);
    final key = child.key;
    final findIndex = findChildIndexCallback;
    if (key == null || findIndex == null || findIndex(key) == position.index) return child;
    return KeyedSubtree(child: child);
  }
}
