import '../../database/app_database.dart';
import '../../media/ids.dart';
import '../../media/media_item.dart';
import '../../media/media_server_client.dart';
import '../../media/media_source_info.dart';
import '../../services/cached_playback_metadata_service.dart';
import '../../services/the_intro_db_fallback_service.dart';
import '../../services/settings_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/global_key_utils.dart';

class VideoControlsPlaybackExtrasLoader {
  final MediaItem metadata;
  final MediaServerClient? client;
  final AppDatabase database;

  const VideoControlsPlaybackExtrasLoader({required this.metadata, required this.database, required this.client});

  Future<PlaybackExtras?> load({bool forceRefresh = false}) async {
    if (client == null) {
      return _loadFromCacheOnly(cacheServerId: await _resolveCacheServerId());
    }

    try {
      appLogger.d('_loadPlaybackExtras: starting for ${metadata.id} (forceRefresh=$forceRefresh)');
      final settings = await SettingsService.getInstance();
      final extras = await client!.fetchPlaybackExtras(
        metadata.id,
        introPattern: settings.read(SettingsService.introPattern),
        creditsPattern: settings.read(SettingsService.creditsPattern),
        forceChapterFallback: settings.read(SettingsService.forceSkipMarkerFallback),
        forceRefresh: forceRefresh,
      );
      final resolved = await _addTheIntroDbFallback(extras, client!);
      appLogger.d('_loadPlaybackExtras: got ${_describe(resolved)}');
      return resolved;
    } catch (e, stack) {
      appLogger.d('_loadPlaybackExtras: network path failed, trying cache fallback');
      try {
        final settings = await SettingsService.getInstance();
        final extras = await client!.fetchPlaybackExtrasFromCacheOnly(
          metadata.id,
          introPattern: settings.read(SettingsService.introPattern),
          creditsPattern: settings.read(SettingsService.creditsPattern),
          forceChapterFallback: settings.read(SettingsService.forceSkipMarkerFallback),
        );
        if (extras != null) {
          final resolved = await _addTheIntroDbFallback(extras, client!);
          appLogger.d('_loadPlaybackExtras: loaded ${_describe(resolved)} from cache');
          return resolved;
        }
      } catch (cacheError) {
        appLogger.d('_loadPlaybackExtras: cache fallback failed', error: cacheError);
      }
      appLogger.e('_loadPlaybackExtras failed', error: e, stackTrace: stack);
      return null;
    }
  }

  Future<PlaybackExtras> _addTheIntroDbFallback(PlaybackExtras extras, MediaServerClient client) async {
    final settings = await SettingsService.getInstance();
    if (!settings.read(SettingsService.theIntroDbFallback) || extras.markers.any((marker) => marker.type == 'intro')) {
      return extras;
    }
    try {
      final markers = await TheIntroDbFallbackService().fetchIntroMarkers(metadata, client);
      if (markers.isEmpty) return extras;
      final combined = [...extras.markers, ...markers]..sort((a, b) => a.startTimeOffset.compareTo(b.startTimeOffset));
      return PlaybackExtras(chapters: extras.chapters, markers: combined);
    } catch (error) {
      appLogger.d('TheIntroDB fallback unavailable', error: error);
      return extras;
    }
  }

  Future<PlaybackExtras?> _loadFromCacheOnly({required String? cacheServerId}) async {
    if (cacheServerId == null) {
      appLogger.w('_loadPlaybackExtras: no client or cache scope for server ${metadata.serverId}');
      return null;
    }
    try {
      final settings = await SettingsService.getInstance();
      final extras = await CachedPlaybackMetadataService.fetchPlaybackExtras(
        backend: metadata.backend,
        cacheServerId: cacheServerId,
        itemId: metadata.id,
        introPattern: settings.read(SettingsService.introPattern),
        creditsPattern: settings.read(SettingsService.creditsPattern),
        forceChapterFallback: settings.read(SettingsService.forceSkipMarkerFallback),
      );
      appLogger.d(
        extras == null
            ? '_loadPlaybackExtras: no cached extras for ${metadata.id}'
            : '_loadPlaybackExtras: cache-only ${_describe(extras)}',
      );
      return extras;
    } catch (e) {
      appLogger.d('_loadPlaybackExtras: cache-only path failed', error: e);
      return null;
    }
  }

  /// Marker counts are the difference between "the server has no intro data"
  /// and "auto-skip never fired", which is otherwise indistinguishable in a
  /// user-supplied log.
  static String _describe(PlaybackExtras extras) {
    final markerTypes = extras.markers.map((m) => m.type).join(',');
    return '${extras.chapters.length} chapters, ${extras.markers.length} markers'
        '${markerTypes.isEmpty ? '' : ' ($markerTypes)'}';
  }

  Future<String?> _resolveCacheServerId() async {
    final serverId = metadata.serverId;
    if (serverId == null) return null;
    try {
      final row = await (database.select(
        database.downloadedMedia,
      )..where((tbl) => tbl.globalKey.equals(buildGlobalKey(ServerId(serverId), metadata.id)))).getSingleOrNull();
      return row?.clientScopeId ?? serverId;
    } catch (_) {
      return serverId;
    }
  }
}
