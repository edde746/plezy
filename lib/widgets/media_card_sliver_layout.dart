import 'package:flutter/material.dart';

import '../media/media_item.dart';
import '../services/settings_service.dart';
import 'media_grid_delegate.dart';
import 'sliver_cross_axis_layout_builder.dart';

@immutable
class MediaCardSliverPosition {
  const MediaCardSliverPosition({
    required this.index,
    required this.itemCount,
    required this.columnCount,
    required this.isGrid,
    this.layoutEpoch,
  });

  final int index;
  final int itemCount;
  final int columnCount;
  final bool isGrid;
  final Object? layoutEpoch;

  bool get isFirstRow => index < columnCount;
  bool get isFirstColumn => index % columnCount == 0;
  bool get isLastColumn => index % columnCount == columnCount - 1;
  bool get disableScale => !isGrid;
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
    this.fullBleedImage = false,
    this.useWideAspectRatio = false,
    this.shape,
    this.usePaddingAware = false,
    this.horizontalPadding = 0,
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
  final bool fullBleedImage;
  final bool useWideAspectRatio;
  final CardShape? shape;
  final bool usePaddingAware;
  final double horizontalPadding;
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
          itemBuilder: (context, index) => itemBuilder(
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

    return SliverPadding(
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
            usePaddingAware: usePaddingAware,
            horizontalPadding: horizontalPadding,
          );
          onGridGeometry?.call(geometry);
          final layoutEpoch = gridEpochBuilder?.call(geometry);
          return SliverGrid.builder(
            addAutomaticKeepAlives: false,
            addSemanticIndexes: false,
            gridDelegate: geometry.delegate,
            itemCount: itemCount,
            itemBuilder: (context, index) => itemBuilder(
              context,
              MediaCardSliverPosition(
                index: index,
                itemCount: itemCount,
                columnCount: geometry.columnCount,
                isGrid: true,
                layoutEpoch: layoutEpoch,
              ),
            ),
          );
        },
      ),
    );
  }
}
