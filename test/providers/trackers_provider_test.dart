import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/trackers/anilist/anilist_account_store.dart';
import 'package:plezy/services/trackers/anilist/anilist_session.dart';
import 'package:plezy/services/trackers/mal/mal_account_store.dart';
import 'package:plezy/services/trackers/mal/mal_session.dart';
import 'package:plezy/services/trackers/simkl/simkl_account_store.dart';
import 'package:plezy/services/trackers/simkl/simkl_session.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';

import '../test_helpers/prefs.dart';

MalSession _mal({String? username}) => MalSession(
  accessToken: 'mal-at',
  refreshToken: 'mal-rt',
  expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
  createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  username: username,
);

AnilistSession _anilist({String? username}) => AnilistSession(
  accessToken: 'anilist-at',
  expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
  createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  username: username,
);

SimklSession _simkl({String? username}) =>
    SimklSession(accessToken: 'simkl-at', createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000, username: username);

void main() {
  setUp(resetSharedPreferencesForTest);

  group('TrackersProvider', () {
    test('starts with all trackers disconnected', () {
      final p = TrackersProvider();
      expect(p.mal, isNull);
      expect(p.anilist, isNull);
      expect(p.simkl, isNull);
      expect(p.isMalConnected, isFalse);
      expect(p.isAnilistConnected, isFalse);
      expect(p.isSimklConnected, isFalse);
      expect(p.malUsername, isNull);
      expect(p.anilistUsername, isNull);
      expect(p.simklUsername, isNull);
      expect(p.isConnecting(TrackerService.mal), isFalse);
      expect(p.isConnecting(TrackerService.anilist), isFalse);
      expect(p.isConnecting(TrackerService.simkl), isFalse);
      p.dispose();
    });

    test('onActiveProfileChanged loads sessions from per-profile stores', () async {
      const uuid = 'profile-1';
      await malAccountStore.save(uuid, _mal(username: 'alice'));
      await anilistAccountStore.save(uuid, _anilist(username: 'bob'));
      await simklAccountStore.save(uuid, _simkl(username: 'carol'));

      // Reset cached singletons so the provider reads fresh prefs state.
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      var notified = 0;
      p.addListener(() => notified++);

      await p.onActiveProfileChanged(uuid);
      expect(p.isMalConnected, isTrue);
      expect(p.isAnilistConnected, isTrue);
      expect(p.isSimklConnected, isTrue);
      expect(p.malUsername, 'alice');
      expect(p.anilistUsername, 'bob');
      expect(p.simklUsername, 'carol');
      expect(notified, greaterThanOrEqualTo(1));

      p.dispose();
    });

    test('onActiveProfileChanged switching to empty profile clears all sessions', () async {
      const uuid = 'profile-1';
      await malAccountStore.save(uuid, _mal(username: 'alice'));
      await anilistAccountStore.save(uuid, _anilist(username: 'bob'));
      await simklAccountStore.save(uuid, _simkl(username: 'carol'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await p.onActiveProfileChanged(uuid);
      expect(p.isMalConnected, isTrue);

      await p.onActiveProfileChanged('other-profile');
      expect(p.isMalConnected, isFalse);
      expect(p.isAnilistConnected, isFalse);
      expect(p.isSimklConnected, isFalse);

      p.dispose();
    });

    test('onActiveProfileChanged loads only the populated stores', () async {
      const uuid = 'profile-2';
      // Only AniList is set up — MAL and Simkl remain absent.
      await anilistAccountStore.save(uuid, _anilist(username: 'bob'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await p.onActiveProfileChanged(uuid);
      expect(p.isAnilistConnected, isTrue);
      expect(p.anilistUsername, 'bob');
      expect(p.isMalConnected, isFalse);
      expect(p.isSimklConnected, isFalse);
      p.dispose();
    });

    test('disconnectMal clears stored session and notifies', () async {
      const uuid = 'profile-3';
      await malAccountStore.save(uuid, _mal(username: 'alice'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await p.onActiveProfileChanged(uuid);
      expect(p.isMalConnected, isTrue);

      var notified = 0;
      p.addListener(() => notified++);

      await p.disconnectMal();
      expect(p.isMalConnected, isFalse);
      expect(p.mal, isNull);
      // _clearAndRebind notifies once.
      expect(notified, 1);

      // Persistence is cleared too.
      expect(await malAccountStore.load(uuid), isNull);

      p.dispose();
    });

    test('disconnectAnilist clears anilist while leaving MAL intact', () async {
      const uuid = 'profile-4';
      await malAccountStore.save(uuid, _mal(username: 'alice'));
      await anilistAccountStore.save(uuid, _anilist(username: 'bob'));
      BaseSharedPreferencesService.resetForTesting();

      final p = TrackersProvider();
      await p.onActiveProfileChanged(uuid);

      await p.disconnectAnilist();
      expect(p.isAnilistConnected, isFalse);
      expect(p.isMalConnected, isTrue);
      expect(p.malUsername, 'alice');

      p.dispose();
    });

    test('disconnectSimkl on a profile with no session is safe', () async {
      final p = TrackersProvider();
      // No `onActiveProfileChanged` — uuid is empty (global slot).
      // disconnectSimkl just clears the (already absent) entry and rebinds.
      await p.disconnectSimkl();
      expect(p.isSimklConnected, isFalse);
      p.dispose();
    });

    test('cancelConnect is a no-op when not connecting', () {
      final p = TrackersProvider();
      expect(() => p.cancelConnect(), returnsNormally);
      expect(p.isConnecting(TrackerService.mal), isFalse);
      p.dispose();
    });

    test('safeNotifyListeners after dispose is a no-op', () async {
      final p = TrackersProvider();
      p.dispose();
      // Post-dispose rebind should not throw.
      await p.onActiveProfileChanged('any-uuid');
    });
  });
}
