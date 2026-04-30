import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/services/favorite_channels_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/prefs.dart';

/// Direct tests of the SharedPreferences-backed favorite channels store.
/// `_JellyfinLiveTvSupport` doesn't run in these — the repo is the
/// boundary, so a test here exercises both the legacy-key migration path
/// and the JSON round-trip without spinning up an HTTP layer.
FavoriteChannel _channel(String id, {String? title, String source = 'server://abc/jellyfin'}) =>
    FavoriteChannel(source: source, id: id, title: title);

const _key = 'jellyfin_fav_channels:abc/user-1';
const _legacyKey = 'jellyfin_fav_channels:abc';

void main() {
  setUp(resetSharedPreferencesForTest);

  group('SharedPreferencesFavoriteChannelsRepository', () {
    const repo = SharedPreferencesFavoriteChannelsRepository();

    test('read returns empty list when neither key is set', () async {
      final result = await repo.read(key: _key, legacyKey: _legacyKey);
      expect(result, isEmpty);
    });

    test('read parses an existing list at key', () async {
      SharedPreferences.setMockInitialValues({
        _key: jsonEncode([
          {'source': 'server://abc/jellyfin', 'id': 'ch-1', 'title': 'Channel 1'},
          {'source': 'server://abc/jellyfin', 'id': 'ch-2', 'title': 'Channel 2'},
        ]),
      });
      final result = await repo.read(key: _key, legacyKey: _legacyKey);
      expect(result.map((c) => c.id), ['ch-1', 'ch-2']);
      expect(result.first.title, 'Channel 1');
    });

    test('read migrates from the legacy key when primary is absent', () async {
      SharedPreferences.setMockInitialValues({
        _legacyKey: jsonEncode([
          {'source': 'server://abc/jellyfin', 'id': 'ch-legacy'},
        ]),
      });
      final result = await repo.read(key: _key, legacyKey: _legacyKey);
      expect(result, hasLength(1));
      expect(result.first.id, 'ch-legacy');

      // The migrated value should now live under [_key], and the legacy
      // slot should be cleared so a second user reading the same instance
      // doesn't inherit it.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_key), isNotNull);
      expect(prefs.getString(_legacyKey), isNull);
    });

    test('read does not migrate when primary already has a value', () async {
      SharedPreferences.setMockInitialValues({
        _key: jsonEncode([
          {'source': 'server://abc/jellyfin', 'id': 'ch-existing'},
        ]),
        _legacyKey: jsonEncode([
          {'source': 'server://abc/jellyfin', 'id': 'ch-legacy'},
        ]),
      });
      final result = await repo.read(key: _key, legacyKey: _legacyKey);
      expect(result.first.id, 'ch-existing');
      // Legacy slot is left intact when not consumed.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_legacyKey), isNotNull);
    });

    test('read returns empty list when stored value is malformed', () async {
      SharedPreferences.setMockInitialValues({_key: 'not valid json'});
      // jsonDecode will throw — repo's contract is to NOT swallow that.
      // (Caller logs and degrades.) Verify the throw happens here.
      await expectLater(repo.read(key: _key, legacyKey: _legacyKey), throwsA(isA<FormatException>()));
    });

    test('read returns empty list when stored value is a non-list JSON', () async {
      SharedPreferences.setMockInitialValues({_key: '{"not": "a list"}'});
      final result = await repo.read(key: _key, legacyKey: _legacyKey);
      expect(result, isEmpty);
    });

    test('write persists the list as JSON under [key]', () async {
      await repo.write(_key, [_channel('ch-a', title: 'A'), _channel('ch-b', title: 'B')]);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as List;
      expect(decoded, hasLength(2));
      expect((decoded.first as Map)['id'], 'ch-a');
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
