import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_item_sort.dart';
import 'package:plezy/media/media_kind.dart';
import '../test_helpers/media_items.dart';

/// Local [MediaItem] ordering used by the downloads screen (#927). The
/// contract under test: each key's ordering, missing values pinned to the
/// tail in both directions, and a deterministic title/id tiebreak (Dart's
/// List.sort is not stable).
MediaItem _item({
  String id = 'item-1',
  String? title,
  String? titleSort,
  int? addedAt,
  String? originallyAvailableAt,
  double? rating,
  String? libraryId,
  String? libraryTitle,
  String? serverId,
  String? serverName,
}) => testMediaItem(
  id: id,
  kind: MediaKind.movie,
  title: title,
  titleSort: titleSort,
  addedAt: addedAt,
  originallyAvailableAt: originallyAvailableAt,
  rating: rating,
  libraryId: libraryId,
  libraryTitle: libraryTitle,
  serverId: serverId,
  serverName: serverName,
);

List<String> _sortedIds(
  List<MediaItem> items,
  String key, {
  bool descending = false,
  MediaItemSortExtras Function(MediaItem item)? extras,
}) {
  final sorted = [...items]..sort(mediaItemSortComparator(key, descending: descending, extras: extras));
  return sorted.map((i) => i.id).toList();
}

void main() {
  group('mediaItemSortComparator title', () {
    test('orders case-insensitively by titleSort, falling back to title', () {
      final items = [
        _item(id: 'a', title: 'Banana'),
        _item(id: 'b', title: 'Ignored', titleSort: 'apple'),
        _item(id: 'c', title: 'cherry'),
      ];
      expect(_sortedIds(items, mediaSortKeyTitle), ['b', 'a', 'c']);
    });

    test('descending reverses the order', () {
      final items = [_item(id: 'a', title: 'Alpha'), _item(id: 'b', title: 'Beta')];
      expect(_sortedIds(items, mediaSortKeyTitle, descending: true), ['b', 'a']);
    });
  });

  group('mediaItemSortComparator dateAdded', () {
    test('orders by addedAt, newest last ascending', () {
      final items = [_item(id: 'new', addedAt: 300), _item(id: 'old', addedAt: 100), _item(id: 'mid', addedAt: 200)];
      expect(_sortedIds(items, mediaSortKeyDateAdded), ['old', 'mid', 'new']);
      expect(_sortedIds(items, mediaSortKeyDateAdded, descending: true), ['new', 'mid', 'old']);
    });

    test('missing addedAt sorts last in both directions', () {
      final items = [_item(id: 'none', title: 'Zed'), _item(id: 'dated', addedAt: 100)];
      expect(_sortedIds(items, mediaSortKeyDateAdded), ['dated', 'none']);
      expect(_sortedIds(items, mediaSortKeyDateAdded, descending: true), ['dated', 'none']);
    });
  });

  group('mediaItemSortComparator releaseDate', () {
    test('orders by originallyAvailableAt string, nulls last both ways', () {
      final items = [
        _item(id: 'undated', title: 'Zed'),
        _item(id: 'newer', originallyAvailableAt: '2024-01-01'),
        _item(id: 'older', originallyAvailableAt: '1999-05-20'),
      ];
      expect(_sortedIds(items, mediaSortKeyReleaseDate), ['older', 'newer', 'undated']);
      expect(_sortedIds(items, mediaSortKeyReleaseDate, descending: true), ['newer', 'older', 'undated']);
    });
  });

  group('mediaItemSortComparator rating', () {
    test('orders by rating, nulls last both ways', () {
      final items = [_item(id: 'unrated', title: 'Zed'), _item(id: 'high', rating: 9.1), _item(id: 'low', rating: 4.2)];
      expect(_sortedIds(items, mediaSortKeyRating), ['low', 'high', 'unrated']);
      expect(_sortedIds(items, mediaSortKeyRating, descending: true), ['high', 'low', 'unrated']);
    });
  });

  group('mediaItemSortComparator downloadedAt', () {
    test('orders by extras downloadedAt, missing extras last both ways', () {
      final items = [_item(id: 'a', title: 'Zed'), _item(id: 'b'), _item(id: 'c')];
      MediaItemSortExtras extras(MediaItem item) => switch (item.id) {
        'b' => (downloadedAt: 200, totalBytes: null),
        'c' => (downloadedAt: 100, totalBytes: null),
        _ => (downloadedAt: null, totalBytes: null),
      };

      expect(_sortedIds(items, mediaSortKeyDownloadedAt, extras: extras), ['c', 'b', 'a']);
      expect(_sortedIds(items, mediaSortKeyDownloadedAt, extras: extras, descending: true), ['b', 'c', 'a']);
    });

    test('without an extras lookup every item is missing and falls back to title order', () {
      final items = [_item(id: 'b', title: 'Beta'), _item(id: 'a', title: 'Alpha')];
      expect(_sortedIds(items, mediaSortKeyDownloadedAt), ['a', 'b']);
    });
  });

  group('mediaItemSortComparator size', () {
    test('orders by extras totalBytes; zero and null count as missing', () {
      final items = [
        _item(id: 'zero', title: 'Aaa'),
        _item(id: 'none', title: 'Zzz'),
        _item(id: 'big'),
        _item(id: 'small'),
      ];
      MediaItemSortExtras extras(MediaItem item) => switch (item.id) {
        'big' => (downloadedAt: null, totalBytes: 9000),
        'small' => (downloadedAt: null, totalBytes: 100),
        'zero' => (downloadedAt: null, totalBytes: 0),
        _ => (downloadedAt: null, totalBytes: null),
      };

      // Missing entries stay at the tail; their internal title tiebreak
      // flips with the direction like every other comparison.
      expect(_sortedIds(items, mediaSortKeySize, extras: extras), ['small', 'big', 'zero', 'none']);
      expect(_sortedIds(items, mediaSortKeySize, extras: extras, descending: true), ['big', 'small', 'none', 'zero']);
    });
  });

  group('mediaItemSortComparator library', () {
    test('orders by libraryTitle, then serverName when no library title', () {
      final items = [
        _item(id: 'c', title: 'Zed', serverName: 'Server B'),
        _item(id: 'a', libraryTitle: 'Movies', serverName: 'Server A'),
        _item(id: 'b', libraryTitle: 'Shows', serverName: 'Server A'),
      ];
      // 'server b' < 'shows' — the serverName fallback participates in the
      // same ordering as real library titles.
      expect(_sortedIds(items, mediaSortKeyLibrary), ['a', 'c', 'b']);
    });

    test('items in the same library fall back to title', () {
      final items = [
        _item(id: 'b', title: 'Beta', libraryTitle: 'Movies'),
        _item(id: 'a', title: 'Alpha', libraryTitle: 'Movies'),
      ];
      expect(_sortedIds(items, mediaSortKeyLibrary), ['a', 'b']);
    });
  });

  group('mediaItemSortComparator ties', () {
    test('equal primary values order by title then id', () {
      final items = [
        _item(id: 'z', title: 'Same', addedAt: 100),
        _item(id: 'y', title: 'Alpha', addedAt: 100),
        _item(id: 'x', title: 'Alpha', addedAt: 100),
      ];
      // 'x' and 'y' share title 'Alpha' → id decides between them.
      expect(_sortedIds(items, mediaSortKeyDateAdded), ['x', 'y', 'z']);
    });

    test('unknown key falls back to title/id order', () {
      final items = [_item(id: 'b', title: 'Beta'), _item(id: 'a', title: 'Alpha')];
      expect(_sortedIds(items, 'notAKey'), ['a', 'b']);
    });
  });
}
