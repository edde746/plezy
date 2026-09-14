import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/car_ux_restrictions_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/services/attached_player.dart';

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

    test('cache-pause-wait is written for mpv and skipped for other cores', () {
      fakeAsync((async) {
        final (attached, player, _) = build(async);
        bool? result;
        attached.setCachePauseWait(const Duration(seconds: 4)).then((v) => result = v);
        async.flushMicrotasks();
        expect(result, isTrue);
        expect(player.properties, {'cache-pause-wait': '4'});

        player.properties.clear();
        player.playerType = 'exoplayer';
        attached.setCachePauseWait(const Duration(seconds: 4)).then((v) => result = v);
        async.flushMicrotasks();
        expect(result, isTrue);
        expect(player.properties, isEmpty);
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

    test('pending teardown NOT_INITIALIZED reports failure and fires onLost once', () {
      fakeAsync((async) {
        final (attached, player, lostEvents) = build(async);
        final playingIntents = <bool>[];
        attached.playingIntents.listen(playingIntents.add);
        final pending = Completer<void>();
        player.nextCommandFuture = pending.future;
        bool? result;

        attached.play().then((value) => result = value);
        async.flushMicrotasks();
        expect(result, isNull);

        pending.completeError(PlatformException(code: 'NOT_INITIALIZED'));
        async.flushMicrotasks();

        expect(result, isFalse);
        expect(lostEvents, ['lost']);

        player.emitPlaying(true);
        async.flushMicrotasks();
        expect(playingIntents, [true], reason: 'the failed command must remove its outstanding expectation');
        attached.dispose();
      });
    });

    test('SET_PROPERTY_FAILED remains non-recoverable', () {
      fakeAsync((async) {
        final (attached, player, lostEvents) = build(async);

        player.nextCommandError = PlatformException(code: 'SET_PROPERTY_FAILED');
        Object? error;
        attached.play().catchError((Object caught) {
          error = caught;
          return false;
        });
        async.flushMicrotasks();
        expect(error, isA<PlatformException>());
        expect((error as PlatformException).code, 'SET_PROPERTY_FAILED');
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

    test('a failed delegate never falls back against a replacement source', () {
      fakeAsync((async) {
        final pending = Completer<void>();
        final (attached, player, lostEvents) = build(async, remoteSeek: (_) => pending.future);
        bool? result;
        attached.seek(const Duration(seconds: 30)).then((v) => result = v);
        async.flushMicrotasks();
        attached.unbind();
        attached.observeBinding(ratingKey: 'B', serverId: 'srv', hasFirstFrame: true);
        player.setPosition(const Duration(seconds: 5));
        pending.completeError(StateError('old screen gone'));
        async.flushMicrotasks();
        expect(result, isFalse);
        expect(player.currentPosition, const Duration(seconds: 5));
        expect(player.commandLog.where((command) => command.startsWith('seek:')), isEmpty);
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

  group('driver distraction', () {
    tearDown(() {
      TvDetectionService.debugReset();
      CarUxRestrictionsService.debugSetOverride(null);
    });

    test('a driving vehicle refuses a play the room asked for', () {
      fakeAsync((async) {
        TvDetectionService.debugSetAutomotiveOverride(true);
        CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.restricted);
        final (attached, player, _) = build(async);

        attached.play();
        async.flushMicrotasks();

        expect(player.state.playing, isFalse, reason: 'DD-3: sync must not start video while driving');
        attached.dispose();
      });
    });

    test('a parked vehicle lets the room drive playback as usual', () {
      fakeAsync((async) {
        TvDetectionService.debugSetAutomotiveOverride(true);
        CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
        final (attached, player, _) = build(async);

        attached.play();
        async.flushMicrotasks();

        expect(player.state.playing, isTrue);
        attached.dispose();
      });
    });

    test('a pause the vehicle forces is an acknowledgement, not a room-wide intent', () {
      fakeAsync((async) {
        final (attached, player, _) = build(async, playing: true);
        final intents = <bool>[];
        attached.playingIntents.listen(intents.add);

        // What the video screen issues when a car starts driving: the local player stops, but the
        // room must not be told its user pressed pause.
        attached.pause();
        async.flushMicrotasks();

        expect(player.state.playing, isFalse);
        expect(intents, isEmpty, reason: 'one car driving must not pause everybody else');
        attached.dispose();
      });
    });

    test('pausing an already-paused player leaves no acknowledgement to swallow the next one', () {
      fakeAsync((async) {
        final (attached, player, _) = build(async);
        final intents = <bool>[];
        attached.playingIntents.listen(intents.add);

        // The vehicle pauses a guest that is not playing — buffering, say — so nothing will report
        // a transition, and no expectation may be left behind.
        attached.pauseWithoutAck();
        async.flushMicrotasks();

        // The restriction lifts, the guest plays, and then the user pauses for real: that pause is
        // theirs and the room has to hear about it.
        player.emitPlaying(true);
        async.flushMicrotasks();
        player.emitPlaying(false);
        async.flushMicrotasks();

        expect(intents, contains(false), reason: 'a stale acknowledgement would have eaten this');
        attached.dispose();
      });
    });

    test('two pauses in flight leave only one acknowledgement behind', () {
      fakeAsync((async) {
        final (attached, player, _) = build(async, playing: true);
        final intents = <bool>[];
        attached.playingIntents.listen(intents.add);

        // The car's direct restriction pause and its lifecycle pause both land before the player
        // reports anything: two commands, one event.
        attached.pause();
        attached.pause();
        async.flushMicrotasks();
        expect(intents, isEmpty);

        // The user's own pause afterwards is theirs, and the room has to hear it.
        player.emitPlaying(true);
        async.flushMicrotasks();
        player.emitPlaying(false);
        async.flushMicrotasks();

        expect(intents, contains(false), reason: 'a surplus acknowledgement would have eaten this');
        attached.dispose();
      });
    });

    test('a sync seek while driving cannot leave the player running', () {
      fakeAsync((async) {
        TvDetectionService.debugSetAutomotiveOverride(true);
        CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.restricted);
        // End of file: mpv leaves the raw pause flag false, so seeking off it resumes without
        // anyone calling play — the one way past the vehicle guard on play().
        final (attached, player, _) = build(async, playing: true);

        final intents = <bool>[];
        attached.playingIntents.listen(intents.add);

        attached.seek(const Duration(minutes: 3));
        async.flushMicrotasks();

        expect(player.state.playing, isFalse, reason: 'DD-3: a seek must not become playback while driving');
        expect(intents, isEmpty, reason: 'and stopping it is this car\'s business, not the room\'s');
        attached.dispose();
      });
    });
  });
}
