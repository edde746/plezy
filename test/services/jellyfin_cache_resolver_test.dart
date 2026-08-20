import 'dart:convert';

import 'package:drift/drift.dart' show ApplyInterceptor, QueryExecutor, QueryInterceptor, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/services/jellyfin_cache_resolver.dart';

void main() {
  late AppDatabase db;
  late JellyfinCacheResolver resolver;
  late _SelectCounter selectCounter;

  setUp(() {
    selectCounter = _SelectCounter();
    db = AppDatabase.forTesting(NativeDatabase.memory().interceptWith(selectCounter));
    resolver = JellyfinCacheResolver(db);
  });

  tearDown(() => db.close());

  Future<void> insertConnection(String machineId, String userId, {String? profileId}) async {
    final connectionId = '$machineId/$userId';
    await db
        .into(db.connections)
        .insert(
          ConnectionsCompanion.insert(
            id: connectionId,
            kind: 'jellyfin',
            displayName: userId,
            configJson: jsonEncode({'serverMachineId': machineId, 'userId': userId}),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    if (profileId != null) {
      await db
          .into(db.profileConnections)
          .insert(
            ProfileConnectionsCompanion.insert(
              profileId: profileId,
              connectionId: connectionId,
              userIdentifier: userId,
            ),
          );
    }
  }

  Future<void> insertItem(String scopeId, String userId, String itemId, {bool pinned = false}) {
    return db
        .into(db.apiCache)
        .insert(
          ApiCacheCompanion.insert(
            cacheKey: '$scopeId:/Users/$userId/Items/$itemId',
            data: jsonEncode({'Id': itemId, 'Name': userId}),
            pinned: Value(pinned),
          ),
        );
  }

  test('bare server id resolves its compound cache row and connection', () async {
    await insertConnection('server', 'user-a');
    await insertItem('server/user-a', 'user-a', 'item-1');

    final match = await resolver.findResolvedItem('server', 'item-1');

    expect(match?.key.scopeId, 'server/user-a');
    expect(match?.connection.id, 'server/user-a');
  });

  test('compound scope selects the same user cache row, connection, and profile binding', () async {
    await insertConnection('server', 'user-a', profileId: 'profile-a');
    await insertConnection('server', 'user-b', profileId: 'profile-b');
    await insertItem('server/user-a', 'user-a', 'item-1');
    await insertItem('server/user-b', 'user-b', 'item-1');

    final match = await resolver.findResolvedItem('server/user-b', 'item-1');

    expect(match?.key.userId, 'user-b');
    expect(match?.connection.id, 'server/user-b');
  });

  test('rejects a cache row whose compound scope and user segment disagree', () async {
    await insertConnection('server', 'user-a');
    await insertConnection('server', 'user-b');
    await insertItem('server/user-a', 'user-b', 'item-1');

    expect(await resolver.findItem('server/user-a', 'item-1'), isNull);
  });

  test('returns no match when the exact user connection is absent', () async {
    await insertConnection('server', 'user-a');
    await insertItem('server/user-b', 'user-b', 'item-1');

    expect(await resolver.findResolvedItem('server/user-b', 'item-1'), isNull);
  });

  test('rejects a connection bound to a different Jellyfin user', () async {
    await insertConnection('server', 'user-a');
    await db
        .into(db.profileConnections)
        .insert(
          ProfileConnectionsCompanion.insert(
            profileId: 'profile-b',
            connectionId: 'server/user-a',
            userIdentifier: 'user-b',
          ),
        );
    await insertItem('server/user-a', 'user-a', 'item-1');

    expect(await resolver.findResolvedItem('server/user-a', 'item-1'), isNull);
  });

  test('treats wildcard characters in server and item ids literally', () async {
    await insertConnection('server_%', 'user-a');
    await insertConnection('server-xx', 'user-a');
    await insertItem('server_%/user-a', 'user-a', 'item_%');
    await insertItem('server-xx/user-a', 'user-a', 'item-zz');

    final match = await resolver.findResolvedItem('server_%', 'item_%');

    expect(match?.key.scopeId, 'server_%/user-a');
    expect(match?.key.itemId, 'item_%');
  });

  test('resolves pinned rows against each exact same-server user connection', () async {
    await insertConnection('server', 'user-a', profileId: 'profile-a');
    await insertConnection('server', 'user-b', profileId: 'profile-b');
    await insertItem('server/user-a', 'user-a', 'item-a', pinned: true);
    await insertItem('server/user-b', 'user-b', 'item-b', pinned: true);

    final matches = await resolver.findPinnedItems();

    expect(matches.map((match) => match.connection.id).toSet(), {'server/user-a', 'server/user-b'});
  });

  test('pinned resolution uses a constant number of selects as rows grow', () async {
    await insertConnection('server', 'user-a', profileId: 'profile-a');
    await insertItem('server/user-a', 'user-a', 'item-1', pinned: true);

    selectCounter.count = 0;
    expect(await resolver.findPinnedItems(), hasLength(1));
    final oneRowSelects = selectCounter.count;

    for (var i = 2; i <= 100; i++) {
      await insertItem('server/user-a', 'user-a', 'item-$i', pinned: true);
    }

    selectCounter.count = 0;
    expect(await resolver.findPinnedItems(), hasLength(100));
    expect(selectCounter.count, oneRowSelects);
    expect(oneRowSelects, 3);
  });
}

class _SelectCounter extends QueryInterceptor {
  int count = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(QueryExecutor executor, String statement, List<Object?> args) {
    count++;
    return executor.runSelect(statement, args);
  }
}
