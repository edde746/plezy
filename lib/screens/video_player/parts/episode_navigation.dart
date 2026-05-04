part of '../../video_player_screen.dart';

extension _VideoPlayerEpisodeNavigationMethods on VideoPlayerScreenState {
  Future<void> _playNext() async {
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
            isOffline: _isOfflinePlayback,
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
            isOffline: _isOfflinePlayback,
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
          isOffline: _isOfflinePlayback,
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
    final previousMetadata = _currentMetadata;

    final currentAudioTrack = currentPlayer.state.track.audio;
    final currentSubtitleTrack = currentPlayer.state.track.subtitle;
    final currentSecondarySubtitleTrack = currentPlayer.state.track.secondarySubtitle;

    // Capture context-dependent values before async gaps. The neutral
    // [PlaybackInitializationService] consumes [mediaClient] regardless of
    // backend. We still narrow to [plexClient] for [TrackManager]'s
    // server-side track persistence, which is Plex-only — Jellyfin
    // sessions get a null `getPlexClient` and skip that path.
    final mediaClient = _isOfflinePlayback ? null : _getMediaServerClient(context);
    final plexClient = mediaClient is PlexClient ? mediaClient : null;
    final streamHeaders = mediaClient?.streamHeaders ?? const <String, String>{};
    final offlineWatchService = context.read<OfflineWatchSyncService>();
    final userProfileProvider = context.read<UserProfileProvider>();
    final playbackState = context.read<PlaybackStateProvider>();
    final database = context.read<AppDatabase>();

    await _sendStoppedProgressOnce();
    _progressTracker?.stopTracking();
    _progressTracker?.dispose();
    _progressTracker = null;
    unawaited(DiscordRPCService.instance.stopPlayback());
    unawaited(TraktScrobbleService.instance.stopPlayback());
    unawaited(TrackerCoordinator.instance.stopPlayback());

    _currentMetadata = episodeMetadata;
    VideoPlayerScreenState._activeId = episodeMetadata.id;
    _showPlayNextDialog = false;
    _autoPlayTimer?.cancel();
    _hasFirstFrame.value = false;

    try {
      // Same service shape works for both online (mediaClient non-null,
      // bundled video URL + media info) and pure-offline (mediaClient null,
      // local file + cached media info if available).
      final playbackService = PlaybackInitializationService(client: mediaClient, database: database);
      final result = await playbackService.getPlaybackData(
        metadata: episodeMetadata,
        selectedMediaIndex: widget.selectedMediaIndex,
        preferOffline: _isOfflinePlayback || _selectedQualityPreset.isOriginal,
        qualityPreset: _selectedQualityPreset,
        selectedAudioStreamId: _selectedAudioStreamId,
        sessionIdentifier: _playbackSessionIdentifier,
        transcodeSessionId: _playbackTranscodeSessionId,
      );

      if (result.videoUrl == null) {
        throw PlaybackException('No video URL available');
      }

      Duration? resumePosition;
      _isTranscoding = result.isTranscoding;
      _effectiveIsOffline = result.isOffline;
      _playbackPlaySessionId = result.playSessionId;
      _playbackPlayMethod = result.playMethod;
      if (result.activeAudioStreamId != null) {
        _selectedAudioStreamId = result.activeAudioStreamId;
      }
      if (result.fallbackReason != null && !_selectedQualityPreset.isOriginal) {
        if (mounted) {
          showErrorSnackBar(context, t.videoControls.transcodeUnavailableFallback);
        }
        _selectedQualityPreset = TranscodeQualityPreset.original;
      }

      if (_isOfflinePlayback) {
        final localOffset = await offlineWatchService.getLocalViewOffset(episodeMetadata.globalKey);
        if (localOffset != null && localOffset > 0) {
          resumePosition = Duration(milliseconds: localOffset);
        }
      }
      resumePosition ??= episodeMetadata.viewOffsetMs != null
          ? Duration(milliseconds: episodeMetadata.viewOffsetMs!)
          : null;

      final hasExternalSubs = result.externalSubtitles.isNotEmpty;
      final isExoPlayer = player is PlayerAndroid;
      await currentPlayer.open(
        Media(result.videoUrl!, start: resumePosition, headers: streamHeaders),
        play: isExoPlayer || !hasExternalSubs,
        externalSubtitles: isExoPlayer && hasExternalSubs ? result.externalSubtitles : null,
      );

      _completionTriggered = false;
      _isSwappingEpisode = false;

      if (!mounted) return;

      _scrubPreviewSource?.dispose();
      _setPlayerState(() {
        _availableVersions = result.availableVersions;
        _currentMediaInfo = result.mediaInfo;
        _scrubPreviewSource = null;
        _isLoadingNext = false;
      });

      _trackManager?.dispose();
      _trackManager = TrackManager(
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
      _trackManager!.cacheExternalSubtitles(result.externalSubtitles);

      if (player is! PlayerAndroid && hasExternalSubs) {
        _trackManager!.waitingForExternalSubsTrackSelection = true;
        try {
          await _trackManager!.addExternalSubtitles(result.externalSubtitles);
        } finally {
          await _trackManager!.resumeAfterSubtitleLoad();
        }
      } else {
        _trackManager!.applyTrackSelectionWhenReady();
      }

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

      if (_autoPipEnabled) {
        unawaited(_videoPIPManager?.updateAutoPipState(isPlaying: currentPlayer.state.playing));
      }
    } catch (e) {
      _isSwappingEpisode = false;
      _completionTriggered = false;
      _currentMetadata = previousMetadata;
      VideoPlayerScreenState._activeId = previousMetadata.id;
      appLogger.e('Failed to swap episode in PiP', error: e);
    }
  }
}
