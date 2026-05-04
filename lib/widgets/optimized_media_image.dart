import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../media/media_server_client.dart';
import '../services/image_cache_service.dart';
import '../utils/app_logger.dart';
import '../utils/media_image_helper.dart';
import '../utils/obfuscation_utils.dart';

/// Tracks recent image load failures to log a periodic summary instead of
/// spamming per-image. Resets after [_logInterval] so recurring issues
/// remain visible.
int _imageFailureCount = 0;
DateTime _lastFailureLog = DateTime.now();
const _logInterval = Duration(seconds: 10);

Widget blurArtwork(Widget child, {double sigma = 30, bool clip = true}) {
  if (!kBlurArtwork) return child;
  final filtered = ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    child: child,
  );
  return clip ? ClipRect(child: filtered) : filtered;
}

class OptimizedMediaImage extends StatelessWidget {
  final MediaServerClient? client;
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

  const OptimizedMediaImage._({
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
  const factory OptimizedMediaImage({
    Key? key,
    MediaServerClient? client,
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
  }) = OptimizedMediaImage._;

  /// Named constructor for poster images with default fallback icon.
  const OptimizedMediaImage.poster({
    Key? key,
    MediaServerClient? client,
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

  /// Named constructor for episode thumbnails.
  const OptimizedMediaImage.thumb({
    Key? key,
    MediaServerClient? client,
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

  /// Named constructor for playlist images.
  const OptimizedMediaImage.playlist({
    Key? key,
    MediaServerClient? client,
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
    final localFile = localFilePath != null ? File(localFilePath!) : null;
    final hasLocal = localFile != null && localFile.existsSync();

    // No local file and no network path → fallback
    if (!hasLocal && (imagePath == null || imagePath!.isEmpty)) {
      return _buildFallback(context);
    }

    // Fast path: skip LayoutBuilder when both dimensions are explicitly known
    if (_hasKnownDimensions) {
      return blurArtwork(
        hasLocal
            ? _buildLocalFileImage(context, localFile, width!, height!)
            : _buildCachedImage(context, width!, height!),
      );
    }

    return blurArtwork(
      LayoutBuilder(
        builder: (context, constraints) {
          final effectiveWidth = _resolvedDimension(width, constraints.maxWidth, 300.0);
          final effectiveHeight = _resolvedDimension(height, constraints.maxHeight, 450.0);
          return hasLocal
              ? _buildLocalFileImage(context, localFile, effectiveWidth, effectiveHeight)
              : _buildCachedImage(context, effectiveWidth, effectiveHeight);
        },
      ),
    );
  }

  Widget _buildLocalFileImage(BuildContext context, File file, double effectiveWidth, double effectiveHeight) {
    final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
    final scaledWidth = effectiveWidth * dpr;
    final scaledHeight = effectiveHeight * dpr;
    final (_, memHeight) = MediaImageHelper.getMemCacheDimensions(
      displayWidth: scaledWidth.isFinite && scaledWidth > 0 ? scaledWidth.round() : 0,
      displayHeight: scaledHeight.isFinite && scaledHeight > 0 ? scaledHeight.round() : 0,
      imageType: imageType,
    );

    return Image.file(
      file,
      width: width,
      height: height,
      // Only cacheHeight: leaving cacheWidth null preserves decode aspect
      // ratio, mirroring the network branch which only passes maxHeight to
      // CachedNetworkImageProvider.
      cacheHeight: memHeight > 0 ? memHeight : null,
      fit: fit,
      filterQuality: filterQuality,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) {
        if (errorWidget != null) {
          return errorWidget!(context, file.path, error);
        }
        return _buildErrorWidget(context, error);
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
    final devicePixelRatio = MediaImageHelper.effectiveDevicePixelRatio(context);

    final imageUrl = MediaImageHelper.getOptimizedImageUrl(
      client: client,
      thumbPath: imagePath,
      maxWidth: effectiveWidth,
      maxHeight: effectiveHeight,
      devicePixelRatio: devicePixelRatio,
      enableTranscoding: enableTranscoding && MediaImageHelper.shouldTranscode(imagePath),
      imageType: imageType,
    );

    if (imageUrl.isEmpty) {
      return _buildFallback(context);
    }

    final scaledWidth = effectiveWidth * devicePixelRatio;
    final scaledHeight = effectiveHeight * devicePixelRatio;
    final (_, memHeight) = MediaImageHelper.getMemCacheDimensions(
      displayWidth: scaledWidth.isFinite && scaledWidth > 0 ? scaledWidth.round() : 0,
      displayHeight: scaledHeight.isFinite && scaledHeight > 0 ? scaledHeight.round() : 0,
      imageType: imageType,
    );

    final effectiveCacheKey = cacheKey ?? _generateCacheKey(imageUrl);

    return Image(
      image: CachedNetworkImageProvider(
        imageUrl,
        cacheKey: effectiveCacheKey,
        cacheManager: PlexImageCacheManager.instance,
        headers: const {'User-Agent': 'Plezy'},
        maxHeight: memHeight,
      ),
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) {
        _imageFailureCount++;
        final now = DateTime.now();
        if (now.difference(_lastFailureLog) >= _logInterval) {
          appLogger.w('Image load failed ($_imageFailureCount since last log): $error');
          _imageFailureCount = 0;
          _lastFailureLog = now;
        }
        return _buildErrorWidget(context, error);
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: frame != null ? child : _buildPlaceholder(context),
        );
      },
    );
  }

  Widget _surfacePlaceholder(BuildContext context, {IconData? icon, Color? iconColor, bool fillParent = false}) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      width: fillParent ? null : width,
      height: fillParent ? null : height,
      color: theme.surfaceContainerHighest,
      child: icon == null
          ? null
          : Center(child: AppIcon(icon, fill: 1, size: 40, color: iconColor ?? theme.onSurfaceVariant)),
    );
  }

  Widget _buildPlaceholder(BuildContext context) =>
      _surfacePlaceholder(context, icon: fallbackIcon, iconColor: Colors.white54);

  Widget _buildErrorWidget(BuildContext context, dynamic _) =>
      _surfacePlaceholder(context, icon: fallbackIcon ?? Symbols.broken_image_rounded, fillParent: true);

  Widget _buildFallback(BuildContext context) =>
      _surfacePlaceholder(context, icon: fallbackIcon ?? Symbols.image_not_supported_rounded);

  String _generateCacheKey(String imageUrl) {
    // URL already encodes bucketed transcode dimensions via roundDimensions,
    // so the URL hash alone uniquely identifies the bytes on disk. Including
    // mem-cache dimensions here would re-introduce churn on every pixel of
    // window resize and defeat getMemCacheDimensions' bucketing.
    return 'plex_optimized_${sha1.convert(utf8.encode(imageUrl))}';
  }
}
