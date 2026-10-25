import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/companion_remote/remote_pairing_store.dart';
import 'package:plezy/services/credential_vault.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(resetSharedPreferencesForTest);

  test('host capabilities are stable, encrypted, profile scoped and revocable', () async {
    final first = await RemotePairingStore.hostCode('profile-a');
    expect(first, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(await RemotePairingStore.hostCode('profile-a'), first);
    expect(await RemotePairingStore.hostCode('profile-b'), isNot(first));
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final stored = prefs.keys.where((key) => key.startsWith('companion_remote_pairing_'));
    expect(stored, hasLength(2));
    for (final key in stored) {
      expect(prefs.getString(key), startsWith('enc:v2:'));
      expect(prefs.getString(key), isNot(contains(first)));
    }
    final rotated = await RemotePairingStore.hostCode('profile-a', rotate: true);
    expect(rotated, isNot(first));
    CredentialVault.invalidateCache();
    expect(await RemotePairingStore.hostCode('profile-a'), rotated);
  });

  test('remembered remotes are isolated by profile and peer', () async {
    const code = '0123456789abcdef0123456789abcdef';
    expect(await RemotePairingStore.remoteCode('p1', 'host1'), isNull);
    await RemotePairingStore.rememberRemote('p1', 'host1', code);
    expect(await RemotePairingStore.remoteCode('p1', 'host1'), code);
    expect(await RemotePairingStore.remoteCode('p2', 'host1'), isNull);
    expect(await RemotePairingStore.remoteCode('p1', 'host2'), isNull);
    expect(RemotePairingStore.normalizeCode(RemotePairingStore.displayCode(code).toUpperCase()), code);
    expect(RemotePairingStore.normalizeCode('123456'), isNull);
  });
}
