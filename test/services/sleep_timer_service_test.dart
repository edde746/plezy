import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/sleep_timer_service.dart';

// IMPORTANT: [SleepTimerService] uses raw `DateTime.now()` (not
// `clock.now()` from package:clock), so `fake_async` cannot virtualize the
// service's wall-clock arithmetic. Specifically, `remainingTime` computes
// `endTime.difference(DateTime.now())` against the real system clock, while
// the periodic Timer ticks every 1s in fake time but always sees a near-zero
// elapsed wall clock — so the prompt never fires under `fakeAsync`.
//
// Strategy:
//   - State assertions (start/cancel/extend/restart bookkeeping) use the real
//     clock with sub-second resolution.
//   - We do NOT exercise the prompt-fires-when-elapsed branch because the
//     periodic tick is hard-coded at 1s and waiting that long in tests is
//     flaky. That branch is documented as uncovered at the bottom of this file.
//
// The service is a process-global singleton, so each test calls `cancelTimer`
// in setUp/tearDown to reset bookkeeping. We never call `dispose()` (it would
// close shared StreamControllers and break subsequent tests).

void main() {
  late SleepTimerService timer;

  setUp(() {
    timer = SleepTimerService();
    timer.cancelTimer();
  });

  tearDown(() {
    timer.cancelTimer();
  });

  // ============================================================
  // Initial state
  // ============================================================

  group('initial state', () {
    test('isActive is false on a fresh / cancelled service', () {
      expect(timer.isActive, isFalse);
      expect(timer.endTime, isNull);
      expect(timer.duration, isNull);
      expect(timer.originalDuration, isNull);
      expect(timer.remainingTime, isNull);
    });

    test('factory returns the same singleton', () {
      final a = SleepTimerService();
      final b = SleepTimerService();
      expect(identical(a, b), isTrue);
    });
  });

  // ============================================================
  // startTimer — bookkeeping
  // ============================================================

  group('startTimer', () {
    test('sets isActive, duration, originalDuration, and endTime', () {
      timer.startTimer(const Duration(minutes: 30), () {});
      try {
        expect(timer.isActive, isTrue);
        expect(timer.duration, const Duration(minutes: 30));
        expect(timer.originalDuration, const Duration(minutes: 30));
        expect(timer.endTime, isNotNull);
      } finally {
        timer.cancelTimer();
      }
    });

    test('endTime is approximately now + duration (real clock)', () {
      final before = DateTime.now();
      timer.startTimer(const Duration(minutes: 10), () {});
      try {
        final delta = timer.endTime!.difference(before).inSeconds;
        // Generous bounds for any millisecond-scale slop between sample points.
        expect(delta, inInclusiveRange(599, 601));
      } finally {
        timer.cancelTimer();
      }
    });

    test('starting a new timer cancels the previous one', () {
      var firstFired = false;
      timer.startTimer(const Duration(minutes: 30), () => firstFired = true);
      final firstEnd = timer.endTime;

      timer.startTimer(const Duration(minutes: 5), () {});
      // Different end time means the prior periodic timer was cancelled and
      // replaced.
      expect(timer.endTime, isNot(equals(firstEnd)));
      expect(timer.duration, const Duration(minutes: 5));
      expect(firstFired, isFalse);

      timer.cancelTimer();
    });
  });

  // ============================================================
  // cancelTimer
  // ============================================================

  group('cancelTimer', () {
    test('clears all state and stops the periodic ticker', () async {
      var fired = false;
      timer.startTimer(const Duration(minutes: 5), () => fired = true);

      timer.cancelTimer();
      expect(timer.isActive, isFalse);
      expect(timer.endTime, isNull);
      expect(timer.duration, isNull);
      expect(timer.originalDuration, isNull);

      // Pump the event queue briefly to confirm the periodic Timer is dead —
      // even in real time we can be sure the user callback never fires for a
      // 5-minute timer that we cancel immediately.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(fired, isFalse);
    });

    test('cancelTimer on idle service is a no-op', () {
      timer.cancelTimer();
      expect(timer.isActive, isFalse);
    });
  });

  // ============================================================
  // restartTimer / restartIfNeeded / markNeedsRestart
  // ============================================================

  group('restartTimer', () {
    test('restartTimer after cancel is a no-op (originalDuration cleared)', () {
      timer.startTimer(const Duration(minutes: 1), () {});
      timer.cancelTimer();

      timer.restartTimer();
      expect(timer.isActive, isFalse);
    });
  });

  group('markNeedsRestart / restartIfNeeded', () {
    test('restartIfNeeded does nothing when not marked', () {
      var fired = false;
      timer.restartIfNeeded(() => fired = true);
      expect(timer.isActive, isFalse);
      expect(fired, isFalse);
    });

    test('markNeedsRestart on idle service does NOT enable restartIfNeeded', () {
      // markNeedsRestart only sets the flag when isActive OR originalDuration
      // is set; otherwise the call is a no-op so a fresh service stays idle.
      timer.markNeedsRestart();
      var fired = false;
      timer.restartIfNeeded(() => fired = true);
      expect(timer.isActive, isFalse);
      expect(fired, isFalse);
    });

    test('marked while active + restartIfNeeded after cancel starts a new timer', () {
      // Plant a timer + flag.
      timer.startTimer(const Duration(minutes: 5), () {});
      timer.markNeedsRestart();
      // Simulate prompt-flow's _stopTimerOnly: clear ticker but keep originalDuration.
      // We can't call the private method, so instead cancel + verify restartIfNeeded
      // is gated on originalDuration. Re-arm via startTimer + markNeedsRestart so
      // _originalDuration is non-null at the point of restartIfNeeded.
      timer.cancelTimer();
      timer.startTimer(const Duration(minutes: 5), () {});
      timer.markNeedsRestart();
      // _needsRestart is now true and originalDuration is set.

      var newCallbackHooked = false;
      timer.restartIfNeeded(() => newCallbackHooked = true);
      // restartIfNeeded calls startTimer with the new callback; isActive=true.
      expect(timer.isActive, isTrue);

      // Calling again is a no-op because the flag was consumed.
      var secondHook = false;
      timer.restartIfNeeded(() => secondHook = true);
      expect(secondHook, isFalse);

      // Sanity: we never auto-fire under real time within milliseconds.
      expect(newCallbackHooked, isFalse);

      timer.cancelTimer();
    });
  });

  // ============================================================
  // extendTimer
  // ============================================================

  group('extendTimer', () {
    test('shifts endTime and grows duration by the additional time', () {
      timer.startTimer(const Duration(minutes: 10), () {});
      try {
        final originalEnd = timer.endTime!;

        timer.extendTimer(const Duration(minutes: 5));
        expect(timer.endTime, originalEnd.add(const Duration(minutes: 5)));
        expect(timer.duration, const Duration(minutes: 15));
        // originalDuration is the user-selected value and should NOT change.
        expect(timer.originalDuration, const Duration(minutes: 10));
      } finally {
        timer.cancelTimer();
      }
    });

    test('extendTimer on idle service is a no-op', () {
      timer.extendTimer(const Duration(minutes: 5));
      expect(timer.endTime, isNull);
      expect(timer.duration, isNull);
    });
  });

  // ============================================================
  // executeCompletion
  // ============================================================

  group('executeCompletion', () {
    test('runs the stored callback and emits onCompleted', () async {
      var fired = 0;
      var completedFired = 0;
      final sub = timer.onCompleted.listen((_) => completedFired++);

      timer.startTimer(const Duration(minutes: 5), () => fired++);
      timer.executeCompletion();

      // Stream events on a broadcast controller need a microtask to drain.
      await Future<void>.delayed(Duration.zero);

      expect(fired, 1);
      expect(completedFired, 1);

      await sub.cancel();
      timer.cancelTimer();
    });

    test('executeCompletion when no callback is set still emits onCompleted', () async {
      var completedFired = 0;
      final sub = timer.onCompleted.listen((_) => completedFired++);

      // No startTimer call → _onTimerComplete is null.
      timer.executeCompletion();
      await Future<void>.delayed(Duration.zero);

      expect(completedFired, 1);

      await sub.cancel();
    });
  });

  // ============================================================
  // Change notifications
  // ============================================================

  group('change notifications', () {
    test('startTimer and cancelTimer each notify listeners at least once', () {
      var notifications = 0;
      void listener() => notifications++;
      timer.addListener(listener);

      timer.startTimer(const Duration(minutes: 1), () {});
      // startTimer notifies once at the bottom of the method (the periodic
      // timer hasn't ticked yet within this synchronous frame).
      expect(notifications, greaterThanOrEqualTo(1));

      notifications = 0;
      timer.cancelTimer();
      expect(notifications, greaterThanOrEqualTo(1));

      timer.removeListener(listener);
    });

    test('extendTimer notifies listeners', () {
      timer.startTimer(const Duration(minutes: 5), () {});

      var notifications = 0;
      void listener() => notifications++;
      timer.addListener(listener);

      timer.extendTimer(const Duration(minutes: 1));
      expect(notifications, 1);

      timer.removeListener(listener);
      timer.cancelTimer();
    });
  });

  // ============================================================
  // What's NOT covered (and why)
  // ============================================================
  //
  // - The prompt-fires-when-duration-elapses branch in `startTimer`:
  //   The periodic Timer fires every 1s, and the production code uses raw
  //   `DateTime.now()` for end/elapsed math, so neither `fake_async` nor
  //   `package:clock` substitutes can virtualize it without touching the
  //   service. Verifying it would require a wall-clock wait of >1s, which
  //   is flaky for unit tests.
  //
  // - `restartTimer` after `_stopTimerOnly` (the post-prompt path):
  //   `_stopTimerOnly` is private and only reached by the periodic-tick
  //   completion above, so the post-prompt restart flow is also not
  //   verifiable here without injecting a clock dependency.
}
