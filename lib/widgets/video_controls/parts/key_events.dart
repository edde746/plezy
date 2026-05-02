part of '../video_controls.dart';

extension _PlexVideoControlsKeyEventMethods on _PlexVideoControlsState {
  Future<void> _initKeyboardService() async {
    _keyboardService = await KeyboardShortcutsService.getInstance();
  }

  /// Check if a key is a directional key (arrow keys)
  bool _isDirectionalKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight;
  }

  /// Check if a key is a select/enter key
  bool _isSelectKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.gameButtonA;
  }

  /// Determine if the key event should toggle play/pause based on configured hotkeys.
  bool _isPlayPauseKey(KeyEvent event) {
    final logicalKey = event.logicalKey;
    final physicalKey = event.physicalKey;

    // Always accept hardware media play/pause keys (Android TV remotes)
    if (logicalKey == LogicalKeyboardKey.mediaPlayPause ||
        logicalKey == LogicalKeyboardKey.mediaPlay ||
        logicalKey == LogicalKeyboardKey.mediaPause) {
      return true;
    }

    // When the shortcuts service is available, respect the configured play/pause hotkey
    if (_keyboardService != null) {
      final hotkey = _keyboardService!.hotkeys['play_pause'];
      if (hotkey == null) return false;
      return hotkey.key == physicalKey;
    }

    // Fallback to defaults while the service is loading
    return physicalKey == PhysicalKeyboardKey.space || physicalKey == PhysicalKeyboardKey.mediaPlayPause;
  }

  /// Check if a key is a media seek key (Android TV remotes)
  bool _isMediaSeekKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.mediaFastForward ||
        key == LogicalKeyboardKey.mediaRewind ||
        key == LogicalKeyboardKey.mediaSkipForward ||
        key == LogicalKeyboardKey.mediaSkipBackward;
  }

  /// Check if a key is a media track key (Android TV remotes)
  bool _isMediaTrackKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.mediaTrackNext || key == LogicalKeyboardKey.mediaTrackPrevious;
  }

  bool _isPlayPauseActivation(KeyEvent event) {
    return event is KeyDownEvent && _isPlayPauseKey(event);
  }

  /// Global key event handler for focus-independent shortcuts (desktop only)
  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (!mounted) return false;

    // When an overlay sheet is open (e.g. subtitle search with text fields),
    // don't consume key events — let text input work normally.
    if (OverlaySheetController.maybeOf(context)?.isOpen ?? false) {
      return false;
    }

    // Back key fallback when _focusNode lost focus (TV, or desktop with nav on).
    // Focus.onKeyEvent won't fire if _focusNode lost focus, so handle ESC here.
    if ((_videoPlayerNavigationEnabled || PlatformDetector.isTV()) && event.logicalKey.isBackKey) {
      if (!_focusNode.hasFocus) {
        // Skip if an overlay sheet is open — the sheet's FocusScope handles
        // back keys via its own onKeyEvent. Without this check, this global
        // handler would call Navigator.pop() alongside the sheet's handler.
        final sheetOpen = OverlaySheetController.maybeOf(context)?.isOpen ?? false;
        if (sheetOpen) return false;
        // On TV, mark coordinator early (KeyDown) so PopScope.onPopInvokedWithResult
        // sees it before KeyUp — prevents the system back from racing ahead.
        if (PlatformDetector.isTV() && event is KeyDownEvent) {
          BackKeyCoordinator.markHandled();
        }
        final backResult = handleBackKeyAction(event, () {
          if (PlatformDetector.isTV()) {
            if (_showControls) {
              if (_isContentStripVisible) {
                _desktopControlsKey.currentState?.dismissContentStrip();
                _setControlsState(() => _isContentStripVisible = false);
                _restartHideTimerIfPlaying();
                return;
              }
              _hideControls();
              return;
            }
            (widget.onBack ?? () => Navigator.of(context).pop(true))();
            return;
          }
          if (!_showControls) {
            _showControlsWithFocus();
          } else {
            (widget.onBack ?? () => Navigator.of(context).pop(true))();
          }
        });
        if (backResult != KeyEventResult.ignored) return true;
      }
    }

    // Only handle when video player navigation is disabled (desktop mode without D-pad nav)
    if (_videoPlayerNavigationEnabled) return false;

    // Skip on mobile (unless TV)
    final isMobile = PlatformDetector.isMobile(context) && !PlatformDetector.isTV();
    if (isMobile) return false;

    // Handle play/pause globally - works regardless of focus
    if (_isPlayPauseActivation(event)) {
      _playOrPause();
      _showControlsWithFocus(requestFocus: false);
      return true; // Event handled, stop propagation
    }

    // Fallback: handle all other shortcuts when focus has drifted away
    // (e.g. after controls auto-hide). The !hasFocus guard prevents
    // double-handling when the Focus onKeyEvent already processes the event.
    if (!_focusNode.hasFocus && _keyboardService != null) {
      // On Windows/Linux with navigation off, ESC only exits fullscreen —
      // never exits the player. Intercept before the keyboard shortcuts
      // service which would call onBack and pop the route.
      // Skip if an overlay sheet is open — let the sheet handle ESC.
      if (!_videoPlayerNavigationEnabled && (Platform.isWindows || Platform.isLinux) && event.logicalKey.isBackKey) {
        final sheetOpen = OverlaySheetController.maybeOf(context)?.isOpen ?? false;
        if (!sheetOpen) {
          if (event is KeyUpEvent) {
            _exitFullscreenIfNeeded();
          }
          _focusNode.requestFocus();
          return true;
        }
      }
      final result = _keyboardService!.handleVideoPlayerKeyEvent(
        event,
        widget.player,
        _toggleFullscreen,
        _toggleSubtitles,
        _nextAudioTrack,
        _nextSubtitleTrack,
        _nextChapter,
        _previousChapter,
        onBack: widget.onBack ?? () => Navigator.of(context).pop(true),
        onToggleShader: _toggleShader,
        onNextEpisode: widget.onNext,
        onPreviousEpisode: widget.onPrevious,
        currentPositionEpoch: widget.currentPositionEpoch,
        onLiveSeek: widget.onLiveSeek,
      );
      if (result == KeyEventResult.handled) {
        _focusNode.requestFocus(); // self-heal focus
        return true;
      }
    }

    return true; // Consume all events while video player is active
  }

  KeyEventResult _handleControlsKeyEvent(KeyEvent event, bool isMobile) {
    // On Windows/Linux with navigation off, ESC only exits fullscreen —
    // never exits the player. Consume all back key events and check
    // actual window state asynchronously.
    if (!_videoPlayerNavigationEnabled && (Platform.isWindows || Platform.isLinux) && event.logicalKey.isBackKey) {
      if (event is KeyUpEvent) {
        _exitFullscreenIfNeeded();
      }
      return KeyEventResult.handled;
    }
    // On TV, mark coordinator early (KeyDown) so PopScope.onPopInvokedWithResult
    // sees it before KeyUp — prevents the system back from racing ahead.
    if (PlatformDetector.isTV() && event.logicalKey.isBackKey && event is KeyDownEvent) {
      BackKeyCoordinator.markHandled();
    }
    final backResult = handleBackKeyAction(event, () {
      if (PlatformDetector.isTV()) {
        if (_showControls) {
          if (_isContentStripVisible) {
            _desktopControlsKey.currentState?.dismissContentStrip();
            _setControlsState(() => _isContentStripVisible = false);
            _restartHideTimerIfPlaying();
            return;
          }
          _hideControls();
          return;
        }
        (widget.onBack ?? () => Navigator.of(context).pop(true))();
        return;
      }
      if (!_showControls) {
        _showControlsWithFocus();
        return;
      }
      // Controls visible - navigate back
      (widget.onBack ?? () => Navigator.of(context).pop(true))();
    });
    if (backResult != KeyEventResult.ignored) {
      return backResult;
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
      _restartHideTimerIfPlaying();
    }

    final key = event.logicalKey;
    final isPlayPauseKey = _isPlayPauseKey(event);

    // Always consume play/pause keys to prevent propagation to background routes.
    // On TV/mobile, handle play/pause here; on desktop, the global handler does it.
    if (isPlayPauseKey) {
      if (_videoPlayerNavigationEnabled || isMobile) {
        if (_isPlayPauseActivation(event)) {
          _playOrPause();
          _showControlsWithFocus(requestFocus: _videoPlayerNavigationEnabled);
        }
      }
      return KeyEventResult.handled;
    }

    // Handle media seek keys (Android TV remotes).
    // Uses chapter navigation if chapters are available, otherwise seeks by configured time.
    if (event is KeyDownEvent && _isMediaSeekKey(key)) {
      if (widget.canControl) {
        final isForward = key == LogicalKeyboardKey.mediaFastForward || key == LogicalKeyboardKey.mediaSkipForward;
        unawaited(_seekToChapter(forward: isForward));
      }
      _showControlsWithFocus(requestFocus: _videoPlayerNavigationEnabled);
      return KeyEventResult.handled;
    }

    // Handle next/previous track keys (Android TV remotes).
    // Uses same behavior as seek keys: chapter navigation or time-based seek.
    if (event is KeyDownEvent && _isMediaTrackKey(key)) {
      if (widget.canControl) {
        unawaited(_seekToChapter(forward: key == LogicalKeyboardKey.mediaTrackNext));
      }
      _showControlsWithFocus(requestFocus: _videoPlayerNavigationEnabled);
      return KeyEventResult.handled;
    }

    // Handle Select/Enter when controls are hidden: pause and show controls.
    // Only intercept if this Focus node itself has primary focus (not a descendant).
    if (_isSelectKey(key) && !_showControls && _focusNode.hasPrimaryFocus) {
      _playOrPause();
      _showControlsWithFocus();
      return KeyEventResult.handled;
    }

    // On desktop/TV, show controls on directional input.
    // LEFT/RIGHT focuses timeline for seeking, UP/DOWN focuses play/pause.
    if (!isMobile && _isDirectionalKey(key) && (_videoPlayerNavigationEnabled || PlatformDetector.isTV())) {
      if (!_showControls) {
        final isHorizontal = key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight;
        if (isHorizontal) {
          _showControlsWithTimelineFocus();
          if (widget.canControl) {
            final forward = key == LogicalKeyboardKey.arrowRight;
            unawaited(_seekByTime(forward: forward));
          }
        } else {
          _showControlsWithFocus();
        }
        return KeyEventResult.handled;
      }
      // Children (DesktopVideoControls) handle navigation first via their own onKeyEvent.
      // If we reach here, children already declined the event — consume it to prevent leaking.
      return KeyEventResult.handled;
    }

    // Pass other events to the keyboard shortcuts service.
    if (_keyboardService == null) return KeyEventResult.handled;

    final result = _keyboardService!.handleVideoPlayerKeyEvent(
      event,
      widget.player,
      _toggleFullscreen,
      _toggleSubtitles,
      _nextAudioTrack,
      _nextSubtitleTrack,
      _nextChapter,
      _previousChapter,
      onBack: widget.onBack ?? () => Navigator.of(context).pop(true),
      onToggleShader: _toggleShader,
      onSkipMarker: _performAutoSkip,
      onNextEpisode: widget.onNext,
      onPreviousEpisode: widget.onPrevious,
      currentPositionEpoch: widget.currentPositionEpoch,
      onLiveSeek: widget.onLiveSeek,
    );
    // Let non-navigation keys (volume, etc.) pass through to the OS.
    if (!event.logicalKey.isNavigationKey) return KeyEventResult.ignored;
    // Never return .ignored for navigation keys — prevent leaking to previous routes.
    return result == KeyEventResult.ignored ? KeyEventResult.handled : result;
  }
}
