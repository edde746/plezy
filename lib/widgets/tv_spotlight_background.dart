import 'dart:io';

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../services/device_performance.dart';
import '../utils/content_utils.dart';
import '../utils/formatters.dart';
import '../utils/layout_constants.dart';
import '../utils/media_image_helper.dart';
import '../services/settings_service.dart';
import '../utils/tone_mapped_logo_image.dart';
import 'cycling_media_backdrop.dart';
import 'fitting_title_text.dart';
import 'fitted_metadata_line.dart';
import 'settings_builder.dart';
import 'media_rating_badge.dart';
import 'optimized_media_image.dart' show ClearLogoImage, blurArtwork;
import 'rasterized_gradient.dart';

class TvSpotlightBackground extends StatelessWidget {
  final MediaItem? item;
  final MediaServerClient? client;
  final bool hideSpoilers;
  final double contentBottom;
  final double? contentTop;
  final double? contentLeft;
  final bool compact;
  final bool showInfo;
  final String? Function(String? artworkPath)? localArtworkPathResolver;
  final bool allowNetwork;

  /// Optional caller-owned fact appended to the existing metadata line.
  final Widget? metadataTrailing;

  const TvSpotlightBackground({
    super.key,
    required this.item,
    required this.client,
    this.hideSpoilers = false,
    this.contentBottom = 360,
    this.contentTop,
    this.contentLeft,
    this.compact = false,
    this.showInfo = true,
    this.localArtworkPathResolver,
    this.allowNetwork = true,
    this.metadataTrailing,
  });

  double _scale(BuildContext context) => TvLayoutConstants.scaleOf(context);

  @override
  Widget build(BuildContext context) {
    final media = item;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    // The gradients never differ between spotlight items, so only the artwork
    // cross-fades by image paint alpha. Keeping the gradients outside the
    // rotating layer avoids full-screen saveLayers on low-end TVs.
    final size = MediaQuery.sizeOf(context);
    final containerAspect = size.width / size.height;
    final fallbackPaths = media == null
        ? const <String>[]
        : <String>[...media.heroArtCandidates(containerAspectRatio: containerAspect), ?media.thumbPath];
    return SettingValueBuilder<bool>(
      pref: SettingsService.tvCornerSpotlightBackdrop,
      builder: (context, cornerBackdrop, _) {
        final backdropSize = cornerBackdrop ? Size(size.width * 0.68, size.height * 0.72) : size;
        final backdrop = CyclingMediaBackdrop(
          mediaKey: media?.globalKey,
          imagePaths: media?.heroRotationPaths(containerAspectRatio: containerAspect) ?? const [],
          fallbackImagePaths: fallbackPaths,
          client: client,
          localArtworkPathResolver: localArtworkPathResolver == null ? null : (path) => localArtworkPathResolver!(path),
          allowNetwork: allowNetwork,
          // Always request at full-screen size: the corner box only crops the
          // layout. A mode-dependent size would change the transcode URL and
          // cold-start every cached backdrop when the setting is toggled.
          width: size.width,
          height: size.height,
          fallbackColor: media == null ? bgColor : Theme.of(context).colorScheme.surfaceContainerHighest,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: cornerBackdrop ? _buildCornerBackdrop(backdropSize, backdrop) : blurArtwork(backdrop),
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
      },
    );
  }

  /// Corner spotlight: artwork pinned to the top-right corner, left and
  /// bottom edges feathered into the scaffold background so the info block
  /// sits on a calm surface instead of the image.
  Widget _buildCornerBackdrop(Size backdropSize, Widget backdrop) {
    return Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        width: backdropSize.width,
        height: backdropSize.height,
        child: ShaderMask(
          shaderCallback: (rect) =>
              const LinearGradient(colors: [Colors.transparent, Colors.white], stops: [0.0, 0.35]).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.55, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: backdrop,
          ),
        ),
      ),
    );
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
      ],
    );
  }

  Widget _buildLogoOrTitle(BuildContext context, MediaItem media, String title) {
    final theme = Theme.of(context);
    // The spotlight scrim washes artwork toward the scaffold background, so
    // light themes recolor light-toned logos to stay visible.
    final logoToneTarget = logoToneTargetFor(
      surface: theme.scaffoldBackgroundColor,
      foreground: theme.colorScheme.onSurface,
    );
    final scale = _scale(context);
    final logoPath = media.clearLogoPath;
    final logoWidth = _logoWidth(scale);
    final logoHeight = _logoHeight(scale);
    if (logoPath == null || logoPath.isEmpty) {
      return SizedBox(width: logoWidth, height: logoHeight, child: _buildTitle(context, title));
    }
    final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
    final (logoMemWidth, logoMemHeight) = MediaImageHelper.getMemCacheDimensions(
      displayWidth: (logoWidth * dpr).round(),
      displayHeight: (logoHeight * dpr).round(),
      imageType: ImageType.heroLogo,
    );

    final localLogoPath = localArtworkPathResolver?.call(logoPath);
    if (localLogoPath != null && File(localLogoPath).existsSync()) {
      final bounded = MediaImageHelper.boundedDecode(
        FileImage(File(localLogoPath)),
        memWidth: logoMemWidth,
        memHeight: logoMemHeight,
      );
      return SizedBox(
        width: logoWidth,
        height: logoHeight,
        child: blurArtwork(
          Image(
            image: logoToneTarget == null
                ? bounded
                : ToneMappedLogoImage(bounded, target: logoToneTarget, remapMixed: false),
            fit: BoxFit.contain,
            alignment: .centerLeft,
            errorBuilder: (context, error, stackTrace) => _buildTitle(context, title),
          ),
          sigma: 10,
          clip: false,
        ),
      );
    }

    return ClearLogoImage(
      client: client,
      logoPath: logoPath,
      width: logoWidth,
      height: logoHeight,
      fadeInDuration: DevicePerformance.reducedDuration(const Duration(milliseconds: 200)),
      logoToneTarget: logoToneTarget,
      fallbackBuilder: (context) => _buildTitle(context, title),
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

    final parts = <MetadataLinePart>[];
    if (media.isEpisode && episodeLabel != null) parts.add(MetadataLineText(episodeLabel, dropPriority: 0));
    if (media.isMovie) {
      parts.add(MetadataLineText(t.discover.movie, dropPriority: 3));
    } else if (media.isShow) {
      parts.add(MetadataLineText(t.discover.tvShow, dropPriority: 3));
    }
    // Hub listings carry the scalar rating pair, so the dashboard spotlight
    // shows every score the shelf request already returned — no per-item
    // hydration to lengthen it.
    final ratings = mediaRatingsFor(media);
    if (ratings.isNotEmpty) parts.add(MetadataLineRatings(ratings, dropPriority: 4));
    if (media.contentRating != null) {
      parts.add(MetadataLineText(formatContentRating(media.contentRating!), dropPriority: 2));
    }
    if (media.durationMs != null) {
      parts.add(MetadataLineText(formatDurationTextual(media.durationMs!), dropPriority: 1));
    }
    if (media.isEpisode && media.originallyAvailableAt != null) {
      parts.add(MetadataLineText(formatFullDate(media.originallyAvailableAt!), dropPriority: 0));
    } else if (media.year != null) {
      parts.add(MetadataLineText(media.year.toString(), dropPriority: 0));
    }

    final line = parts.isEmpty
        ? null
        : FittedMetadataLine(
            textStyle: textStyle,
            parts: parts,
            ratingIconSize: textStyle.fontSize,
            ratingSpacing: 4 * scale,
            ratingEntrySpacing: 12 * scale,
          );
    final trailing = metadataTrailing;
    if (trailing == null) return line ?? const SizedBox.shrink();
    if (line == null) return trailing;
    // The trailing fact is caller-owned and always shown; the line fits
    // itself into whatever width the trailing widget leaves over.
    return Row(
      mainAxisSize: .min,
      children: [
        Flexible(child: line),
        Text(FittedMetadataLine.separator, maxLines: 1, style: textStyle),
        trailing,
      ],
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
}
