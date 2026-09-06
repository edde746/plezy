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

/// The screen's in-place media transition engine: source/quality/audio/
/// subtitle switches and full item reloads that reuse the live player
/// instead of pushing a new route. Shared by episode navigation, lifecycle
/// restore, spurious-EOF recovery, Watch Together, and the companion remote.
extension _VideoPlayerReloadMethods on VideoPlayerScreenState {
  Future<PlaybackSourceChangeOutcome> _switchPlaybackSource({
    int? newMediaIndex,
    TranscodeQualityPreset? newPreset,
    int? newAudioStreamId,
    PlaybackSourceSubtitleChoice? newSubtitleChoice,
  }) async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return PlaybackSourceChangeOutcome.unavailable;
    // Live streams have no version/quality/audio catalog to switch; the only
    // source change a live session supports is its server-side subtitle
    // delivery (Plex burn-on-request, issue #1983).
    final isLiveSubtitleSwitch =
        widget.isLive &&
        newSubtitleChoice != null &&
        newMediaIndex == null &&
        newPreset == null &&
        newAudioStreamId == null;
    if (widget.isLive && !isLiveSubtitleSwitch) return PlaybackSourceChangeOutcome.unavailable;
    final transitionLease = _transitionGate.tryAcquire(PlaybackTransition.switchingSource);
    if (transitionLease == null) return PlaybackSourceChangeOutcome.busy;
    try {
      if (isLiveSubtitleSwitch) return await _switchLiveSubtitle(newSubtitleChoice);
      return await _performPlaybackSourceSwitch(
        currentPlayer: currentPlayer,
        transitionLease: transitionLease,
        newMediaIndex: newMediaIndex,
        newPreset: newPreset,
        newAudioStreamId: newAudioStreamId,
        newSubtitleChoice: newSubtitleChoice,
      );
    } finally {
      _transitionGate.release(transitionLease);
    }
  }

  Future<PlaybackSourceChangeOutcome> _performPlaybackSourceSwitch({
    required Player currentPlayer,
    required PlaybackTransitionLease transitionLease,
    int? newMediaIndex,
    TranscodeQualityPreset? newPreset,
    int? newAudioStreamId,
    PlaybackSourceSubtitleChoice? newSubtitleChoice,
  }) async {
    bool isCurrentSourceSwitch() =>
        mounted &&
        player == currentPlayer &&
        _transitionGate.owns(transitionLease, expected: PlaybackTransition.switchingSource);
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
          throw PlaybackException(
            t.messages.streamSelectionUnavailable,
            reason: PlaybackFailureReason.invalidPlaybackData,
          );
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
        );
        if (!saved) {
          throw PlaybackException(t.messages.streamSelectionFailed);
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
      if (outcome == MediaReloadOutcome.opened) {
        rememberSourceAudioPreference();
        rememberSourceSubtitlePreference();
      }
      return switch (outcome) {
        MediaReloadOutcome.opened => PlaybackSourceChangeOutcome.applied,
        MediaReloadOutcome.rejected => PlaybackSourceChangeOutcome.busy,
        MediaReloadOutcome.superseded => PlaybackSourceChangeOutcome.superseded,
        MediaReloadOutcome.failed => PlaybackSourceChangeOutcome.failed,
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
    // On a transcode the server owns the picture: a burned subtitle cannot be removed or covered
    // locally, and an embedded target can only arrive by being burned in. Either way the change
    // goes back to the server rather than being applied to the running player.
    final burnSession = _playbackSession;
    final burnedSourceStreamId = burnSession?.subtitleSelection.primarySourceStreamId;
    final targetSourceStreamId = choice.sourceStreamId;
    if (PlaybackSubtitleResolver.burnRequiresRenegotiation(
      isTranscoding: _isTranscoding,
      currentSourceStreamId: burnedSourceStreamId,
      currentSelectionHasSidecar:
          burnSession != null &&
          burnedSourceStreamId != null &&
          _sidecarForSourceStreamId(burnSession, burnedSourceStreamId) != null,
      targetIsOff: choice.isOff,
      // "A file the client fetches for itself", which the two backends mark differently: Jellyfin
      // flags the row `IsExternal`, while Plex never sets that and instead gives a real external
      // subtitle a `/library/streams/{id}` key - the same test `_selectedInternalSubtitleForHls`
      // uses to decide what it must not burn. Reading only `isExternalFile` classified every Plex
      // external file as an embedded target and sent an already-loaded track switch to the server.
      targetIsExternalFile:
          targetSourceStreamId != null &&
          (_currentMediaInfo?.subtitleTracks.any(
                (track) =>
                    track.id == targetSourceStreamId &&
                    (track.isExternalFile ||
                        (_currentMetadata.backend == MediaBackend.plex && (track.key?.isNotEmpty ?? false))),
              ) ??
              false),
    )) {
      return false;
    }

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
  /// The returned [MediaReloadOutcome] tells the caller what actually
  /// happened: only [MediaReloadOutcome.failed] means the previous session
  /// is still on screen with its (possibly dead) stream; user feedback for
  /// failures is shown here unless [showErrorUi] is false.
  Future<MediaReloadOutcome> _reloadMediaInPlace({
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
    PlaybackTransitionLease? transitionLease,
    WatchPlaybackLease? watchTogetherLease,
    String reason = 'media reload',
  }) async {
    if (widget.isLive) {
      _clearEpisodeLoadingFlags();
      return MediaReloadOutcome.rejected;
    }
    final existingPlayer = player;
    if (!mounted || existingPlayer == null) {
      if (mounted) _clearEpisodeLoadingFlags();
      return MediaReloadOutcome.rejected;
    }
    final initialWatchTogether = _activeWatchTogetherSession();
    final roomLease = watchTogetherLease ?? initialWatchTogether?.capturePlaybackLease();
    if (roomLease != null && !roomLease.isCurrent) return MediaReloadOutcome.superseded;

    final reloadLease = transitionLease == null
        ? _transitionGate.tryAcquire(PlaybackTransition.reloadingMedia)
        : _transitionGate.advance(
            transitionLease,
            PlaybackTransition.reloadingMedia,
            expected: PlaybackTransition.switchingSource,
          )
        ? transitionLease
        : null;
    if (reloadLease == null) {
      _clearEpisodeLoadingFlags();
      return MediaReloadOutcome.rejected;
    }

    try {
      final currentPlayer = existingPlayer;
      final attempt = _beginPlaybackAttempt(currentPlayer, isMediaReload: true);
      bool isCurrentReload() =>
          attempt.isCurrent &&
          !_hasFatalPlaybackError &&
          !_isExiting.value &&
          (roomLease == null || roomLease.isCurrent);

      // The session itself swaps atomically at the open boundary, so the only
      // rollback state is the eagerly-set identity (shown by the loading UI)
      // and the first-frame flag.
      final previousMetadata = _playbackSession?.metadata ?? _currentMetadata;
      final previousLaunchIdentity = VideoPlayerScreenState._activeRouteGuard.identityFor(this);
      final previousPartId = _currentMediaInfo?.partId;
      final previousMediaSourceId = _currentMediaInfo?.mediaSourceId;
      final previousFirstFrame = _firstFrame.snapshot();
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
      Completer<void>? reloadStartupHold;
      var didOpenReplacement = false;

      // Capture context-dependent values before async gaps. The neutral
      // [PlaybackInitializationService] consumes [mediaClient] regardless of
      // backend. We still narrow to [plexClient] for [TrackManager]'s
      // server-side track persistence, which is Plex-only — Jellyfin
      // sessions get a null `getPlexClient` and skip that path.
      late final OfflineWatchSyncService offlineWatchService;
      late final AccountPreferencesController accountPreferences;
      late final PlaybackStateProvider playbackState;
      late final AppDatabase database;
      late final MultiServerManager serverManager;
      late final WatchTogetherProvider? watchTogether;
      late final Object? watchTogetherBinding;
      late final bool wtOwnsStart;
      try {
        offlineWatchService = context.read<OfflineWatchSyncService>();
        accountPreferences = context.read<AccountPreferencesController>();
        playbackState = context.read<PlaybackStateProvider>();
        database = context.read<AppDatabase>();
        serverManager = context.read<MultiServerProvider>().serverManager;
        // Cycle the Watch Together attachment across every reload: the
        // reload's internal pause/open churn must not leak into the sync layer
        // as user intents. Readiness re-handshakes on re-attach (item changes
        // start a new media epoch; same-item source switches group-wait while
        // we reload).
        watchTogether = initialWatchTogether;
        watchTogetherBinding = _watchTogetherBinding;
        wtOwnsStart = _watchTogetherOwnsPlaybackStart();
      } catch (e, stackTrace) {
        appLogger.e('Failed to prepare media reload during $reason', error: e, stackTrace: stackTrace);
        if (mounted && showErrorUi) {
          showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
        }
        _clearEpisodeLoadingFlags();
        return MediaReloadOutcome.failed;
      }

      final shouldAutoStart = shouldAutoStartReloadedMedia(
        wasPlayingBeforeReload: wasPlayingBeforeReload,
        watchTogetherOwnsStart: wtOwnsStart,
        startPaused: startPaused,
      );

      if (!isCurrentReload()) return MediaReloadOutcome.superseded;

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
        _episode.showPlayNextDialog = false;
        _episode.autoPlayTimer?.cancel();
        _firstFrame.resetUiForOpen();

        // Detach before pausing so the reload's internal pause can't broadcast
        // a party-wide pause; the finally below restores the attachment.
        if (watchTogether != null && watchTogetherBinding != null) {
          watchTogether.unbindPlayer(expectedBinding: watchTogetherBinding);
        }
        try {
          await currentPlayer.pause();
        } catch (e) {
          appLogger.w('Failed to pause before $reason', error: e);
        }
        if (!isCurrentReload()) return MediaReloadOutcome.superseded;

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
        if (!isCurrentReload()) return MediaReloadOutcome.superseded;

        final playbackResolver = PlaybackSourceResolver(serverManager: serverManager, database: database);
        await stoppedProgressFuture;
        if (!isCurrentReload()) return MediaReloadOutcome.superseded;
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
          ),
          offlineLibraryMode: _offlineLibraryMode,
        );
        if (!isCurrentReload()) return MediaReloadOutcome.superseded;
        final result = playbackContext.result;
        final mediaClient = playbackContext.reportingClient;
        final plexClient = mediaClient is PlexClient ? mediaClient : null;
        final streamHeaders = playbackContext.streamHeaders;

        if (result.videoUrl == null) {
          throw PlaybackException(t.messages.noVideoUrl, reason: PlaybackFailureReason.noPlayableSource);
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
          if (!isCurrentReload()) return MediaReloadOutcome.superseded;
        }
        final subtitleSelection = await _resolveSubtitleSelectionForOpen(
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
        if (!isCurrentReload()) return MediaReloadOutcome.superseded;

        // Build the replacement session now, commit it only once open()
        // succeeds — until then every session-derived getter still describes
        // the item that is actually playing.
        final session = PlaybackSession.fromContext(
          playbackContext,
          requestedQualityPreset: targetQualityPreset,
          requestedMediaSourceId: selectedMediaSourceId,
          subtitleSelection: subtitleSelection,
        );
        if (result.fallbackReason != null && !targetQualityPreset.isOriginal && mounted) {
          showErrorSnackBar(context, t.videoControls.transcodeUnavailableFallback);
        }

        final settingsService = await SettingsService.getInstance();
        if (!isCurrentReload()) return MediaReloadOutcome.superseded;

        // Shared open orchestration with the initial start flow
        // ([_openResolvedMedia]) — including the Android MPV startup decoder
        // refresh, whose gate is armed before open and released after track
        // setup.
        final flow = await _openResolvedMedia(
          currentPlayer: currentPlayer,
          settingsService: settingsService,
          metadata: metadata,
          result: result,
          session: session,
          subtitleSelection: subtitleSelection,
          headers: result.usesLocalMedia ? null : streamHeaders,
          // Not _isOfflinePlayback: the replacement session commits later, in
          // onOpened, so the getter still describes the previous item here.
          isLocalMedia: _offlineLibraryMode || result.usesLocalMedia,
          isCurrent: isCurrentReload,
          staleGuard: isCurrentReload,
          // Captured before the reload detached the player from the sync
          // layer; a live read would see the detached state.
          watchTogetherOwnsStart: () => wtOwnsStart,
          resolveShouldAutoStart: (_) => shouldAutoStart,
          resumePosition: () => openResumePosition,
          plexClient: () => plexClient,
          getProfileSettings: () => accountPreferences.activePreferences,
          preferredAudioTrack: initializationAudioTrack,
          wtStartupHold: () => reloadStartupHold,
          primarySubtitleTranscoding: () => result.isTranscoding,
          ensureAudioFocus: () => currentPlayer.requestAudioFocus(),
          clearFirstFrameForOpen: false,
          deferAutomotiveStart: false,
          beforeArm: () async {
            if (!isCurrentReload()) return false;
            _progressTracker?.stopTracking();
            _progressTracker?.dispose();
            _progressTracker = null;
            unawaited(DiscordRPCService.instance.stopPlayback());
            unawaited(TrackerCoordinator.instance.stopPlayback());
            if (!isCurrentReload()) return false;

            // Generation invalidation prevents follow-on selection calls,
            // but a native audio/subtitle/rate mutation may already have
            // been dispatched. Drain exactly that captured operation before
            // reusing the player for replacement media, otherwise its late
            // completion can mutate the replacement item's tracks.
            await attempt.trackMutationDrain;
            await watchTogether?.pendingRateCommands;
            // Native seeks must finish before a replacement source opens. The
            // EOF delegate's reload is not a native seek and never joins this drain.
            await _nativeSeekDrain?.future;
            return isCurrentReload();
          },
          afterMediaOpened: (_, holdPlaybackStart, _) async {
            if (wtOwnsStart && holdPlaybackStart) reloadStartupHold = Completer<void>();
            _episode.completionLatch.reset();
            if (isItemChange) {
              // Same-item reloads (including the spurious-EOF recovery itself
              // and quality switches) keep the spent budget — that is the
              // loop guard.
              _eofRecovery.resetBudget();
            }

            // Versions/mediaInfo come from the committed session; rebuild so
            // the controls pick them up. Same-part switches
            // (quality/audio/subtitle) keep the scrub-preview source —
            // BIF/trickplay is per part, so a reset would re-download
            // identical bytes.
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
            return true;
          },
          onOpening: () {
            _firstFrame.resetRenderedForAttempt();
            // 503s observed from here on belong to the replacement open.
            _http503Watchdog.disarm();
          },
          onOpened: () {
            // The player now owns the new file — publish the session at the
            // same boundary so identity and source state flip together.
            didOpenReplacement = true;
            if (!attempt.isCurrent) return;
            _commitPlaybackSession(session);
            _commitWatchTogetherSelection(watchTogether, roomLease, metadata, openResumePosition ?? Duration.zero);
          },
        );
        if (flow == null) return MediaReloadOutcome.superseded;
        if (!isCurrentReload()) return MediaReloadOutcome.superseded;

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

        if (isItemChange) {
          unawaited(_reapplyScopedPlayerPrefsForItemChange(previousMetadata: previousMetadata, metadata: metadata));
        }

        _setPlayerState(() {
          _episode.next = null;
          _episode.previous = null;
          _episode.nextStatus = QueueNavigationStatus.failed;
          // A successful swap restores the transient-retry budget for the
          // next transition (#1867).
          _episode.playNextTransientRetryCount = 0;
        });

        try {
          playbackState.setCurrentItem(metadata);
        } catch (e) {
          appLogger.d('playbackState.setCurrentItem failed', error: e);
        }

        unawaited(_loadAdjacentEpisodes(metadata: metadata, attempt: attempt));
        if (!isCurrentReload()) return MediaReloadOutcome.superseded;

        if (_autoPipEnabled) {
          unawaited(_updateAutoPipState(isPlaying: currentPlayer.state.playing));
        }
        return MediaReloadOutcome.opened;
      } catch (e) {
        if (!isCurrentReload()) return MediaReloadOutcome.superseded;
        // Record the classified reason so _playNext can re-present the Play
        // Next prompt when an EOF-driven advance merely hit a transient
        // server blip (#1867). Non-PlaybackException throws stay null —
        // they never qualify for a retry prompt.
        _episode.lastReloadFailureReason = e is PlaybackException ? e.reason : null;
        _episode.completionLatch.reset();
        if (!didOpenReplacement) {
          // Nothing was opened: the previous session is still committed, so
          // only the eagerly-set identity needs restoring before resuming.
          _currentMetadata = previousMetadata;
          if (previousLaunchIdentity != null) {
            VideoPlayerScreenState._activeRouteGuard.update(this, previousLaunchIdentity);
          }
          _firstFrame.restore(previousFirstFrame);
          _hasFatalPlaybackError = previousHasFatalPlaybackError;
          // If the stop report already went out, un-latch the tracker so the
          // resumed session keeps reporting (and its eventual real stop sends).
          _progressTracker?.resumeAfterStoppedReport();
          if (!wtOwnsStart && wasPlayingBeforeReload && mounted && player == currentPlayer) {
            unawaited(_playWithPlaybackIntent(currentPlayer));
          }
        }
        if (_progressTracker == null && player == currentPlayer) {
          // Progress reporting must survive both exits: beforeArm disposed the
          // tracker before the open boundary, so rebuild it for the item
          // actually on screen (the failure may have hit before
          // _wirePerItemPlaybackServices ran). On the rollback path
          // _currentMetadata was just restored to the previous item; after a
          // committed open it is the replacement. _playbackSession describes
          // that same item on both paths, so its client and session fields are
          // the right wiring either way.
          _wirePerItemPlaybackServices(
            metadata: _currentMetadata,
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
          _episode.isLoadingNext = false;
          _episode.isLoadingPrevious = false;
        });
        if (isItemChange) _showChromeForSwappedItem();
        appLogger.e('Failed to reload media in-place during $reason', error: e);
        if (mounted && showErrorUi) {
          showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
        }
        return didOpenReplacement ? MediaReloadOutcome.opened : MediaReloadOutcome.failed;
      } finally {
        if (attempt.isCurrent && !didOpenReplacement && _currentMetadata.globalKey != previousMetadata.globalKey) {
          _currentMetadata = previousMetadata;
          if (previousLaunchIdentity != null) {
            VideoPlayerScreenState._activeRouteGuard.update(this, previousLaunchIdentity);
          }
          _firstFrame.restore(previousFirstFrame);
        }
        // Only the current screen/session/open may restore its committed source.
        // A pre-open failure restores A; successful open commits B. Superseded
        // work never binds either over its successor.
        try {
          if (watchTogether != null &&
              roomLease != null &&
              isCurrentReload() &&
              watchTogether.isPlaybackLeaseCurrent(roomLease) &&
              (watchTogetherBinding == null || watchTogether.ownsBinding(watchTogetherBinding)) &&
              !watchTogether.hasAttachedPlayer) {
            _attachToWatchTogetherSession(
              lease: roomLease,
              startupHold: didOpenReplacement ? reloadStartupHold?.future : null,
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
      _transitionGate.release(reloadLease);
      // Every superseded return leaves the episode loading flags set otherwise, and
      // _playNext/_playPrevious treat them as a re-entrancy guard — a stuck flag turns the
      // Next button into a no-op for the rest of the session. Idempotent: the success and
      // rollback paths above have already cleared them, and this skips the rebuild when
      // neither flag is set.
      _clearEpisodeLoadingFlags();
    }
  }

  /// Re-push scope-persisted player values whose resolution changed with the
  /// item swapped in by [_reloadMediaInPlace].
  ///
  /// Shader, box-fit, and sync offsets are applied once per screen/player and
  /// otherwise survive an in-place reload as latent native state — correct as
  /// long as both items resolve to the same value, wrong the moment a Watch
  /// Together swap or a next-episode hop crosses a library/title boundary.
  /// Only changed resolutions are pushed so a session-local tweak keeps
  /// carrying over exactly as it does today. Playback speed needs no handling
  /// here: TrackManager re-resolves it on every open.
  Future<void> _reapplyScopedPlayerPrefsForItemChange({
    required MediaItem previousMetadata,
    required MediaItem metadata,
  }) async {
    final currentPlayer = player;
    if (currentPlayer == null) return;
    try {
      final previousAudioOffset = ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.audioSyncOffset, previousMetadata);
      final audioOffset = ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.audioSyncOffset, metadata);
      if (audioOffset != previousAudioOffset) {
        await currentPlayer.setProperty('audio-delay', (audioOffset / 1000.0).toString());
      }

      final previousSubtitleOffset = ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.subtitleSyncOffset, previousMetadata);
      final subtitleOffset = ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.subtitleSyncOffset, metadata);
      if (subtitleOffset != previousSubtitleOffset) {
        await currentPlayer.setProperty('sub-delay', (subtitleOffset / 1000.0).toString());
      }

      final previousBoxFit = ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.boxFitMode, previousMetadata);
      final boxFit = ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.boxFitMode, metadata);
      if (boxFit != previousBoxFit) {
        _videoFilterManager?.setBoxFitMode(boxFit);
      }

      final previousShaderId = ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.shaderPreset, previousMetadata);
      final shaderId = ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.shaderPreset, metadata);
      if (shaderId != previousShaderId && mounted) {
        // _currentMetadata is already the new item; the helper resolves
        // against it and swaps the mpv shader chain.
        await _visualEffects.applySavedPreset();
      }
    } catch (e, stackTrace) {
      appLogger.w('Failed to re-apply scoped player settings after item change', error: e, stackTrace: stackTrace);
    }
  }
}
