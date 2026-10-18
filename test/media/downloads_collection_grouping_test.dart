import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/downloads_collection_grouping.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';

import '../test_helpers/media_items.dart';

MediaItem _movie(String id, {bool watched = false, String serverId = 's1'}) =>
    testMediaItem(id: id, title: id, serverId: serverId, viewCount: watched ? 1 : 0);

MediaItem _show(String id, {required int episodes, required int watched}) => testMediaItem(
  id: id,
  kind: MediaKind.show,
  title: id,
  serverId: 's1',
  leafCount: episodes,
  viewedLeafCount: watched,
);

DownloadedCollection _collection(String id, List<String> memberIds, {String? title, String serverId = 's1'}) => (
  collection: testMediaItem(id: id, kind: MediaKind.collection, title: title ?? id, serverId: serverId),
  memberIds: memberIds,
);

List<String> _ids(List<MediaItem> items) => [for (final item in items) item.id];

void main() {
  test('folds two or more members into a folder at the first member\'s place', () {
    final items = [_movie('a'), _movie('dune-2'), _movie('b'), _movie('dune-1'), _movie('solo')];

    final grouped = groupByDownloadedCollection(items, [
      _collection('dune', ['dune-1', 'dune-2', 'not-downloaded']),
      _collection('lonely', ['solo', 'gone']),
    ]);

    expect(_ids(grouped), ['a', 'dune', 'b', 'solo']);
    expect(grouped[1].childCount, 2);
  });

  test('a title in two folding collections shows in neither place alone', () {
    final items = [_movie('x'), _movie('y'), _movie('z')];

    final grouped = groupByDownloadedCollection(items, [
      _collection('saga', ['y', 'z'], title: 'Saga'),
      _collection('box', ['x', 'y'], title: 'Box'),
    ]);

    expect(_ids(grouped), ['box', 'saga']);
  });

  test('members on another server never match', () {
    final items = [_movie('a'), _movie('b')];

    final grouped = groupByDownloadedCollection(items, [
      _collection('c', ['a', 'b'], serverId: 's2'),
    ]);

    expect(_ids(grouped), ['a', 'b']);
  });

  test('folders add up their members\' watch state, a show counting its episodes', () {
    final items = [_movie('m1', watched: true), _movie('m2'), _show('s', episodes: 4, watched: 4)];

    final folder = groupByDownloadedCollection(items, [
      _collection('c', ['m1', 'm2', 's']),
    ]).single;

    expect(folder.childCount, 3);
    expect(folder.unwatchedCount, 1);
    expect(folder.isWatched, isFalse);
    expect(folder.isPartiallyWatched, isTrue);
  });
}
