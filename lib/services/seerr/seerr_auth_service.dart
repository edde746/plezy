import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import '../../connection/connection.dart';
import '../../models/seerr/seerr_user.dart';
import '../../utils/app_logger.dart';
import 'seerr_constants.dart';
import 'seerr_exceptions.dart';
import 'seerr_http_client.dart';

/// Result of probing a Seerr instance — what /status and /settings/public
/// reported before any user authenticated.
class SeerrProbeInfo {
  /// Application title from /settings/public (falls back to "Seerr").
  final String instanceLabel;

  /// Version string from /status (best-effort; empty if unknown).
  final String version;

  /// Whether Seerr reports it has completed first-run setup.
  final bool initialized;

  const SeerrProbeInfo({required this.instanceLabel, required this.version, required this.initialized});
}

/// Authenticates a user against a Seerr instance using their Jellyfin
/// credentials.
///
/// Lifecycle for adding a server:
///   1. [probe] — confirm the URL points at a running, initialised Seerr.
///   2. [authenticateWithJellyfin] — sign in and return a built [SeerrConnection].
///   3. [reauth] — silent re-login using stored Jellyfin credentials
///      (called from the SeerrClient's 401 handler).
///   4. [signOut] — best-effort POST /auth/logout.
class SeerrAuthService {
  SeerrAuthService({@visibleForTesting http.Client Function()? testHttpClientFactory})
    : _testHttpClientFactory = testHttpClientFactory;

  final http.Client Function()? _testHttpClientFactory;

  http.Client? _newTestClient() => _testHttpClientFactory?.call();

  SeerrHttpClient _buildClient(String baseUrl, {String? sessionCookie}) =>
      SeerrHttpClient(baseUrl: baseUrl, httpClient: _newTestClient(), initialSessionCookie: sessionCookie);

  /// Validate that [baseUrl] points to a Seerr instance and capture the
  /// minimal metadata needed to label the connection. Throws
  /// [SeerrUrlException] on transport failures or when the instance reports
  /// `initialized: false`.
  Future<SeerrProbeInfo> probe(String baseUrl) async {
    final client = _buildClient(baseUrl);
    try {
      final settings = await _safeGet(client, '/settings/public', timeout: SeerrConstants.probeTimeout);
      if (settings == null) {
        throw const SeerrUrlException('Could not reach /settings/public');
      }
      final initialized = settings['initialized'] as bool? ?? false;
      String label = 'Seerr';
      final raw = settings['applicationTitle'];
      if (raw is String && raw.isNotEmpty) label = raw;

      String version = '';
      try {
        final status = await _safeGet(client, '/status', timeout: SeerrConstants.probeTimeout);
        final v = status?['version'];
        if (v is String) version = v;
      } catch (e) {
        appLogger.d('Seerr probe: /status failed (non-fatal): $e');
      }

      return SeerrProbeInfo(instanceLabel: label, version: version, initialized: initialized);
    } finally {
      client.dispose();
    }
  }

  /// Sign in with Jellyfin SSO. Returns a fully-built [SeerrConnection]
  /// with the session cookie captured and the Seerr-side user populated.
  Future<SeerrConnection> authenticateWithJellyfin({
    required String baseUrl,
    required String username,
    required String password,
    SeerrProbeInfo? probeInfo,
  }) async {
    final info = probeInfo ?? await probe(baseUrl);
    if (!info.initialized) {
      throw const SeerrUrlException('Seerr instance has not completed first-run setup');
    }
    final client = _buildClient(baseUrl);
    try {
      final loginRes = await client.sendJson(
        'POST',
        '/auth/jellyfin',
        body: {'username': username, 'password': password},
        timeout: SeerrConstants.authRequestTimeout,
        authenticated: false,
      );
      if (loginRes.response.statusCode == 401 || loginRes.response.statusCode == 403) {
        throw SeerrAuthException(
          'Invalid Jellyfin username or password',
          statusCode: loginRes.response.statusCode,
        );
      }
      SeerrHttpClient.throwForStatus(loginRes);
      if (!client.captureSessionCookie(loginRes.response)) {
        throw const SeerrAuthException('Seerr did not issue a session cookie');
      }
      final user = _extractUserFromLogin(loginRes.data) ?? await _fetchMe(client);
      if (user == null) {
        throw const SeerrAuthException('Seerr did not return user information');
      }
      final now = DateTime.now();
      return SeerrConnection(
        id: _connectionId(baseUrl, user.id),
        baseUrl: baseUrl,
        instanceLabel: info.instanceLabel,
        jellyfinUsername: username,
        jellyfinPassword: password,
        sessionCookie: client.sessionCookieValue ?? '',
        sessionCookieCapturedAt: now,
        seerrUserId: user.id,
        seerrUserType: user.userType,
        permissions: user.permissions,
        avatarUrl: user.avatar,
        status: ConnectionStatus.online,
        createdAt: now,
        lastAuthenticatedAt: now,
      );
    } finally {
      client.dispose();
    }
  }

  /// Re-login silently using the [connection]'s stored Jellyfin password.
  /// Returns the updated connection with the new cookie value. Throws
  /// [SeerrAuthException] when the stored password is empty or rejected.
  Future<SeerrConnection> reauth(SeerrConnection connection) async {
    if (connection.jellyfinPassword.isEmpty) {
      throw const SeerrAuthException('No stored credentials for silent re-auth');
    }
    final refreshed = await authenticateWithJellyfin(
      baseUrl: connection.baseUrl,
      username: connection.jellyfinUsername,
      password: connection.jellyfinPassword,
    );
    return connection.copyWith(
      sessionCookie: refreshed.sessionCookie,
      sessionCookieCapturedAt: refreshed.sessionCookieCapturedAt,
      seerrUserId: refreshed.seerrUserId,
      seerrUserType: refreshed.seerrUserType,
      permissions: refreshed.permissions,
      avatarUrl: refreshed.avatarUrl,
      instanceLabel: refreshed.instanceLabel,
      status: ConnectionStatus.online,
      lastAuthenticatedAt: DateTime.now(),
    );
  }

  /// Best-effort sign-out. Swallows errors — the server may already have
  /// expired the session and a failure shouldn't block local cleanup.
  Future<void> signOut(SeerrConnection connection) async {
    final client = _buildClient(connection.baseUrl, sessionCookie: connection.sessionCookie);
    try {
      await client.sendJson('POST', '/auth/logout', timeout: SeerrConstants.authRequestTimeout);
    } catch (e) {
      appLogger.d('Seerr signOut best-effort failed: $e');
    } finally {
      client.dispose();
    }
  }

  Future<Map<String, dynamic>?> _safeGet(SeerrHttpClient client, String path, {required Duration timeout}) async {
    try {
      final res = await client.sendJson('GET', path, timeout: timeout, authenticated: false);
      if (res.response.statusCode >= 400) return null;
      return res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : null;
    } catch (_) {
      return null;
    }
  }

  Future<SeerrUser?> _fetchMe(SeerrHttpClient client) async {
    final res = await client.sendJson('GET', '/auth/me', timeout: SeerrConstants.authRequestTimeout);
    SeerrHttpClient.throwForStatus(res);
    if (res.data is Map<String, dynamic>) return SeerrUser.fromJson(res.data as Map<String, dynamic>);
    return null;
  }

  SeerrUser? _extractUserFromLogin(dynamic data) {
    if (data is Map<String, dynamic>) {
      // /auth/jellyfin returns the User directly (per Overseerr lineage).
      try {
        return SeerrUser.fromJson(data);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Connection id format: `seerr-<host>-<userId>` so the same Seerr +
  /// Jellyfin-user pair always maps to a single row.
  static String _connectionId(String baseUrl, int seerrUserId) {
    final uri = Uri.tryParse(baseUrl);
    final host = uri?.host.isNotEmpty == true ? uri!.host : baseUrl;
    return 'seerr-$host-$seerrUserId';
  }
}
