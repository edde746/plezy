import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../mpv/mpv.dart';
import 'plex_client.dart';
import '../models/plex_metadata.dart';
import '../providers/playback_state_provider.dart';
import '../utils/app_logger.dart';
import '../utils/video_player_navigation.dart';

/// Result of loading adjacent episodes
class AdjacentEpisodes {
  final PlexMetadata? next;
  final PlexMetadata? previous;

  AdjacentEpisodes({this.next, this.previous});

  bool get hasNext => next != null;
  bool get hasPrevious => previous != null;
}

/// Manages episode navigation for TV show playback.
///
/// Handles:
/// - Loading next/previous episodes from play queues
/// - Navigating between episodes while preserving track selections
/// - Supporting both sequential and shuffle playback modes
///
/// All episode navigation uses Plex play queues for consistent behavior.
class EpisodeNavigationService {
  /// Load the next and previous episodes for the current episode
  ///
  /// Returns null for episodes if:
  /// - Not applicable (e.g., movie content)
  /// - Next episode doesn't exist (end of season/series)
  /// - Previous episode doesn't exist (first episode)
  Future<AdjacentEpisodes> loadAdjacentEpisodes({
    required BuildContext context,
    required PlexClient client,
    required PlexMetadata metadata,
  }) async {
    try {
      final playbackState = context.read<PlaybackStateProvider>();

      // All episode navigation now uses play queues (sequential, shuffle, playlists)
      // If no queue is active, navigation is not available
      if (!playbackState.isQueueActive) {
        return AdjacentEpisodes();
      }

      // Use the play queue for next/previous navigation
      final next = await playbackState.getNextEpisode(metadata.ratingKey, loopQueue: false);
      final previous = await playbackState.getPreviousEpisode(metadata.ratingKey);

      final mode = playbackState.isShuffleActive ? 'Shuffle' : 'Sequential';
      appLogger.d('$mode mode - Next: ${next?.title}, Previous: ${previous?.title}');

      return AdjacentEpisodes(next: next, previous: previous);
    } catch (e) {
      // Non-critical: Failed to load next/previous episode metadata
      appLogger.d('Could not load adjacent episodes', error: e);
      return AdjacentEpisodes();
    }
  }

  /// Navigate to the next or previous episode
  ///
  /// Preserves the current audio track, subtitle track, and playback rate
  /// selections when transitioning between episodes.
  Future<void> navigateToEpisode({
    required BuildContext context,
    required PlexMetadata episode,
    required Player? player,
    bool usePushReplacement = true,
  }) async {
    if (!context.mounted) return;

    // Capture current player state before navigation
    AudioTrack? currentAudioTrack;
    SubtitleTrack? currentSubtitleTrack;
    double? currentPlaybackRate;

    if (player != null) {
      currentAudioTrack = player.state.track.audio;
      currentSubtitleTrack = player.state.track.subtitle;
      currentPlaybackRate = player.state.rate;

      appLogger.d(
        'Navigating to episode with preserved settings - Audio: ${currentAudioTrack?.id}, Subtitle: ${currentSubtitleTrack?.id}, Rate: ${currentPlaybackRate}x',
      );
    }

    // Navigate to the new episode
    if (context.mounted) {
      navigateToVideoPlayer(
        context,
        metadata: episode,
        preferredAudioTrack: currentAudioTrack,
        preferredSubtitleTrack: currentSubtitleTrack,
        preferredPlaybackRate: currentPlaybackRate,
        usePushReplacement: usePushReplacement,
      );
    }
  }
}
