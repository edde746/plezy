import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/remote_streams/remote_stream_models.dart';
import 'package:plezy/services/remote_streams/stremio_addon_client.dart';

StremioAddonInstallation _addon() => const StremioAddonInstallation(
  id: 'installation',
  name: 'Test catalog',
  manifestUrl: 'https://catalog.example.test/prefix/manifest.json?install=private',
  manifest: {
    'id': 'test.catalog',
    'name': 'Test catalog',
    'version': '1.0.0',
    'resources': [
      {
        'name': 'catalog',
        'types': ['movie'],
      },
    ],
    'catalogs': [
      {
        'type': 'movie',
        'id': 'top',
        'name': 'Top',
        'extra': [
          {
            'name': 'genre',
            'title': 'Genre',
            'isRequired': true,
            'options': ['Drama', 'Mystery'],
            'optionsLimit': 1,
          },
          {'name': 'skip'},
        ],
      },
    ],
  },
);

void main() {
  group('Stremio catalog filters', () {
    test('catalog descriptors expose bounded option lists and required fields', () {
      final client = StremioAddonClient(client: MockClient((_) async => http.Response('{}', 200)));
      addTearDown(client.close);

      final catalog = client.catalogs(_addon()).single;

      expect(catalog.canBrowse, isTrue);
      expect(catalog.supportsSkip, isTrue);
      expect(catalog.requiredExtras, {'genre'});
      expect(catalog.extras.singleWhere((extra) => extra.name == 'genre').options, ['Drama', 'Mystery']);
      expect(catalog.extras.singleWhere((extra) => extra.name == 'genre').optionsLimit, 1);
    });

    test('required extras and pagination stay in the configured add-on path', () async {
      Uri? requested;
      final client = StremioAddonClient(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response(jsonEncode({'metas': []}), 200, headers: {'content-type': 'application/json'});
        }),
      );
      addTearDown(client.close);
      final catalog = client.catalogs(_addon()).single;

      await client.fetchCatalog(_addon(), catalog, skip: 20, extras: const {'genre': 'Drama'});

      expect(requested?.pathSegments, ['prefix', 'catalog', 'movie', 'top', 'genre=Drama&skip=20.json']);
      expect(requested?.queryParameters, {'install': 'private'});
    });

    test('free-text required filters preserve punctuation and commas', () async {
      Uri? requested;
      final addon = StremioAddonInstallation(
        id: 'free-text',
        name: 'Free text',
        manifestUrl: 'https://catalog.example.test/manifest.json',
        manifest: {
          ..._addon().manifest,
          'catalogs': [
            {
              'type': 'movie',
              'id': 'by-title',
              'extra': [
                {'name': 'query', 'title': 'Title', 'isRequired': true},
              ],
            },
          ],
        },
      );
      final client = StremioAddonClient(
        client: MockClient((request) async {
          requested = request.url;
          return http.Response('{"metas":[]}', 200);
        }),
      );
      addTearDown(client.close);
      final catalog = client.catalogs(addon).single;

      expect(catalog.canBrowse, isTrue);
      await client.fetchCatalog(addon, catalog, extras: const {'query': 'Crime, Mystery'});

      expect(requested?.pathSegments.last, 'query=Crime, Mystery.json');
    });

    test('missing required extras and undeclared option values are rejected', () async {
      final client = StremioAddonClient(client: MockClient((_) async => http.Response('{"metas":[]}', 200)));
      addTearDown(client.close);
      final catalog = client.catalogs(_addon()).single;

      await expectLater(client.fetchCatalog(_addon(), catalog), throwsA(isA<StremioAddonException>()));
      await expectLater(
        client.fetchCatalog(_addon(), catalog, extras: const {'genre': 'Comedy'}),
        throwsA(isA<StremioAddonException>()),
      );
    });

    test('legacy extraRequired remains supported', () {
      final addon = StremioAddonInstallation(
        id: 'legacy-required',
        name: 'Legacy required',
        manifestUrl: 'https://catalog.example.test/manifest.json',
        manifest: {
          ..._addon().manifest,
          'catalogs': [
            {
              'type': 'movie',
              'id': 'legacy',
              'name': 'Legacy',
              'extraRequired': ['genre'],
              'extra': [
                {
                  'name': 'genre',
                  'options': ['Drama', 'Mystery'],
                },
              ],
            },
          ],
        },
      );
      final client = StremioAddonClient(client: MockClient((_) async => http.Response('{}', 200)));
      addTearDown(client.close);

      final catalog = client.catalogs(addon).single;

      expect(catalog.canBrowse, isTrue);
      expect(catalog.requiredExtras, {'genre'});
    });

    test('search-only catalogs remain searchable but are not browsed unfiltered', () {
      final addon = StremioAddonInstallation(
        id: 'search-only',
        name: 'Search only',
        manifestUrl: 'https://catalog.example.test/manifest.json',
        manifest: {
          ..._addon().manifest,
          'catalogs': [
            {
              'type': 'movie',
              'id': 'search',
              'extra': [
                {'name': 'search', 'isRequired': true},
                {'name': 'skip'},
              ],
            },
          ],
        },
      );
      final client = StremioAddonClient(client: MockClient((_) async => http.Response('{}', 200)));
      addTearDown(client.close);

      final catalog = client.catalogs(addon).single;

      expect(catalog.canBrowse, isFalse);
      expect(catalog.supportsSearch, isTrue);
    });
  });
}
