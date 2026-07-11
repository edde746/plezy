import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/companion_remote/companion_remote_peer_service.dart';
import 'package:plezy/services/companion_remote/remote_auth_context.dart';

void main() {
  RemoteAuthContext authContext() => const RemoteAuthContext(
    id: 'test-context',
    backend: 'legacy',
    connectionId: '',
    homeSecret: [1, 2, 3, 4],
    discoveryKey: [],
    clientIdentifier: 'test-client',
    userUuid: 'test-user',
    allowedUserUuids: ['test-user'],
  );

  group('CompanionRemotePeerService connect is time-bounded', () {
    test('a dead endpoint that accepts but never speaks WS fails in well under 15s', () async {
      // Accept the TCP connection but never upgrade to WebSocket and never send
      // anything. Pre-fix, IOWebSocketChannel.connect() with no connectTimeout
      // leaves `await _channel!.ready` hanging until the OS TCP timeout
      // (~2 minutes); post-fix the 5s connectTimeout bounds it.
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sub = server.listen((socket) {
        // Accept and hold the connection open; never respond.
      });
      addTearDown(() async {
        await sub.cancel();
        await server.close();
      });

      final service = CompanionRemotePeerService();
      addTearDown(() => service.dispose());

      final address = '127.0.0.1:${server.port}';
      final stopwatch = Stopwatch()..start();

      await expectLater(
        service.joinSessionWithContexts('test', 'test', address, [authContext()]),
        throwsA(isA<Object>()),
      );

      stopwatch.stop();
      expect(
        stopwatch.elapsed < const Duration(seconds: 10),
        isTrue,
        reason: 'connect should fail in ~5s via connectTimeout, not hang toward the ~2min OS TCP timeout '
            '(took ${stopwatch.elapsed})',
      );
    });

    test('a connection-refused address fails promptly', () async {
      // Bind, note the port, then close it so nothing is listening — the OS
      // should refuse the connection immediately (no need for connectTimeout
      // to kick in here, but it must not regress into a slow path either).
      final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = probe.port;
      await probe.close();

      final service = CompanionRemotePeerService();
      addTearDown(() => service.dispose());

      final address = '127.0.0.1:$port';
      final stopwatch = Stopwatch()..start();

      await expectLater(
        service.joinSessionWithContexts('test', 'test', address, [authContext()]),
        throwsA(isA<Object>()),
      );

      stopwatch.stop();
      expect(
        stopwatch.elapsed < const Duration(seconds: 10),
        isTrue,
        reason: 'connection-refused should fail promptly (took ${stopwatch.elapsed})',
      );
    });
  });
}
