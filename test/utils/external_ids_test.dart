import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/external_ids.dart';

void main() {
  group('ExternalIds.fromGuids', () {
    test('parses Plex `imdb://`, `tmdb://`, `tvdb://` URIs', () {
      final ids = ExternalIds.fromGuids(<dynamic>[
        {'id': 'imdb://tt12345'},
        {'id': 'tmdb://456'},
        {'id': 'tvdb://789'},
      ]);
      expect(ids.imdb, 'tt12345');
      expect(ids.tmdb, 456);
      expect(ids.tvdb, 789);
      expect(ids.hasAny, isTrue);
    });

    test('ignores unknown schemes and bad shapes', () {
      final ids = ExternalIds.fromGuids(<dynamic>[
        {'id': 'mbid://abc'},
        'not-a-map',
        {'id': null},
        {'id': 'tmdb://not-a-number'},
      ]);
      expect(ids.hasAny, isFalse);
    });
  });

  group('ExternalIds.fromJellyfinProviderIds', () {
    test('extracts Tmdb/Imdb/Tvdb (case-insensitive)', () {
      final ids = ExternalIds.fromJellyfinProviderIds({'Tmdb': '12345', 'Imdb': 'tt99999', 'Tvdb': '777'});
      expect(ids.tmdb, 12345);
      expect(ids.imdb, 'tt99999');
      expect(ids.tvdb, 777);
    });

    test('handles lowercase keys', () {
      final ids = ExternalIds.fromJellyfinProviderIds({'tmdb': '111', 'imdb': 'tt000'});
      expect(ids.tmdb, 111);
      expect(ids.imdb, 'tt000');
      expect(ids.tvdb, isNull);
    });

    test('ignores unknown providers and empty values', () {
      final ids = ExternalIds.fromJellyfinProviderIds({'AniList': '42', 'Tvdb': ''});
      expect(ids.hasAny, isFalse);
    });

    test('ignores non-numeric numeric IDs', () {
      final ids = ExternalIds.fromJellyfinProviderIds({'Tmdb': 'not-a-number', 'Imdb': 'tt12345'});
      expect(ids.tmdb, isNull);
      expect(ids.imdb, 'tt12345');
    });
  });
}
