import '../../media/media_kind.dart';
import '../../models/catalog/catalog_item.dart';
import '../../utils/external_ids.dart';
import '../../utils/json_utils.dart';
import '../trackers/mdblist/mdblist_client.dart';
import 'catalog_source.dart';
import 'catalog_watchlist_machinery.dart';

/// MDBList watchlist/search adapter. The tracker owns [_client].
class MdblistCatalogSource with CatalogWatchlistMachinery implements CatalogSource {
  MdblistCatalogSource(this._client);

  final MdblistClient _client;

  @override
  CatalogSourceId get id => CatalogSourceId.mdblist;

  @override
  String get displayName => 'MDBList';

  @override
  List<CatalogRowId> get supportedRows => const [CatalogRowId.watchlist];

  @override
  bool get supportsWatchlist => true;

  @override
  String get watchlistLogLabel => 'MDBList: watchlist';

  @override
  int get watchlistPageLimit => 250;

  @override
  int get watchlistMaxPages => 4;

  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) async {
    if (row != CatalogRowId.watchlist) throw ArgumentError('MDBList does not serve ${row.name}');
    final result = await _fetchWatchlistPage(page, limit);
    return CatalogPage(items: result.items, hasMore: result.hasMore, totalResults: result.total);
  }

  Future<({List<CatalogItem> items, bool hasMore, int? total})> _fetchWatchlistPage(int page, int limit) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedLimit = limit < 1 ? 1 : limit;
    final response = await _client.getWatchlist(limit: normalizedLimit, offset: (normalizedPage - 1) * normalizedLimit);
    final items = [
      ..._itemsFrom(response['movies'], MediaKind.movie),
      ..._itemsFrom(response['shows'], MediaKind.show),
    ];
    final pagination = response['pagination'];
    final pageData = pagination is Map ? pagination : const <Object?, Object?>{};
    final hasMore = flexibleBoolNullable(pageData['has_more']) ?? items.length >= normalizedLimit;
    final totalMovies = flexibleInt(pageData['total_movies']);
    final totalShows = flexibleInt(pageData['total_shows']);
    final total = totalMovies == null && totalShows == null ? null : (totalMovies ?? 0) + (totalShows ?? 0);
    return (items: items, hasMore: hasMore, total: total);
  }

  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || limit <= 0) return const [];
    final response = await _client.searchCatalog(trimmed, limit: limit);
    return [
      for (final entry in flexibleMapList(response['search']))
        if (_kindFor(entry['type']) case final kind?) ?_itemFor(entry, kind),
    ].take(limit).toList(growable: false);
  }

  @override
  Future<CatalogDetail> fetchDetail(CatalogItem item, {int castLimit = 20, int relatedLimit = 20}) async =>
      CatalogDetail(item: item);

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async {
    if (kind != MediaKind.movie && kind != MediaKind.show) return null;
    return external.hasCatalogIds ? CatalogItemIds.fromExternal(external) : null;
  }

  @override
  Future<WatchlistKeyPage> fetchWatchlistKeyPage(int page, int limit) async {
    final result = await _fetchWatchlistPage(page, limit);
    return (groups: [for (final item in result.items) membershipKeysFor(item.kind, item.ids)], hasMore: result.hasMore);
  }

  @override
  Future<void> performWatchlistMutation(MediaKind kind, CatalogItemIds ids, {required bool add}) async {
    if (kind != MediaKind.movie && kind != MediaKind.show) {
      throw ArgumentError('MDBList watchlists only accept movies and shows');
    }
    final mutationIds = <String, dynamic>{
      if (ids.imdb != null) 'imdb': ids.imdb,
      if (ids.tmdb != null) 'tmdb': ids.tmdb,
      if (ids.tvdb != null) 'tvdb': ids.tvdb,
      if (ids.trakt != null) 'trakt': ids.trakt,
    };
    if (mutationIds.isEmpty) throw ArgumentError('MDBList watchlist mutation requires an external id');
    final body = {
      kind == MediaKind.show ? 'shows' : 'movies': [mutationIds],
    };
    if (add) {
      await _client.addToWatchlist(body);
    } else {
      await _client.removeFromWatchlist(body);
    }
  }

  List<CatalogItem> _itemsFrom(Object? value, MediaKind kind) => [
    for (final entry in flexibleMapList(value)) ?_itemFor(entry, kind),
  ];

  CatalogItem? _itemFor(Map<String, dynamic> entry, MediaKind kind) {
    final title = _string(entry['title']);
    final ids = _idsFor(entry);
    if (title == null || !ids.hasAny) return null;
    final score = flexibleDouble(entry['score']);
    return CatalogItem(
      source: CatalogSourceId.mdblist,
      kind: kind,
      title: title,
      year: flexibleInt(entry['year'] ?? entry['release_year']),
      overview: _string(entry['description']),
      rating: score == null || score < 0 || score > 100 ? null : score / 10,
      genres: flexibleStringList(entry['genres']),
      ids: ids,
      posterUrl: _string(entry['poster']),
      addedAt: entry['watchlist_at'] is String ? DateTime.tryParse(entry['watchlist_at'] as String) : null,
    );
  }

  CatalogItemIds _idsFor(Map<String, dynamic> entry) {
    final rawIds = entry['ids'];
    final ids = rawIds is Map ? rawIds : const <Object?, Object?>{};
    return CatalogItemIds(
      trakt: flexibleInt(ids['trakt'] ?? ids['traktid']),
      imdb: _string(ids['imdb'] ?? ids['imdbid'] ?? entry['imdb_id']),
      tmdb: flexibleInt(ids['tmdb'] ?? ids['tmdbid'] ?? entry['id']),
      tvdb: flexibleInt(ids['tvdb'] ?? ids['tvdbid'] ?? entry['tvdb_id']),
    );
  }

  static String? _string(Object? value) => value is String && value.isNotEmpty ? value : null;

  static MediaKind? _kindFor(Object? type) => switch (type) {
    'movie' => MediaKind.movie,
    'show' || 'series' => MediaKind.show,
    _ => null,
  };

  @override
  void dispose() => disposeWatchlistMachinery();
}
