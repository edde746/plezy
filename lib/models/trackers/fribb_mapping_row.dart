/// One row from `anime-list-mini.json` (Fribb/anime-lists).
class FribbMappingRow {
  final int? anilistId;
  final String? imdbId;
  final int? malId;
  final int? simklId;
  final int? tmdbId;
  final int? tvdbId;

  /// Plex season number this mapping corresponds to. A single show-level
  /// external ID can resolve to multiple rows for split-cour anime; the
  /// resolver picks by matching the episode's `parentIndex` against these.
  final int? tvdbSeason;
  final int? tmdbSeason;

  /// `TV` / `MOVIE` / `OVA` / `ONA` / `SPECIAL` / `UNKNOWN` / `null`.
  final String? type;

  const FribbMappingRow({
    this.anilistId,
    this.imdbId,
    this.malId,
    this.simklId,
    this.tmdbId,
    this.tvdbId,
    this.tvdbSeason,
    this.tmdbSeason,
    this.type,
  });

  bool get isMovie => type == 'MOVIE';

  factory FribbMappingRow.fromJson(Map<String, dynamic> json) {
    final season = json['season'];
    int? tvdbSeason;
    int? tmdbSeason;
    if (season is Map) {
      tvdbSeason = (season['tvdb'] as num?)?.toInt();
      tmdbSeason = (season['tmdb'] as num?)?.toInt();
    }
    return FribbMappingRow(
      anilistId: (json['anilist_id'] as num?)?.toInt(),
      imdbId: json['imdb_id'] as String?,
      malId: (json['mal_id'] as num?)?.toInt(),
      simklId: (json['simkl_id'] as num?)?.toInt(),
      tmdbId: (json['themoviedb_id'] as num?)?.toInt(),
      tvdbId: (json['tvdb_id'] as num?)?.toInt(),
      tvdbSeason: tvdbSeason,
      tmdbSeason: tmdbSeason,
      type: json['type'] as String?,
    );
  }
}
