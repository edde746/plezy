import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';

import '../test_helpers/prefs.dart';

void main() {
  late AppDatabase db;
  late ProfileConnectionRegistry registry;

  setUp(() async {
    resetSharedPreferencesForTest();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    registry = ProfileConnectionRegistry(db);

    // Seed the parent rows that ProfileConnections now FK-references.
    // Without this, every upsert below trips the FK constraint added in
    // schema v17.
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final id in ['p1', 'p2']) {
      await db
          .into(db.profiles)
          .insert(ProfilesCompanion.insert(id: id, kind: 'local', displayName: id, configJson: '{}', createdAt: now));
    }
    for (final id in ['c1', 'c2']) {
      await db
          .into(db.connections)
          .insert(ConnectionsCompanion.insert(id: id, kind: 'plex', displayName: id, configJson: '{}', createdAt: now));
    }
  });

  tearDown(() async {
    await db.close();
  });

  group('ProfileConnectionRegistry', () {
    test('listForProfile is empty initially', () async {
      expect(await registry.listForProfile('p1'), isEmpty);
    });

    test('upsert inserts and round-trips', () async {
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c1', userToken: 'tok', userIdentifier: 'uid-1'),
      );
      final list = await registry.listForProfile('p1');
      expect(list, hasLength(1));
      expect(list.first.userToken, 'tok');
      expect(list.first.userIdentifier, 'uid-1');
      final raw = await db.select(db.profileConnections).getSingle();
      expect(raw.userToken, isNot('tok'));
    });

    test('first row for a profile is auto-default', () async {
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c1', userToken: 't', userIdentifier: 'u'),
      );
      final pc = await registry.get('p1', 'c1');
      expect(pc!.isDefault, isTrue);
    });

    test('subsequent rows do not auto-replace the default', () async {
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c1', userToken: 't1', userIdentifier: 'u1'),
      );
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c2', userToken: 't2', userIdentifier: 'u2'),
      );
      final list = await registry.listForProfile('p1');
      final defaults = list.where((pc) => pc.isDefault).toList();
      expect(defaults, hasLength(1));
      expect(defaults.first.connectionId, 'c1');
    });

    test('re-upsert preserves the existing default flag', () async {
      // Regression: re-upserting a default row used to clobber its
      // `isDefault` because the fast path always wrote `isFirst`.
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c1', userToken: 't1', userIdentifier: 'u1'),
      );
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c2', userToken: 't2', userIdentifier: 'u2'),
      );
      expect((await registry.get('p1', 'c1'))!.isDefault, isTrue);

      // Re-upsert c1 (token refresh) — the default flag must survive.
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c1', userToken: 't1-refreshed', userIdentifier: 'u1'),
      );
      expect((await registry.get('p1', 'c1'))!.isDefault, isTrue);
      expect((await registry.get('p1', 'c2'))!.isDefault, isFalse);
    });

    test('setDefault flips the default flag exclusively', () async {
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c1', userToken: 't1', userIdentifier: 'u1'),
      );
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c2', userToken: 't2', userIdentifier: 'u2'),
      );
      await registry.setDefault('p1', 'c2');
      final list = await registry.listForProfile('p1');
      final c1 = list.firstWhere((pc) => pc.connectionId == 'c1');
      final c2 = list.firstWhere((pc) => pc.connectionId == 'c2');
      expect(c1.isDefault, isFalse);
      expect(c2.isDefault, isTrue);
    });

    test('recordToken caches a fresh user token', () async {
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c1', userToken: '', userIdentifier: 'u1'),
      );
      await registry.recordToken('p1', 'c1', 'fresh-token');
      final pc = await registry.get('p1', 'c1');
      expect(pc!.userToken, 'fresh-token');
      expect(pc.tokenAcquiredAt, isNotNull);
    });

    test('remove drops the row and promotes the next one as default', () async {
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c1', userToken: 't1', userIdentifier: 'u1'),
      );
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c2', userToken: 't2', userIdentifier: 'u2'),
      );
      // c1 is default initially. Removing it should promote c2.
      await registry.remove('p1', 'c1');
      final remaining = await registry.listForProfile('p1');
      expect(remaining, hasLength(1));
      expect(remaining.first.connectionId, 'c2');
      expect(remaining.first.isDefault, isTrue);
    });

    test('removeAllForConnection cascades across profiles', () async {
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c1', userToken: 't', userIdentifier: 'u'),
      );
      await registry.upsert(
        const ProfileConnection(profileId: 'p2', connectionId: 'c1', userToken: 't', userIdentifier: 'u'),
      );
      final removed = await registry.removeAllForConnection('c1');
      expect(removed, 2);
      expect(await registry.listForConnection('c1'), isEmpty);
    });

    test('removeAllForProfile drops every row for a profile', () async {
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c1', userToken: 't', userIdentifier: 'u'),
      );
      await registry.upsert(
        const ProfileConnection(profileId: 'p1', connectionId: 'c2', userToken: 't', userIdentifier: 'u'),
      );
      final removed = await registry.removeAllForProfile('p1');
      expect(removed, 2);
      expect(await registry.listForProfile('p1'), isEmpty);
    });

    test('upsert succeeds for a virtual plex_home profile id with no parent row', () async {
      // Regression for the v17 FK that broke Plex Home activation: virtual
      // plex_home profiles are never persisted in `profiles`, so the join
      // row's profile_id has no parent. v20 dropped the FK; this insert
      // must round-trip without a FOREIGN KEY constraint failure.
      const plexHomeId = 'plex-home-plex.acc-uuid-1234';
      await registry.upsert(
        const ProfileConnection(
          profileId: plexHomeId,
          connectionId: 'c1',
          userToken: 'home-tok',
          userIdentifier: 'uuid-1234',
        ),
      );
      final list = await registry.listForProfile(plexHomeId);
      expect(list, hasLength(1));
      expect(list.first.userToken, 'home-tok');
      expect(list.first.userIdentifier, 'uuid-1234');
    });
  });
}
