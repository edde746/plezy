import 'package:flutter/widgets.dart';

import 'strings.g.dart';

/// Resolves device locales in preference order while preserving Chinese script.
///
/// Slang's generic resolver cannot disambiguate `zh` and `zh-Hant` after an
/// exact script-and-region miss, so common Traditional Chinese device tags need
/// an application-owned canonicalization step.
AppLocale resolvePreferredAppLocale(Iterable<Locale> preferredLocales) {
  for (final locale in preferredLocales) {
    final resolved = _resolveChineseLocale(locale) ?? AppLocaleUtils.parse(locale.toLanguageTag());
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
  String get intlLocaleName => this == AppLocale.zhHant ? 'zh_TW' : languageCode;

  /// Locale name accepted by `package:duration`.
  String get durationLocaleName => this == AppLocale.zhHant ? 'zh_Hant' : languageCode;

  /// Locale identifier sent in Plex request headers.
  String get plexLanguageCode => this == AppLocale.zhHant ? 'zh-TW' : languageCode;
}
