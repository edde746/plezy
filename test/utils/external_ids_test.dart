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

  group('ExternalIds.fromLegacyPlexGuid', () {
    test('normalizes official Plex agent GUIDs', () {
      final cases = <({String guid, String? imdb, int? tmdb, int? tvdb})>[
        (guid: 'com.plexapp.agents.imdb://tt29768334?lang=en', imdb: 'tt29768334', tmdb: null, tvdb: null),
        (guid: 'com.plexapp.agents.themoviedb://1241983', imdb: null, tmdb: 1241983, tvdb: null),
        (guid: 'com.plexapp.agents.thetvdb://315500?lang=en', imdb: null, tmdb: null, tvdb: 315500),
      ];

      for (final testCase in cases) {
        final ids = ExternalIds.fromLegacyPlexGuid(testCase.guid);
        expect(
          (imdb: ids.imdb, tmdb: ids.tmdb, tvdb: ids.tvdb),
          (imdb: testCase.imdb, tmdb: testCase.tmdb, tvdb: testCase.tvdb),
          reason: testCase.guid,
        );
      }
    });

    test('normalizes HAMA GUID modes with direct external IDs', () {
      final cases = <({String guid, String? imdb, int? tmdb, int? tvdb})>[
        (guid: 'com.plexapp.agents.hama://tvdb-315500', imdb: null, tmdb: null, tvdb: 315500),
        (guid: 'com.plexapp.agents.hama://tvdb2-315500', imdb: null, tmdb: null, tvdb: 315500),
        (guid: 'com.plexapp.agents.hama://tvdb9-315500', imdb: null, tmdb: null, tvdb: 315500),
        (guid: 'com.plexapp.agents.hama://tmdb-69346', imdb: null, tmdb: 69346, tvdb: null),
        (guid: 'com.plexapp.agents.hama://tsdb-69346?lang=en', imdb: null, tmdb: 69346, tvdb: null),
        (guid: 'com.plexapp.agents.hama://imdb-6455986', imdb: 'tt6455986', tmdb: null, tvdb: null),
        (guid: 'com.plexapp.agents.hama://imdb-tt6455986', imdb: 'tt6455986', tmdb: null, tvdb: null),
      ];

      for (final testCase in cases) {
        final ids = ExternalIds.fromLegacyPlexGuid(testCase.guid);
        expect(
          (imdb: ids.imdb, tmdb: ids.tmdb, tvdb: ids.tvdb),
          (imdb: testCase.imdb, tmdb: testCase.tmdb, tvdb: testCase.tvdb),
          reason: testCase.guid,
        );
      }
    });

    test('rejects unsupported agents, AniDB modes, and malformed IDs', () {
      final invalid = <Object?>[
        null,
        315500,
        '',
        'not a URI',
        'plex://movie/abc',
        'local://315500',
        'com.plexapp.agents.none://315500',
        'com.plexapp.agents.hama://anidb-11905',
        'com.plexapp.agents.hama://tvdb10-315500',
        'com.plexapp.agents.hama://tvdb-not-a-number',
        'com.plexapp.agents.hama://tmdb-',
        'com.plexapp.agents.hama://imdb-not-an-id',
        'com.plexapp.agents.themoviedb://1241983/extra',
      ];

      for (final guid in invalid) {
        expect(ExternalIds.fromLegacyPlexGuid(guid).hasAny, isFalse, reason: '$guid');
      }
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
