import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/plex_metadata.dart';
import '../providers/plex_client_provider.dart';
import '../i18n/strings.g.dart';

/// Custom list item widget for playlist items
/// Shows drag handle, poster, title/metadata, duration, and remove button
class PlaylistItemCard extends StatelessWidget {
  final PlexMetadata item;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback? onTap;
  final bool canReorder; // Whether drag handle should be shown

  const PlaylistItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
    this.onTap,
    this.canReorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Drag handle (if reorderable)
              if (canReorder)
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.drag_indicator, color: Colors.grey),
                  ),
                ),

              // Poster thumbnail
              _buildPosterImage(context),

              const SizedBox(width: 12),

              // Title and metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      item.displayTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Subtitle (episode info or type)
                    Text(
                      _buildSubtitle(),
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Progress indicator if partially watched
                    if (item.viewOffset != null && item.duration != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: LinearProgressIndicator(
                          value: item.viewOffset! / item.duration!,
                          backgroundColor: Colors.grey[800],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 3,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Duration
              if (item.duration != null)
                Text(
                  _formatDuration(item.duration!),
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),

              const SizedBox(width: 8),

              // Remove button
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onRemove,
                tooltip: t.playlists.removeItem,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPosterImage(BuildContext context) {
    final posterUrl = item.posterThumb();
    if (posterUrl != null) {
      return Consumer<PlexClientProvider>(
        builder: (context, clientProvider, child) {
          final client = clientProvider.client;
          if (client == null) {
            return _buildPlaceholder();
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: client.getThumbnailUrl(posterUrl),
              width: 60,
              height: 90,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildPlaceholder(),
              errorWidget: (context, url, error) => _buildPlaceholder(),
            ),
          );
        },
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.movie, color: Colors.grey, size: 24),
    );
  }

  String _buildSubtitle() {
    final itemType = item.type.toLowerCase();

    if (itemType == 'episode') {
      // For episodes, show "S#E# - Episode Title"
      final season = item.parentIndex;
      final episode = item.index;
      if (season != null && episode != null) {
        return 'S${season}E$episode${item.displaySubtitle != null ? ' - ${item.displaySubtitle}' : ''}';
      }
      return item.displaySubtitle ?? t.discover.tvShow;
    } else if (itemType == 'movie') {
      // For movies, show year
      return item.year?.toString() ?? t.discover.movie;
    }

    // Default to type
    return item.type;
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
}
