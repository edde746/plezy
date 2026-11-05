import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/trackers/tracker_account_store.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/tracker_session.dart';

import '../../test_helpers/prefs.dart';

const _fullProfileId = 'plex-home-plex.e443d57860076fc3-e443d57860076fc3';
const _homeUserUuid = 'e443d57860076fc3';

TrackerSession _session() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  return TrackerSession(accessToken: 'a', refreshToken: 'r', expiresAt: now + 86400, createdAt: now);
}

void main() {
  setUp(resetSharedPreferencesForTest);

  group('reconnect status', () {
    final store = trackerAccountStore(TrackerService.trakt);

    test('a service that was never connected does not need reconnecting', () async {
      expect(await store.loadState(_fullProfileId), (session: null, needsReconnect: false));
    });

    test('invalidation removes credentials and survives a cache restart in the same user scope', () async {
      await store.save(_fullProfileId, _session());
      await store.markNeedsReconnect(_fullProfileId);
      BaseSharedPreferencesService.resetForTesting();

      expect(await store.loadState(_homeUserUuid), (session: null, needsReconnect: true));
      expect(await store.loadState('another-profile'), (session: null, needsReconnect: false));
      final prefs = await BaseSharedPreferencesService.sharedCache();
      expect(prefs.getString('user_${_homeUserUuid}_trakt_session'), isNull);
      expect(prefs.getBool('user_${_homeUserUuid}_trakt_session_needs_reconnect'), isTrue);
    });

    test('a reconnect saved immediately after invalidation wins over both invalidation writes', () async {
      await store.save(_fullProfileId, _session());
      final invalidating = store.markNeedsReconnect(_fullProfileId);
      final reconnecting = store.save(_fullProfileId, _session());
      // A read started during the writes must see their final state, not the
      // old credentials or a half-written warning.
      final loading = store.loadState(_fullProfileId);
      await Future.wait([invalidating, reconnecting]);

      final state = await loading;
      expect(state.session?.accessToken, 'a');
      expect(state.needsReconnect, isFalse);
    });

    test('explicit disconnect clears the warning without affecting another profile', () async {
      await store.markNeedsReconnect(_fullProfileId);
      await store.markNeedsReconnect('another-profile');
      await store.clear(_fullProfileId);

      expect(await store.loadState(_fullProfileId), (session: null, needsReconnect: false));
      expect(await store.loadState('another-profile'), (session: null, needsReconnect: true));
    });

    test('a warning recorded before credential removal takes precedence over the stale token', () async {
      await store.save(_fullProfileId, _session());
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setBool('user_${_homeUserUuid}_trakt_session_needs_reconnect', true);

      expect(await store.loadState(_fullProfileId), (session: null, needsReconnect: true));
    });

    test('an unusable saved connection is explained instead of treated as never connected', () async {
      final prefs = await BaseSharedPreferencesService.sharedCache();
      await prefs.setString('user_${_homeUserUuid}_trakt_session', '{truncated');

      expect(await store.loadState(_fullProfileId), (session: null, needsReconnect: true));
      await store.clear(_fullProfileId);
      expect(await store.loadState(_fullProfileId), (session: null, needsReconnect: false));
    });
  });

  group('profile user scoping', () {
    test('profileUserScope reduces Plex Home ids to the bare home-user uuid', () {
      expect(profileUserScope(_fullProfileId), _homeUserUuid);
      expect(profileUserScope(_homeUserUuid), _homeUserUuid);
      expect(profileUserScope('local-abc'), 'local-abc');
    });

    test('profileScopedPrefsKey normalizes full profile ids to the uuid scope', () {
      expect(profileScopedPrefsKey(_fullProfileId, 'trakt_session'), 'user_${_homeUserUuid}_trakt_session');
      expect(profileScopedPrefsKey(_homeUserUuid, 'trakt_session'), 'user_${_homeUserUuid}_trakt_session');
      expect(profileScopedPrefsKey('', 'trakt_session'), 'trakt_session');
    });

    /// Regression: sessions saved under the full profile id were relocated to
    /// the uuid scope by StorageService's launch-time repair, so the next
    /// hydrate (same full id) missed them — Trakt "unlinked" on every
    /// restart. Save and load must agree on the uuid scope regardless of
    /// which id form the caller passes.
    test('store writes the uuid-scoped key and loads it from either id form', () async {
      final store = trackerAccountStore(TrackerService.trakt);
      await store.save(_fullProfileId, _session());

      final prefs = await BaseSharedPreferencesService.sharedCache();
      expect(prefs.getString('user_${_homeUserUuid}_trakt_session'), isNotNull);
      expect(prefs.getString('user_${_fullProfileId}_trakt_session'), isNull);

      expect(await store.load(_fullProfileId), isNotNull);
      expect(await store.load(_homeUserUuid), isNotNull);

      await store.clear(_fullProfileId);
      expect(await store.load(_homeUserUuid), isNull);
    });
  });
}
