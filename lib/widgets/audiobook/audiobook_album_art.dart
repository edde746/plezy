import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/plex_metadata.dart';
import '../../providers/plex_client_provider.dart';

/// Displays the album art for an audiobook with fallback icon
class AudiobookAlbumArt extends StatelessWidget {
  final PlexMetadata metadata;
  final double size;

  const AudiobookAlbumArt({
    super.key,
    required this.metadata,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    final clientProvider = context.watch<PlexClientProvider>();
    final client = clientProvider.client;

    // Use parent thumb (book cover) if available, otherwise use track thumb
    final thumbUrl = metadata.parentThumb ?? metadata.thumb;

    if (thumbUrl != null && client != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: client.getThumbnailUrl(thumbUrl),
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildFallback(),
            errorWidget: (context, url, error) => _buildFallback(),
          ),
        ),
      );
    } else {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: _buildFallback(),
      );
    }
  }

  Widget _buildFallback() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.headphones, size: 100, color: Colors.white30),
      ),
    );
  }
}
