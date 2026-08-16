import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_browser_dialect.dart';
import 'package:plezy/services/credential_vault.dart';
import 'package:plezy/services/plex_auth_service.dart';

import '../test_helpers/prefs.dart';

/// The id of the connection currently flagged default, read straight from the
/// row (the registry maintains the flag; there is no public reader).
Future<String?> _defaultConnectionId(AppDatabase db) async {
  for (final row in await db.select(db.connections).get()) {
    if (row.isDefault) return row.id;
  }
  return null;
}

JellyfinConnection _jellyfin({String id = 'srv-1', String userName = 'edde', int createdAtMs = 1_000_000}) {
  return JellyfinConnection(
    id: id,
    baseUrl: 'https://jellyfin.local',
    serverName: 'Home',
    serverMachineId: 'jf-machine-$id',
    userId: 'user-$id',
    userName: userName,
    accessToken: 'tok-$id',
    deviceId: 'dev-1',
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
  );
}

JellyfinConnection _emby({String id = 'emby-1', String accessToken = 'emby-token', int createdAtMs = 1_000_000}) {
  return JellyfinConnection(
    id: id,
    baseUrl: 'https://emby.local',
    serverName: 'Emby Home',
    serverMachineId: 'emby-machine-$id',
    userId: 'user-$id',
    userName: 'edde',
    accessToken: accessToken,
    deviceId: 'dev-1',
    dialect: MediaBrowserDialect.emby,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
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
      expect(await _defaultConnectionId(db), isNull);
    });

    test('first upserted connection becomes the default', () async {
      await registry.upsert(_jellyfin(id: 'a'));
      final list = await registry.list();
      expect(list.length, 1);
      expect(list.first.id, 'a');

      expect(await _defaultConnectionId(db), 'a');
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

    test('Emby upsert preserves its persisted discriminator and connection dialect', () async {
      await registry.upsert(_emby(id: 'e'));

      final restored = await registry.get('e') as JellyfinConnection;
      final row = await (db.select(db.connections)..where((table) => table.id.equals('e'))).getSingle();

      expect(restored.dialect, MediaBrowserDialect.emby);
      expect(restored.kind, MediaBackend.emby);
      expect(restored.kind.id, 'emby');
      expect(row.kind, 'emby');
    });

    test('Jellyfin and Emby rows coexist and round-trip to their own dialects', () async {
      await registry.upsert(_jellyfin(id: 'j'));
      await registry.upsert(_emby(id: 'e'));

      final jellyfin = await registry.get('j') as JellyfinConnection;
      final emby = await registry.get('e') as JellyfinConnection;
      final rows = await db.select(db.connections).get();
      final kindById = {for (final row in rows) row.id: row.kind};

      expect(jellyfin.dialect, MediaBrowserDialect.jellyfin);
      expect(jellyfin.kind, MediaBackend.jellyfin);
      expect(emby.dialect, MediaBrowserDialect.emby);
      expect(emby.kind, MediaBackend.emby);
      expect(kindById, {'j': 'jellyfin', 'e': 'emby'});
    });

    test('upsert encrypts tokens at rest and decrypts on read', () async {
      await registry.upsert(_plex(id: 'p'));
      await registry.upsert(_jellyfin(id: 'j'));
      await registry.upsert(_emby(id: 'e', accessToken: 'emby-raw-token'));

      final rows = await db.select(db.connections).get();
      expect(rows.singleWhere((r) => r.id == 'p').configJson, isNot(contains('tok-p')));
      expect(rows.singleWhere((r) => r.id == 'p').configJson, isNot(contains('server-token-p')));
      expect(rows.singleWhere((r) => r.id == 'j').configJson, isNot(contains('tok-j')));
      expect(rows.singleWhere((r) => r.id == 'e').configJson, isNot(contains('emby-raw-token')));

      expect((await registry.get('p') as PlexAccountConnection).accountToken, 'tok-p');
      expect((await registry.get('p') as PlexAccountConnection).servers.single.accessToken, 'server-token-p');
      expect((await registry.get('j') as JellyfinConnection).accessToken, 'tok-j');
      expect((await registry.get('e') as JellyfinConnection).accessToken, 'emby-raw-token');
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
      await registry.setDefault('b');
      expect(await _defaultConnectionId(db), 'b');
      await registry.setDefault('a');
      expect(await _defaultConnectionId(db), 'a');
    });

    test('remove deletes a row and re-elects a default when needed', () async {
      await registry.upsert(_jellyfin(id: 'a'));
      await registry.upsert(_jellyfin(id: 'b'));
      await registry.remove('a');
      expect(await _defaultConnectionId(db), 'b');
      await registry.remove('b');
      expect(await _defaultConnectionId(db), isNull);
    });

    test('re-upsert preserves the existing default flag', () async {
      // Regression: a token/metadata refresh that re-upserts an existing
      // default row used to clear `isDefault` because the writer always
      // wrote `isFirst` (false on update).
      await registry.upsert(_jellyfin(id: 'a'));
      await registry.upsert(_jellyfin(id: 'b'));
      expect(await _defaultConnectionId(db), 'a');

      await registry.upsert(_jellyfin(id: 'a', userName: 'refreshed'));
      expect(await _defaultConnectionId(db), 'a');

      await registry.upsert(_jellyfin(id: 'b', userName: 'refreshed'));
      expect(await _defaultConnectionId(db), 'a');
    });

    test('re-upsert preserves the original creation order', () async {
      // Regression: creation order decides which connection lends a profile
      // its picture (issue #1667) and which row `remove` promotes to default.
      // Re-authenticating rebuilds the model with `DateTime.now()` under the
      // same stable id, so an unguarded writer restamped the originally-first
      // connection and shuffled it to last.
      await registry.upsert(_jellyfin(id: 'first', createdAtMs: 1_000_000));
      await registry.upsert(_jellyfin(id: 'second', createdAtMs: 2_000_000));

      await registry.upsert(_jellyfin(id: 'first', createdAtMs: 9_000_000));

      final list = await registry.list();
      expect(list.map((c) => c.id).toList(), ['first', 'second']);
      expect(list.first.createdAt, DateTime.fromMillisecondsSinceEpoch(1_000_000));
    });

    test('a genuinely new connection keeps the creation time it was built with', () async {
      await registry.upsert(_jellyfin(id: 'a', createdAtMs: 5_000_000));

      expect((await registry.list()).single.createdAt, DateTime.fromMillisecondsSinceEpoch(5_000_000));
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
