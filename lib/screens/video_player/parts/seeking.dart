part of '../../video_player_screen.dart';

extension _VideoPlayerSeekingMethods on VideoPlayerScreenState {
  Future<void> _seekPlayback(Duration position) async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return;

    final target = clampSeekPosition(currentPlayer, position);
    if (!_shouldRestartPlexTranscodeForSeek) {
      await currentPlayer.seek(target);
      return;
    }

    if (_canSeekWithinCurrentTranscodeBuffer(currentPlayer, target)) {
      await currentPlayer.seek(target);
      return;
    }

    await _restartPlexTranscodeAt(target);
  }

  bool get _shouldRestartPlexTranscodeForSeek {
    return _isTranscoding &&
        !widget.isLive &&
        !_isOfflinePlayback &&
        _currentMetadata.backend == MediaBackend.plex &&
        _selectedQualityPreset != TranscodeQualityPreset.original;
  }

  bool _canSeekWithinCurrentTranscodeBuffer(Player currentPlayer, Duration target) {
    const edgeTolerance = Duration(milliseconds: 500);
    final targetMs = target.inMilliseconds;
    for (final range in currentPlayer.state.bufferRanges) {
      final startMs = range.start.inMilliseconds - edgeTolerance.inMilliseconds;
      final endMs = range.end.inMilliseconds - edgeTolerance.inMilliseconds;
      if (targetMs >= startMs && targetMs <= endMs) return true;
    }
    return false;
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
    final wasPlaying = currentPlayer.state.playing;
    final nextTranscodeSessionId = generateSessionIdentifier();
    final offlineWatchService = context.read<OfflineWatchSyncService>();
    final playbackResolver = PlaybackSourceResolver(
      serverManager: context.read<MultiServerProvider>().serverManager,
      database: context.read<AppDatabase>(),
    );

    try {
      _playbackTranscodeSessionId = nextTranscodeSessionId;
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

      final attachesSubsAtOpen = currentPlayer.attachesExternalSubtitlesAtOpen;
      final hasExternalSubs = result.externalSubtitles.isNotEmpty;
      final shouldAutoPlay = wasPlaying && (attachesSubsAtOpen || !hasExternalSubs);

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
        externalSubtitlesAtOpen: attachesSubsAtOpen && hasExternalSubs ? result.externalSubtitles : null,
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
          forPlayer: currentPlayer,
          trackManager: trackManager,
          externalSubtitles: result.externalSubtitles,
          // A restart while paused must stay paused — selection is still
          // applied through the resume-skipped branch.
          shouldResumeAfterSubtitleLoad: () => wasPlaying && mounted && player == currentPlayer,
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
