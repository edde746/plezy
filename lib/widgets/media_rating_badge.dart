import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../media/media_item.dart';
import '../media/media_rating.dart';
import '../utils/formatters.dart';
import '../utils/rating_utils.dart';
import 'app_icon.dart';

enum MediaRatingBadgeVariant { chip, inline }

/// Every attributed score for [item], falling back to [fallbackItem] as a
/// whole rather than per-source — a show's ratings never mix with an
/// episode's.
List<MediaRatingSource> mediaRatingsFor(MediaItem item, {MediaItem? fallbackItem}) {
  final ratings = _ratingsFor(item);
  if (ratings.isNotEmpty || fallbackItem == null) return ratings;
  return _ratingsFor(fallbackItem);
}

/// Formatted value for [rating] — the brand badge's own formatting where the
/// source has one, otherwise the neutral 0-10 rendering.
String mediaRatingLabel(MediaRatingSource rating) =>
    ratingInfoForSource(rating.source, rating.value)?.formattedValue ?? formatRating(rating.value);

List<MediaRatingSource> _ratingsFor(MediaItem item) {
  final ratings = item.ratings;
  if (ratings != null && ratings.isNotEmpty) return ratings;
  // Backends that report a bare score with no provenance (and cached rows
  // written before the attributed list existed) still get one badge.
  final rating = item.rating;
  return rating == null ? const [] : [MediaRatingSource(source: '', value: rating)];
}

/// Every attributed score an item carries, side by side.
///
/// A Plex detail response yields up to four (Rotten Tomatoes critic and
/// audience, IMDb, TMDB); a library listing yields the one or two the server
/// sends with it; Jellyfin yields its community score and Tomatometer. The
/// group renders whatever is there and collapses to a single badge when that
/// is all the response carried — no extra requests are made to lengthen it.
///
/// `chip` wraps the whole set in one pill so a badge row's element count does
/// not grow with the number of sources. `inline` is the bare row, for
/// single-line metadata strips that already own their own separators.
class MediaRatingBadgeGroup extends StatelessWidget {
  const MediaRatingBadgeGroup.chip({
    super.key,
    required this.item,
    this.fallbackItem,
    this.textStyle,
    this.foregroundColor,
    this.backgroundColor,
    this.iconSize,
    this.padding,
    this.spacing,
    this.entrySpacing,
  }) : variant = MediaRatingBadgeVariant.chip;

  const MediaRatingBadgeGroup.inline({
    super.key,
    required this.item,
    this.fallbackItem,
    this.textStyle,
    this.foregroundColor,
    this.iconSize,
    this.spacing,
    this.entrySpacing,
  }) : variant = MediaRatingBadgeVariant.inline,
       backgroundColor = null,
       padding = EdgeInsets.zero;

  final MediaItem item;

  /// Consulted only when [item] carries no ratings at all — an episode row
  /// borrowing its show's scores.
  final MediaItem? fallbackItem;
  final MediaRatingBadgeVariant variant;
  final TextStyle? textStyle;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;

  /// Gap between a badge's icon and its value.
  final double? spacing;

  /// Gap between adjacent scores.
  final double? entrySpacing;

  /// Null when the item has no score at all, so callers can omit the slot
  /// instead of rendering an empty pill.
  static MediaRatingBadgeGroup? inlineForMedia({
    required MediaItem item,
    MediaItem? fallbackItem,
    TextStyle? textStyle,
    Color? foregroundColor,
    double? iconSize,
    double? spacing,
    double? entrySpacing,
  }) {
    if (mediaRatingsFor(item, fallbackItem: fallbackItem).isEmpty) return null;
    return MediaRatingBadgeGroup.inline(
      item: item,
      fallbackItem: fallbackItem,
      textStyle: textStyle,
      foregroundColor: foregroundColor,
      iconSize: iconSize,
      spacing: spacing,
      entrySpacing: entrySpacing,
    );
  }

  /// Every score read out as `<source> <value>`, for the metadata-line
  /// announcement. Falls back to the bare value where the source is unnamed.
  static String? semanticLabelForMedia(MediaItem item, {MediaItem? fallbackItem}) {
    final ratings = mediaRatingsFor(item, fallbackItem: fallbackItem);
    return ratings.isEmpty ? null : _semanticLabelFor(ratings);
  }

  static String _semanticLabelFor(List<MediaRatingSource> ratings) => [
    for (final rating in ratings)
      switch (ratingSourceLabel(rating.source)) {
        final label? => '$label ${mediaRatingLabel(rating)}',
        null => mediaRatingLabel(rating),
      },
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    final ratings = mediaRatingsFor(item, fallbackItem: fallbackItem);
    if (ratings.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final isInline = variant == MediaRatingBadgeVariant.inline;
    final foreground = foregroundColor ?? (isInline ? colorScheme.onSurface : colorScheme.onSecondaryContainer);
    final style = _resolveTextStyle(textStyle, foreground, isInline);
    final gap = entrySpacing ?? 10;

    final children = <Widget>[];
    for (final rating in ratings) {
      if (children.isNotEmpty) children.add(SizedBox(width: gap));
      children.add(
        _buildContent(
          source: rating.source,
          value: rating.value,
          // Plex's own critic/audience split is the only place the generic
          // icons still carry meaning; every branded source draws its logo.
          fallbackIcon: rating.source == 'audience' ? Symbols.people_rounded : Symbols.star_rounded,
          foreground: foreground,
          style: style,
          iconSize: iconSize,
          spacing: spacing,
        ),
      );
    }

    // A bare row reads as a run of unattributed numbers once more than one
    // source is present, so the whole group announces itself as one node
    // naming each source. Parents that build their own merged announcement
    // (the TV metadata line) exclude this subtree anyway.
    final content = Semantics(
      label: _semanticLabelFor(ratings),
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
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

TextStyle _resolveTextStyle(TextStyle? textStyle, Color foreground, bool isInline) {
  return (textStyle ??
          TextStyle(color: foreground, fontSize: 13, fontWeight: isInline ? FontWeight.w700 : FontWeight.w600))
      .copyWith(color: textStyle?.color ?? foreground);
}

Widget _buildContent({
  required String? source,
  required double value,
  required IconData fallbackIcon,
  required Color foreground,
  required TextStyle style,
  required double? iconSize,
  required double? spacing,
}) {
  final size = iconSize ?? style.fontSize ?? 13;
  final info = source == null ? null : ratingInfoForSource(source, value);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (info != null)
        SvgPicture.asset(info.assetPath, width: size, height: size)
      else
        AppIcon(fallbackIcon, fill: 1, color: foreground, size: size),
      SizedBox(width: spacing ?? 4),
      Text(info?.formattedValue ?? formatRating(value), maxLines: 1, overflow: TextOverflow.clip, style: style),
    ],
  );
}
