part of '../../video_player_screen.dart';

extension _VideoPlayerPlaybackServiceMethods on VideoPlayerScreenState {
  /// Wire the per-item playback services that need to (re)bind whenever
  /// the active media item changes: [PlaybackProgressTracker],
  /// [MediaControlsManager.updateMetadata], and the
  /// Discord/Trakt/Tracker scrobblers. Both [_initializeServices] and
  /// [_swapEpisodeInPip] call this so the two flows can't drift.
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
    if (currentPlayer == null) return;
    _stoppedProgressFuture = null;

    // Progress tracker — offline mode queues for later sync; online mode
    // dispatches to the right backend through the neutral client.
    if (_isOfflinePlayback) {
      _progressTracker = PlaybackProgressTracker(
        client: null,
        metadata: metadata,
        player: currentPlayer,
        isOffline: true,
        offlineWatchService: offlineWatchService,
      );
      _progressTracker!.startTracking();
    } else if (mediaClient != null) {
      _progressTracker = PlaybackProgressTracker(
        client: mediaClient,
        metadata: metadata,
        player: currentPlayer,
        playMethod: playMethod ?? (_isTranscoding ? 'Transcode' : 'DirectPlay'),
        playSessionId: playSessionId,
        mediaInfo: mediaInfo,
      );
      _progressTracker!.startTracking();
    }

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
    if (mediaClient != null) {
      unawaited(DiscordRPCService.instance.startPlayback(metadata, mediaClient));
      unawaited(TraktScrobbleService.instance.startPlayback(metadata, mediaClient, isLive: widget.isLive));
      unawaited(TrackerCoordinator.instance.startPlayback(metadata, mediaClient, isLive: widget.isLive));
    }
  }

  /// Initialize the service layer
  Future<void> _initializeServices() async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return;

    // Live TV: send timeline heartbeats to keep transcode session alive
    if (widget.isLive) {
      _startLiveTimelineUpdates();
      return;
    }

    // Get client (null in offline mode). Backend-neutral lookup so Jellyfin
    // items also wire a [PlaybackProgressTracker]; the tracker dispatches
    // to the right backend's reporting endpoints internally.
    final mediaClient = _isOfflinePlayback ? null : _getMediaServerClient(context);
    final offlineWatchService = context.read<OfflineWatchSyncService>();

    // Initialize media controls manager (must exist before the per-item
    // helper wires its metadata update).
    final mediaControlsManager = MediaControlsManager();
    _mediaControlsManager = mediaControlsManager;

    // Set up media control event handling
    _mediaControlSubscription = mediaControlsManager.controlEvents.listen((event) {
      final activePlayer = player;
      if (_mediaControlsSuspendedForTvBackground) {
        final eventLabel = event.runtimeType.toString();
        if (activePlayer != null && (event is PlayEvent || event is TogglePlayPauseEvent)) {
          appLogger.d('Media control: $eventLabel received while Android TV background-suspended');
          unawaited(_requestForegroundResumeFromSuspendedMediaControl(eventLabel));
        } else {
          appLogger.d('Media control: $eventLabel ignored while Android TV background-suspended');
        }
        return;
      }

      if (_isAppleAudioSessionEvent(event)) {
        unawaited(_handleAppleAudioSessionEvent(event));
        return;
      }

      if (activePlayer == null && event is! NextTrackEvent && event is! PreviousTrackEvent) return;

      if (event is PlayEvent) {
        appLogger.d('Media control: Play event received');
        _seekBackForRewind(activePlayer!);
        activePlayer.play();
        _wasPlayingBeforeInactive = false;
        _updateMediaControlsPlaybackState();
      } else if (event is PauseEvent) {
        if (_suppressMediaPauseDuringFrameRateSwitch) {
          appLogger.d('Media control: Pause event suppressed (frame rate switch in progress)');
          return;
        }
        appLogger.d('Media control: Pause event received');
        activePlayer!.pause();
        _updateMediaControlsPlaybackState();
      } else if (event is TogglePlayPauseEvent) {
        appLogger.d('Media control: Toggle play/pause event received');
        if (activePlayer!.state.isActive) {
          activePlayer.pause();
        } else {
          _seekBackForRewind(activePlayer);
          activePlayer.play();
          _wasPlayingBeforeInactive = false;
        }
        _updateMediaControlsPlaybackState();
      } else if (event is SeekEvent) {
        appLogger.d('Media control: Seek event received to ${event.position}');
        unawaited(_seekPlayback(clampSeekPosition(activePlayer!, event.position)));
      } else if (event is NextTrackEvent) {
        appLogger.d('Media control: Next track event received');
        if (_nextEpisode != null) _playNext();
      } else if (event is PreviousTrackEvent) {
        appLogger.d('Media control: Previous track event received');
        unawaited(_restartOrPlayPrevious());
      }
    });

    // Wire progress tracker, media-controls metadata, and the
    // Discord/Trakt/Tracker scrobblers. Shared with [_swapEpisodeInPip]
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
      TraktScrobbleService.instance.updatePosition(position);
      TrackerCoordinator.instance.updatePosition(position);
      // Keep Trakt's known duration current — mpv only emits on the duration
      // stream once per load, but this is cheap and avoids an extra listener.
      TraktScrobbleService.instance.updateDuration(currentPlayer.state.duration);
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

    if (isPlaying && _mediaControlsSuspendedForTvBackground) {
      appLogger.w('Playback started while Android TV background media controls are suspended; pausing');
      Sentry.addBreadcrumb(
        Breadcrumb(message: 'Blocked TV background playback start', category: 'player.media_controls'),
      );
      final currentPlayer = player;
      if (currentPlayer != null) {
        unawaited(currentPlayer.pause());
      }
      unawaited(_setWakelock(false));
      return;
    }

    unawaited(_setWakelock(isPlaying));

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

    // Update Discord Rich Presence + Trakt scrobble
    if (isPlaying) {
      DiscordRPCService.instance.resumePlayback();
      TraktScrobbleService.instance.resumePlayback();
    } else {
      DiscordRPCService.instance.pausePlayback();
      TraktScrobbleService.instance.pausePlayback();
    }

    // Update auto-PiP readiness
    if (_autoPipEnabled) {
      _videoPIPManager?.updateAutoPipState(isPlaying: isPlaying);
    }
  }

  bool _isAppleAudioSessionEvent(Object event) =>
      event is AudioInterruptionBeganEvent ||
      event is AudioInterruptionEndedEvent ||
      event is AudioRouteOldDeviceUnavailableEvent ||
      event is AudioRouteNewDeviceAvailableEvent;

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
      await currentPlayer.pause();
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
      await expectedPlayer.play();
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
    if (_completionTriggered && !_showPlayNextDialog && _autoPlayTimer?.isActive != true) {
      _completionTriggered = false;
    }
    unawaited(_seekPlayback(pos));
  }
}
