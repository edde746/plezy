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
