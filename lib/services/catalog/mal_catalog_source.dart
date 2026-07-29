import 'package:collection/collection.dart';

import '../../media/media_kind.dart';
import '../../models/catalog/catalog_cast_member.dart';
import '../../models/catalog/catalog_item.dart';
import '../../models/catalog/catalog_metadata.dart';
import '../../models/mal/mal_anime.dart';
import '../../models/trackers/fribb_mapping_row.dart';
import '../../utils/app_logger.dart';
import '../../utils/external_ids.dart';
import '../trackers/fribb_mapping_store.dart';
import '../trackers/mal/mal_client.dart';
import '../trackers/mal/mal_constants.dart';
import '../trackers/tracker_exceptions.dart';
import 'catalog_source.dart';
import 'catalog_watchlist_machinery.dart';

/// [CatalogSource] backed by the MyAnimeList API.
///
/// Wraps the [MalClient] owned by `MalTracker` (rebound per profile by
/// `TrackersProvider`; never disposed here). MAL is anime-only with no
/// movie/show split, so it serves the anime rows, and its watchlist is the
/// user's Plan to Watch list.
///
/// MAL entries carry no media-server external ids; the Fribb anime-lists
/// mapping bridges both directions: catalog items are enriched with
/// tvdb/tmdb/imdb (library matching, cross-source membership), and library
/// items resolve to a MAL id via [resolveItemIds].
class MalCatalogSource with CatalogWatchlistMachinery implements CatalogSource {
  final MalClient _client;
  final FribbMappingLookup _fribb;

  MalCatalogSource(this._client, {FribbMappingLookup? fribb}) : _fribb = fribb ?? FribbMappingStore.instance;

  @override
  String get watchlistLogLabel => 'MAL: Plan to Watch';

  /// Full-snapshot paging: 4 × 500 covers 2000 Plan to Watch entries.
  @override
  int get watchlistPageLimit => 500;
  @override
  int get watchlistMaxPages => 4;

  @override
  CatalogSourceId get id => CatalogSourceId.mal;

  @override
  String get displayName => 'MyAnimeList';

  @override
  List<CatalogRowId> get supportedRows => const [
    CatalogRowId.watchlist,
    CatalogRowId.suggestedAnime,
    CatalogRowId.airingAnime,
    CatalogRowId.popularAnime,
  ];

  @override
  bool get supportsWatchlist => true;

  @override
  Future<CatalogPage> fetchRow(CatalogRowId row, {int page = 1, int limit = 25}) async {
    final res = switch (row) {
      CatalogRowId.watchlist => await _client.getPlanToWatch(page: page, limit: limit),
      CatalogRowId.suggestedAnime => await _client.getSuggestedAnime(page: page, limit: limit),
      CatalogRowId.airingAnime => await _client.getAnimeRanking(MalRankingType.airing, page: page, limit: limit),
      CatalogRowId.popularAnime => await _client.getAnimeRanking(MalRankingType.bypopularity, page: page, limit: limit),
      CatalogRowId.recommendedMovies ||
      CatalogRowId.recommendedShows ||
      CatalogRowId.trendingMovies ||
      CatalogRowId.trendingShows ||
      CatalogRowId.popularMovies ||
      CatalogRowId.popularShows ||
      CatalogRowId.trendingAnime ||
      CatalogRowId.trending ||
      CatalogRowId.upcomingMovies ||
      CatalogRowId.upcomingShows => throw ArgumentError('MAL does not serve ${row.name}'),
    };
    final rankingScope = switch (row) {
      CatalogRowId.airingAnime => CatalogRankScope.airing,
      CatalogRowId.popularAnime => CatalogRankScope.popular,
      _ => null,
    };
    return CatalogPage(
      items: await _toCatalogItems(res.items, rankingRanks: res.rankingRanks, rankingScope: rankingScope),
      hasMore: res.hasMore,
    );
  }

  /// MAL rejects queries under 3 characters (`invalid q`) — return empty
  /// instead of surfacing a 400 while the user is still typing.
  @override
  Future<List<CatalogItem>> search(String query, {int limit = 30}) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];
    final res = await _client.searchAnime(trimmed, limit: limit);
    return _toCatalogItems(res.items);
  }

  @override
  Future<CatalogDetail> fetchDetail(CatalogItem item, {int castLimit = 20, int relatedLimit = 20}) async {
    final malId = item.ids.mal;
    if (malId == null) return CatalogDetail(item: item);

    final responses = await Future.wait<Object?>([_loadAnimeDetail(malId, relatedLimit), _loadCast(malId, castLimit)]);
    final detail = responses[0] as MalAnimeDetail?;
    final cast = responses[1] as List<CatalogCastMember>;
    if (detail == null) return CatalogDetail(item: item, cast: cast);

    final recommendations = [
      for (final recommendation in detail.recommendations)
        if (recommendation.anime.id != null) recommendation,
    ];
    final relationEntries = [
      for (final relation in detail.relations)
        if (relation.anime.id != null) relation,
    ];
    final mapped = await Future.wait([
      _toCatalogItems(
        [for (final recommendation in recommendations) recommendation.anime],
        recommendationCounts: [for (final recommendation in recommendations) recommendation.count],
      ),
      _toCatalogItems([for (final relation in relationEntries) relation.anime]),
    ]);
    final related = mapped[0];
    final relationItems = mapped[1];
    final groupedRelations = <CatalogRelationType, List<CatalogItem>>{};
    for (var i = 0; i < relationEntries.length; i++) {
      groupedRelations
          .putIfAbsent(_relationTypeFor(relationEntries[i].type), () => <CatalogItem>[])
          .add(relationItems[i]);
    }

    final detailPosterUrl = detail.anime.mainPicture?.primary ?? item.posterUrl;
    final detailItem = _toCatalogItem(
      detail.anime,
      null,
      statistics: detail.statistics,
      gallery: _galleryFor(detail.pictures, detailPosterUrl),
      background: detail.background,
    );
    return CatalogDetail(
      item: item.enrichedWith(detailItem),
      cast: cast,
      related: related,
      relations: [for (final entry in groupedRelations.entries) CatalogRelation(type: entry.key, items: entry.value)],
    );
  }

  /// Enrich concurrently so all items share one Fribb index load (per-item
  /// awaits would retry the download for every item when it is failing).
  Future<List<CatalogItem>> _toCatalogItems(
    List<MalAnime> anime, {
    List<int?> rankingRanks = const [],
    CatalogRankScope? rankingScope,
    List<int?> recommendationCounts = const [],
  }) async {
    final withIds = <MalAnime>[];
    final originalIndexes = <int>[];
    for (var i = 0; i < anime.length; i++) {
      if (anime[i].id == null) continue;
      withIds.add(anime[i]);
      originalIndexes.add(i);
    }
    final rows = await Future.wait([for (final entry in withIds) _fribb.lookupByMal(entry.id!)]);
    return [
      for (var i = 0; i < withIds.length; i++)
        _toCatalogItem(
          withIds[i],
          rows[i],
          rankingRank: originalIndexes[i] < rankingRanks.length ? rankingRanks[originalIndexes[i]] : null,
          rankingScope: rankingScope,
          recommendationCount: originalIndexes[i] < recommendationCounts.length
              ? recommendationCounts[originalIndexes[i]]
              : null,
        ),
    ];
  }

  /// Normalize MAL's status strings. `finished_airing` on a movie maps to
  /// null — an "Ended" chip on every movie is noise.
  static CatalogAirStatus? airStatusFor(MalAnime anime) => switch (anime.status) {
    'currently_airing' => CatalogAirStatus.airing,
    'finished_airing' => anime.isMovie ? null : CatalogAirStatus.ended,
    'not_yet_aired' => CatalogAirStatus.upcoming,
    _ => null,
  };

  CatalogItem _toCatalogItem(
    MalAnime anime,
    FribbMappingRow? row, {
    int? rankingRank,
    CatalogRankScope? rankingScope,
    int? recommendationCount,
    MalStatistics? statistics,
    List<String>? gallery,
    String? background,
  }) {
    final title = anime.displayTitle;
    final originalTitle = anime.title;
    return CatalogItem(
      source: CatalogSourceId.mal,
      kind: anime.isMovie ? MediaKind.movie : MediaKind.show,
      title: title,
      // Set literal: insertion-ordered and deduped. MAL repeats the English
      // and romaji titles inside `synonyms`, and a duplicate candidate costs
      // the reverse library lookup a wasted request.
      altTitles: <String>{
        for (final candidate in <String?>[
          anime.alternativeTitles?.en,
          anime.title,
          anime.alternativeTitles?.ja,
          ...?anime.alternativeTitles?.synonyms,
        ])
          if (candidate != null && candidate.isNotEmpty && candidate != title) candidate,
      }.toList(),
      year: anime.year,
      overview: anime.synopsis,
      runtimeMinutes: anime.runtimeMinutes,
      rating: anime.mean,
      votes: anime.numScoringUsers,
      genres: anime.genreNames,
      certification: anime.certification,
      airStatus: airStatusFor(anime),
      episodeCount: anime.isMovie || (anime.numEpisodes ?? 0) <= 0 ? null : anime.numEpisodes,
      network: anime.primaryStudio,
      ids: CatalogItemIds(
        mal: anime.id,
        anilist: row?.anilistId,
        simkl: row?.simklId,
        imdb: row?.imdbIds?.firstOrNull,
        tmdb: row?.tmdbIds?.firstOrNull,
        tvdb: row?.tvdbId,
      ),
      // Which season of the parent series this entry maps to, for the reverse
      // library lookup — distinct from the calendar broadcastSeason below.
      season: row == null || (row.tvdbSeason == null && row.tmdbSeason == null)
          ? null
          : ExternalSeasonRef(tvdb: row.tvdbSeason, tmdb: row.tmdbSeason),
      posterUrl: anime.mainPicture?.primary,
      ranks: _ranksFor(anime, rankingRank: rankingRank, rankingScope: rankingScope),
      audience: _audienceFor(anime, statistics),
      broadcast: _broadcastFor(anime.broadcast),
      endDate: _dateFor(anime.endDate),
      originalTitle: originalTitle != null && originalTitle.isNotEmpty && originalTitle != title ? originalTitle : null,
      broadcastSeason: _seasonFor(anime.startSeason),
      sourceMaterial: _sourceMaterialFor(anime.source),
      isAdult: _isAdultFor(anime.nsfw),
      recommendationCount: recommendationCount,
      gallery: gallery,
      background: background,
    );
  }

  Future<MalAnimeDetail?> _loadAnimeDetail(int malId, int relatedLimit) async {
    try {
      return await _client.getAnimeDetail(malId, relatedLimit: relatedLimit);
    } catch (e, st) {
      appLogger.w('MAL: anime detail load failed', error: e, stackTrace: st);
      return null;
    }
  }

  Future<List<CatalogCastMember>> _loadCast(int malId, int limit) async {
    try {
      final res = await _client.getAnimeCharacters(malId, limit: limit);
      return [
        for (final character in res.items)
          if (character.name.isNotEmpty)
            CatalogCastMember(name: character.name, secondary: character.role, imageUrl: character.imageUrl),
      ];
    } catch (e, st) {
      appLogger.w('MAL: character load failed', error: e, stackTrace: st);
      return const [];
    }
  }

  static List<CatalogRank>? _ranksFor(MalAnime anime, {int? rankingRank, CatalogRankScope? rankingScope}) {
    final ranks = <CatalogRank>[];
    var rowRankIsPopular = false;
    if (rankingRank != null && rankingRank > 0 && rankingScope != null) {
      ranks.add(CatalogRank(rank: rankingRank, scope: rankingScope, allTime: true));
      rowRankIsPopular = rankingScope == CatalogRankScope.popular;
    }
    final popularity = anime.popularity;
    if (popularity != null && popularity > 0 && !rowRankIsPopular) {
      ranks.add(CatalogRank(rank: popularity, scope: CatalogRankScope.popular, allTime: true));
    }
    final scoreRank = anime.rank;
    if (scoreRank != null && scoreRank > 0) {
      ranks.add(CatalogRank(rank: scoreRank, scope: CatalogRankScope.rated, allTime: true));
    }
    return ranks.isEmpty ? null : ranks;
  }

  static CatalogAudience? _audienceFor(MalAnime anime, MalStatistics? statistics) {
    final audience = CatalogAudience(
      listed: statistics?.numListUsers ?? anime.numListUsers,
      planning: statistics?.planToWatch,
      watching: statistics?.watching,
      completed: statistics?.completed,
      onHold: statistics?.onHold,
      dropped: statistics?.dropped,
    );
    return audience.isEmpty ? null : audience;
  }

  static CatalogBroadcast? _broadcastFor(MalBroadcast? broadcast) {
    if (broadcast == null) return null;
    final weekday = switch (broadcast.dayOfTheWeek?.toLowerCase()) {
      'monday' => DateTime.monday,
      'tuesday' => DateTime.tuesday,
      'wednesday' => DateTime.wednesday,
      'thursday' => DateTime.thursday,
      'friday' => DateTime.friday,
      'saturday' => DateTime.saturday,
      'sunday' => DateTime.sunday,
      _ => null,
    };
    final time = _normalizedTime(broadcast.startTime);
    if (weekday == null && time == null) return null;
    return CatalogBroadcast(weekday: weekday, time: time, timezone: 'Asia/Tokyo');
  }

  static String? _normalizedTime(String? value) {
    if (value == null || value.length != 5 || value[2] != ':') return null;
    final hour = int.tryParse(value.substring(0, 2));
    final minute = int.tryParse(value.substring(3));
    if (hour == null || hour < 0 || hour > 23 || minute == null || minute < 0 || minute > 59) {
      return null;
    }
    return value;
  }

  static CatalogSeasonInfo? _seasonFor(MalStartSeason? season) {
    final name = CatalogSeasonInfo.parseName(season?.season);
    return name == null ? null : CatalogSeasonInfo(name: name, year: season?.year);
  }

  static CatalogSourceMaterial? _sourceMaterialFor(String? source) => switch (source) {
    null || '' => null,
    'original' => CatalogSourceMaterial.original,
    'manga' || '4_koma_manga' || 'digital_manga' => CatalogSourceMaterial.manga,
    'light_novel' => CatalogSourceMaterial.lightNovel,
    'novel' => CatalogSourceMaterial.novel,
    'visual_novel' => CatalogSourceMaterial.visualNovel,
    'game' || 'card_game' => CatalogSourceMaterial.game,
    'web_manga' => CatalogSourceMaterial.webComic,
    'music' => CatalogSourceMaterial.musicRelease,
    _ => CatalogSourceMaterial.otherMedia,
  };

  static bool? _isAdultFor(String? nsfw) => switch (nsfw) {
    'gray' || 'black' => true,
    'white' => false,
    _ => null,
  };

  static DateTime? _dateFor(String? value) => value == null ? null : DateTime.tryParse(value);

  static List<String>? _galleryFor(List<MalPicture> pictures, String? posterUrl) {
    final urls = <String>{};
    for (final picture in pictures) {
      final url = picture.primary;
      if (url != null && url != posterUrl) urls.add(url);
    }
    return urls.isEmpty ? null : urls.toList(growable: false);
  }

  static CatalogRelationType _relationTypeFor(String? type) => switch (type) {
    'prequel' => CatalogRelationType.prequel,
    'sequel' => CatalogRelationType.sequel,
    'side_story' => CatalogRelationType.sideStory,
    'spin_off' => CatalogRelationType.spinOff,
    'alternative_version' => CatalogRelationType.alternativeVersion,
    'summary' => CatalogRelationType.summary,
    'parent_story' => CatalogRelationType.parentStory,
    'adaptation' => CatalogRelationType.adaptation,
    _ => CatalogRelationType.other,
  };

  /// Reverse-map a library item's external ids to its MAL entry. A show-level
  /// id can resolve to several rows (split-cour anime, one row per season);
  /// prefer season 1 — "add this show" means its first season on MAL. Null
  /// (non-anime) hides the watchlist action.
  @override
  Future<CatalogItemIds?> resolveItemIds(MediaKind kind, ExternalIds external) async {
    if (!external.hasAny) return null;
    final rows = await _fribb.lookup(tvdbId: external.tvdb, tmdbId: external.tmdb, imdbId: external.imdb);
    final malId = _pickRow(kind, rows)?.malId;
    if (malId == null) return null;
    return CatalogItemIds(mal: malId, imdb: external.imdb, tmdb: external.tmdb, tvdb: external.tvdb);
  }

  static FribbMappingRow? _pickRow(MediaKind kind, List<FribbMappingRow> rows) {
    final withMal = [
      for (final row in rows)
        if (row.malId != null) row,
    ];
    if (withMal.isEmpty) return null;
    if (kind == MediaKind.movie) {
      return withMal.firstWhereOrNull((row) => row.isMovie) ?? withMal.first;
    }
    return withMal.firstWhereOrNull((row) => row.tvdbSeason == 1 || row.tmdbSeason == 1) ?? withMal.first;
  }

  /// MAL ids are globally unique across anime, so membership keys skip the
  /// kind namespace — a library movie and a MAL `ova` entry for the same
  /// title still agree.
  static String _membershipKey(int malId) => 'mal:$malId';

  @override
  List<String> membershipKeysFor(MediaKind kind, CatalogItemIds ids) => [
    if (ids.mal case final int malId) _membershipKey(malId),
  ];

  @override
  Future<WatchlistKeyPage> fetchWatchlistKeyPage(int page, int limit) async {
    final res = await _client.getPlanToWatch(page: page, limit: limit);
    return (
      groups: [
        for (final anime in res.items)
          if (anime.id != null) [_membershipKey(anime.id!)],
      ],
      hasMore: res.hasMore,
    );
  }

  @override
  Future<CatalogItemIds> resolveWatchlistMutationIds(MediaKind kind, CatalogItemIds ids) async {
    final malId = ids.mal ?? (await resolveItemIds(kind, ids.toExternalIds()))?.mal;
    if (malId == null) {
      throw StateError('MAL: no anime mapping for ${ids.canonicalKey ?? 'item'}');
    }
    return CatalogItemIds(mal: malId, imdb: ids.imdb, tmdb: ids.tmdb, tvdb: ids.tvdb);
  }

  @override
  Future<void> performWatchlistMutation(MediaKind kind, CatalogItemIds ids, {required bool add}) async {
    final malId = ids.mal!;
    if (add) {
      await _client.updateMyListStatus(malId, const {'status': 'plan_to_watch'});
    } else {
      await _deleteEntry(malId);
    }
  }

  /// Removing an entry that is already gone is success, not failure.
  Future<void> _deleteEntry(int malId) async {
    try {
      await _client.deleteMyListStatus(malId);
    } on TrackerApiException catch (e) {
      if (e.statusCode == 404) return;
      rethrow;
    }
  }

  @override
  void dispose() {
    disposeWatchlistMachinery();
  }
}
