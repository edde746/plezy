import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/serial_future_queue.dart';

void main() {
  test('an idle queue starts work on the current clock after its previous operation completed', () async {
    final queue = SerialFutureQueue();
    await queue.run(() async => 1);

    fakeAsync((clock) {
      var completed = false;
      queue.run(() async => 2).then((_) => completed = true);
      clock.flushMicrotasks();
      expect(completed, isTrue, reason: 'an idle queue must not retain the previous async zone');
    });
  });

  test('an operation detached by reset cannot clear the replacement queue tail', () async {
    final queue = SerialFutureQueue();
    final oldRelease = Completer<void>();
    final newRelease = Completer<void>();
    final old = queue.run(() => oldRelease.future);
    queue.reset();
    final replacement = queue.run(() => newRelease.future);
    oldRelease.complete();
    await old;

    var thirdStarted = false;
    final third = queue.run(() async => thirdStarted = true);
    await Future<void>.delayed(Duration.zero);
    expect(thirdStarted, isFalse);
    newRelease.complete();
    await replacement;
    await third;
    expect(thirdStarted, isTrue);
  });

  test('a failed operation does not poison the next queued operation', () async {
    final queue = SerialFutureQueue();

    await expectLater(queue.run<void>(() async => throw StateError('failed')), throwsStateError);
    expect(await queue.run(() async => 42), 42);
    await queue.settled;
  });

  test('operations remain serialized while callers receive their own results', () async {
    final queue = SerialFutureQueue();
    final firstStarted = Completer<void>();
    final releaseFirst = Completer<void>();
    var secondStarted = false;

    final first = queue.run(() async {
      firstStarted.complete();
      await releaseFirst.future;
      return 'first';
    });
    final second = queue.run(() async {
      secondStarted = true;
      return 'second';
    });

    await firstStarted.future;
    await Future<void>.delayed(Duration.zero);
    expect(secondStarted, isFalse);

    releaseFirst.complete();
    expect(await first, 'first');
    expect(await second, 'second');
  });
}
