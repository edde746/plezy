part of '../../video_player_screen.dart';

extension _VideoPlayerDisplayMatchingMethods on VideoPlayerScreenState {
  Future<void> _applyFrameRateMatching() async {
    if (player == null || !Platform.isAndroid) return;
    if (_frameRate.applied) return;

    try {
      final fpsStr = await player!.getProperty('container-fps');
      final fps = double.tryParse(fpsStr ?? '');
      if (fps == null || fps <= 0) {
        // ExoPlayer detects FPS from frame timestamps after ~8 rendered frames.
        // STATE_READY fires before frames render, so retry until detection completes.
        if (player!.detectsFpsAfterRender && _frameRate.retries < 10) {
          _frameRate.retries++;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && player != null) _applyFrameRateMatching();
          });
          return;
        }
        appLogger.d('Frame rate matching: No valid fps available ($fpsStr)');
        return;
      }

      _frameRate.retries = 0;
      _frameRate.applied = true;
      final durationMs = player!.state.duration.inMilliseconds;
      final settingsService = await SettingsService.getInstance();

      // Pause so the playback clock doesn't advance while the TV renegotiates
      // HDMI. The native setVideoFrameRate call below awaits the real display
      // change event (+ settle + user delay) before returning, and then we
      // resume — same shape as the primary pre-playback path, just later.
      try {
        await player!.pause();
      } catch (e) {
        appLogger.w('Failed to pause before frame rate switch', error: e);
      }

      final didSwitch = await _switchDisplayFrameRateForOpen(
        player: player!,
        settingsService: settingsService,
        fps: fps,
        durationMs: durationMs,
      );
      if (didSwitch) {
        await _refreshAndroidMpvDecoderAfterFrameRateSwitch(reason: 'post-first-frame display switch');
      }

      if (mounted && player != null) {
        await player!.play();
      }

      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(message: 'Frame rate matching: ${fps}fps, switched=$didSwitch', category: 'player'),
        ),
      );
      appLogger.d('Frame rate matching: Set display to ${fps}fps (duration: ${durationMs}ms, switched=$didSwitch)');
    } catch (e) {
      appLogger.w('Failed to apply frame rate matching', error: e);
    }
  }

  Future<void> _refreshAndroidMpvDecoderAfterFrameRateSwitch({required String reason}) async {
    final p = player;
    if (!mounted || p == null || !p.needsDecoderRefreshAfterDisplaySwitch) return;

    final isLive = widget.isLive;
    final targetPosition = p.state.position;

    // Subscribe before refreshing so the broadcast event isn't dropped when
    // the restart fires synchronously fast.
    var timedOut = false;
    final restartFuture = p.streams.playbackRestart.first.timeout(
      const Duration(seconds: 4),
      onTimeout: () {
        timedOut = true;
      },
    );
    final sw = Stopwatch()..start();
    try {
      if (isLive) {
        appLogger.d('Frame rate matching: flushing Android MPV live buffers ($reason, command=drop-buffers)');
        await p.command(['drop-buffers']);
      } else {
        appLogger.d(
          'Frame rate matching: refreshing Android MPV decoder '
          '($reason, target=${targetPosition.inMilliseconds}ms)',
        );
        await p.seek(targetPosition);
      }
      await restartFuture;
      appLogger.d(
        'Frame rate matching: refreshed Android MPV decoder '
        '($reason, target=${isLive ? 'live' : '${targetPosition.inMilliseconds}ms'}, waited=${sw.elapsedMilliseconds}ms, '
        'gate=${timedOut ? 'timeout' : 'playback-restart'})',
      );
    } catch (e) {
      appLogger.w('Failed to refresh Android MPV decoder after frame rate switch ($reason)', error: e);
    }
  }

  /// Apply Windows display mode matching (refresh rate, HDR).
  Future<void> _applyWindowsDisplayMatching() async {
    if (player == null || _displayModeService == null) return;

    try {
      final displayCriteria = _isTranscoding ? null : _currentMediaInfo?.displayCriteria;
      final fpsStr = await player!.getProperty('container-fps');
      final fallbackFps = double.tryParse(fpsStr ?? '');

      final sigPeakStr = await player!.getProperty('video-params/sig-peak');
      final sigPeak = double.tryParse(sigPeakStr ?? '');

      final delay = await _displayModeService!.applyDisplayMatching(
        criteria: displayCriteria,
        fallbackFps: fallbackFps,
        fallbackSigPeak: sigPeak,
      );

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
