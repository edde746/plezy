import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/refresh_pacer.dart';

void main() {
  const debounce = Duration(seconds: 3);
  const cooldown = Duration(minutes: 2);
  const blockedRetry = Duration(seconds: 15);

  ({RefreshPacer pacer, List<int> passes, void Function(bool) setBlocked, void Function(bool) setDropped}) build() {
    final passes = <int>[];
    var blocked = false;
    var dropped = false;
    final pacer = RefreshPacer(
      debounce: debounce,
      cooldown: cooldown,
      blockedRetry: blockedRetry,
      isBlocked: () => blocked,
      runPass: () {
        if (dropped) return false;
        passes.add(passes.length);
        return true;
      },
    );
    return (pacer: pacer, passes: passes, setBlocked: (v) => blocked = v, setDropped: (v) => dropped = v);
  }

  test('a burst coalesces into one pass at the debounce edge', () {
    fakeAsync((async) {
      final h = build();
      h.pacer.schedule();
      async.elapse(const Duration(seconds: 1));
      h.pacer.schedule();
      h.pacer.schedule();
      expect(h.passes, isEmpty);
      async.elapse(const Duration(seconds: 2));
      expect(h.passes, hasLength(1), reason: 'one pass exactly [debounce] after the first event');
      h.pacer.dispose();
    });
  });

  test('a sustained sub-debounce event stream cannot starve the pass', () {
    fakeAsync((async) {
      final h = build();
      // Events every 2 s forever — each inside the 3 s debounce window.
      for (var i = 0; i < 10; i++) {
        h.pacer.schedule();
        async.elapse(const Duration(seconds: 2));
      }
      expect(h.passes, isNotEmpty, reason: 'arm-once debounce fires despite the stream never going quiet');
      h.pacer.dispose();
    });
  });

  test('blocked pass retries until unblocked', () {
    fakeAsync((async) {
      final h = build();
      h.setBlocked(true);
      h.pacer.schedule();
      async.elapse(debounce + blockedRetry * 2);
      expect(h.passes, isEmpty);
      h.setBlocked(false);
      async.elapse(blockedRetry);
      expect(h.passes, hasLength(1));
      h.pacer.dispose();
    });
  });

  test('cooldown latches exactly one trailing pass', () {
    fakeAsync((async) {
      final h = build();
      h.pacer.schedule();
      async.elapse(debounce);
      expect(h.passes, hasLength(1), reason: 'leading pass immediate after quiet period');
      // Three more bursts inside the cooldown window.
      for (var i = 0; i < 3; i++) {
        h.pacer.schedule();
        async.elapse(const Duration(seconds: 10));
      }
      expect(h.passes, hasLength(1), reason: 'cooldown holds');
      async.elapse(cooldown);
      expect(h.passes, hasLength(2), reason: 'exactly one trailing pass at the window edge');
      async.elapse(cooldown * 2);
      expect(h.passes, hasLength(2), reason: 'no further passes without new events');
      h.pacer.dispose();
    });
  });

  test('a change event after the cooldown expires refreshes promptly', () {
    fakeAsync((async) {
      final h = build();
      h.pacer.schedule();
      async.elapse(debounce);
      expect(h.passes, hasLength(1));
      async.elapse(cooldown);
      h.pacer.schedule();
      async.elapse(debounce);
      expect(h.passes, hasLength(2));
      h.pacer.dispose();
    });
  });

  test('notePass credits an external refresh: next event defers to the trailing edge', () {
    fakeAsync((async) {
      final h = build();
      h.pacer.notePass(); // pull pass committed
      h.pacer.schedule(); // push event seconds later
      async.elapse(debounce);
      expect(h.passes, isEmpty, reason: 'the fresh pull pass absorbs the immediate push pass');
      async.elapse(cooldown);
      expect(h.passes, hasLength(1), reason: 'the change still lands as the trailing pass');
      h.pacer.dispose();
    });
  });

  test('notePass defers a latched trailing pass to the refreshed window edge', () {
    fakeAsync((async) {
      final h = build();
      h.pacer.schedule();
      async.elapse(debounce); // leading pass, window opens
      h.pacer.schedule();
      async.elapse(debounce); // latched trailing
      expect(h.passes, hasLength(1));
      // A pull pass commits mid-window: the owed pass defers to the new
      // window's edge instead of firing at the old one — the pull fetch may
      // have raced the change it reported, so it is not dropped.
      async.elapse(const Duration(minutes: 1));
      h.pacer.notePass();
      async.elapse(cooldown - const Duration(minutes: 1));
      expect(h.passes, hasLength(1), reason: 'the old window edge no longer fires');
      async.elapse(const Duration(minutes: 1));
      expect(h.passes, hasLength(2), reason: 'the owed pass lands at the refreshed edge');
      h.pacer.dispose();
    });
  });

  test('a dropped pass does not spend the cooldown', () {
    fakeAsync((async) {
      final h = build();
      h.setDropped(true);
      h.pacer.schedule();
      async.elapse(debounce);
      expect(h.passes, isEmpty);
      h.setDropped(false);
      h.pacer.schedule();
      async.elapse(debounce);
      expect(h.passes, hasLength(1), reason: 'next event refreshes promptly; no cooldown was armed');
      h.pacer.dispose();
    });
  });

  test('dispose cancels scheduled work', () {
    fakeAsync((async) {
      final h = build();
      h.pacer.schedule();
      h.pacer.dispose();
      async.elapse(debounce * 2);
      expect(h.passes, isEmpty);
      expect(async.pendingTimers, isEmpty);
    });
  });
}
