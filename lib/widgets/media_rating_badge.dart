import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../media/media_item.dart';
import '../media/media_rating.dart';
import '../utils/formatters.dart';
import '../utils/rating_utils.dart';
import 'app_icon.dart';

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

/// Every score read out as `<source> <value>`, for merged metadata-line
/// announcements. Falls back to the bare value where the source is unnamed.
String ratingsSemanticLabel(List<MediaRatingSource> ratings) => [
  for (final rating in ratings)
    switch (ratingSourceLabel(rating.source)) {
      final label? => '$label ${mediaRatingLabel(rating)}',
      null => mediaRatingLabel(rating),
    },
].join(', ');

/// Width one badge occupies on an inline strip — icon, gap, and formatted
/// value — mirroring [InlineRatingBadges]'s per-badge layout so a metadata
/// line can decide how many badges fit before building them (#1893).
///
/// [textStyle] must be the effective style the strip's [Text]s resolve to:
/// the caller's style merged over the ambient [DefaultTextStyle].
double inlineRatingBadgeWidth(
  MediaRatingSource rating, {
  required TextStyle textStyle,
  required TextScaler textScaler,
  required TextDirection textDirection,
  double? iconSize,
  double? spacing,
}) {
  final size = iconSize ?? textStyle.fontSize ?? 13;
  final info = ratingInfoForSource(rating.source, rating.value);
  final painter = TextPainter(
    text: TextSpan(text: mediaRatingLabel(rating), style: textStyle),
    textDirection: textDirection,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  final width = size * (info?.iconAspect ?? 1) + (spacing ?? 4) + painter.width;
  painter.dispose();
  return width;
}

/// The bare badge row for an explicit list of scores, for single-line
/// metadata strips that already own their separators.
///
/// A bare row reads as a run of unattributed numbers once more than one
/// source is present, so the whole group announces itself as one node naming
/// each source. Parents that build their own merged announcement (the TV
/// detail line) exclude this subtree anyway.
class InlineRatingBadges extends StatelessWidget {
  const InlineRatingBadges({
    super.key,
    required this.ratings,
    this.textStyle,
    this.foregroundColor,
    this.iconSize,
    this.spacing,
    this.entrySpacing,
  });

  final List<MediaRatingSource> ratings;
  final TextStyle? textStyle;
  final Color? foregroundColor;
  final double? iconSize;

  /// Gap between a badge's icon and its value.
  final double? spacing;

  /// Gap between adjacent scores.
  final double? entrySpacing;

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty) return const SizedBox.shrink();

    final foreground = foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    final style = (textStyle ?? TextStyle(color: foreground, fontSize: 13, fontWeight: FontWeight.w700)).copyWith(
      color: textStyle?.color ?? foreground,
    );
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

    return Semantics(
      label: ratingsSemanticLabel(ratings),
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
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
        // A tight box at the viewBox's own aspect: identical to the svg's
        // natural fit at this height, but with a width that is known before
        // layout so fitted lines can measure a badge exactly (#1893).
        SizedBox(width: size * info.iconAspect, height: size, child: SvgPicture.asset(info.assetPath))
      else
        AppIcon(fallbackIcon, fill: 1, color: foreground, size: size),
      SizedBox(width: spacing ?? 4),
      Text(info?.formattedValue ?? formatRating(value), maxLines: 1, overflow: TextOverflow.clip, style: style),
    ],
  );
}
