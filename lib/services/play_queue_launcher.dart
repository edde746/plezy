import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/play_queue_response.dart';
import '../models/plex_metadata.dart';
import '../models/plex_playlist.dart';
import '../providers/playback_state_provider.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import '../utils/video_player_navigation.dart';
import '../i18n/strings.g.dart';
import 'plex_client.dart';

/// Result type for play queue operations
sealed class PlayQueueResult {
  const PlayQueueResult();
}

class PlayQueueSuccess extends PlayQueueResult {
  const PlayQueueSuccess();
}

class PlayQueueEmpty extends PlayQueueResult {
  const PlayQueueEmpty();
}

class PlayQueueError extends PlayQueueResult {
  final Object error;
  const PlayQueueError(this.error);
}

/// Service to handle play queue creation and navigation.
///
/// Centralizes the common pattern of:
/// 1. Creating a play queue via various methods
/// 2. Setting up PlaybackStateProvider
/// 3. Navigating to the video player
/// 4. Handling errors with appropriate feedback
class PlayQueueLauncher {
  final BuildContext context;
  final PlexClient client;
  final String? serverId;
  final String? serverName;

  PlayQueueLauncher({
    required this.context,
    required this.client,
    this.serverId,
    this.serverName,
  });

  /// Launch playback from a collection or playlist.
  Future<PlayQueueResult> launchFromCollectionOrPlaylist({
    required dynamic item, // PlexMetadata (collection) or PlexPlaylist
    required bool shuffle,
    bool showLoadingIndicator = true,
  }) async {
    final isCollection = item is PlexMetadata;
    final isPlaylist = item is PlexPlaylist;

    if (!isCollection && !isPlaylist) {
      return PlayQueueError(
        Exception('Item must be either a collection or playlist'),
      );
    }

    return _executeWithLoading(
      showLoading: showLoadingIndicator,
      action: t.common.shuffle,
      execute: (dismissLoading) async {
        final String ratingKey = item.ratingKey;
        final String? itemServerId = item.serverId ?? serverId;
        final String? itemServerName = item.serverName ?? serverName;

        PlayQueueResponse? playQueue;

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
            playQueue = fetchedQueue;
          }
        }

        // Close loading dialog before navigating to the player
        await dismissLoading();

        return _launchFromQueue(
          playQueue: playQueue,
          ratingKey: ratingKey,
          serverId: itemServerId,
          serverName: itemServerName,
        );
      },
    );
  }

  /// Launch playback from a playlist starting at a specific item.
  Future<PlayQueueResult> launchFromPlaylistItem({
    required PlexPlaylist playlist,
    required PlexMetadata selectedItem,
    bool showLoadingIndicator = true,
  }) async {
    return _executeWithLoading(
      showLoading: showLoadingIndicator,
      action: t.discover.play,
      execute: (dismissLoading) async {
        final playQueue = await client.createPlayQueue(
          playlistID: int.parse(playlist.ratingKey),
          type: 'video',
          key: selectedItem.key,
        );

        // Close loading dialog before navigating to the player
        await dismissLoading();

        return _launchFromQueue(
          playQueue: playQueue,
          ratingKey: playlist.ratingKey,
          serverId: serverId,
          serverName: serverName,
          selectedItem: playQueue?.selectedItem,
        );
      },
    );
  }

  /// Launch shuffled playback for a show or season.
  Future<PlayQueueResult> launchShuffledShow({
    required PlexMetadata metadata,
    bool showLoadingIndicator = true,
  }) async {
    final mediaType = metadata.mediaType;

    if (mediaType != PlexMediaType.show && mediaType != PlexMediaType.season) {
      return PlayQueueError(
        Exception('Shuffle play only works for shows and seasons'),
      );
    }

    return _executeWithLoading(
      showLoading: showLoadingIndicator,
      action: t.common.shuffle,
      execute: (dismissLoading) async {
        // Determine the rating key for the play queue
        String showRatingKey;
        if (mediaType == PlexMediaType.show) {
          showRatingKey = metadata.ratingKey;
        } else {
          // For seasons, we need the show's rating key
          if (metadata.parentRatingKey == null) {
            throw Exception('Season is missing parentRatingKey');
          }
          showRatingKey = metadata.parentRatingKey!;
        }

        final playQueue = await client.createShowPlayQueue(
          showRatingKey: showRatingKey,
          shuffle: 1,
        );

        // Close loading dialog before navigating to the player
        await dismissLoading();

        return _launchFromQueue(
          playQueue: playQueue,
          ratingKey: showRatingKey,
          serverId: metadata.serverId ?? serverId,
          serverName: metadata.serverName ?? serverName,
          copyServerInfo: true,
        );
      },
    );
  }

  /// Core method to launch playback from a play queue.
  Future<PlayQueueResult> _launchFromQueue({
    required PlayQueueResponse? playQueue,
    required String ratingKey,
    String? serverId,
    String? serverName,
    PlexMetadata? selectedItem,
    bool copyServerInfo = false,
  }) async {
    if (playQueue == null ||
        playQueue.items == null ||
        playQueue.items!.isEmpty) {
      return const PlayQueueEmpty();
    }

    if (!context.mounted) return const PlayQueueError('Context not mounted');

    // Set up playback state
    final playbackState = context.read<PlaybackStateProvider>();
    playbackState.setClient(client);
    await playbackState.setPlaybackFromPlayQueue(
      playQueue,
      ratingKey,
      serverId: serverId,
      serverName: serverName,
    );

    if (!context.mounted) return const PlayQueueError('Context not mounted');

    // Determine which item to navigate to
    var itemToPlay = selectedItem ?? playQueue.items!.first;

    // Copy server info if needed
    if (copyServerInfo && serverId != null) {
      itemToPlay = itemToPlay.copyWith(
        serverId: serverId,
        serverName: serverName,
      );
    }

    // Navigate to video player
    await navigateToVideoPlayer(context, metadata: itemToPlay);

    return const PlayQueueSuccess();
  }

  /// Execute an action with optional loading indicator and error handling.
  Future<PlayQueueResult> _executeWithLoading({
    required bool showLoading,
    required String action,
    required Future<PlayQueueResult> Function(
      Future<void> Function() dismissLoading,
    ) execute,
  }) async {
    BuildContext? loadingDialogContext;
    var loadingVisible = false;

    // Show loading indicator
    if (showLoading && context.mounted) {
      loadingVisible = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          loadingDialogContext = dialogContext;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    Future<void> dismissLoading() async {
      if (!showLoading || !loadingVisible) return;
      final dialogContext = loadingDialogContext;
      if (dialogContext == null) return;

      // Only dismiss if the dialog is still the current route to avoid
      // accidentally popping the player after navigation.
      final route = ModalRoute.of(dialogContext);
      if (route?.isCurrent ?? false) {
        Navigator.of(dialogContext).pop();
      }

      loadingVisible = false;
    }

    try {
      final result = await execute(dismissLoading);

      // Handle empty queue result
      if (result is PlayQueueEmpty && context.mounted) {
        showErrorSnackBar(context, t.messages.failedToCreatePlayQueueNoItems);
      }

      await dismissLoading();
      return result;
    } catch (e) {
      appLogger.e('Failed to $action', error: e);

      if (context.mounted) {
        showErrorSnackBar(
          context,
          t.messages.failedPlayback(action: action, error: e.toString()),
        );
      }

      await dismissLoading();
      return PlayQueueError(e);
    } finally {
      await dismissLoading();
    }
  }
}
