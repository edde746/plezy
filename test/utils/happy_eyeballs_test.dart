import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/happy_eyeballs.dart';

/// dart:io's own connect path resolves A and AAAA separately and delays the
/// AAAA lookup to favour IPv4, so a dual-stack server with a healthy IPv4 path
/// is never tried over IPv6. These tests pin the replacement behaviour: the
/// resolver's ordering is what decides, and the fallback stays fast.
void main() {
  final v6 = InternetAddress('2001:db8::1');
  final v6Alt = InternetAddress('2001:db8::2');
  final v4 = InternetAddress('192.0.2.1');
  final v4Alt = InternetAddress('192.0.2.2');

  List<String> literals(List<InternetAddress> addresses) => addresses.map((a) => a.address).toList();

  group('orderCandidates', () {
    test('keeps the resolver order when only one family resolved', () {
      expect(literals(orderCandidates([v6, v6Alt])), ['2001:db8::1', '2001:db8::2']);
    });

    test('interleaves families without overriding the leading one', () {
      expect(literals(orderCandidates([v6, v6Alt, v4])), ['2001:db8::1', '192.0.2.1', '2001:db8::2']);
    });

    test('leads with IPv4 when that is what the resolver ranked first', () {
      expect(literals(orderCandidates([v4, v4Alt, v6])), ['192.0.2.1', '2001:db8::1', '192.0.2.2']);
    });

    test('passes trivial lists straight through', () {
      expect(orderCandidates(const []), isEmpty);
      expect(literals(orderCandidates([v4])), ['192.0.2.1']);
    });
  });

  group('startHappyEyeballsConnect', () {
    late ServerSocket server;
    late StreamSubscription<Socket> accepted;
    final serverSide = <Socket>[];

    setUp(() async {
      server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      accepted = server.listen(serverSide.add);
    });

    tearDown(() async {
      await accepted.cancel();
      for (final socket in serverSide) {
        socket.destroy();
      }
      serverSide.clear();
      await server.close();
    });

    Future<Socket> freshSocket() => Socket.connect(InternetAddress.loopbackIPv4, server.port);

    ConnectionTask<Socket> connectedTask() => ConnectionTask.fromSocket(freshSocket(), () {});

    test('attempts the resolver first address first, IPv6 included', () async {
      final attempted = <String>[];

      final task = await startHappyEyeballsConnect(
        host: 'dual.test',
        port: 443,
        lookup: (_) async => [v6, v4],
        connect: (address, port) async {
          attempted.add(address.address);
          return connectedTask();
        },
      );
      final socket = await task.socket;
      addTearDown(socket.destroy);

      // The whole point: the AAAA candidate is tried, and tried first.
      expect(attempted, ['2001:db8::1']);
    });

    test('races the next candidate after the stagger when the first stalls', () async {
      final attempted = <String>[];
      final stalled = Completer<Socket>();
      var stalledCancelled = false;

      final task = await startHappyEyeballsConnect(
        host: 'dual.test',
        port: 443,
        attemptDelay: const Duration(milliseconds: 30),
        lookup: (_) async => [v6, v4],
        connect: (address, port) async {
          attempted.add(address.address);
          if (address.type == InternetAddressType.IPv6) {
            return ConnectionTask.fromSocket(stalled.future, () => stalledCancelled = true);
          }
          return connectedTask();
        },
      );
      final socket = await task.socket;
      addTearDown(socket.destroy);

      expect(attempted, ['2001:db8::1', '192.0.2.1']);
      expect(stalledCancelled, isTrue, reason: 'the losing attempt must be torn down');
    });

    test('starts the next candidate immediately when one fails', () async {
      final attempted = <String>[];
      final stopwatch = Stopwatch()..start();

      final task = await startHappyEyeballsConnect(
        host: 'dual.test',
        port: 443,
        // Long enough that a stagger-driven fallback would blow the assertion.
        attemptDelay: const Duration(seconds: 5),
        lookup: (_) async => [v6, v4],
        connect: (address, port) async {
          attempted.add(address.address);
          if (address.type == InternetAddressType.IPv6) {
            throw SocketException('no route to ${address.address}');
          }
          return connectedTask();
        },
      );
      final socket = await task.socket;
      stopwatch.stop();
      addTearDown(socket.destroy);

      expect(attempted, ['2001:db8::1', '192.0.2.1']);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('reports the first failure when every candidate fails', () async {
      final task = await startHappyEyeballsConnect(
        host: 'dual.test',
        port: 443,
        attemptDelay: const Duration(seconds: 5),
        lookup: (_) async => [v6, v4],
        connect: (address, port) async => throw SocketException('no route to ${address.address}'),
      );

      await expectLater(
        task.socket,
        throwsA(isA<SocketException>().having((e) => e.message, 'message', contains('2001:db8::1'))),
      );
    });

    test('cancel tears down every in-flight attempt', () async {
      var cancels = 0;
      final stalled = Completer<Socket>();

      final task = await startHappyEyeballsConnect(
        host: 'dual.test',
        port: 443,
        attemptDelay: const Duration(milliseconds: 10),
        lookup: (_) async => [v6, v4],
        connect: (address, port) async => ConnectionTask.fromSocket(stalled.future, () => cancels++),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      task.cancel();

      await expectLater(task.socket, throwsA(isA<SocketException>()));
      expect(cancels, 2);
    });

    test('skips the resolver for an address literal', () async {
      var lookups = 0;
      final attempted = <String>[];

      final task = await startHappyEyeballsConnect(
        host: '192.0.2.1',
        port: 443,
        lookup: (_) async {
          lookups++;
          return [v4];
        },
        connect: (address, port) async {
          attempted.add(address.address);
          return connectedTask();
        },
      );
      final socket = await task.socket;
      addTearDown(socket.destroy);

      expect(lookups, 0);
      expect(attempted, ['192.0.2.1']);
    });

    // Regression guard for the obligation that comes with owning
    // connectionFactory: dart:io no longer upgrades the socket, so an https URL
    // handed back unsecured would speak cleartext to port 443.
    test('secure: true really performs a TLS handshake', () async {
      final plaintext = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final greeter = plaintext.listen((socket) => socket.add('HTTP/1.1 200 OK\r\n'.codeUnits));
      addTearDown(() async {
        await greeter.cancel();
        await plaintext.close();
      });

      final task = await startHappyEyeballsConnect(
        host: 'plex.invalid',
        port: plaintext.port,
        secure: true,
        lookup: (_) async => [InternetAddress.loopbackIPv4],
      );

      // A non-TLS peer must surface as a failed handshake, never as a usable
      // socket: reaching `await task.socket` without an error would mean the
      // https request was about to go out in the clear.
      await expectLater(task.socket, throwsA(anyOf(isA<TlsException>(), isA<SocketException>())));
    });
  });

  group('happyEyeballsConnectionFactory', () {
    test('hands a plain socket to a proxy so dart:io can tunnel and secure it', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final accepted = server.listen((socket) => socket.destroy());
      addTearDown(() async {
        await accepted.cancel();
        await server.close();
      });

      final task = await happyEyeballsConnectionFactory(
        Uri.parse('https://plex.invalid/library/sections'),
        InternetAddress.loopbackIPv4.address,
        server.port,
      );
      final socket = await task.socket;
      addTearDown(socket.destroy);

      expect(socket, isNot(isA<SecureSocket>()));
    });
  });
}
