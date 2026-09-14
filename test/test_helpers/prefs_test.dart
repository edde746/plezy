import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesStorePlatform originalLegacyPlatform;
  late SharedPreferencesAsyncPlatform? originalAsyncPlatform;
  late SharedPreferencesStorePlatform sentinelLegacyPlatform;
  late SharedPreferencesAsyncPlatform sentinelAsyncPlatform;

  setUp(() {
    originalLegacyPlatform = SharedPreferencesStorePlatform.instance;
    originalAsyncPlatform = SharedPreferencesAsyncPlatform.instance;
    sentinelLegacyPlatform = InMemorySharedPreferencesStore.withData({'flutter.restored_legacy': true});
    sentinelAsyncPlatform = InMemorySharedPreferencesAsync.withData({'restored_async': true});
    SharedPreferencesStorePlatform.instance = sentinelLegacyPlatform;
    SharedPreferencesAsyncPlatform.instance = sentinelAsyncPlatform;
    SharedPreferences.resetStatic();
    SettingsService.resetForTesting();
    BaseSharedPreferencesService.resetForTesting();
  });

  tearDown(() async {
    try {
      expect(SharedPreferencesStorePlatform.instance, same(sentinelLegacyPlatform));
      expect(SharedPreferencesAsyncPlatform.instance, same(sentinelAsyncPlatform));
      expect((await SharedPreferences.getInstance()).getBool('restored_legacy'), isTrue);
      expect(await SharedPreferencesAsync().getBool('restored_async'), isTrue);
      final restoredSettings = await SettingsService.getInstance();
      expect(restoredSettings.prefs.getBool('temporary_value'), isNull);
    } finally {
      SharedPreferencesStorePlatform.instance = originalLegacyPlatform;
      SharedPreferencesAsyncPlatform.instance = originalAsyncPlatform;
      SharedPreferences.resetStatic();
      SettingsService.resetForTesting();
      BaseSharedPreferencesService.resetForTesting();
    }
  });

  test('restores both platform singletons and invalidates cached services', () async {
    resetSharedPreferencesForTest();

    final temporarySettings = await SettingsService.getInstance();
    await temporarySettings.prefs.setBool('temporary_value', true);
    expect(temporarySettings.prefs.getBool('temporary_value'), isTrue);
    expect(SharedPreferencesStorePlatform.instance, isNot(same(sentinelLegacyPlatform)));
    expect(SharedPreferencesAsyncPlatform.instance, isNot(same(sentinelAsyncPlatform)));
  });

  test('nested resets restore the immediately preceding platform pair', () {
    resetSharedPreferencesForTest(initialAsync: const {'first': true});
    final firstLegacyPlatform = SharedPreferencesStorePlatform.instance;
    final firstAsyncPlatform = SharedPreferencesAsyncPlatform.instance;

    addTearDown(() {
      expect(SharedPreferencesStorePlatform.instance, same(firstLegacyPlatform));
      expect(SharedPreferencesAsyncPlatform.instance, same(firstAsyncPlatform));
    });

    resetSharedPreferencesForTest(initialAsync: const {'second': true});
    expect(SharedPreferencesStorePlatform.instance, isNot(same(firstLegacyPlatform)));
    expect(SharedPreferencesAsyncPlatform.instance, isNot(same(firstAsyncPlatform)));
  });
}
