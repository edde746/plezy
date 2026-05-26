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

  Future<void> addRatings(Map<String, dynamic> body) =>
      _request('POST', '/sync/ratings', body: body, allowStatuses: const {200, 201});

  Future<void> removeRatings(Map<String, dynamic> body) => _request('POST', '/sync/ratings/remove', body: body);

  /// Saves current playback progress as a resume point.
  /// Per trakt.apib, /scrobble/stop with progress < 80% stores the position
  /// without marking as watched. Returns immediately for progress < 1% to
  /// avoid Trakt's 422 response.
  Future<void> savePlaybackProgress(TraktScrobbleRequest item) {
    if ((item.progress ?? 0) < 1.0) return Future.value();
    return scrobbleStop(item);
  }

  // ---------------------------------------------------------------------------
  // Pull methods — used by TraktWatchStateProvider for authoritative watch state
  // ---------------------------------------------------------------------------

  /// `GET /sync/watched/movies` — full history for all watched movies.
  Future<List<dynamic>> getWatchedMovies() async {
    final res = await _request('GET', '/sync/watched/movies');
    return res as List<dynamic>? ?? [];
  }

  /// `GET /sync/watched/shows` — full history including per-season/episode data.
  /// Does NOT use `?extended=noseasons` so we get the complete episode breakdown.
  Future<List<dynamic>> getWatchedShows() async {
    final res = await _request('GET', '/sync/watched/shows');
    return res as List<dynamic>? ?? [];
  }

  /// `GET apiz.trakt.tv/sync/progress/up_next_nitro` — private endpoint that
  /// returns shows with a next episode to watch, regardless of whether it has
  /// been started. Used to supplement /sync/playback/episodes for shows where
  /// the last episode was completed but the next hasn't been started.
  Future<List<dynamic>> getUpNextItems() async {
    final res = await _request('GET', '${TraktConstants.apizBase}/sync/progress/up_next_nitro');
    return res as List<dynamic>? ?? [];
  }

  /// `GET /sync/playback/movies?extended=full,images` — all in-progress movies, paginated.
  Future<List<dynamic>> getPlaybackMovies({int limit = 100}) =>
      _fetchAllPages('/sync/playback/movies?extended=full,images', limit: limit);

  /// `GET /sync/playback/episodes?extended=full,images` — all in-progress episodes, paginated.
  Future<List<dynamic>> getPlaybackEpisodes({int limit = 100}) =>
      _fetchAllPages('/sync/playback/episodes?extended=full,images', limit: limit);

  /// `GET /sync/last_activities` — timestamps of the most recent watched/paused
  /// events. Used to decide whether a full re-sync is necessary.
  Future<Map<String, dynamic>> getLastActivities() async {
    final res = await _request('GET', '/sync/last_activities');
    return res as Map<String, dynamic>? ?? {};
  }

  /// `GET /shows/{id}/progress/watched` — detailed season/episode breakdown for
  /// a specific show. Called lazily when a show detail screen is opened.
  Future<Map<String, dynamic>> getShowWatchedProgress(int traktId) async {
    final res = await _request('GET', '/shows/$traktId/progress/watched');
    return res as Map<String, dynamic>? ?? {};
  }

  /// `GET /sync/watchlist/{type}` — user's watchlist (movies or shows).
  Future<List<dynamic>> getWatchlist({String type = 'shows'}) async {
    final res = await _request('GET', '/sync/watchlist/$type');
    return res as List<dynamic>? ?? [];
  }

  /// `GET /sync/ratings/{type}` — user's ratings with rating value and date.
  Future<List<dynamic>> getRatings({String type = 'shows'}) async {
    final res = await _request('GET', '/sync/ratings/$type');
    return res as List<dynamic>? ?? [];
  }

  /// `GET /sync/favorites/{type}` — user's favorites with optional notes.
  Future<List<dynamic>> getFavorites({String type = 'shows'}) async {
    final res = await _request('GET', '/sync/favorites/$type');
    return res as List<dynamic>? ?? [];
  }

  /// `GET /sync/collection/{type}` — user's collected items with metadata.
  Future<List<dynamic>> getCollection({String type = 'shows'}) async {
    final res = await _request('GET', '/sync/collection/$type');
    return res as List<dynamic>? ?? [];
  }

  /// Refresh the access token. Coalesces concurrent calls via [_refreshLock] so
  /// duplicate POSTs don't race when multiple in-flight requests hit 401.
  Future<TraktSession> refresh() => _refreshCoalescer.run(_doRefresh);

  Future<TraktSession> _doRefresh() async {
    appLogger.d('Trakt: refreshing access token');
    final tokenUri = Uri.parse(TraktConstants.tokenUrl);
    final res = await sendAbortableHttpRequest(
      _http,
      'POST',
      tokenUri,
      headers: TraktConstants.headers(),
      body: json.encode({
        'refresh_token': _session.refreshToken,
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
      return _session;
    }

    appLogger.w('Trakt: refresh failed (${res.statusCode}), session invalidated');
    onSessionInvalidated();
    throw TraktAuthException('Refresh failed: HTTP ${res.statusCode}');
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

  /// Fetches every page of a paginated Trakt list endpoint and returns the
  /// merged items. [path] must already contain query params (e.g.
  /// `?extended=full,images`) — `&page=N&limit=L` are appended per iteration.
  Future<List<dynamic>> _fetchAllPages(String path, {int limit = 100}) async {
    if (_session.needsRefresh) {
      try {
        await refresh();
      } catch (_) {}
    }

    final allItems = <dynamic>[];
    var page = 1;
    var totalPages = 1;

    do {
      final pagePath = '$path&page=$page&limit=$limit';
      var res = await _send('GET', pagePath);

      if (res.statusCode == 401) {
        await refresh();
        res = await _send('GET', pagePath);
      }
      if (res.statusCode == 429) {
        throw TraktRateLimitException(retryAfterSeconds: int.tryParse(res.headers['retry-after'] ?? ''));
      }
      if (res.statusCode != 200) {
        throw TraktApiException(statusCode: res.statusCode, body: res.body);
      }

      if (res.body.isNotEmpty) {
        try {
          final decoded = json.decode(res.body);
          if (decoded is List) allItems.addAll(decoded);
        } catch (_) {}
      }

      totalPages = int.tryParse(res.headers['x-pagination-page-count'] ?? '1') ?? 1;
      appLogger.d('Trakt paginated $path page=$page/$totalPages total=${allItems.length}');
      page++;
    } while (page <= totalPages);

    return allItems;
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
    final uri = path.startsWith('https://') ? Uri.parse(path) : Uri.parse('${TraktConstants.apiBase}$path');
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
  const TraktAuthException(this.message);
  @override
  String toString() => 'TraktAuthException: $message';
}
