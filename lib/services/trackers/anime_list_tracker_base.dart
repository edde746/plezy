import '../../models/trackers/anime_ids.dart';
import '../../models/trackers/tracker_context.dart';
import '../../utils/app_logger.dart';
import 'tracker.dart';
import 'tracker_id_resolver.dart';

mixin AnimeListTrackerBase<TClient extends DisposableTrackerClient> on TrackerBase, ClientBackedTracker<TClient>
    implements TrackerRatingSource {
  final Map<int, Future<int?>> _episodeCountLoads = {};

  @override
  bool get needsFribb => true;

  String get logLabel;
  String get idLogName;
  String get ratingUnavailableName;

  int? animeId(AnimeIds? anime);
  Future<int?> loadAnimeEpisodeCount(TClient client, int animeId);
  Future<void> saveAnimeProgress(
    TClient client, {
    required int animeId,
    required int progress,
    required bool completed,
  });
  Future<void> deleteAnimeEntry(TClient client, int animeId);
  Future<void> setAnimeRating(TClient client, int animeId, int score);
  Future<int?> loadAnimeRating(TClient client, int animeId);

  void clearAnimeListTrackerCache() {
    _episodeCountLoads.clear();
  }

  @override
  Future<void> markWatched(TrackerContext ctx) async {
    final activeClient = client;
    final id = animeId(ctx.anime);
    if (activeClient == null || id == null) return;

    final progress = ctx.isMovie ? 1 : (ctx.animeProgress ?? ctx.episodeNumber);
    if (progress == null || progress <= 0) return;
    final total = ctx.isMovie || ctx.animeProgress == null ? null : await _episodeCount(activeClient, id);
    final watched = total != null && progress > total ? total : progress;
    final completed = ctx.isMovie || (total != null && progress >= total);

    await saveAnimeProgress(activeClient, animeId: id, progress: watched, completed: completed);
  }

  @override
  Future<void> markUnwatched(TrackerContext ctx) async {
    if (ctx.isMovie) {
      await removeFromList(ctx);
    }
  }

  Future<void> removeFromList(TrackerContext ctx) async {
    final activeClient = client;
    final id = animeId(ctx.anime);
    if (activeClient == null || id == null) return;
    await deleteAnimeEntry(activeClient, id);
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
    if (activeClient == null || id == null) throw TrackerRatingUnavailableException(ratingUnavailableName);
    return (activeClient, id);
  }

  Future<int?> _episodeCount(TClient activeClient, int id) {
    final existing = _episodeCountLoads[id];
    if (existing != null) return existing;

    late final Future<int?> loading;
    loading = loadAnimeEpisodeCount(activeClient, id).catchError((Object e) {
      if (identical(_episodeCountLoads[id], loading)) {
        final _ = _episodeCountLoads.remove(id);
      }
      appLogger.d('$logLabel: failed to fetch anime episode count ($idLogName=$id)', error: e);
      return null;
    });
    _episodeCountLoads[id] = loading;
    return loading;
  }
}
