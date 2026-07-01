import 'dart:async';

import 'package:http/http.dart' as http;

import '../../connection/connection.dart';
import '../../models/seerr/seerr_movie_details.dart';
import '../../models/seerr/seerr_page.dart';
import '../../models/seerr/seerr_request.dart';
import '../../models/seerr/seerr_search_result.dart';
import '../../models/seerr/seerr_service_instance.dart';
import '../../models/seerr/seerr_tv_details.dart';
import '../../models/seerr/seerr_user.dart';
import '../../utils/app_logger.dart';
import 'seerr_auth_service.dart';
import 'seerr_exceptions.dart';
import 'seerr_http_client.dart';

/// HTTP wrapper for the Seerr REST API, scoped to a single authenticated
/// [SeerrConnection].
///
/// On 401, silently re-authenticates via [SeerrAuthService.reauth] using the
/// connection's stored Jellyfin credentials, swaps the cookie, and retries
/// the call once. Concurrent re-auths coalesce so only one POST /auth/jellyfin
/// runs even when multiple in-flight requests trip 401 at the same time.
class SeerrClient {
  /// Coalesces concurrent reauth POSTs across all SeerrClient instances that
  /// share the same connection.id, mirroring TraktClient._refreshesByToken.
  static final Map<String, Future<SeerrConnection>> _reauthsByConnectionId = {};

  SeerrConnection _connection;
  final SeerrHttpClient _http;
  final SeerrAuthService _auth;

  /// Fired when re-auth fails permanently (bad password, server rejects the
  /// stored credentials). The provider clears local state and surfaces the
  /// login screen.
  final void Function() onSessionInvalidated;

  /// Fired when re-auth succeeds with a new cookie. The provider persists
  /// the updated connection via ConnectionRegistry.
  final void Function(SeerrConnection connection)? onSessionUpdated;

  SeerrClient(
    SeerrConnection connection, {
    required this.onSessionInvalidated,
    this.onSessionUpdated,
    SeerrAuthService? authService,
    http.Client? httpClient,
  }) : _connection = connection,
       _http = SeerrHttpClient(
         baseUrl: connection.baseUrl,
         httpClient: httpClient,
         initialSessionCookie: connection.sessionCookie,
       ),
       _auth = authService ?? SeerrAuthService();

  SeerrConnection get connection => _connection;

  /// Replace the in-memory connection (e.g. after the provider received a
  /// session update through another code path). The HTTP cookie is synced
  /// to match.
  void updateConnection(SeerrConnection connection) {
    _connection = connection;
    _http.setSessionCookieValue(connection.sessionCookie);
  }

  void dispose() => _http.dispose();

  // ---------- Auth ----------

  Future<SeerrUser> getMe() async {
    final res = await _request('GET', '/auth/me');
    return SeerrUser.fromJson(res as Map<String, dynamic>);
  }

  // ---------- Search ----------

  /// Search Seerr's TMDB-backed catalog. Returns a paginated list of mixed
  /// movie/tv/person results.
  Future<SeerrPage<SeerrSearchResult>> search(String query, {int page = 1}) async {
    final raw = await _request('GET', '/search', query: {'query': query, 'page': page});
    return SeerrPage<SeerrSearchResult>.fromJson(
      raw as Map<String, dynamic>,
      (item) => SeerrSearchResult.fromJson(item),
    );
  }

  // ---------- Discover ----------

  Future<SeerrPage<SeerrSearchResult>> discoverMovies({int page = 1}) async {
    final raw = await _request('GET', '/discover/movies', query: {'page': page});
    return SeerrPage<SeerrSearchResult>.fromJson(
      raw as Map<String, dynamic>,
      (item) {
        // /discover/movies items lack mediaType — coerce to movie.
        final coerced = Map<String, dynamic>.from(item)..putIfAbsent('mediaType', () => 'movie');
        return SeerrSearchResult.fromJson(coerced);
      },
    );
  }

  Future<SeerrPage<SeerrSearchResult>> discoverTv({int page = 1}) async {
    final raw = await _request('GET', '/discover/tv', query: {'page': page});
    return SeerrPage<SeerrSearchResult>.fromJson(
      raw as Map<String, dynamic>,
      (item) {
        final coerced = Map<String, dynamic>.from(item)..putIfAbsent('mediaType', () => 'tv');
        return SeerrSearchResult.fromJson(coerced);
      },
    );
  }

  /// Mixed trending — movies, tv, person.
  Future<SeerrPage<SeerrSearchResult>> discoverTrending({int page = 1}) async {
    final raw = await _request('GET', '/discover/trending', query: {'page': page});
    return SeerrPage<SeerrSearchResult>.fromJson(
      raw as Map<String, dynamic>,
      (item) => SeerrSearchResult.fromJson(item),
    );
  }

  // ---------- Movie / TV details ----------

  Future<SeerrMovieDetails> getMovie(int tmdbId) async {
    final raw = await _request('GET', '/movie/$tmdbId');
    return SeerrMovieDetails.fromJson(raw as Map<String, dynamic>);
  }

  Future<SeerrTvDetails> getTv(int tmdbId) async {
    final raw = await _request('GET', '/tv/$tmdbId');
    return SeerrTvDetails.fromJson(raw as Map<String, dynamic>);
  }

  /// "More like this" — Seerr's TMDB-backed recommendations for a movie or
  /// TV show. Falls back to /similar when /recommendations returns empty
  /// (TMDB's recommendations are curated and don't exist for every title).
  Future<SeerrPage<SeerrSearchResult>> getMovieRecommendations(int tmdbId, {int page = 1}) async {
    final raw = await _request('GET', '/movie/$tmdbId/recommendations', query: {'page': page});
    return SeerrPage<SeerrSearchResult>.fromJson(
      raw as Map<String, dynamic>,
      (item) {
        final coerced = Map<String, dynamic>.from(item)..putIfAbsent('mediaType', () => 'movie');
        return SeerrSearchResult.fromJson(coerced);
      },
    );
  }

  Future<SeerrPage<SeerrSearchResult>> getTvRecommendations(int tmdbId, {int page = 1}) async {
    final raw = await _request('GET', '/tv/$tmdbId/recommendations', query: {'page': page});
    return SeerrPage<SeerrSearchResult>.fromJson(
      raw as Map<String, dynamic>,
      (item) {
        final coerced = Map<String, dynamic>.from(item)..putIfAbsent('mediaType', () => 'tv');
        return SeerrSearchResult.fromJson(coerced);
      },
    );
  }

  // ---------- Requests ----------

  /// Submit a new request. Returns the created MediaRequest.
  Future<SeerrRequest> createRequest(SeerrRequestPayload payload) async {
    final raw = await _request('POST', '/request', body: payload.toJson());
    return SeerrRequest.fromJson(raw as Map<String, dynamic>);
  }

  /// Paginated list of all requests visible to the authenticated user.
  /// [filter] is one of `all`, `pending`, `approved`, `available`,
  /// `processing`, `unavailable`. [sort] is `added` or `modified`.
  Future<SeerrPage<SeerrRequest>> getRequests({int page = 1, String? filter, String? sort}) async {
    final raw = await _request('GET', '/request', query: {
      'take': 20,
      'skip': (page - 1) * 20,
      if (filter != null) 'filter': filter,
      if (sort != null) 'sort': sort,
    });
    return SeerrPage<SeerrRequest>.fromJson(
      raw as Map<String, dynamic>,
      (item) => SeerrRequest.fromJson(item),
    );
  }

  Future<void> deleteRequest(int id) async {
    await _request('DELETE', '/request/$id');
  }

  // ---------- Service config (Sonarr / Radarr) ----------

  /// Lightweight per-session cache: profile lists rarely change and a single
  /// request sheet open shouldn't refetch them. Keyed by `"sonarr:$id"` etc.
  final Map<String, SeerrServiceDetail> _serviceDetailCache = {};
  List<SeerrServiceInstance>? _sonarrServicesCache;
  List<SeerrServiceInstance>? _radarrServicesCache;

  /// All configured Sonarr instances (one row per server, with which is
  /// 4K-flagged + which is the default).
  Future<List<SeerrServiceInstance>> getSonarrServices() async {
    final cached = _sonarrServicesCache;
    if (cached != null) return cached;
    final raw = await _request('GET', '/service/sonarr');
    final list = _parseServiceList(raw);
    _sonarrServicesCache = list;
    return list;
  }

  Future<List<SeerrServiceInstance>> getRadarrServices() async {
    final cached = _radarrServicesCache;
    if (cached != null) return cached;
    final raw = await _request('GET', '/service/radarr');
    final list = _parseServiceList(raw);
    _radarrServicesCache = list;
    return list;
  }

  /// Full detail for one Sonarr/Radarr instance including profiles + root
  /// folders + language profiles. Cached for the lifetime of the client so
  /// reopening the request sheet doesn't re-fetch.
  Future<SeerrServiceDetail> getSonarrService(int sonarrId) async {
    final key = 'sonarr:$sonarrId';
    final cached = _serviceDetailCache[key];
    if (cached != null) return cached;
    final raw = await _request('GET', '/service/sonarr/$sonarrId');
    final detail = SeerrServiceDetail.fromJson(raw as Map<String, dynamic>);
    _serviceDetailCache[key] = detail;
    return detail;
  }

  Future<SeerrServiceDetail> getRadarrService(int radarrId) async {
    final key = 'radarr:$radarrId';
    final cached = _serviceDetailCache[key];
    if (cached != null) return cached;
    final raw = await _request('GET', '/service/radarr/$radarrId');
    final detail = SeerrServiceDetail.fromJson(raw as Map<String, dynamic>);
    _serviceDetailCache[key] = detail;
    return detail;
  }

  List<SeerrServiceInstance> _parseServiceList(dynamic raw) {
    if (raw is! List) return const [];
    final out = <SeerrServiceInstance>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) out.add(SeerrServiceInstance.fromJson(item));
    }
    return out;
  }

  // ---------- Internals ----------

  /// Issue an authenticated request; on 401 trigger reauth-and-retry once.
  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    var res = await _http.sendJson(method, path, query: query, body: body);
    if (res.response.statusCode == 401) {
      try {
        await _reauthCoalesced();
      } on SeerrAuthException {
        onSessionInvalidated();
        rethrow;
      }
      res = await _http.sendJson(method, path, query: query, body: body);
      if (res.response.statusCode == 401) {
        onSessionInvalidated();
        throw const SeerrAuthException('Re-auth succeeded but next request still 401', statusCode: 401);
      }
    }
    SeerrHttpClient.throwForStatus(res);
    return res.data;
  }

  /// Coalesce concurrent reauth attempts so only one POST /auth/jellyfin
  /// fires per connection regardless of how many in-flight 401s hit at once.
  Future<SeerrConnection> _reauthCoalesced() async {
    final id = _connection.id;
    final existing = _reauthsByConnectionId[id];
    if (existing != null) {
      final next = await existing;
      if (next.sessionCookie != _connection.sessionCookie) {
        updateConnection(next);
        onSessionUpdated?.call(next);
      }
      return next;
    }
    late final Future<SeerrConnection> reauth;
    reauth = _doReauth().whenComplete(() {
      if (identical(_reauthsByConnectionId[id], reauth)) {
        _reauthsByConnectionId.remove(id);
      }
    });
    _reauthsByConnectionId[id] = reauth;
    return reauth;
  }

  Future<SeerrConnection> _doReauth() async {
    appLogger.d('Seerr: silently re-authenticating');
    final updated = await _auth.reauth(_connection);
    updateConnection(updated);
    onSessionUpdated?.call(updated);
    return updated;
  }
}
