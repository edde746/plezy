import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utils/abortable_http_request.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;
import '../trackers/tracker_http_client.dart';
import 'cli_debrid_constants.dart';
import 'cli_debrid_exceptions.dart';

/// HTTP response paired with its decoded JSON body. `data` is null for
/// no-content responses and non-JSON bodies.
class CliDebridResponse {
  final http.Response response;
  final dynamic data;
  const CliDebridResponse(this.response, this.data);

  int get statusCode => response.statusCode;
}

/// Thin wrapper around `package:http` for cli_debrid API calls.
///
/// Auth is a single static API token sent as `Authorization: Bearer <token>`
/// (cli_debrid's `_check_api_token()` accepts this or `?token=`; the header
/// form avoids leaking the token into request logs/proxies via the URL).
/// No cookie capture, no re-auth — unlike Seerr, cli_debrid's token doesn't
/// expire on its own.
class CliDebridHttpClient {
  final String baseUrl;
  final String apiToken;
  final http.Client _http;

  CliDebridHttpClient({required this.baseUrl, required this.apiToken, http.Client? httpClient})
    : _http = httpClient ?? platform.createPlatformClient();

  void dispose() => _http.close();

  /// Send a request against [path] (relative to [baseUrl], e.g. '/database/rescrape_item'),
  /// returning the decoded JSON body. Non-2xx is returned to the caller
  /// (never thrown here) — see [throwForStatus] for the mapped-exception path.
  Future<CliDebridResponse> send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Map<String, Object?>? body,
    Duration timeout = CliDebridConstants.requestTimeout,
  }) async {
    if (!const {'GET', 'POST', 'PUT', 'DELETE'}.contains(method)) {
      throw ArgumentError('Unsupported HTTP method: $method');
    }
    final uri = _uri(path, query);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (apiToken.isNotEmpty) 'Authorization': 'Bearer $apiToken',
      if (body != null) 'Content-Type': 'application/json',
    };
    final sw = Stopwatch()..start();
    final response = await sendAbortableHttpRequest(
      _http,
      method,
      uri,
      headers: headers,
      body: body == null ? null : jsonEncode(body),
      timeout: timeout,
      operation: 'cli_debrid $method $path',
    );
    appLogger.d('cli_debrid $method $path -> ${response.statusCode} (${sw.elapsedMilliseconds}ms)');
    return CliDebridResponse(response, TrackerHttpClient.decodeJson(response.body));
  }

  Uri _uri(String path, Map<String, Object?>? query) {
    final base = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: {for (final e in query.entries) e.key: '${e.value}'});
  }

  /// Throw the mapped exception for a 4xx/5xx response; no-op on success.
  static void throwForStatus(CliDebridResponse res) {
    final code = res.statusCode;
    if (code >= 200 && code < 300) return;
    final data = res.data;
    final message = data is Map<String, dynamic> ? data['error'] as String? : null;
    if (code == 401 || code == 302) {
      // cli_debrid's @user_required redirects (302) to /auth/login on missing/
      // invalid credentials rather than a clean 401 when the user system is
      // enabled but the caller has no session — treat both as an auth failure.
      throw CliDebridAuthException(
        (message?.isNotEmpty ?? false) ? message! : 'Authentication failed',
        statusCode: code,
      );
    }
    final candidatesRaw = data is Map<String, dynamic> ? data['candidates'] : null;
    final candidates = candidatesRaw is List ? candidatesRaw.whereType<Map<String, Object?>>().toList() : null;
    throw CliDebridApiException(
      (message?.isNotEmpty ?? false) ? message! : 'HTTP $code',
      statusCode: code,
      candidates: candidates,
    );
  }

  /// Trim whitespace and trailing slashes so URL construction is consistent.
  static String normalizeBaseUrl(String input) {
    var v = input.trim();
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }
}
