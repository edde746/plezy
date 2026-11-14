import 'dart:async';

import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/watch_credentials_bridge.dart';

import '../test_helpers/backend_client_fixtures.dart';

class _FakeManager extends MultiServerManager {
  final Map<String, MediaServerClient> clients = {};
  final StreamController<Map<String, bool>> status = StreamController.broadcast(sync: true);

  @override
  List<String> get serverIds => clients.keys.toList();

  @override
  MediaServerClient? getClient(ServerId serverId) => clients[serverId];

  @override
  Stream<Map<String, bool>> get statusStream => status.stream;

  final Set<String> owned = {};
  final Map<String, List<String>> remote = {};

  @override
  bool isOwnerOrAdmin(ServerId serverId) => owned.contains(serverId);

  @override
  List<String> plexRemoteUris(ServerId serverId) => remote[serverId] ?? const [];

  void emit() => status.add({});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/watch');
  late List<MethodCall> calls;
  late _FakeManager manager;
  late WatchCredentialsBridge bridge;
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
    calls = [];
    manager = _FakeManager();
    bridge = WatchCredentialsBridge(serverManager: manager, channel: channel);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() async {
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  List<String> methods() => calls.map((call) => call.method).toList();

  test('credentials name the server, so the watch can verify a LAN address', () {
    manager.clients['machine-1'] = testPlexClient(baseUrl: 'https://plex.example.com', token: 'tok');

    expect(bridge.credentials(), {
      'serverUrl': 'https://plex.example.com',
      'token': 'tok',
      'machineIdentifier': 'machine-1',
    });
  });

  test('remote addresses go along, so the watch can reach Plex on a run without the phone', () {
    manager.clients['machine-1'] = testPlexClient(baseUrl: 'https://10-0-2-5.abc.plex.direct:32400', token: 'tok');
    manager.remote['machine-1'] = [
      'https://10-0-2-5.abc.plex.direct:32400',
      'https://plex.example.com:443',
      'https://1-2-3-4.abc.plex.direct:8443',
    ];

    expect(
      bridge.credentials()!['fallbackUrls'],
      'https://plex.example.com:443\nhttps://1-2-3-4.abc.plex.direct:8443',
      reason: 'the address already in serverUrl is not repeated',
    );
  });

  test("the owner's own server is chosen over one shared with them, which lacks their playlists", () {
    manager.clients['shared'] = testPlexClient(baseUrl: 'https://friend.example.com', token: 'tok');
    manager.clients['mine'] = testPlexClient(baseUrl: 'https://home.example.com', token: 'tok');
    manager.owned.add('mine');

    expect(bridge.credentials()!['machineIdentifier'], 'mine');
  });

  test('a phone that has not connected yet does not sign the watch out', () {
    fakeAsync((async) {
      bridge.start();
      manager.emit();
      async.elapse(WatchCredentialsBridge.signOutGrace * 2);
      async.flushMicrotasks();

      expect(methods(), isNot(contains('clearPlexCredentials')));
    });
  });

  test('losing the last Plex server signs the watch out after the grace period', () {
    fakeAsync((async) {
      manager.clients['machine-1'] = testPlexClient(token: 'tok');
      bridge.start();
      async.flushMicrotasks();
      expect(methods(), ['updatePlexCredentials']);

      manager.clients.clear();
      manager.emit();
      async.elapse(WatchCredentialsBridge.signOutGrace - const Duration(milliseconds: 1));
      expect(methods(), isNot(contains('clearPlexCredentials')));

      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();
      expect(methods().last, 'clearPlexCredentials');
    });
  });

  test('a profile switch that brings a server back keeps the watch signed in', () {
    fakeAsync((async) {
      manager.clients['machine-1'] = testPlexClient(token: 'tok');
      bridge.start();
      async.flushMicrotasks();

      manager.clients.clear();
      manager.emit();
      async.elapse(const Duration(seconds: 1));
      manager.clients['machine-2'] = testPlexClient(token: 'other');
      manager.emit();
      async.elapse(WatchCredentialsBridge.signOutGrace * 2);
      async.flushMicrotasks();

      expect(methods(), isNot(contains('clearPlexCredentials')));
    });
  });

  test('disposing does not sign the watch out later', () {
    fakeAsync((async) {
      manager.clients['machine-1'] = testPlexClient(token: 'tok');
      bridge.start();
      async.flushMicrotasks();

      manager.clients.clear();
      manager.emit();
      unawaited(bridge.dispose());
      async.elapse(WatchCredentialsBridge.signOutGrace * 2);
      async.flushMicrotasks();

      expect(methods(), isNot(contains('clearPlexCredentials')));
    });
  });

  test('a rating key is only looked up on the server it came from', () async {
    final requested = <String>[];
    Future<Never> refuse(String server) async {
      requested.add(server);
      throw StateError('no transcode here');
    }

    manager.clients['first'] = testPlexClient(token: 'token-first', handler: (_) => refuse('first'));
    manager.clients['second'] = testPlexClient(token: 'token-second', handler: (_) => refuse('second'));

    await bridge.resolveMusicStreamUrl('42', machineIdentifier: 'second').catchError((_) => null);

    expect(requested, isNotEmpty);
    expect(requested.toSet(), {'second'});
  });

  test('without a machine identifier only the first Plex server is asked', () async {
    final requested = <String>[];
    Future<Never> refuse(String server) async {
      requested.add(server);
      throw StateError('no transcode here');
    }

    manager.clients['first'] = testPlexClient(token: 'token-first', handler: (_) => refuse('first'));
    manager.clients['second'] = testPlexClient(token: 'token-second', handler: (_) => refuse('second'));

    await bridge.resolveMusicStreamUrl('42').catchError((_) => null);

    expect(requested.toSet(), {'first'});
  });
}
