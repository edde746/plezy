import '../../models/trackers/fribb_mapping_row.dart';

/// Indexed view of the Fribb mapping database, queried by external ID.
///
/// Lookup tables (tvdb / tmdb tv / tmdb movie / imdb) into a shared list of
/// rows. A single tvdb_id may map to multiple rows (split-cour anime → one per
/// season); callers that have a Plex season number should filter by
/// [FribbMappingRow.tvdbSeason] or [FribbMappingRow.tmdbSeason].
///
/// TMDB gets two tables because it numbers movies and TV series independently:
/// one number routinely names an unrelated film and series, so a single table
/// would hand a library movie some anime series' entry.
class FribbIndex {
  final Map<int, List<FribbMappingRow>> byTvdb;
  final Map<int, List<FribbMappingRow>> byTmdbTv;
  final Map<int, List<FribbMappingRow>> byTmdbMovie;
  final Map<String, List<FribbMappingRow>> byImdb;

  /// Reverse index for the Explore catalog: MAL id → its (single) row, so a
  /// MAL entry can be matched back to library external ids.
  final Map<int, FribbMappingRow> byMal;

  /// AniDB id → its (single) row. AniDB is the dataset's own primary key, so
  /// unlike the three catalog indexes this one never resolves to a list.
  /// Plex's HAMA agent identifies anime by AniDB id and nothing else, which is
  /// the only way a library item reaches the mapping through it (#1788).
  final Map<int, FribbMappingRow> byAnidb;

  const FribbIndex({
    required this.byTvdb,
    required this.byTmdbTv,
    required this.byTmdbMovie,
    required this.byImdb,
    this.byMal = const {},
    this.byAnidb = const {},
  });

  static const empty = FribbIndex(byTvdb: {}, byTmdbTv: {}, byTmdbMovie: {}, byImdb: {});

  /// A row may carry several imdb/tmdb movie ids (movie collections), so each
  /// row is filed under every id it declares.
  factory FribbIndex.fromRows(Iterable<FribbMappingRow> rows) {
    final byTvdb = <int, List<FribbMappingRow>>{};
    final byTmdbTv = <int, List<FribbMappingRow>>{};
    final byTmdbMovie = <int, List<FribbMappingRow>>{};
    final byImdb = <String, List<FribbMappingRow>>{};
    final byMal = <int, FribbMappingRow>{};
    final byAnidb = <int, FribbMappingRow>{};

    for (final row in rows) {
      final tvdb = row.tvdbId;
      if (tvdb != null) {
        (byTvdb[tvdb] ??= <FribbMappingRow>[]).add(row);
      }
      final tmdbTv = row.tmdbTvId;
      if (tmdbTv != null) {
        (byTmdbTv[tmdbTv] ??= <FribbMappingRow>[]).add(row);
      }
      for (final tmdb in row.tmdbMovieIds ?? const <int>[]) {
        (byTmdbMovie[tmdb] ??= <FribbMappingRow>[]).add(row);
      }
      for (final imdb in row.imdbIds ?? const <String>[]) {
        if (imdb.isEmpty) continue;
        (byImdb[imdb] ??= <FribbMappingRow>[]).add(row);
      }
      final mal = row.malId;
      if (mal != null) byMal.putIfAbsent(mal, () => row);
      final anidb = row.anidbId;
      if (anidb != null) byAnidb.putIfAbsent(anidb, () => row);
    }

    return FribbIndex(
      byTvdb: byTvdb,
      byTmdbTv: byTmdbTv,
      byTmdbMovie: byTmdbMovie,
      byImdb: byImdb,
      byMal: byMal,
      byAnidb: byAnidb,
    );
  }

  bool get isEmpty =>
      byTvdb.isEmpty && byTmdbTv.isEmpty && byTmdbMovie.isEmpty && byImdb.isEmpty && byMal.isEmpty && byAnidb.isEmpty;

  /// Rows for a library item's external IDs: the first non-empty candidate list
  /// in preference order anidb → tvdb → tmdb → imdb.
  ///
  /// AniDB leads because it is the dataset's primary key: it names exactly one
  /// entry, where a tvdb/tmdb/imdb hit can be a whole split-cour show the
  /// caller still has to disambiguate.
  ///
  /// A [movie] skips TVDB altogether: Fribb's `tvdb_id` is always a series id
  /// (an anime film appears there as a special of its series), while a library
  /// movie's TVDB id is a TVDB movie id — a separate numbering that would only
  /// ever collide. Its TMDB id is likewise looked up among movie ids only.
  List<FribbMappingRow> lookup({required bool movie, int? anidbId, int? tvdbId, int? tmdbId, String? imdbId}) {
    if (anidbId != null) {
      final hit = byAnidb[anidbId];
      if (hit != null) return [hit];
    }
    if (tvdbId != null && !movie) {
      final hits = byTvdb[tvdbId];
      if (hits != null && hits.isNotEmpty) return hits;
    }
    if (tmdbId != null) {
      final hits = (movie ? byTmdbMovie : byTmdbTv)[tmdbId];
      if (hits != null && hits.isNotEmpty) return hits;
    }
    if (imdbId != null) {
      final hits = byImdb[imdbId];
      if (hits != null && hits.isNotEmpty) return hits;
    }
    return const [];
  }
}

abstract interface class FribbMappingLookup {
  /// Rows for a library item's external IDs. [movie] names the namespace its
  /// TMDB and TVDB ids live in: both catalogs number films apart from series.
  Future<List<FribbMappingRow>> lookup({required bool movie, int? anidbId, int? tvdbId, int? tmdbId, String? imdbId});

  Future<FribbMappingRow?> lookupByMal(int malId);
}
