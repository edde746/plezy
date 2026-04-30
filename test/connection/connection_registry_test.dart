import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/services/credential_vault.dart';
import 'package:plezy/services/plex_auth_service.dart';

import '../test_helpers/prefs.dart';

JellyfinConnection _jellyfin({String id = 'srv-1', String userName = 'edde'}) {
  return JellyfinConnection(
    id: id,
    baseUrl: 'https://jellyfin.local',
    serverName: 'Home',
    serverMachineId: 'jf-machine-$id',
    userId: 'user-$id',
    userName: userName,
    accessToken: 'tok-$id',
    deviceId: 'dev-1',
    createdAt: DateTime.fromMillisecondsSinceEpoch(1_000_000),
  );
}

PlexAccountConnection _plex({String id = 'plex-1'}) {
  return PlexAccountConnection(
    id: id,
    accountToken: 'tok-$id',
    clientIdentifier: 'cid-$id',
    accountLabel: 'me@example.com',
    servers: [
      PlexServer(
        name: 'Server $id',
        clientIdentifier: 'server-$id',
        accessToken: 'server-token-$id',
        connections: [
          PlexConnection(
            protocol: 'https',
            address: 'plex.example.com',
            port: 443,
            uri: 'https://plex.example.com',
            local: false,
            relay: false,
            ipv6: false,
          ),
        ],
        owned: true,
      ),
    ],
    createdAt: DateTime.fromMillisecondsSinceEpoch(1_000_000),
  );
}

void main() {
  late AppDatabase db;
  late ConnectionRegistry registry;

  setUp(() {
    resetSharedPreferencesForTest();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    registry = ConnectionRegistry(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ConnectionRegistry', () {
    test('list() returns empty when no connections stored', () async {
      expect(await registry.list(), isEmpty);
      expect(await registry.getDefault(), isNull);
    });

    test('first upserted connection becomes the default', () async {
      await registry.upsert(_jellyfin(id: 'a'));
      final list = await registry.list();
      expect(list.length, 1);
      expect(list.first.id, 'a');

      final defaultConn = await registry.getDefault();
      expect(defaultConn?.id, 'a');
    });

    test('upsert preserves type discriminator (Plex vs Jellyfin)', () async {
      await registry.upsert(_plex(id: 'p'));
      await registry.upsert(_jellyfin(id: 'j'));

      final plex = await registry.get('p');
      final jelly = await registry.get('j');
      expect(plex, isA<PlexAccountConnection>());
      expect(jelly, isA<JellyfinConnection>());

      expect((plex as PlexAccountConnection).accountToken, 'tok-p');
      expect((jelly as JellyfinConnection).baseUrl, 'https://jellyfin.local');
    });

    test('upsert encrypts tokens at rest and decrypts on read', () async {
      await registry.upsert(_plex(id: 'p'));
      await registry.upsert(_jellyfin(id: 'j'));

      final rows = await db.select(db.connections).get();
      expect(rows.singleWhere((r) => r.id == 'p').configJson, isNot(contains('tok-p')));
      expect(rows.singleWhere((r) => r.id == 'p').configJson, isNot(contains('server-token-p')));
      expect(rows.singleWhere((r) => r.id == 'j').configJson, isNot(contains('tok-j')));

      expect((await registry.get('p') as PlexAccountConnection).accountToken, 'tok-p');
      expect((await registry.get('p') as PlexAccountConnection).servers.single.accessToken, 'server-token-p');
      expect((await registry.get('j') as JellyfinConnection).accessToken, 'tok-j');
    });

    test('read migrates legacy plaintext Plex server tokens', () async {
      final plex = _plex(id: 'legacy');
      final config = plex.toConfigJson();
      config['accountToken'] = await CredentialVault.protect(plex.accountToken);
      await db
          .into(db.connections)
          .insert(
            ConnectionsCompanion.insert(
              id: plex.id,
              kind: plex.kind.id,
              displayName: plex.displayName,
              configJson: jsonEncode(config),
              createdAt: plex.createdAt.millisecondsSinceEpoch,
              isDefault: const Value(true),
            ),
          );

      final restored = await registry.get('legacy') as PlexAccountConnection;
      expect(restored.accountToken, 'tok-legacy');
      expect(restored.servers.single.accessToken, 'server-token-legacy');

      final row = await (db.select(db.connections)..where((t) => t.id.equals('legacy'))).getSingle();
      expect(row.configJson, isNot(contains('server-token-legacy')));
    });

    test('setDefault flips the flag and clears it on others', () async {
      await registry.upsert(_jellyfin(id: 'a'));
      await registry.upsert(_jellyfin(id: 'b'));
      // First is default by default; explicitly switch to b.
      await registry.setDefault('b');
      expect((await registry.getDefault())?.id, 'b');
      // Switch back to a.
      await registry.setDefault('a');
      expect((await registry.getDefault())?.id, 'a');
    });

    test('remove deletes a row and re-elects a default when needed', () async {
      await registry.upsert(_jellyfin(id: 'a'));
      await registry.upsert(_jellyfin(id: 'b'));
      // a is default (first one in).
      await registry.remove('a');
      // b should now be the default.
      expect((await registry.getDefault())?.id, 'b');
      // Removing the last clears the default cleanly.
      await registry.remove('b');
      expect(await registry.getDefault(), isNull);
    });

    test('re-upsert preserves the existing default flag', () async {
      // Regression: a token/metadata refresh that re-upserts an existing
      // default row used to clear `isDefault` because the writer always
      // wrote `isFirst` (false on update).
      await registry.upsert(_jellyfin(id: 'a'));
      await registry.upsert(_jellyfin(id: 'b'));
      expect((await registry.getDefault())?.id, 'a');

      // Re-upsert the default with refreshed credentials.
      await registry.upsert(_jellyfin(id: 'a', userName: 'refreshed'));
      expect((await registry.getDefault())?.id, 'a');

      // And re-upserting a non-default row doesn't accidentally promote it.
      await registry.upsert(_jellyfin(id: 'b', userName: 'refreshed'));
      expect((await registry.getDefault())?.id, 'a');
    });

    test('recordAuthSuccess updates lastAuthenticatedAt without losing config', () async {
      await registry.upsert(_jellyfin(id: 'a'));
      final at = DateTime.fromMillisecondsSinceEpoch(2_000_000);
      await registry.recordAuthSuccess('a', at);

      final c = await registry.get('a') as JellyfinConnection;
      expect(c.lastAuthenticatedAt, at);
      expect(c.baseUrl, 'https://jellyfin.local');
      expect(c.accessToken, 'tok-a');
    });
  });
}
