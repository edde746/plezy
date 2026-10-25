import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/credential_vault.dart';
import 'package:plezy/services/seerr/seerr_session_store.dart';
import 'package:plezy/services/trackers/tracker_account_store.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/tracker_session.dart';

import '../test_helpers/prefs.dart';

class _Keychain extends TestFlutterSecureStoragePlatform {
  _Keychain() : super({});
  bool locked = false;
  bool failWrite = false;

  @override
  Future<String?> read({required String key, required Map<String, String> options}) async {
    if (locked) throw PlatformException(code: 'KeyringLocked');
    return super.read(key: key, options: options);
  }

  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) async {
    if (locked || failWrite) throw PlatformException(code: 'KeyringLocked');
    await super.write(key: key, value: value, options: options);
  }
}

Future<String> _legacyCredential() async {
  final bytes = List.generate(32, (index) => index);
  final prefs = await BaseSharedPreferencesService.sharedCache();
  await prefs.setString('credential_vault_key_v1', base64Encode(bytes));
  final box = await AesGcm.with256bits().encrypt(utf8.encode('legacy-token'), secretKey: SecretKey(bytes));
  return 'enc:v1:${jsonEncode({'n': base64Encode(box.nonce), 'c': base64Encode(box.cipherText), 'm': base64Encode(box.mac.bytes)})}';
}

void main() {
  late _Keychain keychain;
  setUp(() {
    resetSharedPreferencesForTest();
    keychain = _Keychain();
    FlutterSecureStoragePlatform.instance = keychain;
  });

  test('legacy key is removed only after verified OS persistence and remains readable after restart', () async {
    final legacy = await _legacyCredential();
    expect(await CredentialVault.reveal(legacy), 'legacy-token');
    final prefs = await BaseSharedPreferencesService.sharedCache();
    expect(prefs.getString('credential_vault_key_v1'), isNull);
    expect(keychain.data.keys, contains('legacy-v1-key-id'));
    CredentialVault.invalidateCache();
    expect(await CredentialVault.reveal(legacy), 'legacy-token');
    final migrated = await CredentialVault.protect(legacy);
    expect(migrated, startsWith('enc:v2:'));
    expect(await CredentialVault.reveal(migrated), 'legacy-token');
  });

  test('failed OS migration preserves legacy data and retries after unlock', () async {
    final legacy = await _legacyCredential();
    keychain.failWrite = true;
    await expectLater(CredentialVault.reveal(legacy), throwsA(isA<PlatformException>()));
    final prefs = await BaseSharedPreferencesService.sharedCache();
    expect(prefs.getString('credential_vault_key_v1'), isNotNull);
    keychain.failWrite = false;
    expect(await CredentialVault.reveal(legacy), 'legacy-token');
  });

  test('locked OS store is a retriable error and never an empty credential', () async {
    final value = await CredentialVault.protect('session-token');
    CredentialVault.invalidateCache();
    keychain.locked = true;
    await expectLater(CredentialVault.reveal(value), throwsA(isA<PlatformException>()));
    keychain.locked = false;
    expect(await CredentialVault.reveal(value), 'session-token');
  });

  test('ciphertext retains its own key when another writer chooses a new active key', () async {
    final first = await CredentialVault.protect('first');
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.remove('credential_vault_active_key_id_v2');
    CredentialVault.invalidateCache();
    final second = await CredentialVault.protect('second');
    CredentialVault.invalidateCache();
    expect(await CredentialVault.reveal(first), 'first');
    expect(await CredentialVault.reveal(second), 'second');
    expect(keychain.data.keys.where((key) => key.startsWith('v2-')), hasLength(2));
  });

  test('tracker access and refresh tokens migrate together without reauthentication', () async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final session = TrackerSession(
      accessToken: 'tracker-access',
      refreshToken: 'tracker-refresh',
      expiresAt: 1000,
      createdAt: 1,
    );
    await prefs.setString('trakt_session', session.encode());
    final loaded = await trackerAccountStore(TrackerService.trakt).load('');
    expect(loaded?.accessToken, 'tracker-access');
    expect(loaded?.refreshToken, 'tracker-refresh');
    final stored = prefs.getString('trakt_session')!;
    expect(stored, startsWith('enc:v2:'));
    expect(stored, isNot(contains('tracker-access')));
    expect(stored, isNot(contains('tracker-refresh')));
  });

  test('Seerr migrates both its session cookie and legacy protected password', () async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final oldPassword = await _legacyCredential();
    final session = SeerrSession(
      baseUrl: 'https://seerr.test',
      method: SeerrAuthMethod.local,
      identifier: 'user',
      secret: oldPassword,
      cookie: 'session-cookie',
      userId: 1,
      permissions: 0,
      displayName: 'User',
      instanceLabel: 'Server',
      createdAt: 1,
    );
    await prefs.setString('seerr_session', session.encode());
    final loaded = await const SeerrSessionStore().load('');
    expect(loaded?.cookie, 'session-cookie');
    expect(loaded?.secret, 'legacy-token');
    expect(prefs.getString('seerr_session'), startsWith('enc:v2:'));
    expect(prefs.getString('seerr_session'), isNot(contains('session-cookie')));
    CredentialVault.invalidateCache();
    expect((await const SeerrSessionStore().load(''))?.secret, 'legacy-token');
  });
}
