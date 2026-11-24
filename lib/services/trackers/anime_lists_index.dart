import '../../models/trackers/anime_lists_mapping.dart';

/// Anime-Lists entries by the TVDB and TMDB series they map onto. Several AniDB
/// entries share one series (split cours, specials), so each id holds a list.
class AnimeListsIndex {
  final Map<int, List<AnimeListEntry>> byTvdb;
  final Map<int, List<AnimeListEntry>> byTmdbTv;

  const AnimeListsIndex({required this.byTvdb, required this.byTmdbTv});

  static const empty = AnimeListsIndex(byTvdb: {}, byTmdbTv: {});

  factory AnimeListsIndex.fromEntries(Iterable<AnimeListEntry> entries) {
    final byTvdb = <int, List<AnimeListEntry>>{};
    final byTmdbTv = <int, List<AnimeListEntry>>{};
    for (final entry in entries) {
      final tvdb = entry.tvdbId;
      if (tvdb != null) (byTvdb[tvdb] ??= <AnimeListEntry>[]).add(entry);
      final tmdbTv = entry.tmdbTvId;
      if (tmdbTv != null) (byTmdbTv[tmdbTv] ??= <AnimeListEntry>[]).add(entry);
    }
    return AnimeListsIndex(byTvdb: byTvdb, byTmdbTv: byTmdbTv);
  }

  bool get isEmpty => byTvdb.isEmpty && byTmdbTv.isEmpty;

  /// The AniDB episode an aired TVDB (else TMDB) episode is, when exactly one
  /// is the best match: explicit mappings beat ranges, which beat an entry's
  /// default season. Same-priority matches that disagree resolve to null.
  AnimeEpisodeMatch? lookupEpisode({int? tvdbId, int? tmdbId, int? season, int? episodeNumber}) {
    if (season == null || episodeNumber == null || episodeNumber <= 0) return null;
    if (tvdbId != null) {
      final selected = _selectMatch(_matches(byTvdb[tvdbId], AnimeListProvider.tvdb, season, episodeNumber));
      if (selected != null) return selected;
    }
    if (tmdbId != null) {
      return _selectMatch(_matches(byTmdbTv[tmdbId], AnimeListProvider.tmdb, season, episodeNumber));
    }
    return null;
  }

  Set<int> animeIdsForSeason({int? tvdbId, int? tmdbId, required int season}) {
    if (tvdbId != null) {
      final ids = _seasonAnimeIds(byTvdb[tvdbId], AnimeListProvider.tvdb, season);
      if (ids.isNotEmpty) return ids;
    }
    if (tmdbId != null) {
      return _seasonAnimeIds(byTmdbTv[tmdbId], AnimeListProvider.tmdb, season);
    }
    return const <int>{};
  }

  Set<int> animeIdsForShow({int? tvdbId, int? tmdbId}) {
    if (tvdbId != null) {
      final entries = byTvdb[tvdbId];
      if (entries != null && entries.isNotEmpty) return {for (final entry in entries) entry.anidbId};
    }
    if (tmdbId != null) {
      final entries = byTmdbTv[tmdbId];
      if (entries != null && entries.isNotEmpty) return {for (final entry in entries) entry.anidbId};
    }
    return const <int>{};
  }
}

abstract interface class AnimeListsMappingLookup {
  Future<AnimeEpisodeMatch?> lookupEpisode({int? tvdbId, int? tmdbId, int? season, int? episodeNumber});

  Future<Set<int>> lookupAnimeIdsForSeason({int? tvdbId, int? tmdbId, required int season});

  Future<Set<int>> lookupAnimeIdsForShow({int? tvdbId, int? tmdbId});
}

List<AnimeEpisodeMatch> _matches(
  List<AnimeListEntry>? entries,
  AnimeListProvider provider,
  int season,
  int episodeNumber,
) {
  if (entries == null || entries.isEmpty) return const [];
  return [
    for (final entry in entries)
      ...entry.resolveEpisode(provider: provider, externalSeason: season, externalEpisode: episodeNumber),
  ];
}

AnimeEpisodeMatch? _selectMatch(List<AnimeEpisodeMatch> matches) {
  if (matches.isEmpty) return null;
  final bestPriority = matches.map(_matchPriority).reduce((a, b) => a < b ? a : b);
  final best = matches.where((match) => _matchPriority(match) == bestPriority).toList(growable: false);
  final first = best.first;
  if (best.every(first.sameEpisode)) return first;
  return null;
}

int _matchPriority(AnimeEpisodeMatch match) => switch (match.kind) {
  AnimeListMatchKind.explicit => 0,
  AnimeListMatchKind.range => 1,
  AnimeListMatchKind.defaultMapping => 2,
};

Set<int> _seasonAnimeIds(List<AnimeListEntry>? entries, AnimeListProvider provider, int season) {
  if (entries == null || entries.isEmpty) return const <int>{};
  return {
    for (final entry in entries)
      if (entry.mapsSeason(provider: provider, externalSeason: season)) entry.anidbId,
  };
}
