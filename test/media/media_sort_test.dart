import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_sort.dart';

void main() {
  group('MediaSort.getSortKey', () {
    test('returns plain key for ascending', () {
      final s = MediaSort(key: 'titleSort', title: 'Title');
      expect(s.getSortKey(), 'titleSort');
      expect(s.getSortKey(descending: false), 'titleSort');
    });

    test('appends :desc when no descKey is provided', () {
      final s = MediaSort(key: 'addedAt', title: 'Recently Added');
      expect(s.getSortKey(descending: true), 'addedAt:desc');
    });

    test('uses explicit descKey when provided', () {
      final s = MediaSort(key: 'titleSort', descKey: 'titleSort:desc', title: 'Title');
      expect(s.getSortKey(descending: true), 'titleSort:desc');

      final custom = MediaSort(key: 'rating', descKey: 'rating.desc.custom', title: 'Rating');
      expect(custom.getSortKey(descending: true), 'rating.desc.custom');
    });
  });

  group('MediaSort.isDefaultDescending', () {
    test('true for "desc" (case-insensitive)', () {
      expect(MediaSort(key: 'k', title: 't', defaultDirection: 'desc').isDefaultDescending, isTrue);
      expect(MediaSort(key: 'k', title: 't', defaultDirection: 'DESC').isDefaultDescending, isTrue);
      expect(MediaSort(key: 'k', title: 't', defaultDirection: 'Desc').isDefaultDescending, isTrue);
    });

    test('false for "asc", null, or other values', () {
      expect(MediaSort(key: 'k', title: 't', defaultDirection: 'asc').isDefaultDescending, isFalse);
      expect(MediaSort(key: 'k', title: 't').isDefaultDescending, isFalse);
      expect(MediaSort(key: 'k', title: 't', defaultDirection: '').isDefaultDescending, isFalse);
    });
  });

  group('MediaSort.fromJson', () {
    test('parses all fields', () {
      final s = MediaSort.fromJson({
        'key': 'titleSort',
        'descKey': 'titleSort:desc',
        'title': 'Title',
        'defaultDirection': 'asc',
      });
      expect(s.key, 'titleSort');
      expect(s.descKey, 'titleSort:desc');
      expect(s.title, 'Title');
      expect(s.defaultDirection, 'asc');
    });

    test('tolerates missing optional fields', () {
      final s = MediaSort.fromJson({'key': 'k', 'title': 't'});
      expect(s.descKey, isNull);
      expect(s.defaultDirection, isNull);
    });
  });

  group('MediaSort equality & hashCode', () {
    test('equality is based on key only (matches current contract)', () {
      final a = MediaSort(key: 'k', descKey: 'k:desc', title: 'A', defaultDirection: 'asc');
      final b = MediaSort(key: 'k', descKey: 'other', title: 'B', defaultDirection: 'desc');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different keys are not equal', () {
      final a = MediaSort(key: 'k1', title: 'A');
      final b = MediaSort(key: 'k2', title: 'A');
      expect(a, isNot(equals(b)));
    });

    test('identity short-circuit', () {
      final a = MediaSort(key: 'k', title: 't');
      expect(a == a, isTrue);
    });
  });
}
