part of '../video_controls.dart';

extension _VideoControlsNavigationMethods on _PlexVideoControlsState {
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
        liveEpochForPosition: widget.liveEpochForPosition,
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
    String? preferredLanguageCode,
  }) async {
    if (!mounted) return SubtitleDownloadApplyOutcome.unavailable;
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
      final client = context.getMediaClientForServer(ServerId(serverId));
      final expectedDownloadedStreamId = await client.consumeDownloadedSubtitleStreamId(
        ratingKey,
        mediaIndex: widget.selectedMediaIndex,
      );

      if (expectedDownloadedStreamId != null) {
        final immediateOutcome = await switchSource(
          newSubtitleChoice: PlaybackSourceSubtitleChoice.source(expectedDownloadedStreamId),
        );
        final mappedImmediateOutcome = subtitleDownloadApplyOutcomeFor(immediateOutcome);
        if (mappedImmediateOutcome == SubtitleDownloadApplyOutcome.applied) {
          try {
            final tracksAfterImmediateApply = await client.fetchSourceSubtitleTracks(
              ratingKey,
              mediaIndex: widget.selectedMediaIndex,
            );
            final selectedNow = tracksAfterImmediateApply.any(
              (track) => track.id == expectedDownloadedStreamId && track.selected,
            );
            if (selectedNow) {
              return mappedImmediateOutcome;
            }
          } catch (e) {
            appLogger.w('Failed to verify immediate subtitle apply state', error: e);
          }
        }
      }

      // Server-side subtitle download is asynchronous: apply polls until the
      // new stream appears on the active media source.
      // Snapshot the authoritative source IDs so we can identify the new
      // download without asking mpv to synchronously open its remote URL.
      final existingSourceIds = widget.sourceSubtitleTracks.map((track) => track.id).toSet();
      final currentSelectedSourceId = widget.selectedSubtitleChoice?.isOff == false
          ? widget.selectedSubtitleChoice?.sourceStreamId
          : null;

      final deadline = DateTime.now().add(const Duration(seconds: 15));
      MediaSubtitleTrack? newTrack;

      while (mounted && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return SubtitleDownloadApplyOutcome.superseded;

        try {
          if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
          final tracks = await client.fetchSourceSubtitleTracks(ratingKey, mediaIndex: widget.selectedMediaIndex);
          if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
          if (expectedDownloadedStreamId != null) {
            final exactMatch = tracks.where((track) => track.id == expectedDownloadedStreamId).toList(growable: false);
            if (exactMatch.isNotEmpty) {
              newTrack = exactMatch.firstWhere((track) => track.isExternalFile, orElse: () => exactMatch.first);
              break;
            }

            final retryOutcome = await switchSource(
              newSubtitleChoice: PlaybackSourceSubtitleChoice.source(expectedDownloadedStreamId),
            );
            final mappedRetryOutcome = subtitleDownloadApplyOutcomeFor(retryOutcome);
            if (mappedRetryOutcome == SubtitleDownloadApplyOutcome.applied) {
              // A reload may settle before the refreshed source-track view marks
              // the downloaded stream selected. Keep polling until selection is
              // observable to avoid reporting a false success.
              continue;
            }
          }
          newTrack = findDownloadedExternalSubtitleTrack(
            tracks,
            existingSourceIds,
            preferredLanguageCode: preferredLanguageCode,
            currentSelectedSourceId: currentSelectedSourceId,
          );
          if (newTrack != null) break;
        } catch (e) {
          appLogger.w('Subtitle download poll iteration failed', error: e);
          if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
        }
      }

      if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
      if (newTrack == null) return SubtitleDownloadApplyOutcome.timedOut;
      final outcome = await switchSource(newSubtitleChoice: PlaybackSourceSubtitleChoice.source(newTrack.id));
      final mappedOutcome = subtitleDownloadApplyOutcomeFor(outcome);
      if (mappedOutcome != SubtitleDownloadApplyOutcome.applied) return mappedOutcome;
      if (client.backend != MediaBackend.plex) return mappedOutcome;

      final expectedSelectedStreamId = expectedDownloadedStreamId ?? newTrack.id;
      for (var attempt = 0; attempt < 4; attempt++) {
        if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
        try {
          final tracks = await client.fetchSourceSubtitleTracks(
            ratingKey,
            mediaIndex: widget.selectedMediaIndex,
          );
          if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
          final selectedNow = tracks.any(
            (track) => track.id == expectedSelectedStreamId && track.selected,
          );
          if (selectedNow) return mappedOutcome;
        } catch (e) {
          appLogger.w('Failed to verify downloaded subtitle selection state', error: e);
        }
        if (attempt < 3) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      return SubtitleDownloadApplyOutcome.timedOut;
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
