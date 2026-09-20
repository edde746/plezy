import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/downloads_filter.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_kind.dart';
import '../test_helpers/media_items.dart';

/// The downloads screen's local filter predicate (#927). The contract under
/// test: 'unwatched' keeps only items with unwatched content, 'library'
/// matches any of its `serverId:libraryId` values (with a null-libraryId
/// escape), a negated clause inverts its field, and unknown fields are
/// ignored for forward compatibility.
void main() {
  group('downloadItemMatchesFilters unwatched', () {
    test('leaf items pass only when not watched', () {
      final unwatched = testMediaItem(id: 'u', kind: MediaKind.movie, viewCount: 0);
      final watched = testMediaItem(id: 'w', kind: MediaKind.movie, viewCount: 1);
      const selected = [
        LibraryFilter(field: downloadFilterUnwatched, values: ['1']),
      ];

      expect(downloadItemMatchesFilters(unwatched, selected), isTrue);
      expect(downloadItemMatchesFilters(watched, selected), isFalse);
    });

    test('containers answer from unwatchedCount when leaf counts are set', () {
      final partlyWatched = testMediaItem(id: 'p', kind: MediaKind.show, leafCount: 10, viewedLeafCount: 4);
      final fullyWatched = testMediaItem(id: 'f', kind: MediaKind.show, leafCount: 10, viewedLeafCount: 10);
      const selected = [
        LibraryFilter(field: downloadFilterUnwatched, values: ['1']),
      ];

      expect(partlyWatched.unwatchedCount, 6);
      expect(downloadItemMatchesFilters(partlyWatched, selected), isTrue);
      expect(downloadItemMatchesFilters(fullyWatched, selected), isFalse);
    });
  });

  group('downloadItemMatchesFilters library', () {
    test('matches the serverId:libraryId pair', () {
      final item = testMediaItem(id: 'i', kind: MediaKind.movie, serverId: 's1', libraryId: '7');
      expect(
        downloadItemMatchesFilters(item, const [
          LibraryFilter(field: downloadFilterLibrary, values: ['s1:7']),
        ]),
        isTrue,
      );
      expect(
        downloadItemMatchesFilters(item, const [
          LibraryFilter(field: downloadFilterLibrary, values: ['s1:8']),
        ]),
        isFalse,
      );
      expect(
        downloadItemMatchesFilters(item, const [
          LibraryFilter(field: downloadFilterLibrary, values: ['s2:7']),
        ]),
        isFalse,
      );
    });

    test('empty library suffix matches items with a null libraryId', () {
      final noLibrary = testMediaItem(id: 'i', kind: MediaKind.movie, serverId: 's1');
      final withLibrary = testMediaItem(id: 'j', kind: MediaKind.movie, serverId: 's1', libraryId: '7');

      expect(
        downloadItemMatchesFilters(noLibrary, const [
          LibraryFilter(field: downloadFilterLibrary, values: ['s1:']),
        ]),
        isTrue,
      );
      expect(
        downloadItemMatchesFilters(withLibrary, const [
          LibraryFilter(field: downloadFilterLibrary, values: ['s1:']),
        ]),
        isFalse,
      );
      // …and a null-libraryId item never matches a specific library value.
      expect(
        downloadItemMatchesFilters(noLibrary, const [
          LibraryFilter(field: downloadFilterLibrary, values: ['s1:7']),
        ]),
        isFalse,
      );
    });

    test('downloadLibraryFilterValue builds the expected value shape', () {
      expect(downloadLibraryFilterValue('s1', '7'), 's1:7');
      expect(downloadLibraryFilterValue('s1', null), 's1:');
    });
  });

  group('downloadItemMatchesFilters composition', () {
    test('unknown fields are ignored', () {
      final item = testMediaItem(id: 'i', kind: MediaKind.movie, viewCount: 1);
      expect(
        downloadItemMatchesFilters(item, const [
          LibraryFilter(field: 'genre', values: ['action']),
          LibraryFilter(field: 'year', values: ['2020']),
        ]),
        isTrue,
      );
    });

    test('all selected filters must pass', () {
      final item = testMediaItem(id: 'i', kind: MediaKind.movie, serverId: 's1', libraryId: '7', viewCount: 0);
      expect(
        downloadItemMatchesFilters(item, const [
          LibraryFilter(field: downloadFilterUnwatched, values: ['1']),
          LibraryFilter(field: downloadFilterLibrary, values: ['s1:7']),
        ]),
        isTrue,
      );
      expect(
        downloadItemMatchesFilters(item, const [
          LibraryFilter(field: downloadFilterUnwatched, values: ['1']),
          LibraryFilter(field: downloadFilterLibrary, values: ['s1:8']),
        ]),
        isFalse,
      );
    });

    test('values inside one clause OR', () {
      final item = testMediaItem(id: 'i', kind: MediaKind.movie, serverId: 's1', libraryId: '7');
      const clause = [
        LibraryFilter(field: downloadFilterLibrary, values: ['s1:8', 's1:7']),
      ];
      expect(downloadItemMatchesFilters(item, clause), isTrue);
      const other = [
        LibraryFilter(field: downloadFilterLibrary, values: ['s1:8', 's1:9']),
      ];
      expect(downloadItemMatchesFilters(item, other), isFalse);
    });

    test('a negated clause inverts its field', () {
      final watched = testMediaItem(id: 'w', kind: MediaKind.movie, viewCount: 1);
      final unwatched = testMediaItem(id: 'u', kind: MediaKind.movie, viewCount: 0);
      const watchedOnly = [
        LibraryFilter(field: downloadFilterUnwatched, op: LibraryFilterOperator.isNot, values: ['1']),
      ];
      expect(downloadItemMatchesFilters(watched, watchedOnly), isTrue);
      expect(downloadItemMatchesFilters(unwatched, watchedOnly), isFalse);
    });

    test('a negated library clause excludes every listed library', () {
      final item = testMediaItem(id: 'i', kind: MediaKind.movie, serverId: 's1', libraryId: '7');
      const excluded = [
        LibraryFilter(field: downloadFilterLibrary, op: LibraryFilterOperator.isNot, values: ['s1:7']),
      ];
      expect(downloadItemMatchesFilters(item, excluded), isFalse);
      const excludedOther = [
        LibraryFilter(field: downloadFilterLibrary, op: LibraryFilterOperator.isNot, values: ['s1:8']),
      ];
      expect(downloadItemMatchesFilters(item, excludedOther), isTrue);
    });

    test('empty selection matches everything', () {
      final item = testMediaItem(id: 'i', kind: MediaKind.movie, viewCount: 1);
      expect(downloadItemMatchesFilters(item, const []), isTrue);
    });
  });
}
