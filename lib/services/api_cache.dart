import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../utils/isolate_helper.dart';

/// Backend-agnostic key-value cache for API responses.
///
/// Stores raw JSON keyed by `serverId:endpoint` in the shared `ApiCache`
/// Drift table. `serverId` values are globally unique across connected
/// backends, so Plex and Jellyfin entries never collide despite sharing
/// the same table.
///
/// Plex- and Jellyfin-specific helpers (item-id pinning, metadata parsing)
/// live on subclasses [PlexApiCache] / [JellyfinApiCache], which also
/// implement the abstract [getMetadata] / [pinForOffline] / [deleteForItem]
/// methods so callers can dispatch via [forBackend] instead of switching on
/// the backend type at every call site.
abstract class ApiCache {
  static ApiCache? _instance;

  /// Returns the most recently registered cache instance — used by callers
  /// that don't care which backend's helpers they're hitting (e.g. plain
  /// `get`/`put` from `JellyfinClient`). Backend-specific operations should
  /// route through [forBackend] instead.
  static ApiCache get instance {
    if (_instance == null) {
      throw StateError('ApiCache not initialized. Call initialize() on a backend cache first.');
    }
    return _instance!;
  }

  static final Map<MediaBackend, ApiCache> _byBackend = {};

  /// Subclasses call this from their own `initialize` to register themselves
  /// for backend dispatch. Also seeds [instance] so the legacy singleton
  /// surface keeps working.
  static void registerInstance(MediaBackend backend, ApiCache cache) {
    _byBackend[backend] = cache;
    _instance = cache;
  }

  /// Pick the cache for [backend]. Plex is the legacy default — covers items
  /// predating the Connections table where the backend can't be resolved.
  static ApiCache forBackend(MediaBackend? backend) {
    final picked = _byBackend[backend ?? MediaBackend.plex] ?? _byBackend[MediaBackend.plex];
    if (picked == null) {
      throw StateError('No ApiCache registered for backend $backend');
    }
    return picked;
  }

  final AppDatabase _db;

  ApiCache(this._db);

  /// Direct database access for services that need to query the cache table
  /// outside the standard get/put surface (e.g. playback initialisation that
  /// joins on adjacent tables).
  AppDatabase get database => _db;

  String _buildKey(String serverId, String endpoint) {
    return '$serverId:$endpoint';
  }

  /// Get cached response for an endpoint.
  Future<Map<String, dynamic>?> get(String serverId, String endpoint) async {
    final key = _buildKey(serverId, endpoint);
    final result = await (_db.select(_db.apiCache)..where((t) => t.cacheKey.equals(key))).getSingleOrNull();
    if (result != null) {
      return await tryIsolateRun(() => jsonDecode(result.data) as Map<String, dynamic>);
    }
    return null;
  }

  /// Cache a response for an endpoint.
  Future<void> put(String serverId, String endpoint, Map<String, dynamic> data) async {
    final key = _buildKey(serverId, endpoint);
    final encoded = await tryIsolateRun(() => jsonEncode(data));
    await _db
        .into(_db.apiCache)
        .insertOnConflictUpdate(
          ApiCacheCompanion(cacheKey: Value(key), data: Value(encoded), cachedAt: Value(DateTime.now())),
        );
  }

  /// Delete all cached data for a server.
  Future<void> deleteForServer(String serverId) async {
    await (_db.delete(_db.apiCache)..where((t) => t.cacheKey.like('$serverId:%'))).go();
  }

  /// Pin an endpoint's response so the row survives cache eviction.
  Future<void> pin(String serverId, String endpoint) async {
    final key = _buildKey(serverId, endpoint);
    await (_db.update(
      _db.apiCache,
    )..where((t) => t.cacheKey.equals(key))).write(const ApiCacheCompanion(pinned: Value(true)));
  }

  /// Unpin a previously pinned endpoint.
  Future<void> unpin(String serverId, String endpoint) async {
    final key = _buildKey(serverId, endpoint);
    await (_db.update(
      _db.apiCache,
    )..where((t) => t.cacheKey.equals(key))).write(const ApiCacheCompanion(pinned: Value(false)));
  }

  /// Whether the endpoint is pinned for offline.
  Future<bool> isPinned(String serverId, String endpoint) async {
    final key = _buildKey(serverId, endpoint);
    final result = await (_db.select(_db.apiCache)..where((t) => t.cacheKey.equals(key))).getSingleOrNull();
    return result?.pinned ?? false;
  }

  /// Clear every cached row (debugging / sign-out).
  Future<void> clearAll() async {
    await _db.delete(_db.apiCache).go();
  }

  /// Clear volatile cached rows while preserving pinned offline metadata.
  Future<void> clearVolatile() async {
    await (_db.delete(_db.apiCache)..where((t) => t.pinned.equals(false))).go();
  }

  /// Pin every row whose `cacheKey` matches the SQL `LIKE` [pattern]. Used by
  /// backend subclasses that pin by item-shape rather than a single endpoint
  /// (e.g. Jellyfin's per-user item rows where the user segment is a
  /// wildcard).
  Future<void> pinByKeyPattern(String pattern) async {
    await (_db.update(
      _db.apiCache,
    )..where((t) => t.cacheKey.like(pattern))).write(const ApiCacheCompanion(pinned: Value(true)));
  }

  /// Inverse of [pinByKeyPattern].
  Future<void> unpinByKeyPattern(String pattern) async {
    await (_db.update(
      _db.apiCache,
    )..where((t) => t.cacheKey.like(pattern))).write(const ApiCacheCompanion(pinned: Value(false)));
  }

  /// True when at least one pinned row matches [pattern].
  Future<bool> hasPinnedMatching(String pattern) async {
    final rows = await (_db.select(_db.apiCache)..where((t) => t.cacheKey.like(pattern) & t.pinned.equals(true))).get();
    return rows.isNotEmpty;
  }

  /// Pull pinned rows for [serverId] and extract the first capture group of
  /// [keyPattern] from each `cacheKey`. Returns the unique set of captured
  /// ids — backend subclasses use this to enumerate their pinned items
  /// (Plex ratingKeys, Jellyfin item ids).
  Future<Set<String>> extractPinnedIds(String serverId, RegExp keyPattern) async {
    final rows = await (_db.select(
      _db.apiCache,
    )..where((t) => t.cacheKey.like('$serverId:%') & t.pinned.equals(true))).get();
    final ids = <String>{};
    for (final row in rows) {
      final match = keyPattern.firstMatch(row.cacheKey);
      if (match != null) ids.add(match.group(1)!);
    }
    return ids;
  }

  /// Walk every pinned row, extract `(serverId, capturedId, rawData)` tuples
  /// from rows whose `cacheKey` matches [keyPattern]. The serverId is parsed
  /// from the prefix before the first colon. Backend subclasses use this to
  /// batch-load all pinned metadata into their own model type without
  /// re-implementing the row walker.
  Future<List<({String serverId, String id, String data})>> listPinnedRowsByPattern(RegExp keyPattern) async {
    final rows = await (_db.select(_db.apiCache)..where((t) => t.pinned.equals(true))).get();
    final out = <({String serverId, String id, String data})>[];
    for (final row in rows) {
      final colon = row.cacheKey.indexOf(':');
      if (colon < 0) continue;
      final match = keyPattern.firstMatch(row.cacheKey);
      if (match == null) continue;
      out.add((serverId: row.cacheKey.substring(0, colon), id: match.group(1)!, data: row.data));
    }
    return out;
  }

  // ── Backend-shape operations ──────────────────────────────────────
  // These are implemented by the per-backend subclasses so callers can
  // dispatch via [forBackend(backend).getMetadata(...)] without an outer
  // `switch (backend)` at every call site.

  /// Fetch and parse cached [MediaItem] for [itemId] on [serverId]. Returns
  /// `null` when the item isn't cached.
  Future<MediaItem?> getMetadata(String serverId, String itemId);

  /// Pin the cached metadata row(s) for [itemId] so they survive cache
  /// eviction (used by the offline-download pipeline).
  Future<void> pinForOffline(String serverId, String itemId);

  /// Delete cached metadata for [itemId] (used when removing a download).
  Future<void> deleteForItem(String serverId, String itemId);

  /// Persist a watched/unwatched flip into the cached metadata JSON for
  /// [itemId] so reloads (`getMetadata` / `getAllPinnedMetadata`) reflect the
  /// state without having to refetch from the server. No-op when the row
  /// isn't cached. Backend subclasses know which JSON fields to mutate
  /// (Plex `viewCount`, Jellyfin `UserData.PlayCount` / `Played`).
  ///
  /// Optional positional progress fields ([viewOffsetMs], [lastViewedAt],
  /// [viewedLeafCount]) let the offline-watch-sync service mirror richer
  /// snapshots from the server's episode-list response without having to
  /// fall back to a per-backend mutation. When omitted, the watched flip
  /// uses the same defaults as before (zero-out `viewOffset`, stamp
  /// `lastViewedAt` only when transitioning to watched).
  ///
  /// **Drift discipline:** the inputs are backend-neutral but the JSON
  /// shape + units are not. Adding a new watch-state input here means
  /// updating *both* concrete impls ([PlexApiCache.applyWatchState],
  /// [JellyfinApiCache.applyWatchState]) — Plex stores epoch-seconds and
  /// flat fields, Jellyfin stores ISO-8601 + ticks under `UserData`.
  /// The mutations are too short (~3 lines per backend) for a shared
  /// adapter to be a net win, so they live duplicated by design.
  Future<void> applyWatchState({
    required String serverId,
    required String itemId,
    required bool isWatched,
    int? viewOffsetMs,
    int? lastViewedAt,
    int? viewedLeafCount,
  });

  /// Bulk-load every pinned metadata row into a [MediaItem] map keyed by
  /// `buildGlobalKey(serverId, itemId)`. Used by [DownloadManagerService] on
  /// cold start to hydrate offline state in a single query per backend.
  Future<Map<String, MediaItem>> getAllPinnedMetadata();
}
