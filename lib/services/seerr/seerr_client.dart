import 'dart:async';

import 'package:http/http.dart' as http;

import '../../models/seerr/seerr_details.dart';
import '../../models/seerr/seerr_media.dart';
import '../../models/seerr/seerr_page.dart';
import '../../models/seerr/seerr_public_settings.dart';
import '../../models/seerr/seerr_request.dart';
import '../../models/seerr/seerr_service.dart';
import '../../models/seerr/seerr_session.dart';
import '../../models/seerr/seerr_user.dart';
import '../../utils/app_logger.dart';
import '../trackers/future_coalescer.dart';
import 'seerr_auth_service.dart';
import 'seerr_constants.dart';
import 'seerr_exceptions.dart';
import 'seerr_http_client.dart';

/// Supplies the profile's current Plex account token at silent-re-auth time,
/// so plex-method sessions never store a token copy that could go stale.
typedef SeerrPlexTokenSupplier = Future<String?> Function();

/// Authenticated Seerr API client, scoped to one [SeerrSession].
///
/// On 401 it re-logins silently via [SeerrAuthService.reauth] (password
/// methods use the stored secret; plex uses [plexTokenSupplier]), swaps the
/// cookie, and retries once. Concurrent re-auths coalesce per instance+user
/// so a burst of in-flight 401s triggers a single login POST — the same
/// shape as `TraktClient._refreshesByToken`.
class SeerrClient {
  static final KeyedFutureCoalescer<String, SeerrSession> _reauthsByIdentity = KeyedFutureCoalescer();

  SeerrSession _session;
  final SeerrHttpClient _http;
  final SeerrAuthService _auth;
  final SeerrPlexTokenSupplier? plexTokenSupplier;

  /// Fired when re-auth fails permanently (rejected credentials, no stored
  /// secret). The owning provider clears local state.
  final void Function() onSessionInvalidated;

  /// Fired when re-auth succeeds with a fresh cookie so the owner persists it.
  final void Function(SeerrSession session)? onSessionUpdated;

  SeerrClient(
    SeerrSession session, {
    required this.onSessionInvalidated,
    this.onSessionUpdated,
    this.plexTokenSupplier,
    SeerrAuthService? authService,
    http.Client? httpClient,
  }) : _session = session,
       _http = SeerrHttpClient(baseUrl: session.baseUrl, httpClient: httpClient, cookie: session.cookie),
       _auth = authService ?? SeerrAuthService();

  SeerrSession get session => _session;

  void updateSession(SeerrSession session) {
    _session = session;
    _http.cookie = session.cookie;
  }

  void dispose() => _http.dispose();

  // ---------- Auth ----------

  Future<SeerrUser> getMe() async {
    final data = await _request('GET', '/auth/me');
    return SeerrUser.fromJson(data as Map<String, dynamic>);
  }

  SeerrPublicSettings? _publicSettingsCache;

  /// Instance flags the request sheet gates on (4K enablement, partial
  /// requests). Cached for the client's lifetime — admins change these
  /// rarely and a new client is built per session rebind anyway.
  Future<SeerrPublicSettings> getPublicSettings() async {
    if (_publicSettingsCache case final SeerrPublicSettings cached) return cached;
    final data = await _request('GET', '/settings/public');
    return _publicSettingsCache = SeerrPublicSettings.fromJson(data as Map<String, dynamic>);
  }

  // ---------- Discover / search ----------

  /// `/discover/movies` — popular movies.
  Future<SeerrPage<SeerrMedia>> getPopularMovies({int page = 1}) => _mediaPage('/discover/movies', page, 'movie');

  /// `/discover/tv` — popular series.
  Future<SeerrPage<SeerrMedia>> getPopularTv({int page = 1}) => _mediaPage('/discover/tv', page, 'tv');

  Future<SeerrPage<SeerrMedia>> getUpcomingMovies({int page = 1}) =>
      _mediaPage('/discover/movies/upcoming', page, 'movie');

  Future<SeerrPage<SeerrMedia>> getUpcomingTv({int page = 1}) => _mediaPage('/discover/tv/upcoming', page, 'tv');

  /// `/discover/trending` — mixed movies/TV/people; person entries are
  /// dropped.
  Future<SeerrPage<SeerrMedia>> getTrending({int page = 1}) => _mediaPage('/discover/trending', page, null);

  /// `/search` — Seerr's TMDB-backed catalog search (mixed results, person
  /// entries dropped).
  Future<SeerrPage<SeerrMedia>> search(String query, {int page = 1}) async {
    final data = await _request('GET', '/search', query: {'query': query, 'page': page});
    return _parseMediaPage(data, null);
  }

  /// TMDB "more like this" for a title; items lack `mediaType` like the
  /// single-type discover endpoints.
  Future<SeerrPage<SeerrMedia>> getMovieRecommendations(int tmdbId, {int page = 1}) =>
      _mediaPage('/movie/$tmdbId/recommendations', page, 'movie');

  Future<SeerrPage<SeerrMedia>> getTvRecommendations(int tmdbId, {int page = 1}) =>
      _mediaPage('/tv/$tmdbId/recommendations', page, 'tv');

  Future<SeerrPage<SeerrMedia>> _mediaPage(String path, int page, String? coerceMediaType) async {
    final data = await _request('GET', path, query: {'page': page});
    return _parseMediaPage(data, coerceMediaType);
  }

  SeerrPage<SeerrMedia> _parseMediaPage(dynamic data, String? coerceMediaType) {
    return SeerrPage<SeerrMedia>.fromJson(data as Map<String, dynamic>, (item) {
      final mediaType = item['mediaType'] as String? ?? coerceMediaType;
      if (mediaType != 'movie' && mediaType != 'tv') return null;
      return SeerrMedia.fromJson({...item, 'mediaType': mediaType});
    });
  }

  // ---------- Details ----------

  Future<SeerrMovieDetails> getMovie(int tmdbId) async {
    final data = await _request('GET', '/movie/$tmdbId');
    return SeerrMovieDetails.fromJson(data as Map<String, dynamic>);
  }

  Future<SeerrTvDetails> getTv(int tmdbId) async {
    final data = await _request('GET', '/tv/$tmdbId');
    return SeerrTvDetails.fromJson(data as Map<String, dynamic>);
  }

  // ---------- Requests ----------

  Future<SeerrRequest> createRequest(SeerrRequestPayload payload) async {
    final data = await _request('POST', '/request', body: payload.toJson());
    return SeerrRequest.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteRequest(int requestId) async {
    await _request('DELETE', '/request/$requestId');
  }

  // ---------- Sonarr / Radarr options (request sheet advanced pickers) ----------

  Future<List<SeerrServiceInstance>> getRadarrServices() => _serviceList('/service/radarr');

  Future<List<SeerrServiceInstance>> getSonarrServices() => _serviceList('/service/sonarr');

  Future<SeerrServiceDetail> getRadarrService(int id) => _serviceDetail('/service/radarr/$id');

  Future<SeerrServiceDetail> getSonarrService(int id) => _serviceDetail('/service/sonarr/$id');

  Future<List<SeerrServiceInstance>> _serviceList(String path) async {
    final data = await _request('GET', path);
    return [
      if (data is List)
        for (final item in data)
          if (item is Map<String, dynamic>) SeerrServiceInstance.fromJson(item),
    ];
  }

  Future<SeerrServiceDetail> _serviceDetail(String path) async {
    final data = await _request('GET', path);
    return SeerrServiceDetail.fromJson(data as Map<String, dynamic>);
  }

  // ---------- Internals ----------

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, Object?>? query,
    Map<String, Object?>? body,
  }) async {
    var res = await _http.send(method, path, query: query, body: body);
    if (res.statusCode == 401) {
      try {
        await _reauthCoalesced();
      } on SeerrAuthException {
        onSessionInvalidated();
        rethrow;
      }
      res = await _http.send(method, path, query: query, body: body);
      if (res.statusCode == 401) {
        onSessionInvalidated();
        throw const SeerrAuthException('Session rejected after successful re-auth', statusCode: 401);
      }
    }
    SeerrHttpClient.throwForStatus(res);
    return res.data;
  }

  Future<void> _reauthCoalesced() async {
    final identity = '${_session.baseUrl}#${_session.userId}';
    final next = await _reauthsByIdentity.run(identity, _doReauth);
    // No-op for the initiating client (_doReauth adopted already); joiners
    // sharing the identity pick up the fresh cookie here.
    if (next.cookie != _session.cookie) _adopt(next);
  }

  Future<SeerrSession> _doReauth() async {
    appLogger.d('Seerr: session expired, re-authenticating silently');
    // The supplier reaches into profile/registry state with no timeout of
    // its own; unbounded, a hang here would park the coalesced future in
    // _reauthsByIdentity forever and wedge every future re-auth for this
    // identity. A null token maps to a retryable SeerrReauthUnavailable.
    final plexToken = _session.method == SeerrAuthMethod.plex
        ? await _resolvePlexToken().timeout(SeerrConstants.authTimeout, onTimeout: () => null)
        : null;
    final next = await _auth.reauth(_session, plexToken: plexToken);
    _adopt(next);
    return next;
  }

  /// Owns the `Future<String?>` type: calling `.timeout(onTimeout: () =>
  /// null)` directly on the supplier's future trips the covariant-generics
  /// runtime check when a caller hands us a `Future<String> Function()`.
  Future<String?> _resolvePlexToken() async => plexTokenSupplier == null ? null : await plexTokenSupplier!();

  void _adopt(SeerrSession next) {
    updateSession(next);
    onSessionUpdated?.call(next);
  }
}
