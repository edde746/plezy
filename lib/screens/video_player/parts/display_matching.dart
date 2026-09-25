part of '../../video_player_screen.dart';

extension _VideoPlayerDisplayMatchingMethods on VideoPlayerScreenState {
  /// The Android display-mode request [output] yields under the user's
  /// matching settings, or null when neither setting produces a target. A
  /// null [fps] is a resolution-only switch: the native side keeps the
  /// current refresh rate.
  ({double? fps, int width, int height})? _displayTargetFor(
    SettingsService settingsService,
    PlayerOutputFormat output,
  ) {
    final fps = settingsService.read(SettingsService.matchContentFrameRate) ? output.fps : null;
    final matchResolution = settingsService.read(SettingsService.matchContentResolution);
    if (matchResolution && !output.hasDimensions) {
      appLogger.d('Display matching: no decoded dimensions for resolution matching');
    }
    final hasResolutionTarget = matchResolution && output.hasDimensions;
    if (fps == null && !hasResolutionTarget) return null;
    return (fps: fps, width: hasResolutionTarget ? output.width : 0, height: hasResolutionTarget ? output.height : 0);
  }

  /// Ask Android for [target], then refresh the mpv decoder if the display
  /// actually switched — seeking to [refreshPosition] when given (where the
  /// measurement window started), else in place. The caller has already
  /// paused playback. Returns whether a switch was initiated.
  Future<bool> _switchDisplayToTarget({
    required Player currentPlayer,
    required SettingsService settingsService,
    required ({double? fps, int width, int height}) target,
    required String reason,
    Duration? refreshPosition,
  }) async {
    _frameRate.applied = true;
    final durationMs = currentPlayer.state.duration.inMilliseconds;
    final didSwitch = await _switchDisplayFrameRateForOpen(
      player: currentPlayer,
      settingsService: settingsService,
      fps: target.fps ?? 0,
      durationMs: durationMs,
      videoWidth: target.width,
      videoHeight: target.height,
    );
    if (didSwitch && mounted && player == currentPlayer) {
      await _refreshAndroidMpvDecoderAfterFrameRateSwitch(reason: reason, targetPosition: refreshPosition);
    }

    unawaited(
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Display matching: ${target.fps}fps, ${target.width}x${target.height}, switched=$didSwitch',
          category: 'player',
        ),
      ),
    );
    appLogger.d(
      'Display matching: ${target.fps}fps, ${target.width}x${target.height} '
      '(duration: ${durationMs}ms, switched=$didSwitch, $reason)',
    );
    return didSwitch;
  }

  /// Post-first-frame display matching for an Android open that no startup
  /// gate owned: ExoPlayer without a metadata rate. mpv opens behind
  /// [_FrameRateStartupPlan.needsFirstFrameSwitch] instead, which marks the
  /// item applied before open so this stays a no-op for it.
  Future<void> _applyFrameRateMatching() async {
    if (player == null || !Platform.isAndroid) return;
    if (_frameRate.applied) return;

    try {
      final settingsService = await SettingsService.getInstance();
      final output = await PlayerOutputFormat.read(player!);
      if (!mounted || player == null) return;

      if (settingsService.read(SettingsService.matchContentFrameRate) && !output.hasFrameRate) {
        // ExoPlayer detects FPS from frame timestamps after ~8 rendered frames.
        // STATE_READY fires before frames render, so retry until detection
        // completes — also with resolution matching on, so one switch can
        // serve both rather than committing a resolution-only mode early.
        if (player!.detectsFpsAfterRender && _frameRate.retries < 10) {
          _frameRate.retries++;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && player != null) _applyFrameRateMatching();
          });
          return;
        }
        appLogger.d('Display matching: No valid fps available');
      }
      _frameRate.retries = 0;
      final target = _displayTargetFor(settingsService, output);
      if (target == null) return;

      // Pause so the playback clock doesn't advance while the TV renegotiates
      // HDMI. The native setVideoFrameRate call awaits the real display
      // change event (+ settle + user delay) before returning, and then we
      // resume.
      final currentPlayer = player!;
      try {
        await currentPlayer.pause();
      } catch (e) {
        appLogger.w('Failed to pause before display mode switch', error: e);
      }
      await _switchDisplayToTarget(
        currentPlayer: currentPlayer,
        settingsService: settingsService,
        target: target,
        reason: 'post-first-frame display switch',
      );
      if (mounted && player == currentPlayer) {
        await _playWithPlaybackIntent(currentPlayer);
      }
    } catch (e) {
      appLogger.w('Failed to apply frame rate matching', error: e);
    }
  }

  /// Restart the MediaCodec decoder against the reconfigured surface: a seek
  /// to [targetPosition] (default: in place) for VOD, a buffer flush for live.
  Future<void> _refreshAndroidMpvDecoderAfterFrameRateSwitch({required String reason, Duration? targetPosition}) async {
    final p = player;
    if (!mounted || p == null || !p.needsDecoderRefreshAfterDisplaySwitch) return;

    final isLive = widget.isLive;
    targetPosition ??= p.state.position;

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

  /// Apply Windows display mode matching (refresh rate, HDR) from what mpv
  /// presents: the derived output rate and `video-params/sig-peak`, which mpv
  /// raises above 1.0 for PQ/HLG (and Dolby Vision base layers).
  Future<void> _applyWindowsDisplayMatching() async {
    if (player == null || _displayModeService == null) return;

    try {
      final currentPlayer = player!;
      final output = await PlayerOutputFormat.read(currentPlayer);
      if (!mounted || player != currentPlayer) return;
      final sigPeak = double.tryParse(await currentPlayer.getProperty('video-params/sig-peak') ?? '');
      if (!mounted || _displayModeService == null) return;
      final displayModeService = _displayModeService!;

      final delay = await displayModeService.applyDisplayMatching(fps: output.fps, sigPeak: sigPeak);
      if (!mounted || player != currentPlayer) return;

      // Leaving fullscreen clears mpv's colorspace hint so its HDR swapchain
      // is released before system HDR goes off (_restoreWindowsDisplayMode).
      // With system HDR on again, restore the hint the user's HDR setting
      // asks for, or mpv keeps presenting SDR.
      if (displayModeService.hdrStateChanged) {
        final settingsService = await SettingsService.getInstance();
        final enableHDR = settingsService.read(SettingsService.enableHDR);
        await currentPlayer.setProperty('hdr-enabled', enableHDR ? 'yes' : 'no');
      }

      if (delay > Duration.zero) {
        // The delay lets the display finish re-syncing before playback runs
        // on, so hold playback through it (as the Android switch does) rather
        // than just waiting while the video keeps playing.
        final holdPlayback = currentPlayer.state.playing;
        if (holdPlayback) await currentPlayer.pause();
        await Future.delayed(delay);
        // A pause the viewer asked for meanwhile clears the play intent.
        if (holdPlayback && mounted && player == currentPlayer && _playbackIntentShouldPlay) {
          await _playWithPlaybackIntent(currentPlayer);
        }
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
      if (_firstFrame.uiReady.value && !_displayModeService!.anyChangeApplied) {
        _applyWindowsDisplayMatching();
      }
    } else if (_displayModeService!.anyChangeApplied) {
      _restoreWindowsDisplayMode();
    }
  }

  /// Restore Windows display mode to original state. Fullscreen-exit only:
  /// `dispose()` runs its own fire-and-forget variant because it cannot await
  /// the HDR settle below.
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
