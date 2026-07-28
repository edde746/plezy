import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/screens/video_player/wakelock_controller.dart';

void main() {
  group('WakelockController', () {
    test('drains enable then disable without overlapping platform work', () async {
      final platform = _ControlledPlatformToggle();
      final controller = WakelockController(platformToggle: platform.call);

      final enable = controller.setEnabled(true);
      await _flushTasks();
      expect(platform.calls, [true]);

      final disable = controller.setEnabled(false);
      await _flushTasks();
      expect(platform.calls, [true]);
      expect(platform.maxConcurrent, 1);

      platform.succeedNext();
      await _flushTasks();
      expect(platform.calls, [true, false]);

      platform.succeedNext();
      await Future.wait([enable, disable]);

      expect(platform.completed, [true, false]);
      expect(platform.active, 0);
      expect(platform.maxConcurrent, 1);
    });

    test('drains disable then enable to the latest desired state', () async {
      final platform = _ControlledPlatformToggle();
      final controller = WakelockController(platformToggle: platform.call);

      final initialEnable = controller.setEnabled(true);
      await _flushTasks();
      platform.succeedNext();
      await initialEnable;

      final disable = controller.setEnabled(false);
      await _flushTasks();
      expect(platform.calls, [true, false]);

      final enable = controller.setEnabled(true);
      await _flushTasks();
      expect(platform.calls, [true, false]);

      platform.succeedNext();
      await _flushTasks();
      expect(platform.calls, [true, false, true]);

      platform.succeedNext();
      await Future.wait([disable, enable]);

      expect(platform.completed, [true, false, true]);
      expect(platform.maxConcurrent, 1);
    });

    test('absorbs acquisition failure and retries only when requested', () async {
      var calls = 0;
      final controller = WakelockController(
        platformToggle: (enabled) async {
          calls++;
          expect(enabled, isTrue);
          if (calls == 1) throw StateError('enable failed');
        },
      );

      await expectLater(controller.setEnabled(true), completes);
      await _flushTasks();
      expect(calls, 1, reason: 'a failure must not start an automatic retry loop');

      await expectLater(controller.setEnabled(true), completes);
      expect(calls, 2, reason: 'the failed state must remain explicitly retryable');

      await controller.setEnabled(true);
      expect(calls, 2, reason: 'only successful platform work becomes effective');
    });

    test('applies a newer opposing request after acquisition fails', () async {
      final platform = _ControlledPlatformToggle();
      final controller = WakelockController(platformToggle: platform.call);

      final enable = controller.setEnabled(true);
      await _flushTasks();
      final disable = controller.setEnabled(false);

      platform.failNext(StateError('enable failed'));
      await _flushTasks();
      expect(platform.calls, [true, false]);
      expect(platform.maxConcurrent, 1);

      platform.succeedNext();
      await expectLater(Future.wait([enable, disable]), completes);

      expect(platform.completed, [false]);
      expect(platform.active, 0);
    });

    test('keeps effective state after release failure and retries disable', () async {
      var disableAttempts = 0;
      final calls = <bool>[];
      final controller = WakelockController(
        platformToggle: (enabled) async {
          calls.add(enabled);
          if (!enabled && disableAttempts++ == 0) {
            throw StateError('disable failed');
          }
        },
      );

      await controller.setEnabled(true);
      await expectLater(controller.setEnabled(false), completes);
      expect(calls, [true, false]);

      await expectLater(controller.setEnabled(false), completes);
      expect(calls, [true, false, false]);

      await controller.setEnabled(false);
      expect(calls, [true, false, false]);
    });

    test('detached teardown disable drains after an in-flight enable', () async {
      final platform = _ControlledPlatformToggle();
      final controller = WakelockController(platformToggle: platform.call);

      final enable = controller.setEnabled(true);
      await _flushTasks();
      unawaited(controller.setEnabled(false));

      platform.succeedNext();
      await _flushTasks();
      expect(platform.calls, [true, false]);

      platform.succeedNext();
      await enable;
      await _flushTasks();

      expect(platform.completed, [true, false]);
      expect(platform.active, 0);
      expect(platform.maxConcurrent, 1);
    });
  });
}

Future<void> _flushTasks() => Future<void>.delayed(Duration.zero);

class _ControlledPlatformToggle {
  final calls = <bool>[];
  final completed = <bool>[];
  final _pending = <({bool enabled, Completer<void> completer})>[];

  int active = 0;
  int maxConcurrent = 0;

  Future<void> call(bool enabled) async {
    calls.add(enabled);
    active++;
    if (active > maxConcurrent) maxConcurrent = active;

    final completer = Completer<void>();
    _pending.add((enabled: enabled, completer: completer));
    try {
      await completer.future;
      completed.add(enabled);
    } finally {
      active--;
    }
  }

  void succeedNext() => _pending.removeAt(0).completer.complete();

  void failNext(Object error) => _pending.removeAt(0).completer.completeError(error);
}
