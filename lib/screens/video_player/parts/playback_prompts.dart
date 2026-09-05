part of '../../video_player_screen.dart';

extension _VideoPlayerPlaybackPromptMethods on VideoPlayerScreenState {
  void _onVideoCompleted(bool completed, {bool skipAutoPlayCountdown = false}) async {
    // Live TV streams are continuous — ignore transient EOF events while an
    // HLS playlist refreshes or crosses a discontinuity.
    if (widget.isLive) return;
    if (!completed) return;
    // Ignore spurious EOF from the old file during an in-place media-source
    // transition (episode swap, transcode restart, channel switch).
    if (_transitionGate.transition != PlaybackTransition.idle) return;
    if (_episode.isResolvingCompletionAdjacency) return;

    // mpv does not flip the `pause` property on EOF, so _onPlayingStateChanged
    // never fires false.  Normalize all playback-dependent state.
    unawaited(_wakelockController.setEnabled(false));
    final duration = player?.state.duration;
    unawaited(
      duration != null && duration.inMilliseconds > 0
          ? _sendStoppedProgressOnce(positionOverride: duration)
          : _sendStoppedProgressOnce(),
    );
    _mediaControls.pushPlaybackState();
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
    if (sleepTimerService.isEndOfVideoMode && !_episode.completionLatch.triggered) {
      _episode.completionLatch.latch();
      sleepTimerService.notifyVideoCompleted();
      return;
    }
    if (!_canNavigateMediaItems()) {
      if (!_episode.completionLatch.triggered) _episode.completionLatch.latch();
      return;
    }

    var navigationAction = completionNavigationAction(
      hasNext: _episode.next != null,
      adjacentStatus: _episode.nextStatus,
    );
    if (navigationAction == CompletionNavigationAction.retryAdjacent) {
      _episode.isResolvingCompletionAdjacency = true;
      try {
        await _loadAdjacentEpisodes();
      } finally {
        _episode.isResolvingCompletionAdjacency = false;
      }
      if (!mounted) return;
      navigationAction = completionNavigationAction(
        hasNext: _episode.next != null,
        adjacentStatus: _episode.nextStatus,
      );
      if (navigationAction == CompletionNavigationAction.retryAdjacent) {
        _episode.completionLatch.latch();
        showGlobalErrorSnackBar(t.messages.errorLoadingSeries);
        return;
      }
    }

    if (navigationAction == CompletionNavigationAction.presentNext &&
        !_episode.showPlayNextDialog &&
        !_showStillWatchingPrompt &&
        !_episode.completionLatch.triggered) {
      _episode.completionLatch.latch();

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
      final countdownSeconds = settings.read(SettingsService.playNextCountdown);

      // A zero countdown (#1827) behaves like the PiP path above: no prompt,
      // straight into the next episode.
      if (autoPlayEnabled && (skipAutoPlayCountdown || countdownSeconds == 0)) {
        unawaited(_playNext());
        return;
      }

      _setPlayerState(() {
        _episode.showPlayNextDialog = true;
        _episode.autoPlayCountdown.value = autoPlayEnabled ? countdownSeconds : -1;
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
    } else if (navigationAction == CompletionNavigationAction.exit && !_episode.completionLatch.triggered) {
      _episode.completionLatch.latch();
      unawaited(_handleBackButton());
    }
  }

  void _startAutoPlayTimer() {
    if (!_canNavigateMediaItems()) return;
    _episode.autoPlayTimer?.cancel();
    _episode.autoPlayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final nextCountdown = _episode.autoPlayCountdown.value - 1;
      _episode.autoPlayCountdown.value = nextCountdown;
      if (nextCountdown <= 0) {
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
    if (_episode.isLoadingNext || _episode.showPlayNextDialog || _showStillWatchingPrompt) return;

    // Capture keyboard mode before the async gap, same as _onVideoCompleted.
    final isKeyboardMode = PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context, listen: false);
    final settings = await SettingsService.getInstance();
    if (!mounted || _episode.isLoadingNext || _episode.showPlayNextDialog) return;

    final presentation = playNextRetryPresentation(
      wasAtCompletion: wasAtCompletion,
      failureReason: _episode.lastReloadFailureReason,
      hasNext: _episode.next != null,
      autoPlayEnabled: settings.read(SettingsService.autoPlayNextEpisode),
      inWatchTogetherSession: _activeWatchTogetherSession() != null,
      autoRetriesUsed: _episode.playNextTransientRetryCount,
    );
    if (presentation == PlayNextRetryPresentation.none) return;

    // The failed reload's rollback reset the latch; re-latch so a duplicate
    // EOF signal from the parked stream cannot stack a second prompt on top.
    if (!_episode.completionLatch.triggered) _episode.completionLatch.latch();

    final countdown = presentation == PlayNextRetryPresentation.countdown;
    if (countdown) _episode.playNextTransientRetryCount++;

    _setPlayerState(() {
      _episode.showPlayNextDialog = true;
      // Deliberately not [SettingsService.playNextCountdown]: this countdown
      // spaces transient-failure retries (see completion_latch.dart), so a
      // user preference of 0 must not collapse it into a hot retry loop.
      _episode.autoPlayCountdown.value = countdown ? 5 : -1;
    });

    if (isKeyboardMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playNextConfirmFocusNode.requestFocus();
      });
    }

    if (countdown) _startAutoPlayTimer();
  }

  void _cancelAutoPlay() {
    _episode.autoPlayTimer?.cancel();
    _unfocusPlayNextPrompt();
    _progressTracker?.resumeAfterStoppedReport();
    // Keep the latch set while playback is still parked at EOF, so duplicate
    // completed signals cannot re-open this prompt. It is re-armed once playback
    // seeks back clear of the end region (see the position listener) or new media loads.
    _setPlayerState(() {
      _episode.showPlayNextDialog = false;
    });
  }

  void _dismissPlaybackPromptForBack() {
    if (_episode.showPlayNextDialog) {
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
    _episode.completionLatch.rearmIfClear(
      promptVisible: _episode.showPlayNextDialog,
      countdownActive: _episode.autoPlayTimer?.isActive == true,
    );
  }

  void _showStillWatchingDialog() {
    // Don't show if auto-play dialog is already visible
    if (_episode.showPlayNextDialog) return;

    final isKeyboardMode = PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context, listen: false);

    _setPlayerState(() {
      _showStillWatchingPrompt = true;
      _stillWatchingCountdown.value = 30;
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
      final nextCountdown = _stillWatchingCountdown.value - 1;
      _stillWatchingCountdown.value = nextCountdown;
      if (nextCountdown <= 0) {
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
      // Back or a next-episode action on the visible prompt is the same
      // "still watching" acknowledgement as Continue: re-arm the sleep timer.
      // Guarded on prompt visibility — ordinary navigation also dismisses
      // here and must leave an armed timer untouched.
      SleepTimerService().restartTimer();
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
