import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/music_assistant/music_assistant_api.dart';
import 'package:plezy/services/music_assistant/music_assistant_library.dart';
import 'package:plezy/services/music_assistant/music_assistant_models.dart';

const _greeting = {
  'server_id': 'fe2f5b6fd78e4608bb8b075a6c269fbf',
  'server_version': '2.6.3',
  'schema_version': 26,
  'min_supported_schema_version': 24,
  'base_url': 'http://10.0.2.107:8095',
  'homeassistant_addon': false,
  'onboard_done': true,
};

void main() {
  group('handshake', () {
    test('reads the unsolicited greeting and exposes server metadata', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);

      expect(harness.client.serverVersion, '2.6.3');
      expect(harness.client.schemaVersion, 26);
      expect(harness.client.isConnected, isTrue);
      // Derived from the connect URL, not the greeting's base_url, so a server
      // advertising an unreachable address cannot break image loading.
      expect(harness.client.httpBaseUrl.toString(), 'http://127.0.0.1:8095');
    });

    test('normalises the connect URL to the single /ws endpoint', () async {
      final harness = await _Harness.connected(baseUrl: Uri.parse('https://ma.example.com/'));
      addTearDown(harness.dispose);

      expect(harness.channel.url.toString(), 'wss://ma.example.com/ws');
    });

    test('a socket that never opens fails inside the handshake budget', () {
      // The device bug. `handshakeTimeout` bounded only the greeting, and the
      // socket open was awaited with no deadline at all — so a host that
      // accepts no connection left `connect()` hanging on the platform's TCP
      // retransmit schedule. Measured against a blackholed address: still
      // unsettled 24 seconds into an 8 second budget, with the add-server form
      // showing a spinner and no error the entire time.
      //
      // Fake time, because the real thing is a minute of wall clock: the point
      // under test is that the deadline exists, not how long Darwin retries.
      fakeAsync((async) {
        // A factory whose future never completes is exactly a SYN into a
        // blackhole — no answer, no refusal, no error.
        final client = MusicAssistantApi(
          autoReconnect: false,
          handshakeTimeout: const Duration(seconds: 8),
          channelFactory: (_) => Completer<MaChannel>().future,
        );
        Object? outcome;
        unawaited(
          client
              .connect(Uri.parse('http://10.255.255.1:8095'))
              .then<void>((_) => outcome = 'connected', onError: (Object e) => outcome = e),
        );

        async.elapse(const Duration(seconds: 7));
        expect(outcome, isNull, reason: 'must not give up before its budget');

        async.elapse(const Duration(seconds: 2));
        expect(outcome, isA<MaConnectionException>());
        // Named apart from "Server sent no greeting": nothing answering and a
        // port that answers but stays silent have different causes.
        expect((outcome! as MaConnectionException).message, contains('No answer from 10.255.255.1:8095'));
        client.dispose();
      });
    });

    test('builds imageproxy URLs from a metadata image path', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);

      final url = harness.client.imageUrl('al-4e9Hni_692d2ed2', imageProvider: 'opensubsonic--pu5hhsYV', size: 300)!;
      expect(url.path, '/imageproxy');
      // The proxy 404s without `provider` and serves the original file without
      // `size`, so both travel with the path.
      expect(url.queryParameters, {'path': 'al-4e9Hni_692d2ed2', 'provider': 'opensubsonic--pu5hhsYV', 'size': '300'});
    });
  });

  group('message_id correlation', () {
    test('resolves out-of-order replies to the right request', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);

      final albums = harness.client.sendCommand('music/albums/count');
      final artists = harness.client.sendCommand('music/artists/count');
      final tracks = harness.client.sendCommand('music/tracks/count');
      await harness.pump();

      final ids = harness.sentMessageIds;
      expect(ids, hasLength(3));

      // Reply in 3, 1, 2 order — the server genuinely does this.
      harness.channel.emit({'message_id': ids[2], 'result': 365691, 'partial': false});
      harness.channel.emit({'message_id': ids[0], 'result': 32717, 'partial': false});
      harness.channel.emit({'message_id': ids[1], 'result': 10331, 'partial': false});

      expect(await albums, 32717);
      expect(await artists, 10331);
      expect(await tracks, 365691);
    });

    test('a reply for one request never completes another', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);

      final first = harness.client.sendCommand('music/albums/count');
      final second = harness.client.sendCommand('music/artists/count');
      await harness.pump();

      harness.channel.emit({'message_id': harness.sentMessageIds[1], 'result': 7});
      await harness.pump();

      expect(await second, 7);
      // The first request must still be outstanding, not resolved by proximity.
      var firstDone = false;
      unawaited(first.then<void>((_) => firstDone = true).catchError((Object _) {}));
      await harness.pump();
      expect(firstDone, isFalse);

      harness.channel.emit({'message_id': harness.sentMessageIds[0], 'result': 28671});
      expect(await first, 28671);
    });

    test('an unknown message_id is ignored instead of failing a live request', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);

      final pending = harness.client.sendCommand('music/albums/count');
      await harness.pump();

      harness.channel.emit({'message_id': 'stale-9999', 'result': 1});
      harness.channel.emit({'message_id': harness.sentMessageIds.first, 'result': 28671});

      expect(await pending, 28671);
    });

    test('an error frame surfaces error_code and details', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);

      final pending = harness.client.sendCommand('this/does/not/exist');
      await harness.pump();
      harness.channel.emit({
        'message_id': harness.sentMessageIds.first,
        'error_code': 12,
        'details': 'Invalid command: this/does/not/exist',
      });

      await expectLater(
        pending,
        throwsA(
          isA<MaRequestException>()
              .having((error) => error.errorCode, 'errorCode', 12)
              .having((error) => error.message, 'message', contains('Invalid command')),
        ),
      );
    });

    test('a request that is never answered times out', () async {
      final harness = await _Harness.connected(requestTimeout: const Duration(milliseconds: 40));
      addTearDown(harness.dispose);

      await expectLater(harness.client.sendCommand('music/albums/count'), throwsA(isA<MaTimeoutException>()));
    });
  });

  group('concurrency limit', () {
    // These exist because the server has no way to defend itself. Music
    // Assistant drops a client at `Client exceeded max pending messages: 512`,
    // but it stops being usable long before that: a saturated server answers
    // `count` in 9ms while `players/all` and every `library_items` request hang
    // for an hour, and only a container restart brings it back. That happened
    // three times in one day, and the smallest fan-out that did it was seven
    // parallel `music/item_by_uri` calls. Two features — "Most played" as a row,
    // and expanding the "recently played" rows — were deleted rather than
    // fixed, because there was nothing here to make them safe.

    test('twenty concurrent callers never put more than the limit on the wire', () async {
      const limit = 3;
      const callers = 20;
      final harness = await _Harness.connected(maxConcurrentRequests: limit);
      addTearDown(harness.dispose);

      // One `music/item_by_uri` per row is exactly the shape of the expansion
      // that was dropped: twenty rows, twenty requests, all issued at once.
      final results = [
        for (var i = 0; i < callers; i++)
          harness.client.sendCommand('music/item_by_uri', args: {'uri': 'library://track/$i'}),
      ];
      await harness.pump();

      var highWater = 0;
      for (var answered = 0; answered < callers; answered++) {
        final outstanding = harness.channel.sent.length - answered;
        if (outstanding > highWater) highWater = outstanding;
        expect(
          harness.client.inFlightRequestCount,
          lessThanOrEqualTo(limit),
          reason: 'the client must never hold more than $limit slots',
        );

        // Answer the oldest outstanding request, and answer it with its own
        // index — so a mis-routed reply shows up as a wrong value below.
        harness.channel.emit({'message_id': harness.sentMessageIds[answered], 'result': answered});
        await harness.pump();
      }

      expect(
        highWater,
        limit,
        reason: 'without a limiter all $callers frames go out at once; the wedge is the whole point',
      );
      // Queued, not dropped: every caller is still served.
      expect(harness.channel.sent, hasLength(callers));
      expect(harness.client.queuedRequestCount, 0);
      expect(harness.client.inFlightRequestCount, 0);
      for (var i = 0; i < callers; i++) {
        expect(await results[i], i, reason: 'queueing must not disturb message_id correlation');
      }
    });

    test('a queued request still correlates by message_id, not by arrival order', () async {
      final harness = await _Harness.connected(maxConcurrentRequests: 2);
      addTearDown(harness.dispose);

      final first = harness.client.sendCommand('music/albums/count');
      final second = harness.client.sendCommand('music/artists/count');
      final third = harness.client.sendCommand('music/tracks/count');
      await harness.pump();

      expect(harness.channel.sent, hasLength(2), reason: 'the third is behind the limit');
      expect(harness.client.queuedRequestCount, 1);

      // Reply to the second first. That releases a slot, so the third goes out
      // while the first is still outstanding.
      harness.channel.emit({'message_id': harness.sentMessageIds[1], 'result': 10331});
      await harness.pump();
      expect(harness.channel.sent, hasLength(3));

      // And now answer the remaining two in reverse order.
      harness.channel.emit({'message_id': harness.sentMessageIds[2], 'result': 365691});
      harness.channel.emit({'message_id': harness.sentMessageIds[0], 'result': 32717});

      expect(await first, 32717);
      expect(await second, 10331);
      expect(await third, 365691);
    });

    test('time spent waiting for a slot is not charged to the request timeout', () async {
      // The deadline is a claim about how long the *server* may take. Starting
      // the timer when the caller asked would make a deep fan-out fail from the
      // back forwards under a limiter that is doing exactly its job — and the
      // failure would look like server slowness, which is the misdiagnosis this
      // whole area keeps producing.
      final harness = await _Harness.connected(
        maxConcurrentRequests: 1,
        requestTimeout: const Duration(milliseconds: 120),
      );
      addTearDown(harness.dispose);

      final blocker = harness.client.sendCommand('music/search');
      final queued = harness.client.sendCommand('music/albums/count');
      await harness.pump();
      expect(harness.channel.sent, hasLength(1), reason: 'the second request must be waiting for a slot');

      // Hold the only slot for most of the deadline.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      harness.channel.emit({'message_id': harness.sentMessageIds.first, 'result': 1});
      expect(await blocker, 1);
      await harness.pump();
      expect(harness.channel.sent, hasLength(2), reason: 'the freed slot must dispatch the queued request');

      // Past 120ms since the caller asked, but well inside 120ms since it was
      // sent. It must still be alive.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      harness.channel.emit({'message_id': harness.sentMessageIds[1], 'result': 28671});
      expect(await queued, 28671);
    });

    test('a timed-out request releases its slot so the queue keeps draining', () async {
      // The path that matters against a server that has gone quiet: if a
      // timeout did not free its slot the queue would deadlock behind it and
      // the app would hang rather than surface the failure.
      final harness = await _Harness.connected(
        maxConcurrentRequests: 1,
        requestTimeout: const Duration(milliseconds: 40),
      );
      addTearDown(harness.dispose);

      final ignored = harness.client.sendCommand('players/all');
      final failure = expectLater(ignored, throwsA(isA<MaTimeoutException>()));
      final queued = harness.client.sendCommand('music/albums/count');
      await harness.pump();
      expect(harness.channel.sent, hasLength(1));

      await failure;
      await harness.pump();

      expect(harness.channel.sent, hasLength(2));
      harness.channel.emit({'message_id': harness.sentMessageIds[1], 'result': 28671});
      expect(await queued, 28671);
    });

    test('a chunked response holds its slot until the terminating frame', () async {
      // A `partial: true` stream is still work in progress on the server.
      // Releasing on the first chunk would let the client run over the limit by
      // however many streams were open.
      final harness = await _Harness.connected(maxConcurrentRequests: 1);
      addTearDown(harness.dispose);

      final chunked = harness.client.sendCommand('music/playlists/playlist_tracks');
      final queued = harness.client.sendCommand('music/albums/count');
      await harness.pump();
      final messageId = harness.sentMessageIds.first;

      harness.channel.emit({
        'message_id': messageId,
        'result': [_album('1', 'A')],
        'partial': true,
      });
      await harness.pump();
      expect(harness.channel.sent, hasLength(1), reason: 'a chunk is not a completion');

      harness.channel.emit({'message_id': messageId, 'result': <dynamic>[], 'partial': false});
      expect(await chunked as List<dynamic>, hasLength(1));
      await harness.pump();

      expect(harness.channel.sent, hasLength(2));
      harness.channel.emit({'message_id': harness.sentMessageIds[1], 'result': 28671});
      expect(await queued, 28671);
    });

    test('a dropped socket fails queued requests as well as in-flight ones', () async {
      // A queued request that survived the drop would be sent on a connection
      // that never asked for it; one that did not survive would hang forever
      // with nothing left to dispatch it.
      final harness = await _Harness.connected(maxConcurrentRequests: 1, autoReconnect: false);
      addTearDown(harness.dispose);

      final inFlight = harness.client.sendCommand('players/all');
      final queued = harness.client.sendCommand('music/albums/count');
      final failures = Future.wait([
        expectLater(inFlight, throwsA(isA<MaConnectionException>())),
        expectLater(queued, throwsA(isA<MaConnectionException>())),
      ]);
      await harness.pump();
      expect(harness.client.queuedRequestCount, 1);

      await harness.channel.closeFromServer();
      await harness.pump();

      await failures;
      expect(harness.client.queuedRequestCount, 0);
    });

    test('the default bound sits under the fan-out that wedged a real server', () {
      final client = MusicAssistantApi();
      addTearDown(client.dispose);

      expect(client.maxConcurrentRequests, MusicAssistantApi.defaultMaxConcurrentRequests);
      expect(MusicAssistantApi.defaultMaxConcurrentRequests, greaterThan(0));
      // 512 is where the protocol drops the client outright, but seven parallel
      // `music/item_by_uri` calls were enough to hang a real server for an hour.
      // The default has to be chosen against the seven, not the 512.
      expect(
        MusicAssistantApi.defaultMaxConcurrentRequests,
        lessThan(7),
        reason: 'a default at or above the measured wedge is not a limit',
      );
    });
  });

  group('sendCommandForMap', () {
    test('a JSON object comes back as-is', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);

      final pending = harness.client.sendCommandForMap('music/search');
      await harness.pump();
      harness.channel.emit({
        'message_id': harness.sentMessageIds.last,
        'result': {'albums': <dynamic>[]},
      });

      expect(await pending, {'albums': <dynamic>[]});
    });

    test('a null result is "nothing there", so it maps to the empty object', () async {
      // `music/item_by_uri` answers null for a uri that no longer resolves.
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);

      final pending = harness.client.sendCommandForMap('music/item_by_uri');
      await harness.pump();
      harness.channel.emit({'message_id': harness.sentMessageIds.last, 'result': null});

      expect(await pending, isEmpty);
    });

    test('a non-object result is a fault, not an empty answer', () async {
      // Returning `const {}` here made a renamed command, an interposed proxy
      // or an unknown schema all render as "your library is empty" — an
      // outcome nobody reports, because it looks like the truth.
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);

      final pending = harness.client.sendCommandForMap('music/search');
      final failure = expectLater(
        pending,
        throwsA(isA<MaProtocolException>().having((e) => e.command, 'command', 'music/search')),
      );
      await harness.pump();
      harness.channel.emit({
        'message_id': harness.sentMessageIds.last,
        'result': ['not', 'an', 'object'],
      });

      await failure;
    });
  });

  group('events', () {
    test('event frames go to the event stream and are not treated as replies', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);

      final received = <MaEvent>[];
      final subscription = harness.client.events.listen(received.add);
      addTearDown(subscription.cancel);

      final pending = harness.client.sendCommand('music/albums/count');
      await harness.pump();

      // The frames immediately following a request are, in practice, events.
      harness.channel.emit({'event': 'media_item_added', 'object_id': 'library://track/365455', 'data': {}});
      harness.channel.emit({
        'event': 'player_updated',
        'object_id': 'ma_plezy_abc',
        'data': {'state': 'playing'},
      });
      await harness.pump();

      expect(received.map((event) => event.event), ['media_item_added', 'player_updated']);
      expect(received.last.data['state'], 'playing');

      var resolved = false;
      unawaited(pending.then<void>((_) => resolved = true).catchError((Object _) {}));
      await harness.pump();
      expect(resolved, isFalse, reason: 'events must not resolve an outstanding request');

      harness.channel.emit({'message_id': harness.sentMessageIds.first, 'result': 28671});
      expect(await pending, 28671);
    });

    test('a malformed frame is dropped without breaking the stream', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);

      final received = <MaEvent>[];
      final subscription = harness.client.events.listen(received.add);
      addTearDown(subscription.cancel);

      harness.channel.emitRaw('not json at all');
      harness.channel.emitRaw('[1,2,3]');
      harness.channel.emit({'event': 'queue_updated', 'object_id': 'q', 'data': {}});
      await harness.pump();

      expect(received.single.event, 'queue_updated');
    });
  });

  group('lifecycle', () {
    test('a dropped socket fails in-flight requests', () async {
      final harness = await _Harness.connected(autoReconnect: false);
      addTearDown(harness.dispose);

      final pending = harness.client.sendCommand('music/albums/count');
      // Attached before the drop: the client fails the request synchronously
      // from the close callback, so a later listener would be too late and the
      // error would be reported as unhandled.
      final failure = expectLater(pending, throwsA(isA<MaConnectionException>()));
      await harness.pump();
      await harness.channel.closeFromServer();
      await harness.pump();

      await failure;
      expect(harness.client.isConnected, isFalse);
    });

    test('dispose cancels pending requests and the scheduled retry', () async {
      final harness = await _Harness.connected(retryBaseDelay: const Duration(milliseconds: 5));

      final pending = harness.client.sendCommand('music/albums/count');
      final failure = expectLater(pending, throwsA(isA<MaConnectionException>()));
      await harness.pump();
      await harness.channel.closeFromServer();
      await harness.pump();

      await failure;

      final attemptsAtDispose = harness.channel.openCount;
      await harness.client.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(harness.channel.openCount, attemptsAtDispose, reason: 'no retry may run after dispose');
    });
  });

  group('keepalive', () {
    test('the production transport arms a WebSocket ping', () async {
      // The whole point: web_socket_channel defaults pingInterval to null, and
      // with it null a link that dies silently (AP reboot, Wi-Fi→cellular, iOS
      // suspending the socket) produces no onDone and no onError. The client
      // then sits in `connected` forever with a socket nothing can travel over.
      // Asserted against a real loopback server because the assignment is one
      // line that reads like decoration.
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      unawaited(
        server.first.then((request) async {
          final peer = await WebSocketTransformer.upgrade(request);
          try {
            await peer.done;
          } finally {
            await peer.close();
          }
        }),
      );

      final socket = await MusicAssistantApi.connectKeepAliveSocket(
        Uri.parse('ws://${server.address.address}:${server.port}/ws'),
        const Duration(seconds: 7),
      );
      addTearDown(() => socket.close());

      expect(socket.pingInterval, const Duration(seconds: 7));
    });

    test('the default interval is a real duration, not null', () {
      // A null or zero interval is the shipped bug, not a configuration.
      expect(MusicAssistantApi().pingInterval, MusicAssistantApi.defaultPingInterval);
      expect(MusicAssistantApi.defaultPingInterval, greaterThan(Duration.zero));
    });
  });

  group('reconnect backoff', () {
    test('doubles and caps at 30s', () {
      Duration delay(int attempt) => MusicAssistantApi.backoffDelay(attempt);

      expect(delay(0), const Duration(seconds: 1));
      expect(delay(1), const Duration(seconds: 2));
      expect(delay(2), const Duration(seconds: 4));
      expect(delay(3), const Duration(seconds: 8));
      expect(delay(4), const Duration(seconds: 16));
      expect(delay(5), MusicAssistantApi.maxRetryDelay);
      expect(delay(12), MusicAssistantApi.maxRetryDelay);
    });

    test('retries do not reset the attempt counter', () async {
      // Regression guard for the shipped bug: routing retries through the
      // public connect(), which resets the counter, pinned every retry at the
      // first rung of the ladder and produced an endless fast reconnect loop.
      final channel = _FakeChannel(failConnections: true);
      final client = MusicAssistantApi(
        channelFactory: channel.open,
        retryBaseDelay: const Duration(milliseconds: 5),
        maxRetryDelayOverride: const Duration(milliseconds: 40),
      );
      addTearDown(client.dispose);

      await expectLater(client.connect(Uri.parse('http://127.0.0.1:8095')), throwsA(anything));

      // Wait long enough for several rungs (5 + 10 + 20 + 40ms) to elapse.
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(channel.openCount, greaterThan(1), reason: 'the retry loop must actually run');
      expect(
        client.retryAttempt,
        greaterThanOrEqualTo(channel.openCount),
        reason: 'every failed attempt must advance the ladder',
      );
    });

    test('a successful connect resets the ladder', () async {
      final channel = _FakeChannel(failConnections: true);
      final client = MusicAssistantApi(
        channelFactory: channel.open,
        retryBaseDelay: const Duration(milliseconds: 5),
        maxRetryDelayOverride: const Duration(milliseconds: 20),
      );
      addTearDown(client.dispose);

      await expectLater(client.connect(Uri.parse('http://127.0.0.1:8095')), throwsA(anything));
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(client.retryAttempt, greaterThan(1));

      channel.failConnections = false;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      channel.emit(_greeting);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(client.isConnected, isTrue);
      expect(client.retryAttempt, 0);
    });
  });

  group('library paging', () {
    test('getPage always sends an explicit limit', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);
      final library = MusicAssistantLibrary(harness.client);

      final pending = library.getPage(MaLibraryType.albums, offset: 12800);
      await harness.pump();

      final sent = harness.sentFrames.last;
      expect(sent['command'], 'music/albums/library_items');
      // Omitting `limit` makes the server silently truncate at 500 items.
      expect(sent['args'], {'limit': 500, 'offset': 12800});

      harness.channel.emit({
        'message_id': sent['message_id'],
        'result': [_album('9560', '+ (plus)')],
      });
      expect((await pending).single.name, '+ (plus)');
    });

    test('parses both the bare-array and wrapped result shapes', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);
      final library = MusicAssistantLibrary(harness.client);

      final bare = library.getPage(MaLibraryType.albums);
      await harness.pump();
      harness.channel.emit({
        'message_id': harness.sentMessageIds.last,
        'result': [_album('1', 'A')],
      });
      expect((await bare).single.itemId, '1');

      final wrapped = library.getPage(MaLibraryType.albums);
      await harness.pump();
      harness.channel.emit({
        'message_id': harness.sentMessageIds.last,
        'result': {
          'items': [_album('2', 'B')],
          'total': 1,
        },
      });
      expect((await wrapped).single.itemId, '2');
    });

    test('reassembles a chunked response instead of stopping at the first frame', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);

      final pending = harness.client.sendCommand('music/playlists/playlist_tracks');
      await harness.pump();
      final messageId = harness.sentMessageIds.last;

      // Generator commands stream 500 items per frame and terminate with an
      // empty `partial: false` frame. Completing on the first frame would
      // silently truncate a long playlist with no error to observe.
      harness.channel.emit({
        'message_id': messageId,
        'result': [_album('1', 'A')],
        'partial': true,
      });
      harness.channel.emit({
        'message_id': messageId,
        'result': [_album('2', 'B')],
        'partial': true,
      });
      harness.channel.emit({'message_id': messageId, 'result': <dynamic>[], 'partial': false});

      final result = await pending as List<dynamic>;
      expect(result, hasLength(2));
      expect([for (final entry in result) (entry as Map<String, dynamic>)['item_id']], ['1', '2']);
    });

    test('a chunked response whose terminator carries items keeps them', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);

      final pending = harness.client.sendCommand('music/playlists/playlist_tracks');
      await harness.pump();
      final messageId = harness.sentMessageIds.last;

      harness.channel.emit({
        'message_id': messageId,
        'result': [_album('1', 'A')],
        'partial': true,
      });
      harness.channel.emit({
        'message_id': messageId,
        'result': [_album('2', 'B')],
        'partial': false,
      });

      expect(await pending as List<dynamic>, hasLength(2));
    });

    test('a chunk restarts the request deadline so a long stream does not time out', () async {
      final harness = await _Harness.connected(requestTimeout: const Duration(milliseconds: 150));
      addTearDown(harness.dispose);

      final pending = harness.client.sendCommand('music/playlists/playlist_tracks');
      await harness.pump();
      final messageId = harness.sentMessageIds.last;

      for (var i = 0; i < 3; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        harness.channel.emit({
          'message_id': messageId,
          'result': [_album('$i', 'A')],
          'partial': true,
        });
      }
      harness.channel.emit({'message_id': messageId, 'result': <dynamic>[], 'partial': false});

      expect(await pending as List<dynamic>, hasLength(3));
    });

    test('a chunked stream that never terminates is capped by item count', () async {
      // The restarting deadline above is what removes the only bound this loop
      // had: a generator that keeps emitting frames grows `chunks` and pushes
      // the deadline out together, so the request never fails and the buffer
      // never stops growing. Failing loudly beats being killed by the OS.
      final harness = await _Harness.connected(maxChunkedItems: 3);
      addTearDown(harness.dispose);

      final pending = harness.client.sendCommand('music/playlists/playlist_tracks');
      final failure = expectLater(
        pending,
        throwsA(
          isA<MaProtocolException>().having((e) => e.message, 'message', contains('without a terminating frame')),
        ),
      );
      await harness.pump();
      final messageId = harness.sentMessageIds.last;

      for (var i = 0; i < 5; i++) {
        harness.channel.emit({
          'message_id': messageId,
          'result': [_album('$i', 'A')],
          'partial': true,
        });
      }
      await harness.pump();
      await failure;
    });

    test('a chunked stream is also capped by a total time budget', () async {
      // A slow dribble stays under the item cap forever. The per-chunk deadline
      // cannot catch it — every chunk is progress — so the whole response needs
      // its own budget.
      final harness = await _Harness.connected(
        requestTimeout: const Duration(seconds: 5),
        chunkedResponseTimeout: const Duration(milliseconds: 60),
      );
      addTearDown(harness.dispose);

      final pending = harness.client.sendCommand('music/playlists/playlist_tracks');
      final failure = expectLater(
        pending,
        throwsA(isA<MaTimeoutException>().having((e) => e.message, 'message', contains('total budget'))),
      );
      await harness.pump();
      final messageId = harness.sentMessageIds.last;

      for (var i = 0; i < 6; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        harness.channel.emit({
          'message_id': messageId,
          'result': [_album('$i', 'A')],
          'partial': true,
        });
      }
      await harness.pump();
      await failure;
    });

    test('playlist tracks retry once with force_refresh when the server answers empty', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);
      final library = MusicAssistantLibrary(harness.client);

      final pending = library.getPlaylistTracks(_item('4', uri: 'library://playlist/4'));
      await harness.pump();
      // A playlist the server has not resolved yet answers with an empty list
      // and no error, so every playlist would look empty without the retry.
      expect(harness.sentFrames.last['args'], {'item_id': '4', 'provider_instance_id_or_domain': 'library'});
      harness.channel.emit({'message_id': harness.sentMessageIds.last, 'result': <dynamic>[]});
      await harness.pump();

      expect(harness.sentFrames.last['args'], {
        'item_id': '4',
        'provider_instance_id_or_domain': 'library',
        'force_refresh': true,
      });
      harness.channel.emit({
        'message_id': harness.sentMessageIds.last,
        'result': [_album('1', 'A')],
      });
      expect((await pending).single.itemId, '1');
    });

    test('playlist tracks do not re-request when the first answer has items', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);
      final library = MusicAssistantLibrary(harness.client);

      final pending = library.getPlaylistTracks(_item('4', uri: 'library://playlist/4'));
      await harness.pump();
      harness.channel.emit({
        'message_id': harness.sentMessageIds.last,
        'result': [_album('1', 'A')],
      });

      expect(await pending, hasLength(1));
      expect(harness.sentFrames, hasLength(1));
    });

    test('getCount reads the bare integer result', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);
      final library = MusicAssistantLibrary(harness.client);

      final pending = library.getCount(MaLibraryType.tracks);
      await harness.pump();
      expect(harness.sentFrames.last['command'], 'music/tracks/count');

      harness.channel.emit({'message_id': harness.sentMessageIds.last, 'result': 365691, 'partial': false});
      expect(await pending, 365691);
    });
  });

  group('search', () {
    test('sends library_only: true by default', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);
      final library = MusicAssistantLibrary(harness.client);

      final pending = library.search('love');
      await harness.pump();

      final args = harness.sentFrames.last['args'] as Map<String, dynamic>;
      expect(harness.sentFrames.last['command'], 'music/search');
      expect(args['library_only'], isTrue, reason: 'without it the server queries every provider live (8.4s vs 0.09s)');
      expect(args['search_query'], 'love');
      expect(args['media_types'], ['album', 'artist', 'track', 'playlist']);
      expect(args['limit'], 50);

      harness.channel.emit({
        'message_id': harness.sentMessageIds.last,
        'result': {
          'albums': [_album('9560', 'Love')],
          'artists': [],
          'tracks': [],
          'playlists': [],
          'radio': [],
          'audiobooks': [],
          'podcasts': [],
        },
      });

      final results = await pending;
      expect(results.albums.single.name, 'Love');
      expect(results.totalCount, 1);
    });

    test('library_only can be turned off explicitly', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);
      final library = MusicAssistantLibrary(harness.client);

      unawaited(
        library.search('love', libraryOnly: false, types: [MaLibraryType.tracks]).catchError((Object _) {
          return const MaSearchResults();
        }),
      );
      await harness.pump();

      final args = harness.sentFrames.last['args'] as Map<String, dynamic>;
      expect(args['library_only'], isFalse);
      expect(args['media_types'], ['track']);
    });

    test('an empty query short-circuits without hitting the server', () async {
      final harness = await _Harness.connected();
      addTearDown(harness.dispose);
      final library = MusicAssistantLibrary(harness.client);

      final results = await library.search('   ');
      expect(results.isEmpty, isTrue);
      expect(harness.sentFrames, isEmpty);
    });
  });

  group('models', () {
    test('parses a real album item', () {
      final item = MaItem.fromJson(_album('9560', '+ (plus)'));

      expect(item.itemId, '9560');
      expect(item.provider, 'library');
      expect(item.sortName, '+');
      expect(item.uri, 'library://album/9560');
      expect(item.mediaType, 'album');
      expect(item.year, 2011);
      expect(item.favorite, isFalse);
      expect(item.primaryArtist?.name, 'Ed Sheeran');
      expect(item.imagePath, 'al-4e9Hni3gptmRhnfiL6Y6iJ_692d2ed2');
    });

    test('tolerates a nearly empty item', () {
      final item = MaItem.fromJson(const {'item_id': 7});

      expect(item.itemId, '7');
      expect(item.name, '');
      expect(item.sortName, '');
      expect(item.year, isNull);
      expect(item.artists, isEmpty);
      expect(item.imagePath, isNull);
      expect(item.id, ':7');
    });

    test('falls back to name when sort_name is absent', () {
      expect(MaItem.fromJson(const {'item_id': '1', 'name': 'Nirvana'}).sortName, 'Nirvana');
    });

    test('search results default every bucket to empty', () {
      expect(MaSearchResults.fromJson(null).isEmpty, isTrue);
      expect(MaSearchResults.fromJson(const {'albums': null}).albums, isEmpty);
    });

    test('maps library types to their search media_types', () {
      expect(MaLibraryType.albums.mediaType, 'album');
      expect(MaLibraryType.playlists.segment, 'playlists');
    });
  });
}

// --- fixtures ---------------------------------------------------------------

Map<String, dynamic> _album(String itemId, String name) => {
  'item_id': itemId,
  'provider': 'library',
  'name': name,
  'sort_name': '+',
  'uri': 'library://album/$itemId',
  'media_type': 'album',
  'favorite': false,
  'year': 2011,
  'artists': [
    {'item_id': '46', 'provider': 'library', 'name': 'Ed Sheeran', 'uri': 'library://artist/46'},
  ],
  'metadata': {
    'images': [
      {'type': 'thumb', 'path': 'al-4e9Hni3gptmRhnfiL6Y6iJ_692d2ed2', 'remotely_accessible': false},
    ],
  },
};

MaItem _item(String itemId, {String provider = 'library', String? uri}) => MaItem(
  itemId: itemId,
  provider: provider,
  name: 'Item $itemId',
  sortName: 'item $itemId',
  uri: uri ?? 'library://album/$itemId',
  mediaType: 'album',
);

// --- fakes ------------------------------------------------------------------

/// In-memory [MaChannel] standing in for the WebSocket.
class _FakeChannel implements MaChannel {
  final List<String> sent = [];
  final StreamController<dynamic> _incoming = StreamController<dynamic>.broadcast();

  /// Number of times the client asked for a transport, i.e. connection
  /// attempts. Used to observe the retry loop.
  int openCount = 0;
  bool failConnections;
  Uri? url;

  _FakeChannel({this.failConnections = false});

  Future<MaChannel> open(Uri url) async {
    openCount++;
    this.url = url;
    if (failConnections) throw const SocketFailure();
    return this;
  }

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  void send(String message) => sent.add(message);

  @override
  Future<void> close() async {}

  void emit(Map<String, dynamic> frame) => emitRaw(jsonEncode(frame));

  void emitRaw(String frame) {
    if (!_incoming.isClosed) _incoming.add(frame);
  }

  Future<void> closeFromServer() async {
    if (!_incoming.isClosed) await _incoming.close();
  }

  Future<void> shutdown() async {
    if (!_incoming.isClosed) await _incoming.close();
  }
}

class SocketFailure implements Exception {
  const SocketFailure();
}

/// A connected client plus its fake transport.
class _Harness {
  final MusicAssistantApi client;
  final _FakeChannel channel;

  _Harness(this.client, this.channel);

  static Future<_Harness> connected({
    Uri? baseUrl,
    Duration requestTimeout = const Duration(seconds: 5),
    Duration retryBaseDelay = const Duration(seconds: 30),
    int maxChunkedItems = MusicAssistantApi.defaultMaxChunkedItems,
    Duration chunkedResponseTimeout = MusicAssistantApi.defaultChunkedResponseTimeout,
    int maxConcurrentRequests = MusicAssistantApi.defaultMaxConcurrentRequests,
    bool autoReconnect = true,
  }) async {
    final channel = _FakeChannel();
    final client = MusicAssistantApi(
      channelFactory: channel.open,
      requestTimeout: requestTimeout,
      handshakeTimeout: const Duration(seconds: 2),
      retryBaseDelay: retryBaseDelay,
      maxChunkedItems: maxChunkedItems,
      chunkedResponseTimeout: chunkedResponseTimeout,
      maxConcurrentRequests: maxConcurrentRequests,
      autoReconnect: autoReconnect,
    );
    final connecting = client.connect(baseUrl ?? Uri.parse('http://127.0.0.1:8095'));
    // The greeting is unsolicited, so it can only be emitted once the client
    // has subscribed.
    await Future<void>.delayed(Duration.zero);
    channel.emit(_greeting);
    await connecting;
    channel.sent.clear();
    return _Harness(client, channel);
  }

  List<Map<String, dynamic>> get sentFrames => [
    for (final frame in channel.sent) jsonDecode(frame) as Map<String, dynamic>,
  ];

  List<String> get sentMessageIds => [for (final frame in sentFrames) frame['message_id'] as String];

  /// Lets queued microtasks and stream events settle.
  Future<void> pump() => Future<void>.delayed(Duration.zero);

  Future<void> dispose() async {
    await client.dispose();
    await channel.shutdown();
  }
}
