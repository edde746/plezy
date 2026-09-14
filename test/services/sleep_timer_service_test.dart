import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:plezy/services/sleep_timer_service.dart';

// Timer ticks and wall-clock arithmetic advance together in an isolated service.
void main() {
  test('duration expiry emits one prompt without completing playback', () {
    fakeAsync((async) {
      final epoch = DateTime.utc(2026, 7, 20, 12);
      final service = SleepTimerService.withClock(() => epoch.add(async.elapsed));
      var prompts = 0;
      var pauses = 0;
      service.onPrompt.listen((_) => prompts++);
      service.bindPlayback(owner: Object(), onComplete: () => pauses++);
      service.startTimer(const Duration(seconds: 3));

      async.elapse(const Duration(seconds: 2));
      expect(service.remainingTime, const Duration(seconds: 1));
      expect(prompts, 0);

      async.elapse(const Duration(milliseconds: 999));
      expect(service.remainingTime, const Duration(milliseconds: 1));
      expect(prompts, 0);

      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      expect(prompts, 1);
      expect(pauses, 0);
      expect(service.isActive, isFalse);
      expect(service.remainingTime, isNull);

      async.elapse(const Duration(minutes: 1));
      expect(prompts, 1);
      service.dispose();
      async.flushMicrotasks();
    });
  });

  test('replacement keeps end-of-video armed and stale release cannot detach its successor', () {
    fakeAsync((async) {
      final service = SleepTimerService.withClock(() => DateTime.utc(2026, 7, 20, 12));
      final outgoing = Object();
      final successor = Object();
      final paused = <Object>[];
      var completions = 0;
      service.onCompleted.listen((_) => completions++);
      service.bindPlayback(owner: outgoing, onComplete: () => paused.add(outgoing));
      service.armEndOfVideo();

      service.bindPlayback(owner: successor, onComplete: () => paused.add(successor));
      service.unbindPlayback(outgoing);
      service.restartIfNeeded();
      expect(service.isEndOfVideoMode, isTrue);

      service.notifyVideoCompleted();
      service.notifyVideoCompleted();
      async.flushMicrotasks();
      expect(paused, [successor]);
      expect(completions, 1);
      expect(service.isActive, isFalse);
      service.dispose();
      async.flushMicrotasks();
    });
  });

  test('replacement preserves the countdown and its binding survives duration completion', () {
    fakeAsync((async) {
      final epoch = DateTime.utc(2026, 7, 20, 12);
      final service = SleepTimerService.withClock(() => epoch.add(async.elapsed));
      final outgoing = Object();
      final successor = Object();
      final paused = <Object>[];
      var prompts = 0;
      service.onPrompt.listen((_) => prompts++);
      service.bindPlayback(owner: outgoing, onComplete: () => paused.add(outgoing));
      service.startTimer(const Duration(seconds: 6));
      async.elapse(const Duration(seconds: 2));
      final deadline = service.endTime;

      service.bindPlayback(owner: successor, onComplete: () => paused.add(successor));
      service.unbindPlayback(outgoing);
      service.restartIfNeeded();
      expect(service.endTime, deadline);
      expect(service.remainingTime, const Duration(seconds: 4));
      expect(service.isEndOfVideoMode, isFalse);

      async.elapse(const Duration(seconds: 3));
      expect(prompts, 0);
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(prompts, 1);
      expect(paused, isEmpty);

      // Duration expiry prompts instead of pausing. A later stop selection must
      // still target the successor, without the UI binding a callback again.
      service.armEndOfVideo();
      service.notifyVideoCompleted();
      expect(paused, [successor]);
      service.dispose();
      async.flushMicrotasks();
    });
  });

  test('extension delays the prompt but restart uses the selected duration and keeps playback bound', () {
    fakeAsync((async) {
      final epoch = DateTime.utc(2026, 7, 20, 12);
      final service = SleepTimerService.withClock(() => epoch.add(async.elapsed));
      var prompts = 0;
      var pauses = 0;
      service.onPrompt.listen((_) => prompts++);
      service.bindPlayback(owner: Object(), onComplete: () => pauses++);
      service.startTimer(const Duration(seconds: 2));
      service.extendTimer(const Duration(seconds: 2));

      async.elapse(const Duration(seconds: 2));
      expect(prompts, 0);
      expect(service.remainingTime, const Duration(seconds: 2));
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(prompts, 1);

      service.restartTimer();
      expect(service.remainingTime, const Duration(seconds: 2));
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(prompts, 2);
      expect(pauses, 0);

      service.armEndOfVideo();
      service.notifyVideoCompleted();
      expect(pauses, 1);
      service.dispose();
      async.flushMicrotasks();
    });
  });

  test('ordinary exit restarts a duration timer once with its original selection on reentry', () {
    fakeAsync((async) {
      final epoch = DateTime.utc(2026, 7, 20, 12);
      final service = SleepTimerService.withClock(() => epoch.add(async.elapsed));
      final outgoing = Object();
      final successor = Object();
      final paused = <Object>[];
      var prompts = 0;
      service.onPrompt.listen((_) => prompts++);
      service.bindPlayback(owner: outgoing, onComplete: () => paused.add(outgoing));
      service.startTimer(const Duration(seconds: 4));
      service.extendTimer(const Duration(seconds: 2));
      async.elapse(const Duration(seconds: 2));
      service.unbindPlayback(outgoing);
      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();
      expect(prompts, 1);

      service.bindPlayback(owner: successor, onComplete: () => paused.add(successor));
      service.restartIfNeeded();
      expect(service.remainingTime, const Duration(seconds: 4));
      async.elapse(const Duration(seconds: 1));
      service.restartIfNeeded();
      expect(service.remainingTime, const Duration(seconds: 3));
      async.elapse(const Duration(seconds: 3));
      async.flushMicrotasks();
      expect(prompts, 2);
      expect(paused, isEmpty);

      service.armEndOfVideo();
      service.notifyVideoCompleted();
      expect(paused, [successor]);
      service.dispose();
      async.flushMicrotasks();
    });
  });

  test('exiting while the duration prompt is pending restarts on the next playback', () {
    fakeAsync((async) {
      final epoch = DateTime.utc(2026, 7, 20, 12);
      final service = SleepTimerService.withClock(() => epoch.add(async.elapsed));
      final outgoing = Object();
      var prompts = 0;
      service.onPrompt.listen((_) => prompts++);
      service.bindPlayback(owner: outgoing, onComplete: () {});
      service.startTimer(const Duration(seconds: 2));
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(prompts, 1);
      expect(service.isActive, isFalse);

      service.unbindPlayback(outgoing);
      service.bindPlayback(owner: Object(), onComplete: () {});
      service.restartIfNeeded();
      async.elapse(const Duration(seconds: 1));
      expect(prompts, 1);
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(prompts, 2);
      service.dispose();
      async.flushMicrotasks();
    });
  });

  test('ordinary exit releases playback and reentry restores end-of-video with a fresh owner', () {
    fakeAsync((async) {
      final service = SleepTimerService.withClock(() => DateTime.utc(2026, 7, 20, 12));
      final outgoing = Object();
      final successor = Object();
      final paused = <Object>[];
      service.bindPlayback(owner: outgoing, onComplete: () => paused.add(outgoing));
      service.armEndOfVideo();
      service.unbindPlayback(outgoing);

      // Completion while no playback is bound must not retain the old player.
      service.notifyVideoCompleted();
      expect(paused, isEmpty);
      service.bindPlayback(owner: successor, onComplete: () => paused.add(successor));
      service.restartIfNeeded();
      expect(service.isEndOfVideoMode, isTrue);
      service.notifyVideoCompleted();
      expect(paused, [successor]);
      service.dispose();
      async.flushMicrotasks();
    });
  });

  test('cancelling a duration prevents its prompt and restart without detaching playback', () {
    fakeAsync((async) {
      final epoch = DateTime.utc(2026, 7, 20, 12);
      final service = SleepTimerService.withClock(() => epoch.add(async.elapsed));
      var prompts = 0;
      var pauses = 0;
      service.onPrompt.listen((_) => prompts++);
      service.bindPlayback(owner: Object(), onComplete: () => pauses++);
      service.startTimer(const Duration(seconds: 2));
      async.elapse(const Duration(seconds: 1));
      service.cancelTimer();
      service.restartTimer();
      service.restartIfNeeded();
      async.elapse(const Duration(minutes: 1));
      expect(prompts, 0);
      expect(service.isActive, isFalse);

      service.armEndOfVideo();
      service.notifyVideoCompleted();
      expect(pauses, 1);
      service.dispose();
      async.flushMicrotasks();
    });
  });

  test('cancelling a pending end-of-video restart cannot revive the old mode', () {
    fakeAsync((async) {
      final epoch = DateTime.utc(2026, 7, 20, 12);
      final service = SleepTimerService.withClock(() => epoch.add(async.elapsed));
      final outgoing = Object();
      var prompts = 0;
      var pauses = 0;
      service.onPrompt.listen((_) => prompts++);
      service.bindPlayback(owner: outgoing, onComplete: () => pauses++);
      service.armEndOfVideo();
      service.unbindPlayback(outgoing);
      service.notifyVideoCompleted();
      service.cancelTimer();

      service.bindPlayback(owner: Object(), onComplete: () => pauses++);
      service.restartIfNeeded();
      service.notifyVideoCompleted();
      expect(service.isActive, isFalse);
      expect(pauses, 0);

      service.startTimer(const Duration(seconds: 2));
      service.restartIfNeeded();
      service.notifyVideoCompleted();
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(prompts, 1);
      expect(pauses, 0);
      service.dispose();
      async.flushMicrotasks();
    });
  });

  test('changing duration cancels the earlier deadline rather than adding a second timer', () {
    fakeAsync((async) {
      final epoch = DateTime.utc(2026, 7, 20, 12);
      final service = SleepTimerService.withClock(() => epoch.add(async.elapsed));
      var prompts = 0;
      service.onPrompt.listen((_) => prompts++);
      service.startTimer(const Duration(seconds: 2));
      async.elapse(const Duration(seconds: 1));
      service.startTimer(const Duration(seconds: 5));

      async.elapse(const Duration(seconds: 1));
      expect(prompts, 0);
      async.elapse(const Duration(seconds: 4));
      async.flushMicrotasks();
      expect(prompts, 1);
      async.elapse(const Duration(seconds: 5));
      expect(prompts, 1);
      service.dispose();
      async.flushMicrotasks();
    });
  });

  test('switching timer modes only responds to the selected completion trigger', () {
    fakeAsync((async) {
      final epoch = DateTime.utc(2026, 7, 20, 12);
      final service = SleepTimerService.withClock(() => epoch.add(async.elapsed));
      var prompts = 0;
      var pauses = 0;
      service.onPrompt.listen((_) => prompts++);
      service.bindPlayback(owner: Object(), onComplete: () => pauses++);
      service.startTimer(const Duration(seconds: 2));
      service.armEndOfVideo();
      async.elapse(const Duration(seconds: 3));
      expect(prompts, 0);
      service.notifyVideoCompleted();
      expect(pauses, 1);

      service.armEndOfVideo();
      service.startTimer(const Duration(seconds: 2));
      service.notifyVideoCompleted();
      expect(pauses, 1);
      async.elapse(const Duration(seconds: 2));
      async.flushMicrotasks();
      expect(prompts, 1);
      service.dispose();
      async.flushMicrotasks();
    });
  });
}
