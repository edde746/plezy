import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import '../client/plex_client.dart';
import '../models/plex_media_info.dart';
import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';
import '../i18n/strings.g.dart';

/// Service responsible for initializing video playback
///
/// Handles the complex process of:
/// 1. Fetching video playback data from the Plex server
/// 2. Building external subtitle tracks
/// 3. Opening media in the player
/// 4. Adding external subtitles to the player
/// 5. Seeking to resume position
/// 6. Starting playback
class PlaybackInitializationService {
  final Player player;
  final PlexClient client;
  final BuildContext context;

  PlaybackInitializationService({
    required this.player,
    required this.client,
    required this.context,
  });

  /// Start playback for the given metadata
  ///
  /// Returns a PlaybackInitializationResult with available versions and other data
  Future<PlaybackInitializationResult> startPlayback({
    required PlexMetadata metadata,
    required int selectedMediaIndex,
  }) async {
    try {
      // Get consolidated playback data (URL, media info, and versions) in a single API call
      final playbackData = await client.getVideoPlaybackData(
        metadata.ratingKey,
        mediaIndex: selectedMediaIndex,
      );

      if (!playbackData.hasValidVideoUrl) {
        throw PlaybackException(t.messages.fileInfoNotAvailable);
      }

      final videoUrl = playbackData.videoUrl!;
      final mediaInfo = playbackData.mediaInfo;

      // Build list of external subtitle tracks for media_kit
      final externalSubtitles = _buildExternalSubtitles(mediaInfo);

      // Open video (without external subtitles in Media constructor)
      await player.open(Media(videoUrl), play: false);

      // Wait for media to be ready (duration > 0)
      await _waitForMediaReady();

      // Add external subtitle tracks without auto-selecting them
      if (externalSubtitles.isNotEmpty) {
        await _addExternalSubtitles(externalSubtitles);
      }

      // Set up playback position if resuming
      if (metadata.viewOffset != null && metadata.viewOffset! > 0) {
        final resumePosition = Duration(milliseconds: metadata.viewOffset!);
        await player.seek(resumePosition);
      }

      // Start playback after seeking
      await player.play();

      // Return result with available versions for UI updates
      return PlaybackInitializationResult(
        availableVersions: playbackData.availableVersions,
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

  /// Wait for media to be ready (duration > 0)
  Future<void> _waitForMediaReady() async {
    int attempts = 0;
    while (player.state.duration.inMilliseconds == 0 && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  /// Add external subtitle tracks to the player without auto-selecting them
  Future<void> _addExternalSubtitles(
    List<SubtitleTrack> externalSubtitles,
  ) async {
    appLogger.d(
      'Adding ${externalSubtitles.length} external subtitle(s) to player',
    );

    final nativePlayer = player.platform as dynamic;

    for (final subtitleTrack in externalSubtitles) {
      try {
        // Use mpv's sub-add with 'auto' flag to avoid auto-selection
        await nativePlayer.command([
          'sub-add',
          subtitleTrack.id,
          'auto',
          subtitleTrack.title ?? 'external',
          subtitleTrack.language ?? 'auto',
        ]);
      } catch (e) {
        appLogger.w(
          'Failed to add external subtitle: ${subtitleTrack.title}',
          error: e,
        );
      }
    }
  }
}

/// Result of playback initialization
class PlaybackInitializationResult {
  final List<dynamic> availableVersions;

  PlaybackInitializationResult({required this.availableVersions});
}

/// Exception thrown when playback initialization fails
class PlaybackException implements Exception {
  final String message;

  PlaybackException(this.message);

  @override
  String toString() => message;
}
