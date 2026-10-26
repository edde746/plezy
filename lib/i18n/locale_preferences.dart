import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../services/settings_service.dart';
import 'app_locale_utils.dart';
import 'strings.g.dart';
import 'platform_locale_sync.dart';

/// UI language, regional formatting and metadata language are independent.
/// Protocol values, persisted numbers and playback positions never use these
/// formatters: localization belongs at the presentation boundary.
class LocalePreferences {
  LocalePreferences._();

  static Future<void> _pending = Future.value();

  static bool get followsSystem =>
      SettingsService.instanceOrNull?.readNullableString(SettingsService.appLocale.key)?.isNotEmpty != true;

  static String get formattingLocaleName {
    final preference = SettingsService.instanceOrNull?.read(SettingsService.formatLocale) ?? 'app';
    final device = AppLocaleEnvironment.deviceLocales;
    String requested;
    if (preference == 'system') {
      requested = device.isEmpty ? 'en' : device.first.toLanguageTag().replaceAll('-', '_');
    } else if (preference != 'app') {
      requested = preference.replaceAll('-', '_');
    } else {
      final app = LocaleSettings.currentLocale;
      // Keep regional conventions when the device and chosen UI language agree.
      final matchingDevice = device.where(
        (locale) =>
            locale.languageCode == app.languageCode &&
            (app.languageCode != 'zh' || resolvePreferredAppLocale([locale]) == app),
      );
      requested = app.countryCode == null && matchingDevice.isNotEmpty
          ? matchingDevice.first.toLanguageTag().replaceAll('-', '_')
          : app.intlLocaleName;
    }
    return Intl.verifiedLocale(requested, NumberFormat.localeExists, onFailure: (_) => 'en') ?? 'en';
  }

  static String get metadataLanguageCode {
    final preference = SettingsService.instanceOrNull?.read(SettingsService.metadataLocale) ?? '';
    return preference.isEmpty ? LocaleSettings.currentLocale.plexLanguageCode : preference;
  }

  /// Serializing locale loads prevents a slower deferred locale from replacing
  /// the viewer's newer choice. Resolve preferences when the operation runs.
  static Future<void> apply() {
    final next = _pending.catchError((Object _) {}).then((_) async {
      final settings = SettingsService.instanceOrNull;
      if (settings != null) await PlatformLocaleSync.synchronize(settings);
      final locale =
          settings?.read(SettingsService.appLocale) ?? resolvePreferredAppLocale(AppLocaleEnvironment.deviceLocales);
      await LocaleSettings.setLocale(locale);
      await initializeDateFormatting();
      Intl.defaultLocale = formattingLocaleName;
    });
    _pending = next;
    return next;
  }
}
