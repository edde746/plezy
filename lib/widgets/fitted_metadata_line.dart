import 'package:flutter/material.dart';

import '../media/media_rating.dart';
import '../utils/text_measure_cache.dart';
import 'media_rating_badge.dart';

/// One slot on a [FittedMetadataLine].
sealed class MetadataLinePart {
  const MetadataLinePart({required this.dropPriority});

  /// Which parts give way first when the line overflows: higher values are
  /// dropped before lower ones, rightmost first among equals. A
  /// [MetadataLineRatings] slot sheds one badge at a time from the end before
  /// the slot disappears.
  final int dropPriority;
}

/// A plain text field: year, certification, runtime, a quality label.
class MetadataLineText extends MetadataLinePart {
  const MetadataLineText(this.text, {required super.dropPriority});

  final String text;
}

/// The attributed-score slot. Every score shares this one slot so the bullet
/// separators don't multiply with the number of sources.
class MetadataLineRatings extends MetadataLinePart {
  const MetadataLineRatings(this.ratings, {required super.dropPriority});

  final List<MediaRatingSource> ratings;
}

/// A single-line metadata strip that sheds its least useful parts instead of
/// clipping at the edge (#1893).
///
/// Parts render in list order, separated by bullets. When the assembled line
/// is wider than the incoming constraints, whole units — a text part, or one
/// rating badge — are removed by [MetadataLinePart.dropPriority] until the
/// rest fits, so the tail of the line never silently vanishes under a hard
/// cutoff.
class FittedMetadataLine extends StatelessWidget {
  const FittedMetadataLine({
    super.key,
    required this.textStyle,
    required this.parts,
    this.ratingIconSize,
    this.ratingSpacing,
    this.ratingEntrySpacing,
  });

  /// Style shared by every text part, the separators, and the badge values.
  final TextStyle textStyle;
  final List<MetadataLinePart> parts;

  /// Icon size inside the ratings slot; defaults to the text's font size.
  final double? ratingIconSize;

  /// Gap between a badge's icon and its value.
  final double? ratingSpacing;

  /// Gap between adjacent badges inside the ratings slot.
  final double? ratingEntrySpacing;

  /// Also for callers that append their own trailing widget to the line.
  static const String separator = '  •  ';

  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        // Text merges its style over the ambient default, so measuring with
        // the bare style would drop the theme's font metrics.
        final effectiveStyle = DefaultTextStyle.of(context).style.merge(textStyle);
        final textScaler = MediaQuery.textScalerOf(context);
        final textDirection = Directionality.of(context);
        final iconSize = ratingIconSize ?? effectiveStyle.fontSize ?? 13;
        final badgeGap = ratingSpacing ?? 4;
        final entryGap = ratingEntrySpacing ?? 10;

        double textWidth(String text) => cachedSingleLineTextSize(
          text,
          style: effectiveStyle,
          textScaler: textScaler,
          textDirection: textDirection,
        ).width;

        // Units are the droppable atoms: a text part is one unit, a ratings
        // slot is one unit per badge.
        final unitWidths = <List<double>>[
          for (final part in parts)
            switch (part) {
              MetadataLineText(:final text) => <double>[textWidth(text)],
              MetadataLineRatings(:final ratings) => <double>[
                for (final rating in ratings)
                  inlineRatingBadgeWidth(
                    rating,
                    textStyle: effectiveStyle,
                    textScaler: textScaler,
                    textDirection: textDirection,
                    iconSize: iconSize,
                    spacing: badgeGap,
                  ),
              ],
            },
        ];
        final keptUnits = [for (final widths in unitWidths) widths.length];
        final separatorWidth = textWidth(separator);

        double partWidth(int index) {
          final kept = keptUnits[index];
          var width = 0.0;
          for (var unit = 0; unit < kept; unit++) {
            width += unitWidths[index][unit];
          }
          if (kept > 1) width += entryGap * (kept - 1);
          return width;
        }

        double totalWidth() {
          var total = 0.0;
          var keptParts = 0;
          for (var index = 0; index < parts.length; index++) {
            if (keptUnits[index] == 0) continue;
            total += partWidth(index);
            keptParts++;
          }
          if (keptParts > 1) total += separatorWidth * (keptParts - 1);
          return total;
        }

        if (constraints.hasBoundedWidth) {
          while (totalWidth() > constraints.maxWidth) {
            var dropIndex = -1;
            for (var index = 0; index < parts.length; index++) {
              if (keptUnits[index] == 0) continue;
              if (dropIndex == -1 || parts[index].dropPriority >= parts[dropIndex].dropPriority) dropIndex = index;
            }
            if (dropIndex == -1) break;
            keptUnits[dropIndex]--;
          }
        }

        final children = <Widget>[];
        for (var index = 0; index < parts.length; index++) {
          final kept = keptUnits[index];
          if (kept == 0) continue;
          if (children.isNotEmpty) children.add(Text(separator, maxLines: 1, style: textStyle));
          children.add(switch (parts[index]) {
            MetadataLineText(:final text) => Text(text, maxLines: 1, style: textStyle),
            MetadataLineRatings(:final ratings) => InlineRatingBadges(
              ratings: kept == ratings.length ? ratings : ratings.sublist(0, kept),
              textStyle: textStyle,
              foregroundColor: textStyle.color,
              iconSize: iconSize,
              spacing: badgeGap,
              entrySpacing: entryGap,
            ),
          });
        }
        if (children.isEmpty) return const SizedBox.shrink();
        return Row(mainAxisSize: MainAxisSize.min, children: children);
      },
    );
  }
}
