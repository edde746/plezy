part of '../../video_player_screen.dart';

extension _VideoPlayerEpisodeQueueMethods on VideoPlayerScreenState {
  /// Ensure a play queue exists for sequential episode playback
  Future<void> _ensurePlayQueue() async {
    if (!mounted) return;

    // Download/offline library mode uses the local downloaded queue instead.
    if (_offlineLibraryMode) return;

    // Skip play queue for live TV (would interfere with tuner session)
    if (widget.isLive) return;

    if (!_currentMetadata.isEpisode) {
      return;
    }

    // Plex-only — Jellyfin's local queue is published by
    // EpisodeNavigationService._ensureLocalEpisodeQueue from
    // _loadAdjacentEpisodes, so this method is a no-op for it.
    if (_currentMetadata.backend != MediaBackend.plex) return;

    try {
      final client = context.getPlexClientForServer(ServerId(_currentMetadata.serverId!));

      final playbackState = context.read<PlaybackStateProvider>();

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

      appLogger.d('Creating sequential play queue for show $showRatingKey');
      final playQueue = await client.createShowPlayQueue(
        showRatingKey: showRatingKey,
        shuffle: 0,
        startingEpisodeKey: _currentMetadata.id,
        librarySectionID: _currentMetadata.libraryId,
        librarySectionTitle: _currentMetadata.libraryTitle,
      );

      if (playQueue != null && playQueue.items != null && playQueue.items!.isNotEmpty) {
        await playbackState.setPlaybackFromPlayQueue(playQueue, showRatingKey);
        playbackState.setPlayQueueWindowFetcher(
          (id, {center, window = 50}) => client.getPlayQueue(
            id,
            center: center,
            window: window,
            librarySectionID: _currentMetadata.libraryId,
            librarySectionTitle: _currentMetadata.libraryTitle,
          ),
        );

        appLogger.d('Sequential play queue created with ${playQueue.items!.length} items');
      }
    } catch (e) {
      // Non-critical: Sequential playback will fall back to non-queue navigation
      appLogger.d('Could not create play queue for sequential playback', error: e);
    }
  }

  Future<void> _loadAdjacentEpisodes({MediaItem? metadata, _PlaybackAttempt? attempt}) async {
    if (!mounted || widget.isLive) return;

    final targetMetadata = metadata ?? _currentMetadata;

    if (_offlineLibraryMode) {
      // Offline mode: find next/previous from downloaded episodes
      _loadAdjacentEpisodesOffline();
      return;
    }

    try {
      final adjacentEpisodes = await _episodeNavigation.loadAdjacentEpisodes(
        context: context,
        metadata: targetMetadata,
      );

      if (mounted && _currentMetadata.globalKey == targetMetadata.globalKey && (attempt == null || attempt.isCurrent)) {
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

      // Aired watch order (Specials interleaved by air date) — the shared
      // episode order, so offline next/prev matches streaming, what "download
      // next N" selects, and the offline OnDeck list (#1416/#1414). Copy first
      // so the provider's cached list isn't reordered.
      final sorted = List<MediaItem>.from(episodes)..sort(compareEpisodesByWatchOrder);

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
