import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/connection/connection.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/library_change_event.dart';
import 'package:plezy/services/library_events/library_event_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/utils/active_client_scope.dart';
import 'package:plezy/utils/deletion_notifier.dart';
import 'package:plezy/utils/library_content_notifier.dart';

import '../../test_helpers/backend_client_fixtures.dart';

class _RequestGate {
  final started = Completer<void>();
  final release = Completer<void>();

  Future<void> wait() {
    if (!started.isCompleted) started.complete();
    return release.future;
  }

  void open() {
    if (!release.isCompleted) release.complete();
  }
}

class _PushConnection {
  _PushConnection(this.token, this.socket) {
    socket.listen((_) {}, onDone: closed.complete);
  }

  final String? token;
  final WebSocket socket;
  final closed = Completer<void>();

  void removeItems(List<String> ids) {
    socket.add(
      jsonEncode({
        'NotificationContainer': {
          'type': 'timeline',
          'TimelineEntry': [
            for (final id in ids)
              {
                'identifier': 'com.plexapp.plugins.library',
                'sectionID': 'movies',
                'itemID': id,
                'type': -1,
                'state': 5,
              },
          ],
        },
      }),
    );
  }
}

/// Real HTTP validation and websocket upgrades share one ephemeral Plex
/// endpoint. Gates hold requests, never the client's commit implementation.
class _PlexPushServer {
  _PlexPushServer._(this._server, this.serverId);

  final HttpServer _server;
  final ServerId serverId;
  final connections = <_PushConnection>[];
  final upgradeTokens = <String?>[];
  final rejectedTokens = <String>{};
  final identityGates = <String, _RequestGate>{};
  final _upgradeGates = <_RequestGate>[];
  _RequestGate? holdNextUpgrade;
  bool _closed = false;

  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  static Future<_PlexPushServer> start(String serverId) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixture = _PlexPushServer._(server, ServerId(serverId));
    server.listen(fixture._handle);
    return fixture;
  }

  Future<void> _handle(HttpRequest request) async {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final token = request.uri.queryParameters['X-Plex-Token'];
      upgradeTokens.add(token);
      final gate = holdNextUpgrade;
      holdNextUpgrade = null;
      if (gate != null) {
        _upgradeGates.add(gate);
        await gate.wait();
      }
      if (_closed) {
        await request.response.close();
        return;
      }
      connections.add(_PushConnection(token, await WebSocketTransformer.upgrade(request)));
      return;
    }

    final token = request.headers.value('X-Plex-Token');
    if (request.uri.path == '/') {
      await identityGates[token]?.wait();
    }
    if (rejectedTokens.contains(token)) {
      request.response.statusCode = HttpStatus.unauthorized;
    } else {
      request.response.headers.contentType = ContentType.json;
      switch (request.uri.path) {
        case '/':
          request.response.write(
            jsonEncode({
              'MediaContainer': {'machineIdentifier': serverId.value},
            }),
          );
        case '/media/providers':
          request.response.write(
            jsonEncode({
              'MediaContainer': {'MediaProvider': <Object>[]},
            }),
          );
        default:
          request.response.statusCode = HttpStatus.notFound;
      }
    }
    await request.response.close();
  }

  PlexServer resource(String token) => PlexServer(
    name: serverId.value,
    clientIdentifier: serverId.value,
    accessToken: token,
    connections: const [],
    owned: true,
  );

  Future<_PushConnection> connection(String token, {int occurrence = 0}) async {
    await _waitFor(() => connections.where((connection) => connection.token == token).length > occurrence);
    return connections.where((connection) => connection.token == token).elementAt(occurrence);
  }

  Future<void> close() async {
    _closed = true;
    holdNextUpgrade?.open();
    for (final gate in [...identityGates.values, ..._upgradeGates]) {
      gate.open();
    }
    for (final connection in connections) {
      await connection.socket.close();
    }
    await _server.close(force: true);
  }
}

PlexAccountConnection _account(List<PlexServer> servers) => PlexAccountConnection(
  id: 'account',
  accountToken: 'account-token',
  clientIdentifier: 'test-client',
  accountLabel: 'Account',
  servers: servers,
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

PlexProfileScopeId _scope(_PlexPushServer server, String profileId) =>
    buildPlexProfileScopeId(serverId: server.serverId, profileId: profileId);

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('push condition did not settle within 15 seconds');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  late AppDatabase db;
  late MultiServerManager manager;
  late LibraryEventService service;
  late List<_PlexPushServer> servers;
  late List<LibraryChangeEvent> changes;
  late List<DeletionEvent> deletions;
  late StreamSubscription<LibraryChangeEvent> contentSubscription;
  late StreamSubscription<DeletionEvent> deletionSubscription;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    manager = MultiServerManager(connectivityChanges: () => const Stream.empty());
    service = LibraryEventService(manager);
    servers = [];
    changes = [];
    deletions = [];
    contentSubscription = LibraryContentNotifier().stream.listen(changes.add);
    deletionSubscription = DeletionNotifier().stream.listen(deletions.add);
  });

  tearDown(() async {
    service.dispose();
    manager.dispose();
    await contentSubscription.cancel();
    await deletionSubscription.cancel();
    for (final server in servers) {
      await server.close();
    }
    await db.close();
  });

  Future<_PlexPushServer> startServer(String id) async {
    final server = await _PlexPushServer.start(id);
    servers.add(server);
    return server;
  }

  PlexClient register(_PlexPushServer server, {String token = 'token-a', String profileId = 'a'}) {
    final client = testPlexClient(
      baseUrl: server.baseUrl,
      token: token,
      serverId: server.serverId,
      profileScopeId: _scope(server, profileId),
      httpClient: http.Client(),
      prioritizedEndpoints: [server.baseUrl],
    );
    manager.debugRegisterClientForTesting(client);
    return client;
  }

  test('a healthy retained client reauthenticates A to B to A and same-profile token rotation', () async {
    final server = await startServer('shared');
    final unrelated = await startServer('unrelated');
    final client = register(server);
    register(unrelated);
    service.sync();
    final first = await server.connection('token-a');
    final unaffected = await unrelated.connection('token-a');
    first.removeItems(['a-first']);
    await _waitFor(() => changes.length == 1);
    final statuses = <Map<String, bool>>[];
    final statusSubscription = manager.statusStream.listen(statuses.add);
    addTearDown(statusSubscription.cancel);

    for (final transition in [
      (profile: 'b', token: 'token-b', item: 'b', occurrence: 0),
      (profile: 'a', token: 'token-a', item: 'a-returned', occurrence: 1),
      (profile: 'a', token: 'token-a-rotated', item: 'a-rotated', occurrence: 0),
    ]) {
      final previous = server.connections.last;
      expect(
        await manager.refreshTokensForProfile(
          _account([server.resource(transition.token)]),
          profileId: transition.profile,
        ),
        {'shared'},
      );
      expect(manager.onlineClients['shared'], same(client));
      final current = await server.connection(transition.token, occurrence: transition.occurrence);
      await previous.closed.future.timeout(const Duration(seconds: 5));
      current.removeItems([transition.item]);
      await _waitFor(() => deletions.any((event) => event.itemId == transition.item));
      expect(unaffected.closed.isCompleted, isFalse);
      expect(unrelated.upgradeTokens, ['token-a']);
    }

    expect(server.upgradeTokens, ['token-a', 'token-b', 'token-a', 'token-a-rotated']);
    expect(deletions.map((event) => event.itemId), ['a-first', 'b', 'a-returned', 'a-rotated']);
    expect(statuses, hasLength(3), reason: 'one manager publication per refresh, no extra session status churn');
  });

  test('no-op and failed credential updates retain the healthy authenticated socket', () async {
    final server = await startServer('shared');
    final client = register(server);
    service.sync();
    final original = await server.connection('token-a');
    final session = client.authenticationSessionId;

    expect(await manager.refreshTokensForProfile(_account([server.resource('token-a')]), profileId: 'a'), {'shared'});
    client.applyLanguageUpdate('fr');
    server.rejectedTokens.add('rejected');
    await expectLater(
      client.applyProfileUpdate(newToken: 'rejected', newProfileScopeId: _scope(server, 'b')),
      throwsA(isA<MediaServerHttpException>().having((error) => error.statusCode, 'statusCode', 401)),
    );
    service.sync();
    expect(client.authenticationSessionId, same(session));
    original.removeItems(['still-a']);
    await _waitFor(() => deletions.isNotEmpty);
    expect(deletions.single.itemId, 'still-a');
    expect(original.closed.isCompleted, isFalse);
    expect(server.upgradeTokens, ['token-a']);
  });

  test('old frames cannot cross the commit-to-batched-status interval', () async {
    final server = await startServer('shared');
    final slowServer = await startServer('slow');
    final client = register(server);
    register(slowServer);
    service.sync();
    final old = await server.connection('token-a');
    await slowServer.connection('token-a');
    final gate = _RequestGate();
    slowServer.identityGates['token-b'] = gate;
    final statuses = <Map<String, bool>>[];
    final statusSubscription = manager.statusStream.listen(statuses.add);
    addTearDown(statusSubscription.cancel);
    final refresh = manager.refreshTokensForProfile(
      _account([server.resource('token-b'), slowServer.resource('token-b')]),
      profileId: 'b',
    );
    await gate.started.future;
    await _waitFor(() => client.config.token == 'token-b');
    expect(statuses, isEmpty, reason: 'the other server is still validating');

    old.removeItems(['a-after-b-commit']);
    await old.closed.future.timeout(const Duration(seconds: 5));
    await pumpEventQueue();
    expect(changes, isEmpty);
    expect(deletions, isEmpty);
    expect(server.upgradeTokens, ['token-a'], reason: 'stale forwarding does not publish or globally reconnect');

    gate.open();
    expect(await refresh, {'shared', 'slow'});
    final current = await server.connection('token-b');
    current.removeItems(['b-current']);
    await _waitFor(() => deletions.isNotEmpty);
    expect(deletions.single.itemId, 'b-current');
    expect(statuses, hasLength(1));
  });

  test('a pending coalesced A event is stale even after returning to A before status', () async {
    final server = await startServer('shared');
    final client = register(server);
    service.sync();
    final old = await server.connection('token-a');
    // One frame schedules both the leading event and a trailing removal in
    // the same synchronous onFrame call, before the leading event is observed.
    old.removeItems(['a-leading', 'a-pending']);
    await _waitFor(() => changes.length == 1);
    expect(deletions.single.itemId, 'a-leading');
    final originalSession = client.authenticationSessionId;
    expect(await client.applyProfileUpdate(newToken: 'token-b', newProfileScopeId: _scope(server, 'b')), isTrue);
    expect(await client.applyProfileUpdate(newToken: 'token-a', newProfileScopeId: _scope(server, 'a')), isTrue);
    expect(client.authenticationSessionId, isNot(same(originalSession)));

    // Let the actual ten-second production throttle flush, with no manager
    // status at all. The stale-event guard must retire rather than forward it.
    await old.closed.future.timeout(const Duration(seconds: 15));
    await pumpEventQueue();
    expect(deletions.map((event) => event.itemId), ['a-leading']);
    expect(changes, hasLength(1));
    service.sync();
    final current = await server.connection('token-a', occurrence: 1);
    current.removeItems(['a-new-session']);
    await _waitFor(() => deletions.length == 2);
    expect(deletions.last.itemId, 'a-new-session');
  });

  test('an old upgrade completing after a committed switch is closed without forwarding', () async {
    final server = await startServer('shared');
    register(server);
    final gate = _RequestGate();
    server.holdNextUpgrade = gate;
    service.sync();
    await gate.started.future;
    expect(server.upgradeTokens, ['token-a']);

    expect(await manager.refreshTokensForProfile(_account([server.resource('token-b')]), profileId: 'b'), {'shared'});
    final current = await server.connection('token-b');
    gate.open();
    final late = await server.connection('token-a');
    await late.closed.future.timeout(const Duration(seconds: 5));
    current.removeItems(['b-only']);
    await _waitFor(() => deletions.isNotEmpty);
    expect(deletions.single.itemId, 'b-only');
    expect(server.upgradeTokens, ['token-a', 'token-b']);
    expect(current.closed.isCompleted, isFalse);
  });

  test('retired retries stay cancelled across suspend and normal reconnect still works', () async {
    final server = await startServer('shared');
    final client = register(server);
    service.sync();
    final original = await server.connection('token-a');
    // The remote close arms the normal five-second retry; a profile commit
    // must retire that retry rather than opening a duplicate B connection.
    await original.socket.close();
    await original.closed.future;
    await pumpEventQueue();
    expect(await manager.refreshTokensForProfile(_account([server.resource('token-b')]), profileId: 'b'), {'shared'});
    final switched = await server.connection('token-b');
    final session = client.authenticationSessionId;
    service.suspend();
    await switched.closed.future.timeout(const Duration(seconds: 5));
    manager.debugEmitStatusForTesting();
    await Future<void>.delayed(const Duration(milliseconds: 5200));
    expect(server.upgradeTokens, ['token-a', 'token-b']);
    expect(service.activeServerIds, isEmpty);

    service.resume();
    final resumed = await server.connection('token-b', occurrence: 1);
    expect(client.authenticationSessionId, same(session));
    final alternateEndpoint = await startServer('shared');
    await client.updateEndpointPreferences([alternateEndpoint.baseUrl, server.baseUrl], switchToFirst: true);
    manager.debugEmitStatusForTesting();
    await pumpEventQueue();
    expect(client.authenticationSessionId, same(session));
    expect(resumed.closed.isCompleted, isFalse, reason: 'endpoint promotion is not a new authentication session');
    expect(alternateEndpoint.upgradeTokens, isEmpty);
    await resumed.socket.close();
    final reconnected = await alternateEndpoint.connection('token-b');
    reconnected.removeItems(['b-reconnected']);
    await _waitFor(() => deletions.isNotEmpty);
    expect(deletions.single.itemId, 'b-reconnected');
    expect(client.authenticationSessionId, same(session));
    expect(server.upgradeTokens, ['token-a', 'token-b', 'token-b']);
    expect(alternateEndpoint.upgradeTokens, ['token-b'], reason: 'ordinary reconnect uses the live endpoint');
  });
}
