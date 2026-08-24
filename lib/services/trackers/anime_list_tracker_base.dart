import '../../models/trackers/anime_ids.dart';
import '../../models/trackers/anime_list_snapshot.dart';
import '../../models/trackers/tracker_context.dart';
import '../../utils/app_logger.dart';
import 'future_coalescer.dart';
import 'tracker.dart';
import 'tracker_id_resolver.dart';

mixin AnimeListTrackerBase<TClient extends DisposableTrackerClient> on TrackerBase, ClientBackedTracker<TClient>
    implements TrackerRatingSource, SeriesProgressTracker {
  final KeyedFutureCache<int, AnimeListSnapshot?> _listSnapshotLoads = KeyedFutureCache();

  @override
  bool get needsFribb => true;

  String get logLabel;

  int? animeId(AnimeIds? anime);
  Future<AnimeListSnapshot?> loadAnimeListSnapshot(TClient client, int animeId);

  /// Write watched progress to the service.
  ///
  /// [rewatching] means the write must represent an in-progress rewatch
  /// instead of a first watch. [rewatchCount] is the absolute finished-rewatch
  /// count to record and is non-null only when this write completes a rewatch.
  Future<void> saveAnimeProgress(
    TClient client, {
    required int animeId,
    required int progress,
    required bool completed,
    required bool rewatching,
    int? rewatchCount,
  });
  Future<void> deleteAnimeEntry(TClient client, int animeId);
  Future<void> setAnimeRating(TClient client, int animeId, int score);
  Future<int?> loadAnimeRating(TClient client, int animeId);

  void clearAnimeListTrackerCache() {
    _listSnapshotLoads.clear();
  }

  @override
  Object? seriesEntryId(TrackerContext ctx) => animeId(ctx.anime);

  /// A movie entry is a single unit; an episode claims the mapped anime progress
  /// when Fribb defined that scope, else its own episode number.
  @override
  int? seriesProgress(TrackerContext ctx) => ctx.isMovie ? 1 : (ctx.animeProgress ?? ctx.episodeNumber);

  /// [watchedAt] is ignored: a list entry stores a progress counter, not dated
  /// plays, so a replayed write is indistinguishable from a fresh one.
  ///
  /// Rewatch state is preserved rather than stomped back to watching (issue
  /// #2026): an entry the user set to rewatching stays a rewatch until it
  /// completes, and new progress on a completed entry starts a rewatch.
  /// Completing a rewatch records the bumped rewatch count as an absolute
  /// value from the snapshot, so a replayed completion writes the same count
  /// instead of incrementing again.
  @override
  Future<void> markWatched(TrackerContext ctx, {DateTime? watchedAt}) async {
    final activeClient = client;
    final id = animeId(ctx.anime);
    if (activeClient == null || id == null) return;

    final progress = seriesProgress(ctx);
    if (progress == null || progress <= 0) return;

    final snapshot = await _listSnapshot(activeClient, id);
    // The total is only comparable when Fribb mapped this playback into the
    // anime's own episode space; a local episode number says nothing about
    // the mapped entry's total. Movies complete in a single unit.
    final total = ctx.isMovie || ctx.animeProgress == null ? null : snapshot?.episodeCount;
    final watched = total != null && progress > total ? total : progress;
    final completed = ctx.isMovie || (total != null && progress >= total);

    final rewatching = !completed && snapshot != null && (snapshot.rewatching || snapshot.completed);
    final rewatchCount = completed && (snapshot?.rewatching ?? false) ? snapshot!.rewatchCount + 1 : null;

    await saveAnimeProgress(
      activeClient,
      animeId: id,
      progress: watched,
      completed: completed,
      rewatching: rewatching,
      rewatchCount: rewatchCount,
    );
    // The write changed the very fields the snapshot feeds back into the next
    // write (status, rewatching, rewatch count), so keeping it would replay
    // this decision on stale state — e.g. bumping the rewatch count again. A
    // failed write throws above this line and keeps the snapshot for a retry.
    _listSnapshotLoads.remove(id);
  }

  @override
  Future<void> markUnwatched(TrackerContext ctx) async {
    if (ctx.isMovie) {
      await removeFromList(ctx);
    }
  }

  @override
  Future<void> removeFromList(TrackerContext ctx) async {
    final activeClient = client;
    final id = animeId(ctx.anime);
    if (activeClient == null || id == null) return;
    await deleteAnimeEntry(activeClient, id);
    // The entry is gone; the memoized snapshot still describes it. Same
    // keep-on-failure contract as [markWatched]. Ratings skip this: the
    // snapshot carries no rating field, so [setAnimeRating] changes nothing
    // the cache mirrors.
    _listSnapshotLoads.remove(id);
  }

  @override
  Future<void> rate(TrackerRatingContext ctx, int score) async {
    final (activeClient, id) = _ratingTarget(ctx);
    await setAnimeRating(activeClient, id, score.clamp(1, 10).toInt());
  }

  @override
  Future<void> clearRating(TrackerRatingContext ctx) async {
    final (activeClient, id) = _ratingTarget(ctx);
    await setAnimeRating(activeClient, id, 0);
  }

  @override
  Future<int?> getRating(TrackerRatingContext ctx) async {
    final (activeClient, id) = _ratingTarget(ctx);
    return loadAnimeRating(activeClient, id);
  }

  (TClient, int) _ratingTarget(TrackerRatingContext ctx) {
    final activeClient = client;
    final id = animeId(ctx.ids.anime);
    if (activeClient == null || id == null) throw TrackerRatingUnavailableException(logLabel);
    return (activeClient, id);
  }

  Future<AnimeListSnapshot?> _listSnapshot(TClient activeClient, int id) => _listSnapshotLoads
      .run(
        id,
        () => loadAnimeListSnapshot(activeClient, id),
        onError: (e) => appLogger.d('$logLabel: failed to fetch anime list snapshot ($name=$id)', error: e),
      )
      .catchError((Object _) => null);
}
