import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/services/storage_service.dart';

import '../test_helpers/prefs.dart';

PlexHomeUser _homeUser(String uuid, {String name = 'Home User'}) {
  return PlexHomeUser(
    id: 1,
    uuid: uuid,
    title: name,
    thumb: '',
    hasPassword: false,
    restricted: false,
    updatedAt: null,
    admin: true,
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
  late AppDatabase db;
  late ProfileRegistry registry;
  late ConnectionRegistry connections;
  late PlexHomeService plexHome;
  late ActiveProfileProvider provider;
  late StorageService storage;
  late List<PlexHomeUser> fetchedHomeUsers;

  setUp(() async {
    resetSharedPreferencesForTest();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    registry = ProfileRegistry(db);
    connections = ConnectionRegistry(db);
    storage = await StorageService.getInstance();
    fetchedHomeUsers = const [];
    plexHome = PlexHomeService(
      connections: connections,
      profileConnections: ProfileConnectionRegistry(db),
      storage: storage,
      plexHomeUserFetcher: (_) async => fetchedHomeUsers,
    );
    provider = ActiveProfileProvider(
      registry: registry,
      plexHome: plexHome,
      connections: connections,
      storage: storage,
    );
  });

  tearDown(() async {
    await provider.resetForTesting();
    provider.dispose();
    await plexHome.dispose();
    await db.close();
  });

  group('ActiveProfileProvider', () {
    test('initialize with no profiles leaves active null', () async {
      await provider.initialize();
      expect(provider.profiles, isEmpty);
      expect(provider.active, isNull);
    });

    test('concurrent initialize calls await the same in-flight load', () async {
      final first = provider.initialize();
      final second = provider.initialize();
      expect(identical(first, second), isTrue);

      await second;
      expect(provider.isInitialized, isTrue);
    });

    test('initialize leaves active null when no active id stored', () async {
      // Fresh state: no auto-fallback to the first profile so the UI can
      // force the picker. The binder skips its rebind while active is null,
      // which is what avoids the surprise PIN prompt at first sign-in.
      await registry.upsert(Profile.local(id: 'p1', displayName: 'Owner', createdAt: DateTime(2026, 1, 1)));
      await provider.initialize();
      expect(provider.profiles, hasLength(1));
      expect(provider.activeId, isNull);
    });

    test('reloadFromStorage resolves Plex Home profile added after early initialize', () async {
      await provider.initialize();
      expect(provider.profiles, isEmpty);

      final account = _account('plex.migrated');
      final user = _homeUser('home-user-1', name: 'Migrated User');
      fetchedHomeUsers = [user];
      await connections.upsert(account);
      await storage.savePlexHomeUsersCache(account.id, [user.toJson()]);
      final profileId = plexHomeProfileId(accountConnectionId: account.id, homeUserUuid: user.uuid);
      await storage.setActiveProfileId(profileId);

      await provider.reloadFromStorage();

      expect(provider.profiles.map((p) => p.id), contains(profileId));
      expect(provider.activeId, profileId);
      expect(provider.active?.displayName, 'Migrated User');
    });

    test('initialize keeps a stored id it cannot resolve (transient snapshots must not wipe it)', () async {
      // Early snapshots can legitimately miss state (boot before migration,
      // Plex Home cache not hydrated yet) — resolution goes inactive but the
      // persisted selection survives for a later snapshot to resolve.
      // Genuinely unresolvable ids are cleared by the boot guard and the
      // post-removal settle flow, not here.
      await registry.upsert(Profile.local(id: 'p1', displayName: 'Owner', createdAt: DateTime(2026, 1, 1)));
      await storage.setActiveProfileId('ghost-id-no-longer-exists');
      await provider.initialize();
      await Future<void>.delayed(Duration.zero);
      expect(provider.activeId, isNull);
      expect(storage.getActiveProfileId(), 'ghost-id-no-longer-exists');
    });

    test('re-upserting an identical connection does not notify listeners', () async {
      await registry.upsert(Profile.local(id: 'p1', displayName: 'Owner', createdAt: DateTime(2026, 1, 1)));
      final account = _account('plex.acct');
      await connections.upsert(account);
      await provider.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      var notifications = 0;
      provider.addListener(() => notifications++);
      // Same row content — the binder does this on every successful bind
      // (persisting refreshed-but-identical server metadata).
      await connections.upsert(account);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(notifications, 0);
    });

    test('initialize resolves the stored active profile id', () async {
      await registry.upsert(Profile.local(id: 'p1', displayName: 'Owner', createdAt: DateTime(2026, 1, 1)));
      await registry.upsert(Profile.local(id: 'p2', displayName: 'Kids', createdAt: DateTime(2026, 1, 2)));
      await storage.setActiveProfileId('p2');
      await provider.initialize();
      expect(provider.activeId, 'p2');
    });

    test('activate without PIN switches a non-protected profile', () async {
      await registry.upsert(Profile.local(id: 'p1', displayName: 'Owner', createdAt: DateTime(2026, 1, 1)));
      await registry.upsert(Profile.local(id: 'p2', displayName: 'Kids', createdAt: DateTime(2026, 1, 2)));
      await provider.initialize();
      final p2 = provider.profiles.firstWhere((p) => p.id == 'p2');
      final ok = await provider.activate(p2);
      expect(ok, isTrue);
      expect(provider.activeId, 'p2');
    });

    test('activate moves the selected profile to the front by recent usage', () async {
      await registry.upsert(Profile.local(id: 'p1', displayName: 'Owner', createdAt: DateTime(2026, 1, 1)));
      await registry.upsert(Profile.local(id: 'p2', displayName: 'Kids', createdAt: DateTime(2026, 1, 2)));
      await provider.initialize();
      expect(provider.profiles.map((p) => p.id).toList(), ['p1', 'p2']);

      final p2 = provider.profiles.firstWhere((p) => p.id == 'p2');
      final ok = await provider.activate(p2);

      expect(ok, isTrue);
      expect(provider.profiles.map((p) => p.id).toList(), ['p2', 'p1']);
      expect(storage.getProfileLastUsed('p2'), isNotNull);
    });

    test('clearActiveProfile clears storage and in-memory active profile', () async {
      await registry.upsert(Profile.local(id: 'p1', displayName: 'Owner', createdAt: DateTime(2026, 1, 1)));
      await provider.initialize();
      await provider.activate(provider.profiles.single);

      await provider.clearActiveProfile();

      expect(storage.getActiveProfileId(), isNull);
      expect(provider.active, isNull);
    });

    test('activate rejects wrong PIN for a protected local profile', () async {
      await registry.upsert(
        Profile.local(id: 'p1', displayName: 'Kids', pinHash: computePinHash('1234'), createdAt: DateTime(2026, 1, 1)),
      );
      await provider.initialize();
      final p1 = provider.profiles.first;
      expect(await provider.activate(p1, pin: 'wrong'), isFalse);
      expect(await provider.activate(p1, pin: '1234'), isTrue);
    });

    test('hasMultipleProfiles reflects the registry size', () async {
      await registry.upsert(Profile.local(id: 'p1', displayName: 'Owner', createdAt: DateTime(2026, 1, 1)));
      await provider.initialize();
      expect(provider.hasMultipleProfiles, isFalse);
      // Latch onto the next provider notification that flips the flag,
      // instead of sleeping a fixed duration. The provider is a ChangeNotifier
      // (not a Stream), so we use addListener + Completer here rather than
      // expectLater(stream, ...) like the other profile tests.
      final flipped = Completer<void>();
      void listener() {
        if (provider.hasMultipleProfiles && !flipped.isCompleted) {
          flipped.complete();
        }
      }

      provider.addListener(listener);
      addTearDown(() => provider.removeListener(listener));
      await registry.upsert(Profile.local(id: 'p2', displayName: 'Kids', createdAt: DateTime(2026, 1, 2)));
      await flipped.future.timeout(const Duration(seconds: 2));
      expect(provider.hasMultipleProfiles, isTrue);
    });
  });
}
