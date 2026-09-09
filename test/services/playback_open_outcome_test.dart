import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/playback_open_outcome.dart';

/// A player whose load-scoped streams the test drives directly. [close] ends
/// every stream at once, like a disposed player closing its controllers.
class _StreamPlayer implements Player {
  final started = StreamController<void>.broadcast();
  final primaryReady = StreamController<void>.broadcast();
  final loaded = StreamController<void>.broadcast();
  final restarted = StreamController<void>.broadcast();
  final failed = StreamController<void>.broadcast();
  final switched = StreamController<void>.broadcast();

  @override
  late final PlayerStreams streams = PlayerStreams(
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
    error: const Stream.empty(),
    audioDevice: const Stream.empty(),
    audioDevices: const Stream.empty(),
    bufferRanges: const Stream.empty(),
    playbackRestart: restarted.stream,
    fileStarted: started.stream,
    fileLoaded: loaded.stream,
    fileLoadFailed: failed.stream,
    primaryMediaReady: primaryReady.stream,
    backendSwitched: switched.stream,
  );

  Future<void> close() => Future.wait([
    started.close(),
    primaryReady.close(),
    loaded.close(),
    restarted.close(),
    failed.close(),
    switched.close(),
  ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Lets the broadcast controllers deliver and the futures' callbacks run.
Future<void> _settle() async {
  for (var i = 0; i < 3; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _StreamPlayer player;

  setUp(() => player = _StreamPlayer());
  tearDown(() => player.close());

  test('a load-scoped end-file error settles every waiter false without throwing', () async {
    final outcome = PlaybackOpenOutcome.armForTesting(player);

    player.started.add(null);
    player.failed.add(null);

    expect(await outcome.fileLoaded, isFalse);
    expect(await outcome.firstFrame, isFalse);
    expect(await outcome.primaryMediaReady, isFalse);
    expect(outcome.failed, isTrue);
    expect(outcome.isAborted, isFalse);
  });

  test('closing the player streams settles pending waiters false instead of erroring', () async {
    final outcome = PlaybackOpenOutcome.armForTesting(player);
    final fileLoaded = outcome.fileLoaded;
    final firstFrame = outcome.firstFrame;

    await player.close();

    expect(await fileLoaded, isFalse);
    expect(await firstFrame, isFalse);
    expect(outcome.isAborted, isTrue);
  });

  test('abort settles every pending waiter and is idempotent', () async {
    final outcome = PlaybackOpenOutcome.armForTesting(player);

    outcome.abort('fatal player error');
    outcome.abort('screen disposed');

    expect(await outcome.fileLoaded, isFalse);
    expect(await outcome.firstFrame, isFalse);
    expect(outcome.abortReason, 'fatal player error');
    expect(outcome.isSettled, isTrue);

    // Released: later player events cannot revive or flip a settled outcome.
    player.started.add(null);
    player.loaded.add(null);
    player.restarted.add(null);
    await _settle();
    expect(await outcome.firstFrame, isFalse);
  });

  test('success resolves true and a later failure does not flip it', () async {
    final outcome = PlaybackOpenOutcome.armForTesting(player);

    player.started.add(null);
    player.loaded.add(null);
    await _settle();
    expect(await outcome.fileLoaded, isTrue);
    expect(outcome.isSettled, isFalse);

    // Playback died after loading but before its first frame: the loaded
    // verdict stands, the frame verdict does not.
    player.failed.add(null);
    await _settle();
    expect(await outcome.fileLoaded, isTrue);
    expect(await outcome.firstFrame, isFalse);

    // And a first frame settles everything true at once.
    final rendered = PlaybackOpenOutcome.armForTesting(player);
    player.started.add(null);
    player.restarted.add(null);
    await _settle();
    expect(await rendered.primaryMediaReady, isTrue);
    expect(await rendered.fileLoaded, isTrue);
    expect(await rendered.firstFrame, isTrue);
    rendered.abort('too late');
    expect(rendered.isAborted, isFalse);
    expect(await rendered.firstFrame, isTrue);
  });

  test('signals before this attempt starts its file belong to the previous file', () async {
    final outcome = PlaybackOpenOutcome.armForTesting(player);

    // A seek on the outgoing item, then its death, while the new open is
    // still being resolved.
    player.restarted.add(null);
    player.loaded.add(null);
    player.failed.add(null);
    await _settle();
    expect(outcome.isSettled, isFalse);
    expect(outcome.failed, isFalse);

    player.started.add(null);
    player.loaded.add(null);
    player.restarted.add(null);
    expect(await outcome.firstFrame, isTrue);
  });

  test('Android ExoPlayer: an end-file before the backend switch is not terminal', () async {
    final outcome = PlaybackOpenOutcome.armForTesting(player, startsOnAndroidExoPlayer: true);

    player.loaded.add(null); // ExoPlayer media-item transition.
    player.failed.add(null); // Unsupported format; the mpv fallback follows.
    await _settle();
    expect(outcome.isSettled, isFalse);
    expect(outcome.failed, isFalse);

    var switched = false;
    unawaited(outcome.backendSwitched.then((_) => switched = true));
    player.switched.add(null);
    await _settle();
    expect(switched, isTrue);

    // mpv's own load delimits the signals from here on.
    player.started.add(null);
    player.primaryReady.add(null);
    player.loaded.add(null);
    expect(await outcome.primaryMediaReady, isTrue);
    expect(await outcome.fileLoaded, isTrue);
    expect(outcome.isSettled, isFalse);

    player.failed.add(null);
    expect(await outcome.firstFrame, isFalse);
    expect(outcome.failed, isTrue);
  });

  test('Android ExoPlayer: its first frame after the media-item transition settles the open', () async {
    final outcome = PlaybackOpenOutcome.armForTesting(player, startsOnAndroidExoPlayer: true);

    // A rebuffer of the outgoing item while the new open resolves.
    player.restarted.add(null);
    await _settle();
    expect(outcome.isSettled, isFalse);

    player.loaded.add(null);
    player.restarted.add(null);
    expect(await outcome.fileLoaded, isTrue);
    expect(await outcome.firstFrame, isTrue);
  });

  test('the deadline counts from load start and aborts a backend that goes silent', () {
    fakeAsync((async) {
      final outcome = PlaybackOpenOutcome.armForTesting(player, deadline: const Duration(seconds: 30));
      bool? firstFrame;
      unawaited(outcome.firstFrame.then((value) => firstFrame = value));

      // Nothing started: no clock runs while open() is still being dispatched.
      async.elapse(const Duration(minutes: 1));
      expect(outcome.isSettled, isFalse);

      player.started.add(null);
      async.elapse(const Duration(seconds: 29));
      expect(outcome.isSettled, isFalse);

      // A reopen (sidecar fallback) restarts the budget.
      player.started.add(null);
      async.elapse(const Duration(seconds: 29));
      expect(outcome.isSettled, isFalse);

      async.elapse(const Duration(seconds: 1));
      expect(firstFrame, isFalse);
      expect(outcome.isAborted, isTrue);
      expect(async.nonPeriodicTimerCount, 0);
    });
  });

  test('a rendered first frame cancels the deadline', () {
    fakeAsync((async) {
      final outcome = PlaybackOpenOutcome.armForTesting(player, deadline: const Duration(seconds: 30));

      player.started.add(null);
      player.restarted.add(null);
      async.flushMicrotasks();

      expect(outcome.isSettled, isTrue);
      expect(async.nonPeriodicTimerCount, 0);
    });
  });
}
