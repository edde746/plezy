import 'dart:async';
import 'dart:ui';
import '../media/ids.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/card_focus_scope.dart';
import '../focus/focus_theme.dart';
import '../focus/input_mode_tracker.dart';
import '../i18n/app_locale_utils.dart';
import '../media/catalog_item_ref.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_kind.dart';
import '../media/media_playlist.dart';
import '../mixins/context_menu_tap_mixin.dart';
import '../models/catalog/catalog_item.dart';
import '../models/catalog/catalog_metadata.dart';
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

const int _catalogBadgeLimit = 3;
String? _compactNumberLocale;
NumberFormat? _compactNumberFormatter;
String? _percentNumberLocale;
NumberFormat? _percentNumberFormatter;

String _formatCompactCatalogNumber(num value) {
  final locale = LocaleSettings.currentLocale.intlLocaleName;
  if (_compactNumberFormatter == null || _compactNumberLocale != locale) {
    _compactNumberLocale = locale;
    _compactNumberFormatter = NumberFormat.compact(locale: locale);
  }
  return _compactNumberFormatter!.format(value);
}

String _formatCatalogPercent(double value) {
  final locale = LocaleSettings.currentLocale.intlLocaleName;
  if (_percentNumberFormatter == null || _percentNumberLocale != locale) {
    _percentNumberLocale = locale;
    _percentNumberFormatter = NumberFormat.percentPattern(locale);
  }
  return _percentNumberFormatter!.format(value);
}

/// Composes the "PG-13 • 2006 • 2h 10min • 7.7★" line under a card.
///
/// [compact] is for the poster grid, where the line is one ellipsized row a
/// third of the screen wide. Measured on a Pixel 7, the full order spends the
/// whole row on `PG-13 • 2006 • 2h 10mi…` and truncates the rating away —
/// the one value this line exists to show. The compact form therefore leads
/// with the rating and drops certification, edition, genres and studio, all
/// of which the detail screen and the search list still render in full.
String _buildMediaMetadataLine(MediaItem item, {CatalogItem? catalogItem, bool compact = false}) {
  final parts = <String>[];

  if (item.kind == MediaKind.collection) {
    final count = item.childCount ?? item.leafCount;
    if (count != null && count > 0) {
      parts.add(t.playlists.itemCount(count: count));
    }
    return parts.join(' • ');
  }

  String? ratingPart() {
    if (item.rating case final rating?) {
      final votes = compact ? null : catalogItem?.votes;
      final voteSuffix = votes != null && votes > 0 ? ' (${_formatCompactCatalogNumber(votes)})' : '';
      return '${formatRating(rating)}★$voteSuffix';
    }
    return null;
  }

  if (compact) {
    if (ratingPart() case final rating?) parts.add(rating);
    if (item.year case final year?) parts.add('$year');
    if (item.durationMs case final durationMs?) parts.add(formatDurationTextual(durationMs));
    return parts.join(' • ');
  }

  if (item.contentRating case final contentRating? when contentRating.isNotEmpty) {
    final formatted = formatContentRating(contentRating);
    if (formatted.isNotEmpty) parts.add(formatted);
  }
  if (item.year case final year?) parts.add('$year');
  if (item.editionTitle case final editionTitle?) parts.add(editionTitle);
  if (item.durationMs case final durationMs?) parts.add(formatDurationTextual(durationMs));
  if (ratingPart() case final rating?) parts.add(rating);

  if (catalogItem != null) {
    final genres = catalogItem.genres;
    if (genres != null && genres.isNotEmpty) {
      parts.add(genres.length == 1 ? genres.first : '${genres.first}, ${genres[1]}');
    }
  }

  final studio = item.studio ?? catalogItem?.network;
  if (studio != null && studio.isNotEmpty) parts.add(studio);
  return parts.join(' • ');
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

  /// Optional collection position announced with the card.
  final String? semanticValue;
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

  /// Paint-time black tint amount for the artwork, from 0 (clear) to 1 (black).
  final Animation<double>? artworkDim;

  /// Overrides the silhouette inferred from the item itself. Collection and
  /// playlist records do not encode the media-library shape, so their owning
  /// surface supplies this for music libraries.
  final CardShape? cardShapeOverride;

  const MediaCard({
    super.key,
    required this.item,
    this.semanticValue,
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
    this.artworkDim,
    this.cardShapeOverride,
  }) : usesContinueWatchingAction = usesContinueWatchingAction ?? isInContinueWatching;

  @override
  State<MediaCard> createState() => MediaCardState();
}

class MediaCardState extends State<MediaCard> with ContextMenuTapMixin<MediaCard> {
  /// Public method to trigger tap action (for keyboard/gamepad SELECT)
  void handleTap() {
    _handleTap(context, _effectiveItemForAction(context));
  }

  CatalogItem? _cachedCatalogItem;
  Color? _catalogAccent;

  CatalogItem? get _catalogItem => _cachedCatalogItem;

  @override
  void initState() {
    super.initState();
    _cacheCatalogItem(widget.item);
  }

  @override
  void didUpdateWidget(covariant MediaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.item, widget.item)) _cacheCatalogItem(widget.item);
  }

  void _cacheCatalogItem(Object item) {
    _cachedCatalogItem = item is MediaItem ? item.catalogItem : null;
    _catalogAccent = _parseCatalogAccent(_cachedCatalogItem?.accentColor);
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
    final enableDetailLinks = widget.onTap == null;
    final preservePointerDetailSemantics = !PlatformDetector.isTV() || MediaQuery.accessibleNavigationOf(context);
    final preserveDetailSemantics =
        preservePointerDetailSemantics && enableDetailLinks && item is MediaItem && _hasPointerDetailLinks(item);
    final localPosterPath = _getLocalPosterPath(context, item);

    Widget cardWidget = viewMode == ViewMode.grid
        ? _buildGridCard(context, item, localPosterPath, preserveDetailSemantics: preserveDetailSemantics)
        : _MediaCardList(
            item: item,
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
            cardShapeOverride: widget.cardShapeOverride,
            catalogItem: _catalogItem,
            enableDetailLinks: enableDetailLinks,
          );

    cardWidget = Semantics(
      container: preserveDetailSemantics,
      explicitChildNodes: preserveDetailSemantics,
      label: semanticLabel,
      value: widget.semanticValue,
      button: true,
      onTap: handleTap,
      onLongPress: showContextMenu,
      excludeSemantics: !preserveDetailSemantics,
      child: cardWidget,
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
  /// flattened Column.
  ///
  /// Cards without detail links retain one merged semantic node. Cards with
  /// pointer detail links leave those specific actions as explicit descendants
  /// of the coherent card announcement.
  Widget _buildGridCard(
    BuildContext context,
    Object item,
    String? localPosterPath, {
    required bool preserveDetailSemantics,
  }) {
    final catalogItem = _catalogItem;
    final now = catalogItem?.nextEpisode == null ? null : DateTime.now();
    final badgeLabels = _buildCatalogBadgeLabels(catalogItem, now);
    final Widget card;
    if (widget.fullBleedImage) {
      card = LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = widget.width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : null);
          final cardHeight = widget.height ?? (constraints.hasBoundedHeight ? constraints.maxHeight : null);
          if (cardHeight == null) {
            return _buildStandardGridCard(context, item, localPosterPath, badgeLabels: badgeLabels);
          }
          return _buildFullBleedGridCard(
            context,
            item,
            localPosterPath,
            width: cardWidth,
            height: cardHeight,
            badgeLabels: badgeLabels,
          );
        },
      );
    } else {
      card = _buildStandardGridCard(context, item, localPosterPath, badgeLabels: badgeLabels);
    }

    return preserveDetailSemantics ? card : MergeSemantics(child: card);
  }

  Widget _buildFullBleedGridCard(
    BuildContext context,
    Object item,
    String? localPosterPath, {
    required double? width,
    required double height,
    required List<String> badgeLabels,
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
        child: ExcludeSemantics(
          child: _CatalogFocusBorder(
            accentColor: _catalogAccent,
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
                    cardShapeOverride: widget.cardShapeOverride,
                    catalogItem: _catalogItem,
                    knownWidth: width,
                    knownHeight: height,
                    artworkDim: widget.artworkDim,
                  ),
                  if (item is MediaItem && _showsWatchedIndicator(item)) WatchedIndicator(item: item),
                  if (badgeLabels.isNotEmpty) _CatalogBadges(labels: badgeLabels),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardGridCard(
    BuildContext context,
    Object item,
    String? localPosterPath, {
    required List<String> badgeLabels,
  }) {
    // Compute actual poster dimensions from card dimensions
    final posterWidth = widget.width != null ? widget.width! - 6 : null;
    final posterHeight = widget.height;

    // The focus border hugs the poster (captions stay outside it), matching
    // the full-bleed card treatment.
    final poster = ExcludeSemantics(
      child: _CatalogFocusBorder(
        accentColor: _catalogAccent,
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
                cardShapeOverride: widget.cardShapeOverride,
                catalogItem: _catalogItem,
                knownWidth: _catalogItem != null ? posterWidth : (posterHeight != null ? posterWidth : null),
                knownHeight: posterHeight,
                artworkDim: widget.artworkDim,
              ),
            ),
            if (item is MediaItem && _showsWatchedIndicator(item)) WatchedIndicator(item: item),
            if (badgeLabels.isNotEmpty) _CatalogBadges(labels: badgeLabels),
          ],
        ),
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
                ExcludeSemantics(
                  child: Text(
                    item is MediaPlaylist ? item.title : (item as MediaItem).displayTitle,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: const TextStyle(fontWeight: .w600, fontSize: 13, height: 1.1),
                  ),
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
                  catalogItem: _catalogItem,
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
  final CardShape? cardShapeOverride;
  final bool enableDetailLinks;
  final CatalogItem? catalogItem;

  const _MediaCardList({
    required this.item,
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
    this.cardShapeOverride,
    this.catalogItem,
    required this.enableDetailLinks,
  });

  CardShape _cardShape() {
    if (cardShapeOverride case final shape?) return shape;
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
    final current = item;
    if (current is MediaPlaylist) {
      final parts = <String>[];
      if (current.leafCount != null && current.leafCount! > 0) {
        parts.add(t.playlists.itemCount(count: current.leafCount!));
      }
      if (current.durationMs case final durationMs?) {
        parts.add(formatDurationTextual(durationMs));
      }
      if (current.smart) parts.add(t.playlists.smartPlaylist);
      return parts.join(' • ');
    }
    return current is MediaItem ? _buildMediaMetadataLine(current, catalogItem: catalogItem) : '';
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
        return 'S${mi.parentIndex}${_episodeNumberSuffix(mi)}';
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

  TextStyle? _subtitleStyle(BuildContext context) => Theme.of(context).textTheme.bodySmall?.copyWith(
    color: tokens(context).textMuted.withValues(alpha: 0.85),
    fontSize: _subtitleFontSize,
  );

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
              ExcludeSemantics(
                child: SizedBox(
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
                          cardShapeOverride: cardShapeOverride,
                          catalogItem: catalogItem,
                          knownWidth: catalogItem == null ? null : _posterWidth(),
                          knownHeight: catalogItem == null ? null : _posterHeight(),
                        ),
                      ),
                      if (item is MediaItem && _showsWatchedIndicator(item as MediaItem))
                        WatchedIndicator(item: item as MediaItem),
                    ],
                  ),
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
                      ExcludeSemantics(
                        child: Text(
                          _displayTitle(),
                          maxLines: 2,
                          overflow: .ellipsis,
                          style: TextStyle(fontWeight: .w600, fontSize: _titleFontSize, height: 1.2),
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (metadataLine.isNotEmpty) ...[
                      ExcludeSemantics(
                        child: Text(
                          metadataLine,
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens(context).textMuted.withValues(alpha: 0.9),
                            fontSize: _metadataFontSize,
                            fontWeight: .w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (item is MediaItem &&
                        (item as MediaItem).isEpisode &&
                        (item as MediaItem).parentIndex != null &&
                        (item as MediaItem).parentId != null) ...[
                      _buildEpisodeSubtitleRow(
                        context,
                        item as MediaItem,
                        style: _subtitleStyle(context),
                        enableDetailLinks: enableDetailLinks,
                        isOffline: isOffline,
                      ),
                      const SizedBox(height: 4),
                    ] else if (subtitle != null) ...[
                      ExcludeSemantics(
                        child: Text(subtitle, maxLines: 1, overflow: .ellipsis, style: _subtitleStyle(context)),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (!(item is MediaItem &&
                            SettingsService.instance.read(SettingsService.hideSpoilers) &&
                            (item as MediaItem).shouldHideSpoiler) &&
                        _summary() != null) ...[
                      ExcludeSemantics(
                        child: Text(
                          _summary()!,
                          maxLines: _summaryMaxLines,
                          overflow: .ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens(context).textMuted.withValues(alpha: 0.7),
                            fontSize: _summaryFontSize,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                    if (showServerName && item is MediaItem && (item as MediaItem).serverName != null) ...[
                      const SizedBox(height: 4),
                      ExcludeSemantics(
                        child: Row(
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
  CardShape? cardShapeOverride,
  CatalogItem? catalogItem,
  double? knownWidth,
  double? knownHeight,
  Animation<double>? artworkDim,
}) {
  if (item is MediaPlaylist) {
    return OptimizedMediaImage(
      client: isOffline ? null : context.tryGetMediaClientWithFallback(serverIdOrNull(item.serverId)),
      imagePath: item.displayImagePath,
      width: knownWidth ?? double.infinity,
      height: knownHeight ?? double.infinity,
      fit: BoxFit.cover,
      placeholder: _buildPosterLoadingPlaceholder,
      fallbackIcon: Symbols.playlist_play_rounded,
      imageType: cardShapeOverride == CardShape.square ? ImageType.square : ImageType.poster,
      localFilePath: localPosterPath,
      artworkDim: artworkDim,
    );
  } else if (item is MediaItem) {
    final EpisodePosterMode episodePosterMode =
        episodePosterModeOverride ?? SettingsService.instance.read(SettingsService.episodePosterMode);
    final hideSpoilers = SettingsService.instance.read(SettingsService.hideSpoilers);
    final shouldBlur =
        hideSpoilers && item.shouldHideSpoiler && episodePosterMode == EpisodePosterMode.episodeThumbnail;
    final mediaClient = isOffline ? null : context.tryGetMediaClientWithFallback(serverIdOrNull(item.serverId));
    final fallbackIcon = _mediaPosterFallbackIcon(item);
    final imageType = switch (cardShapeOverride) {
      CardShape.square => ImageType.square,
      CardShape.wide => ImageType.thumb,
      CardShape.poster => ImageType.poster,
      null => MediaImageHelper.cardImageType(item, episodePosterMode, mixedHubContext: mixedHubContext),
    };
    final defaultPosterUrl = item.posterThumb(mode: episodePosterMode, mixedHubContext: mixedHubContext);
    final defaultFallbackUrl = item.posterThumbFallback(mode: episodePosterMode, mixedHubContext: mixedHubContext);
    final targetPx = knownWidth != null && knownWidth.isFinite && knownWidth > 0
        ? (knownWidth * MediaQuery.devicePixelRatioOf(context)).ceil()
        : null;
    final catalogArtworkUrl = targetPx == null
        ? null
        : imageType == ImageType.thumb
        ? catalogItem?.backdropFor(targetPx)
        : catalogItem?.posterFor(targetPx);
    final primaryPosterUrl = catalogArtworkUrl ?? defaultPosterUrl;
    final posterFallbackUrl = catalogArtworkUrl != null && catalogArtworkUrl != defaultPosterUrl
        ? defaultPosterUrl ?? defaultFallbackUrl
        : defaultFallbackUrl;
    final useRememberedFallback = posterFallbackUrl != null && _hasFailedPosterUrl(primaryPosterUrl);
    final posterUrl = useRememberedFallback ? posterFallbackUrl : primaryPosterUrl;

    OptimizedMediaImage buildImage(
      String? path,
      ImageType type, {
      String? localFilePath,
      Widget Function(BuildContext, String, dynamic)? errorWidget,
    }) => OptimizedMediaImage(
      client: mediaClient,
      imagePath: path,
      width: knownWidth ?? double.infinity,
      height: knownHeight ?? double.infinity,
      fit: BoxFit.cover,
      placeholder: _buildPosterLoadingPlaceholder,
      fallbackIcon: fallbackIcon,
      errorWidget: errorWidget,
      imageType: type,
      localFilePath: localFilePath,
      artworkDim: artworkDim,
    );

    // Remember the dead primary URL so later builds go straight to the fallback.
    Widget Function(BuildContext, String, dynamic)? retryWithFallback(ImageType type) {
      if (posterFallbackUrl == null || useRememberedFallback) return null;
      return (_, _, error) {
        // Only an attempted-and-failed load proves the primary artwork is dead.
        // An unresolvable URL just means there is no client right now (offline,
        // profile switch, reconnect); memoizing it would pin this item to
        // fallback artwork for the process lifetime.
        if (error is! UnresolvedImageUrl) _rememberFailedPosterUrl(primaryPosterUrl);
        return buildImage(posterFallbackUrl, type);
      };
    }

    Widget image;

    // Square 1:1 artwork for music (artists/albums/tracks)
    if (imageType == ImageType.square) {
      image = buildImage(
        posterUrl,
        ImageType.square,
        localFilePath: localPosterPath,
        errorWidget: retryWithFallback(ImageType.square),
      );
    } else if (imageType == ImageType.thumb) {
      // Use thumb image type for 16:9 content (episodes, or movies in mixed hubs)
      image = buildImage(posterUrl, ImageType.thumb, localFilePath: localPosterPath);
    } else {
      image = buildImage(
        posterUrl,
        ImageType.poster,
        localFilePath: localPosterPath,
        errorWidget: retryWithFallback(ImageType.poster),
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
      return ExcludeSemantics(
        child: Text(
          t.playlists.itemCount(count: playlist.leafCount!),
          maxLines: 1,
          overflow: .ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 11, height: 1.1),
        ),
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
    CatalogItem? catalogItem,
  }) {
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: tokens(context).textMuted, fontSize: 11, height: 1.1);

    if (catalogItem != null) {
      final metadata = _buildMediaMetadataLine(mi, catalogItem: catalogItem, compact: true);
      if (metadata.isNotEmpty) {
        return ExcludeSemantics(
          child: Text(metadata, maxLines: 1, overflow: .ellipsis, style: subtitleStyle),
        );
      }
    }

    // For collections, show item count
    if (mi.kind == MediaKind.collection) {
      final count = mi.childCount ?? mi.leafCount;
      if (count != null && count > 0) {
        return ExcludeSemantics(
          child: Text(
            t.playlists.itemCount(count: count),
            maxLines: 1,
            overflow: .ellipsis,
            style: subtitleStyle,
          ),
        );
      }
    }

    // For albums, show the album artist
    if (mi.kind == MediaKind.album && mi.albumArtistTitle != null) {
      return ExcludeSemantics(
        child: Text(mi.albumArtistTitle!, maxLines: 1, overflow: .ellipsis, style: subtitleStyle),
      );
    }

    // For tracks, show "Artist • duration"
    if (mi.kind == MediaKind.track) {
      final parts = [?mi.trackArtistTitle, if (mi.durationMs case final durationMs?) formatDurationTextual(durationMs)];
      if (parts.isNotEmpty) {
        return ExcludeSemantics(
          child: Text(parts.join(' • '), maxLines: 1, overflow: .ellipsis, style: subtitleStyle),
        );
      }
    }

    // For episodes, show "S# · Episode Title" with clickable season link
    if (mi.isEpisode && mi.parentIndex != null) {
      if (enableDetailLinks && mi.parentId != null) {
        return _buildEpisodeSubtitleRow(
          context,
          mi,
          style: subtitleStyle,
          enableDetailLinks: true,
          isOffline: isOffline,
        );
      }
      final episodeTitle = mi.displaySubtitle ?? mi.displayTitle;
      return ExcludeSemantics(
        child: Text(
          'S${mi.parentIndex}${_episodeNumberSuffix(mi)} · $episodeTitle',
          maxLines: 1,
          overflow: .ellipsis,
          style: subtitleStyle,
        ),
      );
    }

    // For other media types, show subtitle/parent/year
    if (mi.displaySubtitle != null) {
      return ExcludeSemantics(
        child: Text(mi.displaySubtitle!, maxLines: 1, overflow: .ellipsis, style: subtitleStyle),
      );
    } else if (mi.parentTitle != null) {
      return ExcludeSemantics(
        child: Text(mi.parentTitle!, maxLines: 1, overflow: .ellipsis, style: subtitleStyle),
      );
    } else if (mi.year != null) {
      final edition = mi.editionTitle;
      return ExcludeSemantics(
        child: Text(
          edition != null ? '${mi.year} · $edition' : '${mi.year}',
          maxLines: 1,
          overflow: .ellipsis,
          style: subtitleStyle,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

Color? _parseCatalogAccent(String? value) {
  if (value == null || value.length != 7 || value.codeUnitAt(0) != 0x23) return null;
  final rgb = int.tryParse(value.substring(1), radix: 16);
  return rgb == null ? null : Color(0xff000000 | rgb);
}

String _catalogSeasonName(CatalogSeasonName season) => switch (season) {
  CatalogSeasonName.winter => t.explore.season.winter,
  CatalogSeasonName.spring => t.explore.season.spring,
  CatalogSeasonName.summer => t.explore.season.summer,
  CatalogSeasonName.fall => t.explore.season.fall,
};

String? _catalogRankBadge(CatalogItem item) {
  String? allTimeLabel;
  for (final rank in item.ranks ?? const <CatalogRank>[]) {
    final contextual = !rank.allTime || rank.scope == CatalogRankScope.seasonal;
    if (contextual) {
      final season = rank.season;
      final year = rank.year;
      if (season == null && year == null) continue;
      final seasonLabel = season == null
          ? '$year'
          : year == null
          ? _catalogSeasonName(season)
          : t.explore.season.withYear(season: _catalogSeasonName(season), year: year);
      return t.explore.badge.rankSeasonal(n: rank.rank, season: seasonLabel);
    }

    allTimeLabel ??= switch (rank.scope) {
      CatalogRankScope.popular => t.explore.badge.rankPopular(n: rank.rank),
      CatalogRankScope.airing => t.explore.badge.rankAiring(n: rank.rank),
      CatalogRankScope.rated => t.explore.badge.rankRated(n: rank.rank),
      CatalogRankScope.favorited => t.explore.badge.rankFavorited(n: rank.rank),
      CatalogRankScope.trending => t.explore.badge.rankTrending(n: rank.rank),
      CatalogRankScope.seasonal => null,
    };
  }
  return allTimeLabel;
}

String? _catalogAvailabilityBadge(CatalogServerState? state) {
  if (state == null) return null;
  if (state.availability4k == CatalogAvailability.available) return t.explore.badge.availableIn4k;
  if (state.availability == CatalogAvailability.available) return t.explore.badge.available;

  final availableSeasons = state.availableSeasons;
  final totalSeasons = state.totalSeasons;
  if (availableSeasons != null && totalSeasons != null && availableSeasons > 0 && totalSeasons > 0) {
    return t.explore.badge.seasonsAvailable(available: availableSeasons, total: totalSeasons);
  }
  if (state.availability == CatalogAvailability.partiallyAvailable ||
      state.availability4k == CatalogAvailability.partiallyAvailable) {
    return t.explore.badge.partiallyAvailable;
  }
  return null;
}

String? _catalogRequestBadge(CatalogServerState? state) {
  if (state == null) return null;
  final is4k = state.request4k != null;
  final request = state.request4k ?? state.request;
  return switch (request) {
    CatalogRequestState.pending => t.explore.badge.pendingApproval,
    CatalogRequestState.approved => is4k ? t.explore.badge.requested4k : t.explore.badge.requested,
    CatalogRequestState.processing => t.explore.badge.processing,
    CatalogRequestState.declined => t.explore.badge.declined,
    CatalogRequestState.failed => t.explore.badge.requestFailed,
    null => null,
  };
}

String? _catalogNextEpisodeBadge(CatalogItem item, DateTime? now) {
  final nextEpisode = item.nextEpisode;
  if (nextEpisode == null || now == null || !nextEpisode.airsAt.isAfter(now)) return null;
  final duration = formatDurationTextual(nextEpisode.timeUntil(now).inMilliseconds);
  final episode = nextEpisode.episode;
  return episode == null
      ? t.explore.badge.nextAiringIn(duration: duration)
      : t.explore.badge.nextEpisodeIn(episode: episode, duration: duration);
}

String? _catalogViewersBadge(CatalogAudience? audience) {
  final viewers = audience?.viewers;
  final period = audience?.viewersPeriod;
  if (viewers == null || viewers <= 0 || period == null) return null;
  final count = _formatCompactCatalogNumber(viewers);
  return switch (period) {
    CatalogAudiencePeriod.day => t.explore.stats.viewersDay(n: count),
    CatalogAudiencePeriod.week => t.explore.stats.viewersWeek(n: count),
    CatalogAudiencePeriod.month => t.explore.stats.viewersMonth(n: count),
    CatalogAudiencePeriod.year => t.explore.stats.viewersYear(n: count),
    CatalogAudiencePeriod.allTime => t.explore.stats.viewersAllTime(n: count),
  };
}

String? _catalogEpisodeBadge(CatalogItem item) {
  if (item.kind != MediaKind.show) return null;
  final episodeCount = item.episodeCount;
  final runtimeMinutes = item.runtimeMinutes;
  final parts = <String>[
    if (episodeCount != null && episodeCount > 0) t.explore.badge.episodesShort(n: episodeCount),
    if (runtimeMinutes != null && runtimeMinutes > 0) t.explore.badge.minutesPerEpisode(n: runtimeMinutes),
  ];
  return parts.isEmpty ? null : parts.join(' • ');
}

List<String> _buildCatalogBadgeLabels(CatalogItem? item, DateTime? now) {
  if (item == null) return const [];
  final labels = <String>[];

  void add(String? label) {
    if (label != null && label.isNotEmpty && labels.length < _catalogBadgeLimit) labels.add(label);
  }

  // Server availability and request state are independent, so each gets its
  // own high-priority slot. This preserves cases such as HD available plus a
  // pending 4K request instead of collapsing them into one misleading ladder.
  add(_catalogAvailabilityBadge(item.serverState));
  add(_catalogRequestBadge(item.serverState));
  final recommendationCount = item.recommendationCount;
  if (recommendationCount != null && recommendationCount > 0) {
    add(t.explore.detail.recommendedByUsers(n: recommendationCount));
  } else {
    final recommendationPercent = item.recommendationPercent;
    if (recommendationPercent != null && recommendationPercent > 0 && recommendationPercent <= 1) {
      add(t.explore.detail.recommendedByPercent(percent: _formatCatalogPercent(recommendationPercent)));
    }
  }
  // Row-specific provenance follows server state, then safety, airing,
  // leaderboard, live audience, windowed audience, and episodic shape.
  if (item.isAdult == true) add(t.explore.badge.adult);
  add(_catalogNextEpisodeBadge(item, now));
  add(_catalogRankBadge(item));

  final audience = item.audience;
  final watchingNow = audience?.watchingNow;
  if (watchingNow != null && watchingNow > 0) {
    add(t.explore.badge.watchingNow(n: _formatCompactCatalogNumber(watchingNow)));
  }
  add(_catalogViewersBadge(audience));

  add(_catalogEpisodeBadge(item));
  return labels;
}

class _CatalogBadges extends StatelessWidget {
  final List<String> labels;

  const _CatalogBadges({required this.labels});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const Key('catalog-badges'),
      top: 6,
      left: 6,
      right: 6,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            if (index > 0) const SizedBox(height: 3),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: Text(
                  labels[index],
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: .w700, height: 1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CatalogFocusBorder extends StatelessWidget {
  final Color? accentColor;
  final double borderRadius;
  final Widget child;

  const _CatalogFocusBorder({required this.accentColor, required this.borderRadius, required this.child});

  @override
  Widget build(BuildContext context) {
    final color = accentColor;
    if (color == null) return CardFocusBorder(borderRadius: borderRadius, child: child);
    final showFocus = CardFocusScope.maybeOf(context);
    if (showFocus == null) return child;
    return AnimatedContainer(
      duration: FocusTheme.getAnimationDuration(context),
      curve: Curves.easeOutCubic,
      foregroundDecoration: FocusTheme.focusDecoration(
        context,
        isFocused: showFocus,
        borderRadius: borderRadius,
        borderStrokeAlign: BorderSide.strokeAlignOutside,
        color: color,
      ),
      child: child,
    );
  }
}

/// "S# E# · Episode title" with the season number linking to the season.
Widget _buildEpisodeSubtitleRow(
  BuildContext context,
  MediaItem mi, {
  required TextStyle? style,
  required bool enableDetailLinks,
  required bool isOffline,
}) {
  final seasonLabel = 'S${mi.parentIndex}';
  return Row(
    children: [
      if (enableDetailLinks)
        _ClickableText(
          text: seasonLabel,
          style: style,
          onTap: () => _navigateToFocusedDetail(context, mi, isOffline: isOffline),
        )
      else
        ExcludeSemantics(child: Text(seasonLabel, style: style)),
      ExcludeSemantics(child: Text('${_episodeNumberSuffix(mi)} · ', style: style)),
      Expanded(
        child: ExcludeSemantics(
          child: Text(mi.displaySubtitle ?? mi.displayTitle, maxLines: 1, overflow: .ellipsis, style: style),
        ),
      ),
    ],
  );
}

/// Empty unless [SettingsService.showEpisodeNumberOnCards] is on.
String _episodeNumberSuffix(MediaItem mi) {
  final showEp = SettingsService.instance.read(SettingsService.showEpisodeNumberOnCards);
  return (showEp && mi.index != null) ? ' E${mi.index}' : '';
}

/// Whether the card renders any pointer detail link for this item.
bool _hasPointerDetailLinks(MediaItem mi) {
  if (_hasClickableTitle(mi)) return true;
  return mi.isEpisode && mi.parentIndex != null && mi.parentId != null;
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
/// Keyboard/dpad mode keeps plain visual text while screen readers retain the
/// separately invokable detail action.
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
    final text = Semantics(
      label: widget.text,
      hint: t.mediaMenu.viewDetails,
      button: true,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: Text(
        widget.text,
        maxLines: 1,
        overflow: .ellipsis,
        style: isKeyboard
            ? baseStyle
            : baseStyle.copyWith(
                decoration: _isHovered ? TextDecoration.underline : null,
                decorationColor: baseStyle.color,
              ),
      ),
    );

    if (isKeyboard) return text;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(excludeFromSemantics: true, onTap: widget.onTap, child: text),
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
        excludeFromSemantics: true,
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
      excludeFromSemantics: true,
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
