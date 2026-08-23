import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/companion_remote/remote_command.dart';
import 'package:plezy/models/companion_remote/remote_session.dart';
import 'package:plezy/services/companion_remote/companion_remote_peer_service.dart';
import 'package:plezy/services/companion_remote/remote_auth_context.dart';
import 'package:plezy/services/companion_remote/remote_auth_service.dart';

const _ioTimeout = Duration(seconds: 5);

void main() {
  test('auth precondition error uses the active locale', () async {
    await LocaleSettings.setLocale(AppLocale.bg);
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
    final peer = CompanionRemotePeerService();
    addTearDown(peer.dispose);

    await expectLater(
      () => peer.createSessionForContexts('Test Host', 'macos', const []),
      throwsA(isA<PeerError>().having((error) => error.message, 'message', 'Неуспешно удостоверяване')),
    );
  });

  test('per-source admission rejects before upgrade and recovers exactly one slot', () async {
    final host = CompanionRemotePeerService.forTesting(maxTotalHostConnections: 4, maxHostConnectionsPerSource: 2);
    final clients = <_RawWebSocketClient>[];
    addTearDown(() => _disposeHostAndClients(host, clients));
    final port = await _startHost(host);

    clients.add(await _RawWebSocketClient.connect(port));
    clients.add(await _RawWebSocketClient.connect(port));
    await _expectWebSocketHandshakeStatus(port, HttpStatus.tooManyRequests);
    expect(clients, everyElement(predicate<_RawWebSocketClient>((client) => client.isOpen)));

    await clients.removeAt(0).dispose();
    clients.add(await _RawWebSocketClient.connect(port));
    await _expectWebSocketHandshakeStatus(port, HttpStatus.tooManyRequests);
  });

  test('global admission rejects independently and releases one reservation once', () async {
    final host = CompanionRemotePeerService.forTesting(maxTotalHostConnections: 2, maxHostConnectionsPerSource: 4);
    final clients = <_RawWebSocketClient>[];
    addTearDown(() => _disposeHostAndClients(host, clients));
    final port = await _startHost(host);

    clients.add(await _RawWebSocketClient.connect(port));
    clients.add(await _RawWebSocketClient.connect(port));
    await _expectWebSocketHandshakeStatus(port, HttpStatus.tooManyRequests);

    await clients.removeAt(0).dispose();
    clients.add(await _RawWebSocketClient.connect(port));
    await _expectWebSocketHandshakeStatus(port, HttpStatus.tooManyRequests);
  });

  test('authentication timeout releases capacity for a legitimate encrypted session', () async {
    final host = CompanionRemotePeerService.forTesting(
      maxTotalHostConnections: 1,
      maxHostConnectionsPerSource: 1,
      authTimeout: const Duration(milliseconds: 300),
    );
    final remote = CompanionRemotePeerService();
    final clients = <_RawWebSocketClient>[];
    addTearDown(() async {
      await remote.dispose();
      await _disposeHostAndClients(host, clients);
    });
    final port = await _startHost(host);

    final silent = await _RawWebSocketClient.connect(port);
    clients.add(silent);
    expect(await silent.closed.timeout(_ioTimeout), 4001);
    clients.remove(silent);

    await remote.joinSessionWithContexts(
      'Test Remote',
      'ios',
      '127.0.0.1:$port',
      [_authContext],
      authContextId: _authContext.id,
      expectedHostClientId: _authContext.clientIdentifier,
    );
    final command = host.onCommandReceived.firstWhere((event) => event.type == RemoteCommandType.play);
    remote.sendCommand(const RemoteCommand(type: RemoteCommandType.play));
    expect((await command.timeout(_ioTimeout)).type, RemoteCommandType.play);
  });

  test('disconnect closes pending sockets and restart restores full capacity', () async {
    final host = CompanionRemotePeerService.forTesting(
      maxTotalHostConnections: 2,
      maxHostConnectionsPerSource: 2,
      authTimeout: const Duration(seconds: 1),
    );
    final clients = <_RawWebSocketClient>[];
    addTearDown(() => _disposeHostAndClients(host, clients));
    var port = await _startHost(host);

    final firstGeneration = [await _RawWebSocketClient.connect(port), await _RawWebSocketClient.connect(port)];
    clients.addAll(firstGeneration);
    await host.disconnect();
    expect(
      await Future.wait(firstGeneration.map((client) => client.closed.timeout(_ioTimeout))),
      everyElement(isNot(4001)),
    );
    clients.removeWhere(firstGeneration.contains);

    port = await _startHost(host);
    clients.add(await _RawWebSocketClient.connect(port));
    clients.add(await _RawWebSocketClient.connect(port));
    await _expectWebSocketHandshakeStatus(port, HttpStatus.tooManyRequests);
  });

  test('failed HTTP upgrade and abrupt socket loss both release the only slot', () async {
    final host = CompanionRemotePeerService.forTesting(maxTotalHostConnections: 1, maxHostConnectionsPerSource: 1);
    final clients = <_RawWebSocketClient>[];
    addTearDown(() => _disposeHostAndClients(host, clients));
    final port = await _startHost(host);

    final httpClient = HttpClient();
    addTearDown(() => httpClient.close(force: true));
    final request = await httpClient.getUrl(Uri.parse('http://127.0.0.1:$port/ws'));
    final response = await request.close();
    expect(response.statusCode, HttpStatus.badRequest);
    await response.drain<void>();

    final afterFailedUpgrade = await _RawWebSocketClient.connect(port);
    clients.add(afterFailedUpgrade);
    await afterFailedUpgrade.dispose();
    clients.remove(afterFailedUpgrade);

    final abrupt = await _RawUpgradedSocket.connect(port);
    addTearDown(abrupt.dispose);
    await abrupt.dispose();
    await _flushEventQueue();

    clients.add(await _RawWebSocketClient.connect(port));
    await _expectWebSocketHandshakeStatus(port, HttpStatus.tooManyRequests);
  });

  test('setup failure after upgrade closes the socket and releases the only slot', () async {
    var rejectSetup = true;
    final host = CompanionRemotePeerService.forTesting(
      maxTotalHostConnections: 1,
      maxHostConnectionsPerSource: 1,
      afterHostUpgrade: () {
        if (!rejectSetup) return;
        rejectSetup = false;
        throw StateError('injected admission setup failure');
      },
    );
    final clients = <_RawWebSocketClient>[];
    addTearDown(() => _disposeHostAndClients(host, clients));
    final port = await _startHost(host);

    final rejected = await WebSocket.connect('ws://127.0.0.1:$port/ws');
    try {
      await rejected.drain<void>().timeout(_ioTimeout);
      expect(rejected.readyState, WebSocket.closed);
    } finally {
      await rejected.close();
    }

    clients.add(await _RawWebSocketClient.connect(port));
    await _expectWebSocketHandshakeStatus(port, HttpStatus.tooManyRequests);
  });

  test('oversized and malformed first messages close generically and always restore capacity', () async {
    final host = CompanionRemotePeerService.forTesting(
      maxTotalHostConnections: 1,
      maxHostConnectionsPerSource: 1,
      maxPreAuthMessageBytes: 256,
      maxFailedAuthAttempts: 20,
    );
    final clients = <_RawWebSocketClient>[];
    final connected = <Object>[];
    final commands = <RemoteCommand>[];
    final connectedSubscription = host.onDeviceConnected.listen(connected.add);
    final commandSubscription = host.onCommandReceived.listen(commands.add);
    addTearDown(() async {
      await connectedSubscription.cancel();
      await commandSubscription.cancel();
      await _disposeHostAndClients(host, clients);
    });
    final port = await _startHost(host);

    final cases = <({String name, dynamic payload, int closeCode})>[
      (name: 'oversized text', payload: 'x' * 257, closeCode: 4003),
      (name: 'oversized UTF-8 text', payload: 'é' * 129, closeCode: 4003),
      (name: 'binary input', payload: <int>[1, 2, 3], closeCode: 4003),
      (name: 'invalid JSON', payload: '{', closeCode: 4003),
      (name: 'non-map JSON', payload: '[]', closeCode: 4003),
      (name: 'invalid Base64', payload: _minimalAuth(clientNonce: '%%%'), closeCode: 4003),
      (name: 'wrong nonce length', payload: _minimalAuth(clientNonce: base64Encode([1, 2])), closeCode: 4003),
      (name: 'missing fields', payload: jsonEncode({'type': 'auth'}), closeCode: 4003),
      (
        name: 'wrong field type',
        payload: jsonEncode({
          'type': 'auth',
          'authTag': 1,
          'clientNonce': base64Encode(List<int>.filled(32, 1)),
          'userUUID': 'user-1',
          'clientIdentifier': 'remote-client',
          'deviceName': 'Remote',
          'platform': 'test',
        }),
        closeCode: 4003,
      ),
      (name: 'unexpected type', payload: jsonEncode({'type': 'ping'}), closeCode: 4002),
    ];

    for (final malformedCase in cases) {
      final client = await _RawWebSocketClient.connect(port);
      clients.add(client);
      client.add(malformedCase.payload);
      await client.authFailed.timeout(_ioTimeout);
      expect(await client.closed.timeout(_ioTimeout), malformedCase.closeCode, reason: malformedCase.name);
      clients.remove(client);
    }

    final capacityProbe = await _RawWebSocketClient.connect(port);
    clients.add(capacityProbe);
    expect(capacityProbe.isOpen, isTrue);
    expect(connected, isEmpty);
    expect(commands, isEmpty);
  });

  test('malformed first message counts once, ignores a queued valid auth, and locks out before upgrade', () async {
    final host = CompanionRemotePeerService.forTesting(
      maxTotalHostConnections: 2,
      maxHostConnectionsPerSource: 2,
      maxFailedAuthAttempts: 2,
    );
    final clients = <_RawWebSocketClient>[];
    final connected = <Object>[];
    final subscription = host.onDeviceConnected.listen(connected.add);
    addTearDown(() async {
      await subscription.cancel();
      await _disposeHostAndClients(host, clients);
    });
    final port = await _startHost(host);

    final first = await _RawWebSocketClient.connect(port);
    clients.add(first);
    final validAuth = _validAuthMessage(first.challenge, _authContext);
    first.add('{');
    first.add(validAuth);
    await first.authFailed.timeout(_ioTimeout);
    expect(await first.closed.timeout(_ioTimeout), 4003);
    clients.remove(first);

    final second = await _RawWebSocketClient.connect(port);
    clients.add(second);
    second.add(<int>[9]);
    await second.authFailed.timeout(_ioTimeout);
    expect(await second.closed.timeout(_ioTimeout), 4003);
    clients.remove(second);

    await _expectWebSocketHandshakeStatus(port, HttpStatus.tooManyRequests);
    expect(connected, isEmpty);
  });

  test('unknown context, disallowed user, and bad HMAC share the terminal auth failure path', () async {
    final host = CompanionRemotePeerService.forTesting(maxFailedAuthAttempts: 10);
    final clients = <_RawWebSocketClient>[];
    addTearDown(() => _disposeHostAndClients(host, clients));
    final port = await _startHost(host);

    final attempts = <String Function(_RawWebSocketClient)>[
      (client) => _validAuthMessage(client.challenge, _authContext, authContextId: 'missing-context'),
      (client) => _validAuthMessage(client.challenge, _authContext, userUuid: 'disallowed-user'),
      (client) => _validAuthMessage(client.challenge, _authContext, authTag: 'invalid-tag'),
    ];

    for (final message in attempts) {
      final client = await _RawWebSocketClient.connect(port);
      clients.add(client);
      client.add(message(client));
      await client.authFailed.timeout(_ioTimeout);
      expect(await client.closed.timeout(_ioTimeout), 4003);
      clients.remove(client);
    }
  });

  test('single-context auth remains compatible without authContextId', () async {
    final host = CompanionRemotePeerService.forTesting();
    final clients = <_RawWebSocketClient>[];
    addTearDown(() => _disposeHostAndClients(host, clients));
    final port = await _startHost(host);

    final client = await _RawWebSocketClient.connect(port);
    clients.add(client);
    final connected = host.onDeviceConnected.first;
    client.add(_validAuthMessage(client.challenge, _authContext, includeAuthContextId: false));

    await connected.timeout(_ioTimeout);
    expect(host.isConnected, isTrue);
    expect(host.selectedAuthContextId, _authContext.id);
  });

  test('closed authentication race cannot commit and replacement late close cannot clear the winner', () async {
    final secondDerivationEntered = Completer<void>();
    final releaseSecondDerivation = Completer<void>();
    final secondDerivationReturned = Completer<void>();
    var derivationCount = 0;
    final host = CompanionRemotePeerService.forTesting(
      deriveSessionEncKey: (homeSecret, hostNonce, clientNonce) async {
        derivationCount++;
        if (derivationCount == 2) {
          secondDerivationEntered.complete();
          await releaseSecondDerivation.future;
        }
        final key = await RemoteAuthService.instance.deriveSessionEncKey(homeSecret, hostNonce, clientNonce);
        if (derivationCount == 2 && !secondDerivationReturned.isCompleted) {
          secondDerivationReturned.complete();
        }
        return key;
      },
    );
    final clients = <_RawWebSocketClient>[];
    final connected = <Object>[];
    final subscription = host.onDeviceConnected.listen(connected.add);
    addTearDown(() async {
      if (!releaseSecondDerivation.isCompleted) releaseSecondDerivation.complete();
      await subscription.cancel();
      await _disposeHostAndClients(host, clients);
    });
    final port = await _startHost(host);

    final original = await _RawWebSocketClient.connect(port);
    clients.add(original);
    final originalConnected = host.onDeviceConnected.first;
    original.add(_validAuthMessage(original.challenge, _authContext, deviceName: 'Original'));
    await originalConnected.timeout(_ioTimeout);
    expect(host.isConnected, isTrue);

    final racing = await _RawWebSocketClient.connect(port);
    clients.add(racing);
    racing.add(_validAuthMessage(racing.challenge, _authContext, deviceName: 'Closed racer'));
    await secondDerivationEntered.future.timeout(_ioTimeout);
    await racing.dispose();
    clients.remove(racing);
    releaseSecondDerivation.complete();
    await secondDerivationReturned.future.timeout(_ioTimeout);
    await _flushEventQueue();

    expect(host.isConnected, isTrue);
    expect(original.isOpen, isTrue);
    expect(connected, hasLength(1));

    final replacement = await _RawWebSocketClient.connect(port);
    clients.add(replacement);
    final replacementConnected = host.onDeviceConnected.first;
    replacement.add(_validAuthMessage(replacement.challenge, _authContext, deviceName: 'Replacement'));
    await replacementConnected.timeout(_ioTimeout);
    expect(await original.closed.timeout(_ioTimeout), 4004);
    clients.remove(original);
    await _flushEventQueue();

    expect(host.isConnected, isTrue);
    expect(connected, hasLength(2));
  });

  test('address probes release every source slot before the managed connection', () async {
    final host = CompanionRemotePeerService.forTesting(maxTotalHostConnections: 2, maxHostConnectionsPerSource: 2);
    final remote = CompanionRemotePeerService();
    addTearDown(() async {
      await remote.dispose();
      await host.dispose();
    });
    final port = await _startHost(host);
    final address = '127.0.0.1:$port';

    final winner = await remote.joinSessionRacingWithContexts(
      'Test Remote',
      'ios',
      [address, address],
      [_authContext],
      authContextId: _authContext.id,
      expectedHostClientId: _authContext.clientIdentifier,
    );

    expect(winner, address);
    final command = host.onCommandReceived.firstWhere((event) => event.type == RemoteCommandType.play);
    remote.sendCommand(const RemoteCommand(type: RemoteCommandType.play));
    expect((await command.timeout(_ioTimeout)).type, RemoteCommandType.play);
  });

  test('managed join waits for every probe terminal event and listener cleanup', () async {
    final closeRequested = List.generate(2, (_) => Completer<void>());
    final listenerCleanedUp = List.generate(2, (_) => Completer<void>());
    final controllers = List.generate(2, (_) => StreamController<dynamic>(sync: true));
    var nextProbe = 0;
    final managedJoinStarted = Completer<void>();
    late final _ManagedJoinObservingPeer remote;
    remote = _ManagedJoinObservingPeer(
      raceProbeFactory: (_) {
        final index = nextProbe++;
        return (
          close: () async {
            if (!closeRequested[index].isCompleted) {
              closeRequested[index].complete();
            }
          },
          ready: Future<void>.value(),
          stream: _CancelTrackingStream(controllers[index].stream, () {
            if (!listenerCleanedUp[index].isCompleted) {
              listenerCleanedUp[index].complete();
            }
          }),
        );
      },
      onManagedJoin: () async {
        expect(listenerCleanedUp, everyElement(predicate<Completer<void>>((item) => item.isCompleted)));
        managedJoinStarted.complete();
      },
    );
    addTearDown(() async {
      for (final controller in controllers) {
        if (!controller.isClosed) await controller.close();
      }
      await remote.dispose();
    });

    final join = remote.joinSessionRacingWithContexts(
      'Test Remote',
      'ios',
      const ['probe-a', 'probe-b'],
      [_authContext],
    );
    expect(nextProbe, 2);

    controllers.first.add(jsonEncode({'type': 'challenge'}));
    await closeRequested.first.future.timeout(_ioTimeout);
    expect(managedJoinStarted.isCompleted, isFalse);

    await controllers.first.close();
    await closeRequested.last.future.timeout(_ioTimeout);
    expect(listenerCleanedUp.first.isCompleted, isTrue);
    expect(managedJoinStarted.isCompleted, isFalse);

    await controllers.last.close();
    expect(await join.timeout(_ioTimeout), 'probe-a');
    expect(listenerCleanedUp, everyElement(predicate<Completer<void>>((item) => item.isCompleted)));
    expect(managedJoinStarted.isCompleted, isTrue);
  });

  test('race cleanup does not hang behind a candidate that never finishes connecting', () async {
    final host = CompanionRemotePeerService();
    final remote = CompanionRemotePeerService();
    // Accepts the TCP connection but never answers the WebSocket upgrade,
    // like a beacon-advertised virtual-adapter address that black-holes.
    final blackHole = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final stalledSockets = <Socket>[];
    final blackHoleSubscription = blackHole.listen(stalledSockets.add);
    addTearDown(() async {
      await remote.dispose();
      await host.dispose();
      await blackHoleSubscription.cancel();
      for (final socket in stalledSockets) {
        socket.destroy();
      }
      await blackHole.close();
    });

    final session = await host.createSessionForContexts('Test Host', 'macos', [_authContext]);
    final hostAddress = '127.0.0.1:${session.port}';

    // Pre-fix, probe cleanup awaited a `sink.close()` that never completes
    // for a still-connecting candidate, so the managed join after a won race
    // never started; the deadline is what distinguishes pass from hang.
    final winner = await remote
        .joinSessionRacingWithContexts(
          'Test Remote',
          'ios',
          ['127.0.0.1:${blackHole.port}', hostAddress],
          [_authContext],
          authContextId: _authContext.id,
          expectedHostClientId: _authContext.clientIdentifier,
        )
        .timeout(_ioTimeout);

    expect(winner, hostAddress);
    final command = host.onCommandReceived.firstWhere((event) => event.type == RemoteCommandType.play);
    remote.sendCommand(const RemoteCommand(type: RemoteCommandType.play));
    expect((await command.timeout(_ioTimeout)).type, RemoteCommandType.play);
  });

  test('manual join to an endpoint that never completes the handshake fails with a timeout', () async {
    final remote = CompanionRemotePeerService.forTesting(remoteConnectTimeout: const Duration(milliseconds: 400));
    final blackHole = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final stalledSockets = <Socket>[];
    final blackHoleSubscription = blackHole.listen(stalledSockets.add);
    addTearDown(() async {
      await remote.dispose();
      await blackHoleSubscription.cancel();
      for (final socket in stalledSockets) {
        socket.destroy();
      }
      await blackHole.close();
    });

    await expectLater(
      remote
          .joinSessionWithContexts('Test Remote', 'ios', '127.0.0.1:${blackHole.port}', [_authContext])
          .timeout(_ioTimeout),
      throwsA(isA<PeerError>().having((error) => error.type, 'type', PeerErrorType.timeout)),
    );
  });

  test('disconnect does not hang while the managed connect is still pending', () async {
    final remote = CompanionRemotePeerService.forTesting(remoteConnectTimeout: const Duration(seconds: 30));
    final blackHole = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final stalledSockets = <Socket>[];
    final blackHoleSubscription = blackHole.listen(stalledSockets.add);
    addTearDown(() async {
      await remote.dispose();
      await blackHoleSubscription.cancel();
      for (final socket in stalledSockets) {
        socket.destroy();
      }
      await blackHole.close();
    });

    final join = remote.joinSessionWithContexts('Test Remote', 'ios', '127.0.0.1:${blackHole.port}', [_authContext]);
    // Settles with an error once teardown destroys the black-holed socket.
    unawaited(join.catchError((_) {}));
    await _flushEventQueue();

    await remote.disconnect().timeout(_ioTimeout);
  });

  test('host and remote dispatch encrypted commands through the same contract', () async {
    final host = CompanionRemotePeerService();
    final remote = CompanionRemotePeerService();
    addTearDown(() async {
      await remote.dispose();
      await host.dispose();
    });

    final session = await host.createSessionForContexts('Test Host', 'macos', [_authContext]);
    await remote.joinSessionWithContexts(
      'Test Remote',
      'ios',
      '127.0.0.1:${session.port}',
      [_authContext],
      authContextId: _authContext.id,
      expectedHostClientId: _authContext.clientIdentifier,
    );

    final hostCommand = host.onCommandReceived.firstWhere((command) => command.type == RemoteCommandType.play);
    remote.sendCommand(const RemoteCommand(type: RemoteCommandType.play, data: {'source': 'remote'}));
    expect(
      await hostCommand.timeout(_ioTimeout),
      const RemoteCommand(type: RemoteCommandType.play, data: {'source': 'remote'}),
    );

    final remoteCommand = remote.onCommandReceived.firstWhere((command) => command.type == RemoteCommandType.pause);
    host.sendCommand(const RemoteCommand(type: RemoteCommandType.pause, data: {'source': 'host'}));
    expect(
      await remoteCommand.timeout(_ioTimeout),
      const RemoteCommand(type: RemoteCommandType.pause, data: {'source': 'host'}),
    );
  });

  test('abrupt connection loss surfaces as a disconnect, not a terminal error', () async {
    final host = CompanionRemotePeerService();
    final remote = CompanionRemotePeerService();
    _TcpProxy? proxy;
    addTearDown(() async {
      await remote.dispose();
      await host.dispose();
      await proxy?.dispose();
    });

    final session = await host.createSessionForContexts('Test Host', 'macos', [_authContext]);
    final activeProxy = proxy = await _TcpProxy.start(session.port);

    await remote.joinSessionWithContexts(
      'Test Remote',
      'ios',
      '127.0.0.1:${activeProxy.port}',
      [_authContext],
      authContextId: _authContext.id,
      expectedHostClientId: _authContext.clientIdentifier,
    );

    final errors = <RemotePeerError>[];
    final statuses = <RemoteSessionStatus>[];
    final errorSubscription = remote.onError.listen(errors.add);
    final statusSubscription = remote.onConnectionStateChanged.listen(statuses.add);
    addTearDown(() async {
      await errorSubscription.cancel();
      await statusSubscription.cancel();
    });
    final disconnected = remote.onDeviceDisconnected.first;

    // Kill the TCP connection without a WebSocket close handshake — the
    // signal a resumed Android app sees after backgrounding killed the
    // socket. It must feed the disconnect/reconnect path, never a terminal
    // error (dart:io normalizes even read-side socket errors to onDone, and
    // the peer's onError branch mirrors this contract for transports that do
    // surface errors).
    activeProxy.abortSockets();

    await disconnected.timeout(_ioTimeout);
    await _flushEventQueue();
    expect(errors, isEmpty);
    expect(statuses, [RemoteSessionStatus.disconnected]);
  });
}

typedef _TestRaceProbeConnection = ({Future<void> Function() close, Future<void> ready, Stream<dynamic> stream});

class _ManagedJoinObservingPeer extends CompanionRemotePeerService {
  _ManagedJoinObservingPeer({
    required _TestRaceProbeConnection Function(Uri uri) raceProbeFactory,
    required this._onManagedJoin,
  }) : super.forTesting(raceProbeFactory: raceProbeFactory);

  final Future<void> Function() _onManagedJoin;

  @override
  Future<void> joinSessionWithContexts(
    String deviceName,
    String platform,
    String hostAddress,
    List<RemoteAuthContext> authContexts, {
    String? authContextId,
    String expectedHostClientId = '',
  }) {
    return _onManagedJoin();
  }
}

class _CancelTrackingStream<T> extends Stream<T> {
  _CancelTrackingStream(this._delegate, this._onCancel);

  final Stream<T> _delegate;
  final void Function() _onCancel;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _CancelTrackingSubscription(
      _delegate.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError),
      _onCancel,
    );
  }
}

class _CancelTrackingSubscription<T> implements StreamSubscription<T> {
  _CancelTrackingSubscription(this._delegate, this._onCancel);

  final StreamSubscription<T> _delegate;
  final void Function() _onCancel;

  @override
  Future<void> cancel() {
    _onCancel();
    return _delegate.cancel();
  }

  @override
  void onData(void Function(T data)? handleData) => _delegate.onData(handleData);

  @override
  void onError(Function? handleError) => _delegate.onError(handleError);

  @override
  void onDone(void Function()? handleDone) => _delegate.onDone(handleDone);

  @override
  void pause([Future<void>? resumeSignal]) => _delegate.pause(resumeSignal);

  @override
  void resume() => _delegate.resume();

  @override
  bool get isPaused => _delegate.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => _delegate.asFuture(futureValue);
}

/// Byte-level TCP relay between the remote client and a real host, so a test
/// can destroy the transport under the client without the WebSocket close
/// handshake a clean [CompanionRemotePeerService.disconnect] would perform.
class _TcpProxy {
  _TcpProxy._(this._server, this._targetPort);

  final ServerSocket _server;
  final int _targetPort;
  final List<Socket> _sockets = [];
  bool _serverClosed = false;

  int get port => _server.port;

  static Future<_TcpProxy> start(int targetPort) async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final proxy = _TcpProxy._(server, targetPort);
    server.listen((socket) => unawaited(proxy._pipe(socket)));
    return proxy;
  }

  Future<void> _pipe(Socket remoteSide) async {
    final hostSide = await Socket.connect(InternetAddress.loopbackIPv4, _targetPort);
    _sockets
      ..add(remoteSide)
      ..add(hostSide);
    remoteSide.listen(hostSide.add, onDone: hostSide.destroy, onError: (Object _) => hostSide.destroy());
    hostSide.listen(remoteSide.add, onDone: remoteSide.destroy, onError: (Object _) => remoteSide.destroy());
  }

  /// Destroy both pipe ends immediately, with no WebSocket close frame.
  void abortSockets() {
    for (final socket in _sockets) {
      socket.destroy();
    }
  }

  Future<void> dispose() async {
    if (!_serverClosed) {
      _serverClosed = true;
      await _server.close();
    }
    abortSockets();
  }
}

final _authContext = RemoteAuthContext(
  id: 'context-1',
  backend: 'plex',
  connectionId: 'connection-1',
  homeSecret: List<int>.generate(32, (index) => index),
  discoveryKey: List<int>.generate(32, (index) => 255 - index),
  clientIdentifier: 'host-client',
  userUuid: 'user-1',
  allowedUserUuids: const ['user-1'],
);

Future<int> _startHost(CompanionRemotePeerService host) async {
  final session = await host.createSessionForContexts('Test Host', 'macos', [_authContext]);
  return session.port;
}

Future<void> _disposeHostAndClients(CompanionRemotePeerService host, List<_RawWebSocketClient> clients) async {
  for (final client in List<_RawWebSocketClient>.of(clients)) {
    await client.dispose();
  }
  clients.clear();
  await host.dispose();
}

Future<void> _expectWebSocketHandshakeStatus(int port, int statusCode) async {
  await expectLater(
    WebSocket.connect('ws://127.0.0.1:$port/ws'),
    throwsA(
      isA<WebSocketException>().having((error) => error.toString(), 'message', contains('status code: $statusCode')),
    ),
  );
}

String _minimalAuth({required String clientNonce}) {
  return jsonEncode({
    'type': 'auth',
    'authTag': 'tag',
    'clientNonce': clientNonce,
    'userUUID': 'user-1',
    'clientIdentifier': 'remote-client',
    'deviceName': 'Remote',
    'platform': 'test',
  });
}

String _validAuthMessage(
  Map<String, dynamic> challenge,
  RemoteAuthContext context, {
  String? authContextId,
  String? userUuid,
  String? authTag,
  String deviceName = 'Raw Remote',
  bool includeAuthContextId = true,
}) {
  final hostNonce = base64Decode(challenge['nonce'] as String);
  final clientNonce = RemoteAuthService.instance.generateNonce();
  final selectedUserUuid = userUuid ?? context.userUuid;
  final computedAuthTag = RemoteAuthService.instance.computeAuthTag(
    homeSecret: context.homeSecret,
    hostNonce: hostNonce,
    clientNonce: clientNonce,
    hostClientId: context.clientIdentifier,
    userUUID: selectedUserUuid,
    clientIdentifier: 'raw-remote-client',
    deviceName: deviceName,
    platform: 'test',
  );
  return jsonEncode({
    'type': 'auth',
    if (includeAuthContextId) 'authContextId': authContextId ?? context.id,
    'clientNonce': base64Encode(clientNonce),
    'userUUID': selectedUserUuid,
    'clientIdentifier': 'raw-remote-client',
    'deviceName': deviceName,
    'platform': 'test',
    'authTag': authTag ?? computedAuthTag,
  });
}

Future<void> _flushEventQueue() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _RawWebSocketClient {
  _RawWebSocketClient._(this.socket) {
    _subscription = socket.listen(
      (data) {
        if (data is! String) return;
        try {
          final decoded = jsonDecode(data);
          if (decoded is! Map<String, dynamic>) return;
          if (decoded['type'] == 'challenge' && !_challenge.isCompleted) {
            _challengeValue = decoded;
            _challenge.complete(decoded);
          } else if (decoded['type'] == 'authFailed' && !_authFailed.isCompleted) {
            _authFailed.complete();
          }
        } catch (_) {
          // Encrypted and malformed server messages are not part of this helper.
        }
      },
      onDone: () {
        if (!_closed.isCompleted) _closed.complete(socket.closeCode);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_closed.isCompleted) _closed.completeError(error, stackTrace);
      },
      cancelOnError: true,
    );
  }

  static Future<_RawWebSocketClient> connect(int port) async {
    // Ownership transfers to the returned helper.
    // ignore: close_sinks
    final socket = await WebSocket.connect('ws://127.0.0.1:$port/ws').timeout(_ioTimeout);
    final client = _RawWebSocketClient._(socket);
    try {
      await client._challenge.future.timeout(_ioTimeout);
      return client;
    } catch (_) {
      await client.dispose();
      rethrow;
    }
  }

  final WebSocket socket;
  final Completer<Map<String, dynamic>> _challenge = Completer<Map<String, dynamic>>();
  final Completer<void> _authFailed = Completer<void>();
  final Completer<int?> _closed = Completer<int?>();
  late final StreamSubscription<dynamic> _subscription;
  late Map<String, dynamic> _challengeValue;

  Map<String, dynamic> get challenge => _challengeValue;
  Future<void> get authFailed => _authFailed.future;
  Future<int?> get closed => _closed.future;
  bool get isOpen => socket.readyState == WebSocket.open;

  void add(dynamic data) => socket.add(data);

  Future<void> dispose() async {
    if (!_closed.isCompleted) {
      try {
        await socket.close(WebSocketStatus.normalClosure);
      } catch (_) {
        // The peer may already have closed the transport.
      }
    }
    if (!_closed.isCompleted) {
      await _closed.future.timeout(_ioTimeout);
    }
    await _subscription.cancel();
  }
}

class _RawUpgradedSocket {
  _RawUpgradedSocket._(this.socket, this._subscription, this._done);

  static Future<_RawUpgradedSocket> connect(int port) async {
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, port).timeout(_ioTimeout);
    final responseHeaders = StringBuffer();
    final upgraded = Completer<void>();
    final done = Completer<void>();
    late final StreamSubscription<List<int>> subscription;
    subscription = socket.listen(
      (bytes) {
        responseHeaders.write(latin1.decode(bytes));
        if (!upgraded.isCompleted && responseHeaders.toString().contains('\r\n\r\n')) {
          upgraded.complete();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!upgraded.isCompleted) upgraded.completeError(error, stackTrace);
        if (!done.isCompleted) done.complete();
      },
      onDone: () {
        if (!upgraded.isCompleted) {
          upgraded.completeError(StateError('Socket closed before WebSocket upgrade'));
        }
        if (!done.isCompleted) done.complete();
      },
    );
    try {
      final key = base64Encode(List<int>.generate(16, (index) => index));
      socket.write(
        'GET /ws HTTP/1.1\r\n'
        'Host: 127.0.0.1:$port\r\n'
        'Connection: Upgrade\r\n'
        'Upgrade: websocket\r\n'
        'Sec-WebSocket-Version: 13\r\n'
        'Sec-WebSocket-Key: $key\r\n'
        '\r\n',
      );
      await socket.flush();
      await upgraded.future.timeout(_ioTimeout);
      expect(responseHeaders.toString(), startsWith('HTTP/1.1 101'));
      return _RawUpgradedSocket._(socket, subscription, done);
    } catch (_) {
      socket.destroy();
      await subscription.cancel();
      rethrow;
    }
  }

  final Socket socket;
  final StreamSubscription<List<int>> _subscription;
  final Completer<void> _done;

  Future<void> dispose() async {
    if (!_done.isCompleted) {
      socket.destroy();
      await _done.future.timeout(_ioTimeout);
    }
    await _subscription.cancel();
  }
}
