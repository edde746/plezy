import 'dart:math';
import 'package:flutter/widgets.dart';
import '../services/plex_client.dart';
import 'plex_url_helper.dart';

/// Image types for different transcoding strategies
enum ImageType {
  poster, // 2:3 ratio posters
  art, // Wide background art
  thumb, // 16:9 episode thumbnails
  logo, // Variable ratio clear logos
  avatar, // Square-ish user avatars
}

class PlexImageHelper {
  static const int _widthRoundingFactor = 40;
  static const int _heightRoundingFactor = 60;

  static const int _maxTranscodedWidth = 1920;
  static const int _maxTranscodedHeight = 1080;

  static const int _minTranscodedWidth = 160;
  static const int _minTranscodedHeight = 240;

  /// Rounds dimensions to cache-friendly values to increase cache hit rate
  static (int width, int height) roundDimensions(double width, double height) {
    final roundedWidth = (width / _widthRoundingFactor).ceil() * _widthRoundingFactor;
    final roundedHeight = (height / _heightRoundingFactor).ceil() * _heightRoundingFactor;

    return (
      roundedWidth.clamp(_minTranscodedWidth, _maxTranscodedWidth),
      roundedHeight.clamp(_minTranscodedHeight, _maxTranscodedHeight),
    );
  }

  /// Computes an effective device pixel ratio that accounts for displays where
  /// the platform-reported DPR doesn't reflect the true physical density
  /// (common on Linux X11 with compositor scaling).
  static double effectiveDevicePixelRatio(BuildContext context) {
    final reportedDpr = MediaQuery.of(context).devicePixelRatio;
    try {
      final displayWidth = View.of(context).display.size.width;
      // Scale quality with display resolution: 1920px = baseline (1.0x)
      final displayBasedDpr = (displayWidth / 1920).clamp(1.0, 3.0);
      return max(reportedDpr, displayBasedDpr);
    } catch (_) {
      return reportedDpr;
    }
  }

  /// Calculates optimal image dimensions based on image type and constraints
  static (int width, int height) calculateOptimalDimensions({
    required double maxWidth,
    required double maxHeight,
    required double devicePixelRatio,
    ImageType imageType = ImageType.poster,
  }) {
    final targetWidth = maxWidth.isFinite ? maxWidth * devicePixelRatio : 300 * devicePixelRatio;
    final targetHeight = maxHeight.isFinite ? maxHeight * devicePixelRatio : 450 * devicePixelRatio;

    switch (imageType) {
      case ImageType.art:
        // For art/background images, preserve aspect ratio while covering container
        // Calculate dimensions that ensure the image covers the container without stretching
        // This mimics BoxFit.cover behavior for the transcoding request

        // Use larger dimensions to ensure coverage while preserving aspect ratio
        // This will request a slightly larger image that can be cropped by Flutter's BoxFit.cover
        final coverWidth = targetWidth * 1.1; // 10% larger for better coverage
        final coverHeight = targetHeight * 1.1;

        return roundDimensions(coverWidth, coverHeight);

      case ImageType.logo:
        // For logos, use generous bounds to avoid forcing aspect ratio
        // Prefer width-based scaling for most logos
        final logoWidth = targetWidth;
        final logoHeight = targetHeight; // Allow full height flexibility
        return roundDimensions(logoWidth, logoHeight);

      case ImageType.thumb:
        // For episode thumbs, optimize for 16:9 but allow flexibility
        final thumbHeight = targetHeight;
        final thumbWidth = min(targetWidth, thumbHeight * (16 / 9));
        return roundDimensions(thumbWidth, thumbHeight);

      case ImageType.avatar:
        // For avatars, use square dimensions based on smaller constraint
        final size = min(targetWidth, targetHeight);
        return roundDimensions(size, size);

      case ImageType.poster:
        // For posters, maintain 2:3 aspect ratio (width:height)
        final calculatedWidth = min(targetWidth, targetHeight * (2 / 3));
        final calculatedHeight = calculatedWidth * (3 / 2);
        return roundDimensions(calculatedWidth, calculatedHeight);
    }
  }

  /// Builds a Plex photo transcode URL with optimized parameters
  static String buildTranscodeUrl({
    required PlexClient client,
    required String originalPath,
    required int width,
    int? height,
  }) {
    final baseUrl = client.config.baseUrl;
    final token = client.config.token;

    // URL encode the original path with token
    final encodedPath = Uri.encodeComponent(originalPath.withPlexToken(token));

    // Build the transcode URL
    final transcodeParams = {
      'width': width.toString(),
      if (height != null) 'height': height.toString(),
      'minSize': '1', // Ensure minimum size is maintained
      'upscale': '1', // Allow upscaling for better quality
      'url': encodedPath,
      'X-Plex-Token': token,
    };

    final queryString = transcodeParams.entries.map((e) => '${e.key}=${e.value}').join('&');

    return '$baseUrl/photo/:/transcode?$queryString';
  }

  /// Creates an optimized image URL for Plex content
  /// Falls back to original URL if transcoding is not appropriate
  /// If client is null (offline mode), returns empty string for relative paths
  static String getOptimizedImageUrl({
    PlexClient? client,
    required String? thumbPath,
    required double maxWidth,
    required double maxHeight,
    required double devicePixelRatio,
    bool enableTranscoding = true,
    ImageType imageType = ImageType.poster,
  }) {
    if (thumbPath == null || thumbPath.isEmpty) {
      return '';
    }

    final basePath = thumbPath;

    // If we can't/shouldn't transcode (already a full URL), just return it.
    if (basePath.startsWith('http://') || basePath.startsWith('https://')) {
      return basePath;
    }

    // If no client (offline mode), we can't build URLs for relative paths
    // Images should already be cached from when they were originally loaded
    if (client == null) {
      return '';
    }

    final canTranscode = enableTranscoding && shouldTranscode(basePath);

    // If marked non-transcodable or transcoding disabled, use the direct thumbnail URL.
    if (!canTranscode) {
      return client.getThumbnailUrl(basePath);
    }

    // For very small images use original URL
    if (maxWidth < 80 || maxHeight < 120) {
      return client.getThumbnailUrl(basePath);
    }

    // Calculate optimal dimensions
    final (width, height) = calculateOptimalDimensions(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      devicePixelRatio: devicePixelRatio,
      imageType: imageType,
    );

    // For dimensions close to minimum, use original to avoid unnecessary processing
    if (width <= _minTranscodedWidth * 1.2 && height <= _minTranscodedHeight * 1.2) {
      return client.getThumbnailUrl(basePath);
    }

    try {
      return buildTranscodeUrl(client: client, originalPath: basePath, width: width, height: height);
    } catch (e) {
      // Fallback to original URL on any error
      return client.getThumbnailUrl(basePath);
    }
  }

  /// Generates cache-friendly dimensions for memory caching
  static (int memWidth, int memHeight) getMemCacheDimensions({
    required int displayWidth,
    required int displayHeight,
    double scaleFactor = 1.0,
  }) {
    final scaledWidth = (displayWidth * scaleFactor).round();
    final scaledHeight = (displayHeight * scaleFactor).round();

    return (scaledWidth.clamp(120, 1200), scaledHeight.clamp(180, 1800));
  }

  /// Determines if an image path is suitable for transcoding
  static bool shouldTranscode(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;

    // Don't transcode already processed images or external URLs
    if (imagePath.contains('/photo/:/transcode') ||
        imagePath.startsWith('http://') ||
        imagePath.startsWith('https://')) {
      return false;
    }

    return true;
  }

  /// Creates a consistent cache key for rounded dimensions
  static String generateCacheKey({
    required String originalPath,
    required int width,
    required int height,
    String? serverId,
  }) {
    final serverPrefix = serverId != null ? '${serverId}_' : '';
    return '${serverPrefix}transcode_${width}x${height}_${originalPath.hashCode}';
  }
}
