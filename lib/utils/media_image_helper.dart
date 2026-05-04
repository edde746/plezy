import 'dart:math';
import 'package:flutter/widgets.dart';
import '../media/media_server_client.dart';
import 'platform_detector.dart';

/// Image types for different transcoding strategies
enum ImageType {
  poster, // 2:3 ratio posters
  art, // Wide background art
  thumb, // 16:9 episode thumbnails
  logo, // Variable ratio clear logos
  avatar, // Square-ish user avatars
}

/// Backend-neutral image URL helper.
///
/// Builds optimally-sized image URLs that go through the right server-side
/// transcode path:
/// - **Plex**: `/photo/:/transcode?width=W&height=H&url=...&X-Plex-Token=...`
///   constructed by [MediaServerClient.thumbnailUrl] (PlexClient impl).
/// - **Jellyfin**: `/Items/{id}/Images/{type}?MaxWidth=W&MaxHeight=H&api_key=...`
///   constructed by [MediaServerClient.thumbnailUrl] (JellyfinClient impl).
///
/// Self-contained absolute URLs (Jellyfin items pre-absolutized at the
/// model layer) get sized via query-param append so they pick up the same
/// DPR scaling and cache-bucket rounding as Plex.
///
/// External URLs (EPG provider images, etc.) that the local server doesn't
/// host get proxied through Plex's photo transcoder when a Plex client is
/// available; otherwise they pass through unchanged.
class MediaImageHelper {
  static const int _widthRoundingFactor = 40;
  static const int _heightRoundingFactor = 60;

  static const int _maxTranscodedWidth = 1920;
  static const int _maxTranscodedHeight = 1080;

  static const int _minTranscodedWidth = 160;
  static const int _minTranscodedHeight = 240;

  /// Minimum DPR for TV to ensure sharp artwork on large screens
  static const double _tvMinDpr = 2.0;

  /// Rounds a value up to the next multiple of [factor]. Shared between the
  /// URL dimension rounding (transcode bucket) and the mem-cache dimension
  /// rounding (decode bucket) so both snap to the same grid.
  static int _bucketUp(num value, int factor) => (value / factor).ceil() * factor;

  /// Rounds dimensions to cache-friendly values to increase cache hit rate
  static (int width, int height) roundDimensions(double width, double height) {
    return (
      _bucketUp(width, _widthRoundingFactor).clamp(_minTranscodedWidth, _maxTranscodedWidth),
      _bucketUp(height, _heightRoundingFactor).clamp(_minTranscodedHeight, _maxTranscodedHeight),
    );
  }

  /// Computes an effective device pixel ratio that accounts for displays where
  /// the platform-reported DPR doesn't reflect the true physical density
  /// (common on Linux X11 with compositor scaling).
  static double effectiveDevicePixelRatio(BuildContext context) {
    final reportedDpr = MediaQuery.devicePixelRatioOf(context);
    double dpr;
    try {
      final displayWidth = View.of(context).display.size.width;
      // Scale quality with display resolution: 1920px = baseline (1.0x)
      final displayBasedDpr = (displayWidth / 1920).clamp(1.0, 3.0);
      dpr = max(reportedDpr, displayBasedDpr);
    } catch (_) {
      dpr = reportedDpr;
    }
    if (PlatformDetector.isTV()) dpr = max(dpr, _tvMinDpr);
    return dpr;
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
        final coverWidth = targetWidth * 1.1;
        final coverHeight = targetHeight * 1.1;

        return roundDimensions(coverWidth, coverHeight);

      case ImageType.logo:
        final logoWidth = targetWidth;
        final logoHeight = targetHeight;
        return roundDimensions(logoWidth, logoHeight);

      case ImageType.thumb:
        final thumbHeight = targetHeight;
        final thumbWidth = min(targetWidth, thumbHeight * (16 / 9));
        return roundDimensions(thumbWidth, thumbHeight);

      case ImageType.avatar:
        final size = min(targetWidth, targetHeight);
        return roundDimensions(size, size);

      case ImageType.poster:
        final calculatedWidth = min(targetWidth, targetHeight * (2 / 3));
        final calculatedHeight = calculatedWidth * (3 / 2);
        return roundDimensions(calculatedWidth, calculatedHeight);
    }
  }

  /// Creates an optimized image URL.
  ///
  /// Falls back to the raw [thumbPath] when the path is empty, when no
  /// client is available (offline mode), or when transcoding is suppressed
  /// for this path.
  static String getOptimizedImageUrl({
    MediaServerClient? client,
    required String? thumbPath,
    required double maxWidth,
    required double maxHeight,
    required double devicePixelRatio,
    bool enableTranscoding = true,
    ImageType imageType = ImageType.poster,
  }) {
    if (thumbPath == null || thumbPath.isEmpty) return '';
    final basePath = thumbPath;

    if (basePath.startsWith('http://') || basePath.startsWith('https://')) {
      // Self-contained Jellyfin URLs already carry their own auth
      // (`api_key=...`). Append `MaxWidth/MaxHeight` so we still get DPR
      // scaling and cache-bucket rounding — Jellyfin's image endpoint
      // honours those query params.
      if (basePath.contains('api_key=')) {
        if (!enableTranscoding) return basePath;
        if (basePath.contains('MaxWidth=') || basePath.contains('maxWidth=') || basePath.contains('Width=')) {
          return basePath;
        }
        final (width, height) = calculateOptimalDimensions(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          devicePixelRatio: devicePixelRatio,
          imageType: imageType,
        );
        final separator = basePath.contains('?') ? '&' : '?';
        return '$basePath${separator}MaxWidth=$width&MaxHeight=$height';
      }

      // EPG / external URL — proxy through the server's transcoder. Plex
      // implements [externalImageUrl] via `/photo/:/transcode?url=...`;
      // backends without a comparable endpoint return the URL unchanged.
      if (client == null || !enableTranscoding) return basePath;
      final (width, height) = calculateOptimalDimensions(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        devicePixelRatio: devicePixelRatio,
        imageType: imageType,
      );
      return client.externalImageUrl(basePath, width: width, height: height);
    }

    // Relative path — let the client build the sized URL using its native
    // size-hint params (`/photo/:/transcode` for Plex, `MaxWidth/MaxHeight`
    // for Jellyfin). The interface guarantees both honour width/height.
    if (client == null) {
      // Offline + relative path: the cached entry already exists under the
      // URL originally fetched, so returning '' matches pre-refactor behaviour.
      return '';
    }

    if (!enableTranscoding || !shouldTranscode(basePath)) {
      return client.thumbnailUrl(basePath);
    }

    final (width, height) = calculateOptimalDimensions(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      devicePixelRatio: devicePixelRatio,
      imageType: imageType,
    );

    // For very small targets, skip server-side resizing — the cost of the
    // transcode round-trip outweighs the savings.
    if (maxWidth < 80 || maxHeight < 120) {
      return client.thumbnailUrl(basePath);
    }
    if (width <= _minTranscodedWidth * 1.2 && height <= _minTranscodedHeight * 1.2) {
      return client.thumbnailUrl(basePath);
    }

    return client.thumbnailUrl(basePath, width: width, height: height);
  }

  /// Generates cache-friendly dimensions for memory caching.
  ///
  /// Max bounds are type-aware so large originals (e.g. failed server
  /// transcodes or external EPG images) are capped at a resolution
  /// appropriate for the display context.
  static (int memWidth, int memHeight) getMemCacheDimensions({
    required int displayWidth,
    required int displayHeight,
    double scaleFactor = 1.0,
    ImageType imageType = ImageType.poster,
  }) {
    // Bucket to match roundDimensions() so the mem-cache key and CNIP
    // maxHeight stay stable across sub-bucket resize deltas. Without this,
    // LayoutBuilder rebuilds during window resize churn the cache key on
    // every pixel and evict valid entries from Flutter's image cache.
    final bucketedWidth = _bucketUp(displayWidth * scaleFactor, _widthRoundingFactor);
    final bucketedHeight = _bucketUp(displayHeight * scaleFactor, _heightRoundingFactor);

    final (int maxW, int maxH) = switch (imageType) {
      ImageType.poster => (720, 1080),
      ImageType.thumb => (960, 540),
      ImageType.art => (1920, 1080),
      ImageType.logo => (600, 300),
      ImageType.avatar => (300, 300),
    };

    return (bucketedWidth.clamp(120, maxW), bucketedHeight.clamp(180, maxH));
  }

  /// Determines if an image path is suitable for transcoding
  static bool shouldTranscode(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;

    if (imagePath.contains('/photo/:/transcode') ||
        imagePath.startsWith('http://') ||
        imagePath.startsWith('https://')) {
      return false;
    }

    return true;
  }

  /// Optimized URL for hero/background art ([ImageType.art]).
  static String heroArtUrl({
    required MediaServerClient? client,
    required String? thumbPath,
    required BuildContext context,
    required double containerWidth,
    required double containerHeight,
  }) => _typedUrl(client, thumbPath, context, containerWidth, containerHeight, ImageType.art);

  /// Optimized URL for clear-logo overlays ([ImageType.logo]).
  static String logoUrl({
    required MediaServerClient? client,
    required String? thumbPath,
    required BuildContext context,
    required double containerWidth,
    required double containerHeight,
  }) => _typedUrl(client, thumbPath, context, containerWidth, containerHeight, ImageType.logo);

  static String _typedUrl(
    MediaServerClient? client,
    String? thumbPath,
    BuildContext context,
    double containerWidth,
    double containerHeight,
    ImageType type,
  ) {
    return getOptimizedImageUrl(
      client: client,
      thumbPath: thumbPath,
      maxWidth: containerWidth,
      maxHeight: containerHeight,
      devicePixelRatio: effectiveDevicePixelRatio(context),
      imageType: type,
    );
  }
}
