import 'dart:async';

import 'package:dart_discord_presence/dart_discord_presence.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/discord_rpc_service.dart';

void main() {
  group('posterCacheExpiryFromResponse', () {
    final receivedAt = DateTime.utc(2026, 7, 12, 12);

    test('honors the relay-provided expiry', () {
      expect(
        posterCacheExpiryFromResponse({'expiresIn': 90}, receivedAt: receivedAt),
        receivedAt.add(const Duration(seconds: 90)),
      );
    });

    test('treats a non-positive relay expiry as immediately expired', () {
      expect(posterCacheExpiryFromResponse({'expiresIn': 0}, receivedAt: receivedAt), receivedAt);
    });

    test('retains the legacy fallback for older or invalid relays', () {
      final fallback = receivedAt.add(const Duration(hours: 3));

      expect(posterCacheExpiryFromResponse({'url': '/posters/a.png'}, receivedAt: receivedAt), fallback);
      expect(posterCacheExpiryFromResponse({'expiresIn': '90'}, receivedAt: receivedAt), fallback);
      expect(posterCacheExpiryFromResponse({'expiresIn': 1 << 62}, receivedAt: receivedAt), fallback);
    });
  });

  group('DiscordRPCService reconnect lifecycle', () {
    List<_FakeDiscordRPC> clients = [];
    // When set, the next client the factory builds awaits this before its
    // initialize completes, letting tests hold an initialize in flight.
    Completer<void>? nextInitializeGate;
    DiscordRPCService service() {
      clients = [];
      nextInitializeGate = null;
      return DiscordRPCService.forTesting(
        rpcFactory: () {
          final client = _FakeDiscordRPC()..initializeGate = nextInitializeGate;
          nextInitializeGate = null;
          clients.add(client);
          return client;
        },
      );
    }

    test('a disconnect tears down the client so the reconnect timer builds a fresh one', () {
      fakeAsync((async) {
        final rpcService = service();

        unawaited(rpcService.setEnabled(true));
        async.flushMicrotasks();
        expect(clients, hasLength(1));
        expect(clients.first.initializeCalls, 1);

        clients.first.emitReady();
        async.elapse(const Duration(milliseconds: 200)); // onReady stabilization delay

        clients.first.emitDisconnected();
        async.flushMicrotasks();

        // The dead client must be disposed immediately: a disposed DiscordRPC
        // rejects re-initialization, so leaving it wired dead-ends recovery.
        expect(clients.first.disposeCalls, 1);

        // Regression: _rpc used to stay non-null after a disconnect, making
        // the timer's _connect a no-op and killing presence for the rest of
        // the app session.
        async.elapse(const Duration(seconds: 30));
        expect(clients, hasLength(2));
        expect(clients[1].initializeCalls, 1);

        unawaited(rpcService.dispose());
        async.flushMicrotasks();
        expect(clients[1].disposeCalls, 1);
      });
    });

    test('disabling after a disconnect prevents the reconnect', () {
      fakeAsync((async) {
        final rpcService = service();

        unawaited(rpcService.setEnabled(true));
        async.flushMicrotasks();
        clients.first.emitDisconnected();
        async.flushMicrotasks();

        unawaited(rpcService.setEnabled(false));
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 30));
        expect(clients, hasLength(1), reason: 'disable must cancel the armed reconnect timer');
      });
    });

    test('a stale initialize failure must not tear down the replacement client', () {
      fakeAsync((async) {
        final rpcService = service();
        final gateA = Completer<void>();
        nextInitializeGate = gateA;

        // Client A's initialize is held in flight.
        unawaited(rpcService.setEnabled(true));
        async.flushMicrotasks();
        expect(clients, hasLength(1));
        final a = clients.first;
        expect(a.initializeCalls, 1);

        // Disable tears A down mid-initialize; re-enable builds client B.
        unawaited(rpcService.setEnabled(false));
        async.flushMicrotasks();
        expect(a.disposeCalls, 1);
        unawaited(rpcService.setEnabled(true));
        async.flushMicrotasks();
        expect(clients, hasLength(2));
        final b = clients[1];
        expect(b.initializeCalls, 1);

        // A's initialize now fails. Regression: the catch used to run
        // _teardownRpc(), disposing whatever _rpc held — B — and killing the
        // fresh connection until the 30s retry.
        gateA.completeError(StateError('ipc gone'));
        async.flushMicrotasks();
        expect(b.disposeCalls, 0, reason: 'stale failure must not dispose the successor');

        // No reconnect timer may replace the live client either.
        async.elapse(const Duration(seconds: 30));
        expect(clients, hasLength(2));
        expect(b.disposeCalls, 0);

        // B's subscriptions survived: its onReady still connects the service,
        // observable through stopPlayback clearing presence on B.
        b.emitReady();
        async.elapse(const Duration(milliseconds: 200));
        unawaited(rpcService.stopPlayback());
        async.flushMicrotasks();
        expect(b.clearPresenceCalls, 1, reason: 'ready listener must mark the service connected');

        unawaited(rpcService.dispose());
        async.flushMicrotasks();
        expect(b.disposeCalls, 1);
      });
    });

    test('a current-client initialize failure still tears down and schedules a reconnect', () {
      fakeAsync((async) {
        final rpcService = service();
        final gate = Completer<void>();
        nextInitializeGate = gate;

        unawaited(rpcService.setEnabled(true));
        async.flushMicrotasks();
        expect(clients, hasLength(1));

        gate.completeError(StateError('discord not running'));
        async.flushMicrotasks();
        expect(clients.first.disposeCalls, 1);

        // The armed reconnect timer must build a fresh client.
        async.elapse(const Duration(seconds: 30));
        expect(clients, hasLength(2));
        expect(clients[1].initializeCalls, 1);

        unawaited(rpcService.dispose());
        async.flushMicrotasks();
        expect(clients[1].disposeCalls, 1);
      });
    });
  });
}

/// Fake [DiscordRPC] mirroring the lifecycle contract the service depends on:
/// a disposed client rejects re-initialization, so recovery requires a fresh
/// instance. Only the surface the service touches is implemented.
class _FakeDiscordRPC implements DiscordRPC {
  final _ready = StreamController<DiscordReadyEvent>.broadcast(sync: true);
  final _disconnected = StreamController<DiscordDisconnectedEvent>.broadcast(sync: true);
  final _errors = StreamController<DiscordErrorEvent>.broadcast(sync: true);

  int initializeCalls = 0;
  int disposeCalls = 0;
  int clearPresenceCalls = 0;
  bool _disposed = false;

  /// When set, [initialize] awaits this after recording the call, so tests
  /// can fail (or complete) an in-flight initialize on demand.
  Completer<void>? initializeGate;

  @override
  Stream<DiscordReadyEvent> get onReady => _ready.stream;

  @override
  Stream<DiscordDisconnectedEvent> get onDisconnected => _disconnected.stream;

  @override
  Stream<DiscordErrorEvent> get onError => _errors.stream;

  @override
  Future<void> initialize(String applicationId) async {
    if (_disposed) throw StateError('Cannot initialize a disposed DiscordRPC');
    if (initializeCalls > 0) throw StateError('Already initialized');
    initializeCalls++;
    final gate = initializeGate;
    if (gate != null) await gate.future;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    disposeCalls++;
    await _ready.close();
    await _disconnected.close();
    await _errors.close();
  }

  @override
  Future<void> clearPresence() async {
    clearPresenceCalls++;
  }

  void emitReady() {
    _ready.add(
      const DiscordReadyEvent(
        user: DiscordUser(userId: '1', username: 'tester'),
      ),
    );
  }

  void emitDisconnected() {
    _disconnected.add(const DiscordDisconnectedEvent(errorCode: 1006, message: 'connection lost'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
