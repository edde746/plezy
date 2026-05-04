part of '../video_controls.dart';

extension _PlexVideoControlsNavigationMethods on _PlexVideoControlsState {
  Widget _buildDesktopControlsListener() {
    final playbackState = context.watch<PlaybackStateProvider>();
    final trackControlsState = _buildTrackControlsState(
      playbackState: playbackState,
      onToggleAlwaysOnTop: Platform.isMacOS ? null : _toggleAlwaysOnTop,
    );
    final useDpad = _videoPlayerNavigationEnabled || PlatformDetector.isTV();

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restartHideTimerIfPlaying(),
      child: DesktopVideoControls(
        key: _desktopControlsKey,
        player: widget.player,
        metadata: widget.metadata,
        onNext: widget.onNext,
        onPrevious: widget.onPrevious,
        chapters: _chapters,
        chaptersLoaded: _chaptersLoaded,
        seekTimeSmall: _seekTimeSmall,
        onSeekToPreviousChapter: _seekToPreviousChapter,
        onSeekToNextChapter: _seekToNextChapter,
        onSeekBackward: () => unawaited(_seekByTime(forward: false)),
        onSeekForward: () => unawaited(_seekByTime(forward: true)),
        onSeek: _throttledSeek,
        onSeekEnd: _finalizeSeek,
        getReplayIcon: getReplayIcon,
        getForwardIcon: getForwardIcon,
        onFocusActivity: _restartHideTimerIfPlaying,
        onHideControls: _hideControlsFromKeyboard,
        trackControlsState: trackControlsState,
        onBack: widget.onBack,
        hasFirstFrame: widget.hasFirstFrame,
        thumbnailDataBuilder: widget.thumbnailDataBuilder,
        liveChannelName: widget.liveChannelName,
        captureBuffer: widget.captureBuffer,
        isAtLiveEdge: widget.isAtLiveEdge,
        streamStartEpoch: widget.streamStartEpoch,
        currentPositionEpoch: widget.currentPositionEpoch,
        onLiveSeek: widget.onLiveSeek,
        onJumpToLive: widget.onJumpToLive,
        useDpadNavigation: useDpad,
        serverId: widget.metadata.serverId,
        showQueueTab: playbackState.isQueueActive,
        onQueueItemSelected: playbackState.isQueueActive ? _onQueueItemSelected : null,
        onCancelAutoHide: () => _hideTimer?.cancel(),
        onStartAutoHide: _startHideTimer,
        onSeekCompleted: widget.onSeekCompleted,
        onContentStripVisibilityChanged: (visible) {
          _setControlsState(() => _isContentStripVisible = visible);
          if (visible) {
            _hideTimer?.cancel();
          } else {
            _restartHideTimerIfPlaying();
          }
        },
      ),
    );
  }

  void _onQueueItemSelected(MediaItem item) {
    final videoPlayerState = context.findAncestorStateOfType<VideoPlayerScreenState>();
    videoPlayerState?.navigateToQueueItem(item);
  }

  Future<void> _onSubtitleDownloaded() async {
    if (!mounted) return;

    // Plex-only: the OpenSubtitles polling flow uses [getVideoPlaybackData]
    // and the Plex token. Jellyfin has no analogue and the entry point
    // (`subtitleSearchSupported`) is already gated on backend, but guard
    // here too in case a future caller wires the same handler elsewhere.
    if (widget.metadata.backend != MediaBackend.plex) return;
    final serverId = widget.metadata.serverId;
    if (serverId == null) return;

    try {
      final client = context.getPlexClientForServer(serverId);
      final token = client.config.token;
      if (token == null) return;

      // Plex's OpenSubtitles download is asynchronous: the PUT returns immediately
      // but the new stream entry shows up in metadata seconds later. Poll until it
      // appears. Up to 15s matches what Plex-web tolerates before giving up.
      // Snapshot what's already attached so we can identify the new download.
      final existingUris = widget.player.state.tracks.subtitle.where((t) => t.uri != null).map((t) => t.uri!).toSet();

      final deadline = DateTime.now().add(const Duration(seconds: 15));
      MediaSubtitleTrack? newTrack;
      String? newUrl;
      MediaSourceInfo? latestInfo;

      while (mounted && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;

        try {
          final data = await client.getVideoPlaybackData(widget.metadata.id);
          if (!mounted) return;
          if (data.mediaInfo == null) continue;
          latestInfo = data.mediaInfo;

          for (final plexTrack in data.mediaInfo!.subtitleTracks) {
            if (!plexTrack.isExternal) continue;
            final url = client.buildExternalSubtitleUrl(plexTrack);
            if (url == null) continue;
            if (existingUris.any((uri) => uri.contains(plexTrack.key!))) continue;

            newTrack = plexTrack;
            newUrl = url;
            break;
          }
          if (newTrack != null) break;
        } catch (e) {
          appLogger.w('Subtitle download poll iteration failed', error: e);
        }
      }

      if (!mounted || newTrack == null || newUrl == null) return;

      await widget.player.addSubtitleTrack(
        uri: newUrl,
        title: newTrack.displayTitle ?? newTrack.language ?? 'Downloaded',
        language: newTrack.languageCode,
        select: true,
      );

      final partId = latestInfo?.partId;
      if (partId != null) {
        await client.selectStreams(partId, subtitleStreamID: newTrack.id);
      }
    } catch (e) {
      appLogger.w('Failed to refresh subtitles after download', error: e);
    }
  }

  /// Switch version, quality preset, or audio stream ID. Any combination may
  /// change in one invocation; unspecified values retain their current value.
  /// Always routes through pushReplacement, preserving playback position and
  /// the transcode session identifiers.
  Future<void> _switchVersionAndQuality({
    int? newMediaIndex,
    TranscodeQualityPreset? newPreset,
    int? newAudioStreamId,
  }) async {
    final effectiveMediaIndex = newMediaIndex ?? widget.selectedMediaIndex;
    final effectivePreset = newPreset ?? widget.selectedQualityPreset;
    final effectiveAudioStreamId = newAudioStreamId ?? widget.selectedAudioStreamId;

    final isVersionChange = effectiveMediaIndex != widget.selectedMediaIndex;
    final isPresetChange = effectivePreset != widget.selectedQualityPreset;
    final isAudioChange = effectiveAudioStreamId != widget.selectedAudioStreamId;
    if (!isVersionChange && !isPresetChange && !isAudioChange) {
      return;
    }

    try {
      final currentPosition = widget.player.state.position;

      // Get state reference before async operations
      final videoPlayerState = context.findAncestorStateOfType<VideoPlayerScreenState>();

      if (isVersionChange) {
        final settingsService = await SettingsService.getInstance();
        final seriesKey = widget.metadata.grandparentId ?? widget.metadata.id;
        await settingsService.write(SettingsService.mediaVersionPreferences, {
          ...settingsService.read(SettingsService.mediaVersionPreferences),
          seriesKey: effectiveMediaIndex,
        });
      }

      // Preserve session identifiers across the reload so Plex reuses the
      // transcode session rather than spinning up a new one.
      final sessionId = videoPlayerState?.playbackSessionIdentifier;
      final transcodeSessionId = videoPlayerState?.playbackTranscodeSessionId;

      // Set flag on parent VideoPlayerScreen to skip orientation restoration
      videoPlayerState?.setReplacingWithVideo();
      // Dispose the existing player before spinning up the replacement to avoid race conditions
      await videoPlayerState?.disposePlayerForNavigation();

      // Navigate to new player screen with the updated selection
      // Use PageRouteBuilder with zero-duration transitions to prevent orientation reset
      if (mounted) {
        unawaited(
          Navigator.pushReplacement(
            context,
            PageRouteBuilder<bool>(
              pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
                metadata: widget.metadata.copyWith(viewOffsetMs: currentPosition.inMilliseconds),
                selectedMediaIndex: effectiveMediaIndex,
                selectedQualityPreset: effectivePreset,
                selectedAudioStreamId: effectiveAudioStreamId,
                reusedSessionIdentifier: sessionId,
                reusedTranscodeSessionId: transcodeSessionId,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }
}
