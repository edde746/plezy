import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../media/media_kind.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_item.dart';
import '../../utils/app_logger.dart';
import '../../utils/external_ids.dart';
import '../settings_service.dart';
import 'catalog_source.dart';

/// [CatalogSource] backed by TMDB (The Movie Database) REST API.
class TmdbCatalogSource implements CatalogSource {
  static const String _defaultApiKey = 'b074d2847c2d9e6833c873f1d9321f8c';
  final WatchlistChangeNotifier _watchlistChanges = WatchlistChangeNotifier();

  TmdbCatalogSource();

  @override
  CatalogSourceId get id => CatalogSourceId.tmdb;

  @override
  String get displayName => 'TMDB';

  @override
  List<CatalogRowId> get supportedRows => const [
        CatalogRowId.trendingMovies,
        CatalogRowId.trendingShows,
        CatalogRowId.popularMovies,
        CatalogRowId.popularShows,
        CatalogRowId.upcomingMovies,
        CatalogRowId.upcomingShows,
      ];

  @override
  bool get supportsWatchlist => false;

  @override
  Listenable get watchlistChanges => _watchlistChanges;

  String get _apiKey {
    final custom = SettingsService.instance.read(SettingsService.tmdbApiKey);
    if (custom != null && custom.trim().isNotEmpty) {
      return custom.trim();
    }
    return _defaultApiKey;
  }

  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) async {
    final endpoint = switch (row) {
      CatalogRowId.trendingMovies => '/trending/movie/day',
      CatalogRowId.trendingShows => '/trending/tv/day',
      CatalogRowId.popularMovies => '/movie/popular',
      CatalogRowId.popularShows => '/tv/popular',
      CatalogRowId.upcomingMovies => '/movie/upcoming',
      CatalogRowId.upcomingShows => '/tv/on_the_air',
      _ => throw ArgumentError('TMDB does not serve ${row.name}'),
    };

    final isMovie = row == CatalogRowId.trendingMovies ||
        row == CatalogRowId.popularMovies ||
        row == CatalogRowId.upcomingMovies;

    try {
      final uri = Uri.parse('https://api.themoviedb.org/3$endpoint?api_key=$_apiKey&page=$page');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        return const CatalogPage(items: []);
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? [];
      final totalPages = (data['total_pages'] as int?) ?? 1;

      final items = <CatalogItem>[];
      for (final r in results) {
        if (r is Map<String, dynamic>) {
          final item = _parseItem(r, defaultIsMovie: isMovie);
          if (item != null) items.add(item);
        }
      }
      return CatalogPage(
        items: items,
        hasMore: page < totalPages,
        totalResults: data['total_results'] as int?,
      );
    } catch (e) {
      appLogger.w('TMDB: fetchRow ${row.name} failed', error: e);
      return const CatalogPage(items: []);
    }
  }

  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async {
    if (query.trim().length < 2) return const [];
    try {
      final uri = Uri.parse(
        'https://api.themoviedb.org/3/search/multi?api_key=$_apiKey&query=${Uri.encodeComponent(query.trim())}&page=1',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return const [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? [];

      final items = <CatalogItem>[];
      for (final r in results) {
        if (r is Map<String, dynamic>) {
          final mediaType = r['media_type'] as String?;
          if (mediaType != 'movie' && mediaType != 'tv') continue;
          final item = _parseItem(r, defaultIsMovie: mediaType == 'movie');
          if (item != null) items.add(item);
        }
      }
      return items.take(limit).toList();
    } catch (e) {
      appLogger.w('TMDB: search failed', error: e);
      return const [];
    }
  }

  @override
  Future<CatalogDetail> fetchDetail(CatalogItem item, {int castLimit = 20, int relatedLimit = 20}) async {
    final tmdbId = item.ids.tmdb;
    if (tmdbId == null) return CatalogDetail(item: item);

    final isMovie = item.kind == MediaKind.movie;
    final path = isMovie ? '/movie/$tmdbId' : '/tv/$tmdbId';

    try {
      final uri = Uri.parse(
        'https://api.themoviedb.org/3$path?api_key=$_apiKey&append_to_response=credits,recommendations,external_ids',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return CatalogDetail(item: item);

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      // Extracted IDs
      final extIds = data['external_ids'] as Map<String, dynamic>?;
      final imdbId = extIds?['imdb_id'] as String?;
      final tvdbId = extIds?['tvdb_id'] as int?;

      final enrichedIds = CatalogItemIds(
        tmdb: tmdbId,
        imdb: imdbId != null && imdbId.isNotEmpty ? imdbId : item.ids.imdb,
        tvdb: tvdbId ?? item.ids.tvdb,
      );

      final overview = (data['overview'] as String?) ?? item.overview;
      final voteAverage = (data['vote_average'] as num?)?.toDouble() ?? item.rating;

      final parsedDetail = _parseItem(data, defaultIsMovie: isMovie);
      final detailItem = CatalogItem(
        source: item.source,
        kind: item.kind,
        title: parsedDetail?.title ?? item.title,
        year: parsedDetail?.year ?? item.year,
        overview: overview,
        rating: voteAverage,
        ids: enrichedIds,
        posterUrl: parsedDetail?.posterUrl ?? item.posterUrl,
        backdropUrl: parsedDetail?.backdropUrl ?? item.backdropUrl,
        posterVariants: parsedDetail?.posterVariants ?? item.posterVariants,
        backdropVariants: parsedDetail?.backdropVariants ?? item.backdropVariants,
      );
      final enrichedItem = item.enrichedWith(detailItem);

      // Cast
      final credits = data['credits'] as Map<String, dynamic>?;
      final rawCast = (credits?['cast'] as List<dynamic>?) ?? [];
      final cast = <CatalogCastMember>[];
      for (final c in rawCast.take(castLimit)) {
        if (c is Map<String, dynamic>) {
          final name = c['name'] as String?;
          final character = c['character'] as String?;
          final profilePath = c['profile_path'] as String?;
          if (name != null && name.isNotEmpty) {
            cast.add(CatalogCastMember(
              name: name,
              secondary: character,
              imageUrl: tmdbImageUrl(profilePath, 'w300'),
            ));
          }
        }
      }

      // Recommendations / Related
      final recsData = data['recommendations'] as Map<String, dynamic>?;
      final rawRecs = (recsData?['results'] as List<dynamic>?) ?? [];
      final related = <CatalogItem>[];
      for (final r in rawRecs.take(relatedLimit)) {
        if (r is Map<String, dynamic>) {
          final relItem = _parseItem(r, defaultIsMovie: isMovie);
          if (relItem != null) related.add(relItem);
        }
      }

      return CatalogDetail(
        item: enrichedItem,
        cast: cast,
        related: related,
      );
    } catch (e) {
      appLogger.w('TMDB: fetchDetail failed for $tmdbId', error: e);
      return CatalogDetail(item: item);
    }
  }

  CatalogItem? _parseItem(Map<String, dynamic> r, {required bool defaultIsMovie}) {
    final id = r['id'] as int?;
    if (id == null) return null;

    final mediaType = (r['media_type'] as String?) ?? (defaultIsMovie ? 'movie' : 'tv');
    final isMovie = mediaType == 'movie';

    final title = (r[isMovie ? 'title' : 'name'] as String?) ??
        (r[isMovie ? 'original_title' : 'original_name'] as String?) ??
        '';
    if (title.isEmpty) return null;

    final dateStr = (r[isMovie ? 'release_date' : 'first_air_date'] as String?) ?? '';
    int? year;
    if (dateStr.length >= 4) {
      year = int.tryParse(dateStr.substring(0, 4));
    }

    final posterPath = r['poster_path'] as String?;
    final backdropPath = r['backdrop_path'] as String?;
    final overview = r['overview'] as String?;
    final voteAvg = (r['vote_average'] as num?)?.toDouble();

    return CatalogItem(
      source: CatalogSourceId.tmdb,
      kind: isMovie ? MediaKind.movie : MediaKind.show,
      title: title,
      ids: CatalogItemIds(tmdb: id),
      year: year,
      overview: overview,
      rating: voteAvg != null && voteAvg > 0 ? voteAvg : null,
      posterUrl: tmdbImageUrl(posterPath, 'w600_and_h900_bestv2'),
      backdropUrl: tmdbImageUrl(backdropPath, 'w1920_and_h800_multi_faces'),
      posterVariants: tmdbPosterVariants(posterPath),
      backdropVariants: tmdbBackdropVariants(backdropPath),
    );
  }

  static String? tmdbImageUrl(String? path, String size) =>
      path == null || path.isEmpty ? null : 'https://image.tmdb.org/t/p/$size$path';

  static Map<int, String>? tmdbPosterVariants(String? path) {
    if (path == null || path.isEmpty) return null;
    return {
      92: tmdbImageUrl(path, 'w92')!,
      154: tmdbImageUrl(path, 'w154')!,
      185: tmdbImageUrl(path, 'w185')!,
      342: tmdbImageUrl(path, 'w342')!,
      500: tmdbImageUrl(path, 'w500')!,
      600: tmdbImageUrl(path, 'w600_and_h900_bestv2')!,
      780: tmdbImageUrl(path, 'w780')!,
    };
  }

  static Map<int, String>? tmdbBackdropVariants(String? path) {
    if (path == null || path.isEmpty) return null;
    return {
      300: tmdbImageUrl(path, 'w300')!,
      780: tmdbImageUrl(path, 'w780')!,
      1280: tmdbImageUrl(path, 'w1280')!,
      1920: tmdbImageUrl(path, 'w1920_and_h800_multi_faces')!,
    };
  }

  @override
  Future<void> ensureWatchlistLoaded() async {}

  @override
  bool? isOnWatchlist(MediaKind kind, CatalogItemIds ids) => false;

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async {
    if (external.tmdb != null) return CatalogItemIds(tmdb: external.tmdb);
    return null;
  }

  @override
  Future<void> addToWatchlist(MediaKind kind, CatalogItemIds ids) async {}

  @override
  Future<void> removeFromWatchlist(MediaKind kind, CatalogItemIds ids) async {}

  @override
  void dispose() {
    _watchlistChanges.dispose();
  }
}
