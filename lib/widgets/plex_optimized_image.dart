import 'package:flutter/foundation.dart' show kIsWeb;

import '../utils/platform_helper.dart';
import '../utils/io_helpers.dart';
import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/plex_client.dart';
import '../utils/plex_image_helper.dart';
import 'media_card.dart';

class PlexOptimizedImage extends StatelessWidget {
  final PlexClient? client;
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
  final String? localFilePath;

  const PlexOptimizedImage._({
    super.key,
    this.client,
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
    this.localFilePath,
  });

  /// Generic constructor for optimized images.
  const factory PlexOptimizedImage({
    Key? key,
    PlexClient? client,
    required String? imagePath,
    double? width,
    double? height,
    BoxFit fit,
    FilterQuality filterQuality,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, dynamic)? errorWidget,
    Duration fadeInDuration,
    bool enableTranscoding,
    String? cacheKey,
    Alignment alignment,
    IconData? fallbackIcon,
    ImageType imageType,
    String? localFilePath,
  }) = PlexOptimizedImage._;

  /// Named constructor for poster images with default fallback icon.
  const factory PlexOptimizedImage.poster({
    Key? key,
    PlexClient? client,
    required String? imagePath,
    double? width,
    double? height,
    BoxFit fit,
    FilterQuality filterQuality,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, dynamic)? errorWidget,
    Duration fadeInDuration,
    bool enableTranscoding,
    String? cacheKey,
    Alignment alignment,
    String? localFilePath,
  }) = PlexOptimizedImage._poster;

  /// Named constructor for episode thumbnails.
  const factory PlexOptimizedImage.thumb({
    Key? key,
    PlexClient? client,
    required String? imagePath,
    double? width,
    double? height,
    BoxFit fit,
    FilterQuality filterQuality,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, dynamic)? errorWidget,
    Duration fadeInDuration,
    bool enableTranscoding,
    String? cacheKey,
    Alignment alignment,
    String? localFilePath,
  }) = PlexOptimizedImage._thumb;

  /// Named constructor for playlist images.
  const factory PlexOptimizedImage.playlist({
    Key? key,
    PlexClient? client,
    required String? imagePath,
    double? width,
    double? height,
    BoxFit fit,
    FilterQuality filterQuality,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, dynamic)? errorWidget,
    Duration fadeInDuration,
    bool enableTranscoding,
    String? cacheKey,
    Alignment alignment,
    String? localFilePath,
  }) = PlexOptimizedImage._playlist;

  const PlexOptimizedImage._poster({
    Key? key,
    PlexClient? client,
    required String? imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    FilterQuality filterQuality = FilterQuality.medium,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, dynamic)? errorWidget,
    Duration fadeInDuration = const Duration(milliseconds: 300),
    bool enableTranscoding = true,
    String? cacheKey,
    Alignment alignment = Alignment.center,
    String? localFilePath,
  }) : this._(
         key: key,
         client: client,
         imagePath: imagePath,
         width: width,
         height: height,
         fit: fit,
         filterQuality: filterQuality,
         placeholder: placeholder,
         errorWidget: errorWidget,
         fadeInDuration: fadeInDuration,
         enableTranscoding: enableTranscoding,
         cacheKey: cacheKey,
         alignment: alignment,
         fallbackIcon: Symbols.movie_rounded,
         imageType: ImageType.poster,
         localFilePath: localFilePath,
       );

  const PlexOptimizedImage._thumb({
    Key? key,
    PlexClient? client,
    required String? imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    FilterQuality filterQuality = FilterQuality.medium,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, dynamic)? errorWidget,
    Duration fadeInDuration = const Duration(milliseconds: 300),
    bool enableTranscoding = true,
    String? cacheKey,
    Alignment alignment = Alignment.center,
    String? localFilePath,
  }) : this._(
         key: key,
         client: client,
         imagePath: imagePath,
         width: width,
         height: height,
         fit: fit,
         filterQuality: filterQuality,
         placeholder: placeholder,
         errorWidget: errorWidget,
         fadeInDuration: fadeInDuration,
         enableTranscoding: enableTranscoding,
         cacheKey: cacheKey,
         alignment: alignment,
         fallbackIcon: Symbols.video_library_rounded,
         imageType: ImageType.thumb,
         localFilePath: localFilePath,
       );

  const PlexOptimizedImage._playlist({
    Key? key,
    PlexClient? client,
    required String? imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    FilterQuality filterQuality = FilterQuality.medium,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, dynamic)? errorWidget,
    Duration fadeInDuration = const Duration(milliseconds: 300),
    bool enableTranscoding = true,
    String? cacheKey,
    Alignment alignment = Alignment.center,
    String? localFilePath,
  }) : this._(
         key: key,
         client: client,
         imagePath: imagePath,
         width: width,
         height: height,
         fit: fit,
         filterQuality: filterQuality,
         placeholder: placeholder,
         errorWidget: errorWidget,
         fadeInDuration: fadeInDuration,
         enableTranscoding: enableTranscoding,
         cacheKey: cacheKey,
         alignment: alignment,
         fallbackIcon: Symbols.playlist_play_rounded,
         imageType: ImageType.poster,
         localFilePath: localFilePath,
       );

  /// Whether both width and height are explicitly set to finite positive values,
  /// meaning we can skip the LayoutBuilder.
  bool get _hasKnownDimensions =>
      width != null && width!.isFinite && width! > 0 && height != null && height!.isFinite && height! > 0;

  @override
  Widget build(BuildContext context) {
    // Check for local file first (not available on web)
    if (!kIsWeb && localFilePath != null) {
      final file = File(localFilePath!);
      if (file.existsSync()) {
        return Image.file(
          file as dynamic,
          width: width,
          height: height,
          fit: fit,
          filterQuality: filterQuality,
          alignment: alignment,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(context, error),
        );
      }
    }

    // Return empty container if no image path
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildFallback(context);
    }

    // Fast path: skip LayoutBuilder when both dimensions are explicitly known
    if (_hasKnownDimensions) {
      return _buildCachedImage(context, width!, height!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = _resolvedDimension(width, constraints.maxWidth, 300.0);
        final effectiveHeight = _resolvedDimension(height, constraints.maxHeight, 450.0);
        return _buildCachedImage(context, effectiveWidth, effectiveHeight);
      },
    );
  }

  static double _resolvedDimension(double? explicit, double constraintMax, double fallback) {
    // Pick the explicit size when it's a finite positive number, otherwise
    // fall back to the constraint or a sensible default so we don't end up
    // with NaN/Infinity when rounding to ints for caching.
    if (explicit == null || explicit.isNaN || explicit.isInfinite || explicit <= 0) {
      if (constraintMax.isFinite && constraintMax > 0) {
        return constraintMax;
      }
      return fallback;
    }
    return explicit;
  }

  Widget _buildCachedImage(BuildContext context, double effectiveWidth, double effectiveHeight) {
    final devicePixelRatio = PlexImageHelper.effectiveDevicePixelRatio(context);

    // Get optimized image URL
    final imageUrl = PlexImageHelper.getOptimizedImageUrl(
      client: client,
      thumbPath: imagePath,
      maxWidth: effectiveWidth,
      maxHeight: effectiveHeight,
      devicePixelRatio: devicePixelRatio,
      enableTranscoding: enableTranscoding && PlexImageHelper.shouldTranscode(imagePath),
      imageType: imageType,
    );

    if (imageUrl.isEmpty) {
      return _buildFallback(context);
    }

    // Calculate memory cache dimensions
    final scaledWidth = effectiveWidth * devicePixelRatio;
    final scaledHeight = effectiveHeight * devicePixelRatio;
    final (memWidth, memHeight) = PlexImageHelper.getMemCacheDimensions(
      displayWidth: scaledWidth.isFinite && scaledWidth > 0 ? scaledWidth.round() : 0,
      displayHeight: scaledHeight.isFinite && scaledHeight > 0 ? scaledHeight.round() : 0,
    );

    // Generate cache key if not provided
    final effectiveCacheKey = cacheKey ?? _generateCacheKey(imageUrl, memWidth, memHeight);

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      alignment: alignment,
      fadeInDuration: fadeInDuration,
      memCacheHeight: memHeight,
      cacheKey: effectiveCacheKey,
      placeholder: placeholder != null ? placeholder! : (context, url) => _buildPlaceholder(context),
      errorWidget: errorWidget != null ? errorWidget! : (context, url, error) => _buildErrorWidget(context, error),
      httpHeaders: {'User-Agent': 'Plezy Flutter Client'},
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return SkeletonLoader(
      child: fallbackIcon != null
          ? Center(child: AppIcon(fallbackIcon!, fill: 1, size: 40, color: Colors.white54))
          : null,
    );
  }

  Widget _buildErrorWidget(BuildContext context, dynamic error) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: AppIcon(
          fallbackIcon ?? Symbols.broken_image_rounded,
          fill: 1,
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
        child: AppIcon(
          fallbackIcon ?? Symbols.image_not_supported_rounded,
          fill: 1,
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
