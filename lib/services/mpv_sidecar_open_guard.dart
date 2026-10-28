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
/// The signals come from the attempt's [PlaybackOpenOutcome], so this guard
/// adds only the two bounded waits.
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
    final _MpvSidecarOpenSignal first;
    try {
      first = await Future.any([
        _outcome.primaryMediaReady.then(
          (ready) => ready ? _MpvSidecarOpenSignal.primaryReady : _MpvSidecarOpenSignal.terminal,
        ),
        _outcome.fileLoaded.then(
          (loaded) => loaded ? _MpvSidecarOpenSignal.fileLoaded : _MpvSidecarOpenSignal.terminal,
        ),
      ]).timeout(discoveryTimeout);
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

enum _MpvSidecarOpenSignal { primaryReady, fileLoaded, terminal }
