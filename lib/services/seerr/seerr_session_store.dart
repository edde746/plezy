import '../../models/seerr/seerr_session.dart';
import '../../profiles/profile.dart';
import '../base_shared_preferences_service.dart';
import '../credential_vault.dart';

/// Per-Plex-profile persistence for the Seerr session, mirroring
/// `TrackerAccountStore`'s `user_{uuid}_{baseKey}` scoping.
///
/// The password ([SeerrSession.secret]) is CredentialVault-protected at the
/// store boundary; a failed decrypt degrades to an empty secret (the session
/// keeps working until its cookie expires) rather than dropping the session.
class SeerrSessionStore {
  static const String _baseKey = 'seerr_session';

  const SeerrSessionStore();

  String _scopedKey(String userUuid) => profileScopedPrefsKey(userUuid, _baseKey);

  Future<SeerrSession?> load(String userUuid) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final raw = prefs.getString(_scopedKey(userUuid));
    if (raw == null) return null;
    try {
      final session = SeerrSession.decode(raw);
      if (session.secret.isEmpty) return session;
      return session.copyWith(secret: await CredentialVault.reveal(session.secret) ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String userUuid, SeerrSession session) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final protected = session.secret.isEmpty
        ? session
        : session.copyWith(secret: await CredentialVault.protect(session.secret));
    await prefs.setString(_scopedKey(userUuid), protected.encode());
  }

  Future<void> clear(String userUuid) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.remove(_scopedKey(userUuid));
  }
}
