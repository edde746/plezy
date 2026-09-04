import 'dart:async';

import 'package:flutter/material.dart';

import '../exceptions/media_server_exceptions.dart';
import '../i18n/strings.g.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_playlist.dart';
import '../media/play_queue.dart';
import '../providers/playback_state_provider.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/media_server_http_client.dart';
import '../utils/snackbar_helper.dart';
import '../utils/video_player_navigation.dart';
import 'jellyfin_sequential_launcher.dart';
import 'play_queue_launcher.dart';
import '../widgets/dialog_action_button.dart';

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

class PlayQueueCancelled extends PlayQueueResult {
  const PlayQueueCancelled();
}

class PlayQueueError extends PlayQueueResult {
  final Object error;
  const PlayQueueError(this.error);
}

/// Backend-neutral playback launcher for collections and playlists.
///
/// Plex uses server-side `/playQueues` (one round trip, server tracks
/// queue state). MediaBrowser servers have no equivalent — the concrete
/// [JellyfinSequentialLauncher] builds an in-memory queue from playable
/// descendants or playlist items. [MediaListPlaybackLauncher.forItem] picks
/// the implementation by inspecting the item's backend.
abstract class MediaListPlaybackLauncher {
  /// Launch playback from a collection (a [MediaItem] with
  /// `kind == MediaKind.collection`) or a [MediaPlaylist].
  ///
  /// [startItem] (optional) starts playback at that item rather than the head
  /// of the queue — used by the playlist detail screen's "tap an item to
  /// start here" interaction. Plex passes it as `key` to `/playQueues`;
  /// MediaBrowser rotates the locally-built queue. Ignored when [shuffle] is
  /// true.
  Future<PlayQueueResult> launchFromCollectionOrPlaylist({
    required Object item,
    required bool shuffle,
    MediaItem? startItem,
    bool showLoadingIndicator = true,
  });

  /// Launch shuffled playback for a show or season. Plex builds a server-side
  /// `/playQueues` with `shuffle=1`; MediaBrowser fetches the full episode
  /// list via `fetchClientSideEpisodeQueue`, shuffles locally, and publishes
  /// through `setPlaybackFromLocalQueue` (same path as the sequential queue
  /// from `EpisodeNavigationService`).
  Future<PlayQueueResult> launchShuffledShow({required MediaItem metadata, bool showLoadingIndicator = true});

  /// Launch playback from a folder row of the library tree. Everything each
  /// backend needs is stamped onto [folder]: Plex builds a server-side
  /// `/playQueues` from [MediaItem.backendFolderKey] (returning a
  /// [PlayQueueError] when the row carries none), while MediaBrowser fetches
  /// the folder's playable descendants and publishes a local queue.
  Future<PlayQueueResult> launchFromFolder({
    required MediaItem folder,
    required bool shuffle,
    bool showLoadingIndicator = true,
  });

  /// Pick the right implementation for [item]. Reads
  /// [MediaItem.backend] / [MediaPlaylist.backend].
  static MediaListPlaybackLauncher forItem(BuildContext context, Object item) {
    final backend = _backendOf(item);
    if (backend.usesMediaBrowserApi) {
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

  /// Show a loading dialog (when [showLoading] is true), run [execute],
  /// dismiss the dialog, and translate exceptions into typed launch results.
  /// [actionLabel] feeds the failure-snackbar copy.
  ///
  /// The operation is started before the dialog's first frame is awaited, so
  /// the spinner renders concurrently with the first network round trip
  /// instead of in front of it. Dismissal still waits for the dialog to
  /// mount (see [ScopedLoadingDialogController.dismiss]), so the dialog is
  /// never popped before it exists and is dismissed exactly once on every
  /// success and failure path.
  ///
  /// When [abort] is supplied, the loading route owns its lifecycle: Cancel,
  /// back, or scoped route disposal aborts the operation. Programmatic
  /// dismissal marks completed work before popping so success is not aborted.
  ///
  /// `dismissLoading` is passed into [execute] so the callback can hide the
  /// dialog before navigating to the player; the wrapper dismisses
  /// idempotently afterwards as a safety net.
  ///
  /// A [PlayQueueEmpty] result auto-emits the "no items" snackbar so each
  /// backend doesn't have to remember. Cancellation is never logged or shown
  /// as an empty/error result.
  @protected
  Future<PlayQueueResult> executeWithLoading({
    required BuildContext context,
    required bool showLoading,
    required String actionLabel,
    AbortController? abort,
    required Future<PlayQueueResult> Function(Future<void> Function() dismissLoading) execute,
  }) async {
    final loadingDialog = ScopedLoadingDialogController();
    final loadingOwner = abort == null ? null : _LoadingCancellationOwner(abort);

    if (showLoading) {
      if (!context.mounted) {
        abort?.abort();
      } else {
        loadingDialog.show(
          context,
          builder: (_) => loadingOwner == null
              ? const Center(child: CircularProgressIndicator())
              : _CancellableLoadingDialog(owner: loadingOwner, actionLabel: actionLabel),
          onDisposed: () => loadingOwner?.cancel(),
        );
      }
    }

    Future<void> dismissLoading() async {
      if (!loadingDialog.isVisible) return;
      // Complete before dismissing: work can finish before the first dialog
      // frame, and the route's eventual disposal must remain a success path.
      loadingOwner?.complete();
      await loadingDialog.dismiss();
    }

    try {
      abort?.throwIfAborted();
      // Start the operation before waiting for the dialog's first frame so
      // the first round trip overlaps the spinner's render.
      final operationFuture = execute(dismissLoading);
      // The await below still observes any failure; ignore() only keeps an
      // error that lands before the dialog frame from being reported as
      // unhandled.
      operationFuture.ignore();
      await loadingDialog.ready;
      final result = await operationFuture;
      if (abort?.isAborted ?? false) return const PlayQueueCancelled();

      if (result is PlayQueueEmpty && context.mounted) {
        showErrorSnackBar(context, t.messages.failedToCreatePlayQueueNoItems);
      }

      return result;
    } on MediaServerHttpException catch (e) {
      if (e.isCancellation || (abort?.isAborted ?? false)) {
        return const PlayQueueCancelled();
      }
      appLogger.e('Failed to $actionLabel', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.failedPlayback(action: actionLabel, error: e.toString()));
      }
      return PlayQueueError(e);
    } catch (e) {
      if (abort?.isAborted ?? false) return const PlayQueueCancelled();
      appLogger.e('Failed to $actionLabel', error: e);
      if (context.mounted) {
        showErrorSnackBar(context, t.messages.failedPlayback(action: actionLabel, error: e.toString()));
      }
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
      // The queue holds these exact instances and the player's initState gate
      // matches by identity — a WatchStateStore clone here would wipe the
      // launcher-set queue on entry. The items were fetched from the server
      // in this same user action, so session watch patches are already
      // reflected.
      await navigateToVideoPlayer(context, metadata: itemToPlay, resolveWatchState: false);
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

class _LoadingCancellationOwner {
  final AbortController abort;
  bool _completed = false;

  _LoadingCancellationOwner(this.abort);

  void complete() {
    if (!abort.isAborted) _completed = true;
  }

  void cancel() {
    if (!_completed) abort.abort();
  }
}

class _CancellableLoadingDialog extends StatefulWidget {
  final _LoadingCancellationOwner? owner;
  final String actionLabel;

  const _CancellableLoadingDialog({required this.owner, required this.actionLabel});

  @override
  State<_CancellableLoadingDialog> createState() => _CancellableLoadingDialogState();
}

class _CancellableLoadingDialogState extends State<_CancellableLoadingDialog> {
  bool _dismissed = false;

  void _cancelAndDismiss() {
    if (_dismissed) return;
    _dismissed = true;
    widget.owner?.cancel();
    final route = ModalRoute.of(context);
    if ((route?.isCurrent ?? false) && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    widget.owner?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelAndDismiss();
      },
      child: AlertDialog(
        title: Text(widget.actionLabel),
        content: const Center(widthFactor: 1, heightFactor: 1, child: CircularProgressIndicator()),
        actions: [DialogActionButton(onPressed: _cancelAndDismiss, label: t.common.cancel)],
      ),
    );
  }
}
