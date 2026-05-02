import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/input_mode_tracker.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../media/media_playlist.dart';
import '../mixins/context_menu_tap_mixin.dart';
import '../providers/download_provider.dart';
import '../services/download_storage_service.dart';
import '../services/settings_service.dart';
import 'settings_builder.dart';
import '../screens/media_detail_screen.dart';
import '../utils/content_utils.dart';
import '../utils/provider_extensions.dart';
import '../utils/formatters.dart';
import '../utils/media_navigation_helper.dart';
import '../utils/snackbar_helper.dart';
import '../theme/mono_tokens.dart';
import '../i18n/strings.g.dart';
import 'media_context_menu.dart';
import 'media_progress_bar.dart';
import 'optimized_media_image.dart';

class MediaCard extends StatefulWidget {
  /// Either a [MediaItem] or a [MediaPlaylist]. Typed as [Object] because Dart
  /// has no nominal union type — runtime `is` checks select the variant.
  final Object item;
  final double? width;
  final double? height;
  final void Function(String itemId)? onRefresh;
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

class MediaCardState extends State<MediaCard> with ContextMenuTapMixin<MediaCard> {
  /// Public method to trigger tap action (for keyboard/gamepad SELECT)
  void handleTap() {
    _handleTap(context);
  }

  String _buildSemanticLabel() {
    final item = widget.item;

    // Playlists don't expose kind, so build a simple localized label and exit early
    if (item is MediaPlaylist) {
      final count = item.leafCount;
      final countText = count != null ? ', ${t.playlists.itemCount(count: count)}' : '';
      return '${item.displayTitle}, ${t.playlists.playlist}$countText';
    }

    if (item is! MediaItem) {
      return '$item';
    }

    String baseLabel;
    switch (item.kind) {
      case MediaKind.episode:
        final episodeInfo = item.parentIndex != null && item.index != null ? 'S${item.parentIndex} E${item.index}' : '';
        baseLabel = t.accessibility.mediaCardEpisode(title: item.displayTitle, episodeInfo: episodeInfo);
      case MediaKind.season:
        final seasonInfo = item.parentIndex != null ? 'Season ${item.parentIndex}' : '';
        baseLabel = t.accessibility.mediaCardSeason(title: item.displayTitle, seasonInfo: seasonInfo);
      case MediaKind.movie:
        baseLabel = t.accessibility.mediaCardMovie(title: item.displayTitle);
      default:
        baseLabel = t.accessibility.mediaCardShow(title: item.displayTitle);
    }

    // Add watched status
    final hasActiveProgress =
        item.viewOffsetMs != null &&
        item.durationMs != null &&
        item.viewOffsetMs! > 0 &&
        item.viewOffsetMs! < item.durationMs!;

    if (hasActiveProgress) {
      final percent = ((item.viewOffsetMs! / item.durationMs!) * 100).round();
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
    if (contextMenuKey.currentState?.isContextMenuOpen == true) {
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
      case MediaNavigationResult.librarySelected:
        // Item refresh already handled by onRefresh callback in helper
        break;
    }
  }

  /// Get the local poster path for offline mode
  String? _getLocalPosterPath(BuildContext context) {
    if (!widget.isOffline) return null;
    if (widget.item is! MediaItem) return null;

    final item = widget.item as MediaItem;
    if (item.serverId == null) return null;

    final downloadProvider = context.read<DownloadProvider>();
    final globalKey = item.globalKey;

    // Get artwork reference and resolve to local path using hash (includes serverId)
    final artwork = downloadProvider.getArtworkPaths(globalKey);
    return artwork?.getLocalPath(DownloadStorageService.instance, item.serverId!);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsBuilder(
      prefs: const [
        SettingsService.viewMode,
        SettingsService.libraryDensity,
        SettingsService.episodePosterMode,
        SettingsService.showEpisodeNumberOnCards,
        SettingsService.hideSpoilers,
        SettingsService.showUnwatchedCount,
      ],
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context) {
    final ViewMode viewMode;
    if (widget.forceListMode) {
      viewMode = ViewMode.list;
    } else if (widget.forceGridMode) {
      viewMode = ViewMode.grid;
    } else {
      viewMode = SettingsService.instanceOrNull!.read(SettingsService.viewMode);
    }

    final semanticLabel = _buildSemanticLabel();
    final localPosterPath = _getLocalPosterPath(context);

    final cardWidget = viewMode == ViewMode.grid
        ? _buildGridCard(context, semanticLabel, localPosterPath)
        : _MediaCardList(
            item: widget.item,
            semanticLabel: semanticLabel,
            onTap: () => _handleTap(context),
            onTapDown: storeTapPosition,
            onLongPress: showContextMenuFromTap,
            onSecondaryTapDown: storeTapPosition,
            onSecondaryTap: showContextMenuFromTap,
            density: SettingsService.instanceOrNull!.read(SettingsService.libraryDensity),
            isOffline: widget.isOffline,
            localPosterPath: localPosterPath,
            showServerName: widget.showServerName,
          );

    // MediaContextMenu as a non-widget helper — only wrap with its key for
    // programmatic context menu access; gesture callbacks are on InkWell directly.
    return MediaContextMenu(
      key: contextMenuKey,
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
    final posterWidth = widget.width != null ? widget.width! - 6 : null; // 3px padding each side
    final posterHeight = widget.height;

    return SizedBox(
      width: widget.width,
      child: InkWell(
        canRequestFocus: false,
        onTap: () => _handleTap(context),
        onTapDown: storeTapPosition,
        onLongPress: showContextMenuFromTap,
        onSecondaryTapDown: storeTapPosition,
        onSecondaryTap: showContextMenuFromTap,
        borderRadius: BorderRadius.circular(tokens(context).radiusSm),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 3, 3, 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      if (item is MediaItem) _MediaCardHelpers.buildWatchProgress(context, item),
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
                      if (item is MediaItem) _MediaCardHelpers.buildWatchProgress(context, item),
                    ],
                  ),
                ),
              const SizedBox(height: 2),
              // Title (flattened — no inner Column)
              if (item is MediaItem && _hasClickableTitle(item))
                _ClickableText(
                  text: item.displayTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.1),
                  onTap: () => _navigateToDetail(context, item, isOffline: widget.isOffline),
                )
              else
                Text(
                  item is MediaPlaylist ? item.title : (item as MediaItem).displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.1),
                ),
              // Subtitle
              if (item is MediaPlaylist)
                _MediaCardHelpers.buildPlaylistMeta(context, item)
              else if (item is MediaItem)
                _MediaCardHelpers.buildMetadataSubtitle(context, item, isOffline: widget.isOffline),
            ],
          ),
        ),
      ),
    );
  }
}

/// List layout for media cards
class _MediaCardList extends StatelessWidget {
  /// Either a [MediaItem] or a [MediaPlaylist].
  final Object item;
  final String semanticLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final void Function(TapDownDetails)? onTapDown;
  final VoidCallback? onSecondaryTap;
  final void Function(TapDownDetails)? onSecondaryTapDown;
  final int density;
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
    return 70 + LibraryDensity.factor(density) * 50; // 70–120
  }

  double _posterWidth(BuildContext context) {
    final base = _basePosterWidth();
    // For episodes with thumbnail mode, use wider width to maintain reasonable thumbnail size
    if (item is MediaItem) {
      final mode = SettingsService.instanceOrNull!.read(SettingsService.episodePosterMode);
      if ((item as MediaItem).usesWideAspectRatio(mode)) {
        return base * 1.6; // Wider for 16:9 thumbnails
      }
    }
    return base;
  }

  double _posterHeight(BuildContext context) {
    final base = _basePosterWidth();
    // For episodes with thumbnail mode, use 16:9 aspect ratio
    if (item is MediaItem) {
      final mode = SettingsService.instanceOrNull!.read(SettingsService.episodePosterMode);
      if ((item as MediaItem).usesWideAspectRatio(mode)) {
        // 16:9: height = width * 9/16 = base * 1.6 * 9/16 = base * 0.9
        return base * 0.9;
      }
    }
    return base * 1.5; // Default 2:3 aspect ratio
  }

  double get _titleFontSize => 13 + LibraryDensity.factor(density) * 3; // 13–16

  double get _metadataFontSize => 10 + LibraryDensity.factor(density) * 3; // 10–13

  double get _subtitleFontSize => 11 + LibraryDensity.factor(density) * 3; // 11–14

  double get _summaryFontSize {
    // Summary uses the same sizing as metadata text
    return _metadataFontSize;
  }

  int get _summaryMaxLines => density <= 2 ? 2 : density; // 2, 2, 3, 4, 5

  String _buildMetadataLine() {
    final parts = <String>[];

    if (item is MediaPlaylist) {
      final playlist = item as MediaPlaylist;
      // Add item count
      if (playlist.leafCount != null && playlist.leafCount! > 0) {
        parts.add(t.playlists.itemCount(count: playlist.leafCount!));
      }

      // Add duration
      if (playlist.durationMs != null) {
        parts.add(formatDurationTextual(playlist.durationMs!));
      }

      // Add smart playlist badge
      if (playlist.smart) {
        parts.add(t.playlists.smartPlaylist);
      }
    } else if (item is MediaItem) {
      final mi = item as MediaItem;

      // For collections, show item count
      if (mi.kind == MediaKind.collection) {
        final count = mi.childCount ?? mi.leafCount;
        if (count != null && count > 0) {
          parts.add(t.playlists.itemCount(count: count));
        }
      } else {
        // For other media types, show standard metadata
        // Add content rating
        if (mi.contentRating != null && mi.contentRating!.isNotEmpty) {
          final rating = formatContentRating(mi.contentRating);
          if (rating.isNotEmpty) {
            parts.add(rating);
          }
        }

        // Add year
        if (mi.year != null) {
          parts.add('${mi.year}');
        }

        // Add edition title (Plex-only field; null on other backends)
        if (mi.editionTitle case final editionTitle?) {
          parts.add(editionTitle);
        }

        // Add duration
        if (mi.durationMs != null) {
          parts.add(formatDurationTextual(mi.durationMs!));
        }

        // Add user rating
        if (mi.rating != null) {
          parts.add('${mi.rating!.toStringAsFixed(1)}★');
        }

        // Add studio
        if (mi.studio != null && mi.studio!.isNotEmpty) {
          parts.add(mi.studio!);
        }
      }
    }

    return parts.join(' • ');
  }

  String? _buildSubtitleText(BuildContext context) {
    if (item is MediaPlaylist) {
      // Playlists don't have subtitles
      return null;
    } else if (item is MediaItem) {
      final mi = item as MediaItem;

      // For TV episodes, show S# (optionally with E#)
      if (mi.parentIndex != null && mi.index != null) {
        final showEp = SettingsService.instanceOrNull!.read(SettingsService.showEpisodeNumberOnCards);
        return showEp ? 'S${mi.parentIndex} E${mi.index}' : 'S${mi.parentIndex}';
      }

      // Otherwise use existing subtitle logic
      if (mi.displaySubtitle != null) {
        return mi.displaySubtitle;
      } else if (mi.parentTitle != null) {
        return mi.parentTitle;
      }
    }

    // Year is now shown in metadata line, so don't show it here
    return null;
  }

  String? _summary() {
    final it = item;
    if (it is MediaItem) return it.summary;
    if (it is MediaPlaylist) return it.summary;
    return null;
  }

  String _displayTitle() {
    final it = item;
    if (it is MediaItem) return it.displayTitle;
    if (it is MediaPlaylist) return it.displayTitle;
    return '';
  }

  Widget _buildEpisodeSubtitle(BuildContext context, MediaItem mi) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: tokens(context).textMuted.withValues(alpha: 0.85),
      fontSize: _subtitleFontSize,
    );
    final episodeTitle = mi.displaySubtitle ?? mi.displayTitle;
    final showEp = SettingsService.instanceOrNull!.read(SettingsService.showEpisodeNumberOnCards);
    final episodeNum = (showEp && mi.index != null) ? ' E${mi.index}' : '';
    return Row(
      children: [
        _ClickableText(
          text: 'S${mi.parentIndex}',
          style: style,
          onTap: () => _navigateToSeason(context, mi, isOffline: isOffline),
        ),
        Text('$episodeNum · ', style: style),
        Expanded(
          child: Text(episodeTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final metadataLine = _buildMetadataLine();
    final subtitle = _buildSubtitleText(context);

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
                  if (item is MediaItem) _MediaCardHelpers.buildWatchProgress(context, item as MediaItem),
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
                  if (item is MediaItem && _hasClickableTitle(item as MediaItem))
                    _ClickableText(
                      text: (item as MediaItem).displayTitle,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: _titleFontSize, height: 1.2),
                      onTap: () => _navigateToDetail(context, item as MediaItem, isOffline: isOffline),
                    )
                  else
                    Text(
                      _displayTitle(),
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
                  // Subtitle (S# · Episode Title, or year/parent title)
                  if (item is MediaItem &&
                      (item as MediaItem).isEpisode &&
                      (item as MediaItem).parentIndex != null &&
                      (item as MediaItem).parentId != null) ...[
                    _buildEpisodeSubtitle(context, item as MediaItem),
                    const SizedBox(height: 4),
                  ] else if (subtitle != null) ...[
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
                  if (!(item is MediaItem &&
                          SettingsService.instanceOrNull!.read(SettingsService.hideSpoilers) &&
                          (item as MediaItem).shouldHideSpoiler) &&
                      _summary() != null) ...[
                    Text(
                      _summary()!,
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
                  if (showServerName && item is MediaItem && (item as MediaItem).serverName != null) ...[
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
                            (item as MediaItem).serverName!,
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
  Object item, {
  bool isOffline = false,
  String? localPosterPath,
  bool mixedHubContext = false,
  double? knownWidth,
  double? knownHeight,
}) {
  String? posterUrl;
  IconData fallbackIcon = Symbols.movie_rounded;

  if (item is MediaPlaylist) {
    posterUrl = item.displayImagePath;
    fallbackIcon = Symbols.playlist_play_rounded;

    return OptimizedMediaImage.playlist(
      client: isOffline ? null : context.tryGetMediaClientWithFallback(item.serverId),
      imagePath: posterUrl,
      width: knownWidth ?? double.infinity,
      height: knownHeight ?? double.infinity,
      fit: BoxFit.cover,
      localFilePath: localPosterPath,
    );
  } else if (item is MediaItem) {
    final episodePosterMode = SettingsService.instanceOrNull!.read(SettingsService.episodePosterMode);
    final hideSpoilers = SettingsService.instanceOrNull!.read(SettingsService.hideSpoilers);
    final shouldBlur =
        hideSpoilers && item.shouldHideSpoiler && episodePosterMode == EpisodePosterMode.episodeThumbnail;
    posterUrl = item.posterThumb(mode: episodePosterMode, mixedHubContext: mixedHubContext);

    Widget image;

    // Use thumb image type for 16:9 content (episodes, or movies in mixed hubs)
    if (item.usesWideAspectRatio(episodePosterMode, mixedHubContext: mixedHubContext)) {
      image = OptimizedMediaImage.thumb(
        client: isOffline ? null : context.tryGetMediaClientWithFallback(item.serverId),
        imagePath: posterUrl,
        width: knownWidth ?? double.infinity,
        height: knownHeight ?? double.infinity,
        fit: BoxFit.cover,
        localFilePath: localPosterPath,
      );
    } else {
      image = OptimizedMediaImage.poster(
        client: isOffline ? null : context.tryGetMediaClientWithFallback(item.serverId),
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
  static Widget buildPlaylistMeta(BuildContext context, MediaPlaylist playlist) {
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
  static Widget buildMetadataSubtitle(BuildContext context, MediaItem mi, {bool isOffline = false}) {
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 11, height: 1.1);

    // For collections, show item count
    if (mi.kind == MediaKind.collection) {
      final count = mi.childCount ?? mi.leafCount;
      if (count != null && count > 0) {
        return Text(
          t.playlists.itemCount(count: count),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: subtitleStyle,
        );
      }
    }

    // For episodes, show "S# · Episode Title" with clickable season link
    if (mi.isEpisode && mi.parentIndex != null) {
      final episodeTitle = mi.displaySubtitle ?? mi.displayTitle;
      final showEp = SettingsService.instanceOrNull!.read(SettingsService.showEpisodeNumberOnCards);
      final episodeSuffix = (showEp && mi.index != null) ? ' E${mi.index}' : '';
      if (mi.parentId != null) {
        return Row(
          children: [
            _ClickableText(
              text: 'S${mi.parentIndex}',
              style: subtitleStyle,
              onTap: () => _navigateToSeason(context, mi, isOffline: isOffline),
            ),
            Text('$episodeSuffix · ', style: subtitleStyle),
            Expanded(
              child: Text(episodeTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: subtitleStyle),
            ),
          ],
        );
      }
      return Text(
        'S${mi.parentIndex}$episodeSuffix · $episodeTitle',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: subtitleStyle,
      );
    }

    // For other media types, show subtitle/parent/year
    if (mi.displaySubtitle != null) {
      return Text(mi.displaySubtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: subtitleStyle);
    } else if (mi.parentTitle != null) {
      return Text(mi.parentTitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: subtitleStyle);
    } else if (mi.year != null) {
      final edition = mi.editionTitle;
      return Text(
        edition != null ? '${mi.year} · $edition' : '${mi.year}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: subtitleStyle,
      );
    }

    return const SizedBox.shrink();
  }

  /// Builds watch progress overlay (checkmark for watched, progress bar for in-progress)
  static Widget buildWatchProgress(BuildContext context, MediaItem mi) {
    final showUnwatchedCount = SettingsService.instanceOrNull!.read(SettingsService.showUnwatchedCount);

    final hasActiveProgress =
        mi.viewOffsetMs != null && mi.durationMs != null && mi.viewOffsetMs! > 0 && mi.viewOffsetMs! < mi.durationMs!;

    return Stack(
      children: [
        // Watched indicator (checkmark)
        if (mi.isWatched && !hasActiveProgress)
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
            !mi.isWatched &&
            (mi.kind == MediaKind.show || mi.kind == MediaKind.season) &&
            (mi.leafCount != null && mi.leafCount! > 0 && mi.viewedLeafCount != null))
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
                '${mi.leafCount! - mi.viewedLeafCount!}',
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
              child: MediaProgressBar(viewOffset: mi.viewOffsetMs!, duration: mi.durationMs!),
            ),
          ),
        // Progress bar for seasons (viewedLeafCount / leafCount)
        if (mi.isSeason && mi.isPartiallyWatched)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
              child: LinearProgressIndicator(
                value: mi.viewedLeafCount! / mi.leafCount!,
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

/// Whether this media item has a clickable title that navigates somewhere.
/// Episodes/seasons navigate to their parent show; movies navigate to their detail page.
bool _hasClickableTitle(MediaItem mi) {
  if (mi.isEpisode) return mi.grandparentId != null;
  if (mi.isSeason) return mi.parentId != null;
  if (mi.isMovie) return true;
  return false;
}

/// Navigate to a show with the season tab pre-selected from episode metadata
void _navigateToSeason(BuildContext context, MediaItem episode, {bool isOffline = false}) {
  if (episode.grandparentId != null) {
    // Navigate to the show with the season pre-selected
    final showStub = MediaItem(
      id: episode.grandparentId!,
      backend: episode.backend,
      kind: MediaKind.show,
      title: episode.grandparentTitle ?? episode.displayTitle,
      thumbPath: episode.grandparentThumbPath,
      artPath: episode.grandparentArtPath,
      serverId: episode.serverId,
      serverName: episode.serverName,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MediaDetailScreen(metadata: showStub, isOffline: isOffline, initialSeasonIndex: episode.parentIndex),
      ),
    );
  } else if (episode.parentId != null) {
    // Fallback: navigate to season directly if no grandparent
    final seasonStub = MediaItem(
      id: episode.parentId!,
      backend: episode.backend,
      kind: MediaKind.season,
      title: episode.parentTitle ?? 'Season ${episode.parentIndex ?? ''}',
      index: episode.parentIndex,
      parentId: episode.grandparentId,
      thumbPath: episode.parentThumbPath,
      serverId: episode.serverId,
      serverName: episode.serverName,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaDetailScreen(metadata: seasonStub, isOffline: isOffline),
      ),
    );
  }
}

/// Navigate to the detail screen for a media item.
/// For episodes/seasons: navigates to the parent show with season pre-selected.
/// For movies and other types: navigates to the item's own detail page.
void _navigateToDetail(BuildContext context, MediaItem mi, {bool isOffline = false}) {
  MediaItem target = mi;
  int? initialSeasonIndex;

  if (mi.isEpisode && mi.grandparentId != null) {
    target = MediaItem(
      id: mi.grandparentId!,
      backend: mi.backend,
      kind: MediaKind.show,
      title: mi.grandparentTitle ?? mi.displayTitle,
      thumbPath: mi.grandparentThumbPath,
      artPath: mi.grandparentArtPath,
      serverId: mi.serverId,
      serverName: mi.serverName,
    );
  } else if (mi.isSeason && mi.parentId != null) {
    initialSeasonIndex = mi.index;
    target = MediaItem(
      id: mi.parentId!,
      backend: mi.backend,
      kind: MediaKind.show,
      title: mi.grandparentTitle ?? mi.parentTitle ?? mi.displayTitle,
      thumbPath: mi.grandparentThumbPath ?? mi.parentThumbPath,
      artPath: mi.grandparentArtPath,
      serverId: mi.serverId,
      serverName: mi.serverName,
    );
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MediaDetailScreen(metadata: target, isOffline: isOffline, initialSeasonIndex: initialSeasonIndex),
    ),
  );
}

/// Text widget that shows hover underline + pointer cursor only in pointer mode.
/// In keyboard/dpad mode, renders as plain text with no interaction.
class _ClickableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final VoidCallback onTap;

  const _ClickableText({required this.text, this.style, required this.onTap});

  @override
  State<_ClickableText> createState() => _ClickableTextState();
}

class _ClickableTextState extends State<_ClickableText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isKeyboard = InputModeTracker.isKeyboardMode(context);
    final baseStyle = widget.style ?? const TextStyle();

    if (isKeyboard) {
      return Text(widget.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: baseStyle);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: baseStyle.copyWith(
            decoration: _isHovered ? TextDecoration.underline : null,
            decorationColor: baseStyle.color,
          ),
        ),
      ),
    );
  }
}

/// Static skeleton placeholder with a fixed semi-transparent fill.
class SkeletonLoader extends StatelessWidget {
  final Widget? child;
  final BorderRadius? borderRadius;

  const SkeletonLoader({super.key, this.child, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.075),
        borderRadius: borderRadius ?? BorderRadius.circular(tokens(context).radiusSm),
      ),
      child: child,
    );
  }
}
