part of '../../video_player_screen.dart';

/// Fallback for OS skip commands that arrive without an interval (the
/// platforms normally send one — Android hardcodes 15s).
const _defaultMediaControlSkip = Duration(seconds: 15);

extension _VideoPlayerPlaybackServiceMethods on VideoPlayerScreenState {
  void _queueScrubPreviewLoad({
    required MediaItem metadata,
    required MediaSourceInfo? mediaInfo,
    required MediaServerClient? mediaClient,
  }) {
    if (mediaInfo == null || _isOfflinePlayback || mediaClient == null) return;

    final mediaInfoAtStart = mediaInfo;
    final metadataAtStart = metadata;
    unawaited(
      mediaClient
          .createScrubPreviewSource(item: metadataAtStart, mediaSource: mediaInfoAtStart)
          .then((service) {
            if (service == null) return;
            // Keyed on item + part rather than session identity: the preview
            // is per part, so a load that outlives a same-part source switch
            // (quality/audio) still applies.
            if (mounted &&
                _currentMetadata.globalKey == metadataAtStart.globalKey &&
                _currentMediaInfo?.partId == mediaInfoAtStart.partId) {
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

  Future<void> _markFirstFrameReady(Player currentPlayer, SettingsService settingsService) async {
    if (!mounted || player != currentPlayer || _hasRenderedFirstFrame || _hasFatalPlaybackError) return;

    _hasRenderedFirstFrame = true;
    _hasFirstFrame.value = true;
    unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'First frame ready', category: 'player')));
    final progressTracker = _progressTracker;
    if (progressTracker != null && currentPlayer.state.isActive) {
      unawaited(progressTracker.sendProgress('playing'));
    }

    if (Platform.isAndroid && settingsService.read(SettingsService.matchContentFrameRate)) {
      await _applyFrameRateMatching();
    }

    if (Platform.isWindows && _displayModeService != null) {
      await _applyWindowsDisplayMatching();
    }
  }

  Future<void> _wirePlayerStreams({
    required Player currentPlayer,
    required SettingsService settingsService,
    required bool useExoPlayer,
  }) async {
    // Re-wire scope: exactly the nine subscriptions re-created below. The
    // media-controls listeners belong to _setupMediaControls and the
    // sleep-timer/Apple TV ones to initState; both outlive a re-wire.
    await Future.wait<void>([
      if (_playingSubscription != null) _playingSubscription!.cancel(),
      if (_completedSubscription != null) _completedSubscription!.cancel(),
      if (_errorSubscription != null) _errorSubscription!.cancel(),
      if (_logSubscription != null) _logSubscription!.cancel(),
      if (_backendSwitchedSubscription != null) _backendSwitchedSubscription!.cancel(),
      if (_bufferingSubscription != null) _bufferingSubscription!.cancel(),
      if (_serverStatusSubscription != null) _serverStatusSubscription!.cancel(),
      if (_playbackRestartSubscription != null) _playbackRestartSubscription!.cancel(),
      if (_positionSubscription != null) _positionSubscription!.cancel(),
    ]);
    if (!mounted || player != currentPlayer) return;
    int? lastObservedPositionMs;

    _playingSubscription = currentPlayer.streams.playing.listen(_onPlayingStateChanged);

    _completedSubscription = currentPlayer.streams.completed.listen((done) {
      // completed=false means a file (re)loaded after a reconnect-seek or fresh
      // open — re-arm the end-of-video latch so the real EOF can still show Play
      // Next. But only when playback is clear of the end region: a stray
      // completed=false while parked at EOF must NOT re-arm, or the position
      // listener would immediately re-fire the Play Next prompt.
      if (!done) {
        lastObservedPositionMs = null;
        final durMs = currentPlayer.state.duration.inMilliseconds;
        final posMs = currentPlayer.state.position.inMilliseconds;
        if (durMs <= 0 || posMs < durMs - _completionLatch.rearmWindowMs) {
          _rearmCompletionLatch();
        }
      }
      // A mid-file EOF is the stream dying under us (#1520), not the media
      // ending: it must never mark the item watched, prompt Play Next, or
      // exit a movie. Intercepted here and not inside _onVideoCompleted
      // because the credits-marker auto-skip legitimately calls
      // _onVideoCompleted from mid-credits positions.
      if (done && _interceptSpuriousEof(currentPlayer)) return;
      _onVideoCompleted(done);
    });

    _errorSubscription = currentPlayer.streams.error.listen(_onPlayerError);

    // warn is included so we can catch ffmpeg's "HTTP error 4xx/5xx" line in
    // _onPlayerLog — the error-level log that follows omits the status code.
    _logSubscription = currentPlayer.streams.log
        .where((log) => const {PlayerLogLevel.fatal, PlayerLogLevel.error, PlayerLogLevel.warn}.contains(log.level))
        .listen(_onPlayerLog);

    if (Platform.isAndroid && useExoPlayer) {
      _backendSwitchedSubscription = currentPlayer.streams.backendSwitched.listen((_) => _onBackendSwitched());
    }

    _bufferingSubscription = currentPlayer.streams.buffering.listen((isBuffering) {
      _isBuffering.value = isBuffering;
    });

    // When server comes back online while buffering, force mpv to reconnect
    // immediately instead of waiting for ffmpeg's exponential backoff.
    if (!_isOfflinePlayback && !widget.isLive) {
      final serverId = _currentMetadata.serverId;
      if (serverId != null) {
        final serverManager = context.read<MultiServerProvider>().serverManager;
        bool wasOffline = false;
        _serverStatusSubscription = serverManager.statusStream.listen((statusMap) {
          final isOnline = statusMap[serverId] == true;
          if (!isOnline) {
            wasOffline = true;
          } else if (wasOffline && (_isBuffering.value || _spuriousEofRecoveryParked)) {
            wasOffline = false;
            if (_spuriousEofRecoveryParked) {
              // A parked stream is dead server-side; a seek-in-place would
              // land in the drained cache — only a fresh resolve replaces it.
              unawaited(_retrySpuriousEofRecovery(reason: 'server back online'));
            } else {
              _forceStreamReconnect();
            }
          }
        });
      }
    }

    _playbackRestartSubscription = currentPlayer.streams.playbackRestart.listen((_) async {
      if (!mounted || player != currentPlayer) return;
      _lastLogError = null;
      _fatalHttpStatuses.clear();
      _live.fallbackLevel = 0;
      _live.retryFailed = false;
      final markFirstFrameReady = _markFirstFrameReady(currentPlayer, settingsService);
      _trackManager?.onPlaybackRestart();
      await markFirstFrameReady;
    });

    _positionSubscription = currentPlayer.streams.position.listen((position) {
      final activePlayer = player;
      if (activePlayer == null || activePlayer != currentPlayer) return;

      // Fallback for MPV backends whose playbackRestart event is unavailable.
      // Android ExoPlayer position can advance on its standalone clock without
      // a renderer, so it may infer readiness only after switching to MPV.
      final canInferRenderedFrameFromPosition =
          !(Platform.isAndroid && useExoPlayer) || (currentPlayer is PlayerAndroid && currentPlayer.usingMpvFallback);
      if (canInferRenderedFrameFromPosition && !_hasRenderedFirstFrame) {
        if (lastObservedPositionMs != null && position.inMilliseconds != lastObservedPositionMs) {
          unawaited(_markFirstFrameReady(currentPlayer, settingsService));
        }
        lastObservedPositionMs = position.inMilliseconds;
      }

      // A recovered stream that progressed well past the recovery point
      // proves the reload worked — restore the full spurious-EOF retry
      // budget for the next stream death.
      final recoveryBaselineMs = _spuriousEofRecoveryBaselineMs;
      if (recoveryBaselineMs != null &&
          position.inMilliseconds >= recoveryBaselineMs + VideoPlayerScreenState._spuriousEofProgressResetMs) {
        _spuriousEofRecoveryAttempts = 0;
        _spuriousEofRecoveryBaselineMs = null;
      }

      final duration = activePlayer.state.duration;
      _completionLatch.classifyPosition(
        positionMs: position.inMilliseconds,
        durationMs: duration.inMilliseconds,
        promptVisible: _showPlayNextDialog,
        countdownActive: _autoPlayTimer?.isActive == true,
      );
      // CompletionLatchSignal.rearmed needs no action here: the latch
      // re-armed itself once playback seeked back out of the end region.
    });
  }

  /// Roll the screen back to a re-runnable state after a failed player
  /// attempt. The player is gone but the screen stays mounted and
  /// [_retryPlayerInitialization] may run again, so every collaborator is
  /// released *and* nulled so it can be built once more. Kept separate from
  /// `dispose()`, which instead destroys the notifiers, focus nodes and
  /// player, and cannot await any of this.
  Future<void> _tearDownFailedPlayerAttempt(Player attemptPlayer) async {
    final activePlayer = player;
    if (activePlayer != null && !identical(activePlayer, attemptPlayer)) return;

    // Rollback scope: the nine player streams plus the five media-controls
    // ones. _sleepTimerSubscription and _appleTvPlayPauseSubscription are
    // initState-owned and never re-created — cancelling them here would kill
    // the sleep-timer prompt and the Apple TV remote for the rest of the
    // screen's life.
    final cancellationFutures = <Future<void>>[
      if (_playingSubscription != null) _playingSubscription!.cancel(),
      if (_completedSubscription != null) _completedSubscription!.cancel(),
      if (_errorSubscription != null) _errorSubscription!.cancel(),
      if (_logSubscription != null) _logSubscription!.cancel(),
      if (_backendSwitchedSubscription != null) _backendSwitchedSubscription!.cancel(),
      if (_bufferingSubscription != null) _bufferingSubscription!.cancel(),
      if (_serverStatusSubscription != null) _serverStatusSubscription!.cancel(),
      if (_playbackRestartSubscription != null) _playbackRestartSubscription!.cancel(),
      if (_positionSubscription != null) _positionSubscription!.cancel(),
      if (_mediaControlSubscription != null) _mediaControlSubscription!.cancel(),
      if (_mediaControlsPlayingSubscription != null) _mediaControlsPlayingSubscription!.cancel(),
      if (_mediaControlsPositionSubscription != null) _mediaControlsPositionSubscription!.cancel(),
      if (_mediaControlsRateSubscription != null) _mediaControlsRateSubscription!.cancel(),
      if (_mediaControlsSeekableSubscription != null) _mediaControlsSeekableSubscription!.cancel(),
    ];
    _playingSubscription = null;
    _completedSubscription = null;
    _errorSubscription = null;
    _logSubscription = null;
    _backendSwitchedSubscription = null;
    _bufferingSubscription = null;
    _serverStatusSubscription = null;
    _playbackRestartSubscription = null;
    _positionSubscription = null;
    _mediaControlSubscription = null;
    _mediaControlsPlayingSubscription = null;
    _mediaControlsPositionSubscription = null;
    _mediaControlsRateSubscription = null;
    _mediaControlsSeekableSubscription = null;
    try {
      await Future.wait(cancellationFutures);
    } catch (e, st) {
      appLogger.w('Failed to cancel player subscriptions during initialization rollback', error: e, stackTrace: st);
    }

    final progressTracker = _progressTracker;
    _progressTracker = null;
    progressTracker?.stopTracking();
    progressTracker?.dispose();

    final trackManager = _trackManager;
    _trackManager = null;
    trackManager?.dispose();

    final mediaControlsManager = _mediaControlsManager;
    _mediaControlsManager = null;
    if (mediaControlsManager != null) {
      try {
        await mediaControlsManager.clear();
      } catch (e, st) {
        appLogger.w('Failed to clear media controls during initialization rollback', error: e, stackTrace: st);
      }
      mediaControlsManager.dispose();
    }

    _stopLiveTimelineUpdates();
    _detachPipStateListener();
    _clearAutoPipEnteringCallback();
    final pipInitialized = _pipInitialized;
    _pipInitialized = false;
    if (pipInitialized) {
      try {
        await PipService.setAutoPipReady(ready: false);
      } catch (e, st) {
        appLogger.w('Failed to disable auto-PiP during initialization rollback', error: e, stackTrace: st);
      }
    }

    final ambientLightingService = _ambientLightingService;
    _ambientLightingService = null;
    if (ambientLightingService != null) {
      try {
        await ambientLightingService.disable();
      } catch (e, st) {
        appLogger.w('Failed to disable ambient lighting during initialization rollback', error: e, stackTrace: st);
      }
    }
    _shaderService?.ambientLightingService = null;
    _shaderService = null;
    _videoFilterManager?.ambientLightingService = null;
    _videoFilterManager?.dispose();
    _videoFilterManager = null;
    _pipFiltersPrepared = false;

    final scrubPreviewSource = _scrubPreviewSource;
    _scrubPreviewSource = null;
    scrubPreviewSource?.dispose();

    if (identical(_lastVideoLayoutPlayer, attemptPlayer)) {
      _lastVideoLayoutPlayer = null;
      _lastVideoLayoutSize = null;
      _pendingVideoLayoutSize = null;
    }
    _audioFocusFuture = null;
    _playbackDataFuture = null;
    _playbackSession = null;
    _mediaControlsSuspendedForTvBackground = false;

    if (progressTracker != null) {
      try {
        await Future.wait<void>([
          DiscordRPCService.instance.stopPlayback(),
          TrackerCoordinator.instance.stopPlayback(),
        ]);
      } catch (e, st) {
        appLogger.w('Failed to stop scrobblers during initialization rollback', error: e, stackTrace: st);
      }
    }
    await _wakelockController.setEnabled(false);

    if (mounted) {
      _isBuffering.value = false;
      _hasFirstFrame.value = false;
      _hasRenderedFirstFrame = false;
    }
  }

  /// Wire the per-item playback services that need to (re)bind whenever
  /// the active media item changes: [PlaybackProgressTracker],
  /// [MediaControlsManager.updateMetadata], and the
  /// Discord/Trakt/Tracker scrobblers. Both [_initializeServices] and
  /// [_reloadMediaInPlace] call this so the two flows can't drift.
  ///
  /// The caller is responsible for ensuring `player != null` and (if the
  /// media-controls metadata refresh should run) for having created
  /// [_mediaControlsManager] before the first call.
  void _wirePerItemPlaybackServices({
    required MediaItem metadata,
    required MediaServerClient? mediaClient,
    required OfflineWatchSyncService? offlineWatchService,
    String? playSessionId,
    String? playMethod,
    MediaSourceInfo? mediaInfo,
  }) {
    final currentPlayer = player;
    if (_hasFatalPlaybackError) return;

    if (currentPlayer == null) return;

    _rebindProgressTracker(
      metadata: metadata,
      mediaClient: mediaClient,
      offlineWatchService: offlineWatchService,
      playSessionId: playSessionId,
      playMethod: playMethod,
      mediaInfo: mediaInfo,
    );

    // Media controls metadata. Fire-and-forget — the OS plugin downloads
    // the poster synchronously inside `setMetadata` (~270 ms); the
    // controls populate a beat after first frame which is fine.
    if (_mediaControlsManager != null) {
      unawaited(
        _mediaControlsManager!.updateMetadata(
          metadata: metadata,
          client: mediaClient,
          duration: metadata.durationMs != null ? Duration(milliseconds: metadata.durationMs!) : null,
        ),
      );
    }

    // Scrobblers — Discord RPC, Trakt, unified tracker. All accept the
    // neutral [MediaServerClient]; null short-circuits cleanly.
    if (mediaClient != null && !widget.isPreroll) {
      unawaited(DiscordRPCService.instance.startPlayback(metadata, mediaClient));
      unawaited(TrackerCoordinator.instance.startPlayback(metadata, mediaClient, isLive: widget.isLive));
    }
  }

  /// (Re)create the [PlaybackProgressTracker] for the current play session.
  /// Session-keyed only — a transcode restart rebinds just this, while item
  /// changes go through [_wirePerItemPlaybackServices] for the full set.
  void _rebindProgressTracker({
    required MediaItem metadata,
    required MediaServerClient? mediaClient,
    required OfflineWatchSyncService? offlineWatchService,
    String? playSessionId,
    String? playMethod,
    MediaSourceInfo? mediaInfo,
  }) {
    final currentPlayer = player;
    if (_hasFatalPlaybackError) return;

    if (currentPlayer == null) return;

    if (widget.isPreroll) return;

    // Local media still reports live when its server is online; only queue
    // locally when no reporting client is reachable.
    if (mediaClient != null) {
      // Captured now (synchronously); resolved at scrobble time because the
      // play queue holding the siblings is created fire-and-forget and may
      // not exist yet when the tracker is wired.
      final playbackState = context.read<PlaybackStateProvider>();
      final effectivePlayMethod = playMethod ?? (_isTranscoding ? 'Transcode' : 'DirectPlay');
      _progressTracker = PlaybackProgressTracker(
        client: mediaClient,
        metadata: metadata,
        player: currentPlayer,
        offlineWatchService: offlineWatchService,
        queueOnOnlineFailure: _playbackContext?.shouldQueueOnReportFailure ?? _usesLocalPlaybackSource,
        playMethod: effectivePlayMethod,
        playSessionId: playSessionId,
        mediaInfo: mediaInfo,
        canReportPlayback: () => _hasRenderedFirstFrame && !_hasFatalPlaybackError,
        hasRenderedPlayback: () => _hasRenderedFirstFrame,
        subtitleOffIsDeliberate: () => _playbackSession?.subtitleSelection.declinedPreference == null,
        onPausedKeepalive: mediaClient is PlexClient && effectivePlayMethod == 'Transcode'
            ? () => mediaClient.pingTranscodeSession(_playbackTranscodeSessionId)
            : null,
        onScrobbled: () async {
          // Other episodes of a Plex multi-episode file share this item's
          // part — watching the file watched them too (#1500). Reusing
          // markWatchedFromPlaybackStop keeps the local watched-event
          // emission and the Jellyfin double-scrobble guard (#1287); the
          // trackers hear about a sibling the same way any other watched mark
          // reaches them, since no playback session was ever opened for it.
          final siblings = playbackState.sameFileSiblings(metadata, playedPartId: mediaInfo?.partId?.toString());
          for (final sibling in siblings) {
            if (sibling.isWatched) continue;
            await mediaClient.markWatchedFromPlaybackStop(sibling);
            await TrackerCoordinator.instance.markWatched(sibling, mediaClient);
            appLogger.d('Scrobbled same-file sibling ${sibling.id} of ${metadata.id}');
          }
        },
      );
      _progressTracker!.startTracking();
    } else if (_isOfflinePlayback) {
      _progressTracker = PlaybackProgressTracker(
        client: null,
        metadata: metadata,
        player: currentPlayer,
        isOffline: true,
        offlineWatchService: offlineWatchService,
        canReportPlayback: () => _hasRenderedFirstFrame && !_hasFatalPlaybackError,
        hasRenderedPlayback: () => _hasRenderedFirstFrame,
      );
      _progressTracker!.startTracking();
    }
  }

  /// Initialize the service layer
  Future<void> _initializeServices() async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null || _hasFatalPlaybackError) return;

    // Live TV: send timeline heartbeats to keep transcode session alive
    if (widget.isLive) {
      _startLiveTimelineUpdates();
      return;
    }

    // Get a live reporting client when possible. Downloaded/local playback
    // still uses this path when the server is reachable.
    final mediaClient = _playbackContext?.reportingClient ?? _getOnlineMediaServerClient(context);
    final offlineWatchService = context.read<OfflineWatchSyncService>();

    // Initialize media controls manager (must exist before the per-item
    // helper wires its metadata update).
    final mediaControlsManager = MediaControlsManager();
    _mediaControlsManager = mediaControlsManager;

    final mediaControlRouter = MediaControlRouter(
      // Authority stays Watch Together's. The automotive gate lives in the
      // playback-intent wrappers below, so `onPause` can never be denied: a
      // gated `canControlPlayback` would make the router swallow `PauseEvent`.
      canControlPlayback: _canControlPlayback,
      canNavigateMediaItems: () => _canNavigateMediaItems() && automotivePlaybackAllowedNow(),
      onPlay: () {
        final currentPlayer = player;
        if (currentPlayer == null) return;
        unawaited(_seekBackForRewind(currentPlayer));
        unawaited(_playWithPlaybackIntent(currentPlayer));
        _wasPlayingBeforeInactive = false;
        _announceTransportCommand(willPlay: true);
        _updateMediaControlsPlaybackState();
      },
      onPause: () {
        final currentPlayer = player;
        if (currentPlayer == null) return;
        if (_frameRate.suppressesMediaPause) {
          appLogger.d('Media control: Pause event suppressed (frame rate switch in progress)');
          return;
        }
        unawaited(_pauseWithPlaybackIntent(currentPlayer));
        _announceTransportCommand(willPlay: false);
        _updateMediaControlsPlaybackState();
      },
      onTogglePlayPause: () {
        final currentPlayer = player;
        if (currentPlayer == null) return;
        if (currentPlayer.state.isActive) {
          unawaited(_pauseWithPlaybackIntent(currentPlayer));
          _announceTransportCommand(willPlay: false);
        } else {
          unawaited(_seekBackForRewind(currentPlayer));
          unawaited(_playWithPlaybackIntent(currentPlayer));
          _wasPlayingBeforeInactive = false;
          _announceTransportCommand(willPlay: true);
        }
        _updateMediaControlsPlaybackState();
      },
      onSeek: (position) {
        final currentPlayer = player;
        if (currentPlayer != null) {
          unawaited(_seekPlayback(clampSeekPosition(currentPlayer, position)));
        }
      },
      onNext: () {
        if (_nextEpisode != null) unawaited(_playNext());
      },
      onPrevious: () => unawaited(_restartOrPlayPrevious()),
      onStop: () => unawaited(_handleBackButton()),
      onSkipForward: (interval) => unawaited(_seekRelative(interval ?? _defaultMediaControlSkip)),
      onSkipBackward: (interval) => unawaited(_seekRelative(-(interval ?? _defaultMediaControlSkip))),
      onSetSpeed: (speed) {
        final currentPlayer = player;
        if (currentPlayer != null) unawaited(currentPlayer.setRate(speed));
      },
    );

    // Set up media control event handling
    _mediaControlSubscription = mediaControlsManager.controlEvents.listen((event) {
      if (_mediaControlsSuspendedForTvBackground) {
        appLogger.d('Media control: ${event.runtimeType} ignored while Android TV background-suspended');
        return;
      }

      if (_isAppleAudioSessionEvent(event)) {
        unawaited(_handleAppleAudioSessionEvent(event));
        return;
      }

      if (PlatformDetector.isAppleTV() && _isPlaybackMediaControlEvent(event)) {
        appLogger.d('Media control: ${event.runtimeType} ignored on Apple TV; using native remote bridge');
        return;
      }

      mediaControlRouter.route(event);
    });

    // Wire progress tracker, media-controls metadata, and the
    // Discord/Trakt/Tracker scrobblers. Shared with [_reloadMediaInPlace]
    // so the two flows can't drift.
    _wirePerItemPlaybackServices(
      metadata: _currentMetadata,
      mediaClient: mediaClient,
      offlineWatchService: offlineWatchService,
      playSessionId: _playbackPlaySessionId,
      playMethod: _playbackPlayMethod,
      mediaInfo: _currentMediaInfo,
    );

    if (!mounted) return;

    await _syncMediaControlsAvailability();
    if (!mounted || player != currentPlayer || _mediaControlsManager != mediaControlsManager) return;

    // Listen to playing state and update media controls
    _mediaControlsPlayingSubscription = currentPlayer.streams.playing.listen((isPlaying) {
      _updateMediaControlsPlaybackState();
    });

    // Listen to position updates for media controls and Discord
    _mediaControlsPositionSubscription = currentPlayer.streams.position.listen((position) {
      mediaControlsManager.updatePlaybackState(
        isPlaying: currentPlayer.state.isActive,
        position: position,
        speed: currentPlayer.state.rate,
      );
      DiscordRPCService.instance.updatePosition(position);
      TrackerCoordinator.instance.updatePosition(position);
      // Keep the trackers' known duration current — mpv only emits on the
      // duration stream once per load, but this is cheap and avoids an extra
      // listener.
      TrackerCoordinator.instance.updateDuration(currentPlayer.state.duration);
    });

    // Listen to playback rate changes for Discord Rich Presence
    _mediaControlsRateSubscription = currentPlayer.streams.rate.listen((rate) {
      DiscordRPCService.instance.updatePlaybackSpeed(rate);
    });

    _mediaControlsSeekableSubscription = currentPlayer.streams.seekable.listen((_) {
      unawaited(_syncMediaControlsAvailability());
    });
  }

  void _onPlayingStateChanged(bool isPlaying) {
    if (!isPlaying) {
      _lastPlaybackPauseAt = DateTime.now();
    }

    if (isPlaying && !automotivePlaybackAllowedNow()) {
      // Native audio-focus regain resumes the platform player directly
      // (ExoPlayer's AudioFocusManager, mpv's resumeAfterAudioFocusGain), so it
      // never passes through the Dart playback-intent wrappers. Last line of
      // defence for `DD-2`: audio must not resume while the vehicle restricts
      // the app. Also catches any async open that raced the lifecycle pause.
      appLogger.w('Playback started while Android Automotive UX restrictions are active; pausing');
      Sentry.addBreadcrumb(
        Breadcrumb(message: 'Blocked automotive restricted playback start', category: 'player.driver_distraction'),
      );
      final currentPlayer = player;
      if (currentPlayer != null) {
        unawaited(_pauseWithPlaybackIntent(currentPlayer));
      }
      unawaited(_wakelockController.setEnabled(false));
      return;
    }

    if (isPlaying && _mediaControlsSuspendedForTvBackground) {
      appLogger.w('Playback started while Android TV background media controls are suspended; pausing');
      Sentry.addBreadcrumb(
        Breadcrumb(message: 'Blocked TV background playback start', category: 'player.media_controls'),
      );
      final currentPlayer = player;
      if (currentPlayer != null) {
        unawaited(_pauseWithPlaybackIntent(currentPlayer));
      }
      unawaited(_wakelockController.setEnabled(false));
      return;
    }

    unawaited(_wakelockController.setEnabled(isPlaying));

    if (isPlaying) {
      // Force a texture refresh on resume to unstick stale frames
      // (Linux/macOS texture registrars can miss frame-available
      // notifications after extended pause periods)
      player?.updateFrame();
    }

    // Send timeline update when playback state changes
    _progressTracker?.sendProgress(isPlaying ? 'playing' : 'paused');

    // Update OS media controls playback state
    _updateMediaControlsPlaybackState();

    // Update Discord Rich Presence + real-time trackers
    if (isPlaying) {
      DiscordRPCService.instance.resumePlayback();
      TrackerCoordinator.instance.resumePlayback();
    } else {
      DiscordRPCService.instance.pausePlayback();
      TrackerCoordinator.instance.pausePlayback();
    }

    // Update auto-PiP readiness
    if (_autoPipEnabled) {
      unawaited(_updateAutoPipState(isPlaying: isPlaying));
    }
  }

  bool _isAppleAudioSessionEvent(Object event) =>
      event is AudioInterruptionBeganEvent ||
      event is AudioInterruptionEndedEvent ||
      event is AudioRouteOldDeviceUnavailableEvent ||
      event is AudioRouteNewDeviceAvailableEvent;

  bool _isPlaybackMediaControlEvent(Object event) =>
      event is PlayEvent || event is PauseEvent || event is TogglePlayPauseEvent;

  Future<void> _handleAppleAudioSessionEvent(Object event) async {
    if (!Platform.isIOS || PlatformDetector.isTV()) return;

    final currentPlayer = player;
    if (!mounted || currentPlayer == null || !_isPlayerInitialized) return;

    if (event is AudioInterruptionBeganEvent) {
      await _pauseForAppleAudioSessionEvent(currentPlayer, 'interruption began');
    } else if (event is AudioRouteOldDeviceUnavailableEvent) {
      await _pauseForAppleAudioSessionEvent(currentPlayer, 'private audio route disconnected');
    } else if (event is AudioInterruptionEndedEvent) {
      if (event.shouldResume) {
        await _resumeAfterAppleAudioSessionEvent(currentPlayer, 'interruption ended');
      } else {
        _resumeAfterAppleAudioSessionPause = false;
      }
    } else if (event is AudioRouteNewDeviceAvailableEvent) {
      await _resumeAfterAppleAudioSessionEvent(currentPlayer, 'private audio route connected');
    }
  }

  Future<void> _pauseForAppleAudioSessionEvent(Player currentPlayer, String reason) async {
    final wasPlayingBeforeEvent = currentPlayer.state.isActive || _wasRecentlyPaused();
    if (wasPlayingBeforeEvent) {
      _resumeAfterAppleAudioSessionPause = true;
    }

    try {
      await _pauseWithPlaybackIntent(currentPlayer);
      appLogger.d('Video paused after Apple audio session $reason');
    } catch (e) {
      appLogger.w('Failed to pause after Apple audio session $reason', error: e);
    } finally {
      _updateMediaControlsPlaybackState();
    }
  }

  bool _wasRecentlyPaused() {
    final pauseAt = _lastPlaybackPauseAt;
    if (pauseAt == null) return false;
    return DateTime.now().difference(pauseAt) < const Duration(seconds: 1);
  }

  Future<void> _resumeAfterAppleAudioSessionEvent(Player expectedPlayer, String reason) async {
    if (!_resumeAfterAppleAudioSessionPause) return;
    _resumeAfterAppleAudioSessionPause = false;

    if (!mounted || player != expectedPlayer || !_isPlayerInitialized) return;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      appLogger.d('Skipped Apple audio session resume after $reason because app is not resumed');
      return;
    }
    if (expectedPlayer.state.isActive) return;

    try {
      await _playWithPlaybackIntent(expectedPlayer);
      _wasPlayingBeforeInactive = false;
      appLogger.d('Video resumed after Apple audio session $reason');
    } catch (e) {
      appLogger.w('Failed to resume after Apple audio session $reason', error: e);
    } finally {
      _updateMediaControlsPlaybackState();
    }
  }

  /// Force mpv to reconnect its HTTP stream by seeking to the current position.
  /// This bypasses ffmpeg's exponential reconnect backoff when the app detects
  /// that network connectivity has been restored.
  void _forceStreamReconnect() {
    final p = player;
    if (p == null || !_isPlayerInitialized) return;
    final pos = p.state.position;
    appLogger.i('Network restored while buffering, forcing stream reconnect at ${pos.inSeconds}s');
    // Clear any stale completion latch caused by a spurious EOF during the drop,
    // so the real end-of-file can trigger Play Next after we recover.
    _rearmCompletionLatch();
    unawaited(_seekPlayback(pos));
  }

  /// Intercept an EOF signal that fired far from the end of the media.
  ///
  /// The player reports a clean EOF when a network stream dies mid-file
  /// (#1520) — no libmpv signal distinguishes it from the real end, so
  /// position vs best-known duration is the only discriminator (see
  /// [classifyEofSignal]). Returns true when the signal was spurious and
  /// handled here (recovery started, or playback stays parked); false lets
  /// the caller run the normal completion flow.
  bool _interceptSpuriousEof(Player currentPlayer) {
    // Live EOFs have their own handling, an offline file can't lose its
    // stream, and in-flight transitions already produce expected EOFs that
    // _onVideoCompleted ignores — all fall through untouched.
    if (widget.isLive || _isOfflinePlayback) return false;
    if (_playbackTransition != _PlaybackTransition.idle) return false;
    // Already parked: swallow duplicate EOF signals without burning budget
    // or re-toasting.
    if (_spuriousEofRecoveryParked) return true;

    final positionMs = currentPlayer.state.position.inMilliseconds;
    final playerDurationMs = currentPlayer.state.duration.inMilliseconds;
    final metadataDurationMs = _currentMetadata.durationMs;
    final signal = classifyEofSignal(
      positionMs: positionMs,
      playerDurationMs: playerDurationMs,
      metadataDurationMs: metadataDurationMs,
    );
    if (signal != EofSignalClass.spurious) return false;

    appLogger.w(
      'Spurious EOF at ${positionMs}ms (playerDuration=${playerDurationMs}ms, '
      'metadataDuration=${metadataDurationMs}ms, '
      'cacheEnd=${currentPlayer.state.buffer.inMilliseconds}ms), '
      'recovery attempt ${_spuriousEofRecoveryAttempts + 1}/'
      '${VideoPlayerScreenState._maxSpuriousEofRecoveryAttempts}',
    );

    if (_spuriousEofRecoveryAttempts >= VideoPlayerScreenState._maxSpuriousEofRecoveryAttempts) {
      _parkAfterFailedRecovery();
      return true;
    }
    _spuriousEofRecoveryAttempts++;
    _spuriousEofRecoveryBaselineMs = positionMs;
    unawaited(_recoverFromSpuriousEof(currentPlayer));
    return true;
  }

  /// Leave playback parked on the dead stream: no auto-exit — the user keeps
  /// their place and the snackbar names the actions that actually rebuild the
  /// stream (play/seek route to [_retrySpuriousEofRecovery] while parked).
  void _parkAfterFailedRecovery() {
    _spuriousEofRecoveryParked = true;
    unawaited(_wakelockController.setEnabled(false));
    showGlobalErrorSnackBar(t.messages.streamInterrupted);
  }

  /// Recover from a spurious EOF by re-running the full playback decision in
  /// place — the same path as the TV background suspend restore, because the
  /// failure is the same: the server-side stream is gone and only a fresh
  /// resolve replaces it (a seek-in-place lands inside the dead cache, and a
  /// same-session transcode seek can hit the reaped session).
  Future<void> _recoverFromSpuriousEof(Player currentPlayer) async {
    final outcome = await _reloadMediaInPlace(
      metadata: _currentMetadata,
      resumePosition: currentPlayer.state.position,
      preserveCurrentTrackSelection: true,
      startPaused: !_playbackIntentShouldPlay,
      showErrorUi: false,
      reason: 'spurious EOF recovery',
    );
    if (outcome == _MediaReloadOutcome.failed) _parkAfterFailedRecovery();
    // rejected/superseded: another flow owns the player and will commit
    // fresh media (clearing any park). opened: recovered — the budget
    // resets via 30s of progress or an item change.
  }

  /// Rebuild the dead stream after playback parked on a spurious EOF.
  /// User actions and the server-online monitor land here; these retries are
  /// always allowed and never consume the automatic budget.
  Future<void> _retrySpuriousEofRecovery({required String reason, Duration? resumePosition}) async {
    final currentPlayer = player;
    if (currentPlayer == null || _playbackTransition != _PlaybackTransition.idle) return;
    appLogger.i('Retrying dead-stream recovery ($reason)');
    _spuriousEofRecoveryParked = false;
    final outcome = await _reloadMediaInPlace(
      metadata: _currentMetadata,
      resumePosition: resumePosition ?? currentPlayer.state.position,
      preserveCurrentTrackSelection: true,
      startPaused: !_playbackIntentShouldPlay,
      showErrorUi: false,
      reason: 'stream recovery ($reason)',
    );
    if (outcome == _MediaReloadOutcome.failed) _parkAfterFailedRecovery();
  }
}
