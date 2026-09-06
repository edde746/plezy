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
      final lateSocketClosed = Completer<void>();
      server.listen((request) async {
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
      await Future<void>.delayed(const Duration(milliseconds: 50));
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
