import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/plex_metadata.dart';
import '../models/plex_playlist.dart';
import '../providers/plex_client_provider.dart';
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
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  void _handleTap(BuildContext context) async {
    final client = context.client;
    if (client == null) return;

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

    final cardWidget = viewMode == ViewMode.grid
        ? _MediaCardGrid(
            item: widget.item,
            width: widget.width,
            height: widget.height,
            onTap: () => _handleTap(context),
          )
        : _MediaCardList(
            item: widget.item,
            onTap: () => _handleTap(context),
            density: settingsProvider.libraryDensity,
          );

    // Use context menu for both PlexMetadata and PlexPlaylist items
    return MediaContextMenu(
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
  final VoidCallback onTap;

  const _MediaCardGrid({
    required this.item,
    this.width,
    this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Semantics(
        label: "media-card-${item.ratingKey}",
        identifier: "media-card-${item.ratingKey}",
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster
                if (height != null)
                  SizedBox(
                    width: double.infinity,
                    height: height,
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
                      item is PlexPlaylist
                          ? (item as PlexPlaylist).title
                          : (item as PlexMetadata).displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.1,
                      ),
                    ),
                    if (item is PlexPlaylist)
                      Builder(
                        builder: (context) {
                          final playlist = item as PlexPlaylist;
                          if (playlist.leafCount != null &&
                              playlist.leafCount! > 0) {
                            return Text(
                              t.playlists.itemCount(count: playlist.leafCount!),
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
                    else if (item is PlexMetadata) ...[
                      Builder(
                        builder: (context) {
                          final metadata = item as PlexMetadata;

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
    );
  }

  Widget _buildPosterWithOverlay(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildPosterImage(context, item),
        ),
        _PosterOverlay(item: item),
      ],
    );
  }
}

/// List layout for media cards
class _MediaCardList extends StatelessWidget {
  final dynamic item; // Can be PlexMetadata or PlexPlaylist
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

    return Semantics(
      label: "media-card-${item.ratingKey}",
      identifier: "media-card-${item.ratingKey}",
      button: true,
      child: InkWell(
        onTap: onTap,
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
                      child: _buildPosterImage(context, item),
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
}

Widget _buildPosterImage(BuildContext context, dynamic item) {
  String? posterUrl;
  IconData fallbackIcon = Icons.movie;

  if (item is PlexPlaylist) {
    posterUrl = (item as PlexPlaylist).displayImage;
    fallbackIcon = Icons.playlist_play;
  } else if (item is PlexMetadata) {
    final useSeasonPoster = context.watch<SettingsProvider>().useSeasonPoster;
    posterUrl = (item as PlexMetadata).posterThumb(
      useSeasonPoster: useSeasonPoster,
    );
  }

  if (posterUrl != null) {
    return Consumer<PlexClientProvider>(
      builder: (context, clientProvider, child) {
        final client = clientProvider.client;
        if (client == null) {
          return SkeletonLoader(
            child: Center(
              child: Icon(fallbackIcon, size: 40, color: Colors.white54),
            ),
          );
        }

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
