import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_registry.dart';

void main() {
  late AppDatabase db;
  late ProfileRegistry registry;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    registry = ProfileRegistry(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ProfileRegistry', () {
    test('list is empty initially', () async {
      expect(await registry.list(), isEmpty);
    });

    test('upsert + list round-trips a local profile', () async {
      final profile = Profile.local(
        id: 'local-1',
        displayName: 'Owner',
        pinHash: computePinHash('1234'),
        createdAt: DateTime(2026, 1, 1),
      );
      await registry.upsert(profile);

      final fetched = await _profileById(registry, 'local-1');
      expect(fetched, isNotNull);
      expect(fetched!.kind, ProfileKind.local);
      expect(fetched.displayName, 'Owner');
      expect(fetched.pinHash, profile.pinHash);
    });

    test('list never serves plex_home rows (Plex Home users are not persisted profiles)', () async {
      final profile = Profile.plexHome(
        id: 'plex-home-acct-uuid',
        displayName: 'Admin',
        avatarThumbUrl: 'https://plex.tv/users/abc/avatar?',
        parentConnectionId: 'acct',
        plexAdmin: true,
        plexProtected: true,
        createdAt: DateTime(2026, 1, 1),
      );
      await registry.upsert(profile);

      // The read surface is deliberately local-only: Plex Home users are
      // materialized live by PlexHomeService and any leftover persisted rows
      // are dropped by [ProfileRegistry.dropAllPlexHomeRows].
      expect(await _profileById(registry, profile.id), isNull);
    });

    test('list orders by sortOrder then createdAt', () async {
      await registry.upsert(Profile.local(id: 'a', displayName: 'A', sortOrder: 1, createdAt: DateTime(2026, 1, 1)));
      await registry.upsert(Profile.local(id: 'b', displayName: 'B', sortOrder: 0, createdAt: DateTime(2026, 1, 2)));
      final list = await registry.list();
      expect(list.map((p) => p.id).toList(), ['b', 'a']);
    });

    test('remove deletes a profile', () async {
      await registry.upsert(Profile.local(id: 'p', displayName: 'P', createdAt: DateTime(2026, 1, 1)));
      await registry.remove('p');
      expect(await _profileById(registry, 'p'), isNull);
    });

    test('markUsed updates lastUsedAt', () async {
      await registry.upsert(Profile.local(id: 'p', displayName: 'P', createdAt: DateTime(2026, 1, 1)));
      final ts = DateTime(2026, 1, 5, 12, 0);
      await registry.markUsed('p', ts);
      final fetched = await _profileById(registry, 'p');
      expect(fetched!.lastUsedAt, ts);
    });

    test('upsert is idempotent (replaces existing row)', () async {
      await registry.upsert(Profile.local(id: 'p', displayName: 'Original', createdAt: DateTime(2026, 1, 1)));
      await registry.upsert(Profile.local(id: 'p', displayName: 'Renamed', createdAt: DateTime(2026, 1, 1)));
      final fetched = await _profileById(registry, 'p');
      expect(fetched!.displayName, 'Renamed');
    });

    test('watchProfiles emits on insert + delete', () async {
      // Drift's `.watch()` may coalesce the initial empty snapshot with the
      // first mutation's emission when both happen inside the same
      // microtask, so we don't pin the prefix — what matters is that
      // mutations *do* propagate. `emitsThrough` skips intermediate events
      // and matches the first event satisfying the predicate, then the
      // second matcher takes over. Deterministic on slow CI runners.
      final assertion = expectLater(
        registry.watchProfiles(),
        emitsInOrder([
          emitsThrough(predicate<List<Profile>>((l) => l.length == 1 && l.first.id == 'p')),
          emitsThrough(isEmpty),
        ]),
      );
      await registry.upsert(Profile.local(id: 'p', displayName: 'P', createdAt: DateTime(2026, 1, 1)));
      await registry.remove('p');
      await assertion;
    });
  });
}

Future<Profile?> _profileById(ProfileRegistry registry, String id) async {
  for (final profile in await registry.list()) {
    if (profile.id == id) return profile;
  }
  return null;
}
