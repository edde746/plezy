import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/rating_utils.dart';

void main() {
  group('parseRatingImage - null/missing', () {
    test('returns null when imageUri is null', () {
      expect(parseRatingImage(null, 7.5), isNull);
    });

    test('returns null when value is null', () {
      expect(parseRatingImage('imdb://title/tt123', null), isNull);
    });

    test('returns null for unknown scheme', () {
      expect(parseRatingImage('unknown://foo', 5.0), isNull);
    });
  });

  group('parseRatingImage - Rotten Tomatoes', () {
    test('ripe maps to rt_fresh with percent', () {
      final info = parseRatingImage('rottentomatoes://image.rating.ripe', 7.5);
      expect(info, isNotNull);
      expect(info!.assetPath, 'assets/rating_icons/rt_fresh.svg');
      expect(info.formattedValue, '75%');
    });

    test('rotten maps to rt_rotten', () {
      final info = parseRatingImage('rottentomatoes://image.rating.rotten', 3.2);
      expect(info, isNotNull);
      expect(info!.assetPath, 'assets/rating_icons/rt_rotten.svg');
      expect(info.formattedValue, '32%');
    });

    test('upright maps to rt_upright', () {
      final info = parseRatingImage('rottentomatoes://image.rating.upright', 8.8);
      expect(info!.assetPath, 'assets/rating_icons/rt_upright.svg');
      expect(info.formattedValue, '88%');
    });

    test('spilled maps to rt_spilled', () {
      final info = parseRatingImage('rottentomatoes://image.rating.spilled', 2.0);
      expect(info!.assetPath, 'assets/rating_icons/rt_spilled.svg');
      expect(info.formattedValue, '20%');
    });

    test('unknown RT suffix returns null', () {
      expect(parseRatingImage('rottentomatoes://image.rating.green', 5.0), isNull);
    });

    test('percent rounds to whole number', () {
      final info = parseRatingImage('rottentomatoes://image.rating.ripe', 7.57);
      expect(info!.formattedValue, '76%');
    });
  });

  group('parseRatingImage - IMDb', () {
    test('formats with one decimal', () {
      final info = parseRatingImage('imdb://title/tt123', 7.5);
      expect(info!.assetPath, 'assets/rating_icons/imdb.svg');
      expect(info.formattedValue, '7.5');
    });

    test('formats to one decimal (truncation follows toStringAsFixed semantics)', () {
      final info = parseRatingImage('imdb://title', 7.25);
      expect(info!.formattedValue, anyOf('7.2', '7.3'));
    });
  });

  group('parseRatingImage - TMDB', () {
    test('converts value*10 to percent', () {
      final info = parseRatingImage('themoviedb://foo', 6.8);
      expect(info!.assetPath, 'assets/rating_icons/tmdb.svg');
      expect(info.formattedValue, '68%');
    });
  });

  group('isRottenTomatoes', () {
    test('matches rottentomatoes:// scheme', () {
      expect(isRottenTomatoes('rottentomatoes://image.rating.ripe'), isTrue);
      expect(isRottenTomatoes('rottentomatoes://anything'), isTrue);
    });

    test('false for null', () {
      expect(isRottenTomatoes(null), isFalse);
    });

    test('false for other schemes', () {
      expect(isRottenTomatoes('imdb://title'), isFalse);
      expect(isRottenTomatoes('themoviedb://foo'), isFalse);
      expect(isRottenTomatoes(''), isFalse);
    });
  });
}
