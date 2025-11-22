import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../client/plex_client.dart';
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
      // Validate that machine identifier is available
      if (client.config.machineIdentifier == null) {
        throw Exception('Machine identifier is required to play collections');
      }

      final collectionUri =
          'server://${client.config.machineIdentifier}/com.plexapp.plugins.library/library/collections/${item.ratingKey}';
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

        // Preserve serverId for all items in the queue
        final itemsWithServerId = fetchedQueue.items!.map((queueItem) {
          return queueItem.copyWith(serverId: serverId, serverName: serverName);
        }).toList();

        final queueWithServerId = PlayQueueResponse(
          playQueueID: fetchedQueue.playQueueID,
          playQueueSelectedItemID: fetchedQueue.playQueueSelectedItemID,
          playQueueSelectedItemOffset: fetchedQueue.playQueueSelectedItemOffset,
          playQueueSelectedMetadataItemID:
              fetchedQueue.playQueueSelectedMetadataItemID,
          playQueueShuffled: fetchedQueue.playQueueShuffled,
          playQueueSourceURI: fetchedQueue.playQueueSourceURI,
          playQueueTotalCount: fetchedQueue.playQueueTotalCount,
          playQueueVersion: fetchedQueue.playQueueVersion,
          size: fetchedQueue.size,
          items: itemsWithServerId,
        );

        // Set play queue in provider
        final playbackState = context.read<PlaybackStateProvider>();
        playbackState.setClient(client);
        await playbackState.setPlaybackFromPlayQueue(
          queueWithServerId,
          ratingKey,
          serverId: serverId,
          serverName: serverName,
        );

        if (!context.mounted) return;

        // Navigate to first item
        await navigateToVideoPlayer(context, metadata: itemsWithServerId.first);
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

    // Preserve serverId for all items in the queue
    final itemsWithServerId = playQueue.items!.map((queueItem) {
      return queueItem.copyWith(serverId: serverId, serverName: serverName);
    }).toList();

    final queueWithServerId = PlayQueueResponse(
      playQueueID: playQueue.playQueueID,
      playQueueSelectedItemID: playQueue.playQueueSelectedItemID,
      playQueueSelectedItemOffset: playQueue.playQueueSelectedItemOffset,
      playQueueSelectedMetadataItemID:
          playQueue.playQueueSelectedMetadataItemID,
      playQueueShuffled: playQueue.playQueueShuffled,
      playQueueSourceURI: playQueue.playQueueSourceURI,
      playQueueTotalCount: playQueue.playQueueTotalCount,
      playQueueVersion: playQueue.playQueueVersion,
      size: playQueue.size,
      items: itemsWithServerId,
    );

    // Set play queue in provider
    final playbackState = context.read<PlaybackStateProvider>();
    playbackState.setClient(client);
    await playbackState.setPlaybackFromPlayQueue(
      queueWithServerId,
      ratingKey,
      serverId: serverId,
      serverName: serverName,
    );

    if (!context.mounted) return;

    // Navigate to first item
    await navigateToVideoPlayer(context, metadata: itemsWithServerId.first);
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
