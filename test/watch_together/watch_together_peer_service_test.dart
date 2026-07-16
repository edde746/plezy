import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/watch_together/services/watch_together_peer_service.dart';
import 'package:plezy/watch_together/models/sync_message.dart';

typedef _MessageHandler = FutureOr<void> Function(int connection, WebSocket socket, Map<String, dynamic> message);

Future<T> _withShortenedTimer<T>({
  required Duration original,
  required Duration replacement,
  required Future<T> Function() body,
}) {
  return runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      createTimer: (self, parent, zone, duration, callback) {
        return parent.createTimer(zone, duration == original ? replacement : duration, callback);
      },
    ),
  );
}

class _RelayServer {
  _RelayServer._(this._server, this._handler);

  final HttpServer _server;
  final _MessageHandler _handler;
  final List<WebSocket> sockets = [];
  final List<List<Map<String, dynamic>>> messages = [];

  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  static Future<_RelayServer> start(_MessageHandler handler) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final relay = _RelayServer._(server, handler);
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      final connection = relay.sockets.length;
      relay.sockets.add(socket);
      relay.messages.add([]);
      socket.listen((data) {
        final message = (jsonDecode(data as String) as Map).cast<String, dynamic>();
        relay.messages[connection].add(message);
        relay._handler(connection, socket, message);
      });
    });
    return relay;
  }

  void send(WebSocket socket, Map<String, dynamic> message) => socket.add(jsonEncode(message));

  Future<void> close() async {
    for (final socket in sockets) {
      await socket.close();
    }
    await _server.close(force: true);
  }
}

void main() {
  final services = <WatchTogetherPeerService>[];
  final relays = <_RelayServer>[];

  WatchTogetherPeerService serviceFor(_RelayServer relay) {
    final service = WatchTogetherPeerService(customBaseUrl: relay.baseUrl);
    services.add(service);
    return service;
  }

  Future<_RelayServer> relayWith(_MessageHandler handler) async {
    final relay = await _RelayServer.start(handler);
    relays.add(relay);
    return relay;
  }

  tearDown(() async {
    for (final service in services.reversed) {
      await service.disconnect();
      service.dispose();
    }
    services.clear();
    for (final relay in relays.reversed) {
      await relay.close();
    }
    relays.clear();
  });

  test('invalid relay identifiers fail before network access', () async {
    final service = WatchTogetherPeerService();
    services.add(service);

    await expectLater(service.createSession(sessionId: 'bad room'), throwsArgumentError);
    await expectLater(service.joinSession('bad/room'), throwsArgumentError);
    expect(
      () => service.sendTo('bad peer', const SyncMessage(type: SyncMessageType.requestState, timestamp: 0)),
      throwsArgumentError,
    );
  });

  test('host connects, listens, and announces create with the existing wire format', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'create') {
        relay.send(socket, {'type': 'created', 'sessionId': message['sessionId']});
      }
    });
    final service = serviceFor(relay);

    expect(await service.createSession(sessionId: 'abc12'), 'ABC12');
    expect(service.isHost, isTrue);
    expect(service.myPeerId, 'wt-ABC12');
    expect(relay.messages.single, [
      {'type': 'create', 'sessionId': 'ABC12', 'peerId': 'wt-ABC12'},
    ]);
  });

  test('guest connects, listens, and announces join with the existing wire format', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'join') {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'peers': ['wt-ROOM1'],
        });
      }
    });
    final service = serviceFor(relay);
    final connectedPeers = <String>[];
    final subscription = service.onPeerConnected.listen(connectedPeers.add);
    addTearDown(subscription.cancel);

    await service.joinSession('room1');

    expect(service.isHost, isFalse);
    expect(service.connectedPeers, ['wt-ROOM1']);
    expect(connectedPeers, ['wt-ROOM1']);
    expect(relay.messages.single, [
      {'type': 'join', 'sessionId': 'ROOM1', 'peerId': service.myPeerId},
    ]);
  });

  test('host reconnect joins first and re-creates a missing room on the same socket', () async {
    late final _RelayServer relay;
    relay = await relayWith((connection, socket, message) {
      if (connection == 0 && message['type'] == 'create') {
        relay.send(socket, {'type': 'created', 'sessionId': message['sessionId']});
      } else if (connection == 1 && message['type'] == 'join') {
        relay.send(socket, {'type': 'error', 'code': 'room_not_found', 'message': 'Room not found'});
      } else if (connection == 1 && message['type'] == 'create') {
        relay.send(socket, {'type': 'created', 'sessionId': message['sessionId']});
      }
    });
    final service = serviceFor(relay);
    final reconnected = Completer<void>();
    var reconnectCallbacks = 0;
    service.onReconnected = () {
      reconnectCallbacks++;
      reconnected.complete();
    };

    await _withShortenedTimer(
      original: const Duration(seconds: 2),
      replacement: const Duration(milliseconds: 10),
      body: () => service.createSession(sessionId: 'room2'),
    );
    await relay.sockets.single.close();
    await reconnected.future.timeout(const Duration(seconds: 6));

    expect(reconnectCallbacks, 1);
    expect(relay.sockets, hasLength(2));
    expect(relay.messages[0], [
      {'type': 'create', 'sessionId': 'ROOM2', 'peerId': 'wt-ROOM2'},
    ]);
    expect(relay.messages[1], [
      {'type': 'join', 'sessionId': 'ROOM2', 'peerId': 'wt-ROOM2'},
      {'type': 'create', 'sessionId': 'ROOM2', 'peerId': 'wt-ROOM2'},
    ]);
  });

  test('setup preserves typed timeout and relay errors', () async {
    final timeoutRelay = await relayWith((_, _, _) {});
    final timeoutService = serviceFor(timeoutRelay);

    await expectLater(
      _withShortenedTimer(
        original: const Duration(seconds: 10),
        replacement: const Duration(milliseconds: 10),
        body: () => timeoutService.createSession(sessionId: 'slow1'),
      ),
      throwsA(
        isA<PeerError>()
            .having((error) => error.type, 'type', PeerErrorType.timeout)
            .having((error) => error.message, 'message', 'Timed out creating session'),
      ),
    );

    late final _RelayServer errorRelay;
    errorRelay = await relayWith((_, socket, message) {
      errorRelay.send(socket, {'type': 'error', 'code': 'room_full', 'message': 'Room is full'});
    });
    final errorService = serviceFor(errorRelay);

    await expectLater(
      errorService.joinSession('full1'),
      throwsA(
        isA<PeerError>()
            .having((error) => error.type, 'type', PeerErrorType.serverError)
            .having((error) => error.serverCode, 'serverCode', 'room_full'),
      ),
    );
  });

  test('one setup installs one listener and sends one announcement', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'create') {
        relay.send(socket, {'type': 'created', 'sessionId': message['sessionId']});
      }
    });
    final service = serviceFor(relay);
    final peerEvents = <String>[];
    final peerSeen = Completer<void>();
    final subscription = service.onPeerConnected.listen((peerId) {
      peerEvents.add(peerId);
      if (!peerSeen.isCompleted) peerSeen.complete();
    });
    addTearDown(subscription.cancel);

    await service.createSession(sessionId: 'once1');
    relay.send(relay.sockets.single, {'type': 'peerJoined', 'peerId': 'guest-1'});
    await peerSeen.future.timeout(const Duration(seconds: 1));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(peerEvents, ['guest-1']);
    expect(relay.messages.single.where((message) => message['type'] == 'create'), hasLength(1));
  });

  test('disconnect cancels an in-flight room announcement without timeout delay', () async {
    final announcementSeen = Completer<void>();
    final relay = await relayWith((_, _, message) {
      if (message['type'] == 'create' && !announcementSeen.isCompleted) {
        announcementSeen.complete();
      }
    });
    final service = serviceFor(relay);

    final pending = service.createSession(sessionId: 'cancel1');
    await announcementSeen.future.timeout(const Duration(seconds: 1));
    await service.disconnect();

    await expectLater(pending, throwsStateError);
    expect(service.sessionId, isNull);
    expect(service.connectedPeers, isEmpty);
  });
}
