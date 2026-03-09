import 'package:flutter/material.dart';
import '../mpv/mpv.dart';

import '../services/plex_client.dart';
import '../models/plex_media_info.dart';
import '../models/plex_metadata.dart';
import '../utils/app_logger.dart';
import '../i18n/strings.g.dart';

/// Service responsible for initializing audio playback
///
/// Handles the process of:
/// 1. Fetching audio playback data from the Plex server
/// 2. Opening media in the player
/// 3. Seeking to resume position
/// 4. Starting playback
class AudioPlaybackInitializationService {
  final Player player;
  final PlexClient client;
  final BuildContext context;

  AudioPlaybackInitializationService({
    required this.player,
    required this.client,
    required this.context,
  });

  /// Start playback for the given metadata
  ///
  /// Returns the audio URL and media info
  Future<AudioPlaybackResult> startPlayback({
    required PlexMetadata metadata,
    int selectedMediaIndex = 0,
  }) async {
    try {
      // Get consolidated playback data (URL, media info, and versions) in a single API call
      // We can reuse getVideoPlaybackData as it works for audio tracks too
      final playbackData = await client.getVideoPlaybackData(
        metadata.ratingKey,
        mediaIndex: selectedMediaIndex,
      );

      if (!playbackData.hasValidVideoUrl) {
        throw PlaybackException(t.messages.fileInfoNotAvailable);
      }

      final audioUrl = playbackData.videoUrl!; // URL works for both video and audio
      final mediaInfo = playbackData.mediaInfo;

      // Open audio (Media constructor works for audio files too)
      await player.open(Media(audioUrl), play: false);

      // Wait for media to be ready (duration > 0)
      await _waitForMediaReady();

      // Set up playback position if resuming
      if (metadata.viewOffset != null && metadata.viewOffset! > 0) {
        appLogger.d('Resuming playback at ${metadata.viewOffset} ms');
        final resumePosition = Duration(milliseconds: metadata.viewOffset!);
        await player.seek(resumePosition);
      }

      // Start playback after seeking
      await player.play();

      // Return result with available versions for UI updates
      return AudioPlaybackResult(
        audioUrl: audioUrl,
        mediaInfo: mediaInfo,
        availableVersions: playbackData.availableVersions,
      );
    } catch (e) {
      appLogger.e('Failed to start audio playback', error: e);
      rethrow;
    }
  }

  /// Wait for media to be ready (duration > 0)
  Future<void> _waitForMediaReady() async {
    int attempts = 0;
    while (player.state.duration == Duration.zero && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    if (player.state.duration == Duration.zero) {
      throw PlaybackException('Media failed to load');
    }
  }
}

/// Result of audio playback initialization
class AudioPlaybackResult {
  final String audioUrl;
  final PlexMediaInfo? mediaInfo;
  final List<dynamic> availableVersions;

  AudioPlaybackResult({
    required this.audioUrl,
    required this.mediaInfo,
    required this.availableVersions,
  });
}

/// Exception thrown during playback initialization
class PlaybackException implements Exception {
  final String message;
  PlaybackException(this.message);
  @override
  String toString() => message;
}

