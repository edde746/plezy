import 'package:flutter/material.dart';
import 'package:plezy/utils/content_utils.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../models/plex_metadata.dart';
import '../models/plex_playlist.dart';
import '../providers/download_provider.dart';
import '../services/download_storage_service.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../utils/provider_extensions.dart';
import '../utils/formatters.dart';
import '../utils/media_navigation_helper.dart';
import '../utils/snackbar_helper.dart';
import '../theme/mono_tokens.dart';
import '../i18n/strings.g.dart';
import 'media_context_menu.dart';
import 'media_progress_bar.dart';
import 'plex_optimized_image.dart';
import '../screens/media_detail_screen.dart';

class MediaCard extends StatefulWidget {
  final dynamic item; // Can be PlexMetadata or PlexPlaylist
  final double? width;
  final double? height;
  final void Function(String ratingKey)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final VoidCallback? onListRefresh; // Callback to refresh the entire parent list
  final bool forceGridMode;
  final bool isInContinueWatching;
  final String? collectionId; // The collection ID if displaying within a collection
  final bool isOffline; // True for downloaded content without server access
  final bool mixedHubContext; // True when in a hub with mixed content (movies + episodes)

  const MediaCard({
    super.key,
    required this.item,
    this.width,
    this.height,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.onListRefresh,
    this.forceGridMode = false,
    this.isInContinueWatching = false,
    this.collectionId,
    this.isOffline = false,
    this.mixedHubContext = false,
  });

  @override
  State<MediaCard> createState() => MediaCardState();
}

class MediaCardState extends State<MediaCard> {
  final _contextMenuKey = GlobalKey<MediaContextMenuState>();

  void _showContextMenu() {
    _contextMenuKey.currentState?.showContextMenu(context);
  }

  /// Public method to trigger tap action (for keyboard/gamepad SELECT)
  void handleTap() {
    _handleTap(context);
  }

  /// Public method to show context menu (for keyboard/gamepad context menu key)
  void showContextMenu() {
    _showContextMenu();
  }

  String _buildSemanticLabel() {
    final item = widget.item;

    // Playlists don't expose mediaType, so build a simple localized label and exit early
    if (item is PlexPlaylist) {
      final count = item.leafCount;
      final countText = count != null ? ', ${t.playlists.itemCount(count: count)}' : '';
      return '${item.displayTitle}, ${t.playlists.playlist}$countText';
    }

    // Build base label based on PlexMetadata media type
    if (item is! PlexMetadata) {
      return '$item';
    }

    String baseLabel;
    switch (item.mediaType) {
      case PlexMediaType.episode:
        final episodeInfo = item.parentIndex != null && item.index != null ? 'S${item.parentIndex} E${item.index}' : '';
        baseLabel = t.accessibility.mediaCardEpisode(title: item.displayTitle, episodeInfo: episodeInfo);
      case PlexMediaType.season:
        final seasonInfo = item.parentIndex != null ? 'Season ${item.parentIndex}' : '';
        baseLabel = t.accessibility.mediaCardSeason(title: item.displayTitle, seasonInfo: seasonInfo);
      case PlexMediaType.movie:
        baseLabel = t.accessibility.mediaCardMovie(title: item.displayTitle);
      default:
        baseLabel = t.accessibility.mediaCardShow(title: item.displayTitle);
    }

    // Add watched status
    if (item.isWatched) {
      baseLabel = '$baseLabel, ${t.accessibility.mediaCardWatched}';
    } else if (item.viewOffset != null && item.duration != null && item.viewOffset! > 0) {
      final percent = ((item.viewOffset! / item.duration!) * 100).round();
      baseLabel = '$baseLabel, ${t.accessibility.mediaCardPartiallyWatched(percent: percent)}';
    } else {
      baseLabel = '$baseLabel, ${t.accessibility.mediaCardUnwatched}';
    }

    return baseLabel;
  }

  void _handleTap(BuildContext context) async {
    // Ignore taps while context menu is open to avoid double-activating
    if (_contextMenuKey.currentState?.isContextMenuOpen == true) {
      return;
    }

    final result = await navigateToMediaItem(
      context,
      widget.item,
      onRefresh: widget.onRefresh,
      isOffline: widget.isOffline,
      playDirectly: widget.isInContinueWatching,
    );

    if (!context.mounted) return;

    switch (result) {
      case MediaNavigationResult.unsupported:
        showAppSnackBar(context, t.messages.musicNotSupported);
      case MediaNavigationResult.listRefreshNeeded:
        widget.onListRefresh?.call();
      case MediaNavigationResult.navigated:
        // Item refresh already handled by onRefresh callback in helper
        break;
    }
  }

  /// Get the local poster path for offline mode
  String? _getLocalPosterPath(BuildContext context) {
    if (!widget.isOffline) return null;
    if (widget.item is! PlexMetadata) return null;

    final metadata = widget.item as PlexMetadata;
    if (metadata.serverId == null) return null;

    final downloadProvider = context.read<DownloadProvider>();
    final globalKey = '${metadata.serverId}:${metadata.ratingKey}';

    // Get artwork reference and resolve to local path using hash (includes serverId)
    final artwork = downloadProvider.getArtworkPaths(globalKey);
    return artwork?.getLocalPath(DownloadStorageService.instance, metadata.serverId!);
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final viewMode = widget.forceGridMode ? ViewMode.grid : settingsProvider.viewMode;

    final semanticLabel = _buildSemanticLabel();
    final localPosterPath = _getLocalPosterPath(context);

    final cardWidget = viewMode == ViewMode.grid
        ? _MediaCardGrid(
            item: widget.item,
            width: widget.width,
            height: widget.height,
            semanticLabel: semanticLabel,
            onTap: () => _handleTap(context),
            onLongPress: _showContextMenu,
            isOffline: widget.isOffline,
            localPosterPath: localPosterPath,
            mixedHubContext: widget.mixedHubContext,
          )
        : _MediaCardList(
            item: widget.item,
            semanticLabel: semanticLabel,
            onTap: () => _handleTap(context),
            onLongPress: _showContextMenu,
            density: settingsProvider.libraryDensity,
            isOffline: widget.isOffline,
            localPosterPath: localPosterPath,
          );

    // Use context menu for both PlexMetadata and PlexPlaylist items
    return MediaContextMenu(
      key: _contextMenuKey,
      item: widget.item,
      onRefresh: widget.onRefresh,
      onRemoveFromContinueWatching: widget.onRemoveFromContinueWatching,
      onListRefresh: widget.onListRefresh,
      onTap: () => _handleTap(context),
      isInContinueWatching: widget.isInContinueWatching,
      collectionId: widget.collectionId,
      child: cardWidget,
    );
  }
}

/// Grid layout for media cards
class _MediaCardGrid extends StatelessWidget {
  final dynamic item; // Can be PlexMetadata or PlexPlaylist
  final double? width;
  final double? height;
  final String semanticLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isOffline;
  final String? localPosterPath;
  final bool mixedHubContext;

  const _MediaCardGrid({
    required this.item,
    this.width,
    this.height,
    required this.semanticLabel,
    required this.onTap,
    required this.onLongPress,
    this.isOffline = false,
    this.localPosterPath,
    this.mixedHubContext = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool canNavigateToDetail = _MediaCardHelpers.canNavigateToDetailPage(item);

    return SizedBox(
      width: width,
      child: Semantics(
        label: semanticLabel,
        button: true,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster - tapping plays the content
              if (height != null)
                SizedBox(width: double.infinity, height: height, child: _buildClickablePoster(context, onTap))
              else
                Expanded(child: _buildClickablePoster(context, onTap)),
              const SizedBox(height: 4),
              // Text content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Title - for episodes/movies, navigates to detail page; otherwise plays
                  _HoverableTitle(
                    title: item is PlexPlaylist ? (item as PlexPlaylist).title : (item as PlexMetadata).displayTitle,
                    onTap: canNavigateToDetail
                        ? () => _MediaCardHelpers.navigateToDetailPage(context, item as PlexMetadata)
                        : onTap,
                    showHoverEffect: canNavigateToDetail,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.1),
                  ),
                  // Subtitle - tapping plays the episode
                  if (item is PlexPlaylist)
                    GestureDetector(
                      onTap: onTap,
                      child: _MediaCardHelpers.buildPlaylistMeta(context, item as PlexPlaylist),
                    )
                  else if (item is PlexMetadata)
                    GestureDetector(
                      onTap: onTap,
                      child: _MediaCardHelpers.buildMetadataSubtitle(context, item as PlexMetadata),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPosterWithOverlay(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens(context).radiusSm),
          child: _buildPosterImage(
            context,
            item,
            isOffline: isOffline,
            localPosterPath: localPosterPath,
            mixedHubContext: mixedHubContext,
          ),
        ),
        _PosterOverlay(item: item),
      ],
    );
  }

  Widget _buildClickablePoster(BuildContext context, VoidCallback onTap) {
    return Stack(
      children: [
        // Poster image at the bottom
        _buildPosterWithOverlay(context),
        // InkWell on top for hover/tap effect
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(tokens(context).radiusSm),
            ),
          ),
        ),
      ],
    );
  }
}

/// List layout for media cards
class _MediaCardList extends StatelessWidget {
  final dynamic item; // Can be PlexMetadata or PlexPlaylist
  final String semanticLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final LibraryDensity density;
  final bool isOffline;
  final String? localPosterPath;

  const _MediaCardList({
    required this.item,
    required this.semanticLabel,
    required this.onTap,
    required this.onLongPress,
    required this.density,
    this.isOffline = false,
    this.localPosterPath,
  });

  double _basePosterWidth() {
    switch (density) {
      case LibraryDensity.compact:
        return 80;
      case LibraryDensity.normal:
        return 100;
      case LibraryDensity.comfortable:
        return 120;
    }
  }

  double _posterWidth(BuildContext context) {
    final base = _basePosterWidth();
    // For episodes with thumbnail mode, use wider width to maintain reasonable thumbnail size
    if (item is PlexMetadata) {
      final mode = context.watch<SettingsProvider>().episodePosterMode;
      if ((item as PlexMetadata).usesWideAspectRatio(mode)) {
        return base * 1.6; // Wider for 16:9 thumbnails
      }
    }
    return base;
  }

  double _posterHeight(BuildContext context) {
    final base = _basePosterWidth();
    // For episodes with thumbnail mode, use 16:9 aspect ratio
    if (item is PlexMetadata) {
      final mode = context.watch<SettingsProvider>().episodePosterMode;
      if ((item as PlexMetadata).usesWideAspectRatio(mode)) {
        // 16:9: height = width * 9/16 = base * 1.6 * 9/16 = base * 0.9
        return base * 0.9;
      }
    }
    return base * 1.5; // Default 2:3 aspect ratio
  }

  double get _titleFontSize {
    switch (density) {
      case LibraryDensity.compact:
        return 14;
      case LibraryDensity.normal:
        return 15;
      case LibraryDensity.comfortable:
        return 16;
    }
  }

  double get _metadataFontSize {
    switch (density) {
      case LibraryDensity.compact:
        return 11;
      case LibraryDensity.normal:
        return 12;
      case LibraryDensity.comfortable:
        return 13;
    }
  }

  double get _subtitleFontSize {
    switch (density) {
      case LibraryDensity.compact:
        return 12;
      case LibraryDensity.normal:
        return 13;
      case LibraryDensity.comfortable:
        return 14;
    }
  }

  double get _summaryFontSize {
    // Summary uses the same sizing as metadata text
    return _metadataFontSize;
  }

  int get _summaryMaxLines {
    switch (density) {
      case LibraryDensity.compact:
        return 2;
      case LibraryDensity.normal:
        return 3;
      case LibraryDensity.comfortable:
        return 4;
    }
  }

  String _buildMetadataLine() {
    final parts = <String>[];

    if (item is PlexPlaylist) {
      final playlist = item as PlexPlaylist;
      // Add item count
      if (playlist.leafCount != null && playlist.leafCount! > 0) {
        parts.add(t.playlists.itemCount(count: playlist.leafCount!));
      }

      // Add duration
      if (playlist.duration != null) {
        parts.add(formatDurationTextual(playlist.duration!));
      }

      // Add smart playlist badge
      if (playlist.smart) {
        parts.add(t.playlists.smartPlaylist);
      }
    } else if (item is PlexMetadata) {
      final metadata = item as PlexMetadata;

      // For collections, show item count
      if (metadata.mediaType == PlexMediaType.collection) {
        final count = metadata.childCount ?? metadata.leafCount;
        if (count != null && count > 0) {
          parts.add(t.playlists.itemCount(count: count));
        }
      } else {
        // For other media types, show standard metadata
        // Add content rating
        if (metadata.contentRating != null && metadata.contentRating!.isNotEmpty) {
          final rating = formatContentRating(metadata.contentRating);
          if (rating.isNotEmpty) {
            parts.add(rating);
          }
        }

        // Add year
        if (metadata.year != null) {
          parts.add('${metadata.year}');
        }

        // Add duration
        if (metadata.duration != null) {
          parts.add(formatDurationTextual(metadata.duration!));
        }

        // Add user rating
        if (metadata.rating != null) {
          parts.add('${metadata.rating!.toStringAsFixed(1)}★');
        }

        // Add studio
        if (metadata.studio != null && metadata.studio!.isNotEmpty) {
          parts.add(metadata.studio!);
        }
      }
    }

    return parts.join(' • ');
  }

  String? _buildSubtitleText() {
    if (item is PlexPlaylist) {
      // Playlists don't have subtitles
      return null;
    } else if (item is PlexMetadata) {
      final metadata = item as PlexMetadata;

      // For TV episodes, show S#E# format
      if (metadata.parentIndex != null && metadata.index != null) {
        return 'S${metadata.parentIndex} E${metadata.index}';
      }

      // Otherwise use existing subtitle logic
      if (metadata.displaySubtitle != null) {
        return metadata.displaySubtitle;
      } else if (metadata.parentTitle != null) {
        return metadata.parentTitle;
      }
    }

    // Year is now shown in metadata line, so don't show it here
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final metadataLine = _buildMetadataLine();
    final subtitle = _buildSubtitleText();
    final bool canNavigateToDetail = _MediaCardHelpers.canNavigateToDetailPage(item);

    return Semantics(
      label: semanticLabel,
      button: true,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster (responsive size based on density) - tapping plays the content
            SizedBox(
              width: _posterWidth(context),
              height: _posterHeight(context),
              child: Stack(
                children: [
                  // Poster image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                    child: _buildPosterImage(context, item, isOffline: isOffline, localPosterPath: localPosterPath),
                  ),
                  _PosterOverlay(item: item),
                  // InkWell on top for hover/tap effect
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Title - for episodes/movies, navigates to detail page; otherwise plays
                  _HoverableTitle(
                    title: item.displayTitle,
                    onTap: canNavigateToDetail
                        ? () => _MediaCardHelpers.navigateToDetailPage(context, item as PlexMetadata)
                        : onTap,
                    showHoverEffect: canNavigateToDetail,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: _titleFontSize, height: 1.2),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  // Metadata info line (rating, duration, score, studio) - tapping plays
                  if (metadataLine.isNotEmpty) ...[
                    GestureDetector(
                      onTap: onTap,
                      child: Text(
                        metadataLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens(context).textMuted.withValues(alpha: 0.9),
                          fontSize: _metadataFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  // Subtitle (S#E# or year/parent title) - tapping plays
                  if (subtitle != null) ...[
                    GestureDetector(
                      onTap: onTap,
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens(context).textMuted.withValues(alpha: 0.85),
                          fontSize: _subtitleFontSize,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Summary - tapping plays
                  if (item.summary != null) ...[
                    GestureDetector(
                      onTap: onTap,
                      child: Text(
                        item.summary!,
                        maxLines: _summaryMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens(context).textMuted.withValues(alpha: 0.7),
                          fontSize: _summaryFontSize,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildPosterImage(
  BuildContext context,
  dynamic item, {
  bool isOffline = false,
  String? localPosterPath,
  bool mixedHubContext = false,
}) {
  String? posterUrl;
  IconData fallbackIcon = Symbols.movie_rounded;

  if (item is PlexPlaylist) {
    posterUrl = item.displayImage;
    fallbackIcon = Symbols.playlist_play_rounded;

    return PlexOptimizedImage.playlist(
      client: isOffline ? null : context.getClientWithFallback(item.serverId),
      imagePath: posterUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      localFilePath: localPosterPath,
    );
  } else if (item is PlexMetadata) {
    final episodePosterMode = context.watch<SettingsProvider>().episodePosterMode;
    posterUrl = item.posterThumb(mode: episodePosterMode, mixedHubContext: mixedHubContext);

    // Use thumb image type for 16:9 content (episodes, or movies in mixed hubs)
    if (item.usesWideAspectRatio(episodePosterMode, mixedHubContext: mixedHubContext)) {
      return PlexOptimizedImage.thumb(
        client: isOffline ? null : context.getClientWithFallback(item.serverId),
        imagePath: posterUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        localFilePath: localPosterPath,
      );
    }

    return PlexOptimizedImage.poster(
      client: isOffline ? null : context.getClientWithFallback(item.serverId),
      imagePath: posterUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      localFilePath: localPosterPath,
    );
  }

  return SkeletonLoader(
    child: Center(child: AppIcon(fallbackIcon, fill: 1, size: 40, color: Colors.white54)),
  );
}

/// Overlay widget for poster showing watched indicator and progress bar
class _PosterOverlay extends StatelessWidget {
  final dynamic item; // Can be PlexMetadata or PlexPlaylist

  const _PosterOverlay({required this.item});

  @override
  Widget build(BuildContext context) {
    // Only show overlays for PlexMetadata items
    if (item is! PlexMetadata) {
      return const SizedBox.shrink();
    }

    return _MediaCardHelpers.buildWatchProgress(context, item as PlexMetadata);
  }
}

/// Helper methods for building media card metadata and subtitles
class _MediaCardHelpers {
  /// Builds playlist metadata (item count)
  static Widget buildPlaylistMeta(BuildContext context, PlexPlaylist playlist) {
    if (playlist.leafCount != null && playlist.leafCount! > 0) {
      return Text(
        t.playlists.itemCount(count: playlist.leafCount!),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 11, height: 1.1),
      );
    }
    return const SizedBox.shrink();
  }

  /// Builds metadata subtitle (for collections, episodes, movies, shows)
  static Widget buildMetadataSubtitle(BuildContext context, PlexMetadata metadata) {
    // For collections, show item count
    if (metadata.mediaType == PlexMediaType.collection) {
      final count = metadata.childCount ?? metadata.leafCount;
      if (count != null && count > 0) {
        return Text(
          t.playlists.itemCount(count: count),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 11, height: 1.1),
        );
      }
    }

    // For other media types, show subtitle/parent/year
    if (metadata.displaySubtitle != null) {
      return Text(
        metadata.displaySubtitle!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 11, height: 1.1),
      );
    } else if (metadata.parentTitle != null) {
      return Text(
        metadata.parentTitle!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 11, height: 1.1),
      );
    } else if (metadata.year != null) {
      return Text(
        '${metadata.year}',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 11, height: 1.1),
      );
    }

    return const SizedBox.shrink();
  }

  /// Builds watch progress overlay (checkmark for watched, progress bar for in-progress)
  static Widget buildWatchProgress(BuildContext context, PlexMetadata metadata) {
    return Stack(
      children: [
        // Watched indicator (checkmark)
        if (metadata.isWatched)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: tokens(context).text,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
              ),
              child: AppIcon(Symbols.check_rounded, fill: 1, color: tokens(context).bg, size: 16),
            ),
          ),
        // Progress bar for partially watched content (episodes/movies)
        if (metadata.viewOffset != null && metadata.duration != null && metadata.viewOffset! > 0 && !metadata.isWatched)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
              child: MediaProgressBar(viewOffset: metadata.viewOffset!, duration: metadata.duration!),
            ),
          ),
        // Progress bar for seasons (viewedLeafCount / leafCount)
        if (metadata.isSeason &&
            metadata.viewedLeafCount != null &&
            metadata.leafCount != null &&
            metadata.leafCount! > 0 &&
            metadata.viewedLeafCount! > 0 &&
            metadata.viewedLeafCount! < metadata.leafCount!)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
              child: LinearProgressIndicator(
                value: metadata.viewedLeafCount! / metadata.leafCount!,
                backgroundColor: tokens(context).outline,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                minHeight: 4,
              ),
            ),
          ),
      ],
    );
  }

  /// Whether this item's title should navigate to a detail page
  /// (episodes go to show page, movies go to movie detail page)
  static bool canNavigateToDetailPage(dynamic item) {
    if (item is! PlexMetadata) return false;
    // Episodes navigate to parent show
    if (item.mediaType == PlexMediaType.episode && item.grandparentRatingKey != null && item.grandparentTitle != null) {
      return true;
    }
    // Movies navigate to movie detail page
    if (item.mediaType == PlexMediaType.movie) {
      return true;
    }
    return false;
  }

  /// Navigate to the appropriate detail screen based on item type
  static void navigateToDetailPage(BuildContext context, PlexMetadata item) {
    if (item.mediaType == PlexMediaType.episode && item.grandparentRatingKey != null && item.grandparentTitle != null) {
      // Episode: navigate to parent show
      final showMetadata = PlexMetadata(
        ratingKey: item.grandparentRatingKey!,
        key: '/library/metadata/${item.grandparentRatingKey}',
        type: 'show',
        title: item.grandparentTitle!,
        thumb: item.grandparentThumb,
        art: item.grandparentArt,
        serverId: item.serverId,
        serverName: item.serverName,
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => MediaDetailScreen(metadata: showMetadata)));
    } else if (item.mediaType == PlexMediaType.movie) {
      // Movie: navigate to movie detail page
      Navigator.push(context, MaterialPageRoute(builder: (context) => MediaDetailScreen(metadata: item)));
    }
  }
}

/// Title widget with hover underline effect for clickable show titles
class _HoverableTitle extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  final bool showHoverEffect;
  final TextStyle style;
  final int maxLines;

  const _HoverableTitle({
    required this.title,
    required this.onTap,
    required this.showHoverEffect,
    required this.style,
    this.maxLines = 1,
  });

  @override
  State<_HoverableTitle> createState() => _HoverableTitleState();
}

class _HoverableTitleState extends State<_HoverableTitle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.title,
          maxLines: widget.maxLines,
          overflow: TextOverflow.ellipsis,
          style: widget.style.copyWith(
            decoration: (widget.showHoverEffect && _isHovered) ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader widget with subtle opacity pulse animation
class SkeletonLoader extends StatefulWidget {
  final Widget? child;
  final BorderRadius? borderRadius;

  const SkeletonLoader({super.key, this.child, this.borderRadius});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Semantics(
          label: "skeleton-loader",
          identifier: "skeleton-loader",
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: _animation.value),
              borderRadius: widget.borderRadius ?? BorderRadius.circular(tokens(context).radiusSm),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
