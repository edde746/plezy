import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../i18n/strings.g.dart';
import '../../utils/abortable_http_request.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;
import '../../utils/url_utils.dart';
import '../trackers/tracker_http_client.dart';
import 'seerr_constants.dart';
import 'seerr_exceptions.dart';

/// HTTP response paired with its decoded JSON body. `data` is null for
/// no-content responses and non-JSON bodies.
class SeerrResponse {
  final http.Response response;
  final dynamic data;
  const SeerrResponse(this.response, this.data);

  int get statusCode => response.statusCode;
}

/// Verdict of [SeerrHttpClient.classify]: what a 3xx/401/403 answer under
/// the API path means, and whether Seerr is the one answering.
///
/// Seerr — Overseerr, Jellyseerr and Seerr share this code unchanged
/// (`server/middleware/auth.ts`, `server/routes/auth.ts`, `server/index.ts`)
/// — rejects in exactly two shapes, both JSON, and never redirects:
///
///   * `isAuthenticated` middleware, guarding every route except the login
///     flow and `/settings/public`: 403 `{"status":403,"error":"…"}`, for a
///     missing or expired session and for a permission miss alike.
///   * The error handler rendering a handler's `next({status, message})`:
///     `{"message":"…"}`. With 403 on a login route that is a credential
///     rejection (`Access denied.`, Quick Connect unavailable); on an
///     authenticated route it is an action denial (permission, quota or
///     blocklist), not a verdict about which permission is missing or session
///     expiry, which middleware catches first. `/auth/jellyfin` pairs it with 401:
///     Jellyfin's own status, forwarded with `INVALID_CREDENTIALS` as the
///     message. No route this client calls answers 401 otherwise.
///
/// Anything else carrying a 3xx/401/403 was not Seerr: an SSO redirect, an
/// HTTP Basic challenge, Cloudflare Access, Traefik/Authelia forward-auth,
/// an API gateway. Their JSON bodies (`{"error":"unauthorized"}`,
/// `{"success":false,"errors":[…]}`) prove Seerr answered no more than HTML
/// would, and the stored session may be perfectly valid behind the wall.
enum SeerrRejection {
  /// Success or an ordinary API failure, without authentication evidence.
  none,

  /// Seerr's middleware refused the cookie for this route: either it names
  /// no live session, or the user lacks the route's permission. Only
  /// `GET /auth/me`, which needs no permission bits, tells the two apart.
  session,

  /// A live route handler denied the action. Permission, quota and blocklist
  /// failures share this shape; refresh authority without retyping or replaying.
  routeDenied,

  /// Seerr's login handler refused the credentials offered.
  credentials,

  /// Something in front of Seerr answered. Never a reason to touch the
  /// stored session.
  intermediary,
}

/// Thin wrapper around `package:http` for Seerr API calls.
///
/// Adds the three things the tracker HTTP layer doesn't cover:
///   1. `connect.sid` cookie capture from `Set-Cookie` on login, replayed as
///      `Cookie:` on every subsequent request — Express session auth.
///   2. Query encoding via [encodeQueryParameters] (`%20` for spaces): Seerr
///      proxies `/search` to TMDB, which rejects `+` in the query value.
///   3. Failover across the instance's URLs (a LAN and a remote address) for
///      GETs: one that cannot reach the active URL moves on to the next and,
///      once that answers, reports the switch through [onEndpointSwitch].
///      Writes never fail over, as with the media-server clients.
class SeerrHttpClient {
  /// The instance's URLs in failover order, the initial [baseUrl] first.
  /// Every entry must name the same instance: the session cookie is replayed
  /// against whichever one answers.
  final List<String> _baseUrls;
  int _activeIndex = 0;
  final http.Client _http;
  String? _cookie;

  /// Fired with the URL a GET succeeded on after the previous one could not
  /// be reached, so the owner can persist the switch.
  final void Function(String baseUrl)? onEndpointSwitch;

  SeerrHttpClient({
    required String baseUrl,
    List<String> baseUrls = const [],
    http.Client? httpClient,
    String? cookie,
    this.onEndpointSwitch,
  }) : _baseUrls = List.unmodifiable({normalizeBaseUrl(baseUrl), ...baseUrls.map(normalizeBaseUrl)}),
       _http = httpClient ?? platform.createPlatformClient(),
       _cookie = (cookie?.isNotEmpty ?? false) ? cookie : null;

  /// The URL requests currently go to.
  String get baseUrl => _baseUrls[_activeIndex];

  /// Move to [value], one of the configured URLs; anything else is ignored.
  set baseUrl(String value) {
    final index = _baseUrls.indexOf(normalizeBaseUrl(value));
    if (index >= 0) _activeIndex = index;
  }

  /// Current `connect.sid` value (no `name=` prefix); null until a login
  /// response is captured or [cookie] was seeded.
  String? get cookie => _cookie;

  set cookie(String? value) => _cookie = (value?.isNotEmpty ?? false) ? value : null;

  void dispose() => _http.close();

  /// Parse `Set-Cookie` from [response] and keep the `connect.sid` value.
  /// Returns true when a cookie was captured.
  ///
  /// `package:http` joins multiple `Set-Cookie` headers into one
  /// comma-delimited string. Cookie values are URL-encoded and can't contain
  /// a literal comma, so splitting on `,` and scanning each chunk for the
  /// `connect.sid=` prefix is safe.
  bool captureSessionCookie(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return false;
    const prefix = '${SeerrConstants.sessionCookieName}=';
    for (final chunk in raw.split(',')) {
      final trimmed = chunk.trimLeft();
      if (!trimmed.startsWith(prefix)) continue;
      final afterName = trimmed.substring(prefix.length);
      final end = afterName.indexOf(';');
      final value = (end == -1 ? afterName : afterName.substring(0, end)).trim();
      if (value.isEmpty) continue;
      _cookie = value;
      return true;
    }
    return false;
  }

  /// Send a request under [SeerrConstants.apiPath], returning the decoded
  /// JSON body. No status throws here: the caller runs [classify] over the
  /// answer so a session rejection can feed its silent re-auth path.
  Future<SeerrResponse> send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Map<String, Object?>? body,
    Duration timeout = SeerrConstants.requestTimeout,
    bool authenticated = true,
  }) async {
    if (!const {'GET', 'POST', 'PUT', 'DELETE'}.contains(method)) {
      throw ArgumentError('Unsupported HTTP method: $method');
    }
    final headers = <String, String>{
      'Accept': 'application/json',
      if (authenticated && _cookie != null) 'Cookie': '${SeerrConstants.sessionCookieName}=$_cookie',
      if (body != null) 'Content-Type': 'application/json',
    };
    final sw = Stopwatch()..start();
    // Only a GET walks the URL list when the transport fails: a timed-out
    // write may already have committed server-side and must never be replayed.
    for (var attempt = 0; ; attempt++) {
      final index = _activeIndex;
      final http.Response response;
      try {
        // Abortable so a timeout releases transport resources. Redirects are
        // not followed: Seerr's API never issues one, so a 3xx is an auth
        // proxy in front of it, and following it would turn that into an
        // HTML 200 nobody can diagnose.
        response = await sendAbortableHttpRequest(
          _http,
          method,
          _uri(_baseUrls[index], path, query),
          headers: headers,
          body: body == null ? null : jsonEncode(body),
          timeout: timeout,
          operation: 'Seerr $method $path',
          followRedirects: false,
        );
      } catch (e) {
        if (method != 'GET' || attempt >= _baseUrls.length - 1) rethrow;
        // A concurrent request may have moved on already; never move it back.
        if (_activeIndex == index) {
          _activeIndex = (index + 1) % _baseUrls.length;
          appLogger.i(
            'Seerr $method $path could not reach the active instance URL, trying the next one',
            error: e.runtimeType,
          );
        }
        continue;
      }
      appLogger.d('Seerr $method $path -> ${response.statusCode} (${sw.elapsedMilliseconds}ms)');
      if (attempt > 0) onEndpointSwitch?.call(_baseUrls[index]);
      return SeerrResponse(response, TrackerHttpClient.decodeJson(response.body));
    }
  }

  Uri _uri(String baseUrl, String path, Map<String, Object?>? query) {
    final base = Uri.parse('$baseUrl${SeerrConstants.apiPath}$path');
    final encoded = encodeQueryParameters(query);
    return encoded.isEmpty ? base : base.replace(query: encoded);
  }

  /// Login-flow routes: unauthenticated, and rejected by Seerr's error
  /// handler (`{message}`) rather than by `isAuthenticated` middleware.
  static const _loginPaths = {
    '/auth/local',
    '/auth/plex',
    '/auth/jellyfin',
    '/auth/jellyfin/quickconnect/initiate',
    '/auth/jellyfin/quickconnect/check',
    '/auth/jellyfin/quickconnect/authenticate',
  };

  /// What [res] to [path] says about the caller's standing with Seerr — and
  /// whether Seerr is the one saying it. A JSON body alone proves nothing:
  /// only a status *and* body Seerr actually emits for this route counts,
  /// everything else with a 3xx/401/403 status is [SeerrRejection.intermediary].
  static SeerrRejection classify(SeerrResponse res, {required String path}) {
    final code = res.statusCode;
    if (code >= 300 && code < 400) return SeerrRejection.intermediary;
    if (code != 401 && code != 403) return SeerrRejection.none;
    final data = res.data;
    if (data is! Map<String, dynamic>) return SeerrRejection.intermediary;
    // Error handler: `{message: err.message, errors: err.errors}`, the
    // latter dropped when undefined.
    final handlerShape = data['message'] is String && _onlyKeys(data, const {'message', 'errors'});
    if (_loginPaths.contains(path)) {
      // Only /auth/jellyfin ever pairs it with 401 — Jellyfin's own status,
      // forwarded with the INVALID_CREDENTIALS code as the message.
      if (handlerShape && (code == 403 || path == '/auth/jellyfin' && data['message'] == 'INVALID_CREDENTIALS')) {
        return SeerrRejection.credentials;
      }
      return SeerrRejection.intermediary;
    }
    if (code != 403) return SeerrRejection.intermediary;
    // isAuthenticated middleware: always this exact body.
    if (data['status'] == 403 && data['error'] is String && _onlyKeys(data, const {'status', 'error'})) {
      return SeerrRejection.session;
    }
    // Handler permission, quota and blocklist failures are indistinguishable.
    return handlerShape ? SeerrRejection.routeDenied : SeerrRejection.intermediary;
  }

  static bool _onlyKeys(Map<String, dynamic> data, Set<String> allowed) => data.keys.every(allowed.contains);

  /// Throw [SeerrProxyException] when [classify] says something in front of
  /// Seerr answered; no-op otherwise.
  static void throwIfIntermediary(SeerrResponse res, {required String path}) {
    if (classify(res, path: path) != SeerrRejection.intermediary) return;
    throw SeerrProxyException(
      'An auth proxy answered instead of Seerr (HTTP ${res.statusCode})',
      display: t.seerr.behindAuthProxy,
      statusCode: res.statusCode,
    );
  }

  /// Throw the mapped exception for a 3xx/4xx/5xx response; no-op on success.
  /// Callers pick off the auth verdicts they care about via [classify] first;
  /// what reaches here is either the intermediary's, which throws
  /// [SeerrProxyException], or Seerr's own non-auth failure.
  static void throwForStatus(SeerrResponse res, {required String path}) {
    throwIfIntermediary(res, path: path);
    final code = res.statusCode;
    if (code >= 200 && code < 300) return;
    final data = res.data;
    // Route handlers reject through the error handler (`message`), the
    // permission middleware through its own body (`error`).
    final raw = data is Map<String, dynamic> ? data['message'] ?? data['error'] : null;
    throw SeerrApiException(raw is String && raw.isNotEmpty ? raw : 'HTTP $code', statusCode: code);
  }

  /// Trim whitespace and trailing slashes so cookie/session identity and
  /// request URLs agree on one canonical instance URL.
  static String normalizeBaseUrl(String input) {
    var v = input.trim();
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }
}
