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
        showChapterMarkersOnTimeline: _showChapterMarkersOnTimeline,
        seekTimeSmall: _seekTimeSmall,
        onSeekToPreviousChapter: _seekToPreviousChapter,
        onSeekToNextChapter: _seekToNextChapter,
        onSeekBackward: () => unawaited(_seekByTime(forward: false)),
        onSeekForward: () => unawaited(_seekByTime(forward: true)),
        onSeek: _throttledSeek,
        onSeekEnd: _finalizeSeek,
        onSeekRequested: widget.onSeekRequested,
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
        onLiveSeekBy: widget.onLiveSeekBy,
        onJumpToLive: widget.onJumpToLive,
        useDpadNavigation: useDpad,
        serverId: widget.metadata.serverId,
        showQueueTab: playbackState.isQueueActive,
        onQueueItemSelected: playbackState.isQueueActive ? _onQueueItemSelected : null,
        onCancelAutoHide: widget.chromeController.cancelAutoHide,
        onStartAutoHide: _startHideTimer,
        onSeekCompleted: widget.onSeekCompleted,
        onContentStripVisibilityChanged: (visible) {
          widget.chromeController.setContentStripVisible(visible);
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
      final client = context.getPlexClientForServer(ServerId(serverId));
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
        title: newTrack.displayTitle ?? newTrack.language ?? t.videoControls.downloadedSubtitle,
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

  /// Request a version, quality preset, audio stream, or source subtitle reload.
  /// The owning player screen decides how to apply it so controls do not own
  /// player lifecycle/navigation policy.
  Future<void> _switchVersionAndQuality({
    int? newMediaIndex,
    TranscodeQualityPreset? newPreset,
    int? newAudioStreamId,
    int? newSubtitleStreamId,
  }) async {
    final onPlaybackSourceChanged = widget.onPlaybackSourceChanged;
    if (onPlaybackSourceChanged == null) return;
    try {
      await onPlaybackSourceChanged(
        newMediaIndex: newMediaIndex,
        newPreset: newPreset,
        newAudioStreamId: newAudioStreamId,
        newSubtitleStreamId: newSubtitleStreamId,
      );
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }
}
