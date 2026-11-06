import '../../media/media_kind.dart';
import '../../media/media_rating.dart';
import '../../models/catalog/catalog_item.dart';
import '../../utils/external_ids.dart';
import '../../utils/json_utils.dart';
import '../../utils/app_logger.dart';
import '../trackers/mdblist/mdblist_client.dart';
import 'catalog_source.dart';
import 'catalog_watchlist_machinery.dart';

/// Raw watchlist envelope shared by the row and membership projections.
typedef _WatchlistEnvelope = ({Object? movies, Object? shows, Map<Object?, Object?> pageData, int limit});

/// MDBList watchlist/search adapter. The tracker owns [_client].
class MdblistCatalogSource with CatalogWatchlistMachinery implements CatalogSource, CatalogCommunityRatings {
  MdblistCatalogSource(this._client);

  final MdblistClient _client;

  /// MDBList `ratings[].source` → our source key and the scale MDBList reports that source's `value` on.
  static const Map<String, ({String key, int scale})> _ratingSources = {
    'imdb': (key: 'imdb', scale: 10),
    'tmdb': (key: 'tmdb', scale: 100),
    'tomatoes': (key: 'rottenTomatoesCritic', scale: 100),
    // The Popcornmeter; MDBList's older API called it `tomatoesaudience`.
    'popcorn': (key: 'rottenTomatoesAudience', scale: 100),
    'tomatoesaudience': (key: 'rottenTomatoesAudience', scale: 100),
    'metacritic': (key: 'metacritic', scale: 100),
    'letterboxd': (key: 'letterboxd', scale: 5),
    'trakt': (key: 'trakt', scale: 100),
    'myanimelist': (key: 'mal', scale: 10),
  };

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
    final envelope = await _fetchWatchlistEnvelope(page, limit);
    final items = [..._itemsFrom(envelope.movies, MediaKind.movie), ..._itemsFrom(envelope.shows, MediaKind.show)];
    final totalMovies = flexibleInt(envelope.pageData['total_movies']);
    final totalShows = flexibleInt(envelope.pageData['total_shows']);
    final total = totalMovies == null && totalShows == null ? null : (totalMovies ?? 0) + (totalShows ?? 0);
    return CatalogPage(items: items, hasMore: _hasMore(envelope, items.length), totalResults: total);
  }

  Future<_WatchlistEnvelope> _fetchWatchlistEnvelope(int page, int limit) async {
    final normalizedPage = page < 1 ? 1 : page;
    final normalizedLimit = limit < 1 ? 1 : limit;
    final response = await _client.getWatchlist(limit: normalizedLimit, offset: (normalizedPage - 1) * normalizedLimit);
    final pagination = response['pagination'];
    return (
      movies: response['movies'],
      shows: response['shows'],
      pageData: pagination is Map ? pagination : const <Object?, Object?>{},
      limit: normalizedLimit,
    );
  }

  static bool _hasMore(_WatchlistEnvelope envelope, int rows) =>
      flexibleBoolNullable(envelope.pageData['has_more']) ?? rows >= envelope.limit;

  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || limit <= 0) return const [];
    final response = await _client.searchCatalog(trimmed, limit: limit);
    final items = [
      for (final entry in flexibleMapList(response['search']))
        if (_kindFor(entry['type']) case final kind?) ?_itemFor(entry, kind),
    ].take(limit).toList(growable: false);
    final groups = <(String, MediaKind), List<CatalogItem>>{};
    for (final item in items) {
      final lookup = _searchLookup(item);
      if (lookup != null) (groups[(lookup.$1, item.kind)] ??= []).add(item);
    }
    final hydrated = <String, CatalogItem>{};
    await Future.wait(
      groups.entries.map((group) async {
        final (provider, kind) = group.key;
        final ids = {for (final item in group.value) _searchLookup(item)!.$2}.toList();
        // Normal searches fit one batch per kind. Respect the API ceiling even
        // when a caller explicitly asks for a larger result set.
        for (var start = 0; start < ids.length; start += 200) {
          try {
            final batch = await _client.getMediaInfoBatch(
              provider,
              kind == MediaKind.movie ? 'movie' : 'show',
              ids.skip(start).take(200).toList(),
            );
            for (final info in batch) {
              if (_kindFor(info.data['type']) != kind) continue;
              final candidate = _itemFor(info.data, kind, isMediaInfo: true, isBatch: info.isBatch);
              if (candidate == null) continue;
              for (final original in group.value) {
                if (_sameIdentity(original, candidate)) {
                  hydrated[original.identityKey] = original.enrichedWith(candidate);
                }
              }
            }
          } catch (error) {
            // Discovery still works when hydration is unavailable or rate limited.
            appLogger.d('MDBList: search metadata unavailable', error: error);
            break;
          }
        }
      }),
    );
    return [for (final item in items) hydrated[item.identityKey] ?? item];
  }

  @override
  Future<CatalogDetail> fetchDetail(CatalogItem item, {int castLimit = 20, int relatedLimit = 20}) async {
    final lookup = _lookup(item.kind, item.ids);
    if (lookup == null) return CatalogDetail(item: item);
    final info = await _client.getMediaInfo(lookup.$1, lookup.$2, lookup.$3, includeRecommendations: true);
    if (info == null || _kindFor(info.data['type']) != item.kind) return CatalogDetail(item: item);
    final candidate = _itemFor(info.data, item.kind, isMediaInfo: true);
    if (candidate == null || !_sameIdentity(item, candidate)) return CatalogDetail(item: item);
    return CatalogDetail(
      item: item.enrichedWith(candidate),
      related: [
        for (final raw in flexibleMapList(info.data['recommendations']))
          if (_kindFor(raw['mediatype'] ?? raw['type']) case final kind?) ?_itemFor(raw, kind),
      ].take(relatedLimit < 0 ? 0 : relatedLimit).toList(),
    );
  }

  static (String, Object)? _searchLookup(CatalogItem item) => switch (item.ids) {
    CatalogItemIds(:final tmdb?) => ('tmdb', tmdb),
    CatalogItemIds(:final imdb?) => ('imdb', imdb),
    CatalogItemIds(:final tvdb?) when item.kind == MediaKind.show => ('tvdb', tvdb),
    _ => null,
  };

  static bool _sameIdentity(CatalogItem a, CatalogItem b) {
    if (a.kind != b.kind) return false;
    var shared = false;
    for (final pair in [
      (a.ids.imdb, b.ids.imdb),
      (a.ids.tmdb, b.ids.tmdb),
      (a.ids.tvdb, b.ids.tvdb),
      (a.ids.trakt, b.ids.trakt),
    ]) {
      if (pair.$1 == null || pair.$2 == null) continue;
      if (pair.$1 != pair.$2) return false;
      shared = true;
    }
    return shared;
  }

  /// Every score MDBList aggregates for the title (`/{provider}/{movie|show|any}/{id}`, looked up by IMDb, then
  /// TMDB, a show's TVDB, then MAL id), each moved off its source's scale. MDBList's own `score` is not one.
  @override
  Future<List<MediaRatingSource>> fetchCommunityRatings(MediaKind kind, CatalogItemIds ids) async {
    final lookup = _lookup(kind, ids);
    if (lookup == null) return const [];
    final info = await _client.getMediaInfo(lookup.$1, lookup.$2, lookup.$3);
    return info == null ? const [] : _ratingsFor(info.data['ratings'], isBatch: info.isBatch);
  }

  static (String, String, String)? _lookup(MediaKind kind, CatalogItemIds ids) {
    final type = switch (kind) {
      MediaKind.movie => 'movie',
      MediaKind.show => 'show',
      _ => null,
    };
    if (type == null) return null;
    return switch (ids) {
      CatalogItemIds(:final imdb?) => ('imdb', type, imdb),
      CatalogItemIds(:final tmdb?) => ('tmdb', type, '$tmdb'),
      CatalogItemIds(:final tvdb?) when kind == MediaKind.show => ('tvdb', 'show', '$tvdb'),
      CatalogItemIds(:final mal?) => ('mal', 'any', '$mal'),
      _ => null,
    };
  }

  List<MediaRatingSource> _ratingsFor(Object? raw, {bool isBatch = false}) {
    return [
      for (final rating in flexibleMapList(raw))
        if (_ratingSources[rating['source']] case final source?)
          ?MediaRatingSource.fromScale(
            source.key,
            flexibleDouble(rating['score']) ?? flexibleDouble(rating['value']),
            // Batch Letterboxd values are 0–10; single-title values are 0–5.
            // The normalized 0–100 score is consistent across both endpoints.
            scale: flexibleDouble(rating['score']) != null
                ? 100
                : isBatch && source.key == 'letterboxd'
                ? 10
                : source.scale,
            votes: flexibleInt(rating['votes']),
          ),
    ];
  }

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async {
    if (kind != MediaKind.movie && kind != MediaKind.show) return null;
    return external.hasCatalogIds ? CatalogItemIds.fromExternal(external) : null;
  }

  @override
  Future<WatchlistKeyPage> fetchWatchlistKeyPage(int page, int limit) async {
    final envelope = await _fetchWatchlistEnvelope(page, limit);
    final groups = [
      ..._membershipFrom(envelope.movies, MediaKind.movie),
      ..._membershipFrom(envelope.shows, MediaKind.show),
    ];
    return (groups: groups, hasMore: _hasMore(envelope, groups.length));
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

  List<List<String>> _membershipFrom(Object? value, MediaKind kind) {
    final groups = <List<String>>[];
    for (final entry in flexibleMapList(value)) {
      final ids = _idsFor(entry);
      if (_string(entry['title']) == null || !ids.hasAny) continue;
      groups.add(membershipKeysFor(kind, ids));
    }
    return groups;
  }

  CatalogItem? _itemFor(Map<String, dynamic> entry, MediaKind kind, {bool isMediaInfo = false, bool isBatch = false}) {
    final title = _string(entry['title']);
    final ids = _idsFor(entry, allowTopLevelId: !isMediaInfo);
    if (title == null || !ids.hasAny) return null;
    final score = flexibleDouble(entry['score']);
    return CatalogItem(
      source: CatalogSourceId.mdblist,
      kind: kind,
      title: title,
      year: flexibleInt(entry['year'] ?? entry['release_year']),
      overview: _string(entry['description']),
      // MDBList's show runtime can be a series total, not an episode runtime.
      runtimeMinutes: kind == MediaKind.movie ? flexibleInt(entry['runtime']) : null,
      rating: score == null || score < 0 || score > 100 ? null : score / 10,
      ratings: entry['ratings'] == null ? null : _ratingsFor(entry['ratings'], isBatch: isBatch),
      genres: entry['genres'] == null
          ? null
          : flexibleStringList(entry['genres']) ??
                [for (final genre in flexibleMapList(entry['genres'])) ?_string(genre['title'] ?? genre['name'])],
      certification: _string(entry['certification']),
      trailerUrl: _string(entry['trailer']),
      airStatus: _airStatusFor(entry['status']),
      network: _string(entry['network']),
      releaseDate: DateTime.tryParse('${entry['released'] ?? entry['release_date']}'),
      ids: ids,
      posterUrl: _string(entry['poster']),
      backdropUrl: _string(entry['backdrop']),
      addedAt: entry['watchlist_at'] is String ? DateTime.tryParse(entry['watchlist_at'] as String) : null,
    );
  }

  CatalogItemIds _idsFor(Map<String, dynamic> entry, {bool allowTopLevelId = true}) {
    final rawIds = entry['ids'];
    final ids = rawIds is Map ? rawIds : const <Object?, Object?>{};
    return CatalogItemIds(
      trakt: flexibleInt(ids['trakt'] ?? ids['traktid']),
      imdb: _string(ids['imdb'] ?? ids['imdbid'] ?? entry['imdb_id']),
      tmdb: flexibleInt(ids['tmdb'] ?? ids['tmdbid'] ?? (allowTopLevelId ? entry['id'] : null)),
      tvdb: flexibleInt(ids['tvdb'] ?? ids['tvdbid'] ?? entry['tvdb_id']),
    );
  }

  static String? _string(Object? value) => value is String && value.isNotEmpty ? value : null;

  static CatalogAirStatus? _airStatusFor(Object? value) => switch (_string(value)?.trim().toLowerCase()) {
    'returning series' || 'continuing' => CatalogAirStatus.airing,
    'ended' => CatalogAirStatus.ended,
    'canceled' || 'cancelled' => CatalogAirStatus.canceled,
    'in production' ||
    'post production' ||
    'planned' ||
    'upcoming' ||
    'pilot' ||
    'rumored' => CatalogAirStatus.upcoming,
    _ => null,
  };

  static MediaKind? _kindFor(Object? type) => switch (type) {
    'movie' => MediaKind.movie,
    'show' || 'series' => MediaKind.show,
    _ => null,
  };

  @override
  void dispose() => disposeWatchlistMachinery();
}
