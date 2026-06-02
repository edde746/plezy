import 'dart:async';
import 'package:plezy/media/ids.dart';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_home_user.dart';
import 'package:plezy/profiles/active_profile_binder.dart';
import 'package:plezy/profiles/active_profile_provider.dart';
import 'package:plezy/profiles/plex_home_service.dart';
import 'package:plezy/profiles/profile.dart';
import 'package:plezy/profiles/profile_connection.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/profiles/profile_registry.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/media_server_timeouts.dart';

import '../test_helpers/prefs.dart';

void main() {
  late AppDatabase db;
  late ConnectionRegistry connections;
  late ProfileConnectionRegistry profileConnections;
  late ProfileRegistry profiles;
  late PlexHomeService plexHome;
  late ActiveProfileProvider activeProfile;
  late MultiServerManager manager;
  late MultiServerProvider multiServerProvider;
  late ActiveProfileBinder binder;
  late StorageService storage;
  late bool shouldDeferInitialBind;
  late List<PlexHomeUser> fetchedHomeUsers;

  setUp(() async {
    resetSharedPreferencesForTest();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    connections = ConnectionRegistry(db);
    profileConnections = ProfileConnectionRegistry(db);
    profiles = ProfileRegistry(db);
    storage = await StorageService.getInstance();
    fetchedHomeUsers = const [];
    plexHome = PlexHomeService(
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
      plexHomeUserFetcher: (_) async => fetchedHomeUsers,
    );
    activeProfile = ActiveProfileProvider(
      registry: profiles,
      plexHome: plexHome,
      connections: connections,
      storage: storage,
    );
    manager = MultiServerManager();
    multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
    shouldDeferInitialBind = false;
    binder = ActiveProfileBinder(
      activeProfile: activeProfile,
      connections: connections,
      profileConnections: profileConnections,
      serverManager: manager,
      multiServerProvider: multiServerProvider,
      pinPrompt: (_, {String? errorMessage}) async => null,
      shouldDeferInitialBind: (_) async => shouldDeferInitialBind,
    );
  });

  tearDown(() async {
    binder.dispose();
    multiServerProvider.dispose();
    await activeProfile.resetForTesting();
    activeProfile.dispose();
    await plexHome.dispose();
    await db.close();
  });

  Future<Profile> createActiveLocalProfile(String id) async {
    final profile = Profile.local(id: id, displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
    await profiles.upsert(profile);
    await storage.setActiveProfileId(profile.id);
    await activeProfile.initialize();
    return profile;
  }

  test('local profile with no connections binds successfully with empty visibility', () async {
    final profile = Profile.local(id: 'local-owner', displayName: 'Owner', createdAt: DateTime(2026, 1, 1));
    await profiles.upsert(profile);
    await storage.setActiveProfileId(profile.id);
    await activeProfile.initialize();

    await binder.rebindActive();

    expect(activeProfile.lastBindingSucceeded, isTrue);
    expect(binder.debugLastBoundProfileId, profile.id);
    expect(multiServerProvider.serverIds, isEmpty);
  });

  test('started binder does not loop forever after empty local bind', () async {
    final profile = Profile.local(id: 'local-empty', displayName: 'Empty', createdAt: DateTime(2026, 1, 1));
    await profiles.upsert(profile);
    await storage.setActiveProfileId(profile.id);
    await activeProfile.initialize();

    var notifications = 0;
    activeProfile.addListener(() => notifications++);
    binder.start();

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(activeProfile.isBinding, isFalse);
    expect(activeProfile.lastBindingSucceeded, isTrue);
    expect(binder.debugLastBoundProfileId, profile.id);
    expect(notifications, lessThan(8));
  });

  test('initial bind can be deferred until profile selection', () async {
    final profile = await createActiveLocalProfile('local-deferred');
    shouldDeferInitialBind = true;

    await binder.rebindActive();

    expect(activeProfile.lastBindingSucceeded, isTrue);
    expect(activeProfile.isBinding, isFalse);
    expect(binder.debugLastBoundProfileId, isNull);
    expect(binder.consumeUserInitiatedActivation(profile.id), isFalse);
    expect(multiServerProvider.serverIds, isEmpty);
  });

  test('user initiated activation bypasses initial bind defer', () async {
    final profile = await createActiveLocalProfile('local-user-initiated');
    shouldDeferInitialBind = true;
    binder.markUserInitiatedActivation(profile.id);

    await binder.rebindActive();

    expect(activeProfile.lastBindingSucceeded, isTrue);
    expect(binder.debugLastBoundProfileId, profile.id);
    expect(binder.consumeUserInitiatedActivation(profile.id), isFalse);
  });

  test('tracks expected Plex server ids when bind cannot create a live client', () async {
    binder.dispose();
    multiServerProvider.dispose();

    final failingManager = _FailingPlexMultiServerManager();
    manager = failingManager;
    multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
    binder = ActiveProfileBinder(
      activeProfile: activeProfile,
      connections: connections,
      profileConnections: profileConnections,
      serverManager: manager,
      multiServerProvider: multiServerProvider,
      pinPrompt: (_, {String? errorMessage}) async => null,
      shouldDeferInitialBind: (_) async => false,
      plexAuth: PlexAuthService.forTesting(
        http: MediaServerHttpClient(
          client: MockClient(
            (_) async => http.Response(jsonEncode([_serverJson()]), 200, headers: {'content-type': 'application/json'}),
          ),
        ),
      ),
    );

    final profile = await createActiveLocalProfile('local-plex-offline');
    final account = PlexAccountConnection(
      id: 'plex.account',
      accountToken: 'account-token',
      clientIdentifier: 'client-id',
      accountLabel: 'Owner',
      servers: [_server(accessToken: 'account-server-token')],
      createdAt: DateTime(2026, 1, 1),
    );
    await connections.upsert(account);
    await profileConnections.upsert(
      ProfileConnection(
        profileId: profile.id,
        connectionId: account.id,
        userToken: 'home-user-token',
        userIdentifier: 'home-user-uuid',
        tokenAcquiredAt: DateTime(2026, 1, 1),
      ),
    );

    await binder.rebindActive();

    expect(activeProfile.lastBindingSucceeded, isFalse);
    expect(failingManager.refreshCalls, 1);
    expect(multiServerProvider.serverIds, isEmpty);
    expect(multiServerProvider.expectedServerIds, ['srv-1']);
  });

  test('binds Plex and Jellyfin join rows in parallel', () async {
    binder.dispose();
    multiServerProvider.dispose();

    final mixedManager = _BlockingMixedMultiServerManager();
    manager = mixedManager;
    multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
    binder = ActiveProfileBinder(
      activeProfile: activeProfile,
      connections: connections,
      profileConnections: profileConnections,
      serverManager: manager,
      multiServerProvider: multiServerProvider,
      pinPrompt: (_, {String? errorMessage}) async => null,
      shouldDeferInitialBind: (_) async => false,
      plexAuth: PlexAuthService.forTesting(
        http: MediaServerHttpClient(
          client: MockClient(
            (_) async => http.Response(jsonEncode([_serverJson()]), 200, headers: {'content-type': 'application/json'}),
          ),
        ),
      ),
    );

    final profile = await createActiveLocalProfile('local-mixed');
    final plexAccount = PlexAccountConnection(
      id: 'plex.account',
      accountToken: 'account-token',
      clientIdentifier: 'client-id',
      accountLabel: 'Owner',
      servers: [_server(accessToken: 'account-server-token')],
      createdAt: DateTime(2026, 1, 1),
    );
    final jellyfin = _jellyfinConnection();
    await connections.upsert(plexAccount);
    await connections.upsert(jellyfin);
    await profileConnections.upsert(
      ProfileConnection(
        profileId: profile.id,
        connectionId: plexAccount.id,
        userToken: 'home-user-token',
        userIdentifier: 'home-user-uuid',
        tokenAcquiredAt: DateTime(2026, 1, 1),
      ),
    );
    await profileConnections.upsert(
      ProfileConnection(
        profileId: profile.id,
        connectionId: jellyfin.id,
        userIdentifier: jellyfin.userId,
        tokenAcquiredAt: DateTime(2026, 1, 1),
      ),
    );

    final bind = binder.rebindActive();
    await mixedManager.plexStarted.future;
    await Future<void>.delayed(Duration.zero);

    expect(mixedManager.jellyfinStarted.isCompleted, isTrue);
    expect(activeProfile.isBinding, isTrue);

    mixedManager.releasePlex.complete();
    await bind;

    expect(activeProfile.lastBindingSucceeded, isTrue);
    expect(multiServerProvider.onlineServerIds, ['jf-machine']);
    expect(multiServerProvider.expectedServerIds.toSet(), {'srv-1', 'jf-machine'});
  });

  group('Plex Home token cache policy', () {
    test('cold start uses cached token instead of forcing PIN revalidation', () {
      expect(shouldUsePlexHomeTokenCache(preVerified: false, hasBoundOnce: false), isTrue);
    });

    test('preverified activation uses cache once regardless of setting', () {
      expect(shouldUsePlexHomeTokenCache(preVerified: true, hasBoundOnce: false), isTrue);
    });

    test('user-initiated switches bypass cache after first bind', () {
      expect(shouldUsePlexHomeTokenCache(preVerified: false, hasBoundOnce: true), isFalse);
    });

    test('preverified activation flag is consumed once per profile', () {
      expect(binder.consumePlexHomePreVerified('plex-home-x'), isFalse);
      binder.markPlexHomePreVerified('plex-home-x');
      expect(binder.consumePlexHomePreVerified('plex-home-x'), isTrue);
      expect(binder.consumePlexHomePreVerified('plex-home-x'), isFalse);
    });

    test('preverified activation flag isolates entries per profile id', () {
      binder.markPlexHomePreVerified('plex-home-a');
      binder.markPlexHomePreVerified('plex-home-b');
      expect(binder.consumePlexHomePreVerified('plex-home-b'), isTrue);
      expect(binder.consumePlexHomePreVerified('plex-home-a'), isTrue);
    });
  });

  group('Plex Home server refresh fallback', () {
    Future<({String profileId, _CapturingMultiServerManager manager})> preparePlexHomeBind({
      required bool protected,
      required http.Client httpClient,
    }) async {
      binder.dispose();
      multiServerProvider.dispose();

      final capturingManager = _CapturingMultiServerManager();
      manager = capturingManager;
      multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
      binder = ActiveProfileBinder(
        activeProfile: activeProfile,
        connections: connections,
        profileConnections: profileConnections,
        serverManager: manager,
        multiServerProvider: multiServerProvider,
        pinPrompt: (_, {String? errorMessage}) async => null,
        shouldDeferInitialBind: (_) async => false,
        plexAuth: PlexAuthService.forTesting(http: MediaServerHttpClient(client: httpClient)),
      );

      final account = PlexAccountConnection(
        id: 'plex.account',
        accountToken: 'account-token',
        clientIdentifier: 'client-id',
        accountLabel: 'Owner',
        servers: [_server(accessToken: 'account-server-token')],
        createdAt: DateTime(2026, 1, 1),
      );
      await connections.upsert(account);

      final homeUser = PlexHomeUser(
        id: 1,
        uuid: 'home-user-uuid',
        title: 'Home User',
        thumb: '',
        hasPassword: protected,
        restricted: false,
        updatedAt: null,
        admin: true,
        guest: false,
        protected: protected,
      );
      fetchedHomeUsers = [homeUser];
      final profileId = plexHomeProfileId(accountConnectionId: account.id, homeUserUuid: homeUser.uuid);
      await storage.savePlexHomeUsersCache(account.id, [homeUser.toJson()]);
      await profileConnections.upsert(
        ProfileConnection(
          profileId: profileId,
          connectionId: account.id,
          userToken: 'home-user-token',
          userIdentifier: homeUser.uuid,
          tokenAcquiredAt: DateTime(2026, 1, 1),
        ),
      );
      await storage.setActiveProfileId(profileId);
      await activeProfile.initialize();
      return (profileId: profileId, manager: capturingManager);
    }

    test('uses cached server metadata with the active user token after transient resources failure', () async {
      final prepared = await preparePlexHomeBind(
        protected: false,
        httpClient: MockClient((request) async {
          throw http.ClientException('DNS failed', request.url);
        }),
      );

      await binder.rebindActive();

      expect(activeProfile.lastBindingSucceeded, isTrue);
      expect(binder.debugLastBoundProfileId, prepared.profileId);
      expect(prepared.manager.refreshCalls, 1);
      expect(prepared.manager.lastConnection?.servers.single.accessToken, 'home-user-token');
      expect(prepared.manager.lastConnection?.servers.single.clientIdentifier, 'srv-1');
    });

    test('does not use cached server metadata after cached token auth failure', () async {
      final prepared = await preparePlexHomeBind(
        protected: true,
        httpClient: MockClient((request) async {
          return http.Response('{"errors":[]}', 401, headers: {'content-type': 'application/json'});
        }),
      );

      await binder.rebindActive();

      expect(activeProfile.lastBindingSucceeded, isFalse);
      expect(prepared.manager.refreshCalls, 0);
      final pc = await profileConnections.get(prepared.profileId, 'plex.account');
      expect(pc?.userToken, isNull);
    });
  });
}

PlexServer _server({required String accessToken}) {
  return PlexServer(
    name: 'Home Server',
    clientIdentifier: 'srv-1',
    accessToken: accessToken,
    connections: [
      PlexConnection(
        protocol: 'https',
        address: '192.168.1.3',
        port: 32400,
        uri: 'https://192-168-1-3.machine.plex.direct:32400',
        local: true,
        relay: false,
        ipv6: false,
      ),
    ],
    owned: true,
    presence: true,
  );
}

Map<String, dynamic> _serverJson() => {
  'name': 'Home Server',
  'clientIdentifier': 'srv-1',
  'accessToken': 'server-token',
  'owned': true,
  'provides': 'server',
  'connections': [
    {
      'protocol': 'https',
      'address': '192.168.1.3',
      'port': 32400,
      'uri': 'https://192-168-1-3.machine.plex.direct:32400',
      'local': true,
      'relay': false,
      'IPv6': false,
    },
  ],
};

JellyfinConnection _jellyfinConnection() {
  return JellyfinConnection(
    id: 'jf-machine/user-a',
    baseUrl: 'https://jellyfin.example',
    serverName: 'Jellyfin',
    serverMachineId: 'jf-machine',
    userId: 'user-a',
    userName: 'User A',
    accessToken: 'token',
    deviceId: 'device',
    createdAt: DateTime(2026, 1, 1),
  );
}

class _CapturingMultiServerManager extends MultiServerManager {
  int refreshCalls = 0;
  PlexAccountConnection? lastConnection;

  @override
  Future<Set<String>> refreshTokensForProfile(
    PlexAccountConnection connection, {
    Duration timeout = MediaServerTimeouts.perServerConnect,
  }) async {
    refreshCalls++;
    lastConnection = connection;
    return connection.servers.map((server) => server.clientIdentifier).toSet();
  }
}

class _FailingPlexMultiServerManager extends MultiServerManager {
  int refreshCalls = 0;

  @override
  Future<Set<String>> refreshTokensForProfile(
    PlexAccountConnection connection, {
    Duration timeout = MediaServerTimeouts.perServerConnect,
  }) async {
    refreshCalls++;
    for (final server in connection.servers) {
      updateServerStatus(ServerId(server.clientIdentifier), false);
    }
    return const {};
  }
}

class _BlockingMixedMultiServerManager extends MultiServerManager {
  final plexStarted = Completer<void>();
  final releasePlex = Completer<void>();
  final jellyfinStarted = Completer<void>();

  @override
  Future<Set<String>> refreshTokensForProfile(
    PlexAccountConnection connection, {
    Duration timeout = MediaServerTimeouts.perServerConnect,
  }) async {
    if (!plexStarted.isCompleted) plexStarted.complete();
    await releasePlex.future;
    for (final server in connection.servers) {
      updateServerStatus(ServerId(server.clientIdentifier), false);
    }
    return const {};
  }

  @override
  Future<bool> addJellyfinConnection(JellyfinConnection connection) async {
    if (!jellyfinStarted.isCompleted) jellyfinStarted.complete();
    updateServerStatus(ServerId(connection.serverMachineId), true);
    return true;
  }
}
