import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/downloads_filter.dart';
import 'package:plezy/media/media_kind.dart';
import '../test_helpers/media_items.dart';

/// The downloads screen's local filter predicate (#927). The contract under
/// test: 'unwatched' keeps only items with unwatched content, 'library'
/// matches a `serverId:libraryId` value (with a null-libraryId escape), and
/// unknown keys are ignored for forward compatibility.
void main() {
  group('downloadItemMatchesFilters unwatched', () {
    test('leaf items pass only when not watched', () {
      final unwatched = testMediaItem(id: 'u', kind: MediaKind.movie, viewCount: 0);
      final watched = testMediaItem(id: 'w', kind: MediaKind.movie, viewCount: 1);
      const selected = {downloadFilterUnwatched: '1'};

      expect(downloadItemMatchesFilters(unwatched, selected), isTrue);
      expect(downloadItemMatchesFilters(watched, selected), isFalse);
    });

    test('containers answer from unwatchedCount when leaf counts are set', () {
      final partlyWatched = testMediaItem(id: 'p', kind: MediaKind.show, leafCount: 10, viewedLeafCount: 4);
      final fullyWatched = testMediaItem(id: 'f', kind: MediaKind.show, leafCount: 10, viewedLeafCount: 10);
      const selected = {downloadFilterUnwatched: '1'};

      expect(partlyWatched.unwatchedCount, 6);
      expect(downloadItemMatchesFilters(partlyWatched, selected), isTrue);
      expect(downloadItemMatchesFilters(fullyWatched, selected), isFalse);
    });
  });

  group('downloadItemMatchesFilters library', () {
    test('matches the serverId:libraryId pair', () {
      final item = testMediaItem(id: 'i', kind: MediaKind.movie, serverId: 's1', libraryId: '7');
      expect(downloadItemMatchesFilters(item, {downloadFilterLibrary: 's1:7'}), isTrue);
      expect(downloadItemMatchesFilters(item, {downloadFilterLibrary: 's1:8'}), isFalse);
      expect(downloadItemMatchesFilters(item, {downloadFilterLibrary: 's2:7'}), isFalse);
    });

    test('empty library suffix matches items with a null libraryId', () {
      final noLibrary = testMediaItem(id: 'i', kind: MediaKind.movie, serverId: 's1');
      final withLibrary = testMediaItem(id: 'j', kind: MediaKind.movie, serverId: 's1', libraryId: '7');

      expect(downloadItemMatchesFilters(noLibrary, {downloadFilterLibrary: 's1:'}), isTrue);
      expect(downloadItemMatchesFilters(withLibrary, {downloadFilterLibrary: 's1:'}), isFalse);
      // …and a null-libraryId item never matches a specific library value.
      expect(downloadItemMatchesFilters(noLibrary, {downloadFilterLibrary: 's1:7'}), isFalse);
    });

    test('downloadLibraryFilterValue builds the expected value shape', () {
      expect(downloadLibraryFilterValue('s1', '7'), 's1:7');
      expect(downloadLibraryFilterValue('s1', null), 's1:');
    });
  });

  group('downloadItemMatchesFilters composition', () {
    test('unknown keys are ignored', () {
      final item = testMediaItem(id: 'i', kind: MediaKind.movie, viewCount: 1);
      expect(downloadItemMatchesFilters(item, {'genre': 'action', 'year': '2020'}), isTrue);
    });

    test('all selected filters must pass', () {
      final item = testMediaItem(id: 'i', kind: MediaKind.movie, serverId: 's1', libraryId: '7', viewCount: 0);
      expect(downloadItemMatchesFilters(item, {downloadFilterUnwatched: '1', downloadFilterLibrary: 's1:7'}), isTrue);
      expect(downloadItemMatchesFilters(item, {downloadFilterUnwatched: '1', downloadFilterLibrary: 's1:8'}), isFalse);
    });

    test('empty selection matches everything', () {
      final item = testMediaItem(id: 'i', kind: MediaKind.movie, viewCount: 1);
      expect(downloadItemMatchesFilters(item, const {}), isTrue);
    });
  });
}
