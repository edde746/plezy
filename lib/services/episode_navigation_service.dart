import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/play_queue.dart';
import '../mpv/mpv.dart';
import '../providers/multi_server_provider.dart';
import '../providers/playback_state_provider.dart';
import '../services/multi_server_manager.dart';
import '../utils/app_logger.dart';
import '../utils/video_player_navigation.dart';

/// Result of loading adjacent episodes
class AdjacentEpisodes {
  final MediaItem? next;
  final MediaItem? previous;

  AdjacentEpisodes({this.next, this.previous});

  bool get hasNext => next != null;
  bool get hasPrevious => previous != null;
}

/// Manages episode navigation for TV show playback.
///
/// Handles:
/// - Loading next/previous episodes from play queues
/// - Navigating between episodes while preserving track selections
/// - Supporting both sequential and shuffle playback modes
///
/// Plex episodes navigate through the server-side `/playQueues` queue;
/// Jellyfin (and any other backend whose
/// [MediaServerClient.fetchClientSideEpisodeQueue] returns rows) builds
/// a centred 21-item local queue here and publishes it through
/// [PlaybackStateProvider] so the rest of the player reads prev/next from
/// the same source.
class EpisodeNavigationService {
  /// Cached client-side episode lists, keyed by `seriesId`. Populated by
  /// backends without server-side play queues (Jellyfin); Plex skips this
  /// path entirely. Fetched once per series; subsequent navigation within
  /// the show re-uses the cache so jumping anywhere doesn't trigger a
  /// refetch.
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
  Future<AdjacentEpisodes> loadAdjacentEpisodes({required BuildContext context, required MediaItem metadata}) async {
    try {
      // Resolve providers up-front so we don't reach for `context` after
      // any of the awaits below — avoids the
      // `use_build_context_synchronously` lint and the genuine "widget
      // unmounted mid-load" race it warns about.
      final serverManager = context.read<MultiServerProvider>().serverManager;
      final playbackState = context.read<PlaybackStateProvider>();

      // For Jellyfin, build (or refresh) the centered 21-item window and
      // publish it into PlaybackStateProvider so the rest of this method —
      // and the queue button/sheet — can read prev/next from the same
      // place Plex does. Plex playback comes in here with its server-side
      // queue already populated by `_ensurePlayQueue` so this branch is
      // a no-op (Plex's `fetchClientSideEpisodeQueue` returns null).
      await _ensureLocalEpisodeQueue(serverManager, playbackState, metadata);

      // Both backends now read prev/next off PlaybackStateProvider.
      if (!playbackState.isQueueActive) {
        return AdjacentEpisodes();
      }
      final next = await playbackState.getNextEpisode(metadata.id, loopQueue: false);
      final previous = await playbackState.getPreviousEpisode(metadata.id);
      final mode = playbackState.isShuffleActive ? 'Shuffle' : 'Sequential';
      appLogger.d('$mode mode - Next: ${next?.title}, Previous: ${previous?.title}');
      return AdjacentEpisodes(next: next, previous: previous);
    } catch (e) {
      // Non-critical: Failed to load next/previous episode metadata
      appLogger.d('Could not load adjacent episodes', error: e);
      return AdjacentEpisodes();
    }
  }

  /// Ensure [PlaybackStateProvider] holds a centered 21-item window of
  /// the current series. Cached per-series, so jumping anywhere in the
  /// show only triggers one wire fetch per session. No-op for movies,
  /// items without a series anchor, or backends whose
  /// [MediaServerClient.fetchClientSideEpisodeQueue] returns null (Plex's
  /// queue lives server-side and is populated elsewhere).
  Future<void> _ensureLocalEpisodeQueue(
    MultiServerManager serverManager,
    PlaybackStateProvider playbackState,
    MediaItem metadata,
  ) async {
    if (metadata.serverId == null || !metadata.isEpisode || metadata.grandparentId == null) {
      return;
    }
    final seriesId = metadata.grandparentId!;
    // Don't replace a playlist/collection queue with a series queue.
    // The launcher (e.g. [JellyfinSequentialLauncher]) sets contextKey to
    // the playlist/collection id; a series rebuild here would clobber it
    // and prev/next would walk the show instead of the user's list.
    final activeKey = playbackState.shuffleContextKey;
    if (playbackState.isQueueActive && activeKey != null && activeKey != seriesId) {
      return;
    }
    var allEpisodes = _readSeriesCache(seriesId);
    if (allEpisodes == null) {
      final client = serverManager.getClient(metadata.serverId!);
      if (client == null) return;
      try {
        allEpisodes = await client.fetchClientSideEpisodeQueue(seriesId);
      } catch (e, st) {
        appLogger.w('Failed series-episodes fetch for queue', error: e, stackTrace: st);
        return;
      }
      if (allEpisodes == null) return; // backend uses a server-side queue (Plex)
      if (allEpisodes.isEmpty) return; // empty series
      _writeSeriesCache(seriesId, allEpisodes);
    }
    final anchorIdx = allEpisodes.indexWhere((m) => m.id == metadata.id);
    if (anchorIdx < 0) return;

    final queue = LocalPlayQueue(
      id: '${metadata.backend.id}:$seriesId',
      items: allEpisodes,
      currentIndex: anchorIdx,
      backendId: metadata.backend.id,
    );
    playbackState.setPlaybackFromLocalQueue(queue, contextKey: seriesId);
    appLogger.d('Local episode queue (${allEpisodes.length} episodes, anchor: $anchorIdx)');
  }

  /// Navigate to the next or previous episode
  ///
  /// Preserves the current audio track, subtitle track, and playback rate
  /// selections when transitioning between episodes.
  Future<void> navigateToEpisode({
    required BuildContext context,
    required MediaItem episode,
    required Player? player,
    bool usePushReplacement = true,
  }) async {
    if (!context.mounted) return;

    // Capture current player state before navigation
    AudioTrack? currentAudioTrack;
    SubtitleTrack? currentSubtitleTrack;
    SubtitleTrack? currentSecondarySubtitleTrack;
    double? currentPlaybackRate;

    if (player != null) {
      currentAudioTrack = player.state.track.audio;
      currentSubtitleTrack = player.state.track.subtitle;
      currentSecondarySubtitleTrack = player.state.track.secondarySubtitle;
      currentPlaybackRate = player.state.rate;

      appLogger.d(
        'Navigating to episode with preserved settings - Audio: ${currentAudioTrack?.id}, Subtitle: ${currentSubtitleTrack?.id}, Rate: ${currentPlaybackRate}x',
      );
    }

    // Navigate to the new episode
    if (context.mounted) {
      unawaited(
        navigateToVideoPlayer(
          context,
          metadata: episode,
          preferredAudioTrack: currentAudioTrack,
          preferredSubtitleTrack: currentSubtitleTrack,
          preferredSecondarySubtitleTrack: currentSecondarySubtitleTrack,
          usePushReplacement: usePushReplacement,
        ),
      );
    }
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
