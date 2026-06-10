part of '../video_controls.dart';

extension _PlexVideoControlsPlaybackInputMethods on _PlexVideoControlsState {
  static const Duration _touchTapSuppressionPadding = Duration(milliseconds: 80);

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
      for (final chapter in _chapters) {
        final chapterStart = chapter.startTimeOffset ?? 0;
        if (chapterStart > currentPositionMs) {
          await _seekToPosition(Duration(milliseconds: chapterStart));
          return;
        }
      }
    } else {
      for (int i = _chapters.length - 1; i >= 0; i--) {
        final chapterStart = _chapters[i].startTimeOffset ?? 0;
        if (currentPositionMs > chapterStart + 3000) {
          // If more than 3 seconds into chapter, go to start of current chapter
          await _seekToPosition(Duration(milliseconds: chapterStart));
          return;
        }
      }
      await _seekToPosition(Duration.zero);
    }
  }

  Future<void> _seekToPosition(Duration position, {bool notifyCompletion = true}) async {
    final clamped = clampSeekPosition(widget.player, position);
    await (widget.onSeekRequested ?? widget.player.seek)(clamped);
    if (notifyCompletion && mounted) {
      widget.onSeekCompleted?.call(clamped);
    }
  }

  Future<void> _seekByOffset(Duration delta, {bool notifyCompletion = true}) async {
    // Route relative live-TV skips through the parent accumulator, which
    // coalesces a rapid burst into a single transcode re-open and computes the
    // target from a stable base rather than the laggy live epoch (#1253).
    if (widget.isLive && widget.onLiveSeekBy != null) {
      widget.onLiveSeekBy!(delta.inSeconds);
      return;
    }
    final target = widget.player.state.position + delta;
    final clamped = clampSeekPosition(widget.player, target);
    await (widget.onSeekRequested ?? widget.player.seek)(clamped);
    if (notifyCompletion && mounted) {
      widget.onSeekCompleted?.call(clamped);
    }
  }

  Future<void> _playOrPause() async {
    if (!widget.player.state.playing && _rewindOnResume > 0) {
      final target = widget.player.state.position - Duration(seconds: _rewindOnResume);
      final clamped = clampSeekPosition(widget.player, target);
      await (widget.onSeekRequested ?? widget.player.seek)(clamped);
    }
    await widget.player.playOrPause();
  }

  /// Throttled seek for timeline slider - executes immediately then throttles to 200ms
  void _throttledSeek(Duration position) {
    // Hold before the transcoding early-return so a slow scrub never loses
    // the controls to auto-hide mid-drag (idempotent while held).
    widget.chromeController.hold(PlayerChromeHold.scrub);
    if (widget.isTranscoding) return;
    _seekThrottle([position]);
  }

  /// Finalizes the seek when user stops scrubbing the timeline
  void _finalizeSeek(Duration position) {
    _seekThrottle.cancel();
    unawaited(_seekToPosition(position));
    widget.chromeController.release(PlayerChromeHold.scrub);
  }

  bool get _isTouchTapSuppressed {
    final until = _suppressTouchTapUntil;
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _suppressTouchTapUntil = null;
      return false;
    }
    return true;
  }

  void _suppressTouchTaps() {
    _singleTapTimer?.cancel();
    _singleTapTimer = null;
    _suppressTouchTapUntil = DateTime.now().add(kDoubleTapTimeout + _touchTapSuppressionPadding);
  }

  void _handleTouchPointerDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    _twoFingerDoubleTapTracker.pointerDown(event.pointer, event.position);
    if (_twoFingerDoubleTapTracker.isChordActive) _suppressTouchTaps();
  }

  void _handleTouchPointerMove(PointerMoveEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    _twoFingerDoubleTapTracker.pointerMove(event.pointer, event.position);
    if (_twoFingerDoubleTapTracker.isChordActive) _suppressTouchTaps();
  }

  void _handleTouchPointerUp(PointerUpEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    final isResetGesture = _twoFingerDoubleTapTracker.pointerUp(event.pointer, event.position);
    if (_isTouchTapSuppressed || isResetGesture) _suppressTouchTaps();
    if (isResetGesture) widget.onResetVideoZoom?.call();
  }

  void _handleTouchPointerCancel(PointerCancelEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    _twoFingerDoubleTapTracker.pointerCancel(event.pointer);
    if (_twoFingerDoubleTapTracker.isChordActive) _suppressTouchTaps();
  }

  /// Timing-based double-click detection: avoids `onDoubleTap`'s ~300 ms
  /// tap-resolution delay and the arena competition it introduces.
  void _handleOuterTap() {
    if (PlatformDetector.isMobile(context) && _isTouchTapSuppressed) return;

    if (widget.canControl && _clickVideoTogglesPlayback) {
      _playOrPause();
    } else {
      _toggleControls();
    }

    if (PlatformDetector.isMobile(context)) return;

    final now = DateTime.now();
    if (_lastSkipTapTime != null && now.difference(_lastSkipTapTime!) < kDoubleTapTimeout) {
      _lastSkipTapTime = null;
      _toggleFullscreen();
      return;
    }
    _lastSkipTapTime = now;
  }

  /// Handle tap in skip zone with custom double-tap detection
  void _handleTapInSkipZone({required bool isForward}) {
    if (_isTouchTapSuppressed) return;

    // Cancel any pending single-tap action
    _singleTapTimer?.cancel();
    _singleTapTimer = null;

    // While the skip pill is visible, every tap in the same-direction zone
    // stacks another skip immediately — repeat skips cost one tap, not a
    // fresh double-tap. A tap in the opposite zone falls through to pairing.
    if (_showDoubleTapFeedback && _lastDoubleTapWasForward == isForward) {
      _handleStackingSkip(isForward: isForward);
      return;
    }

    final now = DateTime.now();
    final isDoubleTap =
        _lastSkipTapTime != null &&
        now.difference(_lastSkipTapTime!) < kDoubleTapTimeout &&
        _lastSkipTapWasForward == isForward;

    // Skip ONLY on detected double-tap (no single-tap-to-add behavior)
    if (isDoubleTap) {
      _lastSkipTapTime = null;
      _handleDoubleTapSkip(isForward: isForward);
    } else {
      // First tap - record timestamp and start timer for single-tap action
      _lastSkipTapTime = now;
      _lastSkipTapWasForward = isForward;

      // If no second tap within the double-tap window, treat as single tap
      // to toggle controls
      _singleTapTimer = Timer(kDoubleTapTimeout, () {
        if (mounted) {
          _toggleControls();
        }
      });
    }
  }

  Size _sizeOf(BuildContext context) {
    final renderObject = context.findRenderObject();
    return renderObject is RenderBox ? renderObject.size : Size.zero;
  }

  /// Handle stacking skip - add to accumulated skip when feedback is active.
  /// Feedback refreshes before the seek is issued: the seek can be slow (a
  /// transcode restart does a server round-trip) and the pill must react to
  /// the tap, not to seek completion.
  void _handleStackingSkip({required bool isForward}) {
    if (!widget.canControl) return;

    _accumulatedSkipSeconds += _seekTimeSmall;
    _showSkipFeedback(isForward: isForward);

    final delta = Duration(seconds: isForward ? _seekTimeSmall : -_seekTimeSmall);
    unawaited(_seekByOffset(delta));
  }

  void _handleDoubleTapSkip({required bool isForward}) {
    if (!widget.canControl) return;

    _accumulatedSkipSeconds = _seekTimeSmall;
    _showSkipFeedback(isForward: isForward);

    final delta = Duration(seconds: isForward ? _seekTimeSmall : -_seekTimeSmall);
    unawaited(_seekByOffset(delta));
  }

  /// Show animated visual feedback for skip gesture
  void _showSkipFeedback({required bool isForward}) {
    // Cancel BOTH timers: a skip landing during the fade-out window must not
    // leave the old hide timer pending, or it kills the fresh pill and zeroes
    // the accumulated count mid-display.
    _feedbackTimer?.cancel();
    _feedbackHideTimer?.cancel();

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

        _feedbackHideTimer = Timer(slowDuration, () {
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
  void _handleControlsOverlayTap(TapUpDetails details, Size size) {
    final isMobile = PlatformDetector.isMobile(context);

    if (!isMobile) {
      final DateTime now = DateTime.now();

      // Always perform the single-click behavior immediately
      if (widget.canControl && _clickVideoTogglesPlayback) {
        _playOrPause();
      } else {
        _toggleControls();
      }

      final bool isDoubleClick = _lastSkipTapTime != null && now.difference(_lastSkipTapTime!) < kDoubleTapTimeout;

      if (isDoubleClick) {
        _lastSkipTapTime = null;

        _toggleFullscreen();

        return;
      }

      // Record this click as a candidate for double-click detection
      _lastSkipTapTime = now;
      return;
    }

    if (_isTouchTapSuppressed) return;

    final skipZone = mobileSkipZoneForTap(position: details.localPosition, size: size);
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

  void _handleLongPressCancel() => _handleLongPressEnd();

  /// Build the visual indicator for long-press 2x speed.
  /// Manual (persistent for duration of press) — separate from the stream-driven
  /// toast so it stays visible for the full long-press rather than auto-hiding.
  Widget _buildSpeedIndicator() => const PlayerToastIndicator(icon: Symbols.fast_forward_rounded, text: '2x');
}
