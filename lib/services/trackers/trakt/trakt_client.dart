import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../models/trakt/trakt_cast_entry.dart';
import '../../../models/trakt/trakt_catalog_entry.dart';
import '../../../models/trakt/trakt_catalog_media.dart';
import '../../../models/trakt/trakt_scrobble_request.dart';
import '../../../models/trakt/trakt_user.dart';
import '../../../utils/app_logger.dart';
import '../future_coalescer.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_exceptions.dart';
import '../tracker_http_client.dart';
import '../tracker_session.dart';
import 'trakt_constants.dart';
import '../tracker_page.dart';

/// HTTP wrapper for the Trakt REST API.
///
/// Holds a [TrackerSession] (refreshed in place on 401). Concurrent 401s are
/// coalesced so we only hit `/oauth/token` once per refresh.
class TraktClient implements DisposableTrackerClient {
  static const Set<int> _scrobbleAllowedStatuses = {200, 201, 409};
  static const Set<int> _permanentRefreshFailureStatuses = {400, 401, 403};
  final _refreshCoalescer = FutureCoalescer<TrackerSession>();

  TrackerSession _session;
  final TrackerHttpClient _http;

  /// Fired when refresh fails permanently (e.g. `invalid_grant`). The provider
  /// uses this to clear the stored session and notify the UI.
  final void Function() onSessionInvalidated;

  /// Fired when refresh succeeds so the provider can persist the rotated access/refresh token pair.
  final void Function(TrackerSession session)? onSessionUpdated;

  TraktClient(
    TrackerSession session, {
    required this.onSessionInvalidated,
    this.onSessionUpdated,
    http.Client? httpClient,
  }) : _session = session,
       _http = TrackerHttpClient(service: TrackerService.trakt, logLabel: 'Trakt', httpClient: httpClient);

  TrackerSession get session => _session;

  @override
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
      _request('POST', '/sync/history', body: item.toHistoryBody(watchedAt: watchedAt));

  Future<void> removeFromHistory(TraktScrobbleRequest item) =>
      _request('POST', '/sync/history/remove', body: item.toHistoryBody());

  Future<void> addRatings(Map<String, dynamic> body) =>
      _request('POST', '/sync/ratings', body: body, allowStatuses: const {200, 201});

  Future<void> removeRatings(Map<String, dynamic> body) => _request('POST', '/sync/ratings/remove', body: body);

  Future<List<dynamic>> getRatings(String type) async {
    final res = await _request('GET', '/sync/ratings/$type');
    return res is List ? res : const [];
  }

  // --- Catalog endpoints (Explore tab) ---

  static const String _catalogExtended = 'extended=full,images';

  /// `GET /sync/watchlist[/{type}/{sort}]`. A null [type] returns all entry
  /// types mixed, in the user's rank order. Pagination is currently optional
  /// on this endpoint; sending page/limit makes Trakt echo X-Pagination
  /// headers.
  Future<TrackerPage<TraktCatalogEntry>> getWatchlist({
    TraktCatalogType? type,
    String sort = 'added',
    int page = 1,
    int limit = 100,
  }) async {
    final path = type == null ? '/sync/watchlist' : '/sync/watchlist/${type.name}/$sort';
    final res = await _requestResponse('GET', '$path?$_catalogExtended&page=$page&limit=$limit');
    return TrackerPage.fromResponse(res, _decodeEntries(res.body));
  }

  /// Items are wrapped as `{watchers, movie|show}`. Public endpoint, but sent
  /// authenticated: the tab only exists with a session and per-user rate
  /// limiting is cleaner than app-level.
  Future<TrackerPage<TraktCatalogEntry>> getTrending(TraktCatalogType type, {int page = 1, int limit = 25}) async {
    final res = await _requestResponse('GET', '/${type.name}/trending?$_catalogExtended&page=$page&limit=$limit');
    return TrackerPage.fromResponse(res, _decodeEntries(res.body));
  }

  /// Returns bare movie/show objects (not wrapped like trending).
  Future<TrackerPage<TraktCatalogMedia>> getPopular(TraktCatalogType type, {int page = 1, int limit = 25}) async {
    final res = await _requestResponse('GET', '/${type.name}/popular?$_catalogExtended&page=$page&limit=$limit');
    return TrackerPage.fromResponse(res, _decodeMedia(res.body));
  }

  /// Personalized recommendations. OAuth-required, limit-only (no pagination).
  Future<List<TraktCatalogMedia>> getRecommended(
    TraktCatalogType type, {
    int limit = 25,
    bool ignoreCollected = false,
    bool ignoreWatchlisted = true,
  }) async {
    final res = await _requestResponse(
      'GET',
      '/recommendations/${type.name}'
          '?$_catalogExtended&limit=$limit&ignore_collected=$ignoreCollected&ignore_watchlisted=$ignoreWatchlisted',
    );
    return _decodeMedia(res.body);
  }

  /// Title search across movies and shows (`GET /search/movie,show`).
  /// Results are wrapped `{type, score, movie|show}` like watchlist entries.
  Future<TrackerPage<TraktCatalogEntry>> searchCatalog(String query, {int page = 1, int limit = 25}) async {
    final res = await _requestResponse(
      'GET',
      '/search/movie,show?query=${Uri.encodeQueryComponent(query)}&$_catalogExtended&page=$page&limit=$limit',
    );
    return TrackerPage.fromResponse(res, _decodeEntries(res.body));
  }

  /// Similar titles (`GET /{movies|shows}/{id}/related`) — bare media
  /// objects of the same type. [id] is a Trakt numeric id or slug.
  Future<List<TraktCatalogMedia>> getRelated(TraktCatalogType type, String id, {int limit = 20}) async {
    final res = await _requestResponse('GET', '/${type.name}/$id/related?$_catalogExtended&limit=$limit');
    return _decodeMedia(res.body);
  }

  /// People for a title (`GET /{movies|shows}/{id}/people`). Show requests
  /// include `guest_stars`; Trakt documents that this returns every guest star
  /// with at least one episode and can be a lot of data, so callers must bound
  /// the cast they retain.
  Future<TraktPeople> getPeople(TraktCatalogType type, String id) async {
    final extended = type == TraktCatalogType.shows ? '$_catalogExtended,guest_stars' : _catalogExtended;
    final res = await _requestResponse('GET', '/${type.name}/$id/people?$extended');
    final decoded = TrackerHttpClient.decodeJson(res.body);
    if (decoded is! Map) return const TraktPeople();
    return TraktPeople(
      cast: _decodePeopleEntries(decoded['cast']),
      guestStars: _decodePeopleEntries(decoded['guest_stars']),
      crew: _decodeCrewEntries(decoded['crew']),
    );
  }

  /// Body shape: `{"movies":[{"ids":{...}}],"shows":[{"ids":{...}}]}`.
  Future<void> addToWatchlist(Map<String, dynamic> body) =>
      _request('POST', '/sync/watchlist', body: body, allowStatuses: const {200, 201});

  Future<void> removeFromWatchlist(Map<String, dynamic> body) => _request('POST', '/sync/watchlist/remove', body: body);

  static List<TraktCastEntry> _decodePeopleEntries(Object? raw) {
    if (raw is! List) return const [];
    return [for (final entry in raw.whereType<Map<String, dynamic>>()) TraktCastEntry.fromJson(entry)];
  }

  static List<TraktCastEntry> _decodeCrewEntries(Object? raw) {
    if (raw is! Map) return const [];
    return [
      for (final department in raw.values.whereType<List>())
        for (final entry in department.whereType<Map<String, dynamic>>()) TraktCastEntry.fromJson(entry),
    ];
  }

  static List<TraktCatalogEntry> _decodeEntries(String body) {
    final decoded = TrackerHttpClient.decodeJson(body);
    if (decoded is! List) return const [];
    return [for (final e in decoded.whereType<Map<String, dynamic>>()) TraktCatalogEntry.fromJson(e)];
  }

  static List<TraktCatalogMedia> _decodeMedia(String body) {
    final decoded = TrackerHttpClient.decodeJson(body);
    if (decoded is! List) return const [];
    return [for (final e in decoded.whereType<Map<String, dynamic>>()) TraktCatalogMedia.fromJson(e)];
  }

  /// Refresh the access token. Coalesces concurrent calls so
  /// duplicate POSTs don't race when multiple in-flight requests hit 401.
  Future<TrackerSession> refresh() => _refreshCoalescer.run(_doRefresh);

  Future<TrackerSession> _doRefresh() async {
    final String refreshToken;
    try {
      refreshToken = _session.requireRefreshToken(TrackerService.trakt);
    } on TrackerAuthException catch (e) {
      if (e.isPermanent) onSessionInvalidated();
      rethrow;
    }
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
    final res = await _requestResponse(method, path, body: body, allowStatuses: allowStatuses);
    return TrackerHttpClient.decodeJson(res.body);
  }

  /// [_request] variant exposing the raw response for callers that need
  /// headers (pagination).
  Future<http.Response> _requestResponse(
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
      // A failed refresh propagates its TrackerAuthException; MAL's equivalent
      // path flattens the same failure into TrackerApiException(401).
      await refresh();
      res = await _send(method, path, body: body);
    }

    if (allowStatuses.contains(res.statusCode)) return res;

    if (res.statusCode == 429) {
      throw TrackerRateLimitException(
        service: TrackerService.trakt,
        retryAfterSeconds: int.tryParse(res.headers['retry-after'] ?? ''),
      );
    }

    throw TrackerApiException(service: TrackerService.trakt, statusCode: res.statusCode);
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
