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
    if (_isRestartingTranscodeSeek) return;

    appLogger.d('Restarting Plex transcode at ${target.inSeconds}s');
    _isRestartingTranscodeSeek = true;
    _controlsVisible.value = true;

    final currentPlayer = player;
    if (currentPlayer == null) {
      _isRestartingTranscodeSeek = false;
      return;
    }

    final replacementMetadata = _currentMetadata.copyWith(viewOffsetMs: target.inMilliseconds);
    final wasPlaying = currentPlayer.state.playing;
    final nextTranscodeSessionId = generateSessionIdentifier();

    try {
      final mediaClient = _getMediaServerClient(context);
      if (mediaClient == null) {
        throw StateError('No client registered for ${replacementMetadata.serverId}');
      }

      _playbackTranscodeSessionId = nextTranscodeSessionId;
      final playbackService = PlaybackInitializationService(client: mediaClient, database: context.read<AppDatabase>());
      final result = await playbackService.getPlaybackData(
        metadata: replacementMetadata,
        selectedMediaIndex: widget.selectedMediaIndex,
        selectedMediaSourceId: widget.selectedMediaSourceId,
        preferOffline: false,
        qualityPreset: _selectedQualityPreset,
        selectedAudioStreamId: _selectedAudioStreamId,
        sessionIdentifier: _playbackSessionIdentifier,
        transcodeSessionId: _playbackTranscodeSessionId,
      );
      if (!mounted || player != currentPlayer) return;
      if (result.videoUrl == null) {
        throw PlaybackException(t.messages.fileInfoNotAvailable);
      }

      _currentMetadata = replacementMetadata;
      _isTranscoding = result.isTranscoding;
      _effectiveIsOffline = result.isOffline;
      _playbackPlaySessionId = result.playSessionId;
      _playbackPlayMethod = result.playMethod;
      _selectedAudioStreamId = result.activeAudioStreamId;
      _availableVersions = result.availableVersions;
      _currentMediaInfo = result.mediaInfo;

      final isExoPlayer = currentPlayer is PlayerAndroid;
      final hasExternalSubs = result.externalSubtitles.isNotEmpty;
      final shouldAutoPlay = wasPlaying && (isExoPlayer || !hasExternalSubs);
      final timelineDuration = _currentMetadata.durationMs != null
          ? Duration(milliseconds: _currentMetadata.durationMs!)
          : null;

      await currentPlayer.setProperty('force-seekable', result.isTranscoding ? 'yes' : 'no');
      await currentPlayer.open(
        Media(result.videoUrl!, start: result.isTranscoding ? null : target, headers: _streamHeaders),
        play: shouldAutoPlay,
        externalSubtitles: isExoPlayer && hasExternalSubs ? result.externalSubtitles : null,
        timelineOffset: result.isTranscoding ? target : Duration.zero,
        timelineDuration: result.isTranscoding ? timelineDuration : null,
      );
      if (!mounted || player != currentPlayer) return;

      _setPlayerState(() {});

      final trackManager = _trackManager;
      if (trackManager != null) {
        trackManager.metadata = _currentMetadata;
        trackManager.mediaInfo = _currentMediaInfo;
        trackManager.cacheExternalSubtitles(result.externalSubtitles);
        if (currentPlayer is! PlayerAndroid && result.externalSubtitles.isNotEmpty) {
          trackManager.waitingForExternalSubsTrackSelection = true;
          await trackManager.addExternalSubtitles(result.externalSubtitles);
          if (wasPlaying && mounted && player == currentPlayer) {
            await trackManager.resumeAfterSubtitleLoad();
          } else {
            trackManager.waitingForExternalSubsTrackSelection = false;
            trackManager.applyTrackSelectionWhenReady();
          }
        } else {
          trackManager.applyTrackSelectionWhenReady();
        }
      }

      _updateMediaControlsPlaybackState();
    } catch (e, st) {
      appLogger.w('Failed to restart Plex transcode at ${target.inSeconds}s', error: e, stackTrace: st);
      if (mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    } finally {
      _isRestartingTranscodeSeek = false;
    }
  }
}
