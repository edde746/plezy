part of '../video_controls.dart';

extension _PlexVideoControlsNavigationMethods on _PlexVideoControlsState {
  Widget _buildDesktopControlsListener() {
    final playbackState = context.watch<PlaybackStateProvider>();
    final trackControlsState = _buildTrackControlsState(
      playbackState: playbackState,
      onToggleAlwaysOnTop: Platform.isMacOS ? null : _toggleAlwaysOnTop,
    );
    final useDpad = playerDirectionalNavigationEnabled();

    return _holdChromeWhilePressed(
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

  Future<SubtitleDownloadApplyOutcome> _onDownloadSubtitle({
    required String serverId,
    required String ratingKey,
    required SubtitleSearchResult result,
    required bool Function() sheetIsOpen,
  }) async {
    var outcome = SubtitleDownloadApplyOutcome.notDownloaded; // what a request that throws comes to
    try {
      return outcome = await _downloadSubtitle(serverId: serverId, ratingKey: ratingKey, result: result);
    } finally {
      // The poll and the reload outlive a closed sheet: the player then says how the download ended,
      // unless something else took it over: a newer download, another item, or a playback restart during its reload.
      if (mounted && !sheetIsOpen() && outcome != SubtitleDownloadApplyOutcome.superseded) {
        showSubtitleDownloadOutcome(context, outcome);
      }
    }
  }

  Future<SubtitleDownloadApplyOutcome> _downloadSubtitle({
    required String serverId,
    required String ratingKey,
    required SubtitleSearchResult result,
  }) async {
    // Nothing is requested unless the item is still this one and can reload.
    if (!mounted) return SubtitleDownloadApplyOutcome.notDownloaded;
    if (widget.metadata.serverId != serverId || _subtitleItemId() != ratingKey) {
      return SubtitleDownloadApplyOutcome.notDownloaded;
    }
    final switchSource = widget.onPlaybackSourceChanged;
    if (switchSource == null) return SubtitleDownloadApplyOutcome.notDownloaded;

    final itemKey = widget.metadata.globalKey;
    // A newer download stops this poll: both would take a file that lands
    // after both requests for their own, and reload twice.
    final generation = ++_subtitleDownloadGeneration;
    bool targetIsCurrent() =>
        mounted &&
        generation == _subtitleDownloadGeneration &&
        widget.metadata.globalKey == itemKey &&
        widget.metadata.serverId == serverId &&
        _subtitleItemId() == ratingKey;

    final client = _subtitleSearchClient();
    if (client == null) return SubtitleDownloadApplyOutcome.notDownloaded;
    // A failed request throws: the sheet reports it, or the player once the sheet has closed.
    final findTrack = await client.downloadSubtitle(ratingKey, result, position: widget.player.state.position);
    if (findTrack == null) return SubtitleDownloadApplyOutcome.notDownloaded;

    try {
      // The server downloads asynchronously: the request returns immediately
      // but the new stream entry shows up in metadata seconds later. Poll until it
      // appears, for as long as the client says its server may take.
      final deadline = DateTime.now().add(client.subtitleDownloadTimeout);
      MediaSubtitleTrack? newTrack;

      while (mounted && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return SubtitleDownloadApplyOutcome.superseded;

        try {
          if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
          newTrack = await findTrack();
          if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
          if (newTrack != null) break;
        } catch (e) {
          appLogger.w('Subtitle download poll iteration failed', error: e);
          if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
        }
      }

      if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
      if (newTrack == null) return SubtitleDownloadApplyOutcome.timedOut;
      // Where the rescan keeps stream ids (Plex, which also selects the new
      // subtitle itself) the reload follows the id; where it renumbers them
      // (Jellyfin), the pick travels as the freshly read row instead.
      final choice = client.subtitleDownloadKeepsStreamIds
          ? PlaybackSourceSubtitleChoice.source(newTrack.id)
          : PlaybackSourceSubtitleChoice.downloaded(newTrack);
      final outcome = subtitleDownloadApplyOutcomeFor(await switchSource(newSubtitleChoice: choice));
      // The screen's next build shows any item that took over during the reload, and the subtitle the reload selected.
      await WidgetsBinding.instance.endOfFrame;
      if (!targetIsCurrent()) return SubtitleDownloadApplyOutcome.superseded;
      if (outcome != SubtitleDownloadApplyOutcome.applied) return outcome;
      return widget.selectedSubtitleChoice == choice ? outcome : SubtitleDownloadApplyOutcome.failed;
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
        showErrorSnackBar(context, t.messages.errorLoading(error: localizedErrorReason(e)));
      }
    }
  }
}
