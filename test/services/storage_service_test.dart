import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/storage_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(resetSharedPreferencesForTest);

  group('StorageService.getInstance', () {
    test('returns same singleton instance', () async {
      final a = await StorageService.getInstance();
      final b = await StorageService.getInstance();
      expect(identical(a, b), isTrue);
    });

    test('reset rebuilds against current SharedPreferences', () async {
      final first = await StorageService.getInstance();
      await first.prefs.setString('plex_token', 'token-1');
      BaseSharedPreferencesService.resetForTesting();

      final second = await StorageService.getInstance();
      expect(identical(first, second), isFalse);
      // Reset only the cached singleton, not the underlying prefs — values survive.
      // ignore: deprecated_member_use_from_same_package
      expect(second.getPlexToken(), 'token-1');
    });
  });

  // ============================================================
  // Plex token / client identifier (legacy, retained for migration)
  // ============================================================

  group('PlexToken & ClientIdentifier (legacy migration slots)', () {
    test('getPlexToken reads the legacy slot', () async {
      final s = await StorageService.getInstance();
      // ignore: deprecated_member_use_from_same_package
      expect(s.getPlexToken(), isNull);
      await s.prefs.setString('plex_token', 'abc-123');
      // ignore: deprecated_member_use_from_same_package
      expect(s.getPlexToken(), 'abc-123');
    });

    test('getOrCreateClientIdentifier returns existing value when set', () async {
      final s = await StorageService.getInstance();
      await s.prefs.setString('client_identifier', 'preset-id');
      final result = await s.getOrCreateClientIdentifier();
      expect(result, 'preset-id');
    });

    test('getOrCreateClientIdentifier generates and persists a UUID on first call', () async {
      final s = await StorageService.getInstance();

      final generated = await s.getOrCreateClientIdentifier();
      expect(generated, isNotEmpty);
      // UUIDv4 has 5 hyphen-separated segments.
      expect(generated.split('-'), hasLength(5));

      // Second call returns the same value, not a new UUID.
      final again = await s.getOrCreateClientIdentifier();
      expect(again, generated);
    });

    test('getOrCreateClientIdentifier replaces empty stored value', () async {
      final s = await StorageService.getInstance();
      await s.prefs.setString('client_identifier', '');
      final generated = await s.getOrCreateClientIdentifier();
      expect(generated, isNotEmpty);
    });
  });

  // ============================================================
  // Server endpoints (per-server URL caching)
  // ============================================================

  group('ServerEndpoint', () {
    test('round-trip per server id', () async {
      final s = await StorageService.getInstance();
      await s.saveServerEndpoint('srv-1', 'http://192.0.2.1:32400');
      await s.saveServerEndpoint('srv-2', 'http://198.51.100.5:32400');

      expect(s.getServerEndpoint('srv-1'), 'http://192.0.2.1:32400');
      expect(s.getServerEndpoint('srv-2'), 'http://198.51.100.5:32400');
      expect(s.getServerEndpoint('missing'), isNull);
    });

    test('clearServerEndpoint removes only the targeted id', () async {
      final s = await StorageService.getInstance();
      await s.saveServerEndpoint('srv-1', 'http://example.test');
      await s.saveServerEndpoint('srv-2', 'http://other.test');
      await s.clearServerEndpoint('srv-1');
      expect(s.getServerEndpoint('srv-1'), isNull);
      expect(s.getServerEndpoint('srv-2'), 'http://other.test');
    });
  });

  // ============================================================
  // Multi-server slot (legacy, only `getServersListJson` retained for migration)
  // ============================================================

  group('Servers list (legacy migration slot)', () {
    test('legacy raw read returns null when nothing is stored', () async {
      final s = await StorageService.getInstance();
      // ignore: deprecated_member_use_from_same_package
      expect(s.getServersListJson(), isNull);
    });

    test('clearServersList removes the value', () async {
      final s = await StorageService.getInstance();
      // Write directly under the legacy key — the public setter is gone.
      await s.prefs.setString('servers_list', '[{"x":1}]');
      // ignore: deprecated_member_use_from_same_package
      expect(s.getServersListJson(), '[{"x":1}]');
      await s.clearServersList();
      // ignore: deprecated_member_use_from_same_package
      expect(s.getServersListJson(), isNull);
    });

    test('clearMultiServerData clears legacy list + order + endpoint prefixes', () async {
      final s = await StorageService.getInstance();
      // Write legacy values directly — the setters are gone.
      await s.prefs.setString('servers_list', '[{"x":1}]');
      await s.prefs.setString('server_order', json.encode(['a', 'b']));
      await s.saveServerEndpoint('a', 'http://foo.test');
      await s.saveServerEndpoint('b', 'http://bar.test');

      await s.clearMultiServerData();

      // ignore: deprecated_member_use_from_same_package
      expect(s.getServersListJson(), isNull);
      expect(s.prefs.getString('server_order'), isNull);
      expect(s.getServerEndpoint('a'), isNull);
      expect(s.getServerEndpoint('b'), isNull);
    });
  });

  // ============================================================
  // Hidden libraries (Set<String> persisted as JSON list)
  // ============================================================

  group('Hidden libraries', () {
    test('default is empty set', () async {
      final s = await StorageService.getInstance();
      expect(s.getHiddenLibraries(), isEmpty);
    });

    test('save + read round-trip', () async {
      final s = await StorageService.getInstance();
      await s.saveHiddenLibraries({'lib-a', 'lib-b'});
      expect(s.getHiddenLibraries(), equals({'lib-a', 'lib-b'}));
    });

    test('overwrite replaces previous set', () async {
      final s = await StorageService.getInstance();
      await s.saveHiddenLibraries({'lib-a', 'lib-b'});
      await s.saveHiddenLibraries({'lib-c'});
      expect(s.getHiddenLibraries(), equals({'lib-c'}));
    });

    test('saving empty set persists empty set (not null)', () async {
      final s = await StorageService.getInstance();
      await s.saveHiddenLibraries({'x'});
      await s.saveHiddenLibraries({});
      expect(s.getHiddenLibraries(), isEmpty);
    });

    test('survives garbage JSON by returning empty set', () async {
      final s = await StorageService.getInstance();
      // Write garbage directly under the key getHiddenLibraries() will read.
      await s.prefs.setString('hidden_libraries', 'not-json');
      expect(s.getHiddenLibraries(), isEmpty);
    });
  });

  // ============================================================
  // Library order (List<String>) — scoped to active profile
  // ============================================================

  group('Library order', () {
    test('default is null', () async {
      final s = await StorageService.getInstance();
      expect(s.getLibraryOrder(), isNull);
    });

    test('round-trip preserves order', () async {
      final s = await StorageService.getInstance();
      await s.saveLibraryOrder(['c', 'a', 'b']);
      expect(s.getLibraryOrder(), ['c', 'a', 'b']);
    });

    test('legacy unscoped value migrates into scoped key when an active profile is set', () async {
      final s = await StorageService.getInstance();

      // Write a legacy (unscoped) library order, mimicking pre-multi-user data.
      await s.prefs.setString('library_order', json.encode(['x', 'y']));

      // Set an active profile so reads/writes become scoped.
      await s.setActiveProfileId('local-user-1');

      final read = s.getLibraryOrder();
      expect(read, ['x', 'y']);

      // Migration should have copied the legacy value under the scoped key.
      final scopedRaw = s.prefs.getString('user_local-user-1_library_order');
      expect(scopedRaw, json.encode(['x', 'y']));
      expect(s.prefs.getString('library_order'), isNull);
    });

    test('migrated legacy order is not inherited by another profile', () async {
      final s = await StorageService.getInstance();
      await s.prefs.setString('library_order', json.encode(['legacy']));

      await s.setActiveProfileId('local-user-1');
      expect(s.getLibraryOrder(), ['legacy']);

      await s.setActiveProfileId('local-user-2');
      expect(s.getLibraryOrder(), isNull);
    });

    test('per-user scoping isolates orders', () async {
      final s = await StorageService.getInstance();

      await s.setActiveProfileId('local-user-1');
      await s.saveLibraryOrder(['u1-a', 'u1-b']);

      await s.setActiveProfileId('local-user-2');
      expect(s.getLibraryOrder(), isNull);
      await s.saveLibraryOrder(['u2-a']);

      // Switch back — user-1 sees their own list.
      await s.setActiveProfileId('local-user-1');
      expect(s.getLibraryOrder(), ['u1-a', 'u1-b']);

      await s.setActiveProfileId('local-user-2');
      expect(s.getLibraryOrder(), ['u2-a']);
    });

    test('plex_home profile id parses out the home-user UUID for the prefix', () async {
      final s = await StorageService.getInstance();
      // Format: `plex-home-{accountConnectionId}-{homeUserUuid}` where both
      // the accountConnectionId AND the UUID contain hyphens. The scope must
      // be the FULL 36-char UUID — `lastIndexOf('-')` would slice inside the
      // UUID and break legacy `currentUserUUID`-scoped storage migration.
      await s.setActiveProfileId('plex-home-plex.abc-def-123-aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
      await s.saveLibraryOrder(['x']);
      expect(s.prefs.getString('user_aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee_library_order'), json.encode(['x']));
    });

    test('legacy currentUserUUID scope migrates into the plex-home profile slot', () async {
      // Regression: with the old `lastIndexOf('-')` parser, the scope was
      // only the trailing 12 hex chars of the UUID, so the per-user prefs
      // written under the legacy `currentUserUUID` (which used the FULL
      // UUID as the prefix) would not be picked up after migration.
      final s = await StorageService.getInstance();
      const uuid = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

      // Pre-seed the legacy per-user-scoped order under the full UUID.
      await s.prefs.setString('user_${uuid}_library_order', json.encode(['legacy']));

      await s.setActiveProfileId('plex-home-plex.abc-def-123-$uuid');
      expect(s.getLibraryOrder(), ['legacy']);
    });
  });

  // ============================================================
  // Library filters / sort / grouping / tab
  // ============================================================

  group('Library filters / sort / grouping / tab', () {
    test('global filters round-trip', () async {
      final s = await StorageService.getInstance();
      expect(s.getLibraryFilters(), isEmpty);
      await s.saveLibraryFilters({'genre': 'sci-fi', 'year': '2024'});
      expect(s.getLibraryFilters(), {'genre': 'sci-fi', 'year': '2024'});
    });

    test('per-section filters fall back to global when missing', () async {
      final s = await StorageService.getInstance();
      await s.saveLibraryFilters({'global': 'true'});
      expect(s.getLibraryFilters(sectionId: 'sec-1'), {'global': 'true'});

      await s.saveLibraryFilters({'genre': 'horror'}, sectionId: 'sec-1');
      expect(s.getLibraryFilters(sectionId: 'sec-1'), {'genre': 'horror'});
      expect(s.getLibraryFilters(), {'global': 'true'});
    });

    test('legacy per-section filters migrate once into scoped key', () async {
      final s = await StorageService.getInstance();
      await s.prefs.setString('library_filters_sec-1', json.encode({'genre': 'drama'}));

      await s.setActiveProfileId('local-user-1');
      expect(s.getLibraryFilters(sectionId: 'sec-1'), {'genre': 'drama'});
      expect(s.prefs.getString('user_local-user-1_library_filters_sec-1'), json.encode({'genre': 'drama'}));
      expect(s.prefs.getString('library_filters_sec-1'), isNull);

      await s.setActiveProfileId('local-user-2');
      expect(s.getLibraryFilters(sectionId: 'sec-1'), isEmpty);
    });

    test('library sort round-trips with descending flag', () async {
      final s = await StorageService.getInstance();
      await s.saveLibrarySort('sec-1', 'titleSort', descending: true);
      expect(s.getLibrarySort('sec-1'), {'key': 'titleSort', 'descending': true});

      await s.saveLibrarySort('sec-1', 'addedAt');
      expect(s.getLibrarySort('sec-1'), {'key': 'addedAt', 'descending': false});
    });

    test('library sort: legacy plain-string value migrates to map shape', () async {
      final s = await StorageService.getInstance();
      // Pre-existing legacy plain string under the unscoped key.
      await s.prefs.setString('library_sort_sec-1', 'titleSort');
      // _readJsonMap with legacyStringOk=true should normalize to the map shape.
      final result = s.getLibrarySort('sec-1');
      expect(result, {'key': 'titleSort', 'descending': false});
    });

    test('library grouping round-trips', () async {
      final s = await StorageService.getInstance();
      expect(s.getLibraryGrouping('sec-1'), isNull);
      await s.saveLibraryGrouping('sec-1', 'shows');
      expect(s.getLibraryGrouping('sec-1'), 'shows');
    });

    test('library tab round-trips', () async {
      final s = await StorageService.getInstance();
      expect(s.getLibraryTab('sec-1'), isNull);
      await s.saveLibraryTab('sec-1', 'recommended');
      expect(s.getLibraryTab('sec-1'), 'recommended');
    });

    test('saveSelectedLibraryKey + getSelectedLibraryKey round-trip', () async {
      final s = await StorageService.getInstance();
      expect(s.getSelectedLibraryKey(), isNull);
      await s.saveSelectedLibraryKey('lib-key-42');
      expect(s.getSelectedLibraryKey(), 'lib-key-42');
    });
  });

  // ============================================================
  // Current user UUID (legacy slot retained for migration)
  // ============================================================

  group('CurrentUserUUID (legacy migration slot)', () {
    test('clearCurrentUserUUID wipes the slot', () async {
      final s = await StorageService.getInstance();
      await s.prefs.setString('current_user_uuid', 'u-1');
      // ignore: deprecated_member_use_from_same_package
      expect(s.getCurrentUserUUID(), 'u-1');
      await s.clearCurrentUserUUID();
      // ignore: deprecated_member_use_from_same_package
      expect(s.getCurrentUserUUID(), isNull);
    });
  });

  // ============================================================
  // Episode count persistence (prefix-based)
  // ============================================================

  group('Episode counts', () {
    test('per-key round-trip', () async {
      final s = await StorageService.getInstance();
      await s.saveTotalEpisodeCount('srv:show-1', 12);
      await s.saveTotalEpisodeCount('srv:show-2', 24);
      expect(s.getTotalEpisodeCount('srv:show-1'), 12);
      expect(s.getTotalEpisodeCount('srv:show-2'), 24);
      expect(s.getTotalEpisodeCount('srv:missing'), isNull);
    });

    test('loadAllEpisodeCounts returns every persisted entry', () async {
      final s = await StorageService.getInstance();
      await s.saveTotalEpisodeCount('srv:s1', 1);
      await s.saveTotalEpisodeCount('srv:s2', 2);
      // Unrelated keys must not bleed in.
      await s.prefs.setString('plex_token', 'tok');

      final counts = s.loadAllEpisodeCounts();
      expect(counts, {'srv:s1': 1, 'srv:s2': 2});
    });

    test('removeEpisodeCount deletes only the targeted entry', () async {
      final s = await StorageService.getInstance();
      await s.saveTotalEpisodeCount('srv:s1', 1);
      await s.saveTotalEpisodeCount('srv:s2', 2);
      await s.removeEpisodeCount('srv:s1');
      expect(s.getTotalEpisodeCount('srv:s1'), isNull);
      expect(s.getTotalEpisodeCount('srv:s2'), 2);
    });
  });

  // ============================================================
  // clearCredentials
  // ============================================================

  group('clearCredentials', () {
    test('removes credential keys, plex token, and multi-server data', () async {
      final s = await StorageService.getInstance();

      // Seed every legacy slot directly — the runtime setters were removed
      // when we collapsed the legacy/new dual-write.
      await s.prefs.setString('plex_token', 'tok-x');
      await s.prefs.setString('client_identifier', 'client-x');
      await s.prefs.setString('servers_list', '[{"x":1}]');
      await s.prefs.setString('server_order', json.encode(['a']));
      await s.saveServerEndpoint('a', 'http://foo.test');

      // Library prefs and unrelated counters: write WITHOUT an active profile id
      // so they land on the legacy unscoped key.
      await s.saveLibraryOrder(['lib-1']);
      await s.saveTotalEpisodeCount('srv:s1', 7);

      // Now seed current_user_uuid — clearCredentials should remove this.
      await s.prefs.setString('current_user_uuid', 'u-x');

      await s.clearCredentials();

      // Credential-bucket keys all gone.
      // ignore: deprecated_member_use_from_same_package
      expect(s.getPlexToken(), isNull);
      expect(s.prefs.getString('client_identifier'), isNull);
      // ignore: deprecated_member_use_from_same_package
      expect(s.getCurrentUserUUID(), isNull);

      // Multi-server data wiped.
      // ignore: deprecated_member_use_from_same_package
      expect(s.getServersListJson(), isNull);
      expect(s.prefs.getString('server_order'), isNull);
      expect(s.getServerEndpoint('a'), isNull);

      // Library prefs and unrelated state untouched (no scope active, so
      // the scoped read falls through to the same legacy key it was written to).
      expect(s.getLibraryOrder(), ['lib-1']);
      expect(s.getTotalEpisodeCount('srv:s1'), 7);
    });
  });

  // ============================================================
  // clearLibraryPreferences (user-scoped)
  // ============================================================

  group('clearLibraryPreferences', () {
    test('clears scoped library keys for current user only', () async {
      final s = await StorageService.getInstance();

      // user-1's library prefs
      await s.setActiveProfileId('local-user-1');
      await s.saveLibraryOrder(['u1-a', 'u1-b']);
      await s.saveSelectedLibraryKey('u1-key');
      await s.saveLibraryFilters({'genre': 'horror'}, sectionId: 'sec-1');
      await s.saveLibrarySort('sec-1', 'titleSort', descending: true);
      await s.saveLibraryGrouping('sec-1', 'shows');
      await s.saveLibraryTab('sec-1', 'tabA');
      await s.saveHiddenLibraries({'h-1'});

      // user-2's library prefs (must not be touched by clearing user-1)
      await s.setActiveProfileId('local-user-2');
      await s.saveLibraryOrder(['u2-a']);
      await s.saveSelectedLibraryKey('u2-key');

      // Clear user-2 first to ensure user-2 keys are gone, then verify user-1's intact.
      await s.clearLibraryPreferences();
      expect(s.getLibraryOrder(), isNull);
      expect(s.getSelectedLibraryKey(), isNull);

      await s.setActiveProfileId('local-user-1');
      expect(s.getLibraryOrder(), ['u1-a', 'u1-b']);
      expect(s.getSelectedLibraryKey(), 'u1-key');
      expect(s.getLibraryFilters(sectionId: 'sec-1'), {'genre': 'horror'});
      expect(s.getLibrarySort('sec-1'), {'key': 'titleSort', 'descending': true});
      expect(s.getLibraryGrouping('sec-1'), 'shows');
      expect(s.getLibraryTab('sec-1'), 'tabA');
      expect(s.getHiddenLibraries(), {'h-1'});

      // Now clear user-1 and confirm everything for that user goes away.
      await s.clearLibraryPreferences();
      expect(s.getLibraryOrder(), isNull);
      expect(s.getSelectedLibraryKey(), isNull);
      expect(s.getLibraryFilters(sectionId: 'sec-1'), isEmpty);
      expect(s.getLibrarySort('sec-1'), isNull);
      expect(s.getLibraryGrouping('sec-1'), isNull);
      expect(s.getLibraryTab('sec-1'), isNull);
      expect(s.getHiddenLibraries(), isEmpty);
    });

    test('clearing scoped prefs also consumes pending legacy values', () async {
      final s = await StorageService.getInstance();
      await s.prefs.setString('library_order', json.encode(['legacy']));
      await s.prefs.setString('library_filters_sec-1', json.encode({'genre': 'drama'}));

      await s.setActiveProfileId('local-user-1');
      await s.clearLibraryPreferences();

      expect(s.getLibraryOrder(), isNull);
      expect(s.getLibraryFilters(sectionId: 'sec-1'), isEmpty);
      expect(s.prefs.getString('library_order'), isNull);
      expect(s.prefs.getString('library_filters_sec-1'), isNull);
    });
  });

  // ============================================================
  // clearUserData = clearCredentials + clearLibraryPreferences
  // ============================================================

  group('clearUserData', () {
    test('combines credentials and library-preferences clear', () async {
      final s = await StorageService.getInstance();

      await s.prefs.setString('plex_token', 'tok');
      await s.setActiveProfileId('local-user-1');
      await s.saveLibraryOrder(['lib-a']);
      await s.saveHiddenLibraries({'h-1'});

      await s.clearUserData();

      // ignore: deprecated_member_use_from_same_package
      expect(s.getPlexToken(), isNull);
      // setActiveProfileId is unaffected by clearCredentials, so the prefix
      // is still active — clearLibraryPreferences cleared the scoped values.
      expect(s.getLibraryOrder(), isNull);
      expect(s.getHiddenLibraries(), isEmpty);
    });
  });
}
