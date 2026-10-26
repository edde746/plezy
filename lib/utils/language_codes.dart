import '../data/iso_639_data.dart';
import '../i18n/locale_names.g.dart';
import '../i18n/strings.g.dart';

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

  static String? getIso6392Code(String code) {
    final normalized = code.toLowerCase().trim().split(RegExp('[-_]')).first;
    if (normalized.isEmpty) return null;
    return _resolve(normalized)?.code2;
  }

  static Map<String, String> get _names =>
      localizedLanguageNames[LocaleSettings.currentLocale.languageTag] ?? localizedLanguageNames['en']!;

  /// Localized language, script and territory names; accepts BCP-47 tags and
  /// legacy underscore tags without dropping a Chinese script or region.
  static String getDisplayName(String code) {
    if (code.isEmpty) return code;
    final parts = code.replaceAll('_', '-').split('-');
    final langName = getLanguageName(parts.first) ?? parts.first;
    final locale = LocaleSettings.currentLocale.languageTag;
    final regions = localizedTerritoryNames[locale] ?? localizedTerritoryNames['en']!;
    final scripts = localizedScriptNames[locale] ?? localizedScriptNames['en']!;
    final qualifiers = <String>[];
    for (final part in parts.skip(1)) {
      if (part.length == 4) {
        final script = '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
        qualifiers.add(scripts[script] ?? part);
      } else if (part.length == 2 || RegExp(r'^\d{3}$').hasMatch(part)) {
        qualifiers.add(regions[part.toUpperCase()] ?? part);
      }
    }
    return qualifiers.isEmpty ? langName : '$langName (${qualifiers.join(', ')})';
  }

  /// CLDR's committed insertion order was produced by a locale-aware collator.
  /// Re-evaluate on language change; never cache English options globally.
  static List<({String code, String name})> getAllLanguages() => [
    for (final entry in _names.entries) (code: entry.key, name: entry.value),
  ];

  static String? getLanguageName(String languageCode) {
    final entry = _resolve(languageCode);
    return entry == null ? null : _names[entry.code1] ?? entry.name;
  }
}
