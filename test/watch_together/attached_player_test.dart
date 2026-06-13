import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/watch_together/services/attached_player.dart';

import '../test_helpers/watch_together_fakes.dart';

void main() {
  (AttachedPlayer, FakeSyncPlayer, List<String>) build(
    FakeAsync async, {
    bool playing = false,
    Future<void> Function(Duration)? remoteSeek,
  }) {
    final player = FakeSyncPlayer(playing: playing);
    final lostEvents = <String>[];
    final attached = AttachedPlayer(
      player: player,
      onLost: () => lostEvents.add('lost'),
      remoteSeek: remoteSeek,
      nowMs: () => async.elapsed.inMilliseconds,
    );
    return (attached, player, lostEvents);
  }

  group('expected-state ledger', () {
    test('command-induced transitions are consumed as acks, not intents', () {
      fakeAsync((async) {
        final (attached, player, _) = build(async);
        final intents = <bool>[];
        attached.playingIntents.listen(intents.add);

        attached.play();
        async.flushMicrotasks();

        expect(player.state.playing, isTrue);
        expect(intents, isEmpty);
        attached.dispose();
      });
    });

    test('late property events (after the command future) are still acks', () {
      fakeAsync((async) {
        final (attached, player, _) = build(async);
        final intents = <bool>[];
        attached.playingIntents.listen(intents.add);

        // Simulate the real backend: command ack now, property event later.
        player.emitRestartOnSeek = false;
        attached.pause(); // No-op: already paused — expectation lingers.
        async.flushMicrotasks();
        attached.play();
        async.flushMicrotasks();
        expect(intents, isEmpty);
        attached.dispose();
      });
    });

    test('user transitions with no matching expectation are intents', () {
      fakeAsync((async) {
        final (attached, player, _) = build(async);
        final intents = <bool>[];
        attached.playingIntents.listen(intents.add);

        player.emitPlaying(true);
        async.flushMicrotasks();
        player.emitPlaying(false);
        async.flushMicrotasks();

        expect(intents, [true, false]);
        attached.dispose();
      });
    });

    test('expired expectations no longer absorb user transitions', () {
      fakeAsync((async) {
        final (attached, player, _) = build(async);
        final intents = <bool>[];
        attached.playingIntents.listen(intents.add);

        // Command is silently swallowed (no event) — e.g. seek-before-load.
        player.nextCommandError = null;
        attached.pause(); // Already paused: no event, expectation parked.
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 4)); // Past the 3s TTL.
        player.emitPlaying(true);
        player.emitPlaying(false); // User pause must NOT be eaten.
        async.flushMicrotasks();

        expect(intents, [true, false]);
        attached.dispose();
      });
    });

    test('rate acks are consumed, user rate changes are intents', () {
      fakeAsync((async) {
        final (attached, player, _) = build(async);
        final intents = <double>[];
        attached.rateIntents.listen(intents.add);

        attached.setRate(1.04);
        async.flushMicrotasks();
        expect(intents, isEmpty);

        player.emitRate(2.0);
        async.flushMicrotasks();
        expect(intents, [2.0]);
        attached.dispose();
      });
    });
  });

  group('guarded commands', () {
    test('recoverable PlatformException reports failure and fires onLost once', () {
      fakeAsync((async) {
        final (attached, player, lostEvents) = build(async);

        player.nextCommandError = PlatformException(code: 'COMMAND_FAILED');
        bool? result;
        attached.play().then((v) => result = v);
        async.flushMicrotasks();
        expect(result, isFalse);
        expect(lostEvents, hasLength(1));

        player.nextCommandError = PlatformException(code: 'NOT_INITIALIZED');
        attached.pause().then((v) => result = v);
        async.flushMicrotasks();
        expect(result, isFalse);
        expect(lostEvents, hasLength(1)); // Still once.
        attached.dispose();
      });
    });

    test('non-recoverable PlatformException rethrows', () {
      fakeAsync((async) {
        final (attached, player, lostEvents) = build(async);

        player.nextCommandError = PlatformException(code: 'SOMETHING_ELSE');
        Object? error;
        attached.play().catchError((Object e) {
          error = e;
          return false;
        });
        async.flushMicrotasks();
        expect(error, isA<PlatformException>());
        expect(lostEvents, isEmpty);
        attached.dispose();
      });
    });

    test('commands against a disposed player fail and fire onLost', () {
      fakeAsync((async) {
        final (attached, player, lostEvents) = build(async);
        player.dispose();
        async.flushMicrotasks();

        bool? result;
        attached.play().then((v) => result = v);
        async.flushMicrotasks();
        expect(result, isFalse);
        expect(lostEvents, hasLength(1));
        attached.dispose();
      });
    });

    test('disposing the attachment does not fire onLost', () {
      fakeAsync((async) {
        final (attached, _, lostEvents) = build(async);
        attached.dispose();
        async.flushMicrotasks();

        bool? result;
        attached.play().then((v) => result = v);
        async.flushMicrotasks();
        expect(result, isFalse);
        expect(lostEvents, isEmpty);
      });
    });
  });

  group('seek routing', () {
    test('uses the remote-seek delegate when provided', () {
      fakeAsync((async) {
        final delegated = <Duration>[];
        final (attached, player, _) = build(async, remoteSeek: (target) async => delegated.add(target));

        attached.seek(const Duration(seconds: 30));
        async.flushMicrotasks();

        expect(delegated, [const Duration(seconds: 30)]);
        expect(player.commandLog.where((c) => c.startsWith('seek:')), isEmpty);
        attached.dispose();
      });
    });

    test('falls back to player.seek when the delegate throws', () {
      fakeAsync((async) {
        final (attached, player, lostEvents) = build(async, remoteSeek: (_) async => throw StateError('screen gone'));

        bool? result;
        attached.seek(const Duration(seconds: 30)).then((v) => result = v);
        async.flushMicrotasks();

        expect(result, isTrue);
        expect(player.state.position, const Duration(seconds: 30));
        expect(lostEvents, isEmpty);
        attached.dispose();
      });
    });
  });

  group('signals and snapshots', () {
    test('forwards buffering transitions and playback-restart signals', () {
      fakeAsync((async) {
        final (attached, player, _) = build(async);
        final buffering = <bool>[];
        var loaded = 0;
        attached.bufferingChanges.listen(buffering.add);
        attached.loadedSignals.listen((_) => loaded++);

        player.emitBuffering(true);
        player.emitBuffering(true); // Duplicate suppressed.
        player.emitBuffering(false);
        player.emitPlaybackRestart();
        async.flushMicrotasks();

        expect(buffering, [true, false]);
        expect(loaded, 1);
        attached.dispose();
      });
    });

    test('bufferAhead is null when unknown and clamps at zero', () {
      fakeAsync((async) {
        final (attached, player, _) = build(async);
        expect(attached.bufferAhead, isNull);

        player.setPosition(const Duration(seconds: 10));
        player.setBuffer(const Duration(seconds: 18));
        expect(attached.bufferAhead, const Duration(seconds: 8));

        player.setBuffer(const Duration(seconds: 5));
        expect(attached.bufferAhead, Duration.zero);
        attached.dispose();
      });
    });
  });
}
