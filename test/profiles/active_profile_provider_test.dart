import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/services/storage_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  late AppDatabase db;
  late ProfileRegistry registry;
  late ConnectionRegistry connections;
  late PlexHomeService plexHome;
  late ActiveProfileProvider provider;
  late StorageService storage;

  setUp(() async {
    resetSharedPreferencesForTest();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    registry = ProfileRegistry(db);
    connections = ConnectionRegistry(db);
    storage = await StorageService.getInstance();
    plexHome = PlexHomeService(
      connections: connections,
      profileConnections: ProfileConnectionRegistry(db),
      storage: storage,
      // No accounts in tests, so the fetcher is never called.
      plexHomeUserFetcher: (_) async => const [],
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
      await registry.upsert(
        Profile(id: 'p1', kind: ProfileKind.local, displayName: 'Owner', createdAt: DateTime(2026, 1, 1)),
      );
      await provider.initialize();
      expect(provider.profiles, hasLength(1));
      expect(provider.activeId, isNull);
    });

    test('initialize clears storage when stored id is stale', () async {
      // A previously-active profile that was deleted should not keep
      // storage-scoped settings under the removed profile id.
      await registry.upsert(
        Profile(id: 'p1', kind: ProfileKind.local, displayName: 'Owner', createdAt: DateTime(2026, 1, 1)),
      );
      await storage.setActiveProfileId('ghost-id-no-longer-exists');
      await provider.initialize();
      await Future<void>.delayed(Duration.zero);
      expect(provider.activeId, isNull);
      expect(storage.getActiveProfileId(), isNull);
    });

    test('initialize resolves the stored active profile id', () async {
      await registry.upsert(
        Profile(id: 'p1', kind: ProfileKind.local, displayName: 'Owner', createdAt: DateTime(2026, 1, 1)),
      );
      await registry.upsert(
        Profile(id: 'p2', kind: ProfileKind.local, displayName: 'Kids', createdAt: DateTime(2026, 1, 2)),
      );
      await storage.setActiveProfileId('p2');
      await provider.initialize();
      expect(provider.activeId, 'p2');
    });

    test('activate without PIN switches a non-protected profile', () async {
      await registry.upsert(
        Profile(id: 'p1', kind: ProfileKind.local, displayName: 'Owner', createdAt: DateTime(2026, 1, 1)),
      );
      await registry.upsert(
        Profile(id: 'p2', kind: ProfileKind.local, displayName: 'Kids', createdAt: DateTime(2026, 1, 2)),
      );
      await provider.initialize();
      final p2 = provider.profiles.firstWhere((p) => p.id == 'p2');
      final ok = await provider.activate(p2);
      expect(ok, isTrue);
      expect(provider.activeId, 'p2');
    });

    test('clearActiveProfile clears storage and in-memory active profile', () async {
      await registry.upsert(
        Profile(id: 'p1', kind: ProfileKind.local, displayName: 'Owner', createdAt: DateTime(2026, 1, 1)),
      );
      await provider.initialize();
      await provider.activate(provider.profiles.single);

      await provider.clearActiveProfile();

      expect(storage.getActiveProfileId(), isNull);
      expect(provider.active, isNull);
    });

    test('activate rejects wrong PIN for a protected local profile', () async {
      await registry.upsert(
        Profile(
          id: 'p1',
          kind: ProfileKind.local,
          displayName: 'Kids',
          pinHash: computePinHash('1234'),
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await provider.initialize();
      final p1 = provider.profiles.first;
      expect(await provider.activate(p1, pin: 'wrong'), isFalse);
      expect(await provider.activate(p1, pin: '1234'), isTrue);
    });

    test('hasMultipleProfiles reflects the registry size', () async {
      await registry.upsert(
        Profile(id: 'p1', kind: ProfileKind.local, displayName: 'Owner', createdAt: DateTime(2026, 1, 1)),
      );
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
      await registry.upsert(
        Profile(id: 'p2', kind: ProfileKind.local, displayName: 'Kids', createdAt: DateTime(2026, 1, 2)),
      );
      await flipped.future.timeout(const Duration(seconds: 2));
      expect(provider.hasMultipleProfiles, isTrue);
    });
  });
}
