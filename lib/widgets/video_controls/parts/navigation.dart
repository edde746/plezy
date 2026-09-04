part of '../video_controls.dart';

extension _PlexVideoControlsNavigationMethods on _PlexVideoControlsState {
  Widget _buildDesktopControlsListener() {
    final playbackState = context.watch<PlaybackStateProvider>();
    final trackControlsState = _buildTrackControlsState(
      playbackState: playbackState,
      onToggleAlwaysOnTop: Platform.isMacOS ? null : _toggleAlwaysOnTop,
    );
    final useDpad = playerDirectionalNavigationEnabled();

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restartHideTimerForCurrentPlaybackState(),
      child: DesktopVideoControls(
        key: _desktopControlsKey,
        player: widget.player,
        volumeController: widget.volumeController,
        metadata: widget.metadata,
        onNext: _abandoningBurst(widget.onNext),
        onPrevious: _abandoningBurst(widget.onPrevious),
        onPlayPause: () => unawaited(_playOrPause()),
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
        onScrubStart: _holdTimelineScrub,
        onScrubEnd: _releaseTimelineScrub,
        onSeekRequested: widget.onSeekRequested,
        getReplayIcon: getReplayIcon,
        getForwardIcon: getForwardIcon,
        onFocusActivity: _restartHideTimerForCurrentPlaybackState,
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
        onLiveSeek: _liveSeekAbandoningBurst(widget.onLiveSeek),
        onLiveSeekBy: widget.onLiveSeekBy,
        onJumpToLive: _abandoningBurst(widget.onJumpToLive),
        useDpadNavigation: useDpad,
        serverId: widget.metadata.serverId,
        showQueueTab: playbackState.isQueueActive && widget.canNavigateMediaItems,
        onQueueItemSelected: playbackState.isQueueActive && widget.canNavigateMediaItems ? _onQueueItemSelected : null,
        onCancelAutoHide: widget.chromeController.cancelAutoHide,
        onStartAutoHide: _startHideTimer,
        onSeekCompleted: widget.onSeekCompleted,
        onContentStripVisibilityChanged: (visible) {
          widget.chromeController.setContentStripVisible(visible);
        },
        chromeController: widget.chromeController,
      ),
    );
  }

  void _onQueueItemSelected(MediaItem item) {
    // Same contract as next/previous: the switch is asynchronous, so a burst
    // still armed here would debounce into a seek on the outgoing item.
    _hiddenSeek.cancel();
    _desktopControlsKey.currentState?.abandonPendingSeek();
    _dismissSkipFeedback();
    final videoPlayerState = context.findAncestorStateOfType<VideoPlayerScreenState>();
    videoPlayerState?.navigateToQueueItem(item);
  }

  Future<SubtitleDownloadApplyOutcome> _onSubtitleDownloaded({
    required String serverId,
    required String ratingKey,
  }) async {
    if (!mounted) return SubtitleDownloadApplyOutcome.unavailable;

    // Plex-only: the OpenSubtitles polling flow uses [getVideoPlaybackData]
    // and the Plex token. Jellyfin has no analogue and the entry point
    // (`subtitleSearchSupported`) is already gated on backend, but guard
    // here too in case a future caller wires the same handler elsewhere.
    if (widget.metadata.backend != MediaBackend.plex) return SubtitleDownloadApplyOutcome.unavailable;
    if (widget.metadata.serverId != serverId || widget.metadata.id != ratingKey) {
      return SubtitleDownloadApplyOutcome.superseded;
    }
    final switchSource = widget.onPlaybackSourceChanged;
    if (switchSource == null) return SubtitleDownloadApplyOutcome.unavailable;

    final itemKey = widget.metadata.globalKey;
    bool targetIsCurrent() =>
        mounted &&
        widget.metadata.globalKey == itemKey &&
        widget.metadata.serverId == serverId &&
        widget.metadata.id == ratingKey;

    try {
      final client = context.getPlexClientForServer(ServerId(serverId));

      // Plex's OpenSubtitles download is asynchronous: the PUT returns immediately
      // but the new stream entry shows up in metadata seconds later. Poll until it
      // appears. Up to 15s matches what Plex-web tolerates before giving up.
      // Snapshot the authoritative source IDs so we can identify the new
      // download without asking mpv to synchronously open its remote URL.
      final existingSourceIds = widget.sourceSubtitleTracks.map((track) => track.id).toSet();

      final deadline = DateTime.now().add(const Duration(seconds: 15));
      MediaSubtitleTrack? newTrack;

      while (mounted && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return SubtitleDownloadApplyOutcome.superseded;

        try {
          if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
          // forceRefresh: playback start left a fresh /library/metadata row in
          // the cache (and each network poll would re-stamp it), so a
          // cache-eligible read here would never observe the new stream.
          final data = await client.getVideoPlaybackData(ratingKey, forceRefresh: true);
          if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
          if (data.mediaInfo == null) continue;

          newTrack = findNewExternalSubtitleTrack(data.mediaInfo!.subtitleTracks, existingSourceIds);
          if (newTrack != null) break;
        } catch (e) {
          appLogger.w('Subtitle download poll iteration failed', error: e);
          if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
        }
      }

      if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
      if (newTrack == null) return SubtitleDownloadApplyOutcome.timedOut;
      final outcome = await switchSource(newSubtitleChoice: PlaybackSourceSubtitleChoice.source(newTrack.id));
      return subtitleDownloadApplyOutcomeFor(outcome);
    } catch (e) {
      appLogger.w('Failed to refresh subtitles after download', error: e);
      return SubtitleDownloadApplyOutcome.failed;
    }
  }

  /// Request a version, quality preset, audio stream, or source subtitle reload.
  /// The owning player screen decides how to apply it so controls do not own
  /// player lifecycle/navigation policy.
  Future<void> _switchVersionAndQuality({
    int? newMediaIndex,
    TranscodeQualityPreset? newPreset,
    int? newAudioStreamId,
    PlaybackSourceSubtitleChoice? newSubtitleChoice,
  }) async {
    final onPlaybackSourceChanged = widget.onPlaybackSourceChanged;
    if (onPlaybackSourceChanged == null) return;
    try {
      await onPlaybackSourceChanged(
        newMediaIndex: newMediaIndex,
        newPreset: newPreset,
        newAudioStreamId: newAudioStreamId,
        newSubtitleChoice: newSubtitleChoice,
      );
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }
}
