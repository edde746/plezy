import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../utils/app_logger.dart';
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

  /// Drops the memoized key so tests can simulate key loss/divergence.
  @visibleForTesting
  static void resetKeyForTesting() {
    _secretKey = null;
  }

  static bool isProtected(String? value) => value != null && value.startsWith(_prefix);

  static Future<String> protect(String value) async {
    if (value.isEmpty || isProtected(value)) return value;
    final key = await _getSecretKey();
    final box = await _algorithm.encrypt(utf8.encode(value), secretKey: key);
    return '$_prefix${jsonEncode({'n': base64Encode(box.nonce), 'c': base64Encode(box.cipherText), 'm': base64Encode(box.mac.bytes)})}';
  }

  /// Decrypts a protected value, or returns it unchanged when it isn't
  /// protected. Returns null when decryption fails — a failed MAC check
  /// (key/ciphertext divergence: restored backup, clobbered prefs, racing
  /// key generation) or a corrupt payload means the credential is *lost*,
  /// never a reason to crash; callers treat null as "re-acquire the token".
  static Future<String?> reveal(String value) async {
    if (!isProtected(value)) return value;
    try {
      final payload = jsonDecode(value.substring(_prefix.length)) as Map<String, dynamic>;
      final box = SecretBox(
        base64Decode(payload['c'] as String),
        nonce: base64Decode(payload['n'] as String),
        mac: Mac(base64Decode(payload['m'] as String)),
      );
      final clear = await _algorithm.decrypt(box, secretKey: await _getSecretKey());
      return utf8.decode(clear);
    } catch (e) {
      appLogger.w('CredentialVault: failed to decrypt stored credential, treating as lost', error: e);
      return null;
    }
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
      final revealed = await reveal(token);
      // An undecryptable token becomes the empty string — the shared
      // "no credential, re-auth" shape — and must not be rewritten back.
      migrated = revealed != null && !isProtected(token);
      copy[tokenKey!] = revealed ?? '';
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
        final revealed = await reveal(token);
        migrated = migrated || (revealed != null && !isProtected(token));
        server['accessToken'] = revealed ?? '';
      }
      servers.add(server);
    }
    return (servers: servers, migrated: migrated);
  }

  static Future<SecretKey> _getSecretKey() {
    return _secretKey ??= () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      // The cached snapshot can predate a key written by another isolate
      // (background downloader, first-run migration); generating "fresh" over
      // it would clobber the real key and orphan every stored ciphertext.
      // Reload before deciding, and after writing re-read and adopt whatever
      // actually landed so all isolates converge on a single key.
      try {
        await prefs.reloadCache();
      } catch (e) {
        appLogger.d('CredentialVault: prefs reload before key check failed', error: e);
      }
      final stored = prefs.getString(_keyPref);
      if (stored != null && stored.isNotEmpty) {
        return SecretKey(base64Decode(stored));
      }
      final bytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      await prefs.setString(_keyPref, base64Encode(bytes));
      try {
        await prefs.reloadCache();
        final settled = prefs.getString(_keyPref);
        if (settled != null && settled.isNotEmpty) {
          return SecretKey(base64Decode(settled));
        }
      } catch (e) {
        appLogger.d('CredentialVault: prefs re-read after key write failed', error: e);
      }
      return SecretKey(bytes);
    }();
  }
}
