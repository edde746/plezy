import 'dart:async';

import '../mpv/mpv.dart';
import '../mpv/player/platform/player_android.dart';
import '../mpv/player/player_native.dart';

enum MpvSidecarOpenOutcome { loaded, stalled, inconclusive, aborted }

enum _MpvSidecarOpenMode { directMpv, androidFallback }

/// Watches an mpv open that includes remote subtitle sidecars.
///
/// mpv discovers the primary audio/video tracks before it synchronously waits
/// for external files. Once that milestone is observed, a missing file-loaded
/// event can be attributed to the sidecar phase and recovered safely.
class MpvSidecarOpenGuard {
  final Player player;
  final Duration discoveryTimeout;
  final Duration fileLoadedTimeout;
  final _MpvSidecarOpenMode _mode;

  final Completer<void> _primaryReady = Completer<void>();
  final Completer<void> _fileLoaded = Completer<void>();
  final Completer<void> _playbackRestart = Completer<void>();
  final Completer<void> _backendSwitched = Completer<void>();
  final Completer<void> _fileLoadFailed = Completer<void>();
  final Completer<void> _aborted = Completer<void>();
  StreamSubscription<void>? _fileStartedSubscription;
  StreamSubscription<void>? _primaryReadySubscription;
  StreamSubscription<void>? _fileLoadedSubscription;
  StreamSubscription<void>? _fileLoadFailedSubscription;
  StreamSubscription<void>? _playbackRestartSubscription;
  StreamSubscription<void>? _backendSwitchedSubscription;
  bool _mpvLoadStarted = false;

  MpvSidecarOpenGuard._(this.player, this._mode, this.discoveryTimeout, this.fileLoadedTimeout) {
    _fileStartedSubscription = player.streams.fileStarted.listen((_) {
      if (_mpvSignalsAreActive) _mpvLoadStarted = true;
    });
    _primaryReadySubscription = player.streams.primaryMediaReady.listen((_) {
      if (_mpvLoadStarted && !_primaryReady.isCompleted) _primaryReady.complete();
    }, onDone: _abort);
    _fileLoadedSubscription = player.streams.fileLoaded.listen((_) {
      if (_mpvLoadStarted && !_fileLoaded.isCompleted) _fileLoaded.complete();
    }, onDone: _abort);
    _fileLoadFailedSubscription = player.streams.fileLoadFailed.listen((_) {
      if (_mpvLoadStarted && !_fileLoadFailed.isCompleted) {
        _fileLoadFailed.complete();
      }
    });
    if (_mode == _MpvSidecarOpenMode.androidFallback) {
      _playbackRestartSubscription = player.streams.playbackRestart.listen((_) {
        if (!_backendSwitched.isCompleted && !_playbackRestart.isCompleted) {
          _playbackRestart.complete();
        }
      }, onDone: _abort);
      _backendSwitchedSubscription = player.streams.backendSwitched.listen((_) {
        if (!_backendSwitched.isCompleted) _backendSwitched.complete();
      }, onDone: _abort);
    }
  }

  static MpvSidecarOpenGuard? armIfNeeded({
    required Player player,
    required List<SubtitleTrack>? subtitles,
    Duration discoveryTimeout = const Duration(seconds: 10),
    Duration fileLoadedTimeout = const Duration(seconds: 10),
  }) {
    if (!_hasRemoteSidecar(subtitles)) return null;
    final mode = switch (player) {
      PlayerNative() => _MpvSidecarOpenMode.directMpv,
      PlayerAndroid(usingMpvFallback: true) => _MpvSidecarOpenMode.directMpv,
      PlayerAndroid() => _MpvSidecarOpenMode.androidFallback,
      _ => null,
    };
    if (mode == null) return null;
    return MpvSidecarOpenGuard._(player, mode, discoveryTimeout, fileLoadedTimeout);
  }

  static MpvSidecarOpenGuard armForTesting({
    required Player player,
    required Duration discoveryTimeout,
    required Duration fileLoadedTimeout,
    bool startsOnAndroidExoPlayer = false,
  }) {
    return MpvSidecarOpenGuard._(
      player,
      startsOnAndroidExoPlayer ? _MpvSidecarOpenMode.androidFallback : _MpvSidecarOpenMode.directMpv,
      discoveryTimeout,
      fileLoadedTimeout,
    );
  }

  Future<MpvSidecarOpenOutcome> wait() async {
    final discoveryClock = Stopwatch()..start();
    try {
      if (_mode == _MpvSidecarOpenMode.androidFallback) {
        final androidOutcome = await _waitForAndroidBackendDecision();
        if (androidOutcome != null) return androidOutcome;
      }
      final remainingDiscoveryTime = discoveryTimeout - discoveryClock.elapsed;
      if (remainingDiscoveryTime <= Duration.zero) return MpvSidecarOpenOutcome.inconclusive;
      return await _waitForMpvLoad(remainingDiscoveryTime);
    } finally {
      discoveryClock.stop();
      await dispose();
    }
  }

  Future<MpvSidecarOpenOutcome?> _waitForAndroidBackendDecision() async {
    try {
      final signal = await Future.any([
        _playbackRestart.future.then((_) => _MpvSidecarOpenSignal.playbackRestart),
        _backendSwitched.future.then((_) => _MpvSidecarOpenSignal.backendSwitched),
        _aborted.future.then((_) => _MpvSidecarOpenSignal.aborted),
      ]).timeout(discoveryTimeout);
      return switch (signal) {
        _MpvSidecarOpenSignal.playbackRestart => MpvSidecarOpenOutcome.loaded,
        _MpvSidecarOpenSignal.backendSwitched => null,
        _MpvSidecarOpenSignal.aborted => MpvSidecarOpenOutcome.aborted,
        _ => throw StateError('Unexpected Android sidecar-open signal: $signal'),
      };
    } on TimeoutException {
      return MpvSidecarOpenOutcome.inconclusive;
    }
  }

  Future<MpvSidecarOpenOutcome> _waitForMpvLoad(Duration remainingDiscoveryTime) async {
    final _MpvSidecarOpenSignal first;
    try {
      first = await Future.any([
        _primaryReady.future.then((_) => _MpvSidecarOpenSignal.primaryReady),
        _fileLoaded.future.then((_) => _MpvSidecarOpenSignal.fileLoaded),
        _fileLoadFailed.future.then((_) => _MpvSidecarOpenSignal.fileLoadFailed),
        _aborted.future.then((_) => _MpvSidecarOpenSignal.aborted),
      ]).timeout(remainingDiscoveryTime);
    } on TimeoutException {
      return MpvSidecarOpenOutcome.inconclusive;
    }

    if (first == _MpvSidecarOpenSignal.fileLoaded) return MpvSidecarOpenOutcome.loaded;
    if (first == _MpvSidecarOpenSignal.aborted) return MpvSidecarOpenOutcome.aborted;
    if (first == _MpvSidecarOpenSignal.fileLoadFailed) return MpvSidecarOpenOutcome.inconclusive;

    try {
      final afterPrimary = await Future.any([
        _fileLoaded.future.then((_) => _MpvSidecarOpenSignal.fileLoaded),
        _fileLoadFailed.future.then((_) => _MpvSidecarOpenSignal.fileLoadFailed),
        _aborted.future.then((_) => _MpvSidecarOpenSignal.aborted),
      ]).timeout(fileLoadedTimeout);
      return switch (afterPrimary) {
        _MpvSidecarOpenSignal.fileLoaded => MpvSidecarOpenOutcome.loaded,
        _MpvSidecarOpenSignal.fileLoadFailed => MpvSidecarOpenOutcome.inconclusive,
        _MpvSidecarOpenSignal.aborted => MpvSidecarOpenOutcome.aborted,
        _ => throw StateError('Unexpected post-discovery sidecar-open signal: $afterPrimary'),
      };
    } on TimeoutException {
      return MpvSidecarOpenOutcome.stalled;
    }
  }

  Future<void> dispose() async {
    await Future.wait(<Future<void>>[
      ?_fileStartedSubscription?.cancel(),
      ?_primaryReadySubscription?.cancel(),
      ?_fileLoadedSubscription?.cancel(),
      ?_fileLoadFailedSubscription?.cancel(),
      ?_playbackRestartSubscription?.cancel(),
      ?_backendSwitchedSubscription?.cancel(),
    ]);
    _fileStartedSubscription = null;
    _primaryReadySubscription = null;
    _fileLoadedSubscription = null;
    _fileLoadFailedSubscription = null;
    _playbackRestartSubscription = null;
    _backendSwitchedSubscription = null;
  }

  void _abort() {
    if (!_aborted.isCompleted) _aborted.complete();
  }

  bool get _mpvSignalsAreActive => _mode == _MpvSidecarOpenMode.directMpv || _backendSwitched.isCompleted;

  static bool _hasRemoteSidecar(List<SubtitleTrack>? subtitles) {
    for (final subtitle in subtitles ?? const <SubtitleTrack>[]) {
      final uri = Uri.tryParse(subtitle.uri ?? '');
      if (uri?.scheme == 'http' || uri?.scheme == 'https') return true;
    }
    return false;
  }
}

enum _MpvSidecarOpenSignal { primaryReady, fileLoaded, playbackRestart, backendSwitched, fileLoadFailed, aborted }
