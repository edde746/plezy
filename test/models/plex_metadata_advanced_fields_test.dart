import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex/plex_metadata_preferences.dart';
import 'package:plezy/services/plex_mappers.dart';

void main() {
  group('PlexMetadataPreferences', () {
    test('canonicalizes booleans while preserving string, numeric, and empty preference values', () {
      final preferences = PlexMetadataPreferences.fromMediaContainer({
        'Metadata': [
          {
            'Setting': [
              {'id': 'episodeSort', 'value': 1},
              {'id': 'useOriginalTitle', 'value': true},
              {'id': 'useLocalArtwork', 'value': false},
              {'id': 'languageOverride', 'value': ''},
              {'id': 'showOrdering', 'value': 'tvdbAbsolute'},
            ],
          },
        ],
      });

      expect(preferences.values, {
        'episodeSort': '1',
        'useOriginalTitle': '1',
        'useLocalArtwork': '0',
        'languageOverride': '',
        'showOrdering': 'tvdbAbsolute',
      });
    });

    test('returns no preferences for absent, null, or malformed metadata envelopes', () {
      final containers = <Map<String, dynamic>?>[
        null,
        const {},
        const {'Metadata': null},
        const {'Metadata': 'not-an-object'},
        const {
          'Metadata': [null, 'not-an-object'],
        },
      ];

      for (final container in containers) {
        expect(PlexMetadataPreferences.fromMediaContainer(container).values, isEmpty, reason: '$container');
      }
    });

    test('ignores malformed setting siblings without discarding valid rows', () {
      final preferences = PlexMetadataPreferences.fromMediaContainer({
        'Metadata': {
          'Setting': [
            null,
            'not-an-object',
            {'id': 7, 'value': 'wrong-id-type'},
            {'id': 'missing-value'},
            {'id': 'null-value', 'value': null},
            {
              'id': 'object-value',
              'value': {'nested': true},
            },
            {'id': 'valid', 'value': -3},
          ],
        },
      });

      expect(preferences.values, {'valid': '-3'});
    });

    test('accepts the single-setting object shape', () {
      final preferences = PlexMetadataPreferences.fromMediaContainer({
        'Metadata': {
          'Setting': {'id': 'subtitleMode', 'value': 2},
        },
      });

      expect(preferences.values, {'subtitleMode': '2'});
    });
  });

  test('Plex metadata DTO preserves original title and flexible rating values', () {
    final metadata = PlexMetadataDto.fromJson({
      'ratingKey': 'movie-1',
      'originalTitle': 'Le titre original',
      'rating': '8.2',
      'audienceRating': 8,
      'userRating': '9.5',
    });

    expect(metadata.originalTitle, 'Le titre original');
    expect(metadata.rating, 8.2);
    expect(metadata.audienceRating, 8.0);
    expect(metadata.userRating, 9.5);
  });
}
