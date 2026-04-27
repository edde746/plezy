import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_export_service.dart';

import '../test_helpers/prefs.dart';

// NOTE on coverage scope:
// `SettingsExportService.exportToFile` and `importFromFile` both call into
// platform plumbing (FilePicker, PackageInfo, path_provider, dart:io.File).
// Per the task brief we only round-trip through the *pure* helpers
// `buildExportMap` and `applyImportMap` against an in-memory
// SharedPreferencesWithCache. That covers the user-prefix re-scoping, the
// allow/deny filtering, and the typed value (de)serialization — which is
// where the format-stability risk lives.

void main() {
  setUp(resetSharedPreferencesForTest);

  // ============================================================
  // buildExportMap — header fields
  // ============================================================

  group('buildExportMap header', () {
    test('emits the documented format version, an ISO8601 timestamp, and the platform', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      final out = SettingsExportService.buildExportMap(prefs);

      expect(out['formatVersion'], SettingsExportService.formatVersion);
      expect(out['appVersion'], '');
      expect(out['exportedAt'], isA<String>());
      // Sanity: the timestamp parses as an ISO-8601 instant.
      expect(() => DateTime.parse(out['exportedAt'] as String), returnsNormally);
      expect(out['platform'], isA<String>());
      expect(out['prefs'], isA<Map>());
    });

    test('honors the supplied appVersion', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      final out = SettingsExportService.buildExportMap(prefs, appVersion: '1.2.3');
      expect(out['appVersion'], '1.2.3');
    });
  });

  // ============================================================
  // buildExportMap — type encoding round-trip
  // ============================================================

  group('buildExportMap type encoding', () {
    test('encodes bool / int / double / string / stringList with type markers', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setBool('flag_a', true);
      await prefs.setInt('count_a', 42);
      await prefs.setDouble('volume', 0.75);
      await prefs.setString('name', 'plezy');
      await prefs.setStringList('list_a', const ['x', 'y']);

      final out = SettingsExportService.buildExportMap(prefs);
      final p = out['prefs'] as Map<String, dynamic>;

      expect(p['flag_a'], {'type': 'bool', 'value': true});
      expect(p['count_a'], {'type': 'int', 'value': 42});
      expect(p['volume'], {'type': 'double', 'value': 0.75});
      expect(p['name'], {'type': 'string', 'value': 'plezy'});
      expect(p['list_a'], {
        'type': 'stringList',
        'value': ['x', 'y'],
      });
    });
  });

  // ============================================================
  // buildExportMap — denylist filtering
  // ============================================================

  group('buildExportMap denylist', () {
    test('drops exact-deny credential keys', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      // Sample of the credential bucket — should never leak.
      await prefs.setString('plex_token', 'abc');
      await prefs.setString('client_identifier', 'xyz');
      await prefs.setString('current_user_uuid', 'user-1');
      await prefs.setString('user_profile', '{}');
      // Plus a good-faith key that should stay.
      await prefs.setBool('keep_me', true);

      final out = SettingsExportService.buildExportMap(prefs);
      final p = out['prefs'] as Map<String, dynamic>;

      expect(p, isNot(contains('plex_token')));
      expect(p, isNot(contains('client_identifier')));
      expect(p, isNot(contains('current_user_uuid')));
      expect(p, isNot(contains('user_profile')));
      expect(p, contains('keep_me'));
    });

    test('drops prefix-deny keys (server_endpoint_, episode_count_, watched_threshold_, trakt_)', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString('server_endpoint_srv1', 'http://x');
      await prefs.setInt('episode_count_show42', 24);
      await prefs.setInt('watched_threshold_srv1', 95);
      await prefs.setString('trakt_access_token', 'secret');
      // The trakt feature flag uses a different prefix and SHOULD survive.
      await prefs.setBool('enable_trakt_scrobble', true);

      final out = SettingsExportService.buildExportMap(prefs);
      final p = out['prefs'] as Map<String, dynamic>;

      expect(p, isNot(contains('server_endpoint_srv1')));
      expect(p, isNot(contains('episode_count_show42')));
      expect(p, isNot(contains('watched_threshold_srv1')));
      expect(p, isNot(contains('trakt_access_token')));
      expect(p, contains('enable_trakt_scrobble'));
    });

    test('drops MAL / AniList / SIMKL session keys but keeps their feature toggles', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      // Stripped tracker session tokens — these would carry access_token /
      // refresh_token JSON if they leaked into the export.
      await prefs.setString('mal_session', '{"access_token":"a","refresh_token":"r"}');
      await prefs.setString('anilist_session', '{"access_token":"a"}');
      await prefs.setString('simkl_session', '{"access_token":"a"}');
      // Feature toggles use the `enable_` prefix and SHOULD survive.
      await prefs.setBool('enable_mal_scrobble', true);
      await prefs.setBool('enable_anilist_scrobble', true);
      await prefs.setBool('enable_simkl_scrobble', true);

      final out = SettingsExportService.buildExportMap(prefs);
      final p = out['prefs'] as Map<String, dynamic>;

      expect(p, isNot(contains('mal_session')));
      expect(p, isNot(contains('anilist_session')));
      expect(p, isNot(contains('simkl_session')));
      expect(p, contains('enable_mal_scrobble'));
      expect(p, contains('enable_anilist_scrobble'));
      expect(p, contains('enable_simkl_scrobble'));
    });

    test('user-scoped tracker sessions are dropped after the user prefix is stripped', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      // TrackerAccountStore writes under user_{uuid}_{baseKey}. After the
      // active-user prefix is stripped on export, the key falls under the
      // tracker prefix denylist.
      await prefs.setString('user_alice_mal_session', '{"access_token":"a"}');
      await prefs.setString('user_alice_anilist_session', '{"access_token":"a"}');
      await prefs.setString('user_alice_simkl_session', '{"access_token":"a"}');
      await prefs.setString('user_alice_trakt_session', '{"access_token":"a"}');

      final out = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice');
      final p = out['prefs'] as Map<String, dynamic>;

      expect(p, isNot(contains('mal_session')));
      expect(p, isNot(contains('anilist_session')));
      expect(p, isNot(contains('simkl_session')));
      expect(p, isNot(contains('trakt_session')));
    });

    test('drops the internal migration flag', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setBool('buffer_size_migrated_to_auto', true);
      final out = SettingsExportService.buildExportMap(prefs);
      expect((out['prefs'] as Map), isNot(contains('buffer_size_migrated_to_auto')));
    });
  });

  // ============================================================
  // buildExportMap — user-prefix scoping
  // ============================================================

  group('buildExportMap user-scoping', () {
    test('strips the active user prefix on export', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setStringList('user_alice_library_order', const ['a', 'b']);
      await prefs.setBool('user_alice_hidden_libraries_does_not_exist', true);

      final out = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice');
      final p = out['prefs'] as Map<String, dynamic>;

      // Active user's keys land under their *base* names.
      expect(p, contains('library_order'));
      expect(p['library_order'], {
        'type': 'stringList',
        'value': ['a', 'b'],
      });
      // Anything else under user_ that *isn't* the active user is excluded —
      // the synthetic key above lives under "alice" and so it goes through.
      expect(p, contains('hidden_libraries_does_not_exist'));
    });

    test('skips other users\' scoped keys entirely', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setStringList('user_alice_library_order', const ['a']);
      await prefs.setStringList('user_bob_library_order', const ['b']);

      final out = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice');
      final p = out['prefs'] as Map<String, dynamic>;

      // alice's value made it through (stripped to base key).
      expect(p['library_order'], {
        'type': 'stringList',
        'value': ['a'],
      });
      // bob's was filtered out — there's no second pref with that name.
      expect(p.values.where((v) => (v as Map)['value'] is List && (v['value'] as List).contains('b')), isEmpty);
    });

    test('without currentUserUuid: every user_-prefixed key is skipped', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setStringList('user_alice_library_order', const ['a']);
      await prefs.setBool('global_flag', true);

      final out = SettingsExportService.buildExportMap(prefs); // no UUID
      final p = out['prefs'] as Map<String, dynamic>;

      expect(p, contains('global_flag'));
      // Every user_-scoped key is skipped because we have no active user.
      expect(p.keys.where((k) => k.startsWith('user_')), isEmpty);
      expect(p, isNot(contains('library_order')));
    });
  });

  // ============================================================
  // applyImportMap — version + structure validation
  // ============================================================

  group('applyImportMap validation', () {
    test('throws when formatVersion is missing or wrong type', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      // Missing
      expect(
        () => SettingsExportService.applyImportMap({'prefs': const <String, dynamic>{}}, prefs, currentUserUuid: 'u'),
        throwsA(isA<InvalidExportFileException>()),
      );
      // Wrong type
      expect(
        () => SettingsExportService.applyImportMap(
          {'formatVersion': 'one', 'prefs': const <String, dynamic>{}},
          prefs,
          currentUserUuid: 'u',
        ),
        throwsA(isA<InvalidExportFileException>()),
      );
    });

    test('throws when formatVersion is newer than the supported one', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      expect(
        () => SettingsExportService.applyImportMap(
          {'formatVersion': SettingsExportService.formatVersion + 1, 'prefs': const <String, dynamic>{}},
          prefs,
          currentUserUuid: 'u',
        ),
        throwsA(isA<InvalidExportFileException>()),
      );
    });

    test('throws when prefs is missing or not a map', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      expect(
        () => SettingsExportService.applyImportMap(
          {'formatVersion': SettingsExportService.formatVersion},
          prefs,
          currentUserUuid: 'u',
        ),
        throwsA(isA<InvalidExportFileException>()),
      );
      expect(
        () => SettingsExportService.applyImportMap(
          {'formatVersion': SettingsExportService.formatVersion, 'prefs': 'not-a-map'},
          prefs,
          currentUserUuid: 'u',
        ),
        throwsA(isA<InvalidExportFileException>()),
      );
    });
  });

  // ============================================================
  // applyImportMap — typed writes
  // ============================================================

  group('applyImportMap typed writes', () {
    test('writes bool / int / double / string / stringList back into prefs', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      final result = await SettingsExportService.applyImportMap(
        {
          'formatVersion': SettingsExportService.formatVersion,
          'prefs': {
            'a_flag': {'type': 'bool', 'value': true},
            'a_int': {'type': 'int', 'value': 7},
            'a_double': {'type': 'double', 'value': 1.5},
            'a_string': {'type': 'string', 'value': 'hi'},
            'a_list': {
              'type': 'stringList',
              'value': ['x', 'y'],
            },
          },
        },
        prefs,
        currentUserUuid: 'alice',
      );

      expect(result.keysImported, 5);
      expect(result.keysSkipped, 0);

      expect(prefs.getBool('a_flag'), isTrue);
      expect(prefs.getInt('a_int'), 7);
      expect(prefs.getDouble('a_double'), 1.5);
      expect(prefs.getString('a_string'), 'hi');
      expect(prefs.getStringList('a_list'), ['x', 'y']);
    });

    test('double accepts num input (importing an int as double)', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      final result = await SettingsExportService.applyImportMap(
        {
          'formatVersion': SettingsExportService.formatVersion,
          'prefs': {
            // Value is encoded as int but typed as double — should still write.
            'speed': {'type': 'double', 'value': 2},
          },
        },
        prefs,
        currentUserUuid: 'alice',
      );

      expect(result.keysImported, 1);
      expect(prefs.getDouble('speed'), 2.0);
    });

    test('skips entries with mismatched type/value pairs without throwing', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      final result = await SettingsExportService.applyImportMap(
        {
          'formatVersion': SettingsExportService.formatVersion,
          'prefs': {
            // bool with non-bool value
            'bad_bool': {'type': 'bool', 'value': 'yes'},
            // unknown type tag
            'bad_type': {'type': 'enum', 'value': 'foo'},
            // not a map at all
            'not_map': 'whatever',
            // missing type key
            'no_type': {'value': 1},
            // type isn't a string
            'type_not_str': {'type': 1, 'value': 1},
          },
        },
        prefs,
        currentUserUuid: 'alice',
      );

      expect(result.keysImported, 0);
      expect(result.keysSkipped, 5);
      // None of the bad keys ended up in prefs.
      expect(prefs.getBool('bad_bool'), isNull);
      expect(prefs.getString('bad_type'), isNull);
      expect(prefs.getString('not_map'), isNull);
    });

    test('skips deny-listed keys even if present in the import payload', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      final result = await SettingsExportService.applyImportMap(
        {
          'formatVersion': SettingsExportService.formatVersion,
          'prefs': {
            'plex_token': {'type': 'string', 'value': 'malicious'},
            'server_endpoint_srv': {'type': 'string', 'value': 'http://attacker.test'},
            'good_key': {'type': 'bool', 'value': true},
          },
        },
        prefs,
        currentUserUuid: 'alice',
      );

      expect(result.keysImported, 1);
      expect(result.keysSkipped, 2);
      expect(prefs.getString('plex_token'), isNull);
      expect(prefs.getString('server_endpoint_srv'), isNull);
      expect(prefs.getBool('good_key'), isTrue);
    });
  });

  // ============================================================
  // applyImportMap — user-scoped re-scoping
  // ============================================================

  group('applyImportMap user-scoping', () {
    test('re-applies the active user prefix to scoped base keys', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      final result = await SettingsExportService.applyImportMap(
        {
          'formatVersion': SettingsExportService.formatVersion,
          'prefs': {
            // exact-match scoped base keys
            'library_order': {
              'type': 'stringList',
              'value': ['a', 'b'],
            },
            'hidden_libraries': {'type': 'string', 'value': '["lib1"]'},
            // prefix-match scoped base keys
            'library_filters_section1': {'type': 'string', 'value': '{}'},
            'library_sort_section1': {'type': 'string', 'value': 'titleSort'},
            'library_grouping_section1': {'type': 'string', 'value': 'shows'},
            'library_tab_section1': {'type': 'string', 'value': 'recommended'},
            // global key — must NOT be scoped
            'enable_hardware_decoding': {'type': 'bool', 'value': true},
          },
        },
        prefs,
        currentUserUuid: 'alice',
      );

      expect(result.keysImported, 7);

      // Scoped keys land under user_alice_*
      expect(prefs.getStringList('user_alice_library_order'), ['a', 'b']);
      expect(prefs.getString('user_alice_hidden_libraries'), '["lib1"]');
      expect(prefs.getString('user_alice_library_filters_section1'), '{}');
      expect(prefs.getString('user_alice_library_sort_section1'), 'titleSort');
      expect(prefs.getString('user_alice_library_grouping_section1'), 'shows');
      expect(prefs.getString('user_alice_library_tab_section1'), 'recommended');

      // Global key stays unscoped.
      expect(prefs.getBool('enable_hardware_decoding'), isTrue);
      expect(prefs.getBool('user_alice_enable_hardware_decoding'), isNull);
    });
  });

  // ============================================================
  // Round-trip
  // ============================================================

  group('round-trip', () {
    test('build → JSON → parse → apply produces the same key/value/type', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();

      // Seed a representative mix.
      await prefs.setBool('enable_hardware_decoding', true);
      await prefs.setInt('seek_time_small', 15);
      await prefs.setDouble('volume', 0.75);
      await prefs.setString('preferred_video_codec', 'h264');
      await prefs.setStringList('shader_list', const ['a', 'b', 'c']);
      // User-scoped data for "alice".
      await prefs.setStringList('user_alice_library_order', const ['lib-1', 'lib-2']);
      // Credential we expect to be stripped.
      await prefs.setString('plex_token', 'never-this');

      // Export.
      final exportMap = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice', appVersion: '9.9.9');
      final encoded = json.encode(exportMap);

      // Wipe prefs to simulate a fresh device.
      await prefs.clear();
      // Confirm wipe.
      expect(prefs.getInt('seek_time_small'), isNull);
      expect(prefs.getStringList('user_alice_library_order'), isNull);

      // Parse back and import — same alice, so scoped keys round-trip cleanly.
      final decoded = json.decode(encoded) as Map<String, dynamic>;
      final result = await SettingsExportService.applyImportMap(decoded, prefs, currentUserUuid: 'alice');

      // 6 expected keys round-trip; the count includes the unrelated
      // `plezy_legacy_prefs_migrated_v1` flag the cache plants. We only assert
      // it is at LEAST our expected six keys, not an exact count.
      expect(result.keysImported, greaterThanOrEqualTo(6));
      expect(result.keysSkipped, 0);

      // Values restored under their original keys (with re-applied scoping).
      expect(prefs.getBool('enable_hardware_decoding'), isTrue);
      expect(prefs.getInt('seek_time_small'), 15);
      expect(prefs.getDouble('volume'), 0.75);
      expect(prefs.getString('preferred_video_codec'), 'h264');
      expect(prefs.getStringList('shader_list'), ['a', 'b', 'c']);
      expect(prefs.getStringList('user_alice_library_order'), ['lib-1', 'lib-2']);

      // Credential never came back.
      expect(prefs.getString('plex_token'), isNull);
    });

    test('cross-user round-trip: alice exports → bob imports → keys land under bob', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setStringList('user_alice_library_order', const ['lib-a', 'lib-b']);

      final exportMap = SettingsExportService.buildExportMap(prefs, currentUserUuid: 'alice');
      // Wipe alice's data.
      await prefs.clear();

      // Bob imports. Scoped base key gets re-applied with bob's prefix.
      final result = await SettingsExportService.applyImportMap(exportMap, prefs, currentUserUuid: 'bob');
      // The cache plants `plezy_legacy_prefs_migrated_v1` on first init, so
      // the export count includes that flag too. Just confirm the scoped
      // value made it through.
      expect(result.keysImported, greaterThanOrEqualTo(1));

      // Alice's data is now under bob's namespace.
      expect(prefs.getStringList('user_bob_library_order'), ['lib-a', 'lib-b']);
      expect(prefs.getStringList('user_alice_library_order'), isNull);
    });
  });

  // ============================================================
  // Exception types
  // ============================================================

  group('exception types', () {
    test('NoUserSignedInException is a SettingsExportException', () {
      const ex = NoUserSignedInException();
      expect(ex, isA<SettingsExportException>());
      expect(ex.toString(), contains('No user is signed in'));
    });

    test('InvalidExportFileException is a SettingsExportException with message', () {
      const ex = InvalidExportFileException('bad shape');
      expect(ex, isA<SettingsExportException>());
      expect(ex.toString(), contains('bad shape'));
    });
  });
}
