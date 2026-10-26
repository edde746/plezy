part of '../../video_player_screen.dart';

extension _VideoPlayerPipMethods on VideoPlayerScreenState {
  void _attachPipStateListener() {
    _releasePipStateListener ??= bindListenable(PipService().isPipActive, _onPipStateChanged);
  }

  void _detachPipStateListener() {
    _releasePipStateListener?.call();
    _releasePipStateListener = null;
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
        // iOS/tvOS and macOS zoom the native video layer; mpv's video-zoom
        // would force vo_avfoundation's Core Image path and kill HDR/DV
        // passthrough.
        nativeVideoZoom: Platform.isIOS || Platform.isMacOS,
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

    // Native PiP remains available as the operating-system background path.
    // The in-app action below is app-owned and uses the shared workspace on
    // every Flutter target.
    if (PipService().isPipActive.value) {
      await PipService.exit();
      return;
    }

    final existingId = _workspaceSessionId;
    final existingController = _workspaceController;
    if (existingId != null && existingController != null) {
      if (_workspaceSurfaceDetached) {
        if (existingController.isRestored(existingId)) {
          existingController.showSessionInWorkspace(existingId);
          _setPlayerState(() => _workspaceSurfaceDetached = true);
        } else {
          // The PiP control is an on/off toggle: restore this player to its
          // original route while keeping playback alive. The workspace title
          // bar owns the separate fullscreen action.
          existingController.restore(existingId);
        }
      } else if (existingController.showSessionInWorkspace(existingId)) {
        _setPlayerState(() => _workspaceSurfaceDetached = true);
      }
      return;
    }

    if (!mounted || player == null) return;
    _registerVideoWorkspaceSession();
  }

  /// Retain this route's one real native player and move its widget into the
  /// shared workspace. Opening another media route while a workspace is active
  /// calls this before playback starts, so sessions can be composed without a
  /// second Player owner or a route restart.
  bool _registerVideoWorkspaceSession([MultiviewWorkspaceController? workspaceOverride]) {
    if (!mounted || player == null || _workspaceSessionId != null) return false;
    final workspace = workspaceOverride ?? context.read<MultiviewWorkspaceController>();
    final mediaNavigator = Navigator.of(context);
    final mediaRoute = ModalRoute.of(context);
    final stableMediaId = _currentMetadata?.globalKey;
    final sessionId = 'video:${stableMediaId ?? _playbackSessionIdentifier}';
    final title = _currentMetadata?.title;

    _workspaceSessionId = sessionId;
    _workspaceController = workspace;
    _workspaceSurfaceDetached = true;
    _setPlayerState(() {});

    final registration = WorkspaceSurfaceRegistration(
      descriptor: WorkspaceSessionDescriptor(
        id: sessionId,
        kind: widget.isLive ? MultiviewMediaKind.liveTv : MultiviewMediaKind.video,
        title: title == null || title.isEmpty ? t.videoControls.pipButton : title,
        mediaKey: _currentMetadata?.globalKey,
        progressOwner: _currentMetadata?.globalKey,
        hasAudio: true,
        hasVideo: true,
        openedAt: DateTime.now(),
      ),
      videoPlayerSlot: _videoPlayerSlot,
      buildSurface: (workspaceContext) => OverlaySheetHost(
        canPop: false,
        onBack: () => _handleScreenPlayerNavigation(PlayerNavigationKey.back),
        child: _buildVideoPlayer(workspaceContext, forWorkspace: true),
      ),
      onRestore: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _workspaceSessionId != sessionId) return;
          _workspaceSurfaceDetached = false;
          _setPlayerState(() {});
          final route = mediaRoute;
          if (mediaNavigator.mounted && route?.isActive == true) {
            mediaNavigator.popUntil((candidate) => identical(candidate, route));
          }
        });
      },
      onClose: () => unawaited(_handleBackButton()),
      onAudioOwnershipChanged: (enabled) async {
        final volumeController = _volumeController;
        if (volumeController != null) await volumeController.setWorkspaceAudioEnabled(enabled);
      },
    );

    if (!workspace.register(registration)) {
      _workspaceSessionId = null;
      _workspaceController = null;
      _workspaceSurfaceDetached = false;
      _setPlayerState(() {});
      _onPipRequestFailed(t.videoControls.pipFailed);
      return false;
    }
    return true;
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
      unawaited(_visualEffects.restoreAmbientLighting());
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

    if (!_pipInitialized || _videoFilterManager == null) {
      _setPlayerState(() {});
      return;
    }

    if (isInPip) {
      _preparePipFiltersForEntry();
    } else {
      _restorePipFiltersAfterExit();
    }
    _setPlayerState(() {});
  }
}
