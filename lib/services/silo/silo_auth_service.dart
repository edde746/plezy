import 'dart:io';

import '../../connection/connection.dart';
import '../../exceptions/media_server_exceptions.dart';
import 'silo_api.dart';
import 'silo_identity.dart';
import 'silo_json.dart';

/// Revoke a stored Silo session on its server. Best effort, bounded by the
/// logout timeout; errors are logged without token material.
Future<void> revokeSiloSession(SiloConnection connection) async {
  if (connection.refreshToken.isEmpty && connection.accessToken.isEmpty) return;
  final api = SiloApi(
    baseUrl: connection.baseUrl,
    identity: await resolveSiloClientIdentity(),
    tokens: SiloTokens(
      accessToken: connection.accessToken,
      refreshToken: connection.refreshToken,
      expiresAt: connection.accessTokenExpiresAt,
    ),
  );
  try {
    await api.logout();
  } finally {
    api.close();
  }
}

/// What a probed address answered with.
class SiloServerProbe {
  /// Normalised base URL (scheme, host, port, path prefix; no `/api/v2`).
  final String baseUrl;
  final String serverId;
  final String serverVersion;
  final bool passwordLogin;

  const SiloServerProbe({
    required this.baseUrl,
    required this.serverId,
    required this.serverVersion,
    required this.passwordLogin,
  });

  bool get isCleartext => baseUrl.startsWith('http://');

  /// `host[:port][/prefix]` for display.
  String get displayName {
    final uri = Uri.parse(baseUrl);
    final port = uri.hasPort ? ':${uri.port}' : '';
    final prefix = uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path;
    return '${uri.host}$port$prefix';
  }
}

class SiloProfileChoice {
  final String id;
  final String name;
  final bool hasPin;
  final bool isPrimary;
  final bool isChild;
  final String? avatarUrl;

  const SiloProfileChoice({
    required this.id,
    required this.name,
    required this.hasPin,
    required this.isPrimary,
    required this.isChild,
    this.avatarUrl,
  });
}

/// A signed-in account waiting for a profile choice.
class SiloSignIn {
  final SiloServerProbe server;
  final SiloApi api;
  final SiloTokens tokens;
  final String accountId;
  final String userName;
  final String role;
  final List<SiloProfileChoice> profiles;

  const SiloSignIn({
    required this.server,
    required this.api,
    required this.tokens,
    required this.accountId,
    required this.userName,
    required this.role,
    required this.profiles,
  });
}

/// Onboarding against a Silo server's native API: address probe, password
/// sign-in, profile list and PIN check. Produces a [SiloConnection].
class SiloAuthService {
  SiloAuthService({required this.identity});

  final SiloClientIdentity identity;

  // --------------------------------------------------------------- address

  /// Interpret what the user typed. Without a scheme HTTPS comes first; plain
  /// HTTP is offered second only for hosts that are local by construction.
  /// A public `http://` address is accepted only when typed explicitly (the
  /// screen asks the user to confirm it).
  static List<String> candidatesFor(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) throw const MediaServerUrlException('Enter your Silo server address.');
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return [normalize(trimmed)];
    if (trimmed.contains('://')) {
      throw const MediaServerUrlException('Only http:// and https:// addresses are supported.');
    }
    final https = normalize('https://$trimmed');
    return [https, if (isLocalNetworkHost(Uri.parse(https).host)) normalize('http://$trimmed')];
  }

  /// Normalise a schemed URL: no user info, query or fragment; trailing
  /// slashes and pasted suffixes (`/api/v2`, `/web/index.html`) removed.
  static String normalize(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null || uri.host.isEmpty || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const MediaServerUrlException('That is not a valid server address.');
    }
    if (uri.userInfo.isNotEmpty) {
      throw const MediaServerUrlException('Server addresses cannot contain a user name or password.');
    }
    if (uri.hasQuery || uri.hasFragment) {
      throw const MediaServerUrlException('Server addresses cannot contain a query or fragment.');
    }
    var path = uri.path;
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    var changed = true;
    while (changed) {
      changed = false;
      for (final suffix in const ['/api/v2', '/api/v1', '/api', '/web/index.html', '/index.html', '/web', '/login']) {
        if (path.toLowerCase().endsWith(suffix)) {
          path = path.substring(0, path.length - suffix.length);
          while (path.endsWith('/')) {
            path = path.substring(0, path.length - 1);
          }
          changed = true;
        }
      }
    }
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port$path';
  }

  /// Loopback, private, link-local, CGNAT/overlay ranges, `.local`, `.lan`,
  /// `.home.arpa` and single-label names.
  static bool isLocalNetworkHost(String host) {
    final h = host.toLowerCase();
    if (h == 'localhost' || h.endsWith('.local') || h.endsWith('.lan') || h.endsWith('.home.arpa')) return true;
    final ip = InternetAddress.tryParse(h.replaceAll('[', '').replaceAll(']', ''));
    if (ip == null) return !h.contains('.');
    if (ip.isLoopback || ip.isLinkLocal) return true;
    if (ip.type == InternetAddressType.IPv4) {
      final b = ip.rawAddress;
      return b[0] == 10 ||
          (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
          (b[0] == 192 && b[1] == 168) ||
          (b[0] == 100 && b[1] >= 64 && b[1] <= 127);
    }
    final b = ip.rawAddress;
    return (b[0] & 0xfe) == 0xfc; // fc00::/7 unique local
  }

  /// Try each candidate in order; the first that answers as a v2 Silo server
  /// wins. A TLS failure on HTTPS is reported rather than downgraded.
  Future<SiloServerProbe> probe(String input) async {
    final candidates = candidatesFor(input);
    Object? lastError;
    for (final candidate in candidates) {
      final api = SiloApi(baseUrl: candidate, identity: identity);
      try {
        final info = await api.systemInfo();
        if (intOrNull(info['api_major']) != 2) {
          throw const MediaServerUrlException(
            'This server does not offer Silo API version 2. Update Silo, or check the address.',
          );
        }
        final serverIdentity = await api.serverIdentity();
        final serverId = str(serverIdentity['server_id']);
        if (serverId.isEmpty) {
          throw const MediaServerUrlException('The server did not report an identity.');
        }
        var passwordLogin = true;
        try {
          passwordLogin = boolOr((await api.authProviders())['password_login'], true);
        } catch (_) {}
        return SiloServerProbe(
          baseUrl: candidate,
          serverId: serverId,
          serverVersion: str(info['server_version']),
          passwordLogin: passwordLogin,
        );
      } on MediaServerUrlException {
        rethrow;
      } on MediaServerHttpException catch (e) {
        if (e.statusCode == 404) {
          throw const MediaServerUrlException(
            'That address does not look like a Silo server (or it is too old for this app).',
          );
        }
        if (_isTlsFailure(e)) {
          throw MediaServerUrlException(
            'The server\'s certificate is not trusted, so the connection was refused. '
            'Fix the certificate or use the server\'s trusted address.',
          );
        }
        lastError = e;
      } catch (e) {
        lastError = e;
      } finally {
        api.close();
      }
    }
    throw MediaServerUrlException(
      'Can\'t reach a Silo server at that address. Check it and that the server is running.',
      display: lastError is MediaServerException ? (lastError).display : null,
    );
  }

  static bool _isTlsFailure(MediaServerHttpException e) {
    final m = e.message.toLowerCase();
    return m.contains('handshake') || m.contains('certificate') || m.contains('tls');
  }

  // ---------------------------------------------------------------- sign-in

  Future<SiloSignIn> signIn(SiloServerProbe server, {required String username, required String password}) async {
    final api = SiloApi(baseUrl: server.baseUrl, identity: identity);
    try {
      final SiloTokens tokens;
      try {
        tokens = await api.login(username: username.trim(), password: password);
      } on MediaServerAuthException {
        throw const MediaServerAuthException('That username or password is not right.', statusCode: 401);
      } on MediaServerHttpException catch (e) {
        if (e.statusCode == 429) {
          throw const MediaServerAuthException('Too many sign-in attempts. Wait a moment and try again.');
        }
        rethrow;
      }
      final account = await api.currentAccount();
      if (boolOr(account['password_change_required'])) {
        await api.logout();
        throw const MediaServerAuthException(
          'This account must change its password first. Sign in to the Silo web app, then try again.',
        );
      }
      final profiles = [
        for (final p in await api.profiles())
          if (str(p['id']).isNotEmpty)
            SiloProfileChoice(
              id: str(p['id']),
              name: str(p['name']).isEmpty ? 'Profile' : str(p['name']),
              hasPin: boolOr(p['has_pin']),
              isPrimary: boolOr(p['is_primary']),
              isChild: boolOr(p['is_child']),
              avatarUrl: strOrNull(p['avatar_url']) == null ? null : api.resolveServerUrl(str(p['avatar_url'])),
            ),
      ];
      profiles.sort((a, b) => a.isPrimary == b.isPrimary ? 0 : (a.isPrimary ? -1 : 1));
      return SiloSignIn(
        server: server,
        api: api,
        tokens: tokens,
        accountId: str(account['id']),
        userName: str(account['username']).isEmpty ? username.trim() : str(account['username']),
        role: str(account['role']),
        profiles: profiles,
      );
    } catch (_) {
      api.close();
      rethrow;
    }
  }

  /// Check a PIN. Returns the profile proof and its expiry, or `null` for a
  /// wrong PIN. A locked profile throws with the server's wait.
  Future<({String token, DateTime? expiresAt})?> verifyPin(SiloSignIn signIn, String profileId, String pin) async {
    try {
      final result = await signIn.api.verifyProfilePin(profileId, pin);
      if (!boolOr(result['valid'])) return null;
      final token = str(result['profile_token']);
      if (token.isEmpty) return null;
      return (token: token, expiresAt: DateTime.tryParse(str(result['expires_at'])));
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 429) {
        throw const MediaServerAuthException('Too many wrong PINs. This profile is locked for a few minutes.');
      }
      rethrow;
    }
  }

  SiloConnection buildConnection(
    SiloSignIn signIn, {
    required SiloProfileChoice profile,
    String? profileToken,
    DateTime? profileTokenExpiresAt,
  }) {
    final now = DateTime.now();
    // Read the tokens from the API: a refresh during profile listing may
    // have rotated them.
    final tokens = signIn.api.tokens ?? signIn.tokens;
    return SiloConnection(
      serverId: signIn.server.serverId,
      baseUrl: signIn.server.baseUrl,
      serverName: signIn.server.displayName,
      accountId: signIn.accountId,
      userName: signIn.userName,
      role: signIn.role,
      profileId: profile.id,
      profileName: profile.name,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      accessTokenExpiresAt: tokens.expiresAt,
      profileToken: profileToken,
      profileTokenExpiresAt: profileTokenExpiresAt,
      deviceId: identity.deviceId,
      createdAt: now,
      lastAuthenticatedAt: now,
    );
  }
}
