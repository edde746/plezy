import '../../media/media_kind.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_item.dart';
import '../../models/trakt/trakt_catalog_entry.dart';
import '../../models/trakt/trakt_catalog_media.dart';
import '../../models/trakt/trakt_ids.dart';
import '../../utils/external_ids.dart';
import '../trakt/trakt_client.dart';
import '../trakt/trakt_constants.dart';
import 'catalog_source.dart';
import 'catalog_watchlist_machinery.dart';

/// [CatalogSource] backed by the Trakt API.
///
/// Wraps the catalog [TraktClient] owned by `TraktAccountProvider` (not owned
/// here — never disposed by this class). Watchlist membership rides
/// [CatalogWatchlistMachinery] with kind-namespaced keys over every id form.
class TraktCatalogSource with CatalogWatchlistMachinery implements CatalogSource {
  final TraktClient _client;

  TraktCatalogSource(this._client);

  @override
  String get watchlistLogLabel => 'Trakt: watchlist';

  /// Full-snapshot paging: 4 × 250 covers 1000 watchlist entries.
  @override
  int get watchlistPageLimit => 250;
  @override
  int get watchlistMaxPages => 4;

  @override
  CatalogSourceId get id => CatalogSourceId.trakt;

  @override
  String get displayName => 'Trakt';

  @override
  List<CatalogRowId> get supportedRows => const [
    CatalogRowId.watchlist,
    CatalogRowId.recommendedMovies,
    CatalogRowId.recommendedShows,
    CatalogRowId.trendingMovies,
    CatalogRowId.trendingShows,
    CatalogRowId.popularMovies,
    CatalogRowId.popularShows,
  ];

  @override
  bool get supportsWatchlist => true;

  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) async {
    switch (row) {
      case CatalogRowId.watchlist:
        final res = await _client.getWatchlist(page: page, limit: limit);
        return CatalogPage(items: _fromEntries(res.items), hasMore: res.hasMore);
      case CatalogRowId.recommendedMovies:
        return CatalogPage(
          items: _fromMedia(await _client.getRecommended(TraktCatalogType.movies, limit: limit), MediaKind.movie),
        );
      case CatalogRowId.recommendedShows:
        return CatalogPage(
          items: _fromMedia(await _client.getRecommended(TraktCatalogType.shows, limit: limit), MediaKind.show),
        );
      case CatalogRowId.trendingMovies:
        final res = await _client.getTrending(TraktCatalogType.movies, page: page, limit: limit);
        return CatalogPage(
          items: _fromEntries(res.items, kind: MediaKind.movie),
          hasMore: res.hasMore,
        );
      case CatalogRowId.trendingShows:
        final res = await _client.getTrending(TraktCatalogType.shows, page: page, limit: limit);
        return CatalogPage(
          items: _fromEntries(res.items, kind: MediaKind.show),
          hasMore: res.hasMore,
        );
      case CatalogRowId.popularMovies:
        final res = await _client.getPopular(TraktCatalogType.movies, page: page, limit: limit);
        return CatalogPage(items: _fromMedia(res.items, MediaKind.movie), hasMore: res.hasMore);
      case CatalogRowId.popularShows:
        final res = await _client.getPopular(TraktCatalogType.shows, page: page, limit: limit);
        return CatalogPage(items: _fromMedia(res.items, MediaKind.show), hasMore: res.hasMore);
      case CatalogRowId.suggestedAnime:
      case CatalogRowId.airingAnime:
      case CatalogRowId.popularAnime:
      case CatalogRowId.trending:
      case CatalogRowId.upcomingMovies:
      case CatalogRowId.upcomingShows:
        throw ArgumentError('Trakt does not serve ${row.name}');
    }
  }

  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final res = await _client.searchCatalog(trimmed, limit: limit);
    return _fromEntries(res.items);
  }

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async =>
      external.hasAny ? CatalogItemIds.fromExternal(external) : null;

  @override
  Future<List<CatalogCastMember>> fetchCast(CatalogItem item, {int limit = 20}) async {
    final id = item.ids.trakt?.toString() ?? item.ids.slug ?? item.ids.imdb;
    if (id == null) return const [];
    final type = item.kind == MediaKind.movie ? TraktCatalogType.movies : TraktCatalogType.shows;
    final cast = await _client.getPeople(type, id);
    return [
      for (final entry in cast.take(limit))
        if (entry.person?.name case final String name when name.isNotEmpty)
          CatalogCastMember(
            name: name,
            secondary: entry.characters?.firstOrNull,
            imageUrl: entry.person?.images?.primaryHeadshot,
          ),
    ];
  }

  @override
  Future<List<CatalogItem>> fetchRelated(CatalogItem item, {int limit = 20}) async {
    final id = item.ids.trakt?.toString() ?? item.ids.slug ?? item.ids.imdb;
    if (id == null) return const [];
    final type = item.kind == MediaKind.movie ? TraktCatalogType.movies : TraktCatalogType.shows;
    return _fromMedia(await _client.getRelated(type, id, limit: limit), item.kind);
  }

  @override
  Future<WatchlistKeyPage> fetchWatchlistKeyPage(int page, int limit) async {
    final res = await _client.getWatchlist(page: page, limit: limit);
    return (
      groups: [for (final item in _fromEntries(res.items)) membershipKeysFor(item.kind, item.ids)],
      hasMore: res.hasMore,
    );
  }

  @override
  Future<void> performWatchlistMutation(MediaKind kind, CatalogItemIds ids, {required bool add}) async {
    final body = {
      kind == MediaKind.show ? 'shows' : 'movies': [
        {'ids': TraktIds(trakt: ids.trakt, slug: ids.slug, imdb: ids.imdb, tmdb: ids.tmdb, tvdb: ids.tvdb).toJson()},
      ],
    };
    add ? await _client.addToWatchlist(body) : await _client.removeFromWatchlist(body);
  }

  @override
  List<String> membershipKeysFor(MediaKind kind, CatalogItemIds ids) => [
    for (final key in ids.allKeys) '${kind.id}/$key',
  ];

  List<CatalogItem> _fromEntries(List<TraktCatalogEntry> entries, {MediaKind? kind}) => [
    for (final entry in entries)
      if (entry.media != null && _entryKind(entry, kind) != null && entry.media!.ids.hasAny)
        _toCatalogItem(entry.media!, _entryKind(entry, kind)!),
  ];

  List<CatalogItem> _fromMedia(List<TraktCatalogMedia> media, MediaKind kind) => [
    for (final m in media)
      if (m.ids.hasAny) _toCatalogItem(m, kind),
  ];

  /// Watchlist entries carry a `type` field; trending entries are typed by
  /// which wrapper key is present; fixed-kind endpoints pass [fixed].
  static MediaKind? _entryKind(TraktCatalogEntry entry, MediaKind? fixed) {
    if (fixed != null) return fixed;
    return switch (entry.type) {
      'movie' => MediaKind.movie,
      'show' => MediaKind.show,
      null => entry.isShow ? MediaKind.show : MediaKind.movie,
      _ => null, // seasons/episodes on the watchlist are not Explore rows
    };
  }

  /// Normalize Trakt's status strings. Movies' `released` maps to null —
  /// a "Released" chip on every movie is noise.
  static CatalogAirStatus? airStatusFor(String? status) => switch (status) {
    'returning series' || 'continuing' => CatalogAirStatus.airing,
    'ended' => CatalogAirStatus.ended,
    'canceled' => CatalogAirStatus.canceled,
    'in production' ||
    'post production' ||
    'planned' ||
    'upcoming' ||
    'pilot' ||
    'rumored' => CatalogAirStatus.upcoming,
    _ => null,
  };

  CatalogItem _toCatalogItem(TraktCatalogMedia m, MediaKind kind) => CatalogItem(
    source: CatalogSourceId.trakt,
    kind: kind,
    title: m.title ?? '',
    year: m.year,
    overview: m.overview,
    runtimeMinutes: m.runtime,
    rating: m.rating,
    votes: m.votes,
    genres: m.genres,
    certification: m.certification,
    trailerUrl: m.trailer,
    airStatus: airStatusFor(m.status),
    episodeCount: m.airedEpisodes,
    network: m.network,
    ids: CatalogItemIds(trakt: m.ids.trakt, slug: m.ids.slug, imdb: m.ids.imdb, tmdb: m.ids.tmdb, tvdb: m.ids.tvdb),
    posterUrl: m.images?.primaryPoster,
    backdropUrl: m.images?.primaryBackdrop,
  );

  @override
  void dispose() {
    disposeWatchlistMachinery();
  }
}
