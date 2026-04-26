import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profiles_view.dart';

void main() {
  group('visibleProfileConnections', () {
    test('keeps all local profile connection rows', () {
      final profile = Profile(
        id: 'local-1',
        kind: ProfileKind.local,
        displayName: 'Owner',
        createdAt: DateTime(2026, 1, 1),
      );
      const rows = [
        ProfileConnection(profileId: 'local-1', connectionId: 'plex-1', userIdentifier: 'u1'),
        ProfileConnection(profileId: 'local-1', connectionId: 'jellyfin-1', userIdentifier: 'u2'),
      ];

      expect(visibleProfileConnections(profile, rows), rows);
    });

    test('filters Plex Home parent token cache row', () {
      final profile = Profile(
        id: 'plex-home-plex-1-user-1',
        kind: ProfileKind.plexHome,
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
}
