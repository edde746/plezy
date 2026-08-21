import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/prefs_recovery.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Reset shared-prefs platform mocks AND the cached singleton instances.
/// Call from `setUp` so each test starts with a clean slate.
void resetSharedPreferencesForTest({Map<String, Object> initialAsync = const {}}) {
  final previousLegacyPlatform = SharedPreferencesStorePlatform.instance;
  final previousAsyncPlatform = SharedPreferencesAsyncPlatform.instance;
  addTearDown(() {
    SharedPreferencesStorePlatform.instance = previousLegacyPlatform;
    SharedPreferencesAsyncPlatform.instance = previousAsyncPlatform;
    SharedPreferences.resetStatic();
    SettingsService.resetForTesting();
    BaseSharedPreferencesService.resetForTesting();
    PrefsRecovery.debugSetSupportedPlatformOverride(null);
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  // The desktop store preflight (`PrefsRecovery.assertStoreReadable`) reads
  // the real on-disk store through path_provider. These fixtures replace the
  // preference backends with in-memory fakes, so there is no real store to
  // validate — and on the hosts where the preflight is active (Linux and
  // Windows) its genuine file IO can never complete inside `testWidgets`'
  // fake async zone, deadlocking every widget test that initialises settings
  // until the ten-minute timeout. Suites that exercise the preflight itself
  // (`prefs_store_repair_flow_test.dart`) opt back in explicitly.
  PrefsRecovery.debugSetSupportedPlatformOverride(false);
  SharedPreferences.setMockInitialValues({});
  SharedPreferencesAsyncPlatform.instance = initialAsync.isEmpty
      ? InMemorySharedPreferencesAsync.empty()
      : InMemorySharedPreferencesAsync.withData(initialAsync);
  BaseSharedPreferencesService.resetForTesting();
}
