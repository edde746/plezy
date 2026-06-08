import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/connection/connection.dart';
import 'package:vibe_stream/models/plex/plex_home_user.dart';
import 'package:vibe_stream/profiles/profile.dart';
import 'package:vibe_stream/profiles/profile_merge.dart';
import 'package:vibe_stream/services/storage_service.dart';

import '../test_helpers/prefs.dart';

PlexHomeUser _homeUser(String uuid, String name) {
  return PlexHomeUser(
    id: 1,
    uuid: uuid,
    title: name,
    thumb: '',
    hasPassword: false,
    restricted: false,
    updatedAt: null,
    admin: false,
    guest: false,
    protected: false,
  );
}

PlexAccountConnection _account(String id) {
  return PlexAccountConnection(
    id: id,
    accountToken: 'token-$id',
    clientIdentifier: 'client-$id',
    accountLabel: 'Plex',
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
  });

  group('mergeLocalWithPlexHome', () {
    test('sorts local and Plex Home profiles by most recent usage', () async {
      final storage = await StorageService.getInstance();
      final plexProfileId = plexHomeProfileId(accountConnectionId: 'plex-1', homeUserUuid: 'home-1');
      await storage.markProfileUsed('local-older', DateTime(2026, 1, 2));
      await storage.markProfileUsed(plexProfileId, DateTime(2026, 1, 3));

      final profiles = mergeLocalWithPlexHome(
        locals: [
          Profile.local(id: 'local-older', displayName: 'Older', createdAt: DateTime(2026, 1, 1)),
          Profile.local(id: 'local-never', displayName: 'Never', createdAt: DateTime(2026, 1, 2)),
        ],
        plexHomeByConnectionId: {
          'plex-1': [_homeUser('home-1', 'Home')],
        },
        connectionsById: {'plex-1': _account('plex-1')},
        storage: storage,
      );

      expect(profiles.map((p) => p.id).toList(), [plexProfileId, 'local-older', 'local-never']);
      expect(profiles.first.lastUsedAt, DateTime(2026, 1, 3));
    });

    test('keeps never-used profiles in fallback order', () {
      final firstPlexId = plexHomeProfileId(accountConnectionId: 'plex-1', homeUserUuid: 'home-1');
      final secondPlexId = plexHomeProfileId(accountConnectionId: 'plex-1', homeUserUuid: 'home-2');

      final profiles = mergeLocalWithPlexHome(
        locals: [
          Profile.local(id: 'local-a', displayName: 'A', createdAt: DateTime(2026, 1, 1)),
          Profile.local(id: 'local-b', displayName: 'B', createdAt: DateTime(2026, 1, 2)),
        ],
        plexHomeByConnectionId: {
          'plex-1': [_homeUser('home-1', 'Home 1'), _homeUser('home-2', 'Home 2')],
        },
        connectionsById: {'plex-1': _account('plex-1')},
      );

      expect(profiles.map((p) => p.id).toList(), ['local-a', 'local-b', firstPlexId, secondPlexId]);
    });

    test('uses the newest local timestamp from storage or the database row', () async {
      final storage = await StorageService.getInstance();
      await storage.markProfileUsed('local-storage-newer', DateTime(2026, 1, 4));
      await storage.markProfileUsed('local-db-newer', DateTime(2026, 1, 2));

      final profiles = mergeLocalWithPlexHome(
        locals: [
          Profile.local(
            id: 'local-db-newer',
            displayName: 'DB newer',
            createdAt: DateTime(2026, 1, 1),
            lastUsedAt: DateTime(2026, 1, 3),
          ),
          Profile.local(id: 'local-storage-newer', displayName: 'Storage newer', createdAt: DateTime(2026, 1, 2)),
        ],
        plexHomeByConnectionId: const {},
        connectionsById: const {},
        storage: storage,
      );

      expect(profiles.map((p) => p.id).toList(), ['local-storage-newer', 'local-db-newer']);
      expect(profiles.first.lastUsedAt, DateTime(2026, 1, 4));
      expect(profiles.last.lastUsedAt, DateTime(2026, 1, 3));
    });
  });
}
