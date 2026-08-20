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

  /// Focus Play/Pause when the viewer is already driving with keyboard/D-pad
  /// and opted into player navigation.
  ///
  /// This is an *automatic* grab — no key caused it — so it additionally
  /// requires an active keyboard session; a key-driven grab only needs
  /// [eventRequestsFocusNavigation].
  ///
  /// Returns whether it actually moved focus, because the caller uses that to
  /// decide whether the player surface still needs to claim the remote. It must
  /// therefore report `false` when the chrome is not mounted — a TV route opens
  /// with the chrome down, and claiming that it focused something there would
  /// leave the remote parked on the screen node (#1765).
  bool _focusPlayPauseIfKeyboardMode() {
    if (!mounted || !_showControls) return false;
    // The raw preference, not the directional policy: a TV viewer who turned
    // player navigation off must not get Play/Pause focused on open.
    if (!videoPlayerNavigationPreference()) return false;
    final isMobile = PlatformDetector.isMobile(context) && !PlatformDetector.isTV();
    if (isMobile || !InputModeTracker.isKeyboardMode(context, listen: false)) return false;
    final controls = _desktopControlsKey.currentState;
    if (controls == null) return false;
    controls.requestPlayPauseFocus();
    return true;
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
  /// Maestro builds extend the delay because accessibility-tree queries can take
  /// longer than the production timeout on physical devices.
  Duration get _hideDelay {
    if (const bool.fromEnvironment('PLEZY_MAESTRO_E2E')) {
      return const Duration(seconds: 30);
    }
    final isMobile = (Platform.isIOS || Platform.isAndroid) && !PlatformDetector.isTV();
    if (isMobile || playerDirectionalNavigationEnabled()) {
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

  /// Restart the hide timer on user interaction for the current playback state.
  void _restartHideTimerForCurrentPlaybackState() => widget.chromeController.restartAutoHideForCurrentPlaybackState();

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (_desktopControlsKey.currentState?.handleContentStripScroll(event) ?? false) {
      _cancelAutoSkipFromUserInteraction();
      return;
    }
    _cancelAutoSkipFromUserInteraction();
    widget.volumeController.adjust(-event.scrollDelta.dy / 20);
    _showControlsFromPointerActivity();
  }

  /// Show controls in response to pointer activity (mouse/trackpad movement).
  void _showControlsFromPointerActivity() {
    widget.chromeController.recordPointerActivity();
  }

  void _toggleControls() {
    widget.chromeController.toggle();
  }

  void _toggleControlsFromSemantics() {
    if (_showControls) {
      widget.chromeController.hide();
      return;
    }
    widget.chromeController.show(restartAutoHide: false);
    widget.chromeController.cancelAutoHide();
  }

  /// Apply preferred orientations for the given lock state. Wired to
  /// [SettingsService.rotationLocked] via [bindEffect] so any change — from
  /// this toggle or from the settings screen — fires the same SystemChrome call.
  void _applyRotationLock(bool locked) {
    if (PlatformDetector.isAutomotive()) return;
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
      _cancelEdgeAdjustmentGesture();
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
    if (!PlatformDetector.supportsPictureInPicture()) {
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

  Future<void> _toggleFullscreen() async {
    if (!PlatformDetector.isDesktopOS()) return;
    await FullscreenStateManager().toggleFullscreen();
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
    final focusPlayPause = widget.chromeController.takePlayPauseFocus();
    _lastControlsVisible = controlsVisible;

    if (visibilityChanged && !controlsVisible) {
      _desktopControlsKey.currentState?.hideContentStrip();
      _cancelSkipButtonDismissTimer();
      // When the chrome never reached full opacity, hide() already retired the
      // presented flag — no fade-out will run, so AnimatedOpacity.onEnd never
      // fires. Drop the subtree here instead of waiting for it.
      final controlsDismissed = !widget.chromeController.controlsPresented;
      _setControlsState(() {
        _controlsOpaque = false;
        if (controlsDismissed) _controlsMounted = false;
        if (_currentMarker != null) _skipButtonDismissed = true;
      });
      _claimPlayerSurfaceFocus();
    } else if (visibilityChanged) {
      // The timeline is about to take over held-key seeking; commit whatever
      // the hidden-chrome burst accumulated so it can't rebase from a stale
      // position once the timeline's own accumulator starts.
      _flushHiddenDirectionalSeek();
      _setControlsState(() {
        _controlsMounted = true;
        _controlsOpaque = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only flips the render target so the freshly mounted AnimatedOpacity
        // animates up instead of inserting at full opacity. The controller's
        // opaque flag follows the real fade-in completion (AnimatedOpacity.onEnd
        // in video_controls.dart): marking it here would let a hide() landing
        // before the next build trust an opacity the renderer never realized —
        // hide() would keep controlsPresented while the fade-in target never
        // rendered, so no fade-out runs and markControlsHidden never arrives.
        if (!mounted || !_showControls || !_controlsMounted) return;
        _setControlsState(() => _controlsOpaque = true);
      });
    } else if (controlsVisible && !_controlsMounted) {
      widget.chromeController.markControlsOpaque();
      _setControlsState(() {
        _controlsMounted = true;
        _controlsOpaque = true;
      });
    }

    if (visibilityChanged && Platform.isMacOS) {
      _updateTrafficLightVisibility();
    }

    if (focusPlayPause) {
      _requestPlayPauseFocus();
    }
  }

  /// Park focus on the player surface so this widget's key layer owns the
  /// remote. Without this the screen node keeps primary focus and its
  /// self-heal raises the whole chrome on the first actionable key, which is
  /// what the transient seek and transport indicators exist to avoid.
  void _claimPlayerSurfaceFocus() {
    if (_sheetIsOpen()) return;
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Re-check: a sheet or a route can open during the frame we deferred
      // over, and the retry must not pull the remote back out of it.
      if (!mounted || _focusNode.hasPrimaryFocus || _sheetIsOpen()) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;
      _focusNode.requestFocus();
    });
  }

  bool _sheetIsOpen() => OverlaySheetController.maybeOf(context)?.isOpen ?? false;

  void _requestPlayPauseFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.chromeController.controlsVisible) return;
      // Never steal focus from an open sheet (same rule as
      // _claimPlayerSurfaceFocus).
      if (OverlaySheetController.maybeOf(context)?.isOpen ?? false) return;
      _desktopControlsKey.currentState?.requestPlayPauseFocus();
    });
  }
}
