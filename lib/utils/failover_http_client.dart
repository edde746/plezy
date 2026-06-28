import 'endpoint_failover_interceptor.dart';
import 'app_logger.dart';
import 'media_server_http_client.dart';
import '../exceptions/media_server_exceptions.dart';

/// [MediaServerHttpClient] with endpoint failover, shared by both backends
/// (the single implementation of what used to be `PlexClient._getWithFailover`
/// and `_JellyfinFailoverHttpClient`).
///
/// Semantics — decided once, here ([retryTransientMediaServerCall]'s doc
/// cross-references this):
///
/// - **Failover is GET-only.** Mutations (POST/PUT/DELETE) fail fast on both
///   backends: replaying a mutation against a second endpoint when the first
///   was flaky-but-alive risks double-application, and no caller needs it.
/// - **Trigger:** a transient transport failure
///   ([MediaServerHttpException.isTransient]) or a 5xx — whether thrown or
///   returned as a response. 4xx answers never trigger failover.
/// - **One alternative per cascade.** A failed retry (transport error *or*
///   error status) resets the list to the preferred endpoint and fires
///   [onAllEndpointsExhausted]; the next cascade starts from the best
///   candidate again. Concurrent requests are generation-stamped so a request
///   raced by a switch doesn't cascade a second time.
/// - **Persistence is two-phase:** the switch is applied with
///   `persist: false` for the retry, and only a successful retry persists the
///   winner (`persist: true`).
/// - **Retry interplay:** [retryTransientMediaServerCall] is for
///   *slow-but-working* endpoints (per-surface timeout budgets); surfaces
///   that wrap it pass `allowEndpointFailover: false` so a slow row doesn't
///   move the whole client off an otherwise working endpoint. Failover is for
///   *dead* endpoints.
class FailoverHttpClient extends MediaServerHttpClient {
  /// [prioritizedEndpoints] may be empty (failover disabled — plain client
  /// behavior). A single-entry list still arms [onAllEndpointsExhausted]:
  /// the lone endpoint failing *is* exhaustion, and the owning manager uses
  /// that to flip server status and reconnect.
  FailoverHttpClient({
    super.client,
    required super.baseUrl,
    required super.defaultHeaders,
    super.connectTimeout,
    super.receiveTimeout,
    super.usePlexApiClient,
    required this.logLabel,
    required List<String> prioritizedEndpoints,
    required this.onEndpointSwitch,
    this.onAllEndpointsExhausted,
  }) : _endpointManager = prioritizedEndpoints.isNotEmpty ? EndpointFailoverManager(prioritizedEndpoints) : null;

  /// Backend name for log lines ('Plex' / 'Jellyfin') — keeps failover logs
  /// greppable per backend now that the implementation is shared.
  final String logLabel;
  final EndpointFailoverManager? _endpointManager;

  /// Applies a base-URL change on the owning client. The callback must update
  /// this client's [baseUrl] alongside its own config/connection snapshot
  /// (the two-phase protocol calls it with `persist: false` before the retry
  /// and `persist: true` only after a success — persistence must not be gated
  /// on the URL having changed, since the second call sees it already applied).
  final Future<void> Function(String newBaseUrl, {required bool persist}) onEndpointSwitch;

  /// Fired when a cascade ends without a working endpoint (or the retry
  /// itself fails). The owning manager debounces this into a server-offline
  /// flip + reconnection.
  final void Function()? onAllEndpointsExhausted;

  bool _failoverSwitching = false;

  /// Endpoints currently configured, preferred-first (test/diagnostic view).
  List<String> get endpoints => _endpointManager?.endpoints ?? const [];

  /// Replace the endpoint list after a connection refresh, keeping
  /// [currentBaseUrl] active when provided (it must be present in the list).
  void resetEndpoints(List<String> prioritizedEndpoints, {String? currentBaseUrl}) {
    _endpointManager?.reset(prioritizedEndpoints, currentBaseUrl: currentBaseUrl);
  }

  @override
  Future<MediaServerResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    AbortController? abort,
    bool allowEndpointFailover = true,
  }) async {
    final generation = _endpointManager?.generation;
    final MediaServerResponse response;
    try {
      response = await super.get(
        path,
        queryParameters: queryParameters,
        headers: headers,
        timeout: timeout,
        abort: abort,
      );
    } on MediaServerHttpException catch (e) {
      if (!allowEndpointFailover || !_shouldAttemptFailover(exception: e) || !_canFailover(generation)) {
        rethrow;
      }
      final retried = await _failoverOnce(
        path,
        queryParameters: queryParameters,
        headers: headers,
        timeout: timeout,
        abort: abort,
      );
      if (retried == null) rethrow;
      return retried;
    }
    if (!allowEndpointFailover ||
        !_shouldAttemptFailover(statusCode: response.statusCode) ||
        !_canFailover(generation)) {
      return response;
    }
    return await _failoverOnce(
          path,
          queryParameters: queryParameters,
          headers: headers,
          timeout: timeout,
          abort: abort,
        ) ??
        response;
  }

  bool _canFailover(int? requestGeneration) {
    final manager = _endpointManager;
    return manager != null && !_failoverSwitching && requestGeneration == manager.generation;
  }

  bool _shouldAttemptFailover({MediaServerHttpException? exception, int? statusCode}) {
    if (exception != null) {
      if (exception.isTransient) return true;
      statusCode = exception.statusCode;
    }
    return statusCode != null && statusCode >= 500 && statusCode <= 599;
  }

  /// One step of the cascade: move to the next endpoint and retry once.
  ///
  /// Returns the retry's response on success. Returns `null` when no fallback
  /// exists (after resetting and firing [onAllEndpointsExhausted]) — the
  /// caller surfaces its original failure. A retry that answers with an error
  /// status is returned as-is (the caller's status handling applies), and a
  /// retry that throws rethrows; both count as exhaustion: the list resets to
  /// the preferred endpoint so the next cascade starts from the best candidate.
  Future<MediaServerResponse?> _failoverOnce(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    AbortController? abort,
  }) async {
    final manager = _endpointManager!;
    if (!manager.hasFallback) {
      await _resetToPreferred(manager);
      onAllEndpointsExhausted?.call();
      return null;
    }

    final failedEndpoint = manager.current;
    final nextBaseUrl = manager.moveToNext();
    if (nextBaseUrl == null) return null;

    _failoverSwitching = true;
    try {
      appLogger.i(
        'Switching $logLabel endpoint after GET failure',
        error: {'from': failedEndpoint, 'to': nextBaseUrl, 'path': path},
      );
      await onEndpointSwitch(nextBaseUrl, persist: false);
      final response = await super.get(
        path,
        queryParameters: queryParameters,
        headers: headers,
        timeout: timeout,
        abort: abort,
      );
      if (response.statusCode < 400) {
        appLogger.i('$logLabel endpoint failover retry succeeded', error: {'newEndpoint': nextBaseUrl});
        await onEndpointSwitch(nextBaseUrl, persist: true);
        return response;
      }
      await _resetToPreferred(manager);
      onAllEndpointsExhausted?.call();
      return response;
    } catch (_) {
      await _resetToPreferred(manager);
      onAllEndpointsExhausted?.call();
      rethrow;
    } finally {
      _failoverSwitching = false;
    }
  }

  Future<void> _resetToPreferred(EndpointFailoverManager manager) async {
    final resetBaseUrl = manager.resetToFirst();
    if (resetBaseUrl != null) {
      await onEndpointSwitch(resetBaseUrl, persist: false);
    }
  }
}
