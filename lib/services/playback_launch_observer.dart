/// A pull-only observation seam for an explicitly requested launch. It owns no
/// player, queue, timer, or persisted state. UI navigation still completes on
/// route close; the command adapter reads the attached owner's native snapshot.
class PlaybackLaunchObserver {
  PlaybackLaunchObserver({required this._isCurrent});

  final bool Function() _isCurrent;
  bool _cancelled = false;
  String stage = 'accepted';
  String? blocker;
  String? failure;
  Map<String, dynamic> Function()? _read;
  bool Function()? _ownsPlayback;
  int? _terminalPositionMs;
  int? _terminalDurationMs;

  bool get isCurrent => !_cancelled && _isCurrent();

  /// Receipt status can outlive its native owner (failure/completion), and
  /// observation can end without cancelling the screen's lifetime fence.
  bool get ownsPlayback => isCurrent && (_ownsPlayback?.call() ?? false);

  void attach(Map<String, dynamic> Function() read, {bool Function()? ownsPlayback}) {
    if (!isCurrent) return;
    _read = read;
    _ownsPlayback = ownsPlayback;
  }

  void mark(String value, {String? blocker, String? failure, int? positionMs, int? durationMs}) {
    if (!isCurrent) return;
    stage = value;
    this.blocker = blocker;
    this.failure = failure;
    _terminalPositionMs = positionMs;
    _terminalDurationMs = durationMs;
  }

  Map<String, dynamic> snapshot() {
    if (!isCurrent) return const {'stage': 'cancelled', 'playing': false, 'buffering': false};
    if (stage != 'completed' &&
        stage != 'failed' &&
        stage != 'cancelled' &&
        stage != 'blocked' &&
        stage != 'externalLaunched') {
      final observed = _read?.call();
      if (observed != null) return observed;
    }
    return {
      'stage': stage,
      'playing': false,
      'buffering': false,
      if (_terminalPositionMs != null) 'positionMs': _terminalPositionMs,
      if (_terminalDurationMs != null) 'durationMs': _terminalDurationMs,
      if (blocker != null) 'blocker': blocker,
      if (failure != null) 'failure': {'code': failure},
    };
  }

  void detach({String stage = 'cancelled'}) {
    _read = null;
    _ownsPlayback = null;
    if (this.stage != 'completed' &&
        this.stage != 'failed' &&
        this.stage != 'blocked' &&
        this.stage != 'externalLaunched') {
      this.stage = stage;
    }
  }

  /// Invalidates pending opens and detaches observation, without stopping a
  /// player that may now belong to the UI or a different profile.
  void cancel() {
    _cancelled = true;
    _read = null;
    _ownsPlayback = null;
  }
}
