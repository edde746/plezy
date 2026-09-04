import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/watch_together/services/clock_sync.dart';

void main() {
  // Drives ClockSync with a virtual clock anchored to fakeAsync's elapsed time.
  (ClockSync, List<int>) build(FakeAsync async, {int epochMs = 1000000}) {
    final pings = <int>[];
    final sync = ClockSync(sendPing: pings.add, nowMs: () => epochMs + async.elapsed.inMilliseconds);
    return (sync, pings);
  }

  test('sends a convergence burst then settles into the steady interval', () {
    fakeAsync((async) {
      final (sync, pings) = build(async);
      sync.start();
      expect(pings.length, 1); // Immediate first ping.

      async.elapse(const Duration(milliseconds: 1100));
      expect(pings.length, 3); // Burst of 3 total.

      async.elapse(const Duration(seconds: 10));
      expect(pings.length, 5); // Two steady 5s ticks.

      sync.stop();
      async.elapse(const Duration(seconds: 30));
      expect(pings.length, 5);
    });
  });

  test('computes the offset from a pong and translates host time', () {
    fakeAsync((async) {
      final (sync, pings) = build(async);
      sync.start();
      final pingId = pings.single;

      // 100ms RTT; host clock 5000ms ahead of ours at the midpoint.
      async.elapse(const Duration(milliseconds: 100));
      final hostAtMidpoint = pingId + 50 + 5000;
      sync.onPong(pingId, hostAtMidpoint);

      expect(sync.offsetMs, 5000);
      expect(sync.minRttMs, 100);
      expect(sync.hostNowMs(), 1000000 + 100 + 5000);
      sync.stop();
    });
  });

  test('prefers the lowest-RTT sample in the window', () {
    fakeAsync((async) {
      final (sync, pings) = build(async);
      sync.start();

      // First exchange: jittery 100ms RTT whose asymmetry skews the offset.
      final first = pings[0]; // Sent at t=0; ping id == send timestamp.
      async.elapse(const Duration(milliseconds: 100));
      sync.onPong(first, first + 50 + 5040);
      expect(sync.offsetMs, 5040);
      expect(sync.minRttMs, 100);

      // Burst ping at t=500; answer it with a clean 40ms RTT.
      async.elapse(const Duration(milliseconds: 400));
      final second = pings[1];
      async.elapse(const Duration(milliseconds: 40));
      sync.onPong(second, second + 20 + 5000);

      expect(sync.minRttMs, 40);
      expect(sync.offsetMs, 5000);
      sync.stop();
    });
  });

  test('an offset beyond what the round trips can explain restarts the window', () {
    fakeAsync((async) {
      final (sync, pings) = build(async);
      sync.start();

      final first = pings[0];
      async.elapse(const Duration(milliseconds: 40));
      sync.onPong(first, first + 20 + 5000);
      expect(sync.offsetMs, 5000);

      // The host's clock stepped 800ms between exchanges. Under the old
      // rule this 60ms sample would lose to the 40ms one for the whole
      // window and every anchor would read 800ms wrong for ~40s.
      async.elapse(const Duration(milliseconds: 460));
      final second = pings[1];
      async.elapse(const Duration(milliseconds: 60));
      sync.onPong(second, second + 30 + 5800);

      expect(sync.offsetMs, 5800);
      expect(sync.minRttMs, 60); // The pre-step sample is gone.
      sync.stop();
    });
  });

  test('discards samples with RTT over a second and unknown ping ids', () {
    fakeAsync((async) {
      final (sync, pings) = build(async);
      sync.start();
      final pingId = pings.single;

      sync.onPong(123456789, 42); // Not ours.
      expect(sync.offsetMs, isNull);

      async.elapse(const Duration(milliseconds: 1500));
      sync.onPong(pingId, pingId + 750);
      expect(sync.offsetMs, isNull); // RTT 1500ms discarded.

      // A pong for an already-consumed/never-sent id stays ignored.
      sync.onPong(pingId, pingId + 750);
      expect(sync.offsetMs, isNull);
      sync.stop();
    });
  });

  test('keeps multiple pings in flight and matches each by id', () {
    fakeAsync((async) {
      final (sync, pings) = build(async);
      sync.start();
      async.elapse(const Duration(milliseconds: 1100));
      expect(pings.length, 3);

      // Answer them out of order; offsets differ only by what asymmetric
      // delay on each round trip can explain.
      final p0 = pings[0], p1 = pings[1], p2 = pings[2];
      sync.onPong(p2, p2 + 50 + 1000); // RTT = now - sentAt(t=1000ms) = 100ms
      sync.onPong(p0, p0 + 550 + 1300); // RTT 1100ms → discarded
      sync.onPong(p1, p1 + 300 + 1200); // RTT 600ms → accepted

      expect(sync.minRttMs, 100);
      expect(sync.offsetMs, 1000);
      sync.stop();
    });
  });

  test('window evicts the oldest samples', () {
    fakeAsync((async) {
      final (sync, pings) = build(async);
      sync.start();

      // First sample: the all-time best RTT (10ms), offset 130.
      final first = pings[0];
      async.elapse(const Duration(milliseconds: 10));
      sync.onPong(first, first + 5 + 130);
      expect(sync.offsetMs, 130);

      // Push 8 more samples (the window size) with worse RTTs, offset 100.
      for (var i = 0; i < 8; i++) {
        async.elapse(const Duration(seconds: 5));
        final pingId = pings.last; // Sent at t == pingId (id is timestamp).
        async.elapse(const Duration(milliseconds: 60));
        final now = 1000000 + async.elapsed.inMilliseconds;
        final rtt = now - pingId;
        sync.onPong(pingId, pingId + rtt ~/ 2 + 100);
        if (i < 7) expect(sync.offsetMs, 130); // The 10ms sample still wins.
      }

      // The 10ms/130 sample has been evicted; best of the window wins.
      expect(sync.offsetMs, 100);
      sync.stop();
    });
  });
}
