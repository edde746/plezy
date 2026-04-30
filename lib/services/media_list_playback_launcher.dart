import 'dart:async';

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_playlist.dart';
import '../media/play_queue.dart';
import '../providers/playback_state_provider.dart';
import '../utils/app_logger.dart';
import '../utils/snackbar_helper.dart';
import '../utils/video_player_navigation.dart';
import 'jellyfin_sequential_launcher.dart';
import 'play_queue_launcher.dart';

/// Result type for play queue launches. Same shape as the previous
/// [PlexPlayQueueLauncher] result so existing call sites can keep their
/// pattern matching unchanged.
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

/// Backend-neutral playback launcher for collections and playlists.
///
/// Plex uses server-side `/playQueues` (one round trip, server tracks
/// queue state). Jellyfin has no equivalent — the client builds an
/// in-memory queue from `fetchChildren` (collection) or
/// `fetchPlaylistItems` (playlist). [MediaListPlaybackLauncher.forItem]
/// picks the implementation by inspecting the item's backend.
abstract class MediaListPlaybackLauncher {
  /// Launch playback from a collection (a [MediaItem] with
  /// `kind == MediaKind.collection`) or a [MediaPlaylist].
  ///
  /// [startItem] (optional) starts playback at that item rather than the head
  /// of the queue — used by the playlist detail screen's "tap an item to
  /// start here" interaction. Plex passes it as `key` to `/playQueues`;
  /// Jellyfin rotates the locally-built queue. Ignored when [shuffle] is
  /// true.
  Future<PlayQueueResult> launchFromCollectionOrPlaylist({
    required Object item,
    required bool shuffle,
    MediaItem? startItem,
    bool showLoadingIndicator = true,
  });

  /// Launch shuffled playback for a show or season. Plex builds a server-side
  /// `/playQueues` with `shuffle=1`; Jellyfin fetches the full episode list
  /// via `fetchClientSideEpisodeQueue`, shuffles locally, and publishes
  /// through `setPlaybackFromLocalQueue` (same path as the sequential
  /// queue from `EpisodeNavigationService`).
  Future<PlayQueueResult> launchShuffledShow({required MediaItem metadata, bool showLoadingIndicator = true});

  /// Pick the right implementation for [item]. Reads
  /// [MediaItem.backend] / [MediaPlaylist.backend].
  static MediaListPlaybackLauncher forItem(BuildContext context, Object item) {
    final backend = _backendOf(item);
    if (backend == MediaBackend.jellyfin) {
      return JellyfinSequentialLauncher(context: context);
    }
    return PlexPlayQueueLauncher.forContext(context, item);
  }

  static MediaBackend _backendOf(Object item) {
    if (item is MediaItem) return item.backend;
    if (item is MediaPlaylist) return item.backend;
    throw ArgumentError('Unsupported item type for MediaListPlaybackLauncher: ${item.runtimeType}');
  }

  /// Pull (kind, id, serverId, serverName) from an [item] that's a
  /// [MediaItem] (collection-only) or a [MediaPlaylist]. Returns `null` for
  /// any other type (including non-collection [MediaItem]) — caller turns
  /// that into a [PlayQueueError] with whatever wording fits the call site.
  static MediaListItemFacts? classifyItem(Object item) {
    if (item is MediaItem) {
      if (item.kind != MediaKind.collection) return null;
      return MediaListItemFacts(
        isCollection: true,
        isPlaylist: false,
        id: item.id,
        serverId: item.serverId,
        serverName: item.serverName,
      );
    }
    if (item is MediaPlaylist) {
      return MediaListItemFacts(
        isCollection: false,
        isPlaylist: true,
        id: item.id,
        serverId: item.serverId,
        serverName: item.serverName,
      );
    }
    return null;
  }

  /// Show a loading dialog (when [showLoading] is true), invoke [execute],
  /// dismiss the dialog, and translate exceptions into a localized snackbar
  /// + [PlayQueueError]. [actionLabel] feeds the failure-snackbar copy.
  ///
  /// `dismissLoading` is passed into [execute] so the callback can hide the
  /// dialog before navigating to the player; the wrapper dismisses
  /// idempotently afterwards as a safety net.
  ///
  /// A [PlayQueueEmpty] result auto-emits the "no items" snackbar so each
  /// backend doesn't have to remember.
  @protected
  Future<PlayQueueResult> executeWithLoading({
    required BuildContext context,
    required bool showLoading,
    required String actionLabel,
    required Future<PlayQueueResult> Function(Future<void> Function() dismissLoading) execute,
  }) async {
    BuildContext? loadingDialogContext;
    var loadingVisible = false;

    if (showLoading && context.mounted) {
      loadingVisible = true;
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            loadingDialogContext = dialogContext;
            return const Center(child: CircularProgressIndicator());
          },
        ),
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

      if (result is PlayQueueEmpty && context.mounted) {
        showErrorSnackBar(context, t.messages.failedToCreatePlayQueueNoItems);
      }

      await dismissLoading();
      return result;
    } catch (e) {
      appLogger.e('Failed to $actionLabel', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.failedPlayback(action: actionLabel, error: e.toString()));
      }
      await dismissLoading();
      return PlayQueueError(e);
    } finally {
      await dismissLoading();
    }
  }

  /// Publish a client-side queue and navigate to its selected item.
  @protected
  Future<PlayQueueResult> launchLocalQueuePlayback({
    required BuildContext context,
    required PlaybackStateProvider playbackState,
    required LocalPlayQueue queue,
    required String contextKey,
    Future<void> Function(MediaItem item)? navigateForTesting,
  }) async {
    if (queue.items.isEmpty) return const PlayQueueEmpty();
    if (!context.mounted && navigateForTesting == null) {
      return const PlayQueueError('Context not mounted');
    }

    final currentIndex = queue.currentIndex ?? 0;
    if (currentIndex < 0 || currentIndex >= queue.items.length) {
      return PlayQueueError(RangeError.index(currentIndex, queue.items, 'currentIndex'));
    }

    playbackState.setPlaybackFromLocalQueue(queue, contextKey: contextKey);
    final itemToPlay = queue.items[currentIndex];
    if (navigateForTesting != null) {
      await navigateForTesting(itemToPlay);
    } else {
      if (!context.mounted) return const PlayQueueError('Context not mounted');
      await navigateToVideoPlayer(context, metadata: itemToPlay);
    }
    return const PlayQueueSuccess();
  }
}

/// Common shape extracted from [MediaItem] (collection) and [MediaPlaylist]
/// so both launcher backends share their classification preamble.
class MediaListItemFacts {
  final bool isCollection;
  final bool isPlaylist;
  final String id;
  final String? serverId;
  final String? serverName;

  const MediaListItemFacts({
    required this.isCollection,
    required this.isPlaylist,
    required this.id,
    required this.serverId,
    required this.serverName,
  });
}
