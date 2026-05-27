import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import '../connection/connection.dart';
import '../connection/connection_auth_service.dart';
import '../exceptions/media_server_exceptions.dart';
import '../utils/app_logger.dart';
import '../utils/media_server_http_client.dart';
import '../utils/media_server_timeouts.dart';
import '../utils/log_redaction_manager.dart';
import '../utils/poll_with_backoff.dart';
import '../utils/url_utils.dart';
import 'jellyfin_auth_header.dart';

/// Result of a successful Jellyfin URL probe (`/System/Info/Public`).
class JellyfinServerInfo {
  final String serverName;

  /// Server's `Id` field — Jellyfin's machine identifier (UUID hex).
  final String machineId;

  /// Server's reported version string.
  final String version;

  const JellyfinServerInfo({required this.serverName, required this.machineId, required this.version});
}

/// Result of `POST /QuickConnect/Initiate`. The [code] is shown to the user
/// and entered in their Jellyfin web UI to approve sign-in; the [secret] is
/// the opaque polling/exchange handle.
class JellyfinQuickConnectInitiation {
  final String code;
  final String secret;
  const JellyfinQuickConnectInitiation({required this.code, required this.secret});
}

/// Auth flow for adding or refreshing a [JellyfinConnection].
///
/// Lifecycle for adding a server:
///   1. [probe] — validates the URL responds as a Jellyfin server.
///   2. [authenticateByName] (or future Quick Connect equivalent) — exchanges
///      credentials for a long-lived access token and returns a built
///      [JellyfinConnection] ready to insert into [ConnectionRegistry].
///   3. (later) [validate] / [refresh] / [signOut] for the [ConnectionAuthService]
///      contract.
class JellyfinConnectionAuthService implements ConnectionAuthService {
  JellyfinConnectionAuthService({
    required this.clientName,
    required this.clientVersion,
    required this.deviceName,
    @visibleForTesting http.Client Function()? testHttpClientFactory,
  }) : _testHttpClientFactory = testHttpClientFactory;

  /// App identity sent in the `MediaBrowser` Authorization header. Jellyfin
  /// uses `Client`/`Device`/`DeviceId`/`Version` to populate the device list
  /// in its admin UI and to issue tokens.
  final String clientName;
  final String clientVersion;
  final String deviceName;

  /// Test-only HTTP client factory. When non-null, every internal
  /// [MediaServerHttpClient] is built with a fresh client from this factory
  /// instead of the platform default — lets unit tests intercept requests
  /// via `package:http/testing`'s [http.MockClient]. Returns a factory rather
  /// than a single instance because each [MediaServerHttpClient] closes its
  /// underlying client on `close()`.
  final http.Client Function()? _testHttpClientFactory;

  MediaServerHttpClient _buildHttpClient({required String baseUrl, Map<String, String> headers = const {}}) {
    LogRedactionManager.registerServerUrl(baseUrl);
    return MediaServerHttpClient(baseUrl: baseUrl, defaultHeaders: headers, client: _testHttpClientFactory?.call());
  }

  /// Probe the server identified by [baseUrl] without authenticating. Returns
  /// the public info used by the UI to confirm "yes that's the right server"
  /// before asking for credentials. Throws [MediaServerUrlException] when the
  /// URL is unreachable or doesn't look like a Jellyfin server.
  Future<JellyfinServerInfo> probe(String baseUrl) async {
    final normalised = _normaliseBaseUrl(baseUrl);
    final client = _buildHttpClient(baseUrl: normalised);
    try {
      final response = await client.get('/System/Info/Public', timeout: MediaServerTimeouts.jellyfinProbe);
      throwIfHttpError(response);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw MediaServerUrlException('Server response was not JSON');
      }
      final id = data['Id'];
      final name = data['ServerName'] ?? data['LocalAddress'];
      if (id is! String || name is! String) {
        throw MediaServerUrlException('Server response missing Id/ServerName — not a Jellyfin server?');
      }
      return JellyfinServerInfo(serverName: name, machineId: id, version: data['Version'] as String? ?? '');
    } on MediaServerUrlException {
      // Already the right shape — propagate without re-wrapping.
      rethrow;
    } on MediaServerHttpException catch (e) {
      throw MediaServerUrlException('Server probe failed: ${e.message}');
    } on TimeoutException {
      // Defensive: most request timeouts are wrapped by MediaServerHttpClient,
      // but keep raw timeouts surfaced uniformly if one escapes.
      throw MediaServerUrlException('Server did not respond in time');
    } catch (e) {
      // Catch-all for transport errors that bypass the http client wrap
      // (DNS failures, TLS handshake errors, etc.).
      throw MediaServerUrlException('Server probe failed: $e');
    } finally {
      client.close();
    }
  }

  /// Authenticate against [baseUrl] with [username]/[password] and return a
  /// fully-formed [JellyfinConnection]. Throws [MediaServerAuthException] for
  /// 401/403 responses; other transport errors propagate.
  Future<JellyfinConnection> authenticateByName({
    required String baseUrl,
    required String username,
    required String password,
    required String deviceId,
    JellyfinServerInfo? serverInfo,
  }) async {
    final normalised = _normaliseBaseUrl(baseUrl);
    final info = serverInfo ?? await probe(normalised);

    final authHeader = buildJellyfinAuthHeader(
      clientName: clientName,
      clientVersion: clientVersion,
      deviceName: deviceName,
      deviceId: deviceId,
    );
    final client = _buildHttpClient(
      baseUrl: normalised,
      headers: {'Authorization': authHeader, 'Content-Type': 'application/json'},
    );
    try {
      final response = await client.post(
        '/Users/AuthenticateByName',
        body: jsonEncode({'Username': username, 'Pw': password}),
        // Bound the auth POST so a hanging server can't freeze the auth
        // screen indefinitely; mirrors the timeout on [probe].
        timeout: MediaServerTimeouts.jellyfinProbe,
      );
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw MediaServerAuthException('Invalid username or password', statusCode: response.statusCode);
      }
      throwIfHttpError(response);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw MediaServerAuthException('Authentication response was not JSON');
      }
      final accessToken = data['AccessToken'] as String?;
      final user = data['User'] as Map<String, dynamic>?;
      if (accessToken == null || user == null) {
        throw MediaServerAuthException('Authentication response missing AccessToken or User');
      }
      final userId = user['Id'] as String?;
      final userName = user['Name'] as String?;
      if (userId == null || userName == null) {
        throw MediaServerAuthException('Authentication response missing User.Id or User.Name');
      }
      final policy = user['Policy'] as Map<String, dynamic>?;
      final isAdmin = policy?['IsAdministrator'] as bool? ?? false;

      return _buildConnection(
        info: info,
        normalisedBaseUrl: normalised,
        userId: userId,
        userName: userName,
        accessToken: accessToken,
        deviceId: deviceId,
        isAdministrator: isAdmin,
      );
    } on TimeoutException {
      // Defensive: most request timeouts are wrapped by MediaServerHttpClient.
      // Surface raw timeouts as a URL-level error if one escapes.
      throw MediaServerUrlException('Server did not respond in time');
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        throw MediaServerAuthException('Invalid username or password', statusCode: e.statusCode);
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Whether [baseUrl] has Quick Connect enabled. Returns `false` for any
  /// failure — Jellyfin <10.7 returns 404 on this path, and an offline server
  /// is functionally indistinguishable from QC-disabled for UI purposes.
  Future<bool> isQuickConnectEnabled(String baseUrl) async {
    final normalised = _normaliseBaseUrl(baseUrl);
    final client = _buildHttpClient(baseUrl: normalised);
    try {
      final response = await client.get('/QuickConnect/Enabled', timeout: MediaServerTimeouts.jellyfinProbe);
      if (response.statusCode != 200) return false;
      final data = response.data;
      // The endpoint returns a bare JSON `true`/`false`, not an object.
      return data is bool ? data : false;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  /// Initiate a Quick Connect session: returns the user-facing code and the
  /// polling secret. The Authorization header carries the device identity
  /// only — there's no token until the secret is exchanged after approval.
  Future<JellyfinQuickConnectInitiation> initiateQuickConnect({
    required String baseUrl,
    required String deviceId,
  }) async {
    final normalised = _normaliseBaseUrl(baseUrl);
    final authHeader = buildJellyfinAuthHeader(
      clientName: clientName,
      clientVersion: clientVersion,
      deviceName: deviceName,
      deviceId: deviceId,
    );
    final client = _buildHttpClient(baseUrl: normalised, headers: {'Authorization': authHeader});
    try {
      // Current Jellyfin (10.7+) accepts GET; older builds required POST.
      // Try GET first, fall back on 405.
      var response = await client.get('/QuickConnect/Initiate', timeout: MediaServerTimeouts.jellyfinProbe);
      if (response.statusCode == 405) {
        response = await client.post('/QuickConnect/Initiate', timeout: MediaServerTimeouts.jellyfinProbe);
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw MediaServerAuthException('Quick Connect rejected by server', statusCode: response.statusCode);
      }
      throwIfHttpError(response);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw MediaServerAuthException('Quick Connect response was not JSON');
      }
      final code = data['Code'] as String?;
      final secret = data['Secret'] as String?;
      if (code == null || secret == null) {
        throw MediaServerAuthException('Quick Connect response missing Code or Secret');
      }
      return JellyfinQuickConnectInitiation(code: code, secret: secret);
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        throw MediaServerAuthException('Quick Connect rejected by server', statusCode: e.statusCode);
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Poll `/QuickConnect/Connect?secret=…` until the user approves the code
  /// in their Jellyfin web UI, then exchange the approved secret for a token
  /// and return a fully-formed [JellyfinConnection]. Returns `null` on
  /// cancel, timeout, or server-side secret expiry (404 mid-poll). Throws
  /// [MediaServerAuthException] on auth failures (401/403).
  Future<JellyfinConnection?> authenticateByQuickConnect({
    required String baseUrl,
    required String secret,
    required String deviceId,
    JellyfinServerInfo? serverInfo,
    Duration timeout = const Duration(minutes: 5),
    bool Function()? shouldCancel,
  }) async {
    final normalised = _normaliseBaseUrl(baseUrl);
    final info = serverInfo ?? await probe(normalised);
    LogRedactionManager.registerCustomValue(secret);

    final authHeader = buildJellyfinAuthHeader(
      clientName: clientName,
      clientVersion: clientVersion,
      deviceName: deviceName,
      deviceId: deviceId,
    );
    // Reuse a single client across the polling loop — opening one per tick
    // would churn TCP connections needlessly on a 5-minute window.
    final pollClient = _buildHttpClient(baseUrl: normalised, headers: {'Authorization': authHeader});
    bool? approved;
    try {
      approved = await pollWithBackoff<bool>(
        endTime: DateTime.now().add(timeout),
        shouldCancel: shouldCancel,
        probe: () async {
          try {
            final response = await pollClient.get(
              '/QuickConnect/Connect',
              queryParameters: {'secret': secret},
              timeout: MediaServerTimeouts.jellyfinProbe,
            );
            // 404 mid-poll = secret expired or revoked server-side. Terminal.
            if (response.statusCode == 404) throw const PollTerminatedSignal();
            if (response.statusCode == 401 || response.statusCode == 403) {
              throw MediaServerAuthException('Quick Connect poll rejected by server', statusCode: response.statusCode);
            }
            throwIfHttpError(response);
            final data = response.data;
            if (data is Map<String, dynamic> && data['Authenticated'] == true) {
              return true;
            }
            return null;
          } on MediaServerHttpException catch (e) {
            if (e.statusCode == 404) throw const PollTerminatedSignal();
            if (e.statusCode == 401 || e.statusCode == 403) {
              throw MediaServerAuthException('Quick Connect poll rejected by server', statusCode: e.statusCode);
            }
            // Transient network blip — let the backoff handle it. The outer
            // timeout is the safety net if the server is durably broken.
            return null;
          }
        },
      );
    } finally {
      pollClient.close();
    }

    if (approved != true) return null;

    // Exchange the approved secret for an access token.
    final exchangeClient = _buildHttpClient(
      baseUrl: normalised,
      headers: {'Authorization': authHeader, 'Content-Type': 'application/json'},
    );
    try {
      final response = await exchangeClient.post(
        '/Users/AuthenticateWithQuickConnect',
        body: jsonEncode({'Secret': secret}),
      );
      if (response.statusCode == 400) {
        throw MediaServerAuthException('Quick Connect exchange rejected by server', statusCode: response.statusCode);
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw MediaServerAuthException('Quick Connect exchange rejected by server', statusCode: response.statusCode);
      }
      throwIfHttpError(response);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw MediaServerAuthException('Quick Connect exchange response was not JSON');
      }
      final accessToken = data['AccessToken'] as String?;
      final user = data['User'] as Map<String, dynamic>?;
      if (accessToken == null || user == null) {
        throw MediaServerAuthException('Quick Connect exchange missing AccessToken or User');
      }
      final userId = user['Id'] as String?;
      final userName = user['Name'] as String?;
      if (userId == null || userName == null) {
        throw MediaServerAuthException('Quick Connect exchange missing User.Id or User.Name');
      }
      final policy = user['Policy'] as Map<String, dynamic>?;
      final isAdmin = policy?['IsAdministrator'] as bool? ?? false;

      return _buildConnection(
        info: info,
        normalisedBaseUrl: normalised,
        userId: userId,
        userName: userName,
        accessToken: accessToken,
        deviceId: deviceId,
        isAdministrator: isAdmin,
      );
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 400 || e.statusCode == 401 || e.statusCode == 403) {
        throw MediaServerAuthException('Quick Connect exchange rejected by server', statusCode: e.statusCode);
      }
      rethrow;
    } finally {
      exchangeClient.close();
    }
  }

  @override
  Future<bool> validate(Connection connection) async {
    if (connection is! JellyfinConnection) return false;
    final client = _authenticatedClient(connection);
    try {
      final response = await client.get('/Users/Me', timeout: MediaServerTimeouts.jellyfinProbe);
      return response.statusCode == 200;
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) return false;
      rethrow;
    } finally {
      client.close();
    }
  }

  @override
  Future<Connection> refresh(Connection connection) async {
    if (connection is! JellyfinConnection) return connection;
    final ok = await validate(connection);
    if (!ok) {
      return connection.copyWith(status: ConnectionStatus.authError);
    }
    return connection.copyWith(status: ConnectionStatus.online, lastAuthenticatedAt: DateTime.now());
  }

  @override
  Future<void> signOut(Connection connection) async {
    if (connection is! JellyfinConnection) return;
    final client = _authenticatedClient(connection);
    try {
      // Best-effort: server may already have invalidated the session.
      await client.post('/Sessions/Logout', timeout: MediaServerTimeouts.jellyfinSignOut);
    } catch (e) {
      appLogger.d('JellyfinConnectionAuthService: signOut best-effort failed: $e');
    } finally {
      client.close();
    }
  }

  MediaServerHttpClient _authenticatedClient(JellyfinConnection connection) {
    LogRedactionManager.registerToken(connection.accessToken);
    return _buildHttpClient(
      baseUrl: connection.baseUrl,
      headers: {
        'X-Emby-Token': connection.accessToken,
        'Authorization': buildJellyfinAuthHeader(
          clientName: clientName,
          clientVersion: clientVersion,
          deviceName: deviceName,
          deviceId: connection.deviceId,
          accessToken: connection.accessToken,
        ),
      },
    );
  }

  /// Strip any trailing slash so subsequent path joins (`/Users/...`) don't
  /// produce double slashes. Delegates to the shared [stripTrailingSlash].
  static String _normaliseBaseUrl(String input) => stripTrailingSlash(input);

  /// Build a [JellyfinConnection] from a successful auth/exchange response.
  /// Connection id is derived from `(machineId, userId)` so each user on a
  /// given server has a single stable connection row.
  static JellyfinConnection _buildConnection({
    required JellyfinServerInfo info,
    required String normalisedBaseUrl,
    required String userId,
    required String userName,
    required String accessToken,
    required String deviceId,
    required bool isAdministrator,
  }) {
    final now = DateTime.now();
    return JellyfinConnection(
      id: '${info.machineId}/$userId',
      baseUrl: normalisedBaseUrl,
      serverName: info.serverName,
      serverMachineId: info.machineId,
      userId: userId,
      userName: userName,
      accessToken: accessToken,
      deviceId: deviceId,
      isAdministrator: isAdministrator,
      status: ConnectionStatus.online,
      createdAt: now,
      lastAuthenticatedAt: now,
    );
  }
}
