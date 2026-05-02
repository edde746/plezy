part of '../../video_player_screen.dart';

extension _VideoPlayerPipShaderMethods on VideoPlayerScreenState {
  /// Initialize VideoFilterManager and VideoPIPManager if not already set up.
  /// Called from both live TV and VOD playback paths.
  Future<void> _initVideoFilterAndPip() async {
    if (player == null || _videoFilterManager != null) return;
    final settings = await SettingsService.getInstance();
    _videoFilterManager = VideoFilterManager(
      player: player!,
      availableVersions: _availableVersions,
      selectedMediaIndex: widget.selectedMediaIndex,
      initialBoxFitMode: settings.read(SettingsService.defaultBoxFitMode),
      onBoxFitModeChanged: (mode) => settings.write(SettingsService.defaultBoxFitMode, mode),
    );
    _videoFilterManager!.updateVideoFilter();

    _videoPIPManager = VideoPIPManager(player: player!);
    _videoPIPManager!.onBeforeEnterPip = () {
      _videoFilterManager?.enterPipMode();
    };
    _videoPIPManager!.isPipActive.addListener(_onPipStateChanged);
  }

  Future<void> _togglePIPMode() async {
    final result = await _videoPIPManager?.togglePIP();
    if (result != null && !result.$1 && mounted) {
      showErrorSnackBar(context, result.$2 ?? t.videoControls.pipFailed);
    }
  }

  /// Handle PiP state changes to restore video scaling when exiting PiP
  void _onPipStateChanged() {
    final isInPip = _videoPIPManager?.isPipActive.value ?? PipService().isPipActive.value;
    _setAndroidAutoPipTransitionInFlight(false, reason: 'pip_state_changed');
    _recordLifecycleState('pip_state_changed', action: isInPip ? 'entered' : 'exited');

    if (_videoPIPManager == null || _videoFilterManager == null) return;

    // Only handle exit - entry is handled by onBeforeEnterPip callback
    if (!isInPip) {
      final restoreAmbient = _videoFilterManager!.hadAmbientLightingBeforePip;
      _videoFilterManager!.exitPipMode();
      // Restore ambient lighting if it was active before PiP
      if (restoreAmbient) {
        _videoFilterManager!.clearPipAmbientLightingFlag();
        _restoreAmbientLighting();
      }
    }
  }

  /// Apply the saved shader preset on playback start.
  /// Reads directly from SettingsService (synchronous SharedPreferences) to
  /// avoid a race with ShaderProvider's async initialization.
  Future<void> _applySavedShaderPreset() async {
    if (_shaderService == null || !_shaderService!.isSupported) return;

    try {
      final shaderProvider = context.read<ShaderProvider>();
      final settings = await SettingsService.getInstance();
      final presetId = settings.read(SettingsService.globalShaderPreset);
      final preset =
          (shaderProvider.initialized ? shaderProvider.findPresetById(presetId) : ShaderPreset.fromId(presetId)) ??
          ShaderPreset.none;
      await _shaderService!.applyPreset(preset);
      if (!mounted) return;
      shaderProvider.setCurrentPreset(preset);
    } catch (e) {
      appLogger.d('Could not apply shader preset', error: e);
    }
  }

  /// Restore ambient lighting from persisted setting
  Future<void> _restoreAmbientLighting() async {
    final shaderProvider = context.read<ShaderProvider>();
    final settings = await SettingsService.getInstance();
    if (!settings.read(SettingsService.ambientLighting)) return;

    final ambientLighting = _ambientLightingService;
    if (ambientLighting == null || !ambientLighting.isSupported) return;

    // Same enable logic as _toggleAmbientLighting
    final dwidth = await player?.getProperty('dwidth');
    final dheight = await player?.getProperty('dheight');
    if (dwidth == null || dheight == null) return;
    final w = double.tryParse(dwidth);
    final h = double.tryParse(dheight);
    if (w == null || h == null || h == 0) return;
    final videoAspect = w / h;

    final playerSize = _videoFilterManager?.playerSize;
    if (playerSize == null || playerSize.height == 0) return;
    final outputAspect = playerSize.width / playerSize.height;

    // Clear shaders — ambient lighting and shaders are mutually exclusive
    if (shaderProvider.isShaderEnabled) {
      await _shaderService!.applyPreset(ShaderPreset.none);
      shaderProvider.setCurrentPreset(ShaderPreset.none);
    }

    _videoFilterManager?.resetToContain();
    await ambientLighting.enable(videoAspect, outputAspect);
    if (mounted) _setPlayerState(() {});
  }

  /// Cycle through BoxFit modes: contain → cover → fill → contain (for button)
  void _cycleBoxFitMode() {
    // Disable ambient lighting when switching boxfit modes
    // (cover/fill change the video rect, making the baked-in shader incorrect)
    _ambientLightingService?.disable();
    _setPlayerState(() {
      _videoFilterManager?.cycleBoxFitMode();
    });
  }

  /// Update video-aspect-override when player size changes.
  /// The shader adapts automatically via built-in target_size uniform.
  void _updateAmbientLightingOnResize(Size newSize) {
    final ambientLighting = _ambientLightingService;
    if (ambientLighting == null || !ambientLighting.isEnabled) return;
    if (newSize.height == 0) return;

    ambientLighting.updateOutputAspect(newSize.width / newSize.height);
  }

  /// Toggle ambient lighting effect on/off
  Future<void> _toggleAmbientLighting() async {
    final ambientLighting = _ambientLightingService;
    if (ambientLighting == null || !ambientLighting.isSupported) return;
    final shaderProvider = context.read<ShaderProvider>();

    if (ambientLighting.isEnabled) {
      await ambientLighting.disable();
      _videoFilterManager?.updateVideoFilter();
    } else {
      // Get video display aspect ratio
      final dwidth = await player?.getProperty('dwidth');
      final dheight = await player?.getProperty('dheight');
      if (dwidth == null || dheight == null) return;
      final w = double.tryParse(dwidth);
      final h = double.tryParse(dheight);
      if (w == null || h == null || h == 0) return;
      final videoAspect = w / h;

      // Get player widget aspect ratio
      final playerSize = _videoFilterManager?.playerSize;
      if (playerSize == null || playerSize.height == 0) return;
      final outputAspect = playerSize.width / playerSize.height;

      // Clear shaders — ambient lighting and shaders are mutually exclusive
      if (shaderProvider.isShaderEnabled) {
        await _shaderService!.applyPreset(ShaderPreset.none);
        shaderProvider.setCurrentPreset(ShaderPreset.none);
      }

      // Force contain mode when enabling ambient lighting
      _videoFilterManager?.resetToContain();

      await ambientLighting.enable(videoAspect, outputAspect);
    }

    // Persist ambient lighting state
    final settings = await SettingsService.getInstance();
    unawaited(settings.write(SettingsService.ambientLighting, ambientLighting.isEnabled));

    if (mounted) _setPlayerState(() {});
  }

  /// Toggle between contain and cover modes only (for pinch gesture)
  void _toggleContainCover() {
    _setPlayerState(() {
      _videoFilterManager?.toggleContainCover();
    });
  }
}
