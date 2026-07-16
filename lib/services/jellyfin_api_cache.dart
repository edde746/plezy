import 'dart:convert';
import '../media/ids.dart';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../utils/app_logger.dart';
import '../utils/global_key_utils.dart';
import '../utils/isolate_helper.dart';
import 'api_cache.dart';
import 'credential_vault.dart';
import 'jellyfin_cache_resolver.dart';
import 'jellyfin_mappers.dart';

/// Jellyfin-shape helpers on top of the shared [ApiCache] substrate.
///
/// Cache rows for Jellyfin item metadata use the compound connection id
/// (`{machineId}/{userId}`) plus the read-path endpoint key
/// `/Users/{userId}/Items/{itemId}`. The public [MediaItem.serverId] remains
/// the bare machine id; the compound prefix only isolates local user-scoped
/// state such as `UserData`.
class JellyfinApiCache extends ApiCache {
  static final _singleton = ApiCacheSingleton<JellyfinApiCache>(MediaBackend.jellyfin, 'JellyfinApiCache');
  static JellyfinApiCache get instance => _singleton.instance;

  JellyfinApiCache._(super.db);

  /// Initialize the singleton with an [AppDatabase] instance. Also registers
  /// this instance with the [ApiCache] backend dispatch so callers using
  /// `ApiCache.forBackend(MediaBackend.jellyfin)` resolve here.
  static void initialize(AppDatabase db) => _singleton.install(JellyfinApiCache._(db));

  JellyfinCacheResolver get _resolver => JellyfinCacheResolver(database);

  static String mediaSegmentsEndpoint(String itemId) => '/MediaSegments/${Uri.encodeComponent(itemId)}';

  /// Delete cached item metadata and playback segment rows for [itemId].
  /// Children-list endpoints are out of scope for v1 — they'll get cleaned up
  /// via [deleteForServer] or [clearAll].
  @override
  Future<void> deleteForItem(ServerId serverId, String itemId) async {
    final endpoint = mediaSegmentsEndpoint(itemId);
    await (database.delete(database.apiCache)..where(
          (t) => _resolver.itemKeyPredicate(t.cacheKey, serverId, itemId) | t.cacheKey.equals('$serverId:$endpoint'),
        ))
        .go();
  }

  /// Pin the metadata row(s) for [itemId] so they survive cache eviction.
  @override
  Future<void> pinForOffline(ServerId serverId, String itemId) async {
    final endpoint = mediaSegmentsEndpoint(itemId);
    await Future.wait([
      (database.update(database.apiCache)..where((t) => _resolver.itemKeyPredicate(t.cacheKey, serverId, itemId)))
          .write(const ApiCacheCompanion(pinned: Value(true))),
      pin(serverId, endpoint),
    ]);
  }

  Future<void> unpinForOffline(ServerId serverId, String itemId) async {
    final endpoint = mediaSegmentsEndpoint(itemId);
    await Future.wait([
      (database.update(database.apiCache)..where((t) => _resolver.itemKeyPredicate(t.cacheKey, serverId, itemId)))
          .write(const ApiCacheCompanion(pinned: Value(false))),
      unpin(serverId, endpoint),
    ]);
  }

  /// Whether the metadata for [itemId] is pinned for offline.
  ///
  /// Named `isPinnedItemId` to avoid colliding with the inherited
  /// [ApiCache.isPinned]'s identical Dart signature.
  Future<bool> isPinnedItemId(ServerId serverId, String itemId) async {
    final row =
        await (database.select(database.apiCache)
              ..where((t) => _resolver.itemKeyPredicate(t.cacheKey, serverId, itemId) & t.pinned.equals(true))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

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
  Future<MediaItem?> getMetadata(ServerId serverId, String itemId) async {
    final resolved = await _resolver.findResolvedItem(serverId, itemId);
    if (resolved == null) return null;
    final ctx = await _serverContext(resolved.connection, machineId: resolved.key.machineId);
    if (ctx == null) return null;

    try {
      final data = jsonDecode(resolved.cacheRow.data) as Map<String, dynamic>;
      final absolutizer = JellyfinImageAbsolutizer(baseUrl: ctx.baseUrl, accessToken: ctx.accessToken);
      return JellyfinMappers.mediaItem(
        data,
        serverId: ServerId(ctx.machineId),
        serverName: ctx.name,
        absolutizer: absolutizer,
      );
    } catch (_) {
      return null;
    }
  }

  /// Persist a watched/unwatched flip into cached `BaseItemDto` rows for
  /// [itemId]. Compound Jellyfin scope ids update only their user. A legacy
  /// bare machine id is accepted only when its matching rows belong to one
  /// user; ambiguous multi-user writes are skipped rather than bleeding watch
  /// state across profiles.
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
    required ServerId serverId,
    required String itemId,
    required bool isWatched,
    int? viewOffsetMs,
    int? lastViewedAt,
    int? viewedLeafCount,
  }) async {
    final query = database.select(database.apiCache)
      ..where((t) => _resolver.itemKeyPredicate(t.cacheKey, serverId, itemId));
    final rows = await query.get();
    if (rows.isEmpty) return;
    if (!serverId.contains('/')) {
      final userIds = <String>{
        for (final row in rows)
          if (JellyfinCacheResolver.parseItemKey(row.cacheKey) case final key?) key.userId,
      };
      if (userIds.length > 1) {
        appLogger.w(
          'Skipping ambiguous bare-scope Jellyfin watch-state cache write',
          error: {'serverId': serverId, 'itemId': itemId, 'userCount': userIds.length},
        );
        return;
      }
    }
    for (final row in rows) {
      try {
        final data = jsonDecode(row.data) as Map<String, dynamic>;
        final userData = (data['UserData'] is Map<String, dynamic>)
            ? (data['UserData'] as Map<String, dynamic>)
            : <String, dynamic>{};
        userData['Played'] = isWatched;
        final positionTicks = viewOffsetMs != null ? viewOffsetMs * 10_000 : 0;
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
  /// Returns a map keyed by `buildGlobalKey(ServerId(serverId), itemId)` for O(1)
  /// lookups, mirroring [PlexApiCache.getAllPinnedMetadata] so callers can
  /// spread-merge the two results.
  @override
  Future<Map<String, MediaItem>> getAllPinnedMetadata() async {
    final entries = await _resolver.findPinnedItems();
    if (entries.isEmpty) return {};

    // Resolve the connection context per serverId once on the main thread
    // (DB queries can't move into the isolate). Each context carries the
    // serverName used to stamp the [MediaItem] plus the baseUrl/accessToken
    // required to absolutize image paths.
    final contexts = <String, ({String machineId, String name, String baseUrl, String accessToken})>{};
    final absolutizers = <String, JellyfinImageAbsolutizer>{};
    for (final entry in entries) {
      final id = entry.connection.id;
      if (contexts.containsKey(id)) continue;
      final ctx = await _serverContext(entry.connection, machineId: entry.key.machineId);
      if (ctx != null) {
        contexts[id] = ctx;
        absolutizers[id] = JellyfinImageAbsolutizer(baseUrl: ctx.baseUrl, accessToken: ctx.accessToken);
      }
    }

    return await tryIsolateRun(
      () => decodeCachedMediaRows(
        entries,
        serializedData: (entry) => entry.cacheRow.data,
        decode: (entry, data) {
          final ctx = contexts[entry.connection.id];
          final absolutizer = absolutizers[entry.connection.id];
          if (ctx == null || absolutizer == null) return null;
          final mapped = JellyfinMappers.mediaItem(
            data,
            serverId: ServerId(ctx.machineId),
            serverName: ctx.name,
            absolutizer: absolutizer,
          );
          if (mapped == null) return null;
          return MapEntry(buildGlobalKey(ServerId(entry.key.scopeId), entry.key.itemId), mapped);
        },
      ),
    );
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
  Future<({String machineId, String name, String baseUrl, String accessToken})?> _serverContext(
    ConnectionRow row, {
    required String machineId,
  }) async {
    String? configName;
    String? configMachineId;
    String baseUrl = '';
    String accessToken = '';
    try {
      final rawConfig = jsonDecode(row.configJson) as Map<String, dynamic>;
      final config = (await CredentialVault.revealConnectionConfig(row.kind, rawConfig)).config;
      configName = config['serverName'] as String?;
      configMachineId = config['serverMachineId'] as String?;
      baseUrl = config['baseUrl'] as String? ?? '';
      accessToken = config['accessToken'] as String? ?? '';
    } catch (_) {
      // Fall through with the values defaulted above.
    }
    if (baseUrl.isEmpty) return null;
    configMachineId ??= machineId;
    final name = (configName != null && configName.isNotEmpty) ? configName : row.displayName;
    return (machineId: configMachineId, name: name, baseUrl: baseUrl, accessToken: accessToken);
  }
}
