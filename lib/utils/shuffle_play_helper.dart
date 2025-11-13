import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plex_metadata.dart';
import '../providers/playback_state_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../i18n/strings.g.dart';

/// Handle shuffle play action for shows and seasons
///
/// Fetches episodes based on user settings (unwatched only or including watched),
/// shuffles them, and starts playback from the first shuffled episode.
/// The shuffle queue is stored in the PlaybackStateProvider for continuous shuffle playback.
Future<void> handleShufflePlay(
  BuildContext context,
  PlexMetadata metadata,
) async {
  final client = context.client;
  if (client == null) return;

  final playbackState = context.read<PlaybackStateProvider>();
  final settingsProvider = context.read<SettingsProvider>();
  final itemType = metadata.type.toLowerCase();

  // Get shuffle setting
  final unwatchedOnly = settingsProvider.shuffleUnwatchedOnly;

  try {
    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    // Get episodes based on type and settings
    List<PlexMetadata> episodes;
    if (itemType == 'show') {
      if (unwatchedOnly) {
        // Get only unwatched episodes
        episodes = await client.getAllUnwatchedEpisodes(metadata.ratingKey);
      } else {
        // Get all episodes from all seasons
        final allEpisodes = <PlexMetadata>[];
        final seasons = await client.getChildren(metadata.ratingKey);

        for (final season in seasons) {
          if (season.type == 'season') {
            final seasonEpisodes = await client.getChildren(season.ratingKey);
            final episodesOnly = seasonEpisodes
                .where((ep) => ep.type == 'episode')
                .toList();
            allEpisodes.addAll(episodesOnly);
          }
        }
        episodes = allEpisodes;
      }
    } else {
      // season
      if (unwatchedOnly) {
        // Get only unwatched episodes
        episodes = await client.getUnwatchedEpisodesInSeason(
          metadata.ratingKey,
        );
      } else {
        // Get all episodes in season
        final seasonEpisodes = await client.getChildren(metadata.ratingKey);
        episodes = seasonEpisodes.where((ep) => ep.type == 'episode').toList();
      }
    }

    // Close loading indicator
    if (context.mounted) {
      Navigator.pop(context);
    }

    if (episodes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.messages.noEpisodesFound)));
      }
      return;
    }

    // Shuffle the episodes
    episodes.shuffle();

    // Store shuffle queue in provider
    playbackState.setShuffleQueue(episodes, metadata.ratingKey);

    // Navigate to first episode
    if (context.mounted) {
      await navigateToVideoPlayer(context, metadata: episodes.first);
    }
  } catch (e) {
    // Close loading indicator if it's still open
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.messages.errorLoading(error: e.toString()))),
      );
    }
  }
}
