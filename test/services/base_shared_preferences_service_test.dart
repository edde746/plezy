import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helpers/prefs.dart';

void main() {
  setUp(resetSharedPreferencesForTest);

  tearDown(BaseSharedPreferencesService.resetForTesting);

  test('failed shared cache load is coalesced but a later call retries', () async {
    final firstLoad = Completer<SharedPreferencesWithCache>();
    final originalError = StateError('preferences unavailable');
    final originalStackTrace = StackTrace.current;
    var loadCount = 0;

    BaseSharedPreferencesService.setCacheLoaderForTesting(() {
      loadCount++;
      if (loadCount == 1) return firstLoad.future;
      return SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
    });

    final firstCaller = BaseSharedPreferencesService.sharedCache();
    final concurrentCaller = BaseSharedPreferencesService.sharedCache();
    expect(identical(firstCaller, concurrentCaller), isTrue);
    expect(loadCount, 1);

    firstLoad.completeError(originalError, originalStackTrace);
    Object? caughtError;
    StackTrace? caughtStackTrace;
    try {
      await firstCaller;
    } catch (error, stackTrace) {
      caughtError = error;
      caughtStackTrace = stackTrace;
    }

    expect(identical(caughtError, originalError), isTrue);
    expect(caughtStackTrace.toString(), originalStackTrace.toString());

    final recovered = await BaseSharedPreferencesService.sharedCache();
    expect(loadCount, 2);
    await recovered.setBool('recovered', true);
    expect(recovered.getBool('recovered'), isTrue);
  });

  test('reset restores the production cache loader', () async {
    BaseSharedPreferencesService.setCacheLoaderForTesting(
      () => Future<SharedPreferencesWithCache>.error(StateError('injected failure')),
    );

    BaseSharedPreferencesService.resetForTesting();

    final cache = await BaseSharedPreferencesService.sharedCache();
    await cache.setString('loader', 'production');
    expect(cache.getString('loader'), 'production');
  });
}
