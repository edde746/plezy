part of '../../video_player_screen.dart';

extension _VideoPlayerEpisodeNavigationMethods on VideoPlayerScreenState {
  void _clearEpisodeLoadingFlags() {
    if (!_isLoadingNext && !_isLoadingPrevious) return;
    _setPlayerState(() {
      _isLoadingNext = false;
      _isLoadingPrevious = false;
    });
  }

  /// Old screen-swap parity: after an in-place item change (or its failed
  /// rollback), surface the chrome and re-anchor focus on play/pause. The
  /// control that drove the swap (next button, queue item, play-next prompt)
  /// may have unmounted or unfocused by now — without a fresh route's
  /// autofocus, dpad navigation would be stranded until the chrome is hidden
  /// and re-shown. Focusing play/pause is invisible in pointer mode (focus
  /// visuals are keyboard/dpad-gated).
  void _showChromeForSwappedItem() {
    if (!mounted) return;
    _chromeController.show(focusTarget: PlayerChromeFocusTarget.playPause);
  }

  Future<void> _playNext() async {
    if (!mounted) return;
    if (_nextEpisode == null || _isLoadingNext) return;

    _autoPlayTimer?.cancel();
    _unfocusPlayNextPrompt();
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
    _unfocusPlayNextPrompt();
    _dismissStillWatching();

    _setPlayerState(() {
      _showPlayNextDialog = false;
      _completionLatch.reset();
    });

    final target = clampSeekPosition(currentPlayer, Duration.zero);
    await _seekPlayback(target);
    if (!mounted || currentPlayer != player) return;

    _notifyWatchTogetherSeek(target);
    _updateMediaControlsPlaybackState();
  }

  /// Replace this screen with a fresh player route — the fallback for flows
  /// the in-place reload cannot serve. Marks the screen as being replaced so
  /// dispose skips the app-level player-exit side effects the replacement
  /// route takes over (WT host-exit notify, sleep timer, system UI restore,
  /// display mode).
  Future<void> _replaceScreenWithPlayer(MediaItem metadata) async {
    _isReplacingWithVideo = true; // before any await — dispose can run mid-helper
    try {
      await navigateToVideoPlayer(
        context,
        metadata: metadata,
        usePushReplacement: true,
        isOffline: _offlineLibraryMode,
      );
    } finally {
      // Still mounted ⇒ no push happened (external-player branch or a
      // throw): this screen stays, so restore normal-exit semantics.
      if (mounted) {
        _isReplacingWithVideo = false;
        _clearEpisodeLoadingFlags();
      }
    }
  }

  /// Navigates to a new episode by reusing the current player whenever possible.
  Future<void> _navigateToEpisode(MediaItem episodeMetadata) async {
    if (player == null) {
      if (mounted) unawaited(_replaceScreenWithPlayer(episodeMetadata));
      return;
    }

    await _reloadMediaInPlace(
      metadata: episodeMetadata,
      selectedMediaIndex: _effectiveSelectedMediaIndex,
      selectedMediaSourceId: null,
      qualityPreset: _selectedQualityPreset,
      // Stream ids are per-part: the previous episode's audio id is
      // meaningless on the new item, so let preferences pick the track.
      useCurrentAudioStreamSelection: false,
      preserveCurrentTrackSelection: true,
      reason: 'episode navigation',
    );
  }

  Future<void> _switchPlaybackSource({
    int? newMediaIndex,
    TranscodeQualityPreset? newPreset,
    int? newAudioStreamId,
    int? newSubtitleStreamId,
  }) async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null || _playbackTransition != _PlaybackTransition.idle) return;

    final effectiveMediaIndex = newMediaIndex ?? _effectiveSelectedMediaIndex;
    final effectivePreset = newPreset ?? _selectedQualityPreset;
    final effectiveAudioStreamId = newAudioStreamId ?? _selectedAudioStreamId;
    final currentSubtitleStreamId = _selectedSourceSubtitleStreamIdForControls(_sourceSubtitleTracksForControls());
    final effectiveSubtitleStreamId = newSubtitleStreamId ?? currentSubtitleStreamId;
    final effectiveMediaSourceId = newMediaIndex != null
        ? PlaybackSession.mediaSourceIdForIndex(_availableVersions, effectiveMediaIndex) ?? _requestedMediaSourceId
        : _requestedMediaSourceId;

    final isVersionChange =
        effectiveMediaIndex != _effectiveSelectedMediaIndex ||
        (_requestedMediaSourceId != null && effectiveMediaSourceId != _requestedMediaSourceId);
    final isPresetChange = effectivePreset != _selectedQualityPreset;
    final isAudioChange = effectiveAudioStreamId != _selectedAudioStreamId;
    final isSubtitleChange = newSubtitleStreamId != null && effectiveSubtitleStreamId != currentSubtitleStreamId;
    if (!isVersionChange && !isPresetChange && !isAudioChange && !isSubtitleChange) return;

    // Read the client before any await — context across an async gap. A
    // missing client leaves this null and the guard below reports it.
    final serverId = _currentMetadata.serverId;
    PlexClient? subtitleClient;
    if (isSubtitleChange && serverId != null) {
      try {
        subtitleClient = context.getPlexClientForServer(ServerId(serverId));
      } catch (_) {}
    }

    try {
      if (isVersionChange) {
        await saveMediaVersionIndexFor(_currentMetadata, effectiveMediaIndex);
      }

      if (isSubtitleChange) {
        final partId = _currentMediaInfo?.partId;
        if (subtitleClient == null || partId == null || effectiveSubtitleStreamId == null) {
          throw StateError('No Plex part available for subtitle stream selection');
        }
        final saved = await subtitleClient.selectStreams(
          partId,
          subtitleStreamID: effectiveSubtitleStreamId,
          allParts: true,
        );
        if (!saved) {
          throw StateError('Failed to select subtitle stream');
        }
      }

      await _reloadMediaInPlace(
        metadata: _currentMetadata.copyWith(viewOffsetMs: currentPlayer.state.position.inMilliseconds),
        selectedMediaIndex: effectiveMediaIndex,
        selectedMediaSourceId: effectiveMediaSourceId,
        qualityPreset: effectivePreset,
        // A version change selects a different part, and stream ids are
        // per-part — only same-part switches may carry the current id.
        selectedAudioStreamId: isVersionChange ? newAudioStreamId : effectiveAudioStreamId,
        useCurrentAudioStreamSelection: !isVersionChange,
        resumePosition: currentPlayer.state.position,
        preserveCurrentTrackSelection: false,
        reason: 'source switch',
      );
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  /// Reload a VOD item/source while keeping the route, player instance, and
  /// native renderer alive. This is the common path for episode navigation,
  /// queue item jumps, Watch Together media switches, and source changes.
  Future<bool> _reloadMediaInPlace({
    required MediaItem metadata,
    int? selectedMediaIndex,
    String? selectedMediaSourceId,
    TranscodeQualityPreset? qualityPreset,
    int? selectedAudioStreamId,
    Duration? resumePosition,
    bool preserveCurrentTrackSelection = false,
    bool useCurrentAudioStreamSelection = true,
    String reason = 'media reload',
  }) async {
    if (widget.isLive) {
      _clearEpisodeLoadingFlags();
      return false;
    }
    final existingPlayer = player;
    if (!mounted || existingPlayer == null || _playbackTransition != _PlaybackTransition.idle) {
      if (mounted) _clearEpisodeLoadingFlags();
      return false;
    }

    _playbackTransition = _PlaybackTransition.reloadingMedia;
    final currentPlayer = player!;
    final attempt = _beginPlaybackAttempt(currentPlayer, isMediaReload: true);
    bool isCurrentReload() => attempt.isCurrent;

    // The session itself swaps atomically at the open boundary, so the only
    // rollback state is the eagerly-set identity (shown by the loading UI)
    // and the first-frame flag.
    final previousMetadata = _currentMetadata;
    final previousMediaIndex = _effectiveSelectedMediaIndex;
    final previousPartId = _currentMediaInfo?.partId;
    final previousHasFirstFrame = _hasFirstFrame.value;
    final isItemChange = previousMetadata.globalKey != metadata.globalKey;

    final currentAudioTrack = preserveCurrentTrackSelection ? currentPlayer.state.track.audio : null;
    final currentSubtitleTrack = preserveCurrentTrackSelection ? currentPlayer.state.track.subtitle : null;
    final currentSecondarySubtitleTrack = preserveCurrentTrackSelection
        ? currentPlayer.state.track.secondarySubtitle
        : null;
    final wasPlayingBeforeReload = currentPlayer.state.playing;
    var didOpenReplacement = false;

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
    // Cycle the Watch Together attachment across every reload: the reload's
    // internal pause/open churn must not leak into the sync layer as user
    // intents. Readiness re-handshakes on re-attach (item changes start a
    // new media epoch; same-item source switches group-wait while we
    // reload).
    final watchTogether = _activeWatchTogetherSession();
    final watchTogetherWasAttached = watchTogether?.hasAttachedPlayer ?? false;
    final cycleWatchTogetherAttachment = watchTogetherWasAttached;
    final wtOwnsStart = _watchTogetherOwnsPlaybackStart();

    if (!isCurrentReload()) return true;

    final targetMediaIndex = selectedMediaIndex ?? _effectiveSelectedMediaIndex;
    final targetQualityPreset = qualityPreset ?? _selectedQualityPreset;
    final targetAudioStreamId = useCurrentAudioStreamSelection
        ? selectedAudioStreamId ?? _selectedAudioStreamId
        : selectedAudioStreamId;
    // Eager identity-only: the loading UI shows the new title immediately,
    // while the selection/source state flips with the session commit at the
    // open boundary.
    _currentMetadata = metadata;
    VideoPlayerScreenState._activeId = metadata.id;
    VideoPlayerScreenState._activeMediaIndex = targetMediaIndex;
    _unfocusPlayNextPrompt();
    _showPlayNextDialog = false;
    _autoPlayTimer?.cancel();
    _hasFirstFrame.value = false;

    try {
      // Detach before pausing so the reload's internal pause can't broadcast
      // a party-wide pause; the finally below restores the attachment.
      if (cycleWatchTogetherAttachment) {
        watchTogether!.detachPlayer();
      }
      try {
        await currentPlayer.pause();
      } catch (e) {
        appLogger.w('Failed to pause before $reason', error: e);
      }
      if (!isCurrentReload()) return true;

      // Overlap the old item's stop report with the resolve round-trip; it
      // is awaited again right before the open below.
      final stoppedProgressFuture = _sendStoppedProgressOnce();

      final playbackResolver = PlaybackSourceResolver(serverManager: serverManager, database: database);
      final playbackContext = await playbackResolver.resolve(
        metadata: metadata,
        selectedMediaIndex: targetMediaIndex,
        selectedMediaSourceId: selectedMediaSourceId,
        offlineLibraryMode: _offlineLibraryMode,
        qualityPreset: targetQualityPreset,
        selectedAudioStreamId: targetAudioStreamId,
        sessionIdentifier: _playbackSessionIdentifier,
        transcodeSessionId: _playbackTranscodeSessionId,
      );
      if (!isCurrentReload()) return true;
      final result = playbackContext.result;
      final mediaClient = playbackContext.reportingClient;
      final plexClient = mediaClient is PlexClient ? mediaClient : null;
      final streamHeaders = playbackContext.streamHeaders;

      if (result.videoUrl == null) {
        throw PlaybackException('No video URL available');
      }

      // Build the replacement session now, commit it only once open()
      // succeeds — until then every session-derived getter still describes
      // the item that is actually playing.
      final session = PlaybackSession.fromContext(
        playbackContext,
        requestedQualityPreset: targetQualityPreset,
        requestedMediaSourceId: selectedMediaSourceId,
      );
      if (result.fallbackReason != null && !targetQualityPreset.isOriginal && mounted) {
        showErrorSnackBar(context, t.videoControls.transcodeUnavailableFallback);
      }

      final openResumePosition = await _resolveOpenResumePosition(
        metadata: metadata,
        isOffline: _offlineLibraryMode || result.isOffline,
        offlineWatchService: offlineWatchService,
        requested: resumePosition,
      );
      if (!isCurrentReload()) return true;

      final hasExternalSubs = result.externalSubtitles.isNotEmpty;
      final attachesSubsAtOpen = currentPlayer.attachesExternalSubtitlesAtOpen;
      final displayCriteria = result.mediaInfo?.displayCriteria;
      final settingsService = await SettingsService.getInstance();
      if (!isCurrentReload()) return true;

      // Same pre-open frame-rate orchestration as the initial start flow —
      // including the Android MPV startup decoder refresh, whose gate is
      // armed before open and released after track setup below.
      final frameRatePlan = await _prepareFrameRateForOpen(
        currentPlayer: currentPlayer,
        settingsService: settingsService,
        preKnownFps: displayCriteria?.fps,
        hasVideoUrl: true,
        ensureAudioFocus: () => currentPlayer.requestAudioFocus(),
      );
      if (frameRatePlan == null || !isCurrentReload()) return true;
      _frameRate.resetForNewItem();
      if (frameRatePlan.countsAsApplied) _frameRate.applied = true;

      await _primeDisplayCriteria(
        player: currentPlayer,
        settingsService: settingsService,
        displayCriteria: displayCriteria,
        isTranscoding: result.isTranscoding,
      );
      if (!isCurrentReload()) return true;
      final openTiming = _playbackOpenTiming(
        backend: metadata.backend,
        isTranscoding: result.isTranscoding,
        resumePosition: openResumePosition,
        durationMs: metadata.durationMs,
      );
      await stoppedProgressFuture;
      _progressTracker?.stopTracking();
      _progressTracker?.dispose();
      _progressTracker = null;
      unawaited(DiscordRPCService.instance.stopPlayback());
      unawaited(TraktScrobbleService.instance.stopPlayback());
      unawaited(TrackerCoordinator.instance.stopPlayback());
      if (!isCurrentReload()) return true;

      frameRatePlan.armStartupRefreshGate(currentPlayer);
      final didOpen = await _openMediaOnPlayer(
        player: currentPlayer,
        settingsService: settingsService,
        videoUrl: result.videoUrl!,
        isTranscoding: result.isTranscoding,
        // Not _isOfflinePlayback: the replacement session commits later, in
        // onOpened, so the getter still describes the previous item here.
        isLocalMedia: _offlineLibraryMode || result.usesLocalMedia,
        selectedVersion: result.selectedVersion,
        timing: openTiming,
        headers: result.usesLocalMedia ? null : streamHeaders,
        play: !frameRatePlan.holdPlaybackStart && !wtOwnsStart && (attachesSubsAtOpen || !hasExternalSubs),
        externalSubtitlesAtOpen: attachesSubsAtOpen && hasExternalSubs ? result.externalSubtitles : null,
        shouldContinue: isCurrentReload,
        onOpened: () {
          // The player now owns the new file — publish the session at the
          // same boundary so identity and source state flip together.
          didOpenReplacement = true;
          _commitPlaybackSession(session);
        },
      );
      if (!didOpen || !isCurrentReload()) return true;
      _completionLatch.reset();

      // Versions/mediaInfo come from the committed session; rebuild so the
      // controls pick them up. Same-part switches (quality/audio/subtitle)
      // keep the scrub-preview source — BIF/trickplay is per part, so a
      // reset would re-download identical bytes.
      final reusesScrubPreview =
          previousMetadata.globalKey == metadata.globalKey &&
          previousPartId != null &&
          previousPartId == result.mediaInfo?.partId;
      if (reusesScrubPreview) {
        _setPlayerState(() {});
      } else {
        _resetScrubPreviewForNewItem(metadata: metadata, mediaInfo: result.mediaInfo, mediaClient: mediaClient);
      }
      _clearEpisodeLoadingFlags();
      if (isItemChange) _showChromeForSwappedItem();

      _trackManager?.dispose();
      final trackManager = _buildTrackManager(
        forPlayer: currentPlayer,
        metadata: metadata,
        plexClient: plexClient,
        getProfileSettings: () => userProfileProvider.profileSettings,
        preferredAudioTrack: currentAudioTrack,
        preferredSubtitleTrack: currentSubtitleTrack,
        preferredSecondarySubtitleTrack: currentSecondarySubtitleTrack,
      );
      _trackManager = trackManager;
      trackManager.cacheExternalSubtitles(result.externalSubtitles);

      await _applyTracksAfterOpen(
        forPlayer: currentPlayer,
        trackManager: trackManager,
        externalSubtitles: result.externalSubtitles,
        // Same guard as the start path: don't resume a player a newer flow
        // owns, and let a pending startup gate (or Watch Together's group
        // start) own the resume instead.
        shouldResumeAfterSubtitleLoad: () =>
            !frameRatePlan.holdPlaybackStart && !wtOwnsStart && mounted && player == currentPlayer,
        applySelectionWhenResumeSkipped: wtOwnsStart && !frameRatePlan.holdPlaybackStart,
      );
      if (!isCurrentReload()) return true;

      await _releaseFrameRateStartupGate(
        currentPlayer: currentPlayer,
        settingsService: settingsService,
        plan: frameRatePlan,
        resumeAfterStartupGate: (reason) => _resumeAfterStartupGateOrYieldToWatchTogether(
          currentPlayer: currentPlayer,
          attachesSubsAtOpen: attachesSubsAtOpen,
          hasExternalSubs: hasExternalSubs,
          reason: reason,
          wtOwnsStart: wtOwnsStart,
        ),
      );
      if (!isCurrentReload()) return true;

      // Same helper as the initial start flow, so any future change lands in
      // both paths together.
      _wirePerItemPlaybackServices(
        metadata: metadata,
        mediaClient: mediaClient,
        offlineWatchService: offlineWatchService,
        playSessionId: _playbackPlaySessionId,
        playMethod: _playbackPlayMethod,
        mediaInfo: _currentMediaInfo,
      );

      try {
        playbackState.setCurrentItem(metadata);
      } catch (e) {
        appLogger.d('playbackState.setCurrentItem failed', error: e);
      }

      unawaited(_loadAdjacentEpisodes(metadata: metadata, attempt: attempt));
      if (!isCurrentReload()) return true;

      if (_autoPipEnabled) {
        unawaited(_videoPIPManager?.updateAutoPipState(isPlaying: currentPlayer.state.playing));
      }
      return true;
    } catch (e) {
      if (!isCurrentReload()) return true;
      _completionLatch.reset();
      if (!didOpenReplacement) {
        // Nothing was opened: the previous session is still committed, so
        // only the eagerly-set identity needs restoring before resuming.
        _currentMetadata = previousMetadata;
        VideoPlayerScreenState._activeId = previousMetadata.id;
        VideoPlayerScreenState._activeMediaIndex = previousMediaIndex;
        _hasFirstFrame.value = previousHasFirstFrame;
        // If the stop report already went out, un-latch the tracker so the
        // resumed session keeps reporting (and its eventual real stop sends).
        _progressTracker?.resumeAfterStoppedReport();
        if (wasPlayingBeforeReload && mounted && player == currentPlayer) {
          unawaited(currentPlayer.play());
        }
      } else if (_progressTracker == null && player == currentPlayer) {
        // The new file is playing and its session is committed — keep the
        // new identity and make sure progress reporting is wired to the
        // item actually on screen (the failure may have hit before
        // _wirePerItemPlaybackServices ran).
        _wirePerItemPlaybackServices(
          metadata: metadata,
          mediaClient: _playbackSession?.reportingClient,
          offlineWatchService: offlineWatchService,
          playSessionId: _playbackPlaySessionId,
          playMethod: _playbackPlayMethod,
          mediaInfo: _currentMediaInfo,
        );
      }
      // Unconditional setState — beyond the flags this also publishes the
      // rolled-back identity (_clearEpisodeLoadingFlags skips the rebuild
      // when no loading flags are set).
      _setPlayerState(() {
        _isLoadingNext = false;
        _isLoadingPrevious = false;
      });
      if (isItemChange) _showChromeForSwappedItem();
      appLogger.e('Failed to reload media in-place during $reason', error: e);
      if (mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
      return true;
    } finally {
      // Release the reload transition unless a newer flow already took
      // ownership (a non-reload attempt force-idles it; a newer reload can
      // then re-acquire it).
      if (attempt.isCurrent && _playbackTransition == _PlaybackTransition.reloadingMedia) {
        _playbackTransition = _PlaybackTransition.idle;
      }
      // Restore Watch Together sync on every exit: after a successful item
      // change (readiness re-handshakes for the new item), after a failed
      // reload (the still-playing old item must stay synced), and when the
      // controller auto-detached itself on a mid-reload player failure.
      // _currentMetadata is correct on both the success and rollback paths
      // by the time we get here.
      final reattachServerId = _currentMetadata.serverId;
      if (watchTogetherWasAttached &&
          watchTogether != null &&
          watchTogether.isInSession &&
          mounted &&
          player == currentPlayer &&
          reattachServerId != null &&
          !watchTogether.hasAttachedPlayer) {
        watchTogether.attachPlayer(
          currentPlayer,
          ratingKey: _currentMetadata.id,
          serverId: reattachServerId,
          mediaTitle: _currentMetadata.displayTitle,
          hasFirstFrame: _hasFirstFrame.value,
          remoteSeek: _seekPlayback,
        );
      }
    }
  }
}
