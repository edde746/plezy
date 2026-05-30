part of '../../video_player_screen.dart';

extension _VideoPlayerPlaybackStartMethods on VideoPlayerScreenState {
  Future<void> _startPlayback() async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return;
    final playbackGeneration = _beginPlaybackGeneration();

    // Live TV mode: bypass standard playback initialization
    if (widget.isLive) {
      try {
        _hasFirstFrame.value = false;
        await currentPlayer.requestAudioFocus();
        await _setLiveStreamOptions();
        if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;

        String streamUrl;
        if (_liveStreamUrl != null) {
          streamUrl = _liveStreamUrl!;
          _streamStartEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
          _isAtLiveEdge = true;
        } else {
          // Tune channel inside the player (shows loading spinner while tuning)
          final channels = widget.liveChannels;
          final channelIndex = _liveChannelIndex;
          if (channels == null || channelIndex < 0 || channelIndex >= channels.length) {
            throw Exception('No channel to tune');
          }
          final channel = channels[channelIndex];
          appLogger.d('Tune: dvrKey=$_liveDvrKey channelKey=${channel.key}');
          final client = _liveClient;
          if (client is! PlexClient) {
            throw StateError(
              'In-player live tuning is Plex-only; got ${client?.runtimeType ?? 'null'}. '
              'Jellyfin live TV must pass a pre-resolved liveStreamUrl via LiveTvSupport.resolveStreamUrl.',
            );
          }
          final dvrKey = _liveDvrKey;
          if (dvrKey == null) throw Exception('No DVR to tune');
          final tuneResult = await client.tuneChannel(dvrKey, channel.key);
          if (tuneResult == null) throw Exception('Failed to tune channel');

          _liveSessionIdentifier = tuneResult.sessionIdentifier;
          _liveSessionPath = tuneResult.sessionPath;
          _liveProgramId = tuneResult.metadata.ratingKey;
          _liveDurationMs = tuneResult.metadata.duration;
          _captureBuffer = tuneResult.captureBuffer;
          _programBeginsAt = tuneResult.beginsAt;
          _transcodeSessionId = generateSessionIdentifier();

          // Show "Watch from Start" dialog when an existing capture session has >60s of history.
          // On a fresh tune (no active recording), the buffer is empty so this won't trigger.
          int? offsetSeconds;
          if (_captureBuffer != null && _programBeginsAt != null) {
            final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            final offsetProgramStart = _programBeginsAt! - _captureBuffer!.startedAt.round();
            // If a session recording started after current program start, offset of program start at will be negative.
            // If a session recording started before current program start, offset of program start will be positive.
            // If guide data is not available, program start will be equal to current time.
            final useProgramStart = offsetProgramStart > 0 && nowEpoch - _programBeginsAt! > 60;
            final effectiveStart = useProgramStart ? _programBeginsAt! : _captureBuffer!.seekableStartEpoch;
            final elapsed = nowEpoch - effectiveStart;
            appLogger.d(
              'Time-shift: buffer=${_captureBuffer!.seekableDurationSeconds}s, '
              'beginsAt=$_programBeginsAt, elapsed=${elapsed}s (need >60 for dialog)',
            );
            if (elapsed > 60) {
              final watchFromStart = await _showWatchFromStartDialog(effectiveStart, nowEpoch);
              if (!mounted) return;
              if (watchFromStart == true) {
                offsetSeconds = useProgramStart ? offsetProgramStart : _captureBuffer!.seekStartSeconds.round();
              }
            }
          }

          // Build the stream URL (with optional offset for time-shift)
          final streamPath = await client.buildLiveStreamPath(
            sessionPath: tuneResult.sessionPath,
            sessionIdentifier: tuneResult.sessionIdentifier,
            transcodeSessionId: _transcodeSessionId!,
            offsetSeconds: offsetSeconds,
          );
          if (streamPath == null || !mounted) throw Exception('Failed to build stream path');

          streamUrl = client.buildLiveStreamUrl(streamPath);
          _liveStreamUrl = streamUrl;

          // Track stream start epoch for position calculations
          if (offsetSeconds != null) {
            _streamStartEpoch = _captureBuffer!.startedAt + offsetSeconds;
            _isAtLiveEdge = false;
          } else {
            _streamStartEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
            _isAtLiveEdge = true;
          }
        }

        _livePlaybackStartTime = DateTime.now();
        await currentPlayer.setProperty('force-seekable', 'no');
        await currentPlayer.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);
        if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;

        _trackManager?.cacheExternalSubtitles(const []);

        await _initVideoFilterAndPip();
        if (!mounted || player != currentPlayer) return;

        if (mounted) {
          _setPlayerState(() {
            _availableVersions = [];
            _currentMediaInfo = null;
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
      PlaybackInitializationResult result;
      PlaybackContext playbackContext;
      Map<String, String>? streamHeaders;

      if (widget.isOffline) {
        final playbackResolver = PlaybackSourceResolver(
          serverManager: context.read<MultiServerProvider>().serverManager,
          database: context.read<AppDatabase>(),
        );
        playbackContext = await playbackResolver.resolve(
          metadata: _currentMetadata,
          selectedMediaIndex: widget.selectedMediaIndex,
          selectedMediaSourceId: widget.selectedMediaSourceId,
          offlineLibraryMode: true,
          qualityPreset: _selectedQualityPreset,
          selectedAudioStreamId: _selectedAudioStreamId,
          sessionIdentifier: _playbackSessionIdentifier,
          transcodeSessionId: _playbackTranscodeSessionId,
        );
        result = playbackContext.result;
        if (result.videoUrl == null) {
          throw PlaybackException(t.messages.fileInfoNotAvailable);
        }
        streamHeaders = playbackContext.streamHeaders;
        _isTranscoding = result.isTranscoding;
        _effectiveIsOffline = result.isOffline;
        _playbackPlaySessionId = result.playSessionId;
        _playbackPlayMethod = result.playMethod;
        _selectedAudioStreamId = result.activeAudioStreamId;
      } else {
        // Online path: `_playbackDataFuture` was kicked off in `_initializePlayer`
        // in parallel with MPV setup. Quality preset + server capabilities +
        // headers were resolved there too. Just await the result.
        streamHeaders = _streamHeaders;
        final playbackDataFuture = _playbackDataFuture;
        if (playbackDataFuture == null) {
          throw StateError('Playback data was not prepared before playback start');
        }
        playbackContext = await playbackDataFuture;
        result = playbackContext.result;
        if (!mounted || player != currentPlayer) return;
        streamHeaders = playbackContext.streamHeaders;

        _isTranscoding = result.isTranscoding;
        _effectiveIsOffline = result.isOffline;
        _playbackPlaySessionId = result.playSessionId;
        _playbackPlayMethod = result.playMethod;
        _selectedAudioStreamId = result.activeAudioStreamId;

        if (result.fallbackReason != null && !_selectedQualityPreset.isOriginal) {
          if (mounted) {
            showErrorSnackBar(context, t.videoControls.transcodeUnavailableFallback);
          }
          // Reset the preset so the UI reflects what's actually playing.
          _selectedQualityPreset = TranscodeQualityPreset.original;
        }
      }
      _playbackContext = playbackContext;

      // Primary refresh-rate path: when metadata provides FPS, Android players
      // can switch before creating decoders. MPV still needs a startup refresh
      // when MediaCodec has already produced its first paused frame.
      final settingsService = await SettingsService.getInstance();
      if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;
      final displayCriteria = result.mediaInfo?.displayCriteria;
      final preKnownFps = displayCriteria?.fps;
      final willAutoSwitch =
          Platform.isAndroid &&
          settingsService.read(SettingsService.matchContentFrameRate) &&
          preKnownFps != null &&
          preKnownFps > 0;
      final isExoPlayer = currentPlayer is PlayerAndroid;
      final isAndroidMpv = Platform.isAndroid && !isExoPlayer;
      final needsExoPlayerFrameRateStartup = willAutoSwitch && isExoPlayer && result.videoUrl != null;
      final needsAndroidMpvFrameRateStartup = willAutoSwitch && isAndroidMpv && result.videoUrl != null;
      var didPreLoadFrameRateSwitch = false;
      var didPreOpenExoFrameRateSwitch = false;
      var preOpenExoFrameRateHandled = false;
      var needsPostOpenFrameRateSwitch =
          willAutoSwitch && !needsAndroidMpvFrameRateStartup && !needsExoPlayerFrameRateStartup;
      var needsAndroidMpvStartupRefresh = false;
      final hasExternalSubs = result.externalSubtitles.isNotEmpty;
      Future<bool>? androidMpvStartupReady;
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

      // MPV on Android can decode and present its first paused frame before a
      // post-open display switch settles. Switch first when metadata already
      // gives us the FPS so MediaCodec starts after the display mode change.
      if (needsAndroidMpvFrameRateStartup) {
        final delaySec = settingsService.read(SettingsService.displaySwitchDelay);
        final durationMs = _currentMetadata.durationMs ?? currentPlayer.state.duration.inMilliseconds;
        _suppressMediaPauseDuringFrameRateSwitch = true;
        Future.delayed(Duration(seconds: 2 + delaySec + 1), () {
          _suppressMediaPauseDuringFrameRateSwitch = false;
        });
        try {
          appLogger.d(
            'Frame rate matching: pre-load MPV switch to ${preKnownFps}fps '
            '(duration: ${durationMs}ms, delay=${delaySec}s)',
          );
          didPreLoadFrameRateSwitch = await currentPlayer.setVideoFrameRate(
            preKnownFps,
            durationMs,
            extraDelayMs: delaySec * 1000,
          );
          if (!mounted || player != currentPlayer) return;
          if (didPreLoadFrameRateSwitch) {
            _frameRateMatchingApplied = true;
            needsAndroidMpvStartupRefresh = true;
          }
          appLogger.d(
            'Frame rate matching: pre-load MPV switch complete '
            '(switched=$didPreLoadFrameRateSwitch, delay=${delaySec}s, '
            'startupRefresh=$needsAndroidMpvStartupRefresh)',
          );
        } catch (e) {
          appLogger.w('Failed to apply pre-load MPV frame rate matching', error: e);
          needsPostOpenFrameRateSwitch = true;
          needsAndroidMpvStartupRefresh = false;
        }
      }

      // ExoPlayer prepares AudioTrack during open() even when opened paused.
      // On Shield/AVR chains, switching HDMI refresh rate after that can break
      // direct passthrough, so switch before ExoPlayer creates renderers.
      if (needsExoPlayerFrameRateStartup) {
        final delaySec = settingsService.read(SettingsService.displaySwitchDelay);
        final durationMs = _currentMetadata.durationMs ?? currentPlayer.state.duration.inMilliseconds;
        _suppressMediaPauseDuringFrameRateSwitch = true;
        Future.delayed(Duration(seconds: 2 + delaySec + 1), () {
          _suppressMediaPauseDuringFrameRateSwitch = false;
        });
        try {
          await ensureAudioFocus();
          if (!mounted || player != currentPlayer) return;
          appLogger.d(
            'Frame rate matching: pre-open ExoPlayer switch to ${preKnownFps}fps '
            '(duration: ${durationMs}ms, delay=${delaySec}s)',
          );
          didPreOpenExoFrameRateSwitch = await currentPlayer.setVideoFrameRate(
            preKnownFps,
            durationMs,
            extraDelayMs: delaySec * 1000,
          );
          if (!mounted || player != currentPlayer) return;
          preOpenExoFrameRateHandled = true;
          appLogger.d(
            'Frame rate matching: pre-open ExoPlayer switch complete '
            '(switched=$didPreOpenExoFrameRateSwitch, delay=${delaySec}s)',
          );
        } catch (e) {
          appLogger.w('Failed to apply pre-open ExoPlayer frame rate matching', error: e);
          needsPostOpenFrameRateSwitch = true;
          preOpenExoFrameRateHandled = false;
        }
      }

      final shouldHoldPlaybackStart = needsPostOpenFrameRateSwitch || needsAndroidMpvStartupRefresh;
      Duration? resumePosition;

      // Open video through Player
      if (result.videoUrl != null) {
        // Reset first frame flag and frame rate retry counter for new video
        _hasFirstFrame.value = false;
        _frameRateRetries = 0;
        _frameRateMatchingApplied = false;
        if (didPreLoadFrameRateSwitch || needsAndroidMpvFrameRateStartup || preOpenExoFrameRateHandled) {
          _frameRateMatchingApplied = true;
        }

        // Request audio focus before starting playback (Android)
        // This causes other media apps (Spotify, podcasts, etc.) to pause.
        // Fired in parallel with MPV setup in `_initializePlayer`; we await
        // the in-flight future here (usually already resolved).
        await ensureAudioFocus();
        if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;

        // Pass resume position if available.
        // In offline mode, prefer locally tracked progress over the cached server value
        // since the user may have watched further since downloading.
        if (_isOfflinePlayback) {
          final globalKey = _currentMetadata.globalKey;
          final localOffset = await offlineWatchService.getLocalViewOffset(globalKey);
          if (!mounted || player != currentPlayer) return;
          if (localOffset != null && localOffset > 0) {
            resumePosition = Duration(milliseconds: localOffset);
            appLogger.d('Resuming offline playback from local progress: ${localOffset}ms');
          }
        }
        resumePosition ??= _currentMetadata.viewOffsetMs != null
            ? Duration(milliseconds: _currentMetadata.viewOffsetMs!)
            : null;

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

        await currentPlayer.setDisplayCriteria(
          !result.isTranscoding && displayCriteria?.canPrimeNativeDisplayCriteria == true ? displayCriteria : null,
        );

        final shouldAutoPlay = !shouldHoldPlaybackStart && (isExoPlayer || !hasExternalSubs);
        if (needsAndroidMpvStartupRefresh) {
          appLogger.d('Frame rate matching: opening Android MPV paused for startup decoder refresh');
          androidMpvStartupReady = currentPlayer.streams.playbackRestart.first
              .then((_) => true)
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  appLogger.w('Timed out waiting for Android MPV startup frame before decoder refresh');
                  return false;
                },
              );
        }

        // ExoPlayer: attach external subs at open time so it discovers
        // them in a single prepare() — no media reload needed for selection.
        // MPV (all platforms including Android): external subs added after open via sub-add.
        final openTiming = _playbackOpenTiming(
          backend: _currentMetadata.backend,
          isTranscoding: result.isTranscoding,
          resumePosition: resumePosition,
          durationMs: _currentMetadata.durationMs,
        );
        // Transcode streams can be seekable even when MPV cannot prove it
        // from response headers. Reset non-transcodes so live/direct/offline
        // streams keep native seekability detection.
        await currentPlayer.setProperty('force-seekable', result.isTranscoding ? 'yes' : 'no');
        await currentPlayer.open(
          Media(result.videoUrl!, start: openTiming.mediaStart, headers: streamHeaders),
          play: shouldAutoPlay,
          externalSubtitles: isExoPlayer && hasExternalSubs ? result.externalSubtitles : null,
          timelineOffset: openTiming.timelineOffset,
          timelineDuration: openTiming.timelineDuration,
        );
        if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;

        // Apply subtitle styling to ExoPlayer native layer (CaptionStyleCompat + libass font scale)
        // Must be called after open() since that's when ExoPlayer initializes
        if (currentPlayer is PlayerAndroid) {
          await currentPlayer.setSubtitleStyle(
            fontSize: settingsService.read(SettingsService.subtitleFontSize).toDouble(),
            textColor: settingsService.read(SettingsService.subtitleTextColor),
            borderSize: settingsService.read(SettingsService.subtitleBorderSize).toDouble(),
            borderColor: settingsService.read(SettingsService.subtitleBorderColor),
            bgColor: settingsService.read(SettingsService.subtitleBackgroundColor),
            bgOpacity: settingsService.read(SettingsService.subtitleBackgroundOpacity),
            subtitlePosition: settingsService.read(SettingsService.subtitlePosition),
            bold: settingsService.read(SettingsService.subtitleBold),
            italic: settingsService.read(SettingsService.subtitleItalic),
          );
        }

        // Attach player to Watch Together session for sync (if in session)
        if (mounted && !_isOfflinePlayback) {
          _attachToWatchTogetherSession();
          _notifyWatchTogetherMediaChange();
        }
      }

      // Update available versions from the playback data
      if (mounted) {
        _setPlayerState(() {
          _availableVersions = result.availableVersions;
          _currentMediaInfo = result.mediaInfo;
          _scrubPreviewSource?.dispose();
          _scrubPreviewSource = null;
        });

        // Backend-neutral scrub-thumbnail load. The factory dispatches to
        // BIF (Plex) or trickplay sprite sheets (Jellyfin) and returns null
        // when the inputs aren't sufficient. Guard against media-change
        // races during the async load.
        final mediaClient = context.tryGetMediaClientForServer(_currentMetadata.serverId);
        final mediaInfoAtStart = _currentMediaInfo;
        if (mediaInfoAtStart != null && !_isOfflinePlayback && mediaClient != null) {
          unawaited(
            mediaClient
                .createScrubPreviewSource(item: _currentMetadata, mediaSource: mediaInfoAtStart)
                .then((service) {
                  if (service == null) return;
                  if (mounted && identical(_currentMediaInfo, mediaInfoAtStart)) {
                    _setPlayerState(() => _scrubPreviewSource = service);
                  } else {
                    service.dispose();
                  }
                })
                .catchError((e, st) {
                  appLogger.w('Scrub preview load failed', error: e, stackTrace: st);
                }),
          );
        }

        await _initVideoFilterAndPip();
        if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;

        if (player == currentPlayer) {
          // Auto-PiP: set up callback for API 26-30 path and initial state
          if (_autoPipEnabled) {
            final autoPipEnteringCallback = () {
              if (!mounted || player != currentPlayer) return;
              _setAndroidAutoPipTransitionInFlight(true, reason: 'native_auto_pip_entering');
              _preparePipFiltersForEntry();
            };
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
        if (!_isCurrentPlaybackGeneration(playbackGeneration, currentPlayer)) return;

        // Track manager: owns track selection, external subtitle loading, and Plex
        // immediate stream writes. Jellyfin persists selected stream indexes through
        // playback progress reports instead.
        final plexTrackClient = mediaClient is PlexClient ? mediaClient : null;
        _trackManager = TrackManager(
          player: currentPlayer,
          isActive: () => mounted && player == currentPlayer,
          persistTrackPreference: plexTrackClient != null ? _plexTrackPersister(() => plexTrackClient) : null,
          getProfileSettings: () => context.read<UserProfileProvider>().profileSettings,
          waitForProfileSettings: _waitForProfileSettingsIfNeeded,
          metadata: _currentMetadata,
          mediaInfo: _currentMediaInfo,
          preferredAudioTrack: widget.preferredAudioTrack,
          preferredSubtitleTrack: widget.preferredSubtitleTrack,
          preferredSecondarySubtitleTrack: widget.preferredSecondarySubtitleTrack,
          showMessage: (message, {duration}) {
            if (mounted) showAppSnackBar(context, message, duration: duration);
          },
        );

        // Store external subtitles for re-use after backend fallback
        _trackManager!.cacheExternalSubtitles(result.externalSubtitles);

        Future<void> resumeAfterStartupGate(String reason) async {
          if (!mounted || player != currentPlayer) return;
          final trackManager = _trackManager;
          if (trackManager == null) return;
          appLogger.d('Frame rate matching: resuming playback after $reason');
          if (currentPlayer is! PlayerAndroid && hasExternalSubs) {
            await trackManager.resumeAfterSubtitleLoad();
          } else {
            await currentPlayer.play();
          }
        }

        // MPV with external subs: add after open via sub-add,
        // opened paused to avoid race condition (issue #226)
        if (currentPlayer is! PlayerAndroid && result.externalSubtitles.isNotEmpty) {
          _hasFirstFrame.value = false;
          _trackManager!.waitingForExternalSubsTrackSelection = true;

          try {
            await _trackManager!.addExternalSubtitles(result.externalSubtitles);
          } finally {
            // When a startup gate below owns the resume,
            // skip this one to avoid a double-play.
            if (!shouldHoldPlaybackStart && mounted && player == currentPlayer) {
              await _trackManager!.resumeAfterSubtitleLoad();
            }
          }
        } else {
          // Android (subs attached at open time) or no external subs:
          // apply once tracks are available
          _trackManager!.applyTrackSelectionWhenReady();
        }

        // Fallback refresh-rate path. The player was opened paused;
        // setVideoFrameRate awaits the real display-change event (+ settle +
        // user delay) before returning, then we start playback.
        if (needsPostOpenFrameRateSwitch && mounted && player == currentPlayer) {
          _frameRateMatchingApplied = true;
          final delaySec = settingsService.read(SettingsService.displaySwitchDelay);
          final durationMs = _currentMetadata.durationMs ?? currentPlayer.state.duration.inMilliseconds;
          _suppressMediaPauseDuringFrameRateSwitch = true;
          Future.delayed(Duration(seconds: 2 + delaySec + 1), () {
            _suppressMediaPauseDuringFrameRateSwitch = false;
          });
          bool didSwitch = false;
          try {
            didSwitch = await currentPlayer.setVideoFrameRate(preKnownFps!, durationMs, extraDelayMs: delaySec * 1000);
            if (!mounted || player != currentPlayer) return;
            if (didSwitch) {
              await _refreshAndroidMpvDecoderAfterFrameRateSwitch(reason: 'post-open frame rate switch');
            }
          } catch (e) {
            appLogger.w('Failed to apply pre-playback frame rate matching', error: e);
          }

          // Always resume — either the switch completed and we want to play,
          // or no switch was needed and we need to start playback now that the
          // preparation gate has been cleared.
          await resumeAfterStartupGate('post-open frame rate switch');

          unawaited(
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Pre-playback frame rate: ${preKnownFps}fps, switched=$didSwitch, delay=${delaySec}s',
                category: 'player',
              ),
            ),
          );
        } else if (needsAndroidMpvStartupRefresh && mounted && player == currentPlayer) {
          appLogger.d('Frame rate matching: waiting for Android MPV startup frame before decoder refresh');
          final startupReady = androidMpvStartupReady == null ? false : await androidMpvStartupReady;
          if (mounted && player == currentPlayer) {
            if (startupReady) {
              await Future<void>.delayed(const Duration(milliseconds: 100));
              await _refreshAndroidMpvDecoderAfterFrameRateSwitch(reason: 'pre-load frame rate startup');
              await resumeAfterStartupGate('startup decoder refresh');
            } else {
              appLogger.w('Frame rate matching: skipping Android MPV decoder refresh because startup frame timed out');
              await resumeAfterStartupGate('startup frame timeout');
            }
          }

          unawaited(
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Android MPV startup decoder refresh after pre-load frame-rate switch',
                category: 'player',
              ),
            ),
          );
        }
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
