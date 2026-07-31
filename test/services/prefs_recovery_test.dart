import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/prefs_recovery.dart';
import 'package:plezy/services/sensitive_prefs.dart';
import 'package:plezy/utils/log_redaction_manager.dart';

/// A 32-byte key, the only length `AesGcm.with256bits()` accepts.
final String _validVaultKey = base64Encode(List<int>.generate(32, (i) => i));

String _traktSession({String access = 'trakt-access-token', String refresh = 'trakt-refresh-token'}) => jsonEncode({
  'access_token': access,
  'refresh_token': refresh,
  'expires_at': 4102444800,
  'username': 'someone',
  'scope': 'public',
  'created_at': 1700000000,
});

String _seerrSession({String cookie = 'seerr-connect-sid'}) => jsonEncode({
  'base_url': 'https://seerr.example.com',
  'method': 'local',
  'identifier': 'user@example.com',
  'secret': 'enc:v1:{"c":"AA==","n":"AA==","m":"AA=="}',
  'cookie': cookie,
  'user_id': 1,
  'permissions': 2,
  'display_name': 'Someone',
  'instance_label': 'Seerr',
  'created_at': 1700000000,
});

void main() {
  late Directory tempDir;
  late File store;

  setUp(() async {
    LogRedactionManager.clearTrackedValues();
    tempDir = await Directory.systemTemp.createTemp('plezy-prefs-recovery');
    store = File('${tempDir.path}/shared_preferences.json');
  });

  tearDown(() async {
    LogRedactionManager.clearTrackedValues();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('salvage', () {
    test('recovers a vault key from a truncated document', () {
      // Exactly the #1732 shape: a non-atomic write cut short, so the object
      // never closes and `json.decode` cannot help.
      final raw = '{"theme":"dark","$credentialVaultKeyPref":"$_validVaultKey","library_den';

      expect(PrefsRecovery.salvage(raw).vaultKey, _validVaultKey);
    });

    test('rejects a vault key that is not 32 bytes', () {
      final raw = jsonEncode({credentialVaultKeyPref: base64Encode(List<int>.filled(16, 7))});

      final salvaged = PrefsRecovery.salvage(raw);

      // A short key would make every later decrypt throw, which is worse than
      // reporting the key as lost.
      expect(salvaged.vaultKey, isNull);
      expect(salvaged.losses, 1);
    });

    test('recovers profile-scoped tracker and Seerr sessions', () {
      final raw = jsonEncode({
        'user_abc_trakt_session': _traktSession(),
        'user_abc_seerr_session': _seerrSession(),
        'theme': 'dark',
      });

      final salvaged = PrefsRecovery.salvage(raw);

      expect(salvaged.sessions.keys, containsAll(['user_abc_trakt_session', 'user_abc_seerr_session']));
      expect(salvaged.losses, 0);
    });

    test('counts an undecodable session as lost rather than reseeding garbage', () {
      final salvaged = PrefsRecovery.salvage(jsonEncode({'trakt_session': '{"access_token":"only-half'}));

      expect(salvaged.sessions, isEmpty);
      expect(salvaged.losses, 1);
    });

    test('normalises a legacy flutter-prefixed key onto the async key', () {
      // A store damaged mid-migration holds credentials only under the legacy
      // spelling, because `SharedPreferences.getInstance()` runs first.
      final raw = jsonEncode({
        '${legacyKeyPrefix}trakt_session': _traktSession(),
        '$legacyKeyPrefix$credentialVaultKeyPref': _validVaultKey,
      });

      final salvaged = PrefsRecovery.salvage(raw);

      expect(salvaged.vaultKey, _validVaultKey);
      expect(salvaged.sessions.keys, ['trakt_session']);
    });

    test('prefers the unprefixed entry over the legacy one regardless of order', () {
      final documents = [
        jsonEncode({
          '${legacyKeyPrefix}trakt_session': _traktSession(access: 'legacy-access'),
          'trakt_session': _traktSession(access: 'current-access'),
        }),
        jsonEncode({
          'trakt_session': _traktSession(access: 'current-access'),
          '${legacyKeyPrefix}trakt_session': _traktSession(access: 'legacy-access'),
        }),
      ];

      for (final raw in documents) {
        expect(PrefsRecovery.salvage(raw).sessions['trakt_session'], contains('current-access'));
      }
    });

    test('registers each secret individually, not just the whole payload', () {
      final raw = jsonEncode({
        'trakt_session': _traktSession(access: 'aaa-access-secret', refresh: 'bbb-refresh-secret'),
        'seerr_session': _seerrSession(cookie: 'ccc-cookie-secret'),
        legacyPlexTokenPref: 'ddd-plex-secret',
      });

      PrefsRecovery.salvage(raw);

      // A bare token quoted on its own must redact too; registering only the
      // encoded blob would leave these exposed.
      for (final secret in ['aaa-access-secret', 'bbb-refresh-secret', 'ccc-cookie-secret', 'ddd-plex-secret']) {
        expect(LogRedactionManager.redact('value=$secret'), isNot(contains(secret)), reason: secret);
      }
    });

    test('registers the salvaged vault key for redaction', () {
      PrefsRecovery.salvage(jsonEncode({credentialVaultKeyPref: _validVaultKey}));

      expect(LogRedactionManager.redact('key=$_validVaultKey'), isNot(contains(_validVaultKey)));
    });
  });

  group('assertStoreReadable', () {
    test('accepts a well-formed document', () async {
      await store.writeAsString(
        jsonEncode({
          'theme': 'dark',
          'count': 3,
          'list': <String>['a'],
        }),
      );

      await expectLater(PrefsRecovery.assertStoreReadable(storeFileOverride: store), completes);
    });

    test('accepts a missing or empty store', () async {
      await expectLater(PrefsRecovery.assertStoreReadable(storeFileOverride: store), completes);

      await store.writeAsString('');
      await expectLater(PrefsRecovery.assertStoreReadable(storeFileOverride: store), completes);
    });

    test('rejects a truncated document', () async {
      await store.writeAsString('{"theme":"dark"');

      await expectLater(
        PrefsRecovery.assertStoreReadable(storeFileOverride: store),
        throwsA(isA<CorruptPreferenceStoreException>()),
      );
    });

    test('rejects a null value before the plugin can memoise it', () async {
      // Valid JSON, so `json.decode` succeeds and the plugin caches the lazy
      // cast; the TypeError only lands later in `Map<String, Object>.from`.
      // Detecting it after that point would leave the bad document memoised
      // and a repair unable to reopen onto a clean store.
      await store.writeAsString('{"theme":"dark","broken":null}');

      await expectLater(
        PrefsRecovery.assertStoreReadable(storeFileOverride: store),
        throwsA(isA<CorruptPreferenceStoreException>()),
      );
    });

    test('rejects a document that is not a JSON object', () async {
      await store.writeAsString('[1,2,3]');

      await expectLater(
        PrefsRecovery.assertStoreReadable(storeFileOverride: store),
        throwsA(isA<CorruptPreferenceStoreException>()),
      );
    });
  });

  group('quarantine', () {
    test('moves the damaged file aside and keeps its bytes', () async {
      final raw = '{"$credentialVaultKeyPref":"$_validVaultKey","trunc';
      await store.writeAsString(raw);

      final result = await PrefsRecovery.quarantine(storeFileOverride: store);

      expect(await store.exists(), isFalse);
      expect(result.backupPath, isNotNull);
      expect(await File(result.backupPath!).readAsString(), raw);
      expect(result.salvaged.vaultKey, _validVaultKey);
    });

    test('deleteBackup removes the credential-bearing copy', () async {
      await store.writeAsString('{"broken');
      final result = await PrefsRecovery.quarantine(storeFileOverride: store);

      await PrefsRecovery.deleteBackup(result.backupPath!);

      expect(await File(result.backupPath!).exists(), isFalse);
    });
  });

  group('backupStore', () {
    test('copies without disturbing the live store', () async {
      await store.writeAsString('{"theme":"dark"}');

      final path = await PrefsRecovery.backupStore(storeFileOverride: store);

      expect(await store.exists(), isTrue);
      expect(await File(path!).readAsString(), '{"theme":"dark"}');
    });
  });

  group('seedStore', () {
    test('writes only the salvaged credentials and leaves no staging file', () async {
      final salvaged = PrefsRecovery.salvage(
        jsonEncode({credentialVaultKeyPref: _validVaultKey, 'trakt_session': _traktSession(), 'theme': 'dark'}),
      );

      expect(await PrefsRecovery.seedStore(salvaged, storeFileOverride: store), isTrue);

      final written = jsonDecode(await store.readAsString()) as Map<String, dynamic>;
      expect(written[credentialVaultKeyPref], _validVaultKey);
      expect(written.containsKey('trakt_session'), isTrue);
      // Ordinary settings are not salvaged, so a reseed must not invent them.
      expect(written.containsKey('theme'), isFalse);
      expect(await File('${store.path}.seed').exists(), isFalse);
    });

    test('the seeded store passes the preflight it will face on restart', () async {
      final salvaged = PrefsRecovery.salvage(jsonEncode({credentialVaultKeyPref: _validVaultKey}));
      await PrefsRecovery.seedStore(salvaged, storeFileOverride: store);

      await expectLater(PrefsRecovery.assertStoreReadable(storeFileOverride: store), completes);
    });

    test('reports false when there is nothing to seed', () async {
      expect(await PrefsRecovery.seedStore(SalvagedPrefsCredentials.empty, storeFileOverride: store), isFalse);
      expect(await store.exists(), isFalse);
    });
  });

  group('CorruptPreferenceStoreException', () {
    test('never renders the document the parser choked on', () {
      // `FormatException.toString()` prints an excerpt of `source` around
      // `offset`. During startup that source is the credential store.
      final source = '{"$credentialVaultKeyPref":"$_validVaultKey","truncated';
      late final FormatException raw;
      try {
        jsonDecode(source);
        fail('expected a FormatException');
      } on FormatException catch (error) {
        raw = error;
      }
      expect(raw.toString(), contains(_validVaultKey), reason: 'precondition: the raw error does leak the key');

      final wrapped = CorruptPreferenceStoreException(raw, StackTrace.current);

      expect(wrapped.toString(), isNot(contains(_validVaultKey)));
      expect(wrapped.toString(), contains('FormatException'));
      expect(wrapped.causeType, 'FormatException');
    });
  });

  group('UnreadableSensitivePreferenceException', () {
    test('names the key but carries no value', () {
      final exception = UnreadableSensitivePreferenceException(credentialVaultKeyPref, TypeError());

      expect(exception.key, credentialVaultKeyPref);
      expect(exception.toString(), contains(credentialVaultKeyPref));
    });
  });

  group('sensitive key registry', () {
    test('covers every credential slot, scoped and unscoped', () {
      for (final key in [
        credentialVaultKeyPref,
        legacyPlexTokenPref,
        'trakt_session',
        'user_abc_mal_session',
        'user_abc_anilist_session',
        'user_abc_simkl_session',
        'seerr_session',
        'user_abc_seerr_session',
      ]) {
        expect(isSensitivePrefKey(key), isTrue, reason: key);
      }
    });

    test('does not claim ordinary preferences', () {
      for (final key in ['theme', 'library_density', 'custom_relay_url', 'session_count']) {
        expect(isSensitivePrefKey(key), isFalse, reason: key);
      }
    });
  });
}
