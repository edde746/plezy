import '../database/app_database.dart';
import '../media/ids.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import 'api_cache.dart';

/// Music Assistant's slice of the shared [ApiCache] substrate.
///
/// Unlike the Plex and Jellyfin caches, rows here hold the *neutral*
/// [MediaItem] JSON rather than the backend's own payload. Music Assistant's
/// wire model is parsed into `MaItem` at the socket boundary and the source map
/// is not retained, so there is no backend-native shape left to store — and
/// nothing on this backend re-reads one.
class MusicAssistantApiCache extends ApiCache {
  static final _singleton = ApiCacheSingleton<MusicAssistantApiCache>({
    MediaBackend.musicAssistant,
  }, 'MusicAssistantApiCache');

  static MusicAssistantApiCache get instance => _singleton.instance;

  MusicAssistantApiCache._(super.db);

  /// Initialize the singleton and register it for
  /// `ApiCache.forBackend(MediaBackend.musicAssistant)` dispatch.
  static void initialize(AppDatabase db) => _singleton.install(MusicAssistantApiCache._(db));

  /// Cache key for one item. The id is a Music Assistant uri
  /// (`library://track/68057`), which is the only globally unique handle the
  /// server has — `item_id` is scoped to both provider and media type.
  static String itemEndpoint(String id) => '/music/item/${Uri.encodeComponent(id)}';

  @override
  Future<MediaItem?> getMetadata(ServerId serverId, String itemId) async {
    final cached = await get(serverId, itemEndpoint(itemId));
    if (cached == null) return null;
    try {
      return MediaItem.fromJson(cached);
    } catch (_) {
      // A row written by an older schema is not worth failing a read over;
      // the caller treats null as a miss and refetches.
      return null;
    }
  }

  Future<void> putMetadata(ServerId serverId, MediaItem item) => put(serverId, itemEndpoint(item.id), item.toJson());

  @override
  Future<void> deleteForItem(ServerId serverId, String itemId) => _delete(serverId, itemEndpoint(itemId));

  /// Music Assistant has no download pipeline in this app — it is a streaming
  /// music backend with no offline surface — so nothing is ever pinned. Pinning
  /// the row anyway keeps the [ApiCache] contract honest rather than throwing
  /// from a cache primitive, which callers do not expect.
  @override
  Future<void> pinForOffline(ServerId serverId, String itemId) => pin(serverId, itemEndpoint(itemId));

  /// No-op: this backend has no watched state. Music Assistant tracks favourites
  /// (`music/favorites/*`) and nothing else per item, and there is no played
  /// flag on the wire to mirror into a cached row.
  @override
  Future<void> applyWatchState({
    required ServerId serverId,
    required String itemId,
    required bool isWatched,
    int? viewOffsetMs,
    int? lastViewedAt,
    int? viewedLeafCount,
  }) async {}

  /// Always empty, for the same reason as [pinForOffline]: nothing on this
  /// backend pins metadata, so the offline library never has rows to hydrate.
  @override
  Future<Map<String, MediaItem>> getAllPinnedMetadata({Set<ServerId>? cacheServerIds}) async => const {};

  Future<void> _delete(ServerId serverId, String endpoint) async {
    final key = '$serverId:$endpoint';
    await (database.delete(database.apiCache)..where((t) => t.cacheKey.equals(key))).go();
  }
}
