import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plex_metadata.dart';
import '../providers/settings_provider.dart';
import 'media_card.dart';
import 'media_grid_delegate.dart';

/// Shared sliver grid builder for displaying media items
/// Used across hub detail, collection detail, playlist detail, and library browse screens
/// to maintain consistent spacing and focus behavior
class MediaGridSliver extends StatelessWidget {
  /// The list of media items to display
  final List<PlexMetadata> items;

  /// Callback when an item needs to be refreshed
  final void Function(String ratingKey)? onRefresh;

  /// Optional collection ID for collection-specific functionality
  final String? collectionId;

  /// Optional callback to refresh the entire parent list
  final VoidCallback? onListRefresh;

  /// Padding around the grid
  /// Defaults to EdgeInsets.fromLTRB(8, 0, 8, 8)
  final EdgeInsets padding;

  /// Whether to use the padding-aware cross axis extent calculation
  /// Defaults to false (uses standard GridSizeCalculator)
  final bool usePaddingAwareExtent;

  /// Horizontal padding to account for when usePaddingAwareExtent is true
  /// Only used if usePaddingAwareExtent is true
  final double horizontalPadding;

  /// Whether to use 16:9 aspect ratio for episode thumbnails
  final bool useWideAspectRatio;

  /// Whether this grid is displaying items from a mixed hub context
  /// (containing both episodes and non-episodes)
  final bool mixedHubContext;

  const MediaGridSliver({
    super.key,
    required this.items,
    this.onRefresh,
    this.collectionId,
    this.onListRefresh,
    this.padding = const EdgeInsets.fromLTRB(8, 0, 8, 8),
    this.usePaddingAwareExtent = false,
    this.horizontalPadding = 16,
    this.useWideAspectRatio = false,
    this.mixedHubContext = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return SliverGrid(
            gridDelegate: MediaGridDelegate.createDelegate(
              context: context,
              density: settingsProvider.libraryDensity,
              usePaddingAware: usePaddingAwareExtent,
              horizontalPadding: horizontalPadding,
              useWideAspectRatio: useWideAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = items[index];
              return MediaCard(
                key: Key(item.ratingKey),
                item: item,
                onRefresh: onRefresh,
                collectionId: collectionId,
                onListRefresh: onListRefresh,
                mixedHubContext: mixedHubContext,
              );
            }, childCount: items.length),
          );
        },
      ),
    );
  }
}
