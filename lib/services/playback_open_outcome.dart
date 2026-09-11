import 'dart:async';

import '../mpv/mpv.dart';
import '../mpv/player/platform/player_android.dart';
import '../utils/app_logger.dart';

/// Whose load-scoped signals describe the file one playback attempt opens.
enum _OpenSignalSource {
  /// mpv everywhere, including Android once its fallback core owns the file.
  mpv,

  /// Android ExoPlayer, which may hand the file to mpv mid-open
  /// (`backend-switched`) and restart the load from scratch there.
  androidExoPlayer,
}

/// The single owner of one playback attempt's open result.
///
/// [Player.open] resolves as soon as the load is dispatched; the backend
/// reports success (`file-loaded`, `playback-restart`) or failure (`end-file
/// reason=error`) later, as events. Every startup waiter — the Android mpv
/// frame-rate startup gate, post-open external-subtitle readiness, the
/// sidecar open guard — derives from this object, so a failed, aborted, or
/// disposed open settles all of them at once instead of each dying with a
/// private timeout or a `Stream.first` that only errors once the player
/// closes its controllers.
///
/// Arm before [Player.open] so a synchronously fast backend cannot outrun the
/// subscriptions. Only signals for the file this attempt loads count: mpv's
/// `start-file` after arming delimits them, and on Android ExoPlayer only a
/// first frame after its media-item transition is conclusive — an `end-file`
/// before [backendSwitched] is not, because the fallback core may still load
/// the file. Such a terminal ExoPlayer failure reaches this object through
/// the screen's error handler and [abort].
///
/// Every future resolves `true` on its event and `false` — never throws —
/// once the load failed, [abort] ran, or the player's streams closed. The
/// optional deadline counts from the backend's load start and aborts a
/// backend that neither loads, fails, nor dies.
class PlaybackOpenOutcome {
  PlaybackOpenOutcome._(Player player, this._source, this._deadline) {
    final streams = player.streams;
    _subscriptions.add(streams.fileStarted.listen((_) => _onFileStarted(), onDone: _onStreamsClosed));
    _subscriptions.add(streams.primaryMediaReady.listen((_) => _onPrimaryMediaReady(), onDone: _onStreamsClosed));
    _subscriptions.add(streams.fileLoaded.listen((_) => _onFileLoaded(), onDone: _onStreamsClosed));
    _subscriptions.add(streams.playbackRestart.listen((_) => _onPlaybackRestart(), onDone: _onStreamsClosed));
    _subscriptions.add(streams.fileLoadFailed.listen((_) => _onFileLoadFailed(), onDone: _onStreamsClosed));
    if (_source == _OpenSignalSource.androidExoPlayer) {
      _subscriptions.add(streams.backendSwitched.listen((_) => _onBackendSwitched(), onDone: _onStreamsClosed));
    }
    // A stream that completes during listen has already settled this object.
    if (isSettled) _release();
  }

  /// Arms for [player]'s next [Player.open]. [deadline] counts from the
  /// backend's load start; null waits until the backend or the caller
  /// settles the open.
  static PlaybackOpenOutcome arm(Player player, {Duration? deadline}) {
    final source = switch (player) {
      PlayerAndroid(usingMpvFallback: false) => _OpenSignalSource.androidExoPlayer,
      _ => _OpenSignalSource.mpv,
    };
    return PlaybackOpenOutcome._(player, source, deadline);
  }

  static PlaybackOpenOutcome armForTesting(Player player, {bool startsOnAndroidExoPlayer = false, Duration? deadline}) {
    return PlaybackOpenOutcome._(
      player,
      startsOnAndroidExoPlayer ? _OpenSignalSource.androidExoPlayer : _OpenSignalSource.mpv,
      deadline,
    );
  }

  final _OpenSignalSource _source;
  final Duration? _deadline;
  final List<StreamSubscription<void>> _subscriptions = [];
  final Completer<bool> _primaryMediaReady = Completer<bool>();
  final Completer<bool> _fileLoaded = Completer<bool>();
  final Completer<bool> _firstFrame = Completer<bool>();
  final Completer<void> _backendSwitched = Completer<void>();
  Timer? _deadlineTimer;

  /// Whether the backend in charge has started this attempt's file since
  /// arming; readiness and failure signals before that belong to whatever
  /// the player was doing previously.
  bool _loadStarted = false;
  bool _failed = false;
  String? _abortReason;

  /// mpv discovered a non-external audio or video track for the file. Fires
  /// before remote subtitle sidecars finish opening, unlike [fileLoaded].
  Future<bool> get primaryMediaReady => _primaryMediaReady.future;

  /// The backend that will play the file has loaded it.
  Future<bool> get fileLoaded => _fileLoaded.future;

  /// The backend rendered the file's first frame.
  Future<bool> get firstFrame => _firstFrame.future;

  /// Completes once Android ExoPlayer handed the load to the mpv fallback
  /// core. Never completes otherwise.
  Future<void> get backendSwitched => _backendSwitched.future;

  bool get startsOnAndroidExoPlayer => _source == _OpenSignalSource.androidExoPlayer;

  /// Whether every future has resolved. A first frame settles all of them;
  /// failure, [abort], and a closed player settle whatever is still pending.
  bool get isSettled => _firstFrame.isCompleted;

  /// The load itself failed (`end-file reason=error` for this attempt's file).
  bool get failed => _failed;

  bool get isAborted => _abortReason != null;

  String? get abortReason => _abortReason;

  /// Settles every pending future with `false` and releases the player
  /// subscriptions. Idempotent; the first terminal signal wins, so aborting a
  /// settled open changes nothing.
  void abort(String reason) {
    if (isSettled) return;
    _abortReason = reason;
    appLogger.d('Playback open aborted: $reason');
    _settlePending(false);
    _release();
  }

  bool get _mpvSignalsActive => _source == _OpenSignalSource.mpv || _backendSwitched.isCompleted;

  void _onFileStarted() {
    if (!_mpvSignalsActive) return;
    _loadStarted = true;
    _restartDeadline();
  }

  void _onPrimaryMediaReady() {
    if (_loadStarted && _mpvSignalsActive) _complete(_primaryMediaReady, true);
  }

  void _onFileLoaded() {
    if (!_mpvSignalsActive) {
      // ExoPlayer's media-item transition: the file is this attempt's, but the
      // format decision — and with it the backend — is still open.
      _loadStarted = true;
      _restartDeadline();
      return;
    }
    if (!_loadStarted) return;
    _complete(_primaryMediaReady, true);
    _complete(_fileLoaded, true);
  }

  void _onPlaybackRestart() {
    if (!_loadStarted) return;
    _complete(_primaryMediaReady, true);
    _complete(_fileLoaded, true);
    _complete(_firstFrame, true);
    _release();
  }

  void _onFileLoadFailed() {
    if (!_loadStarted || !_mpvSignalsActive || isSettled) return;
    _failed = true;
    _settlePending(false);
    _release();
  }

  void _onBackendSwitched() {
    if (_backendSwitched.isCompleted) return;
    // mpv restarts the load: its own start-file re-delimits the signals.
    _loadStarted = false;
    _backendSwitched.complete();
  }

  void _onStreamsClosed() => abort('player streams closed');

  void _restartDeadline() {
    final deadline = _deadline;
    if (deadline == null) return;
    _deadlineTimer?.cancel();
    _deadlineTimer = Timer(deadline, () => abort('no first frame within ${deadline.inSeconds}s of load start'));
  }

  void _settlePending(bool value) {
    _complete(_primaryMediaReady, value);
    _complete(_fileLoaded, value);
    _complete(_firstFrame, value);
  }

  static void _complete(Completer<bool> completer, bool value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  void _release() {
    _deadlineTimer?.cancel();
    _deadlineTimer = null;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }
}
