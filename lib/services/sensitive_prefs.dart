/// Preference keys whose stored values are credentials.
///
/// `shared_preferences` is the most credential-dense artifact in a Plezy
/// installation. On the desktop platforms it is a single plaintext JSON file
/// next to the database, and it holds:
///
/// * [credentialVaultKeyPref] — the AES-256 key that `CredentialVault` uses to
///   protect every server/profile token stored in the Drift
///   `connections.config_json` and `profile_connections.user_token` columns.
///   Losing it orphans every one of those ciphertexts permanently.
/// * tracker sessions — `TrackerAccountStore` persists `TrackerSession.encode()`
///   verbatim, so raw OAuth `access_token`/`refresh_token` pairs for MAL,
///   AniList, Simkl and Trakt live here in plaintext.
/// * Seerr sessions — `SeerrSessionStore` persists a raw `connect.sid` cookie
///   alongside a vault-protected password.
/// * [legacyPlexTokenPref] — the pre-connection-registry Plex token slot. It is
///   drained by the connection migration but can linger on old installs.
///
/// Two subsystems consult this list, both added for #1732:
///
/// * the tolerant preference reads in `BaseSharedPreferencesService` must never
///   silently drop one of these keys — an unreadable credential has to surface
///   as an explicit repair prompt, not as a silent re-authentication;
/// * the corrupt-store repair in `PrefsRecovery` salvages exactly these keys
///   out of a damaged store before quarantining it.
///
/// Keep this list exhaustive. A credential slot that is missing here is
/// silently dropped on a type mismatch and silently lost on a repair.
///
/// This lives apart from `CredentialVault`, `TrackerAccountStore` and
/// `SeerrSessionStore` so `BaseSharedPreferencesService` can depend on it
/// without an import cycle.
library;

/// Key holding the base64 `CredentialVault` AES-256 key.
const String credentialVaultKeyPref = 'credential_vault_key_v1';

/// Legacy single-slot Plex token, superseded by the connection registry.
const String legacyPlexTokenPref = 'plex_token';

/// Unscoped base keys used by `TrackerAccountStore`, one per tracker service.
const List<String> trackerSessionBaseKeys = <String>[
  'mal_session',
  'anilist_session',
  'simkl_session',
  'trakt_session',
];

/// Unscoped base key used by `SeerrSessionStore`.
const String seerrSessionBaseKey = 'seerr_session';

/// Every credential slot that is profile-scoped through `profileScopedPrefsKey`,
/// so a stored key is either the bare base key or `user_{scope}_{baseKey}`.
const List<String> profileScopedCredentialBaseKeys = <String>[...trackerSessionBaseKeys, seerrSessionBaseKey];

final RegExp _profileScopedCredentialPattern = RegExp(
  '^(?:user_.+_)?(?:${profileScopedCredentialBaseKeys.join('|')})\$',
);

/// The unscoped base key [key] resolves to, or null when [key] is not a
/// profile-scoped credential slot.
String? profileScopedCredentialBaseKey(String key) {
  if (!_profileScopedCredentialPattern.hasMatch(key)) return null;
  for (final base in profileScopedCredentialBaseKeys) {
    if (key == base || key.endsWith('_$base')) return base;
  }
  return null;
}

/// Whether [key] is a profile-scoped or global tracker session slot.
bool isTrackerSessionPrefKey(String key) => trackerSessionBaseKeys.contains(profileScopedCredentialBaseKey(key));

/// Whether [key] is a profile-scoped or global Seerr session slot.
bool isSeerrSessionPrefKey(String key) => profileScopedCredentialBaseKey(key) == seerrSessionBaseKey;

/// Whether [key] holds a credential and must never be dropped or exported
/// without an explicit, informed user decision.
bool isSensitivePrefKey(String key) =>
    key == credentialVaultKeyPref || key == legacyPlexTokenPref || profileScopedCredentialBaseKey(key) != null;
