import 'dart:io';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../providers/watch_state_store.dart';
import '../services/image_cache_service.dart';
import '../utils/content_utils.dart';
import '../utils/formatters.dart';
import '../utils/layout_constants.dart';
import '../utils/media_image_helper.dart';
import 'app_icon.dart';
import 'fitting_title_text.dart';
import 'optimized_media_image.dart' show blurArtwork;

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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: SizedBox.expand(
        key: ValueKey(media?.globalKey ?? 'empty_spotlight'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (media != null) _buildArtwork(context, media) else ColoredBox(color: bgColor),
            _buildHorizontalScrim(bgColor),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent, bgColor.withValues(alpha: 0.96)],
                  stops: const [0.0, 0.38, 1.0],
                ),
              ),
            ),
            if (media != null && showInfo)
              Positioned(
                left: contentLeft ?? TvLayoutConstants.horizontalInset,
                right: MediaQuery.sizeOf(context).width * 0.43,
                top: contentTop,
                bottom: contentBottom,
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
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork(BuildContext context, MediaItem media) {
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
    for (final candidate in artCandidates) {
      final localPath = localArtworkPathResolver?.call(candidate);
      if (localPath != null && File(localPath).existsSync()) {
        return blurArtwork(
          Image.file(
            File(localPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
          ),
        );
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

    if (imageUrl.isEmpty) {
      return ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest);
    }

    final (_, memHeight) = MediaImageHelper.getMemCacheDimensions(
      displayWidth: (size.width * dpr).round(),
      displayHeight: (size.height * dpr).round(),
      imageType: ImageType.art,
    );

    return blurArtwork(
      CachedNetworkImage(
        imageUrl: imageUrl,
        cacheManager: PlexImageCacheManager.instance,
        fit: BoxFit.cover,
        memCacheHeight: memHeight,
        placeholder: (context, url) => ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
        errorBuilder: (context, error, stackTrace) =>
            ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
      ),
    );
  }

  Widget _buildHorizontalScrim(Color bgColor) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [bgColor.withValues(alpha: 0.86), bgColor.withValues(alpha: 0.32), Colors.transparent],
          stops: const [0.0, 0.56, 1.0],
        ),
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
    final parts = [
      if (media.isEpisode && episodeLabel != null) episodeLabel,
      if (media.isMovie) t.discover.movie else if (media.isShow) t.discover.tvShow,
      if (media.rating != null) '★ ${formatRating(media.rating!)}',
      if (media.contentRating != null) formatContentRating(media.contentRating!),
      if (media.durationMs != null) formatDurationTextual(media.durationMs!),
      if (media.isEpisode && media.originallyAvailableAt != null)
        formatFullDate(media.originallyAvailableAt!)
      else if (media.year != null)
        media.year.toString(),
    ];
    return Text(
      parts.join('  •  '),
      maxLines: 1,
      overflow: .ellipsis,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: _metadataFontSize(scale),
        fontWeight: .w700,
        letterSpacing: 0.1,
      ),
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
