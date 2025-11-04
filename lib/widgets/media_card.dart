import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/plex_metadata.dart';
import '../providers/plex_client_provider.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../screens/media_detail_screen.dart';
import '../screens/season_detail_screen.dart';
import '../theme/theme_helper.dart';
import 'media_context_menu.dart';

class MediaCard extends StatefulWidget {
  final PlexMetadata item;
  final double? width;
  final double? height;
  final void Function(String ratingKey)? onRefresh;

  const MediaCard({
    super.key,
    required this.item,
    this.width,
    this.height,
    this.onRefresh,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  void _handleTap(BuildContext context) async {
    final client = context.client;
    if (client == null) return;

    final itemType = widget.item.type.toLowerCase();

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
    return SizedBox(
      width: widget.width,
      child: MediaContextMenu(
        metadata: widget.item,
        onRefresh: widget.onRefresh,
        onTap: () => _handleTap(context),
        child: Semantics(
          label: "media-card-${widget.item.ratingKey}",
          identifier: "media-card-${widget.item.ratingKey}",
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
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
                        widget.item.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.1,
                        ),
                      ),
                      if (widget.item.displaySubtitle != null)
                        Text(
                          widget.item.displaySubtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: tokens(context).textMuted,
                                fontSize: 11,
                                height: 1.1,
                              ),
                        )
                      else if (widget.item.parentTitle != null)
                        Text(
                          widget.item.parentTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: tokens(context).textMuted,
                                fontSize: 11,
                                height: 1.1,
                              ),
                        )
                      else if (widget.item.year != null)
                        Text(
                          '${widget.item.year}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: tokens(context).textMuted,
                                fontSize: 11,
                                height: 1.1,
                              ),
                        ),
                    ],
                  ),
                ],
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
    if (widget.item.posterThumb != null) {
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
            imageUrl: client.getThumbnailUrl(widget.item.posterThumb),
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
