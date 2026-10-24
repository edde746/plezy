import 'dart:async';

import 'package:clock/clock.dart';
import 'package:http/http.dart' as http;

import '../../../utils/app_logger.dart';
import '../../../utils/json_utils.dart';
import '../future_coalescer.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_exceptions.dart';
import '../tracker_http_client.dart';
import '../tracker_session.dart';
import 'mdblist_auth_service.dart';
import 'mdblist_constants.dart';

/// Batch and single-title responses use different native rating scales.
typedef MdblistMediaInfo = ({Map<String, dynamic> data, bool isBatch});

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
  final _mediaLoads = KeyedFutureCoalescer<String, MdblistMediaInfo?>();
  final _mediaCache = <String, ({MdblistMediaInfo info, bool related, DateTime at})>{};
  static const _mediaTtl = Duration(hours: 1);
  static const _mediaCapacity = 600;

  MdblistClient(
    TrackerSession session, {
    required this.onSessionInvalidated,
    this.onSessionUpdated,
    http.Client? httpClient,
    MdblistAuthService? authService,
  }) : _session = session,
       _http = TrackerHttpClient(logLabel: 'MDBList', httpClient: httpClient),
       _auth = authService ?? MdblistAuthService();

  TrackerSession get session => _session;

  @override
  void dispose() {
    _mediaCache.clear();
    _mediaLoads.clear();
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

  Future<Map<String, dynamic>> getWatchlist({int limit = 100, int offset = 0}) async {
    final res = await _request(
      'GET',
      '/watchlist/items',
      queryParameters: {
        'limit': '$limit',
        if (offset > 0) 'offset': '$offset',
        'append_to_response': 'genres,poster,description',
      },
    );
    return res is Map ? res.cast<String, dynamic>() : const {};
  }

  Future<Map<String, dynamic>> searchCatalog(String query, {int limit = 30}) async {
    final res = await _request('GET', '/search/any', queryParameters: {'query': query, 'limit': '$limit'});
    return res is Map ? res.cast<String, dynamic>() : const {};
  }

  Future<void> addToWatchlist(Map<String, dynamic> body) => _request('POST', '/watchlist/items/add', body: body);

  Future<void> removeFromWatchlist(Map<String, dynamic> body) =>
      _request('POST', '/watchlist/items/remove', body: body);

  /// The same metadata feeds search, details and community ratings. A batch
  /// answer never satisfies a detail request that also needs recommendations.
  Future<MdblistMediaInfo?> getMediaInfo(
    String provider,
    String mediaType,
    String id, {
    bool includeRecommendations = false,
  }) async {
    final key = '$provider/$mediaType/$id';
    final cached = _mediaCache.remove(key);
    if (cached != null && clock.now().difference(cached.at) < _mediaTtl) {
      _mediaCache[key] = cached;
      if (!includeRecommendations || cached.related) return cached.info;
    }
    return _mediaLoads.run('$key/$includeRecommendations', () async {
      try {
        final res = await _request(
          'GET',
          '/$provider/$mediaType/${Uri.encodeComponent(id)}',
          queryParameters: includeRecommendations ? {'append_to_response': 'recommendations'} : null,
        );
        if (res is! Map) throw const FormatException('Invalid MDBList media response');
        final info = (data: res.cast<String, dynamic>(), isBatch: false);
        _rememberMedia(info, includeRecommendations, requestedKey: key);
        return info;
      } on TrackerApiException catch (e) {
        if (e.statusCode == 404) return null;
        rethrow;
      }
    });
  }

  /// Read-only lookup despite its POST verb. The documented ceiling is 200
  /// IDs; missing IDs are omitted and the response is not in request order.
  Future<List<MdblistMediaInfo>> getMediaInfoBatch(String provider, String mediaType, List<Object> ids) async {
    if (ids.isEmpty || ids.length > 200) throw ArgumentError('Expected 1–200 MDBList lookup IDs');
    final cached = <MdblistMediaInfo>[];
    final missing = <Object>[];
    for (final id in ids.toSet()) {
      final key = '$provider/$mediaType/$id';
      final entry = _mediaCache.remove(key);
      if (entry != null && clock.now().difference(entry.at) < _mediaTtl) {
        _mediaCache[key] = entry;
        cached.add(entry.info);
      } else {
        missing.add(id);
      }
    }
    if (missing.isEmpty) return cached;
    final res = await _request('POST', '/$provider/$mediaType/', body: {'ids': missing});
    if (res is! List) throw const FormatException('Invalid MDBList batch response');
    return [...cached, for (final data in flexibleMapList(res)) _rememberMedia((data: data, isBatch: true), false)];
  }

  MdblistMediaInfo _rememberMedia(MdblistMediaInfo info, bool related, {String? requestedKey}) {
    final type = info.data['type'];
    final ids = info.data['ids'];
    final keys = <String>[
      ?requestedKey,
      if ((type == 'movie' || type == 'show') && ids is Map)
        for (final provider in ['imdb', 'tmdb', 'trakt', if (type == 'show') 'tvdb'])
          if (ids[provider] != null) '$provider/$type/${ids[provider]}',
    ];
    for (final key in keys) {
      final previous = _mediaCache.remove(key);
      // A later search must not downgrade already loaded full detail data.
      _mediaCache[key] =
          previous != null && previous.related && !related && clock.now().difference(previous.at) < _mediaTtl
          ? previous
          : (info: info, related: related, at: clock.now());
    }
    while (_mediaCache.length > _mediaCapacity) {
      _mediaCache.remove(_mediaCache.keys.first);
    }
    return info;
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
    Map<String, String>? queryParameters,
    Set<int> allowStatuses = _defaultAllowedStatuses,
  }) async {
    if (_session.needsRefresh) {
      try {
        await _refresh();
      } catch (_) {
        // Fall through; the request will hit 401 naturally and retry.
      }
    }

    var res = await _send(method, path, body: body, queryParameters: queryParameters);

    if (res.statusCode == 401) {
      // A failed refresh propagates its TrackerAuthException, matching Trakt.
      await _refresh();
      res = await _send(method, path, body: body, queryParameters: queryParameters);
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

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) {
    final uri = Uri.parse('${MdblistConstants.apiBase}$path').replace(queryParameters: queryParameters);
    return _http.sendJson(
      method,
      uri,
      headers: MdblistConstants.headers(accessToken: _session.accessToken),
      body: body,
      allowedMethods: const {'GET', 'POST'},
    );
  }
}
