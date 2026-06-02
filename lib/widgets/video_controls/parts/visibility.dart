part of '../video_controls.dart';

extension _PlexVideoControlsVisibilityMethods on _PlexVideoControlsState {
  /// Called when hasFirstFrame changes - start auto-hide timer when first frame is ready
  void _onFirstFrameReady() {
    final hasFrame = widget.hasFirstFrame?.value ?? true;
    widget.chromeController.setHasFirstFrame(hasFrame);
    if (hasFrame) {
      // Retry with network-first if initial cache-first returned empty
      if (_chapters.isEmpty && _markers.isEmpty) {
        _loadPlaybackExtras(forceRefresh: true);
      }
      _syncCurrentMarkerForCurrentPosition();
    } else {
      _clearCurrentMarker();
    }
  }

  /// Focus play/pause button if we're in keyboard navigation mode (desktop/TV only)
  void _focusPlayPauseIfKeyboardMode() {
    if (!mounted) return;
    if (!_videoPlayerNavigationEnabled) return;
    final isMobile = PlatformDetector.isMobile(context) && !PlatformDetector.isTV();
    if (!isMobile && InputModeTracker.isKeyboardMode(context)) {
      _desktopControlsKey.currentState?.requestPlayPauseFocus();
    }
  }

  /// Listen to playback state changes to manage auto-hide timer
  void _listenToPlayingState() {
    _playingSubscription = widget.player.streams.playing.listen((isPlaying) {
      widget.chromeController.setPlaying(isPlaying);
    });
  }

  /// Listen to completed stream to show controls when video ends
  void _listenToCompleted() {
    _completedSubscription = widget.player.streams.completed.listen((completed) {
      if (completed && mounted) {
        if (_isLongPressing) {
          _handleLongPressCancel();
        }
        widget.chromeController.show(restartAutoHide: false);
        widget.chromeController.cancelAutoHide();
      }
    });
  }

  /// Controls hide delay: 5s on mobile/TV/keyboard-nav, 3s on desktop with mouse.
  Duration get _hideDelay {
    final isMobile = (Platform.isIOS || Platform.isAndroid) && !PlatformDetector.isTV();
    if (isMobile || PlatformDetector.isTV() || _videoPlayerNavigationEnabled) {
      return const Duration(seconds: 5);
    }
    return const Duration(seconds: 3);
  }

  /// Shared hide logic: hides controls, notifies parent, updates traffic lights, restores focus.
  void _hideControls() {
    if (!mounted) return;
    widget.chromeController.hide();
  }

  void _startHideTimer() => widget.chromeController.startAutoHide();

  /// Restart the hide timer on user interaction (if video is playing)
  void _restartHideTimerIfPlaying() => widget.chromeController.restartAutoHideIfPlaying();

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _keyboardService != null) {
      final delta = event.scrollDelta.dy;
      final volume = widget.player.state.volume;
      final maxVol = _keyboardService!.maxVolume.toDouble();
      final newVolume = (volume - delta / 20).clamp(0.0, maxVol);
      widget.player.setVolume(newVolume);
      unawaited(SettingsService.getInstance().then((s) => s.write(SettingsService.volume, newVolume)));
      _showControlsFromPointerActivity();
    }
  }

  /// Show controls in response to pointer activity (mouse/trackpad movement).
  void _showControlsFromPointerActivity() {
    final handled = widget.chromeController.recordPointerActivity();
    if (!handled) return;

    // Cancel auto-skip when user moves pointer over the player
    _cancelAutoSkipTimer();
  }

  void _toggleControls() {
    widget.chromeController.toggle();
    // Cancel auto-skip on any tap
    _cancelAutoSkipTimer();
  }

  /// Apply preferred orientations for the given lock state. Wired to
  /// [SettingsService.rotationLocked] via [bindEffect] so any change — from
  /// this toggle or from the settings screen — fires the same SystemChrome call.
  void _applyRotationLock(bool locked) {
    unawaited(
      SystemChrome.setPreferredOrientations(
        locked ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight] : DeviceOrientation.values,
      ),
    );
  }

  void _toggleRotationLock() {
    unawaited(_settings.write(SettingsService.rotationLocked, !_isRotationLocked));
  }

  void _toggleScreenLock() {
    final locking = !_isScreenLocked;
    _setControlsState(() {
      _isScreenLocked = locking;
      if (locking) {
        _showLockIcon = true;
      }
    });
    if (locking) {
      widget.chromeController.hide(ignoreHolds: true);
      _startLockIconHideTimer();
    }
  }

  void _startLockIconHideTimer() {
    _lockIconTimer?.cancel();
    _lockIconTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _setControlsState(() => _showLockIcon = false);
    });
  }

  void _unlockScreen() {
    _setControlsState(() {
      _isScreenLocked = false;
      _showLockIcon = false;
    });
    _lockIconTimer?.cancel();
    widget.chromeController.show();
  }

  void _updateTrafficLightVisibility() async {
    final generation = ++_trafficLightVisibilityGeneration;
    // When maximized or fullscreen, always keep traffic lights visible so the
    // user can reach them without the controls-hide-on-mouse-leave race.
    // In normal windowed mode, toggle with controls as before.
    final isMaximizedOrFullscreen = await windowManager.isMaximized() || await MacOSWindowService.isFullscreen();
    if (!mounted || generation != _trafficLightVisibilityGeneration) return;
    final visible = isMaximizedOrFullscreen || _showControls;
    await MacOSWindowService.setTrafficLightsVisible(visible);
  }

  Future<void> _checkPipSupport() async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      return;
    }

    try {
      final supported = await PipService.isSupported();
      if (mounted) {
        _setControlsState(() {
          _isPipSupported = supported;
        });
      }
    } catch (e) {
      return;
    }
  }

  /// macOS PiP changed — force controls visible while PiP is active
  void _onMacPipChanged() {
    if (!mounted) return;
    final inPip = _pipService.isPipActive.value;
    if (inPip) {
      widget.chromeController.hold(PlayerChromeHold.pip);
    } else {
      widget.chromeController.release(PlayerChromeHold.pip);
    }
  }

  Future<void> _toggleFullscreen() async {
    if (!PlatformDetector.isDesktopOS()) return;
    await FullscreenStateManager().toggleFullscreen();
  }

  /// Exit fullscreen if the window is actually fullscreen (async check).
  /// Used by ESC handler on Windows/Linux to avoid relying on _isFullscreen flag.
  Future<void> _exitFullscreenIfNeeded() async {
    if (!Platform.isWindows && !Platform.isLinux) return;
    if (await windowManager.isFullScreen()) {
      await FullscreenStateManager().exitFullscreen();
    }
  }

  /// Initialize always-on-top state from window manager (desktop only)
  Future<void> _initAlwaysOnTopState() async {
    final isOnTop = await windowManager.isAlwaysOnTop();
    if (mounted && isOnTop != _isAlwaysOnTop) {
      _setControlsState(() {
        _isAlwaysOnTop = isOnTop;
      });
    }
  }

  /// Toggle always-on-top window mode (desktop only)
  Future<void> _toggleAlwaysOnTop() async {
    if (!PlatformDetector.isDesktopOS()) return;

    final newValue = !_isAlwaysOnTop;
    await windowManager.setAlwaysOnTop(newValue);
    if (!mounted) return;
    _setControlsState(() {
      _isAlwaysOnTop = newValue;
    });
  }

  /// Show controls and optionally focus play/pause on keyboard input (desktop only)
  void _showControlsWithFocus({bool requestFocus = true}) {
    widget.chromeController.show();

    if (requestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _desktopControlsKey.currentState?.requestPlayPauseFocus();
      });
    } else {
      // When not requesting focus on play/pause, ensure main focus node keeps focus
      // This prevents focus from being lost when controls become visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  /// Show controls and focus timeline on LEFT/RIGHT input (TV/desktop)
  void _showControlsWithTimelineFocus() {
    widget.chromeController.show();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _desktopControlsKey.currentState?.requestTimelineFocus();
    });
  }

  /// Hide controls when navigating up from timeline (keyboard mode)
  /// If skip marker button or Play Next dialog is visible, focus it instead of hiding controls
  void _hideControlsFromKeyboard() {
    if (widget.playNextFocusNode != null) {
      widget.playNextFocusNode!.requestFocus();
      return;
    }

    if (_currentMarker != null) {
      _skipMarkerFocusNode.requestFocus();
      return;
    }

    if (_showControls) {
      _hideControls();
    }
  }

  void _onChromeChanged() {
    if (!mounted) return;
    final controlsVisible = widget.chromeController.controlsVisible;
    final visibilityChanged = controlsVisible != _lastControlsVisible;
    final focusTarget = widget.chromeController.takeFocusTarget();
    _lastControlsVisible = controlsVisible;

    if (visibilityChanged && !controlsVisible) {
      _desktopControlsKey.currentState?.hideContentStrip();
      _cancelSkipButtonDismissTimer();
      _setControlsState(() {
        if (_currentMarker != null) _skipButtonDismissed = true;
      });
      _reclaimFocusAfterControlsHide();
    } else {
      _setControlsState(() {});
    }

    if (visibilityChanged && Platform.isMacOS) {
      _updateTrafficLightVisibility();
    }

    if (focusTarget != null) {
      _requestFocusTarget(focusTarget);
    }
  }

  void _reclaimFocusAfterControlsHide() {
    final sheetOpen = OverlaySheetController.maybeOf(context)?.isOpen ?? false;
    if (sheetOpen) return;
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasPrimaryFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  void _requestFocusTarget(PlayerChromeFocusTarget target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.chromeController.controlsVisible) return;
      switch (target) {
        case PlayerChromeFocusTarget.playPause:
          _desktopControlsKey.currentState?.requestPlayPauseFocus();
        case PlayerChromeFocusTarget.timeline:
          _desktopControlsKey.currentState?.requestTimelineFocus();
      }
    });
  }
}
