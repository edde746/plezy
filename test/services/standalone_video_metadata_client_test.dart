import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/standalone_video_metadata_client.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_transport.dart';

void main() {
  for (final byId in [false, true]) {
    test('video metadata accepts Trakt search arrays ${byId ? 'by external ID' : 'by title'}', () async {
      final paths = <String>[];
      final transport = SourceTransport(
        client: MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path.endsWith('/people')) {
            return http.Response(jsonEncode({'cast': []}), 200);
          }
          return http.Response(
            jsonEncode([
              {
                'type': 'movie',
                'movie': {
                  'title': 'Arrival',
                  'year': 2016,
                  'overview': 'A linguist deciphers an unfamiliar language.',
                  'rating': 8.8,
                  'genres': ['science-fiction'],
                  'ids': {'trakt': 123, 'imdb': 'tt2543164'},
                },
              },
            ]),
            200,
          );
        }),
      );
      addTearDown(transport.close);
      final client = StandaloneVideoMetadataClient(transport: transport);
      final result = await client.identify(
        SourceEntry(
          sourceId: 'local',
          id: 'movie',
          title: 'Arrival.2016.mkv',
          kind: SourceItemKind.video,
          identifiers: byId ? {'imdb': 'tt2543164'} : {},
        ),
      );
      expect(result?.title, 'Arrival');
      expect(result?.year, 2016);
      expect(result?.identifiers['trakt'], '123');
      expect(result?.rating, 8.8);
      expect(result?.genres, ['science-fiction']);
      expect(paths, [byId ? '/search/imdb/tt2543164' : '/search/movie,show', '/movies/123/people']);
    });
  }
}
