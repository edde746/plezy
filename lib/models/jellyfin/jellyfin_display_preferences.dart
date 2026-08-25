import '../../utils/json_utils.dart';

/// The MediaBrowser `DisplayPreferences` row Plezy owns.
///
/// `/Shows/NextUp` takes `EnableRewatching` per request and `UserConfiguration`
/// has no field for it, so this arbitrary per-user key/value store is the only
/// place a server-side answer can live. Verified on Jellyfin 10.11.10: the row
/// is keyed `(userId, displayPreferencesId, client)` with no device component,
/// so a value written on one device is returned to another with a different
/// token and session.
class JellyfinDisplayPreferences {
  const JellyfinDisplayPreferences._();

  /// Same id jellyfin-web and jellyfin-androidtv use for user-level settings.
  static const displayPreferencesId = 'usersettings';

  /// Plezy's own client namespace. Deliberately **not** `emby`, the row
  /// jellyfin-web writes and jellyfin-androidtv reads: `POST` replaces that
  /// row's whole custom set and resets any known scalar the body omits
  /// (measured — `skipForwardLength` 15000 reverted to 30000), so writing
  /// there would trash the first-party clients' skip lengths and home-section
  /// order on every save.
  static const client = 'Plezy';

  /// jellyfin-web's own key name for the same switch, so the value is
  /// recognisable to any client that goes looking — including jellyfin-web
  /// itself, should it ever stop passing `enableOnServer: false` and start
  /// syncing it (`src/scripts/settings/userSettings.js`).
  static const rewatchingInNextUpKey = 'enableRewatchingInNextUp';

  /// Read the switch out of a `DisplayPreferences` DTO. Null when the account
  /// has never set it, which is the server's own default (off).
  static bool? readRewatchingInNextUp(Object? dto) {
    final customPrefs = _customPrefs(dto);
    if (customPrefs == null) return null;
    final raw = customPrefs[rewatchingInNextUpKey];
    if (raw == null) return null;
    return flexibleBoolNullable(raw);
  }

  /// Copy [dto] with the switch set, ready to be posted back verbatim.
  ///
  /// The whole DTO round-trips because the write replaces the row: dropping
  /// any other key Plezy stores there, or any scalar the server round-trips,
  /// would silently reset it.
  static Map<String, dynamic> mergeRewatchingInNextUp(Object? dto, bool value) {
    if (dto is! Map<String, dynamic>) {
      throw const FormatException('MediaBrowser DisplayPreferences response is not an object');
    }
    final merged = Map<String, dynamic>.from(dto);
    final customPrefs = Map<String, dynamic>.from(_customPrefs(dto) ?? const {});
    // Values are strings on this API; `true`/`false` matches what jellyfin-web
    // writes for its own boolean prefs (`value.toString()`).
    customPrefs[rewatchingInNextUpKey] = value.toString();
    merged['CustomPrefs'] = customPrefs;
    return merged;
  }

  static Map<String, dynamic>? _customPrefs(Object? dto) {
    if (dto is! Map<String, dynamic>) return null;
    final customPrefs = dto['CustomPrefs'];
    return customPrefs is Map<String, dynamic> ? customPrefs : null;
  }
}
