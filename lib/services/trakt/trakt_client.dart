import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/trakt/trakt_scrobble_request.dart';
import '../../models/trakt/trakt_user.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;
import '../trackers/future_coalescer.dart';
import '../trackers/tracker_constants.dart';
import 'trakt_constants.dart';
import 'trakt_session.dart';

/// HTTP wrapper for the Trakt REST API.
///
/// Holds a [TraktSession] (refreshed in place on 401). Concurrent 401s are
/// coalesced so we only hit `/oauth/token` once per refresh.
class TraktClient {
  static const Set<int> _scrobbleAllowedStatuses = {200, 201, 409};

  TraktSession _session;
  final http.Client _http;

  /// Fired when refresh fails permanently (e.g. `invalid_grant`). The provider
  /// uses this to clear the stored session and notify the UI.
  final void Function() onSessionInvalidated;

  final _refreshCoalescer = FutureCoalescer<TraktSession>();

  TraktClient(TraktSession session, {required this.onSessionInvalidated, http.Client? httpClient})
    : _session = session,
      _http = httpClient ?? platform.createPlatformClient();

  TraktSession get session => _session;

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

  /// Refresh the access token. Coalesces concurrent calls so
  /// duplicate POSTs don't race when multiple in-flight requests hit 401.
  Future<TraktSession> refresh() => _refreshCoalescer.run(_doRefresh);

  Future<TraktSession> _doRefresh() async {
    appLogger.d('Trakt: refreshing access token');
    final res = await _http
        .post(
          Uri.parse(TraktConstants.tokenUrl),
          headers: TraktConstants.headers(),
          body: json.encode({
            'refresh_token': _session.refreshToken,
            'client_id': TraktConstants.clientId,
            'client_secret': TraktConstants.clientSecret,
            'grant_type': 'refresh_token',
          }),
        )
        .timeout(TrackerConstants.refreshTimeout);

    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      _session = TraktSession.fromTokenResponse(body).copyWith(username: _session.username);
      return _session;
    }

    appLogger.w('Trakt: refresh failed (${res.statusCode}), session invalidated');
    onSessionInvalidated();
    throw TraktAuthException('Refresh failed: HTTP ${res.statusCode}');
  }

  /// Revoke the access token at Trakt. Best-effort; swallows network errors.
  Future<void> revoke() async {
    try {
      await _http
          .post(
            Uri.parse(TraktConstants.revokeUrl),
            headers: TraktConstants.headers(),
            body: json.encode({
              'token': _session.accessToken,
              'client_id': TraktConstants.clientId,
              'client_secret': TraktConstants.clientSecret,
            }),
          )
          .timeout(TrackerConstants.revokeTimeout);
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
      'GET' => _http.get(uri, headers: headers),
      'POST' => _http.post(uri, headers: headers, body: encoded),
      'PUT' => _http.put(uri, headers: headers, body: encoded),
      'DELETE' => _http.delete(uri, headers: headers),
      _ => throw ArgumentError('Unsupported HTTP method: $method'),
    }.timeout(TrackerConstants.requestTimeout);
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
  const TraktAuthException(this.message);
  @override
  String toString() => 'TraktAuthException: $message';
}
