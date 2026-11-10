import 'package:flutter/widgets.dart';

import '../utils/language_codes.dart';
import 'settings_service.dart';

/// The ISO 639-1 subtitle language to work in: the viewer's saved preference,
/// else the language the app itself is running in, else English.
///
/// Shared by the search sheet and the always-on fallback so the two cannot
/// disagree about what "my language" means.
String resolveSubtitleSearchLanguageCode({String? savedLanguageCode, required Locale appLocale}) {
  return LanguageCodes.getIso6391Code(savedLanguageCode ?? '') ??
      LanguageCodes.getIso6391Code(appLocale.languageCode) ??
      'en';
}

/// [resolveSubtitleSearchLanguageCode] against the live settings, for callers
/// that have no `BuildContext` handy.
String resolveSubtitleLanguageFromSettings(SettingsService? settings) {
  return resolveSubtitleSearchLanguageCode(
    savedLanguageCode: settings?.read(SettingsService.subtitleSearchLanguage),
    appLocale: settings == null
        ? WidgetsBinding.instance.platformDispatcher.locale
        : Locale(settings.read(SettingsService.appLocale).languageCode),
  );
}
