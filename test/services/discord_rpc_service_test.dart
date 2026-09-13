import 'dart:async';

import 'package:dart_discord_presence/dart_discord_presence.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/services/discord_rpc_service.dart';

import '../test_helpers/discord_rpc_fakes.dart';
import '../test_helpers/media_items.dart';

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
    List<FakeDiscordRPC> clients = [];
    // When set, the next client the factory builds awaits this before its
    // initialize completes, letting tests hold an initialize in flight.
    Completer<void>? nextInitializeGate;
    DiscordRPCService service() {
      clients = [];
      nextInitializeGate = null;
      return DiscordRPCService.forTesting(
        rpcFactory: () {
          final client = FakeDiscordRPC()..initializeGate = nextInitializeGate;
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

  group('DiscordRPCService presence', () {
    late List<FakeDiscordRPC> clients;

    /// A connected service whose next presence write lands on `clients.last`.
    DiscordRPCService connectedService(FakeAsync async) {
      clients = [];
      final rpcService = DiscordRPCService.forTesting(
        rpcFactory: () {
          final client = FakeDiscordRPC();
          clients.add(client);
          return client;
        },
      );
      unawaited(rpcService.setEnabled(true));
      async.flushMicrotasks();
      clients.single.emitReady();
      async.elapse(const Duration(milliseconds: 200));
      return rpcService;
    }

    test('a track publishes a Listening activity with the artist as state', () {
      fakeAsync((async) {
        final rpcService = connectedService(async);
        final track = testMediaItem(
          kind: MediaKind.track,
          title: 'Beautiful Again',
          parentTitle: 'The Surface',
          grandparentTitle: 'Beartooth',
          durationMs: 211000,
        );

        unawaited(rpcService.startPlayback(track, _NoopClient()));
        async.flushMicrotasks();

        final presence = clients.single.presences.single;
        expect(presence.type, DiscordActivityType.listening);
        expect(presence.details, 'Beautiful Again');
        expect(presence.state, 'Beartooth');
        expect(presence.timestamps, isNotNull, reason: 'a playing track runs the progress bar');

        unawaited(rpcService.dispose());
        async.flushMicrotasks();
      });
    });

    test('video keeps the Watching activity', () {
      fakeAsync((async) {
        final rpcService = connectedService(async);
        final movie = testMediaItem(kind: MediaKind.movie, title: 'Heat', year: 1995, studio: 'Warner Bros.');

        unawaited(rpcService.startPlayback(movie, _NoopClient()));
        async.flushMicrotasks();

        final presence = clients.single.presences.single;
        expect(presence.type, DiscordActivityType.watching);
        expect(presence.details, 'Heat (1995)');
        expect(presence.state, 'Warner Bros.');

        unawaited(rpcService.dispose());
        async.flushMicrotasks();
      });
    });

    test('a track bound while paused publishes no progress timestamps', () {
      // The music engine binds presence before the player is audibly playing
      // for a restored or car-restricted session and pauses it at once; that
      // pause must win over the start's own timer.
      fakeAsync((async) {
        final rpcService = connectedService(async);
        final track = testMediaItem(kind: MediaKind.track, title: 'Beautiful Again', durationMs: 211000);

        unawaited(rpcService.startPlayback(track, _NoopClient()));
        unawaited(rpcService.pausePlayback());
        async.flushMicrotasks();

        expect(clients.single.presences, isNotEmpty);
        expect(clients.single.presences.map((p) => p.timestamps), everyElement(isNull));

        unawaited(rpcService.dispose());
        async.flushMicrotasks();
      });
    });
  });
}

class _NoopClient implements MediaServerClient {
  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities.plex;

  @override
  ServerId get serverId => ServerId('server-1');

  @override
  String? get serverName => 'Server';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
