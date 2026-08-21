import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_server_client.dart';

import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/storage_service.dart';
import 'package:plezy/utils/active_client_scope.dart';
import 'package:plezy/utils/device_identity.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/prefs.dart';

JellyfinConnection _jellyfinConnection(String userId) => testJellyfinConnection(
  machineId: 'jf-machine',
  userId: userId,
  serverName: 'Shared JF',
  userName: userId,
  accessToken: 'token-$userId',
  deviceId: 'device',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

JellyfinClient _jellyfinClient(String userId) => testJellyfinClient(connection: _jellyfinConnection(userId));

class _LoopbackJellyfinServer {
  _LoopbackJellyfinServer._(this._server, this.machineId, this.baseUrl, this.requests, this.publicInfoAvailable);

  final HttpServer _server;
  final String machineId;
  final String baseUrl;
  final List<({String path, bool authenticated})> requests;
  bool _closed = false;
  bool publicInfoAvailable;

  static Future<_LoopbackJellyfinServer> start({
    required String machineId,
    Duration responseDelay = Duration.zero,
    void Function(String event)? onRequest,
    bool isAdministrator = false,
    bool publicInfoAvailable = true,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <({String path, bool authenticated})>[];
    final result = _LoopbackJellyfinServer._(
      server,
      machineId,
      'http://127.0.0.1:${server.port}',
      requests,
      publicInfoAvailable,
    );
    server.listen((request) async {
      final authenticated =
          request.headers.value(HttpHeaders.authorizationHeader) != null ||
          request.headers.value('X-Emby-Token') != null ||
          request.uri.queryParameters.keys.any((key) => key.toLowerCase() == 'api_key');
      requests.add((path: request.uri.path, authenticated: authenticated));
      onRequest?.call(request.uri.path);
      if (responseDelay > Duration.zero) {
        await Future<void>.delayed(responseDelay);
      }
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path.endsWith('/System/Info/Public')) {
        if (result.publicInfoAvailable) {
          request.response.write(jsonEncode({'Id': machineId, 'ServerName': 'Loopback', 'Version': '10.9.0'}));
        } else {
          request.response.statusCode = HttpStatus.serviceUnavailable;
          request.response.write('{}');
        }
      } else if (request.uri.path.endsWith('/Users/Me')) {
        request.response.write(
          jsonEncode({
            'Policy': {'IsAdministrator': isAdministrator},
          }),
        );
      } else {
        request.response.write('{}');
      }
      await request.response.close();
    });
    return result;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _server.close(force: true);
  }
}

void main() {
  setUp(resetSharedPreferencesForTest);

  group('initial state', () {
    test('a freshly constructed manager has no servers, clients, or status', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      expect(m.serverIds, isEmpty);
      expect(m.onlineServerIds, isEmpty);
      expect(m.offlineServerIds, isEmpty);
      expect(m.onlineClients, isEmpty);
    });

    test('getClient returns null for unknown ids', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      expect(m.getClient(ServerId('nope')), isNull);
      expect(m.isServerOnline(ServerId('nope')), isFalse);
    });
  });

  group('updateServerStatus + statusStream', () {
    test('emits a snapshot when status flips for a tracked server', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      // Pre-seed status (mirrors what addServer would do post-connect).
      m.updateServerStatus(ServerId('srv-1'), true);
      m.updateServerStatus(ServerId('srv-2'), false);
      m.updateServerStatus(ServerId('srv-1'), false); // change

      // Let the broadcast stream events drain.
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(3));
      expect(emitted[0], {'srv-1': true});
      expect(emitted[1], {'srv-1': true, 'srv-2': false});
      expect(emitted[2], {'srv-1': false, 'srv-2': false});
    });

    test('repeated identical status is debounced (no extra emission)', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      m.updateServerStatus(ServerId('srv-1'), true);
      m.updateServerStatus(ServerId('srv-1'), true); // same value: no-op
      m.updateServerStatus(ServerId('srv-1'), true);

      await Future<void>.delayed(Duration.zero);
      expect(emitted, hasLength(1));
      expect(emitted.first, {'srv-1': true});
    });

    test('online/offline server-id getters reflect updateServerStatus', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.updateServerStatus(ServerId('a'), true);
      m.updateServerStatus(ServerId('b'), false);
      m.updateServerStatus(ServerId('c'), true);

      expect(m.onlineServerIds.toSet(), {'a', 'c'});
      expect(m.offlineServerIds.toSet(), {'b'});
      expect(m.isServerOnline(ServerId('a')), isTrue);
      expect(m.isServerOnline(ServerId('b')), isFalse);
    });
  });

  group('endpoint exhaustion verification', () {
    test('content-route exhaustion keeps an authenticated Jellyfin server online', () async {
      final manager = MultiServerManager();
      addTearDown(manager.dispose);
      final client = testJellyfinClient(
        connection: _jellyfinConnection('user-a'),
        handler: (_) async =>
            http.Response('{"Policy":{"IsAdministrator":false}}', 200, headers: {'content-type': 'application/json'}),
      );
      manager.debugRegisterJellyfinClientForTesting(client);

      final emitted = <Map<String, bool>>[];
      final sub = manager.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      await manager.debugVerifyServerEndpointsExhaustedForTesting(ServerId('jf-machine'));
      await Future<void>.delayed(Duration.zero);

      expect(manager.isServerOnline(ServerId('jf-machine')), isTrue);
      expect(manager.authErrorServerIds, isEmpty);
      expect(emitted, isEmpty, reason: 'a successful health probe must not publish a false offline transition');
    });

    test('auth rejection is published without attempting generic reconnection', () async {
      final manager = MultiServerManager();
      addTearDown(manager.dispose);
      final client = testJellyfinClient(
        connection: _jellyfinConnection('user-a'),
        handler: (_) async => http.Response('', 401),
      );
      manager.debugRegisterJellyfinClientForTesting(client);

      final emitted = <Map<String, bool>>[];
      final sub = manager.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      await manager.debugVerifyServerEndpointsExhaustedForTesting(ServerId('jf-machine'));
      await Future<void>.delayed(Duration.zero);

      expect(manager.isServerOnline(ServerId('jf-machine')), isFalse);
      expect(manager.authErrorServerIds, {'jf-machine'});
      expect(emitted, [
        {'jf-machine': false},
      ]);
    });

    test('confirmed-offline probe publishes offline once and schedules reconnection', () async {
      final manager = MultiServerManager();
      addTearDown(manager.dispose);
      var probes = 0;
      final client = testJellyfinClient(
        connection: _jellyfinConnection('user-a'),
        handler: (req) async {
          if (req.url.path == '/Users/Me') probes++;
          return http.Response('', 500);
        },
      );
      manager.debugRegisterJellyfinClientForTesting(client);

      final emitted = <Map<String, bool>>[];
      final sub = manager.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      await manager.debugVerifyServerEndpointsExhaustedForTesting(ServerId('jf-machine'));
      // The scheduled reconnection runs unawaited — let it finish.
      await pumpEventQueue();

      expect(manager.isServerOnline(ServerId('jf-machine')), isFalse);
      expect(probes, 2, reason: 'confirmed exhaustion schedules the backend reconnection probe');
      expect(emitted, [
        {'jf-machine': false},
      ], reason: 'the reconnection probe repeating the offline verdict must not re-publish it');
    });

    test('probe-raised exhaustion re-arms the retry loop and recovers when the server returns', () {
      fakeAsync((async) {
        final manager = MultiServerManager();
        var healthy = false;
        final client = testJellyfinClient(
          connection: _jellyfinConnection('user-a'),
          handler: (_) async => healthy
              ? http.Response(
                  '{"Policy":{"IsAdministrator":false}}',
                  200,
                  headers: {'content-type': 'application/json'},
                )
              : http.Response('', 500),
          // Production wiring: the probe's own failed GET re-raises exhaustion.
          onAllEndpointsExhausted: () => manager.debugTriggerEndpointsExhaustedForTesting(ServerId('jf-machine')),
        );
        manager.debugRegisterJellyfinClientForTesting(client);

        final emitted = <Map<String, bool>>[];
        final sub = manager.statusStream.listen(emitted.add);

        // A failed content GET raises exhaustion → debounce → probe confirms
        // offline. Exhaustion raised DURING the verification is swallowed by
        // the in-flight guard; the reconnection probe's failure fires after
        // the guard clears and re-arms the debounce.
        manager.debugTriggerEndpointsExhaustedForTesting(ServerId('jf-machine'));
        async.elapse(const Duration(seconds: 5));
        async.flushMicrotasks();
        expect(manager.isServerOnline(ServerId('jf-machine')), isFalse);

        // Server recovers: the self-re-armed loop flips it back online with
        // no external trigger — offline retry must survive the guard.
        healthy = true;
        async.elapse(const Duration(seconds: 6));
        async.flushMicrotasks();
        expect(manager.isServerOnline(ServerId('jf-machine')), isTrue);
        expect(emitted, [
          {'jf-machine': false},
          {'jf-machine': true},
        ]);

        sub.cancel();
        manager.dispose();
      });
    });
  });

  group('refreshTokensForProfile', () {
    test('successful in-place Plex token refresh clears auth-error state', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final m = MultiServerManager();
      addTearDown(m.dispose);

      final client = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: 'https://plex.example',
          token: 'old-token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: '1.0.0',
        ),
        serverId: ServerId('server-1'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-1'), profileId: 'profile-1'),
        serverName: 'Plex',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'MediaContainer': {'machineIdentifier': 'server-1'},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          ),
        ),
      );
      m.debugRegisterClientForTesting(client, online: true);
      m.debugMarkAuthErrorForTesting(ServerId('server-1'));

      final bound = await m.refreshTokensForProfile(
        PlexAccountConnection(
          id: 'account-1',
          accountToken: 'account-token',
          clientIdentifier: 'client-id',
          accountLabel: 'Account',
          servers: [
            PlexServer(
              name: 'Plex',
              clientIdentifier: 'server-1',
              accessToken: 'new-token',
              connections: const [],
              owned: true,
            ),
          ],
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
        profileId: 'profile-1',
      );

      expect(bound, {'server-1'});
      expect(m.authErrorServerIds, isNot(contains('server-1')));
      expect(client.config.token, 'new-token');
    });

    test('unavailable optional Plex providers commits the token and clears old profile provider state', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      String? tokenFor(http.Request request) {
        for (final entry in request.headers.entries) {
          if (entry.key.toLowerCase() == 'x-plex-token') return entry.value;
        }
        return null;
      }

      http.Response jsonResponse(Map<String, dynamic> body) =>
          http.Response(jsonEncode(body), 200, headers: const {'content-type': 'application/json'});

      final client = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: 'https://plex.example',
          token: 'old-token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: '1.0.0',
        ),
        serverId: ServerId('server-1'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-1'), profileId: 'old-profile'),
        serverName: 'Plex',
        httpClient: MockClient((request) async {
          switch (request.url.path) {
            case '/':
              return jsonResponse({
                'MediaContainer': {'machineIdentifier': 'server-1'},
              });
            case '/media/providers':
              if (tokenFor(request) == 'new-token') {
                return http.Response('provider unavailable', 503);
              }
              return jsonResponse({
                'MediaContainer': {
                  'MediaProvider': [
                    {
                      'identifier': 'com.plexapp.plugins.library',
                      'Feature': [
                        {
                          'type': 'content',
                          'Directory': [
                            {'id': '1', 'key': '/library/sections/1', 'type': 'movie', 'title': 'Old Profile Movies'},
                          ],
                        },
                      ],
                    },
                  ],
                },
              });
            case '/library/sections':
              return jsonResponse({
                'MediaContainer': {
                  'Directory': [
                    {'key': '9', 'type': 'movie', 'title': 'Fallback Movies'},
                  ],
                },
              });
            default:
              fail('Unexpected Plex request: ${request.url.path}');
          }
        }),
      );
      final oldScope = buildPlexProfileScopeId(serverId: ServerId('server-1'), profileId: 'old-profile');
      expect(await client.applyProfileUpdate(newToken: 'old-token', newProfileScopeId: oldScope), isTrue);
      expect((await client.fetchLibraries()).map((library) => library.title), ['Old Profile Movies']);

      final manager = MultiServerManager();
      addTearDown(manager.dispose);
      manager.debugRegisterClientForTesting(client, online: true);

      final bound = await manager.refreshTokensForProfile(
        _plexAccount('account-1', [
          PlexServer(
            name: 'Plex',
            clientIdentifier: 'server-1',
            accessToken: 'new-token',
            connections: const [],
            owned: true,
          ),
        ]),
        profileId: 'new-profile',
      );

      expect(bound, {'server-1'});
      expect(manager.isServerOnline(ServerId('server-1')), isTrue);
      expect(manager.authErrorServerIds, isNot(contains('server-1')));
      expect(client.config.token, 'new-token');
      expect(client.profileScopeId, buildPlexProfileScopeId(serverId: ServerId('server-1'), profileId: 'new-profile'));
      expect((await client.fetchLibraries()).map((library) => library.title), ['Fallback Movies']);
    });

    test('newest overlapping Plex profile refresh owns provider state', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final responseGates = <String, Completer<http.Response>>{
        'token-a': Completer<http.Response>(),
        'token-b': Completer<http.Response>(),
      };
      final requestStarted = <String, Completer<void>>{'token-a': Completer<void>(), 'token-b': Completer<void>()};
      String? tokenFor(http.Request request) {
        for (final entry in request.headers.entries) {
          if (entry.key.toLowerCase() == 'x-plex-token') return entry.value;
        }
        return null;
      }

      http.Response providerResponse(String id, String title) => http.Response(
        jsonEncode({
          'MediaContainer': {
            'MediaProvider': [
              {
                'identifier': 'com.plexapp.plugins.library',
                'Feature': [
                  {
                    'type': 'content',
                    'Directory': [
                      {'id': id, 'key': '/library/sections/$id', 'type': 'movie', 'title': title},
                    ],
                  },
                ],
              },
            ],
          },
        }),
        200,
        headers: const {'content-type': 'application/json'},
      );

      final client = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: 'https://plex.example',
          token: 'old-token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: '1.0.0',
        ),
        serverId: ServerId('server-1'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-1'), profileId: 'old-profile'),
        serverName: 'Plex',
        httpClient: MockClient((request) async {
          final token = tokenFor(request)!;
          if (request.url.path == '/') {
            return http.Response(
              jsonEncode({
                'MediaContainer': {'machineIdentifier': 'server-1'},
              }),
              200,
              headers: const {'content-type': 'application/json'},
            );
          }
          expect(request.url.path, '/media/providers');
          requestStarted[token]!.complete();
          return responseGates[token]!.future;
        }),
      );
      final manager = MultiServerManager();
      addTearDown(manager.dispose);
      manager.debugRegisterClientForTesting(client, online: true);

      PlexServer server(String token) => PlexServer(
        name: 'Plex',
        clientIdentifier: 'server-1',
        accessToken: token,
        connections: const [],
        owned: true,
      );

      final earlier = manager.refreshTokensForProfile(
        _plexAccount('account-1', [server('token-a')]),
        profileId: 'profile-a',
      );
      await requestStarted['token-a']!.future;
      final later = manager.refreshTokensForProfile(
        _plexAccount('account-1', [server('token-b')]),
        profileId: 'profile-b',
      );
      await requestStarted['token-b']!.future;

      responseGates['token-b']!.complete(providerResponse('2', 'Profile B Movies'));
      expect(await later, {'server-1'});
      responseGates['token-a']!.complete(providerResponse('1', 'Profile A Movies'));
      expect(await earlier, isEmpty);

      expect(client.config.token, 'token-b');
      expect(client.profileScopeId, buildPlexProfileScopeId(serverId: ServerId('server-1'), profileId: 'profile-b'));
      final libraries = await client.fetchLibraries();
      expect(libraries.map((library) => library.title), ['Profile B Movies']);
    });

    test('rejected refreshed Plex token remains offline and auth-failed', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final client = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: 'https://plex.example',
          token: 'old-token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: '1.0.0',
        ),
        serverId: ServerId('server-1'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-1'), profileId: 'old-profile'),
        serverName: 'Plex',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/');
          return http.Response('rejected', 401);
        }),
      );
      final manager = MultiServerManager();
      addTearDown(manager.dispose);
      manager.debugRegisterClientForTesting(client, online: true);

      final bound = await manager.refreshTokensForProfile(
        _plexAccount('account-1', [
          PlexServer(
            name: 'Plex',
            clientIdentifier: 'server-1',
            accessToken: 'rejected-token',
            connections: const [],
            owned: true,
          ),
        ]),
        profileId: 'profile-b',
      );

      expect(bound, isEmpty);
      expect(manager.isServerOnline(ServerId('server-1')), isFalse);
      expect(manager.authErrorServerIds, contains('server-1'));
      expect(client.config.token, 'old-token');
      expect(client.profileScopeId, buildPlexProfileScopeId(serverId: ServerId('server-1'), profileId: 'old-profile'));
    });

    test('required Plex probe rejects a different server identity without committing the candidate', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final client = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: 'https://plex.example',
          token: 'old-token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: '1.0.0',
        ),
        serverId: ServerId('server-1'),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId('server-1'), profileId: 'old-profile'),
        serverName: 'Plex',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/');
          return http.Response(
            jsonEncode({
              'MediaContainer': {'machineIdentifier': 'different-server'},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
      );
      final manager = MultiServerManager();
      addTearDown(manager.dispose);
      manager.debugRegisterClientForTesting(client, online: true);

      final bound = await manager.refreshTokensForProfile(
        _plexAccount('account-1', [
          PlexServer(
            name: 'Plex',
            clientIdentifier: 'server-1',
            accessToken: 'wrong-server-token',
            connections: const [],
            owned: true,
          ),
        ]),
        profileId: 'profile-b',
      );

      expect(bound, isEmpty);
      expect(manager.isServerOnline(ServerId('server-1')), isFalse);
      expect(client.config.token, 'old-token');
      expect(client.profileScopeId, buildPlexProfileScopeId(serverId: ServerId('server-1'), profileId: 'old-profile'));
    });

    test('concurrent Plex account refreshes do not invalidate each other', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final manager = MultiServerManager();
      addTearDown(manager.dispose);

      PlexClient client(String serverId) => PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: 'https://$serverId.example',
          token: 'old-$serverId',
          clientIdentifier: 'client-$serverId',
          product: 'Plezy',
          version: '1.0.0',
        ),
        serverId: ServerId(serverId),
        profileScopeId: buildPlexProfileScopeId(serverId: ServerId(serverId), profileId: 'profile-$serverId'),
        serverName: serverId,
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'MediaContainer': {'machineIdentifier': serverId},
            }),
            200,
            headers: const {'content-type': 'application/json'},
          ),
        ),
      );

      final clientA = client('server-a');
      final clientB = client('server-b');
      manager.debugRegisterClientForTesting(clientA, online: true);
      manager.debugRegisterClientForTesting(clientB, online: true);

      PlexAccountConnection account(String accountId, String serverId) => PlexAccountConnection(
        id: accountId,
        accountToken: 'account-token',
        clientIdentifier: 'client-$serverId',
        accountLabel: accountId,
        servers: [
          PlexServer(
            name: serverId,
            clientIdentifier: serverId,
            accessToken: 'new-$serverId',
            connections: const [],
            owned: true,
          ),
        ],
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

      final results = await Future.wait([
        manager.refreshTokensForProfile(account('account-a', 'server-a'), profileId: 'profile-server-a'),
        manager.refreshTokensForProfile(account('account-b', 'server-b'), profileId: 'profile-server-b'),
      ]);

      expect(results, [
        {'server-a'},
        {'server-b'},
      ]);
      expect(clientA.config.token, 'new-server-a');
      expect(clientB.config.token, 'new-server-b');
    });

    test('fresh bind registers the scoped factory client and promotes a later endpoint', () async {
      final storage = await _prepareFreshPlexManagerTest();
      final first = _plexEndpoint('first');
      final promoted = _plexEndpoint('promoted');
      final discoveries = StreamController<PlexConnection>(sync: true);
      final server = _ControlledPlexServer(
        serverId: 'fresh-server',
        endpoints: [first, promoted],
        discoveryStreams: [() => discoveries.stream],
      );
      final factory = _RecordingPlexFactory();
      final manager = MultiServerManager(
        plexClientFactory: factory.create,
        connectivityChanges: () => const Stream.empty(),
      );
      addTearDown(manager.dispose);
      addTearDown(discoveries.close);
      final progress = <({String serverId, bool online})>[];
      final progressSub = manager.connectProgressStream.listen(progress.add);
      addTearDown(progressSub.cancel);

      final refresh = manager.refreshTokensForProfile(_plexAccount('fresh-account', [server]), profileId: 'profile-a');
      await pumpEventQueue();
      discoveries.add(first);
      final bound = await refresh;
      await pumpEventQueue();

      final expectedScope = buildPlexProfileScopeId(serverId: ServerId('fresh-server'), profileId: 'profile-a');
      final client = factory.clients['fresh-server']!;
      expect(bound, {'fresh-server'});
      expect(manager.getClient(ServerId('fresh-server')), same(client));
      expect(client.profileScopeId, expectedScope);
      expect(manager.isServerOnline(ServerId('fresh-server')), isTrue);
      expect(progress, contains((serverId: 'fresh-server', online: true)));
      expect(storage.getServerEndpoint(ServerId('fresh-server')), first.uri);

      final call = factory.calls.single;
      expect(call.serverId, ServerId('fresh-server'));
      expect(call.profileScopeId, expectedScope);
      expect(call.config.baseUrl, first.uri);
      expect(call.prioritizedEndpoints?.first, first.uri);
      expect(call.hasEndpointCallback, isTrue);
      expect(call.hasExhaustionCallback, isTrue);
      expect(call.seedTranscoderVideoSupport, isTrue);

      discoveries.add(promoted);
      await discoveries.close();
      await pumpEventQueue(times: 20);

      expect(client.config.baseUrl, promoted.uri);
      expect(storage.getServerEndpoint(ServerId('fresh-server')), promoted.uri);
    });

    test('fresh bind isolates a sibling factory failure and publishes both outcomes', () async {
      await _prepareFreshPlexManagerTest();
      final goodEndpoint = _plexEndpoint('good');
      final badEndpoint = _plexEndpoint('bad');
      final goodServer = _ControlledPlexServer(
        serverId: 'good-server',
        endpoints: [goodEndpoint],
        discoveryStreams: [() => Stream.value(goodEndpoint)],
      );
      final badServer = _ControlledPlexServer(
        serverId: 'bad-server',
        endpoints: [badEndpoint],
        discoveryStreams: [() => Stream.value(badEndpoint)],
      );
      final factory = _RecordingPlexFactory(failingServerIds: {'bad-server'});
      var connectivityFactoryCalls = 0;
      final manager = MultiServerManager(
        plexClientFactory: factory.create,
        connectivityChanges: () {
          connectivityFactoryCalls++;
          return const Stream.empty();
        },
      );
      addTearDown(manager.dispose);
      final progress = <({String serverId, bool online})>[];
      final statuses = <Map<String, bool>>[];
      final progressSub = manager.connectProgressStream.listen(progress.add);
      final statusSub = manager.statusStream.listen(statuses.add);
      addTearDown(progressSub.cancel);
      addTearDown(statusSub.cancel);

      final bound = await manager.refreshTokensForProfile(
        _plexAccount('mixed-account', [goodServer, badServer]),
        profileId: 'profile-a',
      );
      await pumpEventQueue();

      expect(bound, {'good-server'});
      expect(manager.getClient(ServerId('good-server')), same(factory.clients['good-server']));
      expect(manager.getClient(ServerId('bad-server')), isNull);
      expect(manager.isServerOnline(ServerId('good-server')), isTrue);
      expect(manager.isServerOnline(ServerId('bad-server')), isFalse);
      expect(progress, containsAll([(serverId: 'good-server', online: true), (serverId: 'bad-server', online: false)]));
      expect(statuses.last, {'good-server': true, 'bad-server': false});
      expect(connectivityFactoryCalls, 1);
    });

    test('late endpoint promotion cannot mutate persistence or a replacement after removal', () async {
      final storage = await _prepareFreshPlexManagerTest();
      final first = _plexEndpoint('stale-first');
      final late = _plexEndpoint('stale-late');
      final replacementEndpoint = _plexEndpoint('replacement');
      final discoveries = StreamController<PlexConnection>(sync: true);
      final server = _ControlledPlexServer(
        serverId: 'stale-server',
        endpoints: [first, late],
        discoveryStreams: [() => discoveries.stream],
      );
      final factory = _RecordingPlexFactory();
      final manager = MultiServerManager(
        plexClientFactory: factory.create,
        connectivityChanges: () => const Stream.empty(),
      );
      addTearDown(manager.dispose);
      addTearDown(discoveries.close);

      final refresh = manager.refreshTokensForProfile(_plexAccount('stale-account', [server]), profileId: 'profile-a');
      await pumpEventQueue();
      discoveries.add(first);
      expect(await refresh, {'stale-server'});
      expect(storage.getServerEndpoint(ServerId('stale-server')), first.uri);

      manager.removeServer(ServerId('stale-server'));
      final replacementScope = buildPlexProfileScopeId(serverId: ServerId('stale-server'), profileId: 'profile-b');
      final replacement = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: replacementEndpoint.uri,
          token: 'redacted',
          clientIdentifier: 'replacement-client',
          product: 'Plezy',
          version: '1.0.0',
        ),
        serverId: ServerId('stale-server'),
        profileScopeId: replacementScope,
        serverName: 'replacement',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      manager.debugRegisterClientForTesting(replacement);

      discoveries.add(late);
      await discoveries.close();
      await pumpEventQueue(times: 20);

      expect(manager.getClient(ServerId('stale-server')), same(replacement));
      expect(replacement.config.baseUrl, replacementEndpoint.uri);
      expect(storage.getServerEndpoint(ServerId('stale-server')), first.uri);
    });

    test(
      'connectivity monitoring is lazy, singular, ignores none, and coalesces connected events for two seconds',
      () async {
        await _prepareFreshPlexManagerTest();
        final endpoint = _plexEndpoint('monitor');
        final connectivity = _DirectConnectivityStream();
        final server = _ControlledPlexServer(
          serverId: 'monitor-server',
          endpoints: [endpoint],
          discoveryStreams: [() => Stream.value(endpoint)],
        );
        final factory = _RecordingPlexFactory();
        final manager = MultiServerManager(plexClientFactory: factory.create, connectivityChanges: () => connectivity);
        addTearDown(manager.dispose);

        expect(connectivity.listenCount, 0);
        final bound = await manager.refreshTokensForProfile(
          _plexAccount('monitor-account', [server]),
          profileId: 'profile-a',
        );
        expect(bound, {'monitor-server'});
        expect(connectivity.listenCount, 1);
        expect(server.discoveryCalls, 1);

        final secondBound = await manager.refreshTokensForProfile(
          _plexAccount('monitor-account', [server]),
          profileId: 'profile-a',
        );
        expect(secondBound, {'monitor-server'});
        expect(connectivity.listenCount, 1);
        expect(factory.calls, hasLength(1));

        fakeAsync((async) {
          connectivity.add([ConnectivityResult.none]);
          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 3));
          async.flushMicrotasks();
          expect(server.discoveryCalls, 1);
          expect(factory.requests['monitor-server']!.map((request) => request.url.path), ['/', '/media/providers']);

          connectivity.add([ConnectivityResult.wifi]);
          connectivity.add([ConnectivityResult.mobile]);
          async.flushMicrotasks();
          async.elapse(const Duration(milliseconds: 1999));
          async.flushMicrotasks();
          expect(server.discoveryCalls, 1);
          async.elapse(const Duration(milliseconds: 1));
          async.flushMicrotasks();

          expect(server.discoveryCalls, 2);
          expect(factory.requests['monitor-server']!.map((request) => request.url.path), [
            '/',
            '/media/providers',
            '/',
          ]);
          expect(connectivity.cancelCount, 0);
        });

        manager.dispose();
        expect(connectivity.cancelCount, 1);
      },
    );

    test('dispose cancels a pending connectivity debounce with no later mutation', () async {
      final storage = await _prepareFreshPlexManagerTest();
      final endpoint = _plexEndpoint('pending');
      final connectivity = _DirectConnectivityStream();
      final server = _ControlledPlexServer(
        serverId: 'pending-server',
        endpoints: [endpoint],
        discoveryStreams: [() => Stream.value(endpoint)],
      );
      final factory = _RecordingPlexFactory();
      final manager = MultiServerManager(plexClientFactory: factory.create, connectivityChanges: () => connectivity);
      expect(await manager.refreshTokensForProfile(_plexAccount('pending-account', [server]), profileId: 'profile-a'), {
        'pending-server',
      });

      fakeAsync((async) {
        connectivity.add([ConnectivityResult.wifi]);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        manager.dispose();
        async.flushMicrotasks();
        final callsAfterDispose = server.discoveryCalls;
        final persistedAfterDispose = storage.getServerEndpoint(ServerId('pending-server'));
        final requestCountAfterDispose = factory.requests['pending-server']!.length;

        async.elapse(const Duration(seconds: 10));
        async.flushMicrotasks();

        expect(connectivity.cancelCount, 1);
        expect(server.discoveryCalls, callsAfterDispose);
        expect(factory.requests['pending-server'], hasLength(requestCountAfterDispose));
        expect(storage.getServerEndpoint(ServerId('pending-server')), persistedAfterDispose);
        expect(manager.serverIds, isEmpty);
        expect(manager.onlineServerIds, isEmpty);
      });
    });
  });

  group('relay endpoint handling', () {
    test('a relay phase-1 winner is never persisted; a later direct promotion is', () async {
      final storage = await _prepareFreshPlexManagerTest();
      final direct = _plexEndpoint('direct');
      final relay = _plexRelayEndpoint('relay');
      final discoveries = StreamController<PlexConnection>(sync: true);
      final server = _ControlledPlexServer(
        serverId: 'relay-server',
        endpoints: [direct, relay],
        discoveryStreams: [() => discoveries.stream],
      );
      final factory = _RecordingPlexFactory();
      final manager = MultiServerManager(
        plexClientFactory: factory.create,
        connectivityChanges: () => const Stream.empty(),
      );
      addTearDown(manager.dispose);
      addTearDown(discoveries.close);

      final refresh = manager.refreshTokensForProfile(_plexAccount('relay-account', [server]), profileId: 'profile-a');
      await pumpEventQueue();
      discoveries.add(relay);
      expect(await refresh, {'relay-server'});
      await pumpEventQueue();

      final client = factory.clients['relay-server']!;
      expect(client.config.baseUrl, relay.uri);
      expect(storage.getServerEndpoint(ServerId('relay-server')), isNull);
      expect(manager.debugHasPendingRelayEscapeForTesting(ServerId('relay-server')), isTrue);

      discoveries.add(direct);
      await discoveries.close();
      await pumpEventQueue(times: 20);

      expect(client.config.baseUrl, direct.uri);
      expect(storage.getServerEndpoint(ServerId('relay-server')), direct.uri);
      expect(manager.debugHasPendingRelayEscapeForTesting(ServerId('relay-server')), isFalse);
    });

    test('failover onto a relay endpoint never overwrites the preferred endpoint', () async {
      final storage = await _prepareFreshPlexManagerTest();
      final direct = _plexEndpoint('failover-direct');
      final relay = _plexRelayEndpoint('failover-relay');
      final server = _ControlledPlexServer(
        serverId: 'failover-server',
        endpoints: [direct, relay],
        discoveryStreams: [() => Stream.value(direct)],
      );
      final factory = _RecordingPlexFactory();
      final manager = MultiServerManager(
        plexClientFactory: factory.create,
        connectivityChanges: () => const Stream.empty(),
      );
      addTearDown(manager.dispose);

      expect(
        await manager.refreshTokensForProfile(_plexAccount('failover-account', [server]), profileId: 'profile-a'),
        {'failover-server'},
      );
      await pumpEventQueue(times: 20);
      expect(storage.getServerEndpoint(ServerId('failover-server')), direct.uri);

      // Mid-session failover walks onto the relay candidate: the client may
      // use it, but it must not become the next bind's head-start endpoint.
      final onEndpointChanged = factory.calls.single.endpointChanged!;
      await onEndpointChanged(relay.uri);
      expect(storage.getServerEndpoint(ServerId('failover-server')), direct.uri);

      // Reverse rotation (PR #1974 review): a profile refresh rotates the
      // relay URI away, then the old relay URL reports a late failover
      // switch. The live server no longer lists it — the custom-hostname
      // fallback alone would classify it as remote — but the connect-time
      // capture still recognizes it as relay.
      final rotated = _ControlledPlexServer(
        serverId: 'failover-server',
        endpoints: [direct, _plexRelayEndpoint('rotated-relay')],
        discoveryStreams: [() => Stream.value(direct)],
      );
      expect(
        await manager.refreshTokensForProfile(_plexAccount('failover-account', [rotated]), profileId: 'profile-a'),
        {'failover-server'},
      );
      await onEndpointChanged(relay.uri);
      expect(storage.getServerEndpoint(ServerId('failover-server')), direct.uri);
    });

    test('a relay session re-probes on backoff and promotes a returning direct endpoint', () async {
      final storage = await _prepareFreshPlexManagerTest();
      final direct = _plexEndpoint('escape-direct');
      final relay = _plexRelayEndpoint('escape-relay');
      final server = _ControlledPlexServer(
        serverId: 'escape-server',
        endpoints: [direct, relay],
        discoveryStreams: [
          () => Stream.value(relay), // bind: only relay answers
          () => Stream.value(relay), // first escape probe: still relay-only
          () => Stream.value(direct), // second escape probe: direct is back
        ],
      );
      final factory = _RecordingPlexFactory();
      final manager = MultiServerManager(
        plexClientFactory: factory.create,
        connectivityChanges: () => const Stream.empty(),
      );
      addTearDown(manager.dispose);

      expect(await manager.refreshTokensForProfile(_plexAccount('escape-account', [server]), profileId: 'profile-a'), {
        'escape-server',
      });
      await pumpEventQueue(times: 20);
      final client = factory.clients['escape-server']!;
      expect(client.config.baseUrl, relay.uri);
      expect(server.discoveryCalls, 1);
      expect(manager.debugHasPendingRelayEscapeForTesting(ServerId('escape-server')), isTrue);

      fakeAsync((async) {
        // Fire the bind-scheduled probe (its real timer lives outside this zone).
        unawaited(manager.debugFireRelayEscapeForTesting(ServerId('escape-server')));
        async.flushMicrotasks();
        expect(server.discoveryCalls, 2);
        expect(client.config.baseUrl, relay.uri);

        // Still relay-only: rescheduled with a doubled backoff (30s -> 60s).
        async.elapse(const Duration(seconds: 60) - const Duration(milliseconds: 1));
        async.flushMicrotasks();
        expect(server.discoveryCalls, 2);
        async.elapse(const Duration(milliseconds: 1));
        async.flushMicrotasks();

        expect(server.discoveryCalls, 3);
        expect(client.config.baseUrl, direct.uri);
        expect(storage.getServerEndpoint(ServerId('escape-server')), direct.uri);
        expect(manager.debugHasPendingRelayEscapeForTesting(ServerId('escape-server')), isFalse);

        // Off relay: the prober stays stopped.
        async.elapse(const Duration(minutes: 10));
        async.flushMicrotasks();
        expect(server.discoveryCalls, 3);
      });
    });

    test('removing a relay-connected server cancels its escape prober', () async {
      await _prepareFreshPlexManagerTest();
      final relay = _plexRelayEndpoint('removed-relay');
      final server = _ControlledPlexServer(
        serverId: 'removed-server',
        endpoints: [_plexEndpoint('removed-direct'), relay],
        discoveryStreams: [() => Stream.value(relay)],
      );
      final factory = _RecordingPlexFactory();
      final manager = MultiServerManager(
        plexClientFactory: factory.create,
        connectivityChanges: () => const Stream.empty(),
      );
      addTearDown(manager.dispose);

      expect(await manager.refreshTokensForProfile(_plexAccount('removed-account', [server]), profileId: 'profile-a'), {
        'removed-server',
      });
      await pumpEventQueue(times: 20);
      expect(manager.debugHasPendingRelayEscapeForTesting(ServerId('removed-server')), isTrue);

      manager.removeServer(ServerId('removed-server'));
      expect(manager.debugHasPendingRelayEscapeForTesting(ServerId('removed-server')), isFalse);
      expect(server.discoveryCalls, 1);
    });
  });

  group('Jellyfin connection updates', () {
    test('persists refreshed admin status discovered during health checks', () async {
      final persisted = <JellyfinConnection>[];
      final persistStarted = Completer<void>();
      final allowPersist = Completer<void>();
      final client = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a'),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/Users/Me');
          return http.Response(
            '{"Policy":{"IsAdministrator":true}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);
      final m = MultiServerManager()
        ..onJellyfinConnectionUpdated = (connection) async {
          persistStarted.complete();
          await allowPersist.future;
          persisted.add(connection);
        };
      addTearDown(m.dispose);
      m.debugRegisterJellyfinClientForTesting(client);

      final healthFuture = m.checkServerHealth();
      await persistStarted.future;
      expect(persisted, isEmpty);
      allowPersist.complete();
      await healthFuture;

      expect(persisted, hasLength(1));
      expect(persisted.single.isAdministrator, isTrue);
    });

    test('persists a changed profile picture tag discovered during health checks', () async {
      final persisted = <JellyfinConnection>[];
      var requestCount = 0;
      final client = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a').copyWith(primaryImageTag: 'cached-tag'),
        httpClient: MockClient((request) async {
          requestCount++;
          expect(request.url.path, '/Users/Me');
          return http.Response(
            '{"Policy":{"IsAdministrator":false},"PrimaryImageTag":"fresh-tag"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);
      final m = MultiServerManager()..onJellyfinConnectionUpdated = persisted.add;
      addTearDown(m.dispose);
      m.debugRegisterJellyfinClientForTesting(client);

      final status = await client.checkHealth();

      expect(status, HealthStatus.online);
      expect(requestCount, 1);
      expect(persisted, hasLength(1));
      expect(persisted.single.primaryImageTag, 'fresh-tag');
    });

    test('clears the cached profile picture tag when the user deletes their avatar', () async {
      final persisted = <JellyfinConnection>[];
      var requestCount = 0;
      final client = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a').copyWith(primaryImageTag: 'cached-tag'),
        httpClient: MockClient((request) async {
          requestCount++;
          expect(request.url.path, '/Users/Me');
          return http.Response(
            '{"Policy":{"IsAdministrator":false}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);
      final m = MultiServerManager()..onJellyfinConnectionUpdated = persisted.add;
      addTearDown(m.dispose);
      m.debugRegisterJellyfinClientForTesting(client);

      final status = await client.checkHealth();

      expect(status, HealthStatus.online);
      expect(requestCount, 1);
      expect(persisted, hasLength(1));
      expect(persisted.single.primaryImageTag, isNull);
    });

    test('does not persist when the admin flag and profile picture tag are unchanged', () async {
      final persisted = <JellyfinConnection>[];
      var requestCount = 0;
      final client = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a').copyWith(primaryImageTag: 'same-tag'),
        httpClient: MockClient((request) async {
          requestCount++;
          expect(request.url.path, '/Users/Me');
          return http.Response(
            '{"Policy":{"IsAdministrator":false},"PrimaryImageTag":"same-tag"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);
      final m = MultiServerManager()..onJellyfinConnectionUpdated = persisted.add;
      addTearDown(m.dispose);
      m.debugRegisterJellyfinClientForTesting(client);

      final status = await client.checkHealth();

      expect(status, HealthStatus.online);
      expect(requestCount, 1);
      expect(persisted, isEmpty);
    });

    test('persists one connection update when the admin flag and profile picture tag both change', () async {
      final persisted = <JellyfinConnection>[];
      var requestCount = 0;
      final client = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a').copyWith(primaryImageTag: 'cached-tag'),
        httpClient: MockClient((request) async {
          requestCount++;
          expect(request.url.path, '/Users/Me');
          return http.Response(
            '{"Policy":{"IsAdministrator":true},"PrimaryImageTag":"fresh-tag"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);
      final m = MultiServerManager()..onJellyfinConnectionUpdated = persisted.add;
      addTearDown(m.dispose);
      m.debugRegisterJellyfinClientForTesting(client);

      final status = await client.checkHealth();

      expect(status, HealthStatus.online);
      expect(requestCount, 1);
      expect(persisted, hasLength(1));
      expect(persisted.single.isAdministrator, isTrue);
      expect(persisted.single.primaryImageTag, 'fresh-tag');
    });

    test('refreshes the profile picture tag when Policy is missing or malformed', () async {
      final responses = <Map<String, Object?>>[
        {'PrimaryImageTag': 'fresh-tag'},
        {'Policy': 'not-a-map', 'PrimaryImageTag': 'fresh-tag'},
      ];

      for (final responseBody in responses) {
        final persisted = <JellyfinConnection>[];
        var requestCount = 0;
        final client = JellyfinClient.forTesting(
          connection: _jellyfinConnection('user-a').copyWith(primaryImageTag: 'cached-tag'),
          httpClient: MockClient((request) async {
            requestCount++;
            expect(request.url.path, '/Users/Me');
            return http.Response(jsonEncode(responseBody), 200, headers: {'content-type': 'application/json'});
          }),
        );
        addTearDown(client.close);
        final m = MultiServerManager()..onJellyfinConnectionUpdated = persisted.add;
        addTearDown(m.dispose);
        m.debugRegisterJellyfinClientForTesting(client);

        final status = await client.checkHealth();

        expect(status, HealthStatus.online, reason: 'response: $responseBody');
        expect(requestCount, 1, reason: 'response: $responseBody');
        expect(persisted, hasLength(1), reason: 'response: $responseBody');
        expect(persisted.single.primaryImageTag, 'fresh-tag', reason: 'response: $responseBody');
        expect(persisted.single.isAdministrator, isFalse, reason: 'response: $responseBody');
      }
    });

    test('health remains online when persisting refreshed admin status fails', () async {
      final client = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a'),
        httpClient: MockClient(
          (_) async =>
              http.Response('{"Policy":{"IsAdministrator":true}}', 200, headers: {'content-type': 'application/json'}),
        ),
      );
      addTearDown(client.close);
      final m = MultiServerManager()
        ..onJellyfinConnectionUpdated = (_) async {
          throw Exception('disk full');
        };
      addTearDown(m.dispose);
      m.debugRegisterJellyfinClientForTesting(client);

      await m.checkServerHealth();

      expect(m.isServerOnline(ServerId('jf-machine')), isTrue);
      expect(m.isOwnerOrAdmin(ServerId('jf-machine')), isTrue);
    });

    test('ignores stale admin-status persistence from a replaced Jellyfin client', () async {
      final persisted = <JellyfinConnection>[];
      final requestStarted = Completer<void>();
      final allowResponse = Completer<void>();
      final oldClient = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a'),
        httpClient: MockClient((_) async {
          requestStarted.complete();
          await allowResponse.future;
          return http.Response(
            '{"Policy":{"IsAdministrator":true}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final newClient = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a').copyWith(accessToken: 'new-token'),
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      addTearDown(oldClient.close);
      final m = MultiServerManager()..onJellyfinConnectionUpdated = persisted.add;
      addTearDown(m.dispose);

      m.debugRegisterJellyfinClientForTesting(oldClient);
      final healthFuture = m.checkServerHealth();
      await requestStarted.future;
      m.debugRegisterJellyfinClientForTesting(newClient);
      allowResponse.complete();
      await healthFuture;

      expect(persisted, isEmpty);
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-a'), same(newClient));
    });

    test('ignores stale health status when active Jellyfin user changes mid-check', () async {
      final requestStarted = Completer<void>();
      final allowResponse = Completer<void>();
      final userA = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a'),
        httpClient: MockClient((_) async {
          requestStarted.complete();
          await allowResponse.future;
          return http.Response('', 403);
        }),
      );
      final userB = _jellyfinClient('user-b');
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.debugRegisterJellyfinClientForTesting(userA);
      final healthFuture = m.checkServerHealth();
      await requestStarted.future;
      m.debugRegisterJellyfinClientForTesting(userB, online: true);
      allowResponse.complete();
      await healthFuture;

      expect(m.getClient(ServerId('jf-machine')), same(userB));
      expect(m.isServerOnline(ServerId('jf-machine')), isTrue);
      expect(m.authErrorServerIds, isNot(contains('jf-machine')));
    });
  });

  group('addJellyfinConnection endpoint trust admission', () {
    test('historic wrong-machine alternate is removed before authenticated health', () async {
      final previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousHttpOverrides);
      final events = <String>[];
      final active = await _LoopbackJellyfinServer.start(
        machineId: 'jf-machine',
        onRequest: (path) => events.add('active:$path'),
      );
      final wrong = await _LoopbackJellyfinServer.start(
        machineId: 'different-machine',
        onRequest: (path) => events.add('wrong:$path'),
      );
      addTearDown(active.close);
      addTearDown(wrong.close);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final registry = ConnectionRegistry(db);
      addTearDown(db.close);
      final historic = _jellyfinConnection(
        'user-a',
      ).copyWith(baseUrl: active.baseUrl, baseUrls: [active.baseUrl, wrong.baseUrl]);
      await registry.upsert(historic);

      final manager = MultiServerManager()
        ..onJellyfinConnectionUpdated = (connection) async {
          await registry.upsert(connection);
          events.add('persist');
        };
      addTearDown(manager.dispose);

      expect(await manager.addJellyfinConnection(historic), isTrue);

      final live = manager.getJellyfinClientByCompoundId(historic.id)!;
      final stored = await registry.get(historic.id) as JellyfinConnection;
      expect(live.connection.baseUrls, [active.baseUrl]);
      expect(stored.baseUrls, [active.baseUrl]);
      expect(events.indexOf('persist'), greaterThanOrEqualTo(0));
      expect(events.indexOf('persist'), lessThan(events.indexOf('active:/Users/Me')));
      expect(wrong.requests, isNotEmpty);
      expect(wrong.requests, everyElement((path: '/System/Info/Public', authenticated: false)));
    });

    test('partial success retains an unavailable historic alternate and re-admits it on failover', () async {
      final previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousHttpOverrides);
      final active = await _LoopbackJellyfinServer.start(machineId: 'jf-machine');
      final fallback = await _LoopbackJellyfinServer.start(machineId: 'jf-machine', publicInfoAvailable: false);
      final wrong = await _LoopbackJellyfinServer.start(machineId: 'different-machine');
      addTearDown(active.close);
      addTearDown(fallback.close);
      addTearDown(wrong.close);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final registry = ConnectionRegistry(db);
      addTearDown(db.close);
      final historic = _jellyfinConnection(
        'user-a',
      ).copyWith(baseUrl: active.baseUrl, baseUrls: [active.baseUrl, fallback.baseUrl, wrong.baseUrl]);
      await registry.upsert(historic);

      final manager = MultiServerManager()..onJellyfinConnectionUpdated = registry.upsert;
      addTearDown(manager.dispose);

      expect(await manager.addJellyfinConnection(historic), isTrue);

      final live = manager.getJellyfinClientByCompoundId(historic.id)!;
      var stored = await registry.get(historic.id) as JellyfinConnection;
      expect(live.connection.baseUrls, [active.baseUrl, fallback.baseUrl]);
      expect(stored.baseUrls, [active.baseUrl, fallback.baseUrl]);
      expect(wrong.requests, isNotEmpty);
      expect(wrong.requests, everyElement((path: '/System/Info/Public', authenticated: false)));

      final fallbackRequestsBeforeFailover = fallback.requests.length;
      fallback.publicInfoAvailable = true;
      await active.close();

      expect(await live.getMachineIdentifier(), 'jf-machine');

      expect(fallback.requests.skip(fallbackRequestsBeforeFailover), [
        (path: '/System/Info/Public', authenticated: false),
        (path: '/System/Info/Public', authenticated: true),
      ]);
      expect(live.connection.baseUrl, fallback.baseUrl);
      stored = await registry.get(historic.id) as JellyfinConnection;
      expect(stored.baseUrl, fallback.baseUrl);
      expect(stored.baseUrls, [fallback.baseUrl, active.baseUrl]);
    });

    test('unvalidated endpoint race preserves full persisted fallback set during admin refresh', () async {
      final previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousHttpOverrides);
      final active = await _LoopbackJellyfinServer.start(machineId: 'different-machine', isAdministrator: true);
      final fallback = await _LoopbackJellyfinServer.start(machineId: 'different-machine');
      addTearDown(active.close);
      addTearDown(fallback.close);

      final historic = _jellyfinConnection(
        'user-a',
      ).copyWith(baseUrl: active.baseUrl, baseUrls: [active.baseUrl, fallback.baseUrl]);
      final updates = <JellyfinConnection>[];
      final manager = MultiServerManager()..onJellyfinConnectionUpdated = updates.add;
      addTearDown(manager.dispose);

      expect(await manager.addJellyfinConnection(historic), isTrue);

      final live = manager.getJellyfinClientByCompoundId(historic.id)!;
      expect(live.connection.baseUrls, [active.baseUrl]);
      expect(live.connection.isAdministrator, isTrue);
      expect(updates, hasLength(1));
      expect(updates.single.isAdministrator, isTrue);
      expect(updates.single.baseUrls, [active.baseUrl, fallback.baseUrl]);
    });

    test('same-machine pair remains eligible for validated authenticated failover', () async {
      final previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousHttpOverrides);
      final active = await _LoopbackJellyfinServer.start(machineId: 'jf-machine');
      final fallback = await _LoopbackJellyfinServer.start(
        machineId: 'jf-machine',
        responseDelay: const Duration(milliseconds: 20),
      );
      addTearDown(active.close);
      addTearDown(fallback.close);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final registry = ConnectionRegistry(db);
      addTearDown(db.close);
      final historic = _jellyfinConnection(
        'user-a',
      ).copyWith(baseUrl: active.baseUrl, baseUrls: [active.baseUrl, fallback.baseUrl]);
      await registry.upsert(historic);

      final manager = MultiServerManager()..onJellyfinConnectionUpdated = registry.upsert;
      addTearDown(manager.dispose);

      expect(await manager.addJellyfinConnection(historic), isTrue);
      final live = manager.getJellyfinClientByCompoundId(historic.id)!;
      expect(live.connection.baseUrls, [active.baseUrl, fallback.baseUrl]);

      final fallbackRequestsBeforeFailover = fallback.requests.length;
      await active.close();

      expect(await live.getMachineIdentifier(), 'jf-machine');

      final failoverRequests = fallback.requests.skip(fallbackRequestsBeforeFailover).toList();
      expect(failoverRequests, [
        (path: '/System/Info/Public', authenticated: false),
        (path: '/System/Info/Public', authenticated: true),
      ]);
      expect(live.connection.baseUrl, fallback.baseUrl);
      final stored = await registry.get(historic.id) as JellyfinConnection;
      expect(stored.baseUrl, fallback.baseUrl);
      expect(stored.baseUrls, [fallback.baseUrl, active.baseUrl]);
    });

    test('persistence failure never restores rejected alternates in memory', () async {
      final previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousHttpOverrides);
      final active = await _LoopbackJellyfinServer.start(machineId: 'jf-machine');
      final wrong = await _LoopbackJellyfinServer.start(machineId: 'different-machine');
      addTearDown(active.close);
      addTearDown(wrong.close);

      final historic = _jellyfinConnection(
        'user-a',
      ).copyWith(baseUrl: active.baseUrl, baseUrls: [active.baseUrl, wrong.baseUrl]);
      final updates = <JellyfinConnection>[];
      final manager = MultiServerManager()
        ..onJellyfinConnectionUpdated = (connection) async {
          updates.add(connection);
          throw StateError('persistence unavailable');
        };
      addTearDown(manager.dispose);

      expect(await manager.addJellyfinConnection(historic), isTrue);

      expect(updates, hasLength(1));
      expect(updates.single.baseUrls, [active.baseUrl]);
      final live = manager.getJellyfinClientByCompoundId(historic.id)!;
      expect(live.connection.baseUrls, [active.baseUrl]);
      expect(wrong.requests, everyElement((path: '/System/Info/Public', authenticated: false)));
    });
  });

  group('addJellyfinConnection reuse', () {
    // The reuse branch is what keeps a passive rebind (re-adding the same
    // persisted connection) from tearing down a live client and aborting its
    // in-flight requests. The identity assertions are load-bearing: any
    // recreation implies the prior client was closed.
    test('re-adding an identical connection reuses the live client', () async {
      var probes = 0;
      final client = JellyfinClient.forTesting(
        connection: _jellyfinConnection('user-a'),
        httpClient: MockClient((request) async {
          probes++;
          expect(request.url.path, '/Users/Me');
          return http.Response('{}', 200, headers: {'content-type': 'application/json'});
        }),
      );
      addTearDown(client.close);
      final m = MultiServerManager();
      addTearDown(m.dispose);
      m.debugRegisterJellyfinClientForTesting(client);

      final healthy = await m.addJellyfinConnection(_jellyfinConnection('user-a'));

      expect(healthy, isTrue);
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-a'), same(client));
      expect(m.getClient(ServerId('jf-machine')), same(client));
      // One fresh health probe on the existing client; no recreation.
      expect(probes, 1);
    });

    test('reuse rebinds an inactive compound client without closing the active one', () async {
      JellyfinClient clientFor(String userId) => JellyfinClient.forTesting(
        connection: _jellyfinConnection(userId),
        httpClient: MockClient((_) async => http.Response('{}', 200, headers: {'content-type': 'application/json'})),
      );
      final userA = clientFor('user-a');
      final userB = clientFor('user-b');
      addTearDown(userA.close);
      addTearDown(userB.close);
      final m = MultiServerManager();
      addTearDown(m.dispose);
      m.debugRegisterJellyfinClientForTesting(userA);
      m.debugRegisterJellyfinClientForTesting(userB); // takes the machine slot

      await m.addJellyfinConnection(_jellyfinConnection('user-a'));

      expect(m.getClient(ServerId('jf-machine')), same(userA));
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-a'), same(userA));
      // The other user's client stays registered for a future switch back.
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-b'), same(userB));
    });
  });

  group('canReuseJellyfinClient', () {
    // A false verdict routes addJellyfinConnection to the pre-existing
    // replace path (covered by 'ignores stale admin-status persistence from
    // a replaced Jellyfin client' above).
    final base = _jellyfinConnection('user-a');

    test('identical connection is reusable', () {
      expect(MultiServerManager.canReuseJellyfinClient(live: base, incoming: _jellyfinConnection('user-a')), isTrue);
    });

    test('changed access token requires recreation', () {
      expect(
        MultiServerManager.canReuseJellyfinClient(
          live: base,
          incoming: base.copyWith(accessToken: 'rotated'),
        ),
        isFalse,
      );
    });

    test('changed device id requires recreation', () {
      expect(
        MultiServerManager.canReuseJellyfinClient(
          live: base,
          incoming: base.copyWith(deviceId: 'other-device'),
        ),
        isFalse,
      );
    });

    test('same URL set with a different active URL is reusable', () {
      // The live client rotates its active endpoint on its own; the add-path
      // race reorders the candidate list. Neither warrants a teardown.
      final live = base.copyWith(
        baseUrl: 'https://a.example.com',
        baseUrls: ['https://a.example.com', 'https://b.example.com'],
      );
      final incoming = base.copyWith(
        baseUrl: 'https://b.example.com',
        baseUrls: ['https://b.example.com', 'https://a.example.com'],
      );
      expect(MultiServerManager.canReuseJellyfinClient(live: live, incoming: incoming), isTrue);
    });

    test('an added or removed URL requires recreation', () {
      final twoUrls = base.copyWith(baseUrls: ['https://jf.example.com', 'https://alt.example.com']);
      expect(MultiServerManager.canReuseJellyfinClient(live: twoUrls, incoming: base), isFalse);
      expect(MultiServerManager.canReuseJellyfinClient(live: base, incoming: twoUrls), isFalse);
    });
  });

  group('removeServer', () {
    test('removes a tracked server\'s status entry and emits a snapshot', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.updateServerStatus(ServerId('srv-1'), true);
      m.updateServerStatus(ServerId('srv-2'), true);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      m.removeServer(ServerId('srv-1'));
      await Future<void>.delayed(Duration.zero);

      expect(m.serverIds, isNot(contains('srv-1')));
      expect(emitted, isNotEmpty);
      expect(emitted.last, {'srv-2': true});
    });

    test('removing an unknown id still emits a snapshot (does not throw)', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      m.removeServer(ServerId('never-added'));
      await Future<void>.delayed(Duration.zero);

      // Doesn't throw; state stays empty; one snapshot fires.
      expect(m.serverIds, isEmpty);
      expect(emitted, hasLength(1));
      expect(emitted.first, isEmpty);
    });

    test('removing a Jellyfin machine clears every scoped user client', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.debugRegisterJellyfinClientForTesting(_jellyfinClient('user-a'));
      m.debugRegisterJellyfinClientForTesting(_jellyfinClient('user-b'));

      expect(m.getJellyfinClientByCompoundId('jf-machine/user-a'), isNotNull);
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-b'), isNotNull);

      m.removeServer(ServerId('jf-machine'));

      expect(m.getClient(ServerId('jf-machine')), isNull);
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-a'), isNull);
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-b'), isNull);
    });
  });

  group('disconnectAll', () {
    test('clears all status and emits an empty snapshot', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.updateServerStatus(ServerId('a'), true);
      m.updateServerStatus(ServerId('b'), false);

      final emitted = <Map<String, bool>>[];
      final sub = m.statusStream.listen(emitted.add);
      addTearDown(sub.cancel);

      m.disconnectAll();
      await Future<void>.delayed(Duration.zero);

      expect(m.serverIds, isEmpty);
      expect(m.onlineServerIds, isEmpty);
      expect(m.offlineServerIds, isEmpty);
      expect(emitted.last, isEmpty);
    });

    test('clears inactive Jellyfin scoped clients', () {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.debugRegisterJellyfinClientForTesting(_jellyfinClient('user-a'));
      m.debugRegisterJellyfinClientForTesting(_jellyfinClient('user-b'));

      m.disconnectAll();

      expect(m.getClient(ServerId('jf-machine')), isNull);
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-a'), isNull);
      expect(m.getJellyfinClientByCompoundId('jf-machine/user-b'), isNull);
    });
  });

  group('shutdown', () {
    test('clears all state without emitting a snapshot and closes the stream', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.updateServerStatus(ServerId('a'), true);
      m.updateServerStatus(ServerId('b'), false);

      final emitted = <Map<String, bool>>[];
      var done = false;
      final sub = m.statusStream.listen(emitted.add, onDone: () => done = true);
      addTearDown(sub.cancel);

      await m.shutdown();
      await Future<void>.delayed(Duration.zero);

      // Exit teardown must stay invisible: an empty snapshot would flip the
      // still-mounted UI into offline mode while the app shuts down.
      expect(m.serverIds, isEmpty);
      expect(m.onlineServerIds, isEmpty);
      expect(m.offlineServerIds, isEmpty);
      expect(emitted, isEmpty);
      expect(done, isTrue);
    });

    test('a health result landing after shutdown is a silent no-op', () async {
      final m = MultiServerManager();
      addTearDown(m.dispose);

      m.updateServerStatus(ServerId('a'), true);
      await m.shutdown();

      // A probe that was in flight when the exit began must not throw into
      // the closed status controller.
      expect(() => m.updateServerStatus(ServerId('a'), false), returnsNormally);
    });
  });

  group('dispose', () {
    test('disposing without connectivity monitoring does not throw', () {
      final m = MultiServerManager();
      // No startNetworkMonitoring call → _connectivitySubscription is null.
      // dispose() must handle the null-subscription path cleanly.
      expect(m.dispose, returnsNormally);
    });

    test('dispose closes the status stream (existing subscribers get onDone)', () async {
      final m = MultiServerManager();
      var done = false;
      final sub = m.statusStream.listen((_) {}, onDone: () => done = true);
      m.dispose();
      // Allow the close event to propagate.
      await Future<void>.delayed(Duration.zero);
      expect(done, isTrue);
      await sub.cancel();
    });
  });
}

PlexConnection _plexEndpoint(String label) => PlexConnection(
  protocol: 'https',
  address: '$label.invalid',
  port: 32400,
  uri: 'https://$label.invalid:32400',
  local: true,
  relay: false,
  ipv6: false,
);

/// Mirrors a plex.tv relay connection: remote, `relay: true`.
PlexConnection _plexRelayEndpoint(String label) => PlexConnection(
  protocol: 'https',
  address: '$label.invalid',
  port: 8443,
  uri: 'https://$label.invalid:8443',
  local: false,
  relay: true,
  ipv6: false,
);

class _ControlledPlexServer extends PlexServer {
  _ControlledPlexServer({
    required String serverId,
    required List<PlexConnection> endpoints,
    required this.discoveryStreams,
  }) : super(name: serverId, clientIdentifier: serverId, accessToken: 'redacted', connections: endpoints, owned: true);

  final List<Stream<PlexConnection> Function()> discoveryStreams;
  int discoveryCalls = 0;

  @override
  Stream<PlexConnection> findBestWorkingConnection({
    String? preferredUri,
    String? clientIdentifier,
    void Function(bool)? onTranscoderCapability,
  }) {
    onTranscoderCapability?.call(true);
    final index = discoveryCalls++;
    if (discoveryStreams.isEmpty) return const Stream.empty();
    return discoveryStreams[index.clamp(0, discoveryStreams.length - 1)]();
  }
}

class _PlexFactoryCall {
  const _PlexFactoryCall({
    required this.config,
    required this.serverId,
    required this.profileScopeId,
    required this.prioritizedEndpoints,
    required this.endpointChanged,
    required this.hasExhaustionCallback,
    required this.seedTranscoderVideoSupport,
  });

  final PlexConfig config;
  final ServerId serverId;
  final PlexProfileScopeId profileScopeId;
  final List<String>? prioritizedEndpoints;
  final Future<void> Function(String newBaseUrl)? endpointChanged;
  final bool hasExhaustionCallback;
  final bool? seedTranscoderVideoSupport;

  bool get hasEndpointCallback => endpointChanged != null;
}

class _RecordingPlexFactory {
  _RecordingPlexFactory({this.failingServerIds = const {}});

  final Set<String> failingServerIds;
  final calls = <_PlexFactoryCall>[];
  final clients = <String, PlexClient>{};
  final requests = <String, List<http.Request>>{};

  Future<PlexClient> create(
    PlexConfig config, {
    required ServerId serverId,
    required PlexProfileScopeId profileScopeId,
    String? serverName,
    List<String>? prioritizedEndpoints,
    Future<void> Function(String newBaseUrl)? onEndpointChanged,
    void Function()? onAllEndpointsExhausted,
    bool? seedTranscoderVideoSupport,
  }) async {
    calls.add(
      _PlexFactoryCall(
        config: config,
        serverId: serverId,
        profileScopeId: profileScopeId,
        prioritizedEndpoints: prioritizedEndpoints,
        endpointChanged: onEndpointChanged,
        hasExhaustionCallback: onAllEndpointsExhausted != null,
        seedTranscoderVideoSupport: seedTranscoderVideoSupport,
      ),
    );
    if (failingServerIds.contains(serverId)) {
      throw StateError('injected client creation failure');
    }
    final serverRequests = requests.putIfAbsent(serverId, () => []);
    final client = PlexClient.forTesting(
      config: config,
      serverId: serverId,
      profileScopeId: profileScopeId,
      serverName: serverName,
      prioritizedEndpoints: prioritizedEndpoints,
      httpClient: MockClient((request) async {
        serverRequests.add(request);
        final body = request.url.path == '/'
            ? {
                'MediaContainer': {'machineIdentifier': serverId},
              }
            : <String, dynamic>{};
        return http.Response(jsonEncode(body), 200, headers: const {'content-type': 'application/json'});
      }),
    );
    clients[serverId] = client;
    return client;
  }
}

PlexAccountConnection _plexAccount(String accountId, List<PlexServer> servers) => PlexAccountConnection(
  id: accountId,
  accountToken: 'redacted',
  clientIdentifier: 'test-client',
  accountLabel: accountId,
  servers: servers,
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

Future<StorageService> _prepareFreshPlexManagerTest() async {
  PackageInfo.setMockInitialValues(
    appName: 'Plezy',
    packageName: 'com.example.plezy',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  DeviceIdentityService.debugOverride(const DeviceIdentity(platform: 'Test'));
  addTearDown(() => DeviceIdentityService.debugOverride(null));
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  PlexApiCache.initialize(db);
  addTearDown(db.close);
  return StorageService.getInstance();
}

class _DirectConnectivityStream extends Stream<List<ConnectivityResult>> {
  void Function(List<ConnectivityResult>)? _onData;
  int listenCount = 0;
  int cancelCount = 0;

  void add(List<ConnectivityResult> value) => _onData?.call(value);

  @override
  StreamSubscription<List<ConnectivityResult>> listen(
    void Function(List<ConnectivityResult> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    listenCount++;
    _onData = onData;
    return _TrackedStreamSubscription<List<ConnectivityResult>>(
      const Stream<List<ConnectivityResult>>.empty().listen(null),
      () {
        cancelCount++;
        _onData = null;
      },
    );
  }
}

class _TrackedStreamSubscription<T> implements StreamSubscription<T> {
  _TrackedStreamSubscription(this._delegate, this._onCancel);

  final StreamSubscription<T> _delegate;
  final void Function() _onCancel;
  bool _cancelled = false;

  @override
  Future<void> cancel() {
    if (!_cancelled) {
      _cancelled = true;
      _onCancel();
    }
    return _delegate.cancel();
  }

  @override
  void onData(void Function(T data)? handleData) => _delegate.onData(handleData);

  @override
  void onError(Function? handleError) => _delegate.onError(handleError);

  @override
  void onDone(void Function()? handleDone) => _delegate.onDone(handleDone);

  @override
  void pause([Future<void>? resumeSignal]) => _delegate.pause(resumeSignal);

  @override
  void resume() => _delegate.resume();

  @override
  bool get isPaused => _delegate.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => _delegate.asFuture(futureValue);
}
