import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../utils/global_key_utils.dart';
import '../utils/isolate_helper.dart';
import '../utils/plex_cache_parser.dart';
import 'api_cache.dart';
import 'plex_mappers.dart';

/// Plex-shape helpers on top of the shared [ApiCache] substrate.
///
/// The generic CRUD (`get`/`put`/`pin`/...) lives on [ApiCache]. This class
/// adds operations that bake in Plex's `/library/metadata/{ratingKey}`
/// endpoint shape and parse cached JSON into [MediaItem] via
/// [PlexMappers.mediaItemFromCacheJson].
class PlexApiCache extends ApiCache {
  static PlexApiCache? _instance;
  static PlexApiCache get instance {
    if (_instance == null) {
      throw StateError('PlexApiCache not initialized. Call PlexApiCache.initialize() first.');
    }
    return _instance!;
  }

  PlexApiCache._(super.db);

  /// Initialize the singleton with an [AppDatabase] instance. Also registers
  /// this instance with the [ApiCache] backend dispatch so callers using
  /// `ApiCache.forBackend(MediaBackend.plex)` resolve here.
  static void initialize(AppDatabase db) {
    _instance = PlexApiCache._(db);
    ApiCache.registerInstance(MediaBackend.plex, _instance!);
  }

  /// Delete cached data for a specific item (when removing a download).
  @override
  Future<void> deleteForItem(String serverId, String ratingKey) async {
    final metadataKey = '$serverId:/library/metadata/$ratingKey';
    final childrenKey = '$serverId:/library/metadata/$ratingKey/children';

    await (database.delete(
      database.apiCache,
    )..where((t) => t.cacheKey.equals(metadataKey) | t.cacheKey.equals(childrenKey))).go();
  }

  @override
  Future<void> pinForOffline(String serverId, String ratingKey) async {
    return pin(serverId, '/library/metadata/$ratingKey');
  }

  Future<void> unpinForOffline(String serverId, String ratingKey) async {
    return unpin(serverId, '/library/metadata/$ratingKey');
  }

  /// Whether the metadata for [ratingKey] is pinned for offline.
  ///
  /// Named `isPinnedRatingKey` to avoid colliding with the inherited
  /// [ApiCache.isPinned]'s identical Dart signature.
  Future<bool> isPinnedRatingKey(String serverId, String ratingKey) {
    return isPinned(serverId, '/library/metadata/$ratingKey');
  }

  // Rating keys can be alphanumeric, not just numeric.
  static final RegExp _metadataKeyPattern = RegExp(r'/library/metadata/([^/]+)$');

  Future<Set<String>> getPinnedKeys(String serverId) => extractPinnedIds(serverId, _metadataKeyPattern);

  /// Fetch and parse a [MediaItem] from cache.
  ///
  /// The on-disk format is the raw Plex `/library/metadata/{id}` JSON shape;
  /// [PlexMappers.mediaItemFromCacheJson] converts it to the neutral
  /// [MediaItem] at the boundary. Returns `null` when the endpoint is not
  /// cached or contains no metadata.
  @override
  Future<MediaItem?> getMetadata(String serverId, String ratingKey) async {
    final cached = await get(serverId, '/library/metadata/$ratingKey');
    final json = PlexCacheParser.extractFirstMetadata(cached);
    if (json == null) return null;
    return PlexMappers.mediaItemFromCacheJson(json, serverId: serverId);
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
    required String serverId,
    required String itemId,
    required bool isWatched,
    int? viewOffsetMs,
    int? lastViewedAt,
    int? viewedLeafCount,
  }) async {
    final endpoint = '/library/metadata/$itemId';
    final cached = await get(serverId, endpoint);
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
    await put(serverId, endpoint, cached);
  }

  /// Load all pinned Plex metadata in a single query.
  ///
  /// Returns a map keyed by `buildGlobalKey(serverId, ratingKey)` for O(1)
  /// lookups. Used by DownloadProvider to batch-load metadata on startup
  /// instead of issuing per-item DB queries.
  @override
  Future<Map<String, MediaItem>> getAllPinnedMetadata() async {
    final entries = await listPinnedRowsByPattern(_metadataKeyPattern);
    if (entries.isEmpty) return {};

    return await tryIsolateRun(() {
      final result = <String, MediaItem>{};
      for (final entry in entries) {
        try {
          final data = jsonDecode(entry.data) as Map<String, dynamic>;
          final json = PlexCacheParser.extractFirstMetadata(data);
          if (json == null) continue;
          result[buildGlobalKey(entry.serverId, entry.id)] = PlexMappers.mediaItemFromCacheJson(
            json,
            serverId: entry.serverId,
          );
        } catch (_) {
          // Skip malformed entries
        }
      }
      return result;
    });
  }
}
