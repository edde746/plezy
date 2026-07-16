import 'package:flutter/foundation.dart';

import '../../media/media_kind.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_item.dart';
import '../../models/seerr/seerr_details.dart';
import '../../models/seerr/seerr_media.dart';
import '../../models/seerr/seerr_page.dart';
import '../../utils/external_ids.dart';
import '../seerr/seerr_client.dart';
import '../seerr/seerr_constants.dart';
import 'catalog_source.dart';

/// [CatalogSource] backed by a Seerr instance's TMDB-based discover API.
///
/// Wraps the catalog [SeerrClient] owned by `SeerrAccountProvider` (not owned
/// here — never disposed by this class). Seerr has no watchlist; its
/// contribution besides discovery rows is the request flow, which the
/// request surfaces reach through [client] directly.
class SeerrCatalogSource implements CatalogSource {
  final SeerrClient client;
  final WatchlistChangeNotifier _watchlistChanges = WatchlistChangeNotifier();

  SeerrCatalogSource(this.client);

  @override
  CatalogSourceId get id => CatalogSourceId.seerr;

  @override
  String get displayName => 'Seerr';

  @override
  List<CatalogRowId> get supportedRows => const [
    CatalogRowId.trending,
    CatalogRowId.popularMovies,
    CatalogRowId.popularShows,
    CatalogRowId.upcomingMovies,
    CatalogRowId.upcomingShows,
  ];

  @override
  bool get supportsWatchlist => false;

  /// Whether the signed-in user may request titles of [kind] — gates the
  /// detail-screen Request action.
  bool canRequest(MediaKind kind) => seerrHasPermission(client.session.permissions, [
    SeerrPermission.request,
    kind == MediaKind.movie ? SeerrPermission.requestMovie : SeerrPermission.requestTv,
  ]);

  @override
  Listenable get watchlistChanges => _watchlistChanges;

  /// Seerr pages are a fixed 20 items; [limit] cannot be honored, so callers
  /// get pages of 20 with [CatalogPage.hasMore] from `totalPages`.
  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) async {
    final res = await switch (row) {
      CatalogRowId.trending => client.getTrending(page: page),
      CatalogRowId.popularMovies => client.getPopularMovies(page: page),
      CatalogRowId.popularShows => client.getPopularTv(page: page),
      CatalogRowId.upcomingMovies => client.getUpcomingMovies(page: page),
      CatalogRowId.upcomingShows => client.getUpcomingTv(page: page),
      CatalogRowId.watchlist ||
      CatalogRowId.recommendedMovies ||
      CatalogRowId.recommendedShows ||
      CatalogRowId.trendingMovies ||
      CatalogRowId.trendingShows ||
      CatalogRowId.suggestedAnime ||
      CatalogRowId.airingAnime ||
      CatalogRowId.popularAnime => throw ArgumentError('Seerr does not serve ${row.name}'),
    };
    return _toPage(res);
  }

  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final page = await client.search(trimmed);
    return _toPage(page).items;
  }

  @override
  Future<List<CatalogItem>> fetchRelated(CatalogItem item, {int limit = 20}) async {
    final tmdbId = item.ids.tmdb;
    if (tmdbId == null) return const [];
    final page = item.kind == MediaKind.movie
        ? await client.getMovieRecommendations(tmdbId)
        : await client.getTvRecommendations(tmdbId);
    return _toPage(page).items.take(limit).toList();
  }

  /// Seerr requests key on TMDB ids, so any library item carrying one is in
  /// scope; the watchlist action stays hidden regardless
  /// ([supportsWatchlist] is false).
  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async =>
      external.tmdb == null ? null : CatalogItemIds(tmdb: external.tmdb, imdb: external.imdb, tvdb: external.tvdb);

  @override
  Future<List<CatalogCastMember>> fetchCast(CatalogItem item, {int limit = 20}) async {
    final tmdbId = item.ids.tmdb;
    if (tmdbId == null) return const [];
    final SeerrCredits? credits;
    if (item.kind == MediaKind.movie) {
      credits = (await client.getMovie(tmdbId)).credits;
    } else {
      credits = (await client.getTv(tmdbId)).credits;
    }
    return [
      for (final member in (credits?.cast ?? const <SeerrCastMember>[]).take(limit))
        if (member.name case final String name when name.isNotEmpty)
          CatalogCastMember(
            name: name,
            secondary: member.character,
            imageUrl: tmdbImageUrl(member.profilePath, 'w300'),
          ),
    ];
  }

  // Seerr has no watchlist: membership is always unknown and mutations are
  // programming errors (the action is hidden when supportsWatchlist is false).

  @override
  Future<void> ensureWatchlistLoaded() => Future.value();

  @override
  bool? isOnWatchlist(MediaKind kind, CatalogItemIds ids) => null;

  @override
  Future<void> addToWatchlist(MediaKind kind, CatalogItemIds ids) => throw UnsupportedError('Seerr has no watchlist');

  @override
  Future<void> removeFromWatchlist(MediaKind kind, CatalogItemIds ids) =>
      throw UnsupportedError('Seerr has no watchlist');

  CatalogPage _toPage(SeerrPage<SeerrMedia> page) => CatalogPage(
    items: [
      for (final m in page.items)
        if (m.displayTitle.isNotEmpty) _toCatalogItem(m),
    ],
    hasMore: page.hasMore,
  );

  CatalogItem _toCatalogItem(SeerrMedia m) => CatalogItem(
    source: CatalogSourceId.seerr,
    kind: m.isMovie ? MediaKind.movie : MediaKind.show,
    title: m.displayTitle,
    year: m.year,
    overview: m.overview,
    rating: m.voteAverage,
    votes: m.voteCount,
    ids: CatalogItemIds(tmdb: m.id),
    posterUrl: tmdbImageUrl(m.posterPath, 'w600_and_h900_bestv2'),
    backdropUrl: tmdbImageUrl(m.backdropPath, 'w1920_and_h800_multi_faces'),
  );

  /// Seerr serves TMDB relative paths (`/abc.jpg`); images come straight off
  /// the TMDB CDN at the same sizes the Seerr web UI uses.
  static String? tmdbImageUrl(String? path, String size) =>
      path == null || path.isEmpty ? null : 'https://image.tmdb.org/t/p/$size$path';

  @override
  void dispose() {
    _watchlistChanges.dispose();
  }
}
