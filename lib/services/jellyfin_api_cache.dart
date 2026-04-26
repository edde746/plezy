import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../utils/global_key_utils.dart';
import '../utils/isolate_helper.dart';
import 'api_cache.dart';
import 'credential_vault.dart';
import 'jellyfin_mappers.dart';

/// Jellyfin-shape helpers on top of the shared [ApiCache] substrate.
///
/// Cache rows for Jellyfin item metadata use the compound connection id
/// (`{machineId}/{userId}`) plus the read-path endpoint key
/// `/Users/{userId}/Items/{itemId}`. The public [MediaItem.serverId] remains
/// the bare machine id; the compound prefix only isolates local user-scoped
/// state such as `UserData`.
class JellyfinApiCache extends ApiCache {
  static JellyfinApiCache? _instance;
  static JellyfinApiCache get instance {
    if (_instance == null) {
      throw StateError('JellyfinApiCache not initialized. Call JellyfinApiCache.initialize() first.');
    }
    return _instance!;
  }

  JellyfinApiCache._(super.db);

  /// Initialize the singleton with an [AppDatabase] instance. Also registers
  /// this instance with the [ApiCache] backend dispatch so callers using
  /// `ApiCache.forBackend(MediaBackend.jellyfin)` resolve here.
  static void initialize(AppDatabase db) {
    _instance = JellyfinApiCache._(db);
    ApiCache.registerInstance(MediaBackend.jellyfin, _instance!);
  }

  static final RegExp _itemKeyPattern = RegExp(r'/Users/[^/]+/Items/([^/?]+)$');

  String _itemPattern(String serverId, String itemId) => '$serverId:/Users/%/Items/$itemId';

  /// Delete cached item metadata for [itemId] (single-item endpoint only;
  /// children-list endpoints are out of scope for v1 — they'll get cleaned
  /// up via [deleteForServer] or [clearAll]).
  @override
  Future<void> deleteForItem(String serverId, String itemId) async {
    await (database.delete(database.apiCache)..where((t) => t.cacheKey.like(_itemPattern(serverId, itemId)))).go();
  }

  /// Pin the metadata row(s) for [itemId] so they survive cache eviction.
  @override
  Future<void> pinForOffline(String serverId, String itemId) => pinByKeyPattern(_itemPattern(serverId, itemId));

  /// Unpin a previously pinned item.
  Future<void> unpinForOffline(String serverId, String itemId) => unpinByKeyPattern(_itemPattern(serverId, itemId));

  /// Whether the metadata for [itemId] is pinned for offline.
  ///
  /// Named `isPinnedItemId` to avoid colliding with the inherited
  /// [ApiCache.isPinned]'s identical Dart signature.
  Future<bool> isPinnedItemId(String serverId, String itemId) => hasPinnedMatching(_itemPattern(serverId, itemId));

  /// Get all pinned Jellyfin item ids for a server.
  Future<Set<String>> getPinnedItemIds(String serverId) => extractPinnedIds(serverId, _itemKeyPattern);

  /// Fetch and parse a [MediaItem] from cache.
  ///
  /// Returns `null` when no matching row is cached, the row's JSON is
  /// unparseable, or the [Connections] row for [serverId] is missing/has no
  /// usable `baseUrl`.
  ///
  /// Image paths are run through [JellyfinImageAbsolutizer] so cached items
  /// carry the same absolute URLs as items produced by [JellyfinClient]'s
  /// live mapper boundary — without this, downstream consumers (artwork
  /// downloads, offline image rendering) see raw `/Items/...` paths and
  /// fail.
  ///
  /// Single-item path stays on the main isolate — decoding one BaseItemDto
  /// is cheap and matches [PlexApiCache.getMetadata]'s shape. Bulk-load
  /// callers go through [getAllPinnedMetadata] which still parallelises.
  @override
  Future<MediaItem?> getMetadata(String serverId, String itemId) async {
    final row = await (database.select(
      database.apiCache,
    )..where((t) => t.cacheKey.like(_itemPattern(serverId, itemId)))).get();
    if (row.isEmpty) return null;

    final ctx = await _serverContext(serverId);
    if (ctx == null) return null;

    try {
      final data = jsonDecode(row.first.data) as Map<String, dynamic>;
      final absolutizer = JellyfinImageAbsolutizer(baseUrl: ctx.baseUrl, accessToken: ctx.accessToken);
      return JellyfinMappers.mediaItem(data, serverId: ctx.machineId, serverName: ctx.name, absolutizer: absolutizer);
    } catch (_) {
      return null;
    }
  }

  /// Persist a watched/unwatched flip into every cached `BaseItemDto` row
  /// for [itemId] (one per cached userId). Mirrors what the server returns
  /// after the flip so a later cache reload reflects the current watched
  /// state without a network roundtrip.
  ///
  /// [viewOffsetMs] is converted to Jellyfin's 100-ns ticks for
  /// `UserData.PlaybackPositionTicks`. [lastViewedAt] is treated as Plex's
  /// epoch-seconds and translated to Jellyfin's ISO-8601 `LastPlayedDate`.
  /// [viewedLeafCount] is ignored — Jellyfin tracks per-show rollup via
  /// `UserData.UnplayedItemCount`, computed from individual children rather
  /// than aggregated on the parent. The parameter is accepted for API parity
  /// with the Plex caller.
  @override
  Future<void> applyWatchState({
    required String serverId,
    required String itemId,
    required bool isWatched,
    int? viewOffsetMs,
    int? lastViewedAt,
    int? viewedLeafCount,
  }) async {
    final query = database.select(database.apiCache)..where((t) => t.cacheKey.like(_itemPattern(serverId, itemId)));
    final rows = await query.get();
    if (rows.isEmpty) return;
    for (final row in rows) {
      try {
        final data = jsonDecode(row.data) as Map<String, dynamic>;
        final userData = (data['UserData'] is Map<String, dynamic>)
            ? (data['UserData'] as Map<String, dynamic>)
            : <String, dynamic>{};
        userData['Played'] = isWatched;
        final positionTicks = viewOffsetMs != null ? viewOffsetMs * 10000 : 0;
        if (isWatched) {
          final current = (userData['PlayCount'] as num?)?.toInt() ?? 0;
          userData['PlayCount'] = current < 1 ? 1 : current;
          userData['PlaybackPositionTicks'] = positionTicks;
          userData['LastPlayedDate'] = lastViewedAt != null
              ? DateTime.fromMillisecondsSinceEpoch(lastViewedAt * 1000, isUtc: true).toIso8601String()
              : DateTime.now().toUtc().toIso8601String();
        } else {
          userData['PlayCount'] = 0;
          userData['PlaybackPositionTicks'] = positionTicks;
          if (lastViewedAt != null) {
            userData['LastPlayedDate'] = DateTime.fromMillisecondsSinceEpoch(
              lastViewedAt * 1000,
              isUtc: true,
            ).toIso8601String();
          }
        }
        data['UserData'] = userData;
        final encoded = jsonEncode(data);
        await (database.update(database.apiCache)..where((t) => t.cacheKey.equals(row.cacheKey))).write(
          ApiCacheCompanion(data: Value(encoded), cachedAt: Value(DateTime.now())),
        );
      } catch (_) {
        // Skip malformed entries.
      }
    }
  }

  /// Load all pinned Jellyfin metadata in a single query.
  ///
  /// Returns a map keyed by `buildGlobalKey(serverId, itemId)` for O(1)
  /// lookups, mirroring [PlexApiCache.getAllPinnedMetadata] so callers can
  /// spread-merge the two results.
  @override
  Future<Map<String, MediaItem>> getAllPinnedMetadata() async {
    final entries = await listPinnedRowsByPattern(_itemKeyPattern);
    if (entries.isEmpty) return {};

    // Resolve the connection context per serverId once on the main thread
    // (DB queries can't move into the isolate). Each context carries the
    // serverName used to stamp the [MediaItem] plus the baseUrl/accessToken
    // required to absolutize image paths.
    final contexts = <String, ({String machineId, String name, String baseUrl, String accessToken})>{};
    final absolutizers = <String, JellyfinImageAbsolutizer>{};
    for (final id in entries.map((e) => e.serverId).toSet()) {
      final ctx = await _serverContext(id);
      if (ctx != null) {
        contexts[id] = ctx;
        absolutizers[id] = JellyfinImageAbsolutizer(baseUrl: ctx.baseUrl, accessToken: ctx.accessToken);
      }
    }

    return await tryIsolateRun(() {
      final result = <String, MediaItem>{};
      for (final entry in entries) {
        final ctx = contexts[entry.serverId];
        final absolutizer = absolutizers[entry.serverId];
        if (ctx == null || absolutizer == null) continue;
        try {
          final data = jsonDecode(entry.data) as Map<String, dynamic>;
          final mapped = JellyfinMappers.mediaItem(
            data,
            serverId: ctx.machineId,
            serverName: ctx.name,
            absolutizer: absolutizer,
          );
          if (mapped != null) {
            result[buildGlobalKey(entry.serverId, entry.id)] = mapped;
          }
        } catch (_) {
          // Skip malformed entries
        }
      }
      return result;
    });
  }

  /// Resolve the connection context (server name + base URL + access token)
  /// for a cache row keyed by the server's machineId. The [Connections]
  /// row's `id` is `${serverMachineId}/$userId`, so a direct `id == serverId`
  /// lookup misses; fall back to a prefix match.
  ///
  /// `name` matches what the live [JellyfinClient] stamps onto online
  /// MediaItems (`connection.serverName`, not the compound `displayName`).
  /// `baseUrl` and `accessToken` come from the same `configJson` payload
  /// [JellyfinConnection.toConfigJson] writes, so cache-read absolutization
  /// uses the current values — token/URL rotations Just Work.
  ///
  /// Returns `null` when no row matches or the row carries an empty
  /// `baseUrl` (no honest URL we can build).
  Future<({String machineId, String name, String baseUrl, String accessToken})?> _serverContext(String serverId) async {
    // Match either the bare machineId (Plex) or the compound
    // `{machineId}/{userId}` (Jellyfin). The compound match uses a
    // [substr]-based prefix check so any `_` / `%` in the runtime
    // [serverId] is treated literally — `LIKE '$serverId/%'` would
    // interpret those chars as wildcards.
    final prefix = '$serverId/';
    final row =
        await (database.select(database.connections)
              ..where((t) => t.id.equals(serverId) | t.id.substr(1, prefix.length).equals(prefix))
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    String? configName;
    String? machineId;
    String baseUrl = '';
    String accessToken = '';
    try {
      final rawConfig = jsonDecode(row.configJson) as Map<String, dynamic>;
      final config = (await CredentialVault.revealConnectionConfig(row.kind, rawConfig)).config;
      configName = config['serverName'] as String?;
      machineId = config['serverMachineId'] as String?;
      baseUrl = config['baseUrl'] as String? ?? '';
      accessToken = config['accessToken'] as String? ?? '';
    } catch (_) {
      // Fall through with the values defaulted above.
    }
    if (baseUrl.isEmpty) return null;
    machineId ??= row.id.contains('/') ? row.id.substring(0, row.id.indexOf('/')) : row.id;
    final name = (configName != null && configName.isNotEmpty) ? configName : row.displayName;
    return (machineId: machineId, name: name, baseUrl: baseUrl, accessToken: accessToken);
  }
}
