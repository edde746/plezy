import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/utils/media_server_http_client.dart';

/// `getBytes` fills a buffer sized from Content-Length instead of growing one,
/// so a header that disagrees with the body must not lose or corrupt bytes.
void main() {
  const chunks = [
    [1, 2, 3],
    [4, 5],
    [6, 7, 8, 9],
  ];
  const body = [1, 2, 3, 4, 5, 6, 7, 8, 9];

  MediaServerHttpClient clientFor(http.StreamedResponse Function() respond) => MediaServerHttpClient(
    baseUrl: 'https://example.test/',
    client: MockClient.streaming((request, _) async => respond()),
  );

  Future<List<int>> fetch({int? contentLength, List<List<int>> parts = chunks, int? maxBytes}) async {
    final client = clientFor(
      () => http.StreamedResponse(Stream.fromIterable(parts), 200, contentLength: contentLength),
    );
    try {
      return await client.getBytes('/index.bif', maxBytes: maxBytes);
    } finally {
      client.close();
    }
  }

  test('a body matching its Content-Length arrives intact across chunks', () async {
    expect(await fetch(contentLength: body.length), body);
  });

  test('a body without Content-Length arrives intact', () async {
    expect(await fetch(), body);
  });

  test('a body longer than its Content-Length keeps every byte in order', () async {
    expect(await fetch(contentLength: 4), body);
  });

  test('a body shorter than its Content-Length returns only the received bytes', () async {
    expect(await fetch(contentLength: 20), body);
  });

  test('an empty body with Content-Length zero is empty', () async {
    expect(await fetch(contentLength: 0, parts: const []), isEmpty);
  });

  // A BIF scrub preview is tens of MB; checking its size only after the whole
  // body was buffered ran 32-bit Android TV boxes out of memory.
  group('maxBytes', () {
    final rejectedAsTooLarge = throwsA(
      isA<MediaServerHttpException>()
          .having((e) => e.isTransient, 'isTransient', isFalse)
          .having((e) => e.isCancellation, 'isCancellation', isFalse),
    );

    test('a body exactly at the limit arrives intact', () async {
      expect(await fetch(contentLength: body.length, maxBytes: body.length), body);
      expect(await fetch(maxBytes: body.length), body);
    });

    test('a declared Content-Length over the limit fails without waiting for the body', () async {
      // The body never arrives, so a client that tried to read it would hang.
      var cancelled = false;
      final unread = StreamController<List<int>>(onCancel: () => cancelled = true);
      addTearDown(unread.close);
      final client = clientFor(() => http.StreamedResponse(unread.stream, 200, contentLength: 1 << 30));
      addTearDown(client.close);

      await expectLater(client.getBytes('/index.bif', maxBytes: 1024), rejectedAsTooLarge);
      // Cancelled rather than left unread, which would park the connection.
      expect(cancelled, isTrue);
    });

    test('a body that outgrows its Content-Length fails once past the limit', () async {
      await expectLater(fetch(contentLength: 4, maxBytes: body.length - 1), rejectedAsTooLarge);
    });

    test('an undeclared body stops being read once it passes the limit', () async {
      const chunkCount = 1000;
      var produced = 0;
      Iterable<List<int>> chunksUntilCancelled() sync* {
        for (var i = 0; i < chunkCount; i++) {
          produced++;
          yield const [0, 0, 0, 0];
        }
      }

      final client = clientFor(() => http.StreamedResponse(Stream.fromIterable(chunksUntilCancelled()), 200));
      addTearDown(client.close);

      await expectLater(client.getBytes('/index.bif', maxBytes: 10), rejectedAsTooLarge);
      expect(produced, lessThan(chunkCount));
    });
  });
}
