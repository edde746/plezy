import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/database/download_operations.dart';
import 'package:plezy/database/tvos_database_recovery_store.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/credential_vault.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import '../test_helpers/prefs.dart';

JellyfinConnection _connection(String id) => JellyfinConnection(
  id: id,
  baseUrl: 'https://media.invalid/$id',
  serverName: 'Server $id',
  serverMachineId: id,
  userId: 'user-$id',
  userName: 'User $id',
  accessToken: 'protected-connection-canary-$id',
  deviceId: 'device-$id',
  createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
);

Profile _profile(String id) => Profile.local(
  id: id,
  displayName: 'Profile $id',
  pinHash: computePinHash('1234'),
  createdAt: DateTime.fromMillisecondsSinceEpoch(2000),
);

final class _FailingStringPreferencesPlatform extends SharedPreferencesAsyncPlatform {
  _FailingStringPreferencesPlatform(this.delegate);

  final SharedPreferencesAsyncPlatform delegate;
  String? failNextKey;
  final Map<String, int> stringWriteAttempts = {};

  Future<String?> persistedString(String key) => delegate.getString(key, const SharedPreferencesOptions());

  @override
  Future<void> setString(String key, String value, SharedPreferencesOptions options) async {
    stringWriteAttempts[key] = (stringWriteAttempts[key] ?? 0) + 1;
    if (key == failNextKey) {
      failNextKey = null;
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

Future<void> _deleteDatabase(File file) async {
  for (final path in [file.path, '${file.path}-wal', '${file.path}-shm']) {
    final candidate = File(path);
    if (await candidate.exists()) await candidate.delete();
  }
}

Future<List<List<Object>>> _criticalRows(AppDatabase db) async => [
  await (db.select(db.connections)..orderBy([(t) => OrderingTerm.asc(t.id)])).get(),
  await (db.select(db.profiles)..orderBy([(t) => OrderingTerm.asc(t.id)])).get(),
  await (db.select(
    db.profileConnections,
  )..orderBy([(t) => OrderingTerm.asc(t.profileId), (t) => OrderingTerm.asc(t.connectionId)])).get(),
  await (db.select(db.offlineWatchProgress)..orderBy([(t) => OrderingTerm.asc(t.id)])).get(),
];

Future<void> _seedCriticalRows(AppDatabase db) async {
  await ConnectionRegistry(db).upsert(_connection('server-1'));
  await ProfileRegistry(db).upsert(_profile('local-1'));
  await ProfileConnectionRegistry(db).upsert(
    const ProfileConnection(
      profileId: 'local-1',
      connectionId: 'server-1',
      userToken: 'protected-profile-token-canary',
      userIdentifier: 'user-1',
    ),
  );

  await db.upsertProgressAction(
    profileId: 'local-1',
    serverId: ServerId('server-1'),
    clientScopeId: 'server-1/user-1',
    ratingKey: 'progress',
    viewOffset: 1234,
    duration: 9999,
    shouldMarkWatched: false,
  );
  await db.insertWatchAction(
    profileId: 'local-1',
    serverId: ServerId('server-1'),
    clientScopeId: 'server-1/user-1',
    ratingKey: 'watched',
    actionType: OfflineActionType.watched.id,
  );
  await db.insertWatchAction(
    profileId: 'local-1',
    serverId: ServerId('server-1'),
    clientScopeId: 'server-1/user-1',
    ratingKey: 'unwatched',
    actionType: OfflineActionType.unwatched.id,
  );

  final rows = await db.getPendingWatchActions(profileId: 'local-1');
  for (var index = 0; index < rows.length; index++) {
    await (db.update(db.offlineWatchProgress)..where((t) => t.id.equals(rows[index].id))).write(
      OfflineWatchProgressCompanion(createdAt: Value(3000 + index), updatedAt: Value(4000 + index)),
    );
  }
  final revisedFirst = await (db.select(db.offlineWatchProgress)..where((t) => t.id.equals(rows.first.id))).getSingle();
  await db.updateSyncAttemptIfUnchanged(revisedFirst.id, revisedFirst.updatedAt, 'retry-without-protected-payload');
  await db.updateSyncAttemptIfUnchanged(revisedFirst.id, revisedFirst.updatedAt, 'retry-without-protected-payload');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File databaseFile;
  late SharedPreferencesWithCache prefs;
  AppDatabase? database;

  Future<AppDatabaseBootstrap> open({
    bool isTvos = true,
    TvosDatabaseRecoveryStore? store,
    TvosDatabaseRecoveryPriorInstallEvidence? priorEvidence,
  }) async {
    final result = await AppDatabase.open(
      isTvos: isTvos,
      databaseFile: databaseFile,
      preferences: prefs,
      recoveryStore: store,
      priorInstallEvidence: priorEvidence,
    );
    database = result.database;
    return result;
  }

  Future<void> closeAndDelete() async {
    await database?.close();
    database = null;
    await _deleteDatabase(databaseFile);
  }

  setUp(() async {
    resetSharedPreferencesForTest();
    tempDir = await Directory.systemTemp.createTemp('plezy_tvos_recovery_');
    databaseFile = File('${tempDir.path}/plezy_downloads.db');
    prefs = await BaseSharedPreferencesService.sharedCache();
  });

  tearDown(() async {
    await database?.close();
    await tempDir.delete(recursive: true);
  });

  test('restores exact four critical groups and excludes reconstructible tables', () async {
    final first = await open();
    expect(first.recoveryOutcome, TvosDatabaseRecoveryOutcome.fresh);
    await _seedCriticalRows(first.database);

    await first.database.into(first.database.apiCache).insert(ApiCacheCompanion.insert(cacheKey: 'cache', data: '{}'));
    await first.database
        .into(first.database.downloadedMedia)
        .insert(
          DownloadedMediaCompanion.insert(
            serverId: 'server-1',
            ratingKey: 'download',
            globalKey: 'server-1:download',
            type: 'movie',
            status: DownloadStatus.completed.index,
          ),
        );
    await first.database.addDownloadOwner(profileId: 'local-1', globalKey: 'server-1:download');
    await first.database
        .into(first.database.downloadQueue)
        .insert(DownloadQueueCompanion.insert(mediaGlobalKey: 'server-1:download', addedAt: 5000));
    await first.database.insertSyncRule(
      profileId: 'local-1',
      serverId: ServerId('server-1'),
      ratingKey: 'rule',
      globalKey: 'server-1:rule',
      targetType: 'movie',
      episodeCount: 1,
    );

    final expected = await _criticalRows(first.database);
    await closeAndDelete();

    final restored = await open();
    expect(restored.recoveryOutcome, TvosDatabaseRecoveryOutcome.restored);
    expect(await _criticalRows(restored.database), expected);
    expect(await restored.database.select(restored.database.apiCache).get(), isEmpty);
    expect(await restored.database.select(restored.database.downloadedMedia).get(), isEmpty);
    expect(await restored.database.select(restored.database.downloadOwners).get(), isEmpty);
    expect(await restored.database.select(restored.database.downloadQueue).get(), isEmpty);
    expect(await restored.database.select(restored.database.syncRules).get(), isEmpty);
  });

  test('legacy plaintext committed image is restored and replaced with protected credentials', () async {
    CredentialVault.resetKeyForTesting();
    const connectionToken = 'legacy-plaintext-connection-token';
    const profileToken = 'legacy-plaintext-profile-token';
    final legacyConfig = jsonEncode({
      'baseUrl': 'https://legacy.invalid',
      'accessToken': connectionToken,
      'userId': 'legacy-user',
    });
    final identityPayload = jsonEncode({
      'version': TvosDatabaseRecoveryStore.recoveryFormatVersion,
      'rows': {
        'connections': [
          {
            'id': 'legacy-jellyfin',
            'kind': 'jellyfin',
            'displayName': 'Legacy Jellyfin',
            'configJson': legacyConfig,
            'isDefault': true,
            'createdAt': 1000,
            'lastAuthenticatedAt': null,
          },
        ],
        'profiles': [
          {
            'id': 'legacy-profile',
            'kind': 'local',
            'displayName': 'Legacy Profile',
            'avatarThumbUrl': null,
            'configJson': '{}',
            'sortOrder': 0,
            'createdAt': 2000,
            'lastUsedAt': null,
          },
        ],
        'profileConnections': [
          {
            'profileId': 'legacy-profile',
            'connectionId': 'legacy-jellyfin',
            'userToken': profileToken,
            'userIdentifier': 'legacy-user',
            'isDefault': true,
            'tokenAcquiredAt': null,
            'lastUsedAt': null,
          },
        ],
      },
    });
    final pendingPayload = jsonEncode({
      'version': TvosDatabaseRecoveryStore.recoveryFormatVersion,
      'rows': {'offlineWatchProgress': <Object?>[]},
    });
    final manifest = jsonEncode({
      'version': TvosDatabaseRecoveryStore.recoveryFormatVersion,
      'state': 'committed',
      'identityDigest': sha256.convert(utf8.encode(identityPayload)).toString(),
      'pendingDigest': sha256.convert(utf8.encode(pendingPayload)).toString(),
    });
    await prefs.setString(TvosDatabaseRecoveryStore.identityKey, identityPayload);
    await prefs.setString(TvosDatabaseRecoveryStore.pendingKey, pendingPayload);
    await prefs.setString(TvosDatabaseRecoveryStore.manifestKey, manifest);

    final restored = await open();
    expect(restored.recoveryOutcome, TvosDatabaseRecoveryOutcome.restored);

    final connectionRow = await restored.database.select(restored.database.connections).getSingle();
    final restoredConfig = jsonDecode(connectionRow.configJson) as Map<String, dynamic>;
    final protectedConnectionToken = restoredConfig['accessToken'] as String;
    expect(CredentialVault.isProtected(protectedConnectionToken), isTrue);
    expect(await CredentialVault.reveal(protectedConnectionToken), connectionToken);
    final joinRow = await restored.database.select(restored.database.profileConnections).getSingle();
    expect(CredentialVault.isProtected(joinRow.userToken), isTrue);
    expect(await CredentialVault.reveal(joinRow.userToken), profileToken);

    final replacementIdentity = prefs.getString(TvosDatabaseRecoveryStore.identityKey)!;
    expect(replacementIdentity, isNot(contains(connectionToken)));
    expect(replacementIdentity, isNot(contains(profileToken)));
    final replacementRows = (jsonDecode(replacementIdentity) as Map<String, dynamic>)['rows'] as Map<String, dynamic>;
    final replacementConnection = (replacementRows['connections'] as List).single as Map<String, dynamic>;
    final replacementConfig = jsonDecode(replacementConnection['configJson'] as String) as Map<String, dynamic>;
    expect(await CredentialVault.reveal(replacementConfig['accessToken'] as String), connectionToken);
    final replacementJoin = (replacementRows['profileConnections'] as List).single as Map<String, dynamic>;
    expect(await CredentialVault.reveal(replacementJoin['userToken'] as String), profileToken);

    final replacementManifest =
        jsonDecode(prefs.getString(TvosDatabaseRecoveryStore.manifestKey)!) as Map<String, dynamic>;
    expect(replacementManifest['state'], 'committed');
    expect(replacementManifest['identityDigest'], sha256.convert(utf8.encode(replacementIdentity)).toString());
  });

  test('rejects unreleased generation-bearing recovery payloads', () async {
    final first = await open();
    await ProfileRegistry(first.database).upsert(_profile('unknown-generation'));
    await first.database.close();
    database = null;

    final identity = jsonDecode(prefs.getString(TvosDatabaseRecoveryStore.identityKey)!) as Map<String, dynamic>;
    final pending = jsonDecode(prefs.getString(TvosDatabaseRecoveryStore.pendingKey)!) as Map<String, dynamic>;
    final manifest = jsonDecode(prefs.getString(TvosDatabaseRecoveryStore.manifestKey)!) as Map<String, dynamic>;
    identity['generation'] = 7;
    pending['generation'] = 11;
    final legacyIdentity = jsonEncode(identity);
    final legacyPending = jsonEncode(pending);
    manifest
      ..['identityGeneration'] = 7
      ..['identityDigest'] = sha256.convert(utf8.encode(legacyIdentity)).toString()
      ..['pendingGeneration'] = 11
      ..['pendingDigest'] = sha256.convert(utf8.encode(legacyPending)).toString();
    await prefs.setString(TvosDatabaseRecoveryStore.identityKey, legacyIdentity);
    await prefs.setString(TvosDatabaseRecoveryStore.pendingKey, legacyPending);
    await prefs.setString(TvosDatabaseRecoveryStore.manifestKey, jsonEncode(manifest));
    await _deleteDatabase(databaseFile);

    final rejected = await open();
    expect(rejected.recoveryOutcome, TvosDatabaseRecoveryOutcome.recoveryRequired);
    expect(await _criticalRows(rejected.database), everyElement(isEmpty));
  });

  for (final failurePhase in ['mutation', 'row read']) {
    test('$failurePhase failure does not poison later durable mutations', () async {
      final store = TvosDatabaseRecoveryStore(prefs, isTvos: true);
      final first = await open(store: store);
      final originalError = StateError('injected $failurePhase failure');

      await expectLater(
        store.runDurableMutation<void>(
          group: TvosDatabaseRecoveryGroup.identity,
          mutation: () async {
            if (failurePhase == 'mutation') throw originalError;
          },
          readIdentity: () async {
            if (failurePhase == 'row read') throw originalError;
            return const {'connections': <Object?>[], 'profiles': <Object?>[], 'profileConnections': <Object?>[]};
          },
          readPending: () async => const {'offlineWatchProgress': <Object?>[]},
        ),
        throwsA(same(originalError)),
      );

      await ProfileRegistry(first.database).upsert(_profile('after-$failurePhase'));
      expect(await ProfileRegistry(first.database).get('after-$failurePhase'), isNotNull);
    });
  }

  test('failed manifest invalidation reloads durable state and retries before mutation', () async {
    await database?.close();
    database = null;
    resetSharedPreferencesForTest();
    final preferencesPlatform = _FailingStringPreferencesPlatform(SharedPreferencesAsyncPlatform.instance!);
    SharedPreferencesAsyncPlatform.instance = preferencesPlatform;
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = preferencesPlatform.delegate);
    prefs = await BaseSharedPreferencesService.sharedCache();

    final store = TvosDatabaseRecoveryStore(prefs, isTvos: true);
    await open(store: store);
    final durableManifest = await preferencesPlatform.persistedString(TvosDatabaseRecoveryStore.manifestKey);
    expect(durableManifest, contains('committed'));

    var mutationCount = 0;
    Future<void> mutate() => store.runDurableMutation<void>(
      group: TvosDatabaseRecoveryGroup.identity,
      mutation: () async {
        mutationCount++;
      },
      readIdentity: () async => const {
        'connections': <Object?>[],
        'profiles': <Object?>[],
        'profileConnections': <Object?>[],
      },
      readPending: () async => const {'offlineWatchProgress': <Object?>[]},
    );

    preferencesPlatform.failNextKey = TvosDatabaseRecoveryStore.manifestKey;
    await expectLater(mutate(), throwsA(isA<TvosDatabaseDurabilityException>()));
    expect(mutationCount, 0, reason: 'the authoritative mutation must wait for durable invalidation');
    expect(prefs.getString(TvosDatabaseRecoveryStore.manifestKey), durableManifest);
    expect(await preferencesPlatform.persistedString(TvosDatabaseRecoveryStore.manifestKey), durableManifest);

    final attemptsAfterFailure = preferencesPlatform.stringWriteAttempts[TvosDatabaseRecoveryStore.manifestKey]!;
    await mutate();
    expect(mutationCount, 1);
    expect(
      preferencesPlatform.stringWriteAttempts[TvosDatabaseRecoveryStore.manifestKey],
      greaterThan(attemptsAfterFailure),
    );
    expect(await preferencesPlatform.persistedString(TvosDatabaseRecoveryStore.manifestKey), contains('committed'));
  });

  test('unrelated preferences do not consume the recovery image budget', () async {
    final first = await open();
    await ProfileRegistry(first.database).upsert(_profile('survives-large-settings'));
    await first.database.close();
    database = null;
    await prefs.setString('unrelated_large_setting', List.filled(500000, 'x').join());
    await _deleteDatabase(databaseFile);

    final restored = await open();
    expect(restored.recoveryOutcome, TvosDatabaseRecoveryOutcome.restored);
    expect(await ProfileRegistry(restored.database).get('survives-large-settings'), isNotNull);
  });

  group('startup classification', () {
    test('non-tvOS is notApplicable and writes no recovery keys', () async {
      final result = await open(isTvos: false);
      expect(result.recoveryOutcome, TvosDatabaseRecoveryOutcome.notApplicable);
      expect(prefs.keys.where((key) => key.startsWith(TvosDatabaseRecoveryStore.keyPrefix)), isEmpty);
    });

    test('missing database without marker or evidence is fresh', () async {
      final result = await open();
      expect(result.recoveryOutcome, TvosDatabaseRecoveryOutcome.fresh);
      expect(prefs.getString(TvosDatabaseRecoveryStore.manifestKey), contains('committed'));
    });

    test('a wrong-typed recovery marker behaves like a missing one', () async {
      // `reconcile` runs inside `AppDatabase.open`, a fatal startup step, so
      // a mistyped marker used to throw a raw TypeError and veto the launch
      // outright on a first-class TV target (#1732). An unreadable marker
      // tells us nothing, which is the same position as an absent one.
      await prefs.setString(TvosDatabaseRecoveryStore.recoveryRequiredKey, 'yes');

      final result = await open();

      expect(result.recoveryOutcome, TvosDatabaseRecoveryOutcome.fresh);
      expect(prefs.getString(TvosDatabaseRecoveryStore.manifestKey), contains('committed'));

      // The unreadable value is dropped so the next launch starts clean. The
      // removal is fire-and-forget, so give it a turn to land.
      for (var i = 0; i < 20 && prefs.keys.contains(TvosDatabaseRecoveryStore.recoveryRequiredKey); i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(prefs.keys, isNot(contains(TvosDatabaseRecoveryStore.recoveryRequiredKey)));
    });

    test('missing database with prior-install evidence requires recovery', () async {
      await prefs.setString('active_app_profile_id', 'surviving-profile');
      final result = await open();
      expect(result.recoveryOutcome, TvosDatabaseRecoveryOutcome.recoveryRequired);
      expect((await _criticalRows(result.database)).expand((rows) => rows), isEmpty);
    });

    test('recovery-required marker gates a materialized empty database until acknowledgement', () async {
      await prefs.setString('active_app_profile_id', 'surviving-profile');

      final missing = await open();
      expect(missing.recoveryOutcome, TvosDatabaseRecoveryOutcome.recoveryRequired);
      expect(prefs.getBool(TvosDatabaseRecoveryStore.recoveryRequiredKey), isTrue);
      await missing.database.close();
      database = null;

      final restarted = await open();
      expect(restarted.recoveryOutcome, TvosDatabaseRecoveryOutcome.recoveryRequired);
      expect(prefs.getBool(TvosDatabaseRecoveryStore.recoveryRequiredKey), isTrue);
      await expectLater(
        ProfileRegistry(restarted.database).upsert(_profile('blocked-after-restart')),
        throwsA(isA<TvosDatabaseDurabilityException>()),
      );
      expect(await ProfileRegistry(restarted.database).get('blocked-after-restart'), isNull);

      await restarted.database.acknowledgeTvosDatabaseRecoveryRequired();
      expect(prefs.getBool(TvosDatabaseRecoveryStore.recoveryRequiredKey), isNull);
      await ProfileRegistry(restarted.database).upsert(_profile('acknowledged'));
      await closeAndDelete();

      final restored = await open();
      expect(restored.recoveryOutcome, TvosDatabaseRecoveryOutcome.restored);
      expect(await ProfileRegistry(restored.database).get('acknowledged'), isNotNull);
    });

    test('successful restore clears recovery-required gate on a materialized candidate', () async {
      final first = await open();
      await ProfileRegistry(first.database).upsert(_profile('restored-after-restart'));
      await first.database.close();
      database = null;
      final identity = prefs.getString(TvosDatabaseRecoveryStore.identityKey)!;
      final pending = prefs.getString(TvosDatabaseRecoveryStore.pendingKey)!;
      final manifest = prefs.getString(TvosDatabaseRecoveryStore.manifestKey)!;
      await prefs.setString(TvosDatabaseRecoveryStore.identityKey, '$identity-corrupt');
      await _deleteDatabase(databaseFile);

      final missing = await open();
      expect(missing.recoveryOutcome, TvosDatabaseRecoveryOutcome.recoveryRequired);
      expect(prefs.getBool(TvosDatabaseRecoveryStore.recoveryRequiredKey), isTrue);
      expect(await ProfileRegistry(missing.database).get('restored-after-restart'), isNull);
      await missing.database.close();
      database = null;

      await prefs.setString(TvosDatabaseRecoveryStore.identityKey, identity);
      await prefs.setString(TvosDatabaseRecoveryStore.pendingKey, pending);
      await prefs.setString(TvosDatabaseRecoveryStore.manifestKey, manifest);
      final restarted = await open();

      expect(restarted.recoveryOutcome, TvosDatabaseRecoveryOutcome.restored);
      expect(prefs.getBool(TvosDatabaseRecoveryStore.recoveryRequiredKey), isNull);
      expect(await ProfileRegistry(restarted.database).get('restored-after-restart'), isNotNull);
    });

    test('failed marker removal replays a successful restore idempotently on restart', () async {
      final first = await open();
      await _seedCriticalRows(first.database);
      final expected = await _criticalRows(first.database);
      await first.database.close();
      database = null;

      final identity = prefs.getString(TvosDatabaseRecoveryStore.identityKey)!;
      final pending = prefs.getString(TvosDatabaseRecoveryStore.pendingKey)!;
      final manifest = prefs.getString(TvosDatabaseRecoveryStore.manifestKey)!;
      await prefs.setString(TvosDatabaseRecoveryStore.identityKey, '$identity-corrupt');
      await _deleteDatabase(databaseFile);

      final missing = await open();
      expect(missing.recoveryOutcome, TvosDatabaseRecoveryOutcome.recoveryRequired);
      expect(prefs.getBool(TvosDatabaseRecoveryStore.recoveryRequiredKey), isTrue);
      await missing.database.close();
      database = null;

      await prefs.setString(TvosDatabaseRecoveryStore.identityKey, identity);
      await prefs.setString(TvosDatabaseRecoveryStore.pendingKey, pending);
      await prefs.setString(TvosDatabaseRecoveryStore.manifestKey, manifest);
      var markerRemovalAttempts = 0;
      final failingStore = TvosDatabaseRecoveryStore(
        prefs,
        isTvos: true,
        debugBeforePreferenceWrite: (key) async {
          if (key == TvosDatabaseRecoveryStore.recoveryRequiredKey) {
            markerRemovalAttempts++;
            throw StateError('marker removal failed');
          }
        },
      );

      final restoredButUnmarked = await open(store: failingStore);
      expect(restoredButUnmarked.recoveryOutcome, TvosDatabaseRecoveryOutcome.recoveryRequired);
      expect(markerRemovalAttempts, 1);
      expect(await _criticalRows(restoredButUnmarked.database), expected);
      expect(prefs.getBool(TvosDatabaseRecoveryStore.recoveryRequiredKey), isTrue);
      await restoredButUnmarked.database.close();
      database = null;

      final replayed = await open();
      expect(replayed.recoveryOutcome, TvosDatabaseRecoveryOutcome.restored);
      expect(await _criticalRows(replayed.database), expected);
      expect(prefs.getBool(TvosDatabaseRecoveryStore.recoveryRequiredKey), isNull);
      await replayed.database.close();
      database = null;

      final converged = await open();
      expect(converged.recoveryOutcome, TvosDatabaseRecoveryOutcome.adoptedExistingDatabase);
      expect(await _criticalRows(converged.database), expected);
      expect(prefs.getBool(TvosDatabaseRecoveryStore.recoveryRequiredKey), isNull);
    });

    test('existing database without marker is adopted', () async {
      final raw = AppDatabase.forTesting(NativeDatabase(databaseFile));
      await raw.select(raw.connections).get();
      await raw.close();

      final result = await open();
      expect(result.recoveryOutcome, TvosDatabaseRecoveryOutcome.adoptedExistingDatabase);
      expect(prefs.getString(TvosDatabaseRecoveryStore.manifestKey), contains('committed'));
    });

    test('existing readable database is adopted when its recovery image cannot be serialized', () async {
      final store = TvosDatabaseRecoveryStore(prefs, isTvos: true);

      final outcome = await store.reconcile(
        databaseExisted: true,
        readIdentity: () async => {
          'connections': [
            {'unsupported': Object()},
          ],
          'profiles': <Object?>[],
          'profileConnections': <Object?>[],
        },
        readPending: () async => const {'offlineWatchProgress': <Object?>[]},
        restore: (_) async => fail('an existing database must not be restored'),
        hasPriorInstallEvidence: () async => false,
      );

      expect(outcome, TvosDatabaseRecoveryOutcome.adoptedExistingDatabase);
      var mutationRan = false;
      await store.runDurableMutation<void>(
        group: TvosDatabaseRecoveryGroup.identity,
        mutation: () async => mutationRan = true,
        readIdentity: () async => throw StateError('recovery was not disabled'),
        readPending: () async => throw StateError('recovery was not disabled'),
      );
      expect(mutationRan, isTrue);
    });

    for (final failingGroup in ['identity', 'pending']) {
      test('existing database $failingGroup row reader failure propagates', () async {
        final store = TvosDatabaseRecoveryStore(prefs, isTvos: true);
        final readError = StateError('$failingGroup database read failed');

        await expectLater(
          store.reconcile(
            databaseExisted: true,
            readIdentity: () async {
              if (failingGroup == 'identity') throw readError;
              return const {'connections': <Object?>[], 'profiles': <Object?>[], 'profileConnections': <Object?>[]};
            },
            readPending: () async {
              if (failingGroup == 'pending') throw readError;
              return const {'offlineWatchProgress': <Object?>[]};
            },
            restore: (_) async => fail('an existing database must not be restored'),
            hasPriorInstallEvidence: () async => false,
          ),
          throwsA(same(readError)),
        );
        expect(prefs.keys.where((key) => key.startsWith(TvosDatabaseRecoveryStore.keyPrefix)), isEmpty);
      });
    }

    test('existing database remains authoritative when recovery preferences cannot be written', () async {
      final raw = AppDatabase.forTesting(NativeDatabase(databaseFile));
      await raw.select(raw.connections).get();
      await raw.close();
      final store = TvosDatabaseRecoveryStore(
        prefs,
        isTvos: true,
        debugBeforePreferenceWrite: (_) async => throw StateError('write failed'),
      );

      final result = await open(store: store);

      expect(result.recoveryOutcome, TvosDatabaseRecoveryOutcome.adoptedExistingDatabase);
      await ProfileRegistry(result.database).upsert(_profile('database-remains-authoritative'));
      expect(await ProfileRegistry(result.database).get('database-remains-authoritative'), isNotNull);
    });

    test('existing database remains authoritative when recovery image exceeds its budget', () async {
      final raw = AppDatabase.forTesting(NativeDatabase(databaseFile));
      await raw.select(raw.connections).get();
      await raw.close();
      final store = TvosDatabaseRecoveryStore(prefs, isTvos: true, preferenceImageByteCeiling: 1);

      final result = await open(store: store);

      expect(result.recoveryOutcome, TvosDatabaseRecoveryOutcome.adoptedExistingDatabase);
      await ProfileRegistry(result.database).upsert(_profile('database-survives-recovery-budget'));
      expect(await ProfileRegistry(result.database).get('database-survives-recovery-budget'), isNotNull);
    });

    test('startup invalidation failure blocks identity mutation until durable retry', () async {
      final first = await open();
      await ProfileRegistry(first.database).upsert(_profile('stale-image'));
      final staleManifest = prefs.getString(TvosDatabaseRecoveryStore.manifestKey)!;
      await first.database.close();
      database = null;

      var failManifestWrites = true;
      var failedInvalidations = 0;
      final store = TvosDatabaseRecoveryStore(
        prefs,
        isTvos: true,
        debugBeforePreferenceWrite: (key) async {
          if (failManifestWrites && key == TvosDatabaseRecoveryStore.manifestKey) {
            failedInvalidations++;
            throw StateError('manifest invalidation failed');
          }
        },
      );
      final existing = await open(store: store);
      expect(existing.recoveryOutcome, TvosDatabaseRecoveryOutcome.adoptedExistingDatabase);
      expect(prefs.getString(TvosDatabaseRecoveryStore.manifestKey), staleManifest);

      await expectLater(
        ProfileRegistry(existing.database).upsert(_profile('blocked-by-stale-image')),
        throwsA(isA<TvosDatabaseDurabilityException>()),
      );
      expect(failedInvalidations, 2);
      expect(await ProfileRegistry(existing.database).get('blocked-by-stale-image'), isNull);
      expect(prefs.getString(TvosDatabaseRecoveryStore.manifestKey), staleManifest);
      await existing.database.close();
      database = null;

      final probeFile = File('${tempDir.path}/stale-image-probe.db');
      final staleRestore = await AppDatabase.open(isTvos: true, databaseFile: probeFile, preferences: prefs);
      expect(staleRestore.recoveryOutcome, TvosDatabaseRecoveryOutcome.restored);
      expect(await ProfileRegistry(staleRestore.database).get('stale-image'), isNotNull);
      expect(await ProfileRegistry(staleRestore.database).get('blocked-by-stale-image'), isNull);
      await staleRestore.database.close();
      await _deleteDatabase(probeFile);

      failManifestWrites = false;
      final retried = await open(store: store);
      expect(retried.recoveryOutcome, TvosDatabaseRecoveryOutcome.adoptedExistingDatabase);
      await ProfileRegistry(retried.database).upsert(_profile('committed-after-retry'));
      expect(await ProfileRegistry(retried.database).get('committed-after-retry'), isNotNull);
      expect(prefs.getString(TvosDatabaseRecoveryStore.manifestKey), isNot(staleManifest));
      await retried.database.close();
      database = null;
      await _deleteDatabase(databaseFile);

      final recovered = await open();
      expect(recovered.recoveryOutcome, TvosDatabaseRecoveryOutcome.restored);
      expect(await ProfileRegistry(recovered.database).get('stale-image'), isNotNull);
      expect(await ProfileRegistry(recovered.database).get('committed-after-retry'), isNotNull);
      expect(await ProfileRegistry(recovered.database).get('blocked-by-stale-image'), isNull);
    });

    test('existing database repairs an interrupted manifest authoritatively', () async {
      final first = await open();
      await ProfileRegistry(first.database).upsert(_profile('authoritative'));
      final manifest = jsonDecode(prefs.getString(TvosDatabaseRecoveryStore.manifestKey)!) as Map<String, dynamic>;
      manifest['state'] = 'invalidated';
      await prefs.setString(TvosDatabaseRecoveryStore.manifestKey, jsonEncode(manifest));
      await first.database.close();
      database = null;

      final repaired = await open();
      expect(repaired.recoveryOutcome, TvosDatabaseRecoveryOutcome.adoptedExistingDatabase);
      expect(await ProfileRegistry(repaired.database).get('authoritative'), isNotNull);
      expect(prefs.getString(TvosDatabaseRecoveryStore.manifestKey), contains('committed'));
      await closeAndDelete();

      final restored = await open();
      expect(restored.recoveryOutcome, TvosDatabaseRecoveryOutcome.restored);
      expect(await ProfileRegistry(restored.database).get('authoritative'), isNotNull);
    });
  });

  group('invalid missing-database recovery images', () {
    Future<void> expectRejected(Future<void> Function() corrupt) async {
      final first = await open();
      await ProfileRegistry(first.database).upsert(_profile('must-not-partially-restore'));
      await first.database.close();
      database = null;
      await corrupt();
      await _deleteDatabase(databaseFile);

      final result = await open();
      expect(result.recoveryOutcome, TvosDatabaseRecoveryOutcome.recoveryRequired);
      expect((await _criticalRows(result.database)).expand((rows) => rows), isEmpty);
    }

    test('absent payload', () => expectRejected(() => prefs.remove(TvosDatabaseRecoveryStore.identityKey)));

    test('corrupt manifest', () => expectRejected(() => prefs.setString(TvosDatabaseRecoveryStore.manifestKey, '{')));

    test('unsupported version', () async {
      await expectRejected(() async {
        final manifest = jsonDecode(prefs.getString(TvosDatabaseRecoveryStore.manifestKey)!) as Map<String, dynamic>;
        manifest['version'] = 99;
        await prefs.setString(TvosDatabaseRecoveryStore.manifestKey, jsonEncode(manifest));
      });
    });

    test('digest mismatch', () async {
      await expectRejected(() async {
        await prefs.setString(
          TvosDatabaseRecoveryStore.identityKey,
          '${prefs.getString(TvosDatabaseRecoveryStore.identityKey)} ',
        );
      });
    });

    test('structurally invalid payload with matching digest', () async {
      await expectRejected(() async {
        final payload = jsonDecode(prefs.getString(TvosDatabaseRecoveryStore.identityKey)!) as Map<String, dynamic>;
        (payload['rows'] as Map<String, dynamic>).remove('profiles');
        final encoded = jsonEncode(payload);
        final manifest = jsonDecode(prefs.getString(TvosDatabaseRecoveryStore.manifestKey)!) as Map<String, dynamic>;
        manifest['identityDigest'] = sha256.convert(utf8.encode(encoded)).toString();
        await prefs.setString(TvosDatabaseRecoveryStore.identityKey, encoded);
        await prefs.setString(TvosDatabaseRecoveryStore.manifestKey, jsonEncode(manifest));
      });
    });

    test('over-budget complete preference image', () async {
      final first = await open();
      await first.database.close();
      database = null;
      await _deleteDatabase(databaseFile);
      final tinyStore = TvosDatabaseRecoveryStore(prefs, isTvos: true, preferenceImageByteCeiling: 1);
      final result = await open(store: tinyStore);
      expect(result.recoveryOutcome, TvosDatabaseRecoveryOutcome.recoveryRequired);
      expect((await _criticalRows(result.database)).expand((rows) => rows), isEmpty);
    });
  });

  test('explicit sign-in acknowledgement replaces invalid evidence before new mutations', () async {
    final first = await open();
    await first.database.close();
    database = null;
    await prefs.setString(
      TvosDatabaseRecoveryStore.identityKey,
      '${prefs.getString(TvosDatabaseRecoveryStore.identityKey)}-digest-mismatch',
    );
    await _deleteDatabase(databaseFile);

    var result = await open();
    expect(result.recoveryOutcome, TvosDatabaseRecoveryOutcome.recoveryRequired);
    await expectLater(
      ConnectionRegistry(result.database).upsert(_connection('blocked-before-acknowledgement')),
      throwsA(isA<TvosDatabaseDurabilityException>()),
    );
    expect(await result.database.select(result.database.connections).get(), isEmpty);

    await result.database.acknowledgeTvosDatabaseRecoveryRequired();
    await ConnectionRegistry(result.database).upsert(_connection('new-sign-in'));
    final expected = await _criticalRows(result.database);
    await closeAndDelete();

    result = await open();
    expect(result.recoveryOutcome, TvosDatabaseRecoveryOutcome.restored);
    expect(await _criticalRows(result.database), expected);
  });

  group('two-phase crash protocol', () {
    for (final point in TvosDatabaseRecoveryCrashPoint.values) {
      test('$point converges from authoritative database', () async {
        var armed = false;
        final crashStore = TvosDatabaseRecoveryStore(
          prefs,
          isTvos: true,
          debugCrash: (candidate) async {
            if (armed && candidate == point) throw StateError('simulated process stop');
          },
        );
        final first = await open(store: crashStore);
        armed = true;
        await expectLater(ProfileRegistry(first.database).upsert(_profile('crash-row')), throwsA(anything));
        armed = false;
        final expected = await _criticalRows(first.database);
        await first.database.close();
        database = null;

        final repaired = await open();
        expect(repaired.recoveryOutcome, TvosDatabaseRecoveryOutcome.adoptedExistingDatabase);
        expect(await _criticalRows(repaired.database), expected);
        await closeAndDelete();

        final restored = await open();
        expect(restored.recoveryOutcome, TvosDatabaseRecoveryOutcome.restored);
        expect(await _criticalRows(restored.database), expected);
      });
    }

    for (final point in const [
      TvosDatabaseRecoveryCrashPoint.afterInvalidation,
      TvosDatabaseRecoveryCrashPoint.afterDatabaseMutation,
      TvosDatabaseRecoveryCrashPoint.afterPayloadWrite,
    ]) {
      test('$point never restores stale state when database is missing', () async {
        var armed = false;
        final crashStore = TvosDatabaseRecoveryStore(
          prefs,
          isTvos: true,
          debugCrash: (candidate) async {
            if (armed && candidate == point) throw StateError('simulated process stop');
          },
        );
        final first = await open(store: crashStore);
        armed = true;
        await expectLater(ProfileRegistry(first.database).upsert(_profile('uncommitted')), throwsA(anything));
        await closeAndDelete();

        final missing = await open();
        expect(missing.recoveryOutcome, TvosDatabaseRecoveryOutcome.recoveryRequired);
        expect((await _criticalRows(missing.database)).expand((rows) => rows), isEmpty);
      });
    }
  });

  test('preference-write failure is typed, payload-free, and later converges', () async {
    var armed = false;
    final store = TvosDatabaseRecoveryStore(
      prefs,
      isTvos: true,
      debugBeforePreferenceWrite: (key) async {
        if (armed && key == TvosDatabaseRecoveryStore.identityKey) throw StateError('write failed');
      },
    );
    final first = await open(store: store);
    armed = true;
    Object? failure;
    try {
      await ConnectionRegistry(first.database).upsert(_connection('write-failure-canary'));
    } catch (error) {
      failure = error;
    }
    expect(failure, isA<TvosDatabaseDurabilityException>());
    expect(failure.toString(), isNot(contains('protected-connection-canary')));
    expect(await first.database.select(first.database.connections).get(), hasLength(1));
    armed = false;
    await first.database.close();
    database = null;

    final repaired = await open();
    expect(repaired.recoveryOutcome, TvosDatabaseRecoveryOutcome.adoptedExistingDatabase);
    await closeAndDelete();
    final restored = await open();
    expect(restored.recoveryOutcome, TvosDatabaseRecoveryOutcome.restored);
    expect(await restored.database.select(restored.database.connections).get(), hasLength(1));
  });

  test('oversized identity degrades recovery without rejecting authoritative mutations', () async {
    final store = TvosDatabaseRecoveryStore(prefs, isTvos: true, preferenceImageByteCeiling: 1200);
    final first = await open(store: store);
    final canary = List.filled(3000, 'PROTECTED-SIZE-CANARY').join();
    final huge = JellyfinConnection(
      id: 'huge',
      baseUrl: 'https://media.invalid',
      serverName: canary,
      serverMachineId: 'huge',
      userId: 'user',
      userName: 'user',
      accessToken: canary,
      deviceId: 'device',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1),
    );

    await ConnectionRegistry(first.database).upsert(huge);
    await ProfileRegistry(first.database).upsert(_profile('after-degradation'));
    expect(await first.database.select(first.database.connections).get(), hasLength(1));
    expect(await first.database.select(first.database.profiles).get(), hasLength(1));

    await closeAndDelete();
    final missing = await open(store: TvosDatabaseRecoveryStore(prefs, isTvos: true, preferenceImageByteCeiling: 1200));
    expect(missing.recoveryOutcome, TvosDatabaseRecoveryOutcome.recoveryRequired);
    expect(await missing.database.select(missing.database.connections).get(), isEmpty);
    expect(await missing.database.select(missing.database.profiles).get(), isEmpty);
  });

  test('oversized pending actions retain identity in a bounded recovery image', () async {
    const ceiling = 5000;
    final store = TvosDatabaseRecoveryStore(prefs, isTvos: true, preferenceImageByteCeiling: ceiling);
    final first = await open(store: store);
    await ConnectionRegistry(first.database).upsert(_connection('retained'));

    for (var index = 0; index < 20; index++) {
      await first.database.insertWatchAction(
        profileId: 'profile',
        serverId: ServerId('server'),
        ratingKey: '$index-${List.filled(500, 'pending').join()}',
        actionType: OfflineActionType.watched.id,
      );
    }
    expect(await first.database.getPendingWatchActions(), hasLength(20));

    await closeAndDelete();
    final restored = await open(
      store: TvosDatabaseRecoveryStore(prefs, isTvos: true, preferenceImageByteCeiling: ceiling),
    );
    expect(restored.recoveryOutcome, TvosDatabaseRecoveryOutcome.restored);
    expect(await restored.database.select(restored.database.connections).get(), hasLength(1));
    expect(await restored.database.getPendingWatchActions(), isEmpty);
  });

  test('pending mutation wrappers preserve updates, deletes, profile teardown, and clears', () async {
    var result = await open();
    await result.database.upsertProgressAction(
      profileId: 'p1',
      serverId: ServerId('s1'),
      ratingKey: 'a',
      viewOffset: 10,
      duration: 100,
      shouldMarkWatched: false,
    );
    await result.database.adoptLegacyOfflineWatchActionsForProfile('p1');
    await result.database.insertWatchAction(
      profileId: 'p1',
      serverId: ServerId('s1'),
      ratingKey: 'b',
      actionType: OfflineActionType.watched.id,
    );
    final rows = await result.database.getPendingWatchActions();
    await result.database.updateSyncAttemptIfUnchanged(rows.first.id, rows.first.updatedAt, 'retry');
    await result.database.deleteWatchActionIfUnchanged(rows.last.id, rows.last.updatedAt);
    await result.database.insertWatchAction(
      profileId: 'p2',
      serverId: ServerId('s1'),
      ratingKey: 'c',
      actionType: OfflineActionType.unwatched.id,
    );
    await result.database.deleteWatchActionsForProfile('p1');
    var expected = await _criticalRows(result.database);
    await closeAndDelete();
    result = await open();
    expect(await _criticalRows(result.database), expected);

    await result.database.clearAllWatchActions();
    expected = await _criticalRows(result.database);
    await closeAndDelete();
    result = await open();
    expect(await _criticalRows(result.database), expected);
    expect(await result.database.getPendingWatchActions(), isEmpty);
  });

  test('identity mutation wrappers preserve defaults, tokens, cascades, teardown, and clears', () async {
    var result = await open();
    var connections = ConnectionRegistry(result.database);
    var profiles = ProfileRegistry(result.database);
    var joins = ProfileConnectionRegistry(result.database);

    await connections.upsert(_connection('c1'));
    await connections.upsert(_connection('c2'));
    await connections.setDefault('c2');
    await connections.recordAuthSuccess('c2', DateTime.fromMillisecondsSinceEpoch(9000));
    await profiles.upsert(_profile('p1'));
    await profiles.upsert(_profile('p2'));
    await profiles.markUsed('p1', DateTime.fromMillisecondsSinceEpoch(9100));
    await profiles.upsert(
      Profile.plexHome(
        id: 'legacy-home',
        displayName: 'Legacy',
        parentConnectionId: 'c1',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1),
      ),
    );
    await profiles.dropAllPlexHomeRows();
    await joins.upsert(
      const ProfileConnection(profileId: 'p1', connectionId: 'c1', userToken: 'token-1', userIdentifier: 'u1'),
    );
    await joins.upsert(
      const ProfileConnection(profileId: 'p1', connectionId: 'c2', userToken: 'token-2', userIdentifier: 'u2'),
    );
    await joins.recordToken('p1', 'c1', 'token-refreshed');
    final protectedToken = await CredentialVault.protect('token-clear-canary');
    final protectedEnvelope = jsonDecode(protectedToken.substring('enc:v1:'.length)) as Map<String, dynamic>;
    final ciphertext = protectedEnvelope['c'] as String;
    protectedEnvelope['c'] = '${ciphertext.startsWith('A') ? 'B' : 'A'}${ciphertext.substring(1)}';
    final corruptedToken = 'enc:v1:${jsonEncode(protectedEnvelope)}';
    await (result.database.update(
      result.database.profileConnections,
    )..where((t) => t.connectionId.equals('c1'))).write(ProfileConnectionsCompanion(userToken: Value(corruptedToken)));
    await joins.get('p1', 'c1');
    final clearedTokenRow = await (result.database.select(
      result.database.profileConnections,
    )..where((t) => t.connectionId.equals('c1'))).getSingle();
    expect(clearedTokenRow.userToken, isEmpty);
    await joins.markUsed('p1', 'c1');
    await joins.setDefault('p1', 'c2');
    await joins.remove('p1', 'c2');
    await joins.promoteMissingDefaults();
    await joins.removeAllForConnection('c2');
    await connections.remove('c2');
    await profiles.remove('p2');

    var expected = await _criticalRows(result.database);
    await closeAndDelete();
    result = await open();
    expect(await _criticalRows(result.database), expected);

    connections = ConnectionRegistry(result.database);
    profiles = ProfileRegistry(result.database);
    joins = ProfileConnectionRegistry(result.database);
    await joins.clear();
    await profiles.clear();
    await connections.clear();
    expected = await _criticalRows(result.database);
    await closeAndDelete();
    result = await open();
    expect(await _criticalRows(result.database), expected);
    expect(expected.take(3).expand((rows) => rows), isEmpty);
  });
}
