part of '../../video_player_screen.dart';

extension _VideoPlayerPlaybackPromptMethods on VideoPlayerScreenState {
  void _onVideoCompleted(bool completed, {bool skipAutoPlayCountdown = false}) async {
    // Live TV streams are continuous — ignore transient EOF events while an
    // HLS playlist refreshes or crosses a discontinuity.
    if (widget.isLive) return;
    if (!completed) return;
    // Ignore spurious EOF from the old file during an in-place media-source
    // transition (episode swap, transcode restart, channel switch).
    if (_playbackTransition != _PlaybackTransition.idle) return;
    if (_isResolvingCompletionAdjacency) return;

    // mpv does not flip the `pause` property on EOF, so _onPlayingStateChanged
    // never fires false.  Normalize all playback-dependent state.
    unawaited(_wakelockController.setEnabled(false));
    final duration = player?.state.duration;
    unawaited(
      duration != null && duration.inMilliseconds > 0
          ? _sendStoppedProgressOnce(positionOverride: duration)
          : _sendStoppedProgressOnce(),
    );
    _updateMediaControlsPlaybackState();
    unawaited(DiscordRPCService.instance.pausePlayback());
    // The item finished, so real-time trackers get a terminal report now rather
    // than whenever the screen happens to tear down: a completion prompt or
    // end-of-video sleep timer can leave it open for minutes, and until then
    // the service would still show the item as playing. Seed the known duration
    // first — the position stream can stop a beat short of it on EOF. A later
    // dispose or in-place reload finds no context and does nothing.
    if (duration != null && duration.inMilliseconds > 0) {
      TrackerCoordinator.instance.updatePosition(duration);
    }
    unawaited(TrackerCoordinator.instance.stopPlayback());
    if (_autoPipEnabled) {
      unawaited(_updateAutoPipState(isPlaying: false));
    }

    // End-of-video sleep timer takes precedence over autoplay / next-episode
    // dialogs: the user explicitly asked to stop after this item.
    final sleepTimerService = SleepTimerService();
    if (sleepTimerService.isEndOfVideoMode && !_completionLatch.triggered) {
      _completionLatch.latch();
      sleepTimerService.notifyVideoCompleted();
      return;
    }
    if (!_canNavigateMediaItems()) {
      if (!_completionLatch.triggered) _completionLatch.latch();
      return;
    }

    var navigationAction = completionNavigationAction(
      hasNext: _nextEpisode != null,
      adjacentStatus: _nextEpisodeStatus,
    );
    if (navigationAction == CompletionNavigationAction.retryAdjacent) {
      _isResolvingCompletionAdjacency = true;
      try {
        await _loadAdjacentEpisodes();
      } finally {
        _isResolvingCompletionAdjacency = false;
      }
      if (!mounted) return;
      navigationAction = completionNavigationAction(hasNext: _nextEpisode != null, adjacentStatus: _nextEpisodeStatus);
      if (navigationAction == CompletionNavigationAction.retryAdjacent) {
        _completionLatch.latch();
        showGlobalErrorSnackBar(t.messages.errorLoadingSeries);
        return;
      }
    }

    if (navigationAction == CompletionNavigationAction.presentNext &&
        !_showPlayNextDialog &&
        !_showStillWatchingPrompt &&
        !_completionLatch.triggered) {
      _completionLatch.latch();

      // Repeat-all is an explicit continuous playback request. Do not make it
      // depend on the global autoplay-next setting or show the Play Next UI.
      final playbackState = context.read<PlaybackStateProvider>();
      if (playbackState.isRepeatActive) {
        unawaited(_playNext());
        return;
      }

      // PiP: skip dialog (user can't interact), auto-play immediately
      if (PipService().isPipActive.value) {
        unawaited(_playNext());
        return;
      }

      // Capture keyboard mode before async gap
      final isKeyboardMode = PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context, listen: false);

      final settings = await SettingsService.getInstance();
      if (!mounted) return;
      final autoPlayEnabled = settings.read(SettingsService.autoPlayNextEpisode);

      if (skipAutoPlayCountdown && autoPlayEnabled) {
        unawaited(_playNext());
        return;
      }

      _setPlayerState(() {
        _showPlayNextDialog = true;
        _autoPlayCountdown = autoPlayEnabled ? 5 : -1;
      });

      // Auto-focus Play Next button on TV when dialog appears (only in keyboard/TV mode)
      if (isKeyboardMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _playNextConfirmFocusNode.requestFocus();
          }
        });
      }

      if (autoPlayEnabled) {
        _startAutoPlayTimer();
      }
    } else if (navigationAction == CompletionNavigationAction.exit && !_completionLatch.triggered) {
      _completionLatch.latch();
      unawaited(_handleBackButton());
    }
  }

  void _startAutoPlayTimer() {
    if (!_canNavigateMediaItems()) return;
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _setPlayerState(() {
        _autoPlayCountdown--;
      });
      if (_autoPlayCountdown <= 0) {
        timer.cancel();
        _playNext();
      }
    });
  }

  /// Re-present the Play Next prompt after an EOF-driven advance failed on a
  /// transient server blip (#1867).
  ///
  /// The failed reload rolled back to the finished episode's last frame, so
  /// without a prompt the screen parks black until the device sleeps — while
  /// a retry seconds later typically succeeds (skipping manually did exactly
  /// that). [playNextRetryPresentation] owns the decision: only EOF-driven
  /// advances that failed with [PlaybackFailureReason.serverUnavailable]
  /// qualify, the auto-play countdown re-fires [_playNext] up to
  /// [maxPlayNextTransientRetries] times, and after that (with auto-play
  /// off, or in a Watch Together session) the prompt waits for a manual
  /// retry.
  void _presentPlayNextRetryPrompt({required bool wasAtCompletion}) async {
    if (!mounted || !_canNavigateMediaItems()) return;
    if (_isLoadingNext || _showPlayNextDialog || _showStillWatchingPrompt) return;

    // Capture keyboard mode before the async gap, same as _onVideoCompleted.
    final isKeyboardMode = PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context, listen: false);
    final settings = await SettingsService.getInstance();
    if (!mounted || _isLoadingNext || _showPlayNextDialog) return;

    final presentation = playNextRetryPresentation(
      wasAtCompletion: wasAtCompletion,
      failureReason: _lastMediaReloadFailureReason,
      hasNext: _nextEpisode != null,
      autoPlayEnabled: settings.read(SettingsService.autoPlayNextEpisode),
      inWatchTogetherSession: _activeWatchTogetherSession() != null,
      autoRetriesUsed: _playNextTransientRetryCount,
    );
    if (presentation == PlayNextRetryPresentation.none) return;

    // The failed reload's rollback reset the latch; re-latch so a duplicate
    // EOF signal from the parked stream cannot stack a second prompt on top.
    if (!_completionLatch.triggered) _completionLatch.latch();

    final countdown = presentation == PlayNextRetryPresentation.countdown;
    if (countdown) _playNextTransientRetryCount++;

    _setPlayerState(() {
      _showPlayNextDialog = true;
      _autoPlayCountdown = countdown ? 5 : -1;
    });

    if (isKeyboardMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playNextConfirmFocusNode.requestFocus();
      });
    }

    if (countdown) _startAutoPlayTimer();
  }

  void _cancelAutoPlay() {
    _autoPlayTimer?.cancel();
    _unfocusPlayNextPrompt();
    _progressTracker?.resumeAfterStoppedReport();
    // Keep the latch set while playback is still parked at EOF, so duplicate
    // completed signals cannot re-open this prompt. It is re-armed once playback
    // seeks back clear of the end region (see the position listener) or new media loads.
    _setPlayerState(() {
      _showPlayNextDialog = false;
    });
  }

  void _dismissPlaybackPromptForBack() {
    if (_showPlayNextDialog) {
      _cancelAutoPlay();
      return;
    }
    if (_showStillWatchingPrompt) {
      _dismissStillWatching();
    }
  }

  /// Re-arm the end-of-video latch so Play Next can fire again. Callers
  /// decide *when* it is safe to re-arm (media reloaded, or playback moved
  /// back out of the end region); the latch itself refuses while a prompt
  /// or countdown is active.
  void _rearmCompletionLatch() {
    _completionLatch.rearmIfClear(
      promptVisible: _showPlayNextDialog,
      countdownActive: _autoPlayTimer?.isActive == true,
    );
  }

  void _showStillWatchingDialog() {
    // Don't show if auto-play dialog is already visible
    if (_showPlayNextDialog) return;

    final isKeyboardMode = PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context, listen: false);

    _setPlayerState(() {
      _showStillWatchingPrompt = true;
      _stillWatchingCountdown = 30;
    });

    if (isKeyboardMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _stillWatchingContinueFocusNode.requestFocus();
      });
    }

    _stillWatchingTimer?.cancel();
    _stillWatchingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _setPlayerState(() {
        _stillWatchingCountdown--;
      });
      if (_stillWatchingCountdown <= 0) {
        timer.cancel();
        _onStillWatchingTimeout();
      }
    });
  }

  void _onStillWatchingTimeout() {
    _unfocusStillWatchingPrompt();
    final currentPlayer = player;
    if (currentPlayer != null) unawaited(_pauseWithPlaybackIntent(currentPlayer));
    _setPlayerState(() {
      _showStillWatchingPrompt = false;
    });
  }

  void _onStillWatchingContinue() {
    _stillWatchingTimer?.cancel();
    _unfocusStillWatchingPrompt();
    SleepTimerService().restartTimer();
    _setPlayerState(() {
      _showStillWatchingPrompt = false;
    });
  }

  void _onStillWatchingPause() {
    _stillWatchingTimer?.cancel();
    _unfocusStillWatchingPrompt();
    final currentPlayer = player;
    if (currentPlayer != null) unawaited(_pauseWithPlaybackIntent(currentPlayer));
    _setPlayerState(() {
      _showStillWatchingPrompt = false;
    });
  }

  void _dismissStillWatching() {
    _stillWatchingTimer?.cancel();
    if (_showStillWatchingPrompt) {
      _unfocusStillWatchingPrompt();
      _setPlayerState(() {
        _showStillWatchingPrompt = false;
      });
    }
  }

  void _unfocusPlayNextPrompt() {
    _playNextCancelFocusNode.unfocus();
    _playNextConfirmFocusNode.unfocus();
  }

  void _unfocusStillWatchingPrompt() {
    _stillWatchingPauseFocusNode.unfocus();
    _stillWatchingContinueFocusNode.unfocus();
  }
}
