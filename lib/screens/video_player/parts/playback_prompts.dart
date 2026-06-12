part of '../../video_player_screen.dart';

extension _VideoPlayerPlaybackPromptMethods on VideoPlayerScreenState {
  void _onVideoCompleted(bool completed, {bool skipAutoPlayCountdown = false}) async {
    // Live TV streams are continuous — ignore spurious EOF events caused by
    // inter-segment gaps in the chunked MKV transcode stream.
    if (widget.isLive) return;
    if (!completed) return;
    // Ignore spurious EOF from the old file during an in-place media-source
    // transition (episode swap, transcode restart, channel switch).
    if (_playbackTransition != _PlaybackTransition.idle) return;

    // mpv does not flip the `pause` property on EOF, so _onPlayingStateChanged
    // never fires false.  Normalize all playback-dependent state.
    unawaited(_setWakelock(false));
    final duration = player?.state.duration;
    unawaited(
      duration != null && duration.inMilliseconds > 0
          ? _sendStoppedProgressOnce(positionOverride: duration)
          : _sendStoppedProgressOnce(),
    );
    _updateMediaControlsPlaybackState();
    unawaited(DiscordRPCService.instance.pausePlayback());
    unawaited(TraktScrobbleService.instance.pausePlayback());
    if (_autoPipEnabled) {
      unawaited(_videoPIPManager?.updateAutoPipState(isPlaying: false));
    }

    // End-of-video sleep timer takes precedence over autoplay / next-episode
    // dialogs: the user explicitly asked to stop after this item.
    final sleepTimerService = SleepTimerService();
    if (sleepTimerService.isEndOfVideoMode && !_completionLatch.triggered) {
      _completionLatch.latch();
      sleepTimerService.notifyVideoCompleted();
      return;
    }

    if (_nextEpisode != null && !_showPlayNextDialog && !_showStillWatchingPrompt && !_completionLatch.triggered) {
      _completionLatch.latch();

      // PiP: skip dialog (user can't interact), auto-play immediately
      if (PipService().isPipActive.value) {
        unawaited(_playNext());
        return;
      }

      // Capture keyboard mode before async gap
      final isKeyboardMode = PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context);

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
    } else if (_nextEpisode == null && !_completionLatch.triggered) {
      _completionLatch.latch();
      unawaited(_handleBackButton());
    }
  }

  void _startAutoPlayTimer() {
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

  void _cancelAutoPlay() {
    _autoPlayTimer?.cancel();
    _unfocusPlayNextPrompt();
    _progressTracker?.resumeAfterStoppedReport();
    // Keep _completionTriggered set: playback is still parked inside the
    // end-of-video window, so clearing it here would let the position listener
    // re-fire this prompt on the next tick. It is re-armed once playback seeks
    // back clear of the end region (see the position listener) or new media loads.
    _setPlayerState(() {
      _showPlayNextDialog = false;
    });
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

    final isKeyboardMode = PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context);

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
    player?.pause();
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
    player?.pause();
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
