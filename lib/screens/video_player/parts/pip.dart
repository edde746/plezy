part of '../../video_player_screen.dart';

extension _VideoPlayerPipMethods on VideoPlayerScreenState {
  void _attachPipStateListener() {
    final pipState = PipService().isPipActive;
    pipState.removeListener(_onPipStateChanged);
    pipState.addListener(_onPipStateChanged);
  }

  void _detachPipStateListener() {
    PipService().isPipActive.removeListener(_onPipStateChanged);
  }

  void _clearAutoPipEnteringCallback() {
    final callback = _autoPipEnteringCallback;
    if (callback != null && identical(PipService.onAutoPipEntering, callback)) {
      PipService.onAutoPipEntering = null;
    }
    _autoPipEnteringCallback = null;
  }

  /// Initialize VideoFilterManager and the PiP methods if not already set up.
  /// Called from both live TV and VOD playback paths.
  Future<void> _initVideoFilterAndPip() async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return;
    if (_videoFilterManager != null && _pipInitialized) {
      _attachPipStateListener();
      return;
    }

    final needsVideoFilter = _videoFilterManager == null;
    final settings = needsVideoFilter ? await SettingsService.getInstance() : null;
    if (!mounted || player != currentPlayer) return;
    final initialPlayerSize = _lastVideoLayoutPlayer == currentPlayer ? _lastVideoLayoutSize : null;

    if (needsVideoFilter && _videoFilterManager == null && settings != null) {
      _videoFilterManager = VideoFilterManager(
        player: currentPlayer,
        // iOS and tvOS zoom the native video layer; mpv's video-zoom would
        // force vo_avfoundation's Core Image path and kill HDR/DV passthrough.
        nativeVideoZoom: Platform.isIOS,
        initialBoxFitMode: ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.boxFitMode, _currentMetadata),
        initialPlayerSize: initialPlayerSize,
        // Reads _currentMetadata at invocation time so a cycle after an
        // in-place episode swap keys against the item actually on screen.
        onBoxFitModeChanged: (mode) =>
            unawaited(ScopedPlayerPrefs.write(ScopedPlayerPrefs.boxFitMode, _currentMetadata, mode)),
      );
      unawaited(_videoFilterManager!.updateVideoFilter());
    }

    _pipInitialized = true;
    _attachPipStateListener();
  }

  Future<void> _togglePIPMode() async {
    if (!_pipInitialized) return;

    final supported = await PipService.isSupported();
    if (!supported) {
      _onPipRequestFailed('PiP not supported on this device');
      return;
    }

    // If PiP is already active, exit it
    if (PipService().isPipActive.value) {
      await PipService.exit();
      return;
    }

    // Reset video filter to contain mode before entering PiP. Android, iOS,
    // and macOS all reuse the inline video surface/layer for PiP.
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      if (_pipInitialized) _preparePipFiltersForEntry();
      // Wait a frame for the filter change to take effect
      await Future.delayed(const Duration(milliseconds: 50));
    }

    final dims = await _getVideoDimensions();
    final result = await PipService.enter(width: dims.$1, height: dims.$2);
    if (!result.$1) _onPipRequestFailed(result.$2);
  }

  void _onPipRequestFailed(String? error) {
    if (!mounted) return;
    _restorePipFiltersAfterExit();
    showErrorSnackBar(context, error ?? t.videoControls.pipFailed);
  }

  Future<void> _updateAutoPipState({required bool isPlaying}) async {
    if (!_pipInitialized) return;

    if (!isPlaying) {
      await PipService.setAutoPipReady(ready: false);
      return;
    }

    final dims = await _getVideoDimensions();
    await PipService.setAutoPipReady(ready: true, width: dims.$1, height: dims.$2);
  }

  /// Get current video dimensions (display or storage or fallback to viewport)
  Future<(int? width, int? height)> _getVideoDimensions() async {
    final currentPlayer = player;
    int? width;
    int? height;

    try {
      final dwidth = await currentPlayer?.getProperty('dwidth');
      final dheight = await currentPlayer?.getProperty('dheight');
      if (dwidth != null && dheight != null) {
        width = int.tryParse(dwidth);
        height = int.tryParse(dheight);
      }
    } catch (e) {
      appLogger.d('PiP: dwidth/dheight unavailable', error: e);
    }

    if (width == null || height == null) {
      try {
        final videoWidth = await currentPlayer?.getProperty('width');
        final videoHeight = await currentPlayer?.getProperty('height');
        if (videoWidth != null && videoHeight != null) {
          width = int.tryParse(videoWidth);
          height = int.tryParse(videoHeight);
        }
      } catch (e) {
        appLogger.d('PiP: width/height unavailable', error: e);
      }
    }

    final viewport = _lastVideoLayoutPlayer == currentPlayer ? _lastVideoLayoutSize : null;
    width ??= viewport?.width.toInt();
    height ??= viewport?.height.toInt();

    return (width, height);
  }

  void _preparePipFiltersForEntry() {
    if (!mounted) return;
    if (_pipFiltersPrepared) return;
    _pipFiltersPrepared = true;
    _videoFilterManager?.enterPipMode();
  }

  void _restorePipFiltersAfterExit() {
    if (!mounted) {
      _pipFiltersPrepared = false;
      return;
    }

    final filterManager = _videoFilterManager;
    if (filterManager == null) {
      _pipFiltersPrepared = false;
      return;
    }

    final restoreAmbient = filterManager.hadAmbientLightingBeforePip;
    filterManager.exitPipMode();
    if (restoreAmbient) {
      filterManager.clearPipAmbientLightingFlag();
      unawaited(_restoreAmbientLighting());
    }
    _pipFiltersPrepared = false;
  }

  /// Handle PiP state changes to restore video scaling when exiting PiP
  void _onPipStateChanged() {
    if (!mounted || player == null) {
      _detachPipStateListener();
      return;
    }

    final isInPip = PipService().isPipActive.value;
    _setAndroidAutoPipTransitionInFlight(false, reason: 'pip_state_changed');
    _recordLifecycleState('pip_state_changed', action: isInPip ? 'entered' : 'exited');

    if (!_pipInitialized || _videoFilterManager == null) return;

    if (isInPip) {
      _preparePipFiltersForEntry();
    } else {
      _restorePipFiltersAfterExit();
    }
  }
}
