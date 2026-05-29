part of '../../video_player_screen.dart';

extension _VideoPlayerEpisodeNavigationMethods on VideoPlayerScreenState {
  Future<void> _playNext() async {
    if (!mounted) return;
    if (_nextEpisode == null || _isLoadingNext) return;

    _autoPlayTimer?.cancel();
    _dismissStillWatching();

    _notifyWatchTogetherMediaChange(metadata: _nextEpisode);

    _setPlayerState(() {
      _isLoadingNext = true;
      _showPlayNextDialog = false;
    });

    await _navigateToEpisode(_nextEpisode!);
  }

  Future<void> _playPrevious() async {
    if (_previousEpisode == null || _isLoadingPrevious) return;

    _notifyWatchTogetherMediaChange(metadata: _previousEpisode);

    _setPlayerState(() {
      _isLoadingPrevious = true;
    });

    await _navigateToEpisode(_previousEpisode!);
  }

  Future<void> _restartOrPlayPrevious() async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null || _isLoadingPrevious) return;

    if (!shouldRestartBeforePreviousItem(currentPlayer.state.position) && _previousEpisode != null) {
      await _playPrevious();
      return;
    }

    _autoPlayTimer?.cancel();
    _dismissStillWatching();

    _setPlayerState(() {
      _showPlayNextDialog = false;
      _completionTriggered = false;
    });

    final target = clampSeekPosition(currentPlayer, Duration.zero);
    await _seekPlayback(target);
    if (!mounted || currentPlayer != player) return;

    _notifyWatchTogetherSeek(target);
    _updateMediaControlsPlaybackState();
  }

  /// Navigates to a new episode, preserving playback state and track selections.
  /// When PiP is active, swaps the media source in-place to keep the PiP window alive.
  Future<void> _navigateToEpisode(MediaItem episodeMetadata) async {
    // PiP active: swap media in-place to keep the PiP window alive. The
    // swap path threads the neutral [MediaServerClient] through
    // [PlaybackInitializationService] and the lifecycle services, so it
    // works for both Plex and Jellyfin sessions.
    if (PipService().isPipActive.value && player != null) {
      await _swapEpisodeInPip(episodeMetadata);
      return;
    }

    // Set flag to skip orientation restoration in dispose()
    _isReplacingWithVideo = true;

    unawaited(DiscordRPCService.instance.stopPlayback());
    unawaited(TraktScrobbleService.instance.stopPlayback());
    unawaited(TrackerCoordinator.instance.stopPlayback());

    if (player == null) {
      if (mounted) {
        unawaited(
          navigateToVideoPlayer(
            context,
            metadata: episodeMetadata,
            usePushReplacement: true,
            isOffline: widget.isOffline,
          ),
        );
      }
      return;
    }

    // Capture current state atomically to avoid race conditions
    final currentPlayer = player;
    if (currentPlayer == null) {
      if (mounted) {
        unawaited(
          navigateToVideoPlayer(
            context,
            metadata: episodeMetadata,
            usePushReplacement: true,
            isOffline: widget.isOffline,
          ),
        );
      }
      return;
    }

    final currentAudioTrack = currentPlayer.state.track.audio;
    final currentSubtitleTrack = currentPlayer.state.track.subtitle;
    final currentSecondarySubtitleTrack = currentPlayer.state.track.secondarySubtitle;

    unawaited(currentPlayer.pause());
    await _sendStoppedProgressOnce();
    _progressTracker?.stopTracking();

    await disposePlayerForNavigation();

    if (mounted) {
      unawaited(
        navigateToVideoPlayer(
          context,
          metadata: episodeMetadata,
          preferredAudioTrack: currentAudioTrack,
          preferredSubtitleTrack: currentSubtitleTrack,
          preferredSecondarySubtitleTrack: currentSecondarySubtitleTrack,
          usePushReplacement: true,
          isOffline: widget.isOffline,
        ),
      );
    }
  }

  /// Swap to a new episode while keeping the player alive for PiP continuity.
  /// Reuses the existing mpv instance (and its Metal layer in PiP) and only
  /// reloads the media source + resets Dart-side services.
  Future<void> _swapEpisodeInPip(MediaItem episodeMetadata) async {
    _isSwappingEpisode = true;
    final currentPlayer = player!;
    final playbackGeneration = _beginPlaybackGeneration(isEpisodeSwap: true);
    final previousMetadata = _currentMetadata;

    final currentAudioTrack = currentPlayer.state.track.audio;
    final currentSubtitleTrack = currentPlayer.state.track.subtitle;
    final currentSecondarySubtitleTrack = currentPlayer.state.track.secondarySubtitle;

    // Capture context-dependent values before async gaps. The neutral
    // [PlaybackInitializationService] consumes [mediaClient] regardless of
    // backend. We still narrow to [plexClient] for [TrackManager]'s
    // server-side track persistence, which is Plex-only — Jellyfin
    // sessions get a null `getPlexClient` and skip that path.
    final offlineWatchService = context.read<OfflineWatchSyncService>();
    final userProfileProvider = context.read<UserProfileProvider>();
    final playbackState = context.read<PlaybackStateProvider>();
    final database = context.read<AppDatabase>();
    final serverManager = context.read<MultiServerProvider>().serverManager;

    await _sendStoppedProgressOnce();
    _progressTracker?.stopTracking();
    _progressTracker?.dispose();
    _progressTracker = null;
    unawaited(DiscordRPCService.instance.stopPlayback());
    unawaited(TraktScrobbleService.instance.stopPlayback());
    unawaited(TrackerCoordinator.instance.stopPlayback());

    if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;

    _currentMetadata = episodeMetadata;
    VideoPlayerScreenState._activeId = episodeMetadata.id;
    _showPlayNextDialog = false;
    _autoPlayTimer?.cancel();
    _hasFirstFrame.value = false;

    try {
      final playbackResolver = PlaybackSourceResolver(serverManager: serverManager, database: database);
      final playbackContext = await playbackResolver.resolve(
        metadata: episodeMetadata,
        selectedMediaIndex: widget.selectedMediaIndex,
        selectedMediaSourceId: widget.selectedMediaSourceId,
        offlineLibraryMode: widget.isOffline,
        qualityPreset: _selectedQualityPreset,
        selectedAudioStreamId: _selectedAudioStreamId,
        sessionIdentifier: _playbackSessionIdentifier,
        transcodeSessionId: _playbackTranscodeSessionId,
      );
      if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;
      final result = playbackContext.result;
      final mediaClient = playbackContext.reportingClient;
      final plexClient = mediaClient is PlexClient ? mediaClient : null;
      final streamHeaders = playbackContext.streamHeaders;

      if (result.videoUrl == null) {
        throw PlaybackException('No video URL available');
      }

      Duration? resumePosition;
      _isTranscoding = result.isTranscoding;
      _effectiveIsOffline = result.isOffline;
      _playbackContext = playbackContext;
      _playbackPlaySessionId = result.playSessionId;
      _playbackPlayMethod = result.playMethod;
      _selectedAudioStreamId = result.activeAudioStreamId;
      if (result.fallbackReason != null && !_selectedQualityPreset.isOriginal) {
        if (mounted) {
          showErrorSnackBar(context, t.videoControls.transcodeUnavailableFallback);
        }
        _selectedQualityPreset = TranscodeQualityPreset.original;
      }

      if (_isOfflinePlayback) {
        final localOffset = await offlineWatchService.getLocalViewOffset(episodeMetadata.globalKey);
        if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;
        if (localOffset != null && localOffset > 0) {
          resumePosition = Duration(milliseconds: localOffset);
        }
      }
      resumePosition ??= episodeMetadata.viewOffsetMs != null
          ? Duration(milliseconds: episodeMetadata.viewOffsetMs!)
          : null;

      final hasExternalSubs = result.externalSubtitles.isNotEmpty;
      final isExoPlayer = player is PlayerAndroid;
      final displayCriteria = result.mediaInfo?.displayCriteria;
      await currentPlayer.setDisplayCriteria(
        !result.isTranscoding && displayCriteria?.canPrimeNativeDisplayCriteria == true ? displayCriteria : null,
      );
      if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;
      final openTiming = _playbackOpenTiming(
        backend: episodeMetadata.backend,
        isTranscoding: result.isTranscoding,
        resumePosition: resumePosition,
        durationMs: episodeMetadata.durationMs,
      );
      await currentPlayer.setProperty('force-seekable', result.isTranscoding ? 'yes' : 'no');
      if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;
      await currentPlayer.open(
        Media(result.videoUrl!, start: openTiming.mediaStart, headers: result.usesLocalMedia ? null : streamHeaders),
        play: isExoPlayer || !hasExternalSubs,
        externalSubtitles: isExoPlayer && hasExternalSubs ? result.externalSubtitles : null,
        timelineOffset: openTiming.timelineOffset,
        timelineDuration: openTiming.timelineDuration,
      );

      if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;
      _completionTriggered = false;
      _isSwappingEpisode = false;

      _scrubPreviewSource?.dispose();
      _setPlayerState(() {
        _availableVersions = result.availableVersions;
        _currentMediaInfo = result.mediaInfo;
        _scrubPreviewSource = null;
        _isLoadingNext = false;
      });

      _trackManager?.dispose();
      final trackManager = TrackManager(
        player: currentPlayer,
        isActive: () => mounted && player != null,
        // Plex writes track changes immediately. Jellyfin persists selected
        // indexes through playback progress reports.
        persistTrackPreference: plexClient != null ? _plexTrackPersister(() => plexClient) : null,
        getProfileSettings: () => userProfileProvider.profileSettings,
        waitForProfileSettings: _waitForProfileSettingsIfNeeded,
        metadata: episodeMetadata,
        mediaInfo: _currentMediaInfo,
        preferredAudioTrack: currentAudioTrack,
        preferredSubtitleTrack: currentSubtitleTrack,
        preferredSecondarySubtitleTrack: currentSecondarySubtitleTrack,
        showMessage: (message, {duration}) {
          if (mounted) showAppSnackBar(context, message, duration: duration);
        },
      );
      _trackManager = trackManager;
      trackManager.cacheExternalSubtitles(result.externalSubtitles);

      if (player is! PlayerAndroid && hasExternalSubs) {
        trackManager.waitingForExternalSubsTrackSelection = true;
        try {
          await trackManager.addExternalSubtitles(result.externalSubtitles);
        } finally {
          await trackManager.resumeAfterSubtitleLoad();
        }
        if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;
      } else {
        trackManager.applyTrackSelectionWhenReady();
      }
      if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;

      // Same helper as the initial start flow, so any future change lands in
      // both paths together.
      _wirePerItemPlaybackServices(
        metadata: episodeMetadata,
        mediaClient: mediaClient,
        offlineWatchService: offlineWatchService,
        playSessionId: _playbackPlaySessionId,
        playMethod: _playbackPlayMethod,
        mediaInfo: _currentMediaInfo,
      );

      try {
        playbackState.setCurrentItem(episodeMetadata);
      } catch (e) {
        appLogger.d('playbackState.setCurrentItem failed', error: e);
      }

      await _loadAdjacentEpisodes();
      if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;

      if (_autoPipEnabled) {
        unawaited(_videoPIPManager?.updateAutoPipState(isPlaying: currentPlayer.state.playing));
      }
    } catch (e) {
      if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;
      _isSwappingEpisode = false;
      _completionTriggered = false;
      _currentMetadata = previousMetadata;
      VideoPlayerScreenState._activeId = previousMetadata.id;
      appLogger.e('Failed to swap episode in PiP', error: e);
    }
  }
}
