import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../utils/app_logger.dart';
import '../../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../../utils/platform_http_client_io.dart'
    as platform;
import 'simkl_constants.dart';
import 'simkl_session.dart';

/// HTTP wrapper for the Simkl REST API.
///
/// Simkl tokens don't expire; a 401 is terminal (user revoked access at
/// simkl.com/settings/apps). [onSessionInvalidated] clears the local session
/// in that case.
class SimklClient {
  static const Duration _requestTimeout = Duration(seconds: 20);

  final SimklSession session;
  final http.Client _http;
  final void Function() onSessionInvalidated;

  SimklClient(this.session, {required this.onSessionInvalidated, http.Client? httpClient})
    : _http = httpClient ?? platform.createPlatformClient();

  void dispose() => _http.close();

  /// Fetch current user info. Used to populate the display name.
  Future<Map<String, dynamic>?> getUserSettings() async {
    final res = await _request('GET', '/users/settings');
    return res is Map ? res.cast<String, dynamic>() : null;
  }

  /// Mark one or more items as watched. Body shape:
  /// ```
  /// {"movies": [{"ids": {"simkl": 123}}], "shows": [...]}
  /// ```
  Future<void> addToHistory(Map<String, dynamic> body) => _request('POST', '/sync/history', body: body);

  Future<dynamic> _request(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${SimklConstants.apiBase}$path');
    final headers = SimklConstants.headers(accessToken: session.accessToken);
    final encoded = body == null ? null : json.encode(body);

    final sw = Stopwatch()..start();
    final res = await switch (method) {
      'GET' => _http.get(uri, headers: headers),
      'POST' => _http.post(uri, headers: headers, body: encoded),
      _ => throw ArgumentError('Unsupported HTTP method: $method'),
    }.timeout(_requestTimeout);
    sw.stop();
    appLogger.d('Simkl $method ${uri.path} → ${res.statusCode} (${sw.elapsedMilliseconds}ms)');

    if (res.statusCode == 401) {
      onSessionInvalidated();
      throw SimklAuthException('Session invalidated (401)');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw SimklApiException(statusCode: res.statusCode, body: res.body);
    }
    if (res.body.isEmpty) return null;
    try {
      return json.decode(res.body);
    } catch (_) {
      return null;
    }
  }
}

class SimklApiException implements Exception {
  final int statusCode;
  final String body;
  const SimklApiException({required this.statusCode, required this.body});
  @override
  String toString() => 'SimklApiException(HTTP $statusCode): $body';
}

class SimklAuthException implements Exception {
  final String message;
  const SimklAuthException(this.message);
  @override
  String toString() => 'SimklAuthException: $message';
}
