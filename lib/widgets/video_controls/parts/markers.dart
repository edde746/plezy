part of '../video_controls.dart';

extension _PlexVideoControlsMarkerMethods on _PlexVideoControlsState {
  void _listenToPosition() {
    _positionSubscription = widget.player.streams.position.listen((position) {
      if (_markers.isEmpty || !_markersLoaded) {
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
    });
  }

  /// Updates the current marker and manages auto-skip/focus behavior.
  void _updateCurrentMarker(MediaMarker? foundMarker) {
    _setControlsState(() {
      _currentMarker = foundMarker;
      _skipButtonDismissed = false;
    });

    if (foundMarker == null) {
      _cancelAutoSkipTimer();
      _cancelSkipButtonDismissTimer();
      return;
    }

    _startAutoSkipTimer(foundMarker);

    // Auto-skip OFF: dismiss button after 7s if no interaction
    // Auto-skip ON: button stays until controls hide
    if (!_shouldAutoSkipForMarker(foundMarker)) {
      _startSkipButtonDismissTimer();
    }

    // Auto-focus skip button on TV when marker appears (only in keyboard/TV mode)
    if (PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _skipMarkerFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _skipMarker({bool skipAutoPlayCountdown = false}) async {
    if (_currentMarker == null) return;

    final marker = _currentMarker!;
    final endTime = marker.endTime;
    final duration = widget.player.state.duration;
    final isAtEnd = duration > Duration.zero && (duration - endTime).inMilliseconds <= 1000;

    if (marker.isCredits && isAtEnd) {
      if (!skipAutoPlayCountdown && widget.onNext != null) {
        widget.onNext!.call();
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
    _cancelAutoSkipTimer();
    _cancelSkipButtonDismissTimer();
  }

  void _startAutoSkipTimer(MediaMarker marker) {
    _cancelAutoSkipTimer();

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
    _autoSkipTimer?.cancel();
    _autoSkipTimer = null;
    if (mounted) {
      _setControlsState(() {
        _autoSkipProgress = 0.0;
      });
    }
  }

  /// Starts/restarts the skip button dismiss timer. When it fires, hides the
  /// button and cancels any active auto-skip countdown.
  void _startSkipButtonDismissTimer() {
    _skipButtonDismissTimer?.cancel();
    _skipButtonDismissTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted || _currentMarker == null) return;
      _setControlsState(() {
        _skipButtonDismissed = true;
      });
      _cancelAutoSkipTimer();
    });
  }

  void _cancelSkipButtonDismissTimer() {
    _skipButtonDismissTimer?.cancel();
    _skipButtonDismissTimer = null;
  }

  /// Perform the appropriate skip action based on marker type and next episode availability
  void _performAutoSkip({bool skipAutoPlayCountdown = false}) {
    if (_currentMarker == null) return;
    unawaited(_skipMarker(skipAutoPlayCountdown: skipAutoPlayCountdown));
  }

  /// Check if auto-skip should be active for the current marker
  bool _shouldAutoSkipForMarker(MediaMarker marker) {
    return (marker.isCredits && _autoSkipCredits) || (!marker.isCredits && _autoSkipIntro);
  }

  bool _shouldShowAutoSkip() {
    if (_currentMarker == null) return false;
    return _shouldAutoSkipForMarker(_currentMarker!);
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
      onCancelAutoSkip: _cancelAutoSkipTimer,
      onPerformAutoSkip: _performAutoSkip,
      onFocusDown: () => _desktopControlsKey.currentState?.requestPlayPauseFocus(),
    );
  }
}
