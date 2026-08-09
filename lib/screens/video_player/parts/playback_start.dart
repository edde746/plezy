part of '../../video_player_screen.dart';

extension _VideoPlayerPlaybackStartMethods on VideoPlayerScreenState {
  Future<void> _startPlayback() async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return;
    final attempt = _beginPlaybackAttempt(currentPlayer);
    _hasRenderedFirstFrame = false;
    _hasFatalPlaybackError = false;
    // 503s observed from here on belong to this attempt's open.
    _http503Watchdog.disarm();

    // Live TV mode: bypass standard playback initialization
    if (widget.isLive) {
      try {
        _hasFirstFrame.value = false;
        await currentPlayer.requestAudioFocus();
        await _setLiveStreamOptions(currentPlayer);
        if (!attempt.isCurrent) return;

        // Start the session inside the player for both backends (loading
        // spinner covers Plex's tune / Jellyfin's stream negotiation).
        final channel = widget.live!.channel;
        final session = await _startLiveSession(channel);
        if (session == null) throw Exception('Failed to start live channel');
        if (!mounted || !attempt.isCurrent) {
          _abandonLiveSession(session);
          return;
        }
        _live.adoptSession(session);

        // Show "Watch from Start" dialog when an existing capture session has >60s of history.
        // On a fresh tune (no active recording), the buffer is empty so this won't trigger.
        int? offsetSeconds;
        final captureBuffer = session.captureBuffer;
        final programBeginsAt = session.program.beginsAt;
        if (captureBuffer != null && programBeginsAt != null) {
          final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final offsetProgramStart = programBeginsAt - captureBuffer.startedAt.round();
          // If a session recording started after current program start, offset of program start at will be negative.
          // If a session recording started before current program start, offset of program start will be positive.
          // If guide data is not available, program start will be equal to current time.
          final useProgramStart = offsetProgramStart > 0 && nowEpoch - programBeginsAt > 60;
          final effectiveStart = useProgramStart ? programBeginsAt : captureBuffer.seekableStartEpoch;
          final elapsed = nowEpoch - effectiveStart;
          appLogger.d(
            'Time-shift: buffer=${captureBuffer.seekableDurationSeconds}s, '
            'beginsAt=$programBeginsAt, elapsed=${elapsed}s (need >60 for dialog)',
          );
          if (elapsed > 60) {
            final watchFromStart = await _showWatchFromStartDialog(effectiveStart, nowEpoch);
            if (!mounted) return;
            if (watchFromStart == true) {
              offsetSeconds = useProgramStart ? offsetProgramStart : captureBuffer.seekStartSeconds.round();
            }
          }
        }

        // Build the stream URL (with optional offset for time-shift)
        final streamUrl = await session.streamUrlAt(offsetSeconds: offsetSeconds);
        if (streamUrl == null || !mounted) {
          throw Exception('Failed to build stream path');
        }

        // Track stream start epoch for position calculations
        if (offsetSeconds != null) {
          _live.streamStartEpoch = captureBuffer!.startedAt + offsetSeconds;
          _live.atLiveEdge = false;
          _live.playbackStartTime = DateTime.now();
        } else {
          _live.markStreamRestartedAtLiveEdge();
        }

        await currentPlayer.setProperty('force-seekable', 'no');
        await currentPlayer.open(
          Media(streamUrl, headers: const {'Accept-Language': 'en'}),
          play: !PlatformDetector.isAutomotive(),
          isLive: true,
        );
        if (!attempt.isCurrent) return;

        _trackManager?.cacheExternalSubtitles(const []);

        await _initVideoFilterAndPip();
        if (!mounted || player != currentPlayer) return;

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
        if (mounted) {
          showErrorSnackBar(context, e.toString());
          unawaited(_handleBackButton());
        }
      }
      return;
    }

    // Capture providers before async gaps
    final offlineWatchService = context.read<OfflineWatchSyncService>();
    var primaryMediaOpened = false;

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
          throw StateError('Playback data was not prepared before playback start');
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
      final streamHeaders = playbackContext.streamHeaders;
      var subtitleSelection = await _resolveSubtitleSelectionForOpen(
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
      var session = PlaybackSession.fromContext(
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
      final displayCriteria = result.mediaInfo?.displayCriteria;
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

      final frameRatePlan = await _prepareFrameRateForOpen(
        currentPlayer: currentPlayer,
        settingsService: settingsService,
        preKnownFps: displayCriteria?.fps,
        preKnownWidth: displayCriteria?.width ?? 0,
        preKnownHeight: displayCriteria?.height ?? 0,
        hasVideoUrl: result.videoUrl != null,
        isTranscoding: result.isTranscoding,
        ensureAudioFocus: ensureAudioFocus,
      );
      if (frameRatePlan == null) return;
      final shouldHoldPlaybackStart = frameRatePlan.holdPlaybackStart;

      // When a Watch Together session is active the sync layer owns the
      // start: open paused everywhere and let the host coordinate one
      // simultaneous group start.
      final wtOwnsStart = _watchTogetherOwnsPlaybackStart();
      Completer<void>? wtStartupHold;
      late _ExternalSubtitleOpenPlan externalSubtitlePlan;

      // Open video through Player
      if (result.videoUrl != null) {
        // Reset first frame flag and frame rate retry counter for new video
        _hasFirstFrame.value = false;
        _frameRate.resetForNewItem();
        if (frameRatePlan.countsAsApplied) {
          _frameRate.applied = true;
        }

        // Request audio focus before starting playback (Android)
        // This causes other media apps (Spotify, podcasts, etc.) to pause.
        // Fired in parallel with MPV setup in `_initializePlayer`; we await
        // the in-flight future here (usually already resolved).
        await ensureAudioFocus();
        if (!attempt.isCurrent) return;

        final resumePosition = await _resolveOpenResumePosition(
          metadata: _currentMetadata,
          isOffline: _isOfflinePlayback,
          offlineWatchService: offlineWatchService,
        );
        if (!mounted || player != currentPlayer) return;

        await _primeDisplayCriteria(
          player: currentPlayer,
          settingsService: settingsService,
          displayCriteria: displayCriteria,
          isTranscoding: result.isTranscoding,
        );

        frameRatePlan.armStartupRefreshGate(currentPlayer);
        externalSubtitlePlan = _prepareExternalSubtitleOpenPlan(
          player: currentPlayer,
          externalSubtitles: subtitleSelection.sidecarsAtOpen,
        );
        final shouldAutoPlay =
            !shouldHoldPlaybackStart && !wtOwnsStart && externalSubtitlePlan.canStartBeforeTrackSetup;

        // Backends that support at-open sidecars receive them with open()
        // so tracks are discovered in a single prepare/loadfile cycle. Any
        // backend that cannot do that still uses the post-open sub-add path.
        final openTiming = _playbackOpenTiming(
          isTranscoding: result.isTranscoding,
          resumePosition: resumePosition,
          durationMs: _currentMetadata.durationMs,
        );
        await _awaitTranscodeReadiness(
          client: playbackContext.reportingClient,
          isTranscoding: result.isTranscoding,
          videoUrl: result.videoUrl!,
        );
        if (!attempt.isCurrent) return;
        final openResult = await _openMediaOnPlayer(
          player: currentPlayer,
          settingsService: settingsService,
          videoUrl: result.videoUrl!,
          isTranscoding: result.isTranscoding,
          isLocalMedia: _isOfflinePlayback,
          selectedVersion: result.selectedVersion,
          timing: openTiming,
          headers: streamHeaders,
          play: shouldAutoPlay && !PlatformDetector.isAutomotive(),
          externalSubtitlesAtOpen: externalSubtitlePlan.subtitlesAtOpen,
          shouldContinue: () => attempt.isCurrent,
          onMediaAvailabilityChanged: (available) => primaryMediaOpened = available,
        );
        if (!openResult.didOpen || !attempt.isCurrent) return;
        if (openResult.sidecarFallbackUsed) {
          session = _commitSidecarFallbackSession(session);
          subtitleSelection = session.subtitleSelection;
          externalSubtitlePlan = _prepareExternalSubtitleOpenPlan(player: currentPlayer, externalSubtitles: const []);
        }

        // Attach player to Watch Together session for sync (if in session).
        // With a frame-rate startup gate pending, sync readiness waits for
        // its release so the group start can't fire mid display switch.
        if (mounted && !_isOfflinePlayback) {
          if (wtOwnsStart && shouldHoldPlaybackStart) {
            wtStartupHold = Completer<void>();
          }
          _attachToWatchTogetherSession(startupHold: wtStartupHold?.future);
          _notifyWatchTogetherMediaChange();
        }
        if (shouldAutoPlay && PlatformDetector.isAutomotive()) {
          await _playWithPlaybackIntent(currentPlayer);
          if (!attempt.isCurrent) return;
        }
      } else {
        externalSubtitlePlan = _prepareExternalSubtitleOpenPlan(
          player: currentPlayer,
          externalSubtitles: subtitleSelection.sidecarsAtOpen,
          waitForFileLoaded: false,
        );
      }

      // Versions/mediaInfo come from the committed session; rebuild so the
      // controls pick them up.
      if (mounted) {
        final mediaClient = context.tryGetMediaClientForServer(serverIdOrNull(_currentMetadata.serverId));
        _resetScrubPreviewForNewItem(metadata: _currentMetadata, mediaInfo: result.mediaInfo, mediaClient: mediaClient);

        await _initVideoFilterAndPip();
        if (!attempt.isCurrent) return;

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

            await _applySavedShaderPreset();
            await _restoreAmbientLighting();
          }
        }
        if (!attempt.isCurrent) return;

        // Track manager: owns track selection, external subtitle loading, and Plex
        // immediate stream writes. Jellyfin persists selected stream indexes through
        // playback progress reports instead.
        _trackManager = _buildTrackManager(
          forPlayer: currentPlayer,
          metadata: _currentMetadata,
          plexClient: mediaClient is PlexClient ? mediaClient : null,
          getProfileSettings: () => context.read<UserProfileProvider>().profileSettings,
          preferredAudioTrack: _preferredAudioTrack,
          // Same rule as the reload flow: a declined preference is retried by
          // the native passes instead of being frozen into off (#1785).
          preferredSubtitleTrack:
              subtitleSelection.declinedPreference ?? SubtitlePreference.trackOrNull(subtitleSelection.primaryTrack),
          preferredSecondarySubtitleTrack: SubtitlePreference.trackOrNull(subtitleSelection.secondaryTrack),
          // Same rule as the reload flow: a source-backed primary with no sidecar on a transcode is
          // burned into the picture, so nothing native is coming for it.
          primarySubtitleIsServerRendered:
              _isTranscoding &&
              subtitleSelection.primarySourceStreamId != null &&
              subtitleSelection.primarySidecar == null,
        );

        // Store only the active sidecars for re-use after backend fallback.
        _trackManager!.cacheExternalSubtitles(subtitleSelection.sidecarsAtOpen);

        final resumeForStartupFrame =
            frameRatePlan.needsStartupRefresh && externalSubtitlePlan.requiresPostOpenAdd && !wtOwnsStart;
        await _applyTracksAfterOpen(
          trackManager: _trackManager!,
          externalSubtitlePlan: externalSubtitlePlan,
          // When a startup gate below owns the resume, skip this one to
          // avoid a double-play. Post-open external-subtitle paths are the
          // exception: after they attach we must resume once so mpv can
          // produce the startup frame that the decoder-refresh gate is waiting
          // for.
          // Watch Together stays paused for the group start, so selection is
          // armed through the resume-skipped branch.
          shouldResumeAfterSubtitleLoad: () =>
              (!shouldHoldPlaybackStart || resumeForStartupFrame) && !wtOwnsStart && mounted && player == currentPlayer,
          applySelectionWhenResumeSkipped: wtOwnsStart && !shouldHoldPlaybackStart,
        );

        await _releaseFrameRateStartupGate(
          currentPlayer: currentPlayer,
          settingsService: settingsService,
          plan: frameRatePlan,
          resumeAfterStartupGate: (reason) => _finishPlaybackAfterStartupGate(
            currentPlayer: currentPlayer,
            externalSubtitlePlan: externalSubtitlePlan,
            reason: reason,
            shouldResume: !wtOwnsStart,
            watchTogetherOwnsStart: wtOwnsStart,
            wtStartupHold: wtStartupHold,
          ),
          playbackResumedForStartupFrame: resumeForStartupFrame,
        );
        // Backstop: if the gate never ran its resume path (unmounted race),
        // don't leave Watch Together readiness held forever.
        if (wtStartupHold != null && !wtStartupHold.isCompleted) {
          wtStartupHold.complete();
        }
      }
    } on PlaybackException catch (e, st) {
      appLogger.w('Playback initialization failed', error: e, stackTrace: st);
      if (attempt.isCurrent && mounted) {
        if (!primaryMediaOpened) {
          _hasFatalPlaybackError = true;
        }
        _hasFirstFrame.value = true; // Hide spinner on every current startup failure
        showErrorSnackBar(context, e.message);
      }
    } catch (e, st) {
      appLogger.e('Failed to start playback', error: e, stackTrace: st);
      if (attempt.isCurrent && mounted) {
        if (!primaryMediaOpened) {
          _hasFatalPlaybackError = true;
        }
        _hasFirstFrame.value = true; // Hide spinner on every current startup failure
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }
}
