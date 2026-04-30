import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/screens/auth_screen.dart';
import 'package:plezy/services/storage_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(resetSharedPreferencesForTest);

  test('initial profile is built from the refreshed Plex Home cache', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final connections = ConnectionRegistry(db);
    final profileConnections = ProfileConnectionRegistry(db);
    final storage = await StorageService.getInstance();
    final plexHome = PlexHomeService(
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
      plexHomeUserFetcher: (_) async => [
        PlexHomeUser(
          id: 1,
          uuid: 'home-user-a',
          title: 'Home User',
          thumb: '',
          hasPassword: false,
          restricted: false,
          updatedAt: null,
          admin: true,
          guest: false,
          protected: false,
        ),
      ],
    );
    addTearDown(() async {
      await plexHome.dispose();
      await db.close();
    });

    final account = PlexAccountConnection(
      id: 'plex-account-a',
      accountToken: 'account-token',
      clientIdentifier: 'client-a',
      accountLabel: 'Plex',
      createdAt: DateTime(2026, 1, 1),
    );
    await connections.upsert(account);
    await plexHome.refresh(account);

    final profile = initialPlexHomeProfileFromCache(plexHome, account);

    expect(profile, isNotNull);
    expect(profile!.id, plexHomeProfileId(accountConnectionId: account.id, homeUserUuid: 'home-user-a'));
    expect(profile.parentConnectionId, account.id);
    expect(profile.displayName, 'Home User');
  });
}
