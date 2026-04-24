import '../../models/plex_metadata.dart';
import '../../models/trackers/anime_ids.dart';
import '../../models/trackers/fribb_mapping_row.dart';
import '../../utils/plex_external_ids.dart';
import '../plex_client.dart';
import 'fribb_mapping_store.dart';

/// Paired ID output: always-present Plex external IDs (tvdb/imdb/tmdb) plus
/// optional Fribb-sourced anime IDs (mal/anilist/simkl). Simkl uses [external]
/// directly for non-anime titles; MAL/AniList no-op when [anime] is null.
class TrackerIds {
  final PlexExternalIds external;
  final AnimeIds? anime;

  const TrackerIds({required this.external, required this.anime});
}

/// Resolves Plex ratingKeys → tracker external IDs. Returns both Plex
/// external IDs (used by Trakt and by Simkl for non-anime matches) and Fribb
/// anime IDs (used by MAL/AniList, and by Simkl for anime precision).
/// Episodes resolve against the show's GUIDs because Fribb only maps
/// show-level external IDs; split-cour disambiguation uses the Plex season
/// number.
///
/// The Fribb lookup is skipped when [needsFribb] returns false — set this way
/// for Trakt (which never uses anime IDs) and for a Simkl-only configuration,
/// so those users don't pay the 5.6 MB mapping download they'll never need.
class TrackerIdResolver {
  final PlexClient _client;
  final FribbMappingStore _store;
  final bool Function() _needsFribb;

  /// Null entries mean "Plex had no GUIDs" — cached so scrubbing on an
  /// un-matched item doesn't re-hit Plex every position update.
  final Map<String, TrackerIds?> _cache = {};

  TrackerIdResolver(this._client, {bool Function()? needsFribb, FribbMappingStore? store})
    : _needsFribb = needsFribb ?? _returnTrue,
      _store = store ?? FribbMappingStore.instance;

  static bool _returnTrue() => true;

  /// Resolve IDs for a movie.
  Future<TrackerIds?> resolveForMovie(String ratingKey) async {
    if (_cache.containsKey(ratingKey)) return _cache[ratingKey];

    final external = PlexExternalIds.fromGuids(await _client.fetchExternalGuids(ratingKey));
    final ids = await _build(external, isEpisodeSeason: null, isMovie: true);
    _cache[ratingKey] = ids;
    return ids;
  }

  /// Resolve IDs for an episode. Looks up the *show's* external IDs (via
  /// `grandparentRatingKey`), then disambiguates among candidate Fribb rows
  /// using the episode's season number.
  Future<TrackerIds?> resolveShowForEpisode(PlexMetadata episode) async {
    final showRatingKey = episode.grandparentRatingKey;
    if (showRatingKey == null || showRatingKey.isEmpty) return null;

    final season = episode.parentIndex;
    // Cache under the (showRatingKey, season) pair so a show with multiple
    // Fribb rows caches each season separately during a marathon.
    final cacheKey = season != null ? '$showRatingKey#s$season' : showRatingKey;
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    final external = PlexExternalIds.fromGuids(await _client.fetchExternalGuids(showRatingKey));
    final ids = await _build(external, isEpisodeSeason: season, isMovie: false);
    _cache[cacheKey] = ids;
    return ids;
  }

  void clearCache() => _cache.clear();

  Future<TrackerIds?> _build(PlexExternalIds external, {int? isEpisodeSeason, required bool isMovie}) async {
    if (!external.hasAny) return null;
    if (!_needsFribb()) return TrackerIds(external: external, anime: null);
    final rows = await _store.lookup(tvdbId: external.tvdb, tmdbId: external.tmdb, imdbId: external.imdb);
    final row = isMovie ? _pickMovieRow(rows) : _pickShowRow(rows, season: isEpisodeSeason);
    final anime = row == null ? null : AnimeIds.fromFribb(row);
    return TrackerIds(external: external, anime: anime);
  }

  /// Pick the best row for a movie lookup — prefer rows marked `type: MOVIE`.
  FribbMappingRow? _pickMovieRow(List<FribbMappingRow> rows) {
    if (rows.isEmpty) return null;
    final movies = rows.where((r) => r.isMovie);
    if (movies.isNotEmpty) return movies.first;
    // Fall back to any row if no explicit MOVIE row matches — some rows have
    // no type field.
    return rows.first;
  }

  /// Pick the best row for a show lookup. When Fribb has multiple rows
  /// sharing the same show-level external ID (split-cour anime), prefer the
  /// one whose `season.tvdb` matches the Plex episode's season; otherwise
  /// the first non-MOVIE row.
  FribbMappingRow? _pickShowRow(List<FribbMappingRow> rows, {int? season}) {
    if (rows.isEmpty) return null;

    if (season != null) {
      for (final row in rows) {
        if (row.tvdbSeason == season || row.tmdbSeason == season) return row;
      }
    }

    // No season match — fall back to the first non-MOVIE row (prefer series).
    for (final row in rows) {
      if (!row.isMovie) return row;
    }
    return rows.first;
  }
}
