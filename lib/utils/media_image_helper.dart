import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';

import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../services/device_performance.dart';
import '../services/image_cache_service.dart';
import '../services/settings_service.dart' show EpisodePosterMode;
import 'platform_detector.dart';
import 'tone_mapped_logo_image.dart';

/// Image types for different transcoding strategies
enum ImageType {
  poster, // 2:3 ratio posters
  art, // Wide background art
  thumb, // 16:9 episode thumbnails
  logo, // Variable ratio clear logos
  heroLogo, // Large hero clear logos
  avatar, // Small square-ish avatars (user profiles, inline person headers)
  square, // 1:1 grid-cell artwork (albums, artists, tracks, cast cards)
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

  /// 1080p baseline; scaled by [DevicePerformance.displayBudgetFactor] so
  /// 4K-surface displays can fetch up to 3840×2160 instead of upscaling.
  static const int _maxTranscodedWidth = 1920;
  static const int _maxTranscodedHeight = 1080;

  static const int _minTranscodedWidth = 160;
  static const int _minTranscodedHeight = 240;

  /// Minimum DPR for TV to ensure sharp artwork on large screens
  static const double _tvMinDpr = 2.0;

  /// Peak artwork supersample: the fetch and decode carry this multiple of the
  /// pixels the artwork paints into.
  ///
  /// Flutter resolves the leftover scale with a separable filter at whatever
  /// sub-pixel phase the layout lands on — grid strides and scroll offsets are
  /// fractional doubles — and a bitmap that nearly matches its destination is
  /// the worst case: the kernel degenerates into a two-tap blend of
  /// neighbouring texels. A 7% size mismatch therefore costs far more than 7%
  /// of the detail, and an exact 1∶1 fetch is no better, because the phase
  /// still shifts it. RMSE against an ideal area-average of a 1000×1500 Plex
  /// poster in a 186×279 slot, averaged over sub-pixel phases (lower is
  /// sharper, each ratio under its best filter):
  ///
  ///     1.00× 10.4   1.15× 8.3   1.25× 7.0   1.50× 4.7   1.75× 3.8   2.00× 4.0
  ///
  /// 1.5 takes ~80% of the gain for 2.25× the pixels and keeps the paint scale
  /// at 0.67, above the 0.5 where [FilterQuality.high] starts losing to
  /// mipmaps.
  static const double _maxArtworkSupersample = 1.5;

  /// Device pixels per logical pixel past which the supersample stops being
  /// worth its bytes.
  ///
  /// A logical pixel subtends roughly the same angle on every form factor by
  /// construction (~1.5–1.8 arcmin), so a device pixel subtends that over the
  /// ratio. Against ~1 arcmin of acuity one device pixel is clearly resolvable
  /// at DPR 1 (1.52'), borderline at 2 (0.83–0.87' — the TVs and tablets
  /// #1697 and #2020 were reported from) and invisible at 3 (0.63'). So
  /// high-density phones pay nothing: they are the platform on cellular data
  /// and the tightest on RAM.
  static const double _supersampleDensityTarget = 3.0;

  /// Reduced-tier art caps: backdrops at ~720p, masked by the gradient scrims
  /// drawn over them. Tiles (posters/thumbs/squares) deliberately keep full
  /// resolution — capping them reads as blur on large TV panels (#2020) —
  /// while backdrops are the largest RGBA decodes on screen.
  static const int _reducedMaxArtWidth = 1280;
  static const int _reducedMaxArtHeight = 720;

  /// Rounds a value up to the next multiple of [factor]. Shared between the
  /// URL dimension rounding (transcode bucket) and the mem-cache dimension
  /// rounding (decode bucket) so both snap to the same grid.
  ///
  /// The epsilon stops a value that is only floating-point noise above a
  /// bucket edge (`800 * 1.1` is 880.0000000000001) from spending a whole
  /// extra bucket.
  static int _bucketUp(num value, int factor) => ((value / factor) - 1e-9).ceil() * factor;

  /// Rounds dimensions to cache-friendly values to increase cache hit rate
  static (int width, int height) roundDimensions(double width, double height) {
    final budget = DevicePerformance.displayBudgetFactor();
    return (
      _bucketUp(width, _widthRoundingFactor).clamp(_minTranscodedWidth, (_maxTranscodedWidth * budget).round()),
      _bucketUp(height, _heightRoundingFactor).clamp(_minTranscodedHeight, (_maxTranscodedHeight * budget).round()),
    );
  }

  /// The display's true device pixel ratio, corrected where the reported value
  /// doesn't reflect physical density (Linux X11 with compositor scaling) and
  /// floored on TV. This is the paint density; anything that fetches or
  /// decodes artwork wants [artworkPixelRatio].
  static double _displayPixelRatio(BuildContext context) {
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

  /// Supersample factor for [imageType] at a display density of [dpr].
  ///
  /// Tapers from [_maxArtworkSupersample] to 1.0 as the display passes
  /// [_supersampleDensityTarget]. Backdrops opt out at every density: they are
  /// the largest RGBA decodes on screen and sit behind the gradient scrims
  /// that hide the softness this compensates for. The reduced tier opts out
  /// wholesale, like every other memory budget.
  static double _supersampleFor(ImageType imageType, double dpr) {
    if (DevicePerformance.isReduced || imageType == ImageType.art) return 1.0;
    return (_supersampleDensityTarget / dpr).clamp(1.0, _maxArtworkSupersample);
  }

  /// Density to fetch and decode [imageType] artwork at: the display's ratio
  /// plus whatever supersample headroom that density earns.
  ///
  /// Callers scale their logical slot by this before calling
  /// [getOptimizedImageUrl] and [getMemCacheDimensions], so the fetch and the
  /// decode cannot disagree.
  static double artworkPixelRatio(BuildContext context, {ImageType imageType = ImageType.poster}) {
    final dpr = _displayPixelRatio(context);
    return dpr * _supersampleFor(imageType, dpr);
  }

  /// Paint-time filter for [imageType], derived from the same predicate as
  /// [artworkPixelRatio] so the two cannot drift apart.
  ///
  /// Supersampled artwork paints as a real minification, which a bicubic
  /// kernel resolves at the same quality whatever the sub-pixel phase.
  /// [FilterQuality.medium] cannot: its mipmap blend snaps to a half-size
  /// level and then re-introduces the two-tap lerp on top, measuring worse
  /// than plain bilinear at every ratio this class produces. Without headroom
  /// there is nothing for cubic to resolve, so bilinear is both cheaper and
  /// no worse.
  static FilterQuality artworkFilterQuality(BuildContext context, ImageType imageType) =>
      _supersampleFor(imageType, _displayPixelRatio(context)) > 1 ? FilterQuality.high : FilterQuality.low;

  /// Physical artwork pixels to target for a [logicalWidth]-wide slot, for
  /// picking a pre-rendered CDN variant (catalog posters/backdrops) that has
  /// no width/height pair to run through [calculateOptimalDimensions].
  static int artworkTargetPx(BuildContext context, double logicalWidth, {ImageType imageType = ImageType.poster}) =>
      (logicalWidth * artworkPixelRatio(context, imageType: imageType)).ceil();

  /// Calculates optimal image dimensions based on image type and constraints.
  ///
  /// [pixelRatio] is the fetch density from [artworkPixelRatio], not the raw
  /// display ratio: it already carries any supersample headroom.
  static (int width, int height) calculateOptimalDimensions({
    required double maxWidth,
    required double maxHeight,
    required double pixelRatio,
    ImageType imageType = ImageType.poster,
  }) {
    final targetWidth = maxWidth.isFinite ? maxWidth * pixelRatio : 300 * pixelRatio;
    final targetHeight = maxHeight.isFinite ? maxHeight * pixelRatio : 450 * pixelRatio;

    switch (imageType) {
      case ImageType.art:
        if (DevicePerformance.isReduced) {
          // No 1.1× cover overshoot, capped at ~720p.
          return roundDimensions(
            min(targetWidth, _reducedMaxArtWidth.toDouble()),
            min(targetHeight, _reducedMaxArtHeight.toDouble()),
          );
        }
        final coverWidth = targetWidth * 1.1;
        final coverHeight = targetHeight * 1.1;

        return roundDimensions(coverWidth, coverHeight);

      case ImageType.logo:
      case ImageType.heroLogo:
        final logoWidth = targetWidth;
        final logoHeight = targetHeight;
        return roundDimensions(logoWidth, logoHeight);

      case ImageType.thumb:
        final thumbHeight = targetHeight;
        final thumbWidth = min(targetWidth, thumbHeight * (16 / 9));
        return roundDimensions(thumbWidth, thumbHeight);

      case ImageType.avatar:
      case ImageType.square:
        final size = min(targetWidth, targetHeight);
        return roundDimensions(size, size);

      case ImageType.poster:
        final calculatedWidth = min(targetWidth, targetHeight * (2 / 3));
        final calculatedHeight = calculatedWidth * (3 / 2);
        return roundDimensions(calculatedWidth, calculatedHeight);
    }
  }

  /// Whether [type] fills its slot ([BoxFit.cover]) or sits inside it
  /// ([BoxFit.contain]), which is what [MediaServerClient.thumbnailUrl]'s
  /// `cover` flag selects. Logos are the contain case: asking Plex to cover
  /// their slot overshoots the long axis by 20-30% in bytes, and the decode
  /// bounds throw those pixels away again.
  static bool _coversSlot(ImageType type) => switch (type) {
    ImageType.logo || ImageType.heroLogo => false,
    ImageType.art || ImageType.thumb || ImageType.poster || ImageType.avatar || ImageType.square => true,
  };

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
    required double pixelRatio,
    ImageType imageType = ImageType.poster,
  }) {
    if (thumbPath == null || thumbPath.isEmpty) return '';
    final basePath = thumbPath;

    if (basePath.startsWith('http://') || basePath.startsWith('https://')) {
      // Self-contained Jellyfin URLs already carry their own auth
      // (`api_key=...`). Append `maxWidth/maxHeight` so we still get DPR
      // scaling and cache-bucket rounding — Jellyfin's image endpoint
      // honours those query params.
      if (basePath.contains('api_key=')) {
        final (width, height) = calculateOptimalDimensions(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          pixelRatio: pixelRatio,
          imageType: imageType,
        );
        final uri = Uri.parse(basePath);
        final params = Map<String, String>.from(uri.queryParameters);
        final lowerKeys = params.keys.map((k) => k.toLowerCase()).toSet();
        if (!lowerKeys.contains('maxwidth') && !lowerKeys.contains('width')) {
          params['maxWidth'] = '$width';
        }
        if (!lowerKeys.contains('maxheight') && !lowerKeys.contains('height')) {
          params['maxHeight'] = '$height';
        }
        return uri.replace(queryParameters: params).toString();
      }

      // EPG / external URL — proxy through the server's transcoder. Plex
      // implements [externalImageUrl] via `/photo/:/transcode?url=...`;
      // backends without a comparable endpoint return the URL unchanged.
      if (client == null) return basePath;
      final (width, height) = calculateOptimalDimensions(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        pixelRatio: pixelRatio,
        imageType: imageType,
      );
      return client.externalImageUrl(basePath, width: width, height: height, cover: _coversSlot(imageType));
    }

    // Relative path — let the client build the sized URL using its native
    // size-hint params (`/photo/:/transcode` for Plex, `MaxWidth/MaxHeight`
    // for Jellyfin). The interface guarantees both honour width/height.
    if (client == null) {
      // Offline + relative path: the cached entry already exists under the
      // URL originally fetched, so returning '' matches pre-refactor behaviour.
      return '';
    }

    if (!shouldTranscode(basePath)) {
      return client.thumbnailUrl(basePath);
    }

    final (width, height) = calculateOptimalDimensions(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      pixelRatio: pixelRatio,
      imageType: imageType,
    );

    // Always request a sized transcode — even tiny slots. An unsized URL
    // hands the full original to the decoder, and a multi-megapixel
    // original behind a 40px avatar is exactly the decode spike that OOMs
    // low-RAM devices. The floor is 160×240 via [roundDimensions].
    return client.thumbnailUrl(basePath, width: width, height: height, cover: _coversSlot(imageType));
  }

  /// Generates cache-friendly dimensions for memory caching.
  ///
  /// Max bounds are type-aware so large originals (e.g. failed server
  /// transcodes or external EPG images) are capped at a resolution
  /// appropriate for the display context.
  static (int memWidth, int memHeight) getMemCacheDimensions({
    required int displayWidth,
    required int displayHeight,
    ImageType imageType = ImageType.poster,
  }) {
    // Bucket to match roundDimensions() so the mem-cache key and CNIP
    // maxHeight stay stable across sub-bucket resize deltas. Without this,
    // LayoutBuilder rebuilds during window resize churn the cache key on
    // every pixel and evict valid entries from Flutter's image cache.
    //
    // [displayWidth]/[displayHeight] come from the caller's slot scaled by
    // [artworkPixelRatio], so any supersample headroom is already in them and
    // the decode cannot disagree with the fetch.
    final bucketedWidth = _bucketUp(displayWidth, _widthRoundingFactor);
    final bucketedHeight = _bucketUp(displayHeight, _heightRoundingFactor);

    // Full-tier caps are a 1080p baseline scaled to the display, so slots on
    // a 4K surface decode at the resolution they render at instead of being
    // GPU-upscaled from phone-sized budgets. On the reduced tier the factor
    // is pinned to 1.0, so tiles keep the fixed 1080p baseline there; only
    // art gets an explicit smaller pair.
    final budget = DevicePerformance.displayBudgetFactor();
    int scaled(int cap) => (cap * budget).round();
    final (int maxW, int maxH) = switch (imageType) {
      ImageType.poster => (scaled(720), scaled(1080)),
      // Square music artwork fills the same grid cells as posters, so both
      // axes cap at the poster width budget.
      ImageType.square => (scaled(720), scaled(720)),
      ImageType.thumb => (scaled(960), scaled(540)),
      // Reduced-tier backdrops match the ~720p fetch cap so oversized
      // originals (failed transcodes, external images) can't decode past
      // the low-RAM art budget.
      ImageType.art when DevicePerformance.isReduced => (_reducedMaxArtWidth, _reducedMaxArtHeight),
      ImageType.art => (scaled(1920), scaled(1080)),
      ImageType.logo => (scaled(600), scaled(300)),
      ImageType.heroLogo => (scaled(1000), scaled(500)),
      ImageType.avatar => (scaled(300), scaled(300)),
    };

    return (bucketedWidth.clamp(120, maxW), bucketedHeight.clamp(180, maxH));
  }

  /// Wraps [provider] so the decode is bounded on **both** axes.
  ///
  /// `fit` policy keeps aspect ratio and never upscales, so an over-generous
  /// bound is harmless — but an oversized original (failed server transcode,
  /// local artwork file, ultra-wide banner) can no longer decode past the
  /// display budget the way a single-axis bound allows.
  static ImageProvider boundedDecode(ImageProvider provider, {required int memWidth, required int memHeight}) {
    final width = memWidth > 0 ? memWidth : null;
    final height = memHeight > 0 ? memHeight : null;
    if (width == null && height == null) return provider;
    return ResizeImage(provider, width: width, height: height, policy: ResizeImagePolicy.fit);
  }

  /// Selects the decode/transcode shape used by media cards and their
  /// prefetchers. Keeping this derived from [MediaItem.cardShape] prevents the
  /// renderer and prefetch pipeline from assigning different cache budgets.
  static ImageType cardImageType(MediaItem item, EpisodePosterMode episodePosterMode, {bool mixedHubContext = false}) {
    return switch (item.cardShape(episodePosterMode, mixedHubContext: mixedHubContext)) {
      CardShape.square => ImageType.square,
      CardShape.wide => ImageType.thumb,
      CardShape.poster => ImageType.poster,
    };
  }

  /// Creates the final provider for server-hosted artwork.
  ///
  /// The disk key deliberately depends only on the fully bucketed URL. Decode
  /// dimensions belong to Flutter's memory-cache key and must not fragment the
  /// shared disk cache during small layout changes.
  ///
  /// [logoToneTarget] wraps the decode in a [ToneMappedLogoImage] that
  /// recolors light-toned channel logos toward the given theme foreground so
  /// they stay legible on light surfaces. It participates only in the memory
  /// cache key; the disk cache keeps serving the original bytes.
  /// [logoToneRemapMixed] forwards the [ToneMappedLogoImage.remapMixed]
  /// policy.
  static ImageProvider serverArtworkProvider({
    required String imageUrl,
    required int memWidth,
    required int memHeight,
    Color? logoToneTarget,
    bool logoToneRemapMixed = true,
  }) {
    final provider = CachedNetworkImageProvider(
      imageUrl,
      cacheKey: _serverArtworkCacheKey(imageUrl),
      cacheManager: PlexImageCacheManager.instance,
      headers: const {'User-Agent': 'Plezy'},
    );
    final bounded = boundedDecode(provider, memWidth: memWidth, memHeight: memHeight);
    if (logoToneTarget == null) return bounded;
    return ToneMappedLogoImage(bounded, target: logoToneTarget, remapMixed: logoToneRemapMixed);
  }

  static final _serverArtworkCacheKeys = <String, String>{};
  static const _serverArtworkCacheKeyLimit = 512;

  static String _serverArtworkCacheKey(String imageUrl) {
    final cached = _serverArtworkCacheKeys.remove(imageUrl);
    if (cached != null) {
      _serverArtworkCacheKeys[imageUrl] = cached;
      return cached;
    }

    final key = 'plex_optimized_${sha1.convert(utf8.encode(imageUrl))}';
    if (_serverArtworkCacheKeys.length >= _serverArtworkCacheKeyLimit) {
      _serverArtworkCacheKeys.remove(_serverArtworkCacheKeys.keys.first);
    }
    _serverArtworkCacheKeys[imageUrl] = key;
    return key;
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
}
