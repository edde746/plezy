part of '../video_controls.dart';

extension _PlexVideoControlsPlaybackInputMethods on _PlexVideoControlsState {
  static const Duration _touchTapSuppressionPadding = Duration(milliseconds: 80);

  void _onRateChanged(double newRate) {
    if (!mounted) return;
    if (_isLongPressing) return;
    if (_suppressRateToastUntil != null && DateTime.now().isBefore(_suppressRateToastUntil!)) {
      return;
    }
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

  /// Relative seek reported through the transient skip badge instead of the
  /// scrub bar, so the picture and its subtitles stay uncovered (#1676).
  ///
  /// Steps are coalesced into one absolute seek pinned to the pending target,
  /// so a burst of presses cannot rebase off a position a slow backend has not
  /// applied yet — without that the badge would report a total the player
  /// never actually seeks.
  void _seekByWithFeedback(Duration delta) {
    if (!widget.canControl || delta == Duration.zero) return;
    final forward = !delta.isNegative;

    // Live TV: relative epoch-based skips go through the parent accumulator —
    // an absolute target is meaningless against a moving live edge (#1253).
    if (widget.isLive && widget.onLiveSeekBy != null) {
      final stepSeconds = (delta.inMilliseconds.abs() / 1000).round().clamp(1, 300);
      widget.onLiveSeekBy!(forward ? stepSeconds : -stepSeconds);
      _registerSkipFeedback(isForward: forward, seconds: stepSeconds);
      return;
    }

    if (widget.player.state.duration.inMilliseconds <= 0) return;

    _hiddenSeek.seekBy(delta);
    _registerSkipFeedback(isForward: forward, seconds: (delta.inMilliseconds.abs() / 1000).round());
  }

  /// Seek requested by a configured keyboard shortcut (the default Left/Right
  /// and Shift+Left/Right bindings, plus any rebinding of them). Desktop never
  /// reaches the D-pad path below, so this is its route to the same badge.
  void _keyboardSeekBy(int offsetSeconds) => _seekByWithFeedback(Duration(seconds: offsetSeconds));

  /// Directional D-pad seek with the chrome hidden. Mirrors the focused
  /// timeline's held-key behaviour — progressive acceleration plus one
  /// coalesced seek — without raising the timeline.
  void _hiddenDirectionalSeek({required bool forward, required bool isRepeat}) {
    if (!widget.canControl) return;

    if (_hiddenSeekForward != forward) {
      _hiddenSeekForward = forward;
      _hiddenSeekRepeatCount = 0;
    }
    if (isRepeat) _hiddenSeekRepeatCount++;
    final multiplier = isRepeat ? steppedSeekMultiplier(_hiddenSeekRepeatCount) : 1.0;

    final stepMs = (_seekTimeSmall * 1000 * multiplier).clamp(500, 120_000).toInt();
    _seekByWithFeedback(Duration(milliseconds: forward ? stepMs : -stepMs));
  }

  /// Commit the pending coalesced seek — the key was released, or the chrome
  /// took over. A no-op when nothing is pending.
  void _flushHiddenDirectionalSeek() {
    _hiddenSeekForward = null;
    _hiddenSeekRepeatCount = 0;
    _hiddenSeek.flush();
  }

  /// Tolerance for "already at the start", so a previous-chapter press at the
  /// very beginning is recognised as a no-op rather than a rewind to zero.
  static const Duration _startOfMediaTolerance = Duration(milliseconds: 500);

  /// What an adjacent-chapter seek would do from the current position, without
  /// performing it. Resolving separately lets a caller show feedback on key
  /// down rather than after a potentially slow transcode re-open.
  ///
  /// A null [target] with chapters present means there is nowhere to go — past
  /// the last chapter going forward, or already at the start going back — so
  /// callers must neither seek nor announce.
  ({bool usedChapters, MediaChapter? chapter, Duration? target}) _resolveChapterSeek({required bool forward}) {
    if (_chapters.isEmpty) return (usedChapters: false, chapter: null, target: null);

    final position = widget.player.state.position;
    final targetIndex = MediaChapter.seekTargetIndex(position, _chapters, forward: forward);
    if (targetIndex != null) {
      final chapter = _chapters[targetIndex];
      return (usedChapters: true, chapter: chapter, target: chapter.startTime);
    }
    if (!forward && position > _startOfMediaTolerance) {
      return (usedChapters: true, chapter: null, target: Duration.zero);
    }
    return (usedChapters: true, chapter: null, target: null);
  }

  Future<void> _seekToChapter({required bool forward}) {
    return _applyChapterSeek(_resolveChapterSeek(forward: forward), forward: forward);
  }

  Future<void> _applyChapterSeek(
    ({bool usedChapters, MediaChapter? chapter, Duration? target}) resolved, {
    required bool forward,
  }) async {
    if (!resolved.usedChapters) {
      // No chapters - seek by configured amount
      await _seekByOffset(Duration(seconds: forward ? _seekTimeSmall : -_seekTimeSmall));
      return;
    }
    final target = resolved.target;
    if (target != null) await _seekToPosition(target);
  }

  /// Chapter-aware seek driven by a remote's transport keys. Shows a transient
  /// badge instead of raising the chrome (#1676).
  void _seekToChapterWithFeedback({required bool forward}) {
    final resolved = _resolveChapterSeek(forward: forward);
    if (!resolved.usedChapters) {
      // No chapters: take the same coalesced path as every other badged seek.
      // Going through _applyChapterSeek here would rebase each press off
      // player.state.position, so a burst would report a total it never
      // commits.
      _seekByWithFeedback(Duration(seconds: forward ? _seekTimeSmall : -_seekTimeSmall));
      return;
    }
    if (resolved.target != null) {
      // Only announce a jump that actually happens.
      final title = resolved.chapter?.title?.trim();
      widget.toastController.show(
        forward ? Symbols.skip_next_rounded : Symbols.skip_previous_rounded,
        title != null && title.isNotEmpty
            ? title
            : (forward ? t.videoControls.nextChapterButton : t.videoControls.previousChapterButton),
      );
    }
    unawaited(_applyChapterSeek(resolved, forward: forward));
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

  Future<void> _seekToTimelinePosition(Duration position) {
    final clamped = clampSeekPosition(widget.player, position);
    final seekFuture = _seekToPosition(clamped, notifyCompletion: false);
    _lastDispatchedTimelineSeek = clamped;
    _lastDispatchedTimelineSeekFuture = seekFuture;
    return seekFuture;
  }

  Future<void> _playOrPause({TransportCommand command = TransportCommand.toggle}) async {
    if (!widget.canControl) return;
    // Rewind-on-resume keys off the *resolved* intent, not the current state:
    // a directed pause on an already-paused video must leave the position
    // untouched instead of jumping backwards.
    final willPlay = switch (command) {
      TransportCommand.play => true,
      TransportCommand.pause => false,
      TransportCommand.toggle => !widget.player.state.playing,
    };
    if (willPlay && !widget.player.state.playing && _rewindOnResume > 0) {
      final target = widget.player.state.position - Duration(seconds: _rewindOnResume);
      final clamped = clampSeekPosition(widget.player, target);
      await (widget.onSeekRequested ?? widget.player.seek)(clamped);
    }
    final requested = widget.onPlayPauseRequested;
    if (requested != null) {
      await requested(command);
      return;
    }
    await switch (command) {
      TransportCommand.play => widget.player.play(),
      TransportCommand.pause => widget.player.pause(),
      TransportCommand.toggle => widget.player.playOrPause(),
    };
  }

  /// Throttled seek for timeline slider - executes immediately then throttles to 200ms.
  void _throttledSeek(Duration position) {
    _seekThrottle([position]);
  }

  /// Finalizes the seek when user stops scrubbing the timeline
  void _finalizeSeek(Duration position) {
    _seekThrottle.cancel();
    final clamped = clampSeekPosition(widget.player, position);

    // The dedup state is per-gesture: it exists so a drag release doesn't
    // re-issue the seek its own throttle just dispatched. Clear it before
    // deciding, or a later gesture (e.g. a coalesced key-seek flush) landing
    // on the same position would be silently dropped.
    final lastDispatched = _lastDispatchedTimelineSeek;
    final seekFuture = _lastDispatchedTimelineSeekFuture;
    _lastDispatchedTimelineSeek = null;
    _lastDispatchedTimelineSeekFuture = null;

    if (shouldSkipDuplicateTimelineSeek(lastDispatchedSeek: lastDispatched, finalSeek: clamped)) {
      if (seekFuture == null) {
        widget.onSeekCompleted?.call(clamped);
        return;
      }
      unawaited(
        seekFuture.then<void>((_) {
          if (!mounted) return;
          widget.onSeekCompleted?.call(clamped);
        }),
      );
      return;
    }

    unawaited(_seekToPosition(clamped));
  }

  void _holdTimelineScrub() {
    widget.chromeController.hold(PlayerChromeHold.scrub);
  }

  void _releaseTimelineScrub() {
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
    _twoFingerTapTracker.pointerDown(event.pointer, event.position);
    if (_twoFingerTapTracker.isChordActive) {
      _suppressTouchTaps();
      _cancelEdgeAdjustmentGesture();
      return;
    }
    final hit = _edgeAdjustmentSurfaceHit(event.position);
    _handleEdgeAdjustmentEvent(
      _mobileTouchGesturesAllowed && hit != null
          ? _edgeAdjustmentTracker.pointerDown(event.pointer, hit.position, hit.size)
          : const MobileEdgeAdjustmentEvent.none(),
    );
  }

  void _handleTouchPointerMove(PointerMoveEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    _twoFingerTapTracker.pointerMove(event.pointer, event.position);
    if (_twoFingerTapTracker.isChordActive) {
      _suppressTouchTaps();
      _cancelEdgeAdjustmentGesture();
      return;
    }
    if (!_mobileTouchGesturesAllowed) {
      _cancelEdgeAdjustmentGesture();
      return;
    }
    final hit = _edgeAdjustmentSurfaceHit(event.position);
    if (hit == null) {
      _cancelEdgeAdjustmentGesture();
      return;
    }
    _handleEdgeAdjustmentEvent(_edgeAdjustmentTracker.pointerMove(event.pointer, hit.position));
  }

  void _handleTouchPointerUp(PointerUpEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    final isTwoFingerTap = _twoFingerTapTracker.pointerUp(event.pointer, event.position);
    final hit = _edgeAdjustmentSurfaceHit(event.position);
    _handleEdgeAdjustmentEvent(_edgeAdjustmentTracker.pointerUp(event.pointer, hit?.position ?? event.localPosition));
    if (_isTouchTapSuppressed || isTwoFingerTap) _suppressTouchTaps();
    // Toggle playback with the chrome left down (#1505), the moment the chord
    // resolves and in every player state. Deliberately no _toggleControls()/
    // chromeController.show(): covering the frame the viewer paused to read is
    // the problem this gesture exists to solve. The centred transport disc still
    // confirms the command via _announceTransportCommand, which only renders
    // while the chrome is hidden.
    //
    // The chord previously also reset the video zoom on a double tap. That was
    // dropped rather than deferred: recognising a pair means holding this toggle
    // back for kDoubleTapTimeout, and pausing late is pausing on the wrong
    // frame. Zoom reset lives in the video settings sheet, its presets, the
    // keyboard shortcut, and — for touch — pinching back through the 100% detent
    // in VideoFilterManager.snapPinchZoomScale.
    if (isTwoFingerTap && _mobileTouchGesturesAllowed) unawaited(_playOrPause());
  }

  void _handleTouchPointerCancel(PointerCancelEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    _twoFingerTapTracker.pointerCancel(event.pointer);
    _handleEdgeAdjustmentEvent(_edgeAdjustmentTracker.pointerCancel(event.pointer));
    if (_twoFingerTapTracker.isChordActive) _suppressTouchTaps();
  }

  bool get _mobileTouchGesturesAllowed {
    return PlatformDetector.isMobile(context) &&
        !PlatformDetector.isTV() &&
        !_isScreenLocked &&
        !_pipService.isPipActive.value &&
        !widget.chromeController.contentStripVisible;
  }

  ({Offset position, Size size})? _edgeAdjustmentSurfaceHit(Offset globalPosition) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return null;
    return (position: renderObject.globalToLocal(globalPosition), size: renderObject.size);
  }

  bool _isGlobalPositionInEdgeAdjustmentZone(Offset globalPosition) {
    final hit = _edgeAdjustmentSurfaceHit(globalPosition);
    if (hit == null) return false;
    return mobileEdgeAdjustmentZoneForPosition(position: hit.position, size: hit.size) != null;
  }

  void _refreshDeviceAdjustmentValues() {
    unawaited(_readEdgeAdjustmentValue(MobileEdgeAdjustmentSide.left));
    unawaited(_readEdgeAdjustmentValue(MobileEdgeAdjustmentSide.right));
  }

  Future<double?> _readEdgeAdjustmentValue(MobileEdgeAdjustmentSide side) {
    ++_edgeAdjustmentBaselineGeneration;
    _edgeAdjustmentBaselineSide = side;
    final read = side == MobileEdgeAdjustmentSide.left
        ? _deviceAdjustmentService.getBrightness()
        : _deviceAdjustmentService.getMediaVolume();
    final future = read.then((value) {
      if (mounted) _cacheEdgeAdjustmentValue(side, value);
      return value;
    });
    _edgeAdjustmentBaselineFuture = future;
    return future;
  }

  void _cacheEdgeAdjustmentValue(MobileEdgeAdjustmentSide side, double? value) {
    if (value == null) return;
    if (side == MobileEdgeAdjustmentSide.left) {
      _lastKnownBrightness = value;
    } else {
      _lastKnownMediaVolume = value;
    }
  }

  void _handleEdgeAdjustmentEvent(MobileEdgeAdjustmentEvent event) {
    final side = event.side;
    switch (event.type) {
      case MobileEdgeAdjustmentEventType.none:
        return;
      case MobileEdgeAdjustmentEventType.candidate:
        if (side != null) unawaited(_readEdgeAdjustmentValue(side));
        return;
      case MobileEdgeAdjustmentEventType.activated:
        if (side != null) _beginEdgeAdjustment(side, event.deltaFraction);
        return;
      case MobileEdgeAdjustmentEventType.update:
        if (side != null) {
          if (_pendingEdgeAdjustmentSide == side) {
            _pendingEdgeAdjustmentDelta = event.deltaFraction;
          } else if (_edgeAdjustmentWasActive) {
            _updateEdgeAdjustment(side, event.deltaFraction);
          }
        }
        return;
      case MobileEdgeAdjustmentEventType.ended:
        if (_pendingEdgeAdjustmentSide != null) {
          _clearPendingEdgeAdjustment();
          _finishEdgeAdjustment(suppressTap: false);
        } else {
          if (side != null && _edgeAdjustmentWasActive) {
            _updateEdgeAdjustment(side, event.deltaFraction, forceWrite: true);
          }
          _finishEdgeAdjustment(suppressTap: _edgeAdjustmentWasActive);
        }
        return;
      case MobileEdgeAdjustmentEventType.cancelled:
        _clearPendingEdgeAdjustment();
        _finishEdgeAdjustment(suppressTap: event.wasActive || _edgeAdjustmentWasActive);
        return;
    }
  }

  void _beginEdgeAdjustment(MobileEdgeAdjustmentSide side, double deltaFraction) {
    final startValue = _currentEdgeAdjustmentValue(side);
    if (startValue != null) {
      _startEdgeAdjustment(side, deltaFraction, startValue: startValue);
      return;
    }

    _suppressTouchTaps();
    if (_isLongPressing) _handleLongPressCancel();

    final Future<double?>? future;
    final int generation;
    if (_edgeAdjustmentBaselineSide == side && _edgeAdjustmentBaselineFuture != null) {
      future = _edgeAdjustmentBaselineFuture;
      generation = _edgeAdjustmentBaselineGeneration;
    } else {
      future = _readEdgeAdjustmentValue(side);
      generation = _edgeAdjustmentBaselineGeneration;
    }
    _pendingEdgeAdjustmentSide = side;
    _pendingEdgeAdjustmentDelta = deltaFraction;
    _pendingEdgeAdjustmentGeneration = generation;
    unawaited(_resolvePendingEdgeAdjustment(side, generation, future));
  }

  Future<void> _resolvePendingEdgeAdjustment(
    MobileEdgeAdjustmentSide side,
    int generation,
    Future<double?>? future,
  ) async {
    final value = await (future ?? _readEdgeAdjustmentValue(side)).timeout(
      const Duration(milliseconds: 300),
      onTimeout: () => null,
    );
    if (!mounted) return;
    if (_pendingEdgeAdjustmentSide != side || _pendingEdgeAdjustmentGeneration != generation) {
      return;
    }

    final latestDelta = _pendingEdgeAdjustmentDelta;
    _clearPendingEdgeAdjustment();
    _cacheEdgeAdjustmentValue(side, value);
    final startValue = _currentEdgeAdjustmentValue(side);
    if (startValue == null) {
      _finishEdgeAdjustment(suppressTap: false);
      return;
    }
    _startEdgeAdjustment(side, latestDelta, startValue: startValue);
  }

  void _clearPendingEdgeAdjustment() {
    _pendingEdgeAdjustmentSide = null;
    _pendingEdgeAdjustmentDelta = 0.0;
    _pendingEdgeAdjustmentGeneration = null;
  }

  void _startEdgeAdjustment(MobileEdgeAdjustmentSide side, double deltaFraction, {required double startValue}) {
    _suppressTouchTaps();
    if (_isLongPressing) _handleLongPressCancel();
    _edgeAdjustmentIndicatorHideTimer?.cancel();
    _edgeAdjustmentIndicatorClearTimer?.cancel();
    _edgeAdjustmentWasActive = true;
    _edgeAdjustmentStartValue = startValue;
    _lastEdgeAdjustmentWriteAt = null;
    _lastEdgeAdjustmentWriteValue = null;
    widget.chromeController.cancelAutoHide();
    _updateEdgeAdjustment(side, deltaFraction, forceWrite: true);
  }

  void _updateEdgeAdjustment(MobileEdgeAdjustmentSide side, double deltaFraction, {bool forceWrite = false}) {
    final startValue = _edgeAdjustmentStartValue ?? _currentEdgeAdjustmentValue(side);
    if (startValue == null) return;
    final value = (startValue + deltaFraction).clamp(0.0, 1.0).toDouble();
    final indicator = _edgeAdjustmentIndicator.value;
    if (!indicator.visible || indicator.side != side || indicator.value != value) {
      _edgeAdjustmentIndicator.value = (visible: true, side: side, value: value);
    }
    _writeEdgeAdjustment(side, value, force: forceWrite);
  }

  double? _currentEdgeAdjustmentValue(MobileEdgeAdjustmentSide side) {
    return switch (side) {
      MobileEdgeAdjustmentSide.left => _lastKnownBrightness,
      MobileEdgeAdjustmentSide.right => _lastKnownMediaVolume,
    };
  }

  void _writeEdgeAdjustment(MobileEdgeAdjustmentSide side, double value, {required bool force}) {
    final now = DateTime.now();
    final lastWriteAt = _lastEdgeAdjustmentWriteAt;
    final lastValue = _lastEdgeAdjustmentWriteValue;
    final valueChanged = lastValue == null || (value - lastValue).abs() >= 0.01;
    final intervalElapsed = lastWriteAt == null || now.difference(lastWriteAt) >= const Duration(milliseconds: 45);
    if (!force && (!valueChanged || !intervalElapsed)) return;

    _lastEdgeAdjustmentWriteAt = now;
    _lastEdgeAdjustmentWriteValue = value;
    if (side == MobileEdgeAdjustmentSide.left) {
      _lastKnownBrightness = value;
      unawaited(_deviceAdjustmentService.setBrightness(value));
    } else {
      _lastKnownMediaVolume = value;
      unawaited(_deviceAdjustmentService.setMediaVolume(value));
    }
  }

  void _finishEdgeAdjustment({required bool suppressTap}) {
    if (suppressTap) _suppressTouchTaps();
    _edgeAdjustmentWasActive = false;
    _edgeAdjustmentStartValue = null;
    _lastEdgeAdjustmentWriteAt = null;
    _lastEdgeAdjustmentWriteValue = null;
    _restartHideTimerForCurrentPlaybackState();
    _edgeAdjustmentIndicatorHideTimer?.cancel();
    _edgeAdjustmentIndicatorClearTimer?.cancel();
    if (_edgeAdjustmentIndicator.value.side == null) return;
    _edgeAdjustmentIndicatorHideTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final current = _edgeAdjustmentIndicator.value;
      _edgeAdjustmentIndicator.value = (visible: false, side: current.side, value: current.value);
      _edgeAdjustmentIndicatorClearTimer = Timer(const Duration(milliseconds: 220), () {
        if (!mounted) return;
        _edgeAdjustmentIndicator.value = (visible: false, side: null, value: _edgeAdjustmentIndicator.value.value);
      });
    });
  }

  void _cancelEdgeAdjustmentGesture() {
    _handleEdgeAdjustmentEvent(_edgeAdjustmentTracker.cancel());
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

  /// Handle a tap in a skip zone. Every skip costs a fresh same-direction
  /// double tap; a lone tap toggles the chrome.
  ///
  /// The badge left over from the previous skip is a readout, not an armed
  /// state — it says nothing about what the next tap does.
  ///
  /// The pending single-tap timer *is* the pairing window: while it is live the
  /// tap that started it is still unresolved, so a same-direction tap pairs with
  /// it. One deadline instead of a timer plus a `DateTime.now()` difference that
  /// a clock adjustment could stretch or collapse — and it leaves
  /// [_lastSkipTapTime] to the desktop double-click paths alone. Suppressing
  /// touch taps cancels the timer, which correctly disarms a half-finished pair.
  void _handleTapInSkipZone({required bool isForward}) {
    if (_isTouchTapSuppressed) return;

    final pairsWithPendingTap = (_singleTapTimer?.isActive ?? false) && _lastSkipTapWasForward == isForward;

    // Either way the pending tap is resolved now: paired below, or replaced by
    // this one as the start of a new pair.
    _singleTapTimer?.cancel();
    _singleTapTimer = null;

    if (pairsWithPendingTap) {
      _handleDoubleTapSkip(isForward: isForward);
      return;
    }

    _lastSkipTapWasForward = isForward;

    // No partner within the window, and this resolves as a lone tap.
    _singleTapTimer = Timer(kDoubleTapTimeout, () {
      if (mounted) {
        _toggleControls();
      }
    });
  }

  Size _sizeOf(BuildContext context) {
    final renderObject = context.findRenderObject();
    return renderObject is RenderBox ? renderObject.size : Size.zero;
  }

  /// Accumulate skip feedback. Consecutive skips in the same direction stack
  /// into one running total; a direction flip restarts the count.
  void _registerSkipFeedback({required bool isForward, required int seconds}) {
    final stacking = _showDoubleTapFeedback && _lastDoubleTapWasForward == isForward;
    _accumulatedSkipSeconds = stacking ? _accumulatedSkipSeconds + seconds : seconds;
    _showSkipFeedback(isForward: isForward);
  }

  /// Wrap an absolute live action so it takes down the badge a pending live
  /// skip raised.
  ///
  /// Live relative skips bypass [_hiddenSeek] for the parent's epoch
  /// accumulator (#1253), so the jump the reopen announces finds no pending
  /// target here and nothing retires the readout. The absolute action cancels
  /// that queued skip, so its promised total is no longer going anywhere.
  ValueChanged<int>? _liveSeekAbandoningBurst(ValueChanged<int>? onLiveSeek) {
    if (onLiveSeek == null) return null;
    return (offset) {
      _dismissSkipFeedback();
      onLiveSeek(offset);
    };
  }

  /// Wrap an action that replaces what is playing — a live channel switch, the
  /// next or previous item — so the badge goes with the timeline it described.
  ///
  /// The pending skip is cancelled by the switch itself (live keeps its offset
  /// in the parent accumulator, video re-keys on the new item), but neither
  /// route runs through [_hiddenSeek], so nothing else takes the readout down.
  VoidCallback? _abandoningBurst(VoidCallback? action) {
    if (action == null) return null;
    return () {
      // Cancel as well as hide: a held-arrow target stays armed across the
      // asynchronous switch and would otherwise debounce into a seek on the
      // outgoing player before the new item re-keys the controls. The focused
      // desktop timeline coalesces into its own accumulator, so it needs the
      // same treatment.
      _hiddenSeek.cancel();
      _desktopControlsKey.currentState?.abandonPendingSeek();
      _dismissSkipFeedback();
      action();
    };
  }

  /// Handle a completed skip-zone double tap.
  void _handleDoubleTapSkip({required bool isForward}) {
    if (!widget.canControl) return;

    // This tap supersedes any burst the keyboard/D-pad left pending, and it
    // shares the badge with it. Retire that burst first, or its abandonment —
    // triggered by this tap's own seek — would take down the readout this tap
    // is about to put up.
    _hiddenSeek.cancel();
    _registerSkipFeedback(isForward: isForward, seconds: _seekTimeSmall);

    final delta = Duration(seconds: isForward ? _seekTimeSmall : -_seekTimeSmall);
    unawaited(_seekByOffset(delta));
  }

  /// How long the skip badge stays at full opacity. 1200 ms gives time to read
  /// the value and keep skipping; Maestro builds hold it far longer because
  /// accessibility-tree queries on physical devices routinely outlast the
  /// production timeout — the same reason the chrome hide delay is extended.
  Duration get _skipFeedbackDuration => const bool.fromEnvironment('PLEZY_MAESTRO_E2E')
      ? const Duration(seconds: 30)
      : const Duration(milliseconds: 1200);

  /// Show animated visual feedback for skip gesture
  void _showSkipFeedback({required bool isForward}) {
    // Reads `tokens(context)` below, so a caller reaching here after disposal
    // would touch a defunct element rather than merely no-op.
    if (!mounted) return;
    // Cancel BOTH timers: a skip landing during the fade-out window must not
    // leave the old hide timer pending, or it kills the fresh readout and zeroes
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

    _feedbackTimer = Timer(_skipFeedbackDuration, () {
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

  /// Take the skip readout down at once, because the burst it was counting will
  /// never be committed. Fading it out would keep showing a total the player is
  /// not going to seek to; zeroing it without hiding would flash `0s`.
  void _dismissSkipFeedback() {
    _feedbackTimer?.cancel();
    _feedbackTimer = null;
    _feedbackHideTimer?.cancel();
    _feedbackHideTimer = null;
    if (!_showDoubleTapFeedback && _accumulatedSkipSeconds == 0) return;
    _setControlsState(() {
      _showDoubleTapFeedback = false;
      _doubleTapFeedbackOpacity = 0.0;
      _accumulatedSkipSeconds = 0;
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
