import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() => db.close());

  final item = testMediaItem(
    id: 'movie-1',
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    serverId: 'plex-1',
  );

  test('reads allowMediaDeletion from the authenticated root without caching it', () async {
    final requests = <http.Request>[];
    final values = <Object?>[1, false];
    final client = _client(requests, rootValue: () => values.removeAt(0));
    addTearDown(client.close);
    final permissions = client as MediaDeletionPermissionClient;

    expect(await permissions.fetchDeletePermission(item), isTrue);
    expect(await permissions.fetchDeletePermission(item), isFalse);
    expect(requests.map((request) => request.url.path), ['/', '/']);
  });

  test('returns null when Plex does not advertise the deletion capability', () async {
    final requests = <http.Request>[];
    final client = _client(requests, includeRootValue: false);
    addTearDown(client.close);

    expect(await (client as MediaDeletionPermissionClient).fetchDeletePermission(item), isNull);
  });

  test('re-checks the preference and deletes only when it is enabled', () async {
    final requests = <http.Request>[];
    final client = _client(requests, rootValue: () => '1');
    addTearDown(client.close);

    expect(await client.deleteMediaItem(item), isTrue);
    expect(requests.map((request) => '${request.method} ${request.url.path}'), [
      'GET /',
      'DELETE /library/metadata/movie-1',
    ]);
  });

  for (final disabledValue in <Object?>[false, 0, 'false', null]) {
    test('refuses the DELETE when allowMediaDeletion is $disabledValue', () async {
      final requests = <http.Request>[];
      final client = _client(
        requests,
        rootValue: () => disabledValue,
        includeRootValue: disabledValue != null,
      );
      addTearDown(client.close);

      expect(await client.deleteMediaItem(item), isFalse);
      expect(requests.map((request) => '${request.method} ${request.url.path}'), ['GET /']);
    });
  }
}

PlexClient _client(
  List<http.Request> requests, {
  Object? Function()? rootValue,
  bool includeRootValue = true,
}) {
  return testPlexClient(
    serverId: ServerId('plex-1'),
    httpClient: MockClient((request) async {
      requests.add(request);
      if (request.method == 'GET' && request.url.path == '/') {
        return http.Response(
          jsonEncode({
            'MediaContainer': {
              if (includeRootValue) 'allowMediaDeletion': rootValue?.call(),
            },
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }
      if (request.method == 'DELETE' && request.url.path == '/library/metadata/movie-1') {
        return http.Response('', 200);
      }
      return http.Response('not found', 404);
    }),
  );
}
