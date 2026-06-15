import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../media/media_item.dart';
import '../utils/formatters.dart';
import '../utils/rating_utils.dart';
import 'app_icon.dart';

enum MediaRatingBadgeVariant { chip, inline }

class MediaRatingBadge extends StatelessWidget {
  const MediaRatingBadge.chip({
    super.key,
    required this.value,
    required this.fallbackIcon,
    this.imageUri,
    this.fallbackText,
    this.textStyle,
    this.foregroundColor,
    this.backgroundColor,
    this.iconSize,
    this.padding,
    this.spacing,
  }) : variant = MediaRatingBadgeVariant.chip;

  const MediaRatingBadge.inline({
    super.key,
    required this.value,
    required this.fallbackIcon,
    this.imageUri,
    this.fallbackText,
    this.textStyle,
    this.foregroundColor,
    this.iconSize,
    this.spacing,
  }) : variant = MediaRatingBadgeVariant.inline,
       backgroundColor = null,
       padding = EdgeInsets.zero;

  final String? imageUri;
  final double value;
  final IconData fallbackIcon;
  final String? fallbackText;
  final MediaRatingBadgeVariant variant;
  final TextStyle? textStyle;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final double? spacing;

  static MediaRatingBadge? inlineForMedia({
    required MediaItem item,
    MediaItem? fallbackItem,
    TextStyle? textStyle,
    Color? foregroundColor,
    double? iconSize,
    double? spacing,
  }) {
    final data = _ratingDataFor(item) ?? (fallbackItem == null ? null : _ratingDataFor(fallbackItem));
    if (data == null) return null;

    return MediaRatingBadge.inline(
      imageUri: data.imageUri,
      value: data.value,
      fallbackIcon: data.fallbackIcon,
      fallbackText: data.fallbackText,
      foregroundColor: foregroundColor,
      iconSize: iconSize,
      spacing: spacing,
      textStyle: textStyle,
    );
  }

  static _MediaRatingBadgeData? _ratingDataFor(MediaItem item) {
    final plex = item is PlexMediaItem ? item : null;
    final rating = item.rating;
    if (rating != null) {
      return _MediaRatingBadgeData(
        imageUri: plex?.ratingImage,
        value: rating,
        fallbackIcon: Symbols.star_rounded,
        fallbackText: formatRating(rating),
      );
    }

    final audienceRating = plex?.audienceRating;
    if (audienceRating != null) {
      return _MediaRatingBadgeData(
        imageUri: plex?.audienceRatingImage,
        value: audienceRating,
        fallbackIcon: Symbols.people_rounded,
        fallbackText: '${(audienceRating * 10).toStringAsFixed(0)}%',
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isInline = variant == MediaRatingBadgeVariant.inline;
    final foreground = foregroundColor ?? (isInline ? colorScheme.onSurface : colorScheme.onSecondaryContainer);
    final style =
        (textStyle ??
                TextStyle(color: foreground, fontSize: 13, fontWeight: isInline ? FontWeight.w700 : FontWeight.w600))
            .copyWith(color: textStyle?.color ?? foreground);
    final size = iconSize ?? style.fontSize ?? 13;
    final info = parseRatingImage(imageUri, value);
    final label = info?.formattedValue ?? fallbackText ?? '${(value * 10).toStringAsFixed(0)}%';
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (info != null)
          SvgPicture.asset(info.assetPath, width: size, height: size)
        else
          AppIcon(fallbackIcon, fill: 1, color: foreground, size: size),
        SizedBox(width: spacing ?? (isInline ? 4 : 4)),
        Text(label, maxLines: 1, overflow: TextOverflow.clip, style: style),
      ],
    );

    if (isInline) return content;

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.secondaryContainer.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.all(Radius.circular(100)),
      ),
      child: content,
    );
  }
}

class _MediaRatingBadgeData {
  const _MediaRatingBadgeData({
    required this.value,
    required this.fallbackIcon,
    required this.fallbackText,
    this.imageUri,
  });

  final String? imageUri;
  final double value;
  final IconData fallbackIcon;
  final String fallbackText;
}
