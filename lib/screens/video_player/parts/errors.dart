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
        _hasFatalPlaybackError = true;
        _progressTracker?.stopTracking();
        unawaited(_showServerLimitDialog());
      case PlaybackFailureAction.mediaUnreadableDialog:
        _hasFatalPlaybackError = true;
        _progressTracker?.stopTracking();
        unawaited(_showMediaUnreadableDialog());
      case PlaybackFailureAction.serverBusyDialog:
        _hasFatalPlaybackError = true;
        _progressTracker?.stopTracking();
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
        _hasFatalPlaybackError = true;
        _progressTracker?.stopTracking();
        // A failed core start carries only diagnostic text; _lastLogError is
        // raw mpv/ffmpeg output, so neither is fit to show — use the
        // localized copy instead.
        showGlobalErrorSnackBar(
          err.cause == PlayerError.playerInitFailed
              ? t.messages.playbackFailed
              : _redactPlayerError(_lastLogError ?? err.message),
        );
        unawaited(_handleBackButton());
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
