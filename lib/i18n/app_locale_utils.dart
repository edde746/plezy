import 'package:flutter/widgets.dart';

import 'strings.g.dart';

/// Resolves device locales in preference order while preserving Chinese script
/// and the Portuguese variant.
///
/// Slang's generic resolver cannot disambiguate `zh` and `zh-Hant` after an
/// exact script-and-region miss, so common Traditional Chinese device tags need
/// an application-owned canonicalization step. Portuguese has the same shape:
/// `pt` is Brazilian Portuguese and `pt-PT` European Portuguese.
AppLocale resolvePreferredAppLocale(Iterable<Locale> preferredLocales) {
  for (final locale in preferredLocales) {
    final resolved =
        _resolveChineseLocale(locale) ??
        _resolvePortugueseLocale(locale) ??
        AppLocaleUtils.parse(locale.toLanguageTag());
    if (resolved != AppLocale.en || locale.languageCode == AppLocale.en.languageCode) return resolved;
  }
  return AppLocale.en;
}

AppLocale? _resolveChineseLocale(Locale locale) {
  if (locale.languageCode.toLowerCase() != 'zh') return null;

  switch (locale.scriptCode?.toLowerCase()) {
    case 'hant':
      return AppLocale.zhHant;
    case 'hans':
      return AppLocale.zh;
  }

  return switch (locale.countryCode?.toUpperCase()) {
    'TW' || 'HK' || 'MO' => AppLocale.zhHant,
    _ => AppLocale.zh,
  };
}

/// Regions CLDR gives European Portuguese as their parent (every regional
/// Portuguese locale except Brazil). Brazil, other regions and a bare `pt` tag
/// keep the Brazilian translation.
const _europeanPortugueseRegions = {'PT', 'AO', 'MZ', 'CV', 'GW', 'ST', 'TL', 'MO', 'GQ', 'LU', 'CH'};

AppLocale? _resolvePortugueseLocale(Locale locale) {
  if (locale.languageCode.toLowerCase() != 'pt') return null;
  final region = locale.countryCode?.toUpperCase();
  return region != null && _europeanPortugueseRegions.contains(region) ? AppLocale.ptPt : AppLocale.pt;
}

/// [AppLocale.values] grouped by language, in the order each language first
/// appears; this is the order the language picker lists them.
///
/// Slang appends script and region variants after every base language, so
/// `pt-PT` and `zh-Hant` would otherwise sit at the end of the list instead of
/// next to Portuguese and Chinese.
final List<AppLocale> languagePickerLocales = List.unmodifiable([
  for (final languageCode in {for (final locale in AppLocale.values) locale.languageCode})
    ...AppLocale.values.where((locale) => locale.languageCode == languageCode),
]);

/// Locales offered to Flutter's `Localizations`, one per [AppLocale].
final List<Locale> supportedLocalizationsLocales = List.unmodifiable(
  AppLocale.values.map((locale) => locale.localizationsLocale),
);

extension AppLocaleExternalFormats on AppLocale {
  /// Locale handed to Flutter's `Localizations`, which every `Text` inherits
  /// as its paragraph locale, and with it the Han glyph forms platform font
  /// fallback picks. Chinese names its script and region: Windows DirectWrite
  /// treats a bare `zh` like an unknown language and falls back to a Japanese
  /// font (#2752).
  Locale get localizationsLocale => switch (this) {
    AppLocale.zh => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'),
    AppLocale.zhHant => const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'),
    _ => flutterLocale,
  };

  /// Locale name accepted by `package:intl`.
  String get intlLocaleName => switch (this) {
    AppLocale.zhHant => 'zh_TW',
    AppLocale.ptPt => 'pt_PT',
    _ => languageCode,
  };

  /// Locale name accepted by `package:duration`.
  String get durationLocaleName => this == AppLocale.zhHant ? 'zh_Hant' : languageCode;

  /// Locale identifier sent in Plex request headers.
  String get plexLanguageCode => this == AppLocale.zhHant ? 'zh-TW' : languageCode;
}
