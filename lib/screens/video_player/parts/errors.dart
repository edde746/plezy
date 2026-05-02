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

    // Fatal, unrecoverable until server-side fix — show modal instead of a snackbar.
    if (err.cause == PlayerError.serverHttp500 || _sawServer500) {
      _showServerLimitDialog();
      return;
    }

    // Live TV: retry with progressively degraded stream settings
    // (mirrors Plex web client fallback chain).
    if (widget.isLive && _liveStreamFallbackLevel < 2 && !_isRetryingLiveStream) {
      _liveStreamFallbackLevel++;
      _isRetryingLiveStream = true;
      appLogger.w('Live stream failed, retrying with fallback level $_liveStreamFallbackLevel');
      _retryLiveStream().whenComplete(() => _isRetryingLiveStream = false);
      return;
    }

    showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? err.message));
    _handleBackButton();
  }

  void _onPlayerLog(PlayerLog log) {
    if (!_sawServer500 && VideoPlayerScreenState._server500Pattern.hasMatch(log.text)) {
      _sawServer500 = true;
    }
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
