import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/plex_client.dart';
import '../utils/plex_image_helper.dart';
import 'media_card.dart';

class PlexOptimizedImage extends StatelessWidget {
  final PlexClient client;
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Duration fadeInDuration;
  final bool enableTranscoding;
  final String? cacheKey;
  final Alignment alignment;
  final IconData? fallbackIcon;
  final ImageType imageType;

  const PlexOptimizedImage({
    super.key,
    required this.client,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.medium,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.enableTranscoding = true,
    this.cacheKey,
    this.alignment = Alignment.center,
    this.fallbackIcon,
    this.imageType = ImageType.poster,
  });

  @override
  Widget build(BuildContext context) {
    double resolvedDimension(
      double? explicit,
      double constraintMax,
      double fallback,
    ) {
      // Pick the explicit size when it's a finite positive number, otherwise
      // fall back to the constraint or a sensible default so we don't end up
      // with NaN/Infinity when rounding to ints for caching.
      final candidate =
          explicit ??
          (constraintMax.isFinite && constraintMax > 0
              ? constraintMax
              : fallback);
      if (candidate.isNaN || candidate.isInfinite || candidate <= 0) {
        return fallback;
      }
      return candidate;
    }

    // Return empty container if no image path
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildFallback(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

        // Calculate effective constraints with safe fallbacks
        final effectiveWidth = resolvedDimension(
          width,
          constraints.maxWidth,
          300.0,
        );
        final effectiveHeight = resolvedDimension(
          height,
          constraints.maxHeight,
          450.0,
        );

        // Get optimized image URL
        final imageUrl = PlexImageHelper.getOptimizedImageUrl(
          client: client,
          thumbPath: imagePath,
          maxWidth: effectiveWidth,
          maxHeight: effectiveHeight,
          devicePixelRatio: devicePixelRatio,
          enableTranscoding:
              enableTranscoding && PlexImageHelper.shouldTranscode(imagePath),
          imageType: imageType,
        );

        if (imageUrl.isEmpty) {
          return _buildFallback(context);
        }

        // Calculate memory cache dimensions
        final scaledWidth = effectiveWidth * devicePixelRatio;
        final scaledHeight = effectiveHeight * devicePixelRatio;
        final (memWidth, memHeight) = PlexImageHelper.getMemCacheDimensions(
          displayWidth: scaledWidth.isFinite && scaledWidth > 0
              ? scaledWidth.round()
              : 0,
          displayHeight: scaledHeight.isFinite && scaledHeight > 0
              ? scaledHeight.round()
              : 0,
        );

        // Generate cache key if not provided
        final effectiveCacheKey =
            cacheKey ?? _generateCacheKey(imageUrl, memWidth, memHeight);

        return CachedNetworkImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: fit,
          filterQuality: filterQuality,
          alignment: alignment,
          fadeInDuration: fadeInDuration,
          memCacheWidth: memWidth,
          memCacheHeight: memHeight,
          cacheKey: effectiveCacheKey,
          placeholder: placeholder != null
              ? placeholder!
              : (context, url) => _buildPlaceholder(context),
          errorWidget: errorWidget != null
              ? errorWidget!
              : (context, url, error) => _buildErrorWidget(context, error),
          httpHeaders: {'User-Agent': 'Plezy Flutter Client'},
        );
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return SkeletonLoader(
      child: fallbackIcon != null
          ? Center(child: Icon(fallbackIcon!, size: 40, color: Colors.white54))
          : null,
    );
  }

  Widget _buildErrorWidget(BuildContext context, dynamic error) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          fallbackIcon ?? Icons.broken_image,
          size: 40,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          fallbackIcon ?? Icons.image_not_supported,
          size: 40,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String _generateCacheKey(String imageUrl, int memWidth, int memHeight) {
    final urlHash = imageUrl.hashCode;
    return 'plex_optimized_${memWidth}x${memHeight}_$urlHash';
  }
}

/// Specialized version for posters with default fallback icon
class PlexPosterImage extends PlexOptimizedImage {
  const PlexPosterImage({
    super.key,
    required super.client,
    required super.imagePath,
    super.width,
    super.height,
    super.fit = BoxFit.cover,
    super.filterQuality = FilterQuality.medium,
    super.placeholder,
    super.errorWidget,
    super.fadeInDuration = const Duration(milliseconds: 300),
    super.enableTranscoding = true,
    super.cacheKey,
    super.alignment = Alignment.center,
  }) : super(fallbackIcon: Icons.movie, imageType: ImageType.poster);
}

/// Specialized version for episode thumbnails
class PlexThumbImage extends PlexOptimizedImage {
  const PlexThumbImage({
    super.key,
    required super.client,
    required super.imagePath,
    super.width,
    super.height,
    super.fit = BoxFit.cover,
    super.filterQuality = FilterQuality.medium,
    super.placeholder,
    super.errorWidget,
    super.fadeInDuration = const Duration(milliseconds: 300),
    super.enableTranscoding = true,
    super.cacheKey,
    super.alignment = Alignment.center,
  }) : super(fallbackIcon: Icons.video_library, imageType: ImageType.thumb);
}

/// Specialized version for playlist images
class PlexPlaylistImage extends PlexOptimizedImage {
  const PlexPlaylistImage({
    super.key,
    required super.client,
    required super.imagePath,
    super.width,
    super.height,
    super.fit = BoxFit.cover,
    super.filterQuality = FilterQuality.medium,
    super.placeholder,
    super.errorWidget,
    super.fadeInDuration = const Duration(milliseconds: 300),
    super.enableTranscoding = true,
    super.cacheKey,
    super.alignment = Alignment.center,
  }) : super(fallbackIcon: Icons.playlist_play, imageType: ImageType.poster);
}
