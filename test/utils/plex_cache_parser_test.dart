import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/plex_cache_parser.dart';

void main() {
  group('PlexCacheParser.extractMetadataList', () {
    test('returns null for null input', () {
      expect(PlexCacheParser.extractMetadataList(null), isNull);
    });

    test('returns null when MediaContainer missing', () {
      expect(PlexCacheParser.extractMetadataList({}), isNull);
    });

    test('returns null when Metadata key missing', () {
      expect(PlexCacheParser.extractMetadataList({'MediaContainer': {}}), isNull);
    });

    test('returns list when present', () {
      final list = [
        {'ratingKey': '1'},
        {'ratingKey': '2'},
      ];
      final result = PlexCacheParser.extractMetadataList({
        'MediaContainer': {'Metadata': list},
      });
      expect(result, equals(list));
    });

    test('throws TypeError when Metadata is present but not a list (current contract)', () {
      expect(
        () => PlexCacheParser.extractMetadataList({
          'MediaContainer': {'Metadata': 'not-a-list'},
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('PlexCacheParser.extractFirstMetadata', () {
    test('returns null for null input', () {
      expect(PlexCacheParser.extractFirstMetadata(null), isNull);
    });

    test('returns null for empty Metadata', () {
      expect(
        PlexCacheParser.extractFirstMetadata({
          'MediaContainer': {'Metadata': []},
        }),
        isNull,
      );
    });

    test('returns first map when present', () {
      final first = <String, dynamic>{'ratingKey': '1'};
      final second = <String, dynamic>{'ratingKey': '2'};
      final result = PlexCacheParser.extractFirstMetadata({
        'MediaContainer': {
          'Metadata': [first, second],
        },
      });
      expect(result, equals(first));
    });
  });

  group('PlexCacheParser.extractChapters', () {
    test('returns null for null input', () {
      expect(PlexCacheParser.extractChapters(null), isNull);
    });

    test('returns null when no metadata', () {
      expect(
        PlexCacheParser.extractChapters({
          'MediaContainer': {'Metadata': []},
        }),
        isNull,
      );
    });

    test('returns null when first metadata has no Chapter key', () {
      expect(
        PlexCacheParser.extractChapters({
          'MediaContainer': {
            'Metadata': [
              <String, dynamic>{'ratingKey': '1'},
            ],
          },
        }),
        isNull,
      );
    });

    test('returns chapter list when present', () {
      final chapters = [
        {'tag': 'Chapter 1'},
        {'tag': 'Chapter 2'},
      ];
      final result = PlexCacheParser.extractChapters({
        'MediaContainer': {
          'Metadata': [
            {'ratingKey': '1', 'Chapter': chapters},
          ],
        },
      });
      expect(result, equals(chapters));
    });
  });
}
