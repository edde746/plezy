import 'package:flutter/material.dart';

import '../focus/focusable_wrapper.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../utils/content_utils.dart';
import '../utils/formatters.dart';
import '../utils/media_quality_labels.dart';
import 'bottom_sheet_page_scaffold.dart';
import 'fitted_metadata_line.dart';
import 'media_rating_badge.dart';

/// The complete, non-truncating version of a detail hero's information block:
/// every metadata field, every rating badge, the genres, and the full
/// description.
///
/// The TV hero keeps its single fitted metadata line — which sheds rating
/// badges and quality labels when they do not fit (#1893) — and its two-to-
/// three-line summary. This sheet is where the shed and truncated information
/// stays reachable (#2042); nothing here drops on overflow, everything wraps
/// or scrolls.
class MediaDetailsSheet extends StatefulWidget {
  final MediaItem item;

  /// Already resolved by the caller — honoring the spoiler setting and, for
  /// shows, the episode → season → show fallback — so the sheet never shows
  /// more than the hero was allowed to.
  final String? description;

  /// Genres of the title the hero belongs to. Episodes rarely carry their
  /// own, so a hero that follows an episode passes the show's; the TV hero
  /// itself no longer renders them (#2217).
  final List<String> genres;

  const MediaDetailsSheet({super.key, required this.item, this.description, this.genres = const []});

  @override
  State<MediaDetailsSheet> createState() => _MediaDetailsSheetState();
}

class _MediaDetailsSheetState extends State<MediaDetailsSheet> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// D-pad reading support: the body is one focus stop, so up/down page the
  /// sheet instead of moving focus. No-ops when the content already fits.
  void _scrollBy(double direction) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (position.pixels + direction * position.viewportDimension * 0.5).clamp(
      0.0,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return;
    _scrollController.animateTo(target, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
  }

  /// Year (or episode label and air date), certification, runtime, and every
  /// quality label — the plain-text fields of the hero metadata line, complete.
  List<String> _metadataLabels(MediaItem item) {
    final episodeLabel = formatSeasonEpisodeLabel(item.parentIndex, item.index);
    return [
      if (item.isEpisode && episodeLabel != null) episodeLabel,
      if (item.isEpisode && item.originallyAvailableAt != null)
        formatAbbreviatedDate(item.originallyAvailableAt!)
      else if (item.year != null)
        item.year.toString(),
      if (item.contentRating != null) formatContentRating(item.contentRating!),
      if (item.durationMs != null) formatDurationTextual(item.durationMs!),
      ...buildMediaQualityLabels(item),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final labels = _metadataLabels(item);
    final ratings = mediaRatingsFor(item);
    final genres = widget.genres;
    final episodeTitle = item.isEpisode ? item.title : null;
    final description = widget.description;
    final metadataStyle = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1);

    return BottomSheetPageScaffold(
      title: item.displayTitle,
      showHeaderBorder: false,
      // One chrome-less focus stop around the viewport: like the file-info
      // sheet's fields there is nothing to activate, so no focus chrome is
      // drawn — the arrows only page the content beneath.
      child: FocusableWrapper(
        onNavigateUp: () => _scrollBy(-1),
        onNavigateDown: () => _scrollBy(1),
        delegateFocusBorder: true,
        disableScale: true,
        autoScroll: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (episodeTitle != null && episodeTitle.isNotEmpty) ...[
                Text(episodeTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
              ],
              if (labels.isNotEmpty || ratings.isNotEmpty)
                // The hero line's free-flowing look, but wrapping instead
                // of shedding: plain bulleted text with the badge run
                // riding the line as one more segment.
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: labels.join(FittedMetadataLine.separator)),
                      if (labels.isNotEmpty && ratings.isNotEmpty) const TextSpan(text: FittedMetadataLine.separator),
                      if (ratings.isNotEmpty)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: InlineRatingBadges(ratings: ratings, textStyle: metadataStyle),
                        ),
                    ],
                  ),
                  style: metadataStyle,
                ),
              if (genres.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  genres.join(FittedMetadataLine.separator),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
