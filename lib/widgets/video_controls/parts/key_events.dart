part of '../video_controls.dart';

extension _PlexVideoControlsKeyEventMethods on _PlexVideoControlsState {
  Future<void> _initKeyboardService() async {
    _keyboardService = await KeyboardShortcutsService.getInstance();
  }

  void _showScreenshotToast() {
    widget.toastController.show(Symbols.photo_camera_rounded, t.videoControls.screenshotSaved);
  }

  bool _isDirectionalKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight;
  }

  bool _isHorizontalKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight;
  }

  bool _isSelectKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.gameButtonA;
  }

  /// Resolve the transport intent for a key event, or null when the key is not
  /// a transport key. Hardware `mediaPlay`/`mediaPause` stay *directed*; the
  /// configured hotkey is always a toggle.
  TransportCommand? _transportCommandFor(KeyEvent event) {
    // Always accept hardware media transport keys (Android TV remotes)
    final hardware = classifyTransportKey(event.logicalKey);
    if (hardware != null) return hardware;

    final physicalKey = event.physicalKey;

    // When the shortcuts service is available, respect the configured play/pause hotkey
    if (_keyboardService != null) {
      final hotkey = _keyboardService!.hotkeys['play_pause'];
      if (hotkey == null) return null;
      return hotkey.key == physicalKey ? TransportCommand.toggle : null;
    }

    // Fallback to defaults while the service is loading
    if (physicalKey == PhysicalKeyboardKey.space || physicalKey == PhysicalKeyboardKey.mediaPlayPause) {
      return TransportCommand.toggle;
    }
    return null;
  }

  bool _isMediaSeekKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.mediaFastForward ||
        key == LogicalKeyboardKey.mediaRewind ||
        key == LogicalKeyboardKey.mediaSkipForward ||
        key == LogicalKeyboardKey.mediaSkipBackward;
  }

  bool _isMediaTrackKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.mediaTrackNext || key == LogicalKeyboardKey.mediaTrackPrevious;
  }

  TransportCommand? _playPauseActivation(KeyEvent event) {
    return event is KeyDownEvent ? _transportCommandFor(event) : null;
  }

  void _activateHiddenControlsPrimaryAction() {
    if (!widget.canControl) {
      _showControlsWithFocus();
      return;
    }
    if (_isSkipMarkerButtonVisible) {
      _activateSkipMarker();
      return;
    }
    // Raise the chrome *before* toggling: Select is the deliberate "show me the
    // controls" affordance, and the visible chrome suppresses the transient
    // transport disc that would otherwise flash underneath it.
    _showControlsWithFocus();
    unawaited(_playOrPause());
  }

  KeyEventResult _handleLocalPlayerNavigationKeyEvent(KeyEvent event, PlayerNavigationKey navigationKey) {
    if (navigationKey == PlayerNavigationKey.none || navigationKey == PlayerNavigationKey.home) {
      return KeyEventResult.ignored;
    }
    if (PlatformDetector.isTV() && event is KeyDownEvent) {
      BackKeyCoordinator.markHandled();
    }

    final sheetController = OverlaySheetController.maybeOf(context);
    if (sheetController?.isOpen ?? false) {
      return handlePlayerNavigationKeyAction(event, navigationKey, sheetController!.pop);
    }

    if (widget.chromeController.contentStripVisible) {
      return handlePlayerNavigationKeyAction(event, navigationKey, () {
        _desktopControlsKey.currentState?.dismissContentStrip();
        widget.chromeController.setContentStripVisible(false);
        _restartHideTimerForCurrentPlaybackState();
      });
    }

    // The enclosing player screen is the sole owner of fullscreen, chrome,
    // prompt, and route-exit stages.
    return KeyEventResult.ignored;
  }

  KeyEventResult _dispatchShortcut(KeyEvent event, {VoidCallback? onSkipMarker}) {
    return _keyboardService!.handleVideoPlayerKeyEvent(
      event,
      widget.player,
      _toggleFullscreen,
      _toggleSubtitles,
      _nextAudioTrack,
      _nextSubtitleTrack,
      _nextChapter,
      _previousChapter,
      canControlPlayback: widget.canControl,
      canNavigateMediaItems: widget.canNavigateMediaItems,
      onPlayPause: () => unawaited(_playOrPause()),
      onToggleShader: _toggleShader,
      onSkipMarker: onSkipMarker,
      onNextEpisode: _abandoningBurst(widget.onNext),
      onPreviousEpisode: _abandoningBurst(widget.onPrevious),
      onScreenshot: _showScreenshotToast,
      onZoomIn: widget.onZoomIn,
      onZoomOut: widget.onZoomOut,
      onZoomReset: widget.onResetVideoZoom,
      onVolumeUp: () => widget.volumeController.adjust(10),
      onVolumeDown: () => widget.volumeController.adjust(-10),
      onToggleMute: widget.volumeController.toggleMute,
      onLiveSeekBy: widget.onLiveSeekBy,
      onSeekRequested: widget.onSeekRequested,
      onSeekBy: _keyboardSeekBy,
    );
  }

  /// Global key event handler for focus-independent shortcuts (desktop only)
  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (!mounted) return false;
    if (ModalRoute.of(context)?.isCurrent != true) return false;

    // Any actionable key (keyboard / dpad / controller) cancels an in-progress
    // auto-skip countdown. Non-consuming — we fall through so the key still
    // performs its normal action. Single cancel point for keys.
    if (event.isActionable) _cancelAutoSkipFromUserInteraction();

    // When an overlay sheet is open (e.g. subtitle search with text fields),
    // don't consume key events — let text input work normally.
    if (OverlaySheetController.maybeOf(context)?.isOpen ?? false) {
      return false;
    }

    // Native key events also continue through the focus tree after global
    // handlers run. Player navigation must only mutate state there.
    if (classifyPlayerNavigationKey(event, isAppleTV: PlatformDetector.isAppleTV()) != PlayerNavigationKey.none) {
      return false;
    }

    // Only handle when video player navigation is disabled (desktop mode without D-pad nav)
    if (_videoPlayerNavigationEnabled) return false;

    // Skip on mobile (unless TV)
    final isMobile = PlatformDetector.isMobile(context) && !PlatformDetector.isTV();
    if (isMobile) return false;

    // Handle play/pause globally - works regardless of focus. The screen
    // announces the accepted command with a transient disc, so the chrome
    // stays down and subtitles stay readable (#1676).
    final globalCommand = _playPauseActivation(event);
    if (globalCommand != null) {
      unawaited(_playOrPause(command: globalCommand));
      return true; // Event handled, stop propagation
    }

    // Fallback: handle all other shortcuts when focus has drifted away
    // (e.g. after controls auto-hide). The !hasFocus guard prevents
    // double-handling when the Focus onKeyEvent already processes the event.
    if (!_focusNode.hasFocus && _keyboardService != null) {
      final result = _dispatchShortcut(event);
      if (result == KeyEventResult.handled) {
        _focusNode.requestFocus(); // self-heal focus
        return true;
      }
    }

    return false;
  }

  KeyEventResult _handleControlsKeyEvent(KeyEvent event, bool isMobile) {
    final navigationKey = classifyPlayerNavigationKey(event, isAppleTV: PlatformDetector.isAppleTV());
    final navigationResult = _handleLocalPlayerNavigationKeyEvent(event, navigationKey);
    if (navigationResult != KeyEventResult.ignored) {
      return navigationResult;
    }
    if (navigationKey != PlayerNavigationKey.none) return KeyEventResult.ignored;

    // Releasing a key ends its seek burst, before the KeyUp is consumed below.
    // Two independent reasons to fire:
    //  - a released hidden-chrome arrow must reset the acceleration tier even
    //    when nothing is pending, because live TV (and a zero-duration item)
    //    seeks straight through onLiveSeekBy without touching the accumulator;
    //  - any key holding a pending target commits it now, so rebound shortcuts
    //    and Shift+arrow large seeks land promptly rather than on the debounce.
    if (event is KeyUpEvent &&
        ((!_showControls && _isHorizontalKey(event.logicalKey)) || _hiddenSeek.pendingPosition != null)) {
      _flushHiddenDirectionalSeek();
    }

    // Only handle KeyDown and KeyRepeat events.
    // Consume KeyUp events for navigation keys to prevent leaking to previous routes.
    // Let non-navigation keys (volume, etc.) pass through to the OS.
    if (!event.isActionable) {
      if (!event.logicalKey.isNavigationKey) return KeyEventResult.ignored;
      return KeyEventResult.handled;
    }

    // Reset hide timer on any keyboard/controller input when controls are visible.
    if (_showControls) {
      _restartHideTimerForCurrentPlaybackState();
    }

    final key = event.logicalKey;
    final transportCommand = _transportCommandFor(event);

    // Always consume transport keys to prevent propagation to background routes.
    // On TV/mobile, handle them here; on desktop, the global handler does it.
    // The chrome deliberately stays down — the screen announces the accepted
    // command with a centred transient disc instead (#1676).
    if (transportCommand != null) {
      if ((_videoPlayerNavigationEnabled || isMobile) && event is KeyDownEvent) {
        unawaited(_playOrPause(command: transportCommand));
      }
      return KeyEventResult.handled;
    }

    // Handle media seek keys (Android TV remotes).
    // Uses chapter navigation if chapters are available, otherwise seeks by configured time.
    if (event is KeyDownEvent && _isMediaSeekKey(key)) {
      if (widget.canControl) {
        final isForward = key == LogicalKeyboardKey.mediaFastForward || key == LogicalKeyboardKey.mediaSkipForward;
        _seekToChapterWithFeedback(forward: isForward);
      }
      return KeyEventResult.handled;
    }

    // Handle next/previous track keys (Android TV remotes).
    // Uses same behavior as seek keys: chapter navigation or time-based seek.
    if (event is KeyDownEvent && _isMediaTrackKey(key)) {
      if (widget.canControl) {
        _seekToChapterWithFeedback(forward: key == LogicalKeyboardKey.mediaTrackNext);
      }
      return KeyEventResult.handled;
    }

    // Handle Select/Enter when controls are hidden.
    // Only intercept if this Focus node itself has primary focus (not a descendant).
    // When the skip marker button is the only visible affordance, Select activates
    // it; otherwise it falls back to play/pause + show controls.
    if (_isSelectKey(key) && !_showControls && _focusNode.hasPrimaryFocus) {
      return handleOneShotSelect(event, _activateHiddenControlsPrimaryAction);
    }

    // On desktop/TV, directional input drives the player without the chrome.
    // LEFT/RIGHT seeks in place with a transient badge; UP/DOWN is the
    // deliberate "show me the controls" gesture.
    if (!isMobile && _isDirectionalKey(key) && (_videoPlayerNavigationEnabled || PlatformDetector.isTV())) {
      if (!_showControls) {
        if (_isHorizontalKey(key)) {
          if (shouldStartHiddenDirectionalSeek(event)) {
            _hiddenDirectionalSeek(forward: key == LogicalKeyboardKey.arrowRight, isRepeat: event is KeyRepeatEvent);
          }
        } else {
          _flushHiddenDirectionalSeek();
          _showControlsWithFocus();
        }
        return KeyEventResult.handled;
      }
      // Children (DesktopVideoControls) handle navigation first via their own onKeyEvent.
      // If we reach here, children already declined the event — consume it to prevent leaking.
      return KeyEventResult.handled;
    }

    // Pass other events to the keyboard shortcuts service.
    if (_keyboardService == null) {
      return event.logicalKey.isNavigationKey ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    final result = _dispatchShortcut(event, onSkipMarker: _performAutoSkip);
    if (!event.logicalKey.isNavigationKey) return result;
    // Never return .ignored for navigation keys — prevent leaking to previous routes.
    return result == KeyEventResult.ignored ? KeyEventResult.handled : result;
  }
}
