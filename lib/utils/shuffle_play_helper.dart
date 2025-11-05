import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/plex_metadata.dart';
import '../providers/playback_state_provider.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';

/// Handle shuffle play action for shows and seasons
///
/// Fetches all unwatched episodes, shuffles them, and starts playback
/// from the first shuffled episode. The shuffle queue is stored in the
/// PlaybackStateProvider for continuous shuffle playback.
Future<void> handleShufflePlay(
  BuildContext context,
  PlexMetadata metadata,
) async {
  final client = context.client;
  if (client == null) return;

  final playbackState = context.read<PlaybackStateProvider>();
  final itemType = metadata.type.toLowerCase();

  try {
    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator()),
      );
    }

    // Get unwatched episodes based on type
    List<PlexMetadata> episodes;
    if (itemType == 'show') {
      episodes = await client.getAllUnwatchedEpisodes(
        metadata.ratingKey,
      );
    } else {
      // season
      episodes = await client.getUnwatchedEpisodesInSeason(
        metadata.ratingKey,
      );
    }

    // Close loading indicator
    if (context.mounted) {
      Navigator.pop(context);
    }

    if (episodes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No unwatched episodes found')),
        );
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
        SnackBar(content: Text('Error starting shuffle play: $e')),
      );
    }
  }
}
