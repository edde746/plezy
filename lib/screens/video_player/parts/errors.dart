part of '../../video_player_screen.dart';

extension _VideoPlayerErrorMethods on VideoPlayerScreenState {
  String _safePlaybackErrorMessage(Object error) {
    // The native core failed to start; the sentinel carries no prose because
    // the UI owns the wording — show the localized copy directly.
    if (error is PlayerInitializationException) {
      return t.messages.playbackFailed;
    }
    final raw = error.toString();
    final redacted = LogRedactionManager.redact(raw);
    if (raw.contains('No client registered')) {
      return t.messages.errorLoading(error: t.messages.serverUnavailableForProfile);
    }
    return t.messages.errorLoading(error: redacted);
  }

  void _onPlayerError(PlayerError err) {
    appLogger.e('[Player ERROR] ${err.message}');
    if (!mounted || _isExiting.value) return;
    // The open already failed and its verdict is on screen: every further
    // error is the same dead load (a playlist walk, a retrying reconnect)
    // reporting again, and re-running the policy per event is what turned a
    // failed HLS open into an ANR. A new open resets the latch.
    if (_hasFatalPlaybackError) return;

    // A sidecar subtitle fetch can also log a status, but it never raises the
    // end-file error this handler is wired to, so a latched status belongs to
    // the primary media open.
    final action = resolvePlaybackFailureAction(
      cause: err.cause,
      fatalHttpStatuses: _fatalHttpStatuses,
      isLive: widget.isLive,
      liveRetrying: _live.retrying,
      liveFallbackLevel: _live.fallbackLevel,
      liveRetryFailed: _live.retryFailed,
    );

    switch (action) {
      // Both dialogs are unrecoverable until the server side changes, so they
      // replace the snackbar rather than joining it.
      case PlaybackFailureAction.serverLimitDialog:
        _latchFatalPlaybackError(action);
        unawaited(_showServerLimitDialog());
      case PlaybackFailureAction.mediaUnreadableDialog:
        _latchFatalPlaybackError(action);
        unawaited(_showMediaUnreadableDialog());
      case PlaybackFailureAction.serverBusyDialog:
        _latchFatalPlaybackError(action);
        unawaited(_showServerBusyDialog());
      // The bounded retry operation owns errors raised while applying/opening
      // its replacement stream. Do not let the same error close the route.
      case PlaybackFailureAction.ignore:
        return;
      case PlaybackFailureAction.liveRetry:
        _beginLiveLadderRetry();
      case PlaybackFailureAction.liveInterrupted:
        showGlobalErrorSnackBar(t.messages.liveStreamInterrupted);
      case PlaybackFailureAction.fatal:
        _latchFatalPlaybackError(action, cause: err.cause);
        // A failed core start carries only diagnostic text; _lastLogError is
        // raw mpv/ffmpeg output, so neither is fit to show bare — use the
        // localized copy, with the redacted diagnostic as its detail. A timed
        // out open raised nothing itself, but the last error line mpv logged
        // on the way to the stall (a chain that failed, a stream that never
        // produced) is the only diagnosis there is, so it rides along too.
        final lastLogError = _lastLogError;
        final message = switch (err.cause) {
          PlayerError.playerInitFailed => t.messages.playbackFailed,
          PlayerError.openTimedOut =>
            lastLogError == null ? t.messages.playbackFailed : t.messages.playbackFailedDetail(error: lastLogError),
          PlayerError.audioOutputFailed => t.messages.audioOutputFailed,
          _ => t.messages.playbackFailedDetail(error: _redactPlayerError(lastLogError ?? err.message)),
        };
        // Live TV has no in-place reload to retry through: its own start
        // flow leaves the route on failure, so a dead live session does too.
        if (widget.isLive) {
          showGlobalErrorSnackBar(message);
          unawaited(_handleBackButton());
          return;
        }
        _presentPlaybackFailure(message);
    }
  }

  /// A terminal player error: the attempt is no longer current, progress
  /// reporting stops, every waiter armed for its open collapses, and the
  /// backend is told to stop — the error UI is the only thing left running
  /// for it. The stop is not optional: on a failed HLS open mpv falls back to
  /// its playlist parser and walks the manifest's entries, each failing in
  /// turn (46 end-file errors in 4 s on a Fire TV), and with the route no
  /// longer popping nothing else halts that walk; a stalled load is likewise
  /// still retrying and a late success must not play behind the failure
  /// view. Further errors from the same dead open are ignored by
  /// [_onPlayerError] until a new open resets the latch. The launch receipt
  /// goes terminal here, not on exit: the route may never close (an
  /// agent-launched player has nothing to pop to), and a caller polling the
  /// receipt must not read a failed open as `opening` or, after Back, as a
  /// user stop.
  void _latchFatalPlaybackError(PlaybackFailureAction action, {String? cause}) {
    _hasFatalPlaybackError = true;
    _progressTracker?.stopTracking();
    _abortCurrentOpen('player error: ${action.name}');
    final currentPlayer = player;
    if (currentPlayer != null) {
      unawaited(
        currentPlayer.stop().catchError((Object e, StackTrace st) {
          appLogger.w('Failed to stop the failed load', error: e, stackTrace: st);
        }),
      );
    }
    if (_ownsLaunchPlayback() && widget.launchObserver?.failure == null) {
      widget.launchObserver?.mark(
        'failed',
        failure: switch (action) {
          PlaybackFailureAction.serverLimitDialog => 'serverLimit',
          PlaybackFailureAction.mediaUnreadableDialog => 'mediaUnreadable',
          PlaybackFailureAction.serverBusyDialog => 'serverBusy',
          _ => cause == PlayerError.audioOutputFailed ? 'audioOutputFailed' : 'playbackFailed',
        },
      );
    }
  }

  /// Raise the persistent failure surface over the player. It stays until
  /// Retry re-runs the open or Back leaves; a snackbar is neither focusable
  /// nor on a remote's path, and it is gone in seconds. The spinner is
  /// forced down so it cannot sit over the view, and Retry takes focus once
  /// the view has built (see [_initializationErrorFocusNode]). The backend's
  /// end-file verdict always lands; a thrown open only fills an empty view,
  /// since the verdict that preceded it is the more specific of the two.
  void _presentPlaybackFailure(String message) {
    if (!mounted || _shuttingDown) return;
    _firstFrame.forceUiReadyOnFailure();
    _setPlayerState(() {
      _playbackFailureMessage = message;
      _playbackFailureRetry = _retryFailedPlayback;
    });
    _focusFailureActionAfterBuild();
  }

  void _dismissPlaybackFailure() {
    if (_playbackFailureMessage == null) return;
    _setPlayerState(() {
      _playbackFailureMessage = null;
      _playbackFailureRetry = null;
    });
  }

  /// The button only exists after the next frame builds, so the request waits
  /// for it; see [_initializationErrorFocusNode] for why autofocus alone
  /// leaves the view with nothing focused.
  void _focusFailureActionAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _shuttingDown || (_playerInitializationError == null && _playbackFailureMessage == null)) {
        return;
      }
      if (_initializationErrorFocusNode.canRequestFocus) _initializationErrorFocusNode.requestFocus();
    });
  }

  /// The open Retry re-runs for the failure on screen. A failed in-place
  /// source switch restores the request that was playing before it — one
  /// attempt, prompted; a restore that fails too leaves the failure view up.
  /// Anything else re-runs the failed open itself, from the playhead when
  /// that open had already rendered.
  _PlaybackOpenRequest? _retryRequestForFailure() {
    final current = _currentOpenRequest;
    if (current == null) return null;
    final working = _workingOpenRequest;
    if (working != null && working.metadata.globalKey == current.metadata.globalKey && !working.sameSourceAs(current)) {
      return working.resumingAt(current.resumePosition ?? working.resumePosition);
    }
    if (_firstFrame.rendered) return current.resumingAt(player?.state.position);
    return current;
  }

  void _retryFailedPlayback() {
    final request = _retryRequestForFailure();
    if (request == null || player == null) {
      // Nothing was ever dispatched (or the core is gone): start over.
      _retryPlayerInitialization();
      return;
    }
    unawaited(_reopenAfterFailure(request));
  }

  Future<void> _reopenAfterFailure(_PlaybackOpenRequest request) async {
    final outcome = await _reloadMediaInPlace(
      metadata: request.metadata,
      selectedMediaIndex: request.mediaIndex,
      selectedMediaSourceId: request.mediaSourceId,
      qualityPreset: request.qualityPreset,
      selectedAudioStreamId: request.audioStreamId,
      useCurrentAudioStreamSelection: false,
      resumePosition: request.resumePosition,
      preferredSubtitleTrackOverride: SubtitlePreference.trackOrNull(_playbackSession?.subtitleSelection.primaryTrack),
      // A failure before the open rolls the view back to the message it
      // retried from; one after it raises its own through _onPlayerError.
      showErrorUi: false,
      reason: 'retry after playback failure',
    );
    if (outcome == MediaReloadOutcome.failed && mounted && _playbackFailureMessage == null) {
      _presentPlaybackFailure(t.messages.playbackFailed);
    }
  }

  void _onPlayerLog(PlayerLog log) {
    final status = PlayerError.httpStatusFromLog(log.text);
    if (status != null && fatalPlaybackHttpStatuses.contains(status)) _fatalHttpStatuses.add(status);
    // An open the server answers with 503 never fails on its own: ffmpeg's
    // reconnect loop retries 503 forever and mpv just reports buffering
    // (#1830). Bound it. Live TV stays out — its ladder owns retries there.
    // A sidecar subtitle fetch shares this log stream and could arm the
    // watchdog too, but a first frame disarms it, so that only matters when
    // the primary media is itself stuck.
    if (status == 503 && !widget.isLive && !_firstFrame.rendered && !_hasFatalPlaybackError) {
      _http503Watchdog.onOpenPhase503();
    }
    if (log.level == PlayerLogLevel.error || log.level == PlayerLogLevel.fatal) {
      appLogger.e('[Player LOG ERROR] [${log.prefix}] ${log.text}');
      _lastLogError = _redactPlayerError(log.text.trim());
    }
    // A stream mpv gives up on at open (`error_on_track`) ends the file only
    // when the other stream is gone too; otherwise the load lives on with no
    // end-file and the viewer waits out the open deadline for an error mpv
    // logged seconds earlier. Fail the open on that line instead. Same guard
    // as the deadline: a first frame or a latched error already settled this
    // open, and a superseded attempt's lines are not this open's business.
    if (_firstFrame.rendered || _hasFatalPlaybackError || !(_playbackAttempt?.isCurrent ?? false)) return;
    final cause = openFailureCauseFromLog(
      level: log.level,
      prefix: log.prefix,
      text: log.text,
      isAndroid: Platform.isAndroid,
    );
    if (cause == null) return;
    appLogger.w('mpv gave up on a stream while opening — giving up on this open');
    _onPlayerError(PlayerError(log.text.trim(), cause: cause));
  }

  /// The open-phase 503 watchdog's deadline passed with no first frame: the
  /// server is still refusing the stream. Synthesize the error the reconnect
  /// loop will never raise on its own so the normal failure policy runs.
  void _onOpenHttp503Persistent() {
    if (!mounted || _isExiting.value || _firstFrame.rendered || _hasFatalPlaybackError) return;
    appLogger.w(
      'Server kept answering the stream with HTTP 503 for '
      '${openHttp503Patience.inSeconds}s without a first frame — giving up on this open',
    );
    _onPlayerError(PlayerError(t.messages.serverBusyTitle, cause: PlayerError.serverHttp503));
  }

  /// The attempt's open deadline passed: the backend started the load and
  /// then neither loaded, failed, nor died. Its waiters are already aborted;
  /// synthesize the error the backend never raised so the failure policy
  /// runs (which stops the still-retrying load) and the viewer is not left
  /// on a spinner. Same guard as the 503 watchdog: a first frame or a
  /// latched error already settled this open.
  void _onOpenDeadlineExpired(Player currentPlayer, int generation) {
    if (!_isCurrentPlaybackGeneration(generation, currentPlayer) || _firstFrame.rendered || _hasFatalPlaybackError) {
      return;
    }
    appLogger.w(
      'No first frame within ${VideoPlayerScreenState._openDeadline.inSeconds}s of load start — giving up on this open',
    );
    _onPlayerError(PlayerError(t.messages.playbackFailed, cause: PlayerError.openTimedOut));
  }

  String _redactPlayerError(String message) => LogRedactionManager.redact(message);

  Future<void> _showServerLimitDialog() async {
    if (!mounted) return;
    await showServerLimitDialog(context);
    if (mounted) unawaited(_handleBackButton());
  }

  Future<void> _showMediaUnreadableDialog() async {
    if (!mounted) return;
    await showMediaUnreadableDialog(context);
    if (mounted) unawaited(_handleBackButton());
  }

  Future<void> _showServerBusyDialog() async {
    if (!mounted) return;
    // The reconnect loop is still running behind the modal; pause so a server
    // that recovers mid-dialog cannot start playing under it. Best-effort —
    // the route is left on dialog close either way.
    unawaited(player?.pause().catchError((_) {}));
    await showServerBusyDialog(context);
    if (mounted) unawaited(_handleBackButton());
  }

  /// Handle notification when native player switched from ExoPlayer to MPV
  Future<void> _onBackendSwitched() async {
    _playerBackendLabel = 'mpv';
    _recordLifecycleState('backend_switched', action: 'mpv_fallback');

    _toastController.show(
      Symbols.swap_horiz_rounded,
      t.messages.switchingToCompatiblePlayer,
      duration: const Duration(seconds: 2),
    );

    await _trackManager?.onBackendSwitched();
  }
}
