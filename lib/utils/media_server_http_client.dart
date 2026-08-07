import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'app_logger.dart';
import 'future_extensions.dart';
import 'isolate_helper.dart';
import 'log_redaction_manager.dart';
import 'managed_http_client.dart';
import 'url_utils.dart';
import '../exceptions/media_server_exceptions.dart';

// Platform-specific imports are conditional
import 'platform_http_client_stub.dart' if (dart.library.io) 'platform_http_client_io.dart' as platform;

/// Response from [MediaServerHttpClient] requests.
class MediaServerResponse {
  final int statusCode;

  /// Parsed JSON body (`Map<String, dynamic>` or `List`), or raw `String`
  /// for non-JSON responses.
  final dynamic data;

  final Map<String, String> headers;
  final Uri? requestUri;

  /// Final response URI after redirects, or [requestUri] when the transport
  /// does not expose redirect metadata.
  final Uri? effectiveUri;

  MediaServerResponse({required this.statusCode, this.data, required this.headers, this.requestUri, Uri? effectiveUri})
    : effectiveUri = effectiveUri ?? requestUri;
}

/// Throw [MediaServerHttpException] for non-2xx responses so callers don't blindly
/// cast HTML/text error bodies to `Map<String, dynamic>`.
void throwIfHttpError(MediaServerResponse r) {
  if (r.statusCode >= 400) {
    throw MediaServerHttpException(
      type: MediaServerHttpErrorType.unknown,
      statusCode: r.statusCode,
      responseData: r.data,
      requestUri: r.requestUri,
      message: 'HTTP ${r.statusCode}',
    );
  }
}

/// Abort controller for cancelling in-flight HTTP requests.
///
/// Uses the `package:http` [AbortableRequest] mechanism so the underlying
/// transport (IOClient, CronetClient, CupertinoClient) actually cancels
/// the network operation.
class AbortController {
  final _completer = Completer<void>();

  Future<void> get trigger => _completer.future;

  bool get isAborted => _completer.isCompleted;

  void abort() {
    if (!_completer.isCompleted) _completer.complete();
  }

  /// Stop a paged operation before it starts or commits more work.
  ///
  /// The exception deliberately carries no request URI or response payload.
  void throwIfAborted() {
    if (isAborted) {
      throw MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'Operation cancelled');
    }
  }
}

/// HTTP client wrapper providing base URL, default headers, JSON parsing,
/// timeouts, logging, and optional endpoint failover.
class MediaServerHttpClient {
  final http.Client _client;

  /// Requests owned by this client, aborted at the transport on shutdown so an
  /// in-flight body raises [http.RequestAbortedException] instead of truncating.
  final Set<AbortController> _activeAborts = <AbortController>{};

  /// Not delegated to [ManagedHttpClient]'s own closing guard: that reports
  /// shutdown as an [http.ClientException], which maps to
  /// [MediaServerHttpErrorType.connectionError] and so reads as transient.
  /// Failover, pagination and download retry all branch on
  /// [MediaServerHttpException.isCancellation].
  bool _closing = false;

  MediaServerHttpClient({
    http.Client? client,
    this.baseUrl = '',
    Map<String, String> defaultHeaders = const {},
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 120),
    // Plex home loads fan out many HTTP/1.1 calls on Linux. Keep that tuning
    // opt-in so generic tracker/auth clients stay disposable and closeable.
    bool usePlexApiClient = false,
  }) : _client = client ?? (usePlexApiClient ? platform.createPlexApiClient() : platform.createPlatformClient()),
       defaultHeaders = Map.of(defaultHeaders);

  /// The underlying [http.Client] for direct streaming / multipart requests.
  http.Client get inner => _client;

  String baseUrl;
  Map<String, String> defaultHeaders;
  Duration connectTimeout;
  Duration receiveTimeout;

  Future<MediaServerResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    AbortController? abort,
  }) => _send('GET', path, queryParameters: queryParameters, headers: headers, timeout: timeout, abort: abort);

  Future<MediaServerResponse> post(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    AbortController? abort,
  }) => _send(
    'POST',
    path,
    queryParameters: queryParameters,
    headers: headers,
    body: body,
    timeout: timeout,
    abort: abort,
  );

  Future<MediaServerResponse> put(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    AbortController? abort,
  }) => _send(
    'PUT',
    path,
    queryParameters: queryParameters,
    headers: headers,
    body: body,
    timeout: timeout,
    abort: abort,
  );

  Future<MediaServerResponse> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    AbortController? abort,
  }) => _send('DELETE', path, queryParameters: queryParameters, headers: headers, timeout: timeout, abort: abort);

  /// Fetch raw bytes (e.g. images, BIF files, subtitles).
  Future<Uint8List> getBytes(String url, {Map<String, String>? headers, Duration? timeout, AbortController? abort}) {
    return _perform<Uint8List>(
      'GET',
      url,
      headers: headers,
      timeout: timeout,
      abort: abort,
      consume: (streamed, scope) async {
        final bytes = await scope.receive(streamed.stream.toBytes());
        scope.logResponse(streamed.statusCode);
        return bytes;
      },
    );
  }

  /// Fetch raw bytes plus status for probe-style requests. Unlike [getBytes]
  /// the status code is surfaced instead of only logged, and unlike [get] the
  /// body is never text-decoded — a probe may touch binary media. Non-2xx is
  /// returned, not thrown, matching [get].
  Future<MediaServerResponse> getRaw(
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
    AbortController? abort,
  }) {
    return _perform<MediaServerResponse>(
      'GET',
      url,
      headers: headers,
      timeout: timeout,
      abort: abort,
      consume: (streamed, scope) async {
        final bytes = await scope.receive(streamed.stream.toBytes());
        scope.logResponse(streamed.statusCode);
        return MediaServerResponse(
          statusCode: streamed.statusCode,
          data: bytes,
          headers: streamed.headers,
          requestUri: scope.uri,
        );
      },
    );
  }

  /// Stream-download a URL directly into a file.
  Future<void> downloadFile(
    String url,
    String filePath, {
    Map<String, String>? headers,
    Duration? timeout,
    AbortController? abort,
  }) {
    final tempFile = File('$filePath.download');
    return _perform<void>(
      'GET',
      url,
      label: 'download',
      headers: headers,
      timeout: timeout,
      abort: abort,
      // Also clears a temp file left by an earlier attempt when this one never
      // got past connect.
      onError: () async {
        if (await tempFile.exists()) {
          try {
            await tempFile.delete();
          } catch (_) {}
        }
      },
      consume: (streamed, scope) async {
        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          await streamed.stream.drain<void>();
          throw MediaServerHttpException(
            type: MediaServerHttpErrorType.unknown,
            statusCode: streamed.statusCode,
            requestUri: scope.uri,
            message: 'HTTP ${streamed.statusCode}',
          );
        }

        final file = File(filePath);
        await file.parent.create(recursive: true);
        if (await tempFile.exists()) await tempFile.delete();
        final sink = tempFile.openWrite();
        try {
          await scope.receive(streamed.stream.pipe(sink));
        } finally {
          await sink.close();
        }
        if (await file.exists()) await file.delete();
        await tempFile.rename(filePath);
      },
    );
  }

  void close() {
    _closing = true;
    _abortActiveRequests();
    _client.close();
  }

  Future<void> closeGracefully({Duration drainTimeout = const Duration(seconds: 2)}) async {
    _closing = true;
    _abortActiveRequests();
    if (_client case final ManagedHttpClient managed) {
      await managed.closeGracefully(drainTimeout: drainTimeout);
    } else {
      _client.close();
    }
  }

  Future<MediaServerResponse> _send(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    AbortController? abort,
  }) {
    return _perform<MediaServerResponse>(
      method,
      path,
      queryParameters: queryParameters,
      headers: headers,
      body: body,
      timeout: timeout,
      abort: abort,
      consume: (streamed, scope) async {
        final effectiveUri = switch (streamed) {
          http.BaseResponseWithUrl(:final url) => url,
          _ => scope.uri,
        };

        final bytes = await scope.receive(streamed.stream.toBytes());
        scope.logResponse(streamed.statusCode);

        dynamic data;
        try {
          data = await _decodeBody(bytes, streamed.headers);
        } catch (e) {
          final body = await _decodeTextBody(bytes);
          throw MediaServerHttpException(
            type: MediaServerHttpErrorType.unknown,
            statusCode: streamed.statusCode,
            responseData: body,
            requestUri: scope.uri,
            message: 'Failed to decode response body: $e',
          );
        }
        return MediaServerResponse(
          statusCode: streamed.statusCode,
          data: data,
          headers: streamed.headers,
          requestUri: scope.uri,
          effectiveUri: effectiveUri,
        );
      },
    );
  }

  /// Run one request: closing guard, abort registration, connect phase and
  /// failure wrapping. [consume] reads the body through its scope, which
  /// carries the same timeout and abort wiring into the receive phase;
  /// [onError] runs after the abort and before the failure is wrapped. Every
  /// exit path deregisters the request from [_activeAborts].
  Future<T> _perform<T>(
    String method,
    String url, {
    String? label,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    AbortController? abort,
    Future<void> Function()? onError,
    required Future<T> Function(http.StreamedResponse streamed, _RequestScope scope) consume,
  }) async {
    if (_closing) {
      throw MediaServerHttpException(type: MediaServerHttpErrorType.cancelled, message: 'HTTP client is closing');
    }

    final uri = _resolveUri(url, queryParameters);
    final operation = label ?? method;

    final requestAbort = AbortController();
    _activeAborts.add(requestAbort);
    final request = http.AbortableRequest(method, uri, abortTrigger: _abortTrigger(requestAbort, abort));
    request.headers.addAll({...defaultHeaders, ...?headers});
    _setBody(request, body);

    final scope = _RequestScope(this, uri, operation, requestAbort, timeout ?? receiveTimeout);
    try {
      final streamed = await _withAbortOnTimeout(
        _client.send(request),
        timeout ?? connectTimeout,
        operation: '$operation ${uri.path} connect',
        abort: requestAbort,
      );
      return await consume(streamed, scope);
    } catch (e) {
      requestAbort.abort();
      await onError?.call();
      throw MediaServerHttpException.from(e, uri: uri);
    } finally {
      _activeAborts.remove(requestAbort);
    }
  }

  void _abortActiveRequests() {
    for (final abort in _activeAborts.toList()) {
      abort.abort();
    }
  }

  Future<void> _abortTrigger(AbortController owned, AbortController? external) {
    final externalTrigger = external?.trigger;
    return externalTrigger == null ? owned.trigger : Future.any<void>([owned.trigger, externalTrigger]);
  }

  Future<T> _withAbortOnTimeout<T>(
    Future<T> future,
    Duration timeLimit, {
    required String operation,
    required AbortController abort,
  }) async {
    try {
      return await future.namedTimeout(timeLimit, operation: operation);
    } on TimeoutException {
      abort.abort();
      rethrow;
    }
  }

  /// Build a full URI from [baseUrl] + [path] + [queryParameters].
  /// Use this from callers that need to construct URLs with the client's
  /// current (possibly failover-switched) base, rather than reading
  /// `config.baseUrl` directly.
  Uri buildUri(String path, {Map<String, dynamic>? queryParameters}) => _buildUri(path, queryParameters);

  /// Build a full URI from [baseUrl] + [path] + [queryParameters].
  /// Uses [Uri.encodeComponent] which encodes spaces as `%20` (not `+`).
  Uri _buildUri(String path, Map<String, dynamic>? queryParameters) {
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    // [path] may already carry a query string (e.g. Plex home hub keys like
    // `/hubs/home/recentlyAdded?type=2&sectionID=2`). Merge via [_appendQuery] —
    // the same path used for absolute URLs in [_send] — so extra params join with
    // `&` instead of producing a malformed double-`?` URL that corrupts the
    // existing params (e.g. sectionID).
    return _appendQuery(Uri.parse('$base$cleanPath'), queryParameters);
  }

  /// Resolve a request target: absolute URLs keep their own host and query,
  /// relative paths go through [baseUrl].
  Uri _resolveUri(String url, Map<String, dynamic>? queryParameters) =>
      _isAbsoluteUrl(url) ? _appendQuery(Uri.parse(url), queryParameters) : _buildUri(url, queryParameters);

  /// Append query parameters to an already-parsed URI.
  Uri _appendQuery(Uri uri, Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    final query = encodeQueryParameters(queryParameters);
    if (query.isEmpty) return uri;
    final existing = uri.query;
    final combined = existing.isEmpty ? query : '$existing&$query';
    return uri.replace(query: combined);
  }

  static bool _isAbsoluteUrl(String url) => url.startsWith('http://') || url.startsWith('https://');

  /// Set the request body, choosing encoding based on the body type.
  void _setBody(http.Request request, Object? body) {
    if (body == null) return;

    if (body is List<int>) {
      request.bodyBytes = Uint8List.fromList(body);
      return;
    }

    if (body is String) {
      request.body = body;
      return;
    }

    // Content type comes from the caller's headers (Jellyfin/Plex put
    // `application/json` in their defaults); `request.body` falls back to
    // text/plain. Don't add one here — `request.headers` is case-insensitive,
    // and the setter above has already filled the key in either way.
    request.body = jsonEncode(body);
  }

  /// Decode the response body: lenient UTF-8, then JSON parse if applicable.
  /// Large payloads are decoded in a background isolate.
  Future<dynamic> _decodeBody(List<int> bytes, Map<String, String> headers) async {
    if (bytes.isEmpty) return null;

    final contentType = (_headerValue(headers, 'content-type') ?? '').toLowerCase();
    final isJson = contentType.contains('json');

    // For large JSON payloads, do both UTF-8 decode and JSON parse in a
    // single isolate roundtrip to avoid two context switches.
    if (isJson && bytes.length > 50 * 1024) {
      return await tryIsolateRun(() => jsonDecode(utf8.decode(bytes, allowMalformed: true)));
    }

    final body = await _decodeTextBody(bytes);

    return isJson ? jsonDecode(body) : body;
  }

  Future<String> _decodeTextBody(List<int> bytes) async {
    return bytes.length > 50 * 1024
        ? await tryIsolateRun(() => utf8.decode(bytes, allowMalformed: true))
        : utf8.decode(bytes, allowMalformed: true);
  }

  static String? _headerValue(Map<String, String> headers, String name) {
    final lowerName = name.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == lowerName) return entry.value;
    }
    return null;
  }

  void _logResponse(String method, Uri uri, int statusCode, int ms) {
    appLogger.d('$method ${LogRedactionManager.redact(uri.toString())} → $statusCode (${ms}ms)');
  }
}

/// The live request handed to a [MediaServerHttpClient._perform] body handler.
/// Its stopwatch starts with the connect phase, so [logResponse] reports the
/// full round trip regardless of how the body was read.
class _RequestScope {
  _RequestScope(this._owner, this.uri, this._operation, this._abort, this._receiveTimeout);

  final MediaServerHttpClient _owner;
  final Uri uri;
  final String _operation;
  final AbortController _abort;
  final Duration _receiveTimeout;
  final Stopwatch _sw = Stopwatch()..start();

  Future<T> receive<T>(Future<T> future) =>
      _owner._withAbortOnTimeout(future, _receiveTimeout, operation: '$_operation ${uri.path} receive', abort: _abort);

  void logResponse(int statusCode) {
    _sw.stop();
    _owner._logResponse(_operation, uri, statusCode, _sw.elapsedMilliseconds);
  }
}

/// Shared [MediaServerHttpClient] instance for ad-hoc requests (update checks,
/// log uploads, image fetches, etc). No base URL or default Plex headers.
final httpClient = MediaServerHttpClient();
