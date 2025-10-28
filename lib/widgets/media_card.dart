import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../client/plex_client.dart';
import '../models/plex_metadata.dart';
import '../models/plex_user_profile.dart';
import '../screens/media_detail_screen.dart';
import '../screens/season_detail_screen.dart';
import '../screens/video_player_screen.dart';
import 'media_context_menu.dart';

class MediaCard extends StatefulWidget {
  final PlexClient client;
  final PlexMetadata item;
  final double? width;
  final double? height;
  final VoidCallback? onRefresh;
  final PlexUserProfile? userProfile;

  const MediaCard({
    super.key,
    required this.client,
    required this.item,
    this.width,
    this.height,
    this.onRefresh,
    this.userProfile,
  });

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  void _handleTap(BuildContext context) async {
    final itemType = widget.item.type.toLowerCase();

    // For episodes, start playback directly
    if (itemType == 'episode') {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            client: widget.client,
            metadata: widget.item,
            userProfile: widget.userProfile,
          ),
        ),
      );
      // Refresh parent screen if result indicates it's needed
      if (result == true) {
        widget.onRefresh?.call();
      }
    } else if (itemType == 'season') {
      // For seasons, show season detail screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeasonDetailScreen(
            client: widget.client,
            season: widget.item,
            userProfile: widget.userProfile,
          ),
        ),
      );
      // Season screen doesn't return a refresh flag, but we can refresh anyway
      widget.onRefresh?.call();
    } else {
      // For all other types (shows, movies), show detail screen
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => MediaDetailScreen(
            client: widget.client,
            metadata: widget.item,
            userProfile: widget.userProfile,
          ),
        ),
      );
      // Refresh parent screen if result indicates it's needed
      if (result == true) {
        widget.onRefresh?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: MediaContextMenu(
        client: widget.client,
        metadata: widget.item,
        onRefresh: widget.onRefresh,
        onTap: () => _handleTap(context),
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
                  Expanded(
                    child: _buildPosterWithOverlay(context),
                  ),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontSize: 11,
                          height: 1.1,
                        ),
                      )
                    else if (widget.item.parentTitle != null)
                      Text(
                        widget.item.parentTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontSize: 11,
                          height: 1.1,
                        ),
                      )
                    else if (widget.item.year != null)
                      Text(
                        '${widget.item.year}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
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
      return CachedNetworkImage(
        imageUrl: widget.client.getThumbnailUrl(widget.item.posterThumb),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.medium,
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        errorWidget: (context, url, error) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.broken_image, size: 40)),
        ),
      );
    } else {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.movie, size: 40)),
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
        // Watched indicator (green checkmark)
        if (item.isWatched)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
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
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                minHeight: 4,
              ),
            ),
          ),
      ],
    );
  }
}
