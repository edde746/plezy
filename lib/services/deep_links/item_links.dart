import '../../media/ids.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../utils/app_logger.dart';
import '../../utils/external_ids.dart';
import 'deep_link.dart';

/// Whether [item] can be shared as a [PlayLink]: a movie, show or episode
/// that names its server, on any backend.
bool canLinkItem(MediaItem item) => serverItemLink(item) != null;

/// The link that plays [item] from its own server, or null when [item]
/// cannot be linked. Only that server can open it.
PlayLink? serverItemLink(MediaItem item) {
  final serverId = serverIdOrNull(item.serverId);
  if (serverId == null || item.id.trim().isEmpty) return null;
  return switch (item.kind) {
    MediaKind.movie || MediaKind.show || MediaKind.episode => PlayLink(
      target: ItemPlayTarget(serverId: serverId, itemId: item.id),
    ),
    _ => null,
  };
}

/// The link to share for [item], or null when [item] cannot be linked.
///
/// A movie or show gets a catalogue link, which opens the title on any
/// server of any backend that has it, so the link survives the item moving
/// servers and works for a viewer with a different library. A Plex-matched
/// title also carries its Plex GUID: Plex cannot look up a library on its
/// current agent by catalogue id, so the GUID is what finds the title on
/// Plex without a Plex Discover round trip. Without either (unmatched, or
/// the lookup failed) the link is [serverItemLink]. The grammar names only
/// movies and shows by catalogue identity, so an episode always gets
/// [serverItemLink].
Future<PlayLink?> linkForItem(MediaServerClient client, MediaItem item) async {
  final itemLink = serverItemLink(item);
  if (itemLink == null) return null;
  final kind = item.kind;
  if (kind != MediaKind.movie && kind != MediaKind.show) return itemLink;

  var ids = const ExternalIds();
  try {
    ids = await client.fetchExternalIds(item.id);
  } on Exception catch (e, stackTrace) {
    // Best effort: the Plex GUID and the server link need no request.
    appLogger.w('Item link: external ids unavailable for ${item.id}', error: e, stackTrace: stackTrace);
  }
  final catalogId = _catalogId(kind, ids);
  final plexHash = _plexHashOf(kind, item.guid);
  if (catalogId == null && plexHash == null) return itemLink;
  return PlayLink(
    target: CatalogPlayTarget(kind: kind, ids: catalogId ?? const ExternalIds(), plexHash: plexHash),
  );
}

/// One id, the one libraries of [kind] are most often matched by: a single
/// id keeps the link short enough for a small QR code or NFC tag.
ExternalIds? _catalogId(MediaKind kind, ExternalIds ids) {
  final tmdb = ids.tmdb;
  final tvdb = ids.tvdb;
  final imdb = ids.imdb?.trim().toLowerCase();
  final byTmdb = tmdb != null && tmdb > 0 ? ExternalIds(tmdb: tmdb) : null;
  final byTvdb = tvdb != null && tvdb > 0 ? ExternalIds(tvdb: tvdb) : null;
  final byImdb = imdb != null && _imdbId.hasMatch(imdb) ? ExternalIds(imdb: imdb) : null;
  return kind == MediaKind.movie ? byTmdb ?? byImdb ?? byTvdb : byTvdb ?? byTmdb ?? byImdb;
}

String? _plexHashOf(MediaKind kind, String? guid) {
  final prefix = 'plex://${kind.id}/';
  if (guid == null || !guid.startsWith(prefix)) return null;
  final hash = guid.substring(prefix.length);
  return _plexHash.hasMatch(hash) ? hash : null;
}

// The forms the link parser accepts, so every link written here parses back.
final _imdbId = RegExp(r'^tt\d+$');
final _plexHash = RegExp(r'^[0-9a-zA-Z]+$');
