import '../../media/media_rating.dart';
import '../../media/media_kind.dart';
import '../../models/catalog/catalog_metadata.dart';
import '../../models/catalog/catalog_item.dart';
import '../../models/simkl/simkl_all_items_entry.dart';
import '../../models/simkl/simkl_best_item.dart';
import '../../models/simkl/simkl_detail.dart';
import '../../models/simkl/simkl_ids.dart';
import '../../models/simkl/simkl_images.dart';
import '../../models/simkl/simkl_recommendation.dart';
import '../../models/simkl/simkl_rating.dart';
import '../../models/simkl/simkl_search_result.dart';
import '../../models/simkl/simkl_trending_item.dart';
import '../../utils/country_codes.dart';
import '../../utils/external_ids.dart';
import '../trackers/simkl/simkl_client.dart';
import '../trackers/simkl/simkl_constants.dart';
import '../trackers/future_coalescer.dart';
import '../../utils/trailer_urls.dart';
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
  final Set<int> _animeIds = {};
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
    'premiere' || 'tba' => CatalogAirStatus.upcoming,
    _ => null,
  };

  static MediaKind _kindFor(SimklCatalogType type, {String? animeType}) {
    if (type == SimklCatalogType.movies) return MediaKind.movie;
    if (type == SimklCatalogType.anime && animeType?.toLowerCase() == 'movie') return MediaKind.movie;
    return MediaKind.show;
  }

  static CatalogFormat? _formatFor(SimklCatalogType type, String? raw) {
    if (type != SimklCatalogType.anime) return null;
    return switch (raw?.trim().toLowerCase()) {
      'tv' => CatalogFormat.tv,
      'tv short' || 'tv_short' || 'tv-short' => CatalogFormat.tvShort,
      'movie' => CatalogFormat.movie,
      'special' => CatalogFormat.special,
      'ova' => CatalogFormat.ova,
      'ona' => CatalogFormat.ona,
      'music' || 'music video' => CatalogFormat.music,
      null || '' => null,
      _ => CatalogFormat.other,
    };
  }

  SimklCatalogType _detailTypeFor(CatalogItem item) {
    if (item.format != null || _animeIds.contains(item.ids.simkl) || item.ids.mal != null || item.ids.anilist != null) {
      return SimklCatalogType.anime;
    }
    return item.kind == MediaKind.movie ? SimklCatalogType.movies : SimklCatalogType.tv;
  }

  void _rememberType(SimklCatalogType type, SimklIds ids) {
    final simklId = ids.simkl;
    if (type == SimklCatalogType.anime && simklId != null) _animeIds.add(simklId);
  }

  static List<MediaRatingSource>? _ratingsFor(SimklRatings? ratings) {
    if (ratings == null) return null;
    final result = <MediaRatingSource>[];
    for (final (source, rating) in [('simkl', ratings.simkl), ('imdb', ratings.imdb), ('mal', ratings.mal)]) {
      final value = rating?.rating;
      if (value == null || value < 0 || value > 10) continue;
      final votes = rating!.votes;
      result.add(MediaRatingSource(source: source, value: value, votes: votes != null && votes >= 0 ? votes : null));
    }
    return result.isEmpty ? null : result;
  }

  static CatalogAudience? _audienceFor({
    int? viewers,
    CatalogAudiencePeriod? viewersPeriod,
    int? planning,
    String? dropRate,
  }) {
    final normalizedViewers = viewers != null && viewers >= 0 ? viewers : null;
    final normalizedPlanning = planning != null && planning >= 0 ? planning : null;
    final normalizedDropRate = _percentFraction(dropRate);
    if (normalizedViewers == null && normalizedPlanning == null && normalizedDropRate == null) return null;
    return CatalogAudience(
      viewers: normalizedViewers,
      viewersPeriod: normalizedViewers == null ? null : viewersPeriod,
      planning: normalizedPlanning,
      dropRate: normalizedDropRate,
    );
  }

  static double? _percentFraction(String? raw) {
    final value = double.tryParse(raw?.trim().replaceAll('%', '') ?? '');
    if (value == null || value < 0 || value > 100) return null;
    return value / 100;
  }

  static List<CatalogRank>? _rankFor(int? rank, CatalogRankScope scope, {required bool allTime}) =>
      rank == null || rank <= 0 ? null : [CatalogRank(rank: rank, scope: scope, allTime: allTime)];

  static String? _originalTitle(String title, String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty || value.toLowerCase() == title.trim().toLowerCase()) return null;
    return value;
  }

  static List<String>? _alternateTitles(String title, List<String>? raw, {String? originalTitle, String? extra}) {
    final seen = <String>{title.trim().toLowerCase(), if (originalTitle != null) originalTitle.toLowerCase()};
    final result = <String>[];
    for (final candidate in [...?raw, ?extra]) {
      final value = candidate.trim();
      if (value.isEmpty || !seen.add(value.toLowerCase())) continue;
      result.add(value);
    }
    return result.isEmpty ? null : result;
  }

  static List<CatalogLink>? _linksFor(String? raw) {
    final parsed = Uri.tryParse(raw?.trim() ?? '');
    if (parsed == null || parsed.toString().isEmpty) return null;
    final resolved = parsed.hasScheme ? parsed : Uri.parse('https://simkl.com').resolveUri(parsed);
    if (resolved.scheme != 'http' && resolved.scheme != 'https') return null;
    return [CatalogLink(label: 'Simkl', url: resolved.toString())];
  }

  static DateTime? _date(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;
    final match = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value);
    if (match == null) return null;
    final month = int.parse(match.group(1)!);
    final day = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    return DateTime.tryParse(
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
    );
  }

  static List<String>? _countryFor(String? raw) {
    final value = raw?.trim();
    return value == null || value.isEmpty ? null : [CountryCodes.normalizeCode(value)];
  }

  static List<String>? _languageFor(String? raw) {
    final value = raw?.trim();
    return value == null || value.isEmpty ? null : [value.toLowerCase()];
  }

  static List<CatalogCredit>? _creditsFor(String? director) {
    final name = director?.trim();
    return name == null || name.isEmpty ? null : [CatalogCredit(name: name, role: CatalogCreditRole.director)];
  }

  static CatalogBroadcast? _broadcastFor(SimklAirs? airs) {
    if (airs == null) return null;
    final weekday = _weekdayFor(airs.day);
    final time = _broadcastTime(airs.time);
    if (weekday == null && time == null) return null;
    final timezone = airs.timezone?.trim();
    return CatalogBroadcast(
      weekday: weekday,
      time: time,
      timezone: timezone == null || timezone.isEmpty ? null : timezone,
    );
  }

  static int? _weekdayFor(String? raw) => switch (raw?.trim().toLowerCase()) {
    'monday' => DateTime.monday,
    'tuesday' => DateTime.tuesday,
    'wednesday' => DateTime.wednesday,
    'thursday' => DateTime.thursday,
    'friday' => DateTime.friday,
    'saturday' => DateTime.saturday,
    'sunday' => DateTime.sunday,
    _ => null,
  };

  static String? _broadcastTime(String? raw) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*([AP]M)?$', caseSensitive: false).firstMatch(raw?.trim() ?? '');
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)?.toUpperCase();
    if (minute > 59 || (period == null && hour > 23) || (period != null && (hour < 1 || hour > 12))) {
      return null;
    }
    if (period != null) {
      hour %= 12;
      if (period == 'PM') hour += 12;
    }
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static CatalogSeasonInfo? _seasonFor(String? raw) {
    final parts = raw?.trim().split(RegExp(r'\s+'));
    if (parts == null || parts.isEmpty) return null;
    final name = CatalogSeasonInfo.parseName(parts.first);
    if (name == null) return null;
    return CatalogSeasonInfo(name: name, year: parts.length > 1 ? int.tryParse(parts.last) : null);
  }

  static String? _trailerUrl(String? youtube) => youTubeTrailerUrl(youtube);

  CatalogItem _catalogItemFromTrending(SimklTrendingItem item, SimklCatalogType type) {
    _rememberType(type, item.ids);
    final kind = _kindFor(type, animeType: item.animeType);
    final rating = item.ratings?.primary;
    final title = item.title ?? '';
    final originalTitle = _originalTitle(title, item.titleRomaji);
    return CatalogItem(
      source: CatalogSourceId.simkl,
      kind: kind,
      title: title,
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
      posterVariants: simklPosterVariants(item.poster),
      backdropVariants: simklFanartVariants(item.fanart),
      ratings: _ratingsFor(item.ratings),
      ranks: _rankFor(item.rank, CatalogRankScope.trending, allTime: false),
      audience: _audienceFor(
        viewers: item.watched,
        viewersPeriod: CatalogAudiencePeriod.week,
        planning: item.planToWatch,
        dropRate: item.dropRate,
      ),
      releaseDate: _date(item.theater ?? item.releaseDate),
      physicalReleaseDate: _date(item.dvdDate),
      originalTitle: originalTitle,
      altTitles: _alternateTitles(title, item.alternateTitles, originalTitle: originalTitle) ?? const [],
      format: _formatFor(type, item.animeType),
      countries: _countryFor(item.country),
      languages: _languageFor(item.originalLanguage),
      links: _linksFor(item.url),
    );
  }

  CatalogItem _catalogItemFromSearch(SimklSearchResult item, SimklCatalogType type) {
    _rememberType(type, item.ids);
    final kind = _kindFor(type, animeType: item.type);
    final rating = item.ratings?.primary;
    final title = item.title ?? '';
    final originalTitle = _originalTitle(title, item.titleRomaji);
    return CatalogItem(
      source: CatalogSourceId.simkl,
      kind: kind,
      title: title,
      year: item.year,
      rating: rating?.rating,
      votes: rating?.votes,
      airStatus: airStatusFor(item.status, kind),
      episodeCount: kind == MediaKind.movie || (item.episodeCount ?? 0) <= 0 ? null : item.episodeCount,
      ids: item.ids.toCatalogItemIds(),
      posterUrl: simklPosterUrl(item.poster),
      posterVariants: simklPosterVariants(item.poster),
      ratings: _ratingsFor(item.ratings),
      originalTitle: originalTitle,
      altTitles: _alternateTitles(title, item.allTitles, originalTitle: originalTitle, extra: item.titleEn) ?? const [],
      format: _formatFor(type, item.type),
      links: _linksFor(item.url),
    );
  }

  CatalogItem _catalogItemFromBest(SimklBestItem item, SimklCatalogType type) {
    _rememberType(type, item.ids);
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
      posterVariants: simklPosterVariants(item.poster),
      ratings: _ratingsFor(item.ratings),
      audience: _audienceFor(viewers: item.watched, viewersPeriod: CatalogAudiencePeriod.month),
      format: _formatFor(type, null),
      links: _linksFor(item.url),
    );
  }

  CatalogItem _catalogItemFromAllItems(SimklAllItemsEntry entry, SimklCatalogType type) {
    final media = entry.media!;
    _rememberType(type, media.ids);
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
      posterVariants: simklPosterVariants(media.poster),
      backdropVariants: simklFanartVariants(media.fanart),
      addedAt: _date(entry.addedAt),
      userRating: entry.userRating,
      format: _formatFor(type, entry.animeType),
      unairedEpisodeCount: kind == MediaKind.movie || (entry.notAiredEpisodes ?? 0) <= 0
          ? null
          : entry.notAiredEpisodes,
    );
  }

  CatalogItem _catalogItemFromRecommendation(SimklRecommendation item) {
    final type = switch (item.type?.toLowerCase()) {
      'movie' => SimklCatalogType.movies,
      'anime' => SimklCatalogType.anime,
      _ => SimklCatalogType.tv,
    };
    _rememberType(type, item.ids);
    final kind = _kindFor(type, animeType: item.animeType);
    final title = item.title ?? '';
    return CatalogItem(
      source: CatalogSourceId.simkl,
      kind: kind,
      title: title,
      year: item.year,
      ids: item.ids.toCatalogItemIds(),
      posterUrl: simklPosterUrl(item.poster),
      posterVariants: simklPosterVariants(item.poster),
      altTitles: _alternateTitles(title, null, extra: item.englishTitle) ?? const [],
      format: _formatFor(type, item.animeType),
      recommendationCount: item.usersCount != null && item.usersCount! >= 0 ? item.usersCount : null,
      recommendationPercent: _percentFraction(item.usersPercent),
    );
  }

  CatalogItem _catalogItemFromDetail(SimklDetail detail, SimklCatalogType type) {
    final kind = _kindFor(type, animeType: detail.animeType);
    final rating = detail.ratings?.primary;
    final title = detail.title ?? '';
    final originalTitle = _originalTitle(title, detail.originalTitle);
    return CatalogItem(
      source: CatalogSourceId.simkl,
      kind: kind,
      title: title,
      year: detail.year,
      overview: detail.overview,
      runtimeMinutes: detail.runtime,
      rating: rating?.rating,
      votes: rating?.votes,
      genres: detail.genres,
      certification: detail.certification,
      trailerUrl: _trailerUrl(detail.trailer),
      airStatus: airStatusFor(detail.status, kind),
      episodeCount: kind == MediaKind.movie || (detail.totalEpisodes ?? 0) <= 0 ? null : detail.totalEpisodes,
      network: detail.network,
      ids: detail.ids.toCatalogItemIds(),
      posterUrl: simklPosterUrl(detail.poster),
      backdropUrl: simklFanartUrl(detail.fanart),
      posterVariants: simklPosterVariants(detail.poster),
      backdropVariants: simklFanartVariants(detail.fanart),
      ratings: _ratingsFor(detail.ratings),
      ranks: _rankFor(detail.rank, CatalogRankScope.popular, allTime: true),
      audience: _audienceFor(dropRate: detail.dropRate),
      broadcast: _broadcastFor(detail.airs),
      releaseDate: _date(detail.released ?? detail.firstAired),
      physicalReleaseDate: _date(detail.physicalRelease),
      endDate: _date(detail.lastAired),
      originalTitle: originalTitle,
      altTitles:
          _alternateTitles(title, detail.alternateTitles, originalTitle: originalTitle, extra: detail.englishTitle) ??
          const [],
      broadcastSeason: _seasonFor(detail.seasonNameYear),
      format: _formatFor(type, detail.animeType),
      studios: detail.studios,
      countries: _countryFor(detail.country),
      languages: _languageFor(detail.language),
      credits: _creditsFor(detail.director),
      links: _linksFor(detail.url),
      budget: detail.budget,
      revenue: detail.revenue,
    );
  }

  @override
  Future<CatalogDetail> fetchDetail(CatalogItem item, {int castLimit = 20, int relatedLimit = 20}) async {
    final simklId = item.ids.simkl;
    if (simklId == null) return CatalogDetail(item: item);
    final type = _detailTypeFor(item);
    final detail = await _client.getDetail(type, simklId);
    if (detail == null) return CatalogDetail(item: item);
    final related = <CatalogItem>[
      if (relatedLimit > 0)
        for (final recommendation in detail.recommendations.take(relatedLimit))
          if (recommendation.ids.hasAny) _catalogItemFromRecommendation(recommendation),
    ];
    return CatalogDetail(item: item.enrichedWith(_catalogItemFromDetail(detail, type)), related: related);
  }

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async =>
      external.hasCatalogIds ? CatalogItemIds.fromExternal(external) : null;

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
    _animeIds.clear();
    disposeWatchlistMachinery();
  }
}
