import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/live_seek_accumulator.dart';

void main() {
  group('LiveSeekAccumulator', () {
    late List<int> seeks; // recorded re-open targets
    late int currentEpoch; // mutable "live" epoch (streamStart + position)
    late int positionSeconds; // mutable player position, drives settle
    late LiveSeekBounds? window; // mutable seekable window
    late int changes; // onChanged call count
    late bool seekThrows; // make the seek re-open fail
    Completer<void>? gate; // optionally stalls a seek mid-flight

    LiveSeekAccumulator build() => LiveSeekAccumulator(
      seek: (target) async {
        seeks.add(target);
        if (gate != null) await gate!.future;
        if (seekThrows) throw Exception('seek failed');
      },
      currentEpoch: () => currentEpoch,
      positionSeconds: () => positionSeconds,
      bounds: () => window,
      onChanged: () => changes++,
      debounce: const Duration(milliseconds: 300),
      settleCeiling: const Duration(milliseconds: 1500),
      settlePoll: const Duration(milliseconds: 100),
    );

    setUp(() {
      seeks = [];
      currentEpoch = 1000;
      positionSeconds = 0; // re-opened stream settles immediately by default
      window = (start: 0, end: 1000000);
      changes = 0;
      seekThrows = false;
      gate = null;
    });

    test('coalesces a rapid burst into a single seek at the summed target', () {
      fakeAsync((async) {
        final acc = build();
        for (var i = 0; i < 14; i++) {
          acc.seekBy(15);
        }
        // Nothing fires while the burst is still arriving.
        expect(seeks, isEmpty);

        async.elapse(const Duration(milliseconds: 300));
        // 14 presses of 15s from epoch 1000 => one re-open at 1000 + 210.
        expect(seeks, [1210]);
        acc.dispose();
      });
    });

    test('accumulates off the pending target, not the laggy live epoch', () {
      fakeAsync((async) {
        final acc = build();
        acc.seekBy(15); // base 1000 -> 1015
        expect(acc.pendingEpoch, 1015);

        // Simulate the post-reopen overshoot: the raw live epoch jumps wildly.
        // The next press must still compound off the pending target.
        currentEpoch = 99999;
        acc.seekBy(15); // 1015 -> 1030, NOT 99999 + 15
        expect(acc.pendingEpoch, 1030);

        async.elapse(const Duration(milliseconds: 300));
        expect(seeks, [1030]);
        acc.dispose();
      });
    });

    test('clamps the accumulated target to the live edge', () {
      fakeAsync((async) {
        window = (start: 950, end: 1050);
        final acc = build();
        acc.seekBy(100); // 1000 -> 1100, clamped to 1050
        expect(acc.pendingEpoch, 1050);
        acc.seekBy(100); // stays at the edge
        expect(acc.pendingEpoch, 1050);

        async.elapse(const Duration(milliseconds: 300));
        expect(seeks, [1050]);
        acc.dispose();
      });
    });

    test('clamps backward skips to the window start', () {
      fakeAsync((async) {
        window = (start: 950, end: 1050);
        final acc = build();
        acc.seekBy(-100); // 1000 -> 900, clamped to 950
        expect(acc.pendingEpoch, 950);
        acc.dispose();
      });
    });

    test('does not reopen when a skip is clamped to the current boundary', () {
      fakeAsync((async) {
        window = (start: 950, end: 1050);
        final acc = build();

        currentEpoch = 1050;
        acc.seekBy(15);
        expect(acc.pendingEpoch, isNull);

        currentEpoch = 950;
        acc.seekBy(-15);
        expect(acc.pendingEpoch, isNull);

        async.elapse(const Duration(milliseconds: 300));
        expect(seeks, isEmpty);
        expect(changes, 0);
        acc.dispose();
      });
    });

    test('still seeks away from a capture-buffer boundary', () {
      fakeAsync((async) {
        window = (start: 950, end: 1050);
        currentEpoch = 1050;
        final acc = build();

        acc.seekBy(-15);
        expect(acc.pendingEpoch, 1035);

        async.elapse(const Duration(milliseconds: 300));
        expect(seeks, [1035]);
        acc.dispose();
      });
    });

    test('flushes the newer target when a press lands during the seek', () {
      fakeAsync((async) {
        gate = Completer<void>();
        final acc = build();
        acc.seekBy(15); // pending 1015

        async.elapse(const Duration(milliseconds: 300));
        expect(seeks, [1015]); // first seek in flight, awaiting the gate

        acc.seekBy(15); // pending 1030 while the first seek is still open
        gate!.complete(); // first seek resolves
        gate = null; // later seeks resolve immediately
        async.flushMicrotasks();

        // The re-entrant flush picks up the newer target — no waiting for a
        // second debounce, no lost press.
        expect(seeks, [1015, 1030]);
        acc.dispose();
      });
    });

    test('unpins the pending target once the re-opened stream settles', () {
      fakeAsync((async) {
        positionSeconds = 0; // settled
        final acc = build();
        acc.seekBy(15);

        async.elapse(const Duration(milliseconds: 300));
        expect(acc.pendingEpoch, 1015); // still pinned right after the re-open

        async.elapse(const Duration(milliseconds: 100)); // settle poll
        expect(acc.pendingEpoch, isNull);
        acc.dispose();
      });
    });

    test('unpins via the ceiling if the position never settles', () {
      fakeAsync((async) {
        positionSeconds = 100; // never below the settle threshold
        final acc = build();
        acc.seekBy(15);

        async.elapse(const Duration(milliseconds: 300));
        expect(acc.pendingEpoch, 1015);

        async.elapse(const Duration(milliseconds: 1500)); // ceiling
        expect(acc.pendingEpoch, isNull);
        acc.dispose();
      });
    });

    test('a fresh burst after settling re-seeds off the live epoch', () {
      fakeAsync((async) {
        final acc = build();
        acc.seekBy(15); // 1000 -> 1015
        async.elapse(const Duration(milliseconds: 300));
        async.elapse(const Duration(milliseconds: 100)); // settle clears pending
        expect(acc.pendingEpoch, isNull);

        // New stream origin: raw epoch now reflects the previous target.
        currentEpoch = 1015;
        acc.seekBy(15); // base 1015 -> 1030
        async.elapse(const Duration(milliseconds: 300));

        expect(seeks, [1015, 1030]);
        acc.dispose();
      });
    });

    test('releases the pending pin when the re-open fails', () {
      fakeAsync((async) {
        seekThrows = true;
        final acc = build();
        acc.seekBy(15);
        expect(acc.pendingEpoch, 1015);

        async.elapse(const Duration(milliseconds: 300));
        expect(seeks, [1015]); // the re-open was attempted
        expect(acc.pendingEpoch, isNull); // pin released despite the failure
        acc.dispose();
      });
    });

    test('cancel drops the pending target and prevents the debounced seek', () {
      fakeAsync((async) {
        final acc = build();
        acc.seekBy(15);
        expect(acc.pendingEpoch, 1015);

        acc.cancel();
        expect(acc.pendingEpoch, isNull);

        async.elapse(const Duration(milliseconds: 300));
        expect(seeks, isEmpty);
        acc.dispose();
      });
    });

    test('is a no-op when there is no seekable window', () {
      fakeAsync((async) {
        window = null;
        final acc = build();
        acc.seekBy(15);
        expect(acc.pendingEpoch, isNull);

        async.elapse(const Duration(milliseconds: 300));
        expect(seeks, isEmpty);
        acc.dispose();
      });
    });

    test('notifies onChanged when the target changes and when it clears', () {
      fakeAsync((async) {
        positionSeconds = 0;
        final acc = build();
        acc.seekBy(15);
        expect(changes, 1); // accumulate

        async.elapse(const Duration(milliseconds: 300));
        async.elapse(const Duration(milliseconds: 100)); // settle clears
        expect(changes, 2); // clear
        acc.dispose();
      });
    });
  });
}
