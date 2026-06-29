import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utils/app_logger.dart';
import 'seerr_constants.dart';
import 'seerr_exceptions.dart';

/// Thin wrapper around `package:http` for Seerr API calls.
///
/// Adds the two things stock `package:http` doesn't give us:
///   1. `connect.sid` cookie capture from `Set-Cookie` on login, and replay
///      as `Cookie:` on every subsequent request — Express session auth.
///   2. JSON ergonomics + timeout + logging — mirrors the
///      `TrackerHttpClient` convenience layer used by Trakt/MAL/etc.
class SeerrHttpClient {
  final String baseUrl;
  final http.Client _http;
  String? _sessionCookieValue;

  SeerrHttpClient({required String baseUrl, http.Client? httpClient, String? initialSessionCookie})
    : baseUrl = _stripTrailingSlash(baseUrl),
      _http = httpClient ?? http.Client(),
      _sessionCookieValue = initialSessionCookie?.isNotEmpty == true ? initialSessionCookie : null;

  /// Currently held cookie value (raw, no `name=` prefix). Null until either
  /// [setSessionCookieValue] or [captureSessionCookie] succeeds.
  String? get sessionCookieValue => _sessionCookieValue;

  void setSessionCookieValue(String? value) {
    _sessionCookieValue = value?.isNotEmpty == true ? value : null;
  }

  void dispose() => _http.close();

  /// Parse `Set-Cookie` from [response] and store the `connect.sid` value
  /// (without the `name=` prefix). Returns true when a cookie was captured.
  ///
  /// Express's session middleware emits one or more `Set-Cookie` headers;
  /// `package:http` joins multiple values into a single comma-delimited
  /// string. Cookie values are URL-encoded so they cannot themselves contain
  /// a literal comma — splitting on `,` then scanning each chunk for the
  /// `connect.sid=` prefix is safe.
  bool captureSessionCookie(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return false;
    final prefix = '${SeerrConstants.sessionCookieName}=';
    for (final chunk in raw.split(',')) {
      final trimmed = chunk.trimLeft();
      if (!trimmed.startsWith(prefix)) continue;
      final afterName = trimmed.substring(prefix.length);
      final end = afterName.indexOf(';');
      final value = (end == -1 ? afterName : afterName.substring(0, end)).trim();
      if (value.isEmpty) continue;
      _sessionCookieValue = value;
      return true;
    }
    return false;
  }

  Uri _uri(String path, {Map<String, dynamic>? query}) {
    final base = Uri.parse('$baseUrl${SeerrConstants.apiPath}$path');
    if (query == null || query.isEmpty) return base;
    final stringified = <String, String>{};
    for (final entry in query.entries) {
      final v = entry.value;
      if (v == null) continue;
      stringified[entry.key] = v.toString();
    }
    return base.replace(queryParameters: {...base.queryParameters, ...stringified});
  }

  Map<String, String> _headers({Map<String, String>? extra, bool authenticated = true}) {
    final headers = <String, String>{'Accept': 'application/json', 'Accept-Encoding': 'identity'};
    if (authenticated && _sessionCookieValue != null) {
      headers['Cookie'] = '${SeerrConstants.sessionCookieName}=$_sessionCookieValue';
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  /// Send a request expecting JSON in return.
  ///
  /// When [body] is non-null the request is sent as a JSON body with
  /// `Content-Type: application/json`. The response is decoded as JSON
  /// (`dynamic` so callers can branch on Map vs List).
  ///
  /// On HTTP 401 returns the response unmodified (with `data == null`) so
  /// the [SeerrClient] caller can trigger the silent-reauth-and-retry path.
  Future<SeerrResponse> sendJson(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    Duration timeout = SeerrConstants.requestTimeout,
    bool authenticated = true,
  }) async {
    final uri = _uri(path, query: query);
    final headers = _headers(authenticated: authenticated);
    final encodedBody = body == null ? null : json.encode(body);
    if (encodedBody != null) headers['Content-Type'] = 'application/json';

    final sw = Stopwatch()..start();
    final response = await _send(method, uri, headers: headers, body: encodedBody).timeout(timeout);
    sw.stop();
    appLogger.d('Seerr $method $path -> ${response.statusCode} (${sw.elapsedMilliseconds}ms)');

    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = json.decode(response.body);
      } catch (_) {
        data = null;
      }
    }
    return SeerrResponse(response: response, data: data);
  }

  Future<http.Response> _send(String method, Uri uri, {required Map<String, String> headers, String? body}) async {
    switch (method) {
      case 'GET':
        return _http.get(uri, headers: headers);
      case 'POST':
        return _http.post(uri, headers: headers, body: body);
      case 'PUT':
        return _http.put(uri, headers: headers, body: body);
      case 'DELETE':
        return _http.delete(uri, headers: headers, body: body);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Maps a 4xx/5xx response to the appropriate exception. Returns the
  /// response untouched on success codes (and on 401, which the caller
  /// handles via the reauth-and-retry path).
  static void throwForStatus(SeerrResponse res) {
    final code = res.response.statusCode;
    if (code >= 200 && code < 300) return;
    if (code == 401) return; // caller-handled
    if (code == 403) {
      final data = res.data;
      final body = data is Map<String, dynamic> ? (data['message'] as String? ?? data.toString()) : res.response.body;
      throw SeerrAuthException(body.isNotEmpty ? body : 'Forbidden', statusCode: code);
    }
    if (code >= 400 && code < 500) {
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] as String?;
        if (message != null && message.isNotEmpty) throw SeerrRequestException(message, statusCode: code);
      }
    }
    throw SeerrHttpException(code, body: res.response.body);
  }

  static String _stripTrailingSlash(String input) {
    var v = input.trim();
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }
}

/// HTTP response paired with its decoded JSON body. `data` is null for
/// no-content responses, non-JSON bodies, or 401 (auth failure).
class SeerrResponse {
  final http.Response response;
  final dynamic data;
  const SeerrResponse({required this.response, required this.data});
}
