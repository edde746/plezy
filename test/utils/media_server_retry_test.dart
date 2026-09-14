import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/media_server_retry.dart';

MediaServerHttpException _error(MediaServerHttpErrorType type) =>
    MediaServerHttpException(type: type, message: type.name);

void main() {
  group('retryTransientMediaServerCall', () {
    test('runs the call once with the whole deadline as its budget', () async {
      final seenTimeouts = <Duration>[];

      final result = await retryTransientMediaServerCall<String>(
        operation: 'test operation',
        deadline: const Duration(seconds: 20),
        call: (timeout, _) async {
          seenTimeouts.add(timeout);
          return 'ok';
        },
      );

      expect(result, 'ok');
      expect(seenTimeouts, [const Duration(seconds: 20)]);
    });

    // The regression this whole policy exists for: `http.Client.send` resolves
    // on response HEADERS, so a slow-but-alive server surfaces as
    // connectionTimeout. Replaying it made the server re-run the same query and
    // turned an 11s answer into an empty row after 23s (#1784).
    test('does not replay a timeout — the server is working, just slow', () async {
      var attempts = 0;

      await expectLater(
        retryTransientMediaServerCall<void>(
          operation: 'test operation',
          deadline: const Duration(seconds: 20),
          call: (_, _) async {
            attempts++;
            throw _error(MediaServerHttpErrorType.connectionTimeout);
          },
        ),
        throwsA(
          isA<MediaServerHttpException>().having((e) => e.type, 'type', MediaServerHttpErrorType.connectionTimeout),
        ),
      );

      expect(attempts, 1);
    });

    test('a slow response that lands inside the deadline resolves, and is requested once', () {
      fakeAsync((async) {
        var attempts = 0;
        Object? result;

        // Answers at T+11s, well past the old 10s first-attempt budget.
        retryTransientMediaServerCall<String>(
          operation: 'test operation',
          deadline: const Duration(seconds: 20),
          call: (_, _) async {
            attempts++;
            await Future<void>.delayed(const Duration(seconds: 11));
            return 'late but fine';
          },
        ).then((value) => result = value);

        async.elapse(const Duration(seconds: 10, milliseconds: 900));
        expect(result, isNull, reason: 'still in flight');
        expect(attempts, 1);

        async.elapse(const Duration(milliseconds: 200));
        expect(result, 'late but fine');
        expect(attempts, 1, reason: 'never replayed');
      });
    });

    test('retries an immediate connection error', () {
      fakeAsync((async) {
        final aborts = <AbortController>[];
        Object? result;

        retryTransientMediaServerCall<String>(
          operation: 'test operation',
          deadline: const Duration(seconds: 20),
          call: (_, abort) async {
            aborts.add(abort);
            await Future<void>.delayed(const Duration(seconds: 1));
            if (aborts.length < 3) throw _error(MediaServerHttpErrorType.connectionError);
            return 'ok';
          },
        ).then((value) => result = value);

        async.elapse(const Duration(seconds: 5));

        expect(result, 'ok');
        expect(aborts, hasLength(3));
        expect(aborts[0].isAborted, isTrue);
        expect(aborts[1].isAborted, isTrue);
        expect(aborts[2].isAborted, isFalse);
      });
    });

    test('gives up at the deadline and aborts the in-flight request', () {
      fakeAsync((async) {
        var attempts = 0;
        AbortController? last;
        Duration? settledAt;
        Object? error;

        retryTransientMediaServerCall<void>(
          operation: 'test operation',
          deadline: const Duration(seconds: 10),
          call: (_, abort) async {
            attempts++;
            last = abort;
            // Never answers: the request the deadline has to cut off.
            await Future<void>.delayed(const Duration(days: 1));
          },
        ).catchError((Object e) {
          error = e;
          settledAt = async.elapsed;
        });

        async.elapse(const Duration(seconds: 30));

        expect(attempts, 1, reason: 'a timeout is never replayed');
        expect(settledAt, const Duration(seconds: 10));
        expect(last?.isAborted, isTrue, reason: 'the in-flight request is torn down');
        expect(
          error,
          isA<MediaServerHttpException>().having((e) => e.type, 'type', MediaServerHttpErrorType.connectionTimeout),
        );
      });
    });

    test('bounds total wall time by the deadline, not by attempts × timeout', () {
      fakeAsync((async) {
        Duration? settledAt;
        Object? error;

        retryTransientMediaServerCall<void>(
          operation: 'test operation',
          deadline: const Duration(seconds: 15),
          call: (_, _) async {
            // Every attempt burns most of the budget before failing in a
            // retryable way — the worst case for a retry loop.
            await Future<void>.delayed(const Duration(seconds: 6));
            throw _error(MediaServerHttpErrorType.connectionError);
          },
        ).catchError((Object e) {
          error = e;
          settledAt = async.elapsed;
        });

        async.elapse(const Duration(seconds: 120));

        expect(error, isA<MediaServerHttpException>());
        expect(settledAt, isNotNull);
        expect(settledAt!, lessThanOrEqualTo(const Duration(seconds: 15)));
      });
    });

    test('does not retry non-transient failures', () async {
      var attempts = 0;

      await expectLater(
        retryTransientMediaServerCall<void>(
          operation: 'test operation',
          deadline: const Duration(seconds: 20),
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

    test('does not swallow a cancellation as a retryable failure', () async {
      var attempts = 0;

      await expectLater(
        retryTransientMediaServerCall<void>(
          operation: 'test operation',
          deadline: const Duration(seconds: 20),
          call: (_, _) async {
            attempts++;
            throw _error(MediaServerHttpErrorType.cancelled);
          },
        ),
        throwsA(isA<MediaServerHttpException>().having((e) => e.isCancellation, 'isCancellation', isTrue)),
      );

      expect(attempts, 1);
    });
  });
}
