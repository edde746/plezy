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
    // The account-scoped cached PMS token differs from this profile token,
    // so only the freshly fetched resource list reaches the manager.
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
      List<PlexServer>? cachedServers,
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
        servers: cachedServers ?? [_server(accessToken: 'home-user-token')],
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

    test('defers distinct PMS resource tokens until plex.tv refreshes them', () async {
      final fetchStarted = Completer<void>();
      final fetchGate = Completer<void>();
      final prepared = await preparePlexHomeBind(
        protected: false,
        cachedServers: [
          _server(clientIdentifier: 'srv-direct', accessToken: 'home-user-token'),
          _server(clientIdentifier: 'srv-shared', accessToken: 'cached-shared-pms-token', owned: false, local: false),
        ],
        httpClient: MockClient((request) async {
          if (!fetchStarted.isCompleted) fetchStarted.complete();
          await fetchGate.future;
          return http.Response(
            jsonEncode([
              _serverJson(clientIdentifier: 'srv-direct', accessToken: 'fresh-direct-pms-token'),
              _serverJson(
                clientIdentifier: 'srv-shared',
                accessToken: 'fresh-shared-pms-token',
                owned: false,
                local: false,
              ),
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final bind = binder.rebindActive();
      await fetchStarted.future.timeout(const Duration(seconds: 2));
      await pumpUntil(() async => prepared.manager.refreshCalls == 1);

      // The account-scoped cached token for the shared PMS may belong to a
      // different Plex Home profile. Do not replace it with the active
      // plex.tv token and probe the PMS: shared servers reject that as 401.
      expect(prepared.manager.lastConnection?.servers.map((server) => server.clientIdentifier), ['srv-direct']);
      expect(activeProfile.isBinding, isTrue);

      fetchGate.complete();
      await bind.timeout(const Duration(seconds: 2));

      expect(prepared.manager.refreshCalls, 2);
      final refreshedServers = {
        for (final server in prepared.manager.lastConnection!.servers) server.clientIdentifier: server.accessToken,
      };
      expect(refreshedServers, {'srv-direct': 'fresh-direct-pms-token', 'srv-shared': 'fresh-shared-pms-token'});
      expect(activeProfile.lastBindingSucceeded, isTrue);
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

      // The rebind sees that the account-level PMS token differs from the
      // active profile token, so it waits for `/resources` and binds once
      // with the refreshed token instead of doing another optimistic pass.
      await pumpUntil(() async => prepared.manager.refreshCalls >= 2);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(prepared.manager.refreshCalls, 2);
    });
  });

  test('local cached Plex token remints when resources returns zero servers', () async {
    binder.dispose();
    multiServerProvider.dispose();

    var resourceCalls = 0;
    var switchCalls = 0;
    final httpClient = MockClient((request) async {
      if (request.url.path.endsWith('/resources')) {
        resourceCalls++;
        final body = resourceCalls == 1 ? <dynamic>[] : [_serverJson()];
        return http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});
      }
      if (request.url.path.endsWith('/home/users/home-user-uuid/switch')) {
        switchCalls++;
        return http.Response(
          jsonEncode({'authToken': 'fresh-user-token'}),
          201,
          headers: {'content-type': 'application/json'},
        );
      }
      fail('Unexpected request: ${request.method} ${request.url}');
    });

    final recoveringManager = _RecordingPlexManager();
    manager = recoveringManager;
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
      servers: [_server(accessToken: 'stale-server-token')],
      createdAt: DateTime(2026, 1, 1),
    );
    await connections.upsert(account);
    final profile = await createActiveLocalProfile('local-plex-remint');
    await profileConnections.upsert(
      ProfileConnection(
        profileId: profile.id,
        connectionId: account.id,
        userToken: 'stale-user-token',
        userIdentifier: 'home-user-uuid',
      ),
    );

    await binder.rebindActive();

    final row = await profileConnections.get(profile.id, account.id);
    expect(resourceCalls, 2);
    expect(switchCalls, 1);
    expect(row?.userToken, 'fresh-user-token');
    expect(recoveringManager.calls, 1);
    expect(activeProfile.lastBindingSucceeded, isTrue);
    expect(multiServerProvider.onlineServerIds, ['srv-1']);
  });

  group('shared Plex server fetch policy', () {
    Future<({Profile profile, PlexAccountConnection account})> prepareLocalPlex({
      required http.Client httpClient,
      required String? cachedToken,
      List<PlexServer> cachedServers = const [],
      MultiServerManager? testManager,
    }) async {
      binder.dispose();
      multiServerProvider.dispose();

      manager = testManager ?? _CapturingMultiServerManager();
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
        id: 'plex.policy',
        accountToken: 'account-token',
        clientIdentifier: 'client-id',
        accountLabel: 'Owner',
        servers: cachedServers,
        createdAt: DateTime(2026, 1, 1),
      );
      await connections.upsert(account);
      final profile = await createActiveLocalProfile('local-policy');
      await profileConnections.upsert(
        ProfileConnection(
          profileId: profile.id,
          connectionId: account.id,
          userToken: cachedToken,
          userIdentifier: 'home-user-uuid',
        ),
      );
      return (profile: profile, account: account);
    }

    test('cached token success connects the fetched servers without minting', () async {
      var switchCalls = 0;
      final capturing = _CapturingMultiServerManager();
      final prepared = await prepareLocalPlex(
        cachedToken: 'cached-user-token',
        testManager: capturing,
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/home/users/home-user-uuid/switch')) switchCalls++;
          return http.Response(jsonEncode([_serverJson()]), 200, headers: {'content-type': 'application/json'});
        }),
      );

      await binder.rebindActive();

      expect(switchCalls, 0);
      expect(capturing.refreshCalls, 1);
      expect(capturing.lastConnection?.servers.single.accessToken, 'server-token');
      expect((await profileConnections.get(prepared.profile.id, prepared.account.id))?.userToken, 'cached-user-token');
      expect(activeProfile.lastBindingSucceeded, isTrue);
    });

    test('missing token mints once before fetching and persists the fresh token', () async {
      var switchCalls = 0;
      var resourceCalls = 0;
      final prepared = await prepareLocalPlex(
        cachedToken: null,
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/home/users/home-user-uuid/switch')) {
            switchCalls++;
            return http.Response(
              jsonEncode({'authToken': 'fresh-user-token'}),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
          resourceCalls++;
          return http.Response(jsonEncode([_serverJson()]), 200, headers: {'content-type': 'application/json'});
        }),
      );

      await binder.rebindActive();

      expect(switchCalls, 1);
      expect(resourceCalls, 1);
      expect((await profileConnections.get(prepared.profile.id, prepared.account.id))?.userToken, 'fresh-user-token');
      expect(activeProfile.lastBindingSucceeded, isTrue);
    });

    test('cached auth rejection invalidates and remints, while a fatal error does not', () async {
      var resourceCalls = 0;
      var switchCalls = 0;
      final prepared = await prepareLocalPlex(
        cachedToken: 'rejected-token',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/home/users/home-user-uuid/switch')) {
            switchCalls++;
            return http.Response(
              jsonEncode({'authToken': 'replacement-token'}),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
          resourceCalls++;
          if (resourceCalls == 1) {
            return http.Response('{}', 401, headers: {'content-type': 'application/json'});
          }
          return http.Response('{}', 500, headers: {'content-type': 'application/json'});
        }),
      );

      await binder.rebindActive();

      expect(resourceCalls, 2);
      expect(switchCalls, 1);
      expect((await profileConnections.get(prepared.profile.id, prepared.account.id))?.userToken, 'replacement-token');
      expect(activeProfile.lastBindingSucceeded, isFalse);
    });

    test('cancelled fetch does not invalidate or remint the cached token', () async {
      var switchCalls = 0;
      final prepared = await prepareLocalPlex(
        cachedToken: 'cached-user-token',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/home/users/home-user-uuid/switch')) switchCalls++;
          throw http.RequestAbortedException(request.url);
        }),
      );

      await binder.rebindActive();

      expect(switchCalls, 0);
      expect((await profileConnections.get(prepared.profile.id, prepared.account.id))?.userToken, 'cached-user-token');
      expect(activeProfile.lastBindingSucceeded, isFalse);
    });

    test('profile switch cancels stale zero-server handling before invalidation or remint', () async {
      final requestStarted = Completer<void>();
      final releaseRequest = Completer<void>();
      var switchCalls = 0;
      final prepared = await prepareLocalPlex(
        cachedToken: 'cached-user-token',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/home/users/home-user-uuid/switch')) switchCalls++;
          if (!requestStarted.isCompleted) requestStarted.complete();
          await releaseRequest.future;
          return http.Response('[]', 200, headers: {'content-type': 'application/json'});
        }),
      );
      final nextProfile = Profile.local(id: 'local-next', displayName: 'Next', createdAt: DateTime(2026, 1, 2));
      await profiles.upsert(nextProfile);
      await pumpUntil(() async => activeProfile.profiles.any((profile) => profile.id == nextProfile.id));

      binder.start();
      await requestStarted.future;
      await activeProfile.activate(nextProfile);
      releaseRequest.complete();
      await activeProfile.awaitBindingSettle();

      expect(switchCalls, 0);
      expect((await profileConnections.get(prepared.profile.id, prepared.account.id))?.userToken, 'cached-user-token');
      expect(binder.debugLastBoundProfileId, nextProfile.id);
      expect(activeProfile.lastBindingSucceeded, isTrue);
    });
  });

  group('rebind cycle semantics', () {
    test('queued same-id rebind settles once, after the last pass', () async {
      binder.dispose();
      multiServerProvider.dispose();

      final gated = _GatedJellyfinManager();
      manager = gated;
      multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
      binder = ActiveProfileBinder(
        activeProfile: activeProfile,
        connections: connections,
        profileConnections: profileConnections,
        serverManager: manager,
        multiServerProvider: multiServerProvider,
        pinPrompt: (_, {String? errorMessage}) async => null,
        shouldDeferInitialBind: (_) async => false,
      );

      final profile = await createActiveLocalProfile('local-queued');
      final jellyfin = _jellyfinConnection();
      await connections.upsert(jellyfin);
      await profileConnections.upsert(
        ProfileConnection(profileId: profile.id, connectionId: jellyfin.id, userIdentifier: jellyfin.userId),
      );

      final cycle = binder.rebindActive();
      await pumpUntil(() async => gated.calls == 1);

      int? callsAtSettle;
      unawaited(activeProfile.awaitBindingSettle().then((_) => callsAtSettle = gated.calls));
      unawaited(binder.rebindActive()); // queues a same-id follow-up pass
      gated.gate.complete();
      await cycle;
      await Future<void>.delayed(Duration.zero);

      expect(gated.calls, 2);
      // Waiters must observe the whole cycle, not the first pass's outcome.
      expect(callsAtSettle, 2);
      expect(activeProfile.isBinding, isFalse);
    });

    test('A to B to A during one pass forces a complete final A bind', () async {
      binder.dispose();
      multiServerProvider.dispose();

      final gated = _GatedJellyfinManager();
      manager = gated;
      multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
      binder = ActiveProfileBinder(
        activeProfile: activeProfile,
        connections: connections,
        profileConnections: profileConnections,
        serverManager: manager,
        multiServerProvider: multiServerProvider,
        pinPrompt: (_, {String? errorMessage}) async => null,
        shouldDeferInitialBind: (_) async => false,
      );

      final profileA = await createActiveLocalProfile('local-a');
      final profileB = Profile.local(id: 'local-b', displayName: 'B', createdAt: DateTime(2026, 1, 2));
      await profiles.upsert(profileB);
      await pumpUntil(() async => activeProfile.profiles.any((profile) => profile.id == profileB.id));

      final jellyfin = _jellyfinConnection();
      await connections.upsert(jellyfin);
      await profileConnections.upsert(
        ProfileConnection(profileId: profileA.id, connectionId: jellyfin.id, userIdentifier: jellyfin.userId),
      );

      binder.start();
      await pumpUntil(() async => gated.calls == 1);

      expect(await activeProfile.activate(profileB), isTrue);
      expect(await activeProfile.activate(profileA), isTrue);
      gated.gate.complete();
      await activeProfile.awaitBindingSettle();

      expect(gated.calls, 2);
      expect(binder.debugLastBoundProfileId, profileA.id);
      expect(multiServerProvider.onlineServerIds, ['jf-machine']);
      expect(activeProfile.lastBindingSucceeded, isTrue);
    });
    test('passive notifications do not retry a failed profile; explicit rebind does', () async {
      binder.dispose();
      multiServerProvider.dispose();

      final failing = _CountingFailingJellyfinManager();
      manager = failing;
      multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
      binder = ActiveProfileBinder(
        activeProfile: activeProfile,
        connections: connections,
        profileConnections: profileConnections,
        serverManager: manager,
        multiServerProvider: multiServerProvider,
        pinPrompt: (_, {String? errorMessage}) async => null,
        shouldDeferInitialBind: (_) async => false,
      );

      final profile = await createActiveLocalProfile('local-failing');
      final jellyfin = _jellyfinConnection();
      await connections.upsert(jellyfin);
      await profileConnections.upsert(
        ProfileConnection(profileId: profile.id, connectionId: jellyfin.id, userIdentifier: jellyfin.userId),
      );

      binder.start();
      await pumpUntil(() async => failing.calls == 1 && !activeProfile.isBinding);
      expect(activeProfile.lastBindingSucceeded, isFalse);

      // A passive data change (an unrelated connection appearing) must not
      // re-run the failed bind — mid-session retries can pop PIN prompts.
      await connections.upsert(_jellyfinConnection2());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(failing.calls, 1);

      // An explicit rebind clears the marker and retries.
      await binder.rebindActive();
      expect(failing.calls, greaterThan(1));
    });

    test('passive rebind of a protected Plex Home profile never prompts for a PIN', () async {
      binder.dispose();
      multiServerProvider.dispose();

      var pinPrompts = 0;
      manager = _CapturingMultiServerManager();
      multiServerProvider = MultiServerProvider(manager, DataAggregationService(manager));
      binder = ActiveProfileBinder(
        activeProfile: activeProfile,
        connections: connections,
        profileConnections: profileConnections,
        serverManager: manager,
        multiServerProvider: multiServerProvider,
        pinPrompt: (_, {String? errorMessage}) async {
          pinPrompts++;
          return null;
        },
        shouldDeferInitialBind: (_) async => false,
        plexAuth: PlexAuthService.forTesting(
          http: MediaServerHttpClient(client: MockClient((_) async => http.Response('{}', 500))),
        ),
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
        uuid: 'protected-uuid',
        title: 'Protected',
        thumb: '',
        hasPassword: true,
        restricted: false,
        updatedAt: null,
        admin: false,
        guest: false,
        protected: true,
      );
      fetchedHomeUsers = [homeUser];
      await storage.savePlexHomeUsersCache(account.id, [homeUser.toJson()]);

      // Bind a harmless local profile first so the session crosses the
      // cold-start boundary (_hasBoundOnce) — the state in which passive
      // rebinds would otherwise PIN-prompt via /switch.
      await createActiveLocalProfile('local-first');
      binder.start();
      await pumpUntil(() async => !activeProfile.isBinding && binder.debugLastBoundProfileId == 'local-first');

      // Activation WITHOUT the user-initiated mark: the binder must fail the
      // bind silently instead of popping a PIN dialog.
      final protectedProfile = Profile.virtualPlexHome(connectionId: account.id, homeUser: homeUser);
      await activeProfile.activate(protectedProfile);
      await pumpUntil(() async => !activeProfile.isBinding);
      expect(pinPrompts, 0);
      expect(activeProfile.lastBindingSucceeded, isFalse);

      // The same switch marked user-initiated prompts (and the spy cancels).
      binder.markUserInitiatedActivation(protectedProfile.id);
      await binder.rebindActive();
      expect(pinPrompts, 1);
    });
  });
}

PlexServer _server({
  required String accessToken,
  String clientIdentifier = 'srv-1',
  bool owned = true,
  bool local = true,
}) {
  return PlexServer(
    name: 'Home Server',
    clientIdentifier: clientIdentifier,
    accessToken: accessToken,
    connections: [
      PlexConnection(
        protocol: 'https',
        address: '192.168.1.3',
        port: 32400,
        uri: 'https://192-168-1-3.machine.plex.direct:32400',
        local: local,
        relay: false,
        ipv6: false,
      ),
    ],
    owned: owned,
    presence: true,
  );
}

Map<String, dynamic> _serverJson({
  String clientIdentifier = 'srv-1',
  String accessToken = 'server-token',
  bool owned = true,
  bool local = true,
}) => {
  'name': 'Home Server',
  'clientIdentifier': clientIdentifier,
  'accessToken': accessToken,
  'owned': owned,
  'provides': 'server',
  'connections': [
    {
      'protocol': 'https',
      'address': '192.168.1.3',
      'port': 32400,
      'uri': 'https://192-168-1-3.machine.plex.direct:32400',
      'local': local,
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

JellyfinConnection _jellyfinConnection2() {
  return JellyfinConnection(
    id: 'jf-other/user-b',
    baseUrl: 'https://other.example',
    serverName: 'Other',
    serverMachineId: 'jf-other',
    userId: 'user-b',
    userName: 'User B',
    accessToken: 'token-b',
    deviceId: 'device',
    createdAt: DateTime(2026, 1, 2),
  );
}

class _GatedJellyfinManager extends MultiServerManager {
  final Completer<void> gate = Completer<void>();
  int calls = 0;

  @override
  Future<bool> addJellyfinConnection(JellyfinConnection connection) async {
    calls++;
    if (calls == 1) await gate.future;
    updateServerStatus(ServerId(connection.serverMachineId), true);
    return true;
  }
}

class _CountingFailingJellyfinManager extends MultiServerManager {
  int calls = 0;

  @override
  Future<bool> addJellyfinConnection(JellyfinConnection connection) async {
    calls++;
    updateServerStatus(ServerId(connection.serverMachineId), false);
    return false;
  }
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

class _RecordingPlexManager extends MultiServerManager {
  int calls = 0;

  @override
  Future<Set<String>> refreshTokensForProfile(
    PlexAccountConnection connection, {
    Duration timeout = MediaServerTimeouts.perServerConnect,
  }) async {
    calls++;
    final ids = connection.servers.map((server) => server.clientIdentifier).toSet();
    for (final id in ids) {
      updateServerStatus(ServerId(id), true);
    }
    return ids;
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
