import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../models/trackers/anime_lists_mapping.dart';
import '../../utils/app_logger.dart';

enum AnimeProgressScope { show, season, mapped }

class ResolvedAnimeProgress {
  final int progress;

  const ResolvedAnimeProgress({required this.progress});
}

/// Resolves watched progress in the MAL/AniList anime entry selected by Fribb.
///
/// The coordinator builds tracker context before the current playback is marked
/// watched, so unwatched current episodes are added to the watched rollup.
abstract interface class AnimeEpisodeProgressLookup {
  Future<ResolvedAnimeProgress?> resolve(
    MediaItem episode, {
    required AnimeProgressScope scope,
    AnimeEpisodeMatch? animeMatch,
    Future<AnimeEpisodeMatch?> Function(MediaItem episode)? episodeMatcher,
    bool includeCurrentEpisode = true,
  });

  void clearCache();
}

class AnimeEpisodeProgressResolver implements AnimeEpisodeProgressLookup {
  final MediaServerClient _client;
  final Map<String, Future<Map<int, _SeasonProgress>?>> _seasonProgressLoads = {};

  AnimeEpisodeProgressResolver(this._client);

  @override
  Future<ResolvedAnimeProgress?> resolve(
    MediaItem episode, {
    required AnimeProgressScope scope,
    AnimeEpisodeMatch? animeMatch,
    Future<AnimeEpisodeMatch?> Function(MediaItem episode)? episodeMatcher,
    bool includeCurrentEpisode = true,
  }) async {
    final showId = episode.grandparentId;
    final season = episode.parentIndex;
    if (showId == null || showId.isEmpty) return null;
    if (season == null || season <= 0) return null;

    if (scope == AnimeProgressScope.mapped && animeMatch != null) {
      final mapped = episodeMatcher == null
          ? null
          : await _mappedProgress(
              showId,
              episode,
              animeMatch,
              episodeMatcher,
              includeCurrentEpisode: includeCurrentEpisode,
            );
      if (mapped != null) return mapped;
      return includeCurrentEpisode ? ResolvedAnimeProgress(progress: animeMatch.anidbEpisode) : null;
    }

    final progressBySeason = await _seasonProgressFor(showId);
    if (progressBySeason == null) return null;

    final currentAlreadyWatched = (episode.viewCount ?? 0) > 0 || !includeCurrentEpisode;
    return switch (scope) {
      AnimeProgressScope.show => _showProgress(progressBySeason, currentAlreadyWatched),
      AnimeProgressScope.season => _seasonProgress(progressBySeason[season], currentAlreadyWatched),
      AnimeProgressScope.mapped => null,
    };
  }

  Future<ResolvedAnimeProgress?> _mappedProgress(
    String showId,
    MediaItem current,
    AnimeEpisodeMatch target,
    Future<AnimeEpisodeMatch?> Function(MediaItem episode) episodeMatcher, {
    required bool includeCurrentEpisode,
  }) async {
    try {
      final episodes = await _client.fetchPlayableDescendants(showId);
      var progress = includeCurrentEpisode ? target.anidbEpisode : 0;
      for (final episode in episodes) {
        if (episode.kind != MediaKind.episode) continue;
        final isCurrent = episode.id == current.id;
        if ((episode.viewCount ?? 0) <= 0 && !(includeCurrentEpisode && isCurrent)) continue;
        final match = await episodeMatcher(episode);
        if (match == null || !match.sameAnimeEntry(target)) continue;
        if (match.anidbEpisode > progress) progress = match.anidbEpisode;
      }
      return progress > 0 ? ResolvedAnimeProgress(progress: progress) : null;
    } catch (e) {
      appLogger.d('Anime progress: failed to load mapped episode watched state for $showId', error: e);
      return null;
    }
  }

  Future<Map<int, _SeasonProgress>?> _seasonProgressFor(String showId) async {
    final existing = _seasonProgressLoads[showId];
    if (existing != null) return existing;

    late final Future<Map<int, _SeasonProgress>?> loading;
    loading = _loadSeasonProgress(showId).whenComplete(() {
      if (identical(_seasonProgressLoads[showId], loading)) {
        final _ = _seasonProgressLoads.remove(showId);
      }
    });
    _seasonProgressLoads[showId] = loading;
    return loading;
  }

  ResolvedAnimeProgress? _showProgress(Map<int, _SeasonProgress> seasons, bool currentAlreadyWatched) {
    if (seasons.isEmpty) return null;
    var watched = 0;
    var total = 0;
    for (final entry in seasons.entries) {
      final season = entry.key;
      if (season <= 0) continue;
      watched += entry.value.watched;
      final count = entry.value.total;
      if (count != null && count > 0) {
        total += count;
      }
    }
    final progress = watched + (currentAlreadyWatched ? 0 : 1);
    if (progress <= 0) return null;
    return ResolvedAnimeProgress(progress: total > 0 && progress > total ? total : progress);
  }

  ResolvedAnimeProgress? _seasonProgress(_SeasonProgress? season, bool currentAlreadyWatched) {
    if (season == null) return null;
    final progress = season.watched + (currentAlreadyWatched ? 0 : 1);
    if (progress <= 0) return null;
    final total = season.total;
    return ResolvedAnimeProgress(progress: total != null && total > 0 && progress > total ? total : progress);
  }

  Future<Map<int, _SeasonProgress>?> _loadSeasonProgress(String showId) async {
    try {
      final children = await _client.fetchChildren(showId);
      final progress = <int, _SeasonProgress>{};
      for (final item in children) {
        if (item.kind != MediaKind.season) continue;
        final season = item.index;
        if (season == null || season < 0) continue;
        final watched = item.viewedLeafCount;
        if (watched == null || watched < 0) continue;
        final total = item.leafWatchTotal;
        if (progress.containsKey(season)) return null;
        progress[season] = _SeasonProgress(total: total, watched: watched);
      }
      return progress.isEmpty ? null : progress;
    } catch (e) {
      appLogger.d('Anime progress: failed to load season watched counts for $showId', error: e);
      return null;
    }
  }

  @override
  void clearCache() => _seasonProgressLoads.clear();
}

class _SeasonProgress {
  final int? total;
  final int watched;

  const _SeasonProgress({required this.total, required this.watched});
}
