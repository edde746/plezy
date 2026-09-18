import 'media_item.dart';

/// Filter keys understood by [downloadItemMatchesFilters]. The map shape
/// mirrors the library browse filters (`filter name → selected value`) so the
/// downloads UI can reuse the same selection plumbing.
const downloadFilterUnwatched = 'unwatched';
const downloadFilterLibrary = 'library';

/// The [downloadFilterLibrary] value for one library section:
/// `serverId:libraryId`. A null [libraryId] produces the bare `serverId:`
/// form, which matches items with no library attribution.
String downloadLibraryFilterValue(String? serverId, String? libraryId) => '${serverId ?? ''}:${libraryId ?? ''}';

/// Whether [item] passes every active entry in [selected] — the downloads
/// screen's local equivalent of the server-side browse filters (#927).
///
/// Recognized keys:
/// - [downloadFilterUnwatched]: presence means "unwatched only"; the item
///   must still have unwatched content (see [_hasUnwatchedContent]).
/// - [downloadFilterLibrary]: the value is a `serverId:libraryId` pair from
///   [downloadLibraryFilterValue]; the item must belong to that library.
///
/// Unknown keys are ignored — callers whitelist the keys they offer, and
/// ignoring keeps older builds forward-compatible with filters added later.
bool downloadItemMatchesFilters(MediaItem item, Map<String, String> selected) {
  for (final entry in selected.entries) {
    switch (entry.key) {
      case downloadFilterUnwatched:
        if (!_hasUnwatchedContent(item)) return false;
      case downloadFilterLibrary:
        if (!_matchesLibraryValue(item, entry.value)) return false;
    }
  }
  return true;
}

/// Whether the item still has content left to watch. Containers with leaf
/// counts answer from [MediaItem.unwatchedCount]; everything else falls back
/// to [MediaItem.isWatched].
bool _hasUnwatchedContent(MediaItem item) {
  final unwatched = item.unwatchedCount;
  if (unwatched != null) return unwatched > 0;
  return !item.isWatched;
}

/// Matches a `serverId:libraryId` filter value against the item's
/// attribution. An empty library suffix matches items whose [MediaItem.libraryId]
/// is null (e.g. downloads recorded before library metadata existed).
bool _matchesLibraryValue(MediaItem item, String value) {
  final separator = value.indexOf(':');
  final serverId = separator < 0 ? value : value.substring(0, separator);
  final libraryId = separator < 0 ? '' : value.substring(separator + 1);
  if (item.serverId != serverId) return false;
  return libraryId.isEmpty ? item.libraryId == null : item.libraryId == libraryId;
}
