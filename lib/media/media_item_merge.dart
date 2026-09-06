import 'ids.dart';
import 'media_item.dart';
import 'media_version.dart';

/// The library a copy belongs to: [MediaItem.libraryId] with the
/// [MediaItem.libraryTitle] that labels it. The two travel as a pair, since a
/// title is only meaningful next to the id it names.
typedef _LibraryPair = ({String? libraryId, String? libraryTitle});

/// The pair [fresh] belongs to, backed by [known] only where [fresh] leaves
/// room for it.
///
/// A fresh copy naming a different library than [known] takes both fields
/// verbatim — a null title too, so the UI falls back to the server name rather
/// than labeling the new library with the old one's name. One naming the same
/// library fills a missing title from [known]. One naming no library at all
/// keeps the known pair: the stamp is best-effort on both backends, and its
/// absence is not a move.
_LibraryPair _libraryPair(MediaItem fresh, MediaItem? known) {
  final freshId = fresh.libraryId;
  final knownId = known?.libraryId;
  if (freshId == null) {
    return knownId == null
        ? (libraryId: null, libraryTitle: fresh.libraryTitle ?? known?.libraryTitle)
        : (libraryId: knownId, libraryTitle: known!.libraryTitle);
  }
  return (libraryId: freshId, libraryTitle: fresh.libraryTitle ?? (freshId == knownId ? known!.libraryTitle : null));
}

/// Merge freshly fetched metadata with identity and library context already
/// known by the caller. The fetched item owns descriptive fields, while
/// existing context wins when the backend omits it. Library id and title
/// follow [_libraryPair].
MediaItem mergeFetchedMediaItem({required MediaItem fetched, required ServerId fallbackServerId, MediaItem? existing}) {
  final library = _libraryPair(fetched, existing);
  return fetched.copyWith(
    serverId: existing?.serverId ?? fetched.serverId ?? fallbackServerId,
    serverName: existing?.serverName ?? fetched.serverName,
    libraryId: library.libraryId,
    libraryTitle: library.libraryTitle,
  );
}

/// Tallest version height an item exposes, or 0 when the backend reported
/// none.
int _bestResolutionHeight(MediaItem item) {
  var best = 0;
  for (final version in item.mediaVersions ?? const <MediaVersion>[]) {
    final height = version.resolutionHeight;
    if (height != null && height > best) best = height;
  }
  return best;
}

/// Order the library copies of one title best-first: highest resolution, then
/// library title, then server name, then global key.
///
/// Total and derived purely from the items, so a chooser can re-sort after
/// merging a later resolution pass without its rows jumping around.
int compareLibraryCopies(MediaItem a, MediaItem b) {
  final byResolution = _bestResolutionHeight(b).compareTo(_bestResolutionHeight(a));
  if (byResolution != 0) return byResolution;
  final byLibrary = (a.libraryTitle ?? '').compareTo(b.libraryTitle ?? '');
  if (byLibrary != 0) return byLibrary;
  final byServer = (a.serverName ?? '').compareTo(b.serverName ?? '');
  if (byServer != 0) return byServer;
  return a.globalKey.compareTo(b.globalKey);
}

/// Fold a re-resolved copy into the one already known for its
/// [MediaItem.globalKey].
///
/// The addition is fresher, but a degraded pass must not erase context. The
/// Jellyfin library stamp is a best-effort `/Items/{id}/Ancestors` call that
/// hands back an unstamped item when it fails, and a copy that lost its
/// library title is indistinguishable from its sibling in the same server's
/// other library — exactly the ambiguity the chooser exists to resolve. The
/// library pair follows [_libraryPair]; the version list behind the
/// resolution hint is treated the same way as the stamp.
///
/// Shared by the on-screen union ([mergeLibraryCopies]) and the per-server
/// replacement in `CatalogLibraryMatcher`, so one policy decides what a
/// returning copy keeps from its predecessor. Returns [addition] itself when
/// it inherits nothing: [MediaItem] compares by identity, and a caller
/// holding on to the fresh copy must still recognize it.
MediaItem mergeLibraryCopy(MediaItem existing, MediaItem addition) {
  final versions = addition.mediaVersions;
  final library = _libraryPair(addition, existing);
  final serverName = addition.serverName ?? existing.serverName;
  final mediaVersions = versions == null || versions.isEmpty ? existing.mediaVersions : versions;
  if (library.libraryId == addition.libraryId &&
      library.libraryTitle == addition.libraryTitle &&
      serverName == addition.serverName &&
      identical(mediaVersions, versions)) {
    return addition;
  }
  return addition.copyWith(
    libraryId: library.libraryId,
    libraryTitle: library.libraryTitle,
    serverName: serverName,
    mediaVersions: mediaVersions,
  );
}

/// Union [additions] into [current] by [MediaItem.globalKey], then re-sort
/// with [compareLibraryCopies]. A key on both sides is folded by
/// [mergeLibraryCopy].
///
/// Never removes a copy, and never downgrades one. The cross-server fan-out
/// behind these lists logs and skips per-server failures, so a later pass can
/// legitimately come back short a server, or short the best-effort library
/// stamp of a copy it did return.
List<MediaItem> mergeLibraryCopies(Iterable<MediaItem> current, Iterable<MediaItem> additions) {
  final byKey = <String, MediaItem>{for (final item in current) item.globalKey: item};
  for (final item in additions) {
    final existing = byKey[item.globalKey];
    byKey[item.globalKey] = existing == null ? item : mergeLibraryCopy(existing, item);
  }
  return byKey.values.toList()..sort(compareLibraryCopies);
}
