import 'dart:async';

import 'package:http/http.dart' as http;

import '../../i18n/strings.g.dart';
import '../../models/seerr/seerr_public_settings.dart';
import '../../models/seerr/seerr_session.dart';
import '../../models/seerr/seerr_user.dart';
import '../../utils/app_logger.dart';
import '../../utils/log_redaction_manager.dart';
import '../../utils/poll_with_backoff.dart';
import '../../utils/url_utils.dart';
import 'seerr_constants.dart';
import 'seerr_exceptions.dart';
import 'seerr_http_client.dart';

/// A reachable, initialized Seerr instance: the URL that answered and the
/// public settings it reported.
typedef SeerrReachableInstance = ({String baseUrl, SeerrPublicSettings settings});

/// Result of `POST /auth/jellyfin/quickconnect/initiate`: [code] is shown to
/// the user to approve inside Jellyfin, [secret] drives the poll and the final
/// exchange.
class SeerrQuickConnectInitiation {
  final String code;
  final String secret;

  const SeerrQuickConnectInitiation({required this.code, required this.secret});
}

/// Sign-in flows against a Seerr instance. Every flow ends with a captured
/// `connect.sid` cookie and the Seerr-side [SeerrUser] read back through
/// `GET /auth/me`, packed into a [SeerrSession].
class SeerrAuthService {
  final http.Client Function()? httpClientFactory;

  SeerrAuthService({this.httpClientFactory});

  SeerrHttpClient _client(String baseUrl, {String? cookie}) =>
      SeerrHttpClient(baseUrl: baseUrl, httpClient: httpClientFactory?.call(), cookie: cookie);

  /// Schemeless-input guesses, TLS first: a bare host is usually a public
  /// instance behind a reverse proxy, and [probeFirstReachable] must be able
  /// to prefer the TLS candidate before a plaintext one wins the race.
  static const List<BaseUrlGuess> _schemelessGuesses = [
    (scheme: 'https', port: null),
    (scheme: 'http', port: null),
    (scheme: 'http', port: SeerrConstants.defaultPort),
  ];

  /// Expands a user-typed instance address into probe candidates: an explicit
  /// scheme is authoritative, otherwise TLS, plain HTTP, and the default
  /// install port are all tried. Guesses are for discovery only — only the
  /// candidate that answered is persisted.
  static List<String> expandUrlCandidates(String input) => expandBaseUrlCandidates(input, guesses: _schemelessGuesses);

  /// Probes every [expandUrlCandidates] guess for [input] and returns the
  /// first reachable instance.
  ///
  /// TLS wins by construction: probes all start together, but a plaintext
  /// success is held while any `https` candidate is still in flight and is
  /// only accepted once they have all failed. The sign-in that follows posts a
  /// password to whichever URL wins here, so a slow-but-working TLS endpoint
  /// must beat a fast plaintext one; each probe already bounds the hold at
  /// [SeerrConstants.probeTimeout].
  ///
  /// When nothing answers, the failure that reached a *server* is reported in
  /// preference to a transport error, so "finish Seerr's setup" isn't masked by
  /// "could not reach https://…" from a candidate the user never meant.
  Future<SeerrReachableInstance> probeFirstReachable(String input) async {
    final candidates = expandUrlCandidates(input);
    if (candidates.isEmpty) {
      throw SeerrUrlException('Not a usable Seerr instance URL: "$input"', display: t.seerr.invalidUrl);
    }
    if (candidates.length == 1) {
      final only = candidates.single;
      return (baseUrl: only, settings: await probe(only));
    }

    final completer = Completer<SeerrReachableInstance>();
    final failures = List<(Object, StackTrace)?>.filled(candidates.length, null);
    var pending = candidates.length;
    var pendingSecure = candidates.where(_isSecure).length;
    SeerrReachableInstance? heldPlaintext;

    void settle() {
      if (completer.isCompleted) return;
      final held = heldPlaintext;
      if (held != null && pendingSecure == 0) {
        appLogger.d('Seerr: no TLS candidate answered, accepting the plaintext instance URL');
        completer.complete(held);
        return;
      }
      if (pending == 0) {
        final (error, stackTrace) = _mostInformativeFailure(failures);
        completer.completeError(error, stackTrace);
      }
    }

    for (final (index, candidate) in candidates.indexed) {
      final secure = _isSecure(candidate);
      unawaited(
        probe(candidate).then(
          (settings) {
            pending -= 1;
            if (secure) pendingSecure -= 1;
            if (completer.isCompleted) return;
            if (secure) {
              completer.complete((baseUrl: candidate, settings: settings));
              return;
            }
            heldPlaintext ??= (baseUrl: candidate, settings: settings);
            settle();
          },
          onError: (Object error, StackTrace stackTrace) {
            failures[index] = (error, stackTrace);
            pending -= 1;
            if (secure) pendingSecure -= 1;
            settle();
          },
        ),
      );
    }
    return completer.future;
  }

  static bool _isSecure(String baseUrl) => baseUrl.startsWith('https://');

  /// The failure worth showing: one that came back from a server outranks a
  /// transport error, and the first candidate — the URL the user most likely
  /// meant — breaks the tie.
  static (Object, StackTrace) _mostInformativeFailure(List<(Object, StackTrace)?> failures) {
    for (final failure in failures) {
      if (failure != null && failure.$1 is SeerrUrlException && (failure.$1 as SeerrUrlException).statusCode != null) {
        return failure;
      }
    }
    return failures.firstWhere((failure) => failure != null)!;
  }

  /// Validate that [baseUrl] points at a running, initialized Seerr and
  /// collect the metadata the connect flow needs. Throws [SeerrUrlException]
  /// when unreachable, not set up, or answered by an auth proxy instead.
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
      if (SeerrHttpClient.classify(res, path: '/settings/public') == SeerrRejection.intermediary) {
        throw SeerrUrlException(
          'Auth proxy in front of $baseUrl (HTTP ${res.statusCode})',
          display: t.seerr.behindAuthProxy,
          statusCode: res.statusCode,
        );
      }
      final data = res.data;
      if (res.statusCode >= 400 || data is! Map<String, dynamic>) {
        throw SeerrUrlException(
          'No Seerr instance at $baseUrl (HTTP ${res.statusCode})',
          display: t.seerr.noInstanceAtUrl(url: baseUrl, status: res.statusCode),
          statusCode: res.statusCode,
        );
      }
      final settings = SeerrPublicSettings.fromJson(data);
      if (!settings.initialized) {
        throw SeerrUrlException(
          'Seerr instance has not completed first-run setup',
          display: t.seerr.notInitialized,
          statusCode: res.statusCode,
        );
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

  /// `POST /auth/jellyfin/quickconnect/initiate` (Seerr 3.4+): starts a
  /// Jellyfin Quick Connect session proxied by the instance. A 404 means the
  /// instance predates the proxy routes; anything else 4xx/5xx is the
  /// instance's own rejection (Quick Connect disabled on its Jellyfin, Emby
  /// backends, …).
  Future<SeerrQuickConnectInitiation> initiateQuickConnect(String baseUrl) async {
    final client = _client(baseUrl);
    try {
      final res = await client.send(
        'POST',
        '/auth/jellyfin/quickconnect/initiate',
        timeout: SeerrConstants.authTimeout,
        authenticated: false,
      );
      SeerrHttpClient.throwIfIntermediary(res, path: '/auth/jellyfin/quickconnect/initiate');
      final data = res.data;
      final message = data is Map<String, dynamic> ? data['message'] as String? : null;
      if (res.statusCode == 404) {
        throw SeerrAuthException(
          'Seerr has no Quick Connect proxy routes (needs 3.4+)',
          statusCode: res.statusCode,
          display: t.seerr.quickConnectUnsupported,
        );
      }
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
      // The secret rides in a query string, so a poll failure would otherwise
      // put it in a log line via ClientException's URI.
      LogRedactionManager.registerCustomValue(secret);
      return SeerrQuickConnectInitiation(code: code, secret: secret);
    } finally {
      client.dispose();
    }
  }

  /// Polls `GET /auth/jellyfin/quickconnect/check` until the code is approved
  /// inside Jellyfin, then exchanges the secret through
  /// `POST …/authenticate` for a Seerr session.
  ///
  /// Returns null when [shouldCancel] fires, when [timeout] elapses, or when
  /// the instance drops the secret mid-poll (404) — the caller decides which of
  /// those is worth an error message. Transient poll failures keep retrying.
  Future<SeerrSession?> signInWithQuickConnect({
    required String baseUrl,
    required String secret,
    bool Function()? shouldCancel,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    // One client for the whole window: no TCP churn across minutes of polling.
    final pollClient = _client(baseUrl);
    final bool? approved;
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
          const path = '/auth/jellyfin/quickconnect/check';
          if (SeerrHttpClient.classify(res, path: path) == SeerrRejection.credentials) {
            final data = res.data;
            throw SeerrAuthException(
              (data is Map<String, dynamic> ? data['message'] as String? : null) ?? 'Quick Connect poll rejected',
              statusCode: res.statusCode,
              display: t.addServer.quickConnectPollRejected,
            );
          }
          SeerrHttpClient.throwForStatus(res, path: path);
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
      if (SeerrHttpClient.classify(res, path: path) == SeerrRejection.credentials) {
        throw SeerrAuthException(
          (res.data as Map<String, dynamic>)['message'] as String,
          statusCode: res.statusCode,
          display: t.seerr.signInRejected,
        );
      }
      SeerrHttpClient.throwForStatus(res, path: path);
      if (!client.captureSessionCookie(res.response)) {
        throw SeerrAuthException('Seerr did not issue a session cookie', display: t.seerr.noSessionCookie);
      }
      final user = await _fetchUser(client);
      return SeerrSession(
        baseUrl: client.baseUrl,
        method: method,
        identifier: identifier,
        secret: secret,
        cookie: client.cookie!,
        userId: user.id,
        permissions: user.permissions,
        displayName: user.displayName ?? identifier,
        instanceLabel: '',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    } finally {
      client.dispose();
    }
  }

  /// The user behind the fresh cookie, via `GET /auth/me`.
  ///
  /// The login response body is ignored on purpose. Each handler returns
  /// whatever `User` instance it happened to build: `POST /auth/local` loads
  /// only id, email, password, and plexId to check the password, so its body
  /// carries the entity's `permissions` default of 0 rather than the stored
  /// mask (#2213), and a first sign-in through Plex or Jellyfin returns the
  /// just-saved entity before its display name is derived. `/auth/me` reloads
  /// the full row, which is what the Seerr web UI itself reads after login.
  Future<SeerrUser> _fetchUser(SeerrHttpClient client) async {
    final res = await client.send('GET', '/auth/me', timeout: SeerrConstants.authTimeout);
    // Seerr's own middleware refusing the cookie it just issued is an auth
    // failure, not a malformed-user-payload crash further down; a wall in
    // front of it is neither.
    if (SeerrHttpClient.classify(res, path: '/auth/me') == SeerrRejection.session) {
      throw SeerrAuthException(
        'Seerr rejected the fresh session cookie',
        statusCode: res.statusCode,
        display: t.seerr.freshCookieRejected,
      );
    }
    SeerrHttpClient.throwForStatus(res, path: '/auth/me');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      try {
        return SeerrUser.fromJson(data);
      } on TypeError catch (e) {
        appLogger.w('Seerr: /auth/me returned an unusable user', error: e);
      }
    }
    throw SeerrAuthException('Seerr did not return user information', display: t.seerr.noUserInformation);
  }
}
