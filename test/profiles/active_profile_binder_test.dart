import 'dart:async';
import 'package:vibe_stream/media/ids.dart';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vibe_stream/connection/connection.dart';
import 'package:vibe_stream/connection/connection_registry.dart';
import 'package:vibe_stream/database/app_database.dart';
import 'package:vibe_stream/models/plex/plex_home_user.dart';
import 'package:vibe_stream/profiles/active_profile_binder.dart';
import 'package:vibe_stream/profiles/active_profile_provider.dart';
import 'package:vibe_stream/profiles/plex_home_service.dart';
import 'package:vibe_stream/profiles/profile.dart';
import 'package:vibe_stream/profiles/profile_connection.dart';
import 'package:vibe_stream/profiles/profile_connection_registry.dart';
import 'package:vibe_stream/profiles/profile_registry.dart';
import 'package:vibe_stream/providers/multi_server_provider.dart';
import 'package:vibe_stream/services/data_aggregation_service.dart';
import 'package:vibe_stream/services/multi_server_manager.dart';
import 'package:vibe_stream/services/plex_auth_service.dart';
import 'package:vibe_stream/services/storage_service.dart';
import 'package:vibe_stream/utils/media_server_http_client.dart';
import 'package:vibe_stream/utils/media_server_timeouts.dart';

import '../test_helpers/prefs.dart';

/// Poll [condition] until it holds, failing after [timeout]. Used to observe
/// the binder's unawaited background reconcile settling.
Future<void> pumpUntil(Future<bool> Function() condition, {Duration timeout = const Duration(seconds: 2)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

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

  test('start() marks binding synchronously so first-frame readers see it', () async {
    await createActiveLocalProfile('local-sync-start');

    binder.start();

    // Read with no await in between — mirrors DiscoverScreen's no-servers
    // gate running during the first build right after a fresh login.
    expect(activeProfile.isBinding, isTrue);

    final succeeded = await activeProfile.awaitBindingSettle();
    expect(succeeded, isTrue);
    expect(activeProfile.isBinding, isFalse);
    expect(binder.debugLastBoundProfileId, 'local-sync-start');
  });

  test('disposing before the initial rebind microtask clears the binding flag', () async {
    await createActiveLocalProfile('local-dispose-early');

    binder.start();
    expect(activeProfile.isBinding, isTrue);
    binder.dispose();

    // Let the scheduled microtask observe the disposal.
    await Future<void>.delayed(Duration.zero);
    expect(activeProfile.isBinding, isFalse);
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
    // Two connect passes: the optimistic cached-metadata pass binds nothing,
    // so the bind falls back to the freshly fetched resource list.
    expect(failingManager.refreshCalls, 2);
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

    test('binds from cache when plex.tv rejects the token, then flags re-auth from the reconcile', () async {
      final prepared = await preparePlexHomeBind(
        protected: true,
        httpClient: MockClient((request) async {
          return http.Response('{"errors":[]}', 401, headers: {'content-type': 'application/json'});
        }),
      );

      await binder.rebindActive();

      // The optimistic cached bind settles first — content stays available
      // (mirrors the cold-start cache policy: the cached token was valid
      // when minted; the splash must not block on plex.tv's verdict).
      expect(activeProfile.lastBindingSucceeded, isTrue);
      expect(prepared.manager.refreshCalls, 1);
      expect(prepared.manager.lastConnection?.servers.single.accessToken, 'home-user-token');

      // The background reconcile sees the 401: wipes the cached token and
      // flags the account for re-auth — no silent /switch re-mint that
      // could pop a PIN prompt from a background task.
      await pumpUntil(() async {
        final pc = await profileConnections.get(prepared.profileId, 'plex.account');
        return pc?.userToken == null;
      });
      await pumpUntil(() async => manager.authErrorServerIds.contains('srv-1'));
      // No second connect pass was attempted with the rejected token.
      expect(prepared.manager.refreshCalls, 1);
    });

    test('optimistic cached bind settles without waiting for the resource refresh, then reconciles', () async {
      final fetchGate = Completer<void>();
      final prepared = await preparePlexHomeBind(
        protected: false,
        httpClient: MockClient((request) async {
          await fetchGate.future;
          return http.Response(jsonEncode([_serverJson()]), 200, headers: {'content-type': 'application/json'});
        }),
      );

      // Settles while plex.tv still hasn't answered.
      await binder.rebindActive().timeout(const Duration(seconds: 2));

      expect(activeProfile.lastBindingSucceeded, isTrue);
      expect(binder.debugLastBoundProfileId, prepared.profileId);
      expect(prepared.manager.refreshCalls, 1);
      expect(prepared.manager.lastConnection?.servers.single.accessToken, 'home-user-token');

      fetchGate.complete();

      // Same membership → the reconcile rotates in the freshly fetched
      // per-server tokens in place.
      await pumpUntil(() async => prepared.manager.refreshCalls == 2);
      expect(prepared.manager.lastConnection?.servers.single.accessToken, 'server-token');

      // And the refreshed metadata was persisted onto the stored account row.
      final account = await connections.getPlexAccount('plex.account');
      expect(account?.servers.single.accessToken, 'server-token');
    });

    test('membership change in the background refresh triggers a full rebind', () async {
      final fetchGate = Completer<void>();
      final prepared = await preparePlexHomeBind(
        protected: false,
        httpClient: MockClient((request) async {
          await fetchGate.future;
          return http.Response(
            jsonEncode([_serverJson(clientIdentifier: 'srv-2')]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await binder.rebindActive().timeout(const Duration(seconds: 2));
      expect(prepared.manager.refreshCalls, 1);
      expect(prepared.manager.lastConnection?.servers.single.clientIdentifier, 'srv-1');

      fetchGate.complete();

      // Fresh membership {srv-2} ≠ cached {srv-1}: the reconcile persists the
      // new resource list and triggers a full rebind, which reuses the
      // just-validated cached token (pre-verified — no /switch round-trip)
      // and binds the new membership.
      await pumpUntil(() async => prepared.manager.lastConnection?.servers.single.clientIdentifier == 'srv-2');
      final account = await connections.getPlexAccount('plex.account');
      expect(account?.servers.single.clientIdentifier, 'srv-2');
      expect(binder.debugLastBoundProfileId, prepared.profileId);

      // The rebind's own reconcile sees identical membership and converges
      // with one final in-place token pass — no rebind loop.
      await pumpUntil(() async => prepared.manager.refreshCalls >= 3);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(prepared.manager.refreshCalls, 3);
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

Map<String, dynamic> _serverJson({String clientIdentifier = 'srv-1'}) => {
  'name': 'Home Server',
  'clientIdentifier': clientIdentifier,
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
