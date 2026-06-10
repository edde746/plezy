part of '../../video_player_screen.dart';

extension _VideoPlayerPlaybackStartMethods on VideoPlayerScreenState {
  Future<void> _startPlayback() async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return;
    final attempt = _beginPlaybackAttempt(currentPlayer);

    // Live TV mode: bypass standard playback initialization
    if (widget.isLive) {
      try {
        _hasFirstFrame.value = false;
        await currentPlayer.requestAudioFocus();
        await _setLiveStreamOptions(currentPlayer);
        if (!attempt.isCurrent) return;

        String streamUrl;
        if (_live.streamUrl != null) {
          streamUrl = _live.streamUrl!;
          _live.streamStartEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
          _live.atLiveEdge = true;
        } else {
          // Tune channel inside the player (shows loading spinner while tuning)
          final channels = widget.live?.channels;
          final channelIndex = _live.channelIndex;
          if (channels == null || channelIndex < 0 || channelIndex >= channels.length) {
            throw Exception('No channel to tune');
          }
          final channel = channels[channelIndex];
          appLogger.d('Tune: dvrKey=$_live.dvrKey channelKey=${channel.key}');
          final client = _live.client;
          if (client is! PlexClient) {
            throw StateError(
              'In-player live tuning is Plex-only; got ${client?.runtimeType ?? 'null'}. '
              'Jellyfin live TV must pass a pre-resolved liveStreamUrl via LiveTvSupport.resolveStreamUrl.',
            );
          }
          final dvrKey = _live.dvrKey;
          if (dvrKey == null) throw Exception('No DVR to tune');
          final tuneResult = await client.tuneChannel(dvrKey, channel.key);
          if (tuneResult == null) throw Exception('Failed to tune channel');

          _live.sessionIdentifier = tuneResult.sessionIdentifier;
          _live.sessionPath = tuneResult.sessionPath;
          _live.programId = tuneResult.metadata.ratingKey;
          _live.durationMs = tuneResult.metadata.duration;
          _live.captureBuffer = tuneResult.captureBuffer;
          _live.programBeginsAt = tuneResult.beginsAt;
          _live.transcodeSessionId = generateSessionIdentifier();

          // Show "Watch from Start" dialog when an existing capture session has >60s of history.
          // On a fresh tune (no active recording), the buffer is empty so this won't trigger.
          int? offsetSeconds;
          if (_live.captureBuffer != null && _live.programBeginsAt != null) {
            final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            final offsetProgramStart = _live.programBeginsAt! - _live.captureBuffer!.startedAt.round();
            // If a session recording started after current program start, offset of program start at will be negative.
            // If a session recording started before current program start, offset of program start will be positive.
            // If guide data is not available, program start will be equal to current time.
            final useProgramStart = offsetProgramStart > 0 && nowEpoch - _live.programBeginsAt! > 60;
            final effectiveStart = useProgramStart ? _live.programBeginsAt! : _live.captureBuffer!.seekableStartEpoch;
            final elapsed = nowEpoch - effectiveStart;
            appLogger.d(
              'Time-shift: buffer=${_live.captureBuffer!.seekableDurationSeconds}s, '
              'beginsAt=$_live.programBeginsAt, elapsed=${elapsed}s (need >60 for dialog)',
            );
            if (elapsed > 60) {
              final watchFromStart = await _showWatchFromStartDialog(effectiveStart, nowEpoch);
              if (!mounted) return;
              if (watchFromStart == true) {
                offsetSeconds = useProgramStart ? offsetProgramStart : _live.captureBuffer!.seekStartSeconds.round();
              }
            }
          }

          // Build the stream URL (with optional offset for time-shift)
          final streamPath = await client.buildLiveStreamPath(
            sessionPath: tuneResult.sessionPath,
            sessionIdentifier: tuneResult.sessionIdentifier,
            transcodeSessionId: _live.transcodeSessionId!,
            offsetSeconds: offsetSeconds,
          );
          if (streamPath == null || !mounted) throw Exception('Failed to build stream path');

          streamUrl = client.buildLiveStreamUrl(streamPath);
          _live.streamUrl = streamUrl;

          // Track stream start epoch for position calculations
          if (offsetSeconds != null) {
            _live.streamStartEpoch = _live.captureBuffer!.startedAt + offsetSeconds;
            _live.atLiveEdge = false;
          } else {
            _live.streamStartEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
            _live.atLiveEdge = true;
          }
        }

        _live.playbackStartTime = DateTime.now();
        await currentPlayer.setProperty('force-seekable', 'no');
        await currentPlayer.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);
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

    try {
      PlaybackContext playbackContext;

      if (_offlineLibraryMode) {
        final playbackResolver = PlaybackSourceResolver(
          serverManager: context.read<MultiServerProvider>().serverManager,
          database: context.read<AppDatabase>(),
        );
        playbackContext = await playbackResolver.resolve(
          metadata: _currentMetadata,
          selectedMediaIndex: _effectiveSelectedMediaIndex,
          selectedMediaSourceId: _selectedMediaSourceId,
          offlineLibraryMode: true,
          qualityPreset: _selectedQualityPreset,
          selectedAudioStreamId: _selectedAudioStreamId,
          sessionIdentifier: _playbackSessionIdentifier,
          transcodeSessionId: _playbackTranscodeSessionId,
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
      // Initial start has no previous session to protect, so commit as soon
      // as the resolve lands (reload-style flows commit at the open
      // boundary instead).
      _commitPlaybackSession(
        PlaybackSession.fromContext(
          playbackContext,
          requestedQualityPreset: _selectedQualityPreset,
          requestedMediaSourceId: _selectedMediaSourceId,
        ),
      );

      // Primary refresh-rate path: when metadata provides FPS, Android players
      // can switch before creating decoders. MPV still needs a startup refresh
      // when MediaCodec has already produced its first paused frame.
      final settingsService = await SettingsService.getInstance();
      if (!attempt.isCurrent) return;
      final displayCriteria = result.mediaInfo?.displayCriteria;
      final attachesSubsAtOpen = currentPlayer.attachesExternalSubtitlesAtOpen;
      final hasExternalSubs = result.externalSubtitles.isNotEmpty;
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
        hasVideoUrl: result.videoUrl != null,
        ensureAudioFocus: ensureAudioFocus,
      );
      if (frameRatePlan == null) return;
      final shouldHoldPlaybackStart = frameRatePlan.holdPlaybackStart;

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

        // Enable FFmpeg auto-reconnect for VOD streams (covers network drops
        // up to 10 min). Forwarded to the Kotlin layer on Android so MPV
        // inherits it on the ExoPlayer→MPV fallback path (see
        // _onBackendSwitched), so keep it unconditional.
        if (!_isOfflinePlayback && !widget.isLive) {
          await currentPlayer.setProperty(
            'stream-lavf-o',
            'reconnect=1,reconnect_on_network_error=1,reconnect_streamed=1,reconnect_delay_max=600',
          );
        }

        await _primeDisplayCriteria(
          player: currentPlayer,
          settingsService: settingsService,
          displayCriteria: displayCriteria,
          isTranscoding: result.isTranscoding,
        );

        final shouldAutoPlay = !shouldHoldPlaybackStart && (attachesSubsAtOpen || !hasExternalSubs);
        frameRatePlan.armStartupRefreshGate(currentPlayer);

        // ExoPlayer: attach external subs at open time so it discovers
        // them in a single prepare() — no media reload needed for selection.
        // MPV (all platforms including Android): external subs added after open via sub-add.
        final openTiming = _playbackOpenTiming(
          backend: _currentMetadata.backend,
          isTranscoding: result.isTranscoding,
          resumePosition: resumePosition,
          durationMs: _currentMetadata.durationMs,
        );
        final didOpen = await _openMediaOnPlayer(
          player: currentPlayer,
          settingsService: settingsService,
          videoUrl: result.videoUrl!,
          isTranscoding: result.isTranscoding,
          timing: openTiming,
          headers: streamHeaders,
          play: shouldAutoPlay,
          externalSubtitlesAtOpen: attachesSubsAtOpen && hasExternalSubs ? result.externalSubtitles : null,
          shouldContinue: () => attempt.isCurrent,
        );
        if (!didOpen || !attempt.isCurrent) return;

        // Attach player to Watch Together session for sync (if in session)
        if (mounted && !_isOfflinePlayback) {
          _attachToWatchTogetherSession();
          _notifyWatchTogetherMediaChange();
        }
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
            final pipManager = _videoPIPManager;
            if (currentPlayer.state.playing && pipManager != null) {
              unawaited(pipManager.updateAutoPipState(isPlaying: true));
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
          preferredSubtitleTrack: _preferredSubtitleTrack,
          preferredSecondarySubtitleTrack: _preferredSecondarySubtitleTrack,
        );

        // Store external subtitles for re-use after backend fallback
        _trackManager!.cacheExternalSubtitles(result.externalSubtitles);

        await _applyTracksAfterOpen(
          forPlayer: currentPlayer,
          trackManager: _trackManager!,
          externalSubtitles: result.externalSubtitles,
          // When a startup gate below owns the resume, skip this one to
          // avoid a double-play.
          shouldResumeAfterSubtitleLoad: () => !shouldHoldPlaybackStart && mounted && player == currentPlayer,
        );

        await _releaseFrameRateStartupGate(
          currentPlayer: currentPlayer,
          settingsService: settingsService,
          plan: frameRatePlan,
          resumeAfterStartupGate: (reason) => _resumeAfterFrameRateStartupGate(
            currentPlayer: currentPlayer,
            attachesSubsAtOpen: attachesSubsAtOpen,
            hasExternalSubs: hasExternalSubs,
            reason: reason,
          ),
        );
      }
    } on PlaybackException catch (e, st) {
      appLogger.w('Playback initialization failed', error: e, stackTrace: st);
      if (mounted) {
        _hasFirstFrame.value = true; // Hide spinner on error
        showErrorSnackBar(context, e.message);
      }
    } catch (e, st) {
      appLogger.e('Failed to start playback', error: e, stackTrace: st);
      if (mounted) {
        _hasFirstFrame.value = true; // Hide spinner on error
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }
}
