part of '../../video_player_screen.dart';

extension _VideoPlayerLifecycleMethods on VideoPlayerScreenState {
  void _enqueueLifecycleTransition(String label, Future<void> Function() transition) {
    _lifecycleTransition = _lifecycleTransition
        .catchError((Object error, StackTrace stackTrace) {
          appLogger.w('Previous lifecycle transition failed', error: error, stackTrace: stackTrace);
        })
        .then((_) async {
          if (!mounted) return;
          try {
            await transition();
          } catch (e, stackTrace) {
            appLogger.w('Lifecycle transition failed during $label', error: e, stackTrace: stackTrace);
          }
        });
  }

  void _recordLifecycleState(String state, {String? action}) {
    final isTv = PlatformDetector.isTV();
    final pipActive = PipService().isPipActive.value;
    final breadcrumbData = <String, dynamic>{
      'state': state,
      'isTv': isTv,
      'autoPipEnabled': _autoPipEnabled,
      'pipActive': pipActive,
      'pipTransitionInFlight': _androidAutoPipTransitionInFlight,
      'hiddenForBackground': _hiddenForBackground,
      'playerSuspendedForTvBackground': _playerSuspendedForTvBackground,
      'mediaControlsSuspendedForTvBackground': _mediaControlsSuspendedForTvBackground,
      'backend': _playerBackendLabel,
    };
    if (action != null) {
      breadcrumbData['action'] = action;
    }

    Sentry.addBreadcrumb(
      Breadcrumb(message: 'Player lifecycle $state', category: 'player.lifecycle', data: breadcrumbData),
    );

    appLogger.d(
      'Player lifecycle: state=$state'
      '${action != null ? ' action=$action' : ''}'
      ' isTv=$isTv'
      ' autoPipEnabled=$_autoPipEnabled'
      ' pipActive=$pipActive'
      ' pipTransitionInFlight=$_androidAutoPipTransitionInFlight'
      ' hiddenForBackground=$_hiddenForBackground'
      ' playerSuspendedForTvBackground=$_playerSuspendedForTvBackground'
      ' mediaControlsSuspendedForTvBackground=$_mediaControlsSuspendedForTvBackground'
      ' backend=$_playerBackendLabel',
    );
  }

  void _setAndroidAutoPipTransitionInFlight(bool value, {required String reason}) {
    if (!Platform.isAndroid || _androidAutoPipTransitionInFlight == value) return;
    _androidAutoPipTransitionInFlight = value;
    _recordLifecycleState('pip_transition', action: '${value ? 'started' : 'cleared'}:$reason');
  }

  void _suspendLiveTimelineForBackground() {
    _live.resumeTimelineOnResume = _live.timelineTimer != null;
    _stopLiveTimelineUpdates();
  }

  void _resumeLiveTimelineAfterBackgroundIfNeeded() {
    final shouldResume = _live.resumeTimelineOnResume;
    _live.resumeTimelineOnResume = false;
    if (shouldResume && _live.session != null) {
      _startLiveTimelineUpdates();
    }
  }

  Future<void> _handleAppHidden() async {
    if (_shouldSkipForPip) {
      _recordLifecycleState('hidden', action: 'skipped_for_pip');
      return;
    }

    // Suppress Watch Together heartbeats while backgrounded so App Nap
    // doesn't cause stale position broadcasts that make guests loop.
    _watchTogetherProvider?.setBackgrounded(true);

    final currentPlayer = player;
    if (currentPlayer == null || !_isPlayerInitialized) {
      _recordLifecycleState('hidden', action: 'skipped_no_player');
      return;
    }

    final isTv = PlatformDetector.isTV();
    final shouldPauseForBackground = PlatformDetector.isHandheld(context) || isTv;

    // Pause first so Android MPV does not keep decoding against a transient
    // background surface while the app is locking or hiding.
    if (shouldPauseForBackground) {
      _wasPlayingBeforeInactive = currentPlayer.state.isActive;
      if (_wasPlayingBeforeInactive) {
        try {
          await _pauseWithPlaybackIntent(currentPlayer);
          appLogger.d('Video paused due to app being hidden (${isTv ? 'tv' : 'handheld'})');
        } catch (e) {
          appLogger.w('Failed to pause video before background transition', error: e);
        }
      }
    }

    if (!mounted || currentPlayer != player) return;

    _suspendLiveTimelineForBackground();

    if (isTv) {
      await _suspendMediaControlsForTvBackground('hidden');
      if (_armTvBackgroundPlayerSuspendTimer()) {
        _recordLifecycleState('hidden', action: 'tv_background_pause_suspend_armed');
      } else {
        _recordLifecycleState('hidden', action: 'tv_background_pause_only');
      }
      return;
    }

    _hiddenForBackground = true;
    await currentPlayer.setVisible(false, restoreOnWindowVisible: Platform.isMacOS);
    _recordLifecycleState('hidden', action: 'render_hidden');
  }

  Future<void> _handleAppResumed() async {
    _recordLifecycleState('resumed', action: 'begin');
    _watchTogetherProvider?.setBackgrounded(false);

    if (Platform.isAndroid && _androidAutoPipTransitionInFlight && !PipService().isPipActive.value) {
      _setAndroidAutoPipTransitionInFlight(false, reason: 'resume_without_pip');
    }

    final currentPlayer = player;

    // Restore render layer if it was hidden for background, then force a
    // video-output refresh before any auto-resume logic runs.
    if (_hiddenForBackground && currentPlayer != null && _isPlayerInitialized) {
      await currentPlayer.setVisible(true);
      if (!Platform.isMacOS) {
        await currentPlayer.updateFrame();
      }

      if (!mounted || currentPlayer != player) return;

      _hiddenForBackground = false;
      _recordLifecycleState('resumed', action: 'render_restored');
    }

    // A TV background suspend released the native pipeline via stop();
    // rebuild the playback session in place before the media-control restore
    // below can act on the stopped player.
    if (_playerSuspendedForTvBackground) {
      await _restorePlayerAfterTvBackgroundSuspend();
      if (!mounted || currentPlayer != player) return;
    }
    // TV never hides the render layer on background (_handleAppHidden returns
    // early without setting _hiddenForBackground), but the screensaver can
    // still destroy the surface. Kick the video output so a missed surface
    // callback can't leave the picture black: mpv re-attaches via
    // refreshVideoOutput, ExoPlayer just reapplies sizing/z-order.
    else if (!_hiddenForBackground &&
        Platform.isAndroid &&
        PlatformDetector.isTV() &&
        currentPlayer != null &&
        _isPlayerInitialized) {
      await currentPlayer.updateFrame();
      if (!mounted || currentPlayer != player) return;
      _recordLifecycleState('resumed', action: 'tv_video_output_kick');
    }

    // Restore media controls and wakelock when app is resumed.
    if (_isPlayerInitialized && mounted) {
      _resumeMediaControlsAfterTvBackground('app_resumed');
      await _restoreMediaControlsAfterResume();
    }

    _resumeLiveTimelineAfterBackgroundIfNeeded();
    _recordLifecycleState('resumed', action: 'complete');
  }

  /// Arm the grace timer that releases the native AV pipeline if the app
  /// stays backgrounded (Android TV only). Returns whether it was armed.
  bool _armTvBackgroundPlayerSuspendTimer() {
    if (!shouldSuspendPlayerForTvBackground(
      isAndroid: Platform.isAndroid,
      isTv: PlatformDetector.isTV(),
      isLive: widget.isLive,
      alreadySuspended: _playerSuspendedForTvBackground,
    )) {
      return false;
    }
    _tvBackgroundPlayerSuspendTimer?.cancel();
    _tvBackgroundPlayerSuspendTimer = Timer(VideoPlayerScreenState._tvBackgroundPlayerSuspendGrace, () {
      _tvBackgroundPlayerSuspendTimer = null;
      _enqueueLifecycleTransition('tv_background_suspend', _suspendPlayerForTvBackground);
    });
    return true;
  }

  void _cancelTvBackgroundPlayerSuspendTimer() {
    _tvBackgroundPlayerSuspendTimer?.cancel();
    _tvBackgroundPlayerSuspendTimer = null;
  }

  /// Grace expired while still backgrounded: release the native AV pipeline
  /// (MediaCodec decoders + AudioTrack, tunneled passthrough included) so a
  /// parked Plezy can't starve other apps on shared-hardware TV SoCs. stop()
  /// retains Dart-side position/duration/track state on both Android
  /// backends, and the progress tracker keeps sending paused heartbeats at
  /// the retained position, so the server session stays alive and resumable.
  /// Position and track selections are latched here because the reload on
  /// restore reads them after the native state is gone.
  Future<void> _suspendPlayerForTvBackground() async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null || !_isPlayerInitialized) return;
    // A live stream's tuned session is also its time-shift buffer. Stopping
    // it would force a re-tune at the live edge and discard pause state.
    if (widget.isLive) return;
    if (_playerSuspendedForTvBackground || _shouldSkipForPip) return;
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState == AppLifecycleState.resumed || lifecycleState == AppLifecycleState.inactive) return;
    if (_playbackTransition != _PlaybackTransition.idle || !_hasFirstFrame.value) {
      // A reload/zap/startup flow owns the player right now; stopping under
      // it would corrupt its open sequence. Retry after another grace.
      _armTvBackgroundPlayerSuspendTimer();
      return;
    }

    _tvBackgroundSuspendPosition = currentPlayer.state.position;
    _tvBackgroundSuspendAudioTrack = currentPlayer.state.track.audio;
    _tvBackgroundSuspendSubtitleTrack = currentPlayer.state.track.subtitle;
    _tvBackgroundSuspendSecondarySubtitleTrack = currentPlayer.state.track.secondarySubtitle;
    _playerSuspendedForTvBackground = true;
    try {
      await currentPlayer.stop();
      _recordLifecycleState('hidden', action: 'tv_background_suspend');
    } catch (e) {
      _playerSuspendedForTvBackground = false;
      _tvBackgroundSuspendPosition = null;
      _tvBackgroundSuspendAudioTrack = null;
      _tvBackgroundSuspendSubtitleTrack = null;
      _tvBackgroundSuspendSecondarySubtitleTrack = null;
      appLogger.w('TV background suspend failed; player left paused', error: e);
    }
  }

  /// Rebuild the playback session after a TV background suspend released the
  /// native pipeline. VOD reloads in place through the regular reload flow —
  /// a fresh playback decision, since the suspended stream URL may have
  /// expired server-side — and comes back paused; the caller's
  /// [_restoreMediaControlsAfterResume] then resumes it (with
  /// rewind-on-resume) exactly like a plain background pause. Live sessions
  /// never enter this flow because their tuned session and capture-buffer
  /// position must remain intact across backgrounding.
  Future<void> _restorePlayerAfterTvBackgroundSuspend() async {
    _playerSuspendedForTvBackground = false;
    final resumePosition = _tvBackgroundSuspendPosition;
    final audioTrack = _tvBackgroundSuspendAudioTrack;
    final subtitleTrack = _tvBackgroundSuspendSubtitleTrack;
    final secondarySubtitleTrack = _tvBackgroundSuspendSecondarySubtitleTrack;
    _tvBackgroundSuspendPosition = null;
    _tvBackgroundSuspendAudioTrack = null;
    _tvBackgroundSuspendSubtitleTrack = null;
    _tvBackgroundSuspendSecondarySubtitleTrack = null;

    final currentPlayer = player;
    if (!mounted || currentPlayer == null || !_isPlayerInitialized) return;

    _recordLifecycleState('resumed', action: 'tv_background_suspend_reload');
    final reloaded = await _reloadMediaInPlace(
      metadata: _currentMetadata,
      resumePosition: resumePosition,
      preserveCurrentTrackSelection: true,
      preservedAudioTrack: audioTrack,
      preservedSubtitleTrack: subtitleTrack,
      preservedSecondarySubtitleTrack: secondarySubtitleTrack,
      startPaused: true,
      reason: 'TV background suspend restore',
    );
    if (!reloaded) {
      appLogger.w('TV background suspend restore: in-place reload rejected');
    }
  }
}
