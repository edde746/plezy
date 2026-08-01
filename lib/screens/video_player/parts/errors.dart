part of '../../video_player_screen.dart';

extension _VideoPlayerErrorMethods on VideoPlayerScreenState {
  String _safePlaybackErrorMessage(Object error) {
    final raw = error.toString();
    final redacted = LogRedactionManager.redact(raw);
    if (raw.contains('No client registered')) {
      return t.messages.errorLoading(error: 'Server is unavailable for the active profile');
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
      // The bounded retry operation owns errors raised while applying/opening
      // its replacement stream. Do not let the same error close the route.
      case PlaybackFailureAction.ignore:
        return;
      case PlaybackFailureAction.liveRetry:
        _live.fallbackLevel++;
        _live.retrying = true;
        appLogger.w('Live stream failed, retrying with fallback level ${_live.fallbackLevel}');
        unawaited(_retryLiveStream());
      case PlaybackFailureAction.liveInterrupted:
        showGlobalErrorSnackBar(t.messages.liveStreamInterrupted);
      case PlaybackFailureAction.fatal:
        _hasFatalPlaybackError = true;
        _progressTracker?.stopTracking();
        showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? err.message));
        unawaited(_handleBackButton());
    }
  }

  void _onPlayerLog(PlayerLog log) {
    final status = PlayerError.httpStatusFromLog(log.text);
    if (status != null && fatalPlaybackHttpStatuses.contains(status)) _fatalHttpStatuses.add(status);
    if (log.level == PlayerLogLevel.error || log.level == PlayerLogLevel.fatal) {
      appLogger.e('[Player LOG ERROR] [${log.prefix}] ${log.text}');
      _lastLogError = _redactPlayerError(log.text.trim());
    }
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
