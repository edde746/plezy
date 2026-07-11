import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/companion_remote/companion_remote_peer_service.dart';
import 'package:plezy/services/companion_remote/remote_auth_context.dart';

void main() {
  group('CompanionRemotePeerService disconnect after fast connect failure', () {
    late ServerSocket server;
    late CompanionRemotePeerService service;
    var accepted = 0;

    setUp(() async {
      accepted = 0;
      // A server that immediately destroys every incoming connection. This makes
      // the client's `_channel!.ready` throw before any WebSocket upgrade, so the
      // join fails fast without entering the 15s timeout path (which would pull in
      // i18n). We only care that a TCP socket was opened, hence the counter.
      server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((socket) {
        accepted++;
        socket.destroy();
      });
      service = CompanionRemotePeerService();
    });

    tearDown(() async {
      await service.dispose();
      await server.close();
    });

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

    test('disconnect completes quickly and a second connect opens a new socket', () async {
      final address = '127.0.0.1:${server.port}';

      // First attempt: fails fast because the host destroys the socket.
      await expectLater(
        service.joinSessionWithContexts('test', 'test', address, [authContext()]),
        throwsA(isA<Object>()),
      );

      // Pre-fix, disconnect() awaits `_channel!.sink.close()` on a dead socket
      // whose close never completes, hanging forever. Post-fix it is bounded.
      await service.disconnect().timeout(
        const Duration(seconds: 5),
        onTimeout: () => fail('disconnect() hung on a dead channel'),
      );

      // Second attempt must actually open a new TCP socket. Pre-fix the flow
      // wedges inside joinSessionWithContexts' internal disconnect() and never
      // reaches the connect, so `accepted` stays at 1.
      await expectLater(
        service.joinSessionWithContexts('test', 'test', address, [authContext()]),
        throwsA(isA<Object>()),
      );

      expect(accepted, 2, reason: 'a second TCP socket should have been opened');
    });
  });
}
