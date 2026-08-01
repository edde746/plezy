import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:plezy/services/sleep_timer_service.dart';

// Duration-based transitions use an injected clock with fake_async so timer
// ticks and wall-clock arithmetic advance together. The production singleton
// remains covered separately for its shared-instance contract.

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

    test('endTime is based on the injected clock', () {
      final now = DateTime.utc(2026, 7, 20, 12);
      final service = SleepTimerService.withClock(() => now);

      service.startTimer(const Duration(minutes: 10), () {});

      expect(service.endTime, now.add(const Duration(minutes: 10)));
      service.dispose();
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
    test('clears all state and prevents a later prompt', () {
      fakeAsync((async) {
        final epoch = DateTime.utc(2026, 7, 20, 12);
        final service = SleepTimerService.withClock(() => epoch.add(async.elapsed));
        var prompts = 0;
        service.onPrompt.listen((_) => prompts++);
        service.startTimer(const Duration(seconds: 2), () {});

        async.elapse(const Duration(seconds: 1));
        service.cancelTimer();
        async.elapse(const Duration(minutes: 1));
        async.flushMicrotasks();

        expect(service.isActive, isFalse);
        expect(service.endTime, isNull);
        expect(service.duration, isNull);
        expect(service.originalDuration, isNull);
        expect(prompts, 0);
        service.dispose();
        async.flushMicrotasks();
      });
    });

    test('cancelTimer on idle service is a no-op', () {
      timer.cancelTimer();
      expect(timer.isActive, isFalse);
    });
  });

  group('duration transitions', () {
    test('remaining time elapses and emits one prompt on the first due tick', () {
      fakeAsync((async) {
        final epoch = DateTime.utc(2026, 7, 20, 12);
        final service = SleepTimerService.withClock(() => epoch.add(async.elapsed));
        var prompts = 0;
        var completions = 0;
        service.onPrompt.listen((_) => prompts++);

        service.startTimer(const Duration(seconds: 3), () => completions++);
        expect(service.remainingTime, const Duration(seconds: 3));

        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(service.remainingTime, const Duration(seconds: 1));
        expect(prompts, 0);

        async.elapse(const Duration(milliseconds: 999));
        async.flushMicrotasks();
        expect(service.remainingTime, const Duration(milliseconds: 1));
        expect(prompts, 0);

        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();
        expect(prompts, 1);
        expect(completions, 0);
        expect(service.isActive, isFalse);
        expect(service.remainingTime, isNull);

        async.elapse(const Duration(minutes: 1));
        async.flushMicrotasks();
        expect(prompts, 1);
        service.dispose();
        async.flushMicrotasks();
      });
    });

    test('restartTimer after a prompt restarts the original duration and callback', () {
      fakeAsync((async) {
        final epoch = DateTime.utc(2026, 7, 20, 12);
        final service = SleepTimerService.withClock(() => epoch.add(async.elapsed));
        var prompts = 0;
        var completions = 0;
        service.onPrompt.listen((_) => prompts++);

        service.startTimer(const Duration(seconds: 2), () => completions++);
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(prompts, 1);
        expect(service.isActive, isFalse);

        service.restartTimer();
        expect(service.isActive, isTrue);
        expect(service.endTime, epoch.add(const Duration(seconds: 4)));
        expect(service.remainingTime, const Duration(seconds: 2));

        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(prompts, 2);
        expect(completions, 0);

        service.executeCompletion();
        async.flushMicrotasks();
        expect(completions, 1);
        service.dispose();
        async.flushMicrotasks();
      });
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
  // armEndOfVideo / notifyVideoCompleted
  // ============================================================

  group('armEndOfVideo', () {
    test('sets isActive and isEndOfVideoMode without starting a periodic timer', () {
      timer.armEndOfVideo(() {});
      try {
        expect(timer.isActive, isTrue);
        expect(timer.isEndOfVideoMode, isTrue);
        // No fixed duration / endTime in this mode — countdown UIs must
        // detect end-of-video mode instead of falling through.
        expect(timer.endTime, isNull);
        expect(timer.duration, isNull);
        expect(timer.originalDuration, isNull);
        expect(timer.remainingTime, isNull);
      } finally {
        timer.cancelTimer();
      }
    });

    test('replaces any running duration-based timer', () {
      var firstFired = false;
      timer.startTimer(const Duration(minutes: 30), () => firstFired = true);
      expect(timer.isEndOfVideoMode, isFalse);

      timer.armEndOfVideo(() {});
      expect(timer.isEndOfVideoMode, isTrue);
      // The previous duration is gone — armEndOfVideo calls cancelTimer first.
      expect(timer.originalDuration, isNull);
      expect(firstFired, isFalse);

      timer.cancelTimer();
    });

    test('cancelTimer clears end-of-video mode', () {
      timer.armEndOfVideo(() {});
      timer.cancelTimer();
      expect(timer.isActive, isFalse);
      expect(timer.isEndOfVideoMode, isFalse);
    });

    test('arming notifies listeners', () {
      var notifications = 0;
      void listener() => notifications++;
      timer.addListener(listener);

      timer.armEndOfVideo(() {});
      // cancelTimer (called inside armEndOfVideo when idle) is gated on existing
      // state, so a fresh service only emits the single arm notification.
      expect(notifications, greaterThanOrEqualTo(1));

      timer.removeListener(listener);
      timer.cancelTimer();
    });
  });

  group('notifyVideoCompleted', () {
    test('fires the stored callback and emits onCompleted', () async {
      var fired = 0;
      var completedFired = 0;
      final sub = timer.onCompleted.listen((_) => completedFired++);

      timer.armEndOfVideo(() => fired++);
      timer.notifyVideoCompleted();
      await Future<void>.delayed(Duration.zero);

      expect(fired, 1);
      expect(completedFired, 1);
      // Mode is consumed after firing.
      expect(timer.isEndOfVideoMode, isFalse);
      expect(timer.isActive, isFalse);

      await sub.cancel();
    });

    test('does nothing when end-of-video mode is not armed', () async {
      var completedFired = 0;
      final sub = timer.onCompleted.listen((_) => completedFired++);

      timer.notifyVideoCompleted();
      await Future<void>.delayed(Duration.zero);
      expect(completedFired, 0);

      // Also safe when a duration timer is running — should not interfere.
      timer.startTimer(const Duration(minutes: 30), () {});
      timer.notifyVideoCompleted();
      await Future<void>.delayed(Duration.zero);
      expect(completedFired, 0);
      expect(timer.isActive, isTrue);

      await sub.cancel();
      timer.cancelTimer();
    });
  });

  group('end-of-video + restartIfNeeded', () {
    test('preserves the end-of-video mode across a playback session swap', () {
      timer.armEndOfVideo(() {});
      timer.markNeedsRestart();

      var newCallbackHooked = false;
      timer.restartIfNeeded(() => newCallbackHooked = true);

      expect(timer.isActive, isTrue);
      expect(timer.isEndOfVideoMode, isTrue);
      // restartIfNeeded re-arms — the consumer callback should be wired up
      // but not yet invoked.
      expect(newCallbackHooked, isFalse);

      timer.cancelTimer();
    });
  });
}
