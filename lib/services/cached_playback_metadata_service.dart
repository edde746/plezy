import 'dart:convert';

import 'package:drift/drift.dart';

import '../media/media_backend.dart';
import '../media/media_source_info.dart';
import '../utils/app_logger.dart';
import '../utils/plex_cache_parser.dart';
import 'api_cache.dart';
import 'jellyfin_media_info_mapper.dart';
import 'plex_mappers.dart';

class CachedPlaybackMetadataService {
  const CachedPlaybackMetadataService._();

  static Future<MediaSourceInfo?> fetchMediaSourceInfo({
    required MediaBackend backend,
    required String cacheServerId,
    required String itemId,
    int mediaIndex = 0,
  }) async {
    try {
      return switch (backend) {
        MediaBackend.plex => _fetchPlexMediaSourceInfo(cacheServerId, itemId, mediaIndex: mediaIndex),
        MediaBackend.jellyfin => _fetchJellyfinMediaSourceInfo(cacheServerId, itemId, mediaIndex: mediaIndex),
      };
    } catch (e) {
      appLogger.d('Cached media source info unavailable for $cacheServerId:$itemId', error: e);
      return null;
    }
  }

  static Future<PlaybackExtras?> fetchPlaybackExtras({
    required MediaBackend backend,
    required String cacheServerId,
    required String itemId,
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
  }) async {
    try {
      return switch (backend) {
        MediaBackend.plex => _fetchPlexPlaybackExtras(
          cacheServerId,
          itemId,
          introPattern: introPattern,
          creditsPattern: creditsPattern,
          forceChapterFallback: forceChapterFallback,
        ),
        MediaBackend.jellyfin => _fetchJellyfinPlaybackExtras(cacheServerId, itemId),
      };
    } catch (e) {
      appLogger.d('Cached playback extras unavailable for $cacheServerId:$itemId', error: e);
      return null;
    }
  }

  static Future<MediaSourceInfo?> _fetchPlexMediaSourceInfo(
    String serverId,
    String itemId, {
    required int mediaIndex,
  }) async {
    final metadata = await _plexMetadata(serverId, itemId);
    return metadata == null ? null : plexMediaSourceInfoFromCacheJson(metadata, mediaIndex: mediaIndex);
  }

  static Future<PlaybackExtras?> _fetchPlexPlaybackExtras(
    String serverId,
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
  }) async {
    final metadata = await _plexMetadata(serverId, itemId);
    if (metadata == null) return null;
    return plexPlaybackExtrasFromCacheJson(
      metadata,
      introPattern: introPattern,
      creditsPattern: creditsPattern,
      forceChapterFallback: forceChapterFallback,
    );
  }

  static Future<Map<String, dynamic>?> _plexMetadata(String serverId, String itemId) async {
    final cached = await ApiCache.forBackend(MediaBackend.plex).get(serverId, '/library/metadata/$itemId');
    return PlexCacheParser.extractFirstMetadata(cached);
  }

  static Future<MediaSourceInfo?> _fetchJellyfinMediaSourceInfo(
    String cacheServerId,
    String itemId, {
    required int mediaIndex,
  }) async {
    final raw = await _jellyfinRawItem(cacheServerId, itemId);
    final sources = raw['MediaSources'];
    if (sources is! List || sources.isEmpty) return null;
    final selected = mediaIndex >= 0 && mediaIndex < sources.length ? sources[mediaIndex] : sources.first;
    if (selected is! Map<String, dynamic>) return null;
    return jellyfinMediaSourceToMediaSourceInfo(selected, chapters: raw['Chapters'], trickplay: raw['Trickplay']);
  }

  static Future<PlaybackExtras?> _fetchJellyfinPlaybackExtras(String cacheServerId, String itemId) async {
    final raw = await _jellyfinRawItem(cacheServerId, itemId);
    return jellyfinPlaybackExtrasFromRaw(raw, itemId);
  }

  static Future<Map<String, dynamic>> _jellyfinRawItem(String cacheServerId, String itemId) async {
    final cache = ApiCache.forBackend(MediaBackend.jellyfin);
    final scopedPrefix = cacheServerId.contains('/') ? null : '$cacheServerId/%:/Users/%/Items/$itemId';
    final rows =
        await (cache.database.select(cache.database.apiCache)..where(
              (t) =>
                  t.cacheKey.like('$cacheServerId:/Users/%/Items/$itemId') |
                  (scopedPrefix == null ? const Constant(false) : t.cacheKey.like(scopedPrefix)),
            ))
            .get();
    if (rows.isEmpty) throw StateError('No Jellyfin cache row for $cacheServerId:$itemId');
    return jsonDecode(rows.first.data) as Map<String, dynamic>;
  }
}
