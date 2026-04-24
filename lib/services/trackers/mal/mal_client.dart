import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../utils/app_logger.dart';
import '../../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../../utils/platform_http_client_io.dart'
    as platform;
import 'mal_auth_service.dart';
import 'mal_constants.dart';
import 'mal_session.dart';

/// HTTP wrapper for the MAL REST API.
///
/// Refreshes the access token 5 minutes before expiry or on 401. Concurrent
/// 401s are coalesced via [_refreshLock] (same pattern as `TraktClient`).
class MalClient {
  static const Duration _requestTimeout = Duration(seconds: 20);

  MalSession _session;
  final http.Client _http;
  final MalAuthService _auth;
  final void Function() onSessionInvalidated;
  final void Function(MalSession)? onSessionUpdated;

  Future<MalSession>? _refreshLock;

  MalClient(
    MalSession session, {
    required this.onSessionInvalidated,
    this.onSessionUpdated,
    http.Client? httpClient,
    MalAuthService? authService,
  }) : _session = session,
       _http = httpClient ?? platform.createPlatformClient(),
       _auth = authService ?? MalAuthService();

  MalSession get session => _session;

  void dispose() {
    _http.close();
    _auth.dispose();
  }

  /// Fetch basic user info to get the display name.
  Future<Map<String, dynamic>?> getMyUser() async {
    final res = await _request('GET', '/users/@me');
    return res is Map ? res.cast<String, dynamic>() : null;
  }

  /// Update the user's list entry for an anime. Body shape:
  /// ```
  /// {"status": "watching", "num_watched_episodes": 5}
  /// ```
  Future<void> updateMyListStatus(int animeId, Map<String, String> fields) async {
    // MAL's list-status endpoint is form-encoded (not JSON).
    await _request('PATCH', '/anime/$animeId/my_list_status', formBody: fields);
  }

  Future<MalSession> _refresh() {
    final existing = _refreshLock;
    if (existing != null) return existing;
    final lock = _doRefresh();
    _refreshLock = lock;
    return lock.whenComplete(() => _refreshLock = null);
  }

  Future<MalSession> _doRefresh() async {
    try {
      final fresh = await _auth.refresh(_session);
      _session = fresh;
      onSessionUpdated?.call(fresh);
      return fresh;
    } catch (e) {
      appLogger.w('MAL: refresh failed', error: e);
      onSessionInvalidated();
      rethrow;
    }
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? formBody,
  }) async {
    if (_session.needsRefresh) {
      try {
        await _refresh();
      } catch (_) {
        // Fall through; the request will hit 401 naturally and re-try.
      }
    }

    var res = await _send(method, path, body: body, formBody: formBody);

    if (res.statusCode == 401) {
      try {
        await _refresh();
      } catch (_) {
        throw MalApiException(statusCode: 401, body: res.body);
      }
      res = await _send(method, path, body: body, formBody: formBody);
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      try {
        return json.decode(res.body);
      } catch (_) {
        return null;
      }
    }
    throw MalApiException(statusCode: res.statusCode, body: res.body);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? formBody,
  }) async {
    final uri = Uri.parse('${MalConstants.apiBase}$path');
    final headers = MalConstants.headers(accessToken: _session.accessToken);

    String? encoded;
    if (formBody != null) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
      encoded = formBody.entries
          .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
    } else if (body != null) {
      headers['Content-Type'] = 'application/json';
      encoded = json.encode(body);
    }

    final sw = Stopwatch()..start();
    final res = await switch (method) {
      'GET' => _http.get(uri, headers: headers),
      'POST' => _http.post(uri, headers: headers, body: encoded),
      'PATCH' => _http.patch(uri, headers: headers, body: encoded),
      'PUT' => _http.put(uri, headers: headers, body: encoded),
      'DELETE' => _http.delete(uri, headers: headers),
      _ => throw ArgumentError('Unsupported HTTP method: $method'),
    }.timeout(_requestTimeout);
    sw.stop();
    appLogger.d('MAL $method ${uri.path} → ${res.statusCode} (${sw.elapsedMilliseconds}ms)');
    return res;
  }
}

class MalApiException implements Exception {
  final int statusCode;
  final String body;
  const MalApiException({required this.statusCode, required this.body});
  @override
  String toString() => 'MalApiException(HTTP $statusCode): $body';
}
