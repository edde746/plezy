import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Reset shared-prefs platform mocks AND the cached singleton instances.
/// Call from `setUp` so each test starts with a clean slate.
void resetSharedPreferencesForTest({Map<String, Object> initialAsync = const {}}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  SharedPreferencesAsyncPlatform.instance = initialAsync.isEmpty
      ? InMemorySharedPreferencesAsync.empty()
      : InMemorySharedPreferencesAsync.withData(initialAsync);
  BaseSharedPreferencesService.resetForTesting();
}
