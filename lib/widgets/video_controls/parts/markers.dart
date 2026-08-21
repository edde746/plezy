part of '../video_controls.dart';

extension _PlexVideoControlsMarkerMethods on _PlexVideoControlsState {
  void _listenToPosition() {
    _positionSubscription = widget.player.streams.position.listen((position) {
      _syncCurrentMarkerForPosition(position);
    });
  }

  void _syncCurrentMarkerForCurrentPosition() {
    _syncCurrentMarkerForPosition(widget.player.state.position);
  }

  void _syncCurrentMarkerForPosition(Duration position) {
    if (!_hasRenderedFirstFrame || _markers.isEmpty || !_markersLoaded) {
      _clearCurrentMarker();
      return;
    }

    MediaMarker? foundMarker;
    for (final marker in _markers) {
      if (marker.containsPosition(position)) {
        foundMarker = marker;
        break;
      }
    }

    if (foundMarker != _currentMarker && mounted) {
      _updateCurrentMarker(foundMarker);
    }
  }

  void _clearCurrentMarker() {
    final hasMarkerState =
        _currentMarker != null ||
        _skipButtonDismissed ||
        _autoSkipTimer != null ||
        _autoSkipProgress != 0.0 ||
        _skipButtonDismissTimer != null;
    if (!hasMarkerState) return;

    if (_currentMarker != null || _skipButtonDismissed) {
      _setControlsState(() {
        _currentMarker = null;
        _skipButtonDismissed = false;
      });
    }
    _releaseSkipMarkerFocusToSurface();
    _cancelAutoSkipTimer();
    _cancelSkipButtonDismissTimer();
  }

  /// Hands the remote back to the player surface when the skip button is
  /// about to leave the tree while holding focus. Without this, focus falls
  /// out of the controls subtree, the enclosing screen reclaims it onto its
  /// own node, and the next Select raises the chrome instead of toggling
  /// playback (#1890).
  void _releaseSkipMarkerFocusToSurface() {
    if (!_skipMarkerFocusNode.hasFocus) return;
    _claimPlayerSurfaceFocus();
  }

  /// Updates the current marker and manages auto-skip/focus behavior.
  void _updateCurrentMarker(MediaMarker? foundMarker) {
    if (!_hasRenderedFirstFrame) {
      _clearCurrentMarker();
      return;
    }

    if (foundMarker == null) {
      _clearCurrentMarker();
      return;
    }

    _setControlsState(() {
      _currentMarker = foundMarker;
      _skipButtonDismissed = false;
    });

    _startAutoSkipTimer(foundMarker);

    // Auto-skip OFF: dismiss button after 7s if no interaction
    // Auto-skip ON: button stays until controls hide
    if (!_shouldAutoSkipForMarker(foundMarker)) {
      _startSkipButtonDismissTimer();
    }

    // Auto-focus skip button on TV when marker appears (only in keyboard/TV mode)
    if (PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context, listen: false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _skipMarkerFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _skipMarker({bool skipAutoPlayCountdown = false}) async {
    if (!widget.canControl) return;
    if (_currentMarker == null || !_hasRenderedFirstFrame) return;

    final marker = _currentMarker!;
    final endTime = marker.endTime;
    final duration = widget.player.state.duration;
    final isAtEnd = duration > Duration.zero && (duration - endTime).inMilliseconds <= 1000;

    final handsOffToCompletion = marker.isCredits && isAtEnd;
    if (handsOffToCompletion) {
      if (!skipAutoPlayCountdown && widget.onNext != null) {
        _abandoningBurst(widget.onNext)!.call();
      } else {
        // Seeking to EOF is unreliable due to position stream throttling,
        // so pause and defer to the parent's completion flow.
        await widget.player.pause();
        widget.onReachedEnd?.call(skipAutoPlayCountdown: skipAutoPlayCountdown);
      }
    } else {
      await _seekToPosition(endTime);
    }

    if (!mounted) return;
    _setControlsState(() {
      _currentMarker = null;
    });
    // The play-next flow requests its own focus; claiming the surface here
    // would race it.
    if (!handsOffToCompletion) _releaseSkipMarkerFocusToSurface();
    _cancelAutoSkipTimer();
    _cancelSkipButtonDismissTimer();
  }

  void _startAutoSkipTimer(MediaMarker marker) {
    _cancelAutoSkipTimer();
    if (!_hasRenderedFirstFrame) return;

    final shouldAutoSkip = (marker.isCredits && _autoSkipCredits) || (!marker.isCredits && _autoSkipIntro);

    if (!shouldAutoSkip || _autoSkipDelay <= 0) return;

    _autoSkipProgress = 0.0;
    const tickDuration = Duration(milliseconds: 200);
    final totalTicks = (_autoSkipDelay * 1000) / tickDuration.inMilliseconds;

    if (totalTicks <= 0) return;

    _autoSkipTimer = Timer.periodic(tickDuration, (timer) {
      if (!mounted || _currentMarker != marker) {
        timer.cancel();
        return;
      }

      _setControlsState(() {
        _autoSkipProgress = (timer.tick / totalTicks).clamp(0.0, 1.0);
      });

      if (timer.tick >= totalTicks) {
        timer.cancel();
        _performAutoSkip(skipAutoPlayCountdown: true);
      }
    });
  }

  void _cancelAutoSkipTimer() {
    final hadTimer = _autoSkipTimer != null;
    _autoSkipTimer?.cancel();
    _autoSkipTimer = null;
    if (mounted && (hadTimer || _autoSkipProgress != 0.0)) {
      _setControlsState(() {
        _autoSkipProgress = 0.0;
      });
    }
  }

  bool _cancelAutoSkipFromUserInteraction() {
    final hadActiveTimer = _autoSkipTimer?.isActive ?? false;
    if (!hadActiveTimer) return false;

    _cancelAutoSkipTimer();
    if (_currentMarker != null && !_skipButtonDismissed) {
      _startSkipButtonDismissTimer();
    }
    return true;
  }

  /// Starts/restarts the skip button dismiss timer. When it fires, hides the
  /// button and cancels any active auto-skip countdown.
  void _startSkipButtonDismissTimer() {
    _skipButtonDismissTimer?.cancel();
    if (!_hasRenderedFirstFrame) return;
    _skipButtonDismissTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted || _currentMarker == null) return;
      _setControlsState(() {
        _skipButtonDismissed = true;
      });
      // The dismissed flag only hides the button while the chrome is down;
      // with the chrome up the button stays visible and keeps its focus.
      if (!_showControls) _releaseSkipMarkerFocusToSurface();
      _cancelAutoSkipTimer();
    });
  }

  void _cancelSkipButtonDismissTimer() {
    _skipButtonDismissTimer?.cancel();
    _skipButtonDismissTimer = null;
  }

  /// Perform the appropriate skip action based on marker type and next episode availability
  void _performAutoSkip({bool skipAutoPlayCountdown = false}) {
    if (!widget.canControl) return;
    if (_currentMarker == null || !_hasRenderedFirstFrame) return;
    unawaited(_skipMarker(skipAutoPlayCountdown: skipAutoPlayCountdown));
  }

  bool _shouldAutoSkipForMarker(MediaMarker marker) {
    return (marker.isCredits && _autoSkipCredits) || (!marker.isCredits && _autoSkipIntro);
  }

  bool _shouldShowAutoSkip() {
    if (_currentMarker == null) return false;
    return _shouldAutoSkipForMarker(_currentMarker!);
  }

  bool get _isSkipMarkerButtonVisible => shouldShowSkipMarkerButton(
    hasFirstFrame: _hasRenderedFirstFrame,
    hasMarker: _currentMarker != null,
    hasPlayNextPrompt: widget.playNextFocusNode != null,
    skipButtonDismissed: _skipButtonDismissed,
    controlsVisible: _showControls,
  );

  void _activateSkipMarker() {
    if (!_isSkipMarkerButtonVisible) return;
    _cancelAutoSkipTimer();
    _performAutoSkip();
  }

  /// The viewer's "no thanks" to a skip prompt: stops any running auto-skip
  /// countdown and hides the button for the rest of this marker.
  ///
  /// The mirror of [_activateSkipMarker]. The focus hand-back carries its own
  /// chrome guard rather than relying on the caller's: with the chrome up the
  /// button stays visible and keeps focus, so releasing it there would pull the
  /// remote off a control the viewer can still see.
  void _dismissSkipMarker() {
    if (!_isSkipMarkerButtonVisible) return;
    // Cancelled here rather than left to the global key handler's
    // _cancelAutoSkipFromUserInteraction: gamepad and companion-remote presses
    // are synthesized straight onto the focus chain and never reach
    // HardwareKeyboard, so for those this is the only thing that stops the
    // countdown.
    _cancelAutoSkipTimer();
    _cancelSkipButtonDismissTimer();
    _setControlsState(() {
      _skipButtonDismissed = true;
    });
    if (!_showControls) _releaseSkipMarkerFocusToSurface();
  }

  Widget _buildSkipMarkerButton() {
    final isAutoSkipActive = _autoSkipTimer?.isActive ?? false;
    return SkipMarkerButton(
      marker: _currentMarker!,
      playerDuration: widget.player.state.duration,
      hasNextEpisode: widget.onNext != null,
      isAutoSkipActive: isAutoSkipActive,
      shouldShowAutoSkip: _shouldShowAutoSkip(),
      autoSkipDelay: _autoSkipDelay,
      autoSkipProgress: _autoSkipProgress,
      focusNode: _skipMarkerFocusNode,
      onActivate: _activateSkipMarker,
      onFocusDown: () => _desktopControlsKey.currentState?.requestPlayPauseFocus(),
    );
  }
}
