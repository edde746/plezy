import 'dart:async';
import '../media/ids.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/play_queue.dart';
import '../providers/multi_server_provider.dart';
import '../providers/playback_state_provider.dart';
import '../services/multi_server_manager.dart';
import '../utils/app_logger.dart';

/// Result of loading adjacent episodes
class AdjacentEpisodes {
  const AdjacentEpisodes({this.next, this.previous, required this.nextStatus, required this.previousStatus});

  const AdjacentEpisodes.unavailable()
    : next = null,
      previous = null,
      nextStatus = QueueNavigationStatus.unavailable,
      previousStatus = QueueNavigationStatus.unavailable;

  const AdjacentEpisodes.failed()
    : next = null,
      previous = null,
      nextStatus = QueueNavigationStatus.failed,
      previousStatus = QueueNavigationStatus.failed;

  final MediaItem? next;
  final MediaItem? previous;
  final QueueNavigationStatus nextStatus;
  final QueueNavigationStatus previousStatus;

  bool get hasNext => next != null;
  bool get hasPrevious => previous != null;
  bool get isEndConfirmed => nextStatus == QueueNavigationStatus.boundary;
}

enum _EpisodeQueueAvailability { active, unavailable, failed }

/// Manages episode navigation for TV show playback.
///
/// Handles:
/// - Loading next/previous episodes from play queues
/// - Navigating between episodes while preserving track selections
/// - Supporting both sequential and shuffle playback modes
///
/// Plex normally enters with its server-side `/playQueues` queue. If that
/// setup failed, the same client-side full-series path used by Jellyfin is
/// used as a fallback. Both paths publish into [PlaybackStateProvider] so
/// the player reads previous/next from one source.
class EpisodeNavigationService {
  /// Cached client-side episode lists, keyed by `seriesId`. Populated for
  /// Jellyfin and when Plex's server-side queue is unavailable. Fetched once
  /// per series; subsequent navigation within the show reuses the cache.
  ///
  /// Bounded by [_seriesCacheCapacity] LRU-style: each entry holds up to
  /// 200 episodes (~50–80 KB each at typical metadata sizes), so an
  /// unbounded map opens an OOM door for users who hop between many shows
  /// in one session. `LinkedHashMap` preserves insertion order; we re-touch
  /// on hit to keep the most recently used at the back.
  final Map<String, List<MediaItem>> _seriesEpisodeCache = <String, List<MediaItem>>{};

  /// Maximum number of distinct series whose episode lists stay resident.
  /// 5 covers any plausible "binge a few shows in parallel" workflow without
  /// holding ~5–10 MB of metadata when the user wanders the library.
  static const int _seriesCacheCapacity = 5;

  /// Load the next and previous episodes for the current episode
  ///
  /// Returns null for episodes if:
  /// - Not applicable (e.g., movie content)
  /// - Next episode doesn't exist (end of season/series)
  /// - Previous episode doesn't exist (first episode)
  ///
  /// [playedPartId] is the backend part id actually being played, when
  /// known — it lets the queue skip sibling entries of a Plex
  /// multi-episode file (#1500).
  Future<AdjacentEpisodes> loadAdjacentEpisodes({
    required BuildContext context,
    required MediaItem metadata,
    String? playedPartId,
  }) async {
    try {
      // Resolve providers up-front so we don't reach for `context` after
      // any of the awaits below — avoids the
      // `use_build_context_synchronously` lint and the genuine "widget
      // unmounted mid-load" race it warns about.
      final serverManager = context.read<MultiServerProvider>().serverManager;
      final playbackState = context.read<PlaybackStateProvider>();

      // Preserve a server-side Plex queue when available. Otherwise build a
      // full-series local queue for Plex or Jellyfin before resolving
      // adjacency.
      final availability = await _ensureLocalEpisodeQueue(serverManager, playbackState, metadata);

      if (availability == _EpisodeQueueAvailability.unavailable) {
        return const AdjacentEpisodes.unavailable();
      }
      if (availability == _EpisodeQueueAvailability.failed || !playbackState.isQueueActive) {
        return const AdjacentEpisodes.failed();
      }

      final nextResult = await playbackState.getNextEpisode(metadata.id, playedPartId: playedPartId);
      final previousResult = await playbackState.getPreviousEpisode(metadata.id, playedPartId: playedPartId);
      final nextStatus = nextResult.status == QueueNavigationStatus.unavailable
          ? QueueNavigationStatus.failed
          : nextResult.status;
      final previousStatus = previousResult.status == QueueNavigationStatus.unavailable
          ? QueueNavigationStatus.failed
          : previousResult.status;
      final mode = playbackState.isShuffleActive ? 'Shuffle' : 'Sequential';
      appLogger.d(
        '$mode mode - Next: ${nextResult.item?.title} ($nextStatus), '
        'Previous: ${previousResult.item?.title} ($previousStatus)',
      );
      return AdjacentEpisodes(
        next: nextResult.item,
        previous: previousResult.item,
        nextStatus: nextStatus,
        previousStatus: previousStatus,
      );
    } catch (e, st) {
      appLogger.w('Could not load adjacent episodes', error: e, stackTrace: st);
      return const AdjacentEpisodes.failed();
    }
  }

  /// Ensure [PlaybackStateProvider] holds a queue covering the current item.
  /// A queue the item already belongs to (launcher-seeded shuffle, playlist,
  /// collection, or an earlier series build) is preserved. Otherwise the
  /// backend's full series episode list is published, anchored at the current
  /// episode. For Plex this is the fallback when `/playQueues` was
  /// unavailable; for Jellyfin it is the normal queue path.
  Future<_EpisodeQueueAvailability> _ensureLocalEpisodeQueue(
    MultiServerManager serverManager,
    PlaybackStateProvider playbackState,
    MediaItem metadata,
  ) async {
    if (metadata.serverId == null || !metadata.isEpisode || metadata.grandparentId == null) {
      return _EpisodeQueueAvailability.unavailable;
    }
    final seriesId = metadata.grandparentId!;
    // Preserve any queue this item already belongs to — a launcher-seeded
    // shuffled show queue (contextKey == seriesId), a playlist/collection
    // queue, or a series queue this method built earlier. setCurrentItem
    // re-anchors the cursor, replacing the re-anchor the rebuild used to
    // provide. Without this gate a shuffled show queue was clobbered by a
    // sequential rebuild after the first episode (#1466).
    if (playbackState.isItemInActiveQueue(metadata)) {
      playbackState.setCurrentItem(metadata);
      return _EpisodeQueueAvailability.active;
    }
    // Same-episode reload with a fresh object: a source/quality switch hands
    // _reloadMediaInPlace a copyWith clone of the playing item, and MediaItem
    // compares by identity, so the membership gate above misses. The cursor
    // already points at this episode — the queue (and any shuffled order)
    // must survive.
    if (playbackState.isQueueActive && playbackState.currentQueueItem?.globalKey == metadata.globalKey) {
      return _EpisodeQueueAvailability.active;
    }
    // The playing item isn't in the active queue. Still don't replace a
    // playlist/collection queue with a series queue: the launcher (e.g.
    // [JellyfinSequentialLauncher]) sets contextKey to the playlist or
    // collection id; a series rebuild here would clobber it and prev/next
    // would walk the show instead of the user's list.
    final activeKey = playbackState.shuffleContextKey;
    if (playbackState.isQueueActive && activeKey != null && activeKey != seriesId) {
      return _EpisodeQueueAvailability.failed;
    }
    var allEpisodes = _readSeriesCache(seriesId);
    if (allEpisodes == null) {
      final client = serverManager.getClient(ServerId(metadata.serverId!));
      if (client == null) return _EpisodeQueueAvailability.failed;
      try {
        allEpisodes = await client.fetchClientSideEpisodeQueue(seriesId);
      } catch (e, st) {
        appLogger.w('Failed series-episodes fetch for queue', error: e, stackTrace: st);
        return _EpisodeQueueAvailability.failed;
      }
      if (allEpisodes == null || allEpisodes.isEmpty) {
        return _EpisodeQueueAvailability.failed;
      }
      _writeSeriesCache(seriesId, allEpisodes);
    }
    final anchorIdx = allEpisodes.indexWhere((m) => m.id == metadata.id);
    if (anchorIdx < 0) return _EpisodeQueueAvailability.failed;

    final queue = LocalPlayQueue(
      id: '${metadata.backend.id}:$seriesId',
      items: allEpisodes,
      currentIndex: anchorIdx,
      backendId: metadata.backend.id,
    );
    playbackState.setPlaybackFromLocalQueue(queue, contextKey: seriesId);
    appLogger.d('Local episode queue (${allEpisodes.length} episodes, anchor: $anchorIdx)');
    return _EpisodeQueueAvailability.active;
  }

  /// LRU-touching read: re-inserts the entry so it becomes the most recent.
  /// Returns null on miss.
  List<MediaItem>? _readSeriesCache(String seriesId) {
    final value = _seriesEpisodeCache.remove(seriesId);
    if (value != null) {
      _seriesEpisodeCache[seriesId] = value;
    }
    return value;
  }

  /// LRU-bounded write: evicts the oldest entry when capacity is exceeded.
  void _writeSeriesCache(String seriesId, List<MediaItem> episodes) {
    _seriesEpisodeCache.remove(seriesId);
    _seriesEpisodeCache[seriesId] = episodes;
    while (_seriesEpisodeCache.length > _seriesCacheCapacity) {
      _seriesEpisodeCache.remove(_seriesEpisodeCache.keys.first);
    }
  }
}
