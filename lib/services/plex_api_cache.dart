import '../media/ids.dart';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/plex_metadata_recovery.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../utils/global_key_utils.dart';
import '../utils/isolate_helper.dart';
import '../utils/plex_cache_parser.dart';
import '../utils/active_client_scope.dart';
import '../utils/plex_library_section_utils.dart';
import 'api_cache.dart';
import 'plex_mappers.dart';

/// Plex-shape helpers on top of the shared [ApiCache] substrate.
///
/// The generic CRUD (`get`/`put`/`pin`/...) lives on [ApiCache]. This class
/// adds operations that bake in Plex's `/library/metadata/{ratingKey}`
/// endpoint shape and parse cached JSON into [MediaItem] via
/// [PlexMappers.mediaItemFromCacheJson].
class PlexApiCache extends ApiCache {
  static final _singleton = ApiCacheSingleton<PlexApiCache>(const {MediaBackend.plex}, 'PlexApiCache');
  static PlexApiCache get instance => _singleton.instance;

  PlexApiCache._(super.db);

  /// Initialize the singleton with an [AppDatabase] instance. Also registers
  /// this instance with the [ApiCache] backend dispatch so callers using
  /// `ApiCache.forBackend(MediaBackend.plex)` resolve here.
  static void initialize(AppDatabase db) => _singleton.install(PlexApiCache._(db));

  /// Delete cached data for a specific item (when removing a download).
  @override
  Future<void> deleteForItem(ServerId serverId, String ratingKey) async {
    final metadataKey = '$serverId:/library/metadata/$ratingKey';
    final childrenKey = '$serverId:/library/metadata/$ratingKey/children';

    await (database.delete(
      database.apiCache,
    )..where((t) => t.cacheKey.equals(metadataKey) | t.cacheKey.equals(childrenKey))).go();
  }

  /// Remove every profile-private row for a public item after its final
  /// physical download owner is gone.
  Future<void> deleteAllProfileRowsForItem(ServerId publicServerId, String ratingKey) async {
    final rows = await listPinnedRowsByPattern(_metadataKeyPattern);
    for (final row in rows) {
      if (row.id == ratingKey && publicPlexServerIdFromScope(row.serverId) == publicServerId) {
        await deleteForItem(row.serverId, ratingKey);
      }
    }
  }

  @override
  Future<void> pinForOffline(ServerId serverId, String ratingKey) async {
    return pin(serverId, '/library/metadata/$ratingKey');
  }

  // Rating keys can be alphanumeric, not just numeric.
  static final RegExp _metadataKeyPattern = RegExp(r'/library/metadata/([^/]+)$');

  @visibleForTesting
  Future<Set<String>> getPinnedKeys(ServerId serverId) => extractPinnedIds(serverId, _metadataKeyPattern);

  /// Copy one pinned item between cache namespaces.
  ///
  /// Full logout uses [stripProfileState] while moving metadata into the
  /// ownerless transfer namespace. The next profile copies that sanitized
  /// payload into its private namespace before the download is exposed.
  Future<bool> copyPinnedMetadata({
    required ServerId sourceServerId,
    required ServerId destinationServerId,
    required String ratingKey,
    bool stripProfileState = false,
  }) async {
    final endpoint = '/library/metadata/$ratingKey';
    final cached = await get(sourceServerId, endpoint);
    if (cached == null) return false;
    final payload = stripProfileState ? sanitizePlexMetadataMapForOwnerlessTransfer(cached) : cached;
    await put(destinationServerId, endpoint, payload);
    await pin(destinationServerId, endpoint);
    return true;
  }

  /// Fetch and parse a [MediaItem] from cache.
  ///
  /// The on-disk format is the raw Plex `/library/metadata/{id}` JSON shape;
  /// [PlexMappers.mediaItemFromCacheJson] converts it to the neutral
  /// [MediaItem] at the boundary. Returns `null` when the endpoint is not
  /// cached or contains no metadata.
  @override
  Future<MediaItem?> getMetadata(ServerId serverId, String ratingKey) async {
    final cached = await get(serverId, '/library/metadata/$ratingKey');
    final container = PlexCacheParser.extractMediaContainer(cached);
    final json = PlexCacheParser.extractFirstMetadata(cached);
    if (json == null) return null;
    final publicServerId = publicPlexServerIdFromCacheScope(serverId) ?? serverId;
    return PlexMappers.mediaItemFromCacheJson(_withContainerLibrary(json, container), serverId: publicServerId);
  }

  static Map<String, dynamic> _withContainerLibrary(Map<String, dynamic> json, Map<String, dynamic>? container) {
    final sectionId = plexLibrarySectionIdFromJson(json) ?? plexLibrarySectionIdFromJson(container);
    final sectionTitle = plexLibrarySectionTitleFromJson(json) ?? plexLibrarySectionTitleFromJson(container);
    if (sectionId == null && sectionTitle == null) return json;

    final enriched = Map<String, dynamic>.from(json);
    if (sectionId != null) enriched['librarySectionID'] ??= sectionId;
    if (sectionTitle != null) enriched['librarySectionTitle'] ??= sectionTitle;
    return enriched;
  }

  /// Persist a watched/unwatched flip into the cached metadata JSON. Mirrors
  /// what the server would return after the flip so a later cache reload
  /// (e.g. on app restart) reflects the current watched state without a
  /// network roundtrip.
  ///
  /// When [viewOffsetMs] / [lastViewedAt] / [viewedLeafCount] are supplied,
  /// they overwrite the snapshot values mirrored from a fresher server
  /// response (e.g. the offline-watch-sync episode-list refresh). They take
  /// precedence over the defaults the watched flip would otherwise apply —
  /// callers passing them have a more accurate read of server state.
  @override
  Future<void> applyWatchState({
    required ServerId serverId,
    required String itemId,
    required bool isWatched,
    int? viewOffsetMs,
    int? lastViewedAt,
    int? viewedLeafCount,
  }) async {
    final endpoint = '/library/metadata/$itemId';
    final cached = await get(ServerId(serverId), endpoint);
    final json = PlexCacheParser.extractFirstMetadata(cached);
    if (cached == null || json == null) return;
    if (isWatched) {
      final current = (json['viewCount'] as num?)?.toInt() ?? 0;
      json['viewCount'] = current < 1 ? 1 : current;
      json['viewOffset'] = viewOffsetMs ?? 0;
      json['lastViewedAt'] = lastViewedAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    } else {
      json['viewCount'] = 0;
      json['viewOffset'] = viewOffsetMs ?? 0;
      if (lastViewedAt != null) json['lastViewedAt'] = lastViewedAt;
    }
    if (viewedLeafCount != null) json['viewedLeafCount'] = viewedLeafCount;
    await put(ServerId(serverId), endpoint, cached);
  }

  /// Load all pinned Plex metadata in a single query.
  ///
  /// Returns a map keyed by `buildGlobalKey(ServerId(serverId), ratingKey)` for O(1)
  /// lookups. Used by DownloadProvider to batch-load metadata on startup
  /// instead of issuing per-item DB queries.
  @override
  Future<Map<String, MediaItem>> getAllPinnedMetadata({Set<ServerId>? cacheServerIds}) async {
    final allEntries = await listPinnedRowsByPattern(_metadataKeyPattern);
    final entries = cacheServerIds == null
        ? allEntries
        : allEntries.where((entry) => cacheServerIds.contains(entry.serverId)).toList(growable: false);
    if (entries.isEmpty) return {};

    return await tryIsolateRun(
      () => decodeCachedMediaRows(
        entries,
        serializedData: (entry) => entry.data,
        decode: (entry, data) {
          final container = PlexCacheParser.extractMediaContainer(data);
          final json = PlexCacheParser.extractFirstMetadata(data);
          if (json == null) return null;
          final publicServerId = publicPlexServerIdFromCacheScope(entry.serverId) ?? entry.serverId;
          return MapEntry(
            buildGlobalKey(publicServerId, entry.id),
            PlexMappers.mediaItemFromCacheJson(_withContainerLibrary(json, container), serverId: publicServerId),
          );
        },
      ),
    );
  }
}
