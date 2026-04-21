import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex_metadata.dart';
import 'package:plezy/utils/content_utils.dart';

PlexMetadata _episode({int? viewOffset, int? duration, int? viewCount, int? leafCount, int? viewedLeafCount}) {
  return PlexMetadata(
    ratingKey: '1',
    type: 'episode',
    viewOffset: viewOffset,
    duration: duration,
    viewCount: viewCount,
    leafCount: leafCount,
    viewedLeafCount: viewedLeafCount,
  );
}

PlexMetadata _movie({int? viewCount}) {
  return PlexMetadata(ratingKey: '1', type: 'movie', viewCount: viewCount);
}

void main() {
  group('formatContentRating', () {
    test('strips 2-letter country prefixes', () {
      expect(formatContentRating('us/PG-13'), 'PG-13');
      expect(formatContentRating('gb/15'), '15');
    });

    test('strips 3-letter country prefixes', () {
      expect(formatContentRating('deu/16'), '16');
    });

    test('case-insensitive matching', () {
      expect(formatContentRating('US/PG-13'), 'PG-13');
      expect(formatContentRating('Us/PG'), 'PG');
    });

    test('returns original when no prefix present', () {
      expect(formatContentRating('PG-13'), 'PG-13');
      expect(formatContentRating('TV-MA'), 'TV-MA');
    });

    test('returns empty string for null or empty', () {
      expect(formatContentRating(null), '');
      expect(formatContentRating(''), '');
    });

    test('does not strip single-letter or digit prefixes', () {
      expect(formatContentRating('1/foo'), '1/foo');
      expect(formatContentRating('a/foo'), 'a/foo');
    });
  });

  group('PlexMetadataType.shouldHideSpoiler', () {
    test('false for non-episodes', () {
      expect(_movie().shouldHideSpoiler, isFalse);
      final show = PlexMetadata(ratingKey: '1', type: 'show');
      expect(show.shouldHideSpoiler, isFalse);
    });

    test('false when episode has been watched (viewCount > 0)', () {
      expect(_episode(viewCount: 1).shouldHideSpoiler, isFalse);
    });

    test('false when >= 50% watched', () {
      expect(_episode(viewOffset: 5000, duration: 10000).shouldHideSpoiler, isFalse);
      expect(_episode(viewOffset: 8000, duration: 10000).shouldHideSpoiler, isFalse);
    });

    test('true when < 50% watched', () {
      expect(_episode(viewOffset: 1000, duration: 10000).shouldHideSpoiler, isTrue);
      expect(_episode(viewOffset: 4999, duration: 10000).shouldHideSpoiler, isTrue);
    });

    test('true when no progress at all (unwatched)', () {
      expect(_episode().shouldHideSpoiler, isTrue);
      expect(_episode(viewOffset: 0).shouldHideSpoiler, isTrue);
    });

    test('true when duration is missing', () {
      expect(_episode(viewOffset: 500).shouldHideSpoiler, isTrue);
    });
  });

  group('ContentTypeHelper', () {
    test('isMusicContent / isVideoContent are case-insensitive', () {
      expect(ContentTypeHelper.isMusicContent('ARTIST'), isTrue);
      expect(ContentTypeHelper.isMusicContent('track'), isTrue);
      expect(ContentTypeHelper.isMusicContent('movie'), isFalse);

      expect(ContentTypeHelper.isVideoContent('MOVIE'), isTrue);
      expect(ContentTypeHelper.isVideoContent('episode'), isTrue);
      expect(ContentTypeHelper.isVideoContent('artist'), isFalse);
    });

    test('isMusicLibrary returns false for null and non-matching types', () {
      expect(ContentTypeHelper.isMusicLibrary(null), isFalse);
    });
  });
}
