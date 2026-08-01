import 'package:http/http.dart' as http;

import '../../models/seerr/seerr_public_settings.dart';
import '../../models/seerr/seerr_session.dart';
import '../../models/seerr/seerr_user.dart';
import '../../utils/app_logger.dart';
import 'seerr_constants.dart';
import 'seerr_exceptions.dart';
import 'seerr_http_client.dart';

/// Sign-in flows against a Seerr instance. Every flow ends with a captured
/// `connect.sid` cookie and the Seerr-side [SeerrUser], packed into a
/// [SeerrSession].
class SeerrAuthService {
  final http.Client Function()? httpClientFactory;

  SeerrAuthService({this.httpClientFactory});

  SeerrHttpClient _client(String baseUrl, {String? cookie}) =>
      SeerrHttpClient(baseUrl: baseUrl, httpClient: httpClientFactory?.call(), cookie: cookie);

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
        throw SeerrUrlException('Could not reach $baseUrl: $e');
      }
      final data = res.data;
      if (res.statusCode >= 400 || data is! Map<String, dynamic>) {
        throw SeerrUrlException('No Seerr instance at $baseUrl (HTTP ${res.statusCode})');
      }
      final settings = SeerrPublicSettings.fromJson(data);
      if (!settings.initialized) {
        throw const SeerrUrlException('Seerr instance has not completed first-run setup');
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
      SeerrAuthMethod.plex => throw const SeerrReauthUnavailableException('No Plex token available for silent re-auth'),
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
      _ => throw const SeerrAuthException('No stored credentials for silent re-auth'),
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
        throw SeerrAuthException(message ?? 'Sign-in rejected', statusCode: res.statusCode);
      }
      SeerrHttpClient.throwForStatus(res);
      if (!client.captureSessionCookie(res.response)) {
        throw const SeerrAuthException('Seerr did not issue a session cookie');
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
      throw SeerrAuthException('Seerr rejected the fresh session cookie', statusCode: res.statusCode);
    }
    SeerrHttpClient.throwForStatus(res);
    final data = res.data;
    if (data is Map<String, dynamic>) return SeerrUser.fromJson(data);
    throw const SeerrAuthException('Seerr did not return user information');
  }
}
