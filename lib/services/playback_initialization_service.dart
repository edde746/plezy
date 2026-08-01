import 'dart:io';
import '../media/ids.dart';

import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../media/media_source_info.dart';
import '../mpv/models.dart';
import '../utils/app_logger.dart';
import '../utils/global_key_utils.dart';
import 'cached_playback_metadata_service.dart';
import 'download_storage_service.dart';
import 'downloaded_video_source.dart';
import 'playback_initialization_types.dart';

// Re-export so existing callers (video_player_screen) can keep importing
// PlaybackException / PlaybackInitializationResult / TranscodeFallbackReason
// via this service file.
export 'playback_initialization_types.dart';

/// Coordinates playback initialization across backends and modes.
///
/// **Online (client + network):** delegates to
/// [MediaServerClient.getPlaybackInitialization] for the per-backend
/// transcode-or-direct decision.
///
/// **Downloaded/offline:** when [preferOffline] finds a local copy, opens it
/// immediately using per-backend cached [MediaSourceInfo] plus sidecar
/// subtitles. This intentionally avoids any network-first metadata call.
class PlaybackInitializationService {
  final MediaServerClient? client;
  final AppDatabase? database;

  PlaybackInitializationService({this.client, this.database});

  /// Format a video path as a URL (adds file:// prefix for file paths)
  String _formatVideoUrl(String path) {
    return path.contains('://') ? path : 'file://$path';
  }

  /// Check if content is available offline and return local path
  ///
  /// Returns the local file path if the video is downloaded and completed.
  /// Returns null if not available offline or database is not provided.
  Future<String?> getOfflineVideoPath(
    ServerId serverId,
    String ratingKey, {
    int mediaIndex = 0,
    String? selectedMediaSourceId,
  }) async {
    final source = await _resolveOfflineVideoSource(
      serverId,
      ratingKey,
      mediaIndex: mediaIndex,
      selectedMediaSourceId: selectedMediaSourceId,
    );
    return source?.path;
  }

  /// Resolve the downloaded copy of an item to its playable local path plus
  /// the version that is actually on disk.
  ///
  /// Strict by default: a version mismatch returns null so online flows keep
  /// streaming an explicitly requested non-downloaded version. With
  /// [allowAnyDownloadedVersion] the single downloaded version is returned on
  /// mismatch instead — for offline flows where the alternative is failing.
  Future<DownloadedVideoSource?> _resolveOfflineVideoSource(
    ServerId serverId,
    String ratingKey, {
    required int mediaIndex,
    String? selectedMediaSourceId,
    bool allowAnyDownloadedVersion = false,
  }) async {
    if (database == null) {
      return null;
    }

    try {
      // Query by globalKey — the column is UNIQUE so SQLite's auto-index on it
      // makes this an O(log n) lookup. Filtering by (serverId, ratingKey)
      // would only use the serverId index and then linear-scan matching rows.
      final query = database!.select(database!.downloadedMedia)
        ..where((tbl) => tbl.globalKey.equals(buildGlobalKey(ServerId(serverId), ratingKey)));

      final downloadedItem = await query.getSingleOrNull();
      if (downloadedItem == null) {
        return null;
      }

      return await resolveDownloadedVideoSource(
        downloadedItem,
        requestedMediaIndex: mediaIndex,
        requestedMediaSourceId: selectedMediaSourceId,
        allowAnyDownloadedVersion: allowAnyDownloadedVersion,
      );
    } catch (e) {
      appLogger.w('Error checking offline video path', error: e);
      return null;
    }
  }

  /// Fetch playback data for the given metadata.
  ///
  /// Online path: delegates to [MediaServerClient.getPlaybackInitialization].
  ///
  /// Downloaded/offline path: when [preferOffline] finds a downloaded copy,
  /// builds from cached [MediaSourceInfo] and local sidecars immediately.
  Future<PlaybackInitializationResult> getPlaybackData(
    PlaybackInitializationOptions options, {
    bool preferOffline = false,
  }) async {
    final metadata = options.metadata;
    final serverId = metadata.serverId ?? client?.serverId;

    DownloadedVideoSource? offlineSource;
    if (serverId != null && (preferOffline || client == null) && database != null) {
      offlineSource = await _resolveOfflineVideoSource(
        ServerId(serverId),
        metadata.id,
        mediaIndex: options.selectedMediaIndex,
        selectedMediaSourceId: options.selectedMediaSourceId,
        // With no client there is nothing to stream from, so any downloaded
        // version beats failing. With a client the strict match must stand:
        // an explicitly requested non-downloaded version streams from the
        // server (issue #1440).
        allowAnyDownloadedVersion: client == null,
      );
    }

    // Downloaded playback must not wait on a live server. Cached media info
    // preserves track labels where available; the local file is enough to play.
    if (offlineSource != null) {
      appLogger.d('Using offline playback for ${metadata.id}');
      return _buildOfflineResult(
        metadata: metadata,
        offlineVideoPath: offlineSource.path,
        selectedMediaIndex: offlineSource.mediaIndex,
        selectedMediaSourceId: offlineSource.mediaSourceId,
      );
    }

    if (client == null) throw PlaybackException('No video URL available');

    PlaybackInitializationResult result;
    try {
      result = await client!.getPlaybackInitialization(options);
    } catch (e) {
      rethrow;
    }

    return result;
  }

  /// Assemble a pure-offline result: local file + cached media info + sidecar
  /// subtitles. Used both when [client] is null and when an online fetch throws.
  Future<PlaybackInitializationResult> _buildOfflineResult({
    required MediaItem metadata,
    required String offlineVideoPath,
    required int selectedMediaIndex,
    String? selectedMediaSourceId,
  }) async {
    MediaSourceInfo? mediaInfo;
    try {
      final cacheServerId = await _resolveCacheServerId(metadata);
      if (cacheServerId != null) {
        mediaInfo = await CachedPlaybackMetadataService.fetchMediaSourceInfo(
          backend: metadata.backend,
          cacheServerId: cacheServerId,
          itemId: metadata.id,
          mediaIndex: selectedMediaIndex,
        );
      }
    } catch (e) {
      appLogger.d('Could not load cached media info for offline playback', error: e);
    }

    final subtitleSidecars = await _discoverSidecarSubtitles(
      offlineVideoPath,
      metadata: metadata,
      mediaInfo: mediaInfo,
    );

    return PlaybackInitializationResult(
      availableVersions: const [],
      videoUrl: _formatVideoUrl(offlineVideoPath),
      mediaInfo: mediaInfo,
      subtitleSidecars: subtitleSidecars,
      isOffline: true,
      playMethod: 'DirectPlay',
      selectedMediaIndex: selectedMediaIndex,
      selectedMediaSourceId: selectedMediaSourceId,
    );
  }

  Future<String?> _resolveCacheServerId(MediaItem metadata) async {
    final liveClient = client;
    if (liveClient != null) return liveClient.cacheServerId;

    final serverId = metadata.serverId;
    if (serverId == null) return null;
    final db = database;
    if (db == null) return serverId;

    try {
      final row = await (db.select(
        db.downloadedMedia,
      )..where((tbl) => tbl.globalKey.equals(buildGlobalKey(ServerId(serverId), metadata.id)))).getSingleOrNull();
      return row?.clientScopeId ?? serverId;
    } catch (_) {
      return serverId;
    }
  }

  /// Find sidecar subtitle files written by the downloader. Plain file videos
  /// use `{video}_subs/{trackId}.{ext}` with a legacy `{videoDir}/subtitles/*`
  /// fallback. SAF videos are `content://` URIs, so sidecars live in the
  /// app-managed subtitle directory keyed by server/item id.
  Future<List<PlaybackSubtitleSidecar>> _discoverSidecarSubtitles(
    String videoPath, {
    required MediaItem metadata,
    MediaSourceInfo? mediaInfo,
  }) async {
    final subtitles = <PlaybackSubtitleSidecar>[];
    final dirs = videoPath.startsWith('content://')
        ? await _safSidecarSubtitleDirs(metadata)
        : await _fileSidecarSubtitleDirs(videoPath);

    for (final subsDir in dirs) {
      if (!await subsDir.exists()) continue;
      final entities = await subsDir.list().toList();
      for (final entity in entities) {
        if (entity is! File) continue;
        final fileName = p.basenameWithoutExtension(entity.path);
        final trackId = int.tryParse(fileName);

        final cachedTrack = trackId != null
            ? mediaInfo?.subtitleTracks.where((t) => t.id == trackId).firstOrNull
            : null;

        subtitles.add(
          PlaybackSubtitleSidecar(
            sourceStreamId: trackId,
            track: SubtitleTrack.uri(
              Uri.file(entity.path).toString(),
              title: cachedTrack?.displayTitle ?? cachedTrack?.language ?? 'Subtitle $fileName',
              language: cachedTrack?.languageCode,
              codec: cachedTrack?.codec,
              isDefault: cachedTrack?.selected ?? false,
              isForced: cachedTrack?.forced ?? false,
            ),
          ),
        );
      }
    }

    return subtitles;
  }

  Future<List<Directory>> _fileSidecarSubtitleDirs(String videoPath) async {
    final subsPath = videoPath.replaceAll(RegExp(r'\.[^.]+$'), '_subs');
    final primary = Directory(subsPath);
    if (await primary.exists()) return [primary];
    return [Directory(p.join(File(videoPath).parent.path, 'subtitles'))];
  }

  Future<List<Directory>> _safSidecarSubtitleDirs(MediaItem metadata) async {
    final serverId = metadata.serverId;
    if (serverId == null) return const [];

    final storage = DownloadStorageService.instance;
    final dirs = <Directory>[];
    if (metadata.isEpisode && metadata.title != null) {
      dirs.add(await storage.getEpisodeSubtitlesDirectory(metadata));
    } else if (metadata.isMovie && metadata.title != null) {
      dirs.add(await storage.getMovieSubtitlesDirectory(metadata));
    }
    dirs.add(await storage.getSubtitlesDirectory(ServerId(serverId), metadata.id));
    return dirs;
  }
}
