import 'dart:io';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../providers/watch_state_store.dart';
import '../services/device_performance.dart';
import '../services/image_cache_service.dart';
import '../utils/content_utils.dart';
import '../utils/formatters.dart';
import '../utils/layout_constants.dart';
import '../utils/media_image_helper.dart';
import 'app_icon.dart';
import 'fitting_title_text.dart';
import 'media_rating_badge.dart';
import 'optimized_media_image.dart' show blurArtwork;
import 'rasterized_gradient.dart';

class TvSpotlightBackground extends StatelessWidget {
  final MediaItem? item;
  final MediaServerClient? client;
  final bool hideSpoilers;
  final double contentBottom;
  final double? contentTop;
  final double? contentLeft;
  final VoidCallback? onPrimaryAction;
  final Widget? actions;
  final bool compact;
  final bool showPrimaryAction;
  final bool showInfo;
  final String? Function(String? artworkPath)? localArtworkPathResolver;

  const TvSpotlightBackground({
    super.key,
    required this.item,
    required this.client,
    this.hideSpoilers = false,
    this.contentBottom = 360,
    this.contentTop,
    this.contentLeft,
    this.onPrimaryAction,
    this.actions,
    this.compact = false,
    this.showPrimaryAction = true,
    this.showInfo = true,
    this.localArtworkPathResolver,
  });

  double _scale(BuildContext context) => TvLayoutConstants.scaleOf(context);

  @override
  Widget build(BuildContext context) {
    final media = item;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    // The gradients never differ between spotlight items, so only the artwork
    // cross-fades — by image paint alpha, not widget opacity. The former
    // whole-stack AnimatedSwitcher kept two full-screen saveLayers (each with
    // a backdrop + two full-screen gradient fills) blending per frame on
    // every focus move, which alone saturated low-end TV GPUs while browsing.
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: blurArtwork(
            _SpotlightArtworkCrossfade(
              mediaKey: media?.globalKey,
              image: media == null ? null : _artworkProvider(context, media),
              duration: DevicePerformance.reducedDuration(const Duration(milliseconds: 280)),
              fallbackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              emptyColor: bgColor,
            ),
          ),
        ),
        _buildHorizontalScrim(bgColor),
        RasterizedGradient(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent, bgColor.withValues(alpha: 0.96)],
            stops: const [0.0, 0.38, 1.0],
          ),
        ),
        if (media != null && showInfo)
          Positioned(
            left: contentLeft ?? TvLayoutConstants.horizontalInset,
            right: MediaQuery.sizeOf(context).width * 0.43,
            top: contentTop,
            bottom: contentBottom,
            // The info block still cross-fades via AnimatedSwitcher, but its
            // saveLayers are bounded to the text region, not the screen.
            child: AnimatedSwitcher(
              duration: DevicePerformance.reducedDuration(const Duration(milliseconds: 280)),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              // Expand instead of the default loose centered Stack so the
              // info keeps filling the region and bottom-left aligning.
              layoutBuilder: (currentChild, previousChildren) =>
                  Stack(fit: StackFit.expand, children: [...previousChildren, ?currentChild]),
              child: KeyedSubtree(
                key: ValueKey(media.globalKey),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (!constraints.hasBoundedHeight || constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
                      return Align(alignment: .bottomLeft, child: _buildInfo(context, media));
                    }

                    return Align(
                      alignment: .bottomLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: .bottomLeft,
                        child: SizedBox(width: constraints.maxWidth, child: _buildInfo(context, media)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Resolves the backdrop image provider for [media]; null means "no art"
  /// (the crossfade shows [_SpotlightArtworkCrossfade.fallbackColor]).
  ImageProvider? _artworkProvider(BuildContext context, MediaItem media) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
    final containerAspect = size.width / size.height;
    final artCandidates = <String?>[
      media.heroArt(containerAspectRatio: containerAspect) ??
          media.grandparentArtPath ??
          media.artPath ??
          media.backgroundSquarePath ??
          media.thumbPath,
      media.grandparentArtPath,
      media.artPath,
      media.backgroundSquarePath,
      media.thumbPath,
    ];
    final (memWidth, memHeight) = MediaImageHelper.getMemCacheDimensions(
      displayWidth: (size.width * dpr).round(),
      displayHeight: (size.height * dpr).round(),
      imageType: ImageType.art,
    );

    for (final candidate in artCandidates) {
      final localPath = localArtworkPathResolver?.call(candidate);
      if (localPath != null && File(localPath).existsSync()) {
        // Local originals skipped the server transcode entirely, so the
        // decode bound is the only thing between a full-resolution art file
        // and the GPU on a low-RAM TV.
        return MediaImageHelper.boundedDecode(FileImage(File(localPath)), memWidth: memWidth, memHeight: memHeight);
      }
    }

    final artPath = artCandidates.firstWhere((path) => path != null && path.isNotEmpty, orElse: () => null);

    final imageUrl = MediaImageHelper.getOptimizedImageUrl(
      client: client,
      thumbPath: artPath,
      maxWidth: size.width,
      maxHeight: size.height,
      devicePixelRatio: dpr,
      imageType: ImageType.art,
    );

    if (imageUrl.isEmpty) return null;

    final provider = CachedNetworkImageProvider(imageUrl, cacheManager: PlexImageCacheManager.instance);
    return MediaImageHelper.boundedDecode(provider, memWidth: memWidth, memHeight: memHeight);
  }

  Widget _buildHorizontalScrim(Color bgColor) {
    return RasterizedGradient(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [bgColor.withValues(alpha: 0.86), bgColor.withValues(alpha: 0.32), Colors.transparent],
        stops: const [0.0, 0.56, 1.0],
      ),
    );
  }

  Widget _buildInfo(BuildContext context, MediaItem media) {
    final scale = _scale(context);
    final colorScheme = Theme.of(context).colorScheme;
    final shouldHideSpoiler = hideSpoilers && media.shouldHideSpoiler;
    final summary = shouldHideSpoiler ? null : media.summary;
    final title = media.grandparentTitle ?? media.displayTitle;

    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        _buildLogoOrTitle(context, media, title),
        SizedBox(height: _sectionGap(scale)),
        _buildMetadataLine(context, media),
        if (summary != null && summary.isNotEmpty) ...[
          SizedBox(height: _sectionGap(scale)),
          Text(
            summary,
            maxLines: compact ? 3 : 4,
            overflow: .ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.78),
              fontSize: _summaryFontSize(scale),
              height: compact ? 1.34 : 1.45,
            ),
          ),
        ] else if (shouldHideSpoiler && media.isEpisode) ...[
          SizedBox(height: _sectionGap(scale)),
          Text(
            media.title ?? '',
            maxLines: 2,
            overflow: .ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.72),
              fontSize: _summaryFontSize(scale),
              height: compact ? 1.34 : 1.45,
            ),
          ),
        ],
        if (showPrimaryAction || actions != null) ...[
          SizedBox(height: (compact ? 18 : 26) * scale),
          actions ?? _buildPrimaryAction(context, media),
        ],
      ],
    );
  }

  Widget _buildLogoOrTitle(BuildContext context, MediaItem media, String title) {
    final scale = _scale(context);
    final logoPath = media.clearLogoPath;
    final logoWidth = _logoWidth(scale);
    final logoHeight = _logoHeight(scale);
    if (logoPath == null || logoPath.isEmpty) {
      return SizedBox(width: logoWidth, height: logoHeight, child: _buildTitle(context, title));
    }

    final localLogoPath = localArtworkPathResolver?.call(logoPath);
    if (localLogoPath != null && File(localLogoPath).existsSync()) {
      return SizedBox(
        width: logoWidth,
        height: logoHeight,
        child: blurArtwork(
          Image.file(
            File(localLogoPath),
            fit: BoxFit.contain,
            alignment: .centerLeft,
            errorBuilder: (context, error, stackTrace) => _buildTitle(context, title),
          ),
          sigma: 10,
          clip: false,
        ),
      );
    }

    final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
    final imageUrl = MediaImageHelper.getOptimizedImageUrl(
      client: client,
      thumbPath: logoPath,
      maxWidth: logoWidth,
      maxHeight: logoHeight,
      devicePixelRatio: dpr,
      imageType: ImageType.logo,
    );
    if (imageUrl.isEmpty) return _buildTitle(context, title);

    return SizedBox(
      width: logoWidth,
      height: logoHeight,
      child: blurArtwork(
        CachedNetworkImage(
          imageUrl: imageUrl,
          cacheManager: PlexImageCacheManager.instance,
          fit: BoxFit.contain,
          alignment: .centerLeft,
          memCacheWidth: (logoWidth * dpr).clamp(200, 1000).round(),
          fadeInDuration: DevicePerformance.reducedDuration(const Duration(milliseconds: 200)),
          fadeOutDuration: DevicePerformance.reducedDuration(const Duration(milliseconds: 200)),
          placeholder: (context, url) => const SizedBox.shrink(),
          errorBuilder: (context, error, stackTrace) => _buildTitle(context, title),
        ),
        sigma: 10,
        clip: false,
      ),
    );
  }

  Widget _buildTitle(BuildContext context, String title) {
    final scale = _scale(context);
    final colorScheme = Theme.of(context).colorScheme;
    return FittingTitleText(
      title,
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
        color: colorScheme.onSurface,
        fontSize: _titleFontSize(scale),
        fontWeight: .w800,
        shadows: [Shadow(color: colorScheme.surface.withValues(alpha: 0.8), blurRadius: 12)],
      ),
    );
  }

  Widget _buildMetadataLine(BuildContext context, MediaItem media) {
    final scale = _scale(context);
    final colorScheme = Theme.of(context).colorScheme;
    final episodeLabel = formatSeasonEpisodeLabel(media.parentIndex, media.index);
    final textStyle = TextStyle(
      color: colorScheme.onSurface,
      fontSize: _metadataFontSize(scale),
      fontWeight: .w700,
      letterSpacing: 0.1,
    );
    final children = <Widget>[];

    void addSeparator() {
      if (children.isNotEmpty) children.add(Text('  •  ', maxLines: 1, style: textStyle));
    }

    void addTextPart(String text) {
      addSeparator();
      children.add(Text(text, maxLines: 1, style: textStyle));
    }

    void addWidgetPart(Widget widget) {
      addSeparator();
      children.add(widget);
    }

    if (media.isEpisode && episodeLabel != null) addTextPart(episodeLabel);
    if (media.isMovie) {
      addTextPart(t.discover.movie);
    } else if (media.isShow) {
      addTextPart(t.discover.tvShow);
    }
    final ratingBadge = MediaRatingBadge.inlineForMedia(
      item: media,
      foregroundColor: textStyle.color,
      iconSize: textStyle.fontSize,
      spacing: 4 * scale,
      textStyle: textStyle,
    );
    if (ratingBadge != null) {
      addWidgetPart(ratingBadge);
    }
    if (media.contentRating != null) addTextPart(formatContentRating(media.contentRating!));
    if (media.durationMs != null) addTextPart(formatDurationTextual(media.durationMs!));
    if (media.isEpisode && media.originallyAvailableAt != null) {
      addTextPart(formatFullDate(media.originallyAvailableAt!));
    } else if (media.year != null) {
      addTextPart(media.year.toString());
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  double _sectionGap(double scale) => (compact ? 10 : 16) * scale;

  double _logoWidth(double scale) =>
      (compact ? TvLayoutConstants.compactHeroLogoWidth : TvLayoutConstants.heroLogoWidth) * scale;

  double _logoHeight(double scale) =>
      (compact ? TvLayoutConstants.compactHeroLogoHeight : TvLayoutConstants.heroLogoHeight) * scale;

  double _titleFontSize(double scale) => (compact ? 44 : 54) * scale;

  double _metadataFontSize(double scale) => (compact ? 16 : 18) * scale;

  double _summaryFontSize(double scale) => (compact ? 18 : 20) * scale;

  Widget _buildPrimaryAction(BuildContext context, MediaItem media) {
    final scale = _scale(context);
    media = context.withFreshWatchState(media);
    final hasProgress = media.hasActiveProgress;
    final minutesLeft = hasProgress && media.durationMs != null && media.viewOffsetMs != null
        ? ((media.durationMs! - media.viewOffsetMs!) / 60_000).round()
        : 0;

    return GestureDetector(
      onTap: onPrimaryAction,
      child: Container(
        padding: .symmetric(horizontal: (compact ? 24 : 30) * scale, vertical: (compact ? 12 : 15) * scale),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32 * scale)),
        child: Row(
          mainAxisSize: .min,
          children: [
            AppIcon(Symbols.play_arrow_rounded, fill: 1, size: (compact ? 24 : 28) * scale, color: Colors.black),
            SizedBox(width: (compact ? 10 : 12) * scale),
            Text(
              hasProgress ? t.discover.minutesLeft(minutes: minutesLeft) : t.common.play,
              style: TextStyle(color: Colors.black, fontSize: (compact ? 16 : 18) * scale, fontWeight: .w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cross-fades full-screen backdrop art without saveLayers: the previous
/// image stays fully opaque underneath while the incoming one fades in via
/// `Image.opacity` (paint alpha in RawImage). The fade only starts once the
/// incoming image has a frame, so swaps never flash a placeholder — the old
/// backdrop simply stays until the new one is ready.
class _SpotlightArtworkCrossfade extends StatefulWidget {
  const _SpotlightArtworkCrossfade({
    required this.mediaKey,
    required this.image,
    required this.duration,
    required this.fallbackColor,
    required this.emptyColor,
  });

  /// Identity of the current spotlight item; fades trigger on changes.
  final String? mediaKey;

  /// null with a non-null [mediaKey] means "item without art" (fallback box);
  /// null with a null [mediaKey] means "no item" (empty box).
  final ImageProvider? image;
  final Duration duration;
  final Color fallbackColor;
  final Color emptyColor;

  @override
  State<_SpotlightArtworkCrossfade> createState() => _SpotlightArtworkCrossfadeState();
}

class _SpotlightArtworkCrossfadeState extends State<_SpotlightArtworkCrossfade> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this, duration: widget.duration);
  late String? _currentKey = widget.mediaKey;
  late ImageProvider? _base = widget.image;
  late Color _baseColor = widget.mediaKey == null ? widget.emptyColor : widget.fallbackColor;
  ImageProvider? _incoming;
  bool _incomingIsColor = false;
  Color _incomingColor = Colors.transparent;
  bool _incomingErrored = false;
  bool _incomingHasFrame = false;
  bool _fadeStarted = false;

  @override
  void didUpdateWidget(covariant _SpotlightArtworkCrossfade oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fade.duration = widget.duration;
    if (widget.mediaKey == _currentKey) {
      // Same item, possibly a re-resolved provider (size change): update the
      // settled base silently — gaplessPlayback covers the swap.
      if (widget.image != null && widget.image != _base && _incoming == null && !_incomingIsColor) {
        _base = widget.image;
      }
      return;
    }
    _currentKey = widget.mediaKey;
    final incomingColor = widget.mediaKey == null ? widget.emptyColor : widget.fallbackColor;
    if (widget.image != null && widget.image == _base) {
      // Same artwork (e.g. episodes sharing show art): nothing to fade.
      _dropIncoming();
      return;
    }
    setState(() {
      _fade.stop();
      _fade.value = 0;
      _fadeStarted = false;
      _incomingErrored = false;
      _incomingHasFrame = false;
      if (widget.image != null) {
        _incoming = widget.image;
        _incomingIsColor = false;
      } else {
        _incoming = null;
        _incomingIsColor = true;
        _incomingColor = incomingColor;
        _startFade(); // no frame to wait for
      }
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  void _startFade() {
    if (_fadeStarted) return;
    _fadeStarted = true;
    _fade.forward().whenComplete(_promoteIncoming);
  }

  void _promoteIncoming() {
    if (!mounted || (_incoming == null && !_incomingIsColor)) return;
    setState(() {
      if (_incomingIsColor) {
        _base = null;
        _baseColor = _incomingColor;
      } else if (_incomingErrored || !_incomingHasFrame) {
        // Never promote a provider that produced no frame: the base would
        // re-resolve (and re-fail) it. Settle on the fallback box instead.
        _base = null;
        _baseColor = widget.fallbackColor;
      } else {
        _base = _incoming;
      }
      _dropIncoming();
    });
  }

  void _dropIncoming() {
    _incoming = null;
    _incomingIsColor = false;
    _incomingErrored = false;
    _incomingHasFrame = false;
    _fadeStarted = false;
    _fade.value = 0;
  }

  Widget _image(ImageProvider provider, {Animation<double>? opacity}) {
    final isIncoming = opacity != null;
    return Image(
      // Keyed by provider so a replaced incoming gets a fresh element — the
      // framework never clears a retained error on provider swap, which would
      // flash the previous item's failure at the next fade.
      key: isIncoming ? ValueKey<ImageProvider>(provider) : null,
      image: provider,
      fit: BoxFit.cover,
      excludeFromSemantics: true,
      // Keeps the previous frame on provider promotion instead of flashing.
      gaplessPlayback: true,
      opacity: opacity,
      frameBuilder: !isIncoming
          ? null
          : (context, child, frame, wasSynchronouslyLoaded) {
              if (frame != null || wasSynchronouslyLoaded) {
                _incomingHasFrame = true;
                _startFade();
              }
              return child;
            },
      errorBuilder: !isIncoming
          // The settled base must show a static fallback: anything riding
          // _fade here would flash transparent when the controller resets
          // for the next swap.
          ? (context, error, stackTrace) => ColoredBox(color: widget.fallbackColor)
          : (context, error, stackTrace) {
              // Broken incoming art: fade a plain box in instead (bounded to
              // the error case); promotion then settles on the color, not
              // the dead provider.
              _incomingErrored = true;
              _startFade();
              return FadeTransition(
                opacity: _fade,
                child: ColoredBox(color: widget.fallbackColor),
              );
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_base != null) _image(_base!) else ColoredBox(color: _baseColor),
        if (_incoming != null) _image(_incoming!, opacity: _fade),
        if (_incomingIsColor)
          AnimatedBuilder(
            animation: _fade,
            builder: (context, _) =>
                ColoredBox(color: _incomingColor.withValues(alpha: _incomingColor.a * _fade.value)),
          ),
      ],
    );
  }
}
