import '../exceptions/media_server_exceptions.dart';
import 'app_logger.dart';
import 'media_server_http_client.dart';

typedef MediaServerRetryCall<T> = Future<T> Function(Duration timeout, AbortController abort);

/// Runs a media-server call under a single whole-request [deadline], retrying
/// only failures that cost nothing to retry.
///
/// Retry vs failover (see `FailoverHttpClient` for the other half): retry is
/// for a *slow-but-working* endpoint, failover is for a *dead* one. Surfaces
/// wrapped in this helper should pass `allowEndpointFailover: false` on the
/// inner GET so a slow row doesn't move the whole client off an otherwise
/// working endpoint — every existing combined call site does.
///
/// ## Why timeouts are not retried
///
/// `http.Client.send` resolves when response *headers* arrive, so
/// [MediaServerHttpClient]'s connect budget covers DNS + TCP + TLS + request +
/// **the server's think time**. A Jellyfin `/Items/Latest` that needs 11s on a
/// large library therefore raises a `TimeoutException`, which
/// [MediaServerHttpException.from] types as
/// [MediaServerHttpErrorType.connectionTimeout] — indistinguishable from a
/// failed socket connect.
///
/// Replaying it makes the server re-run the same expensive query from scratch,
/// with a *shorter* budget than the one it just missed. The old
/// `[10s, 8s, 5s]` ladder turned an 11s answer into an empty row after 23s
/// (#1784). A timeout means "this endpoint is slower than we can wait", and the
/// answer to that is to give up, not to ask three times.
///
/// [MediaServerHttpErrorType.connectionError] is different: a refused
/// connection, DNS failure or reset socket fails immediately and costs the
/// server nothing, and is frequently a one-off on a mobile link. Those are
/// retried up to [maxConnectionRetries] times.
///
/// [deadline] bounds the whole call — every attempt, plus whatever the last one
/// is still waiting on — and aborts the in-flight request when it expires. Each
/// attempt is *also* handed [deadline] as its own budget so the HTTP layer
/// fails on its own terms first; the outer bound is the backstop that makes the
/// guarantee unconditional.
Future<T> retryTransientMediaServerCall<T>({
  required String operation,
  required Duration deadline,
  required MediaServerRetryCall<T> call,
  int maxConnectionRetries = 2,
}) {
  if (deadline <= Duration.zero) {
    throw ArgumentError.value(deadline, 'deadline', 'must be positive');
  }

  AbortController? inFlight;

  Future<T> attempts() async {
    for (var attempt = 0; ; attempt++) {
      final abort = AbortController();
      inFlight = abort;
      try {
        return await call(deadline, abort);
      } on MediaServerHttpException catch (e, st) {
        abort.abort();
        if (e.type != MediaServerHttpErrorType.connectionError || attempt >= maxConnectionRetries) {
          Error.throwWithStackTrace(e, st);
        }
        appLogger.w(
          'Retrying $operation after a connection error',
          error: {'attempt': attempt + 1, 'maxAttempts': maxConnectionRetries + 1, 'type': e.type.name},
        );
      } catch (e, st) {
        abort.abort();
        Error.throwWithStackTrace(e, st);
      }
    }
  }

  return attempts().timeout(
    deadline,
    onTimeout: () {
      inFlight?.abort();
      throw MediaServerHttpException(
        type: MediaServerHttpErrorType.connectionTimeout,
        message: '$operation exceeded its ${deadline.inSeconds}s budget',
      );
    },
  );
}
