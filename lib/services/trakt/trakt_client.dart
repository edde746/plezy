import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/trakt/trakt_scrobble_request.dart';
import '../../models/trakt/trakt_user.dart';
import '../../utils/app_logger.dart';
import '../trackers/tracker_constants.dart';
import '../trackers/tracker_exceptions.dart';
import '../trackers/tracker_http_client.dart';
import '../trackers/tracker_session.dart';
import 'trakt_constants.dart';

/// HTTP wrapper for the Trakt REST API.
///
/// Holds a [TrackerSession] (refreshed in place on 401). Concurrent 401s are
/// coalesced so we only hit `/oauth/token` once per refresh.
class TraktClient {
  static const Set<int> _scrobbleAllowedStatuses = {200, 201, 409};
  static const Set<int> _permanentRefreshFailureStatuses = {400, 401, 403};
  static final Map<String, Future<TrackerSession>> _refreshesByToken = {};

  TrackerSession _session;
  final TrackerHttpClient _http;

  /// Fired when refresh fails permanently (e.g. `invalid_grant`). The provider
  /// uses this to clear the stored session and notify the UI.
  final void Function() onSessionInvalidated;

  /// Fired when refresh succeeds so the provider can persist the rotated
  /// access/refresh token pair and share it with the other active Trakt clients.
  final void Function(TrackerSession session)? onSessionUpdated;

  TraktClient(
    TrackerSession session, {
    required this.onSessionInvalidated,
    this.onSessionUpdated,
    http.Client? httpClient,
  }) : _session = session,
       _http = TrackerHttpClient(service: TrackerService.trakt, logLabel: 'Trakt', httpClient: httpClient);

  TrackerSession get session => _session;

  void updateSession(TrackerSession session) {
    _session = session;
  }

  void dispose() => _http.dispose();

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
  Future<TrackerSession> refresh() async {
    final String refreshToken;
    try {
      refreshToken = _session.requireRefreshToken(TrackerService.trakt);
    } on TrackerAuthException catch (e) {
      if (e.isPermanent) onSessionInvalidated();
      rethrow;
    }
    final existing = _refreshesByToken[refreshToken];
    if (existing != null) {
      try {
        final session = await existing;
        if (_session.refreshToken == refreshToken) {
          _session = session;
          onSessionUpdated?.call(session);
        }
        return _session;
      } on TrackerAuthException catch (e) {
        if (e.isPermanent && _session.refreshToken == refreshToken) {
          onSessionInvalidated();
        }
        rethrow;
      }
    }

    late final Future<TrackerSession> refresh;
    refresh = _doRefresh(refreshToken).whenComplete(() {
      if (identical(_refreshesByToken[refreshToken], refresh)) {
        _refreshesByToken.remove(refreshToken);
      }
    });
    _refreshesByToken[refreshToken] = refresh;
    return refresh;
  }

  Future<TrackerSession> _doRefresh(String refreshToken) async {
    appLogger.d('Trakt: refreshing access token');
    final tokenUri = Uri.parse(TraktConstants.tokenUrl);
    final res = await _http.sendJson(
      'POST',
      tokenUri,
      headers: TraktConstants.headers(),
      body: {
        'refresh_token': refreshToken,
        'client_id': TraktConstants.clientId,
        'client_secret': TraktConstants.clientSecret,
        'grant_type': 'refresh_token',
      },
      timeout: TrackerConstants.refreshTimeout,
      operation: 'Trakt token refresh',
      allowedMethods: const {'POST'},
    );

    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      _session = TrackerSession.fromTokenResponse(TrackerService.trakt, body).copyWith(username: _session.username);
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
    throw TrackerAuthException(
      service: TrackerService.trakt,
      message: 'Refresh failed: HTTP ${res.statusCode}',
      statusCode: res.statusCode,
      isPermanent: isPermanent,
    );
  }

  /// Revoke the access token at Trakt. Best-effort; swallows network errors.
  Future<void> revoke() async {
    try {
      await _http.sendJson(
        'POST',
        Uri.parse(TraktConstants.revokeUrl),
        headers: TraktConstants.headers(),
        body: {
          'token': _session.accessToken,
          'client_id': TraktConstants.clientId,
          'client_secret': TraktConstants.clientSecret,
        },
        timeout: TrackerConstants.revokeTimeout,
        operation: 'Trakt token revoke',
        allowedMethods: const {'POST'},
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
      return TrackerHttpClient.decodeJson(res.body);
    }

    if (res.statusCode == 429) {
      throw TrackerRateLimitException(
        service: TrackerService.trakt,
        retryAfterSeconds: int.tryParse(res.headers['retry-after'] ?? ''),
      );
    }

    throw TrackerApiException(service: TrackerService.trakt, statusCode: res.statusCode, body: res.body);
  }

  Future<http.Response> _send(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${TraktConstants.apiBase}$path');
    final headers = TraktConstants.headers(accessToken: _session.accessToken);
    return _http.sendJson(
      method,
      uri,
      headers: headers,
      body: body,
      allowedMethods: const {'GET', 'POST', 'PUT', 'DELETE'},
    );
  }
}
