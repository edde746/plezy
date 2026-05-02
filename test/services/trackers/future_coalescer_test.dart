import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/trackers/future_coalescer.dart';

void main() {
  test('FutureCoalescer shares one in-flight future', () async {
    final coalescer = FutureCoalescer<int>();
    final completer = Completer<int>();
    var calls = 0;

    Future<int> create() {
      calls++;
      return completer.future;
    }

    final first = coalescer.run(create);
    final second = coalescer.run(create);

    expect(identical(first, second), isTrue);
    expect(calls, 1);

    completer.complete(42);
    expect(await first, 42);
  });

  test('FutureCoalescer allows a new future after completion', () async {
    final coalescer = FutureCoalescer<int>();
    var next = 0;

    final first = await coalescer.run(() async => ++next);
    final second = await coalescer.run(() async => ++next);

    expect(first, 1);
    expect(second, 2);
  });
}
