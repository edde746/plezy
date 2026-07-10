part of '../../video_player_screen.dart';

extension _VideoPlayerSeekingMethods on VideoPlayerScreenState {
  Future<void> _seekPlayback(Duration position) async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return;

    final target = clampSeekPosition(currentPlayer, position);
    if (_plexTranscodeSeekAction(currentPlayer, target) == PlexTranscodeSeekAction.nativeSeek) {
      await currentPlayer.seek(target);
      return;
    }

    await _restartPlexTranscodeAt(target);
  }

  /// Relative seek shared by the companion remote and the OS media-control
  /// skip commands, including the live-TV capture-buffer branch.
  Future<void> _seekRelative(Duration delta) async {
    final currentPlayer = player;
    if (currentPlayer == null) return;
    if (widget.isLive && _live.captureBuffer != null) {
      _liveSeek.seekBy(delta.inSeconds);
      return;
    }
    await _seekPlayback(currentPlayer.state.position + delta);
  }

  bool get _usesPlexVodTranscodeSeekPolicy {
    return _isTranscoding &&
        !widget.isLive &&
        !_isOfflinePlayback &&
        _currentMetadata.backend == MediaBackend.plex &&
        _selectedQualityPreset != TranscodeQualityPreset.original;
  }

  PlexTranscodeSeekAction _plexTranscodeSeekAction(Player currentPlayer, Duration target) {
    if (!_usesPlexVodTranscodeSeekPolicy) return PlexTranscodeSeekAction.nativeSeek;

    final state = currentPlayer.state;
    final action = resolvePlexTranscodeSeekAction(
      currentPosition: state.position,
      target: target,
      bufferRanges: state.bufferRanges,
      allowBufferedNativeSeek: _playerBackendLabel == 'mpv',
    );
    appLogger.d(
      'Plex transcode seek decision: action=${action.name}, '
      'position=${state.position.inSeconds}s, target=${target.inSeconds}s, '
      'buffer=${state.buffer.inSeconds}s, ranges=${state.bufferRanges.length}',
    );
    return action;
  }

  Future<void> _restartPlexTranscodeAt(Duration target) async {
    if (_playbackTransition != _PlaybackTransition.idle) return;

    appLogger.d('Restarting Plex transcode at ${target.inSeconds}s');
    _playbackTransition = _PlaybackTransition.restartingTranscode;
    _chromeController.show();

    final currentPlayer = player;
    if (currentPlayer == null) {
      _playbackTransition = _PlaybackTransition.idle;
      return;
    }

    final replacementMetadata = _currentMetadata.copyWith(viewOffsetMs: target.inMilliseconds);
    final shouldResumePlayback = _playbackIntentShouldPlay;
    final offlineWatchService = context.read<OfflineWatchSyncService>();
    final playbackResolver = PlaybackSourceResolver(
      serverManager: context.read<MultiServerProvider>().serverManager,
      database: context.read<AppDatabase>(),
    );

    try {
      final playbackContext = await playbackResolver.resolve(
        metadata: replacementMetadata,
        selectedMediaIndex: _effectiveSelectedMediaIndex,
        selectedMediaSourceId: _requestedMediaSourceId,
        offlineLibraryMode: false,
        qualityPreset: _selectedQualityPreset,
        selectedAudioStreamId: _selectedAudioStreamId,
        sessionIdentifier: _playbackSessionIdentifier,
        transcodeSessionId: _playbackTranscodeSessionId,
        // A transcode restart must stay on the server stream even when the
        // preset would normally prefer a downloaded copy.
        preferOffline: false,
      );
      if (!mounted || player != currentPlayer) return;
      final result = playbackContext.result;
      if (result.videoUrl == null) {
        throw PlaybackException(t.messages.fileInfoNotAvailable);
      }

      final session = PlaybackSession.fromContext(
        playbackContext,
        requestedQualityPreset: _selectedQualityPreset,
        requestedMediaSourceId: _requestedMediaSourceId,
      );

      final externalSubtitlePlan = _prepareExternalSubtitleOpenPlan(
        player: currentPlayer,
        externalSubtitles: result.externalSubtitles,
      );
      final shouldAutoPlay = shouldResumePlayback && externalSubtitlePlan.canStartBeforeTrackSetup;

      final didOpen = await _openMediaOnPlayer(
        player: currentPlayer,
        settingsService: SettingsService.instance,
        videoUrl: result.videoUrl!,
        isTranscoding: result.isTranscoding,
        isLocalMedia: result.usesLocalMedia,
        selectedVersion: result.selectedVersion,
        timing: _playbackOpenTiming(
          backend: replacementMetadata.backend,
          isTranscoding: result.isTranscoding,
          resumePosition: target,
          durationMs: replacementMetadata.durationMs,
        ),
        headers: playbackContext.streamHeaders,
        play: shouldAutoPlay,
        externalSubtitlesAtOpen: externalSubtitlePlan.subtitlesAtOpen,
        shouldContinue: () => mounted && player == currentPlayer,
        onOpened: () {
          // A pre-open failure leaves the previous session (and ids)
          // committed; the swap happens only once the player owns the
          // restarted stream.
          _currentMetadata = replacementMetadata;
          _commitPlaybackSession(session);
        },
      );
      if (!didOpen || !mounted || player != currentPlayer) return;

      _setPlayerState(() {});

      // The play session changed with the restarted transcode — rebind the
      // progress tracker so reports don't keep flowing against the dead
      // session ids. The item itself is unchanged, so the item-keyed
      // services (media-controls metadata, scrobblers) stay as they are.
      _progressTracker?.stopTracking();
      _progressTracker?.dispose();
      _progressTracker = null;
      _rebindProgressTracker(
        metadata: _currentMetadata,
        mediaClient: session.reportingClient,
        offlineWatchService: offlineWatchService,
        playSessionId: _playbackPlaySessionId,
        playMethod: _playbackPlayMethod,
        mediaInfo: _currentMediaInfo,
      );

      final trackManager = _trackManager;
      if (trackManager != null) {
        trackManager.metadata = _currentMetadata;
        trackManager.mediaInfo = _currentMediaInfo;
        trackManager.cacheExternalSubtitles(result.externalSubtitles);
        await _applyTracksAfterOpen(
          trackManager: trackManager,
          externalSubtitlePlan: externalSubtitlePlan,
          // A restart while paused must stay paused — selection is still
          // applied through the resume-skipped branch.
          shouldResumeAfterSubtitleLoad: () => shouldResumePlayback && mounted && player == currentPlayer,
          applySelectionWhenResumeSkipped: true,
        );
      }

      _updateMediaControlsPlaybackState();
    } catch (e, st) {
      appLogger.w('Failed to restart Plex transcode at ${target.inSeconds}s', error: e, stackTrace: st);
      if (mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    } finally {
      _playbackTransition = _PlaybackTransition.idle;
    }
  }
}
