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
/// Adds the two things the tracker HTTP layer doesn't cover:
///   1. `connect.sid` cookie capture from `Set-Cookie` on login, replayed as
///      `Cookie:` on every subsequent request — Express session auth.
///   2. Query encoding via [encodeQueryParameters] (`%20` for spaces): Seerr
///      proxies `/search` to TMDB, which rejects `+` in the query value.
class SeerrHttpClient {
  /// `Set-Cookie` attributes, which look like cookies but are not.
  static const Set<String> _cookieAttributes = {
    'path',
    'domain',
    'expires',
    'max-age',
    'secure',
    'httponly',
    'samesite',
    'priority',
    'partitioned',
  };

  final String baseUrl;
  final http.Client _http;

  /// Every cookie the instance has set, replayed on each request.
  ///
  /// A jar rather than the one session cookie: CSRF protection stores its
  /// *secret* in a second cookie (`_csrf`) and only publishes the matching
  /// token in `XSRF-TOKEN`. The server checks the two against each other, so
  /// sending back the token alone is refused exactly like sending nothing.
  final Map<String, String> _cookies = {};

  SeerrHttpClient({required String baseUrl, http.Client? httpClient, String? cookie})
    : baseUrl = normalizeBaseUrl(baseUrl),
      _http = httpClient ?? platform.createPlatformClient() {
    if (cookie != null && cookie.isNotEmpty) _cookies[SeerrConstants.sessionCookieName] = cookie;
  }

  /// Current `connect.sid` value (no `name=` prefix); null until a login
  /// response is captured or [cookie] was seeded.
  String? get cookie => _cookies[SeerrConstants.sessionCookieName];

  set cookie(String? value) {
    if (value == null || value.isEmpty) {
      _cookies.remove(SeerrConstants.sessionCookieName);
    } else {
      _cookies[SeerrConstants.sessionCookieName] = value;
    }
  }

  String? get _csrfToken => _cookies[SeerrConstants.csrfCookieName];

  void dispose() => _http.close();

  /// Stores every cookie in [response] and reports whether the session cookie
  /// was among them.
  ///
  /// `package:http` joins multiple `Set-Cookie` headers into one
  /// comma-delimited string. Cookie *values* cannot contain a literal comma,
  /// but an `Expires` attribute can, so a chunk may be the tail of a date —
  /// those carry no `name=value` pair, or an attribute name, and are skipped.
  bool captureCookies(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return false;

    var capturedSession = false;
    for (final chunk in raw.split(',')) {
      final pair = chunk.trimLeft().split(';').first.trim();
      final separator = pair.indexOf('=');
      if (separator <= 0) continue;
      final name = pair.substring(0, separator).trim();
      final value = pair.substring(separator + 1).trim();
      if (value.isEmpty || _cookieAttributes.contains(name.toLowerCase())) continue;
      _cookies[name] = value;
      if (name == SeerrConstants.sessionCookieName) capturedSession = true;
    }
    return capturedSession;
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
    bool retryOnCsrfFailure = true,
  }) async {
    if (!const {'GET', 'POST', 'PUT', 'DELETE'}.contains(method)) {
      throw ArgumentError('Unsupported HTTP method: $method');
    }
    final uri = _uri(path, query);
    final cookies = [
      for (final entry in _cookies.entries)
        // The session cookie is the one an unauthenticated call must not
        // carry; everything else — the CSRF secret above all — always goes.
        if (authenticated || entry.key != SeerrConstants.sessionCookieName) '${entry.key}=${entry.value}',
    ];
    final headers = <String, String>{
      'Accept': 'application/json',
      if (cookies.isNotEmpty) 'Cookie': cookies.join('; '),
      if (_csrfToken != null && method != 'GET') SeerrConstants.csrfHeaderName: _csrfToken!,
      if (body != null) 'Content-Type': 'application/json',
    };
    final sw = Stopwatch()..start();
    // Abortable so a timeout releases transport resources. A timed-out write
    // may already have committed server-side and must never be replayed.
    // Redirects are not followed: Seerr's
    // API never issues one, so a 3xx is an auth proxy in front of it, and
    // following it would turn that into an HTML 200 nobody can diagnose.
    final response = await sendAbortableHttpRequest(
      _http,
      method,
      uri,
      headers: headers,
      body: body == null ? null : jsonEncode(body),
      timeout: timeout,
      operation: 'Seerr $method $path',
      followRedirects: false,
    );
    appLogger.d('Seerr $method $path -> ${response.statusCode} (${sw.elapsedMilliseconds}ms)');
    captureCookies(response);
    final result = SeerrResponse(response, TrackerHttpClient.decodeJson(response.body));

    // An instance with CSRF protection on refuses every write that does not
    // echo its token, and the token only arrives with a response. A first
    // write therefore has nothing to send: fetch one and repeat, once.
    if (retryOnCsrfFailure && method != 'GET' && _isCsrfRejection(result)) {
      final refreshed = await _fetchCsrfToken(timeout: timeout);
      if (refreshed) {
        return send(
          method,
          path,
          query: query,
          body: body,
          timeout: timeout,
          authenticated: authenticated,
          retryOnCsrfFailure: false,
        );
      }
    }
    return result;
  }

  static bool _isCsrfRejection(SeerrResponse res) {
    if (res.statusCode != 403) return false;
    final data = res.data;
    final message = data is Map<String, dynamic> ? data['message']?.toString() : null;
    return (message ?? '').toLowerCase().contains('csrf');
  }

  /// Reads any endpoint that answers without a session, purely to collect the
  /// `XSRF-TOKEN` cookie it sets.
  Future<bool> _fetchCsrfToken({required Duration timeout}) async {
    try {
      await send('GET', '/settings/public', timeout: timeout, authenticated: false, retryOnCsrfFailure: false);
    } catch (error) {
      appLogger.d('Seerr: could not collect a CSRF token', error: error);
      return false;
    }
    return _csrfToken != null;
  }

  Uri _uri(String path, Map<String, Object?>? query) {
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
