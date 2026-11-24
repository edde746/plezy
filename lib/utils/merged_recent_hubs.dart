import '../media/ids.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_server_client.dart';
import 'global_key_utils.dart';

/// Id of the row built by [mergeRecentlyAddedHubs].
const String mergedRecentlyAddedHubId = 'merged.recentlyadded';

final RegExp _identifierSeparators = RegExp(r'[^a-z0-9]+');

/// Whether [hub] is a single library's Recently Added row. Matched on the
/// server's row identifier, never the (localized) title: Plex per-library rows
/// carry `movie.recentlyAdded.1` / `tv.recentlyAdded.2` (global hubs) or
/// `movie.recentlyadded` (section hubs); Jellyfin's synthesized ones carry
/// `library.<id>.recent`.
bool isLibraryRecentlyAddedHub(MediaHub hub) {
  final identifier = hub.identifier;
  if (identifier == null) return false;
  final tokens = identifier.toLowerCase().split(_identifierSeparators).where((t) => t.isNotEmpty).toList();
  if (tokens.contains('recentlyadded')) return true;
  return tokens.length >= 3 && tokens.first == 'library' && tokens.last == 'recent';
}

/// The library a single-library row belongs to, from the hub itself or, for
/// Plex (which only stamps the library on items), its first item.
String? _hubLibraryKey(MediaHub hub) {
  final serverId = hub.serverId;
  final libraryId = hub.libraryId;
  if (serverId != null && libraryId != null) return buildGlobalKey(ServerId(serverId), libraryId);
  for (final item in hub.items) {
    final key = item.libraryGlobalKey;
    if (key != null) return key;
  }
  return null;
}

/// Folds the Recently Added rows of the libraries in [libraryKeys] into one
/// row, placed where the first of them was. Items are interleaved newest
/// first and capped at [limit]. Only rows already in [hubs] are used, so this
/// makes no extra server requests. Returns [hubs] unchanged when fewer than
/// two rows match (nothing to merge).
List<MediaHub> mergeRecentlyAddedHubs(
  List<MediaHub> hubs,
  Set<String> libraryKeys, {
  required String title,
  int limit = defaultHubPreviewLimit,
}) {
  if (libraryKeys.length < 2) return hubs;

  final sources = <MediaHub>[];
  for (final hub in hubs) {
    if (!isLibraryRecentlyAddedHub(hub)) continue;
    final key = _hubLibraryKey(hub);
    if (key != null && libraryKeys.contains(key)) sources.add(hub);
  }
  if (sources.length < 2) return hubs;

  final seen = <String>{};
  final items = <MediaItem>[
    for (final hub in sources)
      for (final item in hub.items)
        if (seen.add(item.globalKey)) item,
  ]..sort((a, b) => (b.addedAt ?? 0).compareTo(a.addedAt ?? 0));
  final capped = items.length > limit ? items.sublist(0, limit) : items;

  final serverIds = {for (final hub in sources) hub.serverId};
  final merged = MediaHub(
    id: mergedRecentlyAddedHubId,
    identifier: mergedRecentlyAddedHubId,
    title: title,
    type: 'mixed',
    items: capped,
    size: capped.length,
    serverId: serverIds.length == 1 ? serverIds.single : null,
    serverName: serverIds.length == 1 ? sources.first.serverName : null,
  );

  final sourceSet = Set<MediaHub>.identity()..addAll(sources);
  final result = <MediaHub>[];
  var inserted = false;
  for (final hub in hubs) {
    if (!sourceSet.contains(hub)) {
      result.add(hub);
    } else if (!inserted) {
      result.add(merged);
      inserted = true;
    }
  }
  return result;
}
