import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'app_logger.dart';
import 'future_extensions.dart';
import 'isolate_helper.dart';
import 'log_redaction_manager.dart';
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

  MediaServerResponse({required this.statusCode, this.data, required this.headers, this.requestUri});
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

  /// The future that triggers abort when completed.
  Future<void> get trigger => _completer.future;

  bool get isAborted => _completer.isCompleted;

  void abort() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

/// HTTP client wrapper providing base URL, default headers, JSON parsing,
/// timeouts, logging, and optional endpoint failover.
class MediaServerHttpClient {
  final http.Client _client;

  MediaServerHttpClient({
    http.Client? client,
    this.baseUrl = '',
    Map<String, String> defaultHeaders = const {},
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 120),
  }) : _client = client ?? platform.createPlatformClient(),
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
  Future<Uint8List> getBytes(String url, {Map<String, String>? headers, Duration? timeout}) async {
    final uri = _isAbsoluteUrl(url) ? Uri.parse(url) : _buildUri(url, null);
    final request = http.Request('GET', uri);
    request.headers.addAll({...defaultHeaders, ...?headers});

    final sw = Stopwatch()..start();
    try {
      final streamed = await _client
          .send(request)
          .namedTimeout(timeout ?? connectTimeout, operation: 'GET ${uri.path} connect');

      final bytes = await streamed.stream.toBytes().namedTimeout(
        timeout ?? receiveTimeout,
        operation: 'GET ${uri.path} receive',
      );

      sw.stop();
      _logResponse('GET', uri, streamed.statusCode, sw.elapsedMilliseconds);
      return bytes;
    } catch (e) {
      sw.stop();
      throw MediaServerHttpException.from(e, uri: uri);
    }
  }

  /// Stream-download a URL directly into a file.
  Future<void> downloadFile(String url, String filePath, {Map<String, String>? headers, Duration? timeout}) async {
    final uri = _isAbsoluteUrl(url) ? Uri.parse(url) : _buildUri(url, null);
    final request = http.Request('GET', uri);
    request.headers.addAll({...defaultHeaders, ...?headers});

    try {
      final streamed = await _client
          .send(request)
          .namedTimeout(timeout ?? connectTimeout, operation: 'download ${uri.path} connect');

      final file = File(filePath);
      final sink = file.openWrite();
      try {
        await streamed.stream.pipe(sink);
      } finally {
        await sink.close();
      }
    } catch (e) {
      throw MediaServerHttpException.from(e, uri: uri);
    }
  }

  /// Send a streamed request (for image cache etc).
  Future<http.StreamedResponse> sendStreamed(http.BaseRequest request) => _client.send(request);

  void close() => platform.closePlexClient(_client);

  Future<MediaServerResponse> _send(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    AbortController? abort,
  }) async {
    final uri = _isAbsoluteUrl(path)
        ? _appendQuery(Uri.parse(path), queryParameters)
        : _buildUri(path, queryParameters);

    final mergedHeaders = <String, String>{...defaultHeaders, ...?headers};

    // Build the request — use AbortableRequest when abort is provided
    final http.Request request;
    if (abort != null) {
      request = http.AbortableRequest(method, uri, abortTrigger: abort.trigger);
    } else {
      request = http.Request(method, uri);
    }
    request.headers.addAll(mergedHeaders);
    _setBody(request, body);

    final sw = Stopwatch()..start();
    try {
      // Phase 1: send + receive headers (connect timeout)
      final streamed = await _client
          .send(request)
          .namedTimeout(timeout ?? connectTimeout, operation: '$method ${uri.path} connect');

      // Phase 2: consume body (receive timeout)
      final bytes = await streamed.stream.toBytes().namedTimeout(
        timeout ?? receiveTimeout,
        operation: '$method ${uri.path} receive',
      );

      sw.stop();
      _logResponse(method, uri, streamed.statusCode, sw.elapsedMilliseconds);

      dynamic data;
      try {
        data = await _decodeBody(bytes, streamed.headers);
      } catch (e) {
        final body = await _decodeTextBody(bytes);
        throw MediaServerHttpException(
          type: MediaServerHttpErrorType.unknown,
          statusCode: streamed.statusCode,
          responseData: body,
          requestUri: uri,
          message: 'Failed to decode response body: $e',
        );
      }
      return MediaServerResponse(
        statusCode: streamed.statusCode,
        data: data,
        headers: streamed.headers,
        requestUri: uri,
      );
    } catch (e) {
      sw.stop();
      throw MediaServerHttpException.from(e, uri: uri);
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
    final query = _encodeQuery(queryParameters);
    final full = query.isEmpty ? '$base$cleanPath' : '$base$cleanPath?$query';
    return Uri.parse(full);
  }

  /// Append query parameters to an already-parsed URI.
  Uri _appendQuery(Uri uri, Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    final query = _encodeQuery(queryParameters);
    if (query.isEmpty) return uri;
    final existing = uri.query;
    final combined = existing.isEmpty ? query : '$existing&$query';
    return uri.replace(query: combined);
  }

  /// Encode query params with `%20` for spaces (not `+`).
  /// Null values are omitted (supports Dart's `?value` map entries).
  static String _encodeQuery(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return '';
    final parts = <String>[];
    for (final entry in params.entries) {
      if (entry.value == null) continue;
      parts.add(
        '${Uri.encodeComponent(entry.key)}='
        '${Uri.encodeComponent(entry.value.toString())}',
      );
    }
    return parts.join('&');
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

    // Map or List → JSON encode
    request.body = jsonEncode(body);
    // Only set content-type if the caller hasn't already. http.BaseRequest's
    // headers map is case-sensitive, so we must check both common casings —
    // Jellyfin returns 415 if a `Content-Type: application/json` from the
    // default headers ends up coexisting with a lowercase `content-type:
    // application/json; charset=utf-8` we'd append below.
    final hasContentType = request.headers.keys.any((k) => k.toLowerCase() == 'content-type');
    if (!hasContentType) {
      request.headers['content-type'] = 'application/json';
    }
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

/// Shared [MediaServerHttpClient] instance for ad-hoc requests (update checks,
/// log uploads, image fetches, etc). No base URL or default Plex headers.
final httpClient = MediaServerHttpClient();
