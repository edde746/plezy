import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_playlist.dart';
import '../models/plex/play_queue_response.dart';
import '../providers/multi_server_provider.dart';
import '../providers/playback_state_provider.dart';
import '../utils/video_player_navigation.dart';
import '../i18n/strings.g.dart';
import 'media_list_playback_launcher.dart';
import 'plex_client.dart';

// Re-export the result types so existing imports of this file keep working.
export 'media_list_playback_launcher.dart' show PlayQueueResult, PlayQueueSuccess, PlayQueueEmpty, PlayQueueError;

/// Plex-specific play queue launcher.
///
/// Centralizes the common pattern of:
/// 1. Creating a play queue via Plex's server-side `/playQueues` resource
/// 2. Setting up [PlaybackStateProvider]
/// 3. Navigating to the video player
/// 4. Handling errors with appropriate feedback
///
/// Implements [MediaListPlaybackLauncher.launchFromCollectionOrPlaylist] for
/// the backend-neutral entry point. Plex-only flows
/// ([launchFromPlaylistItem], [launchShuffledShow], [launchFromFolder]) live
/// directly on this class because they have no Jellyfin equivalent.
class PlexPlayQueueLauncher extends MediaListPlaybackLauncher {
  final BuildContext context;
  final PlexClient client;
  final String? serverId;
  final String? serverName;

  PlexPlayQueueLauncher({required this.context, required this.client, this.serverId, this.serverName});

  /// Resolve the right [PlexClient] for [item]'s server and build a launcher.
  /// Falls back to the first available Plex client when [item] doesn't carry
  /// a `serverId`.
  factory PlexPlayQueueLauncher.forContext(BuildContext context, Object item) {
    final String? itemServerId;
    final String? itemServerName;
    if (item is MediaItem) {
      itemServerId = item.serverId;
      itemServerName = item.serverName;
    } else if (item is MediaPlaylist) {
      itemServerId = item.serverId;
      itemServerName = item.serverName;
    } else {
      itemServerId = null;
      itemServerName = null;
    }

    final provider = Provider.of<MultiServerProvider>(context, listen: false);
    PlexClient? plexClient;
    if (itemServerId != null) {
      // Plex-only: server-side `/playQueues` resource has no Jellyfin equivalent.
      plexClient = provider.getPlexClientForServer(itemServerId);
    }
    if (plexClient == null) {
      // Fall back to the first online Plex client.
      for (final id in provider.onlineServerIds) {
        final c = provider.getPlexClientForServer(id);
        if (c != null) {
          plexClient = c;
          break;
        }
      }
    }
    if (plexClient == null) {
      throw Exception(t.errors.noClientAvailable);
    }
    return PlexPlayQueueLauncher(
      context: context,
      client: plexClient,
      serverId: itemServerId,
      serverName: itemServerName,
    );
  }

  /// Launch playback from a collection or playlist.
  ///
  /// Accepts a [MediaItem] (collection) or [MediaPlaylist]. Typed as [Object]
  /// because Dart has no nominal union type.
  @override
  Future<PlayQueueResult> launchFromCollectionOrPlaylist({
    required Object item,
    required bool shuffle,
    MediaItem? startItem,
    bool showLoadingIndicator = true,
  }) async {
    final facts = MediaListPlaybackLauncher.classifyItem(item);
    if (facts == null) {
      return PlayQueueError(Exception('Item must be either a collection or playlist'));
    }
    final ratingKey = facts.id;
    final itemServerId = facts.serverId ?? serverId;
    final itemServerName = facts.serverName ?? serverName;

    return executeWithLoading(
      context: context,
      showLoading: showLoadingIndicator,
      actionLabel: t.common.shuffle,
      execute: (dismissLoading) async {
        PlayQueueResponse? playQueue;
        // Plex's `key` param positions the queue's selected item — passed
        // through when the caller wants playback to start at a specific
        // entry. Ignored on shuffle (the server picks a random head).
        final selectedKey = (!shuffle && startItem != null) ? '/library/metadata/${startItem.id}' : null;

        if (facts.isCollection) {
          // Get machine identifier (fetch if not cached in config)
          final machineId = client.config.machineIdentifier ?? await client.getMachineIdentifier();

          if (machineId == null) {
            throw Exception('Could not get server machine identifier');
          }

          final collectionUri = 'server://$machineId/com.plexapp.plugins.library/library/collections/$ratingKey';
          playQueue = await client.createPlayQueue(
            uri: collectionUri,
            type: 'video',
            shuffle: shuffle ? 1 : 0,
            key: selectedKey,
          );
        } else {
          // For playlists, use playlistID parameter
          playQueue = await client.createPlayQueue(
            playlistID: int.parse(ratingKey),
            type: 'video',
            shuffle: shuffle ? 1 : 0,
            key: selectedKey,
          );
        }

        // If the queue is empty, try fetching it again with getPlayQueue
        if (playQueue != null && (playQueue.items == null || playQueue.items!.isEmpty)) {
          final fetchedQueue = await client.getPlayQueue(playQueue.playQueueID);
          if (fetchedQueue != null && fetchedQueue.items != null && fetchedQueue.items!.isNotEmpty) {
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
          selectedItem: selectedKey != null ? _resolveSelectedMediaItem(playQueue) : null,
        );
      },
    );
  }

  /// Launch playback from a playlist starting at a specific item.
  Future<PlayQueueResult> launchFromPlaylistItem({
    required MediaPlaylist playlist,
    required MediaItem selectedItem,
    bool showLoadingIndicator = true,
  }) async {
    return executeWithLoading(
      context: context,
      showLoading: showLoadingIndicator,
      actionLabel: t.common.play,
      execute: (dismissLoading) async {
        // Plex's createPlayQueue takes the metadata `key` (`/library/metadata/{id}`),
        // not the bare ratingKey. Construct it from the MediaItem id.
        final selectedKey = '/library/metadata/${selectedItem.id}';
        final playQueue = await client.createPlayQueue(
          playlistID: int.parse(playlist.id),
          type: 'video',
          key: selectedKey,
        );

        // Close loading dialog before navigating to the player
        await dismissLoading();

        return _launchFromQueue(
          playQueue: playQueue,
          ratingKey: playlist.id,
          serverId: serverId,
          serverName: serverName,
          selectedItem: _resolveSelectedMediaItem(playQueue),
        );
      },
    );
  }

  /// Launch shuffled playback for a show or season.
  @override
  Future<PlayQueueResult> launchShuffledShow({required MediaItem metadata, bool showLoadingIndicator = true}) async {
    final kind = metadata.kind;

    if (kind != MediaKind.show && kind != MediaKind.season) {
      return PlayQueueError(Exception('Shuffle play only works for shows and seasons'));
    }

    return executeWithLoading(
      context: context,
      showLoading: showLoadingIndicator,
      actionLabel: t.common.shuffle,
      execute: (dismissLoading) async {
        // Determine the rating key for the play queue
        String showRatingKey;
        if (kind == MediaKind.show) {
          showRatingKey = metadata.id;
        } else {
          // For seasons, we need the show's rating key
          if (metadata.parentId == null) {
            throw Exception('Season is missing parentRatingKey');
          }
          showRatingKey = metadata.parentId!;
        }

        final playQueue = await client.createShowPlayQueue(showRatingKey: showRatingKey, shuffle: 1);

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

  /// Launch playback from a folder's contents.
  Future<PlayQueueResult> launchFromFolder({
    required String folderKey,
    required bool shuffle,
    bool showLoadingIndicator = true,
  }) async {
    return executeWithLoading(
      context: context,
      showLoading: showLoadingIndicator,
      actionLabel: shuffle ? t.common.shuffle : t.common.play,
      execute: (dismissLoading) async {
        final folderUri = await client.buildFolderUri(folderKey);

        var playQueue = await client.createPlayQueue(uri: folderUri, type: 'video', shuffle: shuffle ? 1 : 0);

        if (playQueue != null && (playQueue.items == null || playQueue.items!.isEmpty)) {
          final fetchedQueue = await client.getPlayQueue(playQueue.playQueueID);
          if (fetchedQueue != null && fetchedQueue.items != null && fetchedQueue.items!.isNotEmpty) {
            playQueue = fetchedQueue;
          }
        }

        await dismissLoading();

        return _launchFromQueue(playQueue: playQueue, ratingKey: folderKey, serverId: serverId, serverName: serverName);
      },
    );
  }

  /// Core method to launch playback from a play queue.
  Future<PlayQueueResult> _launchFromQueue({
    required PlayQueueResponse? playQueue,
    required String ratingKey,
    String? serverId,
    String? serverName,
    MediaItem? selectedItem,
    bool copyServerInfo = false,
  }) async {
    if (playQueue == null || playQueue.items == null || playQueue.items!.isEmpty) {
      return const PlayQueueEmpty();
    }

    if (!context.mounted) return const PlayQueueError('Context not mounted');

    // Set up playback state
    final playbackState = context.read<PlaybackStateProvider>();
    playbackState.setPlayQueueWindowFetcher(client.getPlayQueue);
    await playbackState.setPlaybackFromPlayQueue(playQueue, ratingKey);

    if (!context.mounted) return const PlayQueueError('Context not mounted');

    // Determine which item to navigate to
    var itemToPlay = selectedItem ?? playQueue.items!.first;

    // Copy server info if needed
    if (copyServerInfo && serverId != null) {
      itemToPlay = itemToPlay.copyWith(serverId: serverId, serverName: serverName);
    }

    // Navigate to video player
    await navigateToVideoPlayer(context, metadata: itemToPlay);

    return const PlayQueueSuccess();
  }
}

/// Pull the selected item from a play queue. The selected item is identified
/// by `playQueueSelectedItemID`; returns null if the queue has no selection.
MediaItem? _resolveSelectedMediaItem(PlayQueueResponse? playQueue) {
  return playQueue?.selectedItem;
}
