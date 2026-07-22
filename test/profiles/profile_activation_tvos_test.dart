import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/profiles/active_profile_binder.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_activation.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/utils/platform_detector.dart';

import '../test_helpers/prefs.dart';

void main() {
  late AppDatabase db;
  late ConnectionRegistry connections;
  late ProfileConnectionRegistry profileConnections;
  late ProfileRegistry profiles;
  late PlexHomeService plexHome;
  late ActiveProfileProvider activeProfile;
  late MultiServerManager manager;
  late MultiServerProvider multiServerProvider;
  late ActiveProfileBinder binder;
  late StorageService storage;

  setUp(() async {
    resetSharedPreferencesForTest();
    TvDetectionService.debugSetAppleTVOverride(true);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    connections = ConnectionRegistry(db);
    profileConnections = ProfileConnectionRegistry(db);
    profiles = ProfileRegistry(db);
    storage = await StorageService.getInstance();
    plexHome = PlexHomeService(
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
      plexHomeUserFetcher: (_) async => const [],
    );
    activeProfile = ActiveProfileProvider(
      registry: profiles,
      plexHome: plexHome,
      connections: connections,
      storage: storage,
    );
    manager = MultiServerManager();
    multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
    binder = ActiveProfileBinder(
      activeProfile: activeProfile,
      connections: connections,
      profileConnections: profileConnections,
      serverManager: manager,
      multiServerProvider: multiServerProvider,
      pinPrompt: (_, {String? errorMessage}) async => null,
    );
  });

  tearDown(() async {
    TvDetectionService.debugSetAppleTVOverride(null);
    binder.dispose();
    multiServerProvider.dispose();
    await activeProfile.resetForTesting();
    activeProfile.dispose();
    await plexHome.dispose();
    await db.close();
  });

  Future<void> seedProfiles({String? mappedPinHash}) async {
    await profiles.upsert(Profile.local(id: 'p1', displayName: 'Owner', createdAt: DateTime(2026, 1, 1)));
    await profiles.upsert(
      Profile.local(id: 'p2', displayName: 'Kids', pinHash: mappedPinHash, createdAt: DateTime(2026, 1, 2)),
    );
    await storage.setActiveProfileId('p1');
    await activeProfile.initialize();
  }

  test('activates the mapped non-PIN profile', () async {
    await seedProfiles();
    await storage.setProfileIdForTvosUser('tv-user', 'p2');

    final switched = await activateTvosMappedProfile(
      activeProfile: activeProfile,
      binder: binder,
      tvosUserId: 'tv-user',
    );

    expect(switched, isTrue);
    expect(activeProfile.active?.id, 'p2');
  });

  test('no mapping for the tvOS user is a no-op', () async {
    await seedProfiles();

    final switched = await activateTvosMappedProfile(
      activeProfile: activeProfile,
      binder: binder,
      tvosUserId: 'tv-user',
    );

    expect(switched, isFalse);
    expect(activeProfile.active?.id, 'p1');
  });

  test('mapping to the already-active profile is a no-op', () async {
    await seedProfiles();
    await storage.setProfileIdForTvosUser('tv-user', 'p1');

    final switched = await activateTvosMappedProfile(
      activeProfile: activeProfile,
      binder: binder,
      tvosUserId: 'tv-user',
    );

    expect(switched, isFalse);
    expect(activeProfile.active?.id, 'p1');
  });

  test('mapping to a deleted profile is a no-op', () async {
    await seedProfiles();
    await storage.setProfileIdForTvosUser('tv-user', 'gone');

    final switched = await activateTvosMappedProfile(
      activeProfile: activeProfile,
      binder: binder,
      tvosUserId: 'tv-user',
    );

    expect(switched, isFalse);
    expect(activeProfile.active?.id, 'p1');
  });

  test('PIN-protected mapped profile is skipped without a context', () async {
    await seedProfiles(mappedPinHash: computePinHash('1234'));
    await storage.setProfileIdForTvosUser('tv-user', 'p2');

    final switched = await activateTvosMappedProfile(
      activeProfile: activeProfile,
      binder: binder,
      tvosUserId: 'tv-user',
    );

    expect(switched, isFalse);
    expect(activeProfile.active?.id, 'p1');
  });

  test('does nothing off Apple TV', () async {
    TvDetectionService.debugSetAppleTVOverride(false);
    await seedProfiles();
    await storage.setProfileIdForTvosUser('tv-user', 'p2');

    final switched = await activateTvosMappedProfile(
      activeProfile: activeProfile,
      binder: binder,
      tvosUserId: 'tv-user',
    );

    expect(switched, isFalse);
    expect(activeProfile.active?.id, 'p1');
  });
}
