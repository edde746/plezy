import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/media_server_retry.dart';

void main() {
  group('retryTransientMediaServerCall', () {
    test('retries transient failures in timeout order', () async {
      const timeouts = [Duration(seconds: 10), Duration(seconds: 5), Duration(milliseconds: 2500)];
      final seenTimeouts = <Duration>[];
      final aborts = <AbortController>[];

      final result = await retryTransientMediaServerCall<String>(
        operation: 'test operation',
        attemptTimeouts: timeouts,
        call: (timeout, abort) async {
          seenTimeouts.add(timeout);
          aborts.add(abort);
          if (seenTimeouts.length < 3) {
            throw MediaServerHttpException(type: MediaServerHttpErrorType.connectionTimeout, message: 'timed out');
          }
          return 'ok';
        },
      );

      expect(result, 'ok');
      expect(seenTimeouts, timeouts);
      expect(aborts[0].isAborted, isTrue);
      expect(aborts[1].isAborted, isTrue);
      expect(aborts[2].isAborted, isFalse);
    });

    test('does not retry non-transient failures', () async {
      var attempts = 0;

      await expectLater(
        retryTransientMediaServerCall<void>(
          operation: 'test operation',
          attemptTimeouts: const [Duration(seconds: 10), Duration(seconds: 5)],
          call: (_, _) async {
            attempts++;
            throw MediaServerHttpException(
              type: MediaServerHttpErrorType.unknown,
              statusCode: 404,
              message: 'HTTP 404',
            );
          },
        ),
        throwsA(isA<MediaServerHttpException>().having((e) => e.statusCode, 'statusCode', 404)),
      );

      expect(attempts, 1);
    });

    test('rethrows final transient failure after exhausting attempts', () async {
      var attempts = 0;

      await expectLater(
        retryTransientMediaServerCall<void>(
          operation: 'test operation',
          attemptTimeouts: const [Duration(seconds: 10), Duration(seconds: 5), Duration(milliseconds: 2500)],
          call: (_, _) async {
            attempts++;
            throw MediaServerHttpException(type: MediaServerHttpErrorType.receiveTimeout, message: 'receive timed out');
          },
        ),
        throwsA(isA<MediaServerHttpException>().having((e) => e.type, 'type', MediaServerHttpErrorType.receiveTimeout)),
      );

      expect(attempts, 3);
    });
  });
}
