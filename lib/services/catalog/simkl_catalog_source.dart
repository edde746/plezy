import '../../media/media_kind.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_item.dart';
import '../../models/simkl/simkl_all_items_entry.dart';
import '../../models/simkl/simkl_best_item.dart';
import '../../models/simkl/simkl_ids.dart';
import '../../models/simkl/simkl_images.dart';
import '../../models/simkl/simkl_recommendation.dart';
import '../../models/simkl/simkl_search_result.dart';
import '../../models/simkl/simkl_trending_item.dart';
import '../../utils/external_ids.dart';
import '../trackers/simkl/simkl_client.dart';
import '../trackers/simkl/simkl_constants.dart';
import '../trackers/tracker_exceptions.dart';
import '../trackers/future_coalescer.dart';
import 'catalog_source.dart';
import 'catalog_watchlist_machinery.dart';

/// [CatalogSource] backed by Simkl's REST API and public discovery CDN.
///
/// The client is owned and rebound by `TrackersProvider`; this source only
/// borrows it. Simkl accepts the media server's native external IDs directly,
/// so library-item resolution does not require Fribb.
class SimklCatalogSource with CatalogWatchlistMachinery implements CatalogSource {
  static const Duration _rowCacheTtl = Duration(minutes: 15);

  final SimklClient _client;
  final Map<CatalogRowId, List<CatalogItem>> _rowCache = {};
  final Map<CatalogRowId, DateTime> _rowCacheLoadedAt = {};
  final KeyedFutureCoalescer<CatalogRowId, List<CatalogItem>> _rowLoads = KeyedFutureCoalescer();
  final FutureCoalescer<SimklAllItems> _watchlistLoad = FutureCoalescer();
  SimklAllItems? _watchlistCache;
  int _watchlistCacheGeneration = 0;

  SimklCatalogSource(this._client);

  @override
  CatalogSourceId get id => CatalogSourceId.simkl;

  @override
  String get displayName => 'Simkl';

  @override
  List<CatalogRowId> get supportedRows => const [
    CatalogRowId.watchlist,
    CatalogRowId.trendingMovies,
    CatalogRowId.trendingShows,
    CatalogRowId.trendingAnime,
    CatalogRowId.popularShows,
    CatalogRowId.popularAnime,
  ];

  @override
  bool get supportsWatchlist => true;

  @override
  String get watchlistLogLabel => 'Simkl: Plan to Watch';

  /// Simkl's plan-to-watch snapshot is one unpaginated response.
  @override
  int get watchlistPageLimit => 1;

  @override
  int get watchlistMaxPages => 1;

  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) async {
    if (!supportedRows.contains(row)) {
      throw ArgumentError('Simkl does not serve ${row.name}');
    }

    final normalizedPage = page < 1 ? 1 : page;
    final normalizedLimit = limit < 1 ? 1 : limit;
    var cached = _rowCache[row];
    final loadedAt = _rowCacheLoadedAt[row];
    final expired = normalizedPage == 1 && loadedAt != null && DateTime.now().difference(loadedAt) >= _rowCacheTtl;
    if (cached == null || expired) {
      cached = await _rowLoads.run(row, () async {
        final current = _rowCache[row];
        final currentLoadedAt = _rowCacheLoadedAt[row];
        final currentExpired =
            normalizedPage == 1 &&
            currentLoadedAt != null &&
            DateTime.now().difference(currentLoadedAt) >= _rowCacheTtl;
        if (current != null && !currentExpired) return current;
        if (row == CatalogRowId.watchlist && currentExpired) _invalidateWatchlistCache();
        final fetched = await _fetchUnpaginatedRow(row);
        _rowCache[row] = fetched;
        _rowCacheLoadedAt[row] = DateTime.now();
        return fetched;
      });
    }

    final start = (normalizedPage - 1) * normalizedLimit;
    if (start >= cached.length) return const CatalogPage(items: []);
    final end = (start + normalizedLimit).clamp(0, cached.length);
    return CatalogPage(items: cached.sublist(start, end), hasMore: end < cached.length);
  }

  Future<List<CatalogItem>> _fetchUnpaginatedRow(CatalogRowId row) async => switch (row) {
    CatalogRowId.watchlist => _fetchWatchlistRow(),
    // Simkl requires visible attribution wherever the CDN trending data is
    // displayed. The source switcher logo/name supplies that attribution.
    CatalogRowId.trendingMovies => _fetchTrending(SimklCatalogType.movies),
    CatalogRowId.trendingShows => _fetchTrending(SimklCatalogType.tv),
    CatalogRowId.trendingAnime => _fetchTrending(SimklCatalogType.anime),
    CatalogRowId.popularShows => _fetchBest(SimklCatalogType.tv),
    CatalogRowId.popularAnime => _fetchBest(SimklCatalogType.anime),
    CatalogRowId.recommendedMovies ||
    CatalogRowId.recommendedShows ||
    CatalogRowId.popularMovies ||
    CatalogRowId.suggestedAnime ||
    CatalogRowId.airingAnime ||
    CatalogRowId.trending ||
    CatalogRowId.upcomingMovies ||
    CatalogRowId.upcomingShows => throw ArgumentError('Simkl does not serve ${row.name}'),
  };

  Future<List<CatalogItem>> _fetchTrending(SimklCatalogType type) async => [
    for (final item in await _client.getTrending(type))
      if (item.ids.hasAny) _catalogItemFromTrending(item, type),
  ];

  Future<List<CatalogItem>> _fetchBest(SimklCatalogType type) async => [
    for (final item in await _client.getBest(type))
      if (item.ids.hasAny) _catalogItemFromBest(item, type),
  ];

  Future<List<CatalogItem>> _fetchWatchlistRow() async {
    final response = await _getWatchlistItems();
    return [
      for (final entry in response.movies)
        if (entry.media?.ids.hasAny == true) _catalogItemFromAllItems(entry, SimklCatalogType.movies),
      for (final entry in response.shows)
        if (entry.media?.ids.hasAny == true) _catalogItemFromAllItems(entry, SimklCatalogType.tv),
      for (final entry in response.anime)
        if (entry.media?.ids.hasAny == true) _catalogItemFromAllItems(entry, SimklCatalogType.anime),
    ];
  }

  Future<SimklAllItems> _getWatchlistItems() {
    final cached = _watchlistCache;
    if (cached != null) return Future.value(cached);
    final generation = _watchlistCacheGeneration;
    return _watchlistLoad.run(() async {
      final response = await _client.getAllItems(extended: 'full');
      if (generation == _watchlistCacheGeneration) _watchlistCache = response;
      return response;
    });
  }

  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || limit <= 0) return const [];
    final perType = (limit / 3).ceil().clamp(1, 50);
    final pages = await Future.wait([
      _client.searchCatalog(SimklCatalogType.movies, trimmed, limit: perType),
      _client.searchCatalog(SimklCatalogType.tv, trimmed, limit: perType),
      _client.searchCatalog(SimklCatalogType.anime, trimmed, limit: perType),
    ]);
    final types = const [SimklCatalogType.movies, SimklCatalogType.tv, SimklCatalogType.anime];
    return [
      for (var i = 0; i < pages.length; i++)
        for (final item in pages[i].items)
          if (item.ids.hasAny) _catalogItemFromSearch(item, types[i]),
    ].take(limit).toList();
  }

  static CatalogAirStatus? airStatusFor(String? status, MediaKind kind) => switch (status?.toLowerCase()) {
    'airing' || 'ongoing' => CatalogAirStatus.airing,
    'ended' => kind == MediaKind.movie ? null : CatalogAirStatus.ended,
    'tba' => CatalogAirStatus.upcoming,
    _ => null,
  };

  static MediaKind _kindFor(SimklCatalogType type, {String? animeType}) {
    if (type == SimklCatalogType.movies) return MediaKind.movie;
    if (type == SimklCatalogType.anime && animeType?.toLowerCase() == 'movie') return MediaKind.movie;
    return MediaKind.show;
  }

  CatalogItem _catalogItemFromTrending(SimklTrendingItem item, SimklCatalogType type) {
    final kind = _kindFor(type, animeType: item.animeType);
    final rating = item.ratings?.primary;
    return CatalogItem(
      source: CatalogSourceId.simkl,
      kind: kind,
      title: item.title ?? '',
      year: item.year,
      overview: item.overview,
      runtimeMinutes: item.runtimeMinutes,
      rating: rating?.rating,
      votes: rating?.votes,
      genres: item.genres,
      trailerUrl: item.trailerUrl,
      airStatus: airStatusFor(item.status, kind),
      episodeCount: kind == MediaKind.movie || (item.totalEpisodes ?? 0) <= 0 ? null : item.totalEpisodes,
      network: item.network,
      ids: item.ids.toCatalogItemIds(),
      posterUrl: simklPosterUrl(item.poster),
      backdropUrl: simklFanartUrl(item.fanart),
    );
  }

  CatalogItem _catalogItemFromSearch(SimklSearchResult item, SimklCatalogType type) {
    final kind = _kindFor(type, animeType: item.type);
    final rating = item.ratings?.primary;
    return CatalogItem(
      source: CatalogSourceId.simkl,
      kind: kind,
      title: item.title ?? '',
      year: item.year,
      rating: rating?.rating,
      votes: rating?.votes,
      airStatus: airStatusFor(item.status, kind),
      episodeCount: kind == MediaKind.movie || (item.episodeCount ?? 0) <= 0 ? null : item.episodeCount,
      ids: item.ids.toCatalogItemIds(),
      posterUrl: simklPosterUrl(item.poster),
    );
  }

  CatalogItem _catalogItemFromBest(SimklBestItem item, SimklCatalogType type) {
    final kind = _kindFor(type);
    final rating = item.ratings?.primary;
    return CatalogItem(
      source: CatalogSourceId.simkl,
      kind: kind,
      title: item.title ?? '',
      year: item.year,
      rating: rating?.rating,
      votes: rating?.votes,
      ids: item.ids.toCatalogItemIds(),
      posterUrl: simklPosterUrl(item.poster),
    );
  }

  CatalogItem _catalogItemFromAllItems(SimklAllItemsEntry entry, SimklCatalogType type) {
    final media = entry.media!;
    final kind = _kindFor(type, animeType: entry.animeType);
    return CatalogItem(
      source: CatalogSourceId.simkl,
      kind: kind,
      title: media.title ?? '',
      year: media.year,
      overview: media.overview,
      runtimeMinutes: media.runtime,
      genres: media.genres,
      airStatus: airStatusFor(media.status, kind),
      episodeCount: kind == MediaKind.movie || (entry.totalEpisodes ?? 0) <= 0 ? null : entry.totalEpisodes,
      network: media.network,
      ids: media.ids.toCatalogItemIds(),
      posterUrl: simklPosterUrl(media.poster),
      backdropUrl: simklFanartUrl(media.fanart),
    );
  }

  CatalogItem _catalogItemFromRecommendation(SimklRecommendation item) {
    final kind = item.type == 'movie' ? MediaKind.movie : MediaKind.show;
    return CatalogItem(
      source: CatalogSourceId.simkl,
      kind: kind,
      title: item.title ?? '',
      year: item.year,
      ids: item.ids.toCatalogItemIds(),
      posterUrl: simklPosterUrl(item.poster),
    );
  }

  @override
  Future<List<CatalogCastMember>> fetchCast(CatalogItem item, {int limit = 20}) async => const [];

  @override
  Future<List<CatalogItem>> fetchRelated(CatalogItem item, {int limit = 20}) async {
    final simklId = item.ids.simkl;
    if (simklId == null) return const [];
    final primary = item.kind == MediaKind.movie ? SimklCatalogType.movies : SimklCatalogType.tv;
    List<SimklRecommendation> recommendations;
    try {
      recommendations = await _client.getRecommendations(primary, simklId);
      // Current Simkl detail endpoints return `[]` (HTTP 200), not 404, for
      // an ID belonging to a different media bucket. Anime is therefore the
      // fallback for both an explicit 404 and an empty primary response.
      if (recommendations.isEmpty) {
        recommendations = await _client.getRecommendations(SimklCatalogType.anime, simklId);
      }
    } on TrackerApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      recommendations = await _client.getRecommendations(SimklCatalogType.anime, simklId);
    }
    return [
      for (final recommendation in recommendations.take(limit))
        if (recommendation.ids.hasAny) _catalogItemFromRecommendation(recommendation),
    ];
  }

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async =>
      external.hasAny ? CatalogItemIds.fromExternal(external) : null;

  @override
  Future<WatchlistKeyPage> fetchWatchlistKeyPage(int page, int limit) async {
    final response = await _getWatchlistItems();
    return (
      groups: [
        for (final entry in response.movies)
          if (entry.media case final media?) membershipKeysFor(MediaKind.movie, media.ids.toCatalogItemIds()),
        for (final entry in response.shows)
          if (entry.media case final media?) membershipKeysFor(MediaKind.show, media.ids.toCatalogItemIds()),
        for (final entry in response.anime)
          if (entry.media case final media?)
            [
              ...membershipKeysFor(MediaKind.movie, media.ids.toCatalogItemIds()),
              ...membershipKeysFor(MediaKind.show, media.ids.toCatalogItemIds()),
            ],
      ],
      hasMore: false,
    );
  }

  @override
  Future<void> performWatchlistMutation(MediaKind kind, CatalogItemIds ids, {required bool add}) async {
    final bucket = kind == MediaKind.show ? 'shows' : 'movies';
    final mutationIds = SimklIds.fromCatalogItemIds(ids).toJson();
    if (add) {
      await _client.addToList({
        bucket: [
          {'to': 'plantowatch', 'ids': mutationIds},
        ],
      });
    } else {
      // Simkl has no remove-from-list endpoint. A bare-IDs history removal drops
      // the title from the user's library entirely; for a Plan to Watch entry,
      // that is the documented and intended removal behavior.
      await _client.removeFromHistory({
        bucket: [
          {'ids': mutationIds},
        ],
      });
    }
    _invalidateWatchlistCache();
  }

  void _invalidateWatchlistCache() {
    _watchlistCacheGeneration++;
    _watchlistCache = null;
    _watchlistLoad.reset();
    _rowCache.remove(CatalogRowId.watchlist);
    _rowCacheLoadedAt.remove(CatalogRowId.watchlist);
  }

  @override
  void dispose() {
    _invalidateWatchlistCache();
    _rowCache.clear();
    _rowCacheLoadedAt.clear();
    disposeWatchlistMachinery();
  }
}
