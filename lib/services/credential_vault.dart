import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import 'base_shared_preferences_service.dart';

/// Encrypts credentials before they are persisted in Drift config/token
/// columns. The database no longer stores raw server tokens; registries
/// decrypt at their boundaries and rewrite legacy plaintext values on read.
///
/// Security model: the key is stored in SharedPreferences, so this is
/// obfuscation-at-rest against casual database inspection/export rather than
/// OS-backed Keychain/Keystore protection. Anyone with full access to both app
/// prefs and the database can recover the tokens.
class CredentialVault {
  CredentialVault._();

  static const String _keyPref = 'credential_vault_key_v1';
  static const String _prefix = 'enc:v1:';
  static final AesGcm _algorithm = AesGcm.with256bits();
  static Future<SecretKey>? _secretKey;

  static bool isProtected(String? value) => value != null && value.startsWith(_prefix);

  static Future<String> protect(String value) async {
    if (value.isEmpty || isProtected(value)) return value;
    final key = await _getSecretKey();
    final box = await _algorithm.encrypt(utf8.encode(value), secretKey: key);
    return '$_prefix${jsonEncode({'n': base64Encode(box.nonce), 'c': base64Encode(box.cipherText), 'm': base64Encode(box.mac.bytes)})}';
  }

  static Future<String> reveal(String value) async {
    if (!isProtected(value)) return value;
    final payload = jsonDecode(value.substring(_prefix.length)) as Map<String, dynamic>;
    final box = SecretBox(
      base64Decode(payload['c'] as String),
      nonce: base64Decode(payload['n'] as String),
      mac: Mac(base64Decode(payload['m'] as String)),
    );
    final clear = await _algorithm.decrypt(box, secretKey: await _getSecretKey());
    return utf8.decode(clear);
  }

  static Future<Map<String, Object?>> protectConnectionConfig(String kind, Map<String, Object?> config) async {
    final copy = Map<String, Object?>.from(config);
    final tokenKey = switch (kind) {
      'plex' => 'accountToken',
      'jellyfin' => 'accessToken',
      _ => null,
    };
    final token = tokenKey == null ? null : copy[tokenKey];
    if (token is String) copy[tokenKey!] = await protect(token);
    if (kind == 'plex') {
      copy['servers'] = await _protectPlexServers(copy['servers']);
    }
    return copy;
  }

  static Future<({Map<String, dynamic> config, bool migrated})> revealConnectionConfig(
    String kind,
    Map<String, dynamic> config,
  ) async {
    final copy = Map<String, dynamic>.from(config);
    final tokenKey = switch (kind) {
      'plex' => 'accountToken',
      'jellyfin' => 'accessToken',
      _ => null,
    };
    var migrated = false;
    final token = tokenKey == null ? null : copy[tokenKey];
    if (token is String && token.isNotEmpty) {
      migrated = !isProtected(token);
      copy[tokenKey!] = await reveal(token);
    }
    if (kind == 'plex') {
      final result = await _revealPlexServers(copy['servers']);
      copy['servers'] = result.servers;
      migrated = migrated || result.migrated;
    }
    return (config: copy, migrated: migrated);
  }

  static Future<Object?> _protectPlexServers(Object? rawServers) async {
    if (rawServers is! List) return rawServers;
    final servers = <Object?>[];
    for (final raw in rawServers) {
      if (raw is! Map) {
        servers.add(raw);
        continue;
      }
      final server = Map<String, Object?>.from(raw);
      final token = server['accessToken'];
      if (token is String) server['accessToken'] = await protect(token);
      servers.add(server);
    }
    return servers;
  }

  static Future<({Object? servers, bool migrated})> _revealPlexServers(Object? rawServers) async {
    if (rawServers is! List) return (servers: rawServers, migrated: false);
    var migrated = false;
    final servers = <Object?>[];
    for (final raw in rawServers) {
      if (raw is! Map) {
        servers.add(raw);
        continue;
      }
      final server = Map<String, dynamic>.from(raw);
      final token = server['accessToken'];
      if (token is String && token.isNotEmpty) {
        migrated = migrated || !isProtected(token);
        server['accessToken'] = await reveal(token);
      }
      servers.add(server);
    }
    return (servers: servers, migrated: migrated);
  }

  static Future<SecretKey> _getSecretKey() {
    return _secretKey ??= () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      final stored = prefs.getString(_keyPref);
      if (stored != null && stored.isNotEmpty) {
        return SecretKey(base64Decode(stored));
      }
      final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      await prefs.setString(_keyPref, base64Encode(bytes));
      return SecretKey(bytes);
    }();
  }
}
