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
      final cases = <({String guid, String? imdb, int? tmdb, int? tvdb, int? anidb})>[
        (guid: 'com.plexapp.agents.hama://tvdb-315500', imdb: null, tmdb: null, tvdb: 315500, anidb: null),
        (guid: 'com.plexapp.agents.hama://tvdb2-315500', imdb: null, tmdb: null, tvdb: 315500, anidb: null),
        (guid: 'com.plexapp.agents.hama://tvdb9-315500', imdb: null, tmdb: null, tvdb: 315500, anidb: null),
        (guid: 'com.plexapp.agents.hama://tmdb-69346', imdb: null, tmdb: 69346, tvdb: null, anidb: null),
        (guid: 'com.plexapp.agents.hama://tsdb-69346?lang=en', imdb: null, tmdb: 69346, tvdb: null, anidb: null),
        (guid: 'com.plexapp.agents.hama://imdb-6455986', imdb: 'tt6455986', tmdb: null, tvdb: null, anidb: null),
        (guid: 'com.plexapp.agents.hama://imdb-tt6455986', imdb: 'tt6455986', tmdb: null, tvdb: null, anidb: null),
        (guid: 'com.plexapp.agents.hama://anidb-11905?lang=en', imdb: null, tmdb: null, tvdb: null, anidb: 11905),
      ];

      for (final testCase in cases) {
        final ids = ExternalIds.fromLegacyPlexGuid(testCase.guid);
        expect(
          (imdb: ids.imdb, tmdb: ids.tmdb, tvdb: ids.tvdb, anidb: ids.anidb),
          (imdb: testCase.imdb, tmdb: testCase.tmdb, tvdb: testCase.tvdb, anidb: testCase.anidb),
          reason: testCase.guid,
        );
      }
    });

    test('an AniDB id is not a catalog id', () {
      final ids = ExternalIds.fromLegacyPlexGuid('com.plexapp.agents.hama://anidb-11905');
      expect(ids.hasAny, isTrue);
      expect(ids.hasCatalogIds, isFalse, reason: 'IMDb/TMDB/TVDB consumers must not act on an AniDB id');
    });

    test('rejects unsupported agents, AniDB grouping modes, and malformed IDs', () {
      final invalid = <Object?>[
        null,
        315500,
        '',
        'not a URI',
        'plex://movie/abc',
        'local://315500',
        'com.plexapp.agents.none://315500',
        // anidb2..9 group several AniDB entries under one TVDB-numbered Plex
        // show, so the guid's id does not describe the seasons beside it.
        'com.plexapp.agents.hama://anidb2-11905',
        'com.plexapp.agents.hama://anidb9-11905',
        'com.plexapp.agents.hama://anidb-not-a-number',
        'com.plexapp.agents.hama://anidb-',
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

  group('ExternalIds.legacyPlexGuidPrefixes', () {
    test('every prefix names a guid fromLegacyPlexGuid reads back to the same id', () {
      const ids = ExternalIds(imdb: 'tt0245429', tmdb: 129, tvdb: 276, anidb: 112);
      final prefixes = ids.legacyPlexGuidPrefixes;
      expect(prefixes, isNotEmpty);
      for (final prefix in prefixes) {
        expect(prefix, endsWith('?'), reason: 'a literal prefix filter must stop at the lang argument');
        final parsed = ExternalIds.fromLegacyPlexGuid('${prefix}lang=en');
        expect(parsed.intersects(ids), isTrue, reason: prefix);
      }
      expect(prefixes, contains('com.plexapp.agents.thetvdb://276?'));
      expect(prefixes, contains('com.plexapp.agents.hama://tvdb4-276?'));
      expect(prefixes, contains('com.plexapp.agents.hama://anidb-112?'));
    });

    test('is empty without ids', () {
      expect(const ExternalIds().legacyPlexGuidPrefixes, isEmpty);
    });
  });

  group('ExternalIds.fillFrom', () {
    test('keeps its own ids and only fills the ones it is missing', () {
      const modern = ExternalIds(tvdb: 315500);
      const legacy = ExternalIds(imdb: 'tt6455986', tvdb: 999, anidb: 11905);

      final merged = modern.fillFrom(legacy);

      expect(merged.tvdb, 315500, reason: 'the modern Guid array wins per field');
      expect(merged.imdb, 'tt6455986');
      expect(merged.anidb, 11905);
    });

    test('round-trips every id through JSON', () {
      const ids = ExternalIds(imdb: 'tt1', tmdb: 2, tvdb: 3, anidb: 4);
      final restored = ExternalIds.fromJson(ids.toJson());

      expect((restored.imdb, restored.tmdb, restored.tvdb, restored.anidb), ('tt1', 2, 3, 4));
      expect(ExternalIds.fromJson(const ExternalIds().toJson()).hasAny, isFalse);
    });

    test('intersects matches on an AniDB id alone', () {
      const hama = ExternalIds(anidb: 11905);
      expect(hama.intersects(const ExternalIds(anidb: 11905)), isTrue);
      expect(hama.intersects(const ExternalIds(tvdb: 315500)), isFalse);
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
