import 'library_query.dart';
import 'media_item.dart';

/// Filter fields understood by [downloadItemMatchesFilters]. The clause shape
/// mirrors the library browse filters so the downloads UI can reuse the same
/// selection plumbing and editor.
const downloadFilterUnwatched = 'unwatched';
const downloadFilterLibrary = 'library';

/// The [downloadFilterLibrary] value for one library section:
/// `serverId:libraryId`. A null [libraryId] produces the bare `serverId:`
/// form, which matches items with no library attribution.
String downloadLibraryFilterValue(String? serverId, String? libraryId) => '${serverId ?? ''}:${libraryId ?? ''}';

/// Whether [item] passes every clause in [selected] — the downloads screen's
/// local equivalent of the server-side browse filters (#927).
///
/// Recognized fields:
/// - [downloadFilterUnwatched]: the item must still have unwatched content
///   (see [_hasUnwatchedContent]), or must not when the clause is negated.
/// - [downloadFilterLibrary]: values are `serverId:libraryId` pairs from
///   [downloadLibraryFilterValue]; the item must belong to one of them, or to
///   none of them when the clause is negated.
///
/// Values inside one clause OR and clauses AND, exactly as on the wire.
/// Unknown fields are ignored — callers whitelist the fields they offer, and
/// ignoring keeps older builds forward-compatible with filters added later.
bool downloadItemMatchesFilters(MediaItem item, List<LibraryFilter> selected) {
  for (final clause in selected) {
    if (clause.values.isEmpty) continue;
    final bool matches;
    switch (clause.field) {
      case downloadFilterUnwatched:
        matches = _hasUnwatchedContent(item);
      case downloadFilterLibrary:
        matches = clause.values.any((value) => _matchesLibraryValue(item, value));
      default:
        continue;
    }
    if (matches == clause.op.isNegated) return false;
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
