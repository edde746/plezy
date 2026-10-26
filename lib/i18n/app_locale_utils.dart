import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import 'strings.g.dart';
import 'locale_names.g.dart';

/// One locale source shared by preference resolution and regional formatting.
class AppLocaleEnvironment {
  @visibleForTesting
  static List<Locale>? debugDeviceLocales;

  // Android's in-process locale list starts with the per-app override. Keep
  // the unmodified system list for the independent “Follow system” format.
  static List<Locale>? platformDeviceLocales;

  static List<Locale> get deviceLocales =>
      debugDeviceLocales ?? platformDeviceLocales ?? PlatformDispatcher.instance.locales;
}

/// Resolves device locales in preference order while preserving Chinese script.
///
/// Slang's generic resolver cannot disambiguate `zh` and `zh-Hant` after an
/// exact script-and-region miss, so common Traditional Chinese device tags need
/// an application-owned canonicalization step.
AppLocale resolvePreferredAppLocale(Iterable<Locale> preferredLocales) {
  for (final locale in preferredLocales) {
    final tag = locale.toLanguageTag().toLowerCase();
    final exact = AppLocale.values.where((candidate) => candidate.languageTag.toLowerCase() == tag);
    final resolved = exact.isNotEmpty ? exact.first : _resolveChineseLocale(locale) ?? _resolveRegionalLocale(locale);
    if (resolved != AppLocale.en || locale.languageCode == AppLocale.en.languageCode) return resolved;
  }
  return AppLocale.en;
}

AppLocale _resolveRegionalLocale(Locale locale) {
  // Latin American Spanish has one regional catalog, not one copy per
  // country. Spain and unspecified Spanish retain the language-only catalog.
  const latinAmerica = {
    '419',
    'AR',
    'BO',
    'BR',
    'BZ',
    'CL',
    'CO',
    'CR',
    'CU',
    'DO',
    'EC',
    'GT',
    'HN',
    'MX',
    'NI',
    'PA',
    'PE',
    'PR',
    'PY',
    'SV',
    'US',
    'UY',
    'VE',
  };
  if (locale.languageCode == 'es' && latinAmerica.contains(locale.countryCode?.toUpperCase())) {
    return AppLocaleUtils.parse('es-419');
  }
  // Script-tagged devices must still find a regional variant (fr-Latn-CA).
  final region = locale.countryCode;
  if (region != null) {
    final regionalTag = '${locale.languageCode}-$region'.toLowerCase();
    for (final supported in AppLocale.values) {
      if (supported.languageTag.toLowerCase() == regionalTag) return supported;
    }
  }
  return AppLocaleUtils.parse(locale.toLanguageTag());
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
  String get intlLocaleName => this == AppLocale.zhHant ? 'zh_TW' : languageTag.replaceAll('-', '_');

  /// Locale name accepted by `package:duration`.
  String get durationLocaleName => this == AppLocale.zhHant ? 'zh_Hant' : languageCode;

  /// Locale identifier sent in Plex request headers.
  String get plexLanguageCode => this == AppLocale.zhHant ? 'zh-TW' : languageTag;

  /// Endonyms remain recognizable even when the interface is unfamiliar.
  String get nativeName => localeEndonyms[languageTag] ?? languageTag;

  bool get isRightToLeft => const {'ar', 'fa', 'he'}.contains(languageCode);
}
