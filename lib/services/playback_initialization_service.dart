import 'package:flutter/material.dart';

import '../mpv/mpv.dart';
import '../client/plex_client.dart';
import '../models/plex_media_info.dart';
import '../models/plex_metadata.dart';
import '../models/plex_user_profile.dart';
import '../utils/app_logger.dart';
import '../i18n/strings.g.dart';
import 'track_selection_service.dart';

/// Service responsible for initializing video playback
///
/// Handles the complex process of:
/// 1. Fetching video playback data from the Plex server
/// 2. Building external subtitle tracks
/// 3. Opening media in the player
/// 4. Adding external subtitles to the player
/// 5. Selecting and applying audio/subtitle tracks
/// 6. Seeking to resume position
/// 7. Starting playback
class PlaybackInitializationService {
  final MpvPlayer player;
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
  /// Set [useNativePlayer] to true on macOS to skip Flutter player operations
  Future<PlaybackInitializationResult> startPlayback({
    required PlexMetadata metadata,
    required int selectedMediaIndex,
    required PlexUserProfile? profileSettings,
    MpvAudioTrack? preferredAudioTrack,
    MpvSubtitleTrack? preferredSubtitleTrack,
    double? preferredPlaybackRate,
    bool useNativePlayer = false,
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

      // Skip Flutter player operations when using native player on macOS
      if (!useNativePlayer) {
        // Build list of external subtitle tracks for mpv
        final externalSubtitles = _buildExternalSubtitles(mediaInfo);

        // Open video (without external subtitles in Media constructor)
        await player.open(MpvMedia(videoUrl), play: false);

        // Wait for media to be ready (duration > 0)
        await _waitForMediaReady();

        // Add external subtitle tracks without auto-selecting them
        if (externalSubtitles.isNotEmpty) {
          await _addExternalSubtitles(externalSubtitles);
        }

        // Select and apply tracks BEFORE seeking to resume position
        // This prevents track changes from resetting the playback position on Android
        final trackSelectionService = TrackSelectionService(
          player: player,
          profileSettings: profileSettings,
          metadata: metadata,
        );

        await trackSelectionService.selectAndApplyTracks(
          preferredAudioTrack: preferredAudioTrack,
          preferredSubtitleTrack: preferredSubtitleTrack,
          preferredPlaybackRate: preferredPlaybackRate,
        );

        // Set up playback position if resuming (AFTER track selection)
        if (metadata.viewOffset != null && metadata.viewOffset! > 0) {
          appLogger.d('Resuming playback at ${metadata.viewOffset} ms');
          final resumePosition = Duration(milliseconds: metadata.viewOffset!);
          await player.seek(resumePosition);
        }

        // Start playback after seeking
        await player.play();
      }

      // Return result with available versions and video URL for UI updates
      return PlaybackInitializationResult(
        availableVersions: playbackData.availableVersions,
        videoUrl: videoUrl,
      );
    } catch (e) {
      if (e is PlaybackException) {
        rethrow;
      }
      throw PlaybackException(t.messages.errorLoading(error: e.toString()));
    }
  }

  /// Build list of external subtitle tracks from media info
  List<MpvSubtitleTrack> _buildExternalSubtitles(PlexMediaInfo? mediaInfo) {
    final externalSubtitles = <MpvSubtitleTrack>[];

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
          MpvSubtitleTrack.uri(
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
    List<MpvSubtitleTrack> externalSubtitles,
  ) async {
    appLogger.d(
      'Adding ${externalSubtitles.length} external subtitle(s) to player',
    );

    for (final subtitleTrack in externalSubtitles) {
      try {
        // Use mpv's sub-add with 'auto' flag to avoid auto-selection
        await player.command([
          'sub-add',
          subtitleTrack.uri ?? subtitleTrack.id,
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
  final String? videoUrl;

  PlaybackInitializationResult({
    required this.availableVersions,
    this.videoUrl,
  });
}

/// Exception thrown when playback initialization fails
class PlaybackException implements Exception {
  final String message;

  PlaybackException(this.message);

  @override
  String toString() => message;
}
