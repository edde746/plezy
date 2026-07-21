import 'package:collection/collection.dart';

import '../../media/media_kind.dart';
import '../../models/anilist/anilist_media.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_item.dart';
import '../../models/trackers/fribb_mapping_row.dart';
import '../../utils/external_ids.dart';
import '../trackers/anilist/anilist_client.dart';
import '../trackers/fribb_mapping_store.dart';
import '../trackers/future_coalescer.dart';
import 'catalog_source.dart';
import 'catalog_watchlist_machinery.dart';

/// [CatalogSource] backed by AniList's GraphQL API.
///
/// The client is owned and rebound by `TrackersProvider`; this source only
/// borrows it. Fribb bridges AniList/MAL identities to media-server IDs.
class AnilistCatalogSource with CatalogWatchlistMachinery implements CatalogSource {
  final AnilistClient _client;
  final FribbMappingLookup _fribb;
  final FutureCoalescer<int> _viewerIdLoad = FutureCoalescer<int>();
  int? _viewerId;

  AnilistCatalogSource(this._client, {FribbMappingLookup? fribb}) : _fribb = fribb ?? FribbMappingStore.instance;

  @override
  CatalogSourceId get id => CatalogSourceId.anilist;

  @override
  String get displayName => 'AniList';

  @override
  List<CatalogRowId> get supportedRows => const [
    CatalogRowId.watchlist,
    CatalogRowId.trendingAnime,
    CatalogRowId.airingAnime,
    CatalogRowId.popularAnime,
  ];

  @override
  bool get supportsWatchlist => true;

  @override
  String get watchlistLogLabel => 'AniList: Planning';

  @override
  int get watchlistPageLimit => 500;

  @override
  int get watchlistMaxPages => 4;

  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) async {
    final AnilistPage result;
    switch (row) {
      case CatalogRowId.watchlist:
        result = await _client.getPlanningPage(await _getViewerId(), chunk: page, perChunk: limit);
      case CatalogRowId.trendingAnime:
        result = await _client.getTrendingAnime(page: page, limit: limit);
      case CatalogRowId.airingAnime:
        final current = currentAnimeSeason(DateTime.now());
        result = await _client.getSeasonalAnime(current.season, current.year, page: page, limit: limit);
      case CatalogRowId.popularAnime:
        result = await _client.getPopularAnime(page: page, limit: limit);
      case CatalogRowId.recommendedMovies:
      case CatalogRowId.recommendedShows:
      case CatalogRowId.trendingMovies:
      case CatalogRowId.trendingShows:
      case CatalogRowId.popularMovies:
      case CatalogRowId.popularShows:
      case CatalogRowId.suggestedAnime:
      case CatalogRowId.trending:
      case CatalogRowId.upcomingMovies:
      case CatalogRowId.upcomingShows:
        throw ArgumentError('AniList does not serve ${row.name}');
    }
    return CatalogPage(items: await _toCatalogItems(result.items), hasMore: result.hasMore);
  }

  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final result = await _client.searchAnime(trimmed, limit: limit);
    return _toCatalogItems(result.items);
  }

  static ({String season, int year}) currentAnimeSeason(DateTime date) => switch (date.month) {
    12 => (season: 'WINTER', year: date.year + 1),
    1 || 2 => (season: 'WINTER', year: date.year),
    >= 3 && <= 5 => (season: 'SPRING', year: date.year),
    >= 6 && <= 8 => (season: 'SUMMER', year: date.year),
    _ => (season: 'FALL', year: date.year),
  };

  static CatalogAirStatus? airStatusFor(AnilistMedia anime) => switch (anime.status) {
    'RELEASING' => CatalogAirStatus.airing,
    'FINISHED' => anime.isMovie ? null : CatalogAirStatus.ended,
    'NOT_YET_RELEASED' => CatalogAirStatus.upcoming,
    'CANCELLED' => CatalogAirStatus.canceled,
    _ => null,
  };

  Future<List<CatalogItem>> _toCatalogItems(List<AnilistMedia> anime) async {
    final valid = [
      for (final entry in anime)
        if (entry.id != null) entry,
    ];
    final rows = await Future.wait([
      for (final entry in valid)
        if (entry.idMal case final int malId) _fribb.lookupByMal(malId) else Future<FribbMappingRow?>.value(),
    ]);
    return [for (var i = 0; i < valid.length; i++) _toCatalogItem(valid[i], rows[i])];
  }

  CatalogItem _toCatalogItem(AnilistMedia anime, FribbMappingRow? row) => CatalogItem(
    source: CatalogSourceId.anilist,
    kind: anime.isMovie ? MediaKind.movie : MediaKind.show,
    title: anime.displayTitle,
    year: anime.year,
    overview: anime.description,
    runtimeMinutes: anime.runtimeMinutes,
    rating: anime.rating,
    votes: anime.votes,
    genres: anime.genres,
    trailerUrl: anime.trailerUrl,
    airStatus: airStatusFor(anime),
    episodeCount: anime.isMovie || (anime.episodes ?? 0) <= 0 ? null : anime.episodes,
    network: anime.network,
    ids: CatalogItemIds(
      anilist: anime.id,
      mal: anime.idMal,
      imdb: row?.imdbIds?.firstOrNull,
      tmdb: row?.tmdbIds?.firstOrNull,
      tvdb: row?.tvdbId,
    ),
    posterUrl: anime.posterUrl,
    backdropUrl: anime.backdropUrl,
  );

  @override
  Future<List<CatalogCastMember>> fetchCast(CatalogItem item, {int limit = 20}) async {
    final anilistId = item.ids.anilist;
    if (anilistId == null) return const [];
    final characters = await _client.getAnimeCharacters(anilistId, limit: limit);
    return [
      for (final character in characters)
        if (character.name.isNotEmpty)
          CatalogCastMember(name: character.name, secondary: character.role, imageUrl: character.imageUrl),
    ];
  }

  @override
  Future<List<CatalogItem>> fetchRelated(CatalogItem item, {int limit = 20}) async {
    final anilistId = item.ids.anilist;
    if (anilistId == null) return const [];
    return _toCatalogItems(await _client.getAnimeRecommendations(anilistId, limit: limit));
  }

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async {
    if (!external.hasAny) return null;
    final rows = await _fribb.lookup(tvdbId: external.tvdb, tmdbId: external.tmdb, imdbId: external.imdb);
    final row = _pickRow(kind, rows);
    if (row?.anilistId == null) return null;
    return CatalogItemIds(
      anilist: row!.anilistId,
      mal: row.malId,
      imdb: external.imdb,
      tmdb: external.tmdb,
      tvdb: external.tvdb,
    );
  }

  static FribbMappingRow? _pickRow(MediaKind kind, List<FribbMappingRow> rows) {
    final withAnilist = [
      for (final row in rows)
        if (row.anilistId != null) row,
    ];
    if (withAnilist.isEmpty) return null;
    if (kind == MediaKind.movie) {
      return withAnilist.firstWhereOrNull((row) => row.isMovie) ?? withAnilist.first;
    }
    return withAnilist.firstWhereOrNull((row) => row.tvdbSeason == 1 || row.tmdbSeason == 1) ?? withAnilist.first;
  }

  static List<String> _identityKeys(CatalogItemIds ids) => [
    if (ids.anilist case final int id) 'anilist:$id',
    if (ids.mal case final int id) 'mal:$id',
  ];

  @override
  List<String> membershipKeysFor(MediaKind kind, CatalogItemIds ids) => _identityKeys(ids);

  @override
  Future<WatchlistKeyPage> fetchWatchlistKeyPage(int page, int limit) async {
    final result = await _client.getPlanningIdsPage(await _getViewerId(), chunk: page, perChunk: limit);
    return (
      groups: [
        for (final anime in result.items)
          for (final keys in [_identityKeys(CatalogItemIds(anilist: anime.id, mal: anime.idMal))])
            if (keys.isNotEmpty) keys,
      ],
      hasMore: result.hasMore,
    );
  }

  Future<int> _getViewerId() {
    final cached = _viewerId;
    if (cached != null) return Future.value(cached);
    return _viewerIdLoad.run(() async {
      final id = await _client.getViewerId();
      _viewerId = id;
      return id;
    });
  }

  @override
  Future<CatalogItemIds> resolveWatchlistMutationIds(MediaKind kind, CatalogItemIds ids) async {
    if (ids.anilist != null) return ids;

    if (ids.mal case final int malId) {
      final row = await _fribb.lookupByMal(malId);
      if (row?.anilistId case final int anilistId) {
        return CatalogItemIds(anilist: anilistId, mal: malId, imdb: ids.imdb, tmdb: ids.tmdb, tvdb: ids.tvdb);
      }
    }

    final resolved = await resolveItemIds(kind, ids.toExternalIds());
    if (resolved?.anilist == null) {
      throw StateError('AniList: no anime mapping for ${ids.canonicalKey ?? 'item'}');
    }
    return resolved!;
  }

  @override
  Future<void> performWatchlistMutation(MediaKind kind, CatalogItemIds ids, {required bool add}) async {
    final anilistId = ids.anilist!;
    if (add) {
      await _client.setMediaListStatus(mediaId: anilistId, status: 'PLANNING');
    } else {
      await _client.deleteMediaListEntry(anilistId);
    }
  }

  @override
  void dispose() {
    disposeWatchlistMachinery();
  }
}
