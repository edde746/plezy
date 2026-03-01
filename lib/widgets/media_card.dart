import 'dart:ui';

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

class MediaCard extends StatefulWidget {
  final dynamic item; // Can be PlexMetadata or PlexPlaylist
  final double? width;
  final double? height;
  final void Function(String ratingKey)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final VoidCallback? onListRefresh; // Callback to refresh the entire parent list
  final bool forceGridMode;
  final bool forceListMode;
  final bool isInContinueWatching;
  final String? collectionId; // The collection ID if displaying within a collection
  final bool isOffline; // True for downloaded content without server access
  final bool mixedHubContext; // True when in a hub with mixed content (movies + episodes)
  final bool showServerName; // Show server name in list view (multi-server)

  const MediaCard({
    super.key,
    required this.item,
    this.width,
    this.height,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.onListRefresh,
    this.forceGridMode = false,
    this.forceListMode = false,
    this.isInContinueWatching = false,
    this.collectionId,
    this.isOffline = false,
    this.mixedHubContext = false,
    this.showServerName = false,
  });

  @override
  State<MediaCard> createState() => MediaCardState();
}

class MediaCardState extends State<MediaCard> {
  final _contextMenuKey = GlobalKey<MediaContextMenuState>();
  Offset? _tapPosition;

  void _storeTapPosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  void _showContextMenu() {
    _contextMenuKey.currentState?.showContextMenu(context, position: _tapPosition);
  }

  /// Public method to trigger tap action (for keyboard/gamepad SELECT)
  void handleTap() {
    _handleTap(context);
  }

  /// Public method to show context menu (for keyboard/gamepad context menu key)
  void showContextMenu() {
    _contextMenuKey.currentState?.showContextMenu(context);
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
    final hasActiveProgress =
        item.viewOffset != null && item.duration != null && item.viewOffset! > 0 && item.viewOffset! < item.duration!;

    if (hasActiveProgress) {
      final percent = ((item.viewOffset! / item.duration!) * 100).round();
      baseLabel = '$baseLabel, ${t.accessibility.mediaCardPartiallyWatched(percent: percent)}';
    } else if (item.isWatched) {
      baseLabel = '$baseLabel, ${t.accessibility.mediaCardWatched}';
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
    final globalKey = metadata.globalKey;

    // Get artwork reference and resolve to local path using hash (includes serverId)
    final artwork = downloadProvider.getArtworkPaths(globalKey);
    return artwork?.getLocalPath(DownloadStorageService.instance, metadata.serverId!);
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final viewMode = widget.forceListMode
        ? ViewMode.list
        : widget.forceGridMode
            ? ViewMode.grid
            : settingsProvider.viewMode;

    final semanticLabel = _buildSemanticLabel();
    final localPosterPath = _getLocalPosterPath(context);

    final cardWidget = viewMode == ViewMode.grid
        ? _buildGridCard(context, semanticLabel, localPosterPath)
        : _MediaCardList(
            item: widget.item,
            semanticLabel: semanticLabel,
            onTap: () => _handleTap(context),
            onTapDown: _storeTapPosition,
            onLongPress: _showContextMenu,
            onSecondaryTapDown: _storeTapPosition,
            onSecondaryTap: _showContextMenu,
            density: settingsProvider.libraryDensity,
            isOffline: widget.isOffline,
            localPosterPath: localPosterPath,
            showServerName: widget.showServerName,
          );

    // MediaContextMenu as a non-widget helper — only wrap with its key for
    // programmatic context menu access; gesture callbacks are on InkWell directly.
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

  /// Grid layout — inlined from former _MediaCardGrid, _PosterOverlay, and
  /// flattened Column. Semantics removed (InkWell provides button semantics).
  Widget _buildGridCard(BuildContext context, String semanticLabel, String? localPosterPath) {
    final item = widget.item;
    // Compute actual poster dimensions from card dimensions
    final posterWidth = widget.width != null ? widget.width! - 16 : null; // 8px padding each side
    final posterHeight = widget.height;

    return SizedBox(
      width: widget.width,
      child: InkWell(
        canRequestFocus: false,
        onTap: () => _handleTap(context),
        onTapDown: _storeTapPosition,
        onLongPress: _showContextMenu,
        onSecondaryTapDown: _storeTapPosition,
        onSecondaryTap: _showContextMenu,
        borderRadius: BorderRadius.circular(tokens(context).radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster with overlay
              if (posterHeight != null)
                SizedBox(
                  width: double.infinity,
                  height: posterHeight,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                        child: _buildPosterImage(
                          context,
                          item,
                          isOffline: widget.isOffline,
                          localPosterPath: localPosterPath,
                          mixedHubContext: widget.mixedHubContext,
                          knownWidth: posterWidth,
                          knownHeight: posterHeight,
                        ),
                      ),
                      // Inlined _PosterOverlay
                      if (item is PlexMetadata) _MediaCardHelpers.buildWatchProgress(context, item),
                    ],
                  ),
                )
              else
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                        child: _buildPosterImage(
                          context,
                          item,
                          isOffline: widget.isOffline,
                          localPosterPath: localPosterPath,
                          mixedHubContext: widget.mixedHubContext,
                        ),
                      ),
                      if (item is PlexMetadata) _MediaCardHelpers.buildWatchProgress(context, item),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              // Title (flattened — no inner Column)
              Text(
                item is PlexPlaylist ? item.title : (item as PlexMetadata).displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.1),
              ),
              // Subtitle
              if (item is PlexPlaylist)
                _MediaCardHelpers.buildPlaylistMeta(context, item)
              else if (item is PlexMetadata)
                _MediaCardHelpers.buildMetadataSubtitle(context, item),
            ],
          ),
        ),
      ),
    );
  }
}

/// List layout for media cards
class _MediaCardList extends StatelessWidget {
  final dynamic item; // Can be PlexMetadata or PlexPlaylist
  final String semanticLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final void Function(TapDownDetails)? onTapDown;
  final VoidCallback? onSecondaryTap;
  final void Function(TapDownDetails)? onSecondaryTapDown;
  final LibraryDensity density;
  final bool isOffline;
  final String? localPosterPath;
  final bool showServerName;

  const _MediaCardList({
    required this.item,
    required this.semanticLabel,
    required this.onTap,
    required this.onLongPress,
    this.onTapDown,
    this.onSecondaryTap,
    this.onSecondaryTapDown,
    required this.density,
    this.isOffline = false,
    this.localPosterPath,
    this.showServerName = false,
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

    return InkWell(
      canRequestFocus: false, // Keyboard handled by FocusableMediaCard
      onTap: onTap,
      onTapDown: onTapDown,
      onLongPress: onLongPress,
      onSecondaryTapDown: onSecondaryTapDown,
      onSecondaryTap: onSecondaryTap,
      borderRadius: BorderRadius.circular(tokens(context).radiusSm),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster (responsive size based on density)
            SizedBox(
              width: _posterWidth(context),
              height: _posterHeight(context),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                    child: _buildPosterImage(context, item, isOffline: isOffline, localPosterPath: localPosterPath),
                  ),
                  if (item is PlexMetadata) _MediaCardHelpers.buildWatchProgress(context, item as PlexMetadata),
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
                  // Title
                  Text(
                    item.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: _titleFontSize, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  // Metadata info line (rating, duration, score, studio)
                  if (metadataLine.isNotEmpty) ...[
                    Text(
                      metadataLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens(context).textMuted.withValues(alpha: 0.9),
                        fontSize: _metadataFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  // Subtitle (S#E# or year/parent title)
                  if (subtitle != null) ...[
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens(context).textMuted.withValues(alpha: 0.85),
                        fontSize: _subtitleFontSize,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Summary (hidden when spoiler protection is active)
                  if (!(item is PlexMetadata &&
                          context.watch<SettingsProvider>().hideSpoilers &&
                          (item as PlexMetadata).shouldHideSpoiler) &&
                      item.summary != null) ...[
                    Text(
                      item.summary!,
                      maxLines: _summaryMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens(context).textMuted.withValues(alpha: 0.7),
                        fontSize: _summaryFontSize,
                        height: 1.3,
                      ),
                    ),
                  ],
                  // Server name (multi-server mode)
                  if (showServerName && item is PlexMetadata && (item as PlexMetadata).serverName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AppIcon(
                          Symbols.dns_rounded,
                          fill: 1,
                          size: _metadataFontSize + 2,
                          color: tokens(context).textMuted.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            (item as PlexMetadata).serverName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens(context).textMuted.withValues(alpha: 0.6),
                              fontSize: _metadataFontSize,
                            ),
                          ),
                        ),
                      ],
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
  double? knownWidth,
  double? knownHeight,
}) {
  String? posterUrl;
  IconData fallbackIcon = Symbols.movie_rounded;

  if (item is PlexPlaylist) {
    posterUrl = item.displayImage;
    fallbackIcon = Symbols.playlist_play_rounded;

    return PlexOptimizedImage.playlist(
      client: isOffline ? null : context.getClientWithFallback(item.serverId),
      imagePath: posterUrl,
      width: knownWidth ?? double.infinity,
      height: knownHeight ?? double.infinity,
      fit: BoxFit.cover,
      localFilePath: localPosterPath,
    );
  } else if (item is PlexMetadata) {
    final settingsProvider = context.watch<SettingsProvider>();
    final episodePosterMode = settingsProvider.episodePosterMode;
    final shouldBlur =
        settingsProvider.hideSpoilers &&
        item.shouldHideSpoiler &&
        episodePosterMode == EpisodePosterMode.episodeThumbnail;
    posterUrl = item.posterThumb(mode: episodePosterMode, mixedHubContext: mixedHubContext);

    Widget image;

    // Use thumb image type for 16:9 content (episodes, or movies in mixed hubs)
    if (item.usesWideAspectRatio(episodePosterMode, mixedHubContext: mixedHubContext)) {
      image = PlexOptimizedImage.thumb(
        client: isOffline ? null : context.getClientWithFallback(item.serverId),
        imagePath: posterUrl,
        width: knownWidth ?? double.infinity,
        height: knownHeight ?? double.infinity,
        fit: BoxFit.cover,
        localFilePath: localPosterPath,
      );
    } else {
      image = PlexOptimizedImage.poster(
        client: isOffline ? null : context.getClientWithFallback(item.serverId),
        imagePath: posterUrl,
        width: knownWidth ?? double.infinity,
        height: knownHeight ?? double.infinity,
        fit: BoxFit.cover,
        localFilePath: localPosterPath,
      );
    }

    if (shouldBlur) {
      return ClipRect(
        child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: image),
      );
    }
    return image;
  }

  return SkeletonLoader(
    child: Center(child: AppIcon(fallbackIcon, fill: 1, size: 40, color: Colors.white54)),
  );
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
    final showUnwatchedCount = context.watch<SettingsProvider>().showUnwatchedCount;

    final hasActiveProgress =
        metadata.viewOffset != null &&
        metadata.duration != null &&
        metadata.viewOffset! > 0 &&
        metadata.viewOffset! < metadata.duration!;

    return Stack(
      children: [
        // Watched indicator (checkmark)
        if (metadata.isWatched && !hasActiveProgress)
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
        if (showUnwatchedCount &&
            !metadata.isWatched &&
            (metadata.mediaType == PlexMediaType.show || metadata.mediaType == PlexMediaType.season) &&
            (metadata.leafCount != null && metadata.leafCount! > 0 && metadata.viewedLeafCount != null))
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: tokens(context).text,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
              ),
              alignment: Alignment.center,
              child: Text(
                '${metadata.leafCount! - metadata.viewedLeafCount!}',
                style: TextStyle(color: tokens(context).bg, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        // Progress bar for partially watched content (episodes/movies)
        if (hasActiveProgress)
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: _animation.value * 0.15),
              borderRadius: widget.borderRadius ?? BorderRadius.circular(tokens(context).radiusSm),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
