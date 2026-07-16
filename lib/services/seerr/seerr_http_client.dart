import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utils/abortable_http_request.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;
import '../trackers/tracker_http_client.dart';
import 'seerr_constants.dart';
import 'seerr_exceptions.dart';

/// HTTP response paired with its decoded JSON body. `data` is null for
/// no-content responses and non-JSON bodies.
class SeerrResponse {
  final http.Response response;
  final dynamic data;
  const SeerrResponse(this.response, this.data);

  int get statusCode => response.statusCode;
}

/// Thin wrapper around `package:http` for Seerr API calls.
///
/// Adds the two things the tracker HTTP layer doesn't cover:
///   1. `connect.sid` cookie capture from `Set-Cookie` on login, replayed as
///      `Cookie:` on every subsequent request — Express session auth.
///   2. Query encoding with `%20` for spaces: Seerr proxies `/search` to
///      TMDB, which rejects `+` in the query value, so `Uri.queryParameters`
///      (which emits `+`) cannot be used.
class SeerrHttpClient {
  final String baseUrl;
  final http.Client _http;
  String? _cookie;

  SeerrHttpClient({required String baseUrl, http.Client? httpClient, String? cookie})
    : baseUrl = normalizeBaseUrl(baseUrl),
      _http = httpClient ?? platform.createPlatformClient(),
      _cookie = (cookie?.isNotEmpty ?? false) ? cookie : null;

  /// Current `connect.sid` value (no `name=` prefix); null until a login
  /// response is captured or [cookie] was seeded.
  String? get cookie => _cookie;

  set cookie(String? value) => _cookie = (value?.isNotEmpty ?? false) ? value : null;

  void dispose() => _http.close();

  /// Parse `Set-Cookie` from [response] and keep the `connect.sid` value.
  /// Returns true when a cookie was captured.
  ///
  /// `package:http` joins multiple `Set-Cookie` headers into one
  /// comma-delimited string. Cookie values are URL-encoded and can't contain
  /// a literal comma, so splitting on `,` and scanning each chunk for the
  /// `connect.sid=` prefix is safe.
  bool captureSessionCookie(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return false;
    const prefix = '${SeerrConstants.sessionCookieName}=';
    for (final chunk in raw.split(',')) {
      final trimmed = chunk.trimLeft();
      if (!trimmed.startsWith(prefix)) continue;
      final afterName = trimmed.substring(prefix.length);
      final end = afterName.indexOf(';');
      final value = (end == -1 ? afterName : afterName.substring(0, end)).trim();
      if (value.isEmpty) continue;
      _cookie = value;
      return true;
    }
    return false;
  }

  /// Send a request under [SeerrConstants.apiPath], returning the decoded
  /// JSON body. 401 is returned to the caller (never thrown) so the client
  /// can run its silent re-auth path.
  Future<SeerrResponse> send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Map<String, Object?>? body,
    Duration timeout = SeerrConstants.requestTimeout,
    bool authenticated = true,
  }) async {
    if (!const {'GET', 'POST', 'PUT', 'DELETE'}.contains(method)) {
      throw ArgumentError('Unsupported HTTP method: $method');
    }
    final uri = _uri(path, query);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (authenticated && _cookie != null) 'Cookie': '${SeerrConstants.sessionCookieName}=$_cookie',
      if (body != null) 'Content-Type': 'application/json',
    };
    final sw = Stopwatch()..start();
    // Abortable so a timeout tears the request down instead of letting it
    // race on — a timed-out POST /request must not land server-side after
    // the UI already reported failure.
    final response = await sendAbortableHttpRequest(
      _http,
      method,
      uri,
      headers: headers,
      body: body == null ? null : jsonEncode(body),
      timeout: timeout,
      operation: 'Seerr $method $path',
    );
    appLogger.d('Seerr $method $path -> ${response.statusCode} (${sw.elapsedMilliseconds}ms)');
    return SeerrResponse(response, TrackerHttpClient.decodeJson(response.body));
  }

  Uri _uri(String path, Map<String, Object?>? query) {
    final base = Uri.parse('$baseUrl${SeerrConstants.apiPath}$path');
    if (query == null || query.isEmpty) return base;
    final parts = <String>[
      for (final entry in query.entries)
        if (entry.value != null) '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}',
    ];
    return parts.isEmpty ? base : base.replace(query: parts.join('&'));
  }

  /// Throw the mapped exception for a 4xx/5xx response; no-op on success.
  /// 401 is the caller's re-auth signal and also passes through.
  static void throwForStatus(SeerrResponse res) {
    final code = res.statusCode;
    if (code >= 200 && code < 300 || code == 401) return;
    final data = res.data;
    final message = data is Map<String, dynamic> ? data['message'] as String? : null;
    throw SeerrApiException((message?.isNotEmpty ?? false) ? message! : 'HTTP $code', statusCode: code);
  }

  /// Trim whitespace and trailing slashes so cookie/session identity and
  /// request URLs agree on one canonical instance URL.
  static String normalizeBaseUrl(String input) {
    var v = input.trim();
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }
}
