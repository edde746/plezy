import 'ids.dart';
import 'media_item.dart';
import 'media_version.dart';

/// Merge freshly fetched metadata with identity and library context already
/// known by the caller. The fetched item owns descriptive fields, while
/// existing context wins when the backend omits it.
MediaItem mergeFetchedMediaItem({required MediaItem fetched, required ServerId fallbackServerId, MediaItem? existing}) {
  return fetched.copyWith(
    serverId: existing?.serverId ?? fetched.serverId ?? fallbackServerId,
    serverName: existing?.serverName ?? fetched.serverName,
    libraryId: fetched.libraryId ?? existing?.libraryId,
    libraryTitle: fetched.libraryTitle ?? existing?.libraryTitle,
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

/// Fold a re-resolved copy into the one already on screen.
///
/// The addition is fresher, but a degraded pass must not erase context. The
/// Jellyfin library stamp is a best-effort `/Items/{id}/Ancestors` call that
/// hands back an unstamped item when it fails, and a copy that lost its
/// library title is indistinguishable from its sibling in the same server's
/// other library — exactly the ambiguity the chooser exists to resolve. The
/// version list behind the resolution hint is treated the same way.
MediaItem _mergeCopy(MediaItem existing, MediaItem addition) {
  final versions = addition.mediaVersions;
  return addition.copyWith(
    libraryId: addition.libraryId ?? existing.libraryId,
    libraryTitle: addition.libraryTitle ?? existing.libraryTitle,
    serverName: addition.serverName ?? existing.serverName,
    mediaVersions: versions == null || versions.isEmpty ? existing.mediaVersions : versions,
  );
}

/// Union [additions] into [current] by [MediaItem.globalKey], then re-sort
/// with [compareLibraryCopies]. A key on both sides is folded by [_mergeCopy].
///
/// Never removes a copy, and never downgrades one. The cross-server fan-out
/// behind these lists logs and skips per-server failures, so a later pass can
/// legitimately come back short a server, or short the best-effort library
/// stamp of a copy it did return.
List<MediaItem> mergeLibraryCopies(Iterable<MediaItem> current, Iterable<MediaItem> additions) {
  final byKey = <String, MediaItem>{for (final item in current) item.globalKey: item};
  for (final item in additions) {
    final existing = byKey[item.globalKey];
    byKey[item.globalKey] = existing == null ? item : _mergeCopy(existing, item);
  }
  return byKey.values.toList()..sort(compareLibraryCopies);
}
