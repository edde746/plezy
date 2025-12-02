import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'focus/focus_indicator.dart';
import 'hub_navigation_controller.dart';
import '../client/plex_client.dart';
import '../mixins/keyboard_long_press_mixin.dart';
import '../models/plex_metadata.dart';
import '../models/plex_playlist.dart';
import '../providers/multi_server_provider.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../utils/content_rating_formatter.dart';
import '../utils/duration_formatter.dart';
import '../screens/media_detail_screen.dart';
import '../screens/season_detail_screen.dart';
import '../screens/playlist_detail_screen.dart';
import '../screens/collection_detail_screen.dart';
import '../theme/theme_helper.dart';
import '../i18n/strings.g.dart';
import 'media_context_menu.dart';

class MediaCard extends StatefulWidget {
  final dynamic item; // Can be PlexMetadata or PlexPlaylist
  final double? width;
  final double? height;
  final void Function(String ratingKey)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final VoidCallback?
  onListRefresh; // Callback to refresh the entire parent list
  final bool forceGridMode;
  final bool isInContinueWatching;
  final String?
  collectionId; // The collection ID if displaying within a collection

  /// External FocusNode for hub navigation (provided by HubSection)
  final FocusNode? focusNode;

  /// Hub section ID for focus memory tracking
  final String? hubId;

  /// Item index within the hub section
  final int? itemIndex;

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
    this.focusNode,
    this.hubId,
    this.itemIndex,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  final _contextMenuKey = GlobalKey<MediaContextMenuState>();

  void _showContextMenu() {
    _contextMenuKey.currentState?.showContextMenu(context);
  }

  String _buildSemanticLabel() {
    final item = widget.item;
    final itemType = item.type.toLowerCase();

    // Build base label based on type
    String baseLabel;
    if (itemType == 'episode') {
      final episodeInfo = item.parentIndex != null && item.index != null
          ? 'S${item.parentIndex} E${item.index}'
          : '';
      baseLabel = t.accessibility.mediaCardEpisode(
        title: item.displayTitle,
        episodeInfo: episodeInfo,
      );
    } else if (itemType == 'season') {
      final seasonInfo = item.parentIndex != null
          ? 'Season ${item.parentIndex}'
          : '';
      baseLabel = t.accessibility.mediaCardSeason(
        title: item.displayTitle,
        seasonInfo: seasonInfo,
      );
    } else if (itemType == 'movie') {
      baseLabel = t.accessibility.mediaCardMovie(title: item.displayTitle);
    } else {
      baseLabel = t.accessibility.mediaCardShow(title: item.displayTitle);
    }

    // Add watched status
    if (item.isWatched) {
      baseLabel = '$baseLabel, ${t.accessibility.mediaCardWatched}';
    } else if (item.viewOffset != null &&
        item.duration != null &&
        item.viewOffset! > 0) {
      final percent = ((item.viewOffset! / item.duration!) * 100).round();
      baseLabel =
          '$baseLabel, ${t.accessibility.mediaCardPartiallyWatched(percent: percent)}';
    } else {
      baseLabel = '$baseLabel, ${t.accessibility.mediaCardUnwatched}';
    }

    return baseLabel;
  }

  void _handleTap(BuildContext context) async {
    // Handle playlists
    if (widget.item is PlexPlaylist) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PlaylistDetailScreen(playlist: widget.item as PlexPlaylist),
        ),
      );
      return;
    }

    final itemType = widget.item.type.toLowerCase();

    // Handle collections
    if (itemType == 'collection') {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => CollectionDetailScreen(collection: widget.item),
        ),
      );

      // If collection was deleted, refresh the parent list
      if (result == true && mounted) {
        widget.onListRefresh?.call();
      }
      return;
    }

    // Music content is not yet supported
    if (itemType == 'artist' || itemType == 'album' || itemType == 'track') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.messages.musicNotSupported),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // For episodes, start playback directly
    if (itemType == 'episode') {
      final result = await navigateToVideoPlayer(
        context,
        metadata: widget.item,
      );
      // Refresh parent screen if result indicates it's needed
      if (result == true) {
        widget.onRefresh?.call(widget.item.ratingKey);
      }
    } else if (itemType == 'season') {
      // For seasons, show season detail screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeasonDetailScreen(season: widget.item),
        ),
      );
      // Season screen doesn't return a refresh flag, but we can refresh anyway
      widget.onRefresh?.call(widget.item.ratingKey);
    } else {
      // For all other types (shows, movies), show detail screen
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => MediaDetailScreen(metadata: widget.item),
        ),
      );
      // Refresh parent screen if result indicates it's needed
      if (result == true) {
        widget.onRefresh?.call(widget.item.ratingKey);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final viewMode = widget.forceGridMode
        ? ViewMode.grid
        : settingsProvider.viewMode;

    final semanticLabel = _buildSemanticLabel();

    final cardWidget = viewMode == ViewMode.grid
        ? _MediaCardGrid(
            item: widget.item,
            width: widget.width,
            height: widget.height,
            semanticLabel: semanticLabel,
            onTap: () => _handleTap(context),
            onLongPress: _showContextMenu,
            focusNode: widget.focusNode,
            hubId: widget.hubId,
            itemIndex: widget.itemIndex,
          )
        : _MediaCardList(
            item: widget.item,
            semanticLabel: semanticLabel,
            onTap: () => _handleTap(context),
            onLongPress: _showContextMenu,
            density: settingsProvider.libraryDensity,
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
class _MediaCardGrid extends StatefulWidget {
  final dynamic item; // Can be PlexMetadata or PlexPlaylist
  final double? width;
  final double? height;
  final String semanticLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// External FocusNode for hub navigation (provided by HubSection)
  final FocusNode? focusNode;

  /// Hub section ID for focus memory tracking
  final String? hubId;

  /// Item index within the hub section
  final int? itemIndex;

  const _MediaCardGrid({
    required this.item,
    this.width,
    this.height,
    required this.semanticLabel,
    required this.onTap,
    required this.onLongPress,
    this.focusNode,
    this.hubId,
    this.itemIndex,
  });

  @override
  State<_MediaCardGrid> createState() => _MediaCardGridState();
}

class _MediaCardGridState extends State<_MediaCardGrid>
    with KeyboardLongPressMixin {
  FocusNode? _ownFocusNode;
  bool _isFocused = false;

  @override
  void onKeyboardTap() => widget.onTap();

  @override
  void onKeyboardLongPress() => widget.onLongPress();

  /// Returns the effective focus node (external if provided, otherwise our own)
  FocusNode get _focusNode {
    if (widget.focusNode != null) return widget.focusNode!;
    _ownFocusNode ??= FocusNode();
    return _ownFocusNode!;
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(_MediaCardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If focusNode changed, update listener
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    // Only dispose if we created the node
    _ownFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_focusNode.hasFocus) {
        // Update focus memory if we're in a hub section
        if (widget.hubId != null && widget.itemIndex != null) {
          final controller = HubNavigationScope.maybeOf(context);
          controller?.rememberFocusedIndex(widget.hubId!, widget.itemIndex!);
        }

        // Scroll to center only if item is not fully visible
        _scrollToCenterIfNeeded();
      }
    }
  }

  /// Scrolls to center the item only if it's not already fully visible.
  /// This prevents unnecessary scrolling when navigating horizontally
  /// within the same row while still centering when scrolling is needed.
  void _scrollToCenterIfNeeded() {
    // For hub sections (nested scrollables), use simple centering
    // The smart scroll logic doesn't work well with horizontal+vertical nesting
    if (widget.hubId != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    // For non-hub contexts (like library browse), use smart scrolling
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      // Fallback to simple centering
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final renderObject = context.findRenderObject();
    if (renderObject == null || renderObject is! RenderBox) return;

    final box = renderObject;
    final scrollRenderObject = scrollable.context.findRenderObject();
    if (scrollRenderObject == null) return;

    // Get item's position relative to the scroll view
    final transform = box.getTransformTo(scrollRenderObject);
    final itemRect = MatrixUtils.transformRect(
      transform,
      Offset.zero & box.size,
    );

    // Get viewport bounds
    final position = scrollable.position;
    final viewportHeight = position.viewportDimension;

    // Check if item is fully visible (with margin for focus indicator)
    const focusMargin = 4.0;
    final isFullyVisible =
        itemRect.top >= focusMargin &&
        itemRect.bottom <= viewportHeight - focusMargin;

    if (!isFullyVisible) {
      // Item is not fully visible, scroll to center it
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Handle long-press detection for activation keys
    final longPressResult = handleKeyboardLongPress(event);
    if (longPressResult == KeyEventResult.handled) {
      return longPressResult;
    }

    if (event is KeyDownEvent) {
      // Handle up/down for hub navigation
      if (widget.hubId != null) {
        final controller = HubNavigationScope.maybeOf(context);
        if (controller != null) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            if (controller.navigateToAdjacentHub(widget.hubId!, -1)) {
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (controller.navigateToAdjacentHub(widget.hubId!, 1)) {
              return KeyEventResult.handled;
            }
          }
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: FocusIndicator(
        isFocused: _isFocused,
        borderRadius: 8,
        child: SizedBox(
          width: widget.width,
          child: Semantics(
            label: widget.semanticLabel,
            button: true,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(8),
              focusColor: Colors.transparent, // We use our own focus indicator
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster
                    if (widget.height != null)
                      SizedBox(
                        width: double.infinity,
                        height: widget.height,
                        child: _buildPosterWithOverlay(context),
                      )
                    else
                      Expanded(child: _buildPosterWithOverlay(context)),
                    const SizedBox(height: 4),
                    // Text content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          widget.item is PlexPlaylist
                              ? (widget.item as PlexPlaylist).title
                              : (widget.item as PlexMetadata).displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.1,
                          ),
                        ),
                        if (widget.item is PlexPlaylist)
                          Builder(
                            builder: (context) {
                              final playlist = widget.item as PlexPlaylist;
                              if (playlist.leafCount != null &&
                                  playlist.leafCount! > 0) {
                                return Text(
                                  t.playlists.itemCount(
                                    count: playlist.leafCount!,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: tokens(context).textMuted,
                                        fontSize: 11,
                                        height: 1.1,
                                      ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          )
                        else if (widget.item is PlexMetadata) ...[
                          Builder(
                            builder: (context) {
                              final metadata = widget.item as PlexMetadata;

                              // For collections, show item count
                              if (metadata.type.toLowerCase() == 'collection') {
                                final count =
                                    metadata.childCount ?? metadata.leafCount;
                                if (count != null && count > 0) {
                                  return Text(
                                    t.playlists.itemCount(count: count),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: tokens(context).textMuted,
                                          fontSize: 11,
                                          height: 1.1,
                                        ),
                                  );
                                }
                              }

                              // For other media types, show subtitle/parent/year
                              if (metadata.displaySubtitle != null) {
                                return Text(
                                  metadata.displaySubtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: tokens(context).textMuted,
                                        fontSize: 11,
                                        height: 1.1,
                                      ),
                                );
                              } else if (metadata.parentTitle != null) {
                                return Text(
                                  metadata.parentTitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: tokens(context).textMuted,
                                        fontSize: 11,
                                        height: 1.1,
                                      ),
                                );
                              } else if (metadata.year != null) {
                                return Text(
                                  '${metadata.year}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: tokens(context).textMuted,
                                        fontSize: 11,
                                        height: 1.1,
                                      ),
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosterWithOverlay(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildPosterImage(context, widget.item),
        ),
        _PosterOverlay(item: widget.item),
      ],
    );
  }
}

/// List layout for media cards
class _MediaCardList extends StatefulWidget {
  final dynamic item; // Can be PlexMetadata or PlexPlaylist
  final String semanticLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final LibraryDensity density;

  const _MediaCardList({
    required this.item,
    required this.semanticLabel,
    required this.onTap,
    required this.onLongPress,
    required this.density,
  });

  @override
  State<_MediaCardList> createState() => _MediaCardListState();
}

class _MediaCardListState extends State<_MediaCardList>
    with KeyboardLongPressMixin {
  @override
  void onKeyboardTap() => widget.onTap();

  @override
  void onKeyboardLongPress() => widget.onLongPress();

  /// Scrolls to center the item only if it's not already fully visible.
  /// This prevents unnecessary scrolling when navigating horizontally
  /// within the same row while still centering when scrolling is needed.
  void _scrollToCenterIfNeeded(BuildContext ctx) {
    final scrollable = Scrollable.maybeOf(ctx);
    if (scrollable == null) {
      // Fallback to simple centering
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final renderObject = ctx.findRenderObject();
    if (renderObject == null || renderObject is! RenderBox) return;

    final box = renderObject;
    final scrollRenderObject = scrollable.context.findRenderObject();
    if (scrollRenderObject == null) return;

    // Get item's position relative to the scroll view
    final transform = box.getTransformTo(scrollRenderObject);
    final itemRect = MatrixUtils.transformRect(
      transform,
      Offset.zero & box.size,
    );

    // Get viewport bounds
    final position = scrollable.position;
    final viewportHeight = position.viewportDimension;

    // Check if item is fully visible (with margin for focus indicator)
    const focusMargin = 4.0;
    final isFullyVisible =
        itemRect.top >= focusMargin &&
        itemRect.bottom <= viewportHeight - focusMargin;

    if (!isFullyVisible) {
      // Item is not fully visible, scroll to center it
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  double get _posterWidth {
    switch (widget.density) {
      case LibraryDensity.compact:
        return 80;
      case LibraryDensity.normal:
        return 100;
      case LibraryDensity.comfortable:
        return 120;
    }
  }

  double get _posterHeight {
    return _posterWidth * 1.5; // Maintain 2:3 aspect ratio
  }

  double get _titleFontSize {
    switch (widget.density) {
      case LibraryDensity.compact:
        return 14;
      case LibraryDensity.normal:
        return 15;
      case LibraryDensity.comfortable:
        return 16;
    }
  }

  double get _metadataFontSize {
    switch (widget.density) {
      case LibraryDensity.compact:
        return 11;
      case LibraryDensity.normal:
        return 12;
      case LibraryDensity.comfortable:
        return 13;
    }
  }

  double get _subtitleFontSize {
    switch (widget.density) {
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
    switch (widget.density) {
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

    if (widget.item is PlexPlaylist) {
      final playlist = widget.item as PlexPlaylist;
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
    } else if (widget.item is PlexMetadata) {
      final metadata = widget.item as PlexMetadata;

      // For collections, show item count
      if (metadata.type.toLowerCase() == 'collection') {
        final count = metadata.childCount ?? metadata.leafCount;
        if (count != null && count > 0) {
          parts.add(t.playlists.itemCount(count: count));
        }
      } else {
        // For other media types, show standard metadata
        // Add content rating
        if (metadata.contentRating != null &&
            metadata.contentRating!.isNotEmpty) {
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
    if (widget.item is PlexPlaylist) {
      // Playlists don't have subtitles
      return null;
    } else if (widget.item is PlexMetadata) {
      final metadata = widget.item as PlexMetadata;

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

    return FocusableWrapper(
      onKeyEvent: (node, event) => handleKeyboardLongPress(event),
      onScrollIntoView: _scrollToCenterIfNeeded,
      builder: (context, isFocused) => FocusIndicator(
        isFocused: isFocused,
        borderRadius: 8,
        child: Semantics(
          label: widget.semanticLabel,
          button: true,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            focusColor: Colors.transparent, // We use our own focus indicator
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster (responsive size based on density)
                  SizedBox(
                    width: _posterWidth,
                    height: _posterHeight,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildPosterImage(context, widget.item),
                        ),
                        _PosterOverlay(item: widget.item),
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
                          widget.item.displayTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: _titleFontSize,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Metadata info line (rating, duration, score, studio)
                        if (metadataLine.isNotEmpty) ...[
                          Text(
                            metadataLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: tokens(
                                    context,
                                  ).textMuted.withValues(alpha: 0.9),
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: tokens(
                                    context,
                                  ).textMuted.withValues(alpha: 0.85),
                                  fontSize: _subtitleFontSize,
                                ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        // Summary
                        if (widget.item.summary != null) ...[
                          Text(
                            widget.item.summary!,
                            maxLines: _summaryMaxLines,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: tokens(
                                    context,
                                  ).textMuted.withValues(alpha: 0.7),
                                  fontSize: _summaryFontSize,
                                  height: 1.3,
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
        ),
      ),
    );
  }
}

/// Helper to get the correct PlexClient for an item's server
PlexClient _getClientForItem(BuildContext context, dynamic item) {
  String? serverId;

  if (item is PlexMetadata) {
    serverId = item.serverId;
  } else if (item is PlexPlaylist) {
    serverId = item.serverId;
  }

  // If serverId is null, fall back to first available server
  if (serverId == null) {
    final multiServerProvider = Provider.of<MultiServerProvider>(
      context,
      listen: false,
    );
    if (!multiServerProvider.hasConnectedServers) {
      throw Exception('No servers available');
    }
    serverId = multiServerProvider.onlineServerIds.first;
  }

  return context.getClientForServer(serverId);
}

Widget _buildPosterImage(BuildContext context, dynamic item) {
  String? posterUrl;
  IconData fallbackIcon = Icons.movie;

  if (item is PlexPlaylist) {
    posterUrl = item.displayImage;
    fallbackIcon = Icons.playlist_play;
  } else if (item is PlexMetadata) {
    final useSeasonPoster = context.watch<SettingsProvider>().useSeasonPoster;
    posterUrl = item.posterThumb(useSeasonPoster: useSeasonPoster);
  }

  if (posterUrl != null) {
    return Builder(
      builder: (context) {
        final client = _getClientForItem(context, item);

        return CachedNetworkImage(
          imageUrl: client.getThumbnailUrl(posterUrl!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          filterQuality: FilterQuality.medium,
          fadeInDuration: const Duration(milliseconds: 300),
          placeholder: (context, url) => const SkeletonLoader(),
          errorWidget: (context, url, error) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(child: Icon(fallbackIcon, size: 40)),
          ),
        );
      },
    );
  } else {
    return SkeletonLoader(
      child: Center(child: Icon(fallbackIcon, size: 40, color: Colors.white54)),
    );
  }
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

    final metadata = item as PlexMetadata;

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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(Icons.check, color: tokens(context).bg, size: 16),
            ),
          ),
        // Progress bar for partially watched content
        if (metadata.viewOffset != null &&
            metadata.duration != null &&
            metadata.viewOffset! > 0 &&
            !metadata.isWatched)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: LinearProgressIndicator(
                value: metadata.viewOffset! / metadata.duration!,
                backgroundColor: tokens(context).outline,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
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

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest
                  .withValues(alpha: _animation.value),
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
