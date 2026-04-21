import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/future_extensions.dart';

void main() {
  group('namedTimeout', () {
    test('throws TimeoutException whose message includes operation name', () async {
      final never = Completer<int>().future;
      try {
        await never.namedTimeout(const Duration(milliseconds: 10), operation: 'fetchThing');
        fail('expected TimeoutException');
      } on TimeoutException catch (e) {
        expect(e.message, contains('fetchThing'));
        expect(e.message, contains('timed out'));
        expect(e.duration, const Duration(milliseconds: 10));
      }
    });

    test('passes through the original value when it completes in time', () async {
      final result = await Future.value(42).namedTimeout(const Duration(seconds: 1), operation: 'fast');
      expect(result, 42);
    });

    test('propagates non-timeout errors unchanged', () async {
      final errored = Future<int>.error(StateError('boom'));
      expect(() => errored.namedTimeout(const Duration(seconds: 1), operation: 'op'), throwsA(isA<StateError>()));
    });
  });
}
