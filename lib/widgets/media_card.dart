import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/plex_metadata.dart';
import '../providers/plex_client_provider.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../utils/content_rating_formatter.dart';
import '../utils/platform_detector.dart';
import '../utils/tv_ui_helper.dart';
import '../screens/media_detail_screen.dart';
import '../screens/season_detail_screen.dart';
import '../theme/theme_helper.dart';
import '../i18n/strings.g.dart';
import 'media_context_menu.dart';

class MediaCard extends StatefulWidget {
  final PlexMetadata item;
  final double? width;
  final double? height;
  final void Function(String ratingKey)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final bool forceGridMode;
  final bool isInContinueWatching;

  const MediaCard({
    super.key,
    required this.item,
    this.width,
    this.height,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.forceGridMode = false,
    this.isInContinueWatching = false,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  VoidCallback? _showContextMenu;

  void _handleTap(BuildContext context) async {
    final client = context.client;
    if (client == null) return;

    final itemType = widget.item.type.toLowerCase();

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

    return MediaContextMenu(
      metadata: widget.item,
      onRefresh: widget.onRefresh,
      onRemoveFromContinueWatching: widget.onRemoveFromContinueWatching,
      onTap: () => _handleTap(context),
      isInContinueWatching: widget.isInContinueWatching,
      onMenuReady: (showMenu) => _showContextMenu = showMenu,
      child: viewMode == ViewMode.grid
          ? _MediaCardGrid(
              item: widget.item,
              width: widget.width,
              height: widget.height,
              onTap: () => _handleTap(context),
              showContextMenu: () => _showContextMenu?.call(),
            )
          : _MediaCardList(
              item: widget.item,
              onTap: () => _handleTap(context),
              density: settingsProvider.libraryDensity,
            ),
    );
  }
}

/// Grid layout for media cards
class _MediaCardGrid extends StatefulWidget {
  final PlexMetadata item;
  final double? width;
  final double? height;
  final VoidCallback onTap;
  final VoidCallback? showContextMenu;

  const _MediaCardGrid({
    required this.item,
    this.width,
    this.height,
    required this.onTap,
    this.showContextMenu,
  });

  @override
  State<_MediaCardGrid> createState() => _MediaCardGridState();
}

class _MediaCardGridState extends State<_MediaCardGrid> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isLongPressTriggered = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    // Ensure the focused card is visible on TV
    if (_isFocused && PlatformDetector.isTVSync() && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5, // Center the item
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTV = PlatformDetector.isTVSync();

    return SizedBox(
      width: widget.width,
      child: Semantics(
        label: "media-card-${widget.item.ratingKey}",
        identifier: "media-card-${widget.item.ratingKey}",
        button: true,
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: (node, event) {
            if (!isTV) return KeyEventResult.ignored;

            final isOkButton =
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter;

            if (isOkButton) {
              if (event is KeyDownEvent) {
                // Reset flag on initial key down
                _isLongPressTriggered = false;
                return KeyEventResult.handled;
              } else if (event is KeyRepeatEvent) {
                // Key is being held down - trigger long press action once
                if (!_isLongPressTriggered) {
                  _isLongPressTriggered = true;
                  widget.showContextMenu?.call();
                }
                return KeyEventResult.handled;
              } else if (event is KeyUpEvent) {
                // Key released - if no long press was triggered, do short press
                if (!_isLongPressTriggered) {
                  widget.onTap();
                }
                // Reset for next interaction
                _isLongPressTriggered = false;
                return KeyEventResult.handled;
              }
            }

            return KeyEventResult.ignored;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: _isFocused && isTV
                  ? [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Theme.of(context).colorScheme.primary,
                        spreadRadius: 2,
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onTap,
              child: Padding(
                padding: TVUIHelper.getCardPadding(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                    // Text content
                    Text(
                      widget.item.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: TVUIHelper.getFontSize(12),
                        height: 1.0,
                      ),
                    ),
                    if (widget.item.displaySubtitle != null)
                      Text(
                        widget.item.displaySubtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens(context).textMuted,
                          fontSize: TVUIHelper.getFontSize(10),
                          height: 1.0,
                        ),
                      )
                    else if (widget.item.parentTitle != null)
                      Text(
                        widget.item.parentTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens(context).textMuted,
                          fontSize: TVUIHelper.getFontSize(10),
                          height: 1.0,
                        ),
                      )
                    else if (widget.item.year != null)
                      Text(
                        '${widget.item.year}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens(context).textMuted,
                          fontSize: TVUIHelper.getFontSize(10),
                          height: 1.0,
                        ),
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
          child: _buildPosterImage(context),
        ),
        _PosterOverlay(item: widget.item),
      ],
    );
  }

  Widget _buildPosterImage(BuildContext context) {
    final useSeasonPoster = context.watch<SettingsProvider>().useSeasonPoster;
    final posterUrl = widget.item.posterThumb(useSeasonPoster: useSeasonPoster);
    if (posterUrl != null) {
      return Consumer<PlexClientProvider>(
        builder: (context, clientProvider, child) {
          final client = clientProvider.client;
          if (client == null) {
            return const SkeletonLoader(
              child: Center(
                child: Icon(Icons.movie, size: 40, color: Colors.white54),
              ),
            );
          }

          return CachedNetworkImage(
            imageUrl: client.getThumbnailUrl(posterUrl),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.medium,
            fadeInDuration: const Duration(milliseconds: 300),
            placeholder: (context, url) => const SkeletonLoader(),
            errorWidget: (context, url, error) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: Icon(Icons.broken_image, size: 40)),
            ),
          );
        },
      );
    } else {
      return const SkeletonLoader(
        child: Center(
          child: Icon(Icons.movie, size: 40, color: Colors.white54),
        ),
      );
    }
  }
}

/// List layout for media cards
class _MediaCardList extends StatelessWidget {
  final PlexMetadata item;
  final VoidCallback onTap;
  final LibraryDensity density;

  const _MediaCardList({
    required this.item,
    required this.onTap,
    required this.density,
  });

  double get _posterWidth {
    switch (density) {
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
    switch (density) {
      case LibraryDensity.compact:
        return 11;
      case LibraryDensity.normal:
        return 12;
      case LibraryDensity.comfortable:
        return 13;
    }
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

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _buildMetadataLine() {
    final parts = <String>[];

    // Add content rating
    if (item.contentRating != null && item.contentRating!.isNotEmpty) {
      final rating = formatContentRating(item.contentRating);
      if (rating.isNotEmpty) {
        parts.add(rating);
      }
    }

    // Add year
    if (item.year != null) {
      parts.add('${item.year}');
    }

    // Add duration
    if (item.duration != null) {
      parts.add(_formatDuration(item.duration!));
    }

    // Add user rating
    if (item.rating != null) {
      parts.add('${item.rating!.toStringAsFixed(1)}★');
    }

    // Add studio
    if (item.studio != null && item.studio!.isNotEmpty) {
      parts.add(item.studio!);
    }

    return parts.join(' • ');
  }

  String? _buildSubtitleText() {
    // For TV episodes, show S#E# format
    if (item.parentIndex != null && item.index != null) {
      return 'S${item.parentIndex} E${item.index}';
    }

    // Otherwise use existing subtitle logic
    if (item.displaySubtitle != null) {
      return item.displaySubtitle;
    } else if (item.parentTitle != null) {
      return item.parentTitle;
    }

    // Year is now shown in metadata line, so don't show it here
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final metadataLine = _buildMetadataLine();
    final subtitle = _buildSubtitleText();

    return Semantics(
      label: "media-card-${item.ratingKey}",
      identifier: "media-card-${item.ratingKey}",
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
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
                      child: _buildPosterImage(context),
                    ),
                    _PosterOverlay(item: item),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens(
                            context,
                          ).textMuted.withValues(alpha: 0.85),
                          fontSize: _subtitleFontSize,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Summary
                    if (item.summary != null) ...[
                      Text(
                        item.summary!,
                        maxLines: _summaryMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }

  Widget _buildPosterImage(BuildContext context) {
    final useSeasonPoster = context.watch<SettingsProvider>().useSeasonPoster;
    final posterUrl = item.posterThumb(useSeasonPoster: useSeasonPoster);
    if (posterUrl != null) {
      return Consumer<PlexClientProvider>(
        builder: (context, clientProvider, child) {
          final client = clientProvider.client;
          if (client == null) {
            return const SkeletonLoader(
              child: Center(
                child: Icon(Icons.movie, size: 40, color: Colors.white54),
              ),
            );
          }

          return CachedNetworkImage(
            imageUrl: client.getThumbnailUrl(posterUrl),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.medium,
            fadeInDuration: const Duration(milliseconds: 300),
            placeholder: (context, url) => const SkeletonLoader(),
            errorWidget: (context, url, error) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: Icon(Icons.broken_image, size: 40)),
            ),
          );
        },
      );
    } else {
      return const SkeletonLoader(
        child: Center(
          child: Icon(Icons.movie, size: 40, color: Colors.white54),
        ),
      );
    }
  }
}

/// Overlay widget for poster showing watched indicator and progress bar
class _PosterOverlay extends StatelessWidget {
  final PlexMetadata item;

  const _PosterOverlay({required this.item});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Watched indicator (checkmark)
        if (item.isWatched)
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
        if (item.viewOffset != null &&
            item.duration != null &&
            item.viewOffset! > 0 &&
            !item.isWatched)
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
                value: item.viewOffset! / item.duration!,
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
