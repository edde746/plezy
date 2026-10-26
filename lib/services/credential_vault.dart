import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../utils/app_logger.dart';
import 'base_shared_preferences_service.dart';
import 'credential_key_store.dart';
import 'sensitive_prefs.dart';

/// Encrypts credentials before they are persisted in Drift config/token
/// columns. The database no longer stores raw server tokens; registries
/// decrypt at their boundaries and rewrite legacy plaintext values on read.
///
/// Keys live in the OS credential store. Preferences contain only opaque key
/// identifiers. Each v2 ciphertext names its key, so concurrent first writes
/// from different isolates cannot orphan each other's credentials. Existing
/// v1 keys are migrated with write/read-back verification before the plaintext
/// copy is removed; v1 ciphertext remains readable during lazy migration.
class CredentialVault {
  CredentialVault._();

  static const String _keyPref = credentialVaultKeyPref;
  static const String _legacyPrefix = 'enc:v1:';
  static const String _prefix = 'enc:v2:';
  static const String _activeKeyPref = 'credential_vault_active_key_id_v2';
  static const String _legacyKeySelector = 'legacy-v1-key-id';
  static final AesGcm _algorithm = AesGcm.with256bits();
  static final Map<String, Future<String?>> _decryptionCache = {};
  static Future<({String id, SecretKey key})>? _secretKey;
  static int _cacheGeneration = 0;

  /// Invalidates the memoized key and decrypted credentials after the
  /// underlying preference store is repaired or replaced.
  static void invalidateCache() {
    _cacheGeneration++;
    _secretKey = null;
    _decryptionCache.clear();
  }

  /// Drops memoized vault state so tests can simulate key loss/divergence.
  @visibleForTesting
  static void resetKeyForTesting() {
    invalidateCache();
  }

  static bool isProtected(String? value) =>
      value != null && (value.startsWith(_prefix) || value.startsWith(_legacyPrefix));

  static bool needsMigration(String value) => !value.startsWith(_prefix);

  static Future<String> protect(String value) async {
    if (value.isEmpty || value.startsWith(_prefix)) return value;
    if (value.startsWith(_legacyPrefix)) {
      final revealed = await reveal(value);
      if (revealed == null) throw StateError('Cannot migrate an unreadable credential');
      return protect(revealed);
    }
    while (true) {
      final generation = _cacheGeneration;
      final key = await _getSecretKey();
      final box = await _algorithm.encrypt(utf8.encode(value), secretKey: key.key);
      if (generation != _cacheGeneration) continue;

      final payload = {
        'k': key.id,
        'n': base64Encode(box.nonce),
        'c': base64Encode(box.cipherText),
        'm': base64Encode(box.mac.bytes),
      };
      final ciphertext = '$_prefix${jsonEncode(payload)}';
      _decryptionCache[ciphertext] = Future.value(value);
      return ciphertext;
    }
  }

  /// Decrypts a protected value, or returns it unchanged when it isn't
  /// protected. Returns null when decryption fails — a failed MAC check
  /// (key/ciphertext divergence: restored backup, clobbered prefs, racing
  /// key generation) or a corrupt payload means the credential is *lost*,
  /// never a reason to crash; callers treat null as "re-acquire the token".
  static Future<String?> reveal(String value) async {
    if (!isProtected(value)) return value;
    while (true) {
      final generation = _cacheGeneration;
      final pending = _decryptionCache.putIfAbsent(value, () => _decrypt(value, generation));
      final String? clear;
      try {
        clear = await pending;
      } catch (_) {
        // A locked/unavailable keychain is not a lost token. Do not cache a
        // transient platform failure or rewrite the credential as empty.
        if (identical(_decryptionCache[value], pending)) _decryptionCache.remove(value)?.ignore();
        rethrow;
      }
      if (generation == _cacheGeneration) return clear;
    }
  }

  static Future<String?> _decrypt(String value, int generation) async {
    final legacy = value.startsWith(_legacyPrefix);
    late final Map<String, dynamic> payload;
    late final SecretBox box;
    try {
      payload = jsonDecode(value.substring(legacy ? _legacyPrefix.length : _prefix.length)) as Map<String, dynamic>;
      box = SecretBox(
        base64Decode(payload['c'] as String),
        nonce: base64Decode(payload['n'] as String),
        mac: Mac(base64Decode(payload['m'] as String)),
      );
    } catch (_) {
      return null;
    }
    // Keep platform I/O outside the corruption/MAC catch. A temporary keychain
    // outage must propagate to the retry path rather than sign the user out.
    final keyId = payload['k'];
    if (!legacy && (keyId is! String || !_validKeyId(keyId))) return null;
    final key = legacy ? await _getLegacyKey() : await _readKey(keyId as String);
    if (key == null) return null;
    try {
      final clear = await _algorithm.decrypt(box, secretKey: key);
      return utf8.decode(clear);
    } catch (e) {
      if (generation != _cacheGeneration) return null;
      appLogger.w('CredentialVault: failed to decrypt stored credential, treating as lost', error: e);
      return null;
    }
  }

  static Future<Map<String, Object?>> protectConnectionConfig(String kind, Map<String, Object?> config) async {
    final copy = Map<String, Object?>.from(config);
    final tokenKey = _tokenKeyForKind(kind);
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
    final tokenKey = _tokenKeyForKind(kind);
    var migrated = false;
    final token = tokenKey == null ? null : copy[tokenKey];
    if (token is String && token.isNotEmpty) {
      final revealed = await reveal(token);
      // An undecryptable token becomes the empty string — the shared
      // "no credential, re-auth" shape — and must not be rewritten back.
      migrated = revealed != null && needsMigration(token);
      copy[tokenKey!] = revealed ?? '';
    }
    if (kind == 'plex') {
      final result = await _revealPlexServers(copy['servers']);
      copy['servers'] = result.servers;
      migrated = migrated || result.migrated;
    }
    return (config: copy, migrated: migrated);
  }

  /// Config key holding the long-lived credential for a `connections.kind`
  /// value. Returning `null` means "nothing to encrypt", so every new kind MUST
  /// be listed here — an omission silently persists the token in plaintext.
  static String? _tokenKeyForKind(String kind) => switch (kind) {
    'plex' => 'accountToken',
    'jellyfin' || 'emby' => 'accessToken',
    _ => null,
  };

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
        migrated = migrated || (revealed != null && needsMigration(token));
        server['accessToken'] = revealed ?? '';
      }
      servers.add(server);
    }
    return (servers: servers, migrated: migrated);
  }

  static bool _validKeyId(String id) => RegExp(r'^(?:v2-[0-9a-f]{32}|v1-[0-9a-f]{64})$').hasMatch(id);

  static Future<SecretKey?> _readKey(String id) async {
    if (!_validKeyId(id)) throw const FormatException('Invalid credential key identifier');
    final encoded = await CredentialKeyStore.read(id);
    if (encoded == null) return null;
    final bytes = base64Decode(encoded);
    if (bytes.length != 32) throw const FormatException('Invalid credential key');
    return SecretKey(bytes);
  }

  static Future<void> _writeVerifiedKey(String id, String encoded) async {
    await CredentialKeyStore.write(id, encoded);
    if (await CredentialKeyStore.read(id) != encoded) {
      throw StateError('The OS credential store did not retain the key');
    }
  }

  static Future<SecretKey?> _getLegacyKey() async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.reloadCache();
    final legacy = readTolerantString(prefs, _keyPref);
    if (legacy != null && legacy.isNotEmpty) {
      final bytes = base64Decode(legacy);
      if (bytes.length != 32) throw const FormatException('Invalid legacy credential key');
      final id = 'v1-${crypto.sha256.convert(bytes)}';
      // Content-addressing makes concurrent migrations of the same key
      // idempotent. Never overwrite a different key under a shared name.
      await _writeVerifiedKey(id, legacy);
      await _writeVerifiedKey(_legacyKeySelector, id);
      await prefs.remove(_keyPref);
      return SecretKey(bytes);
    }
    final id = await CredentialKeyStore.read(_legacyKeySelector);
    return id == null ? null : _readKey(id);
  }

  static Future<({String id, SecretKey key})> _getSecretKey() {
    final existing = _secretKey;
    if (existing != null) return existing;
    late final Future<({String id, SecretKey key})> loading;
    loading =
        () async {
          final prefs = await BaseSharedPreferencesService.sharedCache();
          await prefs.reloadCache();
          // Also retire the legacy plaintext key when the first operation is a
          // write, without needing to enumerate/rewrite the whole database first.
          await _getLegacyKey();
          final activeId = readTolerantString(prefs, _activeKeyPref);
          if (activeId != null) {
            final key = await _readKey(activeId);
            if (key != null) return (id: activeId, key: key);
          }
          final random = Random.secure();
          final id = 'v2-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
          final bytes = List<int>.generate(32, (_) => random.nextInt(256));
          await _writeVerifiedKey(id, base64Encode(bytes));
          await prefs.setString(_activeKeyPref, id);
          // Another isolate may choose another active ID; both keys survive and
          // each ciphertext records the exact key that encrypted it.
          return (id: id, key: SecretKey(bytes));
        }().catchError((Object error, StackTrace stackTrace) {
          if (identical(_secretKey, loading)) _secretKey = null;
          Error.throwWithStackTrace(error, stackTrace);
        });
    _secretKey = loading;
    return loading;
  }
}
