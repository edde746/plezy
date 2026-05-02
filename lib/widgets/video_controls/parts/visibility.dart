part of '../video_controls.dart';

extension _PlexVideoControlsVisibilityMethods on _PlexVideoControlsState {
  /// Called when hasFirstFrame changes - start auto-hide timer when first frame is ready
  void _onFirstFrameReady() {
    if (widget.hasFirstFrame?.value == true) {
      _startHideTimer();
      // Retry with network-first if initial cache-first returned empty
      if (_chapters.isEmpty && _markers.isEmpty) {
        _loadPlaybackExtras(forceRefresh: true);
      }
    }
  }

  /// Called when controlsVisible is set externally (e.g. screen-level focus recovery
  /// after controls auto-hide ejects focus on Android TV).
  void _onControlsVisibleExternal() {
    if (widget.controlsVisible?.value == true && !_showControls && mounted) {
      _showControlsWithFocus();
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
      if (isPlaying && _showControls) {
        _startHideTimer();
      } else if (!isPlaying && _showControls) {
        _startPausedHideTimer();
      }
    });
  }

  /// Listen to completed stream to show controls when video ends
  void _listenToCompleted() {
    _completedSubscription = widget.player.streams.completed.listen((completed) {
      if (completed && mounted) {
        // Cancel long-press 2x speed if active
        if (_isLongPressing) {
          _handleLongPressCancel();
        }
        // Show controls when video completes (for play next dialog etc.)
        _setControlsState(() {
          _showControls = true;
        });
        // Notify parent of visibility change (for popup positioning)
        widget.controlsVisible?.value = true;
        _hideTimer?.cancel();
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
    if (!mounted || !_showControls || _forceShowControls) return;
    _setControlsState(() {
      _showControls = false;
      _isContentStripVisible = false;
      // Dismiss skip button with controls — after this it only re-appears with controls
      if (_currentMarker != null) {
        _skipButtonDismissed = true;
      }
    });
    _desktopControlsKey.currentState?.hideContentStrip();
    _cancelSkipButtonDismissTimer();
    widget.controlsVisible?.value = false;
    if (Platform.isMacOS) {
      _updateTrafficLightVisibility();
    }
    // Reclaim focus so the global key handler stays active for TV dpad,
    // but skip if an overlay sheet owns focus — stealing it would break
    // sheet navigation (e.g. the compact sync bar).
    final sheetOpen = OverlaySheetController.maybeOf(context)?.isOpen ?? false;
    if (!sheetOpen) {
      // Always request primary focus on _focusNode — not just when hasFocus is
      // false. hasFocus is true when a descendant (e.g. play/pause) has focus,
      // but we need _focusNode itself to hold primary focus so its onKeyEvent
      // fires for the next d-pad press (otherwise focus escapes to the screen-
      // level self-heal handler which shows controls with play/pause focus).
      _focusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasPrimaryFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();

    // Don't auto-hide while loading first frame (user needs to see spinner and back button)
    final hasFrame = widget.hasFirstFrame?.value ?? true;
    if (!hasFrame) return;

    if (_forceShowControls) return;

    // Only auto-hide if playing
    if (widget.player.state.playing) {
      _hideTimer = Timer(_hideDelay, () {
        // Also check hasFirstFrame in callback (in case it changed)
        final stillLoading = !(widget.hasFirstFrame?.value ?? true);
        if (mounted && widget.player.state.playing && !stillLoading) {
          _hideControls();
        }
      });
    }
  }

  /// Auto-hide controls after pause (does not check playing state in callback).
  void _startPausedHideTimer() {
    _hideTimer?.cancel();
    if (_forceShowControls) return;
    _hideTimer = Timer(_hideDelay, () {
      _hideControls();
    });
  }

  /// Restart the hide timer on user interaction (if video is playing)
  void _restartHideTimerIfPlaying() {
    if (widget.player.state.playing) {
      _startHideTimer();
    }
  }

  /// Hide controls immediately when the mouse leaves the player area (desktop only).
  void _hideControlsFromPointerExit() {
    final isMobile = PlatformDetector.isMobile(context) && !PlatformDetector.isTV();
    if (isMobile) return;

    _hideTimer?.cancel();
    _hideControls();
  }

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
    if (!_showControls) {
      _setControlsState(() {
        _showControls = true;
      });
      // Notify parent of visibility change (for popup positioning)
      widget.controlsVisible?.value = true;
      // On macOS, keep window controls in sync with the overlay
      if (Platform.isMacOS) {
        _updateTrafficLightVisibility();
      }
    }

    // Keep the overlay visible while the user is moving the pointer
    _restartHideTimerIfPlaying();

    // Cancel auto-skip when user moves pointer over the player
    _cancelAutoSkipTimer();
  }

  void _toggleControls() {
    if (_showControls) {
      _hideControls();
    } else {
      _setControlsState(() {
        _showControls = true;
      });
      widget.controlsVisible?.value = true;
      _startHideTimer();
      if (Platform.isMacOS) {
        _updateTrafficLightVisibility();
      }
    }
    // Cancel auto-skip on any tap
    _cancelAutoSkipTimer();
  }

  void _toggleRotationLock() async {
    _setControlsState(() {
      _isRotationLocked = !_isRotationLocked;
    });

    // Save to settings
    final settingsService = await SettingsService.getInstance();
    await settingsService.write(SettingsService.rotationLocked, _isRotationLocked);

    if (_isRotationLocked) {
      // Locked: Allow landscape orientations only
      await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      // Unlocked: Allow all orientations including portrait
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
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
      _hideControls();
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
      _showControls = true;
    });
    _lockIconTimer?.cancel();
    widget.controlsVisible?.value = true;
    _startHideTimer();
  }

  void _updateTrafficLightVisibility() async {
    // When maximized or fullscreen, always keep traffic lights visible so the
    // user can reach them without the controls-hide-on-mouse-leave race.
    // In normal windowed mode, toggle with controls as before.
    final isMaximizedOrFullscreen = await windowManager.isMaximized() || await windowManager.isFullScreen();
    final visible = isMaximizedOrFullscreen || _forceShowControls ? true : _showControls;
    await MacOSWindowService.setTrafficLightsVisible(visible);
  }

  /// Check whether PiP is supported on this device
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
    _setControlsState(() => _forceShowControls = inPip);
    if (inPip) {
      _hideTimer?.cancel();
      widget.controlsVisible?.value = true;
    } else {
      _startHideTimer();
    }
  }

  Future<void> _toggleFullscreen() async {
    if (!PlatformDetector.isMobile(context)) {
      await FullscreenStateManager().toggleFullscreen();
    }
  }

  /// Exit fullscreen if the window is actually fullscreen (async check).
  /// Used by ESC handler on Windows/Linux to avoid relying on _isFullscreen flag.
  Future<void> _exitFullscreenIfNeeded() async {
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
    if (!PlatformDetector.isMobile(context)) {
      final newValue = !_isAlwaysOnTop;
      await windowManager.setAlwaysOnTop(newValue);
      if (!mounted) return;
      _setControlsState(() {
        _isAlwaysOnTop = newValue;
      });
    }
  }

  /// Show controls and optionally focus play/pause on keyboard input (desktop only)
  void _showControlsWithFocus({bool requestFocus = true}) {
    if (!_showControls) {
      _setControlsState(() {
        _showControls = true;
      });
      // Notify parent of visibility change (for popup positioning)
      widget.controlsVisible?.value = true;
      if (Platform.isMacOS) {
        _updateTrafficLightVisibility();
      }
    }
    _startHideTimer();

    // Request focus on play/pause button after controls are shown
    if (requestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
    if (!_showControls) {
      _setControlsState(() {
        _showControls = true;
      });
      // Notify parent of visibility change (for popup positioning)
      widget.controlsVisible?.value = true;
      if (Platform.isMacOS) {
        _updateTrafficLightVisibility();
      }
    }
    _startHideTimer();

    // Request focus on timeline after controls are shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _desktopControlsKey.currentState?.requestTimelineFocus();
    });
  }

  /// Hide controls when navigating up from timeline (keyboard mode)
  /// If skip marker button or Play Next dialog is visible, focus it instead of hiding controls
  void _hideControlsFromKeyboard() {
    // If skip marker button is visible, focus it instead of hiding controls
    if (_currentMarker != null) {
      _skipMarkerFocusNode.requestFocus();
      return;
    }

    // If Play Next dialog is visible (focus node provided), focus it instead of hiding controls
    if (widget.playNextFocusNode != null) {
      widget.playNextFocusNode!.requestFocus();
      return;
    }

    if (_showControls) {
      _hideControls();
    }
  }
}
