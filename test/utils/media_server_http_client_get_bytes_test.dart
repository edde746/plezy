import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  Future<List<int>> fetch({int? contentLength, List<List<int>> parts = chunks}) async {
    final client = MediaServerHttpClient(
      baseUrl: 'https://example.test/',
      client: MockClient.streaming(
        (request, _) async => http.StreamedResponse(Stream.fromIterable(parts), 200, contentLength: contentLength),
      ),
    );
    try {
      return await client.getBytes('/index.bif');
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
}
