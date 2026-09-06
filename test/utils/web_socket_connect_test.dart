import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/web_socket_connect.dart';

void main() {
  /// Accepts TCP connections and never answers the upgrade.
  late ServerSocket blackHole;
  final stalled = <Socket>[];
  late StreamSubscription<Socket> accepting;

  setUp(() async {
    blackHole = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    accepting = blackHole.listen(stalled.add);
  });

  tearDown(() async {
    await accepting.cancel();
    for (final socket in stalled) {
      socket.destroy();
    }
    stalled.clear();
    await blackHole.close();
  });

  Uri blackHoleUri() => Uri.parse('ws://${blackHole.address.address}:${blackHole.port}/ws');

  Future<void> peerSawClose(Socket peer) => peer.drain<void>().timeout(const Duration(seconds: 5));

  group('WebSocketConnectAttempt', () {
    test('same-turn cancellation settles without admitting a later connection', () async {
      final attempt = WebSocketConnectAttempt(blackHoleUri(), connectTimeout: const Duration(seconds: 30));
      final result = expectLater(attempt.socket, throwsA(isA<SocketException>()));
      attempt.cancel();
      await result.timeout(const Duration(seconds: 1));
      await pumpEventQueue();
      for (final peer in stalled) {
        await peerSawClose(peer);
      }
    });

    test('a delayed factory result disposes its already-connected socket before registration', () async {
      final creation = Completer<ConnectionTask<Socket>>();
      final started = Completer<void>();
      final attempt = WebSocketConnectAttempt.withConnectionFactory(
        blackHoleUri(),
        connectTimeout: const Duration(seconds: 30),
        connectionFactory: (_, _, _) {
          started.complete();
          return creation.future;
        },
      );
      addTearDown(attempt.cancel);
      final result = expectLater(attempt.socket, throwsA(isA<SocketException>()));
      await started.future;
      final outgoing = await Socket.connect(blackHole.address, blackHole.port);
      addTearDown(outgoing.destroy);
      await _waitFor(() => stalled.isNotEmpty);
      final peerClosed = peerSawClose(stalled.single);

      attempt.cancel();
      await result;
      creation.complete(ConnectionTask.fromSocket(Future.value(outgoing), () {}));

      await peerClosed;
    });

    for (final cancelFirst in [true, false]) {
      test(
        'a registered task closes its late socket with cancel ${cancelFirst ? 'before' : 'after'} publication',
        () async {
          final connected = Completer<Socket>();
          final started = Completer<void>();
          final attempt = WebSocketConnectAttempt.withConnectionFactory(
            blackHoleUri(),
            connectTimeout: const Duration(seconds: 30),
            connectionFactory: (_, _, _) {
              started.complete();
              return Future.value(ConnectionTask.fromSocket(connected.future, () {}));
            },
          );
          addTearDown(attempt.cancel);
          final result = expectLater(attempt.socket, throwsA(isA<SocketException>()));
          await started.future;
          await pumpEventQueue();
          final outgoing = await Socket.connect(blackHole.address, blackHole.port);
          addTearDown(outgoing.destroy);
          await _waitFor(() => stalled.isNotEmpty);
          final peerClosed = peerSawClose(stalled.single);

          if (cancelFirst) attempt.cancel();
          connected.complete(outgoing);
          if (!cancelFirst) attempt.cancel();

          await result;
          await peerClosed;
        },
      );
    }

    test('late factory errors and synchronous task cancellation errors are consumed', () async {
      for (final failFactory in [true, false]) {
        final creation = Completer<ConnectionTask<Socket>>();
        final started = Completer<void>();
        final cancelled = Completer<void>();
        final attempt = WebSocketConnectAttempt.withConnectionFactory(
          blackHoleUri(),
          connectTimeout: const Duration(seconds: 30),
          connectionFactory: (_, _, _) {
            started.complete();
            return creation.future;
          },
        );
        addTearDown(attempt.cancel);
        final result = expectLater(attempt.socket, throwsA(isA<SocketException>()));
        await started.future;
        attempt.cancel();
        await result;

        if (failFactory) {
          creation.completeError(const SocketException('late factory failure'));
        } else {
          final connected = Completer<Socket>.sync();
          creation.complete(
            ConnectionTask.fromSocket(connected.future, () {
              connected.completeError(const SocketException('late task cancelled'));
              cancelled.complete();
            }),
          );
          await cancelled.future.timeout(const Duration(seconds: 1));
        }
        // The test zone reports any uncaught discarded-future error.
        await pumpEventQueue();
      }
    });

    test('cancellation retains every transport requested before upgrade handoff', () async {
      final client = _PendingFactoryClient(2);
      final attempt = HttpOverrides.runZoned(
        () => WebSocketConnectAttempt.withConnectionFactory(
          blackHoleUri(),
          connectTimeout: const Duration(seconds: 30),
          connectionFactory: (_, _, _) async {
            final outgoing = await Socket.connect(blackHole.address, blackHole.port);
            addTearDown(outgoing.destroy);
            return ConnectionTask.fromSocket(Future.value(outgoing), () {});
          },
        ),
        createHttpClient: (_) => client,
      );
      addTearDown(attempt.cancel);
      final result = expectLater(attempt.socket, throwsA(isA<SocketException>()));
      await client.created.future.timeout(const Duration(seconds: 5));
      await _waitFor(() => stalled.length == 2);
      final closed = stalled.map(peerSawClose).toList();

      attempt.cancel();

      await result;
      await Future.wait(closed);
    });

    test('cancel settles the socket at once and closes the stalled peer', () async {
      final attempt = WebSocketConnectAttempt(blackHoleUri(), connectTimeout: const Duration(seconds: 30));
      await _waitFor(() => stalled.isNotEmpty);
      final peerClosed = peerSawClose(stalled.single);

      final result = expectLater(attempt.socket, throwsA(isA<SocketException>()));
      attempt.cancel();
      attempt.cancel();
      await result.timeout(const Duration(seconds: 1));
      await peerClosed;
    });

    test('the deadline fails the attempt with a TimeoutException and closes the peer', () async {
      final attempt = WebSocketConnectAttempt(blackHoleUri(), connectTimeout: const Duration(milliseconds: 200));
      await _waitFor(() => stalled.isNotEmpty);
      final peerClosed = peerSawClose(stalled.single);

      await expectLater(attempt.socket, throwsA(isA<TimeoutException>()));
      await peerClosed;
    });

    test('an upgrade landing after cancel is closed, not leaked', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final releaseUpgrade = Completer<void>();
      final requestArrived = Completer<void>();
      final lateSocketClosed = Completer<void>();
      server.listen((request) async {
        requestArrived.complete();
        await releaseUpgrade.future;
        final socket = await WebSocketTransformer.upgrade(request);
        socket.listen((_) {}, onDone: socket.close);
        unawaited(socket.done.then((_) => lateSocketClosed.complete()));
      });

      final attempt = WebSocketConnectAttempt(
        Uri.parse('ws://${server.address.address}:${server.port}/ws'),
        connectTimeout: const Duration(seconds: 30),
      );
      final result = expectLater(attempt.socket, throwsA(isA<SocketException>()));
      await requestArrived.future.timeout(const Duration(seconds: 5));
      attempt.cancel();
      await result;

      releaseUpgrade.complete();
      await lateSocketClosed.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => fail('late websocket was never closed by the client'),
      );
    });

    test('a delivered socket survives a later cancel', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final received = Completer<dynamic>();
      server.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        socket.listen((data) {
          received.complete(data);
          socket.close();
        });
      });

      final attempt = WebSocketConnectAttempt(
        Uri.parse('ws://${server.address.address}:${server.port}/ws'),
        connectTimeout: const Duration(seconds: 30),
      );
      final webSocket = await attempt.socket;
      addTearDown(webSocket.close);

      attempt.cancel();
      webSocket.add('still here');

      expect(await received.future.timeout(const Duration(seconds: 5)), 'still here');
    });

    test('redirected upgrade transfers ownership of the delivered transport', () async {
      final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final redirect = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => target.close(force: true));
      addTearDown(() => redirect.close(force: true));
      target.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        addTearDown(socket.close);
        socket.listen(socket.add, onDone: socket.close);
      });
      redirect.listen((request) {
        unawaited(request.response.redirect(Uri.parse('http://${target.address.address}:${target.port}/ws')));
      });
      final attempt = WebSocketConnectAttempt.withConnectionFactory(
        Uri.parse('ws://${redirect.address.address}:${redirect.port}/ws'),
        connectTimeout: const Duration(seconds: 30),
        connectionFactory: (url, _, _) async {
          final socket = await Socket.connect(url.host, url.port);
          addTearDown(socket.destroy);
          return ConnectionTask.fromSocket(Future.value(socket), () {});
        },
      );
      addTearDown(attempt.cancel);
      final socket = await attempt.socket.timeout(const Duration(seconds: 5));
      addTearDown(socket.close);
      attempt.cancel();
      attempt.cancel();

      socket.add('after redirect and cancellation');
      expect(await socket.first.timeout(const Duration(seconds: 5)), 'after redirect and cancellation');
    });
  });

  group('connectWebSocketChannel', () {
    test('closing the sink before ready cancels the attempt', () async {
      final channel = connectWebSocketChannel(blackHoleUri(), connectTimeout: const Duration(seconds: 30));
      await _waitFor(() => stalled.isNotEmpty);
      final peerClosed = peerSawClose(stalled.single);

      final ready = expectLater(channel.ready, throwsA(anything));
      unawaited(channel.sink.close());
      await ready.timeout(const Duration(seconds: 1));
      await peerClosed;
    });

    test('an established channel exchanges frames and closes normally', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        socket.listen(socket.add, onDone: socket.close);
      });

      final channel = connectWebSocketChannel(
        Uri.parse('ws://${server.address.address}:${server.port}/ws'),
        connectTimeout: const Duration(seconds: 30),
      );
      await channel.ready;
      channel.sink.add('echo');
      expect(await channel.stream.first.timeout(const Duration(seconds: 5)), 'echo');
      await channel.sink.close();
    });
  });
}

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('condition not met in time');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

/// Holds factory results in the SDK's pre-registration interval. Multiple
/// invocations model redirect/proxy alternatives, but all transports are real
/// loopback sockets and this client deliberately cannot clean them up.
class _PendingFactoryClient implements HttpClient {
  _PendingFactoryClient(this.count);

  final int count;
  final created = Completer<void>();
  final _request = Completer<HttpClientRequest>();
  late Future<ConnectionTask<Socket>> Function(Uri, String?, int?) _factory;

  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri, String?, int?)? value) {
    _factory = value!;
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    await Future.wait([for (var i = 0; i < count; i++) _factory(url, null, null)]);
    created.complete();
    return _request.future;
  }

  @override
  void close({bool force = false}) {
    if (!_request.isCompleted) _request.completeError(const SocketException('HTTP client closed'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
