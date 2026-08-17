import 'package:flutter/foundation.dart';

import '../../media/media_kind.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_metadata.dart';
import '../../models/catalog/catalog_item.dart';
import '../../models/seerr/seerr_details.dart';
import '../../models/seerr/seerr_media.dart';
import '../../models/seerr/seerr_page.dart';
import '../../models/seerr/seerr_request.dart';
import '../../utils/app_logger.dart';
import '../../utils/country_codes.dart';
import '../../utils/external_ids.dart';
import '../../utils/trailer_urls.dart';
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
      CatalogRowId.trendingAnime ||
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
  Future<CatalogDetail> fetchDetail(CatalogItem item, {int castLimit = 20, int relatedLimit = 20}) async {
    final tmdbId = item.ids.tmdb;
    if (tmdbId == null) return CatalogDetail(item: item);

    // Start both retained calls before awaiting either. Each helper isolates
    // its own failure so detail metadata and recommendations degrade
    // independently.
    final detailsFuture = _fetchDetails(item.kind, tmdbId);
    final relatedFuture = _fetchRecommendations(item.kind, tmdbId, relatedLimit);
    final details = await detailsFuture;
    final related = await relatedFuture;

    return CatalogDetail(
      item: details == null ? item : item.enrichedWith(_toDetailCatalogItem(details, item.kind)),
      cast: details == null ? const [] : _toCast(details, castLimit),
      related: related,
    );
  }

  /// Seerr requests key on TMDB ids, so any library item carrying one is in
  /// scope; the watchlist action stays hidden regardless
  /// ([supportsWatchlist] is false).
  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async =>
      external.tmdb == null ? null : CatalogItemIds(tmdb: external.tmdb, imdb: external.imdb, tvdb: external.tvdb);

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
    totalResults: page.totalResults,
  );

  CatalogItem _toCatalogItem(SeerrMedia m) => CatalogItem(
    source: CatalogSourceId.seerr,
    kind: m.isMovie ? MediaKind.movie : MediaKind.show,
    title: m.displayTitle,
    year: m.year,
    overview: _nonEmpty(m.overview),
    rating: m.voteAverage,
    votes: m.voteCount,
    ids: CatalogItemIds(tmdb: m.id),
    posterUrl: tmdbImageUrl(m.posterPath, 'w600_and_h900_bestv2'),
    backdropUrl: tmdbImageUrl(m.backdropPath, 'w1920_and_h800_multi_faces'),
    posterVariants: tmdbPosterVariants(m.posterPath),
    backdropVariants: tmdbBackdropVariants(m.backdropPath),
    serverState: _serverState(m.mediaInfo),
    releaseDate: _date(m.date),
    originalTitle: _originalTitle(m.displayOriginalTitle, m.displayTitle),
    languages: _languageList(m.originalLanguage),
    countries: _countryCodes(m.originCountry),
    isAdult: m.isMovie ? m.adult : null,
  );

  Future<SeerrDetails?> _fetchDetails(MediaKind kind, int tmdbId) async {
    try {
      return kind == MediaKind.movie ? await client.getMovie(tmdbId) : await client.getTv(tmdbId);
    } catch (error) {
      appLogger.w('Seerr: detail load failed for tmdb:$tmdbId', error: error);
      return null;
    }
  }

  Future<List<CatalogItem>> _fetchRecommendations(MediaKind kind, int tmdbId, int limit) async {
    try {
      final page = kind == MediaKind.movie
          ? await client.getMovieRecommendations(tmdbId)
          : await client.getTvRecommendations(tmdbId);
      return _toPage(page).items.take(limit).toList();
    } catch (error) {
      appLogger.w('Seerr: recommendations load failed for tmdb:$tmdbId', error: error);
      return const [];
    }
  }

  CatalogItem _toDetailCatalogItem(SeerrDetails details, MediaKind kind) => CatalogItem(
    source: CatalogSourceId.seerr,
    kind: kind,
    title: details.displayTitle,
    year: _year(details.date),
    overview: _nonEmpty(details.overview),
    runtimeMinutes: _positive(details.runtime) ?? _firstPositive(details.episodeRunTime),
    rating: details.voteAverage,
    votes: details.voteCount,
    genres: _names(details.genres),
    certification: _certification(details, kind),
    trailerUrl: kind == MediaKind.movie ? _trailerUrl(details.relatedVideos) : null,
    airStatus: _airStatus(details.status, kind),
    episodeCount: kind == MediaKind.show ? _episodeCount(details) : null,
    network: kind == MediaKind.show ? _firstName(details.networks) : null,
    ids: CatalogItemIds(
      tmdb: _positive(details.id),
      imdb: _nonEmpty(details.imdbId) ?? _nonEmpty(details.externalIds?.imdbId),
      tvdb: _positive(details.externalIds?.tvdbId),
    ),
    posterUrl: tmdbImageUrl(details.posterPath, 'w600_and_h900_bestv2'),
    backdropUrl: tmdbImageUrl(details.backdropPath, 'w1920_and_h800_multi_faces'),
    posterVariants: tmdbPosterVariants(details.posterPath),
    backdropVariants: tmdbBackdropVariants(details.backdropPath),
    serverState: _serverState(details.mediaInfo),
    releaseDate: _date(details.date),
    originalTitle: _originalTitle(details.displayOriginalTitle, details.displayTitle),
    tagline: _nonEmpty(details.tagline),
    endDate: _endDate(details, kind),
    studios: _names(details.productionCompanies),
    countries: _detailCountries(details),
    languages: _detailLanguages(details),
    credits: _credits(details),
    tags: _tags(details.keywords),
    budget: _positive(details.budget),
    revenue: _positive(details.revenue),
    isAdult: kind == MediaKind.movie ? details.adult : null,
  );

  List<CatalogCastMember> _toCast(SeerrDetails details, int limit) => [
    for (final member in (details.credits?.cast ?? const <SeerrCastMember>[]).take(limit))
      if (_nonEmpty(member.name) case final String name)
        CatalogCastMember(
          name: name,
          secondary: _nonEmpty(member.character),
          imageUrl: tmdbImageUrl(member.profilePath, 'w300'),
        ),
  ];

  static CatalogServerState? _serverState(SeerrMediaInfo? info) {
    if (info == null) return null;

    int? availableSeasons;
    int? totalSeasons;
    final seasons = info.seasons;
    if (seasons != null && seasons.isNotEmpty) {
      var available = 0;
      var total = 0;
      for (final season in seasons) {
        if (season.seasonNumber <= 0) continue;
        total++;
        if (season.status == SeerrMediaStatus.available) available++;
      }
      if (total > 0) {
        availableSeasons = available;
        totalSeasons = total;
      }
    }

    final state = CatalogServerState(
      availability: _availability(info.status),
      availability4k: _availability(info.status4k),
      request: _requestState(info, is4k: false, mediaStatus: info.status),
      request4k: _requestState(info, is4k: true, mediaStatus: info.status4k),
      availableSeasons: availableSeasons,
      totalSeasons: totalSeasons,
    );
    return state.isEmpty ? null : state;
  }

  static CatalogAvailability? _availability(SeerrMediaStatus status) => switch (status) {
    SeerrMediaStatus.available => CatalogAvailability.available,
    SeerrMediaStatus.partiallyAvailable => CatalogAvailability.partiallyAvailable,
    SeerrMediaStatus.pending ||
    SeerrMediaStatus.processing ||
    SeerrMediaStatus.deleted => CatalogAvailability.unavailable,
    SeerrMediaStatus.unknown => null,
  };

  static CatalogRequestState? _requestState(
    SeerrMediaInfo info, {
    required bool is4k,
    required SeerrMediaStatus mediaStatus,
  }) {
    var pendingApproval = false;
    var approved = false;
    var declined = false;
    for (final request in info.requests ?? const <SeerrRequest>[]) {
      if ((request.is4k ?? false) != is4k) continue;
      switch (request.status) {
        case SeerrRequestStatus.pending:
          pendingApproval = true;
        case SeerrRequestStatus.approved:
          approved = true;
        case SeerrRequestStatus.declined:
          declined = true;
      }
    }

    // These two `pending` values are unrelated. Request.pending means waiting
    // for approval; MediaInfo.pending means an approved request is queued in
    // the acquisition pipeline. Keep that distinction and precedence explicit.
    if (pendingApproval) return CatalogRequestState.pending;
    if (mediaStatus == SeerrMediaStatus.processing) return CatalogRequestState.processing;
    if (approved || mediaStatus == SeerrMediaStatus.pending) return CatalogRequestState.approved;
    if (declined) return CatalogRequestState.declined;
    return null;
  }

  static String? _certification(SeerrDetails details, MediaKind kind) {
    if (kind == MediaKind.movie) {
      return _preferredCountryValue(
        details.releases?.results,
        (entry) => entry.countryCode,
        (entry) =>
            _nonEmpty(entry.rating) ??
            entry.releaseDates?.map((date) => _nonEmpty(date.certification)).nonNulls.firstOrNull,
      );
    }
    return _preferredCountryValue(
      details.contentRatings?.results,
      (entry) => entry.countryCode,
      (entry) => _nonEmpty(entry.rating),
    );
  }

  static String? _preferredCountryValue<T>(
    List<T>? entries,
    String? Function(T entry) country,
    String? Function(T entry) value,
  ) {
    if (entries == null) return null;
    for (final entry in entries) {
      if (country(entry)?.toUpperCase() != 'US') continue;
      if (value(entry) case final String result) return result;
    }
    for (final entry in entries) {
      if (value(entry) case final String result) return result;
    }
    return null;
  }

  static String? _trailerUrl(List<SeerrRelatedVideo>? videos) {
    if (videos == null) return null;
    for (final video in videos) {
      if (video.type?.toLowerCase() != 'trailer') continue;
      if (_nonEmpty(video.url) case final String url) return url;
      if (_nonEmpty(video.key) case final String key when video.site?.toLowerCase() == 'youtube') {
        return youTubeTrailerUrl(key);
      }
    }
    return null;
  }

  static CatalogAirStatus? _airStatus(String? raw, MediaKind kind) {
    return switch (raw?.trim().toLowerCase()) {
      'returning series' || 'airing' => CatalogAirStatus.airing,
      'ended' => CatalogAirStatus.ended,
      'canceled' || 'cancelled' => CatalogAirStatus.canceled,
      'planned' || 'pilot' || 'rumored' || 'in production' || 'post production' => CatalogAirStatus.upcoming,
      'released' when kind == MediaKind.show => CatalogAirStatus.ended,
      _ => null,
    };
  }

  static DateTime? _endDate(SeerrDetails details, MediaKind kind) {
    if (kind != MediaKind.show) return null;
    final status = _airStatus(details.status, kind);
    return status == CatalogAirStatus.ended || status == CatalogAirStatus.canceled ? _date(details.lastAirDate) : null;
  }

  static int? _episodeCount(SeerrDetails details) {
    if (_positive(details.numberOfEpisodes) case final int count) return count;
    var total = 0;
    var found = false;
    for (final season in details.seasons ?? const <SeerrSeason>[]) {
      if (_positive(season.episodeCount) case final int count) {
        total += count;
        found = true;
      }
    }
    return found ? total : null;
  }

  static List<String>? _countryCodes(Iterable<String?>? values) {
    if (values == null) return null;
    final result = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final trimmed = _nonEmpty(value);
      if (trimmed == null) continue;
      final normalized = CountryCodes.normalizeCode(trimmed);
      if (normalized.isNotEmpty && seen.add(normalized)) result.add(normalized);
    }
    return result.isEmpty ? null : result;
  }

  static List<String>? _detailCountries(SeerrDetails details) => _countryCodes([
    ...?details.originCountry,
    for (final value in details.productionCountries ?? const <SeerrProductionCountry>[])
      value.countryCode ?? value.name,
  ]);

  static List<String>? _detailLanguages(SeerrDetails details) => _languageCodes([
    details.originalLanguage,
    ...?details.languages,
    for (final language in details.spokenLanguages ?? const <SeerrSpokenLanguage>[]) language.languageCode,
  ]);

  static List<String>? _languageCodes(Iterable<String?> values) {
    final result = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final normalized = _nonEmpty(value)?.toLowerCase();
      if (normalized != null && seen.add(normalized)) result.add(normalized);
    }
    return result.isEmpty ? null : result;
  }

  static List<CatalogCredit>? _credits(SeerrDetails details) {
    final result = <CatalogCredit>[];
    final seen = <String>{};

    void add(String? rawName, CatalogCreditRole? role) {
      final name = _nonEmpty(rawName);
      if (name == null || role == null || !seen.add('${role.name}\u0000$name')) return;
      result.add(CatalogCredit(name: name, role: role));
    }

    for (final creator in details.createdBy ?? const <SeerrNamedValue>[]) {
      add(creator.name, CatalogCreditRole.creator);
    }
    for (final member in details.credits?.crew ?? const <SeerrCrewMember>[]) {
      add(member.name, _creditRole(member.job, member.department));
    }
    return result.isEmpty ? null : result;
  }

  static CatalogCreditRole? _creditRole(String? job, String? department) {
    return switch (job?.trim().toLowerCase()) {
      'director' => CatalogCreditRole.director,
      'writer' || 'screenplay' || 'story' || 'teleplay' => CatalogCreditRole.writer,
      'producer' || 'executive producer' || 'co-producer' => CatalogCreditRole.producer,
      'composer' || 'original music composer' => CatalogCreditRole.composer,
      _ when department?.trim().toLowerCase() == 'writing' => CatalogCreditRole.writer,
      _ => null,
    };
  }

  static List<CatalogTag>? _tags(List<SeerrNamedValue>? keywords) {
    final names = _names(keywords);
    return names == null ? null : [for (final name in names) CatalogTag(name: name)];
  }

  static List<String>? _names(List<SeerrNamedValue>? values) {
    if (values == null) return null;
    final names = [
      for (final value in values)
        if (_nonEmpty(value.name) case final String name) name,
    ];
    return names.isEmpty ? null : names;
  }

  static String? _firstName(List<SeerrNamedValue>? values) {
    if (values == null) return null;
    for (final value in values) {
      if (_nonEmpty(value.name) case final String name) return name;
    }
    return null;
  }

  static List<String>? _languageList(String? language) => _languageCodes([language]);

  static String? _originalTitle(String? original, String displayed) {
    final value = _nonEmpty(original);
    return value == null || value == displayed ? null : value;
  }

  static DateTime? _date(String? raw) => raw == null ? null : DateTime.tryParse(raw);

  static int? _year(String? raw) {
    if (raw == null || raw.length < 4) return null;
    return int.tryParse(raw.substring(0, 4));
  }

  static int? _positive(int? value) => value != null && value > 0 ? value : null;

  static int? _firstPositive(List<int>? values) {
    if (values == null) return null;
    for (final value in values) {
      if (value > 0) return value;
    }
    return null;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

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

  /// Seerr serves TMDB relative paths (`/abc.jpg`); images come straight off
  /// the TMDB CDN at the same sizes the Seerr web UI uses.
  static String? tmdbImageUrl(String? path, String size) =>
      path == null || path.isEmpty ? null : 'https://image.tmdb.org/t/p/$size$path';

  @override
  void dispose() {
    _watchlistChanges.dispose();
  }
}
