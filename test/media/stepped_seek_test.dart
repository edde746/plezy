import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/stepped_seek.dart';

void main() {
  test('stepped multiplier preserves shared acceleration tiers', () {
    expect(steppedSeekMultiplier(0), 1.5);
    expect(steppedSeekMultiplier(5), 1.5);
    expect(steppedSeekMultiplier(6), 3.0);
    expect(steppedSeekMultiplier(15), 3.0);
    expect(steppedSeekMultiplier(16), 6.0);
    expect(steppedSeekMultiplier(30), 6.0);
    expect(steppedSeekMultiplier(31), 10.0);
  });

  test('rapid steps accumulate and debounce into one seek', () {
    fakeAsync((async) {
      var position = const Duration(seconds: 20);
      final seeks = <Duration>[];
      final accumulator = DebouncedSeekAccumulator(
        currentPosition: () => position,
        duration: () => const Duration(minutes: 2),
        seek: seeks.add,
      );

      accumulator.seekBy(const Duration(seconds: 10));
      accumulator.seekBy(const Duration(seconds: 15));
      accumulator.seekBy(const Duration(seconds: -5));

      expect(accumulator.pendingPosition, const Duration(seconds: 40));
      async.elapse(const Duration(milliseconds: 799));
      expect(seeks, isEmpty);
      async.elapse(const Duration(milliseconds: 1));
      expect(seeks, [const Duration(seconds: 40)]);

      // A slow player still reports the old position. The next burst must use
      // the pinned target rather than silently dropping the committed seek.
      accumulator.seekBy(const Duration(seconds: 10));
      accumulator.flush();
      expect(seeks, [const Duration(seconds: 40), const Duration(seconds: 50)]);

      position = const Duration(seconds: 50);
      async.elapse(const Duration(seconds: 2));
      expect(accumulator.pendingPosition, isNull);
      accumulator.dispose();
    });
  });

  test('clamps targets and cancel prevents a pending seek', () {
    fakeAsync((async) {
      final seeks = <Duration>[];
      final accumulator = DebouncedSeekAccumulator(
        currentPosition: () => const Duration(seconds: 5),
        duration: () => const Duration(seconds: 30),
        seek: seeks.add,
      );

      accumulator.seekBy(const Duration(minutes: 1));
      expect(accumulator.pendingPosition, const Duration(seconds: 30));
      accumulator.cancel();
      async.elapse(const Duration(seconds: 1));
      expect(seeks, isEmpty);
      expect(accumulator.pendingPosition, isNull);
      accumulator.dispose();
    });
  });

  group('foreign seeks', () {
    test('a seek from elsewhere retires the pin so the next step rebases', () {
      fakeAsync((async) {
        var position = const Duration(seconds: 20);
        final seeks = <Duration>[];
        var abandonments = 0;
        final playerJumps = StreamController<Duration?>.broadcast();
        final accumulator = DebouncedSeekAccumulator(
          currentPosition: () => position,
          duration: () => const Duration(minutes: 10),
          seek: seeks.add,
          playheadJumps: playerJumps.stream,
          onBurstAbandoned: () => abandonments++,
        );

        accumulator.seekBy(const Duration(seconds: 10));
        accumulator.flush();
        expect(seeks, [const Duration(seconds: 30)]);
        // The accumulator's own commit, echoed back by the player.
        position = const Duration(seconds: 30);
        playerJumps.add(const Duration(seconds: 30));
        async.flushMicrotasks();
        expect(accumulator.pendingPosition, const Duration(seconds: 30));
        expect(abandonments, 0, reason: 'the accumulator must not mistake its own seek for a foreign one');

        // The user drops the playhead somewhere else with the timeline.
        position = const Duration(minutes: 5);
        playerJumps.add(const Duration(minutes: 5));
        async.flushMicrotasks();
        expect(accumulator.pendingPosition, isNull);
        expect(abandonments, 1);

        accumulator.seekBy(const Duration(seconds: 10));
        accumulator.flush();
        expect(
          seeks.last,
          const Duration(minutes: 5, seconds: 10),
          reason: 'the skip must be relative to the timeline jump, not to the superseded target',
        );

        accumulator.dispose();
        playerJumps.close();
      });
    });

    test('a seek from elsewhere mid-burst drops the undispatched target', () {
      fakeAsync((async) {
        var position = const Duration(seconds: 20);
        final seeks = <Duration>[];
        final playerJumps = StreamController<Duration?>.broadcast();
        final accumulator = DebouncedSeekAccumulator(
          currentPosition: () => position,
          duration: () => const Duration(minutes: 10),
          seek: seeks.add,
          playheadJumps: playerJumps.stream,
        );

        accumulator.seekBy(const Duration(seconds: 10));
        position = const Duration(minutes: 5);
        playerJumps.add(const Duration(minutes: 5));
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 2));
        expect(seeks, isEmpty, reason: 'the debounce belonged to a burst the foreign seek abandoned');
        expect(accumulator.pendingPosition, isNull);

        accumulator.dispose();
        playerJumps.close();
      });
    });

    test('onBurstAbandoned stays out of the ordinary step and settle paths', () {
      fakeAsync((async) {
        var position = const Duration(seconds: 20);
        var abandonments = 0;
        var changes = 0;
        final playerJumps = StreamController<Duration?>.broadcast();
        final accumulator = DebouncedSeekAccumulator(
          currentPosition: () => position,
          duration: () => const Duration(minutes: 10),
          seek: (_) {},
          playheadJumps: playerJumps.stream,
          onChanged: () => changes++,
          onBurstAbandoned: () => abandonments++,
        );

        // Repeated presses advance the pending target: previews repaint, but no
        // press is a foreign seek. Reporting one here would reset the caller's
        // running skip total on every repeat.
        accumulator.seekBy(const Duration(seconds: 10));
        accumulator.seekBy(const Duration(seconds: 10));
        accumulator.seekBy(const Duration(seconds: 10));
        expect(changes, 3);
        expect(abandonments, 0);

        // Nor is the natural settle once playback reaches the target.
        accumulator.flush();
        position = const Duration(seconds: 50);
        async.elapse(const Duration(seconds: 2));
        expect(accumulator.pendingPosition, isNull);
        expect(abandonments, 0);

        accumulator.dispose();
        playerJumps.close();
      });
    });

    test('a retired accumulator stops listening to the player', () {
      fakeAsync((async) {
        final playerJumps = StreamController<Duration?>.broadcast();
        final accumulator = DebouncedSeekAccumulator(
          currentPosition: () => const Duration(seconds: 20),
          duration: () => const Duration(minutes: 10),
          seek: (_) {},
          playheadJumps: playerJumps.stream,
        );

        accumulator.seekBy(const Duration(seconds: 10));
        accumulator.dispose();
        expect(playerJumps.hasListener, isFalse);

        playerJumps.add(const Duration(minutes: 5));
        async.flushMicrotasks();
        playerJumps.close();
      });
    });

    test('a jump with no reported destination is always foreign', () {
      fakeAsync((async) {
        final seeks = <Duration>[];
        var abandonments = 0;
        final playerJumps = StreamController<Duration?>.broadcast();
        var position = const Duration(seconds: 20);
        final accumulator = DebouncedSeekAccumulator(
          currentPosition: () => position,
          duration: () => const Duration(minutes: 10),
          seek: seeks.add,
          playheadJumps: playerJumps.stream,
          onBurstAbandoned: () => abandonments++,
        );

        accumulator.seekBy(const Duration(seconds: 10));
        accumulator.flush();
        expect(accumulator.pendingPosition, const Duration(seconds: 30));

        // mpv's sub-seek picks its own cue, so the destination is unknown.
        position = const Duration(minutes: 2);
        playerJumps.add(null);
        async.flushMicrotasks();

        expect(accumulator.pendingPosition, isNull);
        expect(abandonments, 1);

        accumulator.seekBy(const Duration(seconds: 10));
        accumulator.flush();
        expect(seeks.last, const Duration(minutes: 2, seconds: 10));

        accumulator.dispose();
        playerJumps.close();
      });
    });

    test('rebinding to another player drops the old pin and its stream', () {
      fakeAsync((async) {
        var abandonments = 0;
        final oldPlayer = StreamController<Duration?>.broadcast();
        final newPlayer = StreamController<Duration?>.broadcast();
        final accumulator = DebouncedSeekAccumulator(
          currentPosition: () => const Duration(seconds: 20),
          duration: () => const Duration(minutes: 10),
          seek: (_) {},
          playheadJumps: oldPlayer.stream,
          onBurstAbandoned: () => abandonments++,
        );

        accumulator.seekBy(const Duration(seconds: 10));
        accumulator.attachPlayheadJumps(newPlayer.stream);

        expect(oldPlayer.hasListener, isFalse);
        expect(
          accumulator.pendingPosition,
          isNull,
          reason: 'the pin described the retired player, whose echo will never arrive',
        );
        expect(abandonments, 1, reason: 'the burst was dropped, so its running total is stale too');

        // A late event from the retired player must not reach the accumulator.
        accumulator.seekBy(const Duration(seconds: 10));
        oldPlayer.add(const Duration(minutes: 4));
        async.flushMicrotasks();
        expect(accumulator.pendingPosition, isNotNull);
        expect(abandonments, 1);

        newPlayer.add(const Duration(minutes: 6));
        async.flushMicrotasks();
        expect(accumulator.pendingPosition, isNull, reason: 'the new player is what it listens to now');
        expect(abandonments, 2);

        accumulator.dispose();
        oldPlayer.close();
        newPlayer.close();
      });
    });
  });
}
