import '../exceptions/media_server_exceptions.dart';
import 'app_logger.dart';
import 'media_server_http_client.dart';

typedef MediaServerRetryCall<T> = Future<T> Function(Duration timeout, AbortController abort);

/// Retries media-server calls only when the failure is transient transport
/// noise. Callers pass per-attempt timeouts so cold-start surfaces can use a
/// bounded retry budget without changing global HTTP defaults.
Future<T> retryTransientMediaServerCall<T>({
  required String operation,
  required List<Duration> attemptTimeouts,
  required MediaServerRetryCall<T> call,
}) async {
  if (attemptTimeouts.isEmpty) {
    throw ArgumentError.value(attemptTimeouts, 'attemptTimeouts', 'must contain at least one timeout');
  }

  for (var attempt = 0; attempt < attemptTimeouts.length; attempt++) {
    final timeout = attemptTimeouts[attempt];
    final abort = AbortController();
    try {
      return await call(timeout, abort);
    } on MediaServerHttpException catch (e, st) {
      abort.abort();
      final isLastAttempt = attempt == attemptTimeouts.length - 1;
      if (!e.isTransient || isLastAttempt) {
        Error.throwWithStackTrace(e, st);
      }

      appLogger.w(
        'Retrying $operation after transient media-server failure',
        error: {
          'attempt': attempt + 1,
          'maxAttempts': attemptTimeouts.length,
          'nextTimeoutMs': attemptTimeouts[attempt + 1].inMilliseconds,
          'type': e.type.name,
        },
      );
    } catch (e, st) {
      abort.abort();
      Error.throwWithStackTrace(e, st);
    }
  }

  throw StateError('unreachable retry state');
}
