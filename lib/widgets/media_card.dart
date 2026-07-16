import 'dart:async';
import 'dart:ui';
import '../media/ids.dart';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/card_focus_scope.dart';
import '../focus/input_mode_tracker.dart';
import '../media/catalog_item_ref.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../media/media_playlist.dart';
import '../mixins/context_menu_tap_mixin.dart';
import '../models/catalog/catalog_item.dart';
import '../providers/download_provider.dart';
import '../providers/watch_state_store.dart';
import '../services/download_storage_service.dart';
import '../services/settings_service.dart';
import 'catalog_context_menu.dart';
import 'settings_builder.dart';
import 'watched_indicator.dart';
import '../utils/content_utils.dart';
import '../utils/media_image_helper.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import '../utils/formatters.dart';
import '../utils/media_navigation_helper.dart';
import '../utils/snackbar_helper.dart';
import '../theme/mono_tokens.dart';
import '../i18n/strings.g.dart';
import 'media_context_menu.dart';
import 'media_card_list_layout.dart';
import 'backend_badge.dart';
import 'optimized_media_image.dart';

const _failedPosterUrlCacheLimit = 512;
final _failedPosterUrls = <String>{};

bool _hasFailedPosterUrl(String? url) => url != null && _failedPosterUrls.contains(url);

void _rememberFailedPosterUrl(String? url) {
  if (url == null || url.isEmpty) return;
  _failedPosterUrls.remove(url);
  _failedPosterUrls.add(url);
  if (_failedPosterUrls.length > _failedPosterUrlCacheLimit) {
    _failedPosterUrls.remove(_failedPosterUrls.first);
  }
}

/// The single announcement used for a media card.
///
/// TV browse rails also use this label for their fixed semantic selection
/// proxy, so the accessible description stays identical when the animated
/// card subtree is excluded from semantics.
String mediaCardSemanticLabel(Object item) {
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
      final seasonInfo = item.title?.isNotEmpty == true
          ? item.title!
          : item.index != null
          ? t.common.seasonNumber(number: item.index!)
          : '';
      baseLabel = t.accessibility.mediaCardSeason(title: item.displayTitle, seasonInfo: seasonInfo);
    case MediaKind.movie:
      baseLabel = t.accessibility.mediaCardMovie(title: item.displayTitle);
    // Music reuses the "${title}, ${info}" composite of mediaCardEpisode
    // (no dedicated music keys yet; adding keys is out of scope here).
    case MediaKind.album:
      baseLabel = t.accessibility.mediaCardEpisode(title: item.displayTitle, episodeInfo: item.albumArtistTitle ?? '');
    case MediaKind.track:
      baseLabel = t.accessibility.mediaCardEpisode(title: item.displayTitle, episodeInfo: item.trackArtistTitle ?? '');
    case MediaKind.artist:
      baseLabel = item.displayTitle;
    default:
      baseLabel = t.accessibility.mediaCardShow(title: item.displayTitle);
  }

  // Play-state on an artist is noise — no watched suffix.
  if (item.kind == MediaKind.artist) return baseLabel;

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

class MediaCard extends StatefulWidget {
  /// Either a [MediaItem] or a [MediaPlaylist]. Typed as [Object] because Dart
  /// has no nominal union type — runtime `is` checks select the variant.
  final Object item;
  final double? width;
  final double? height;
  final void Function(MediaItem source)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final VoidCallback? onListRefresh; // Callback to refresh the entire parent list
  /// Overrides the card's default media navigation for specialized surfaces.
  final VoidCallback? onTap;

  /// Overrides the standard media context menu for every long-press path.
  final VoidCallback? onLongPress;
  final bool forceGridMode;
  final bool forceListMode;
  final bool isInContinueWatching;
  final bool usesContinueWatchingAction;
  final String? collectionId; // The collection ID if displaying within a collection
  final bool isOffline; // True for downloaded content without server access
  final bool mixedHubContext; // True when in a hub with mixed content (movies + episodes)
  final bool showServerName; // Show server name in list view (multi-server)
  final EpisodePosterMode? episodePosterModeOverride;
  final bool fullBleedImage;

  const MediaCard({
    super.key,
    required this.item,
    this.width,
    this.height,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.onListRefresh,
    this.onTap,
    this.onLongPress,
    this.forceGridMode = false,
    this.forceListMode = false,
    this.isInContinueWatching = false,
    bool? usesContinueWatchingAction,
    this.collectionId,
    this.isOffline = false,
    this.mixedHubContext = false,
    this.showServerName = false,
    this.episodePosterModeOverride,
    this.fullBleedImage = false,
  }) : usesContinueWatchingAction = usesContinueWatchingAction ?? isInContinueWatching;

  @override
  State<MediaCard> createState() => MediaCardState();
}

class MediaCardState extends State<MediaCard> with ContextMenuTapMixin<MediaCard> {
  /// Public method to trigger tap action (for keyboard/gamepad SELECT)
  void handleTap() {
    _handleTap(context, _effectiveItemForAction(context));
  }

  CatalogItem? get _catalogItem {
    final item = widget.item;
    return item is MediaItem && item.isCatalogItem ? item.catalogItem : null;
  }

  // Catalog stand-ins get the catalog menu at the same seams (long-press,
  // right-click, TV context-menu key) instead of the server-backed
  // MediaContextMenu, which is not in their tree.
  @override
  void showContextMenuFromTap() {
    if (widget.onLongPress case final onLongPress?) {
      onLongPress();
      return;
    }
    final catalogItem = _catalogItem;
    if (catalogItem != null) {
      unawaited(showCatalogItemMenu(context, catalogItem, position: lastTapPosition));
      return;
    }
    super.showContextMenuFromTap();
  }

  @override
  void showContextMenu() {
    if (widget.onLongPress case final onLongPress?) {
      onLongPress();
      return;
    }
    final catalogItem = _catalogItem;
    if (catalogItem != null) {
      unawaited(showCatalogItemMenu(context, catalogItem));
      return;
    }
    super.showContextMenu();
  }

  Object _effectiveItem(BuildContext context) {
    final item = widget.item;
    return item is MediaItem ? context.withFreshWatchState(item) : item;
  }

  Object _effectiveItemForAction(BuildContext context) {
    final item = widget.item;
    return item is MediaItem ? context.readFreshWatchState(item) : item;
  }

  void _handleTap(BuildContext context, Object item) async {
    // Ignore taps while context menu is open to avoid double-activating
    if (contextMenuKey.currentState?.isContextMenuOpen == true) {
      return;
    }
    if (widget.onTap case final onTap?) {
      onTap();
      return;
    }

    final result = await navigateToMediaItem(
      context,
      item,
      onRefresh: widget.onRefresh,
      isOffline: widget.isOffline,
      playDirectly: widget.usesContinueWatchingAction,
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
  String? _getLocalPosterPath(BuildContext context, Object item) {
    if (!widget.isOffline) return null;
    if (item is! MediaItem) return null;

    if (item.serverId == null) return null;

    final downloadProvider = context.read<DownloadProvider>();
    final globalKey = item.globalKey;

    // Get artwork reference and resolve to local path using hash (includes serverId)
    final artwork = downloadProvider.getArtworkPaths(globalKey);
    return artwork?.getLocalPath(DownloadStorageService.instance, ServerId(item.serverId!));
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
    final item = _effectiveItem(context);
    final ViewMode viewMode;
    if (widget.forceListMode) {
      viewMode = ViewMode.list;
    } else if (widget.forceGridMode) {
      viewMode = ViewMode.grid;
    } else {
      viewMode = SettingsService.instance.read(SettingsService.viewMode);
    }

    final semanticLabel = mediaCardSemanticLabel(item);
    final localPosterPath = _getLocalPosterPath(context, item);

    final cardWidget = viewMode == ViewMode.grid
        ? _buildGridCard(context, item, localPosterPath)
        : _MediaCardList(
            item: item,
            semanticLabel: semanticLabel,
            onTap: () => _handleTap(context, item),
            onTapDown: storeTapPosition,
            onLongPress: showContextMenuFromTap,
            onSecondaryTapDown: storeTapPosition,
            onSecondaryTap: showContextMenuFromTap,
            density: SettingsService.instance.read(SettingsService.libraryDensity),
            isOffline: widget.isOffline,
            localPosterPath: localPosterPath,
            showServerName: widget.showServerName,
            episodePosterModeOverride: widget.episodePosterModeOverride,
            enableDetailLinks: widget.onTap == null,
          );

    // Catalog stand-ins (Explore tab) have no server-backed actions — every
    // entry in the context menu would break on serverId == null. Long-press
    // no-ops on them; taps route through the catalog branch in
    // navigateToMediaItem.
    if ((item is MediaItem && item.isCatalogItem) || widget.onLongPress != null) return cardWidget;

    // MediaContextMenu as a non-widget helper — only wrap with its key for
    // programmatic context menu access; gesture callbacks are on InkWell directly.
    return MediaContextMenu(
      key: contextMenuKey,
      item: item,
      onRefresh: widget.onRefresh,
      onRemoveFromContinueWatching: widget.onRemoveFromContinueWatching,
      onListRefresh: widget.onListRefresh,
      onTap: () => _handleTap(context, item),
      isInContinueWatching: widget.isInContinueWatching,
      collectionId: widget.collectionId,
      child: cardWidget,
    );
  }

  /// Grid layout — inlined from former _MediaCardGrid, _PosterOverlay, and
  /// flattened Column. Semantics removed (InkWell provides button semantics).
  ///
  /// MergeSemantics collapses the card (texts, progress, button) into ONE
  /// semantics node. Browse rails/grids show dozens of cards and the
  /// platform-driven semantics pass runs every frame on TV boxes with an
  /// accessibility service active — node count is the cost driver. The card
  /// has a single action (tap; long-press menu), so merging is safe and gives
  /// screen readers one coherent announcement per card.
  Widget _buildGridCard(BuildContext context, Object item, String? localPosterPath) {
    if (widget.fullBleedImage) {
      return MergeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = widget.width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : null);
            final cardHeight = widget.height ?? (constraints.hasBoundedHeight ? constraints.maxHeight : null);
            if (cardHeight == null) return _buildStandardGridCard(context, item, localPosterPath);
            return _buildFullBleedGridCard(context, item, localPosterPath, width: cardWidth, height: cardHeight);
          },
        ),
      );
    }

    return MergeSemantics(child: _buildStandardGridCard(context, item, localPosterPath));
  }

  Widget _buildFullBleedGridCard(
    BuildContext context,
    Object item,
    String? localPosterPath, {
    required double? width,
    required double height,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: _CardTapRegion(
        onTap: () => _handleTap(context, item),
        onTapDown: storeTapPosition,
        onLongPress: showContextMenuFromTap,
        onSecondaryTapDown: storeTapPosition,
        onSecondaryTap: showContextMenuFromTap,
        borderRadius: BorderRadius.circular(tokens(context).radiusSm),
        child: CardFocusBorder(
          borderRadius: _posterFocusRadius(context, item),
          child: _clipPosterImage(
            context,
            item,
            Stack(
              fit: StackFit.expand,
              children: [
                _buildPosterImage(
                  context,
                  item,
                  isOffline: widget.isOffline,
                  localPosterPath: localPosterPath,
                  mixedHubContext: widget.mixedHubContext,
                  episodePosterModeOverride: widget.episodePosterModeOverride,
                  knownWidth: width,
                  knownHeight: height,
                ),
                if (item is MediaItem && _showsWatchedIndicator(item)) WatchedIndicator(item: item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardGridCard(BuildContext context, Object item, String? localPosterPath) {
    // Compute actual poster dimensions from card dimensions
    final posterWidth = widget.width != null ? widget.width! - 6 : null;
    final posterHeight = widget.height;

    // The focus border hugs the poster (captions stay outside it), matching
    // the full-bleed card treatment.
    final poster = CardFocusBorder(
      borderRadius: _posterFocusRadius(context, item),
      child: Stack(
        children: [
          _clipPosterImage(
            context,
            item,
            _buildPosterImage(
              context,
              item,
              isOffline: widget.isOffline,
              localPosterPath: localPosterPath,
              mixedHubContext: widget.mixedHubContext,
              episodePosterModeOverride: widget.episodePosterModeOverride,
              knownWidth: posterHeight != null ? posterWidth : null,
              knownHeight: posterHeight,
            ),
          ),
          if (item is MediaItem && _showsWatchedIndicator(item)) WatchedIndicator(item: item),
        ],
      ),
    );

    return SizedBox(
      width: widget.width,
      child: _CardTapRegion(
        onTap: () => _handleTap(context, item),
        onTapDown: storeTapPosition,
        onLongPress: showContextMenuFromTap,
        onSecondaryTapDown: storeTapPosition,
        onSecondaryTap: showContextMenuFromTap,
        borderRadius: BorderRadius.circular(tokens(context).radiusSm),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 3, 3, 1),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              // Poster with overlay
              if (posterHeight != null)
                SizedBox(width: double.infinity, height: posterHeight, child: poster)
              else
                Expanded(child: poster),
              const SizedBox(height: 2),
              // Title (flattened — no inner Column)
              if (widget.onTap == null && item is MediaItem && _hasClickableTitle(item))
                _ClickableText(
                  text: item.displayTitle,
                  style: const TextStyle(fontWeight: .w600, fontSize: 13, height: 1.1),
                  onTap: () => _navigateToFocusedDetail(context, item, isOffline: widget.isOffline),
                )
              else
                Text(
                  item is MediaPlaylist ? item.title : (item as MediaItem).displayTitle,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: const TextStyle(fontWeight: .w600, fontSize: 13, height: 1.1),
                ),
              // Subtitle
              if (item is MediaPlaylist)
                _MediaCardHelpers.buildPlaylistMeta(context, item)
              else if (item is MediaItem)
                _MediaCardHelpers.buildMetadataSubtitle(
                  context,
                  item,
                  isOffline: widget.isOffline,
                  enableDetailLinks: widget.onTap == null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  final EpisodePosterMode? episodePosterModeOverride;
  final bool enableDetailLinks;

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
    this.episodePosterModeOverride,
    required this.enableDetailLinks,
  });

  CardShape _cardShape() {
    if (item is! MediaItem) return CardShape.poster;
    final EpisodePosterMode mode =
        episodePosterModeOverride ?? SettingsService.instance.read(SettingsService.episodePosterMode);
    return (item as MediaItem).cardShape(mode);
  }

  double _posterWidth() => MediaCardListLayout.posterWidth(density: density, shape: _cardShape());

  double _posterHeight() => MediaCardListLayout.posterHeight(density: density, shape: _cardShape());

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
      if (playlist.leafCount != null && playlist.leafCount! > 0) {
        parts.add(t.playlists.itemCount(count: playlist.leafCount!));
      }

      if (playlist.durationMs != null) {
        parts.add(formatDurationTextual(playlist.durationMs!));
      }

      if (playlist.smart) {
        parts.add(t.playlists.smartPlaylist);
      }
    } else if (item is MediaItem) {
      final mi = item as MediaItem;

      if (mi.kind == MediaKind.collection) {
        final count = mi.childCount ?? mi.leafCount;
        if (count != null && count > 0) {
          parts.add(t.playlists.itemCount(count: count));
        }
      } else {
        if (mi.contentRating != null && mi.contentRating!.isNotEmpty) {
          final rating = formatContentRating(mi.contentRating);
          if (rating.isNotEmpty) {
            parts.add(rating);
          }
        }

        if (mi.year != null) {
          parts.add('${mi.year}');
        }

        if (mi.editionTitle case final editionTitle?) {
          parts.add(editionTitle);
        }

        if (mi.durationMs != null) {
          parts.add(formatDurationTextual(mi.durationMs!));
        }

        if (mi.rating != null) {
          parts.add('${formatRating(mi.rating!)}★');
        }

        if (mi.studio != null && mi.studio!.isNotEmpty) {
          parts.add(mi.studio!);
        }
      }
    }

    return parts.join(' • ');
  }

  String? _buildSubtitleText() {
    if (item is MediaPlaylist) {
      return null;
    } else if (item is MediaItem) {
      final mi = item as MediaItem;

      // Music: a track's parentIndex/index are disc/track numbers, not S#E#.
      if (mi.kind == MediaKind.album) return mi.albumArtistTitle;
      if (mi.kind == MediaKind.track) return mi.trackArtistTitle;

      if (mi.parentIndex != null && mi.index != null) {
        final showEp = SettingsService.instance.read(SettingsService.showEpisodeNumberOnCards);
        return showEp ? 'S${mi.parentIndex} E${mi.index}' : 'S${mi.parentIndex}';
      }

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
    final showEp = SettingsService.instance.read(SettingsService.showEpisodeNumberOnCards);
    final episodeNum = (showEp && mi.index != null) ? ' E${mi.index}' : '';
    return Row(
      children: [
        if (enableDetailLinks)
          _ClickableText(
            text: 'S${mi.parentIndex}',
            style: style,
            onTap: () => _navigateToFocusedDetail(context, mi, isOffline: isOffline),
          )
        else
          Text('S${mi.parentIndex}', style: style),
        Text('$episodeNum · ', style: style),
        Expanded(
          child: Text(episodeTitle, maxLines: 1, overflow: .ellipsis, style: style),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final metadataLine = _buildMetadataLine();
    final subtitle = _buildSubtitleText();

    // List rows keep the whole-row border; inside stroke so adjacent rows
    // don't overlap.
    return CardFocusBorder(
      borderRadius: tokens(context).radiusSm,
      strokeAlign: BorderSide.strokeAlignInside,
      child: _CardTapRegion(
        onTap: onTap,
        onTapDown: onTapDown,
        onLongPress: onLongPress,
        onSecondaryTapDown: onSecondaryTapDown,
        onSecondaryTap: onSecondaryTap,
        borderRadius: BorderRadius.circular(tokens(context).radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: .start,
            children: [
              SizedBox(
                width: _posterWidth(),
                height: _posterHeight(),
                child: Stack(
                  children: [
                    _clipPosterImage(
                      context,
                      item,
                      _buildPosterImage(
                        context,
                        item,
                        isOffline: isOffline,
                        localPosterPath: localPosterPath,
                        episodePosterModeOverride: episodePosterModeOverride,
                      ),
                    ),
                    if (item is MediaItem && _showsWatchedIndicator(item as MediaItem))
                      WatchedIndicator(item: item as MediaItem),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  mainAxisAlignment: .start,
                  children: [
                    if (enableDetailLinks && item is MediaItem && _hasClickableTitle(item as MediaItem))
                      _ClickableText(
                        text: (item as MediaItem).displayTitle,
                        style: TextStyle(fontWeight: .w600, fontSize: _titleFontSize, height: 1.2),
                        onTap: () => _navigateToFocusedDetail(context, item as MediaItem, isOffline: isOffline),
                      )
                    else
                      Text(
                        _displayTitle(),
                        maxLines: 2,
                        overflow: .ellipsis,
                        style: TextStyle(fontWeight: .w600, fontSize: _titleFontSize, height: 1.2),
                      ),
                    const SizedBox(height: 4),
                    if (metadataLine.isNotEmpty) ...[
                      Text(
                        metadataLine,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens(context).textMuted.withValues(alpha: 0.9),
                          fontSize: _metadataFontSize,
                          fontWeight: .w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
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
                        overflow: .ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens(context).textMuted.withValues(alpha: 0.85),
                          fontSize: _subtitleFontSize,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (!(item is MediaItem &&
                            SettingsService.instance.read(SettingsService.hideSpoilers) &&
                            (item as MediaItem).shouldHideSpoiler) &&
                        _summary() != null) ...[
                      Text(
                        _summary()!,
                        maxLines: _summaryMaxLines,
                        overflow: .ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens(context).textMuted.withValues(alpha: 0.7),
                          fontSize: _summaryFontSize,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (showServerName && item is MediaItem && (item as MediaItem).serverName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          BackendBadge(
                            backend: (item as MediaItem).backend,
                            size: _metadataFontSize + 2,
                            color: tokens(context).textMuted.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              (item as MediaItem).serverName!,
                              maxLines: 1,
                              overflow: .ellipsis,
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
      ),
    );
  }
}

Widget _buildPosterLoadingPlaceholder(BuildContext context, String _) {
  return ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const SizedBox.expand());
}

IconData _mediaPosterFallbackIcon(MediaItem item) {
  if (item.kind == MediaKind.artist) return Symbols.artist_rounded;
  if (item.kind == MediaKind.album) return Symbols.album_rounded;
  if (item.kind == MediaKind.track) return Symbols.music_note_rounded;
  if (item.isShow || item.isSeason || item.isEpisode) return Symbols.tv_rounded;
  return Symbols.movie_rounded;
}

/// Oversized radius for circular focus borders: [CardFocusBorder] paints a
/// BoxDecoration border whose corner radii are clamped to the box, so on a
/// square image area this renders a ring hugging the circular artist artwork.
const double _circularFocusRadius = 9999;

bool _isArtist(Object item) => item is MediaItem && item.kind == MediaKind.artist;

/// Artist artwork clips to a circle; everything else keeps the standard
/// rounded rect.
Widget _clipPosterImage(BuildContext context, Object item, Widget image) {
  if (_isArtist(item)) return ClipOval(child: image);
  return ClipRRect(borderRadius: BorderRadius.circular(tokens(context).radiusSm), child: image);
}

/// Focus border radius matching [_clipPosterImage]'s clip shape.
double _posterFocusRadius(BuildContext context, Object item) =>
    _isArtist(item) ? _circularFocusRadius : tokens(context).radiusSm;

/// Watched/progress overlays are suppressed for artists: a corner checkmark
/// sits outside the circular artwork and play-state on an artist is noise.
/// Albums/tracks keep the standard treatment (albums have no in-progress
/// state to draw; tracks can show watched/resume state).
bool _showsWatchedIndicator(MediaItem item) => item.kind != MediaKind.artist;

Widget _buildPosterImage(
  BuildContext context,
  Object item, {
  bool isOffline = false,
  String? localPosterPath,
  bool mixedHubContext = false,
  EpisodePosterMode? episodePosterModeOverride,
  double? knownWidth,
  double? knownHeight,
}) {
  String? posterUrl;

  if (item is MediaPlaylist) {
    posterUrl = item.displayImagePath;

    return OptimizedMediaImage.playlist(
      client: isOffline ? null : context.tryGetMediaClientWithFallback(serverIdOrNull(item.serverId)),
      imagePath: posterUrl,
      width: knownWidth ?? double.infinity,
      height: knownHeight ?? double.infinity,
      fit: BoxFit.cover,
      placeholder: _buildPosterLoadingPlaceholder,
      localFilePath: localPosterPath,
    );
  } else if (item is MediaItem) {
    final EpisodePosterMode episodePosterMode =
        episodePosterModeOverride ?? SettingsService.instance.read(SettingsService.episodePosterMode);
    final hideSpoilers = SettingsService.instance.read(SettingsService.hideSpoilers);
    final shouldBlur =
        hideSpoilers && item.shouldHideSpoiler && episodePosterMode == EpisodePosterMode.episodeThumbnail;
    final primaryPosterUrl = item.posterThumb(mode: episodePosterMode, mixedHubContext: mixedHubContext);
    final posterFallbackUrl = item.posterThumbFallback(mode: episodePosterMode, mixedHubContext: mixedHubContext);
    final useRememberedFallback = posterFallbackUrl != null && _hasFailedPosterUrl(primaryPosterUrl);
    posterUrl = useRememberedFallback ? posterFallbackUrl : primaryPosterUrl;
    final mediaClient = isOffline ? null : context.tryGetMediaClientWithFallback(serverIdOrNull(item.serverId));
    final fallbackIcon = _mediaPosterFallbackIcon(item);
    final imageType = MediaImageHelper.cardImageType(item, episodePosterMode, mixedHubContext: mixedHubContext);

    Widget image;

    // Square 1:1 artwork for music (artists/albums/tracks)
    if (imageType == ImageType.square) {
      image = OptimizedMediaImage(
        client: mediaClient,
        imagePath: posterUrl,
        width: knownWidth ?? double.infinity,
        height: knownHeight ?? double.infinity,
        fit: BoxFit.cover,
        placeholder: _buildPosterLoadingPlaceholder,
        fallbackIcon: fallbackIcon,
        errorWidget: posterFallbackUrl == null || useRememberedFallback
            ? null
            : (_, _, _) {
                _rememberFailedPosterUrl(primaryPosterUrl);
                return OptimizedMediaImage(
                  client: mediaClient,
                  imagePath: posterFallbackUrl,
                  width: knownWidth ?? double.infinity,
                  height: knownHeight ?? double.infinity,
                  fit: BoxFit.cover,
                  placeholder: _buildPosterLoadingPlaceholder,
                  fallbackIcon: fallbackIcon,
                  imageType: ImageType.square,
                );
              },
        imageType: ImageType.square,
        localFilePath: localPosterPath,
      );
    } else if (imageType == ImageType.thumb) {
      // Use thumb image type for 16:9 content (episodes, or movies in mixed hubs)
      image = OptimizedMediaImage.thumb(
        client: mediaClient,
        imagePath: posterUrl,
        width: knownWidth ?? double.infinity,
        height: knownHeight ?? double.infinity,
        fit: BoxFit.cover,
        placeholder: _buildPosterLoadingPlaceholder,
        fallbackIcon: fallbackIcon,
        localFilePath: localPosterPath,
      );
    } else {
      image = OptimizedMediaImage.poster(
        client: mediaClient,
        imagePath: posterUrl,
        width: knownWidth ?? double.infinity,
        height: knownHeight ?? double.infinity,
        fit: BoxFit.cover,
        placeholder: _buildPosterLoadingPlaceholder,
        fallbackIcon: fallbackIcon,
        errorWidget: posterFallbackUrl == null || useRememberedFallback
            ? null
            : (_, _, _) {
                _rememberFailedPosterUrl(primaryPosterUrl);
                return OptimizedMediaImage.poster(
                  client: mediaClient,
                  imagePath: posterFallbackUrl,
                  width: knownWidth ?? double.infinity,
                  height: knownHeight ?? double.infinity,
                  fit: BoxFit.cover,
                  placeholder: _buildPosterLoadingPlaceholder,
                  fallbackIcon: fallbackIcon,
                );
              },
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
    child: const Center(child: AppIcon(Symbols.movie_rounded, fill: 1, size: 40, color: Colors.white54)),
  );
}

class _MediaCardHelpers {
  static Widget buildPlaylistMeta(BuildContext context, MediaPlaylist playlist) {
    if (playlist.leafCount != null && playlist.leafCount! > 0) {
      return Text(
        t.playlists.itemCount(count: playlist.leafCount!),
        maxLines: 1,
        overflow: .ellipsis,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 11, height: 1.1),
      );
    }
    return const SizedBox.shrink();
  }

  /// Builds metadata subtitle (for collections, episodes, movies, shows)
  static Widget buildMetadataSubtitle(
    BuildContext context,
    MediaItem mi, {
    bool isOffline = false,
    bool enableDetailLinks = true,
  }) {
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
          overflow: .ellipsis,
          style: subtitleStyle,
        );
      }
    }

    // For albums, show the album artist
    if (mi.kind == MediaKind.album && mi.albumArtistTitle != null) {
      return Text(mi.albumArtistTitle!, maxLines: 1, overflow: .ellipsis, style: subtitleStyle);
    }

    // For tracks, show "Artist • duration"
    if (mi.kind == MediaKind.track) {
      final parts = [?mi.trackArtistTitle, if (mi.durationMs case final durationMs?) formatDurationTextual(durationMs)];
      if (parts.isNotEmpty) {
        return Text(parts.join(' • '), maxLines: 1, overflow: .ellipsis, style: subtitleStyle);
      }
    }

    // For episodes, show "S# · Episode Title" with clickable season link
    if (mi.isEpisode && mi.parentIndex != null) {
      final episodeTitle = mi.displaySubtitle ?? mi.displayTitle;
      final showEp = SettingsService.instance.read(SettingsService.showEpisodeNumberOnCards);
      final episodeSuffix = (showEp && mi.index != null) ? ' E${mi.index}' : '';
      if (enableDetailLinks && mi.parentId != null) {
        return Row(
          children: [
            _ClickableText(
              text: 'S${mi.parentIndex}',
              style: subtitleStyle,
              onTap: () => _navigateToFocusedDetail(context, mi, isOffline: isOffline),
            ),
            Text('$episodeSuffix · ', style: subtitleStyle),
            Expanded(
              child: Text(episodeTitle, maxLines: 1, overflow: .ellipsis, style: subtitleStyle),
            ),
          ],
        );
      }
      return Text(
        'S${mi.parentIndex}$episodeSuffix · $episodeTitle',
        maxLines: 1,
        overflow: .ellipsis,
        style: subtitleStyle,
      );
    }

    // For other media types, show subtitle/parent/year
    if (mi.displaySubtitle != null) {
      return Text(mi.displaySubtitle!, maxLines: 1, overflow: .ellipsis, style: subtitleStyle);
    } else if (mi.parentTitle != null) {
      return Text(mi.parentTitle!, maxLines: 1, overflow: .ellipsis, style: subtitleStyle);
    } else if (mi.year != null) {
      final edition = mi.editionTitle;
      return Text(
        edition != null ? '${mi.year} · $edition' : '${mi.year}',
        maxLines: 1,
        overflow: .ellipsis,
        style: subtitleStyle,
      );
    }

    return const SizedBox.shrink();
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

void _navigateToFocusedDetail(BuildContext context, MediaItem item, {bool isOffline = false}) {
  navigateToMediaItemDetails(context, item, isOffline: isOffline);
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
      return Text(widget.text, maxLines: 1, overflow: .ellipsis, style: baseStyle);
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
          overflow: .ellipsis,
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

/// Tap surface for a card: a full [InkWell] (ripple, hover, cursor) on
/// desktop where hover feedback matters, a bare [GestureDetector] on TV and
/// touch handhelds — the ripple is invisible under poster art and the
/// per-card ink/hover/focus machinery (~15 elements each) is dead weight
/// that adds up while scrolling card grids.
/// Keyboard focus is handled by the focus wrappers either way
/// (canRequestFocus stays false on the InkWell).
class _CardTapRegion extends StatelessWidget {
  const _CardTapRegion({
    required this.onTap,
    this.onTapDown,
    this.onLongPress,
    this.onSecondaryTap,
    this.onSecondaryTapDown,
    this.borderRadius,
    required this.child,
  });

  final VoidCallback onTap;
  final GestureTapDownCallback? onTapDown;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final GestureTapDownCallback? onSecondaryTapDown;
  final BorderRadius? borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!PlatformDetector.isDesktopOS()) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onTapDown: onTapDown,
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        onSecondaryTapDown: onSecondaryTapDown,
        child: child,
      );
    }
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      canRequestFocus: false,
      onTap: onTap,
      onTapDown: onTapDown,
      onLongPress: onLongPress,
      onSecondaryTapDown: onSecondaryTapDown,
      onSecondaryTap: onSecondaryTap,
      borderRadius: borderRadius,
      child: child,
    );
  }
}
