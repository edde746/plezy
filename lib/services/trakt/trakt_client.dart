import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/trakt/trakt_scrobble_request.dart';
import '../../models/trakt/trakt_user.dart';
import '../../utils/abortable_http_request.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;
import '../trackers/tracker_constants.dart';
import 'trakt_constants.dart';
import 'trakt_session.dart';

/// HTTP wrapper for the Trakt REST API.
///
/// Holds a [TraktSession] (refreshed in place on 401). Concurrent 401s are
/// coalesced so we only hit `/oauth/token` once per refresh.
class TraktClient {
  static const Set<int> _scrobbleAllowedStatuses = {200, 201, 409};
  static const Set<int> _permanentRefreshFailureStatuses = {400, 401, 403};
  static final Map<String, Future<TraktSession>> _refreshesByToken = {};

  TraktSession _session;
  final http.Client _http;

  /// Fired when refresh fails permanently (e.g. `invalid_grant`). The provider
  /// uses this to clear the stored session and notify the UI.
  final void Function() onSessionInvalidated;

  /// Fired when refresh succeeds so the provider can persist the rotated
  /// access/refresh token pair and share it with the other active Trakt clients.
  final void Function(TraktSession session)? onSessionUpdated;

  TraktClient(
    TraktSession session, {
    required this.onSessionInvalidated,
    this.onSessionUpdated,
    http.Client? httpClient,
  })
    : _session = session,
      _http = httpClient ?? platform.createPlatformClient();

  TraktSession get session => _session;

  void updateSession(TraktSession session) {
    _session = session;
  }

  void dispose() => _http.close();

  Future<TraktUser> getUserSettings() async {
    final res = await _request('GET', '/users/settings');
    return TraktUser.fromJson(res as Map<String, dynamic>);
  }

  Future<void> scrobbleStart(TraktScrobbleRequest body) =>
      _request('POST', '/scrobble/start', body: body.toJson(), allowStatuses: _scrobbleAllowedStatuses);

  Future<void> scrobblePause(TraktScrobbleRequest body) =>
      _request('POST', '/scrobble/pause', body: body.toJson(), allowStatuses: _scrobbleAllowedStatuses);

  Future<void> scrobbleStop(TraktScrobbleRequest body) =>
      _request('POST', '/scrobble/stop', body: body.toJson(), allowStatuses: _scrobbleAllowedStatuses);

  Future<void> addToHistory(TraktScrobbleRequest item, {String? watchedAt}) =>
      _request('POST', '/sync/history', body: item.toHistoryAddBody(watchedAt: watchedAt));

  Future<void> removeFromHistory(TraktScrobbleRequest item) =>
      _request('POST', '/sync/history/remove', body: item.toHistoryRemoveBody());

  Future<void> addRatings(Map<String, dynamic> body) =>
      _request('POST', '/sync/ratings', body: body, allowStatuses: const {200, 201});

  Future<void> removeRatings(Map<String, dynamic> body) => _request('POST', '/sync/ratings/remove', body: body);

  Future<List<dynamic>> getRatings(String type) async {
    final res = await _request('GET', '/sync/ratings/$type');
    return res is List ? res : const [];
  }

  /// Refresh the access token. Coalesces concurrent calls so
  /// duplicate POSTs don't race when multiple in-flight requests hit 401.
  Future<TraktSession> refresh() async {
    final refreshToken = _session.refreshToken;
    final existing = _refreshesByToken[refreshToken];
    if (existing != null) {
      try {
        final session = await existing;
        if (_session.refreshToken == refreshToken) {
          _session = session;
          onSessionUpdated?.call(session);
        }
        return _session;
      } on TraktAuthException catch (e) {
        if (e.isPermanent && _session.refreshToken == refreshToken) {
          onSessionInvalidated();
        }
        rethrow;
      }
    }

    late final Future<TraktSession> refresh;
    refresh = _doRefresh(refreshToken).whenComplete(() {
      if (identical(_refreshesByToken[refreshToken], refresh)) {
        _refreshesByToken.remove(refreshToken);
      }
    });
    _refreshesByToken[refreshToken] = refresh;
    return refresh;
  }

  Future<TraktSession> _doRefresh(String refreshToken) async {
    appLogger.d('Trakt: refreshing access token');
    final tokenUri = Uri.parse(TraktConstants.tokenUrl);
    final res = await sendAbortableHttpRequest(
      _http,
      'POST',
      tokenUri,
      headers: TraktConstants.headers(),
      body: json.encode({
        'refresh_token': refreshToken,
        'client_id': TraktConstants.clientId,
        'client_secret': TraktConstants.clientSecret,
        'grant_type': 'refresh_token',
      }),
      timeout: TrackerConstants.refreshTimeout,
      operation: 'Trakt token refresh',
    );

    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      _session = TraktSession.fromTokenResponse(body).copyWith(username: _session.username);
      onSessionUpdated?.call(_session);
      return _session;
    }

    if (_session.refreshToken != refreshToken) {
      appLogger.d('Trakt: refresh failed (${res.statusCode}) after session update; keeping latest session');
      return _session;
    }

    final isPermanent = _permanentRefreshFailureStatuses.contains(res.statusCode);
    if (isPermanent) {
      appLogger.w('Trakt: refresh failed permanently (${res.statusCode}), session invalidated');
      onSessionInvalidated();
    } else {
      appLogger.w('Trakt: refresh failed (${res.statusCode}), will retry later');
    }
    throw TraktAuthException(
      'Refresh failed: HTTP ${res.statusCode}',
      statusCode: res.statusCode,
      isPermanent: isPermanent,
    );
  }

  /// Revoke the access token at Trakt. Best-effort; swallows network errors.
  Future<void> revoke() async {
    try {
      await sendAbortableHttpRequest(
        _http,
        'POST',
        Uri.parse(TraktConstants.revokeUrl),
        headers: TraktConstants.headers(),
        body: json.encode({
          'token': _session.accessToken,
          'client_id': TraktConstants.clientId,
          'client_secret': TraktConstants.clientSecret,
        }),
        timeout: TrackerConstants.revokeTimeout,
        operation: 'Trakt token revoke',
      );
    } catch (e) {
      appLogger.d('Trakt: revoke failed (non-fatal)', error: e);
    }
  }

  /// Send an authenticated request, refreshing on 401 and retrying once.
  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Set<int> allowStatuses = const {200, 201, 204},
  }) async {
    if (_session.needsRefresh) {
      try {
        await refresh();
      } catch (_) {
        // Fall through; the request will hit 401 naturally and retry.
      }
    }

    var res = await _send(method, path, body: body);

    if (res.statusCode == 401) {
      await refresh();
      res = await _send(method, path, body: body);
    }

    if (allowStatuses.contains(res.statusCode)) {
      if (res.body.isEmpty) return null;
      try {
        return json.decode(res.body);
      } catch (_) {
        return null;
      }
    }

    if (res.statusCode == 429) {
      throw TraktRateLimitException(retryAfterSeconds: int.tryParse(res.headers['retry-after'] ?? ''));
    }

    throw TraktApiException(statusCode: res.statusCode, body: res.body);
  }

  Future<http.Response> _send(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${TraktConstants.apiBase}$path');
    final headers = TraktConstants.headers(accessToken: _session.accessToken);
    final encoded = body == null ? null : json.encode(body);

    final sw = Stopwatch()..start();
    final res = await switch (method) {
      'GET' || 'POST' || 'PUT' || 'DELETE' => sendAbortableHttpRequest(
        _http,
        method,
        uri,
        headers: headers,
        body: encoded,
        timeout: TrackerConstants.requestTimeout,
        operation: 'Trakt $method ${uri.path}',
      ),
      _ => throw ArgumentError('Unsupported HTTP method: $method'),
    };
    sw.stop();

    appLogger.d('Trakt $method ${uri.path} → ${res.statusCode} (${sw.elapsedMilliseconds}ms)');
    return res;
  }
}

class TraktApiException implements Exception {
  final int statusCode;
  final String body;
  const TraktApiException({required this.statusCode, required this.body});
  @override
  String toString() => 'TraktApiException(HTTP $statusCode): $body';
}

class TraktRateLimitException implements Exception {
  final int? retryAfterSeconds;
  const TraktRateLimitException({this.retryAfterSeconds});
  @override
  String toString() => 'TraktRateLimitException(retry-after: $retryAfterSeconds s)';
}

class TraktAuthException implements Exception {
  final String message;
  final int? statusCode;
  final bool isPermanent;
  const TraktAuthException(this.message, {this.statusCode, this.isPermanent = false});
  @override
  String toString() => 'TraktAuthException: $message';
}
