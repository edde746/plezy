import 'dart:async';

import 'package:http/http.dart' as http;

import '../../i18n/strings.g.dart';
import '../../models/seerr/seerr_public_settings.dart';
import '../../models/seerr/seerr_session.dart';
import '../../models/seerr/seerr_user.dart';
import '../../utils/app_logger.dart';
import '../../utils/poll_with_backoff.dart';
import '../../utils/url_utils.dart';
import 'seerr_constants.dart';
import 'seerr_exceptions.dart';
import 'seerr_http_client.dart';

/// Result of `POST /auth/jellyfin/quickconnect/initiate`. The [code] is shown
/// to the user to approve inside Jellyfin; the [secret] drives the poll and
/// the final exchange.
class SeerrQuickConnectInitiation {
  final String code;
  final String secret;

  const SeerrQuickConnectInitiation({required this.code, required this.secret});
}

/// Sign-in flows against a Seerr instance. Every flow ends with a captured
/// `connect.sid` cookie and the Seerr-side [SeerrUser], packed into a
/// [SeerrSession].
class SeerrAuthService {
  /// Default Seerr install port, tried last for bare-host input.
  static const int defaultPort = 5055;

  static final RegExp _schemePattern = RegExp(r'^[A-Za-z][A-Za-z\d+.-]*://');

  final http.Client Function()? httpClientFactory;

  SeerrAuthService({this.httpClientFactory});

  SeerrHttpClient _client(String baseUrl, {String? cookie}) =>
      SeerrHttpClient(baseUrl: baseUrl, httpClient: httpClientFactory?.call(), cookie: cookie);

  /// Expand a user-typed instance URL into probe candidates, mirroring the
  /// MediaBrowser add-server rules: an explicit scheme is authoritative, a
  /// bare host tries https, plain http, and the Seerr default port, and a
  /// host with an explicit port tries both schemes. Guesses are for
  /// discovery only; only the winning candidate is persisted.
  static List<String> expandUrlCandidates(String input) {
    final trimmed = canonicalizeBaseUrl(input);
    if (trimmed.isEmpty) return const [];
    if (_schemePattern.hasMatch(trimmed)) return List.unmodifiable([trimmed]);

    final parsed = Uri.tryParse('http://$trimmed');
    if (parsed == null || parsed.host.isEmpty) return List.unmodifiable(['https://$trimmed']);

    final candidates = <String>[];
    void add(Uri uri) {
      final normalized = stripTrailingSlash(uri.replace(query: null, fragment: null).toString());
      if (normalized.isNotEmpty && !candidates.contains(normalized)) candidates.add(normalized);
    }

    add(parsed.replace(scheme: 'https'));
    add(parsed.replace(scheme: 'http'));
    if (!parsed.hasPort) add(parsed.replace(scheme: 'http', port: defaultPort));
    return List.unmodifiable(candidates);
  }

  /// Probe every [expandUrlCandidates] guess for [input] concurrently and
  /// return the first that answers as an initialized Seerr. When none does,
  /// rethrow the primary (first) candidate's failure — that is the URL the
  /// error message should name.
  Future<({String baseUrl, SeerrPublicSettings settings})> probeFirstReachable(String input) async {
    final candidates = expandUrlCandidates(input);
    if (candidates.isEmpty) {
      throw SeerrUrlException('No Seerr instance URL entered', display: t.addServer.required);
    }
    final completer = Completer<({String baseUrl, SeerrPublicSettings settings})>();
    final errors = List<Object?>.filled(candidates.length, null);
    var pending = candidates.length;
    for (final (i, candidate) in candidates.indexed) {
      unawaited(
        probe(candidate)
            .then((settings) {
              if (!completer.isCompleted) completer.complete((baseUrl: candidate, settings: settings));
            })
            .catchError((Object e) {
              errors[i] = e;
              pending -= 1;
              if (pending == 0 && !completer.isCompleted) {
                completer.completeError(errors.firstWhere((err) => err != null)!);
              }
            }),
      );
    }
    return completer.future;
  }

  /// Validate that [baseUrl] points at a running, initialized Seerr and
  /// collect the metadata the connect flow needs. Throws [SeerrUrlException]
  /// when unreachable or not set up.
  Future<SeerrPublicSettings> probe(String baseUrl) async {
    final client = _client(baseUrl);
    try {
      final SeerrResponse res;
      try {
        res = await client.send('GET', '/settings/public', timeout: SeerrConstants.probeTimeout, authenticated: false);
      } catch (e) {
        throw SeerrUrlException(
          'Could not reach $baseUrl: $e',
          display: t.seerr.couldNotReach(url: baseUrl, error: e),
        );
      }
      final data = res.data;
      if (res.statusCode >= 400 || data is! Map<String, dynamic>) {
        throw SeerrUrlException(
          'No Seerr instance at $baseUrl (HTTP ${res.statusCode})',
          display: t.seerr.noInstanceAtUrl(url: baseUrl, status: res.statusCode),
        );
      }
      final settings = SeerrPublicSettings.fromJson(data);
      if (!settings.initialized) {
        throw SeerrUrlException('Seerr instance has not completed first-run setup', display: t.seerr.notInitialized);
      }
      return settings;
    } finally {
      client.dispose();
    }
  }

  /// `POST /auth/plex` with a Plex account token.
  Future<SeerrSession> signInWithPlex({required String baseUrl, required String plexToken}) => _signIn(
    baseUrl: baseUrl,
    method: SeerrAuthMethod.plex,
    path: '/auth/plex',
    body: {'authToken': plexToken},
    identifier: '',
    secret: '',
  );

  /// `POST /auth/jellyfin` with Jellyfin or Emby credentials.
  Future<SeerrSession> signInWithJellyfin({
    required String baseUrl,
    required String username,
    required String password,
    bool emby = false,
  }) => _signIn(
    baseUrl: baseUrl,
    method: emby ? SeerrAuthMethod.emby : SeerrAuthMethod.jellyfin,
    path: '/auth/jellyfin',
    body: {
      'username': username,
      'password': password,
      'serverType': emby ? SeerrMediaServerType.emby : SeerrMediaServerType.jellyfin,
    },
    identifier: username,
    secret: password,
  );

  /// `POST /auth/local` with a Seerr local account.
  Future<SeerrSession> signInWithLocal({required String baseUrl, required String email, required String password}) =>
      _signIn(
        baseUrl: baseUrl,
        method: SeerrAuthMethod.local,
        path: '/auth/local',
        body: {'email': email, 'password': password},
        identifier: email,
        secret: password,
      );

  /// `POST /auth/jellyfin/quickconnect/initiate` (Seerr 3.4+): start a
  /// Jellyfin Quick Connect session proxied through the instance. Throws
  /// [SeerrAuthException] when the route is missing (older Seerr) or the
  /// linked Jellyfin has Quick Connect disabled.
  Future<SeerrQuickConnectInitiation> initiateQuickConnect(String baseUrl) async {
    final client = _client(baseUrl);
    try {
      final res = await client.send(
        'POST',
        '/auth/jellyfin/quickconnect/initiate',
        timeout: SeerrConstants.authTimeout,
        authenticated: false,
      );
      final data = res.data;
      final message = data is Map<String, dynamic> ? data['message'] as String? : null;
      if (res.statusCode >= 400) {
        throw SeerrAuthException(
          message ?? 'Quick Connect rejected (HTTP ${res.statusCode})',
          statusCode: res.statusCode,
          display: t.addServer.quickConnectFailed(error: message ?? 'HTTP ${res.statusCode}'),
        );
      }
      final code = data is Map<String, dynamic> ? data['code'] : null;
      final secret = data is Map<String, dynamic> ? data['secret'] : null;
      if (code is! String || code.isEmpty || secret is! String || secret.isEmpty) {
        throw SeerrAuthException(
          'Quick Connect response is missing a code or secret',
          display: t.addServer.quickConnectMissingFields,
        );
      }
      return SeerrQuickConnectInitiation(code: code, secret: secret);
    } finally {
      client.dispose();
    }
  }

  /// Poll `GET /auth/jellyfin/quickconnect/check` until the user approves the
  /// code inside Jellyfin, then `POST …/authenticate` to mint the Seerr
  /// session. Returns null on cancel, poll timeout, or server-side secret
  /// expiry (404 mid-poll). Transient poll errors retry until [timeout].
  Future<SeerrSession?> signInWithQuickConnect({
    required String baseUrl,
    required String secret,
    bool Function()? shouldCancel,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    // One client across the loop — no TCP churn on a minutes-long window.
    final pollClient = _client(baseUrl);
    bool? approved;
    try {
      approved = await pollWithBackoff<bool>(
        endTime: DateTime.now().add(timeout),
        shouldCancel: shouldCancel,
        initial: SeerrConstants.quickConnectPollInterval,
        maxBackoff: SeerrConstants.quickConnectPollInterval,
        probe: () async {
          final SeerrResponse res;
          try {
            res = await pollClient.send(
              'GET',
              '/auth/jellyfin/quickconnect/check',
              query: {'secret': secret},
              timeout: SeerrConstants.authTimeout,
              authenticated: false,
            );
          } catch (e) {
            appLogger.d('Seerr: Quick Connect poll blip', error: e);
            return null;
          }
          // 404 mid-poll = secret expired or revoked server-side. Terminal.
          if (res.statusCode == 404) throw const PollTerminatedSignal();
          if (res.statusCode == 401 || res.statusCode == 403) {
            final message = res.data is Map<String, dynamic>
                ? (res.data as Map<String, dynamic>)['message'] as String?
                : null;
            throw SeerrAuthException(
              message ?? 'Quick Connect poll rejected',
              statusCode: res.statusCode,
              display: t.addServer.quickConnectPollRejected,
            );
          }
          SeerrHttpClient.throwForStatus(res);
          final data = res.data;
          return data is Map<String, dynamic> && data['authenticated'] == true ? true : null;
        },
      );
    } finally {
      pollClient.dispose();
    }
    if (approved != true) return null;

    return _signIn(
      baseUrl: baseUrl,
      method: SeerrAuthMethod.quickConnect,
      path: '/auth/jellyfin/quickconnect/authenticate',
      body: {'secret': secret},
      identifier: '',
      secret: '',
    );
  }

  /// Silent re-login using the credentials carried by [session]
  /// ([plexToken] for plex-method sessions). Returns the refreshed session.
  Future<SeerrSession> reauth(SeerrSession session, {String? plexToken}) async {
    final fresh = await switch (session.method) {
      SeerrAuthMethod.plex when plexToken != null && plexToken.isNotEmpty => signInWithPlex(
        baseUrl: session.baseUrl,
        plexToken: plexToken,
      ),
      // No token RIGHT NOW is a degraded state (identity not hydrated yet,
      // vault decrypt hiccup), not a server rejection — retryable, so it
      // must not unlink the session. An empty stored secret below is the
      // opposite: those credentials are gone for good, so re-linking is the
      // only way forward and unlinking is honest.
      SeerrAuthMethod.plex => throw SeerrReauthUnavailableException(
        'No Plex token available for silent re-auth',
        display: t.seerr.noPlexTokenForReauth,
      ),
      SeerrAuthMethod.jellyfin || SeerrAuthMethod.emby when session.secret.isNotEmpty => signInWithJellyfin(
        baseUrl: session.baseUrl,
        username: session.identifier,
        password: session.secret,
        emby: session.method == SeerrAuthMethod.emby,
      ),
      SeerrAuthMethod.local when session.secret.isNotEmpty => signInWithLocal(
        baseUrl: session.baseUrl,
        email: session.identifier,
        password: session.secret,
      ),
      _ => throw SeerrAuthException('No stored credentials for silent re-auth', display: t.seerr.noStoredCredentials),
    };
    return session.copyWith(cookie: fresh.cookie, permissions: fresh.permissions, displayName: fresh.displayName);
  }

  /// Best-effort server-side sign-out; local cleanup must not depend on it.
  Future<void> signOut(SeerrSession session) async {
    final client = _client(session.baseUrl, cookie: session.cookie);
    try {
      await client.send('POST', '/auth/logout', timeout: SeerrConstants.authTimeout);
    } catch (e) {
      appLogger.d('Seerr: sign-out best-effort failed', error: e);
    } finally {
      client.dispose();
    }
  }

  Future<SeerrSession> _signIn({
    required String baseUrl,
    required SeerrAuthMethod method,
    required String path,
    required Map<String, Object?> body,
    required String identifier,
    required String secret,
  }) async {
    final client = _client(baseUrl);
    try {
      final res = await client.send(
        'POST',
        path,
        body: body,
        timeout: SeerrConstants.authTimeout,
        authenticated: false,
      );
      if (res.statusCode == 401 || res.statusCode == 403) {
        final message = res.data is Map<String, dynamic>
            ? (res.data as Map<String, dynamic>)['message'] as String?
            : null;
        throw SeerrAuthException(
          message ?? 'Sign-in rejected',
          statusCode: res.statusCode,
          display: t.seerr.signInRejected,
        );
      }
      SeerrHttpClient.throwForStatus(res);
      if (!client.captureSessionCookie(res.response)) {
        throw SeerrAuthException('Seerr did not issue a session cookie', display: t.seerr.noSessionCookie);
      }
      final user = await _resolveUser(client, res.data);
      return SeerrSession(
        baseUrl: client.baseUrl,
        method: method,
        identifier: identifier,
        secret: secret,
        cookie: client.cookie!,
        userId: user.id,
        permissions: user.permissions ?? 0,
        displayName: user.displayName ?? identifier,
        instanceLabel: '',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    } finally {
      client.dispose();
    }
  }

  /// The login endpoints return the [SeerrUser] directly; fall back to
  /// `GET /auth/me` with the fresh cookie if that shape ever changes.
  Future<SeerrUser> _resolveUser(SeerrHttpClient client, dynamic loginData) async {
    if (loginData is Map<String, dynamic>) {
      try {
        return SeerrUser.fromJson(loginData);
      } catch (_) {
        // fall through to /auth/me
      }
    }
    final res = await client.send('GET', '/auth/me', timeout: SeerrConstants.authTimeout);
    // throwForStatus passes 401 through (it's normally the re-auth signal);
    // here it means the fresh cookie was rejected — an auth failure, not a
    // malformed-user-payload crash further down.
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw SeerrAuthException(
        'Seerr rejected the fresh session cookie',
        statusCode: res.statusCode,
        display: t.seerr.freshCookieRejected,
      );
    }
    SeerrHttpClient.throwForStatus(res);
    final data = res.data;
    if (data is Map<String, dynamic>) return SeerrUser.fromJson(data);
    throw SeerrAuthException('Seerr did not return user information', display: t.seerr.noUserInformation);
  }
}
