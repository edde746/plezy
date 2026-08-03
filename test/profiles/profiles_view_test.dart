import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profiles_view.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/profile_stack.dart';

void main() {
  group('visibleProfileConnections', () {
    test('keeps all local profile connection rows', () {
      final profile = Profile.local(id: 'local-1', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
      const rows = [
        ProfileConnection(profileId: 'local-1', connectionId: 'plex-1', userIdentifier: 'u1'),
        ProfileConnection(profileId: 'local-1', connectionId: 'jellyfin-1', userIdentifier: 'u2'),
      ];

      expect(visibleProfileConnections(profile, rows), rows);
    });

    test('filters Plex Home parent token cache row', () {
      final profile = Profile.plexHome(
        id: 'plex-home-plex-1-user-1',
        displayName: 'Kid',
        parentConnectionId: 'plex-1',
        createdAt: DateTime(2026, 1, 1),
      );
      const rows = [
        ProfileConnection(profileId: 'plex-home-plex-1-user-1', connectionId: 'plex-1', userIdentifier: 'user-1'),
        ProfileConnection(profileId: 'plex-home-plex-1-user-1', connectionId: 'jellyfin-1', userIdentifier: 'user-2'),
      ];

      final visible = visibleProfileConnections(profile, rows);

      expect(visible, hasLength(1));
      expect(visible.single.connectionId, 'jellyfin-1');
    });
  });

  group('avatarUrlByProfile', () {
    late ProfileStack stack;

    setUp(() async {
      resetSharedPreferencesForTest();
      stack = await ProfileStack.create(
        homeUsers: [
          PlexHomeUser(
            id: 1,
            uuid: 'home-user',
            title: 'Home User',
            thumb: 'https://images.example/home.jpg',
            hasPassword: false,
            restricted: false,
            updatedAt: null,
            admin: true,
            guest: false,
            protected: false,
          ),
        ],
      );
    });

    tearDown(() => stack.dispose());

    test('maps linked pictures, unlinked initials, and Plex Home pictures', () async {
      final linked = Profile.local(id: 'linked', displayName: 'Linked', createdAt: DateTime(2026, 1, 1));
      final unlinked = Profile.local(id: 'unlinked', displayName: 'Unlinked', createdAt: DateTime(2026, 1, 2));
      final jellyfin = JellyfinConnection(
        id: 'jellyfin',
        baseUrl: 'https://jellyfin.example',
        serverName: 'Jellyfin',
        serverMachineId: 'machine-id',
        userId: 'jellyfin-user',
        userName: 'Jellyfin User',
        accessToken: 'token',
        deviceId: 'device-id',
        primaryImageTag: 'image-tag',
        createdAt: DateTime(2025, 1, 1),
      );
      final plex = PlexAccountConnection(
        id: 'plex',
        accountToken: 'account-token',
        clientIdentifier: 'client-id',
        accountLabel: 'Plex',
        createdAt: DateTime(2025, 1, 2),
      );
      await stack.profiles.upsert(linked);
      await stack.profiles.upsert(unlinked);
      await stack.connections.upsert(jellyfin);
      await stack.connections.upsert(plex);
      await stack.profileConnections.upsert(
        const ProfileConnection(profileId: 'linked', connectionId: 'jellyfin', userIdentifier: 'jellyfin-user'),
      );
      expect(await stack.plexHome.refresh(plex), isTrue);

      final view = await watchProfilesView(
        profiles: stack.profiles,
        profileConnections: stack.profileConnections,
        connections: stack.connections,
        plexHome: stack.plexHome,
        storage: stack.storage,
      ).first.timeout(const Duration(seconds: 2));
      final plexHomeId = plexHomeProfileId(accountConnectionId: plex.id, homeUserUuid: 'home-user');

      expect(
        view.avatarUrlByProfile[linked.id],
        'https://jellyfin.example/Users/jellyfin-user/Images/Primary'
        '?tag=image-tag&maxWidth=240&maxHeight=240',
      );
      expect(view.avatarUrlByProfile[unlinked.id], isNull);
      expect(view.avatarUrlByProfile[plexHomeId], 'https://images.example/home.jpg');
    });
  });
}
