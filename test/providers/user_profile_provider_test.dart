import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex_home.dart';
import 'package:plezy/models/plex_home_user.dart';
import 'package:plezy/providers/user_profile_provider.dart';
import 'package:plezy/services/storage_service.dart';

import '../test_helpers/prefs.dart';

PlexHomeUser _user({
  required int id,
  String? uuid,
  String title = 'Title',
  bool admin = false,
  bool protected = false,
}) {
  return PlexHomeUser(
    id: id,
    uuid: uuid ?? 'uuid-$id',
    title: title,
    username: null,
    email: null,
    friendlyName: null,
    thumb: '',
    hasPassword: false,
    restricted: false,
    updatedAt: null,
    admin: admin,
    guest: false,
    protected: protected,
  );
}

PlexHome _home({List<PlexHomeUser>? users}) {
  return PlexHome(
    id: 1,
    name: 'My Home',
    guestUserID: null,
    guestUserUUID: '',
    guestEnabled: false,
    subscription: false,
    users:
        users ??
        [_user(id: 1, uuid: 'admin-uuid', title: 'Admin', admin: true), _user(id: 2, uuid: 'kid-uuid', title: 'Kid')],
  );
}

void main() {
  setUp(resetSharedPreferencesForTest);

  group('UserProfileProvider', () {
    test('starts with all-null state and no error', () {
      final p = UserProfileProvider();
      expect(p.home, isNull);
      expect(p.currentUser, isNull);
      expect(p.profileSettings, isNull);
      expect(p.isLoading, isFalse);
      expect(p.error, isNull);
      expect(p.hasMultipleUsers, isFalse);
      expect(p.needsInitialProfileSelection, isFalse);
      p.dispose();
    });

    test('initialize loads cached home users from SharedPreferences', () async {
      // Pre-seed home users cache directly.
      final storage = await StorageService.getInstance();
      await storage.saveHomeUsersCache(_home().toJson());

      final p = UserProfileProvider();
      var notified = 0;
      p.addListener(() => notified++);

      await p.initialize();

      expect(p.home, isNotNull);
      expect(p.home!.users, hasLength(2));
      expect(p.home!.name, 'My Home');
      expect(p.hasMultipleUsers, isTrue);
      // No current user UUID stored, so currentUser is null and selection is needed.
      expect(p.currentUser, isNull);
      expect(p.needsInitialProfileSelection, isTrue);
      // _loadCachedData notifies once.
      expect(notified, greaterThanOrEqualTo(1));

      p.dispose();
    });

    test('initialize resolves currentUser from stored UUID', () async {
      final storage = await StorageService.getInstance();
      await storage.saveHomeUsersCache(_home().toJson());
      await storage.saveCurrentUserUUID('kid-uuid');

      final p = UserProfileProvider();
      await p.initialize();

      expect(p.currentUser, isNotNull);
      expect(p.currentUser!.uuid, 'kid-uuid');
      expect(p.currentUser!.title, 'Kid');
      // Once a user is selected, no initial selection needed.
      expect(p.needsInitialProfileSelection, isFalse);

      p.dispose();
    });

    test('hasMultipleUsers reflects the home', () async {
      final storage = await StorageService.getInstance();
      await storage.saveHomeUsersCache(_home(users: [_user(id: 1, admin: true)]).toJson());

      final p = UserProfileProvider();
      await p.initialize();
      expect(p.home!.users, hasLength(1));
      expect(p.hasMultipleUsers, isFalse);

      p.dispose();
    });

    test('needsInitialProfileSelection is false when no home loaded', () async {
      final p = UserProfileProvider();
      await p.initialize(); // No cache, no token → home stays null.
      expect(p.home, isNull);
      expect(p.needsInitialProfileSelection, isFalse);
      p.dispose();
    });

    test('logout with no services initialized is a no-op', () async {
      final p = UserProfileProvider();
      // Without initialize, _storageService is null → logout returns early.
      await p.logout();
      expect(p.home, isNull);
      expect(p.currentUser, isNull);
      expect(p.error, isNull);
      p.dispose();
    });

    test('logout clears all state and notifies', () async {
      final storage = await StorageService.getInstance();
      await storage.saveHomeUsersCache(_home().toJson());
      await storage.saveCurrentUserUUID('admin-uuid');

      final p = UserProfileProvider();
      await p.initialize();
      expect(p.home, isNotNull);
      expect(p.currentUser, isNotNull);

      var notified = 0;
      p.addListener(() => notified++);

      await p.logout();
      expect(p.home, isNull);
      expect(p.currentUser, isNull);
      expect(p.profileSettings, isNull);
      expect(p.error, isNull);
      // Setting loading true/false + clearing state fires notifications.
      expect(notified, greaterThanOrEqualTo(1));

      p.dispose();
    });

    test('refreshCurrentUser is a no-op when currentUser is null', () async {
      final p = UserProfileProvider();
      // No initialize, no current user → method short-circuits without touching network.
      var notified = 0;
      p.addListener(() => notified++);
      await p.refreshCurrentUser();
      expect(notified, 0);
      expect(p.currentUser, isNull);
      p.dispose();
    });

    test('setDataInvalidationCallback stores the callback without side effects', () {
      final p = UserProfileProvider();
      // Should not throw and should not notify.
      var notified = 0;
      p.addListener(() => notified++);
      p.setDataInvalidationCallback((_) async {});
      expect(notified, 0);
      // Clearing it should also be safe.
      p.setDataInvalidationCallback(null);
      expect(notified, 0);
      p.dispose();
    });

    test('safeNotifyListeners after dispose does not throw', () async {
      final p = UserProfileProvider();
      p.dispose();
      // logout uses safeNotifyListeners — must not throw post-dispose.
      // Without initialized services it short-circuits, so no failure either.
      await p.logout();
    });
  });
}
