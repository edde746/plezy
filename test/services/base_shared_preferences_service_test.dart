import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helpers/io_fakes.dart';
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

  _poisonedCacheRegression();
}

/// A failed reopen after repair must reset the cached future so a later attempt
/// can retry instead of replaying the stale error (#1732).
void _poisonedCacheRegression() {
  group('repairCorruptStore', () {
    late Directory root;
    late PathProviderPlatform previousPathProvider;

    setUp(() async {
      resetSharedPreferencesForTest();
      root = await Directory.systemTemp.createTemp('plezy_repair_reopen_');
      previousPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = FakePathProvider(root);
    });

    tearDown(() async {
      BaseSharedPreferencesService.resetForTesting();
      PathProviderPlatform.instance = previousPathProvider;
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('a reopen failure does not poison the shared cache', () async {
      final support = Directory(p.join(root.path, 'support'))..createSync(recursive: true);
      File(p.join(support.path, 'shared_preferences.json')).writeAsStringSync('{"theme":"dark"');

      var loadCount = 0;
      BaseSharedPreferencesService.setCacheLoaderForTesting(() {
        loadCount++;
        if (loadCount == 1) return Future<SharedPreferencesWithCache>.error(StateError('reopen failed'));
        return SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
      });

      await expectLater(BaseSharedPreferencesService.repairCorruptStore(), throwsA(isA<StateError>()));

      // The damaged file is already quarantined, so the next attempt has a
      // clean slate and must actually be allowed to use it.
      final recovered = await BaseSharedPreferencesService.sharedCache();
      expect(loadCount, 2);
      await recovered.setBool('recovered', true);
      expect(recovered.getBool('recovered'), isTrue);
    });
  });
}
