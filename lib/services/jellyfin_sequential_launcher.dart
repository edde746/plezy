import 'dart:math';
import '../media/ids.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';
import '../media/play_queue.dart';
import '../providers/multi_server_provider.dart';
import '../providers/playback_state_provider.dart';
import '../utils/snackbar_helper.dart';
import '../utils/media_server_http_client.dart';
import 'jellyfin_client.dart';
import 'media_list_playback_launcher.dart';
import 'playlist_items_loader.dart';

/// Backend-neutral launcher for Jellyfin collections, playlists, and folders.
///
/// Jellyfin has no server-side queue resource — the client fetches
/// children (collection) or playlist items, applies shuffle locally,
/// and hands the flat list to [PlaybackStateProvider] via
/// [PlaybackStateProvider.setPlaybackFromLocalQueue] which the player
/// already consumes (mirrors the path
/// [EpisodeNavigationService] uses for episode windows).
class JellyfinSequentialLauncher extends MediaListPlaybackLauncher {
  final BuildContext context;

  /// Hook for tests — bypasses [Provider.of] so callers can inject a
  /// fake [MediaServerClient]. Production callers leave this null and
  /// the launcher resolves the client through [MultiServerProvider].
  final MediaServerClient? clientForTesting;

  /// Hook for tests — bypasses [Provider.of] so callers can inject a
  /// fake [PlaybackStateProvider]. Production callers leave this null.
  final PlaybackStateProvider? playbackStateForTesting;

  /// Hook for tests — replaces the real player navigation so the unit
  /// test doesn't need a Navigator/route stack.
  final Future<void> Function(MediaItem item)? navigateForTesting;

  JellyfinSequentialLauncher({
    required this.context,
    this.clientForTesting,
    this.playbackStateForTesting,
    this.navigateForTesting,
  });

  @override
  Future<PlayQueueResult> launchFromCollectionOrPlaylist({
    required Object item,
    required bool shuffle,
    MediaItem? startItem,
    bool showLoadingIndicator = true,
  }) async {
    final facts = MediaListPlaybackLauncher.classifyItem(item);
    if (facts == null) {
      return PlayQueueError(Exception('Item must be a collection or playlist'));
    }
    final serverId = facts.serverId;
    if (serverId == null) {
      return PlayQueueError(Exception('Item is missing serverId'));
    }

    return _launchLocalQueue(
      serverId: serverId,
      queueId: 'jellyfin:${facts.id}',
      contextKey: facts.id,
      shuffle: shuffle,
      showLoadingIndicator: showLoadingIndicator,
      fetchItems: (client, abort) async {
        // Playlists go through the dedicated `/Playlists/{id}/Items` endpoint
        // so playlist-defined order is preserved; collections fall back to
        // recursive descendant expansion (which skips unplayable Series
        // containers and surfaces Movies + Episodes flat).
        final List<MediaItem> items;
        if (facts.isPlaylist) {
          items = await fetchAllPlaylistItems(client, facts.id, abort: abort);
        } else if (client is JellyfinClient) {
          items = await client.fetchPlayableDescendants(facts.id, abort: abort);
        } else {
          // Test/back-end compatibility: the neutral interface intentionally
          // does not bind unrelated complete-list callers to launch lifetime.
          items = await client.fetchPlayableDescendants(facts.id);
        }
        abort.throwIfAborted();
        return items;
      },
      // When a startItem is given (and we're not shuffling), keep the full
      // original order and move the local queue cursor to that item.
      resolveStartIndex: (items) {
        final start = startItem;
        if (shuffle || start == null) return 0;
        final index = items.indexWhere((it) => it.id == start.id);
        return index < 0 ? 0 : index;
      },
    );
  }

  /// Launch playback from a Jellyfin folder row. Jellyfin has no server-side
  /// queue resource, so folders use the same local queue path as collections.
  /// The client query is video-only; music-only folders return [PlayQueueEmpty].
  @override
  Future<PlayQueueResult> launchFromFolder({
    required MediaItem folder,
    required bool shuffle,
    bool showLoadingIndicator = true,
  }) async {
    final serverId = folder.serverId;
    if (serverId == null) {
      return PlayQueueError(Exception('Item is missing serverId'));
    }

    return _launchLocalQueue(
      serverId: serverId,
      queueId: 'jellyfin:folder:${folder.id}',
      contextKey: folder.id,
      shuffle: shuffle,
      showLoadingIndicator: showLoadingIndicator,
      fetchItems: (client, abort) async {
        final fetched = client is JellyfinClient
            ? await client.fetchPlayableFolderDescendants(folder.id, abort: abort)
            : await client.fetchPlayableDescendants(folder.id);
        abort.throwIfAborted();
        return fetched.where((item) => item.kind.isVideo).map((item) {
          return item.copyWith(
            serverId: item.serverId ?? serverId,
            serverName: item.serverName ?? folder.serverName,
            libraryId: item.libraryId ?? folder.libraryId,
            libraryTitle: item.libraryTitle ?? folder.libraryTitle,
          );
        }).toList();
      },
    );
  }

  @override
  Future<PlayQueueResult> launchShuffledShow({required MediaItem metadata, bool showLoadingIndicator = true}) async {
    final kind = metadata.kind;
    if (kind != MediaKind.show && kind != MediaKind.season) {
      return PlayQueueError(Exception('Shuffle play only works for shows and seasons'));
    }
    final serverId = metadata.serverId;
    if (serverId == null) {
      return PlayQueueError(Exception('Item is missing serverId'));
    }
    final String seriesId;
    if (kind == MediaKind.show) {
      seriesId = metadata.id;
    } else {
      final parent = metadata.parentId;
      if (parent == null) {
        return PlayQueueError(Exception('Season is missing parentId'));
      }
      seriesId = parent;
    }

    return _launchLocalQueue(
      serverId: serverId,
      queueId: 'jellyfin:$seriesId',
      contextKey: seriesId,
      shuffle: true,
      showLoadingIndicator: showLoadingIndicator,
      fetchItems: (client, abort) async {
        final raw = client is JellyfinClient
            ? await client.fetchClientSideEpisodeQueue(seriesId, abort: abort)
            : await client.fetchClientSideEpisodeQueue(seriesId);
        abort.throwIfAborted();
        if (raw == null) return const <MediaItem>[];
        return raw.map((e) => e.copyWith(serverId: serverId, serverName: metadata.serverName ?? e.serverName)).toList();
      },
    );
  }

  /// Fetch, shuffle, and publish a local queue behind the cancellable loading
  /// dialog. [fetchItems] carries the only per-entry-point difference: which
  /// client call produces the items and how they're normalized.
  Future<PlayQueueResult> _launchLocalQueue({
    required String serverId,
    required String queueId,
    required String contextKey,
    required bool shuffle,
    required bool showLoadingIndicator,
    required Future<List<MediaItem>> Function(MediaServerClient client, AbortController abort) fetchItems,
    int Function(List<MediaItem> items)? resolveStartIndex,
  }) async {
    final abort = AbortController();

    return executeWithLoading(
      context: context,
      showLoading: showLoadingIndicator,
      actionLabel: shuffle ? t.common.shuffle : t.common.play,
      abort: abort,
      execute: (dismissLoading) async {
        final client = clientForTesting ?? _resolveClient(ServerId(serverId));
        if (client == null) {
          return _missingClientError(serverId, dismissLoading);
        }

        var items = await fetchItems(client, abort);
        if (items.isEmpty) return const PlayQueueEmpty();

        abort.throwIfAborted();
        if (shuffle) {
          items = List.of(items)..shuffle(Random());
        }

        abort.throwIfAborted();
        final startIndex = resolveStartIndex?.call(items) ?? 0;

        await dismissLoading();
        abort.throwIfAborted();
        if (!context.mounted && navigateForTesting == null) {
          return const PlayQueueError('Context not mounted');
        }

        abort.throwIfAborted();
        final playbackState = playbackStateForTesting ?? context.read<PlaybackStateProvider>();
        return launchLocalQueuePlayback(
          context: context,
          playbackState: playbackState,
          queue: LocalPlayQueue(
            id: queueId,
            items: items,
            currentIndex: startIndex,
            shuffled: shuffle,
            backendId: client.backend.id,
          ),
          contextKey: contextKey,
          navigateForTesting: navigateForTesting,
        );
      },
    );
  }

  /// Resolve the [MediaServerClient] for [serverId] through
  /// [MultiServerProvider]. Returns null when the server isn't online or
  /// the provider isn't in scope.
  MediaServerClient? _resolveClient(ServerId serverId) {
    final provider = Provider.of<MultiServerProvider>(context, listen: false);
    return provider.serverManager.getClient(serverId);
  }

  Future<PlayQueueError> _missingClientError(String serverId, Future<void> Function() dismissLoading) async {
    await dismissLoading();
    if (context.mounted) {
      showErrorSnackBar(context, t.errors.noClientAvailable);
    }
    return PlayQueueError(Exception('No client for server $serverId'));
  }
}
