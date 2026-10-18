import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/plex_api_cache.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

Map<String, dynamic> _container(List<Map<String, dynamic>> metadata, {int? totalSize}) => {
  'MediaContainer': {'size': metadata.length, 'totalSize': ?totalSize, 'Metadata': metadata},
};

Map<String, dynamic> _plexTitle(String id, {required int library, List<int> tags = const [], String? released}) => {
  'ratingKey': id,
  'type': 'movie',
  'title': 'Title $id',
  'librarySectionID': library,
  'originallyAvailableAt': ?released,
  'Collection': [
    for (final tag in tags) {'id': tag, 'tag': 'tag text $tag'},
  ],
};

Map<String, dynamic> _plexCollection(String id, {required int index, String? title, Map<String, dynamic>? extra}) => {
  'ratingKey': id,
  'type': 'collection',
  'title': title ?? 'Collection $id',
  'index': index,
  ...?extra,
};

List<String> _ids(List<CollectionMembership> memberships) => [
  for (final (:collection, :memberIds) in memberships) '${collection.id}:${memberIds.join(',')}',
];

void main() {
  group('Plex fetchCollectionMemberships', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      PlexApiCache.initialize(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('matches collections by tag id and orders members by release date or title', () async {
      final client = testPlexClient(
        handler: (request) async => switch (request.url.path) {
          '/library/metadata/m1,m2,m3,m4' => jsonResponse(
            _container([
              _plexTitle('m1', library: 1, tags: [11, 12], released: '2024-03-01'),
              _plexTitle('m2', library: 1, tags: [11], released: '2021-10-22'),
              _plexTitle('m3', library: 1, tags: [12, 13, 14], released: '1999-01-01'),
              _plexTitle('m4', library: 1),
            ]),
          ),
          '/library/sections/1/collections' => jsonResponse(
            _container([
              _plexCollection('c-dune', index: 11, title: 'dune'),
              _plexCollection('c-alpha', index: 12, extra: {'collectionSort': '1'}),
              _plexCollection('c-smart', index: 13, extra: {'smart': '1'}),
              _plexCollection('c-hidden', index: 14, extra: {'collectionMode': '0'}),
              _plexCollection('c-unrelated', index: 99),
            ], totalSize: 5),
          ),
          _ => http.Response('not found', 404),
        },
      );
      addTearDown(client.close);

      final memberships = await client.fetchCollectionMemberships({'m1', 'm2', 'm3', 'm4'});

      expect(_ids(memberships), ['c-dune:m2,m1', 'c-alpha:m1,m3']);
      expect(memberships.first.collection.kind, MediaKind.collection);
      expect(memberships.first.collection.title, 'dune');
    });

    test('reads a custom-ordered collection\'s children for its order', () async {
      final client = testPlexClient(
        handler: (request) async => switch (request.url.path) {
          '/library/metadata/a,b' => jsonResponse(
            _container([
              _plexTitle('a', library: 2, tags: [5], released: '1977-05-25'),
              _plexTitle('b', library: 2, tags: [5], released: '1999-05-19'),
            ]),
          ),
          '/library/sections/2/collections' => jsonResponse(
            _container([
              _plexCollection('saga', index: 5, extra: {'collectionSort': '2'}),
            ], totalSize: 1),
          ),
          '/library/collections/saga/children' => jsonResponse(
            _container([
              {'ratingKey': 'not-downloaded', 'type': 'movie', 'title': 'Other'},
              {'ratingKey': 'b', 'type': 'movie', 'title': 'Episode I'},
              {'ratingKey': 'a', 'type': 'movie', 'title': 'Episode IV'},
            ], totalSize: 3),
          ),
          _ => http.Response('not found', 404),
        },
      );
      addTearDown(client.close);

      expect(_ids(await client.fetchCollectionMemberships({'a', 'b'})), ['saga:b,a']);
    });

    test('a failed collection listing fails the lookup instead of answering partially', () async {
      final client = testPlexClient(
        handler: (request) async => switch (request.url.path) {
          '/library/metadata/x' => jsonResponse(
            _container([
              _plexTitle('x', library: 3, tags: [1]),
            ]),
          ),
          _ => http.Response('error', 500),
        },
      );
      addTearDown(client.close);

      await expectLater(client.fetchCollectionMemberships({'x'}), throwsA(anything));
    });
  });

  group('Jellyfin fetchCollectionMemberships', () {
    test('keeps the BoxSets holding asked-about titles, in each BoxSet\'s order', () async {
      final childrenRequests = <String>[];
      final client = testJellyfinClient(
        handler: (request) async {
          final query = request.url.queryParameters;
          if (request.url.path != '/Items') return http.Response('not found', 404);
          if (query['IncludeItemTypes'] == 'BoxSet') {
            return jsonResponse({
              'Items': [
                {'Id': 'box-dune', 'Name': 'Dune Collection', 'Type': 'BoxSet'},
                {'Id': 'box-other', 'Name': 'Other', 'Type': 'BoxSet'},
              ],
              'TotalRecordCount': 2,
            });
          }
          final parentId = query['ParentId']!;
          childrenRequests.add(parentId);
          return jsonResponse({
            'Items': switch (parentId) {
              'box-dune' => [
                {'Id': 'dune-1'},
                {'Id': 'not-downloaded'},
                {'Id': 'dune-2'},
              ],
              _ => [
                {'Id': 'unrelated'},
              ],
            },
          });
        },
      );
      addTearDown(client.close);

      final memberships = await client.fetchCollectionMemberships({'dune-2', 'dune-1', 'show-1'});

      expect(_ids(memberships), ['box-dune:dune-1,dune-2']);
      expect(memberships.single.collection.title, 'Dune Collection');
      expect(childrenRequests, ['box-dune', 'box-other']);
    });
  });
}
