import '../data/iso_3166_data.dart';

/// Resolves ISO 3166-1 alpha-2 country codes to display names, mirroring
/// [LanguageCodes] for the country dimension.
///
/// Catalog providers return production countries as bare codes (Plex
/// `Country`, Simkl `country`, AniList `countryOfOrigin`, TMDB
/// `origin_country`). Names are English-only for the same reason the ISO 639
/// catalog is: no localized catalog ships with the app.
class CountryCodes {
  /// Display name for [code], or the normalized code when it is not a known
  /// alpha-2 value. Returning the code is deliberate — `SU` is more useful to
  /// a reader than an empty chip.
  static String getDisplayName(String code) => getCountryName(code) ?? code.toUpperCase().trim();

  /// Display name for [code], or null when it is not a known alpha-2 value.
  static String? getCountryName(String code) {
    final normalized = code.toUpperCase().trim();
    if (normalized.length != 2) return null;
    return countryNames[normalized];
  }

  /// Alpha-2 code for a country [name], or null when unrecognized.
  ///
  /// Providers are inconsistent about which side of this mapping they send:
  /// Plex Discover returns `Country` tags as display names such as
  /// `United States of America`, while TMDB and AniList send codes. The index
  /// covers official ISO forms, the readable short forms, and colloquial
  /// names.
  static String? getCountryCode(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) return null;
    if (normalized.length == 2 && countryNames.containsKey(normalized.toUpperCase())) {
      return normalized.toUpperCase();
    }
    return countryCodesByName[normalized.toLowerCase()];
  }

  /// Best-effort alpha-2 for a provider value that may be either a code or a
  /// name. Falls back to the trimmed uppercase input so nothing is dropped.
  static String normalizeCode(String value) => getCountryCode(value) ?? value.toUpperCase().trim();
}
