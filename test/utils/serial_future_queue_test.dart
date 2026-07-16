import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/serial_future_queue.dart';

void main() {
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
