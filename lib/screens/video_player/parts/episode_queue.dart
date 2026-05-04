part of '../../video_player_screen.dart';

extension _VideoPlayerEpisodeQueueMethods on VideoPlayerScreenState {
  /// Ensure a play queue exists for sequential episode playback
  Future<void> _ensurePlayQueue() async {
    if (!mounted) return;

    // Skip play queue in offline mode (requires server connection)
    if (_isOfflinePlayback) return;

    // Skip play queue for live TV (would interfere with tuner session)
    if (widget.isLive) return;

    // Only create play queues for episodes
    if (!_currentMetadata.isEpisode) {
      return;
    }

    // Plex-only — Jellyfin's local queue is published by
    // EpisodeNavigationService._ensureLocalEpisodeQueue from
    // _loadAdjacentEpisodes, so this method is a no-op for it.
    if (_currentMetadata.backend != MediaBackend.plex) return;

    try {
      final client = context.getPlexClientForServer(_currentMetadata.serverId!);

      final playbackState = context.read<PlaybackStateProvider>();

      // Determine the show's rating key
      // For episodes, grandparentId points to the show
      final showRatingKey = _currentMetadata.grandparentId;
      if (showRatingKey == null) {
        appLogger.d('Episode missing grandparentId, skipping play queue creation');
        return;
      }

      // Preserve any queue this item belongs to — playlist, collection,
      // or same-show queue. `isItemInActiveQueue` is the same gate
      // VideoPlayerScreen.initState uses; a context-key check alone would
      // wipe a playlist queue (its key is the playlist id, not the show).
      // Only when the active queue is genuinely stale (item not in it)
      // do we clobber and create a fresh show queue.
      if (playbackState.isItemInActiveQueue(_currentMetadata)) {
        playbackState.setCurrentItem(_currentMetadata);
        appLogger.d('Using existing play queue (context: ${playbackState.shuffleContextKey})');
        return;
      }
      if (playbackState.isQueueActive) {
        appLogger.d('Resetting stale play queue (was: ${playbackState.shuffleContextKey}, now: $showRatingKey)');
        playbackState.clearShuffle();
      }

      // Create a new sequential play queue for the show
      appLogger.d('Creating sequential play queue for show $showRatingKey');
      final playQueue = await client.createShowPlayQueue(
        showRatingKey: showRatingKey,
        shuffle: 0, // Sequential order
        startingEpisodeKey: _currentMetadata.id,
      );

      if (playQueue != null && playQueue.items != null && playQueue.items!.isNotEmpty) {
        // Initialize playback state with the play queue
        await playbackState.setPlaybackFromPlayQueue(playQueue, showRatingKey);

        // Set the client for loading more items
        playbackState.setPlayQueueWindowFetcher(client.getPlayQueue);

        appLogger.d('Sequential play queue created with ${playQueue.items!.length} items');
      }
    } catch (e) {
      // Non-critical: Sequential playback will fall back to non-queue navigation
      appLogger.d('Could not create play queue for sequential playback', error: e);
    }
  }

  Future<void> _loadAdjacentEpisodes() async {
    if (!mounted || widget.isLive) return;

    if (_isOfflinePlayback) {
      // Offline mode: find next/previous from downloaded episodes
      _loadAdjacentEpisodesOffline();
      return;
    }

    try {
      // Load adjacent episodes using the service
      final adjacentEpisodes = await _episodeNavigation.loadAdjacentEpisodes(
        context: context,
        metadata: _currentMetadata,
      );

      if (mounted) {
        _setPlayerState(() {
          _nextEpisode = adjacentEpisodes.next;
          _previousEpisode = adjacentEpisodes.previous;
        });
      }
    } catch (e) {
      // Non-critical: Failed to load next/previous episode metadata
      appLogger.d('Could not load adjacent episodes', error: e);
    }
  }

  /// Load next/previous episodes from locally downloaded content
  void _loadAdjacentEpisodesOffline() {
    if (!_currentMetadata.isEpisode) return;

    final showKey = _currentMetadata.grandparentId;
    if (showKey == null) return;

    try {
      final downloadProvider = context.read<DownloadProvider>();
      final episodes = downloadProvider.getDownloadedEpisodesForShow(showKey);

      if (episodes.isEmpty) return;

      // Sort by aired date, falling back to season/episode number
      final sorted = List<MediaItem>.from(episodes)
        ..sort((a, b) {
          final aDate = a.originallyAvailableAt ?? '';
          final bDate = b.originallyAvailableAt ?? '';
          if (aDate.isEmpty && bDate.isEmpty) {
            final seasonCmp = (a.parentIndex ?? 0).compareTo(b.parentIndex ?? 0);
            if (seasonCmp != 0) return seasonCmp;
            return (a.index ?? 0).compareTo(b.index ?? 0);
          }
          if (aDate.isEmpty) return 1;
          if (bDate.isEmpty) return -1;
          return aDate.compareTo(bDate);
        });

      // Find current episode in the sorted list
      final currentIdx = sorted.indexWhere((ep) => ep.id == _currentMetadata.id);

      if (currentIdx == -1) return;

      if (mounted) {
        _setPlayerState(() {
          _previousEpisode = currentIdx > 0 ? sorted[currentIdx - 1] : null;
          _nextEpisode = currentIdx < sorted.length - 1 ? sorted[currentIdx + 1] : null;
        });
      }
    } catch (e) {
      appLogger.d('Could not load offline adjacent episodes', error: e);
    }
  }
}
