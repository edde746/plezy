import 'plex_client.dart';
import '../models/plex_media_info.dart';
import '../models/plex_metadata.dart';
import '../models/plex_video_playback_data.dart';
import '../models/download_models.dart';
import '../models/transcode_quality_preset.dart';
import '../mpv/mpv.dart';
import '../utils/app_logger.dart';
import '../utils/global_key_utils.dart';
import '../utils/plex_url_helper.dart';
import '../i18n/strings.g.dart';
import '../database/app_database.dart';
import 'download_storage_service.dart';
import 'dart:io';

/// Service responsible for fetching video playback data from the Plex server
class PlaybackInitializationService {
  final PlexClient client;
  final AppDatabase? database;

  PlaybackInitializationService({required this.client, this.database});

  /// Format a video path as a URL (adds file:// prefix for file paths)
  String _formatVideoUrl(String path) {
    return path.contains('://') ? path : 'file://$path';
  }

  /// Check if content is available offline and return local path
  ///
  /// Returns the local file path if the video is downloaded and completed.
  /// Returns null if not available offline or database is not provided.
  Future<String?> getOfflineVideoPath(String serverId, String ratingKey, {int mediaIndex = 0}) async {
    if (database == null) {
      return null;
    }

    try {
      // Query by globalKey — the column is UNIQUE so SQLite's auto-index on it
      // makes this an O(log n) lookup. Filtering by (serverId, ratingKey)
      // would only use the serverId index and then linear-scan matching rows.
      final query = database!.select(database!.downloadedMedia)
        ..where((tbl) => tbl.globalKey.equals(buildGlobalKey(serverId, ratingKey)));

      final downloadedItem = await query.getSingleOrNull();

      // Return null if not found or not completed
      if (downloadedItem == null || downloadedItem.status != DownloadStatus.completed.index) {
        return null;
      }

      // Skip offline file if a different version was requested
      if (downloadedItem.mediaIndex != mediaIndex) {
        appLogger.d(
          '[VersionTrace] Offline video is version ${downloadedItem.mediaIndex}, '
          'but requested version $mediaIndex — skipping offline',
        );
        return null;
      }

      // Return null if no video file path
      if (downloadedItem.videoFilePath == null) {
        return null;
      }

      final storageService = DownloadStorageService.instance;
      final storedPath = downloadedItem.videoFilePath!;

      // Get readable path (handles both SAF URIs and file paths)
      final readablePath = await storageService.getReadablePath(storedPath);

      // For file paths (not SAF), verify the file exists
      if (!storageService.isSafUri(storedPath)) {
        final file = File(readablePath);
        if (!await file.exists()) {
          appLogger.w('Offline video file not found: $readablePath (stored as: $storedPath)');
          return null;
        }
      }

      appLogger.d('Found offline video: $readablePath');
      return readablePath;
    } catch (e) {
      appLogger.w('Error checking offline video path', error: e);
      return null;
    }
  }

  /// Fetch playback data for the given metadata
  ///
  /// Returns a PlaybackInitializationResult with video URL and available versions
  /// If [preferOffline] is true and offline content is available, uses local file
  /// If [playbackData] is provided, skips the network call to fetch it again.
  /// When [qualityPreset] is non-original and online, the video URL is built
  /// against Plex's transcode start endpoint and all subtitle tracks are
  /// sidecar-attached since the transcoded stream carries none.
  Future<PlaybackInitializationResult> getPlaybackData({
    required PlexMetadata metadata,
    required int selectedMediaIndex,
    bool preferOffline = false,
    PlexVideoPlaybackData? playbackData,
    TranscodeQualityPreset qualityPreset = TranscodeQualityPreset.original,
    int? selectedAudioStreamId,
    String? sessionIdentifier,
    String? transcodeSessionId,
  }) async {
    try {
      // Check for offline content first if preferOffline is enabled
      String? offlineVideoPath;
      if (preferOffline && database != null) {
        offlineVideoPath = await getOfflineVideoPath(
          client.serverId,
          metadata.ratingKey,
          mediaIndex: selectedMediaIndex,
        );
      }

      // If offline video is available, use it
      if (offlineVideoPath != null) {
        appLogger.d('Using offline playback for ${metadata.ratingKey}');

        // For offline playback, we still need to fetch media info for subtitles
        // but use the local file path for video
        try {
          final data =
              playbackData ?? await client.getVideoPlaybackData(metadata.ratingKey, mediaIndex: selectedMediaIndex);

          // Build list of external subtitle tracks
          final externalSubtitles = _buildExternalSubtitles(data.mediaInfo);

          // Return result with local file path
          return PlaybackInitializationResult(
            availableVersions: data.availableVersions,
            videoUrl: _formatVideoUrl(offlineVideoPath),
            mediaInfo: data.mediaInfo,
            externalSubtitles: externalSubtitles,
            isOffline: true,
          );
        } catch (e) {
          // If we can't fetch media info (e.g., no network), use offline-only mode
          appLogger.w('Failed to fetch media info for offline video, using offline-only mode', error: e);
          return PlaybackInitializationResult(
            availableVersions: [],
            videoUrl: _formatVideoUrl(offlineVideoPath),
            mediaInfo: null,
            externalSubtitles: const [],
            isOffline: true,
          );
        }
      }

      // Use pre-parsed data or fall back to network streaming
      final data =
          playbackData ?? await client.getVideoPlaybackData(metadata.ratingKey, mediaIndex: selectedMediaIndex);

      if (!data.hasValidVideoUrl) {
        throw PlaybackException(t.messages.fileInfoNotAvailable);
      }

      final wantTranscode = !qualityPreset.isOriginal;
      if (wantTranscode && sessionIdentifier != null && transcodeSessionId != null) {
        final resolvedAudioId = _resolveAudioStreamId(selectedAudioStreamId, data.mediaInfo);
        // Note: no `offsetMs` — seeking is handled by the player via the HLS
        // manifest, matching Plex Web's behavior. Baking `offset=` into the URL
        // makes the server pre-position the transcoder, but the resulting
        // segments and mpv's native HLS positioning fight each other, leaving
        // the player clock at 0 and desyncing sidecar subtitles.
        final result = await client.buildTranscodeStartPath(
          ratingKey: metadata.ratingKey,
          mediaIndex: selectedMediaIndex,
          preset: qualityPreset,
          sessionIdentifier: sessionIdentifier,
          transcodeSessionId: transcodeSessionId,
          audioStreamId: resolvedAudioId,
        );

        if (result.outcome == TranscodeDecisionOutcome.transcodeOk && result.startPath != null) {
          final transcodeUrl = '${client.config.baseUrl}${result.startPath}'.withPlexToken(client.config.token);
          final sidecarSubs = _buildTranscodeSidecarSubtitles(data.mediaInfo);
          return PlaybackInitializationResult(
            availableVersions: data.availableVersions,
            videoUrl: transcodeUrl,
            mediaInfo: data.mediaInfo,
            externalSubtitles: sidecarSubs,
            isOffline: false,
            isTranscoding: true,
            activeAudioStreamId: resolvedAudioId,
          );
        }

        // Decision failed or said direct-play only — fall through to direct-play path
        // and surface the fallback reason so the UI can notify the user.
        final fallbackReason = result.outcome == TranscodeDecisionOutcome.directPlayOnly
            ? TranscodeFallbackReason.directPlayOnly
            : TranscodeFallbackReason.decisionFailed;
        appLogger.w('Transcode decision fell back to direct play: ${fallbackReason.name}');
        return PlaybackInitializationResult(
          availableVersions: data.availableVersions,
          videoUrl: data.videoUrl,
          mediaInfo: data.mediaInfo,
          externalSubtitles: _buildExternalSubtitles(data.mediaInfo),
          isOffline: false,
          isTranscoding: false,
          fallbackReason: fallbackReason,
        );
      }

      // Build list of external subtitle tracks
      final externalSubtitles = _buildExternalSubtitles(data.mediaInfo);

      // Return result with available versions and video URL
      return PlaybackInitializationResult(
        availableVersions: data.availableVersions,
        videoUrl: data.videoUrl,
        mediaInfo: data.mediaInfo,
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

  /// Pick the audio stream ID to send to the transcoder. Preference order:
  /// explicit [explicit] → audio track with `selected == true` → first → null.
  int? _resolveAudioStreamId(int? explicit, PlexMediaInfo? info) {
    if (explicit != null) return explicit;
    if (info == null) return null;
    final tracks = info.audioTracks;
    if (tracks.isEmpty) return null;
    for (final track in tracks) {
      if (track.selected) return track.id;
    }
    return tracks.first.id;
  }

  /// Build sidecar SubtitleTracks for ALL source subtitle streams (internal +
  /// external) so the player can hot-swap between them when the main stream
  /// is transcoded and has no embedded subs.
  List<SubtitleTrack> _buildTranscodeSidecarSubtitles(PlexMediaInfo? mediaInfo) {
    if (mediaInfo == null) return const [];
    final token = client.config.token;
    if (token == null) {
      appLogger.w('No auth token available for transcode sidecar subtitles');
      return const [];
    }

    final tracks = <SubtitleTrack>[];
    for (final sub in mediaInfo.subtitleTracks) {
      try {
        final url = sub.getTranscodeSidecarUrl(client.config.baseUrl, token);
        tracks.add(
          SubtitleTrack.uri(
            url,
            title: sub.displayTitle ?? sub.language ?? 'Track ${sub.id}',
            language: sub.languageCode,
          ),
        );
      } catch (e) {
        appLogger.w('Failed to build sidecar subtitle for stream ${sub.id}', error: e);
      }
    }
    return tracks;
  }

  /// Build list of external subtitle tracks from media info
  List<SubtitleTrack> _buildExternalSubtitles(PlexMediaInfo? mediaInfo) {
    final externalSubtitles = <SubtitleTrack>[];

    if (mediaInfo == null) {
      return externalSubtitles;
    }

    final externalTracks = mediaInfo.subtitleTracks.where((PlexSubtitleTrack track) => track.isExternal).toList();

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
            title: plexTrack.displayTitle ?? plexTrack.language ?? 'Track ${plexTrack.id}',
            language: plexTrack.languageCode,
          ),
        );
      } catch (e) {
        // Silent fallback - log error but continue with other subtitles
        appLogger.w('Failed to add external subtitle track ${plexTrack.id}', error: e);
      }
    }

    return externalSubtitles;
  }
}

/// Reason the transcode branch fell back to direct play.
enum TranscodeFallbackReason {
  /// Plex decision said only direct-play is available.
  directPlayOnly,

  /// The decision endpoint errored (HTTP error, code >= 2000, parse failure).
  decisionFailed,
}

/// Result of playback initialization
class PlaybackInitializationResult {
  final List<dynamic> availableVersions;
  final String? videoUrl;
  final PlexMediaInfo? mediaInfo;
  final List<SubtitleTrack> externalSubtitles;
  final bool isOffline;

  /// `true` when [videoUrl] is a Plex transcode start URL.
  final bool isTranscoding;

  /// Non-null when a non-original preset was requested but fallback kicked in.
  final TranscodeFallbackReason? fallbackReason;

  /// The Plex audio stream ID actually passed to the transcoder (`null` when
  /// not transcoding or when no audio stream was selectable).
  final int? activeAudioStreamId;

  PlaybackInitializationResult({
    required this.availableVersions,
    this.videoUrl,
    this.mediaInfo,
    this.externalSubtitles = const [],
    this.isOffline = false,
    this.isTranscoding = false,
    this.fallbackReason,
    this.activeAudioStreamId,
  });
}

/// Exception thrown when playback initialization fails
class PlaybackException implements Exception {
  final String message;

  PlaybackException(this.message);

  @override
  String toString() => message;
}
