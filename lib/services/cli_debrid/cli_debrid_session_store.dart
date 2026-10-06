import '../../models/cli_debrid/cli_debrid_session.dart';
import '../../profiles/profile.dart';
import '../base_shared_preferences_service.dart';
import '../credential_vault.dart';

/// Per-profile persistence for the cli_debrid session, mirroring
/// `SeerrSessionStore`'s `user_{uuid}_{baseKey}` scoping.
///
/// The API token ([CliDebridSession.apiToken]) is CredentialVault-protected
/// at the store boundary; a failed decrypt degrades to an empty token (the
/// session then behaves as disconnected until the user reconnects) rather
/// than dropping the whole session silently.
class CliDebridSessionStore {
  static const String _baseKey = 'cli_debrid_session';

  const CliDebridSessionStore();

  String _scopedKey(String userUuid) => profileScopedPrefsKey(userUuid, _baseKey);

  Future<CliDebridSession?> load(String userUuid) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final raw = readTolerantString(prefs, _scopedKey(userUuid));
    if (raw == null) return null;
    try {
      final session = CliDebridSession.decode(raw);
      if (session.apiToken.isEmpty) return session;
      return session.copyWith(apiToken: await CredentialVault.reveal(session.apiToken) ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String userUuid, CliDebridSession session) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final protected = session.apiToken.isEmpty
        ? session
        : session.copyWith(apiToken: await CredentialVault.protect(session.apiToken));
    await prefs.setString(_scopedKey(userUuid), protected.encode());
  }

  Future<void> clear(String userUuid) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.remove(_scopedKey(userUuid));
  }
}
