import 'dart:math';

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
import 'media_list_playback_launcher.dart';
import 'playlist_items_loader.dart';

/// Backend-neutral launcher for Jellyfin collections and playlists.
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

    return executeWithLoading(
      context: context,
      showLoading: showLoadingIndicator,
      actionLabel: shuffle ? t.common.shuffle : t.common.play,
      execute: (dismissLoading) async {
        final client = clientForTesting ?? _resolveClient(serverId);
        if (client == null) {
          await dismissLoading();
          if (context.mounted) {
            showErrorSnackBar(context, t.errors.noClientAvailable);
          }
          return PlayQueueError(Exception('No client for server $serverId'));
        }

        // Playlists go through the dedicated `/Playlists/{id}/Items` endpoint
        // so playlist-defined order is preserved; collections fall back to
        // recursive descendant expansion (which skips unplayable Series
        // containers and surfaces Movies + Episodes flat).
        List<MediaItem> items;
        if (facts.isPlaylist) {
          items = await fetchAllPlaylistItems(client, facts.id);
        } else {
          items = await client.fetchPlayableDescendants(facts.id);
        }

        if (items.isEmpty) return const PlayQueueEmpty();

        if (shuffle) {
          items = List.of(items)..shuffle(Random());
        }

        // When a startItem is given (and we're not shuffling), keep the full
        // original order and move the local queue cursor to that item.
        var startIndex = 0;
        if (!shuffle && startItem != null) {
          startIndex = items.indexWhere((it) => it.id == startItem.id);
          if (startIndex < 0) startIndex = 0;
        }

        await dismissLoading();
        if (!context.mounted && navigateForTesting == null) {
          return const PlayQueueError('Context not mounted');
        }

        final playbackState = playbackStateForTesting ?? context.read<PlaybackStateProvider>();
        return launchLocalQueuePlayback(
          context: context,
          playbackState: playbackState,
          queue: LocalPlayQueue(
            id: 'jellyfin:${facts.id}',
            items: items,
            currentIndex: startIndex,
            shuffled: shuffle,
            backendId: client.backend.id,
          ),
          contextKey: facts.id,
          navigateForTesting: navigateForTesting,
        );
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

    return executeWithLoading(
      context: context,
      showLoading: showLoadingIndicator,
      actionLabel: t.common.shuffle,
      execute: (dismissLoading) async {
        final client = clientForTesting ?? _resolveClient(serverId);
        if (client == null) {
          await dismissLoading();
          if (context.mounted) {
            showErrorSnackBar(context, t.errors.noClientAvailable);
          }
          return PlayQueueError(Exception('No client for server $serverId'));
        }

        final raw = await client.fetchClientSideEpisodeQueue(seriesId);
        if (raw == null || raw.isEmpty) return const PlayQueueEmpty();

        final shuffled = List.of(raw)..shuffle(Random());
        final items = shuffled.map((e) => e.copyWith(serverId: serverId, serverName: metadata.serverName)).toList();

        await dismissLoading();
        if (!context.mounted && navigateForTesting == null) {
          return const PlayQueueError('Context not mounted');
        }

        final playbackState = playbackStateForTesting ?? context.read<PlaybackStateProvider>();
        return launchLocalQueuePlayback(
          context: context,
          playbackState: playbackState,
          queue: LocalPlayQueue(
            id: 'jellyfin:$seriesId',
            items: items,
            currentIndex: 0,
            shuffled: true,
            backendId: client.backend.id,
          ),
          contextKey: seriesId,
          navigateForTesting: navigateForTesting,
        );
      },
    );
  }

  /// Resolve the [MediaServerClient] for [serverId] through
  /// [MultiServerProvider]. Returns null when the server isn't online or
  /// the provider isn't in scope.
  MediaServerClient? _resolveClient(String serverId) {
    final provider = Provider.of<MultiServerProvider>(context, listen: false);
    return provider.serverManager.getClient(serverId);
  }
}
