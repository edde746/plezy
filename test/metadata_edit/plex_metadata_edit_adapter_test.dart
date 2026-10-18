import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/metadata_edit/metadata_edit_models.dart';
import 'package:plezy/metadata_edit/plex_metadata_edit_adapter.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/services/plex_api_cache.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';
import '../test_helpers/media_items.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(database);
    addTearDown(database.close);
  });

  test('label suggestions come from the section label filter facet', () async {
    final client = testPlexClient(
      serverId: ServerId('server-1'),
      handler: (request) async {
        if (request.url.path == '/library/sections/1/filters') {
          return jsonResponse({
            'MediaContainer': {
              'Directory': [
                {'filter': 'genre', 'filterType': 'string', 'key': '/library/sections/1/genre', 'title': 'Genre'},
                {'filter': 'label', 'filterType': 'string', 'key': '/library/sections/1/label', 'title': 'Label'},
              ],
            },
          });
        }
        if (request.url.path == '/library/sections/1/label') {
          return jsonResponse({
            'MediaContainer': {
              'Directory': [
                {'key': '42', 'title': 'kids'},
                {'key': '43', 'title': 'horror'},
              ],
            },
          });
        }
        return http.Response('unexpected ${request.url}', 404);
      },
    );
    addTearDown(client.close);

    final adapter = PlexMetadataEditAdapter(client);
    final item = testMediaItem(
      id: 'movie-1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      libraryId: '1',
      serverId: 'server-1',
    );
    final draft = MetadataEditDraft(sourceItem: item, currentItem: item, values: {});
    final labelField = adapter.buildSchema(draft).expand((s) => s.fields).singleWhere((f) => f.id == 'label');

    expect(await adapter.fetchTagSuggestions(draft, labelField), ['kids', 'horror']);
  });

  test('a section without a label facet returns no suggestions', () async {
    final client = testPlexClient(
      serverId: ServerId('server-1'),
      handler: (request) async {
        if (request.url.path == '/library/sections/1/filters') {
          return jsonResponse({
            'MediaContainer': {
              'Directory': [
                {'filter': 'genre', 'filterType': 'string', 'key': '/library/sections/1/genre', 'title': 'Genre'},
              ],
            },
          });
        }
        return http.Response('unexpected ${request.url}', 404);
      },
    );
    addTearDown(client.close);

    final adapter = PlexMetadataEditAdapter(client);
    final item = testMediaItem(
      id: 'movie-1',
      backend: MediaBackend.plex,
      kind: MediaKind.movie,
      libraryId: '1',
      serverId: 'server-1',
    );
    final draft = MetadataEditDraft(sourceItem: item, currentItem: item, values: {});
    final labelField = adapter.buildSchema(draft).expand((s) => s.fields).singleWhere((f) => f.id == 'label');

    expect(await adapter.fetchTagSuggestions(draft, labelField), isEmpty);
  });

  test('an item without a library id skips the facet lookup', () async {
    var called = false;
    final client = testPlexClient(
      serverId: ServerId('server-1'),
      handler: (request) async {
        called = true;
        return http.Response('', 404);
      },
    );
    addTearDown(client.close);

    final adapter = PlexMetadataEditAdapter(client);
    final item = testMediaItem(id: 'movie-1', backend: MediaBackend.plex, kind: MediaKind.movie, serverId: 'server-1');
    final draft = MetadataEditDraft(sourceItem: item, currentItem: item, values: {});
    final labelField = adapter.buildSchema(draft).expand((s) => s.fields).singleWhere((f) => f.id == 'label');

    expect(await adapter.fetchTagSuggestions(draft, labelField), isEmpty);
    expect(called, isFalse);
  });
}
