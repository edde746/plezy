import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/plex_home_cache_codec.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import '../test_helpers/prefs.dart';

PlexHomeUser _user(String uuid, {bool admin = false, bool protected = false, String name = 'User'}) {
  return PlexHomeUser(
    id: 0,
    uuid: uuid,
    title: name,
    username: null,
    email: null,
    friendlyName: null,
    thumb: 'https://plex.tv/users/$uuid/avatar',
    hasPassword: false,
    restricted: false,
    updatedAt: null,
    admin: admin,
    guest: false,
    protected: protected,
  );
}

PlexAccountConnection _account(String id) {
  return PlexAccountConnection(
    id: id,
    accountToken: 'tok-$id',
    clientIdentifier: 'cid-$id',
    accountLabel: 'acct-$id',
    createdAt: DateTime(2026, 1, 1),
  );
}

class _QueuedFetcher {
  final requests = <({String token, Completer<List<PlexHomeUser>> result})>[];
  final _requested = StreamController<void>.broadcast(sync: true);

  Future<List<PlexHomeUser>> call(String token) {
    final result = Completer<List<PlexHomeUser>>();
    requests.add((token: token, result: result));
    _requested.add(null);
    return result.future;
  }

  Future<void> waitForCount(int count) async {
    if (requests.length >= count) return;
    await _requested.stream.firstWhere((_) => requests.length >= count);
  }

  Future<void> close() async {
    for (final request in requests) {
      if (!request.result.isCompleted) request.result.complete(const []);
    }
    await _requested.close();
  }
}

final class _BlockingPreferencesPlatform extends SharedPreferencesAsyncPlatform {
  _BlockingPreferencesPlatform(this.delegate);

  final SharedPreferencesAsyncPlatform delegate;
  String? _blockedStringKey;
  Completer<void>? _writeStarted;
  Completer<void>? _releaseWrite;
  String? _failedStringKey;
  final Map<String, int> stringWriteAttempts = {};

  void blockNextStringWrite(String key) {
    _blockedStringKey = key;
    _writeStarted = Completer<void>();
    _releaseWrite = Completer<void>();
  }

  void failNextStringWrite(String key) {
    _failedStringKey = key;
  }

  Future<void> get writeStarted => _writeStarted!.future;

  void releaseBlockedWrite() {
    final release = _releaseWrite;
    if (release != null && !release.isCompleted) release.complete();
  }

  Future<String?> persistedString(String key) => delegate.getString(key, const SharedPreferencesOptions());

  @override
  Future<void> setString(String key, String value, SharedPreferencesOptions options) async {
    stringWriteAttempts[key] = (stringWriteAttempts[key] ?? 0) + 1;
    if (key == _blockedStringKey) {
      _blockedStringKey = null;
      _writeStarted!.complete();
      await _releaseWrite!.future;
    }
    if (key == _failedStringKey) {
      _failedStringKey = null;
      throw StateError('injected string persistence failure');
    }
    await delegate.setString(key, value, options);
  }

  @override
  Future<void> setInt(String key, int value, SharedPreferencesOptions options) => delegate.setInt(key, value, options);

  @override
  Future<void> setBool(String key, bool value, SharedPreferencesOptions options) =>
      delegate.setBool(key, value, options);

  @override
  Future<void> setDouble(String key, double value, SharedPreferencesOptions options) =>
      delegate.setDouble(key, value, options);

  @override
  Future<void> setStringList(String key, List<String> value, SharedPreferencesOptions options) =>
      delegate.setStringList(key, value, options);

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) => delegate.getString(key, options);

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) => delegate.getBool(key, options);

  @override
  Future<double?> getDouble(String key, SharedPreferencesOptions options) => delegate.getDouble(key, options);

  @override
  Future<int?> getInt(String key, SharedPreferencesOptions options) => delegate.getInt(key, options);

  @override
  Future<List<String>?> getStringList(String key, SharedPreferencesOptions options) =>
      delegate.getStringList(key, options);

  @override
  Future<void> clear(ClearPreferencesParameters parameters, SharedPreferencesOptions options) =>
      delegate.clear(parameters, options);

  @override
  Future<Map<String, Object>> getPreferences(GetPreferencesParameters parameters, SharedPreferencesOptions options) =>
      delegate.getPreferences(parameters, options);

  @override
  Future<Set<String>> getKeys(GetPreferencesParameters parameters, SharedPreferencesOptions options) =>
      delegate.getKeys(parameters, options);
}

void main() {
  late AppDatabase db;
  late ConnectionRegistry connections;
  late ProfileConnectionRegistry profileConnections;
  late StorageService storage;
  late _BlockingPreferencesPlatform preferencesPlatform;
  late PlexHomeService service;

  setUp(() async {
    resetSharedPreferencesForTest();
    preferencesPlatform = _BlockingPreferencesPlatform(SharedPreferencesAsyncPlatform.instance!);
    SharedPreferencesAsyncPlatform.instance = preferencesPlatform;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    connections = ConnectionRegistry(db);
    profileConnections = ProfileConnectionRegistry(db);
    storage = await StorageService.getInstance();
  });

  tearDown(() async {
    await service.dispose();
    await db.close();
  });

  group('PlexHomeService', () {
    test('refresh fetches and caches users for a connection', () async {
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => [_user('admin-uuid', admin: true), _user('kid-uuid', protected: true)],
      );
      final acct = _account('plex.dev1');
      await connections.upsert(acct);
      await service.refresh(acct);

      expect(service.current[acct.id], hasLength(2));
      expect(service.current[acct.id]!.firstWhere((u) => u.admin).uuid, 'admin-uuid');
    });

    test('identical refreshes do not emit a second cache snapshot', () async {
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => [_user('same-user')],
      );
      final acct = _account('plex.same');
      await connections.upsert(acct);
      final emissions = <Map<String, List<PlexHomeUser>>>[];
      final subscription = service.stream.listen(emissions.add);
      addTearDown(subscription.cancel);

      await service.refresh(acct);
      await service.refresh(acct);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(2));
      expect(emissions.last[acct.id]!.single.uuid, 'same-user');
    });
    test('refresh persists users to SharedPreferences', () async {
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => [_user('uuid-1')],
      );
      final acct = _account('plex.dev2');
      await connections.upsert(acct);
      await service.refresh(acct);

      expect(storage.getPlexHomeUsersCacheJson(acct.id), isNotNull);
    });

    test('start hydrates the cache from SharedPreferences', () async {
      // Pre-seed the cache.
      await storage.savePlexHomeUsersCache('plex.dev3', [_user('seeded-uuid').toJson()]);
      final acct = _account('plex.dev3');
      await connections.upsert(acct);

      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => const [], // background refresh returns empty
      );
      await service.start();

      // Cache hydrated synchronously from SharedPreferences before any
      // background fetch resolves.
      expect(service.current[acct.id], hasLength(1));
      expect(service.current[acct.id]!.first.uuid, 'seeded-uuid');
    });

    // `start()` used to be the only entry point, and it was called from a
    // provider `create:` — so it began network refresh before SetupScreen had
    // decided whether the app should go straight offline. `hydrate()` is the
    // disk-only half, safe to call before that decision.
    test('hydrate loads the cache without issuing any network fetch', () async {
      await storage.savePlexHomeUsersCache('plex.hydrate', [_user('cached-uuid').toJson()]);
      final acct = _account('plex.hydrate');
      await connections.upsert(acct);

      final fetcher = _QueuedFetcher();
      addTearDown(fetcher.close);
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: fetcher.call,
      );

      await service.hydrate();
      // Give any stray unawaited refresh a chance to reach the fetcher.
      await Future<void>.delayed(Duration.zero);

      expect(service.current[acct.id]!.single.uuid, 'cached-uuid');
      expect(fetcher.requests, isEmpty, reason: 'hydration must not touch the network');
    });

    test('hydrate still satisfies the stream replay contract', () async {
      // `stream` re-emits on listen so a late listener behind a combineLatest
      // does not sit on ConnectionState.waiting forever. That has to hold even
      // when the live/network side never starts.
      await storage.savePlexHomeUsersCache('plex.replay', [_user('replay-uuid').toJson()]);
      final acct = _account('plex.replay');
      await connections.upsert(acct);

      final fetcher = _QueuedFetcher();
      addTearDown(fetcher.close);
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: fetcher.call,
      );

      await service.hydrate();

      final first = await service.stream.first;
      expect(first[acct.id]!.single.uuid, 'replay-uuid');
      expect(fetcher.requests, isEmpty);
    });

    test('concurrent hydrate calls share one pass and start implies hydration', () async {
      await storage.savePlexHomeUsersCache('plex.coalesce', [_user('coalesce-uuid').toJson()]);
      final acct = _account('plex.coalesce');
      await connections.upsert(acct);

      final fetcher = _QueuedFetcher();
      addTearDown(fetcher.close);
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: fetcher.call,
      );

      // Provider create and a picker opening at the same time.
      await Future.wait([service.hydrate(), service.hydrate(), service.hydrate()]);
      expect(service.current[acct.id]!.single.uuid, 'coalesce-uuid');
      expect(fetcher.requests, isEmpty);

      // start() is self-sufficient: it implies hydration and then goes live.
      await service.start();
      await fetcher.waitForCount(1);
      expect(fetcher.requests, hasLength(1), reason: 'the live side does refresh');
      expect(service.current[acct.id]!.single.uuid, 'coalesce-uuid');
    });

    test('reloadFromStorage picks up caches written after startup', () async {
      final refreshBlocker = Completer<List<PlexHomeUser>>();
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) => refreshBlocker.future,
      );
      addTearDown(() {
        if (!refreshBlocker.isCompleted) refreshBlocker.complete(const []);
      });

      await service.start();
      expect(service.current, isEmpty);

      final acct = _account('plex.migrated');
      await connections.upsert(acct);
      await storage.savePlexHomeUsersCache(acct.id, [_user('migrated-home-user').toJson()]);

      await service.reloadFromStorage();

      expect(service.current[acct.id], hasLength(1));
      expect(service.current[acct.id]!.single.uuid, 'migrated-home-user');
    });

    test('concurrent start calls await the same in-flight startup', () async {
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => const [],
      );

      final first = service.start();
      final second = service.start();

      expect(identical(first, second), isTrue);
      await second;
    });

    test('removing a Plex connection clears its cache slot', () async {
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => [_user('uuid-1')],
      );
      final acct = _account('plex.dev4');
      await connections.upsert(acct);
      await service.refresh(acct);
      expect(service.current[acct.id], isNotNull);

      await service.start();
      // Wait for the service's own stream to emit a snapshot without
      // `acct.id` instead of a fixed-duration sleep — deterministic on slow
      // CI runners and matches when the listener actually settles, not just
      // 30ms after the remove() future resolves.
      final cleared = expectLater(
        service.stream,
        emitsThrough(predicate<Map<String, List<PlexHomeUser>>>((m) => !m.containsKey(acct.id))),
      );
      await connections.remove(acct.id);
      await cleared;

      expect(service.current[acct.id], isNull);
      expect(storage.getPlexHomeUsersCacheJson(acct.id), isNull);
    });

    test('materializeFirstPlexHome wraps the first cached account', () async {
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => [
          _user('admin-uuid', admin: true, name: 'Admin'),
          _user('kid-uuid', name: 'Kid'),
        ],
      );
      final acct = _account('plex.dev5');
      await connections.upsert(acct);
      await service.refresh(acct);

      final home = await service.materializeFirstPlexHome();
      expect(home, isNotNull);
      expect(home!.users, hasLength(2));
      expect(home.adminUser?.uuid, 'admin-uuid');
    });

    test('materializeFirstPlexHome waits for startup cache hydration', () async {
      await storage.savePlexHomeUsersCache('plex.dev-cached', [_user('cached-admin', admin: true).toJson()]);
      final acct = _account('plex.dev-cached');
      await connections.upsert(acct);
      final refreshBlocker = Completer<List<PlexHomeUser>>();
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) => refreshBlocker.future,
      );
      addTearDown(() {
        if (!refreshBlocker.isCompleted) refreshBlocker.complete(const []);
      });

      final home = await service.materializeFirstPlexHome();

      expect(home, isNotNull);
      expect(home!.adminUser?.uuid, 'cached-admin');
    });

    test('clearAll wipes both memory and disk caches', () async {
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: (_) async => [_user('uuid-1')],
      );
      final acct = _account('plex.dev6');
      await connections.upsert(acct);
      await service.refresh(acct);

      await service.clearAll();
      expect(service.current, isEmpty);
      expect(storage.getPlexHomeUsersCacheJson(acct.id), isNull);
    });
    test('later explicit refresh wins regardless of completion order', () async {
      final fetcher = _QueuedFetcher();
      addTearDown(fetcher.close);
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: fetcher.call,
      );
      final acct = _account('plex.ordered');
      await connections.upsert(acct);
      final emissions = <Map<String, List<PlexHomeUser>>>[];
      final subscription = service.stream.listen(emissions.add);
      addTearDown(subscription.cancel);

      final earlier = service.refresh(acct);
      await fetcher.waitForCount(1);
      final later = service.refresh(acct);
      await fetcher.waitForCount(2);
      fetcher.requests[1].result.complete([_user('new-membership')]);
      expect(await later, isTrue);
      fetcher.requests[0].result.complete([_user('stale-membership')]);
      expect(await earlier, isFalse);
      await Future<void>.delayed(Duration.zero);

      expect(service.current[acct.id]!.single.uuid, 'new-membership');
      final persisted = decodePlexHomeUsersCache(storage.getPlexHomeUsersCacheJson(acct.id)!);
      expect(persisted.single.uuid, 'new-membership');
      expect(emissions, hasLength(2));
      expect(emissions.last[acct.id]!.single.uuid, 'new-membership');
      expect(
        emissions.where((snapshot) => snapshot[acct.id]?.any((user) => user.uuid == 'stale-membership') ?? false),
        isEmpty,
      );
    });

    test('identical newer refresh waits for a superseded cache write to settle', () async {
      final fetcher = _QueuedFetcher();
      addTearDown(fetcher.close);
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: fetcher.call,
      );
      final acct = _account('plex.commit-race');
      final cacheKey = 'plex_home_users_${acct.id}';
      await connections.upsert(acct);

      final seed = service.refresh(acct);
      await fetcher.waitForCount(1);
      fetcher.requests[0].result.complete([_user('baseline-membership')]);
      expect(await seed, isTrue);

      preferencesPlatform.blockNextStringWrite(cacheKey);
      addTearDown(preferencesPlatform.releaseBlockedWrite);
      final superseded = service.refresh(acct);
      await fetcher.waitForCount(2);
      fetcher.requests[1].result.complete([_user('new-membership')]);
      await preferencesPlatform.writeStarted;

      expect(decodePlexHomeUsersCache(storage.getPlexHomeUsersCacheJson(acct.id)!).single.uuid, 'new-membership');
      expect(
        decodePlexHomeUsersCache((await preferencesPlatform.persistedString(cacheKey))!).single.uuid,
        'baseline-membership',
      );
      expect(service.current[acct.id]!.single.uuid, 'baseline-membership');

      final newerSettled = Completer<bool>();
      final newer = service.refresh(acct);
      unawaited(newer.then(newerSettled.complete));
      await fetcher.waitForCount(3);
      fetcher.requests[2].result.complete([_user('new-membership')]);
      await Future<void>.delayed(Duration.zero);

      expect(newerSettled.isCompleted, isFalse);
      expect(service.current[acct.id]!.single.uuid, 'baseline-membership');
      preferencesPlatform.releaseBlockedWrite();

      expect(await superseded, isFalse);
      expect(await newer, isTrue);
      expect(service.current[acct.id]!.single.uuid, 'new-membership');
      expect(decodePlexHomeUsersCache(storage.getPlexHomeUsersCacheJson(acct.id)!).single.uuid, 'new-membership');
      expect(
        decodePlexHomeUsersCache((await preferencesPlatform.persistedString(cacheKey))!).single.uuid,
        'new-membership',
      );
    });

    test('identical payload retries after a transient cache persistence failure', () async {
      final fetcher = _QueuedFetcher();
      addTearDown(fetcher.close);
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: fetcher.call,
      );
      final acct = _account('plex.persistence-retry');
      final cacheKey = 'plex_home_users_${acct.id}';
      await connections.upsert(acct);

      final seed = service.refresh(acct);
      await fetcher.waitForCount(1);
      fetcher.requests[0].result.complete([_user('baseline-membership')]);
      expect(await seed, isTrue);

      preferencesPlatform.failNextStringWrite(cacheKey);
      final failed = service.refresh(acct);
      await fetcher.waitForCount(2);
      fetcher.requests[1].result.complete([_user('new-membership')]);
      expect(await failed, isFalse);
      expect(service.current[acct.id]!.single.uuid, 'baseline-membership');
      expect(
        decodePlexHomeUsersCache((await preferencesPlatform.persistedString(cacheKey))!).single.uuid,
        'baseline-membership',
      );

      final attemptsAfterFailure = preferencesPlatform.stringWriteAttempts[cacheKey]!;
      final retry = service.refresh(acct);
      await fetcher.waitForCount(3);
      fetcher.requests[2].result.complete([_user('new-membership')]);

      expect(await retry, isTrue);
      expect(preferencesPlatform.stringWriteAttempts[cacheKey], attemptsAfterFailure + 1);
      expect(service.current[acct.id]!.single.uuid, 'new-membership');
      expect(
        decodePlexHomeUsersCache((await preferencesPlatform.persistedString(cacheKey))!).single.uuid,
        'new-membership',
      );
    });

    test('startup background work coalesces with an active public refresh', () async {
      final fetcher = _QueuedFetcher();
      addTearDown(fetcher.close);
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: fetcher.call,
      );
      final acct = _account('plex.coalesced');
      await connections.upsert(acct);

      final explicit = service.refresh(acct);
      await fetcher.waitForCount(1);
      await service.start();
      await pumpEventQueue();
      expect(fetcher.requests, hasLength(1));

      fetcher.requests.single.result.complete([_user('authoritative')]);
      expect(await explicit, isTrue);
      await pumpEventQueue();
      expect(fetcher.requests, hasLength(1));
      expect(service.current[acct.id]!.single.uuid, 'authoritative');
      expect(decodePlexHomeUsersCache(storage.getPlexHomeUsersCacheJson(acct.id)!).single.uuid, 'authoritative');
    });

    test('overlapping refreshes remain isolated by account', () async {
      final fetcher = _QueuedFetcher();
      addTearDown(fetcher.close);
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: fetcher.call,
      );
      final firstAccount = _account('plex.first');
      final secondAccount = _account('plex.second');
      await connections.upsert(firstAccount);
      await connections.upsert(secondAccount);
      final emissions = <Map<String, List<PlexHomeUser>>>[];
      final subscription = service.stream.listen(emissions.add);
      addTearDown(subscription.cancel);

      final firstRefresh = service.refresh(firstAccount);
      final secondRefresh = service.refresh(secondAccount);
      await fetcher.waitForCount(2);
      expect(fetcher.requests[0].token, firstAccount.accountToken);
      expect(fetcher.requests[1].token, secondAccount.accountToken);
      fetcher.requests[1].result.complete([_user('second-user')]);
      expect(await secondRefresh, isTrue);
      fetcher.requests[0].result.complete([_user('first-user')]);
      expect(await firstRefresh, isTrue);
      await Future<void>.delayed(Duration.zero);

      expect(service.current[firstAccount.id]!.single.uuid, 'first-user');
      expect(service.current[secondAccount.id]!.single.uuid, 'second-user');
      expect(decodePlexHomeUsersCache(storage.getPlexHomeUsersCacheJson(firstAccount.id)!).single.uuid, 'first-user');
      expect(decodePlexHomeUsersCache(storage.getPlexHomeUsersCacheJson(secondAccount.id)!).single.uuid, 'second-user');
      expect(
        emissions,
        contains(
          predicate<Map<String, List<PlexHomeUser>>>(
            (snapshot) => snapshot.containsKey(firstAccount.id) && snapshot.containsKey(secondAccount.id),
          ),
        ),
      );
    });

    test('connection removal invalidates a blocked refresh before clearing cache', () async {
      final fetcher = _QueuedFetcher();
      addTearDown(fetcher.close);
      final acct = _account('plex.removed-late');
      await connections.upsert(acct);
      await storage.savePlexHomeUsersCache(acct.id, [_user('cached-before-removal').toJson()]);
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: fetcher.call,
      );
      await service.start();
      await fetcher.waitForCount(1);
      final emissions = <Map<String, List<PlexHomeUser>>>[];
      final subscription = service.stream.listen(emissions.add);
      addTearDown(subscription.cancel);
      final removedSnapshot = service.stream.firstWhere((snapshot) => !snapshot.containsKey(acct.id));

      await connections.remove(acct.id);
      await removedSnapshot;
      fetcher.requests.single.result.complete([_user('late-user')]);
      await pumpEventQueue();

      expect(service.current, isNot(contains(acct.id)));
      expect(storage.getPlexHomeUsersCacheJson(acct.id), isNull);
      expect(emissions.where((snapshot) => !snapshot.containsKey(acct.id)), hasLength(1));
    });

    test('remove then re-add during a blocked refresh keeps the replacement cache', () async {
      final fetcher = _QueuedFetcher();
      addTearDown(fetcher.close);
      final original = _account('plex.readded');
      await connections.upsert(original);
      await storage.savePlexHomeUsersCache(original.id, [_user('cached-before-removal').toJson()]);
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: fetcher.call,
      );
      await service.start();
      await fetcher.waitForCount(1);

      await connections.remove(original.id);
      await pumpEventQueue();
      final replacement = PlexAccountConnection(
        id: original.id,
        accountToken: 'replacement-token',
        clientIdentifier: original.clientIdentifier,
        accountLabel: original.accountLabel,
        createdAt: original.createdAt,
      );
      await connections.upsert(replacement);
      fetcher.requests.first.result.complete([_user('stale-user')]);
      await fetcher.waitForCount(2);
      expect(fetcher.requests[1].token, 'replacement-token');
      fetcher.requests[1].result.complete([_user('replacement-user')]);
      await pumpEventQueue();

      expect(service.current[original.id]!.single.uuid, 'replacement-user');
      expect(decodePlexHomeUsersCache(storage.getPlexHomeUsersCacheJson(original.id)!).single.uuid, 'replacement-user');
    });
    test('clearAll invalidates a blocked refresh without a late emission', () async {
      final fetcher = _QueuedFetcher();
      addTearDown(fetcher.close);
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: fetcher.call,
      );
      final acct = _account('plex.cleared-late');
      await connections.upsert(acct);
      final emissions = <Map<String, List<PlexHomeUser>>>[];
      final subscription = service.stream.listen(emissions.add);
      addTearDown(subscription.cancel);

      final refresh = service.refresh(acct);
      await fetcher.waitForCount(1);
      await service.clearAll();
      fetcher.requests.single.result.complete([_user('late-user')]);
      expect(await refresh, isFalse);
      await Future<void>.delayed(Duration.zero);

      expect(service.current, isEmpty);
      expect(storage.getPlexHomeUsersCacheJson(acct.id), isNull);
      expect(emissions, hasLength(2));
      expect(emissions.every((snapshot) => !snapshot.containsKey(acct.id)), isTrue);
    });

    test('dispose invalidates a blocked refresh without restoring state', () async {
      final fetcher = _QueuedFetcher();
      addTearDown(fetcher.close);
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: fetcher.call,
      );
      final acct = _account('plex.disposed-late');
      await connections.upsert(acct);
      final emissions = <Map<String, List<PlexHomeUser>>>[];
      final subscription = service.stream.listen(emissions.add);
      addTearDown(subscription.cancel);

      final refresh = service.refresh(acct);
      await fetcher.waitForCount(1);
      await service.dispose();
      fetcher.requests.single.result.complete([_user('late-user')]);
      expect(await refresh, isFalse);
      await Future<void>.delayed(Duration.zero);

      expect(service.current, isEmpty);
      expect(storage.getPlexHomeUsersCacheJson(acct.id), isNull);
      expect(emissions.every((snapshot) => !snapshot.containsKey(acct.id)), isTrue);
    });

    test('failed refresh preserves the completed cache without another emission', () async {
      final fetcher = _QueuedFetcher();
      addTearDown(fetcher.close);
      service = PlexHomeService(
        connections: connections,
        profileConnections: profileConnections,
        storage: storage,
        plexHomeUserFetcher: fetcher.call,
      );
      final acct = _account('plex.failure-cache');
      await connections.upsert(acct);
      final emissions = <Map<String, List<PlexHomeUser>>>[];
      final subscription = service.stream.listen(emissions.add);
      addTearDown(subscription.cancel);

      final seededRefresh = service.refresh(acct);
      await fetcher.waitForCount(1);
      fetcher.requests[0].result.complete([_user('preserved-user')]);
      expect(await seededRefresh, isTrue);
      final failedRefresh = service.refresh(acct);
      await fetcher.waitForCount(2);
      fetcher.requests[1].result.completeError(StateError('synthetic fetch failure'));
      expect(await failedRefresh, isFalse);
      await Future<void>.delayed(Duration.zero);

      expect(service.current[acct.id]!.single.uuid, 'preserved-user');
      expect(decodePlexHomeUsersCache(storage.getPlexHomeUsersCacheJson(acct.id)!).single.uuid, 'preserved-user');
      expect(emissions, hasLength(2));
    });
  });
}
