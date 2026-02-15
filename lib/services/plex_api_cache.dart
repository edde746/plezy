import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/plex_metadata.dart';
import '../utils/plex_cache_parser.dart';

/// Key-value cache for Plex API responses using Drift/SQLite.
/// Stores raw JSON responses keyed by serverId:endpoint format.
class PlexApiCache {
  static PlexApiCache? _instance;
  static PlexApiCache get instance {
    if (_instance == null) {
      throw StateError('PlexApiCache not initialized. Call PlexApiCache.initialize() first.');
    }
    return _instance!;
  }

  final AppDatabase _db;

  PlexApiCache._(this._db);

  /// Initialize the singleton with an AppDatabase instance
  static void initialize(AppDatabase db) {
    _instance = PlexApiCache._(db);
  }

  /// Get the database instance (for services that need direct database access)
  AppDatabase get database => _db;

  /// Build cache key from serverId and endpoint
  String _buildKey(String serverId, String endpoint) {
    return '$serverId:$endpoint';
  }

  /// Get cached response for an endpoint
  Future<Map<String, dynamic>?> get(String serverId, String endpoint) async {
    final key = _buildKey(serverId, endpoint);
    final result = await (_db.select(_db.apiCache)..where((t) => t.cacheKey.equals(key))).getSingleOrNull();

    if (result != null) {
      return jsonDecode(result.data) as Map<String, dynamic>;
    }
    return null;
  }

  /// Cache a response for an endpoint
  Future<void> put(String serverId, String endpoint, Map<String, dynamic> data) async {
    final key = _buildKey(serverId, endpoint);
    await _db
        .into(_db.apiCache)
        .insertOnConflictUpdate(
          ApiCacheCompanion(cacheKey: Value(key), data: Value(jsonEncode(data)), cachedAt: Value(DateTime.now())),
        );
  }

  /// Delete all cached data for a server
  Future<void> deleteForServer(String serverId) async {
    await (_db.delete(_db.apiCache)..where((t) => t.cacheKey.like('$serverId:%'))).go();
  }

  /// Delete cached data for a specific item (when removing a download)
  Future<void> deleteForItem(String serverId, String ratingKey) async {
    // Delete the metadata endpoint
    final metadataKey = _buildKey(serverId, '/library/metadata/$ratingKey');
    final childrenKey = _buildKey(serverId, '/library/metadata/$ratingKey/children');

    await (_db.delete(
      _db.apiCache,
    )..where((t) => t.cacheKey.equals(metadataKey) | t.cacheKey.equals(childrenKey))).go();
  }

  /// Mark an item as pinned for offline access
  Future<void> pinForOffline(String serverId, String ratingKey) async {
    final metadataKey = _buildKey(serverId, '/library/metadata/$ratingKey');
    await (_db.update(
      _db.apiCache,
    )..where((t) => t.cacheKey.equals(metadataKey))).write(const ApiCacheCompanion(pinned: Value(true)));
  }

  /// Unpin an item
  Future<void> unpinForOffline(String serverId, String ratingKey) async {
    final metadataKey = _buildKey(serverId, '/library/metadata/$ratingKey');
    await (_db.update(
      _db.apiCache,
    )..where((t) => t.cacheKey.equals(metadataKey))).write(const ApiCacheCompanion(pinned: Value(false)));
  }

  /// Check if an item is pinned for offline
  Future<bool> isPinned(String serverId, String ratingKey) async {
    final metadataKey = _buildKey(serverId, '/library/metadata/$ratingKey');
    final result = await (_db.select(_db.apiCache)..where((t) => t.cacheKey.equals(metadataKey))).getSingleOrNull();
    return result?.pinned ?? false;
  }

  /// Get all pinned rating keys for a server
  Future<Set<String>> getPinnedKeys(String serverId) async {
    final results = await (_db.select(
      _db.apiCache,
    )..where((t) => t.cacheKey.like('$serverId:%') & t.pinned.equals(true))).get();

    final keys = <String>{};
    for (final row in results) {
      // Extract ratingKey from cache key like "serverId:/library/metadata/12345"
      // Rating keys can be alphanumeric, not just numeric
      final match = RegExp(r'/library/metadata/([^/]+)$').firstMatch(row.cacheKey);
      if (match != null) {
        keys.add(match.group(1)!);
      }
    }
    return keys;
  }

  /// Fetch and parse a [PlexMetadata] item from cache.
  ///
  /// Returns `null` when the endpoint is not cached or contains no metadata.
  Future<PlexMetadata?> getMetadata(String serverId, String ratingKey) async {
    final cached = await get(serverId, '/library/metadata/$ratingKey');
    final json = PlexCacheParser.extractFirstMetadata(cached);
    if (json == null) return null;
    return PlexMetadata.fromJsonWithImages(json).copyWith(serverId: serverId);
  }

  /// Load all pinned metadata in a single query.
  ///
  /// Returns a map keyed by `serverId:ratingKey` for O(1) lookups.
  /// Used by DownloadProvider to batch-load metadata on startup instead of
  /// issuing per-item DB queries.
  Future<Map<String, PlexMetadata>> getAllPinnedMetadata() async {
    final rows = await (_db.select(_db.apiCache)
          ..where((t) => t.pinned.equals(true)))
        .get();

    final result = <String, PlexMetadata>{};
    for (final row in rows) {
      // Extract serverId and ratingKey from cache key like "serverId:/library/metadata/12345"
      final colonIdx = row.cacheKey.indexOf(':');
      if (colonIdx < 0) continue;
      final serverId = row.cacheKey.substring(0, colonIdx);
      final match = RegExp(r'/library/metadata/([^/]+)$').firstMatch(row.cacheKey);
      if (match == null) continue;
      final ratingKey = match.group(1)!;

      try {
        final data = jsonDecode(row.data) as Map<String, dynamic>;
        final json = PlexCacheParser.extractFirstMetadata(data);
        if (json == null) continue;
        final metadata = PlexMetadata.fromJsonWithImages(json).copyWith(serverId: serverId);
        result['$serverId:$ratingKey'] = metadata;
      } catch (_) {
        // Skip malformed entries
      }
    }
    return result;
  }

  /// Clear all cached data (useful for debugging/testing)
  Future<void> clearAll() async {
    await _db.delete(_db.apiCache).go();
  }
}
