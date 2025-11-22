import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/content_rating_formatter.dart';

void main() {
  group('formatContentRating', () {
    test('returns empty string for null input', () {
      expect(formatContentRating(null), '');
    });

    test('returns empty string for empty input', () {
      expect(formatContentRating(''), '');
    });

    test('removes country prefix from US rating', () {
      expect(formatContentRating('us/PG-13'), 'PG-13');
    });

    test('removes country prefix from UK rating', () {
      expect(formatContentRating('gb/12A'), '12A');
    });

    test('removes country prefix from German rating', () {
      expect(formatContentRating('de/FSK 16'), 'FSK 16');
    });

    test('removes country prefix from French rating', () {
      expect(formatContentRating('fr/Tous publics'), 'Tous publics');
    });

    test('handles 3-letter country code', () {
      expect(formatContentRating('aus/M'), 'M');
    });

    test('returns original rating when no country prefix present', () {
      expect(formatContentRating('PG-13'), 'PG-13');
    });

    test('returns original rating for invalid format', () {
      expect(formatContentRating('rating-without-prefix'), 'rating-without-prefix');
    });

    test('handles case insensitive country codes', () {
      expect(formatContentRating('US/R'), 'R');
      expect(formatContentRating('Us/R'), 'R');
      expect(formatContentRating('uS/R'), 'R');
    });

    test('does not remove prefix without slash', () {
      expect(formatContentRating('usR'), 'usR');
    });

    test('handles ratings with special characters', () {
      expect(formatContentRating('de/FSK-18'), 'FSK-18');
    });

    test('handles ratings with numbers', () {
      expect(formatContentRating('gb/18'), '18');
    });

    test('preserves whitespace in rating', () {
      expect(formatContentRating('us/TV-14 D L S V'), 'TV-14 D L S V');
    });

    test('handles slash in rating value itself', () {
      // This tests that only the first prefix is removed
      expect(formatContentRating('us/TV-MA/R'), 'TV-MA/R');
    });
  });
}
