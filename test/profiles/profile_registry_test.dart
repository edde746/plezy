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

    test('upsert + get round-trips a local profile', () async {
      final profile = Profile(
        id: 'local-1',
        kind: ProfileKind.local,
        displayName: 'Owner',
        pinHash: computePinHash('1234'),
        createdAt: DateTime(2026, 1, 1),
      );
      await registry.upsert(profile);

      final fetched = await registry.get('local-1');
      expect(fetched, isNotNull);
      expect(fetched!.kind, ProfileKind.local);
      expect(fetched.displayName, 'Owner');
      expect(fetched.pinHash, profile.pinHash);
    });

    test('upsert + get round-trips a plex_home profile', () async {
      final profile = Profile(
        id: 'plex-home-acct-uuid',
        kind: ProfileKind.plexHome,
        displayName: 'Admin',
        avatarThumbUrl: 'https://plex.tv/users/abc/avatar?',
        parentConnectionId: 'acct',
        plexAdmin: true,
        plexProtected: true,
        createdAt: DateTime(2026, 1, 1),
      );
      await registry.upsert(profile);

      final fetched = await registry.get(profile.id);
      expect(fetched, isNotNull);
      expect(fetched!.kind, ProfileKind.plexHome);
      expect(fetched.avatarThumbUrl, profile.avatarThumbUrl);
      expect(fetched.parentConnectionId, 'acct');
      expect(fetched.plexAdmin, isTrue);
      expect(fetched.plexProtected, isTrue);
    });

    test('list orders by sortOrder then createdAt', () async {
      await registry.upsert(
        Profile(id: 'a', kind: ProfileKind.local, displayName: 'A', sortOrder: 1, createdAt: DateTime(2026, 1, 1)),
      );
      await registry.upsert(
        Profile(id: 'b', kind: ProfileKind.local, displayName: 'B', sortOrder: 0, createdAt: DateTime(2026, 1, 2)),
      );
      final list = await registry.list();
      expect(list.map((p) => p.id).toList(), ['b', 'a']);
    });

    test('remove deletes a profile', () async {
      await registry.upsert(
        Profile(id: 'p', kind: ProfileKind.local, displayName: 'P', createdAt: DateTime(2026, 1, 1)),
      );
      await registry.remove('p');
      expect(await registry.get('p'), isNull);
    });

    test('markUsed updates lastUsedAt', () async {
      await registry.upsert(
        Profile(id: 'p', kind: ProfileKind.local, displayName: 'P', createdAt: DateTime(2026, 1, 1)),
      );
      final ts = DateTime(2026, 1, 5, 12, 0);
      await registry.markUsed('p', ts);
      final fetched = await registry.get('p');
      expect(fetched!.lastUsedAt, ts);
    });

    test('upsert is idempotent (replaces existing row)', () async {
      await registry.upsert(
        Profile(id: 'p', kind: ProfileKind.local, displayName: 'Original', createdAt: DateTime(2026, 1, 1)),
      );
      await registry.upsert(
        Profile(id: 'p', kind: ProfileKind.local, displayName: 'Renamed', createdAt: DateTime(2026, 1, 1)),
      );
      final fetched = await registry.get('p');
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
      await registry.upsert(
        Profile(id: 'p', kind: ProfileKind.local, displayName: 'P', createdAt: DateTime(2026, 1, 1)),
      );
      await registry.remove('p');
      await assertion;
    });
  });
}
