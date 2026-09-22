import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/favorite_channels_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/prefs.dart';

/// Direct tests of the shared-cache-backed favorite channels store.
/// `_JellyfinLiveTvSupport` doesn't run in these — the repo is the
/// boundary, so a test here exercises the legacy-key and legacy-store
/// adoption paths and the JSON round-trip without spinning up an HTTP layer.
FavoriteChannel _channel(String id, {String? title, String source = 'server://abc/jellyfin'}) =>
    FavoriteChannel(source: source, id: id, title: title);

const _key = 'jellyfin_fav_channels:abc/user-1';
const _legacyKey = 'jellyfin_fav_channels:abc';

String _list(List<String> ids) => jsonEncode([
  for (final id in ids) {'source': 'server://abc/jellyfin', 'id': id},
]);

/// An install whose one-shot legacy→async prefs migration already ran, with
/// [legacy] written to the legacy store afterwards by an older build, and
/// [async] already in the shared cache.
void _seedPostMigrationStores({required Map<String, Object> legacy, Map<String, Object> async = const {}}) {
  resetSharedPreferencesForTest(initialAsync: {'plezy_legacy_prefs_migrated_v1': true, ...async});
  SharedPreferences.setMockInitialValues(legacy);
}

void main() {
  const repo = SharedPreferencesFavoriteChannelsRepository();

  group('SharedPreferencesFavoriteChannelsRepository', () {
    setUp(resetSharedPreferencesForTest);

    test('read returns empty list when neither key is set', () async {
      final result = await repo.read(key: _key, legacyKey: _legacyKey);
      expect(result, isEmpty);
    });

    test('read parses an existing list at key', () async {
      resetSharedPreferencesForTest(
        initialAsync: {
          _key: jsonEncode([
            {'source': 'server://abc/jellyfin', 'id': 'ch-1', 'title': 'Channel 1'},
            {'source': 'server://abc/jellyfin', 'id': 'ch-2', 'title': 'Channel 2'},
          ]),
        },
      );
      final result = await repo.read(key: _key, legacyKey: _legacyKey);
      expect(result.map((c) => c.id), ['ch-1', 'ch-2']);
      expect(result.first.title, 'Channel 1');
    });

    test('read migrates from the legacy key when primary is absent', () async {
      resetSharedPreferencesForTest(
        initialAsync: {
          _legacyKey: _list(['ch-legacy']),
        },
      );
      final result = await repo.read(key: _key, legacyKey: _legacyKey);
      expect(result.map((c) => c.id), ['ch-legacy']);

      // The migrated value should now live under [_key], and the legacy
      // slot should be cleared so a second user reading the same instance
      // doesn't inherit it.
      final prefs = await BaseSharedPreferencesService.sharedCache();
      expect(prefs.getString(_key), isNotNull);
      expect(prefs.getString(_legacyKey), isNull);
    });

    test('read does not migrate when primary already has a value', () async {
      resetSharedPreferencesForTest(
        initialAsync: {
          _key: _list(['ch-existing']),
          _legacyKey: _list(['ch-legacy']),
        },
      );
      final result = await repo.read(key: _key, legacyKey: _legacyKey);
      expect(result.first.id, 'ch-existing');
      // Legacy slot is left intact when not consumed.
      final prefs = await BaseSharedPreferencesService.sharedCache();
      expect(prefs.getString(_legacyKey), isNotNull);
    });

    test('read adopts a list an older build left in the legacy store', () async {
      _seedPostMigrationStores(
        legacy: {
          _key: _list(['ch-old-build']),
        },
      );
      final result = await repo.read(key: _key, legacyKey: _legacyKey);
      expect(result.map((c) => c.id), ['ch-old-build']);

      final prefs = await BaseSharedPreferencesService.sharedCache();
      expect(prefs.getString(_key), _list(['ch-old-build']));
      expect((await SharedPreferences.getInstance()).getString(_key), isNull);
    });

    test('read adopts the legacy-store bare-machineId slot last', () async {
      _seedPostMigrationStores(
        legacy: {
          _legacyKey: _list(['ch-oldest']),
        },
      );
      final result = await repo.read(key: _key, legacyKey: _legacyKey);
      expect(result.map((c) => c.id), ['ch-oldest']);

      final prefs = await BaseSharedPreferencesService.sharedCache();
      expect(prefs.getString(_key), _list(['ch-oldest']));
      expect((await SharedPreferences.getInstance()).getString(_legacyKey), isNull);
    });

    test('a shared-cache value wins over anything in the legacy store', () async {
      _seedPostMigrationStores(
        async: {
          _key: _list(['ch-current']),
        },
        legacy: {
          _key: _list(['ch-stale']),
        },
      );
      final result = await repo.read(key: _key, legacyKey: _legacyKey);
      expect(result.map((c) => c.id), ['ch-current']);
      expect((await SharedPreferences.getInstance()).getString(_key), isNotNull);
    });

    test('migrate: false reads the legacy store without moving it', () async {
      _seedPostMigrationStores(
        legacy: {
          _key: _list(['ch-peek']),
        },
      );
      final result = await repo.read(key: _key, legacyKey: _legacyKey, migrate: false);
      expect(result.map((c) => c.id), ['ch-peek']);

      final prefs = await BaseSharedPreferencesService.sharedCache();
      expect(prefs.getString(_key), isNull);
      expect((await SharedPreferences.getInstance()).getString(_key), isNotNull);
    });

    test('read rejects malformed JSON', () async {
      resetSharedPreferencesForTest(initialAsync: {_key: 'not valid json'});
      // jsonDecode will throw — repo's contract is to NOT swallow that.
      // (Caller logs and degrades.) Verify the throw happens here.
      await expectLater(repo.read(key: _key, legacyKey: _legacyKey), throwsA(isA<FormatException>()));
    });

    test('read rejects non-list JSON without replacing persisted state', () async {
      const raw = '{"not": "a list"}';
      resetSharedPreferencesForTest(initialAsync: {_key: raw});
      await expectLater(repo.read(key: _key, legacyKey: _legacyKey), throwsA(isA<FormatException>()));
      expect((await BaseSharedPreferencesService.sharedCache()).getString(_key), raw);
    });

    test('write persists the list as JSON under [key] in the shared cache', () async {
      await repo.write(_key, [_channel('ch-a', title: 'A'), _channel('ch-b', title: 'B')]);
      final prefs = await BaseSharedPreferencesService.sharedCache();
      final raw = prefs.getString(_key);
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as List;
      expect(decoded, hasLength(2));
      expect((decoded.first as Map)['id'], 'ch-a');
      expect((await SharedPreferences.getInstance()).getString(_key), isNull);
    });

    test('write then read round-trips the list verbatim', () async {
      final input = [_channel('ch-1', title: 'One'), _channel('ch-2', title: 'Two')];
      await repo.write(_key, input);
      final out = await repo.read(key: _key, legacyKey: _legacyKey);
      expect(out, hasLength(2));
      expect(out[0].id, 'ch-1');
      expect(out[0].title, 'One');
      expect(out[1].id, 'ch-2');
      expect(out[1].title, 'Two');
    });

    test('write([]) replaces an existing list with an empty one', () async {
      await repo.write(_key, [_channel('ch-1')]);
      await repo.write(_key, const []);
      final out = await repo.read(key: _key, legacyKey: _legacyKey);
      expect(out, isEmpty);
    });
  });
}
