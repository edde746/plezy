import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/locale_preferences.dart';
import 'package:plezy/i18n/app_locale_utils.dart';
import 'package:plezy/i18n/platform_locale_sync.dart';
import 'package:plezy/i18n/presentation_formats.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SettingsService settings;
  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    settings = await SettingsService.getInstance();
    await LocaleSettings.setLocale(AppLocale.en);
  });
  tearDown(() async {
    AppLocaleEnvironment.debugDeviceLocales = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      PlatformLocaleSync.channel, null);
    await LocaleSettings.setLocale(AppLocale.en);
  });

  test('UI, regional formatting and metadata preferences remain independent', () async {
    await settings.write(SettingsService.appLocale, AppLocale.ar);
    await settings.write(SettingsService.formatLocale, 'de-DE');
    await settings.write(SettingsService.metadataLocale, 'ja');
    await LocalePreferences.apply();
    expect(LocaleSettings.currentLocale, AppLocale.ar);
    expect(formatDecimal(1234.5, grouping: true), '1.234,5');
    expect(LocalePreferences.metadataLanguageCode, 'ja');
    expect(formatLocalizedUnit(2, 'hour', width: 'long'), 'ساعتان');
  });

  test('Follow system can be restored after a manual language choice', () async {
    AppLocaleEnvironment.debugDeviceLocales = const [Locale('ja', 'JP')];
    await settings.write(SettingsService.appLocale, AppLocale.fr);
    await LocalePreferences.apply();
    expect(LocalePreferences.followsSystem, isFalse);
    expect(LocaleSettings.currentLocale, AppLocale.fr);
    await settings.reset(SettingsService.appLocale);
    await LocalePreferences.apply();
    expect(LocalePreferences.followsSystem, isTrue);
    expect(LocaleSettings.currentLocale, AppLocale.ja);
  });

  test('Traditional Chinese formatting does not inherit Simplified device symbols', () async {
    AppLocaleEnvironment.debugDeviceLocales = const [Locale('zh', 'CN')];
    await settings.write(SettingsService.appLocale, AppLocale.zhHant);
    await LocalePreferences.apply();
    expect(LocalePreferences.formattingLocaleName, 'zh_TW');
  });

  test('imported locale identifiers are validated and canonicalized', () async {
    await settings.write(SettingsService.formatLocale, 'de_de');
    await settings.write(SettingsService.metadataLocale, 'zh_hant_tw');
    expect(settings.read(SettingsService.formatLocale), 'de-DE');
    expect(settings.read(SettingsService.metadataLocale), 'zh-Hant-TW');
    await expectLater(settings.write(SettingsService.formatLocale, '../../en'), throwsFormatException);
    await expectLater(settings.write(SettingsService.metadataLocale, 'xx'), throwsFormatException);
    expect(() => SettingsService.formatLocale.fromJson(123), throwsFormatException);
  });

  test('Android language picker synchronizes both ways, including system default', () async {
    var nativeTag = '';
    final writes = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      PlatformLocaleSync.channel, (call) async {
        if (call.method == 'getApplicationLocale') return nativeTag;
        nativeTag = call.arguments as String;
        writes.add(nativeTag);
        return null;
      });
    await settings.write(SettingsService.appLocale, AppLocale.fr);
    await PlatformLocaleSync.synchronizeChannel(settings);
    expect(nativeTag, 'fr'); // Migrates an existing in-app choice.
    nativeTag = 'ar'; // Changed in Android Settings while the app was away.
    await PlatformLocaleSync.synchronizeChannel(settings);
    expect(settings.read(SettingsService.appLocale), AppLocale.ar);
    expect(writes, ['fr']); // An OS change must not be overwritten.
    nativeTag = '';
    await PlatformLocaleSync.synchronizeChannel(settings);
    expect(LocalePreferences.followsSystem, isTrue);
    expect(writes, ['fr']);
  });

  test('regional formats can follow device without changing UI or metadata', () async {
    AppLocaleEnvironment.debugDeviceLocales = const [Locale('de', 'DE')];
    await settings.write(SettingsService.appLocale, AppLocale.en);
    await settings.write(SettingsService.formatLocale, 'system');
    await LocalePreferences.apply();
    expect(formatDecimal(2.5), '2,5');
    expect(LocalePreferences.metadataLanguageCode, 'en');
  });

  test('external bidi overrides cannot reorder surrounding UI', () {
    expect(isolateDisplayText('Movie \u202e2026'), '\u2068Movie 2026\u2069');
    expect(isolateDisplayText('فيلم (2026)'), '\u2068فيلم (2026)\u2069');
  });
}
