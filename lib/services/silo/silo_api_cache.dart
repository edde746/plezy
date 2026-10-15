import '../../database/app_database.dart';
import '../../media/ids.dart';
import '../../media/media_backend.dart';
import '../../media/media_item.dart';
import '../../utils/app_logger.dart';
import '../api_cache.dart';

/// Offline cache for Silo items.
///
/// Rows hold Plezy's own serialized [MediaItem] (not raw server JSON), keyed
/// `{cacheServerId}:/items/{contentId}`, so offline reads need no Silo
/// response parsing. The cache server id is the connection's
/// `{serverId}/{profileId}` scope, which keeps one profile's watch state from
/// leaking into another's.
class SiloApiCache extends ApiCache {
  static final _singleton = ApiCacheSingleton<SiloApiCache>(const {MediaBackend.silo}, 'SiloApiCache');
  static SiloApiCache get instance => _singleton.instance;

  SiloApiCache._(super.db);

  static void initialize(AppDatabase db) => _singleton.install(SiloApiCache._(db));

  static String itemEndpoint(String itemId) => '/items/$itemId';
  static final RegExp _itemKeyPattern = RegExp(r':/items/(.+)$');

  Future<void> putItem(ServerId cacheServerId, MediaItem item) async {
    try {
      await put(cacheServerId, itemEndpoint(item.id), {'item': item.toJson()});
    } catch (e, st) {
      appLogger.w('SiloApiCache: write failed for ${item.id}', error: e, stackTrace: st);
    }
  }

  @override
  Future<MediaItem?> getMetadata(ServerId serverId, String itemId) async {
    final row = await get(serverId, itemEndpoint(itemId));
    return _decode(row);
  }

  MediaItem? _decode(Map<String, dynamic>? row) {
    final json = row?['item'];
    if (json is! Map<String, dynamic>) return null;
    try {
      return MediaItem.fromJson(json);
    } catch (e) {
      appLogger.w('SiloApiCache: unreadable cached item', error: e);
      return null;
    }
  }

  @override
  Future<void> pinForOffline(ServerId serverId, String itemId) => pin(serverId, itemEndpoint(itemId));

  @override
  Future<void> deleteForItem(ServerId serverId, String itemId) async {
    final key = '$serverId:${itemEndpoint(itemId)}';
    await (database.delete(database.apiCache)..where((t) => t.cacheKey.equals(key))).go();
  }

  @override
  Future<void> applyWatchState({
    required ServerId serverId,
    required String itemId,
    required bool isWatched,
    int? viewOffsetMs,
    int? lastViewedAt,
    int? viewedLeafCount,
  }) async {
    final endpoint = itemEndpoint(itemId);
    final current = _decode(await get(serverId, endpoint));
    if (current is! SiloMediaItem) return;
    final updated = current.copyWith(
      viewCount: current.kind.usesLeafWatchCounts ? current.viewCount : (isWatched ? 1 : 0),
      viewOffsetMs: isWatched ? null : (viewOffsetMs ?? current.viewOffsetMs),
      lastViewedAt: lastViewedAt ?? current.lastViewedAt,
      viewedLeafCount: viewedLeafCount ?? current.viewedLeafCount,
    );
    final pinned = await isPinned(serverId, endpoint);
    await put(serverId, endpoint, {'item': updated.toJson()});
    if (pinned) await pin(serverId, endpoint);
  }

  @override
  Future<Map<String, MediaItem>> getAllPinnedMetadata({Set<ServerId>? cacheServerIds}) async {
    final rows = await listPinnedRowsByPattern(_itemKeyPattern);
    final out = <String, MediaItem>{};
    for (final row in rows) {
      if (cacheServerIds != null && !cacheServerIds.contains(row.serverId)) continue;
      final decoded = decodeCachedMediaRows<({ServerId serverId, String id, String data})>(
        [row],
        serializedData: (r) => r.data,
        decode: (r, json) {
          final item = _decode(json);
          return item == null ? null : MapEntry('${r.serverId}:${r.id}', item);
        },
      );
      out.addAll(decoded);
    }
    return out;
  }
}
