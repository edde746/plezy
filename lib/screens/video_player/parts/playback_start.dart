part of '../../video_player_screen.dart';

extension _VideoPlayerPlaybackStartMethods on VideoPlayerScreenState {
  Future<void> _startPlayback() async {
    final currentPlayer = player;
    if (!mounted || _shuttingDown || currentPlayer == null) return;
    final attempt = _beginPlaybackAttempt(currentPlayer);
    final watchTogether = _activeWatchTogetherSession();
    final watchTogetherLease = widget.watchTogetherLease;
    _watchTogetherLease = watchTogetherLease;
    if (watchTogether != null && watchTogetherLease != null && watchTogetherLease.isCurrent) {
      _watchTogetherProvider = watchTogether;
      watchTogether.onPlayerMediaSwitched = _handlePlayerMediaSwitch;
    }
    bool isCurrentStart() => attempt.isCurrent && (watchTogetherLease == null || watchTogetherLease.isCurrent);
    _firstFrame.resetRenderedForAttempt();
    _hasFatalPlaybackError = false;
    // 503s observed from here on belong to this attempt's open.
    _http503Watchdog.disarm();

    // Live TV mode: bypass standard playback initialization
    if (widget.isLive) {
      try {
        _firstFrame.resetUiForOpen();
        await currentPlayer.requestAudioFocus();
        await _setLiveStreamOptions(currentPlayer);
        if (!attempt.isCurrent) return;

        // Start the session inside the player for both backends (loading
        // spinner covers Plex's tune / Jellyfin's stream negotiation).
        final channel = widget.live!.channel;
        final session = await _startLiveSession(channel);
        if (session == null) {
          throw PlaybackException(t.liveTv.failedToStartChannel, reason: PlaybackFailureReason.serverUnavailable);
        }
        if (!mounted || !attempt.isCurrent) {
          _abandonLiveSession(session);
          return;
        }
        _live.adoptSession(session);

        // Presentation chooses an epoch; only the backend translates offsets.
        final captureBuffer = session.captureBuffer;
        final timeshift = session is LiveTvTimeshiftSession ? session as LiveTvTimeshiftSession : null;
        final window = captureBuffer == null ? null : timeshift?.seekWindow(captureBuffer);
        double? requestedEpoch;
        if (window != null) {
          final programStart = session.program.beginsAt?.toDouble() ?? window.startEpoch;
          final effectiveStart = window.target(programStart)!;
          if (window.endEpoch - effectiveStart > 60) {
            widget.launchObserver?.mark('blocked', blocker: 'confirmationRequired');
            final watchFromStart = await _showWatchFromStartDialog(effectiveStart.ceil(), window.endEpoch.floor());
            widget.launchObserver?.mark('opening');
            if (!attempt.isCurrent || !identical(_live.session, session)) return;
            if (watchFromStart == true) requestedEpoch = effectiveStart;
          }
        }

        String? streamUrl;
        double? targetEpoch;
        if (timeshift != null && captureBuffer != null) {
          final request = await timeshift.resolveSeek(targetEpoch: requestedEpoch, buffer: captureBuffer);
          streamUrl = request?.url;
          targetEpoch = request?.effectiveTargetEpoch;
        } else {
          streamUrl = await session.streamUrlAt();
        }
        if (!attempt.isCurrent || !identical(_live.session, session)) return;
        if (streamUrl == null) {
          throw PlaybackException(t.liveTv.failedToBuildStreamUrl, reason: PlaybackFailureReason.noPlayableSource);
        }
        if (requestedEpoch == null) {
          _live.markStreamRestartedAtLiveEdge(captureBuffer);
        } else {
          _live.playbackElapsed
            ..reset()
            ..start();
        }

        await _openLiveStream(
          currentPlayer,
          streamUrl,
          targetEpoch: targetEpoch,
          play: !PlatformDetector.isAutomotive(),
          isCurrent: () => attempt.isCurrent && identical(_live.session, session),
          timeShifted: requestedEpoch != null,
        );
        if (!attempt.isCurrent) return;

        _trackManager?.cacheExternalSubtitles(const []);

        await _initVideoFilterAndPip();
        if (!mounted || !attempt.isCurrent) return;

        if (mounted) {
          // Live TV never commits a PlaybackSession, so the session-derived
          // versions/mediaInfo getters already read empty here.
          _setPlayerState(() {
            _isPlayerInitialized = true;
          });
          _trackManager?.mediaInfo = null;
        }
        if (PlatformDetector.isAutomotive()) {
          await _playWithPlaybackIntent(currentPlayer);
        }
      } catch (e, st) {
        appLogger.e('Failed to start live TV playback', error: e, stackTrace: st);
        unawaited(_sendLiveTimeline('stopped'));
        widget.launchObserver?.mark('failed', failure: 'playbackFailed');
        if (mounted && !_shuttingDown) {
          showErrorSnackBar(context, e.toString());
          unawaited(_handleBackButton());
        }
      }
      return;
    }

    // Capture providers before async gaps
    final offlineWatchService = context.read<OfflineWatchSyncService>();
    var primaryMediaOpened = false;
    // Created by afterMediaOpened when the sync layer owns a gated start;
    // released by the startup gate, or by the finally below if the open
    // aborted, threw, or was superseded before the gate ran.
    Completer<void>? wtStartupHold;

    try {
      PlaybackContext playbackContext;

      if (_offlineLibraryMode) {
        final playbackResolver = PlaybackSourceResolver(
          serverManager: context.read<MultiServerProvider>().serverManager,
          database: context.read<AppDatabase>(),
        );
        playbackContext = await playbackResolver.resolve(
          PlaybackInitializationOptions(
            metadata: _currentMetadata,
            selectedMediaIndex: _effectiveSelectedMediaIndex,
            selectedMediaSourceId: _requestedMediaSourceId,
            qualityPreset: _selectedQualityPreset,
            selectedAudioStreamId: _selectedAudioStreamId,
            preferredAudioTrack: _preferredAudioTrack,
            preferredSubtitleTrack: _preferredSubtitleTrack,
            sessionIdentifier: _playbackSessionIdentifier,
            transcodeSessionId: _playbackTranscodeSessionId,
          ),
          offlineLibraryMode: true,
        );
        if (playbackContext.result.videoUrl == null) {
          throw PlaybackException(t.messages.fileInfoNotAvailable);
        }
      } else {
        // Online path: `_playbackDataFuture` was kicked off in `_initializePlayer`
        // in parallel with MPV setup. Quality preset + server capabilities +
        // headers were resolved there too. Just await the result.
        final playbackDataFuture = _playbackDataFuture;
        if (playbackDataFuture == null) {
          throw PlaybackException(t.messages.playbackDataNotPrepared);
        }
        playbackContext = await playbackDataFuture;
        if (!mounted || player != currentPlayer) return;

        if (playbackContext.result.fallbackReason != null && !_selectedQualityPreset.isOriginal) {
          if (mounted) {
            showErrorSnackBar(context, t.videoControls.transcodeUnavailableFallback);
          }
        }
      }
      final result = playbackContext.result;
      if (!attempt.isCurrent) return;
      if (widget.strictMediaSelection &&
          (result.selectedMediaIndex != widget.selectedMediaIndex ||
              (widget.selectedMediaSourceId != null &&
                  (result.selectedMediaSourceId ?? result.selectedVersion?.id) != widget.selectedMediaSourceId))) {
        widget.launchObserver?.mark('failed', failure: 'staleMediaSelection');
        throw PlaybackException(t.messages.playbackFailed);
      }
      final streamHeaders = playbackContext.streamHeaders;
      final subtitleSelection = await _resolveSubtitleSelectionForOpen(
        metadata: _currentMetadata,
        result: result,
        preferredAudioTrack: _preferredAudioTrack,
        preferredSubtitleTrack: _preferredSubtitleTrack,
        preferredSecondarySubtitleTrack: _preferredSecondarySubtitleTrack,
      );
      if (!attempt.isCurrent) return;
      // Initial start has no previous session to protect, so commit as soon
      // as the resolve lands (reload-style flows commit at the open
      // boundary instead).
      final session = PlaybackSession.fromContext(
        playbackContext,
        requestedQualityPreset: _selectedQualityPreset,
        requestedMediaSourceId: _requestedMediaSourceId,
        subtitleSelection: subtitleSelection,
      );
      _commitPlaybackSession(session);

      // Primary refresh-rate path: when metadata provides FPS, Android players
      // can switch before creating decoders. MPV still needs a startup refresh
      // when MediaCodec has already produced its first paused frame.
      final settingsService = await SettingsService.getInstance();
      if (!attempt.isCurrent) return;
      var audioFocusReady = false;

      Future<void> ensureAudioFocus() async {
        if (audioFocusReady) return;
        final focusFuture = _audioFocusFuture;
        if (focusFuture != null) {
          await focusFuture;
          _audioFocusFuture = null;
        } else {
          await currentPlayer.requestAudioFocus();
        }
        audioFocusReady = true;
      }

      Duration? resumePosition;
      PlexClient? plexClientForTracks;

      // A null result (staleness guard or hook aborted the flow) needs no
      // handling here: the finally below is the only post-open work.
      await _openResolvedMedia(
        currentPlayer: currentPlayer,
        settingsService: settingsService,
        metadata: _currentMetadata,
        result: result,
        session: session,
        subtitleSelection: subtitleSelection,
        headers: streamHeaders,
        isLocalMedia: _isOfflinePlayback,
        isCurrent: isCurrentStart,
        outcome: attempt.outcome,
        // When a Watch Together session is active the sync layer owns the
        // start: open paused everywhere and let the host coordinate one
        // simultaneous group start.
        watchTogetherOwnsStart: () => watchTogetherLease != null && _watchTogetherOwnsPlaybackStart(),
        resolveShouldAutoStart: (wtOwnsStart) => !wtOwnsStart,
        resumePosition: () => resumePosition,
        plexClient: () => plexClientForTracks,
        getProfileSettings: () => context.read<AccountPreferencesController>().activePreferences,
        preferredAudioTrack: _preferredAudioTrack,
        primarySubtitleTranscoding: () => _isTranscoding,
        ensureAudioFocus: ensureAudioFocus,
        clearFirstFrameForOpen: true,
        deferAutomotiveStart: true,
        beforePrime: () async {
          // Request audio focus before starting playback (Android)
          // This causes other media apps (Spotify, podcasts, etc.) to pause.
          // Fired in parallel with MPV setup in `_initializePlayer`; we await
          // the in-flight future here (usually already resolved).
          await ensureAudioFocus();
          if (!attempt.isCurrent) return false;

          resumePosition = await _resolveOpenResumePosition(
            metadata: _currentMetadata,
            isOffline: _isOfflinePlayback,
            offlineWatchService: offlineWatchService,
            requested: widget.initialPosition,
          );
          return mounted && player == currentPlayer;
        },
        afterMediaOpened: (shouldAutoPlay, holdPlaybackStart, wtOwnsStart) async {
          // Attach player to Watch Together session for sync (if in session).
          // With a frame-rate startup gate pending, sync readiness waits for
          // its release so the group start can't fire mid display switch.
          if (isCurrentStart() && !_isOfflinePlayback && watchTogetherLease != null) {
            _commitWatchTogetherSelection(
              watchTogether,
              watchTogetherLease,
              _currentMetadata,
              resumePosition ?? Duration.zero,
            );
            if (wtOwnsStart && holdPlaybackStart) wtStartupHold = Completer<void>();
            _attachToWatchTogetherSession(lease: watchTogetherLease, startupHold: wtStartupHold?.future);
          }
          if (shouldAutoPlay && PlatformDetector.isAutomotive()) {
            await _playWithPlaybackIntent(currentPlayer);
            if (!attempt.isCurrent) return false;
          }
          return true;
        },
        beforeTrackSetup: () async {
          // Versions/mediaInfo come from the committed session; rebuild so the
          // controls pick them up.
          if (!mounted) return false;
          final mediaClient = context.tryGetMediaClientForServer(serverIdOrNull(_currentMetadata.serverId));
          plexClientForTracks = mediaClient is PlexClient ? mediaClient : null;
          _resetScrubPreviewForNewItem(
            metadata: _currentMetadata,
            mediaInfo: result.mediaInfo,
            mediaClient: mediaClient,
          );

          await _initVideoFilterAndPip();
          if (!attempt.isCurrent) return false;

          if (player == currentPlayer) {
            // Auto-PiP: set up callback for API 26-30 path and initial state
            if (_autoPipEnabled) {
              void autoPipEnteringCallback() {
                if (!mounted || player != currentPlayer) return;
                _setAndroidAutoPipTransitionInFlight(true, reason: 'native_auto_pip_entering');
                _preparePipFiltersForEntry();
              }

              _autoPipEnteringCallback = autoPipEnteringCallback;
              PipService.onAutoPipEntering = autoPipEnteringCallback;
              if (currentPlayer.state.playing) {
                unawaited(_updateAutoPipState(isPlaying: true));
              }
            }

            // Shader Service (MPV only)
            _shaderService = ShaderService(currentPlayer);
            if (_shaderService!.isSupported) {
              // Ambient Lighting Service
              _ambientLightingService = AmbientLightingService(currentPlayer);
              _shaderService!.ambientLightingService = _ambientLightingService;
              _videoFilterManager?.ambientLightingService = _ambientLightingService;

              await _visualEffects.applySavedPreset();
              await _visualEffects.restoreAmbientLighting();
            }
          }
          return attempt.isCurrent;
        },
        wtStartupHold: () => wtStartupHold,
        onMediaAvailabilityChanged: (available) => primaryMediaOpened = available,
      );
    } on PlaybackException catch (e, st) {
      if (attempt.isCurrent && widget.launchObserver?.failure == null) {
        widget.launchObserver?.mark('failed', failure: e.reason.name);
      }
      appLogger.w('Playback initialization failed', error: e, stackTrace: st);
      if (attempt.isCurrent && mounted) {
        if (!primaryMediaOpened) {
          _hasFatalPlaybackError = true;
        }
        _firstFrame.forceUiReadyOnFailure(); // Hide spinner on every current startup failure
        showErrorSnackBar(context, e.message);
      }
    } catch (e, st) {
      if (attempt.isCurrent) widget.launchObserver?.mark('failed', failure: 'playbackFailed');
      appLogger.e('Failed to start playback', error: e, stackTrace: st);
      if (attempt.isCurrent && mounted) {
        if (!primaryMediaOpened) {
          _hasFatalPlaybackError = true;
        }
        _firstFrame.forceUiReadyOnFailure(); // Hide spinner on every current startup failure
        // The init sentinel carries no prose — the UI owns the wording.
        showErrorSnackBar(
          context,
          e is PlayerInitializationException ? t.messages.playbackFailed : t.messages.errorLoading(error: e.toString()),
        );
      }
    } finally {
      // Backstop: whether the gate never ran its resume path, the open
      // aborted, or the flow threw, never leave Watch Together readiness
      // held forever.
      final startupHold = wtStartupHold;
      if (startupHold != null && !startupHold.isCompleted) {
        startupHold.complete();
      }
    }
  }
}
