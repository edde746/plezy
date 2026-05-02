part of '../../video_player_screen.dart';

extension _VideoPlayerPlaybackStartMethods on VideoPlayerScreenState {
  Future<void> _startPlayback() async {
    if (!mounted) return;

    // Live TV mode: bypass standard playback initialization
    if (widget.isLive) {
      try {
        _hasFirstFrame.value = false;
        await player!.requestAudioFocus();
        await _setLiveStreamOptions();

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
        await player!.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);

        _trackManager?.cacheExternalSubtitles(const []);

        await _initVideoFilterAndPip();

        if (mounted) {
          _setPlayerState(() {
            _availableVersions = [];
            _currentMediaInfo = null;
            _isPlayerInitialized = true;
          });
          _trackManager?.mediaInfo = null;
        }
      } catch (e) {
        appLogger.e('Failed to start live TV playback', error: e);
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
      Map<String, String>? streamHeaders;

      if (widget.isOffline) {
        // Offline mode: route through PlaybackInitializationService with a
        // (possibly null) cached client. The service reads cached media
        // info via the client when available, falls back to local file +
        // sidecar subtitles otherwise.
        final cachedSourceClient = _getMediaServerClient(context);
        final offlineService = PlaybackInitializationService(
          client: cachedSourceClient,
          database: context.read<AppDatabase>(),
        );
        result = await offlineService.getPlaybackData(
          metadata: _currentMetadata,
          selectedMediaIndex: widget.selectedMediaIndex,
          preferOffline: true,
        );
        if (result.videoUrl == null) {
          throw PlaybackException(t.messages.fileInfoNotAvailable);
        }
      } else {
        // Online path: `_playbackDataFuture` was kicked off in `_initializePlayer`
        // in parallel with MPV setup. Quality preset + server capabilities +
        // headers were resolved there too. Just await the result.
        streamHeaders = _streamHeaders;
        result = await _playbackDataFuture!;

        _isTranscoding = result.isTranscoding;
        _effectiveIsOffline = result.isOffline;
        _playbackPlaySessionId = result.playSessionId;
        _playbackPlayMethod = result.playMethod;
        if (result.activeAudioStreamId != null) {
          _selectedAudioStreamId = result.activeAudioStreamId;
        }

        if (result.fallbackReason != null && !_selectedQualityPreset.isOriginal) {
          if (mounted) {
            showErrorSnackBar(context, t.videoControls.transcodeUnavailableFallback);
          }
          // Reset the preset so the UI reflects what's actually playing.
          _selectedQualityPreset = TranscodeQualityPreset.original;
        }
      }

      // Primary refresh-rate path: when Plex metadata provides an fps and the
      // user has frame-rate matching on, open the player paused so the HDMI
      // refresh-rate switch can complete before any frame renders.
      final settingsService = await SettingsService.getInstance();
      final preKnownFps = result.mediaInfo?.frameRate;
      final willAutoSwitch =
          Platform.isAndroid &&
          settingsService.read(SettingsService.matchContentFrameRate) &&
          preKnownFps != null &&
          preKnownFps > 0;

      // Open video through Player
      if (result.videoUrl != null) {
        // Reset first frame flag and frame rate retry counter for new video
        _hasFirstFrame.value = false;
        _frameRateRetries = 0;
        _frameRateMatchingApplied = false;

        // Request audio focus before starting playback (Android)
        // This causes other media apps (Spotify, podcasts, etc.) to pause.
        // Fired in parallel with MPV setup in `_initializePlayer`; we await
        // the in-flight future here (usually already resolved).
        if (_audioFocusFuture != null) {
          await _audioFocusFuture;
          _audioFocusFuture = null;
        } else {
          await player!.requestAudioFocus();
        }

        // Pass resume position if available.
        // In offline mode, prefer locally tracked progress over the cached server value
        // since the user may have watched further since downloading.
        Duration? resumePosition;
        if (_isOfflinePlayback) {
          final globalKey = _currentMetadata.globalKey;
          final localOffset = await offlineWatchService.getLocalViewOffset(globalKey);
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
          await player!.setProperty(
            'stream-lavf-o',
            'reconnect=1,reconnect_on_network_error=1,reconnect_streamed=1,reconnect_delay_max=600',
          );
        }

        final hasExternalSubs = result.externalSubtitles.isNotEmpty;
        final isExoPlayer = player is PlayerAndroid;

        // ExoPlayer: attach external subs at open time so it discovers
        // them in a single prepare() — no media reload needed for selection.
        // MPV (all platforms including Android): external subs added after open via sub-add.
        await player!.open(
          Media(result.videoUrl!, start: resumePosition, headers: streamHeaders),
          play: !willAutoSwitch && (isExoPlayer || !hasExternalSubs),
          externalSubtitles: isExoPlayer && hasExternalSubs ? result.externalSubtitles : null,
        );

        // Apply subtitle styling to ExoPlayer native layer (CaptionStyleCompat + libass font scale)
        // Must be called after open() since that's when ExoPlayer initializes
        if (player is PlayerAndroid) {
          await (player as PlayerAndroid).setSubtitleStyle(
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

        if (player != null) {
          // Auto-PiP: set up callback for API 26-30 path and initial state
          if (_autoPipEnabled) {
            PipService.onAutoPipEntering = () {
              _setAndroidAutoPipTransitionInFlight(true, reason: 'native_auto_pip_entering');
              _videoFilterManager?.enterPipMode();
            };
            if (player!.state.playing) {
              unawaited(_videoPIPManager!.updateAutoPipState(isPlaying: true));
            }
          }

          // Shader Service (MPV only)
          _shaderService = ShaderService(player!);
          if (_shaderService!.isSupported) {
            // Ambient Lighting Service
            _ambientLightingService = AmbientLightingService(player!);
            _shaderService!.ambientLightingService = _ambientLightingService;
            _videoFilterManager?.ambientLightingService = _ambientLightingService;

            await _applySavedShaderPreset();
            await _restoreAmbientLighting();
          }
        }

        // Track manager: owns track selection, external subtitle loading, and Plex
        // immediate stream writes. Jellyfin persists selected stream indexes through
        // playback progress reports instead.
        final plexTrackClient = mediaClient is PlexClient ? mediaClient : null;
        _trackManager = TrackManager(
          player: player!,
          isActive: () => mounted && player != null,
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

        // MPV with external subs: add after open via sub-add,
        // opened paused to avoid race condition (issue #226)
        if (player is! PlayerAndroid && result.externalSubtitles.isNotEmpty) {
          _hasFirstFrame.value = false;
          _trackManager!.waitingForExternalSubsTrackSelection = true;

          try {
            await _trackManager!.addExternalSubtitles(result.externalSubtitles);
          } finally {
            // When willAutoSwitch the pre-playback refresh-rate block below
            // owns the resume, so skip this one to avoid a double-play.
            if (!willAutoSwitch) {
              await _trackManager!.resumeAfterSubtitleLoad();
            }
          }
        } else {
          // Android (subs attached at open time) or no external subs:
          // apply once tracks are available
          _trackManager!.applyTrackSelectionWhenReady();
        }

        // Initiate the HDMI refresh-rate switch BEFORE any frame renders.
        // The player was opened paused; setVideoFrameRate awaits the real
        // display-change event (+ settle + user delay) before returning, and
        // then we start playback — so the first frame the user sees is after
        // the switch has settled.
        if (willAutoSwitch && mounted && player != null) {
          _frameRateMatchingApplied = true;
          final delaySec = settingsService.read(SettingsService.displaySwitchDelay);
          final durationMs = _currentMetadata.durationMs ?? player!.state.duration.inMilliseconds;
          _suppressMediaPauseDuringFrameRateSwitch = true;
          Future.delayed(Duration(seconds: 2 + delaySec + 1), () {
            _suppressMediaPauseDuringFrameRateSwitch = false;
          });
          bool didSwitch = false;
          try {
            didSwitch = await player!.setVideoFrameRate(preKnownFps, durationMs, extraDelayMs: delaySec * 1000);
            // MPV video-sync tuning (no-op on ExoPlayer).
            try {
              await player!.setProperty('video-sync', 'display-tempo');
            } catch (e) {
              appLogger.d('video-sync property unsupported on this player', error: e);
            }
          } catch (e) {
            appLogger.w('Failed to apply pre-playback frame rate matching', error: e);
          }

          // Always resume — either the switch completed and we want to play,
          // or no switch was needed and we need to start playback now that the
          // preparation gate has been cleared.
          if (mounted && player != null) {
            if (player is! PlayerAndroid && result.externalSubtitles.isNotEmpty) {
              await _trackManager!.resumeAfterSubtitleLoad();
            } else {
              await player!.play();
            }
          }

          unawaited(
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Pre-playback frame rate: ${preKnownFps}fps, switched=$didSwitch, delay=${delaySec}s',
                category: 'player',
              ),
            ),
          );
        }
      }
    } on PlaybackException catch (e) {
      if (mounted) {
        _hasFirstFrame.value = true; // Hide spinner on error
        showErrorSnackBar(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        _hasFirstFrame.value = true; // Hide spinner on error
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }
}
