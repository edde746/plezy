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

    Future<(ConnectionTask<Socket>, Socket)> connectedPair() async {
      final listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(listener.close);
      final incoming = listener.first;
      final task = await Socket.startConnect(InternetAddress.loopbackIPv4, listener.port);
      final socket = await task.socket;
      addTearDown(socket.destroy);
      final peer = await incoming;
      addTearDown(peer.destroy);
      return (task, peer);
    }

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
      final stalledSocket = Completer<Socket>();
      final task = startHappyEyeballsConnect(
        'dual.test',
        443,
        attemptDelay: const Duration(milliseconds: 30),
        lookup: (_) async => [v6, v4],
        connect: (address, port) async {
          attempted.add(address.address);
          if (address.type == InternetAddressType.IPv6) {
            return ConnectionTask.fromSocket(stalledSocket.future, () {
              stalledCancelled = true;
              stalledSocket.completeError(const SocketException('cancelled loser'));
            });
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

    test('cancel tears down every in-flight attempt only once', () async {
      var cancels = 0;
      final bothStarted = Completer<void>();
      var starts = 0;
      final task = startHappyEyeballsConnect(
        'dual.test',
        443,
        attemptDelay: Duration.zero,
        lookup: (_) async => [v6, v4],
        connect: (address, port) async {
          final socket = Completer<Socket>.sync();
          if (++starts == 2) bothStarted.complete();
          return ConnectionTask.fromSocket(socket.future, () {
            cancels++;
            socket.completeError(const SocketException('cancelled attempt'));
          });
        },
      );
      final result = expectLater(task.socket, throwsA(isA<SocketException>()));
      await bothStarted.future;
      await Future<void>.delayed(Duration.zero);
      task.cancel();
      task.cancel();

      await result;
      expect(cancels, 2);
    });

    test('observes a native child when cancelled before task creation completes', () async {
      final childCancelled = Completer<void>();
      final task = startHappyEyeballsConnect(
        InternetAddress.loopbackIPv4.address,
        server.port,
        connect: (address, port) async {
          final child = await Socket.startConnect(address, port);
          return ConnectionTask.fromSocket(child.socket, () {
            child.cancel();
            childCancelled.complete();
          });
        },
      );
      final result = expectLater(task.socket, throwsA(isA<SocketException>()));
      task.cancel();

      await result;
      await childCancelled.future;
      await Future<void>.delayed(Duration.zero);
    });

    for (final cancelled in [true, false]) {
      final finish = cancelled ? 'cancellation' : 'another winner';

      test('consumes a late-created child cancellation error after $finish', () async {
        final creation = Completer<ConnectionTask<Socket>>();
        final started = Completer<void>();
        final childSocket = Completer<Socket>.sync();
        final childCancelled = Completer<void>();
        var cancels = 0;
        final task = startHappyEyeballsConnect(
          'dual.test',
          443,
          attemptDelay: Duration.zero,
          lookup: (_) async => [v6, v4],
          connect: (address, port) {
            if (address.type == InternetAddressType.IPv6) {
              started.complete();
              return creation.future;
            }
            return Future.value(connected());
          },
        );
        await started.future;
        if (cancelled) {
          final result = expectLater(task.socket, throwsA(isA<SocketException>()));
          task.cancel();
          task.cancel();
          await result;
        } else {
          addTearDown((await task.socket).destroy);
        }

        creation.complete(
          ConnectionTask.fromSocket(childSocket.future, () {
            cancels++;
            childSocket.completeError(const SocketException('late child cancelled'));
            childCancelled.complete();
          }),
        );
        await childCancelled.future;
        await Future<void>.delayed(Duration.zero);
        if (cancelled) task.cancel();
        expect(cancels, 1);
      });

      test('closes an already-connected task delivered after $finish', () async {
        final unwanted = await connectedPair();
        final unwantedClosed = unwanted.$2.drain<void>();
        final winner = cancelled ? null : await connectedPair();
        final creation = Completer<ConnectionTask<Socket>>();
        final started = Completer<void>();
        final task = startHappyEyeballsConnect(
          'dual.test',
          443,
          attemptDelay: Duration.zero,
          lookup: (_) async => [v6, v4],
          connect: (address, port) {
            if (address.type == InternetAddressType.IPv6) {
              started.complete();
              return creation.future;
            }
            return Future.value(winner!.$1);
          },
        );
        await started.future;
        Socket? delivered;
        addTearDown(() => delivered?.destroy());
        if (cancelled) {
          final result = expectLater(task.socket, throwsA(isA<SocketException>()));
          task.cancel();
          await result;
        } else {
          delivered = await task.socket;
        }

        creation.complete(unwanted.$1);
        await unwantedClosed;
        if (!cancelled) {
          final received = winner!.$2.first;
          delivered!.add([42]);
          await delivered.flush();
          expect(await received, [42]);
        }
      });

      test('closes an observed child that connects after $finish', () async {
        final unwanted = await connectedPair();
        final unwantedClosed = unwanted.$2.drain<void>();
        final winner = cancelled ? null : await connectedPair();
        final childSocket = Completer<Socket>();
        final childCancelled = Completer<void>();
        final started = Completer<void>();
        final task = startHappyEyeballsConnect(
          'dual.test',
          443,
          attemptDelay: cancelled ? const Duration(days: 1) : Duration.zero,
          lookup: (_) async => [v6, v4],
          connect: (address, port) async {
            if (address.type == InternetAddressType.IPv6) {
              started.complete();
              return ConnectionTask.fromSocket(childSocket.future, childCancelled.complete);
            }
            return winner!.$1;
          },
        );
        await started.future;
        Socket? delivered;
        addTearDown(() => delivered?.destroy());
        if (cancelled) {
          await Future<void>.delayed(Duration.zero);
          final result = expectLater(task.socket, throwsA(isA<SocketException>()));
          task.cancel();
          await result;
        } else {
          delivered = await task.socket;
        }

        await childCancelled.future;
        childSocket.complete(await unwanted.$1.socket);
        await unwantedClosed;
        if (!cancelled) {
          final received = winner!.$2.first;
          delivered!.add([42]);
          await delivered.flush();
          expect(await received, [42]);
        }
      });
    }

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
        'fe80::1%251',
        443,
        lookup: (_) async => fail('must not resolve a decoded address literal'),
        connect: (address, port) async {
          attempted.add(address.address);
          return connected();
        },
      );
      addTearDown((await task.socket).destroy);

      expect(attempted, ['fe80::1%1']);
    });

    test('keeps an already-decoded numeric scope without resolving it', () async {
      final attempted = <String>[];
      final task = startHappyEyeballsConnect(
        'fe80::1%1',
        443,
        lookup: (_) async => fail('must not resolve a scoped address literal'),
        connect: (address, port) async {
          attempted.add(address.address);
          return connected();
        },
      );
      addTearDown((await task.socket).destroy);

      expect(attempted, ['fe80::1%1']);
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

    test('cancel after delivery leaves the delivered socket alone', () async {
      final task = startHappyEyeballsConnect(InternetAddress.loopbackIPv4.address, server.port);
      final delivered = await task.socket;
      addTearDown(delivered.destroy);
      await _waitFor(() => serverSide.isNotEmpty);
      final received = serverSide.single.first;

      task.cancel();
      delivered.add([42]);
      await delivered.flush();

      expect(await received, [42]);
    });

    test('cancel during a real TLS handshake settles the task at once', () async {
      // The server accepts and never answers the ClientHello.
      final rawWon = Completer<void>();
      final task = startHappyEyeballsConnect(
        InternetAddress.loopbackIPv4.address,
        server.port,
        secure: true,
        connect: (address, port) async {
          final child = await Socket.startConnect(address, port);
          unawaited(child.socket.then((_) => rawWon.complete(), onError: (Object _) {}));
          return child;
        },
      );
      await rawWon.future;
      await Future<void>.delayed(Duration.zero);

      final result = expectLater(task.socket, throwsA(isA<SocketException>()));
      task.cancel();
      await result.timeout(const Duration(seconds: 1));

      // dart:io residual: nothing can abort `SecureSocket.secure` once it
      // detached the raw transport, so the peer sees the close only when the
      // handshake settles — here because the peer itself gives up.
      final peerClosed = serverSide.single.drain<void>();
      serverSide.single.destroy();
      await peerClosed;
    });

    test('cancel during the handshake destroys the socket it yields late', () async {
      final handshake = Completer<Socket>();
      Socket? raw;
      final task = startHappyEyeballsConnect(
        InternetAddress.loopbackIPv4.address,
        server.port,
        secure: true,
        upgrade: (socket, host) {
          raw = socket;
          return handshake.future;
        },
      );
      await _waitFor(() => raw != null);
      var peerClosed = false;
      unawaited(serverSide.single.drain<void>().then((_) => peerClosed = true));

      final result = expectLater(task.socket, throwsA(isA<SocketException>()));
      task.cancel();
      task.cancel();
      await result;
      // The handshake owns the transport until it settles.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(peerClosed, isFalse);

      handshake.complete(raw);
      await _waitFor(() => peerClosed);
    });

    test('a handshake failure after cancel is consumed', () async {
      final handshake = Completer<Socket>();
      final task = startHappyEyeballsConnect(
        InternetAddress.loopbackIPv4.address,
        server.port,
        secure: true,
        upgrade: (socket, host) => handshake.future,
      );
      await _waitFor(() => serverSide.isNotEmpty);
      final result = expectLater(task.socket, throwsA(isA<SocketException>()));
      task.cancel();
      await result;

      handshake.completeError(const HandshakeException('late failure'));
      await Future<void>.delayed(Duration.zero);
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

Future<void> _waitFor(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('condition not met in time');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
