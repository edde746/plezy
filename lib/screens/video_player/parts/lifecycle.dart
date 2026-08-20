part of '../../video_player_screen.dart';

bool shouldPauseVideoForBackground({required bool isHandheld, required bool isTv, required bool isAutomotive}) =>
    isHandheld || isTv || isAutomotive;

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
      'mediaControlsSuspendedForTvBackground': _mediaControls.suspendedForTvBackground,
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
      ' mediaControlsSuspendedForTvBackground=$_mediaControls.suspendedForTvBackground'
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
    if (widget.isLive && shouldStopLiveSessionForTvBackground(isTv: isTv, policy: _live.session?.backgroundPolicy)) {
      _live.exitOnResume = true;
      _live.resumeTimelineOnResume = false;
      _stopLiveTimelineUpdates();

      // Start the server cleanup before releasing the native stream. tvOS may
      // suspend the process shortly after this lifecycle callback returns.
      final stoppedReport = _sendStoppedProgressOnce();
      try {
        await currentPlayer.stop();
      } catch (e, stackTrace) {
        appLogger.w('Failed to stop live player while backgrounding', error: e, stackTrace: stackTrace);
      }
      await stoppedReport;
      if (!mounted || currentPlayer != player) return;
      await _mediaControls.suspendForTvBackground('hidden_live_stopped');
      _recordLifecycleState('hidden', action: 'live_stopped_exit_on_resume');
      return;
    }

    final isAutomotive = PlatformDetector.isAutomotive();
    final shouldPauseForBackground = shouldPauseVideoForBackground(
      isHandheld: PlatformDetector.isHandheld(context),
      isTv: isTv,
      isAutomotive: isAutomotive,
    );

    // Pause first so Android MPV does not keep decoding against a transient
    // background surface while the app is locking or hiding.
    if (shouldPauseForBackground) {
      // Sticky latch: a car with the Automotive compatibility mode delivers
      // onPause *and* onStop, so this runs twice, and the second pass must not
      // overwrite the latch with the already-paused state. Cleared on resume.
      final wasActive = currentPlayer.state.isActive;
      _wasPlayingBeforeInactive = _wasPlayingBeforeInactive || wasActive;
      if (wasActive) {
        try {
          // On a car this is the driving transition itself, on every head unit whose vehicle cannot
          // report its restrictions. It is forced on this peer alone, so it must not travel to the
          // rest of a Watch Together room; elsewhere backgrounding keeps its existing meaning.
          if (isAutomotive) {
            if (await _pauseWithoutDisturbingTheRoom(currentPlayer)) {
              // The sync layer owns this pause and its resume. Drop the latch so the screen does not
              // also restore playback on the way back and ask the room to play along with it.
              _wasPlayingBeforeInactive = false;
            }
          } else {
            await _pauseWithPlaybackIntent(currentPlayer);
          }
          appLogger.d(
            'Video paused due to app being hidden '
            '(${isAutomotive
                ? 'automotive'
                : isTv
                ? 'tv'
                : 'handheld'})',
          );
        } catch (e) {
          appLogger.w('Failed to pause video before background transition', error: e);
        }
      }
    }

    if (!mounted || currentPlayer != player) return;

    _suspendLiveTimelineForBackground();

    if (isTv) {
      await _mediaControls.suspendForTvBackground('hidden');
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

    if (_live.exitOnResume) {
      _live.exitOnResume = false;
      _recordLifecycleState('resumed', action: 'exit_stopped_live_session');
      await _handleBackButton();
      return;
    }

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
      _mediaControls.resumeAfterTvBackground('app_resumed');
      await _mediaControls.restoreAfterResume();
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
  /// parked Plezy can't starve other apps on shared-hardware TV SoCs, and end
  /// the backend playback session. Fire OS standby never freezes the process,
  /// so paused heartbeats would pin the session in the server dashboard for
  /// as long as the device sits dark (#1911) — and they buy nothing here: the
  /// restore path performs a fresh playback decision and rebuilds progress
  /// reporting anyway. stop() retains Dart-side position/duration/track state
  /// on both Android backends; position and track selections are latched here
  /// because the reload on restore reads them after the native state is gone.
  Future<void> _suspendPlayerForTvBackground() async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null || !_isPlayerInitialized) return;
    // A live stream's tuned session is also its time-shift buffer. Stopping
    // it would force a re-tune at the live edge and discard pause state.
    if (widget.isLive) return;
    if (_playerSuspendedForTvBackground || _shouldSkipForPip) return;
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState == AppLifecycleState.resumed || lifecycleState == AppLifecycleState.inactive) return;
    if (_transitionGate.transition != PlaybackTransition.idle || !_firstFrame.uiReady.value) {
      // A reload/zap/startup flow owns the player right now; stopping under
      // it would corrupt its open sequence. Retry after another grace.
      _armTvBackgroundPlayerSuspendTimer();
      return;
    }

    final suspendPosition = currentPlayer.state.position;
    final suspendDuration = currentPlayer.state.duration;
    _tvBackgroundSuspendPosition = suspendPosition;
    _tvBackgroundSuspendAudioTrack = currentPlayer.state.track.audio;
    _tvBackgroundSuspendSubtitleTrack = currentPlayer.state.track.subtitle;
    _tvBackgroundSuspendSecondarySubtitleTrack = currentPlayer.state.track.secondarySubtitle;
    _playerSuspendedForTvBackground = true;
    // Stop the heartbeat timer first: its paused tick also pings any Plex
    // transcode session, which would keep that alive past the stop report.
    // Start the stopped report before releasing the native stream — the same
    // ordering as the live background path and the reload flow, because
    // stop() resets player state the report would otherwise read. The
    // one-shot latch coalesces this stop with the one the restore reload
    // sends before re-resolving the source.
    _progressTracker?.stopTracking();
    final stoppedReport = _sendStoppedProgressOnce(positionOverride: suspendPosition);
    try {
      await currentPlayer.stop();
      _recordLifecycleState('hidden', action: 'tv_background_suspend');
    } catch (e) {
      _playerSuspendedForTvBackground = false;
      _tvBackgroundSuspendPosition = null;
      _tvBackgroundSuspendAudioTrack = null;
      _tvBackgroundSuspendSubtitleTrack = null;
      _tvBackgroundSuspendSecondarySubtitleTrack = null;
      // The player still holds its native state, so re-arm reporting: the
      // next paused heartbeat re-opens a server session at the same position
      // and the pause stays resumable in place.
      await stoppedReport;
      _progressTracker?.resumeAfterStoppedReport();
      _progressTracker?.startTracking();
      appLogger.w('TV background suspend failed; player left paused', error: e);
      return;
    }
    await stoppedReport;
    if (!(_progressTracker?.stoppedReportDelivered ?? true)) {
      unawaited(_redeliverTvBackgroundStopReport(position: suspendPosition, duration: suspendDuration));
    }
  }

  /// Bounded redelivery of the suspend-time stopped report. Standby entry can
  /// drop Wi-Fi into power-save and stall exactly that connect, and mutations
  /// deliberately never fail over ([FailoverHttpClient]) — a lost terminal
  /// report would leave the server session pinned, the very state the suspend
  /// exists to clear (#1911). Runs detached from the lifecycle transition
  /// queue so a wake-up is never blocked behind a backoff sleep; each attempt
  /// re-checks that the suspend is still standing, because the restore path
  /// clears [_playerSuspendedForTvBackground] before it rebuilds a live
  /// session that a late retry must not report stopped.
  Future<void> _redeliverTvBackgroundStopReport({required Duration position, required Duration duration}) async {
    for (var attempt = 0; attempt < VideoPlayerScreenState._tvBackgroundStopReportMaxRetries; attempt++) {
      await Future<void>.delayed(VideoPlayerScreenState._tvBackgroundStopReportRetryDelay);
      final tracker = _progressTracker;
      if (!mounted || tracker == null || !_playerSuspendedForTvBackground) return;
      if (tracker.stoppedReportDelivered) return;
      await tracker.sendProgress('stopped', positionOverride: position, durationOverride: duration);
    }
  }

  /// Rebuild the playback session after a TV background suspend released the
  /// native pipeline and reported the backend session stopped. VOD reloads in
  /// place through the regular reload flow — a fresh playback decision, since
  /// the old session is closed and its stream URL may have expired
  /// server-side — and comes back paused; the caller's
  /// [MediaControlsScreenController.restoreAfterResume] then resumes it (with
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
    final outcome = await _reloadMediaInPlace(
      metadata: _currentMetadata,
      resumePosition: resumePosition,
      preserveCurrentTrackSelection: true,
      preservedAudioTrack: audioTrack,
      preservedSubtitleTrack: SubtitlePreference.trackOrNull(subtitleTrack),
      preservedSecondarySubtitleTrack: SubtitlePreference.trackOrNull(secondarySubtitleTrack),
      startPaused: true,
      reason: 'TV background suspend restore',
    );
    if (outcome == MediaReloadOutcome.rejected) {
      appLogger.w('TV background suspend restore: in-place reload rejected');
    } else if (outcome == MediaReloadOutcome.failed) {
      appLogger.w('TV background suspend restore: in-place reload failed');
    }
  }
}
