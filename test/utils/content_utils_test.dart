import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_item_types.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/utils/content_utils.dart';

MediaItem _episode({int? viewOffsetMs, int? durationMs, int? viewCount, int? leafCount, int? viewedLeafCount}) {
  return MediaItem(
    id: '1',
    backend: MediaBackend.plex,
    kind: MediaKind.episode,
    viewOffsetMs: viewOffsetMs,
    durationMs: durationMs,
    viewCount: viewCount,
    leafCount: leafCount,
    viewedLeafCount: viewedLeafCount,
  );
}

MediaItem _movie({int? viewCount}) {
  return MediaItem(id: '1', backend: MediaBackend.plex, kind: MediaKind.movie, viewCount: viewCount);
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

  group('MediaItemTypes.shouldHideSpoiler', () {
    test('false for non-episodes', () {
      expect(_movie().shouldHideSpoiler, isFalse);
      final show = MediaItem(id: '1', backend: MediaBackend.plex, kind: MediaKind.show);
      expect(show.shouldHideSpoiler, isFalse);
    });

    test('false when episode has been watched (viewCount > 0)', () {
      expect(_episode(viewCount: 1).shouldHideSpoiler, isFalse);
    });

    test('false when >= 50% watched', () {
      expect(_episode(viewOffsetMs: 5000, durationMs: 10000).shouldHideSpoiler, isFalse);
      expect(_episode(viewOffsetMs: 8000, durationMs: 10000).shouldHideSpoiler, isFalse);
    });

    test('true when < 50% watched', () {
      expect(_episode(viewOffsetMs: 1000, durationMs: 10000).shouldHideSpoiler, isTrue);
      expect(_episode(viewOffsetMs: 4999, durationMs: 10000).shouldHideSpoiler, isTrue);
    });

    test('true when no progress at all (unwatched)', () {
      expect(_episode().shouldHideSpoiler, isTrue);
      expect(_episode(viewOffsetMs: 0).shouldHideSpoiler, isTrue);
    });

    test('true when duration is missing', () {
      expect(_episode(viewOffsetMs: 500).shouldHideSpoiler, isTrue);
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
