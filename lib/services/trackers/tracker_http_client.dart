import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utils/abortable_http_request.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;
import 'tracker_constants.dart';

class TrackerHttpClient {
  static const Set<String> allMethods = {'GET', 'POST', 'PATCH', 'PUT', 'DELETE'};

  final TrackerService service;
  final String logLabel;
  final http.Client _http;

  TrackerHttpClient({required this.service, required this.logLabel, http.Client? httpClient})
    : _http = httpClient ?? platform.createPlatformClient();

  void dispose() => _http.close();

  Future<http.Response> send(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = TrackerConstants.requestTimeout,
    Set<String> allowedMethods = allMethods,
    String? operation,
  }) async {
    if (!allowedMethods.contains(method)) {
      throw ArgumentError('Unsupported HTTP method: $method');
    }

    final op = operation ?? '$logLabel $method ${uri.path}';
    final sw = Stopwatch()..start();
    final res = await sendAbortableHttpRequest(
      _http,
      method,
      uri,
      headers: headers,
      body: body,
      timeout: timeout,
      operation: op,
    );
    sw.stop();
    appLogger.d('$op -> ${res.statusCode} (${sw.elapsedMilliseconds}ms)');
    return res;
  }

  Future<http.Response> sendJson(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Duration timeout = TrackerConstants.requestTimeout,
    Set<String> allowedMethods = allMethods,
    String? operation,
  }) {
    return send(
      method,
      uri,
      // A JSON body must declare its content type; without this, package:http
      // treats a String body as text/plain.
      headers: body == null ? headers : _withJsonContentType(headers),
      body: body == null ? null : json.encode(body),
      timeout: timeout,
      allowedMethods: allowedMethods,
      operation: operation,
    );
  }

  static Map<String, String> _withJsonContentType(Map<String, String>? headers) {
    final merged = Map<String, String>.from(headers ?? const {});
    final hasContentType = merged.keys.any((key) => key.toLowerCase() == 'content-type');
    if (!hasContentType) merged['Content-Type'] = 'application/json';
    return merged;
  }

  Future<http.Response> sendForm(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, String> body,
    Duration timeout = TrackerConstants.requestTimeout,
    Set<String> allowedMethods = allMethods,
    String? operation,
  }) {
    final formHeaders = Map<String, String>.from(headers)..['Content-Type'] = 'application/x-www-form-urlencoded';
    final encoded = body.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return send(
      method,
      uri,
      headers: formHeaders,
      body: encoded,
      timeout: timeout,
      allowedMethods: allowedMethods,
      operation: operation,
    );
  }

  static dynamic decodeJson(String body) {
    if (body.isEmpty) return null;
    try {
      return json.decode(body);
    } catch (_) {
      return null;
    }
  }
}
