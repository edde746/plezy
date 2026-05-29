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

  /// Initialize VideoFilterManager and VideoPIPManager if not already set up.
  /// Called from both live TV and VOD playback paths.
  Future<void> _initVideoFilterAndPip() async {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return;
    if (_videoFilterManager != null && _videoPIPManager != null) {
      _attachPipStateListener();
      return;
    }

    final needsVideoFilter = _videoFilterManager == null;
    final settings = needsVideoFilter ? await SettingsService.getInstance() : null;
    if (!mounted || player != currentPlayer) return;

    if (needsVideoFilter && _videoFilterManager == null && settings != null) {
      _videoFilterManager = VideoFilterManager(
        player: currentPlayer,
        availableVersions: _availableVersions,
        selectedMediaIndex: widget.selectedMediaIndex,
        initialBoxFitMode: settings.read(SettingsService.defaultBoxFitMode),
        onBoxFitModeChanged: (mode) => settings.write(SettingsService.defaultBoxFitMode, mode),
      );
      unawaited(_videoFilterManager!.updateVideoFilter());
    }

    _videoPIPManager ??= VideoPIPManager(player: currentPlayer);
    _videoPIPManager!.onBeforeEnterPip = _preparePipFiltersForEntry;
    _attachPipStateListener();
  }

  Future<void> _togglePIPMode() async {
    final result = await _videoPIPManager?.togglePIP();
    if (result != null && !result.$1 && mounted) {
      _restorePipFiltersAfterExit();
      showErrorSnackBar(context, result.$2 ?? t.videoControls.pipFailed);
    }
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

    final isInPip = _videoPIPManager?.isPipActive.value ?? PipService().isPipActive.value;
    _setAndroidAutoPipTransitionInFlight(false, reason: 'pip_state_changed');
    _recordLifecycleState('pip_state_changed', action: isInPip ? 'entered' : 'exited');

    if (_videoPIPManager == null || _videoFilterManager == null) return;

    if (isInPip) {
      _preparePipFiltersForEntry();
    } else {
      _restorePipFiltersAfterExit();
    }
  }
}
