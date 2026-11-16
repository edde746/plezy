import '../data/iso_639_data.dart';

/// Helper class for converting between ISO 639-1 (2-letter) and ISO 639-2 (3-letter) language codes
class LanguageCodes {
  static LanguageEntry? _resolve(String code) {
    final normalized = code.toLowerCase().trim();
    final entry = languageEntries[normalized];
    if (entry != null) return entry;
    final key = code2ToCode1[normalized] ?? code2BToCode1[normalized];
    return key != null ? languageEntries[key] : null;
  }

  /// Returns all code variations (639-1, 639-2, 639-2/B) for a given language code.
  static List<String> getVariations(String languageCode) {
    final normalized = languageCode.toLowerCase().trim();
    final variations = <String>{normalized};

    final entry = _resolve(languageCode);
    if (entry != null) {
      variations.add(entry.code1);
      variations.add(entry.code2);
      if (entry.code2B != null) variations.add(entry.code2B!);
    }

    return variations.toList();
  }

  static String? getIso6391Code(String code) {
    final normalized = code.toLowerCase().trim().split(RegExp('[-_]')).first;
    if (normalized.isEmpty) return null;
    return _resolve(normalized)?.code1;
  }

  /// Get a display name for a language/locale code.
  /// Handles plain codes ("en" → "English") and locale codes ("en-US" → "English",
  /// "en-AU" → "English (Australia)").
  static String getDisplayName(String code) {
    if (code.isEmpty) return code;

    if (!code.contains('-')) {
      return getLanguageName(code) ?? code;
    }

    final parts = code.split('-');
    final langName = getLanguageName(parts.first) ?? parts.first;
    final region = parts.length > 1 ? _regionNames[parts[1]] : null;
    return region != null ? '$langName ($region)' : langName;
  }

  static const _regionNames = <String, String>{
    'AU': 'Australia',
    'BR': 'Brazil',
    'CA': 'Canada',
    'GB': 'UK',
    'HK': 'Hong Kong',
    'MX': 'Mexico',
    'PT': 'Portugal',
    'TW': 'Taiwan',
  };

  /// Returns all languages as (code, name) pairs, sorted by name.
  static List<({String code, String name})> getAllLanguages() {
    final languages = <({String code, String name})>[];
    for (final entry in languageEntries.values) {
      languages.add((code: entry.code1, name: entry.name));
    }
    languages.sort((a, b) => a.name.compareTo(b.name));
    return languages;
  }

  static String? getLanguageName(String languageCode) {
    return _resolve(languageCode)?.name;
  }
}

/// Checks if a track language matches a preferred language.
///
/// Handles both 2-letter (ISO 639-1) and 3-letter (ISO 639-2) codes, plus
/// bibliographic variants and region codes (e.g. "en-US"). Never a prefix
/// compare, which would let `est` (Estonian) satisfy an `es` (Spanish)
/// preference.
bool subtitleLanguageMatches(String? trackLanguage, String? preferredLanguage) {
  if (trackLanguage == null || preferredLanguage == null) {
    return false;
  }

  final track = trackLanguage.toLowerCase();
  final preferred = preferredLanguage.toLowerCase();

  // Direct match
  if (track == preferred) return true;

  // Extract base language codes (handle region codes like "en-US")
  final trackBase = track.split('-').first;
  final preferredBase = preferred.split('-').first;

  if (trackBase == preferredBase) return true;

  // Get all variations of the preferred language (e.g., "en" → ["en", "eng"])
  final variations = LanguageCodes.getVariations(preferredBase);

  // Check if track's base code matches any variation
  return variations.contains(trackBase);
}
