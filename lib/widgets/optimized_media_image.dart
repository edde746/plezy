import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../media/media_server_client.dart';
import '../services/device_performance.dart';
import '../utils/app_logger.dart';
import '../utils/media_image_helper.dart';
import '../utils/obfuscation_utils.dart';

/// Tracks recent image load failures to log a periodic summary instead of
/// spamming per-image. Resets after [_logInterval] so recurring issues
/// remain visible.
int _imageFailureCount = 0;
DateTime _lastFailureLog = DateTime.now();
const _logInterval = Duration(seconds: 10);

/// Passed to [OptimizedMediaImage.errorWidget] when no URL could be built for
/// the image *at this build*, as opposed to a load that was attempted and
/// failed. Reaching [OptimizedMediaImage._buildCachedImage] already implies a
/// non-empty [OptimizedMediaImage.imagePath], and the only remaining way
/// [MediaImageHelper.getOptimizedImageUrl] returns '' for one is a null
/// [MediaServerClient] (offline mode, profile switch, server reconnect), so the
/// path is not known-bad and callers that memoize failures MUST NOT record it.
class UnresolvedImageUrl implements Exception {
  const UnresolvedImageUrl(this.imagePath);
  final String imagePath;
  @override
  String toString() => 'No image URL could be built for $imagePath';
}

Widget blurArtwork(Widget child, {double sigma = 30, bool clip = true}) {
  if (!kBlurArtwork) return child;
  final filtered = ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    child: child,
  );
  return clip ? ClipRect(child: filtered) : filtered;
}

Widget _withArtworkDim(Animation<double>? dim, Widget Function(Color? tint) builder) {
  if (dim == null) return builder(null);
  return AnimatedBuilder(
    animation: dim,
    builder: (context, _) {
      final amount = dim.value.clamp(0.0, 1.0);
      return builder(amount == 0 ? null : Colors.black.withValues(alpha: amount));
    },
  );
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
  final Alignment alignment;
  final IconData? fallbackIcon;
  final ImageType imageType;
  final String? localFilePath;
  final bool cacheMissingLocalFile;

  /// Black tint applied at image paint time without an opacity save layer.
  final Animation<double>? artworkDim;

  /// Recolors light-toned logo artwork toward this theme foreground so it
  /// stays legible on light surfaces (see [ToneMappedLogoImage]). Applies to
  /// the network decode path only; channel logos are online-only artwork.
  final Color? logoToneTarget;

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
    this.alignment = Alignment.center,
    this.fallbackIcon,
    this.imageType = ImageType.poster,
    this.localFilePath,
    this.artworkDim,
    this.logoToneTarget,
    this.cacheMissingLocalFile = false,
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
    Alignment alignment,
    IconData? fallbackIcon,
    ImageType imageType,
    String? localFilePath,
    Animation<double>? artworkDim,
    Color? logoToneTarget,
    bool cacheMissingLocalFile,
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
    Alignment alignment = Alignment.center,
    IconData? fallbackIcon,
    String? localFilePath,
    Animation<double>? artworkDim,
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
         alignment: alignment,
         fallbackIcon: fallbackIcon ?? Symbols.movie_rounded,
         imageType: ImageType.poster,
         localFilePath: localFilePath,
         artworkDim: artworkDim,
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
    Alignment alignment = Alignment.center,
    IconData? fallbackIcon,
    String? localFilePath,
    Color? logoToneTarget,
    Animation<double>? artworkDim,
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
         alignment: alignment,
         fallbackIcon: fallbackIcon ?? Symbols.video_library_rounded,
         imageType: ImageType.thumb,
         localFilePath: localFilePath,
         logoToneTarget: logoToneTarget,
         artworkDim: artworkDim,
       );

  /// Whether both width and height are explicitly set to finite positive values,
  /// meaning we can skip the LayoutBuilder.
  bool get _hasKnownDimensions =>
      width != null && width!.isFinite && width! > 0 && height != null && height!.isFinite && height! > 0;

  @override
  Widget build(BuildContext context) {
    final path = localFilePath;
    if (path == null) {
      return _buildResolved(context, LocalFileResolution.missing, null);
    }
    return ResolvedLocalFile(path: path, cacheMissing: cacheMissingLocalFile, builder: _buildResolved);
  }

  Widget _buildResolved(BuildContext context, LocalFileResolution resolution, File? localFile) {
    if (resolution == LocalFileResolution.pending) {
      return placeholder == null
          ? _surfacePlaceholder(context)
          : _buildPlaceholder(context, imagePath ?? localFilePath ?? '');
    }
    final hasLocal = resolution == LocalFileResolution.present;

    if (!hasLocal && (imagePath == null || imagePath!.isEmpty)) {
      if (errorWidget != null) {
        return errorWidget!(context, localFilePath ?? '', UnresolvedImageUrl(localFilePath ?? imagePath ?? ''));
      }
      return _buildFallback(context);
    }

    if (_hasKnownDimensions) {
      return blurArtwork(
        hasLocal
            ? _buildLocalFileImage(context, localFile!, width!, height!)
            : _buildCachedImage(context, width!, height!),
      );
    }

    return blurArtwork(
      LayoutBuilder(
        builder: (context, constraints) {
          final effectiveWidth = _resolvedDimension(width, constraints.maxWidth, 300.0);
          final effectiveHeight = _resolvedDimension(height, constraints.maxHeight, 450.0);
          return hasLocal
              ? _buildLocalFileImage(context, localFile!, effectiveWidth, effectiveHeight)
              : _buildCachedImage(context, effectiveWidth, effectiveHeight);
        },
      ),
    );
  }

  Widget _buildLocalFileImage(BuildContext context, File file, double effectiveWidth, double effectiveHeight) {
    final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
    final scaledWidth = effectiveWidth * dpr;
    final scaledHeight = effectiveHeight * dpr;
    final (memWidth, memHeight) = MediaImageHelper.getMemCacheDimensions(
      displayWidth: scaledWidth.isFinite && scaledWidth > 0 ? scaledWidth.round() : 0,
      displayHeight: scaledHeight.isFinite && scaledHeight > 0 ? scaledHeight.round() : 0,
      imageType: imageType,
    );

    return _withArtworkDim(
      artworkDim,
      (tint) => Image(
        image: MediaImageHelper.boundedDecode(FileImage(file), memWidth: memWidth, memHeight: memHeight),
        width: width,
        height: height,
        // Artwork is decorative: the enclosing card exposes one merged node
        // with the title, and a per-image node just grows the semantics tree
        // the TV a11y services make Flutter rebuild every frame.
        excludeFromSemantics: true,
        fit: fit,
        filterQuality: filterQuality,
        alignment: alignment,
        color: tint,
        colorBlendMode: tint == null ? null : BlendMode.srcATop,
        errorBuilder: (context, error, stackTrace) {
          if (errorWidget != null) {
            return errorWidget!(context, file.path, error);
          }
          return _buildErrorWidget(context, error);
        },
      ),
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
      imageType: imageType,
    );

    if (imageUrl.isEmpty) {
      // An unresolvable URL (no client, offline, suppressed transcode) is a
      // load failure from the caller's point of view, so honour its own
      // failure UI rather than the generic broken-image tile.
      if (errorWidget != null) {
        return errorWidget!(context, imagePath ?? '', UnresolvedImageUrl(imagePath ?? ''));
      }
      return _buildFallback(context);
    }

    final scaledWidth = effectiveWidth * devicePixelRatio;
    final scaledHeight = effectiveHeight * devicePixelRatio;
    final (memWidth, memHeight) = MediaImageHelper.getMemCacheDimensions(
      displayWidth: scaledWidth.isFinite && scaledWidth > 0 ? scaledWidth.round() : 0,
      displayHeight: scaledHeight.isFinite && scaledHeight > 0 ? scaledHeight.round() : 0,
      imageType: imageType,
    );

    final resizedProvider = MediaImageHelper.serverArtworkProvider(
      imageUrl: imageUrl,
      memWidth: memWidth,
      memHeight: memHeight,
      logoToneTarget: logoToneTarget,
    );

    // Reduced tier: swap in directly, no fade machinery at all.
    if (DevicePerformance.isReduced) {
      return _withArtworkDim(
        artworkDim,
        (tint) => Image(
          image: resizedProvider,
          width: width,
          height: height,
          // Decorative — see the Image.file branch.
          excludeFromSemantics: true,
          fit: fit,
          filterQuality: filterQuality,
          alignment: alignment,
          color: tint,
          colorBlendMode: tint == null ? null : BlendMode.srcATop,
          errorBuilder: _networkErrorBuilder(imageUrl),
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return _buildPlaceholder(context, imageUrl);
          },
        ),
      );
    }

    return _FadeInNetworkImage(
      image: resizedProvider,
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      alignment: alignment,
      duration: fadeInDuration,
      placeholderBuilder: (context) => _buildPlaceholder(context, imageUrl),
      errorBuilder: _networkErrorBuilder(imageUrl),
      artworkDim: artworkDim,
    );
  }

  ImageErrorWidgetBuilder _networkErrorBuilder(String imageUrl) {
    return (context, error, stackTrace) {
      _imageFailureCount++;
      final now = DateTime.now();
      if (now.difference(_lastFailureLog) >= _logInterval) {
        appLogger.w('Image load failed ($_imageFailureCount since last log): $error');
        _imageFailureCount = 0;
        _lastFailureLog = now;
      }
      if (errorWidget != null) {
        return errorWidget!(context, imageUrl, error);
      }
      return _buildErrorWidget(context, error);
    };
  }

  Widget _surfacePlaceholder(BuildContext context, {IconData? icon, Color? iconColor, bool fillParent = false}) {
    final theme = Theme.of(context).colorScheme;
    final baseSurfaceColor = theme.surfaceContainerHighest;
    final baseIconColor = iconColor ?? theme.onSurfaceVariant;
    return _withArtworkDim(
      artworkDim,
      (tint) => Container(
        width: fillParent ? null : width,
        height: fillParent ? null : height,
        color: tint == null ? baseSurfaceColor : Color.alphaBlend(tint, baseSurfaceColor),
        child: icon == null
            ? null
            : Center(
                child: AppIcon(
                  icon,
                  fill: 1,
                  size: 40,
                  color: tint == null ? baseIconColor : Color.alphaBlend(tint, baseIconColor),
                ),
              ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, String imageUrl) {
    final customPlaceholder = placeholder?.call(context, imageUrl);
    if (customPlaceholder == null) {
      return _surfacePlaceholder(context, icon: fallbackIcon, iconColor: Colors.white54);
    }
    if (artworkDim == null) return customPlaceholder;
    return _withArtworkDim(
      artworkDim,
      (tint) => Stack(
        fit: StackFit.passthrough,
        children: [
          customPlaceholder,
          if (tint != null)
            Positioned.fill(
              child: IgnorePointer(child: ColoredBox(color: tint)),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, dynamic _) => _surfacePlaceholder(
    context,
    icon: fallbackIcon ?? Symbols.broken_image_rounded,
    fillParent: !_hasKnownDimensions,
  );

  Widget _buildFallback(BuildContext context) =>
      _surfacePlaceholder(context, icon: fallbackIcon ?? Symbols.image_not_supported_rounded);
}

/// Clear-logo artwork for hero and detail headers.
///
/// Logos are the one artwork type whose source aspect never matches its slot,
/// so the decode has to preserve the source ratio: [OptimizedMediaImage] goes
/// through [MediaImageHelper.boundedDecode], which bounds both axes under
/// `ResizeImagePolicy.fit`. Handing both mem-cache dimensions to a raw
/// `CachedNetworkImage` instead decodes under `ResizeImagePolicy.exact`, which
/// pins the logo to whatever ratio those two bounds happen to have.
///
/// Plex serves logos as fitting transcodes (`minSize=0&upscale=0`), so the
/// image comes back inside the requested box with aspect intact (a 4313×1035
/// logo asked for at 1200×360 comes back 1200×288). `exact` ignores the
/// source ratio and decodes to whatever ratio the two bounds happen to have:
/// on a phone at DPR 3 the 400×120 hero slot decodes to exactly 1000×360 —
/// the width capped by [MediaImageHelper.getMemCacheDimensions] — turning a
/// 4.17∶1 logo into 2.78∶1.
///
/// [fallbackBuilder] renders the title in place of the logo when the path is
/// missing, the URL can't be built, or the image fails to load.
class ClearLogoImage extends StatelessWidget {
  const ClearLogoImage({
    super.key,
    required this.client,
    required this.logoPath,
    required this.width,
    required this.height,
    required this.fallbackBuilder,
    this.alignment = Alignment.centerLeft,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  final MediaServerClient? client;
  final String? logoPath;
  final double width;
  final double height;
  final WidgetBuilder fallbackBuilder;
  final Alignment alignment;
  final Duration fadeInDuration;

  @override
  Widget build(BuildContext context) {
    final path = logoPath;
    return SizedBox(
      width: width,
      height: height,
      child: path == null || path.isEmpty
          ? fallbackBuilder(context)
          : OptimizedMediaImage(
              client: client,
              imagePath: path,
              width: width,
              height: height,
              fit: BoxFit.contain,
              alignment: alignment,
              imageType: ImageType.heroLogo,
              fadeInDuration: fadeInDuration,
              placeholder: (context, _) => const SizedBox.shrink(),
              errorWidget: (context, _, _) => fallbackBuilder(context),
            ),
    );
  }
}

/// Fades a network image in by animating the image paint's alpha
/// (`Image.opacity` → `RawImage`), not by wrapping it in an opacity widget:
/// a widget-opacity fade is a tile-sized saveLayer per in-flight image, and
/// grid scrolling runs many of them concurrently — a real GPU cost on the
/// weak GLES devices most Android TVs are. The opaque placeholder sits below
/// in a Stack until the fade completes, so the visual result matches the
/// AnimatedSwitcher cross-fade this replaces.
class _FadeInNetworkImage extends StatefulWidget {
  const _FadeInNetworkImage({
    required this.image,
    required this.width,
    required this.height,
    required this.fit,
    required this.filterQuality,
    required this.alignment,
    required this.duration,
    required this.placeholderBuilder,
    required this.errorBuilder,
    required this.artworkDim,
  });

  final ImageProvider image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final Alignment alignment;
  final Duration duration;
  final WidgetBuilder placeholderBuilder;
  final ImageErrorWidgetBuilder errorBuilder;
  final Animation<double>? artworkDim;

  @override
  State<_FadeInNetworkImage> createState() => _FadeInNetworkImageState();
}

class _FadeInNetworkImageState extends State<_FadeInNetworkImage> with SingleTickerProviderStateMixin {
  // Starts fully visible so synchronously-available (memory-cached) images
  // paint immediately; dropped to 0 only once we know the load is async.
  late final AnimationController _opacity = AnimationController(vsync: this, duration: widget.duration, value: 1);
  bool _sawFirstFrame = false;
  bool _placeholderVisible = false;

  @override
  void didUpdateWidget(covariant _FadeInNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) {
      // New stream: rearm so an async swap fades again (a memory-cached swap
      // stays at full opacity via the wasSynchronouslyLoaded path).
      _sawFirstFrame = false;
      _placeholderVisible = false;
      _opacity.value = 1;
    }
  }

  @override
  void dispose() {
    _opacity.dispose();
    super.dispose();
  }

  void _startFade() {
    _sawFirstFrame = true;
    _opacity.forward().whenComplete(() {
      if (mounted && _placeholderVisible) setState(() => _placeholderVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _withArtworkDim(
      widget.artworkDim,
      (tint) => Image(
        image: widget.image,
        width: widget.width,
        height: widget.height,
        // Decorative — see OptimizedMediaImage.
        excludeFromSemantics: true,
        fit: widget.fit,
        filterQuality: widget.filterQuality,
        alignment: widget.alignment,
        color: tint,
        colorBlendMode: tint == null ? null : BlendMode.srcATop,
        opacity: _opacity,
        errorBuilder: widget.errorBuilder,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          if (frame == null && !_sawFirstFrame) {
            // Async load in progress: hide the image and show the placeholder
            // beneath until the first frame arrives. Mutating outside setState
            // is fine here — we're inside build.
            _opacity.value = 0;
            _placeholderVisible = true;
          } else if (frame != null && !_sawFirstFrame) {
            _startFade();
          }
          if (!_placeholderVisible) return child;
          return Stack(
            fit: StackFit.passthrough,
            alignment: Alignment.center,
            children: [widget.placeholderBuilder(context), child],
          );
        },
      ),
    );
  }
}

enum LocalFileResolution { pending, missing, present }

typedef LocalFileResolutionBuilder = Widget Function(BuildContext context, LocalFileResolution resolution, File? file);

Future<bool> _defaultLocalFileExists(File file) => file.exists();

/// Resolves local file availability without blocking the build isolate.
///
/// Results are scoped to this widget state and keyed by [path]. Present files
/// are always cached. Missing files are cached only when [cacheMissing] is set,
/// allowing consumers that expect late file creation to retry on rebuild.
class ResolvedLocalFile extends StatefulWidget {
  const ResolvedLocalFile({
    super.key,
    required this.path,
    required this.builder,
    this.cacheMissing = false,
    this.fileExists = _defaultLocalFileExists,
  });

  final String path;
  final LocalFileResolutionBuilder builder;
  final bool cacheMissing;

  @visibleForTesting
  final Future<bool> Function(File file) fileExists;

  @override
  State<ResolvedLocalFile> createState() => _ResolvedLocalFileState();
}

class _ResolvedLocalFileState extends State<ResolvedLocalFile> {
  final Map<String, File> _presentFiles = <String, File>{};
  final Set<String> _missingFiles = <String>{};
  final Set<String> _pendingPaths = <String>{};
  File? _file;
  LocalFileResolution _resolution = LocalFileResolution.pending;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(ResolvedLocalFile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileExists != widget.fileExists) {
      _presentFiles.clear();
      _missingFiles.clear();
      _pendingPaths.clear();
    } else if (oldWidget.cacheMissing && !widget.cacheMissing) {
      _missingFiles.clear();
    }
    if (oldWidget.path != widget.path ||
        oldWidget.fileExists != widget.fileExists ||
        _resolution == LocalFileResolution.missing) {
      _resolve();
    }
  }

  void _resolve() {
    final path = widget.path;
    final present = _presentFiles[path];
    if (present != null) {
      _file = present;
      _resolution = LocalFileResolution.present;
      return;
    }
    if (widget.cacheMissing && _missingFiles.contains(path)) {
      _file = null;
      _resolution = LocalFileResolution.missing;
      return;
    }

    _file = null;
    _resolution = LocalFileResolution.pending;
    if (!_pendingPaths.add(path)) return;

    final candidate = File(path);
    try {
      widget
          .fileExists(candidate)
          .then(
            (exists) => _complete(path, candidate, exists),
            onError: (Object _, StackTrace _) => _complete(path, candidate, false),
          );
    } catch (_) {
      _complete(path, candidate, false);
    }
  }

  void _complete(String path, File candidate, bool exists) {
    if (!mounted) return;
    _pendingPaths.remove(path);
    if (exists) {
      _presentFiles[path] = candidate;
      _missingFiles.remove(path);
    } else if (widget.cacheMissing) {
      _missingFiles.add(path);
    }
    if (widget.path != path) return;
    setState(() {
      _file = exists ? candidate : null;
      _resolution = exists ? LocalFileResolution.present : LocalFileResolution.missing;
    });
  }

  @override
  void dispose() {
    _presentFiles.clear();
    _missingFiles.clear();
    _pendingPaths.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _resolution, _file);
}
