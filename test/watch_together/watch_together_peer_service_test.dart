import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/watch_together/services/watch_together_peer_service.dart';
import 'package:plezy/watch_together/services/watch_together_relay_endpoint.dart';
import 'package:plezy/watch_together/models/sync_message.dart';

typedef _MessageHandler = FutureOr<void> Function(int connection, WebSocket socket, Map<String, dynamic> message);
const _relayHostId = 'relay-host-7';

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

/// Collapses the initial-setup and release retry backoff so a test that
/// exhausts the retries does not spend the real 250 ms + 500 ms between them.
///
/// Every relay wait a test needs to *expire* is set through the service's own
/// budgets instead, so nothing here puts a real loopback handshake on a
/// deadline shorter than the round trip it is waiting for.
Future<T> _withRetryBackoffShortened<T>(Future<T> Function() body) {
  return _withShortenedTimer(
    original: const Duration(milliseconds: 250),
    replacement: const Duration(milliseconds: 1),
    body: () => _withShortenedTimer(
      original: const Duration(milliseconds: 500),
      replacement: const Duration(milliseconds: 1),
      body: body,
    ),
  );
}

class _TrackingWebSocketSink implements WebSocketSink {
  final Completer<void> _done = Completer<void>();
  bool closed = false;

  @override
  void add(dynamic data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) => stream.drain<void>();

  @override
  Future<void> close([int? closeCode, String? closeReason]) {
    closed = true;
    if (!_done.isCompleted) _done.complete();
    return _done.future;
  }

  @override
  Future<void> get done => _done.future;
}

class _PendingWebSocketChannel extends StreamChannelMixin<dynamic> implements WebSocketChannel {
  final Completer<void> _readyCompleter = Completer<void>();

  @override
  final _TrackingWebSocketSink sink = _TrackingWebSocketSink();

  @override
  Stream<dynamic> get stream => const Stream<dynamic>.empty();

  @override
  Future<void> get ready => _readyCompleter.future;

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  Future<void> closeForTesting() => sink.close();
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

  WatchTogetherPeerService serviceFor(
    _RelayServer relay, {
    Future<void> Function()? debugReconnectSetupSucceededBarrier,
    Duration debugInitialSetupTimeout = const Duration(seconds: 10),
    Duration debugReleaseConnectTimeout = const Duration(seconds: 10),
    Duration debugReleaseTimeout = const Duration(seconds: 10),
    WebSocketChannel Function(Uri uri)? debugChannelFactory,
  }) {
    final service = WatchTogetherPeerService(
      endpoint: WatchTogetherRelayEndpoint.resolve(relay.baseUrl),
      debugReconnectSetupSucceededBarrier: debugReconnectSetupSucceededBarrier,
      debugInitialSetupTimeout: debugInitialSetupTimeout,
      debugReleaseConnectTimeout: debugReleaseConnectTimeout,
      debugReleaseTimeout: debugReleaseTimeout,
      debugChannelFactory: debugChannelFactory,
    );
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

  group('WatchTogetherRelayEndpoint', () {
    test('resolves defaults and canonical endpoint paths', () {
      for (final value in <String?>[null, '', '   ']) {
        final endpoint = WatchTogetherRelayEndpoint.resolve(value);
        expect(endpoint.canonicalBaseUrl, 'https://ice.plezy.app');
        expect(endpoint.healthUri.toString(), 'https://ice.plezy.app/health');
        expect(endpoint.webSocketUri.toString(), 'wss://ice.plezy.app/relay');
      }

      final endpoint = WatchTogetherRelayEndpoint.resolve('  HTTP://Example.COM:8080/old/../prefix///  ');
      expect(endpoint.canonicalBaseUrl, 'http://example.com:8080/prefix');
      expect(endpoint.healthUri.toString(), 'http://example.com:8080/prefix/health');
      expect(endpoint.webSocketUri.toString(), 'ws://example.com:8080/prefix/relay');
    });

    test('default ports share canonical identity while non-default ports remain distinct', () {
      final http = WatchTogetherRelayEndpoint.resolve('http://relay.example.test:80/base/');
      final implicitHttp = WatchTogetherRelayEndpoint.resolve('http://relay.example.test/base');
      final https = WatchTogetherRelayEndpoint.resolve('https://relay.example.test:443/base/');
      final implicitHttps = WatchTogetherRelayEndpoint.resolve('https://relay.example.test/base');
      final nonDefault = WatchTogetherRelayEndpoint.resolve('https://relay.example.test:8443/base');

      expect(http.canonicalBaseUrl, 'http://relay.example.test/base');
      expect(https.canonicalBaseUrl, 'https://relay.example.test/base');
      expect(http, implicitHttp);
      expect(http.hashCode, implicitHttp.hashCode);
      expect(https, implicitHttps);
      expect(https.hashCode, implicitHttps.hashCode);
      expect(nonDefault.canonicalBaseUrl, 'https://relay.example.test:8443/base');
      expect(nonDefault, isNot(implicitHttps));
      expect(http, isNot(https));
    });

    test('accepts supported host forms and rejects unusable bases', () {
      final ipv6 = WatchTogetherRelayEndpoint.tryParseCustom('https://[2001:db8::1]:8443/base/');
      expect(ipv6?.canonicalBaseUrl, 'https://[2001:db8::1]:8443/base');

      for (final value in [
        'relay.example.test',
        '/relative',
        'ftp://relay.example.test',
        'ws://relay.example.test',
        'https://',
        'https://opaque@relay.example.test',
        'https://relay.example.test/path?mode=test',
        'https://relay.example.test/path#fragment',
        'https://relay.example.test:99999',
      ]) {
        expect(WatchTogetherRelayEndpoint.tryParseCustom(value), isNull, reason: value);
      }
    });
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

  test('host stores relay authority and uses a random routing ID', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'create') {
        relay.send(socket, {
          'type': 'created',
          'sessionId': message['sessionId'],
          'hostPeerId': message['peerId'],
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
        });
      }
    });
    final service = serviceFor(relay);

    expect(await service.createSession(sessionId: 'abc12'), 'ABC12');
    expect(service.isHost, isTrue);
    expect(service.myPeerId, isNot('wt-ABC12'));
    expect(service.myPeerId, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(service.hostPeerId, service.myPeerId);
    final create = relay.messages.single.single;
    expect(create, {
      'type': 'create',
      'sessionId': 'ABC12',
      'peerId': service.myPeerId,
      'reconnectToken': matches(RegExp(r'^[A-Za-z0-9_-]{43}$')),
      'protocolVersion': 2,
    });
  });

  test('guest stores the relay-declared host identity', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'join') {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'hostPeerId': _relayHostId,
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
          'peers': [_relayHostId],
        });
      }
    });
    final service = serviceFor(relay);
    final connectedPeers = <String>[];
    final subscription = service.onPeerConnected.listen(connectedPeers.add);
    addTearDown(subscription.cancel);

    await service.joinSession('room1');

    expect(service.isHost, isFalse);
    expect(service.hostPeerId, _relayHostId);
    expect(service.connectedPeers, [_relayHostId]);
    expect(connectedPeers, [_relayHostId]);
    expect(relay.messages.single.single, {
      'type': 'join',
      'sessionId': 'ROOM1',
      'peerId': service.myPeerId,
      'reconnectToken': matches(RegExp(r'^[A-Za-z0-9_-]{43}$')),
      'protocolVersion': 2,
    });
  });

  test('guest reconnect sends its retained capability', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'join') {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'hostPeerId': _relayHostId,
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
          'peers': [_relayHostId],
        });
      }
    });
    final service = serviceFor(relay);
    final reconnected = Completer<void>();
    service.onReconnected = reconnected.complete;

    await _withShortenedTimer(
      original: const Duration(seconds: 2),
      replacement: const Duration(milliseconds: 10),
      body: () => service.joinSession('guest1'),
    );
    final guestPeerId = service.myPeerId;
    await relay.sockets.single.close();
    await reconnected.future.timeout(const Duration(seconds: 6));

    final initialToken = relay.messages[0].single['reconnectToken'];
    expect(relay.messages[1], [
      {
        'type': 'join',
        'sessionId': 'GUEST1',
        'peerId': guestPeerId,
        'reconnectToken': initialToken,
        'protocolVersion': 2,
      },
    ]);
    expect(service.hostPeerId, _relayHostId);
  });

  test('guest reconnect releases an admitted identity when the relay host changed', () async {
    late final _RelayServer relay;
    relay = await relayWith((connection, socket, message) {
      if (message['type'] == 'join') {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'hostPeerId': connection == 0 ? _relayHostId : 'replacement-host',
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
          'peers': [connection == 0 ? _relayHostId : 'replacement-host'],
        });
      } else if (message['type'] == 'leave') {
        relay.send(socket, {
          'type': 'left',
          'sessionId': message['sessionId'],
          'peerId': message['peerId'],
          'protocolVersion': 2,
        });
      }
    });
    final service = serviceFor(relay);
    var reconnectCallbacks = 0;
    service.onReconnected = () => reconnectCallbacks++;
    final identityError = service.onError.firstWhere(
      (error) => error.type == PeerErrorType.serverError && error.message.contains('invalid joined response'),
    );

    await _withShortenedTimer(
      original: const Duration(seconds: 2),
      replacement: const Duration(milliseconds: 10),
      body: () => service.joinSession('guest2'),
    );
    await relay.sockets.single.close();
    await identityError.timeout(const Duration(seconds: 1));
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(service.hostPeerId, _relayHostId);
    expect(reconnectCallbacks, 0);
    expect(relay.sockets, hasLength(2));
    final reconnect = relay.messages[1].first;
    expect(relay.messages[1], [
      reconnect,
      {
        'type': 'leave',
        'sessionId': 'GUEST2',
        'peerId': reconnect['peerId'],
        'reconnectToken': reconnect['reconnectToken'],
        'protocolVersion': 2,
      },
    ]);
  });

  test('guest reconnect closes after a rejected admission leave ACK is lost', () async {
    final leaveSeen = Completer<void>();
    late final _RelayServer relay;
    relay = await relayWith((connection, socket, message) {
      if (message['type'] == 'join') {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'hostPeerId': connection == 0 ? _relayHostId : 'replacement-host',
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
          'peers': [connection == 0 ? _relayHostId : 'replacement-host'],
        });
      } else if (message['type'] == 'leave' && !leaveSeen.isCompleted) {
        leaveSeen.complete();
      }
    });
    final service = serviceFor(relay);

    await _withShortenedTimer(
      original: const Duration(seconds: 10),
      replacement: const Duration(milliseconds: 500),
      body: () => _withShortenedTimer(
        original: const Duration(seconds: 2),
        replacement: const Duration(milliseconds: 10),
        body: () async {
          await service.joinSession('guest3');
          await relay.sockets.single.close();
          await leaveSeen.future.timeout(const Duration(seconds: 1));
          await relay.sockets[1].done.timeout(const Duration(seconds: 1));
        },
      ),
    );

    expect(relay.messages[1].map((message) => message['type']), ['join', 'leave']);
  });

  test('host reconnect proves ownership and re-creates with the retained authority', () async {
    late final _RelayServer relay;
    relay = await relayWith((connection, socket, message) {
      if (connection == 0 && message['type'] == 'create') {
        relay.send(socket, {
          'type': 'created',
          'sessionId': message['sessionId'],
          'hostPeerId': message['peerId'],
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
        });
      } else if (connection == 1 && message['type'] == 'join') {
        relay.send(socket, {'type': 'error', 'code': 'room_not_found', 'message': 'Room not found'});
      } else if (connection == 1 && message['type'] == 'create') {
        relay.send(socket, {
          'type': 'created',
          'sessionId': message['sessionId'],
          'hostPeerId': message['peerId'],
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
        });
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
    final hostPeerId = service.myPeerId;
    await relay.sockets.single.close();
    await reconnected.future.timeout(const Duration(seconds: 6));

    expect(reconnectCallbacks, 1);
    expect(relay.sockets, hasLength(2));
    final initialCreate = relay.messages[0].single;
    final reconnectToken = initialCreate['reconnectToken'];
    expect(initialCreate, {
      'type': 'create',
      'sessionId': 'ROOM2',
      'peerId': hostPeerId,
      'reconnectToken': matches(RegExp(r'^[A-Za-z0-9_-]{43}$')),
      'protocolVersion': 2,
    });
    expect(relay.messages[1], [
      {
        'type': 'join',
        'sessionId': 'ROOM2',
        'peerId': hostPeerId,
        'reconnectToken': reconnectToken,
        'protocolVersion': 2,
      },
      {
        'type': 'create',
        'sessionId': 'ROOM2',
        'peerId': hostPeerId,
        'reconnectToken': reconnectToken,
        'protocolVersion': 2,
      },
    ]);
    expect(service.hostPeerId, hostPeerId);
  });

  test('initial create retry reuses its pre-minted identity and capability', () async {
    late final _RelayServer relay;
    relay = await relayWith((connection, socket, message) async {
      if (message['type'] != 'create') return;
      if (connection == 0) {
        await socket.close();
        return;
      }
      relay.send(socket, {
        'type': 'created',
        'sessionId': message['sessionId'],
        'hostPeerId': message['peerId'],
        'reconnectToken': message['reconnectToken'],
        'protocolVersion': 2,
      });
    });
    final service = serviceFor(relay);

    await _withShortenedTimer(
      original: const Duration(milliseconds: 250),
      replacement: const Duration(milliseconds: 1),
      body: () => service.createSession(sessionId: 'retry1'),
    );

    expect(relay.messages, hasLength(2));
    final first = relay.messages[0].single;
    final retry = relay.messages[1].single;
    expect(first['reconnectToken'], matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(retry, first);
    expect(service.myPeerId, first['peerId']);
    expect(service.hostPeerId, first['peerId']);
  });

  test('setup preserves typed timeout and relay errors', () async {
    final timeoutRelay = await relayWith((_, _, _) {});
    // This relay answers nothing, so the setup announcement and the
    // best-effort release that follows both have to give up on their own.
    final timeoutService = serviceFor(
      timeoutRelay,
      debugInitialSetupTimeout: const Duration(milliseconds: 10),
      debugReleaseTimeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      _withRetryBackoffShortened(() => timeoutService.createSession(sessionId: 'slow1')),
      throwsA(
        isA<PeerError>()
            .having((error) => error.type, 'type', PeerErrorType.timeout)
            .having((error) => error.message, 'message', t.watchTogether.errors.timedOut),
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

  test('relay protocol mismatch remains a typed setup error', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      relay.send(socket, {
        'type': 'error',
        'code': 'protocol_mismatch',
        'message': 'Relay protocol version 2 is required',
      });
    });
    final service = serviceFor(relay);

    await expectLater(
      service.joinSession('proto1'),
      throwsA(
        isA<PeerError>()
            .having((error) => error.type, 'type', PeerErrorType.serverError)
            .having((error) => error.serverCode, 'serverCode', 'protocol_mismatch')
            .having((error) => error.message, 'message', contains('Relay protocol version 2 is required')),
      ),
    );
  });

  test('setup rejects a relay that substitutes the pre-minted capability', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      const tokenA = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
      const tokenB = 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB';
      relay.send(socket, {
        'type': 'created',
        'sessionId': message['sessionId'],
        'hostPeerId': message['peerId'],
        'reconnectToken': message['reconnectToken'] == tokenA ? tokenB : tokenA,
        'protocolVersion': 2,
      });
    });
    final service = serviceFor(relay);

    await expectLater(
      service.createSession(sessionId: 'token1'),
      throwsA(
        isA<PeerError>()
            .having((error) => error.type, 'type', PeerErrorType.serverError)
            .having((error) => error.message, 'message', t.watchTogether.errors.invalidRelayResponse),
      ),
    );
    expect(service.hostPeerId, isNull);
  });

  test('missing or malformed authority fields fail setup immediately', () async {
    late final _RelayServer oldRelay;
    oldRelay = await relayWith((_, socket, message) {
      oldRelay.send(socket, {'type': 'created', 'sessionId': message['sessionId'], 'protocolVersion': 2});
    });
    final oldRelayService = serviceFor(oldRelay);

    await expectLater(
      oldRelayService.createSession(sessionId: 'old01'),
      throwsA(
        isA<PeerError>()
            .having((error) => error.type, 'type', PeerErrorType.serverError)
            .having((error) => error.message, 'message', t.watchTogether.errors.invalidRelayResponse),
      ),
    );
    expect(oldRelayService.hostPeerId, isNull);

    late final _RelayServer malformedRelay;
    malformedRelay = await relayWith((_, socket, message) {
      malformedRelay.send(socket, {
        'type': 'joined',
        'sessionId': message['sessionId'],
        'hostPeerId': _relayHostId,
        'reconnectToken': 'not-a-capability',
        'protocolVersion': 2,
      });
    });
    final malformedService = serviceFor(malformedRelay);

    await expectLater(
      malformedService.joinSession('bad01'),
      throwsA(
        isA<PeerError>()
            .having((error) => error.type, 'type', PeerErrorType.serverError)
            .having((error) => error.message, 'message', t.watchTogether.errors.invalidRelayResponse),
      ),
    );
    expect(malformedService.hostPeerId, isNull);
  });

  test('exhausted create retries end a possibly committed room before clearing credentials', () async {
    late final _RelayServer relay;
    relay = await relayWith((connection, socket, message) {
      if (connection >= 3 && message['type'] == 'join') {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'hostPeerId': message['peerId'],
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
          'peers': const <String>[],
        });
      } else if (message['type'] == 'endSession') {
        relay.send(socket, {'type': 'ended', 'sessionId': message['sessionId'], 'protocolVersion': 2});
      }
    });
    // Only the setup acknowledgement is compressed: the recovery that follows
    // keeps its real budgets, so neither its handshake nor its acknowledgements
    // are racing a deadline shorter than a loopback round trip.
    final service = serviceFor(relay, debugInitialSetupTimeout: const Duration(milliseconds: 10));

    await expectLater(
      _withRetryBackoffShortened(() => service.createSession(sessionId: 'lostc')),
      throwsA(
        isA<PeerError>()
            .having((error) => error.type, 'type', PeerErrorType.timeout)
            .having((error) => error.message, 'message', t.watchTogether.errors.timedOut),
      ),
    );

    expect(relay.messages.map((messages) => messages.map((message) => message['type']).toList()).toList(), [
      ['create'],
      ['create'],
      ['create'],
      ['join', 'endSession'],
    ]);
    final announcements = relay.messages.map((messages) => messages.first).toList();
    expect(announcements.map((message) => message['peerId']).toSet(), hasLength(1));
    expect(announcements.map((message) => message['reconnectToken']).toSet(), hasLength(1));
    expect(service.sessionId, isNull);
    expect(service.myPeerId, isNull);
  });

  test('exhausted join retries leave a possibly committed guest reservation before clearing credentials', () async {
    late final _RelayServer relay;
    relay = await relayWith((connection, socket, message) {
      if (connection >= 3 && message['type'] == 'join') {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'hostPeerId': _relayHostId,
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
          'peers': [_relayHostId],
        });
      } else if (message['type'] == 'leave') {
        relay.send(socket, {
          'type': 'left',
          'sessionId': message['sessionId'],
          'peerId': message['peerId'],
          'protocolVersion': 2,
        });
      }
    });
    final service = serviceFor(relay, debugInitialSetupTimeout: const Duration(milliseconds: 10));

    await expectLater(
      _withRetryBackoffShortened(() => service.joinSession('lostj')),
      throwsA(
        isA<PeerError>()
            .having((error) => error.type, 'type', PeerErrorType.timeout)
            .having((error) => error.message, 'message', isNotEmpty),
      ),
    );

    expect(relay.messages.map((messages) => messages.map((message) => message['type']).toList()).toList(), [
      ['join'],
      ['join'],
      ['join'],
      ['join', 'leave'],
    ]);
    final announcements = relay.messages.map((messages) => messages.first).toList();
    expect(announcements.map((message) => message['peerId']).toSet(), hasLength(1));
    expect(announcements.map((message) => message['reconnectToken']).toSet(), hasLength(1));
    expect(service.sessionId, isNull);
    expect(service.myPeerId, isNull);
  });

  test('guest initial setup treats ended as terminal rather than joined', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'join') {
        relay.send(socket, {'type': 'ended', 'sessionId': message['sessionId'], 'protocolVersion': 2});
      }
    });
    final service = serviceFor(relay);
    final ended = service.onSessionEnded.first;

    await expectLater(
      service.joinSession('ended2'),
      throwsA(
        isA<PeerError>()
            .having((error) => error.type, 'type', PeerErrorType.invalidSession)
            .having((error) => error.message, 'message', t.watchTogether.errors.sessionEnded),
      ),
    );
    await ended.timeout(const Duration(seconds: 1));

    expect(service.sessionId, isNull);
    expect(service.isConnected, isFalse);
    expect(relay.sockets, hasLength(1));
  });

  test('guest reconnect treats ended as terminal and cancels further reconnects', () async {
    late final _RelayServer relay;
    relay = await relayWith((connection, socket, message) {
      if (message['type'] != 'join') return;
      if (connection == 0) {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'hostPeerId': _relayHostId,
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
          'peers': [_relayHostId],
        });
      } else {
        relay.send(socket, {'type': 'ended', 'sessionId': message['sessionId'], 'protocolVersion': 2});
      }
    });
    final service = serviceFor(relay);
    var reconnectCallbacks = 0;
    service.onReconnected = () => reconnectCallbacks++;
    final ended = service.onSessionEnded.first;

    await _withShortenedTimer(
      original: const Duration(seconds: 2),
      replacement: const Duration(milliseconds: 10),
      body: () async {
        await service.joinSession('ended3');
        await relay.sockets.single.close();
        await ended.timeout(const Duration(seconds: 1));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
    );

    expect(reconnectCallbacks, 0);
    expect(service.isConnected, isFalse);
    expect(relay.sockets, hasLength(2));
  });

  test('guest reconnect converges to session ended after room-not-found retries are exhausted', () async {
    late final _RelayServer relay;
    relay = await relayWith((connection, socket, message) {
      if (message['type'] != 'join') return;
      if (connection == 0) {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'hostPeerId': _relayHostId,
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
          'peers': [_relayHostId],
        });
      } else {
        relay.send(socket, {'type': 'error', 'code': 'room_not_found', 'message': 'Room not found'});
      }
    });
    final service = serviceFor(relay);
    var reconnectCallbacks = 0;
    var sessionEndedEvents = 0;
    final ended = Completer<void>();
    service.onReconnected = () => reconnectCallbacks++;
    service.onSessionEnded.listen((_) {
      sessionEndedEvents++;
      if (!ended.isCompleted) ended.complete();
    });

    await _withShortenedTimer(
      original: const Duration(seconds: 2),
      replacement: const Duration(milliseconds: 10),
      body: () => _withShortenedTimer(
        original: const Duration(seconds: 4),
        replacement: const Duration(milliseconds: 10),
        body: () => _withShortenedTimer(
          original: const Duration(seconds: 6),
          replacement: const Duration(milliseconds: 10),
          body: () async {
            await service.joinSession('ended4');
            await relay.sockets.single.close();
            await ended.future.timeout(const Duration(seconds: 1));
            await Future<void>.delayed(const Duration(milliseconds: 50));
          },
        ),
      ),
    );

    expect(reconnectCallbacks, 0);
    expect(sessionEndedEvents, 1);
    expect(service.isConnected, isFalse);
    expect(relay.sockets, hasLength(4));
    expect(
      relay.messages.skip(1).map((messages) => messages.map((message) => message['type']).toList()),
      everyElement(['join']),
    );
  });

  test('initial invalid-room join remains a room-not-found error', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'join') {
        relay.send(socket, {'type': 'error', 'code': 'room_not_found', 'message': 'Room not found'});
      }
    });
    final service = serviceFor(relay);
    var sessionEndedEvents = 0;
    service.onSessionEnded.listen((_) => sessionEndedEvents++);

    await expectLater(
      service.joinSession('miss01'),
      throwsA(
        isA<PeerError>()
            .having((error) => error.type, 'type', PeerErrorType.serverError)
            .having((error) => error.serverCode, 'serverCode', 'room_not_found'),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(sessionEndedEvents, 0);
    expect(relay.messages, hasLength(1));
  });

  test('release timeout covers a pending WebSocket handshake and closes every channel', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'join') {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'hostPeerId': _relayHostId,
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
          'peers': [_relayHostId],
        });
      }
    });
    var channelCalls = 0;
    final pendingChannels = <_PendingWebSocketChannel>[];
    addTearDown(() async {
      for (final channel in pendingChannels) {
        await channel.closeForTesting();
      }
    });
    final service = serviceFor(
      relay,
      debugReleaseConnectTimeout: const Duration(milliseconds: 10),
      debugChannelFactory: (uri) {
        if (channelCalls++ == 0) return WebSocketChannel.connect(uri);
        final channel = _PendingWebSocketChannel();
        pendingChannels.add(channel);
        return channel;
      },
    );

    await service.joinSession('hang01');
    final disconnected = service.onConnectionStateChanged.firstWhere((connected) => !connected);
    await relay.sockets.single.close();
    await disconnected.timeout(const Duration(seconds: 1));

    await expectLater(_withRetryBackoffShortened(service.releaseSession), throwsA(isA<TimeoutException>()));

    expect(pendingChannels, hasLength(3));
    expect(pendingChannels.every((channel) => channel.sink.closed), isTrue);
    expect(relay.sockets, hasLength(1));
  });

  test('guest release accepts peer_id_unavailable after a processed leave loses its ACK', () async {
    late final _RelayServer relay;
    relay = await relayWith((connection, socket, message) {
      if (connection == 0 && message['type'] == 'join') {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'hostPeerId': _relayHostId,
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
          'peers': [_relayHostId],
        });
      } else if (connection == 1 && message['type'] == 'join') {
        relay.send(socket, {
          'type': 'error',
          'code': 'peer_id_unavailable',
          'message': 'Peer identity is no longer available',
        });
      }
    });
    final service = serviceFor(relay, debugReleaseTimeout: const Duration(milliseconds: 10));

    await service.joinSession('lostl');
    await _withRetryBackoffShortened(service.releaseSession);

    expect(relay.messages, hasLength(2));
    expect(relay.messages[0].map((message) => message['type']), ['join', 'leave']);
    expect(relay.messages[1].map((message) => message['type']), ['join']);
  });

  test('guest leave waits for a protocol-2 left acknowledgement', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'join') {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'hostPeerId': _relayHostId,
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
          'peers': [_relayHostId],
        });
      } else if (message['type'] == 'leave') {
        relay.send(socket, {
          'type': 'left',
          'sessionId': message['sessionId'],
          'peerId': message['peerId'],
          'protocolVersion': 2,
        });
      }
    });
    final service = serviceFor(relay);

    await service.joinSession('leave1');
    final join = relay.messages.single.single;
    await service.releaseSession();

    expect(relay.messages.single, [
      join,
      {
        'type': 'leave',
        'sessionId': 'LEAVE1',
        'peerId': service.myPeerId,
        'reconnectToken': join['reconnectToken'],
        'protocolVersion': 2,
      },
    ]);
  });

  test('sequential guest release accepts not-in-room as idempotent success', () async {
    var leaveRequests = 0;
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'join') {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'hostPeerId': _relayHostId,
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
          'peers': [_relayHostId],
        });
      } else if (message['type'] == 'leave') {
        leaveRequests++;
        if (leaveRequests == 1) {
          relay.send(socket, {
            'type': 'left',
            'sessionId': message['sessionId'],
            'peerId': message['peerId'],
            'protocolVersion': 2,
          });
        } else {
          relay.send(socket, {'type': 'error', 'code': 'not_in_room', 'message': 'Peer is not in the room'});
        }
      }
    });
    final service = serviceFor(relay);

    await service.joinSession('leave2');
    await service.releaseSession();
    await service.releaseSession();

    expect(leaveRequests, 2);
    expect(relay.messages.single.map((message) => message['type']), ['join', 'leave', 'leave']);
  });

  test('host end waits for a protocol-2 ended acknowledgement', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'create') {
        relay.send(socket, {
          'type': 'created',
          'sessionId': message['sessionId'],
          'hostPeerId': message['peerId'],
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
        });
      } else if (message['type'] == 'endSession') {
        relay.send(socket, {'type': 'ended', 'sessionId': message['sessionId'], 'protocolVersion': 2});
      }
    });
    final service = serviceFor(relay);

    await service.createSession(sessionId: 'end01');
    final create = relay.messages.single.single;
    await service.releaseSession();

    expect(relay.messages.single, [
      create,
      {
        'type': 'endSession',
        'sessionId': 'END01',
        'peerId': service.myPeerId,
        'reconnectToken': create['reconnectToken'],
        'protocolVersion': 2,
      },
    ]);
  });

  test('guest receives ended before close and does not enter reconnect', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'join') {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'hostPeerId': _relayHostId,
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
          'peers': [_relayHostId],
        });
      }
    });
    final service = serviceFor(relay);

    await _withShortenedTimer(
      original: const Duration(seconds: 2),
      replacement: const Duration(milliseconds: 10),
      body: () async {
        await service.joinSession('ended1');
        final ended = service.onSessionEnded.first;
        relay.send(relay.sockets.single, {'type': 'ended', 'sessionId': 'ENDED1', 'protocolVersion': 2});
        await ended.timeout(const Duration(seconds: 1));
        await relay.sockets.single.close();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
    );

    expect(relay.sockets, hasLength(1));
  });

  test('one setup installs one listener and sends one announcement', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'create') {
        relay.send(socket, {
          'type': 'created',
          'sessionId': message['sessionId'],
          'hostPeerId': message['peerId'],
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
        });
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

  test('explicit disconnect clears relay authority before a new setup', () async {
    late final _RelayServer relay;
    relay = await relayWith((_, socket, message) {
      if (message['type'] == 'create') {
        relay.send(socket, {
          'type': 'created',
          'sessionId': message['sessionId'],
          'hostPeerId': message['peerId'],
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
        });
      }
    });
    final service = serviceFor(relay);

    await service.createSession(sessionId: 'clear1');
    expect(service.hostPeerId, isNotNull);
    await service.disconnect();
    expect(service.hostPeerId, isNull);

    await service.createSession(sessionId: 'clear2');
    expect(relay.messages[1].single, {
      'type': 'create',
      'sessionId': 'CLEAR2',
      'peerId': service.myPeerId,
      'reconnectToken': matches(RegExp(r'^[A-Za-z0-9_-]{43}$')),
      'protocolVersion': 2,
    });
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

  test('dispose invalidates a reconnect after relay setup succeeds', () async {
    final reconnectSetupSucceeded = Completer<void>();
    final releaseReconnectPublication = Completer<void>();
    late final _RelayServer relay;
    relay = await relayWith((connection, socket, message) {
      if (connection == 0 && message['type'] == 'create') {
        relay.send(socket, {
          'type': 'created',
          'sessionId': message['sessionId'],
          'hostPeerId': message['peerId'],
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
        });
      } else if (connection == 1 && message['type'] == 'join') {
        relay.send(socket, {
          'type': 'joined',
          'sessionId': message['sessionId'],
          'hostPeerId': message['peerId'],
          'reconnectToken': message['reconnectToken'],
          'protocolVersion': 2,
          'peers': const <String>[],
        });
      }
    });
    final service = serviceFor(
      relay,
      debugReconnectSetupSucceededBarrier: () {
        reconnectSetupSucceeded.complete();
        return releaseReconnectPublication.future;
      },
    );
    var reconnectCallbacks = 0;
    service.onReconnected = () => reconnectCallbacks++;

    await _withShortenedTimer(
      original: const Duration(seconds: 2),
      replacement: const Duration(milliseconds: 10),
      body: () => service.createSession(sessionId: 'epoch1'),
    );
    await relay.sockets.single.close();
    await reconnectSetupSucceeded.future.timeout(const Duration(seconds: 1));

    service.dispose();
    releaseReconnectPublication.complete();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(reconnectCallbacks, 0);
  });
}
