import 'ids.dart';
import 'media_item.dart';
import '../utils/global_key_utils.dart';

/// A collection that holds downloaded titles: its display metadata and the
/// ids of those titles (movies or shows) in the collection's own order.
typedef DownloadedCollection = ({MediaItem collection, List<String> memberIds});

/// [items] — one downloads tab's movies or shows, already filtered and
/// sorted — with every collection holding at least two of them folded into a
/// folder: the collection item, placed where its first member sat.
///
/// A collection with a single matching title leaves that title on its own. A
/// title in several folding collections appears in each folder and not by
/// itself. Folders sharing a position follow in title order.
///
/// Each folder carries what its card shows: [MediaItem.childCount] is the
/// number of titles it holds, and [MediaItem.leafCount] /
/// [MediaItem.viewedLeafCount] add up its members' watch state — one leaf per
/// movie, a show's downloaded episodes otherwise.
List<MediaItem> groupByDownloadedCollection(List<MediaItem> items, Iterable<DownloadedCollection> collections) {
  final indexByKey = <String, int>{for (final (index, item) in items.indexed) item.globalKey: index};
  final foldersAt = <int, List<MediaItem>>{};
  final folded = <int>{};

  for (final (:collection, :memberIds) in collections) {
    final serverId = collection.serverId;
    if (serverId == null) continue;
    final memberIndexes = <int>{for (final id in memberIds) ?indexByKey[buildGlobalKey(ServerId(serverId), id)]};
    if (memberIndexes.length < 2) continue;

    var leaves = 0;
    var viewedLeaves = 0;
    for (final index in memberIndexes) {
      final member = items[index];
      final total = member.leafWatchTotal;
      if (total == null) {
        leaves++;
        if (member.isWatched) viewedLeaves++;
      } else {
        leaves += total;
        viewedLeaves += (member.viewedLeafCount ?? 0).clamp(0, total);
      }
    }
    final firstIndex = memberIndexes.reduce((a, b) => a < b ? a : b);
    foldersAt
        .putIfAbsent(firstIndex, () => [])
        .add(collection.copyWith(childCount: memberIndexes.length, leafCount: leaves, viewedLeafCount: viewedLeaves));
    folded.addAll(memberIndexes);
  }

  if (foldersAt.isEmpty) return items;
  String titleKey(MediaItem item) => (item.titleSort ?? item.title ?? '').toLowerCase();
  return [
    for (final (index, item) in items.indexed) ...[
      ...?foldersAt[index]?..sort((a, b) => titleKey(a).compareTo(titleKey(b))),
      if (!folded.contains(index)) item,
    ],
  ];
}
