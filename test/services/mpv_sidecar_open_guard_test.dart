import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/mpv_sidecar_open_guard.dart';
import 'package:plezy/services/playback_open_outcome.dart';

/// A stream that never emits and never closes, for the signals a case does
/// not drive: the open outcome treats any closed player stream as the player
/// being gone.
Stream<T> _idle<T>() => StreamController<T>.broadcast().stream;

class _StreamPlayer implements Player {
  @override
  final PlayerStreams streams;

  _StreamPlayer({
    Stream<void>? fileStarted,
    required Stream<void> primaryMediaReady,
    required Stream<void> fileLoaded,
    Stream<void>? fileLoadFailed,
    Stream<void>? playbackRestart,
    Stream<void>? backendSwitched,
    Stream<PlayerError> error = const Stream.empty(),
  }) : streams = PlayerStreams(
         playing: const Stream.empty(),
         completed: const Stream.empty(),
         buffering: const Stream.empty(),
         position: const Stream.empty(),
         duration: const Stream.empty(),
         seekable: const Stream.empty(),
         buffer: const Stream.empty(),
         volume: const Stream.empty(),
         rate: const Stream.empty(),
         tracks: const Stream.empty(),
         track: const Stream.empty(),
         log: const Stream.empty(),
         error: error,
         audioDevice: const Stream.empty(),
         audioDevices: const Stream.empty(),
         bufferRanges: const Stream.empty(),
         playbackRestart: playbackRestart ?? _idle(),
         fileStarted: fileStarted ?? _idle(),
         fileLoaded: fileLoaded,
         fileLoadFailed: fileLoadFailed ?? _idle(),
         primaryMediaReady: primaryMediaReady,
         backendSwitched: backendSwitched ?? _idle(),
       );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MpvSidecarOpenGuard _arm(
  Player player, {
  required Duration discoveryTimeout,
  required Duration fileLoadedTimeout,
  bool startsOnAndroidExoPlayer = false,
}) {
  return MpvSidecarOpenGuard.armForTesting(
    outcome: PlaybackOpenOutcome.armForTesting(player, startsOnAndroidExoPlayer: startsOnAndroidExoPlayer),
    discoveryTimeout: discoveryTimeout,
    fileLoadedTimeout: fileLoadedTimeout,
  );
}

void main() {
  test('file-loaded before primary discovery completes normally', () async {
    final primary = StreamController<void>.broadcast();
    final loaded = StreamController<void>.broadcast();
    final started = StreamController<void>.broadcast();
    addTearDown(primary.close);
    addTearDown(loaded.close);
    addTearDown(started.close);
    final guard = _arm(
      _StreamPlayer(fileStarted: started.stream, primaryMediaReady: primary.stream, fileLoaded: loaded.stream),
      discoveryTimeout: const Duration(milliseconds: 20),
      fileLoadedTimeout: const Duration(milliseconds: 20),
    );

    final outcome = guard.wait();
    started.add(null);
    loaded.add(null);

    expect(await outcome, MpvSidecarOpenOutcome.loaded);
  });

  test('file-loaded after primary discovery completes normally', () async {
    final primary = StreamController<void>.broadcast();
    final loaded = StreamController<void>.broadcast();
    final started = StreamController<void>.broadcast();
    addTearDown(primary.close);
    addTearDown(loaded.close);
    addTearDown(started.close);
    final guard = _arm(
      _StreamPlayer(fileStarted: started.stream, primaryMediaReady: primary.stream, fileLoaded: loaded.stream),
      discoveryTimeout: const Duration(milliseconds: 50),
      fileLoadedTimeout: const Duration(milliseconds: 50),
    );

    final outcome = guard.wait();
    started.add(null);
    primary.add(null);
    await Future<void>.delayed(Duration.zero);
    loaded.add(null);

    expect(await outcome, MpvSidecarOpenOutcome.loaded);
  });

  test('missing file-loaded after primary discovery is classified as a sidecar stall', () async {
    final primary = StreamController<void>.broadcast();
    final loaded = StreamController<void>.broadcast();
    final started = StreamController<void>.broadcast();
    addTearDown(primary.close);
    addTearDown(loaded.close);
    addTearDown(started.close);
    final guard = _arm(
      _StreamPlayer(fileStarted: started.stream, primaryMediaReady: primary.stream, fileLoaded: loaded.stream),
      discoveryTimeout: const Duration(milliseconds: 50),
      fileLoadedTimeout: const Duration(milliseconds: 10),
    );

    final outcome = guard.wait();
    started.add(null);
    primary.add(null);

    expect(await outcome, MpvSidecarOpenOutcome.stalled);
  });

  test('unrelated player errors do not suppress sidecar-stall recovery', () async {
    final primary = StreamController<void>.broadcast();
    final loaded = StreamController<void>.broadcast();
    final started = StreamController<void>.broadcast();
    final errors = StreamController<PlayerError>.broadcast();
    addTearDown(primary.close);
    addTearDown(loaded.close);
    addTearDown(started.close);
    addTearDown(errors.close);
    final guard = _arm(
      _StreamPlayer(
        fileStarted: started.stream,
        primaryMediaReady: primary.stream,
        fileLoaded: loaded.stream,
        error: errors.stream,
      ),
      discoveryTimeout: const Duration(milliseconds: 50),
      fileLoadedTimeout: const Duration(milliseconds: 10),
    );

    final outcome = guard.wait();
    started.add(null);
    primary.add(null);
    errors.add(const PlayerError('setVisible failed'));

    expect(await outcome, MpvSidecarOpenOutcome.stalled);
  });

  test('load-scoped end-file error suppresses sidecar-stall recovery', () async {
    final started = StreamController<void>.broadcast();
    final primary = StreamController<void>.broadcast();
    final loaded = StreamController<void>.broadcast();
    final failed = StreamController<void>.broadcast();
    addTearDown(started.close);
    addTearDown(primary.close);
    addTearDown(loaded.close);
    addTearDown(failed.close);
    final guard = _arm(
      _StreamPlayer(
        fileStarted: started.stream,
        primaryMediaReady: primary.stream,
        fileLoaded: loaded.stream,
        fileLoadFailed: failed.stream,
      ),
      discoveryTimeout: const Duration(milliseconds: 50),
      fileLoadedTimeout: const Duration(milliseconds: 10),
    );

    final outcome = guard.wait();
    started.add(null);
    primary.add(null);
    failed.add(null);

    expect(await outcome, MpvSidecarOpenOutcome.inconclusive);
  });

  test('missing primary discovery times out without claiming a sidecar stall', () async {
    final primary = StreamController<void>.broadcast();
    final loaded = StreamController<void>.broadcast();
    addTearDown(primary.close);
    addTearDown(loaded.close);
    final guard = _arm(
      _StreamPlayer(primaryMediaReady: primary.stream, fileLoaded: loaded.stream),
      discoveryTimeout: const Duration(milliseconds: 10),
      fileLoadedTimeout: const Duration(milliseconds: 10),
    );

    expect(await guard.wait(), MpvSidecarOpenOutcome.inconclusive);
  });

  test('Android ExoPlayer success completes without waiting for mpv signals', () async {
    final primary = StreamController<void>.broadcast();
    final loaded = StreamController<void>.broadcast();
    final restarted = StreamController<void>.broadcast();
    final switched = StreamController<void>.broadcast();
    final started = StreamController<void>.broadcast();
    addTearDown(primary.close);
    addTearDown(loaded.close);
    addTearDown(restarted.close);
    addTearDown(switched.close);
    addTearDown(started.close);
    final guard = _arm(
      _StreamPlayer(
        fileStarted: started.stream,
        primaryMediaReady: primary.stream,
        fileLoaded: loaded.stream,
        playbackRestart: restarted.stream,
        backendSwitched: switched.stream,
      ),
      discoveryTimeout: const Duration(milliseconds: 50),
      fileLoadedTimeout: const Duration(milliseconds: 10),
      startsOnAndroidExoPlayer: true,
    );

    final outcome = guard.wait();
    loaded.add(null); // ExoPlayer's media-item transition is not mpv readiness.
    restarted.add(null);

    expect(await outcome, MpvSidecarOpenOutcome.loaded);
  });

  test('Android fallback ignores stale Exo terminal events and detects an mpv sidecar stall', () async {
    final primary = StreamController<void>.broadcast();
    final loaded = StreamController<void>.broadcast();
    final failed = StreamController<void>.broadcast();
    final restarted = StreamController<void>.broadcast();
    final switched = StreamController<void>.broadcast();
    final started = StreamController<void>.broadcast();
    addTearDown(primary.close);
    addTearDown(loaded.close);
    addTearDown(failed.close);
    addTearDown(restarted.close);
    addTearDown(switched.close);
    addTearDown(started.close);
    final guard = _arm(
      _StreamPlayer(
        fileStarted: started.stream,
        primaryMediaReady: primary.stream,
        fileLoaded: loaded.stream,
        fileLoadFailed: failed.stream,
        playbackRestart: restarted.stream,
        backendSwitched: switched.stream,
      ),
      discoveryTimeout: const Duration(milliseconds: 50),
      fileLoadedTimeout: const Duration(milliseconds: 10),
      startsOnAndroidExoPlayer: true,
    );

    final outcome = guard.wait();
    loaded.add(null);
    failed.add(null);
    switched.add(null);
    await Future<void>.delayed(Duration.zero);
    started.add(null);
    primary.add(null);

    expect(await outcome, MpvSidecarOpenOutcome.stalled);
  });

  test('Android fallback shares one bounded primary-discovery budget with mpv', () async {
    final primary = StreamController<void>.broadcast();
    final loaded = StreamController<void>.broadcast();
    final restarted = StreamController<void>.broadcast();
    final switched = StreamController<void>.broadcast();
    final started = StreamController<void>.broadcast();
    addTearDown(primary.close);
    addTearDown(loaded.close);
    addTearDown(restarted.close);
    addTearDown(switched.close);
    addTearDown(started.close);
    final guard = _arm(
      _StreamPlayer(
        fileStarted: started.stream,
        primaryMediaReady: primary.stream,
        fileLoaded: loaded.stream,
        playbackRestart: restarted.stream,
        backendSwitched: switched.stream,
      ),
      discoveryTimeout: const Duration(milliseconds: 100),
      fileLoadedTimeout: const Duration(milliseconds: 20),
      startsOnAndroidExoPlayer: true,
    );

    final clock = Stopwatch()..start();
    final outcome = guard.wait();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    switched.add(null);
    await Future<void>.delayed(Duration.zero);
    started.add(null);

    expect(await outcome, MpvSidecarOpenOutcome.inconclusive);
    clock.stop();
    expect(clock.elapsed, lessThan(const Duration(milliseconds: 145)));
  });

  test('closing player streams aborts the guard without waiting forever', () async {
    final primary = StreamController<void>.broadcast();
    final loaded = StreamController<void>.broadcast();
    addTearDown(loaded.close);
    final guard = _arm(
      _StreamPlayer(primaryMediaReady: primary.stream, fileLoaded: loaded.stream),
      discoveryTimeout: const Duration(milliseconds: 20),
      fileLoadedTimeout: const Duration(milliseconds: 10),
    );

    final outcome = guard.wait();
    await primary.close();

    expect(await outcome, MpvSidecarOpenOutcome.aborted);
  });

  test('aborting the open outcome aborts the guard ahead of its timeouts', () async {
    final primary = StreamController<void>.broadcast();
    final loaded = StreamController<void>.broadcast();
    final started = StreamController<void>.broadcast();
    addTearDown(primary.close);
    addTearDown(loaded.close);
    addTearDown(started.close);
    final openOutcome = PlaybackOpenOutcome.armForTesting(
      _StreamPlayer(fileStarted: started.stream, primaryMediaReady: primary.stream, fileLoaded: loaded.stream),
    );
    final guard = MpvSidecarOpenGuard.armForTesting(
      outcome: openOutcome,
      discoveryTimeout: const Duration(seconds: 10),
      fileLoadedTimeout: const Duration(seconds: 10),
    );

    final outcome = guard.wait();
    started.add(null);
    primary.add(null);
    await Future<void>.delayed(Duration.zero);
    openOutcome.abort('fatal player error');

    expect(await outcome, MpvSidecarOpenOutcome.aborted);
  });
}
