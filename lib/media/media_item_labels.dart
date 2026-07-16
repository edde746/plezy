import 'media_item.dart';

String formatQueueItemSubtitle(MediaItem item) {
  final grandparentTitle = item.grandparentTitle;
  if (grandparentTitle != null && item.parentIndex != null && item.index != null) {
    return '$grandparentTitle \u00b7 S${item.parentIndex}E${item.index}';
  }
  if (grandparentTitle != null) return grandparentTitle;
  if (item.year != null) {
    final edition = item.editionTitle;
    return edition != null ? '${item.year} \u00b7 $edition' : '${item.year}';
  }
  return item.kind.name;
}
