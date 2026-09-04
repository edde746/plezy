import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/happy_eyeballs.dart';

void main() {
  final v6 = InternetAddress('2001:db8::1');
  final v6Alt = InternetAddress('2001:db8::2');
  final v4 = InternetAddress('192.0.2.1');
  final v4Alt = InternetAddress('192.0.2.2');

  List<String> literals(List<InternetAddress> addresses) => addresses.map((a) => a.address).toList();

  group('orderCandidates', () {
    test('keeps a single-family list as resolved', () {
      expect(literals(orderCandidates([v6, v6Alt])), ['2001:db8::1', '2001:db8::2']);
      expect(orderCandidates(const []), isEmpty);
    });

    test('interleaves families behind the resolver\'s first pick', () {
      expect(literals(orderCandidates([v6, v6Alt, v4])), ['2001:db8::1', '192.0.2.1', '2001:db8::2']);
      expect(literals(orderCandidates([v4, v4Alt, v6])), ['192.0.2.1', '2001:db8::1', '192.0.2.2']);
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

    ConnectionTask<Socket> connected() =>
        ConnectionTask.fromSocket(Socket.connect(InternetAddress.loopbackIPv4, server.port), () {});

    test('tries the resolver\'s first address first', () async {
      final attempted = <String>[];
      final task = startHappyEyeballsConnect(
        'dual.test',
        443,
        lookup: (_) async => [v6, v4],
        connect: (address, port) async {
          attempted.add(address.address);
          return connected();
        },
      );
      addTearDown((await task.socket).destroy);

      expect(attempted, ['2001:db8::1']);
    });

    test('races the next candidate after the stagger and cancels the loser', () async {
      final attempted = <String>[];
      var stalledCancelled = false;
      final task = startHappyEyeballsConnect(
        'dual.test',
        443,
        attemptDelay: const Duration(milliseconds: 30),
        lookup: (_) async => [v6, v4],
        connect: (address, port) async {
          attempted.add(address.address);
          if (address.type == InternetAddressType.IPv6) {
            return ConnectionTask.fromSocket(Completer<Socket>().future, () => stalledCancelled = true);
          }
          return connected();
        },
      );
      addTearDown((await task.socket).destroy);

      expect(attempted, ['2001:db8::1', '192.0.2.1']);
      expect(stalledCancelled, isTrue);
    });

    test('starts the next candidate immediately when one fails', () async {
      final attempted = <String>[];
      final stopwatch = Stopwatch()..start();
      final task = startHappyEyeballsConnect(
        'dual.test',
        443,
        attemptDelay: const Duration(seconds: 5),
        lookup: (_) async => [v6, v4],
        connect: (address, port) async {
          attempted.add(address.address);
          if (address.type == InternetAddressType.IPv6) throw SocketException('no route to ${address.address}');
          return connected();
        },
      );
      addTearDown((await task.socket).destroy);

      expect(attempted, ['2001:db8::1', '192.0.2.1']);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('reports the first failure when every candidate fails', () async {
      final task = startHappyEyeballsConnect(
        'dual.test',
        443,
        attemptDelay: const Duration(seconds: 5),
        lookup: (_) async => [v6, v4],
        connect: (address, port) async => throw SocketException('no route to ${address.address}'),
      );

      await expectLater(
        task.socket,
        throwsA(isA<SocketException>().having((e) => e.message, 'message', contains('2001:db8::1'))),
      );
    });

    test('propagates a lookup failure', () async {
      final task = startHappyEyeballsConnect(
        'missing.test',
        443,
        lookup: (host) async => throw SocketException("Failed host lookup: '$host'"),
        connect: (address, port) async => fail('must not connect'),
      );

      await expectLater(task.socket, throwsA(isA<SocketException>()));
    });

    test('cancel tears down every in-flight attempt', () async {
      var cancels = 0;
      final task = startHappyEyeballsConnect(
        'dual.test',
        443,
        attemptDelay: const Duration(milliseconds: 10),
        lookup: (_) async => [v6, v4],
        connect: (address, port) async => ConnectionTask.fromSocket(Completer<Socket>().future, () => cancels++),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      task.cancel();

      await expectLater(task.socket, throwsA(isA<SocketException>()));
      expect(cancels, 2);
    });

    test('cancel during the lookup never connects', () async {
      final lookup = Completer<List<InternetAddress>>();
      var connects = 0;
      final task = startHappyEyeballsConnect(
        'dual.test',
        443,
        lookup: (_) => lookup.future,
        connect: (address, port) async {
          connects++;
          return connected();
        },
      );
      task.cancel();
      await expectLater(task.socket, throwsA(isA<SocketException>()));

      lookup.complete([v4]);
      await Future<void>.delayed(Duration.zero);
      expect(connects, 0);
    });

    test('skips the resolver for an address literal', () async {
      final attempted = <String>[];
      final task = startHappyEyeballsConnect(
        '192.0.2.1',
        443,
        lookup: (_) async => fail('must not resolve'),
        connect: (address, port) async {
          attempted.add(address.address);
          return connected();
        },
      );
      addTearDown((await task.socket).destroy);

      expect(attempted, ['192.0.2.1']);
    });

    test('decodes a percent-encoded link-local zone', () async {
      final attempted = <String>[];
      final task = startHappyEyeballsConnect(
        'fe80::1%25lo0',
        443,
        connect: (address, port) async {
          attempted.add(address.address);
          return connected();
        },
      );
      addTearDown((await task.socket).destroy);

      expect(attempted, ['fe80::1%lo0']);
    });

    test('secure: true performs a TLS handshake', () async {
      final plaintext = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final greeter = plaintext.listen((socket) => socket.add('HTTP/1.1 200 OK\r\n'.codeUnits));
      addTearDown(() async {
        await greeter.cancel();
        await plaintext.close();
      });

      final task = startHappyEyeballsConnect(
        'plex.invalid',
        plaintext.port,
        secure: true,
        lookup: (_) async => [InternetAddress.loopbackIPv4],
      );

      await expectLater(task.socket, throwsA(anyOf(isA<TlsException>(), isA<SocketException>())));
    });
  });

  group('happyEyeballsConnectionFactory', () {
    test('bounds the lookup by HttpClient.connectionTimeout', () async {
      final client = HttpClient()
        ..connectionTimeout = const Duration(milliseconds: 100)
        ..connectionFactory = (url, proxyHost, proxyPort) => Future.value(
          startHappyEyeballsConnect(url.host, url.port, lookup: (_) => Completer<List<InternetAddress>>().future),
        );
      addTearDown(() => client.close(force: true));

      await expectLater(client.getUrl(Uri.parse('http://stalled.test/')), throwsA(isA<SocketException>()));
    });

    test('hands a plain socket to a proxy', () async {
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
