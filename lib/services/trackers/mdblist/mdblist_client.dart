import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../utils/app_logger.dart';
import '../future_coalescer.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_exceptions.dart';
import '../tracker_http_client.dart';
import '../tracker_session.dart';
import 'mdblist_auth_service.dart';
import 'mdblist_constants.dart';

/// HTTP wrapper for the MDBList REST API.
///
/// Access tokens live 30 days and rotate through the refresh grant, so this
/// mirrors the MAL/Trakt shape: refresh shortly before expiry or on a 401,
/// with concurrent refreshes coalesced into one in-flight request.
class MdblistClient implements DisposableTrackerClient {
  /// `/scrobble/*` answers 201 on success; the sync endpoints answer 200.
  static const Set<int> _defaultAllowedStatuses = {200, 201, 204};

  TrackerSession _session;
  final TrackerHttpClient _http;
  final MdblistAuthService _auth;
  final void Function() onSessionInvalidated;
  final void Function(TrackerSession)? onSessionUpdated;

  final _refreshCoalescer = FutureCoalescer<TrackerSession>();

  MdblistClient(
    TrackerSession session, {
    required this.onSessionInvalidated,
    this.onSessionUpdated,
    http.Client? httpClient,
    MdblistAuthService? authService,
  }) : _session = session,
       _http = TrackerHttpClient(service: TrackerService.mdblist, logLabel: 'MDBList', httpClient: httpClient),
       _auth = authService ?? MdblistAuthService();

  TrackerSession get session => _session;

  @override
  void dispose() {
    _http.dispose();
    _auth.dispose();
  }

  /// Current account. Used to populate the display name.
  Future<Map<String, dynamic>?> getUser() async {
    final res = await _request('GET', '/user');
    return res is Map ? res.cast<String, dynamic>() : null;
  }

  /// Mark items watched. Body shape:
  /// ```
  /// {"movies": [{"ids": {"imdb": "tt0372784"}, "watched_at": "..."}]}
  /// ```
  Future<void> addToWatched(Map<String, dynamic> body) => _request('POST', '/sync/watched', body: body);

  Future<void> removeFromWatched(Map<String, dynamic> body) => _request('POST', '/sync/watched/remove', body: body);

  /// Report real-time playback. [action] is `start`, `pause` or `stop`.
  Future<void> scrobble(String action, Map<String, dynamic> body) => _request('POST', '/scrobble/$action', body: body);

  Future<void> addRatings(Map<String, dynamic> body) => _request('POST', '/sync/ratings', body: body);

  Future<void> removeRatings(Map<String, dynamic> body) => _request('POST', '/sync/ratings/remove', body: body);

  /// All of the user's ratings, keyed by `movies` / `shows` / `seasons` /
  /// `episodes`. MDBList has no per-item rating lookup, so the caller filters.
  Future<List<dynamic>> getRatings(String type) async {
    final res = await _request('GET', '/sync/ratings');
    if (res is Map && res[type] is List) return res[type] as List<dynamic>;
    return const [];
  }

  /// Best-effort server-side revoke, mirroring Trakt's disconnect. Failure is
  /// non-fatal: the local session is already gone by the time this runs.
  Future<void> revoke() async {
    try {
      await _http.sendForm(
        'POST',
        Uri.parse(MdblistConstants.revokeUrl),
        headers: MdblistConstants.headers(),
        body: {'token': _session.accessToken, 'client_id': MdblistConstants.clientId},
        timeout: TrackerConstants.revokeTimeout,
        operation: 'MDBList token revoke',
        allowedMethods: const {'POST'},
      );
    } catch (e) {
      appLogger.d('MDBList: revoke failed (non-fatal)', error: e);
    }
  }

  Future<TrackerSession> _refresh() => _refreshCoalescer.run(_doRefresh);

  Future<TrackerSession> _doRefresh() async {
    try {
      final fresh = await _auth.refresh(_session);
      _session = fresh;
      onSessionUpdated?.call(fresh);
      return fresh;
    } catch (e) {
      appLogger.w('MDBList: refresh failed', error: e);
      // Only a terminally-invalid grant clears the session; transient 5xx and
      // network failures fall through so a later 401 can retry.
      if (e is TrackerAuthException && e.isPermanent) onSessionInvalidated();
      rethrow;
    }
  }

  /// Send an authenticated request, refreshing on 401 and retrying once.
  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Set<int> allowStatuses = _defaultAllowedStatuses,
  }) async {
    if (_session.needsRefresh) {
      try {
        await _refresh();
      } catch (_) {
        // Fall through; the request will hit 401 naturally and retry.
      }
    }

    var res = await _send(method, path, body: body);

    if (res.statusCode == 401) {
      // A failed refresh propagates its TrackerAuthException, matching Trakt.
      await _refresh();
      res = await _send(method, path, body: body);
    }

    if (allowStatuses.contains(res.statusCode)) return TrackerHttpClient.decodeJson(res.body);

    if (res.statusCode == 429) {
      throw TrackerRateLimitException(
        service: TrackerService.mdblist,
        retryAfterSeconds: int.tryParse(res.headers['retry-after'] ?? ''),
      );
    }

    throw TrackerApiException(service: TrackerService.mdblist, statusCode: res.statusCode);
  }

  Future<http.Response> _send(String method, String path, {Map<String, dynamic>? body}) {
    final uri = Uri.parse('${MdblistConstants.apiBase}$path');
    return _http.sendJson(
      method,
      uri,
      headers: MdblistConstants.headers(accessToken: _session.accessToken),
      body: body,
      allowedMethods: const {'GET', 'POST'},
    );
  }
}
