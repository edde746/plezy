part of '../../video_player_screen.dart';

extension _VideoPlayerDisplayMatchingMethods on VideoPlayerScreenState {
  Future<void> _applyFrameRateMatching() async {
    if (player == null || !Platform.isAndroid) return;
    if (_frameRateMatchingApplied) return;

    try {
      final fpsStr = await player!.getProperty('container-fps');
      final fps = double.tryParse(fpsStr ?? '');
      if (fps == null || fps <= 0) {
        // ExoPlayer detects FPS from frame timestamps after ~8 rendered frames.
        // STATE_READY fires before frames render, so retry until detection completes.
        if (player is PlayerAndroid && _frameRateRetries < 10) {
          _frameRateRetries++;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && player != null) _applyFrameRateMatching();
          });
          return;
        }
        appLogger.d('Frame rate matching: No valid fps available ($fpsStr)');
        return;
      }

      _frameRateRetries = 0;
      _frameRateMatchingApplied = true;
      final durationMs = player!.state.duration.inMilliseconds;
      final settingsService = await SettingsService.getInstance();
      final delaySec = settingsService.read(SettingsService.displaySwitchDelay);

      // Suppress spurious PauseEvent from MediaSession during HDMI renegotiation.
      // Fire Stick (and similar Android TV devices) send onPause() through the
      // MediaSession callback when the display mode changes for frame rate matching.
      _suppressMediaPauseDuringFrameRateSwitch = true;
      Future.delayed(Duration(seconds: 2 + delaySec + 1), () {
        _suppressMediaPauseDuringFrameRateSwitch = false;
      });

      // Pause so the playback clock doesn't advance while the TV renegotiates
      // HDMI. The native setVideoFrameRate call below awaits the real display
      // change event (+ settle + user delay) before returning, and then we
      // resume — same shape as the primary pre-playback path, just later.
      try {
        await player!.pause();
      } catch (e) {
        appLogger.w('Failed to pause before frame rate switch', error: e);
      }

      final didSwitch = await player!.setVideoFrameRate(fps, durationMs, extraDelayMs: delaySec * 1000);

      // Set MPV video-sync mode for smoother playback when display is synced
      try {
        await player!.setProperty('video-sync', 'display-tempo');
      } catch (e) {
        appLogger.d('video-sync property unsupported', error: e);
      }

      if (mounted && player != null) {
        await player!.play();
      }

      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Frame rate matching: ${fps}fps, switched=$didSwitch, delay=${delaySec}s',
            category: 'player',
          ),
        ),
      );
      appLogger.d('Frame rate matching: Set display to ${fps}fps (duration: ${durationMs}ms, switched=$didSwitch)');
    } catch (e) {
      appLogger.w('Failed to apply frame rate matching', error: e);
    }
  }

  /// Clear frame rate matching and restore default display mode
  Future<void> _clearFrameRateMatching() async {
    if (player == null || !Platform.isAndroid) return;

    try {
      await player!.clearVideoFrameRate();
      await player!.setProperty('video-sync', 'audio');
      unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'Frame rate matching cleared', category: 'player')));
      appLogger.d('Frame rate matching: Cleared, restored default display mode');
    } catch (e) {
      appLogger.d('Failed to clear frame rate matching', error: e);
    }
  }

  /// Apply Windows display mode matching (refresh rate, HDR).
  Future<void> _applyWindowsDisplayMatching() async {
    if (player == null || _displayModeService == null) return;

    try {
      final fpsStr = await player!.getProperty('container-fps');
      final fps = double.tryParse(fpsStr ?? '');

      final sigPeakStr = await player!.getProperty('video-params/sig-peak');
      final sigPeak = double.tryParse(sigPeakStr ?? '');

      final delay = await _displayModeService!.applyDisplayMatching(fps: fps, sigPeak: sigPeak);

      if (delay > Duration.zero) {
        await Future.delayed(delay);
      }
    } catch (e) {
      appLogger.w('Failed to apply display mode matching', error: e);
    }
  }

  /// Called when fullscreen state changes — apply or restore Windows display
  /// matching. On Windows the player opens windowed by default, so the initial
  /// attempt during `playbackRestart` is skipped by DisplayModeService's
  /// fullscreen gate. Catching the enter-fullscreen transition here lets the
  /// switch happen at the natural moment the user starts watching.
  void _onFullscreenChanged() {
    if (_displayModeService == null) return;
    if (FullscreenStateManager().isFullscreen) {
      if (_hasFirstFrame.value && !_displayModeService!.anyChangeApplied) {
        _applyWindowsDisplayMatching();
      }
    } else if (_displayModeService!.anyChangeApplied) {
      _restoreWindowsDisplayMode();
    }
  }

  /// Restore Windows display mode to original state.
  Future<void> _restoreWindowsDisplayMode() async {
    if (_displayModeService == null || !_displayModeService!.anyChangeApplied) return;

    try {
      // If HDR was toggled, release mpv's HDR swapchain first.
      if (_displayModeService!.hdrStateChanged && player != null) {
        await player!.setProperty('target-colorspace-hint', 'no');
        await Future.delayed(const Duration(milliseconds: 200));
      }

      await _displayModeService!.restoreAll();
    } catch (e) {
      appLogger.w('Failed to restore display mode', error: e);
    }
  }
}
