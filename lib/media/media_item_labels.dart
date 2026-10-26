import '../i18n/presentation_formats.dart';
import '../utils/formatters.dart';
import 'media_item.dart';
import 'media_kind.dart';

String formatQueueItemSubtitle(MediaItem item) {
  final grandparentTitle = item.grandparentTitle;
  final episodeLabel = formatSeasonEpisodeLabel(item.parentIndex, item.index);
  if (grandparentTitle != null && episodeLabel != null) {
    return toBulletedString([grandparentTitle, episodeLabel]);
  }
  if (grandparentTitle != null) return grandparentTitle;
  if (item.year != null) {
    final year = formatDecimal(item.year!, maximumDecimals: 0);
    final edition = item.editionTitle;
    return edition != null ? toBulletedString([year, edition]) : year;
  }
  return item.kind.label;
}

/// Unambiguous label for the exact item a destructive action will affect.
///
/// [MediaItem.displayTitle] deliberately collapses an episode or season to its
/// show name so cards can headline the series. That makes it actively
/// dangerous in a delete confirmation: a show and one of its episodes render
/// the identical string, which is how #1781 was reported as "deleting one
/// episode deleted them all". This names the target instead.
String formatMediaTargetLabel(MediaItem item) {
  final segments = <String>[];
  void add(String? value) {
    if (value != null && value.isNotEmpty) segments.add(value);
  }

  switch (item.kind) {
    case MediaKind.episode:
      add(item.grandparentTitle);
      add(formatSeasonEpisodeLabel(item.parentIndex, item.index));
      add(item.title);
    case MediaKind.season:
      add(item.grandparentTitle ?? item.parentTitle);
      add(item.title);
    default:
      add(item.title);
  }

  // Every segment can be absent on a sparse row; the collapsed show name still
  // beats an empty confirmation.
  return segments.isEmpty ? item.displayTitle : toBulletedString(segments);
}
