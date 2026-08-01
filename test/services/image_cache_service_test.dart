import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/image_cache_service.dart';

/// Pins the artwork request limiter's permit lifecycle. CE's cache manager
/// abandons non-200/202 responses without listening to the body, so the
/// wrapper must release those slots itself or the limiter wedges after a
/// handful of stale-thumb 404s (#1473).
void main() {
  const timeout = Duration(seconds: 5);

  test('reduced-tier devices cap artwork fan-out', () {
    expect(artworkRequestConcurrencyForTier(reduced: true), 3);
    expect(artworkRequestConcurrencyForTier(reduced: false), 6);
  });

  http.Request get(String path) => http.Request('GET', Uri.parse('https://example.invalid$path'));

  MockClient mixedClient() => MockClient((request) async {
    if (request.url.path.contains('missing')) {
      return http.Response('not found', 404, headers: {'x-marker': 'err'});
    }
    return http.Response('poster-bytes', 200);
  });

  test('error burst does not wedge the limiter (#1473)', () async {
    final client = createArtworkHttpClientForTest(mixedClient(), maxConcurrent: 2);

    // More failures than permits, bodies deliberately never read — mirrors
    // CE throwing on the status without listening to the stream.
    for (var i = 0; i < 5; i++) {
      final response = await client.send(get('/missing/$i')).timeout(timeout);
      expect(response.statusCode, 404);
      expect(response.headers['x-marker'], 'err');
    }

    final ok = await client.send(get('/poster')).timeout(timeout);
    expect(ok.statusCode, 200);
    expect(await ok.stream.bytesToString().timeout(timeout), 'poster-bytes');
  });

  test('successful downloads still hold a slot until the body is drained', () async {
    final client = createArtworkHttpClientForTest(mixedClient(), maxConcurrent: 1);

    final first = await client.send(get('/poster')).timeout(timeout);
    var secondDone = false;
    final second = client.send(get('/poster')).then((response) async {
      secondDone = true;
      await response.stream.drain<void>();
    });

    await pumpEventQueue();
    expect(secondDone, isFalse, reason: 'slot must stay held while the first body is unread');

    await first.stream.drain<void>();
    await second.timeout(timeout);
    expect(secondDone, isTrue);
  });

  test('an unclaimed successful body cannot permanently leak a permit', () async {
    final client = createArtworkHttpClientForTest(
      mixedClient(),
      maxConcurrent: 1,
      unclaimedResponseTimeout: const Duration(milliseconds: 20),
    );

    // Mirrors an image widget being disposed after headers arrive but before
    // the cache manager starts listening to the response body.
    await client.send(get('/abandoned')).timeout(timeout);

    final next = await client.send(get('/poster')).timeout(timeout);
    expect(await next.stream.bytesToString().timeout(timeout), 'poster-bytes');
  });

  test('an unclaimed body is cancelled so the transport can reclaim its connection', () async {
    final cancelled = Completer<void>();
    final body = StreamController<List<int>>(onCancel: () => cancelled.complete());
    final client = createArtworkHttpClientForTest(
      MockClient.streaming((request, _) async => http.StreamedResponse(body.stream, 200)),
      maxConcurrent: 1,
      unclaimedResponseTimeout: const Duration(milliseconds: 20),
    );

    await client.send(get('/abandoned')).timeout(timeout);
    await cancelled.future.timeout(timeout);
    await body.close();
  });

  test('error bodies are drained so the transport can reclaim the connection', () async {
    final listened = Completer<void>();
    final body = StreamController<List<int>>(onListen: () => listened.complete());
    unawaited(body.close());
    final client = createArtworkHttpClientForTest(
      MockClient.streaming((request, _) async => http.StreamedResponse(body.stream, 404)),
      maxConcurrent: 2,
    );

    final response = await client.send(get('/missing')).timeout(timeout);
    expect(response.statusCode, 404);
    await listened.future.timeout(timeout);
  });

  test('a throwing send releases its slot', () async {
    var failures = 0;
    final client = createArtworkHttpClientForTest(
      MockClient((request) async {
        if (failures < 2) {
          failures++;
          throw http.ClientException('boom');
        }
        return http.Response('poster-bytes', 200);
      }),
      maxConcurrent: 1,
    );

    for (var i = 0; i < 2; i++) {
      await expectLater(client.send(get('/poster')).timeout(timeout), throwsA(isA<http.ClientException>()));
    }

    final ok = await client.send(get('/poster')).timeout(timeout);
    expect(ok.statusCode, 200);
  });

  test('cancelling a successful body releases its slot', () async {
    final client = createArtworkHttpClientForTest(mixedClient(), maxConcurrent: 1);

    final first = await client.send(get('/poster')).timeout(timeout);
    final subscription = first.stream.listen((_) {});
    await subscription.cancel();

    final ok = await client.send(get('/poster')).timeout(timeout);
    expect(ok.statusCode, 200);
    await ok.stream.drain<void>();
  });
}
