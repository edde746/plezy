import 'plex_client.dart';
import '../models/plex_media_info.dart';
import '../models/plex_metadata.dart';
import '../models/download_status.dart';
import '../mpv/mpv.dart';
import '../utils/app_logger.dart';
import '../i18n/strings.g.dart';
import '../database/app_database.dart';
import 'download_storage_service.dart';
import 'dart:io';
import 'package:drift/drift.dart';

/// Service responsible for fetching video playback data from the Plex server
class PlaybackInitializationService {
  final PlexClient client;
  final AppDatabase? database;

  PlaybackInitializationService({required this.client, this.database});

  /// Check if content is available offline and return local path
  ///
  /// Returns the local file path if the video is downloaded and completed.
  /// Returns null if not available offline or database is not provided.
  Future<String?> getOfflineVideoPath(String serverId, String ratingKey) async {
    if (database == null) {
      return null;
    }

    try {
      // Query database for downloaded media with matching serverId and ratingKey
      final query = database!.select(database!.downloadedMedia)
        ..where(
          (tbl) =>
              tbl.serverId.equals(serverId) & tbl.ratingKey.equals(ratingKey),
        );

      final downloadedItem = await query.getSingleOrNull();

      // Return null if not found or not completed
      if (downloadedItem == null ||
          downloadedItem.status != DownloadStatus.completed.index) {
        return null;
      }

      // Return null if no video file path
      if (downloadedItem.videoFilePath == null) {
        return null;
      }

      final storageService = DownloadStorageService.instance;
      final storedPath = downloadedItem.videoFilePath!;

      // Check if this is a SAF URI (content://)
      if (storageService.isSafUri(storedPath)) {
        // SAF URIs are already valid for media players
        appLogger.d('Found offline video (SAF): $storedPath');
        return storedPath;
      }

      // Convert relative path to absolute path (handles both old absolute and new relative paths)
      final absolutePath = await storageService.ensureAbsolutePath(storedPath);

      // Verify file exists
      final file = File(absolutePath);
      if (!await file.exists()) {
        appLogger.w(
          'Offline video file not found: $absolutePath (stored as: $storedPath)',
        );
        return null;
      }

      appLogger.d('Found offline video: $absolutePath');
      return absolutePath;
    } catch (e) {
      appLogger.w('Error checking offline video path', error: e);
      return null;
    }
  }

  /// Fetch playback data for the given metadata
  ///
  /// Returns a PlaybackInitializationResult with video URL and available versions
  /// If [preferOffline] is true and offline content is available, uses local file
  Future<PlaybackInitializationResult> getPlaybackData({
    required PlexMetadata metadata,
    required int selectedMediaIndex,
    bool preferOffline = false,
  }) async {
    try {
      // Check for offline content first if preferOffline is enabled
      String? offlineVideoPath;
      if (preferOffline && database != null) {
        offlineVideoPath = await getOfflineVideoPath(
          client.serverId,
          metadata.ratingKey,
        );
      }

      // If offline video is available, use it
      if (offlineVideoPath != null) {
        appLogger.d('Using offline playback for ${metadata.ratingKey}');

        // For offline playback, we still need to fetch media info for subtitles
        // but use the local file path for video
        try {
          final playbackData = await client.getVideoPlaybackData(
            metadata.ratingKey,
            mediaIndex: selectedMediaIndex,
          );

          // Build list of external subtitle tracks
          final externalSubtitles = _buildExternalSubtitles(
            playbackData.mediaInfo,
          );

          // Return result with local file path (file:// prefix for file paths, keep SAF URIs as-is)
          return PlaybackInitializationResult(
            availableVersions: playbackData.availableVersions,
            videoUrl: offlineVideoPath.contains('://')
                ? offlineVideoPath
                : 'file://$offlineVideoPath',
            mediaInfo: playbackData.mediaInfo,
            externalSubtitles: externalSubtitles,
            isOffline: true,
          );
        } catch (e) {
          // If we can't fetch media info (e.g., no network), use offline-only mode
          appLogger.w(
            'Failed to fetch media info for offline video, using offline-only mode',
            error: e,
          );
          return PlaybackInitializationResult(
            availableVersions: [],
            videoUrl: offlineVideoPath.contains('://')
                ? offlineVideoPath
                : 'file://$offlineVideoPath',
            mediaInfo: null,
            externalSubtitles: const [],
            isOffline: true,
          );
        }
      }

      // Fall back to network streaming
      final playbackData = await client.getVideoPlaybackData(
        metadata.ratingKey,
        mediaIndex: selectedMediaIndex,
      );

      if (!playbackData.hasValidVideoUrl) {
        throw PlaybackException(t.messages.fileInfoNotAvailable);
      }

      // Build list of external subtitle tracks
      final externalSubtitles = _buildExternalSubtitles(playbackData.mediaInfo);

      // Return result with available versions and video URL
      return PlaybackInitializationResult(
        availableVersions: playbackData.availableVersions,
        videoUrl: playbackData.videoUrl,
        mediaInfo: playbackData.mediaInfo,
        externalSubtitles: externalSubtitles,
        isOffline: false,
      );
    } catch (e) {
      if (e is PlaybackException) {
        rethrow;
      }
      throw PlaybackException(t.messages.errorLoading(error: e.toString()));
    }
  }

  /// Build list of external subtitle tracks from media info
  List<SubtitleTrack> _buildExternalSubtitles(PlexMediaInfo? mediaInfo) {
    final externalSubtitles = <SubtitleTrack>[];

    if (mediaInfo == null) {
      return externalSubtitles;
    }

    final externalTracks = mediaInfo.subtitleTracks
        .where((PlexSubtitleTrack track) => track.isExternal)
        .toList();

    if (externalTracks.isNotEmpty) {
      appLogger.d('Found ${externalTracks.length} external subtitle track(s)');
    }

    for (final plexTrack in externalTracks) {
      try {
        // Skip if no auth token is available
        final token = client.config.token;
        if (token == null) {
          appLogger.w('No auth token available for external subtitles');
          continue;
        }

        final url = plexTrack.getSubtitleUrl(client.config.baseUrl, token);

        // Skip if URL couldn't be constructed
        if (url == null) continue;

        externalSubtitles.add(
          SubtitleTrack.uri(
            url,
            title:
                plexTrack.displayTitle ??
                plexTrack.language ??
                'Track ${plexTrack.id}',
            language: plexTrack.languageCode,
          ),
        );
      } catch (e) {
        // Silent fallback - log error but continue with other subtitles
        appLogger.w(
          'Failed to add external subtitle track ${plexTrack.id}',
          error: e,
        );
      }
    }

    return externalSubtitles;
  }
}

/// Result of playback initialization
class PlaybackInitializationResult {
  final List<dynamic> availableVersions;
  final String? videoUrl;
  final PlexMediaInfo? mediaInfo;
  final List<SubtitleTrack> externalSubtitles;
  final bool isOffline;

  PlaybackInitializationResult({
    required this.availableVersions,
    this.videoUrl,
    this.mediaInfo,
    this.externalSubtitles = const [],
    this.isOffline = false,
  });
}

/// Exception thrown when playback initialization fails
class PlaybackException implements Exception {
  final String message;

  PlaybackException(this.message);

  @override
  String toString() => message;
}
