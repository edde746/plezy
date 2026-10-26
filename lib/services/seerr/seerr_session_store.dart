import '../../models/seerr/seerr_session.dart';
import '../../profiles/profile.dart';
import '../../utils/serial_future_queue.dart';
import '../base_shared_preferences_service.dart';
import '../credential_vault.dart';

/// Per-Plex-profile persistence for the Seerr session, mirroring
/// `TrackerAccountStore`'s `user_{uuid}_{baseKey}` scoping.
///
/// Protects the entire session, including its bearer cookie. Older sessions
/// with only an encrypted password migrate on read without a fresh sign-in.
class SeerrSessionStore {
  static const String _baseKey = 'seerr_session';

  // Shared across profile-keyed provider/store lifetimes. Enqueue the entire
  // operation before any preferences/vault await so a new load or clear cannot
  // overtake an old provider's still-encrypting save.
  static final SerialFutureQueue _persistence = SerialFutureQueue();

  const SeerrSessionStore();

  String _scopedKey(String userUuid) => profileScopedPrefsKey(userUuid, _baseKey);

  Future<SeerrSession?> load(String userUuid) => _persistence.run(() async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    // Outside the try below on purpose: an unreadable credential must
    // reach the repair prompt, not be swallowed as 'no session'.
    final raw = readTolerantString(prefs, _scopedKey(userUuid));
    if (raw == null) return null;
    final clear = await CredentialVault.reveal(raw);
    if (clear == null) return null;
    final SeerrSession decoded;
    try {
      decoded = SeerrSession.decode(clear);
    } catch (_) {
      return null;
    }
    final session = decoded.secret.isEmpty
        ? decoded
        : decoded.copyWith(secret: await CredentialVault.reveal(decoded.secret) ?? '');
    if (CredentialVault.needsMigration(raw)) {
      await prefs.setString(_scopedKey(userUuid), await CredentialVault.protect(session.encode()));
    }
    return session;
  });

  Future<void> save(String userUuid, SeerrSession session) => _persistence.run(() async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.setString(_scopedKey(userUuid), await CredentialVault.protect(session.encode()));
  });

  Future<void> clear(String userUuid) => _persistence.run(() async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.remove(_scopedKey(userUuid));
  });
}
