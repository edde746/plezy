part of '../video_controls.dart';

extension _PlexVideoControlsPlaybackInputMethods on _PlexVideoControlsState {
  void _onRateChanged(double newRate) {
    if (!mounted) return;
    if (_isLongPressing) return;
    if (_suppressRateToastUntil != null && DateTime.now().isBefore(_suppressRateToastUntil!)) return;
    final prev = _lastReportedRate;
    if (prev != null && (prev - newRate).abs() < 0.005) return;
    _lastReportedRate = newRate;
    final icon = newRate >= 1.0 ? Symbols.fast_forward_rounded : Symbols.slow_motion_video_rounded;
    widget.toastController.show(icon, formatPlaybackRate(newRate));
  }

  void _seekToPreviousChapter() => unawaited(_seekToChapter(forward: false));

  void _seekToNextChapter() => unawaited(_seekToChapter(forward: true));

  Future<void> _seekByTime({required bool forward}) async {
    final delta = Duration(seconds: forward ? _seekTimeSmall : -_seekTimeSmall);
    await _seekByOffset(delta);
  }

  Future<void> _seekToChapter({required bool forward}) async {
    if (_chapters.isEmpty) {
      // No chapters - seek by configured amount
      final delta = Duration(seconds: forward ? _seekTimeSmall : -_seekTimeSmall);
      await _seekByOffset(delta);
      return;
    }

    final currentPositionMs = widget.player.state.position.inMilliseconds;

    if (forward) {
      // Find next chapter
      for (final chapter in _chapters) {
        final chapterStart = chapter.startTimeOffset ?? 0;
        if (chapterStart > currentPositionMs) {
          await _seekToPosition(Duration(milliseconds: chapterStart));
          return;
        }
      }
    } else {
      // Find previous/current chapter
      for (int i = _chapters.length - 1; i >= 0; i--) {
        final chapterStart = _chapters[i].startTimeOffset ?? 0;
        if (currentPositionMs > chapterStart + 3000) {
          // If more than 3 seconds into chapter, go to start of current chapter
          await _seekToPosition(Duration(milliseconds: chapterStart));
          return;
        }
      }
      // If at start of first chapter, go to beginning
      await _seekToPosition(Duration.zero);
    }
  }

  Future<void> _seekToPosition(Duration position, {bool notifyCompletion = true}) async {
    final clamped = clampSeekPosition(widget.player, position);
    await widget.player.seek(clamped);
    if (notifyCompletion && mounted) {
      widget.onSeekCompleted?.call(clamped);
    }
  }

  Future<void> _seekByOffset(Duration delta, {bool notifyCompletion = true}) async {
    // Route through live seek callback for time-shifted live TV
    if (widget.isLive && widget.onLiveSeek != null && widget.currentPositionEpoch != null) {
      widget.onLiveSeek!(widget.currentPositionEpoch! + delta.inSeconds);
      return;
    }
    final target = widget.player.state.position + delta;
    final clamped = clampSeekPosition(widget.player, target);
    await widget.player.seek(clamped);
    if (notifyCompletion && mounted) {
      widget.onSeekCompleted?.call(clamped);
    }
  }

  Future<void> _playOrPause() async {
    if (!widget.player.state.playing && _rewindOnResume > 0) {
      final target = widget.player.state.position - Duration(seconds: _rewindOnResume);
      final clamped = clampSeekPosition(widget.player, target);
      await widget.player.seek(clamped);
    }
    await widget.player.playOrPause();
  }

  /// Throttled seek for timeline slider - executes immediately then throttles to 200ms
  void _throttledSeek(Duration position) => _seekThrottle([position]);

  /// Finalizes the seek when user stops scrubbing the timeline
  void _finalizeSeek(Duration position) {
    _seekThrottle.cancel();
    unawaited(_seekToPosition(position));
  }

  /// Timing-based double-click detection: avoids `onDoubleTap`'s ~300 ms
  /// tap-resolution delay and the arena competition it introduces.
  void _handleOuterTap() {
    if (widget.canControl && _clickVideoTogglesPlayback) {
      _playOrPause();
    } else {
      _toggleControls();
    }

    if (PlatformDetector.isMobile(context)) return;

    final now = DateTime.now();
    if (_lastSkipTapTime != null && now.difference(_lastSkipTapTime!).inMilliseconds < 250) {
      _lastSkipTapTime = null;
      _toggleFullscreen();
      return;
    }
    _lastSkipTapTime = now;
  }

  /// Handle tap in skip zone with custom double-tap detection
  void _handleTapInSkipZone({required bool isForward}) {
    final now = DateTime.now();

    // Cancel any pending single-tap action
    _singleTapTimer?.cancel();
    _singleTapTimer = null;

    // Debounce: ignore taps within 200ms of last skip action
    // This prevents double-taps from counting as two separate skips
    if (_lastSkipActionTime != null && now.difference(_lastSkipActionTime!).inMilliseconds < 200) {
      return;
    }

    // Check if this qualifies as a double-tap (within 250ms of last tap, same side)
    final isDoubleTap =
        _lastSkipTapTime != null &&
        now.difference(_lastSkipTapTime!).inMilliseconds < 250 &&
        _lastSkipTapWasForward == isForward;

    // Skip ONLY on detected double-tap (no single-tap-to-add behavior)
    if (isDoubleTap) {
      _lastSkipTapTime = null; // Reset to prevent triple-tap chaining

      if (_showDoubleTapFeedback && _lastDoubleTapWasForward == isForward) {
        // Stacking skip - add to accumulated
        unawaited(_handleStackingSkip(isForward: isForward));
      } else {
        // First double-tap - initiate skip
        unawaited(_handleDoubleTapSkip(isForward: isForward));
      }
    } else {
      // First tap - record timestamp and start timer for single-tap action
      _lastSkipTapTime = now;
      _lastSkipTapWasForward = isForward;

      // If no second tap within 250ms, treat as single tap to toggle controls
      _singleTapTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) {
          _toggleControls();
        }
      });
    }
  }

  /// Handle stacking skip - add to accumulated skip when feedback is active
  Future<void> _handleStackingSkip({required bool isForward}) async {
    if (!widget.canControl) return;

    // Add to accumulated skip
    _accumulatedSkipSeconds += _seekTimeSmall;

    // Calculate and perform seek
    final delta = Duration(seconds: isForward ? _seekTimeSmall : -_seekTimeSmall);
    await _seekByOffset(delta);

    // Refresh feedback (extends timer, updates display)
    _showSkipFeedback(isForward: isForward);

    // Record skip time for debounce
    _lastSkipActionTime = DateTime.now();
  }

  /// Handle double-tap skip forward or backward
  Future<void> _handleDoubleTapSkip({required bool isForward}) async {
    // Ignore if user cannot control playback
    if (!widget.canControl) return;

    // Reset accumulated skip for new gesture
    _accumulatedSkipSeconds = _seekTimeSmall;

    final delta = Duration(seconds: isForward ? _seekTimeSmall : -_seekTimeSmall);
    await _seekByOffset(delta);

    // Show visual feedback
    _showSkipFeedback(isForward: isForward);

    // Record skip time for debounce
    _lastSkipActionTime = DateTime.now();
  }

  /// Show animated visual feedback for skip gesture
  void _showSkipFeedback({required bool isForward}) {
    _feedbackTimer?.cancel();

    _setControlsState(() {
      _lastDoubleTapWasForward = isForward;
      _showDoubleTapFeedback = true;
      _doubleTapFeedbackOpacity = 1.0;
    });

    // Capture duration before timer to avoid context access in callback
    final slowDuration = tokens(context).slow;

    // Fade out after delay (1200ms gives time to see value and continue tapping)
    _feedbackTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _setControlsState(() {
          _doubleTapFeedbackOpacity = 0.0;
        });

        Timer(slowDuration, () {
          if (mounted) {
            _setControlsState(() {
              _showDoubleTapFeedback = false;
              _accumulatedSkipSeconds = 0; // Reset when feedback hides
            });
          }
        });
      }
    });
  }

  /// Handle tap on controls overlay - route to skip zones or toggle controls
  void _handleControlsOverlayTap(TapUpDetails details, BoxConstraints constraints) {
    final isMobile = PlatformDetector.isMobile(context);

    if (!isMobile) {
      final DateTime now = DateTime.now();

      // Always perform the single-click behavior immediately
      if (widget.canControl && _clickVideoTogglesPlayback) {
        _playOrPause();
      } else {
        _toggleControls();
      }

      // Detect double-click
      final bool isDoubleClick = _lastSkipTapTime != null && now.difference(_lastSkipTapTime!).inMilliseconds < 250;

      if (isDoubleClick) {
        _lastSkipTapTime = null;

        // Perform desktop double-click action: toggle fullscreen
        _toggleFullscreen();

        return;
      }

      // Record this click as a candidate for double-click detection
      _lastSkipTapTime = now;
      return;
    }

    final width = constraints.maxWidth;
    final skipZone = mobileSkipZoneForTap(position: details.localPosition, size: Size(width, constraints.maxHeight));
    if (skipZone != null) {
      _handleTapInSkipZone(isForward: skipZone);
      return;
    }

    // Not in skip zone, toggle controls
    _toggleControls();
  }

  /// Handle long-press start - activate 2x speed
  void _handleLongPressStart() {
    if (!widget.canControl || widget.isLive) return;

    _setControlsState(() {
      _isLongPressing = true;
      _rateBeforeLongPress = widget.player.state.rate;
      _showSpeedIndicator = true;
    });
    widget.player.setRate(2.0);
  }

  /// Handle long-press end - restore original speed
  void _handleLongPressEnd() {
    if (!_isLongPressing) return;
    // Swallow the rate-restore emission so the stream-driven toast doesn't
    // flash as the rate snaps back to the prior value.
    _suppressRateToastUntil = DateTime.now().add(const Duration(milliseconds: 250));
    widget.player.setRate(_rateBeforeLongPress ?? 1.0);
    _setControlsState(() {
      _isLongPressing = false;
      _rateBeforeLongPress = null;
      _showSpeedIndicator = false;
    });
  }

  /// Handle long-press cancel (same as end)
  void _handleLongPressCancel() => _handleLongPressEnd();

  /// Build the visual indicator for long-press 2x speed.
  /// Manual (persistent for duration of press) — separate from the stream-driven
  /// toast so it stays visible for the full long-press rather than auto-hiding.
  Widget _buildSpeedIndicator() => const PlayerToastIndicator(icon: Symbols.fast_forward_rounded, text: '2x');
}
