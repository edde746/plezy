import 'package:collection/collection.dart';

import '../../media/media_rating.dart';
import '../../media/media_kind.dart';
import '../../models/anilist/anilist_media.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_item.dart';
import '../../models/catalog/catalog_metadata.dart';
import '../../models/trackers/fribb_mapping_row.dart';
import '../../utils/country_codes.dart';
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
  static final RegExp _accentColorPattern = RegExp(r'^#[0-9a-fA-F]{6}$');

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
    // A set literal: insertion-ordered and deduped. Providers repeat titles
    // across fields — AniList lists the English title again under `synonyms` —
    // and a duplicate here costs the reverse library lookup a wasted request.
    altTitles: <String>{
      for (final title in <String?>[
        anime.titleEnglish,
        anime.titleUserPreferred,
        anime.titleRomaji,
        anime.titleNative,
        ...?anime.synonyms,
      ])
        if (title != null && title.isNotEmpty && title != anime.displayTitle) title,
    }.toList(),
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
    season: row == null || (row.tvdbSeason == null && row.tmdbSeason == null)
        ? null
        : ExternalSeasonRef(tvdb: row.tvdbSeason, tmdb: row.tmdbSeason),
    posterUrl: anime.posterUrl,
    backdropUrl: anime.backdropUrl,
    accentColor: _accentColorFor(anime.coverImageColor),
    ratings: _ratingsFor(anime.meanRating),
    ranks: _ranksFor(anime.rankings),
    audience: _audienceFor(anime),
    nextEpisode: _nextEpisodeFor(anime.nextAiringEpisode),
    releaseDate: anime.releaseDate,
    endDate: anime.finalEpisodeDate,
    originalTitle: _differentTitle(anime.titleNative, anime.displayTitle),
    broadcastSeason: _seasonFor(anime.season, anime.seasonYear),
    format: _formatFor(anime.format),
    sourceMaterial: _sourceMaterialFor(anime.source),
    studios: anime.mainStudios,
    countries: _countriesFor(anime.countryOfOrigin),
    credits: _creditsFor(anime.staffCredits),
    tags: _tagsFor(anime.tags),
    links: _linksFor(anime.externalLinks, anime.streamingEpisodes),
    cast: _castFor(anime.characters),
  );

  @override
  Future<CatalogDetail> fetchDetail(CatalogItem item, {int castLimit = 20, int relatedLimit = 20}) async {
    final anilistId = item.ids.anilist;
    if (anilistId == null) return CatalogDetail(item: item);

    final cachedCast = item.cast;
    final response = await _client.getAnimeDetail(
      anilistId,
      castLimit: castLimit,
      relatedLimit: relatedLimit,
      includeCharacters: cachedCast == null,
    );
    final relationEdges = [
      for (final edge in response.relations)
        if (edge.item.id != null) edge,
    ];
    final mapped = await Future.wait([
      _toCatalogItems(response.recommendations),
      _toCatalogItems([for (final edge in relationEdges) edge.item]),
    ]);
    final groupedRelations = <CatalogRelationType, List<CatalogItem>>{};
    for (var i = 0; i < relationEdges.length; i++) {
      final type = _relationTypeFor(relationEdges[i].relationType);
      groupedRelations.putIfAbsent(type, () => []).add(mapped[1][i]);
    }
    final detailItem = response.item;
    final mappedDetail = detailItem == null ? null : _toCatalogItem(detailItem, null);
    return CatalogDetail(
      item: mappedDetail == null ? item : item.enrichedWith(mappedDetail),
      cast: cachedCast ?? mappedDetail?.cast ?? const [],
      related: mapped[0],
      relations: [for (final entry in groupedRelations.entries) CatalogRelation(type: entry.key, items: entry.value)],
    );
  }

  static List<CatalogCastMember>? _castFor(List<AnilistCharacter>? characters) => characters == null
      ? null
      : [
          for (final character in characters)
            CatalogCastMember(name: character.name, secondary: character.role, imageUrl: character.imageUrl),
        ];

  static List<MediaRatingSource>? _ratingsFor(double? meanRating) =>
      meanRating == null ? null : [MediaRatingSource(source: 'anilist', value: meanRating)];

  static CatalogNextEpisode? _nextEpisodeFor(AnilistNextAiringEpisode? airing) => airing == null
      ? null
      : CatalogNextEpisode(
          episode: airing.episode,
          airsAt: DateTime.fromMillisecondsSinceEpoch(airing.airingAt * Duration.millisecondsPerSecond, isUtc: true),
        );

  static CatalogSeasonInfo? _seasonFor(String? season, int? year) {
    final name = CatalogSeasonInfo.parseName(season);
    return name == null ? null : CatalogSeasonInfo(name: name, year: year);
  }

  static List<CatalogRank>? _ranksFor(List<AnilistRanking>? rankings) {
    if (rankings == null) return null;
    final ranks = [
      for (final ranking in rankings)
        if (_rankScopeFor(ranking.type) case final CatalogRankScope scope)
          CatalogRank(
            rank: ranking.rank,
            scope: scope,
            allTime: ranking.allTime,
            year: ranking.year,
            season: CatalogSeasonInfo.parseName(ranking.season),
          ),
    ];
    return ranks.isEmpty ? null : ranks;
  }

  static CatalogRankScope? _rankScopeFor(String? type) => switch (type) {
    'POPULAR' => CatalogRankScope.popular,
    'RATED' => CatalogRankScope.rated,
    _ => null,
  };

  static CatalogAudience? _audienceFor(AnilistMedia anime) {
    if (anime.popularity == null && anime.favourites == null && anime.trending == null) return null;
    return CatalogAudience(listed: anime.popularity, favorited: anime.favourites, trendingActivity: anime.trending);
  }

  static String? _accentColorFor(String? value) {
    final color = value?.trim();
    return color != null && _accentColorPattern.hasMatch(color) ? color.toLowerCase() : null;
  }

  static String? _differentTitle(String? value, String displayTitle) {
    final title = value?.trim();
    if (title == null || title.isEmpty || title.toLowerCase() == displayTitle.toLowerCase()) return null;
    return title;
  }

  static CatalogFormat? _formatFor(String? format) => switch (format) {
    null => null,
    'TV' => CatalogFormat.tv,
    'TV_SHORT' => CatalogFormat.tvShort,
    'MOVIE' => CatalogFormat.movie,
    'SPECIAL' => CatalogFormat.special,
    'OVA' => CatalogFormat.ova,
    'ONA' => CatalogFormat.ona,
    'MUSIC' => CatalogFormat.music,
    _ => CatalogFormat.other,
  };

  static CatalogSourceMaterial? _sourceMaterialFor(String? source) => switch (source) {
    null => null,
    'ORIGINAL' => CatalogSourceMaterial.original,
    'MANGA' || 'COMIC' || 'DOUJINSHI' => CatalogSourceMaterial.manga,
    'LIGHT_NOVEL' => CatalogSourceMaterial.lightNovel,
    'NOVEL' || 'WEB_NOVEL' => CatalogSourceMaterial.novel,
    'VISUAL_NOVEL' => CatalogSourceMaterial.visualNovel,
    'VIDEO_GAME' || 'GAME' => CatalogSourceMaterial.game,
    'WEB_COMIC' => CatalogSourceMaterial.webComic,
    'MUSIC' => CatalogSourceMaterial.musicRelease,
    _ => CatalogSourceMaterial.otherMedia,
  };

  static List<String>? _countriesFor(String? country) {
    final code = country == null ? null : CountryCodes.normalizeCode(country);
    return code == null || code.isEmpty ? null : [code];
  }

  static List<CatalogCredit>? _creditsFor(List<AnilistStaffCredit>? staff) {
    if (staff == null) return null;
    final credits = <CatalogCredit>[];
    for (final member in staff) {
      final role = _creditRoleFor(member.role);
      if (role == null) continue;
      final credit = CatalogCredit(name: member.name, role: role);
      if (!credits.any((existing) => existing.name == credit.name && existing.role == credit.role)) {
        credits.add(credit);
      }
    }
    return credits.isEmpty ? null : credits;
  }

  static CatalogCreditRole? _creditRoleFor(String raw) {
    final role = raw.trim().toLowerCase();
    if (role == 'director' || role == 'series director') return CatalogCreditRole.director;
    if (role == 'writer' || role == 'series composition' || role.contains('script') || role.contains('screenplay')) {
      return CatalogCreditRole.writer;
    }
    if (role == 'music' || role.contains('composer') || role.contains('music composition')) {
      return CatalogCreditRole.composer;
    }
    return null;
  }

  static List<CatalogTag>? _tagsFor(List<AnilistTag>? tags) => tags == null
      ? null
      : [for (final tag in tags) CatalogTag(name: tag.name, rank: tag.rank, isSpoiler: tag.isMediaSpoiler)];

  static List<CatalogLink>? _linksFor(List<AnilistLink>? external, List<AnilistLink>? streaming) {
    final links = <CatalogLink>[];
    for (final link in external ?? const <AnilistLink>[]) {
      links.add(CatalogLink(label: link.label, url: link.url));
    }
    for (final link in streaming ?? const <AnilistLink>[]) {
      final catalogLink = CatalogLink(label: link.label, url: link.url, isStreaming: true);
      final existing = links.indexWhere((candidate) => candidate.url == link.url);
      if (existing == -1) {
        links.add(catalogLink);
      } else {
        links[existing] = catalogLink;
      }
    }
    return links.isEmpty ? null : links;
  }

  static CatalogRelationType _relationTypeFor(String? type) => switch (type) {
    'PREQUEL' => CatalogRelationType.prequel,
    'SEQUEL' => CatalogRelationType.sequel,
    'SIDE_STORY' => CatalogRelationType.sideStory,
    'SPIN_OFF' => CatalogRelationType.spinOff,
    'ALTERNATIVE' => CatalogRelationType.alternativeVersion,
    'SUMMARY' => CatalogRelationType.summary,
    'PARENT' => CatalogRelationType.parentStory,
    'ADAPTATION' => CatalogRelationType.adaptation,
    _ => CatalogRelationType.other,
  };

  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async {
    if (!external.hasAny) return null;
    final rows = await _fribb.lookup(
      anidbId: external.anidb,
      tvdbId: external.tvdb,
      tmdbId: external.tmdb,
      imdbId: external.imdb,
    );
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
