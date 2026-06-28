import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/tracker_http_client.dart';

TrackerHttpClient _client(void Function(http.Request) capture) {
  return TrackerHttpClient(
    service: TrackerService.mal,
    logLabel: 'MAL',
    httpClient: MockClient((request) async {
      capture(request);
      return http.Response('{}', 200);
    }),
  );
}

void main() {
  group('TrackerHttpClient.sendJson content type', () {
    test('defaults a JSON content type when the caller omits one', () async {
      http.Request? sent;
      final client = _client((r) => sent = r);

      await client.sendJson(
        'POST',
        Uri.parse('https://api.example.com/x'),
        headers: {'Accept': 'application/json'},
        body: {'a': 1},
      );

      expect(sent!.headers['content-type'], contains('application/json'));
      client.dispose();
    });

    test('preserves a caller-provided content type', () async {
      http.Request? sent;
      final client = _client((r) => sent = r);

      await client.sendJson(
        'POST',
        Uri.parse('https://api.example.com/x'),
        headers: {'Content-Type': 'application/vnd.api+json'},
        body: {'a': 1},
      );

      expect(sent!.headers['content-type'], contains('application/vnd.api+json'));
      client.dispose();
    });

    test('preserves a caller-provided content type case-insensitively', () async {
      http.Request? sent;
      final client = _client((r) => sent = r);

      await client.sendJson(
        'POST',
        Uri.parse('https://api.example.com/x'),
        headers: {'content-type': 'application/vnd.api+json'},
        body: {'a': 1},
      );

      expect(sent!.headers['content-type'], contains('application/vnd.api+json'));
      client.dispose();
    });

    test('does not add a content type when there is no body', () async {
      http.Request? sent;
      final client = _client((r) => sent = r);

      await client.sendJson('GET', Uri.parse('https://api.example.com/x'), headers: {'Accept': 'application/json'});

      expect(sent!.headers.containsKey('content-type'), isFalse);
      client.dispose();
    });
  });
}
