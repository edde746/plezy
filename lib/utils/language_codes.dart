import '../data/iso_639_data.dart';

/// Helper class for converting between ISO 639-1 (2-letter) and ISO 639-2 (3-letter) language codes,
/// with support for regional and script language variants (e.g., pt-BR, pt-PT, es-419, zh-Hans).
class LanguageCodes {
  /// Regional and script language variants supported in user preferences and subtitle search.
  static const regionalLanguages = <String>['pt-BR', 'pt-PT', 'es-419', 'zh-Hans', 'zh-Hant', 'fr-CA'];

  static const _regionalAliases = <String, String>{'pob': 'pt-BR'};

  /// Resolves known regional aliases (e.g. "pob" -> "pt-BR").
  static String? resolveAlias(String code) => _regionalAliases[code.toLowerCase().trim()];

  static LanguageEntry? _resolve(String code) {
    final normalized = code.toLowerCase().trim();
    final entry = languageEntries[normalized];
    if (entry != null) return entry;
    final key = code2ToCode1[normalized] ?? code2BToCode1[normalized];
    return key != null ? languageEntries[key] : null;
  }

  /// Returns all code variations (639-1, 639-2, 639-2/B, and regional aliases) for a given language code.
  static List<String> getVariations(String languageCode) {
    final normalized = languageCode.toLowerCase().trim().replaceAll('_', '-');
    final variations = <String>{normalized};

    final alias = _regionalAliases[normalized];
    if (alias != null) {
      variations.add(alias.toLowerCase());
    }
    for (final entry in _regionalAliases.entries) {
      if (entry.value.toLowerCase() == normalized) {
        variations.add(entry.key.toLowerCase());
      }
    }

    final target = alias ?? normalized;
    final entry = _resolve(target.split('-').first);
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

  /// Normalizes a language code. Preserves supported regional variants (e.g. "pt-BR", "pt_BR" -> "pt-BR",
  /// "pob" -> "pt-BR"), while mapping 3-letter codes to ISO 639-1 (e.g. "eng" -> "en").
  static String? normalizeCode(String? code) {
    if (code == null) return null;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();
    final alias = _regionalAliases[lower];
    if (alias != null) return alias;

    final normalized = trimmed.replaceAll('_', '-');
    if (normalized.contains('-')) {
      final parts = normalized.split('-');
      final base = getIso6391Code(parts.first) ?? parts.first.toLowerCase();
      final tag = parts.length > 1 ? parts[1] : '';
      final formattedTag = tag.length == 4
          ? '${tag[0].toUpperCase()}${tag.substring(1).toLowerCase()}'
          : tag.toUpperCase();
      final candidate = '$base-$formattedTag';
      for (final regional in regionalLanguages) {
        if (regional.toLowerCase() == candidate.toLowerCase()) {
          return regional;
        }
      }
      return base;
    }

    return getIso6391Code(trimmed);
  }

  /// Get a display name for a language/locale code.
  /// Handles plain codes ("en" → "English") and locale codes ("en-US" → "English",
  /// "pt-BR" → "Portuguese (Brazil)").
  static String getDisplayName(String code) {
    if (code.isEmpty) return code;

    final alias = _regionalAliases[code.toLowerCase().trim()];
    final target = alias ?? code;

    final normalized = target.replaceAll('_', '-').trim();
    if (!normalized.contains('-')) {
      return getLanguageName(normalized) ?? normalized;
    }

    final parts = normalized.split('-');
    final langName = getLanguageName(parts.first) ?? parts.first;
    final regionTag = parts.length > 1 ? parts[1].toUpperCase() : null;
    final region = regionTag != null ? _regionNames[regionTag] : null;
    return region != null ? '$langName ($region)' : langName;
  }

  static const _regionNames = <String, String>{
    '419': 'Latin America',
    'AU': 'Australia',
    'BR': 'Brazil',
    'CA': 'Canada',
    'GB': 'UK',
    'HK': 'Hong Kong',
    'MX': 'Mexico',
    'PT': 'Portugal',
    'TW': 'Taiwan',
    'HANS': 'Simplified',
    'HANT': 'Traditional',
  };

  /// Returns all languages as (code, name) pairs, sorted by name.
  static List<({String code, String name})> getAllLanguages() {
    final languages = <({String code, String name})>[];
    for (final entry in languageEntries.values) {
      languages.add((code: entry.code1, name: entry.name));
    }
    for (final code in regionalLanguages) {
      languages.add((code: code, name: getDisplayName(code)));
    }
    languages.sort((a, b) => a.name.compareTo(b.name));
    return languages;
  }

  static String? getLanguageName(String languageCode) {
    final entry = _resolve(languageCode);
    if (entry != null) return entry.name;
    final alias = _regionalAliases[languageCode.toLowerCase().trim()];
    if (alias != null) return getDisplayName(alias);
    if (languageCode.contains(RegExp('[-_]'))) {
      final name = getDisplayName(languageCode);
      if (name != languageCode) return name;
    }
    return null;
  }
}
