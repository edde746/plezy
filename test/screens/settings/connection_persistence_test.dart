import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/screens/settings/connection_persistence.dart';
import 'package:plezy/services/credential_vault.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/prefs.dart';

final class _AfterStatementFailure implements Exception {
  const _AfterStatementFailure(this.stage);

  final String stage;

  @override
  String toString() => 'after $stage statement';
}

class _FailingProfileRegistry extends ProfileRegistry {
  _FailingProfileRegistry(super.db);

  @override
  Future<void> upsert(Profile profile) async {
    await super.upsert(profile);
    throw const _AfterStatementFailure('profile');
  }
}

class _FailingConnectionRegistry extends ConnectionRegistry {
  _FailingConnectionRegistry(super.db);

  @override
  Future<void> upsert(Connection connection) async {
    await super.upsert(connection);
    throw const _AfterStatementFailure('connection');
  }
}

class _FailingProfileConnectionRegistry extends ProfileConnectionRegistry {
  _FailingProfileConnectionRegistry(super.db);

  @override
  Future<void> upsert(ProfileConnection connection, {bool makeDefault = false}) async {
    await super.upsert(connection, makeDefault: makeDefault);
    throw const _AfterStatementFailure('join');
  }
}

class _GatedProfileConnectionRegistry extends ProfileConnectionRegistry {
  _GatedProfileConnectionRegistry(super.db, {required this.fail});

  final bool fail;
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> upsert(ProfileConnection connection, {bool makeDefault = false}) async {
    await super.upsert(connection, makeDefault: makeDefault);
    started.complete();
    await release.future;
    if (fail) throw const _AfterStatementFailure('gated join');
  }
}

class _RejectingActiveProfileProvider extends ActiveProfileProvider {
  _RejectingActiveProfileProvider({
    required super.registry,
    required super.plexHome,
    required super.connections,
    required super.storage,
  });

  @override
  Future<bool> activate(Profile profile, {String? pin}) async => false;
}

class _ThrowingActiveProfileProvider extends ActiveProfileProvider {
  _ThrowingActiveProfileProvider({
    required super.registry,
    required super.plexHome,
    required super.connections,
    required super.storage,
  });

  @override
  Future<bool> activate(Profile profile, {String? pin}) async {
    await super.activate(profile, pin: pin);
    throw const _AfterStatementFailure('active marker');
  }
}

class _NoTimerPlexHomeService extends PlexHomeService {
  _NoTimerPlexHomeService({required super.connections, required super.profileConnections, required super.storage});

  @override
  Future<void> start() async {}

  @override
  Future<void> reloadFromStorage() async {}
}

JellyfinConnection _connection({String token = 'opaque-token-current', String userName = 'Fixture User'}) {
  return JellyfinConnection(
    id: 'fixture-machine/fixture-user',
    baseUrl: 'https://media.invalid',
    serverName: 'Fixture Server',
    serverMachineId: 'fixture-machine',
    userId: 'fixture-user',
    userName: userName,
    accessToken: token,
    deviceId: 'fixture-device',
    createdAt: DateTime.utc(2026, 1, 2),
  );
}

Profile _profile(String id, {String name = 'Fixture Profile'}) {
  return Profile.local(id: id, displayName: name, createdAt: DateTime.utc(2026, 1, 1));
}

Future<Object?> _runProvisioning(WidgetTester tester, Future<bool> Function() command) {
  return tester.runAsync<Object?>(() async {
    try {
      return await command();
    } catch (error) {
      return error;
    }
  });
}

ProfileConnection _join(Profile profile, JellyfinConnection connection) {
  return ProfileConnection(
    profileId: profile.id,
    connectionId: connection.id,
    userToken: connection.accessToken,
    userIdentifier: connection.userId,
    tokenAcquiredAt: DateTime.utc(2026, 1, 2),
  );
}

void main() {
  late AppDatabase db;
  late StorageService storage;
  late ProfileRegistry profiles;
  late ConnectionRegistry connections;
  late ProfileConnectionRegistry profileConnections;
  late PlexHomeService plexHome;
  late ActiveProfileProvider activeProfiles;
  BuildContext? hostContext;

  Future<void> mountHost(
    WidgetTester tester, {
    ProfileRegistry? profileRegistry,
    ConnectionRegistry? connectionRegistry,
    ProfileConnectionRegistry? joinRegistry,
    bool initializeActive = false,
    ActiveProfileProvider Function(
      ProfileRegistry profiles,
      PlexHomeService plexHome,
      ConnectionRegistry connections,
      StorageService storage,
    )?
    activeFactory,
  }) async {
    await tester.runAsync(() => CredentialVault.protect('opaque-vault-warmup'));
    profiles = profileRegistry ?? ProfileRegistry(db);
    connections = connectionRegistry ?? ConnectionRegistry(db);
    profileConnections = joinRegistry ?? ProfileConnectionRegistry(db);
    plexHome = _NoTimerPlexHomeService(
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
    );
    activeProfiles =
        activeFactory?.call(profiles, plexHome, connections, storage) ??
        ActiveProfileProvider(registry: profiles, plexHome: plexHome, connections: connections, storage: storage);
    if (initializeActive) await tester.runAsync(activeProfiles.initialize);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: db),
          Provider<StorageService>.value(value: storage),
          Provider<ProfileRegistry>.value(value: profiles),
          Provider<ConnectionRegistry>.value(value: connections),
          Provider<ProfileConnectionRegistry>.value(value: profileConnections),
          ChangeNotifierProvider<ActiveProfileProvider>.value(value: activeProfiles),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              hostContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Future<void> expectEmptyAttempt(Profile profile, JellyfinConnection connection) async {
    expect(await ProfileRegistry(db).get(profile.id), isNull);
    expect(await ConnectionRegistry(db).get(connection.id), isNull);
    expect(await ProfileConnectionRegistry(db).get(profile.id, connection.id), isNull);
    expect(storage.getActiveProfileId(), isNull);
    expect(storage.getProfileLastUsed(profile.id), isNull);
  }

  setUp(() async {
    resetSharedPreferencesForTest();
    CredentialVault.resetKeyForTesting();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    storage = await StorageService.getInstance();
    hostContext = null;
  });

  tearDown(() async {
    if (hostContext != null) {
      await activeProfiles.resetForTesting();
      activeProfiles.dispose();
      await plexHome.dispose();
    }
    await db.close();
  });

  testWidgets('profile statement failure rolls back the complete first-run bundle', (tester) async {
    final profile = _profile('fixture-new-profile');
    final connection = _connection();
    var runtimeAdds = 0;
    await mountHost(tester, profileRegistry: _FailingProfileRegistry(db));

    final error = await _runProvisioning(
      tester,
      () => persistAndBindConnection(
        context: hostContext!,
        connection: connection,
        bindToProfile: _join(profile, connection),
        firstRunProfile: profile,
        addToManager: () async {
          runtimeAdds++;
          return true;
        },
      ),
    );
    expect(error, isA<_AfterStatementFailure>());

    await expectEmptyAttempt(profile, connection);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(runtimeAdds, 0);
  });

  testWidgets('connection statement failure rolls back the complete first-run bundle', (tester) async {
    final profile = _profile('fixture-new-profile');
    final connection = _connection();
    await mountHost(tester, connectionRegistry: _FailingConnectionRegistry(db));

    final error = await _runProvisioning(
      tester,
      () => persistAndBindConnection(
        context: hostContext!,
        connection: connection,
        bindToProfile: _join(profile, connection),
        firstRunProfile: profile,
        addToManager: null,
      ),
    );
    expect(error, isA<_AfterStatementFailure>());

    await expectEmptyAttempt(profile, connection);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('join statement failure rolls back the complete first-run bundle', (tester) async {
    final profile = _profile('fixture-new-profile');
    final connection = _connection();
    await mountHost(tester, joinRegistry: _FailingProfileConnectionRegistry(db));

    final error = await _runProvisioning(
      tester,
      () => persistAndBindConnection(
        context: hostContext!,
        connection: connection,
        bindToProfile: _join(profile, connection),
        firstRunProfile: profile,
        addToManager: null,
      ),
    );
    expect(error, isA<_AfterStatementFailure>());

    await expectEmptyAttempt(profile, connection);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('existing connection update is restored when join statement fails', (tester) async {
    final target = _profile('fixture-existing-profile');
    final priorConnection = _connection(token: 'opaque-token-prior', userName: 'Prior User');
    final updatedConnection = _connection(token: 'opaque-token-updated', userName: 'Updated User');
    await ProfileRegistry(db).upsert(target);
    await tester.runAsync(() => ConnectionRegistry(db).upsert(priorConnection));
    await storage.setActiveProfileId(target.id);
    await mountHost(tester, joinRegistry: _FailingProfileConnectionRegistry(db));

    final error = await _runProvisioning(
      tester,
      () => persistAndBindConnection(
        context: hostContext!,
        connection: updatedConnection,
        bindToProfile: _join(target, updatedConnection),
        addToManager: null,
      ),
    );
    expect(error, isA<_AfterStatementFailure>());

    final restored = await tester.runAsync(() => ConnectionRegistry(db).get(priorConnection.id)) as JellyfinConnection;
    expect(restored.accessToken, priorConnection.accessToken);
    expect(restored.userName, priorConnection.userName);
    expect(await ProfileRegistry(db).get(target.id), isNotNull);
    expect(await ProfileConnectionRegistry(db).get(target.id, priorConnection.id), isNull);
    expect(storage.getActiveProfileId(), target.id);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('activation rejection compensates relational and preference state', (tester) async {
    final priorProfile = _profile('fixture-prior-profile', name: 'Prior Profile');
    final newProfile = _profile('fixture-new-profile');
    final connection = _connection();
    await ProfileRegistry(db).upsert(priorProfile);
    await storage.setActiveProfileId(priorProfile.id);
    await mountHost(
      tester,
      initializeActive: true,
      activeFactory: (profiles, plexHome, connections, storage) => _RejectingActiveProfileProvider(
        registry: profiles,
        plexHome: plexHome,
        connections: connections,
        storage: storage,
      ),
    );

    final error = await _runProvisioning(
      tester,
      () => persistAndBindConnection(
        context: hostContext!,
        connection: connection,
        bindToProfile: _join(newProfile, connection),
        firstRunProfile: newProfile,
        addToManager: null,
      ),
    );
    expect(error, isA<StateError>());

    expect(await ProfileRegistry(db).get(newProfile.id), isNull);
    expect(await ConnectionRegistry(db).get(connection.id), isNull);
    expect(await ProfileConnectionRegistry(db).get(newProfile.id, connection.id), isNull);
    expect(storage.getProfileLastUsed(newProfile.id), isNull);
    expect(storage.getActiveProfileId(), priorProfile.id);
    expect(activeProfiles.activeId, priorProfile.id);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('activation throw restores a prior same-id connection and original active state', (tester) async {
    final priorProfile = _profile('fixture-prior-profile', name: 'Prior Profile');
    final newProfile = _profile('fixture-new-profile');
    final priorConnection = _connection(token: 'opaque-token-prior', userName: 'Prior User');
    final updatedConnection = _connection(token: 'opaque-token-updated', userName: 'Updated User');
    await ProfileRegistry(db).upsert(priorProfile);
    await tester.runAsync(() => ConnectionRegistry(db).upsert(priorConnection));
    await storage.setActiveProfileId(priorProfile.id);
    await mountHost(
      tester,
      initializeActive: true,
      activeFactory: (profiles, plexHome, connections, storage) => _ThrowingActiveProfileProvider(
        registry: profiles,
        plexHome: plexHome,
        connections: connections,
        storage: storage,
      ),
    );

    final error = await _runProvisioning(
      tester,
      () => persistAndBindConnection(
        context: hostContext!,
        connection: updatedConnection,
        bindToProfile: _join(newProfile, updatedConnection),
        firstRunProfile: newProfile,
        addToManager: null,
      ),
    );
    expect(error, isA<_AfterStatementFailure>());

    final restored = await tester.runAsync(() => ConnectionRegistry(db).get(priorConnection.id)) as JellyfinConnection;
    expect(restored.accessToken, priorConnection.accessToken);
    expect(restored.userName, priorConnection.userName);
    expect(await ProfileRegistry(db).get(newProfile.id), isNull);
    expect(await ProfileConnectionRegistry(db).get(newProfile.id, priorConnection.id), isNull);
    expect(storage.getProfileLastUsed(newProfile.id), isNull);
    expect(storage.getActiveProfileId(), priorProfile.id);
    expect(activeProfiles.activeId, priorProfile.id);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('durable command completes after route unmount', (tester) async {
    final profile = _profile('fixture-new-profile');
    final connection = _connection(token: '');
    final gated = _GatedProfileConnectionRegistry(db, fail: false);
    var runtimeAdds = 0;
    await mountHost(tester, joinRegistry: gated);

    final pending = persistAndBindConnection(
      context: hostContext!,
      connection: connection,
      bindToProfile: _join(profile, connection),
      firstRunProfile: profile,
      addToManager: () async {
        runtimeAdds++;
        return true;
      },
    );
    await gated.started.future;
    await tester.pumpWidget(const SizedBox.shrink());
    gated.release.complete();

    expect(await pending, isFalse);
    expect(await ProfileRegistry(db).get(profile.id), isNotNull);
    expect(await ConnectionRegistry(db).get(connection.id), isNotNull);
    expect(await ProfileConnectionRegistry(db).get(profile.id, connection.id), isNotNull);
    expect(storage.getActiveProfileId(), profile.id);
    expect(runtimeAdds, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('failed durable command rolls back after route unmount', (tester) async {
    final profile = _profile('fixture-new-profile');
    final connection = _connection(token: '');
    final gated = _GatedProfileConnectionRegistry(db, fail: true);
    await mountHost(tester, joinRegistry: gated);

    final pending = persistAndBindConnection(
      context: hostContext!,
      connection: connection,
      bindToProfile: _join(profile, connection),
      firstRunProfile: profile,
      addToManager: null,
    ).then<Object?>((value) => value, onError: (Object error, StackTrace _) => error);
    await gated.started.future;
    await tester.pumpWidget(const SizedBox.shrink());
    gated.release.complete();

    expect(await pending, isA<_AfterStatementFailure>());
    await expectEmptyAttempt(profile, connection);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
