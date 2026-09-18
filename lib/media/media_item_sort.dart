import 'media_item.dart';
import 'media_sort.dart';

/// Sort keys understood by [mediaItemSortComparator]. These are local,
/// backend-neutral keys — unlike the server sort keys on [MediaSort] they are
/// resolved against [MediaItem] fields (and [MediaItemSortExtras]) directly.
const mediaSortKeyTitle = 'title';
const mediaSortKeyDateAdded = 'dateAdded';
const mediaSortKeyReleaseDate = 'releaseDate';
const mediaSortKeyRating = 'rating';
const mediaSortKeyDownloadedAt = 'downloadedAt';
const mediaSortKeySize = 'size';
const mediaSortKeyLibrary = 'library';

/// Per-item fields a [MediaItem] does not carry but a local sort may need —
/// currently download bookkeeping supplied by the downloads layer.
typedef MediaItemSortExtras = ({int? downloadedAt, int? totalBytes});

/// Builds a [Comparator] over [MediaItem] for local (in-memory) sorting of
/// lists that mix servers and libraries, where server-side sort keys cannot
/// apply — the downloads screen being the motivating case (#927).
///
/// [key] is one of the `mediaSortKey*` constants; an unrecognized key yields
/// the deterministic title/id order. [extras] supplies per-item fields the
/// item itself lacks (download timestamp, byte size) for the
/// [mediaSortKeyDownloadedAt] and [mediaSortKeySize] keys.
///
/// Missing values always sort last — including under [descending], which
/// flips the ordering of present values without moving the missing tail. A
/// zero byte count counts as missing for [mediaSortKeySize]. Ties fall back
/// to title then id so the order is deterministic (Dart's [List.sort] is not
/// stable).
Comparator<MediaItem> mediaItemSortComparator(
  String key, {
  required bool descending,
  MediaItemSortExtras Function(MediaItem item)? extras,
}) {
  return (a, b) {
    final aValue = _sortValue(key, a, extras);
    final bValue = _sortValue(key, b, extras);

    // Missing values pin to the tail in both directions, so the placement
    // check happens before the descending flip.
    if (aValue == null && bValue == null) return _tiebreak(a, b, descending);
    if (aValue == null) return 1;
    if (bValue == null) return -1;

    final primary = _compareValues(aValue, bValue);
    if (primary != 0) return descending ? -primary : primary;
    return _tiebreak(a, b, descending);
  };
}

/// The comparable value [key] sorts [item] on, or null when the item has no
/// meaningful value (missing field, absent extras, zero size, unknown key).
Object? _sortValue(String key, MediaItem item, MediaItemSortExtras Function(MediaItem item)? extras) {
  return switch (key) {
    mediaSortKeyTitle => _titleKey(item),
    mediaSortKeyDateAdded => item.addedAt,
    mediaSortKeyReleaseDate => item.originallyAvailableAt,
    mediaSortKeyRating => item.rating,
    mediaSortKeyDownloadedAt => extras?.call(item).downloadedAt,
    mediaSortKeySize => _sizeValue(extras?.call(item).totalBytes),
    mediaSortKeyLibrary => _libraryKey(item),
    _ => null,
  };
}

int? _sizeValue(int? totalBytes) => totalBytes != null && totalBytes > 0 ? totalBytes : null;

/// Both values come from the same sort key, so they share a runtime type.
int _compareValues(Object a, Object b) {
  if (a is int) return a.compareTo(b as int);
  if (a is double) return a.compareTo(b as double);
  return (a as String).compareTo(b as String);
}

/// Case-insensitive display title, preferring the backend's sort title.
String _titleKey(MediaItem item) => (item.titleSort ?? item.title ?? '').toLowerCase();

/// Library grouping label: the section title when known, else the server
/// name so items still cluster per server.
String _libraryKey(MediaItem item) => (item.libraryTitle ?? item.serverName ?? '').toLowerCase();

/// Deterministic fallback for equal primary values: title, then id.
int _tiebreak(MediaItem a, MediaItem b, bool descending) {
  final byTitle = _titleKey(a).compareTo(_titleKey(b));
  final result = byTitle != 0 ? byTitle : a.id.compareTo(b.id);
  return descending ? -result : result;
}
