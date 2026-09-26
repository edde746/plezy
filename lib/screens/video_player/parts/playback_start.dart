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
    _dismissPlaybackFailure();
    // 503s observed from here on belong to this attempt's open.
    _http503Watchdog.disarm();

    // Live TV mode: bypass standard playback initialization
    if (widget.isLive) {
      // Owned until the start commits or fails: a zap from a source that
      // does not wait for the on-screen controls (OS media session, companion
      // remote) would otherwise tune alongside it, and whichever adopted last
      // would orphan the other's session. The attempt above idled the gate.
      final startLease = _transitionGate.tryAcquire(PlaybackTransition.startingLive);
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
            // A launcher/automation deep link may pre-answer the prompt.
            final bool? watchFromStart;
            switch (widget.live!.startPosition) {
              case LiveTvStartPosition.beginning:
                watchFromStart = true;
              case LiveTvStartPosition.live:
                watchFromStart = false;
              case LiveTvStartPosition.ask:
                widget.launchObserver?.mark('blocked', blocker: 'confirmationRequired');
                watchFromStart = await _showWatchFromStartDialog(effectiveStart, nowEpoch);
                widget.launchObserver?.mark('opening');
                if (!mounted || !attempt.isCurrent) return;
            }
            if (watchFromStart == true) {
              offsetSeconds = useProgramStart ? offsetProgramStart : captureBuffer.seekStartSeconds.round();
            }
          }
        }

        // Build the stream URL (with optional offset for time-shift)
        final streamUrl = await session.streamUrlAt(offsetSeconds: offsetSeconds);
        if (!attempt.isCurrent) return;
        if (streamUrl == null || !mounted) {
          throw PlaybackException(t.liveTv.failedToBuildStreamUrl, reason: PlaybackFailureReason.noPlayableSource);
        }

        // Track the requested epoch separately from MPV's source-local clock.
        int? targetEpoch;
        if (offsetSeconds != null) {
          targetEpoch = (captureBuffer!.startedAt + offsetSeconds).round();
          if (currentPlayer is! PlayerNative) {
            _live.streamStartEpoch = captureBuffer.startedAt + offsetSeconds;
          }
          _live.atLiveEdge = false;
          _live.playbackStartTime = DateTime.now();
        } else {
          _live.markStreamRestartedAtLiveEdge(captureBuffer);
          targetEpoch = captureBuffer == null ? null : _live.streamStartEpoch.round();
        }

        await _openLiveStream(
          currentPlayer,
          streamUrl,
          targetEpoch: targetEpoch,
          play: !PlatformDetector.isAutomotive(),
          timeShifted: offsetSeconds != null,
        );
        if (!attempt.isCurrent) return;

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
          showErrorSnackBar(context, t.liveTv.playbackStartFailed(reason: localizedErrorReason(e)));
          unawaited(_handleBackButton());
        }
      } finally {
        if (startLease != null) _transitionGate.release(startLease);
      }
      return;
    }

    // Remembered before anything can fail so the failure view's Retry can
    // re-run exactly this open, resolve included.
    _currentOpenRequest = _PlaybackOpenRequest(
      metadata: _currentMetadata,
      mediaIndex: _effectiveSelectedMediaIndex,
      mediaSourceId: _requestedMediaSourceId,
      qualityPreset: _selectedQualityPreset,
      audioStreamId: _selectedAudioStreamId,
      resumePosition: widget.initialPosition,
    );

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

      // Display matching: mpv and Apple TV open paused and negotiate from the
      // decoded stream at the first frame; ExoPlayer switches before creating
      // its decoders when metadata provides an fps.
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
      MediaServerClient? mediaClientForTracks;

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
        mediaClient: () => mediaClientForTracks,
        getProfileSettings: () => context.read<AccountPreferencesController>().activePreferences,
        preferredAudioTrack: _preferredAudioTrack,
        primarySubtitleTranscoding: () => _isTranscoding,
        ensureAudioFocus: ensureAudioFocus,
        clearFirstFrameForOpen: true,
        deferAutomotiveStart: true,
        beforeColorHint: () async {
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
          mediaClientForTracks = mediaClient;
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
              // Applied at the first frame, once mpv reports the picture
              // geometry — see [VisualEffectsController.armAmbientRestore].
              _visualEffects.armAmbientRestore();
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
      if (attempt.isCurrent && mounted) _reportStartFailure(e.message, primaryMediaOpened: primaryMediaOpened);
    } catch (e, st) {
      if (attempt.isCurrent) widget.launchObserver?.mark('failed', failure: 'playbackFailed');
      appLogger.e('Failed to start playback', error: e, stackTrace: st);
      if (attempt.isCurrent && mounted) {
        // The init sentinel carries no prose — the UI owns the wording.
        _reportStartFailure(
          e is PlayerInitializationException
              ? t.messages.playbackFailed
              : t.messages.playbackFailedDetail(error: _redactPlayerError(e.toString())),
          primaryMediaOpened: primaryMediaOpened,
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

  /// A current start threw. Before the backend took the file there is nothing
  /// on screen but a spinner, so the failure view replaces it — a snackbar
  /// would leave a dead black player behind it. After the open (track setup,
  /// services) the picture may well be playing, so the error is only
  /// reported. A backend verdict that already raised the view keeps its
  /// more specific message.
  void _reportStartFailure(String message, {required bool primaryMediaOpened}) {
    if (primaryMediaOpened) {
      _firstFrame.forceUiReadyOnFailure();
      showErrorSnackBar(context, message);
      return;
    }
    _hasFatalPlaybackError = true;
    if (_playbackFailureMessage == null) _presentPlaybackFailure(message);
  }
}
