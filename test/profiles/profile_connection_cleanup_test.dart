import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/connection/connection.dart';
import 'package:vibe_stream/connection/connection_registry.dart';
import 'package:vibe_stream/database/app_database.dart';
import 'package:vibe_stream/profiles/profile_connection.dart';
import 'package:vibe_stream/profiles/profile_connection_cleanup.dart';
import 'package:vibe_stream/profiles/profile_connection_registry.dart';
import 'package:vibe_stream/services/plex_auth_service.dart';
import 'package:vibe_stream/services/storage_service.dart';

import '../test_helpers/prefs.dart';

JellyfinConnection _jellyfin({String machineId = 'jf-machine', String userId = 'user-a'}) {
  return JellyfinConnection(
    id: '$machineId/$userId',
    baseUrl: 'https://jellyfin.local',
    serverName: 'Jellyfin',
    serverMachineId: machineId,
    userId: userId,
    userName: userId,
    accessToken: 'token-$userId',
    deviceId: 'device-1',
    createdAt: DateTime.fromMillisecondsSinceEpoch(1_000_000),
    lastAuthenticatedAt: DateTime.fromMillisecondsSinceEpoch(1_000_000),
  );
}

PlexAccountConnection _plex() {
  return PlexAccountConnection(
    id: 'plex-account',
    accountToken: 'account-token',
    clientIdentifier: 'client-1',
    accountLabel: 'Plex',
    servers: [
      PlexServer(
        name: 'Plex Server',
        clientIdentifier: 'plex-machine',
        accessToken: 'server-token',
        connections: [
          PlexConnection(
            protocol: 'https',
            address: 'plex.example.test',
            port: 443,
            uri: 'https://plex.example.test',
            local: false,
            relay: false,
            ipv6: false,
          ),
        ],
        owned: true,
      ),
    ],
    createdAt: DateTime.fromMillisecondsSinceEpoch(1_000_000),
    lastAuthenticatedAt: DateTime.fromMillisecondsSinceEpoch(1_000_000),
  );
}

void main() {
  late AppDatabase db;
  late ConnectionRegistry connections;
  late ProfileConnectionRegistry profileConnections;
  late StorageService storage;

  setUp(() async {
    resetSharedPreferencesForTest();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    connections = ConnectionRegistry(db);
    profileConnections = ProfileConnectionRegistry(db);
    storage = await StorageService.getInstance();
  });

  tearDown(() async {
    await db.close();
  });

  group('profile connection cleanup', () {
    test('removing the last Jellyfin profile link deletes the connection and profile prefs', () async {
      final conn = _jellyfin();
      await connections.upsert(conn);
      await profileConnections.upsert(
        ProfileConnection(
          profileId: 'p1',
          connectionId: conn.id,
          userToken: conn.accessToken,
          userIdentifier: conn.userId,
        ),
      );
      await storage.setActiveProfileId('p1');
      await storage.saveHiddenLibraries({'jf-machine:movies'});
      await storage.saveLibraryOrder(['jf-machine:movies']);

      await removeProfileConnectionAndCleanup(
        profileId: 'p1',
        connection: conn,
        profileConnections: profileConnections,
        connections: connections,
        storage: storage,
      );

      expect(await profileConnections.listForConnection(conn.id), isEmpty);
      expect(await connections.get(conn.id), isNull);
      expect(storage.getHiddenLibraries(), isEmpty);
      expect(storage.getLibraryOrder(), isNull);
    });

    test('removing one profile link keeps a shared Jellyfin connection and other profile prefs', () async {
      final conn = _jellyfin();
      await connections.upsert(conn);
      await profileConnections.upsert(
        ProfileConnection(
          profileId: 'p1',
          connectionId: conn.id,
          userToken: conn.accessToken,
          userIdentifier: conn.userId,
        ),
      );
      await profileConnections.upsert(
        ProfileConnection(
          profileId: 'p2',
          connectionId: conn.id,
          userToken: conn.accessToken,
          userIdentifier: conn.userId,
        ),
      );

      await storage.setActiveProfileId('p1');
      await storage.saveHiddenLibraries({'jf-machine:movies'});
      await storage.setActiveProfileId('p2');
      await storage.saveHiddenLibraries({'jf-machine:movies'});

      await removeProfileConnectionAndCleanup(
        profileId: 'p1',
        connection: conn,
        profileConnections: profileConnections,
        connections: connections,
        storage: storage,
      );

      expect(await connections.get(conn.id), isNotNull);
      final remaining = await profileConnections.listForConnection(conn.id);
      expect(remaining, hasLength(1));
      expect(remaining.single.profileId, 'p2');

      await storage.setActiveProfileId('p1');
      expect(storage.getHiddenLibraries(), isEmpty);
      await storage.setActiveProfileId('p2');
      expect(storage.getHiddenLibraries(), {'jf-machine:movies'});
    });

    test('startup prune removes unreferenced Jellyfin rows and stale prefs', () async {
      final conn = _jellyfin();
      await connections.upsert(conn);
      await storage.setActiveProfileId('p1');
      await storage.saveHiddenLibraries({'jf-machine:movies'});
      await storage.saveLibrarySort('jf-machine:movies', 'titleSort');

      final removed = await pruneUnreferencedJellyfinConnections(
        profileConnections: profileConnections,
        connections: connections,
        storage: storage,
      );

      expect(removed, 1);
      expect(await connections.get(conn.id), isNull);
      expect(storage.getHiddenLibraries(), isEmpty);
      expect(storage.getLibrarySort('jf-machine:movies'), isNull);
    });

    test('startup prune does not clear prefs when another user on the same server is still referenced', () async {
      final orphan = _jellyfin(userId: 'user-a');
      final sharedServer = _jellyfin(userId: 'user-b');
      await connections.upsert(orphan);
      await connections.upsert(sharedServer);
      await profileConnections.upsert(
        ProfileConnection(
          profileId: 'p2',
          connectionId: sharedServer.id,
          userToken: sharedServer.accessToken,
          userIdentifier: sharedServer.userId,
        ),
      );
      await storage.setActiveProfileId('p2');
      await storage.saveHiddenLibraries({'jf-machine:movies'});

      final removed = await pruneUnreferencedJellyfinConnections(
        profileConnections: profileConnections,
        connections: connections,
        storage: storage,
      );

      expect(removed, 1);
      expect(await connections.get(orphan.id), isNull);
      expect(await connections.get(sharedServer.id), isNotNull);
      expect(storage.getHiddenLibraries(), {'jf-machine:movies'});
    });

    test('Plex profile unlink clears only that profile because Plex Home access can be implicit', () async {
      final conn = _plex();
      await connections.upsert(conn);
      await profileConnections.upsert(
        ProfileConnection(profileId: 'p1', connectionId: conn.id, userToken: 'user-token', userIdentifier: 'home-user'),
      );

      await storage.setActiveProfileId('p1');
      await storage.saveHiddenLibraries({'plex-machine:movies'});
      await storage.setActiveProfileId('p2');
      await storage.saveHiddenLibraries({'plex-machine:movies'});

      await removeProfileConnectionAndCleanup(
        profileId: 'p1',
        connection: conn,
        profileConnections: profileConnections,
        connections: connections,
        storage: storage,
      );

      expect(await connections.get(conn.id), isNotNull);
      expect(await profileConnections.listForConnection(conn.id), isEmpty);
      await storage.setActiveProfileId('p1');
      expect(storage.getHiddenLibraries(), isEmpty);
      await storage.setActiveProfileId('p2');
      expect(storage.getHiddenLibraries(), {'plex-machine:movies'});
    });
  });
}
