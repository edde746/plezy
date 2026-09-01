import 'dart:async';

import 'package:http/http.dart' as http;

import '../../i18n/app_locale_utils.dart';
import '../../i18n/strings.g.dart';

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
/// When the instance no longer knows the session (see [_isSessionRejection])
/// it re-logins silently via [SeerrAuthService.reauth] (password methods use
/// the stored secret; plex uses [plexTokenSupplier]), swaps the cookie, and
/// retries once. Concurrent re-auths coalesce per instance+user so a burst of
/// in-flight rejections triggers a single login POST.
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

  /// Re-read the signed-in user and adopt a changed permission mask or
  /// display name.
  ///
  /// The session stores both as a sign-in-time snapshot. An admin granting
  /// request rights later, or a session persisted by a build that read the
  /// partial `/auth/local` body as permission-less (#2213), only reaches the
  /// Request action once the snapshot is refreshed — and a silent re-auth,
  /// the only other refresh, never runs while the cookie is still accepted.
  Future<void> refreshUser() async {
    final user = await getMe();
    final displayName = user.displayName ?? _session.displayName;
    if (user.permissions == _session.permissions && displayName == _session.displayName) return;
    _adopt(_session.copyWith(permissions: user.permissions, displayName: displayName));
  }

  SeerrPublicSettings? _publicSettingsCache;

  /// Instance flags the request sheet gates on (4K enablement, partial
  /// requests). Cached for the client's lifetime — admins change these
  /// rarely and a new client is built per session rebind anyway.
  Future<SeerrPublicSettings> getPublicSettings() async {
    if (_publicSettingsCache case final SeerrPublicSettings cached) return cached;
    final data = await _request('GET', '/settings/public');
    final settings = SeerrPublicSettings.fromJson(data as Map<String, dynamic>);
    _publicSettingsCache = settings;
    // Every settings fetch re-derives the product discriminator (MediaStatus
    // codes 6/7 decode per product) so legacy sessions persisted before the
    // flag existed, and sessions whose instance changed product, converge.
    if (settings.product != _session.product) _adopt(_session.copyWith(product: settings.product));
    return settings;
  }

  // ---------- Discover / search ----------

  /// `/discover/movies` — popular movies.
  ///
  /// Deliberately unlocalized. Overseerr and Jellyseerr bind this route's
  /// `language` query parameter to `originalLanguage`, i.e. TMDB's
  /// `with_original_language`, so sending the app locale narrows the shelf to
  /// titles *originally made* in that language (#1763). The display language
  /// here comes from the instance/user locale, which already wins over the
  /// query value, so omitting it costs nothing.
  Future<SeerrPage<SeerrMedia>> getPopularMovies({int page = 1}) =>
      _mediaPage('/discover/movies', page, 'movie', localized: false);

  /// `/discover/tv` — popular series. Unlocalized for the same reason as
  /// [getPopularMovies].
  Future<SeerrPage<SeerrMedia>> getPopularTv({int page = 1}) =>
      _mediaPage('/discover/tv', page, 'tv', localized: false);

  Future<SeerrPage<SeerrMedia>> getUpcomingMovies({int page = 1}) =>
      _mediaPage('/discover/movies/upcoming', page, 'movie');

  Future<SeerrPage<SeerrMedia>> getUpcomingTv({int page = 1}) => _mediaPage('/discover/tv/upcoming', page, 'tv');

  /// `/discover/trending` — mixed movies/TV/people; person entries are
  /// dropped.
  Future<SeerrPage<SeerrMedia>> getTrending({int page = 1}) => _mediaPage('/discover/trending', page, null);

  /// `/search` — Seerr's TMDB-backed catalog search (mixed results, person
  /// entries dropped).
  Future<SeerrPage<SeerrMedia>> search(String query, {int page = 1}) async {
    final data = await _request('GET', '/search', query: {'query': query, 'page': page, 'language': _language});
    return _parseMediaPage(data, null);
  }

  /// TMDB "more like this" for a title; items lack `mediaType` like the
  /// single-type discover endpoints.
  Future<SeerrPage<SeerrMedia>> getMovieRecommendations(int tmdbId, {int page = 1}) =>
      _mediaPage('/movie/$tmdbId/recommendations', page, 'movie');

  Future<SeerrPage<SeerrMedia>> getTvRecommendations(int tmdbId, {int page = 1}) =>
      _mediaPage('/tv/$tmdbId/recommendations', page, 'tv');

  /// [localized] adds the app locale as `language`. Only the two paged
  /// discover routes opt out; everywhere else Seerr treats it as the display
  /// language, which is what we want.
  Future<SeerrPage<SeerrMedia>> _mediaPage(
    String path,
    int page,
    String? coerceMediaType, {
    bool localized = true,
  }) async {
    final data = await _request('GET', path, query: {'page': page, if (localized) 'language': _language});
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

  Future<SeerrDetails> getMovie(int tmdbId) => _details('/movie/$tmdbId');

  Future<SeerrDetails> getTv(int tmdbId) => _details('/tv/$tmdbId');

  Future<SeerrDetails> _details(String path) async {
    final data = await _request('GET', path, query: {'language': _language});
    return SeerrDetails.fromJson(data as Map<String, dynamic>);
  }

  // ---------- Requests ----------

  Future<SeerrRequest> createRequest(SeerrRequestPayload payload) async {
    final data = await _request('POST', '/request', body: payload.toJson());
    return SeerrRequest.fromJson(data as Map<String, dynamic>);
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
  String get _language => LocaleSettings.currentLocale.plexLanguageCode;

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, Object?>? query,
    Map<String, Object?>? body,
  }) async {
    var res = await _http.send(method, path, query: query, body: body);
    if (await _isSessionRejection(res, path)) {
      try {
        await _reauthCoalesced();
      } on SeerrAuthException {
        onSessionInvalidated();
        rethrow;
      }
      res = await _http.send(method, path, query: query, body: body);
      if (res.statusCode == 401) {
        onSessionInvalidated();
        throw SeerrAuthException(
          'Session rejected after successful re-auth',
          statusCode: 401,
          display: t.seerr.sessionRejectedAfterReauth,
        );
      }
    }
    SeerrHttpClient.throwForStatus(res);
    return res.data;
  }

  /// Whether [res] means the instance no longer knows the session.
  ///
  /// Seerr answers a missing or expired session with 403, never 401 — the
  /// same status and body its permission checks produce — so a 403 only
  /// counts as expiry once `GET /auth/me` (authenticated, no permission bits)
  /// rejects the cookie too. Re-authing on every 403 would instead unlink a
  /// Quick Connect session, which has no re-auth credentials, over a plain
  /// permission denial. A 401 never comes from Seerr itself (a proxy in front
  /// of it can send one) and is taken at face value.
  Future<bool> _isSessionRejection(SeerrResponse res, String path) async {
    if (res.statusCode == 401) return true;
    if (res.statusCode != 403) return false;
    if (path == '/auth/me') return true;
    final me = await _http.send('GET', '/auth/me');
    return me.statusCode == 401 || me.statusCode == 403;
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

  /// Adopt a refreshed session, merging the product discriminator instead of
  /// wholesale-replacing it: a re-auth completes from the snapshot taken when
  /// it started, so a concurrent [getPublicSettings] adoption would otherwise
  /// be overwritten — and the settings cache means it would never be
  /// reapplied. Cached settings are authoritative; failing that, a known
  /// product never downgrades to unknown.
  void _adopt(SeerrSession next) {
    final product = _publicSettingsCache?.product ?? _session.product;
    final merged = product == SeerrProduct.unknown || product == next.product ? next : next.copyWith(product: product);
    updateSession(merged);
    onSessionUpdated?.call(merged);
  }
}
