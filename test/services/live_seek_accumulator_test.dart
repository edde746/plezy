import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/live_seek_accumulator.dart';

void main() {
  group('LiveSeekAccumulator', () {
    late List<double> seeks; // recorded re-open targets
    late double currentEpoch; // mutable "live" epoch (streamStart + position)
    late LiveSeekBounds? window; // mutable seekable window
    late int changes; // onChanged call count
    late bool seekThrows; // make the seek re-open fail
    late bool seekSucceeds; // make the calibrated re-open report failure
    Completer<void>? gate; // optionally stalls a seek mid-flight

    LiveSeekAccumulator build() => LiveSeekAccumulator(
      seek: (target) async {
        seeks.add(target);
        if (gate != null) await gate!.future;
        if (seekThrows) throw Exception('seek failed');
        return seekSucceeds;
      },
      currentEpoch: () => currentEpoch,
      bounds: () => window,
      onChanged: () => changes++,
      debounce: const Duration(milliseconds: 300),
    );

    setUp(() {
      seeks = [];
      currentEpoch = 1000;
      window = const LiveSeekBounds(startEpoch: 0, endEpoch: 1000000);
      changes = 0;
      seekThrows = false;
      seekSucceeds = true;
      gate = null;
    });

    for (final outcome in ['success', 'failure', 'exception']) {
      test('remote program preview survives debounce/readiness and clears after $outcome', () {
        fakeAsync((async) {
          final acc = build();
          gate = Completer<void>();
          seekSucceeds = outcome == 'success';
          seekThrows = outcome == 'exception';
          acc.seekBy(-15, previewProgram: true);
          expect(acc.programPreviewEpoch, 985);
          async.elapse(const Duration(milliseconds: 300));
          expect(seeks, [985]);
          expect(acc.programPreviewEpoch, 985);
          gate!.complete();
          async.flushMicrotasks();
          expect(acc.programPreviewEpoch, isNull);
          expect(acc.pendingEpoch, isNull);
          acc.dispose();
        });
      });
    }

    test('mouse scrubs, ordinary skips, return-to-live and cancellation do not retain program previews', () {
      fakeAsync((async) {
        final acc = LiveSeekAccumulator(
          seek: (_) => Completer<bool>().future,
          seekLive: () async => true,
          currentEpoch: () => 1000,
          bounds: () => const LiveSeekBounds(startEpoch: 0, endEpoch: 2000),
        );
        acc.seekBy(-15);
        expect(acc.programPreviewEpoch, isNull);
        acc.seekBy(-15, previewProgram: true);
        expect(acc.programPreviewEpoch, 970);
        acc.seekTo(900);
        expect(acc.programPreviewEpoch, isNull);
        acc.seekBy(-15, previewProgram: true);
        expect(acc.programPreviewEpoch, 885);
        acc.jumpToLive();
        expect(acc.programPreviewEpoch, isNull);
        acc.seekBy(-15, previewProgram: true);
        acc.cancel();
        expect(acc.programPreviewEpoch, isNull);
        acc.dispose();
      });
    });

    test('an older failed seek cannot clear the newer remote preview', () {
      fakeAsync((async) {
        final first = Completer<bool>();
        final second = Completer<bool>();
        var opens = 0;
        final acc = LiveSeekAccumulator(
          seek: (_) => ++opens == 1 ? first.future : second.future,
          currentEpoch: () => 1000,
          bounds: () => const LiveSeekBounds(startEpoch: 0, endEpoch: 2000),
        );
        acc.seekBy(-200, previewProgram: true);
        async.elapse(const Duration(milliseconds: 300));
        acc.seekBy(300, previewProgram: true);
        expect(acc.programPreviewEpoch, 1100);
        first.complete(false);
        async.flushMicrotasks();
        expect(opens, 2);
        expect(acc.programPreviewEpoch, 1100);
        second.complete(true);
        async.flushMicrotasks();
        expect(acc.programPreviewEpoch, isNull);
        acc.dispose();
      });
    });

    test('return to live supersedes resolving seek with the backend live operation', () {
      fakeAsync((async) {
        final delayed = Completer<bool>();
        final offsets = <double>[];
        var liveOpens = 0;
        final acc = LiveSeekAccumulator(
          seek: (target) {
            offsets.add(target);
            return delayed.future;
          },
          seekLive: () async {
            liveOpens++;
            return true;
          },
          currentEpoch: () => 1000,
          bounds: () => const LiveSeekBounds(startEpoch: 500, endEpoch: 1200),
          debounce: Duration.zero,
        );
        acc.seekBy(-15);
        async.elapse(Duration.zero);
        final oldIntent = acc.intentGeneration;
        acc.jumpToLive();
        expect(acc.intentGeneration, greaterThan(oldIntent));
        expect(acc.pendingEpoch, 1200);
        delayed.complete(false);
        async.flushMicrotasks();
        expect(offsets, [985]);
        expect(liveOpens, 1);
        expect(acc.pendingEpoch, isNull);
        acc.dispose();
      });
    });

    test('absolute pending seek is the base for relative input and revalidates at dispatch', () {
      fakeAsync((async) {
        final acc = build();
        gate = Completer<void>();
        acc.seekTo(1100);
        acc.seekBy(-300);
        expect(acc.pendingEpoch, 800);
        window = const LiveSeekBounds(startEpoch: 850, endEpoch: 1200);
        gate!.complete();
        gate = null;
        async.flushMicrotasks();
        expect(seeks, [1100, 850]);
        expect(acc.pendingEpoch, isNull);
        acc.dispose();
      });
    });

    test('same pending boundary does not supersede readiness or reopen again', () {
      fakeAsync((async) {
        gate = Completer<void>();
        window = const LiveSeekBounds(startEpoch: 900, endEpoch: 1050);
        final acc = build();
        acc.seekBy(100);
        async.elapse(const Duration(milliseconds: 300));
        final intent = acc.intentGeneration;
        acc.seekBy(15);
        expect(acc.intentGeneration, intent);
        gate!.complete();
        gate = null;
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        expect(seeks, [1050]);
        acc.dispose();
      });
    });

    test('stale bounds reject relative offsets but backend live remains available', () {
      fakeAsync((async) {
        var live = 0;
        final offsets = <double>[];
        final acc = LiveSeekAccumulator(
          seek: (value) async {
            offsets.add(value);
            return true;
          },
          seekLive: () async {
            live++;
            return true;
          },
          currentEpoch: () => 1000,
          bounds: () => null,
        );
        acc.seekBy(-15);
        acc.seekTo(900);
        expect(acc.pendingEpoch, isNull);
        acc.jumpToLive(previewEpoch: 1100);
        async.flushMicrotasks();
        expect(live, 1);
        expect(offsets, isEmpty);
        expect(acc.pendingEpoch, isNull);
        acc.dispose();
      });
    });

    test('changing a pending live operation to the same offset notifies ownership', () {
      fakeAsync((async) {
        final liveReady = Completer<bool>();
        var changes = 0;
        final acc = LiveSeekAccumulator(
          seek: (_) async => true,
          seekLive: () => liveReady.future,
          currentEpoch: () => 1000,
          bounds: () => const LiveSeekBounds(startEpoch: 900, endEpoch: 1100),
          onChanged: () => changes++,
        );
        acc.jumpToLive();
        final originalChanges = changes;
        final originalIntent = acc.intentGeneration;
        acc.seekBy(15);
        expect(acc.intentGeneration, greaterThan(originalIntent));
        expect(changes, originalChanges + 1);
        liveReady.complete(false);
        async.flushMicrotasks();
        acc.dispose();
      });
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
        window = const LiveSeekBounds(startEpoch: 950, endEpoch: 1050);
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
        window = const LiveSeekBounds(startEpoch: 950, endEpoch: 1050);
        final acc = build();
        acc.seekBy(-100); // 1000 -> 900, clamped to 950
        expect(acc.pendingEpoch, 950);
        acc.dispose();
      });
    });

    test('does not reopen when a skip is clamped to the current boundary', () {
      fakeAsync((async) {
        window = const LiveSeekBounds(startEpoch: 950, endEpoch: 1050);
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
        window = const LiveSeekBounds(startEpoch: 950, endEpoch: 1050);
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

    for (final throws in [false, true]) {
      test('dispatches newer input after an expired debounce and ${throws ? 'exception' : 'failed calibration'}', () {
        fakeAsync((async) {
          final completions = <Completer<bool>>[];
          final acc = LiveSeekAccumulator(
            seek: (target) {
              seeks.add(target);
              final completion = Completer<bool>();
              completions.add(completion);
              return completion.future;
            },
            currentEpoch: () => currentEpoch,
            bounds: () => window,
            debounce: const Duration(milliseconds: 300),
          );
          acc.seekBy(15);
          async.elapse(const Duration(milliseconds: 300));
          acc.seekBy(15);
          async.elapse(const Duration(milliseconds: 300));
          expect(seeks, [1015]);
          expect(acc.pendingEpoch, 1030);

          if (throws) {
            completions.first.completeError(StateError('source replacement failed'));
          } else {
            completions.first.complete(false);
          }
          async.flushMicrotasks();
          expect(seeks, [1015, 1030]);
          expect(acc.pendingEpoch, 1030);

          completions.last.complete(true);
          async.flushMicrotasks();
          expect(acc.pendingEpoch, isNull);
          currentEpoch = 1045;
          acc.seekBy(15);
          async.elapse(const Duration(milliseconds: 300));
          expect(seeks, [1015, 1030, 1060]);
          completions.last.complete(true);
          async.flushMicrotasks();
          acc.dispose();
        });
      });
    }

    test('unpins the pending target only after clock calibration completes', () {
      fakeAsync((async) {
        gate = Completer<void>();
        final acc = build();
        acc.seekBy(15);

        async.elapse(const Duration(milliseconds: 300));
        expect(acc.pendingEpoch, 1015);

        async.elapse(const Duration(seconds: 10));
        expect(acc.pendingEpoch, 1015, reason: 'elapsed time is not evidence that a source clock is calibrated');

        gate!.complete();
        async.flushMicrotasks();
        expect(acc.pendingEpoch, isNull);
        acc.dispose();
      });
    });

    test('a fresh burst after settling re-seeds off the live epoch', () {
      fakeAsync((async) {
        final acc = build();
        acc.seekBy(15); // 1000 -> 1015
        async.elapse(const Duration(milliseconds: 300));
        async.flushMicrotasks();
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

    test('releases the pending pin when calibration returns false', () {
      fakeAsync((async) {
        seekSucceeds = false;
        final acc = build();
        acc.seekBy(15);

        async.elapse(const Duration(milliseconds: 300));
        async.flushMicrotasks();

        expect(seeks, [1015]);
        expect(acc.pendingEpoch, isNull);
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
        final acc = build();
        acc.seekBy(15);
        expect(changes, 1); // accumulate

        async.elapse(const Duration(milliseconds: 300));
        async.flushMicrotasks();
        expect(changes, 2); // clear
        acc.dispose();
      });
    });
  });
}
