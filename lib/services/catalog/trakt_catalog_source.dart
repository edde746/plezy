import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../../i18n/strings.g.dart';
import '../../media/media_kind.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_item.dart';
import '../../models/catalog/catalog_metadata.dart';
import '../../models/trakt/trakt_cast_entry.dart';
import '../../models/trakt/trakt_catalog_entry.dart';
import '../../models/trakt/trakt_catalog_media.dart';
import '../../models/trakt/trakt_ids.dart';
import '../../models/trakt/trakt_title_variant.dart';
import '../../utils/app_logger.dart';
import '../../utils/country_codes.dart';
import '../../utils/external_ids.dart';
import '../trackers/trakt/trakt_client.dart';
import '../trackers/trakt/trakt_constants.dart';
import 'catalog_source.dart';
import 'catalog_watchlist_machinery.dart';

/// [CatalogSource] backed by the Trakt API.
///
/// Wraps the catalog [TraktClient] owned by `TrackersProvider` (not owned here
/// — never disposed by this class). Watchlist membership rides
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
        return CatalogPage(items: _fromEntries(res.items), hasMore: res.hasMore, totalResults: res.itemCount);
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
          totalResults: res.itemCount,
        );
      case CatalogRowId.trendingShows:
        final res = await _client.getTrending(TraktCatalogType.shows, page: page, limit: limit);
        return CatalogPage(
          items: _fromEntries(res.items, kind: MediaKind.show),
          hasMore: res.hasMore,
          totalResults: res.itemCount,
        );
      case CatalogRowId.popularMovies:
        final res = await _client.getPopular(TraktCatalogType.movies, page: page, limit: limit);
        return CatalogPage(
          items: _fromMedia(res.items, MediaKind.movie),
          hasMore: res.hasMore,
          totalResults: res.itemCount,
        );
      case CatalogRowId.popularShows:
        final res = await _client.getPopular(TraktCatalogType.shows, page: page, limit: limit);
        return CatalogPage(
          items: _fromMedia(res.items, MediaKind.show),
          hasMore: res.hasMore,
          totalResults: res.itemCount,
        );
      case CatalogRowId.trendingAnime:
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
      external.hasCatalogIds ? CatalogItemIds.fromExternal(external) : null;

  @override
  Future<CatalogDetail> fetchDetail(CatalogItem item, {int castLimit = 20, int relatedLimit = 20}) async {
    final id = item.ids.trakt?.toString() ?? item.ids.slug ?? item.ids.imdb;
    if (id == null) return CatalogDetail(item: item);
    final type = item.kind == MediaKind.movie ? TraktCatalogType.movies : TraktCatalogType.shows;

    // Start every request before awaiting any. Trakt keeps people, related
    // titles, aliases and translations on separate endpoints, so four calls
    // are the minimum; the last two exist for the library lookup (#2098).
    final peopleFuture = _withoutFailure(_client.getPeople(type, id), 'people', item);
    final relatedFuture = _withoutFailure(_client.getRelated(type, id, limit: relatedLimit), 'related', item);
    final aliasesFuture = _withoutFailure(_client.getAliases(type, id), 'aliases', item);
    final translationsFuture = _withoutFailure(
      _client.getTranslations(type, id, LocaleSettings.currentLocale.languageCode),
      'translations',
      item,
    );
    final people = await peopleFuture;
    final related = await relatedFuture;
    final aliases = await aliasesFuture;
    final translations = await translationsFuture;
    final credits = _creditsFrom(people?.crew);
    final altTitles = lookupTitles(item, aliases: aliases ?? const [], translations: translations ?? const []);
    final enrichedItem = credits.isEmpty && altTitles.isEmpty
        ? item
        : item.enrichedWith(
            CatalogItem(
              source: CatalogSourceId.trakt,
              kind: item.kind,
              title: '',
              ids: const CatalogItemIds(),
              credits: credits,
              altTitles: altTitles,
            ),
          );

    return CatalogDetail(
      item: enrichedItem,
      cast: _castFrom(people, castLimit),
      related: related == null ? const [] : _fromMedia(related, item.kind),
    );
  }

  /// The alternate titles worth one library-lookup request each, in the
  /// order the candidate budget should spend them (see
  /// `titleMatchCandidates`; Trakt rows carry none of their own):
  ///
  /// 1. the romaji/transliterated title — the first alias from the item's
  ///    own country written in plain ASCII, which is how a Latin-script
  ///    library files a Japanese title (`Sousou no Frieren`);
  /// 2. the app-locale translation, for a library titled in the user's
  ///    language (`Frieren: Tras finalizar el viaje`).
  ///
  /// The native title is not repeated here: Trakt already sends it as
  /// `original_title`, and the matcher reads [CatalogItem.originalTitle]
  /// for every source.
  ///
  /// Only one alias is taken, and only an ASCII one: Trakt lists every
  /// spelling (`Sōsō no Frieren`, `Sōsō no Furīren`) and every region's
  /// marketing name, hundreds of rows for a long-running show, and each
  /// would cost a request of its own. A variant that is the item's own
  /// title in other punctuation (`"Oshi no Ko"`, `【OSHI NO KO】`) is skipped:
  /// the search index tokenizes on punctuation, so it would only repeat the
  /// own title's request.
  @visibleForTesting
  static List<String> lookupTitles(
    CatalogItem item, {
    required List<TraktTitleVariant> aliases,
    required List<TraktTitleVariant> translations,
  }) {
    final own = _letters(item.title);
    final country = item.countries?.firstOrNull;
    String? romaji;
    if (country != null) {
      for (final alias in aliases) {
        final title = alias.title?.trim();
        if (title == null || title.isEmpty || alias.country == null) continue;
        if (CountryCodes.normalizeCode(alias.country!) != country) continue;
        if (!_isAscii(title) || _letters(title) == own) continue;
        romaji = title;
        break;
      }
    }
    final localized = translations.map((variant) => variant.title?.trim()).firstWhereOrNull((title) {
      return title != null && title.isNotEmpty && _letters(title) != own;
    });
    return <String>{?romaji, ?localized}.toList(growable: false);
  }

  static final RegExp _notLetterOrDigit = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

  static String _letters(String title) => title.toLowerCase().replaceAll(_notLetterOrDigit, '');

  static bool _isAscii(String value) => value.codeUnits.every((unit) => unit < 0x80);

  Future<T?> _withoutFailure<T>(Future<T> request, String requestName, CatalogItem item) async {
    try {
      return await request;
    } catch (error, stackTrace) {
      appLogger.d(
        'Trakt: catalog $requestName load failed for ${item.identityKey}',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  List<CatalogCastMember> _castFrom(TraktPeople? people, int limit) {
    if (people == null || limit <= 0) return const [];
    final cast = <CatalogCastMember>[];
    // `guest_stars` can be a very large response. Regular cast stays first and
    // the combined retained list is bounded even though Trakt sends all rows.
    for (final entry in people.cast.followedBy(people.guestStars)) {
      if (cast.length >= limit) break;
      if (entry.person?.name case final String name when name.isNotEmpty) {
        cast.add(
          CatalogCastMember(
            name: name,
            secondary: _castSecondary(entry),
            imageUrl: entry.person?.images?.primaryHeadshot,
          ),
        );
      }
    }
    return cast;
  }

  static String? _castSecondary(TraktCastEntry entry) {
    final characters = entry.characters?.where((character) => character.isNotEmpty).join(', ');
    final episodeCount = entry.episodeCount;
    final parts = [
      if (characters != null && characters.isNotEmpty) characters,
      if (episodeCount != null) t.explore.badge.episodesShort(n: episodeCount),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static List<CatalogCredit> _creditsFrom(List<TraktCastEntry>? crew) {
    if (crew == null || crew.isEmpty) return const [];
    final credits = <CatalogCredit>[];
    final seen = <String>{};
    for (final role in const [CatalogCreditRole.director, CatalogCreditRole.writer, CatalogCreditRole.producer]) {
      for (final entry in crew) {
        final name = entry.person?.name;
        if (name == null || name.isEmpty || !_hasCreditRole(entry, role)) continue;
        final key = '${role.name}/${name.toLowerCase()}';
        if (seen.add(key)) credits.add(CatalogCredit(name: name, role: role));
      }
    }
    return credits;
  }

  static bool _hasCreditRole(TraktCastEntry entry, CatalogCreditRole role) {
    final job = entry.job;
    final jobs = <String>[
      if (job != null) job.toLowerCase(),
      for (final job in entry.jobs ?? const <String>[]) job.toLowerCase(),
    ];
    return switch (role) {
      CatalogCreditRole.director => jobs.any((job) => job == 'director' || job == 'co-director'),
      CatalogCreditRole.writer => jobs.any((job) => const {'writer', 'screenplay', 'story', 'teleplay'}.contains(job)),
      CatalogCreditRole.producer => jobs.any((job) => job == 'producer' || job.endsWith(' producer')),
      _ => false,
    };
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

  List<CatalogItem> _fromEntries(List<TraktCatalogEntry> entries, {MediaKind? kind}) => [
    for (final entry in entries)
      if (entry.media != null && _entryKind(entry, kind) != null && entry.media!.ids.hasAny)
        _toCatalogItem(
          entry.media!,
          _entryKind(entry, kind)!,
          watchers: entry.watchers,
          addedAt: _parseDate(entry.listedAt),
        ),
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

  CatalogItem _toCatalogItem(TraktCatalogMedia media, MediaKind kind, {int? watchers, DateTime? addedAt}) {
    final audience = CatalogAudience(watchingNow: watchers, comments: media.commentCount);
    final broadcast = CatalogBroadcast(
      weekday: weekdayFor(media.airs?.day),
      time: _broadcastTime(media.airs?.time),
      timezone: media.airs?.timezone,
    );
    return CatalogItem(
      source: CatalogSourceId.trakt,
      kind: kind,
      title: media.title ?? '',
      year: media.year,
      overview: media.overview,
      runtimeMinutes: media.runtime,
      rating: media.rating,
      votes: media.votes,
      genres: media.genres,
      certification: media.certification,
      trailerUrl: media.trailer,
      airStatus: airStatusFor(media.status),
      episodeCount: media.airedEpisodes,
      network: media.network,
      ids: CatalogItemIds(
        trakt: media.ids.trakt,
        slug: media.ids.slug,
        imdb: media.ids.imdb,
        tmdb: media.ids.tmdb,
        tvdb: media.ids.tvdb,
      ),
      posterUrl: media.images?.primaryPoster,
      backdropUrl: media.images?.primaryBackdrop,
      logoUrl: media.images?.primaryLogo,
      audience: audience.isEmpty ? null : audience,
      broadcast: broadcast.isEmpty ? null : broadcast,
      releaseDate: _parseDate(media.released ?? media.firstAired),
      addedAt: addedAt,
      originalTitle: media.originalTitle,
      tagline: media.tagline,
      countries: media.country == null || media.country!.isEmpty ? null : [CountryCodes.normalizeCode(media.country!)],
      languages: _languagesFor(media),
      recommenders: _recommendersFor(media),
    );
  }

  static int? weekdayFor(String? day) => switch (day?.toLowerCase()) {
    'monday' => DateTime.monday,
    'tuesday' => DateTime.tuesday,
    'wednesday' => DateTime.wednesday,
    'thursday' => DateTime.thursday,
    'friday' => DateTime.friday,
    'saturday' => DateTime.saturday,
    'sunday' => DateTime.sunday,
    _ => null,
  };

  static String? _broadcastTime(String? time) {
    if (time == null || time.length < 5 || time[2] != ':') return null;
    final hour = int.tryParse(time.substring(0, 2));
    final minute = int.tryParse(time.substring(3, 5));
    if (hour == null || hour < 0 || hour > 23 || minute == null || minute < 0 || minute > 59) {
      return null;
    }
    return time.substring(0, 5);
  }

  static DateTime? _parseDate(String? raw) => raw == null ? null : DateTime.tryParse(raw);

  static List<String>? _languagesFor(TraktCatalogMedia media) {
    final languages = <String>{
      if (media.language case final String language when language.isNotEmpty) language.toLowerCase(),
      ...?media.languages?.where((language) => language.isNotEmpty).map((language) => language.toLowerCase()),
      ...?media.availableTranslations
          ?.where((language) => language.isNotEmpty)
          .map((language) => language.toLowerCase()),
    };
    return languages.isEmpty ? null : languages.toList(growable: false);
  }

  static List<CatalogRecommender>? _recommendersFor(TraktCatalogMedia media) {
    final recommenders = <CatalogRecommender>[
      for (final user in media.favoritedBy ?? const <TraktRecommendationUser>[])
        if (user.username case final String username when username.isNotEmpty)
          CatalogRecommender(
            username: username,
            name: user.name,
            note: user.notes,
            reason: CatalogRecommendationReason.favorited,
          ),
      for (final user in media.recommendedBy ?? const <TraktRecommendationUser>[])
        if (user.username case final String username when username.isNotEmpty)
          CatalogRecommender(
            username: username,
            name: user.name,
            note: user.notes,
            reason: CatalogRecommendationReason.recommended,
          ),
    ];
    return recommenders.isEmpty ? null : recommenders;
  }

  @override
  void dispose() {
    disposeWatchlistMachinery();
  }
}
