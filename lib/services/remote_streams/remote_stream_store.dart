import 'package:shared_preferences/shared_preferences.dart';

import '../../profiles/profile.dart';
import '../base_shared_preferences_service.dart';
import '../credential_vault.dart';
import 'remote_stream_models.dart';

enum RemoteStreamStoreFailure { unreadable }

class RemoteStreamStoreException implements Exception {
  const RemoteStreamStoreException(this.reason);
  final RemoteStreamStoreFailure reason;
}

/// Profile-scoped store for add-on endpoints and provider credentials. The
/// complete record is encrypted before it enters SharedPreferences so signed
/// manifest URLs are protected alongside API tokens.
class RemoteStreamStore {
  static const _key = 'remote_streaming_v1';

  static String _scopedKey(String profileId) => profileScopedPrefsKey(profileId, _key);

  static Future<RemoteStreamSnapshot> load(String profileId) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final raw = prefs.getString(_scopedKey(profileId));
    if (raw == null || raw.isEmpty) return const RemoteStreamSnapshot();
    final clear = await CredentialVault.reveal(raw);
    if (clear == null) throw const RemoteStreamStoreException(RemoteStreamStoreFailure.unreadable);
    final RemoteStreamSnapshot snapshot;
    try {
      snapshot = RemoteStreamSnapshot.decode(clear);
    } on Object {
      // Keep the original ciphertext intact. Replacing it with an empty
      // snapshot would silently discard every saved account and add-on URL.
      throw const RemoteStreamStoreException(RemoteStreamStoreFailure.unreadable);
    }
    if (CredentialVault.needsMigration(raw)) await _write(prefs, profileId, snapshot);
    return snapshot;
  }

  static Future<void> save(String profileId, RemoteStreamSnapshot snapshot) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await _write(prefs, profileId, snapshot);
  }

  static Future<void> _write(SharedPreferencesWithCache prefs, String profileId, RemoteStreamSnapshot snapshot) async {
    await prefs.setString(_scopedKey(profileId), await CredentialVault.protect(snapshot.encode()));
  }
}
