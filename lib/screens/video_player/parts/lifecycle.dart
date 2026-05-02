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
      ' backend=$_playerBackendLabel',
    );
  }

  void _setAndroidAutoPipTransitionInFlight(bool value, {required String reason}) {
    if (!Platform.isAndroid || _androidAutoPipTransitionInFlight == value) return;
    _androidAutoPipTransitionInFlight = value;
    _recordLifecycleState('pip_transition', action: '${value ? 'started' : 'cleared'}:$reason');
  }

  void _suspendLiveTimelineForBackground() {
    _resumeLiveTimelineOnResume = _liveTimelineTimer != null;
    _stopLiveTimelineUpdates();
  }

  void _resumeLiveTimelineAfterBackgroundIfNeeded() {
    final shouldResume = _resumeLiveTimelineOnResume;
    _resumeLiveTimelineOnResume = false;
    if (shouldResume && _liveSessionIdentifier != null) {
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
          await currentPlayer.pause();
          appLogger.d('Video paused due to app being hidden (${isTv ? 'tv' : 'handheld'})');
        } catch (e) {
          appLogger.w('Failed to pause video before background transition', error: e);
        }
      }
    }

    if (!mounted || currentPlayer != player) return;

    _suspendLiveTimelineForBackground();

    if (isTv) {
      _recordLifecycleState('hidden', action: 'tv_background_pause_only');
      return;
    }

    _hiddenForBackground = true;
    await currentPlayer.setVisible(false);
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
      await currentPlayer.updateFrame();

      if (!mounted || currentPlayer != player) return;

      _hiddenForBackground = false;
      _recordLifecycleState('resumed', action: 'render_restored');
    }

    // Restore media controls and wakelock when app is resumed.
    if (_isPlayerInitialized && mounted) {
      await _restoreMediaControlsAfterResume();
    }

    _resumeLiveTimelineAfterBackgroundIfNeeded();
    _recordLifecycleState('resumed', action: 'complete');
  }
}
