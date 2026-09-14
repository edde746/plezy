import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/video_player/open_http_503_watchdog.dart';

// An open the server answers with 503 never fails on its own: ffmpeg's
// reconnect loop retries 503 forever (#1520) and mpv just reports buffering,
// so a server that keeps refusing leaves a silent black screen (#1830). The
// watchdog is the only thing that ends that open; these tests pin its arming,
// deadline, and disarm contract.
void main() {
  test('fires once patience elapses after the first open-phase 503', () {
    fakeAsync((async) {
      var fired = 0;
      final watchdog = OpenHttp503Watchdog(onPersistent: () => fired++);

      watchdog.onOpenPhase503();
      expect(watchdog.isArmed, isTrue);

      async.elapse(openHttp503Patience - const Duration(milliseconds: 1));
      expect(fired, 0);

      async.elapse(const Duration(milliseconds: 1));
      expect(fired, 1);
      expect(watchdog.isArmed, isFalse);
    });
  });

  test('repeated 503s from the reconnect loop keep the original deadline', () {
    fakeAsync((async) {
      var fired = 0;
      final watchdog = OpenHttp503Watchdog(onPersistent: () => fired++);

      watchdog.onOpenPhase503();
      async.elapse(openHttp503Patience - const Duration(seconds: 1));
      // ffmpeg retries with backoff; each retry logs another 503. None of
      // them may push the deadline out, or a permanently refusing server
      // keeps the watchdog pending forever — the exact bug it exists to end.
      watchdog.onOpenPhase503();
      watchdog.onOpenPhase503();

      async.elapse(const Duration(seconds: 1));
      expect(fired, 1);
    });
  });

  test('disarming before the deadline prevents the failure', () {
    fakeAsync((async) {
      var fired = 0;
      final watchdog = OpenHttp503Watchdog(onPersistent: () => fired++);

      watchdog.onOpenPhase503();
      async.elapse(openHttp503Patience - const Duration(seconds: 1));
      // First frame rendered: the open succeeded, later 503s are the
      // reconnect path's business.
      watchdog.disarm();
      expect(watchdog.isArmed, isFalse);

      async.elapse(openHttp503Patience * 2);
      expect(fired, 0);
    });
  });

  test('a 503 after disarm re-arms with a fresh deadline', () {
    fakeAsync((async) {
      var fired = 0;
      final watchdog = OpenHttp503Watchdog(onPersistent: () => fired++);

      watchdog.onOpenPhase503();
      async.elapse(openHttp503Patience - const Duration(seconds: 1));
      watchdog.disarm();

      // A new open starts 503ing: the old open's elapsed time must not count
      // against it.
      watchdog.onOpenPhase503();
      async.elapse(openHttp503Patience - const Duration(seconds: 1));
      expect(fired, 0);

      async.elapse(const Duration(seconds: 1));
      expect(fired, 1);
    });
  });

  test('never fires without an observed 503', () {
    fakeAsync((async) {
      var fired = 0;
      OpenHttp503Watchdog(onPersistent: () => fired++);

      async.elapse(openHttp503Patience * 3);
      expect(fired, 0);
    });
  });
}
