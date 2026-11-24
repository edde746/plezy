/// One row of Fribb's `anime-list-mini.json` (Fribb/anime-lists), as the
/// `fribb` table of anime-mappings carries it.
class FribbMappingRow {
  final int? anidbId;
  final int? anilistId;

  /// Fribb's `imdb_id` is an array of IMDb GUIDs (movie collections / multi-part
  /// can carry several); a Plex item matches if its single IMDb id is any one.
  final List<String>? imdbIds;
  final int? malId;
  final int? simklId;

  /// TMDB TV series id, from `themoviedb_id: {"tv": id}`.
  ///
  /// Fribb's `themoviedb_id` is `{"tv": <int>}` (always a single id) or
  /// `{"movie": [<int>, ...]}` (one or more). TMDB numbers movies and TV series
  /// independently, so the key is the only thing saying which namespace an id
  /// lives in: TMDB 982 is both the film The Manchurian Candidate and the series
  /// Transformers: Armada. The row's `type` cannot stand in for it — a MOVIE row
  /// can be a TMDB TV special (`{"tv": id}` at season 0) and an OVA a TMDB movie.
  final int? tmdbTvId;

  /// TMDB movie ids, from `themoviedb_id: {"movie": [ids]}`. A movie collection
  /// or multi-part film can carry several; a library movie matches if its single
  /// TMDB id is any one. Never mixed with [tmdbTvId].
  final List<int>? tmdbMovieIds;
  final int? tvdbId;

  /// Plex season number this mapping corresponds to. A single show-level
  /// external ID can resolve to multiple rows for split-cour anime; the
  /// resolver picks by matching the episode's `parentIndex` against these.
  final int? tvdbSeason;
  final int? tmdbSeason;

  /// `TV` / `MOVIE` / `OVA` / `ONA` / `SPECIAL` / `UNKNOWN` / `null`.
  final String? type;

  const FribbMappingRow({
    this.anidbId,
    this.anilistId,
    this.imdbIds,
    this.malId,
    this.simklId,
    this.tmdbTvId,
    this.tmdbMovieIds,
    this.tvdbId,
    this.tvdbSeason,
    this.tmdbSeason,
    this.type,
  });

  bool get isMovie => type == 'MOVIE';

  /// The TMDB id in the namespace the caller presents this entry in — a movie
  /// id for a movie, the series id otherwise — or null when Fribb has none there.
  int? tmdbIdFor({required bool movie}) => movie ? tmdbMovieIds?.firstOrNull : tmdbTvId;
}
