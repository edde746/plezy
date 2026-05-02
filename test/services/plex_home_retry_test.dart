import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

typedef _RequestHandler = Future<http.StreamedResponse> Function(http.BaseRequest request);

class _SequenceClient extends http.BaseClient {
  _SequenceClient(this._handlers);

  final List<_RequestHandler> _handlers;
  final requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    if (_handlers.isEmpty) {
      throw StateError('Unexpected request: ${request.url}');
    }
    return _handlers.removeAt(0)(request);
  }
}

void main() {
  group('PlexClient home hub retries', () {
    test('fetchGlobalHubs retries a transient first failure', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
      addTearDown(db.close);

      final httpClient = _SequenceClient([
        (_) async => throw TimeoutException('cold Plex start'),
        (_) async => _jsonResponse(_globalHubsPayload()),
      ]);
      final client = PlexClient.forTesting(
        config: PlexConfig(
          baseUrl: 'http://server:32400',
          token: 'token',
          clientIdentifier: 'client-id',
          product: 'Plezy',
          version: 'test',
        ),
        serverId: 'server-id',
        serverName: 'Server',
        httpClient: httpClient,
      );
      addTearDown(client.close);

      final hubs = await client.fetchGlobalHubs(limit: 12);

      expect(hubs, hasLength(1));
      expect(hubs.single.title, 'Recently Added Movies');
      expect(hubs.single.items.single.title, 'Movie A');
      expect(httpClient.requests, hasLength(2));
      expect(httpClient.requests.map((r) => r.url.path), everyElement('/hubs'));
      expect(httpClient.requests.map((r) => r.url.queryParameters['count']), everyElement('12'));
    });
  });
}

Future<http.StreamedResponse> _jsonResponse(Map<String, dynamic> body) async {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(body))),
    200,
    headers: {'content-type': 'application/json'},
  );
}

Map<String, dynamic> _globalHubsPayload() => {
  'MediaContainer': {
    'Hub': [
      {
        'key': '/hubs/movie.recentlyAdded',
        'title': 'Recently Added Movies',
        'type': 'movie',
        'hubIdentifier': 'movie.recentlyAdded.1',
        'size': 1,
        'Metadata': [
          {'ratingKey': '1', 'type': 'movie', 'title': 'Movie A'},
        ],
      },
    ],
  },
};
