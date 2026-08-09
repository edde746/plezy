part of '../../video_player_screen.dart';

/// Keeps an explicit transcode subtitle choice pending while the native
/// player finishes discovering sidecars that were attached during open.
///
/// Returning true tells the source-switch caller that no media reload is
/// needed. [TrackManager] owns the generation-scoped late-track listener.
Future<bool> deferTranscodeSubtitleSelection({
  required TrackManager trackManager,
  required MediaSubtitleTrack sourceTrack,
  required PlaybackSubtitleSidecar sourceSidecar,
  required int sourceStreamId,
  required Future<void> Function(SubtitleTrack track, {int? sourceStreamId}) onSubtitleTrackChanged,
  required bool Function() shouldContinue,
}) async {
  final deferredTrack = PlaybackSubtitleResolver.subtitleTrackForSource(sourceTrack, sidecar: sourceSidecar);
  trackManager.preferredSubtitleTrack = SubtitlePreference.track(deferredTrack);
  // Persist first: the screen callback routes to onSubtitleTrackSelectedByUser,
  // which invalidates the pending selection. Arming before that would retire the
  // deferred pass we depend on to apply this choice once mpv discovers the sidecar.
  await onSubtitleTrackChanged(deferredTrack, sourceStreamId: sourceStreamId);
  // Persisting suspends, so the switch may have been superseded meanwhile.
  // Arming then would attach a listener belonging to an operation nobody is
  // waiting on any more.
  if (!shouldContinue()) return false;
  trackManager.applyTrackSelectionWhenReady();
  return true;
}

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
    if (!_canNavigateMediaItems()) return;
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
    if (!_canNavigateMediaItems()) return;
    if (_previousEpisode == null || _isLoadingPrevious) return;

    _notifyWatchTogetherMediaChange(metadata: _previousEpisode);

    _setPlayerState(() {
      _isLoadingPrevious = true;
    });

    await _navigateToEpisode(_previousEpisode!);
  }

  Future<void> _restartOrPlayPrevious() async {
    if (!_canNavigateMediaItems()) return;
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
    final currentPlayer = player;
    if (currentPlayer == null) {
      if (mounted) unawaited(_replaceScreenWithPlayer(episodeMetadata));
      return;
    }

    // Callers fire this without awaiting (auto-play countdown, PiP, the prompt), so an escaping
    // throw would be an unhandled async error that also strands the loading flag set by
    // _playNext — which then silently disables item navigation for the rest of the session.
    try {
      // Carry the playing version to the next episode by signature — its Media
      // list may order versions differently, so the bare index is a guess and
      // the source id is per-episode.
      final currentVersionSignature =
          _effectiveSelectedMediaIndex >= 0 && _effectiveSelectedMediaIndex < _availableVersions.length
          ? _availableVersions[_effectiveSelectedMediaIndex].signature
          : null;
      // Users who curate per-episode selections server-side (e.g. via Plex Auto
      // Languages) opt out of carrying tracks across episodes entirely: with no
      // preferences, both audio and subtitles start at the server-selected
      // priority (#1717).
      final settingsService = await SettingsService.getInstance();
      final followServerSelections = settingsService.read(SettingsService.followServerTrackSelections);
      final committedSubtitleSelection = _playbackSession?.subtitleSelection;
      final primarySubtitlePreference = followServerSelections
          ? null
          : subtitlePreferenceForItemChange(
              hasCommittedSelection: committedSubtitleSelection != null,
              committedTrack: committedSubtitleSelection?.primaryTrack,
              nativeTrack: currentPlayer.state.track.subtitle,
              declinedPreference: committedSubtitleSelection?.declinedPreference,
              sessionPreference: _sessionSubtitlePreference,
            );
      final secondarySubtitlePreference = followServerSelections
          ? null
          : subtitlePreferenceForItemChange(
              hasCommittedSelection: committedSubtitleSelection != null,
              committedTrack: committedSubtitleSelection?.secondaryTrack,
              nativeTrack: currentPlayer.state.track.secondarySubtitle,
              sessionPreference: _sessionSecondarySubtitlePreference,
            );
      await _reloadMediaInPlace(
        metadata: episodeMetadata,
        selectedMediaIndex: _effectiveSelectedMediaIndex,
        selectedMediaSourceId: null,
        preferredVersionSignature: currentVersionSignature,
        qualityPreset: _selectedQualityPreset,
        // Stream ids are per-part: the previous episode's audio id is
        // meaningless on the new item, so let preferences pick the track.
        useCurrentAudioStreamSelection: false,
        preserveCurrentTrackSelection: !followServerSelections,
        preservedAudioTrack: _sessionAudioPreference,
        preservedSubtitleTrack: primarySubtitlePreference,
        preservedSecondarySubtitleTrack: secondarySubtitlePreference,
        reason: 'episode navigation',
      );
    } catch (e, stackTrace) {
      appLogger.e('Failed to navigate to the next item', error: e, stackTrace: stackTrace);
      _clearEpisodeLoadingFlags();
      if (mounted) showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
    }
  }

  Future<PlaybackSourceChangeOutcome> _switchPlaybackSource({
    int? newMediaIndex,
    TranscodeQualityPreset? newPreset,
    int? newAudioStreamId,
    PlaybackSourceSubtitleChoice? newSubtitleChoice,
  }) async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return PlaybackSourceChangeOutcome.unavailable;
    if (widget.isLive) return PlaybackSourceChangeOutcome.unavailable;
    final transitionLease = _tryAcquirePlaybackTransition(_PlaybackTransition.switchingSource);
    if (transitionLease == null) return PlaybackSourceChangeOutcome.busy;
    try {
      return await _performPlaybackSourceSwitch(
        currentPlayer: currentPlayer,
        transitionLease: transitionLease,
        newMediaIndex: newMediaIndex,
        newPreset: newPreset,
        newAudioStreamId: newAudioStreamId,
        newSubtitleChoice: newSubtitleChoice,
      );
    } finally {
      _releasePlaybackTransition(transitionLease);
    }
  }

  Future<PlaybackSourceChangeOutcome> _performPlaybackSourceSwitch({
    required Player currentPlayer,
    required _PlaybackTransitionLease transitionLease,
    int? newMediaIndex,
    TranscodeQualityPreset? newPreset,
    int? newAudioStreamId,
    PlaybackSourceSubtitleChoice? newSubtitleChoice,
  }) async {
    bool isCurrentSourceSwitch() =>
        mounted &&
        player == currentPlayer &&
        _ownsPlaybackTransition(transitionLease, expected: _PlaybackTransition.switchingSource);
    bool sourceSwitchWasSuperseded() => !mounted || player != currentPlayer || transitionLease.wasSuperseded;
    void rememberSourceAudioPreference() {
      final streamId = newAudioStreamId;
      final mediaInfo = _currentMediaInfo;
      if (streamId == null || mediaInfo == null) return;
      for (final row in mediaInfo.audioTracks) {
        if (row.id == streamId) {
          _sessionAudioPreference = PlaybackSubtitleResolver.audioTrackForSource(row);
          return;
        }
      }
    }

    void rememberSourceSubtitlePreference() {
      final choice = newSubtitleChoice;
      final mediaInfo = _currentMediaInfo;
      if (choice == null || mediaInfo == null) return;
      // The local-switch path records through the screen's remember chain;
      // this covers picks that had to reload, whose resolved outcome never
      // reaches _rememberNativeSubtitleSelectionForSlot.
      final preference = sessionPreferenceForSourceSubtitleChoice(choice, mediaInfo.subtitleTracks);
      if (preference != null) _sessionSubtitlePreference = preference;
    }

    // Snapshot the backend client before subtitle selection can cross an
    // async boundary or the profile-scoped context can disappear.
    final serverId = _currentMetadata.serverId;
    final isPlexBacked = _currentMetadata.backend == MediaBackend.plex;
    PlexClient? streamSelectClient;
    if (isPlexBacked && serverId != null) {
      try {
        streamSelectClient = context.getPlexClientForServer(ServerId(serverId));
      } catch (_) {}
    }

    if (newSubtitleChoice != null && newMediaIndex == null && newPreset == null && newAudioStreamId == null) {
      try {
        final selected = await _selectSourceSubtitleLocally(
          currentPlayer,
          newSubtitleChoice,
          shouldContinue: isCurrentSourceSwitch,
        );
        if (!isCurrentSourceSwitch()) return PlaybackSourceChangeOutcome.superseded;
        if (selected) {
          return PlaybackSourceChangeOutcome.applied;
        }
      } catch (e) {
        if (sourceSwitchWasSuperseded()) return PlaybackSourceChangeOutcome.superseded;
        if (mounted) {
          showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
        }
        return PlaybackSourceChangeOutcome.failed;
      }
    }

    final effectiveMediaIndex = newMediaIndex ?? _effectiveSelectedMediaIndex;
    final effectivePreset = newPreset ?? _selectedQualityPreset;
    final effectiveAudioStreamId = newAudioStreamId ?? _selectedAudioStreamId;
    final currentSubtitleChoice = _selectedSourceSubtitleChoiceForControls(_sourceSubtitleTracksForControls());
    final preferredSubtitleTrackForReload = newSubtitleChoice == null
        ? SubtitlePreference.trackOrNull(_playbackSession?.subtitleSelection.primaryTrack)
        : newSubtitleChoice.isOff
        ? const SubtitlePreference.off()
        : SubtitlePreference.trackOrNull(
            PlaybackSubtitleResolver.preferredTrackForSource(_currentMediaInfo, newSubtitleChoice.sourceStreamId!),
          );
    final effectiveMediaSourceId = newMediaIndex != null
        ? PlaybackSession.mediaSourceIdForIndex(_availableVersions, effectiveMediaIndex) ?? _requestedMediaSourceId
        : _requestedMediaSourceId;

    final isVersionChange =
        effectiveMediaIndex != _effectiveSelectedMediaIndex ||
        (_requestedMediaSourceId != null && effectiveMediaSourceId != _requestedMediaSourceId);
    final isPresetChange = effectivePreset != _selectedQualityPreset;
    final isAudioChange = effectiveAudioStreamId != _selectedAudioStreamId;
    final isSubtitleChange = newSubtitleChoice != null && newSubtitleChoice != currentSubtitleChoice;
    if (!isVersionChange && !isPresetChange && !isAudioChange && !isSubtitleChange) {
      rememberSourceAudioPreference();
      rememberSourceSubtitlePreference();
      return PlaybackSourceChangeOutcome.unchanged;
    }

    try {
      if (isVersionChange) {
        await saveMediaVersionPreferenceFor(_currentMetadata, index: effectiveMediaIndex, versions: _availableVersions);
        if (!isCurrentSourceSwitch()) return PlaybackSourceChangeOutcome.superseded;
      }

      if ((isSubtitleChange && isPlexBacked) || (isAudioChange && isPlexBacked)) {
        final partId = _currentMediaInfo?.partId;
        if (streamSelectClient == null || partId == null) {
          throw StateError('No Plex part available for stream selection');
        }
        final saved = await streamSelectClient.selectStreams(
          partId,
          audioStreamID: isAudioChange ? effectiveAudioStreamId : null,
          // Plex's wire API uses 0 for Off. Keep that convention at this
          // backend boundary so it cannot collide with Jellyfin source ids.
          subtitleStreamID: isSubtitleChange
              ? newSubtitleChoice.isOff
                    ? 0
                    : newSubtitleChoice.sourceStreamId
              : null,
          allParts: true,
        );
        if (!saved) {
          throw StateError('Failed to select streams');
        }
        if (!isCurrentSourceSwitch()) return PlaybackSourceChangeOutcome.superseded;
      }

      final outcome = await _reloadMediaInPlace(
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
        preferredSubtitleTrackOverride: preferredSubtitleTrackForReload,
        transitionLease: transitionLease,
        reason: 'source switch',
      );
      if (outcome == _MediaReloadOutcome.opened) {
        rememberSourceAudioPreference();
        rememberSourceSubtitlePreference();
      }
      return switch (outcome) {
        _MediaReloadOutcome.opened => PlaybackSourceChangeOutcome.applied,
        _MediaReloadOutcome.rejected => PlaybackSourceChangeOutcome.busy,
        _MediaReloadOutcome.superseded => PlaybackSourceChangeOutcome.superseded,
        _MediaReloadOutcome.failed => PlaybackSourceChangeOutcome.failed,
      };
    } catch (e) {
      // A normal switchingSource -> reloadingMedia phase advance (and the
      // reload's eventual release) does not mean this operation was replaced.
      // Only an explicit force-idle/new playback generation supersedes the
      // lease; real errors after an owned phase change must remain failures.
      if (sourceSwitchWasSuperseded()) return PlaybackSourceChangeOutcome.superseded;
      if (mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
      return PlaybackSourceChangeOutcome.failed;
    }
  }

  Future<bool> _selectSourceSubtitleLocally(
    Player currentPlayer,
    PlaybackSourceSubtitleChoice choice, {
    required bool Function() shouldContinue,
  }) async {
    if (choice.isOff) {
      await currentPlayer.selectSecondarySubtitleTrack(SubtitleTrack.off);
      if (!shouldContinue()) return false;
      _onSecondarySubtitleTrackChanged(SubtitleTrack.off);
      await currentPlayer.selectSubtitleTrack(SubtitleTrack.off);
      if (!shouldContinue()) return false;
      await _onSubtitleTrackChanged(SubtitleTrack.off);
      return true;
    }

    final sourceStreamId = choice.sourceStreamId!;
    final info = _currentMediaInfo;
    if (info == null) return false;
    MediaSubtitleTrack? sourceTrack;
    for (final candidate in info.subtitleTracks) {
      if (candidate.id == sourceStreamId) {
        sourceTrack = candidate;
        break;
      }
    }
    if (sourceTrack == null) return false;

    final nativeTracks = currentPlayer.state.tracks.subtitle;
    final session = _playbackSession;
    final sourceSidecar = session == null ? null : _sidecarForSourceStreamId(session, sourceStreamId);
    final nativeTrack = PlaybackSubtitleResolver.nativeTrackForSource(
      sourceTrack: sourceTrack,
      nativeTracks: nativeTracks,
      allSourceTracks: info.subtitleTracks,
      isResolvedSidecar: sourceSidecar != null,
      isContainerSidecar: sourceSidecar?.track.isContainer == true,
      currentSourceStreamId: session?.subtitleSelection.primarySourceStreamId,
      selectedNativeTrack: currentPlayer.state.track.subtitle,
    );
    if (nativeTrack == null) {
      final trackManager = _trackManager;
      if (!_isTranscoding || sourceSidecar == null || trackManager == null) return false;

      return deferTranscodeSubtitleSelection(
        trackManager: trackManager,
        sourceTrack: sourceTrack,
        sourceSidecar: sourceSidecar,
        sourceStreamId: sourceStreamId,
        onSubtitleTrackChanged: _onSubtitleTrackChanged,
        shouldContinue: shouldContinue,
      );
    }

    await currentPlayer.selectSubtitleTrack(nativeTrack);
    if (!shouldContinue()) return false;
    await _onSubtitleTrackChanged(nativeTrack, sourceStreamId: sourceStreamId);
    return true;
  }

  /// Reload a VOD item/source while keeping the route, player instance, and
  /// native renderer alive. This is the common path for episode navigation,
  /// queue item jumps, Watch Together media switches, and source changes.
  ///
  /// [preservedAudioTrack]/[preservedSubtitleTrack]/
  /// [preservedSecondarySubtitleTrack] override the live player state when
  /// [preserveCurrentTrackSelection] is set — for callers whose player no
  /// longer holds the selections (the TV background suspend stops the native
  /// player, which clears its track state, before the reload runs).
  ///
  /// [startPaused] keeps the reloaded item paused: open() starts held, and
  /// every post-open resume point (subtitle-load resume, frame-rate gate
  /// release) arms track selection without playing, the same way a Watch
  /// Together-owned start does. The caller owns starting playback.
  ///
  /// The returned [_MediaReloadOutcome] tells the caller what actually
  /// happened: only [_MediaReloadOutcome.failed] means the previous session
  /// is still on screen with its (possibly dead) stream; user feedback for
  /// failures is shown here unless [showErrorUi] is false.
  Future<_MediaReloadOutcome> _reloadMediaInPlace({
    required MediaItem metadata,
    int? selectedMediaIndex,
    String? selectedMediaSourceId,
    String? preferredVersionSignature,
    TranscodeQualityPreset? qualityPreset,
    int? selectedAudioStreamId,
    Duration? resumePosition,
    bool preserveCurrentTrackSelection = false,
    AudioTrack? preservedAudioTrack,
    SubtitlePreference? preservedSubtitleTrack,
    SubtitlePreference? preservedSecondarySubtitleTrack,
    SubtitlePreference? preferredSubtitleTrackOverride,
    bool startPaused = false,
    bool useCurrentAudioStreamSelection = true,
    bool showErrorUi = true,
    _PlaybackTransitionLease? transitionLease,
    String reason = 'media reload',
  }) async {
    if (widget.isLive) {
      _clearEpisodeLoadingFlags();
      return _MediaReloadOutcome.rejected;
    }
    final existingPlayer = player;
    if (!mounted || existingPlayer == null) {
      if (mounted) _clearEpisodeLoadingFlags();
      return _MediaReloadOutcome.rejected;
    }

    final reloadLease = transitionLease == null
        ? _tryAcquirePlaybackTransition(_PlaybackTransition.reloadingMedia)
        : _advancePlaybackTransition(
            transitionLease,
            _PlaybackTransition.reloadingMedia,
            expected: _PlaybackTransition.switchingSource,
          )
        ? transitionLease
        : null;
    if (reloadLease == null) {
      _clearEpisodeLoadingFlags();
      return _MediaReloadOutcome.rejected;
    }

    try {
      final currentPlayer = existingPlayer;
      final attempt = _beginPlaybackAttempt(currentPlayer, isMediaReload: true);
      bool isCurrentReload() => attempt.isCurrent && !_hasFatalPlaybackError && !_isExiting.value;

      // The session itself swaps atomically at the open boundary, so the only
      // rollback state is the eagerly-set identity (shown by the loading UI)
      // and the first-frame flag.
      final previousMetadata = _currentMetadata;
      final previousLaunchIdentity = VideoPlayerScreenState._activeRouteGuard.identityFor(this);
      final previousPartId = _currentMediaInfo?.partId;
      final previousMediaSourceId = _currentMediaInfo?.mediaSourceId;
      final previousHasFirstFrame = _hasFirstFrame.value;
      final previousHasRenderedFirstFrame = _hasRenderedFirstFrame;
      final previousHasFatalPlaybackError = _hasFatalPlaybackError;
      _hasFatalPlaybackError = false;
      final isItemChange = previousMetadata.globalKey != metadata.globalKey;

      final currentAudioTrack = preserveCurrentTrackSelection
          ? preservedAudioTrack ?? currentPlayer.state.track.audio
          : null;
      final currentSubtitleTrack =
          preferredSubtitleTrackOverride ??
          (preserveCurrentTrackSelection
              ? preservedSubtitleTrack ?? SubtitlePreference.trackOrNull(currentPlayer.state.track.subtitle)
              : null);
      final currentSecondarySubtitleTrack = preserveCurrentTrackSelection
          ? preservedSecondarySubtitleTrack ??
                SubtitlePreference.trackOrNull(currentPlayer.state.track.secondarySubtitle)
          : null;
      final wasPlayingBeforeReload = _playbackIntentShouldPlay;
      var didOpenReplacement = false;

      // Capture context-dependent values before async gaps. The neutral
      // [PlaybackInitializationService] consumes [mediaClient] regardless of
      // backend. We still narrow to [plexClient] for [TrackManager]'s
      // server-side track persistence, which is Plex-only — Jellyfin
      // sessions get a null `getPlexClient` and skip that path.
      late final OfflineWatchSyncService offlineWatchService;
      late final UserProfileProvider userProfileProvider;
      late final PlaybackStateProvider playbackState;
      late final AppDatabase database;
      late final MultiServerManager serverManager;
      late final WatchTogetherProvider? watchTogether;
      late final bool watchTogetherWasAttached;
      late final bool cycleWatchTogetherAttachment;
      late final bool wtOwnsStart;
      try {
        offlineWatchService = context.read<OfflineWatchSyncService>();
        userProfileProvider = context.read<UserProfileProvider>();
        playbackState = context.read<PlaybackStateProvider>();
        database = context.read<AppDatabase>();
        serverManager = context.read<MultiServerProvider>().serverManager;
        // Cycle the Watch Together attachment across every reload: the
        // reload's internal pause/open churn must not leak into the sync layer
        // as user intents. Readiness re-handshakes on re-attach (item changes
        // start a new media epoch; same-item source switches group-wait while
        // we reload).
        watchTogether = _activeWatchTogetherSession();
        watchTogetherWasAttached = watchTogether?.hasAttachedPlayer ?? false;
        cycleWatchTogetherAttachment = watchTogetherWasAttached;
        wtOwnsStart = _watchTogetherOwnsPlaybackStart();
      } catch (e, stackTrace) {
        appLogger.e('Failed to prepare media reload during $reason', error: e, stackTrace: stackTrace);
        if (mounted && showErrorUi) {
          showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
        }
        _clearEpisodeLoadingFlags();
        return _MediaReloadOutcome.failed;
      }

      final shouldAutoStart = shouldAutoStartReloadedMedia(
        wasPlayingBeforeReload: wasPlayingBeforeReload,
        watchTogetherOwnsStart: wtOwnsStart,
        startPaused: startPaused,
      );

      if (!isCurrentReload()) return _MediaReloadOutcome.superseded;

      final targetMediaIndex = selectedMediaIndex ?? _effectiveSelectedMediaIndex;
      final targetQualityPreset = qualityPreset ?? _selectedQualityPreset;
      final targetAudioStreamId = useCurrentAudioStreamSelection
          ? selectedAudioStreamId ?? _selectedAudioStreamId
          : selectedAudioStreamId;
      final targetLaunchIdentity = VideoPlayerLaunchIdentity(
        metadata: metadata,
        mediaIndex: targetMediaIndex,
        selectedMediaSourceId: selectedMediaSourceId,
        selectedQualityPreset: targetQualityPreset,
        isOffline: _offlineLibraryMode,
        routeKind: VideoPlayerRouteKind.vod,
      );
      final preservesRequestedSubtitleSource =
          !isItemChange &&
          targetMediaIndex == _effectiveSelectedMediaIndex &&
          (selectedMediaSourceId == null || selectedMediaSourceId == previousMediaSourceId);
      final initializationSubtitleTrack = preservesRequestedSubtitleSource
          ? currentSubtitleTrack
          : SubtitlePreference.demoteToIntent(currentSubtitleTrack);
      // Same boundary rule for audio: native and Jellyfin stream ids are
      // reused per item, so a cross-source carry keeps only its semantics —
      // an identity match against a reused id would latch by ordinal and
      // bypass the evidence bands' ambiguity decline.
      final initializationAudioTrack = preservesRequestedSubtitleSource || currentAudioTrack == null
          ? currentAudioTrack
          : itemAgnosticAudioCarry(currentAudioTrack);
      try {
        // Eager identity-only: the loading UI shows the new title immediately,
        // while the selection/source state flips with the session commit at
        // the open boundary. Keep these writes inside the rollback boundary.
        _currentMetadata = metadata;
        VideoPlayerScreenState._activeRouteGuard.update(this, targetLaunchIdentity);
        _unfocusPlayNextPrompt();
        _showPlayNextDialog = false;
        _autoPlayTimer?.cancel();
        _hasFirstFrame.value = false;

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
        if (!isCurrentReload()) return _MediaReloadOutcome.superseded;

        // Local resume lookup can overlap the old stop, but source resolution
        // below must not: Plex can use that stop to terminate any new
        // transcode sharing this playback session identifier.
        final stoppedProgressFuture = _sendStoppedProgressOnce();

        var openResumePosition = await _resolveOpenResumePosition(
          metadata: metadata,
          isOffline: _offlineLibraryMode,
          offlineWatchService: offlineWatchService,
          requested: resumePosition,
        );
        if (!isCurrentReload()) return _MediaReloadOutcome.superseded;

        final playbackResolver = PlaybackSourceResolver(serverManager: serverManager, database: database);
        await stoppedProgressFuture;
        if (!isCurrentReload()) return _MediaReloadOutcome.superseded;
        final playbackContext = await playbackResolver.resolve(
          PlaybackInitializationOptions(
            metadata: metadata,
            selectedMediaIndex: targetMediaIndex,
            selectedMediaSourceId: selectedMediaSourceId,
            preferredVersionSignature: preferredVersionSignature,
            qualityPreset: targetQualityPreset,
            selectedAudioStreamId: targetAudioStreamId,
            preferredAudioTrack: initializationAudioTrack,
            preferredSubtitleTrack: initializationSubtitleTrack,
            sessionIdentifier: _playbackSessionIdentifier,
            transcodeSessionId: _playbackTranscodeSessionId,
            transcodeOffset: openResumePosition,
          ),
          offlineLibraryMode: _offlineLibraryMode,
        );
        if (!isCurrentReload()) return _MediaReloadOutcome.superseded;
        final result = playbackContext.result;
        final mediaClient = playbackContext.reportingClient;
        final plexClient = mediaClient is PlexClient ? mediaClient : null;
        final streamHeaders = playbackContext.streamHeaders;

        if (result.videoUrl == null) {
          throw PlaybackException('No video URL available');
        }
        if (result.isOffline && !_offlineLibraryMode) {
          // The pre-resolve lookup assumed an online source; a download won
          // instead, so consult locally tracked progress after all.
          openResumePosition = await _resolveOpenResumePosition(
            metadata: metadata,
            isOffline: true,
            offlineWatchService: offlineWatchService,
            requested: resumePosition,
          );
          if (!isCurrentReload()) return _MediaReloadOutcome.superseded;
        }
        var subtitleSelection = await _resolveSubtitleSelectionForOpen(
          metadata: metadata,
          result: result,
          preferredAudioTrack: initializationAudioTrack,
          preferredSubtitleTrack: currentSubtitleTrack,
          preferredSecondarySubtitleTrack: currentSecondarySubtitleTrack,
          preserveSubtitleSourceIdentity:
              result.mediaInfo != null &&
              ((previousMediaSourceId != null && previousMediaSourceId == result.mediaInfo!.mediaSourceId) ||
                  (previousPartId != null && previousPartId == result.mediaInfo!.partId)),
        );
        if (!isCurrentReload()) return _MediaReloadOutcome.superseded;

        // Build the replacement session now, commit it only once open()
        // succeeds — until then every session-derived getter still describes
        // the item that is actually playing.
        var session = PlaybackSession.fromContext(
          playbackContext,
          requestedQualityPreset: targetQualityPreset,
          requestedMediaSourceId: selectedMediaSourceId,
          subtitleSelection: subtitleSelection,
        );
        if (result.fallbackReason != null && !targetQualityPreset.isOriginal && mounted) {
          showErrorSnackBar(context, t.videoControls.transcodeUnavailableFallback);
        }

        final displayCriteria = result.mediaInfo?.displayCriteria;
        final settingsService = await SettingsService.getInstance();
        if (!isCurrentReload()) return _MediaReloadOutcome.superseded;

        // Same pre-open frame-rate orchestration as the initial start flow —
        // including the Android MPV startup decoder refresh, whose gate is
        // armed before open and released after track setup below.
        final frameRatePlan = await _prepareFrameRateForOpen(
          currentPlayer: currentPlayer,
          settingsService: settingsService,
          preKnownFps: displayCriteria?.fps,
          preKnownWidth: displayCriteria?.width ?? 0,
          preKnownHeight: displayCriteria?.height ?? 0,
          hasVideoUrl: true,
          isTranscoding: result.isTranscoding,
          ensureAudioFocus: () => currentPlayer.requestAudioFocus(),
        );
        if (frameRatePlan == null || !isCurrentReload()) {
          return _MediaReloadOutcome.superseded;
        }
        _frameRate.resetForNewItem();
        if (frameRatePlan.countsAsApplied) _frameRate.applied = true;

        await _primeDisplayCriteria(
          player: currentPlayer,
          settingsService: settingsService,
          displayCriteria: displayCriteria,
          isTranscoding: result.isTranscoding,
        );
        if (!isCurrentReload()) return _MediaReloadOutcome.superseded;
        final openTiming = _playbackOpenTiming(
          isTranscoding: result.isTranscoding,
          resumePosition: openResumePosition,
          durationMs: metadata.durationMs,
        );
        _progressTracker?.stopTracking();
        _progressTracker?.dispose();
        _progressTracker = null;
        unawaited(DiscordRPCService.instance.stopPlayback());
        unawaited(TrackerCoordinator.instance.stopPlayback());
        if (!isCurrentReload()) return _MediaReloadOutcome.superseded;

        // Generation invalidation prevents follow-on selection calls, but a
        // native audio/subtitle/rate mutation may already have been
        // dispatched. Drain exactly that captured operation before reusing
        // the player for replacement media, otherwise its late completion can
        // mutate the replacement item's tracks.
        await attempt.trackMutationDrain;
        if (!isCurrentReload()) return _MediaReloadOutcome.superseded;

        frameRatePlan.armStartupRefreshGate(currentPlayer);
        final externalSubtitlePlan = _prepareExternalSubtitleOpenPlan(
          player: currentPlayer,
          externalSubtitles: subtitleSelection.sidecarsAtOpen,
        );
        var effectiveExternalSubtitlePlan = externalSubtitlePlan;
        await _awaitTranscodeReadiness(
          client: mediaClient,
          isTranscoding: result.isTranscoding,
          videoUrl: result.videoUrl!,
        );
        if (!isCurrentReload()) return _MediaReloadOutcome.superseded;
        final openResult = await _openMediaOnPlayer(
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
          // The vehicle is not consulted here: `_openMediaOnPlayer` reads it at the `player.open`
          // itself, which is after this and its own awaited tuning work.
          play: shouldAutoStart && !frameRatePlan.holdPlaybackStart && externalSubtitlePlan.canStartBeforeTrackSetup,
          externalSubtitlesAtOpen: externalSubtitlePlan.subtitlesAtOpen,
          shouldContinue: isCurrentReload,
          onOpening: () {
            _hasRenderedFirstFrame = false;
            // 503s observed from here on belong to the replacement open.
            _http503Watchdog.disarm();
          },
          onOpened: () {
            // The player now owns the new file — publish the session at the
            // same boundary so identity and source state flip together.
            didOpenReplacement = true;
            _commitPlaybackSession(session);
          },
        );
        // A false didOpen means shouldContinue stopped the sequence pre-open
        // (open failures throw into the catch below) — superseded either way.
        if (!openResult.didOpen || !isCurrentReload()) {
          return _MediaReloadOutcome.superseded;
        }
        if (openResult.sidecarFallbackUsed) {
          session = _commitSidecarFallbackSession(session);
          subtitleSelection = session.subtitleSelection;
          effectiveExternalSubtitlePlan = _prepareExternalSubtitleOpenPlan(
            player: currentPlayer,
            externalSubtitles: const [],
          );
        }
        _completionLatch.reset();
        if (isItemChange) {
          // Same-item reloads (including the spurious-EOF recovery itself and
          // quality switches) keep the spent budget — that is the loop guard.
          _spuriousEofRecoveryAttempts = 0;
          _spuriousEofRecoveryBaselineMs = null;
        }

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
          preferredAudioTrack: initializationAudioTrack,
          // A declined carry stays alive for the native passes: freezing the
          // resolver's off verdict here would turn a metadata mismatch into a
          // navigation-priority off that no late track can undo (#1785).
          preferredSubtitleTrack:
              subtitleSelection.declinedPreference ?? SubtitlePreference.trackOrNull(subtitleSelection.primaryTrack),
          preferredSecondarySubtitleTrack: SubtitlePreference.trackOrNull(subtitleSelection.secondaryTrack),
        );
        _trackManager = trackManager;
        trackManager.cacheExternalSubtitles(subtitleSelection.sidecarsAtOpen);

        final resumeForStartupFrame =
            shouldAutoStart && frameRatePlan.needsStartupRefresh && effectiveExternalSubtitlePlan.requiresPostOpenAdd;
        await _applyTracksAfterOpen(
          trackManager: trackManager,
          externalSubtitlePlan: effectiveExternalSubtitlePlan,
          // Same guard as the start path: don't resume a player a newer flow
          // owns, and let a pending startup gate (or Watch Together's group
          // start) own the resume instead. Post-open external-subtitle paths
          // resume once here so the startup refresh gate can observe a frame.
          shouldResumeAfterSubtitleLoad: () =>
              shouldAutoStart &&
              (!frameRatePlan.holdPlaybackStart || resumeForStartupFrame) &&
              mounted &&
              player == currentPlayer,
          applySelectionWhenResumeSkipped: !shouldAutoStart && !frameRatePlan.holdPlaybackStart,
        );
        if (!isCurrentReload()) return _MediaReloadOutcome.superseded;

        await _releaseFrameRateStartupGate(
          currentPlayer: currentPlayer,
          settingsService: settingsService,
          plan: frameRatePlan,
          // Paused reloads use the same no-resume branch as an externally
          // coordinated start: track selection is armed without manufacturing
          // a new play intent.
          resumeAfterStartupGate: (reason) => _finishPlaybackAfterStartupGate(
            currentPlayer: currentPlayer,
            externalSubtitlePlan: effectiveExternalSubtitlePlan,
            reason: reason,
            shouldResume: shouldAutoStart,
            watchTogetherOwnsStart: wtOwnsStart,
          ),
          playbackResumedForStartupFrame: resumeForStartupFrame,
        );
        if (!isCurrentReload()) return _MediaReloadOutcome.superseded;

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

        _setPlayerState(() {
          _nextEpisode = null;
          _previousEpisode = null;
          _nextEpisodeStatus = QueueNavigationStatus.failed;
        });

        try {
          playbackState.setCurrentItem(metadata);
        } catch (e) {
          appLogger.d('playbackState.setCurrentItem failed', error: e);
        }

        unawaited(_loadAdjacentEpisodes(metadata: metadata, attempt: attempt));
        if (!isCurrentReload()) return _MediaReloadOutcome.superseded;

        if (_autoPipEnabled) {
          unawaited(_updateAutoPipState(isPlaying: currentPlayer.state.playing));
        }
        return _MediaReloadOutcome.opened;
      } catch (e) {
        if (!isCurrentReload()) return _MediaReloadOutcome.superseded;
        _completionLatch.reset();
        if (!didOpenReplacement) {
          // Nothing was opened: the previous session is still committed, so
          // only the eagerly-set identity needs restoring before resuming.
          _currentMetadata = previousMetadata;
          if (previousLaunchIdentity != null) {
            VideoPlayerScreenState._activeRouteGuard.update(this, previousLaunchIdentity);
          }
          _hasFirstFrame.value = previousHasFirstFrame;
          _hasRenderedFirstFrame = previousHasRenderedFirstFrame;
          _hasFatalPlaybackError = previousHasFatalPlaybackError;
          // If the stop report already went out, un-latch the tracker so the
          // resumed session keeps reporting (and its eventual real stop sends).
          _progressTracker?.resumeAfterStoppedReport();
          if (wasPlayingBeforeReload && mounted && player == currentPlayer) {
            unawaited(_playWithPlaybackIntent(currentPlayer));
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
        if (mounted && showErrorUi) {
          showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
        }
        return didOpenReplacement ? _MediaReloadOutcome.opened : _MediaReloadOutcome.failed;
      } finally {
        // Restore Watch Together sync on every exit: after a successful item
        // change (readiness re-handshakes for the new item), after a failed
        // reload (the still-playing old item must stay synced), and when the
        // controller auto-detached itself on a mid-reload player failure.
        // _currentMetadata is correct on both the success and rollback paths
        // by the time we get here.
        try {
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
        } catch (e, stackTrace) {
          // Playback has already reached a definitive opened/failed outcome;
          // a best-effort sync reattach must not rewrite it or escape through
          // the source-switch error classifier.
          appLogger.w('Failed to reattach Watch Together after $reason', error: e, stackTrace: stackTrace);
        }
      }
    } finally {
      // Cover setup as well as async playback work: context/provider reads can
      // throw before the operational try/catch is entered. Identity ownership
      // prevents this continuation from releasing a newer transition.
      _releasePlaybackTransition(reloadLease);
      // Every superseded return leaves the episode loading flags set otherwise, and
      // _playNext/_playPrevious treat them as a re-entrancy guard — a stuck flag turns the
      // Next button into a no-op for the rest of the session. Idempotent: the success and
      // rollback paths above have already cleared them, and this skips the rebuild when
      // neither flag is set.
      _clearEpisodeLoadingFlags();
    }
  }
}
