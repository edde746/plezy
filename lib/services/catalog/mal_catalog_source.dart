import 'package:collection/collection.dart';

import '../../media/media_kind.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_item.dart';
import '../../models/mal/mal_anime.dart';
import '../../models/trackers/fribb_mapping_row.dart';
import '../../utils/external_ids.dart';
import '../trackers/fribb_mapping_store.dart';
import '../trackers/mal/mal_client.dart';
import '../trackers/mal/mal_constants.dart';
import '../trackers/tracker_exceptions.dart';
import 'catalog_source.dart';
import 'catalog_watchlist_machinery.dart';

/// [CatalogSource] backed by the MyAnimeList API.
///
/// Wraps the [MalClient] owned by `MalTracker` (rebound per profile by
/// `TrackersProvider`; never disposed here). MAL is anime-only with no
/// movie/show split, so it serves the anime rows, and its watchlist is the
/// user's Plan to Watch list.
///
/// MAL entries carry no media-server external ids; the Fribb anime-lists
/// mapping bridges both directions: catalog items are enriched with
/// tvdb/tmdb/imdb (library matching, cross-source membership), and library
/// items resolve to a MAL id via [resolveItemIds].
class MalCatalogSource with CatalogWatchlistMachinery implements CatalogSource {
  final MalClient _client;
  final FribbMappingLookup _fribb;

  MalCatalogSource(this._client, {FribbMappingLookup? fribb}) : _fribb = fribb ?? FribbMappingStore.instance;

  @override
  String get watchlistLogLabel => 'MAL: Plan to Watch';

  /// Full-snapshot paging: 4 × 500 covers 2000 Plan to Watch entries.
  @override
  int get watchlistPageLimit => 500;
  @override
  int get watchlistMaxPages => 4;

  @override
  CatalogSourceId get id => CatalogSourceId.mal;

  @override
  String get displayName => 'MyAnimeList';

  @override
  List<CatalogRowId> get supportedRows => const [
    CatalogRowId.watchlist,
    CatalogRowId.suggestedAnime,
    CatalogRowId.airingAnime,
    CatalogRowId.popularAnime,
  ];

  @override
  bool get supportsWatchlist => true;

  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) async {
    final res = switch (row) {
      CatalogRowId.watchlist => await _client.getPlanToWatch(page: page, limit: limit),
      CatalogRowId.suggestedAnime => await _client.getSuggestedAnime(page: page, limit: limit),
      CatalogRowId.airingAnime => await _client.getAnimeRanking(MalRankingType.airing, page: page, limit: limit),
      CatalogRowId.popularAnime => await _client.getAnimeRanking(MalRankingType.bypopularity, page: page, limit: limit),
      CatalogRowId.recommendedMovies ||
      CatalogRowId.recommendedShows ||
      CatalogRowId.trendingMovies ||
      CatalogRowId.trendingShows ||
      CatalogRowId.popularMovies ||
      CatalogRowId.popularShows ||
      CatalogRowId.trending ||
      CatalogRowId.upcomingMovies ||
      CatalogRowId.upcomingShows => throw ArgumentError('MAL does not serve ${row.name}'),
    };
    return CatalogPage(items: await _toCatalogItems(res.items), hasMore: res.hasMore);
  }

  /// MAL rejects queries under 3 characters (`invalid q`) — return empty
  /// instead of surfacing a 400 while the user is still typing.
  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];
    final res = await _client.searchAnime(trimmed, limit: limit);
    return _toCatalogItems(res.items);
  }

  @override
  Future<List<CatalogItem>> fetchRelated(CatalogItem item, {int limit = 20}) async {
    final malId = item.ids.mal;
    if (malId == null) return const [];
    return _toCatalogItems(await _client.getAnimeRecommendations(malId, limit: limit));
  }

  /// Enrich concurrently so all items share one Fribb index load (per-item
  /// awaits would retry the download for every item when it is failing).
  Future<List<CatalogItem>> _toCatalogItems(List<MalAnime> anime) async {
    final withIds = [
      for (final entry in anime)
        if (entry.id != null) entry,
    ];
    final rows = await Future.wait([for (final entry in withIds) _fribb.lookupByMal(entry.id!)]);
    return [for (var i = 0; i < withIds.length; i++) _toCatalogItem(withIds[i], rows[i])];
  }

  /// Normalize MAL's status strings. `finished_airing` on a movie maps to
  /// null — an "Ended" chip on every movie is noise.
  static CatalogAirStatus? airStatusFor(MalAnime anime) => switch (anime.status) {
    'currently_airing' => CatalogAirStatus.airing,
    'finished_airing' => anime.isMovie ? null : CatalogAirStatus.ended,
    'not_yet_aired' => CatalogAirStatus.upcoming,
    _ => null,
  };

  CatalogItem _toCatalogItem(MalAnime anime, FribbMappingRow? row) => CatalogItem(
    source: CatalogSourceId.mal,
    kind: anime.isMovie ? MediaKind.movie : MediaKind.show,
    title: anime.displayTitle,
    year: anime.year,
    overview: anime.synopsis,
    runtimeMinutes: anime.runtimeMinutes,
    rating: anime.mean,
    votes: anime.numScoringUsers,
    genres: anime.genreNames,
    certification: anime.certification,
    airStatus: airStatusFor(anime),
    episodeCount: anime.isMovie || (anime.numEpisodes ?? 0) <= 0 ? null : anime.numEpisodes,
    network: anime.primaryStudio,
    ids: CatalogItemIds(
      mal: anime.id,
      imdb: row?.imdbIds?.firstOrNull,
      tmdb: row?.tmdbIds?.firstOrNull,
      tvdb: row?.tvdbId,
    ),
    posterUrl: anime.mainPicture?.primary,
  );

  @override
  Future<List<CatalogCastMember>> fetchCast(CatalogItem item, {int limit = 20}) async {
    final malId = item.ids.mal;
    if (malId == null) return const [];
    final res = await _client.getAnimeCharacters(malId, limit: limit);
    return [
      for (final character in res.items)
        if (character.name.isNotEmpty)
          CatalogCastMember(name: character.name, secondary: character.role, imageUrl: character.imageUrl),
    ];
  }

  /// Reverse-map a library item's external ids to its MAL entry. A show-level
  /// id can resolve to several rows (split-cour anime, one row per season);
  /// prefer season 1 — "add this show" means its first season on MAL. Null
  /// (non-anime) hides the watchlist action.
  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async {
    if (!external.hasAny) return null;
    final rows = await _fribb.lookup(tvdbId: external.tvdb, tmdbId: external.tmdb, imdbId: external.imdb);
    final malId = _pickRow(kind, rows)?.malId;
    if (malId == null) return null;
    return CatalogItemIds(mal: malId, imdb: external.imdb, tmdb: external.tmdb, tvdb: external.tvdb);
  }

  static FribbMappingRow? _pickRow(MediaKind kind, List<FribbMappingRow> rows) {
    final withMal = [
      for (final row in rows)
        if (row.malId != null) row,
    ];
    if (withMal.isEmpty) return null;
    if (kind == MediaKind.movie) {
      return withMal.firstWhereOrNull((row) => row.isMovie) ?? withMal.first;
    }
    return withMal.firstWhereOrNull((row) => row.tvdbSeason == 1 || row.tmdbSeason == 1) ?? withMal.first;
  }

  /// MAL ids are globally unique across anime, so membership keys skip the
  /// kind namespace — a library movie and a MAL `ova` entry for the same
  /// title still agree.
  static String _membershipKey(int malId) => 'mal:$malId';

  @override
  List<String> membershipKeysFor(MediaKind kind, CatalogItemIds ids) => [
    if (ids.mal case final int malId) _membershipKey(malId),
  ];

  @override
  Future<WatchlistKeyPage> fetchWatchlistKeyPage(int page, int limit) async {
    final res = await _client.getPlanToWatch(page: page, limit: limit);
    return (
      groups: [
        for (final anime in res.items)
          if (anime.id != null) [_membershipKey(anime.id!)],
      ],
      hasMore: res.hasMore,
    );
  }

  @override
  Future<CatalogItemIds> resolveWatchlistMutationIds(MediaKind kind, CatalogItemIds ids) async {
    final malId = ids.mal ?? (await resolveItemIds(kind, ids.toExternalIds()))?.mal;
    if (malId == null) {
      throw StateError('MAL: no anime mapping for ${ids.canonicalKey ?? 'item'}');
    }
    return CatalogItemIds(mal: malId, imdb: ids.imdb, tmdb: ids.tmdb, tvdb: ids.tvdb);
  }

  @override
  Future<void> performWatchlistMutation(MediaKind kind, CatalogItemIds ids, {required bool add}) async {
    final malId = ids.mal!;
    if (add) {
      await _client.updateMyListStatus(malId, const {'status': 'plan_to_watch'});
    } else {
      await _deleteEntry(malId);
    }
  }

  /// Removing an entry that is already gone is success, not failure.
  Future<void> _deleteEntry(int malId) async {
    try {
      await _client.deleteMyListStatus(malId);
    } on TrackerApiException catch (e) {
      if (e.statusCode == 404) return;
      rethrow;
    }
  }

  @override
  void dispose() {
    disposeWatchlistMachinery();
  }
}
