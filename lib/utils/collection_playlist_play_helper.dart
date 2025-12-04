import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/plex_client.dart';
import '../models/plex_metadata.dart';
import '../models/plex_playlist.dart';
import '../models/play_queue_response.dart';
import '../providers/playback_state_provider.dart';
import '../utils/app_logger.dart';
import '../utils/video_player_navigation.dart';
import '../i18n/strings.g.dart';

/// Helper function to play a collection or playlist
Future<void> playCollectionOrPlaylist({
  required BuildContext context,
  required PlexClient client,
  required dynamic item, // PlexMetadata (collection) or PlexPlaylist
  required bool shuffle,
}) async {
  try {
    final isCollection = item is PlexMetadata;
    final isPlaylist = item is PlexPlaylist;

    if (!isCollection && !isPlaylist) {
      throw Exception('Item must be either a collection or playlist');
    }

    String ratingKey = item.ratingKey;
    String? serverId = item.serverId;
    String? serverName = item.serverName;

    final PlayQueueResponse? playQueue;
    if (isCollection) {
      // Get machine identifier (fetch if not cached in config)
      final machineId =
          client.config.machineIdentifier ??
          await client.getMachineIdentifier();

      if (machineId == null) {
        throw Exception('Could not get server machine identifier');
      }

      final collectionUri =
          'server://$machineId/com.plexapp.plugins.library/library/collections/${item.ratingKey}';
      playQueue = await client.createPlayQueue(
        uri: collectionUri,
        type: 'video',
        shuffle: shuffle ? 1 : 0,
      );
    } else {
      // For playlists, use playlistID parameter
      playQueue = await client.createPlayQueue(
        playlistID: int.parse(item.ratingKey),
        type: 'video',
        shuffle: shuffle ? 1 : 0,
      );
    }

    // If the queue is empty, try fetching it again with getPlayQueue
    if (playQueue != null &&
        (playQueue.items == null || playQueue.items!.isEmpty)) {
      final fetchedQueue = await client.getPlayQueue(playQueue.playQueueID);

      if (fetchedQueue != null &&
          fetchedQueue.items != null &&
          fetchedQueue.items!.isNotEmpty) {
        if (!context.mounted) return;

        // Items are automatically tagged with server info by PlexClient
        // Set play queue in provider
        final playbackState = context.read<PlaybackStateProvider>();
        playbackState.setClient(client);
        await playbackState.setPlaybackFromPlayQueue(
          fetchedQueue,
          ratingKey,
          serverId: serverId,
          serverName: serverName,
        );

        if (!context.mounted) return;

        // Navigate to first item
        await navigateToVideoPlayer(
          context,
          metadata: fetchedQueue.items!.first,
        );
        return;
      }
    }

    if (playQueue == null ||
        playQueue.items == null ||
        playQueue.items!.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.messages.failedToCreatePlayQueueNoItems)),
        );
      }
      return;
    }

    if (!context.mounted) return;

    // Items are automatically tagged with server info by PlexClient
    // Set play queue in provider
    final playbackState = context.read<PlaybackStateProvider>();
    playbackState.setClient(client);
    await playbackState.setPlaybackFromPlayQueue(
      playQueue,
      ratingKey,
      serverId: serverId,
      serverName: serverName,
    );

    if (!context.mounted) return;

    // Navigate to first item
    await navigateToVideoPlayer(context, metadata: playQueue.items!.first);
  } catch (e) {
    appLogger.e('Failed to ${shuffle ? "shuffle play" : "play"}', error: e);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.messages.failedPlayback(
              action: shuffle ? t.common.shuffle : t.discover.play,
              error: e.toString(),
            ),
          ),
        ),
      );
    }
  }
}
