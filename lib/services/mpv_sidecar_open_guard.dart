import 'dart:async';

import '../mpv/mpv.dart';
import 'playback_open_outcome.dart';

enum MpvSidecarOpenOutcome { loaded, stalled, inconclusive, aborted }

/// Watches an mpv open that includes remote subtitle sidecars.
///
/// mpv discovers the primary audio/video tracks before it synchronously waits
/// for external files. Once that milestone is observed, a missing file-loaded
/// event can be attributed to the sidecar phase and recovered safely.
///
/// The signals come from the attempt's [PlaybackOpenOutcome] — including the
/// Android rule that nothing ExoPlayer reports before it hands the file to
/// mpv counts as mpv readiness — so this guard adds only the two bounded
/// waits.
class MpvSidecarOpenGuard {
  MpvSidecarOpenGuard._(this._outcome, this.discoveryTimeout, this.fileLoadedTimeout);

  final PlaybackOpenOutcome _outcome;
  final Duration discoveryTimeout;
  final Duration fileLoadedTimeout;

  static MpvSidecarOpenGuard? armIfNeeded({
    required PlaybackOpenOutcome outcome,
    required List<SubtitleTrack>? subtitles,
    Duration discoveryTimeout = const Duration(seconds: 10),
    Duration fileLoadedTimeout = const Duration(seconds: 10),
  }) {
    if (!_hasRemoteSidecar(subtitles)) return null;
    return MpvSidecarOpenGuard._(outcome, discoveryTimeout, fileLoadedTimeout);
  }

  static MpvSidecarOpenGuard armForTesting({
    required PlaybackOpenOutcome outcome,
    required Duration discoveryTimeout,
    required Duration fileLoadedTimeout,
  }) {
    return MpvSidecarOpenGuard._(outcome, discoveryTimeout, fileLoadedTimeout);
  }

  Future<MpvSidecarOpenOutcome> wait() async {
    final discoveryClock = Stopwatch()..start();
    try {
      if (_outcome.startsOnAndroidExoPlayer) {
        final androidOutcome = await _waitForAndroidBackendDecision();
        if (androidOutcome != null) return androidOutcome;
      }
      final remainingDiscoveryTime = discoveryTimeout - discoveryClock.elapsed;
      if (remainingDiscoveryTime <= Duration.zero) return MpvSidecarOpenOutcome.inconclusive;
      return await _waitForMpvLoad(remainingDiscoveryTime);
    } finally {
      discoveryClock.stop();
    }
  }

  /// ExoPlayer rendering the file settles the open; a backend switch hands
  /// the remaining discovery budget to the mpv wait (null).
  Future<MpvSidecarOpenOutcome?> _waitForAndroidBackendDecision() async {
    try {
      final signal = await Future.any([
        _outcome.firstFrame.then(
          (rendered) => rendered ? _MpvSidecarOpenSignal.playbackRestart : _MpvSidecarOpenSignal.terminal,
        ),
        _outcome.backendSwitched.then((_) => _MpvSidecarOpenSignal.backendSwitched),
      ]).timeout(discoveryTimeout);
      return switch (signal) {
        _MpvSidecarOpenSignal.playbackRestart => MpvSidecarOpenOutcome.loaded,
        _MpvSidecarOpenSignal.backendSwitched => null,
        _MpvSidecarOpenSignal.terminal => _terminalOutcome(),
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
        _outcome.primaryMediaReady.then(
          (ready) => ready ? _MpvSidecarOpenSignal.primaryReady : _MpvSidecarOpenSignal.terminal,
        ),
        _outcome.fileLoaded.then(
          (loaded) => loaded ? _MpvSidecarOpenSignal.fileLoaded : _MpvSidecarOpenSignal.terminal,
        ),
      ]).timeout(remainingDiscoveryTime);
    } on TimeoutException {
      return MpvSidecarOpenOutcome.inconclusive;
    }

    if (first == _MpvSidecarOpenSignal.fileLoaded) return MpvSidecarOpenOutcome.loaded;
    if (first == _MpvSidecarOpenSignal.terminal) return _terminalOutcome();

    try {
      final loaded = await _outcome.fileLoaded.timeout(fileLoadedTimeout);
      return loaded ? MpvSidecarOpenOutcome.loaded : _terminalOutcome();
    } on TimeoutException {
      return MpvSidecarOpenOutcome.stalled;
    }
  }

  /// A load that failed on its own is inconclusive about the sidecar; an
  /// aborted or disposed open has no verdict to give.
  MpvSidecarOpenOutcome _terminalOutcome() =>
      _outcome.isAborted ? MpvSidecarOpenOutcome.aborted : MpvSidecarOpenOutcome.inconclusive;

  static bool _hasRemoteSidecar(List<SubtitleTrack>? subtitles) {
    for (final subtitle in subtitles ?? const <SubtitleTrack>[]) {
      final uri = Uri.tryParse(subtitle.uri ?? '');
      if (uri?.scheme == 'http' || uri?.scheme == 'https') return true;
    }
    return false;
  }
}

enum _MpvSidecarOpenSignal { primaryReady, fileLoaded, playbackRestart, backendSwitched, terminal }
