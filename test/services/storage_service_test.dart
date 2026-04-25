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
      await first.savePlexToken('token-1');
      BaseSharedPreferencesService.resetForTesting();

      final second = await StorageService.getInstance();
      expect(identical(first, second), isFalse);
      // Reset only the cached singleton, not the underlying prefs — values survive.
      expect(second.getPlexToken(), 'token-1');
    });
  });

  // ============================================================
  // Plex token / client identifier
  // ============================================================

  group('PlexToken & ClientIdentifier', () {
    test('savePlexToken persists value', () async {
      final s = await StorageService.getInstance();
      expect(s.getPlexToken(), isNull);
      await s.savePlexToken('abc-123');
      expect(s.getPlexToken(), 'abc-123');
    });

    test('saveClientIdentifier persists value', () async {
      final s = await StorageService.getInstance();
      expect(s.getClientIdentifier(), isNull);
      await s.saveClientIdentifier('client-xyz');
      expect(s.getClientIdentifier(), 'client-xyz');
    });

    test('getOrCreateClientIdentifier returns existing value when set', () async {
      final s = await StorageService.getInstance();
      await s.saveClientIdentifier('preset-id');
      final result = await s.getOrCreateClientIdentifier();
      expect(result, 'preset-id');
      expect(s.getClientIdentifier(), 'preset-id');
    });

    test('getOrCreateClientIdentifier generates and persists a UUID on first call', () async {
      final s = await StorageService.getInstance();
      expect(s.getClientIdentifier(), isNull);

      final generated = await s.getOrCreateClientIdentifier();
      expect(generated, isNotEmpty);
      // UUIDv4 has 5 hyphen-separated segments.
      expect(generated.split('-'), hasLength(5));
      expect(s.getClientIdentifier(), generated);

      // Second call returns the same value, not a new UUID.
      final again = await s.getOrCreateClientIdentifier();
      expect(again, generated);
    });

    test('getOrCreateClientIdentifier replaces empty stored value', () async {
      final s = await StorageService.getInstance();
      await s.saveClientIdentifier('');
      final generated = await s.getOrCreateClientIdentifier();
      expect(generated, isNotEmpty);
      expect(s.getClientIdentifier(), generated);
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
  // Multi-server JSON list & order
  // ============================================================

  group('Servers list & order', () {
    test('servers list JSON round-trips', () async {
      final s = await StorageService.getInstance();
      expect(s.getServersListJson(), isNull);
      const payload = '[{"name":"home"}]';
      await s.saveServersListJson(payload);
      expect(s.getServersListJson(), payload);
    });

    test('clearServersList removes the value', () async {
      final s = await StorageService.getInstance();
      await s.saveServersListJson('[{"x":1}]');
      await s.clearServersList();
      expect(s.getServersListJson(), isNull);
    });

    test('server order round-trips and clears', () async {
      final s = await StorageService.getInstance();
      expect(s.getServerOrder(), isNull);

      await s.saveServerOrder(['srv-2', 'srv-1', 'srv-3']);
      expect(s.getServerOrder(), ['srv-2', 'srv-1', 'srv-3']);

      await s.clearServerOrder();
      expect(s.getServerOrder(), isNull);
    });

    test('clearMultiServerData clears list + order + endpoint prefixes', () async {
      final s = await StorageService.getInstance();
      await s.saveServersListJson('[{"x":1}]');
      await s.saveServerOrder(['a', 'b']);
      await s.saveServerEndpoint('a', 'http://foo.test');
      await s.saveServerEndpoint('b', 'http://bar.test');

      await s.clearMultiServerData();

      expect(s.getServersListJson(), isNull);
      expect(s.getServerOrder(), isNull);
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
  // Library order (List<String>)
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

    test('legacy unscoped value migrates into scoped key when user UUID is set', () async {
      final s = await StorageService.getInstance();

      // Write a legacy (unscoped) library order, mimicking pre-multi-user data.
      await s.prefs.setString('library_order', json.encode(['x', 'y']));

      // Set a current user UUID so reads/writes become scoped.
      await s.saveCurrentUserUUID('user-1');

      final read = s.getLibraryOrder();
      expect(read, ['x', 'y']);

      // Migration should have copied the legacy value under the scoped key.
      final scopedRaw = s.prefs.getString('user_user-1_library_order');
      expect(scopedRaw, json.encode(['x', 'y']));
    });

    test('per-user scoping isolates orders', () async {
      final s = await StorageService.getInstance();

      await s.saveCurrentUserUUID('user-1');
      await s.saveLibraryOrder(['u1-a', 'u1-b']);

      await s.saveCurrentUserUUID('user-2');
      expect(s.getLibraryOrder(), isNull);
      await s.saveLibraryOrder(['u2-a']);

      // Switch back — user-1 sees their own list.
      await s.saveCurrentUserUUID('user-1');
      expect(s.getLibraryOrder(), ['u1-a', 'u1-b']);

      await s.saveCurrentUserUUID('user-2');
      expect(s.getLibraryOrder(), ['u2-a']);
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
  // User profile / UUID
  // ============================================================

  group('User profile & UUID', () {
    test('saveUserProfile + getUserProfile round-trip preserves nested data', () async {
      final s = await StorageService.getInstance();
      expect(s.getUserProfile(), isNull);
      final profile = {'id': 1, 'username': 'edde', 'email': 'e@example.test'};
      await s.saveUserProfile(profile);
      expect(s.getUserProfile(), profile);
    });

    test('saveCurrentUserUUID + clearCurrentUserUUID', () async {
      final s = await StorageService.getInstance();
      await s.saveCurrentUserUUID('u-1');
      expect(s.getCurrentUserUUID(), 'u-1');
      await s.clearCurrentUserUUID();
      expect(s.getCurrentUserUUID(), isNull);
    });
  });

  // ============================================================
  // Home users cache (TTL)
  // ============================================================

  group('Home users cache', () {
    test('saved cache is readable while non-expired', () async {
      final s = await StorageService.getInstance();
      await s.saveHomeUsersCache({'users': []});
      expect(s.getHomeUsersCache(), {'users': []});
    });

    test('expired cache returns null and self-clears', () async {
      final s = await StorageService.getInstance();
      await s.saveHomeUsersCache({'users': []});
      // Force-expire the cache by writing a past timestamp under the expiry key.
      await s.prefs.setInt('home_users_cache_expiry', DateTime.now().millisecondsSinceEpoch - 1000);
      expect(s.getHomeUsersCache(), isNull);
      // After self-clear, both keys are gone.
      expect(s.prefs.getString('home_users_cache'), isNull);
      expect(s.prefs.getInt('home_users_cache_expiry'), isNull);
    });

    test('clearHomeUsersCache removes both data and expiry', () async {
      final s = await StorageService.getInstance();
      await s.saveHomeUsersCache({'users': []});
      await s.clearHomeUsersCache();
      expect(s.getHomeUsersCache(), isNull);
      expect(s.prefs.getString('home_users_cache'), isNull);
      expect(s.prefs.getInt('home_users_cache_expiry'), isNull);
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
      await s.savePlexToken('tok');

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

      await s.savePlexToken('tok-x');
      await s.saveClientIdentifier('client-x');
      await s.saveUserProfile({'id': 99});
      await s.saveHomeUsersCache({'users': []});
      await s.saveServersListJson('[{"x":1}]');
      await s.saveServerOrder(['a']);
      await s.saveServerEndpoint('a', 'http://foo.test');

      // Library prefs and unrelated counters: write WITHOUT a current-user UUID
      // so they land on the legacy unscoped key. The credentials clear path
      // wipes current_user_uuid; we want to confirm library data is untouched.
      await s.saveLibraryOrder(['lib-1']);
      await s.saveTotalEpisodeCount('srv:s1', 7);

      // Now set a user UUID — clearCredentials should remove this.
      await s.saveCurrentUserUUID('u-x');

      await s.clearCredentials();

      // Credential-bucket keys all gone.
      expect(s.getPlexToken(), isNull);
      expect(s.getClientIdentifier(), isNull);
      expect(s.getCurrentUserUUID(), isNull);
      expect(s.getUserProfile(), isNull);

      // Multi-server data wiped.
      expect(s.getServersListJson(), isNull);
      expect(s.getServerOrder(), isNull);
      expect(s.getServerEndpoint('a'), isNull);

      // Library prefs and unrelated state untouched (user UUID is gone, so
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
      await s.saveCurrentUserUUID('user-1');
      await s.saveLibraryOrder(['u1-a', 'u1-b']);
      await s.saveSelectedLibraryKey('u1-key');
      await s.saveLibraryFilters({'genre': 'horror'}, sectionId: 'sec-1');
      await s.saveLibrarySort('sec-1', 'titleSort', descending: true);
      await s.saveLibraryGrouping('sec-1', 'shows');
      await s.saveLibraryTab('sec-1', 'tabA');
      await s.saveHiddenLibraries({'h-1'});

      // user-2's library prefs (must not be touched by clearing user-1)
      await s.saveCurrentUserUUID('user-2');
      await s.saveLibraryOrder(['u2-a']);
      await s.saveSelectedLibraryKey('u2-key');

      // Clear user-2 first to ensure user-2 keys are gone, then verify user-1's intact.
      await s.clearLibraryPreferences();
      expect(s.getLibraryOrder(), isNull);
      expect(s.getSelectedLibraryKey(), isNull);

      await s.saveCurrentUserUUID('user-1');
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
  });

  // ============================================================
  // clearUserData = clearCredentials + clearLibraryPreferences
  // ============================================================

  group('clearUserData', () {
    test('combines credentials and library-preferences clear', () async {
      final s = await StorageService.getInstance();

      await s.savePlexToken('tok');
      await s.saveCurrentUserUUID('user-1');
      await s.saveLibraryOrder(['lib-a']);
      await s.saveHiddenLibraries({'h-1'});

      await s.clearUserData();

      expect(s.getPlexToken(), isNull);
      // current_user_uuid is part of the credentials bucket; clearing it
      // means the scoped-key prefix flips to empty and reads return null.
      expect(s.getCurrentUserUUID(), isNull);
      expect(s.getLibraryOrder(), isNull);
      expect(s.getHiddenLibraries(), isEmpty);
    });
  });
}
