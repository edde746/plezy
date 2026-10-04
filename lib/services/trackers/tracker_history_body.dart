import '../../models/trackers/tracker_context.dart';
import 'tracker.dart';

/// The history body Simkl (`/sync/history`), Trakt (`/sync/history`) and
/// MDBList (`/sync/watched`) share, along with their `/remove` siblings: movies
/// by ids, episodes nested as show → season → episode.
///
/// [idsFor] returns the ids the service matches an item on, or an empty map when
/// it cannot address the item, which is then left out — as is an episode without
/// a season or number. Episodes of one show fold into a single show entry, and a
/// repeated item (two media-server rows for one episode) is sent once, so a
/// service that counts plays records one. [includeWatchedAt] stamps each item
/// with its [TrackerHistoryEntry.watchedAt]; removals never carry it.
///
/// Null when no entry is addressable, so the caller sends nothing.
Map<String, dynamic>? trackerHistoryBody(
  Iterable<TrackerHistoryEntry> entries, {
  required Map<String, Object?> Function(TrackerContext ctx) idsFor,
  required bool includeWatchedAt,
}) {
  final movies = <String, Map<String, dynamic>>{};
  final shows = <String, _ShowEntry>{};
  for (final (:ctx, :watchedAt) in entries) {
    final ids = idsFor(ctx);
    if (ids.isEmpty) continue;
    final stamp = includeWatchedAt ? watchedAt?.toUtc().toIso8601String() : null;
    final key = _idsKey(ids);
    if (ctx.isMovie) {
      movies.putIfAbsent(key, () => {'ids': ids, 'watched_at': ?stamp});
      continue;
    }
    final season = ctx.season;
    final number = ctx.episodeNumber;
    if (season == null || number == null) continue;
    shows
        .putIfAbsent(key, () => _ShowEntry(ids))
        .seasons
        .putIfAbsent(season, () => {})
        .putIfAbsent(number, () => {'number': number, 'watched_at': ?stamp});
  }
  if (movies.isEmpty && shows.isEmpty) return null;
  return {
    if (movies.isNotEmpty) 'movies': movies.values.toList(),
    if (shows.isNotEmpty)
      'shows': [
        for (final show in shows.values)
          {
            'ids': show.ids,
            'seasons': [
              for (final MapEntry(key: number, value: episodes) in show.seasons.entries)
                {'number': number, 'episodes': episodes.values.toList()},
            ],
          },
      ],
  };
}

/// Order-independent identity of an id block, so two episodes carrying the same
/// ids fold into one show entry however their maps were built.
String _idsKey(Map<String, Object?> ids) =>
    (ids.entries.map((entry) => '${entry.key}=${entry.value}').toList()..sort()).join('&');

class _ShowEntry {
  _ShowEntry(this.ids);

  final Map<String, Object?> ids;

  /// Season number → episode number → episode item, in first-seen order.
  final Map<int, Map<int, Map<String, dynamic>>> seasons = {};
}
