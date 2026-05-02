part of '../../video_player_screen.dart';

extension _VideoPlayerPlaybackPromptMethods on VideoPlayerScreenState {
  void _onVideoCompleted(bool completed, {bool skipAutoPlayCountdown = false}) async {
    // Live TV streams are continuous — ignore spurious EOF events caused by
    // inter-segment gaps in the chunked MKV transcode stream.
    if (widget.isLive) return;
    if (!completed) return;
    // Ignore spurious EOF from the old file during in-place episode swap
    if (_isSwappingEpisode) return;

    // mpv does not flip the `pause` property on EOF, so _onPlayingStateChanged
    // never fires false.  Normalize all playback-dependent state.
    unawaited(_setWakelock(false));
    unawaited(_progressTracker?.sendProgress('paused'));
    _updateMediaControlsPlaybackState();
    unawaited(DiscordRPCService.instance.pausePlayback());
    unawaited(TraktScrobbleService.instance.pausePlayback());
    if (_autoPipEnabled) {
      unawaited(_videoPIPManager?.updateAutoPipState(isPlaying: false));
    }

    if (_nextEpisode != null && !_showPlayNextDialog && !_showStillWatchingPrompt && !_completionTriggered) {
      _completionTriggered = true;

      // PiP: skip dialog (user can't interact), auto-play immediately
      if (PipService().isPipActive.value) {
        unawaited(_playNext());
        return;
      }

      // Capture keyboard mode before async gap
      final isKeyboardMode = PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context);

      final settings = await SettingsService.getInstance();
      final autoPlayEnabled = settings.read(SettingsService.autoPlayNextEpisode);

      if (skipAutoPlayCountdown && autoPlayEnabled) {
        unawaited(_playNext());
        return;
      }

      if (!mounted) return;
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
    } else if (_nextEpisode == null && !_completionTriggered) {
      _completionTriggered = true;
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
    _completionTriggered = false; // Reset so it can trigger again if user seeks near end
    _setPlayerState(() {
      _showPlayNextDialog = false;
    });
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
    player?.pause();
    _setPlayerState(() {
      _showStillWatchingPrompt = false;
    });
  }

  void _onStillWatchingContinue() {
    _stillWatchingTimer?.cancel();
    SleepTimerService().restartTimer();
    _setPlayerState(() {
      _showStillWatchingPrompt = false;
    });
  }

  void _onStillWatchingPause() {
    _stillWatchingTimer?.cancel();
    player?.pause();
    _setPlayerState(() {
      _showStillWatchingPrompt = false;
    });
  }

  void _dismissStillWatching() {
    _stillWatchingTimer?.cancel();
    if (_showStillWatchingPrompt) {
      _setPlayerState(() {
        _showStillWatchingPrompt = false;
      });
    }
  }
}
