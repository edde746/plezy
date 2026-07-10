part of '../../jellyfin_client.dart';

String _segment(String value) => Uri.encodeComponent(value);

/// Transport policy for a hub surface: bounded transient retries, no
/// endpoint failover. See `_getItemsResponse`.
typedef _HubRetryPolicy = ({String operation, List<Duration> attemptTimeouts});

const _HubRetryPolicy _homeHubRetry = (
  operation: 'Jellyfin home hubs',
  attemptTimeouts: MediaServerTimeouts.homeHubAttemptTimeouts,
);

const _HubRetryPolicy _libraryHubRetry = (
  operation: 'Jellyfin library hubs',
  attemptTimeouts: MediaServerTimeouts.libraryHubAttemptTimeouts,
);

const _HubRetryPolicy _continueWatchingRetry = (
  operation: 'Jellyfin continue watching',
  attemptTimeouts: MediaServerTimeouts.homeHubAttemptTimeouts,
);

List<Map<String, dynamic>> _itemsArray(Object? data) {
  if (data is Map<String, dynamic>) {
    final items = data['Items'];
    if (items is List) return items.whereType<Map<String, dynamic>>().toList();
  }
  if (data is List) return data.whereType<Map<String, dynamic>>().toList();
  return const [];
}

/// Slim field set for grid/list browsing — what the card UI actually
/// renders (title, year, watched badge, episode count for series).
///
/// The real Jellyfin web client + Findroid skip explicit `Fields` for
/// list calls; we ask for the minimum extras needed to drive the
/// MediaItem mapper:
///  - `RecursiveItemCount`/`ChildCount` for series leaf count
///  - `UserData` is included in defaults but pinned for safety
///  - `PremiereDate` for sort-by-release-date and episode metadata
///  - `OriginalTitle`/`SortName` for sort + alphabetised display
///  - `Overview` so list rows can show their description
///
/// Heavier fields (`MediaSources`, `People`, `Genres`, `Tags`, `Studios`,
/// `Taglines`, `ProviderIds`, `Chapters`) stay in [_detailFields] — together
/// they added seconds to large-library pages on small home servers.
const _browseFields = 'RecursiveItemCount,ChildCount,UserData,PremiereDate,OriginalTitle,SortName,Overview';

/// Existing episode-row requests can show Plex-style quality labels when the
/// response includes `MediaSources`. Keep this off broad library/search/latest
/// queries because it is the heaviest item field Jellyfin returns.
const _episodeRowFields = '$_browseFields,MediaSources';

/// Folder-tree field set for MEDIA children. The tree renders
/// title/thumb/watch state plus default dto fields (year, runtime, ratings);
/// it deliberately skips `RecursiveItemCount`/`ChildCount` — per-item COUNT
/// queries the server runs for every folder/series row, which made large
/// folder listings very slow — and `Overview`, which the tree never shows.
/// Jellyfin web's folder view requests none of them either. The unwatched
/// badge survives via `UserData.UnplayedItemCount`
/// ([MediaItem.unwatchedCount] fallback).
const _folderBrowseFields = 'UserData,PremiereDate,OriginalTitle,SortName';

/// Folder-tree field set for FILESYSTEM FOLDER children, which render only
/// their name. Queried with `EnableUserData=false`: user data on a folder dto
/// makes the server compute a recursive unplayed count per folder, by far the
/// dominant cost of folder browsing (see [_fetchFolderChildren]).
const _folderRowFields = 'SortName';

/// Even slimmer set used by [fetchClientSideEpisodeQueue]. Queue rows
/// only need title, thumbnail (`ImageTags['Primary']`), season/episode
/// index, watched state, and the air date that drives the watch order.
/// Title + indices come back without any `Fields` request; we ask for
/// `UserData` (watched indicator) and `PremiereDate` (air-date sort, so
/// Specials interleave — see [compareEpisodesByWatchOrder]). Drops
/// `Overview` etc. so even a thousand-episode shounen show fits in one
/// response.
const _queueFields = 'UserData,PremiereDate';

/// Page size for [fetchClientSideEpisodeQueue]. Keeps each server response
/// bounded while still returning the full series queue.
const _episodeQueuePageSize = 200;

/// How many recently played episodes to scan when stamping `/Shows/NextUp`
/// rows with their series' last-watched date (see [_attachSeriesLastPlayed]).
/// Mirrors [_episodeQueuePageSize]; covers far more distinct series than the
/// Next Up list ever returns, while keeping the response bounded.
const _continueWatchingSeriesLookback = 200;

const _childrenPageSize = 500;
const _pagedListPageSize = 200;
const _playableDescendantTypes = 'Movie,Episode,Audio';
const _playableFolderDescendantTypes = 'Movie,Episode,Video,MusicVideo';
const _episodeOrderQueryParameters = {
  'SortBy': 'ParentIndexNumber,IndexNumber,SortName',
  'SortOrder': 'Ascending,Ascending,Ascending',
};

bool _isJellyfinFolderDto(Map<String, dynamic> item) {
  final type = (item['Type'] as String?)?.toLowerCase();
  return type == 'folder' || type == 'collectionfolder' || (type == null && item['IsFolder'] == true);
}

String _jellyfinFolderSortName(Map<String, dynamic> item) {
  final raw = item['SortName'] as String? ?? item['Name'] as String? ?? '';
  return raw.toLowerCase();
}

int _fallbackPageTotal({required int offset, required int itemCount, int? requestedSize}) {
  if (requestedSize == null || requestedSize <= 0 || itemCount < requestedSize) {
    return offset + itemCount;
  }
  return offset + itemCount + 1;
}

/// `/Items/Filters` is a legacy unpaged endpoint; keep failures isolated from
/// the paged Browse tab so very large libraries can still open.
const _filtersTimeout = Duration(seconds: 8);

/// Full field set for the detail screen and the resume / next-up
/// pre-fetch paths. Mirrors what the Jellyfin web detail view requests.
const _detailFields =
    'Overview,Genres,People,Studios,ProductionLocations,Tags,Taglines,DateCreated,DateLastSaved,'
    'PremiereDate,RecursiveItemCount,ChildCount,UserData,MediaSources,OriginalTitle,SortName,'
    // Chapters: Jellyfin returns them at the item level; the playback
    // init flow plucks `raw['Chapters']` and feeds the seek-bar tick UI.
    'Chapters,'
    // Trickplay: per-resolution sprite-sheet manifest. The scrub-thumbnail
    // loader reads `raw['Trickplay']` and computes tile URLs from it.
    'Trickplay,'
    // ProviderIds carries Tmdb/Imdb/Tvdb keys — required for Trakt + the
    // unified tracker coordinator to scrobble Jellyfin items without
    // any extra round-trip.
    'ProviderIds';

mixin _JellyfinBrowseMethods on MediaServerCacheMixin {
  JellyfinConnection get connection;
  FailoverHttpClient get _http;
  MediaItem? _mapItem(Map<String, dynamic> json);
  List<MediaItem> _mapItems(Iterable<Map<String, dynamic>> items);

  // Endpoint conventions follow what the official Jellyfin Kotlin SDK
  // generates (cross-checked against the Findroid client). The SDK mixes
  // `/Users/{userId}/...` for "user library" / "views" / "latest" / "single
  // item" calls and `/Items?userId=...` for the generic list and resume
  // endpoints. We mirror that exactly so requests hash the same way against
  // proxy rules and rate limiters as a stock Jellyfin app.

  @override
  Future<List<MediaLibrary>> fetchLibraries() async {
    final response = await _http.get('/Users/${_segment(connection.userId)}/Views');
    throwIfHttpError(response);
    final items = _itemsArray(response.data);
    // Jellyfin surfaces the user's collection (BoxSet) and playlist roots as
    // top-level views. We expose those as per-library tabs instead of
    // standalone library entries — matches the Plex shape and avoids
    // duplicating the same data in two navigation slots.
    return items
        .where((view) {
          final ct = (view['CollectionType'] as String?)?.toLowerCase();
          return ct != 'boxsets' && ct != 'playlists';
        })
        .map((view) => JellyfinMappers.library(view, serverId: serverId, serverName: serverName))
        .whereType<MediaLibrary>()
        .toList();
  }

  @override
  Future<LibraryPage<MediaItem>> fetchLibraryContent(
    String libraryId,
    LibraryQuery query, {
    AbortController? abort,
  }) async {
    final translator = JellyfinLibraryQueryTranslator(
      userId: connection.userId,
      parentId: libraryId,
      fields: _browseFields,
    );
    final params = translator.toQueryParameters(query);

    // Artist browsing routes to `/Artists/AlbumArtists` instead of
    // `/Items?IncludeItemTypes=MusicArtist`: the /Items query only returns
    // folder-derived artists under their folder names, missing tag-only
    // per-track artists entirely (and folder names can differ from the tag
    // names shown everywhere else). AlbumArtists matches Plex's "album
    // artists" library semantic. The branch lives here rather than in the
    // translator because the translator's contract is query *parameters*
    // only — the endpoint choice is client routing, like the seasons vs
    // generic-children split in [fetchChildrenPage]. The artists endpoint
    // accepts the same paging/sort/filter/prefix params /Items does
    // (ParentId, StartIndex, Limit, SortBy/SortOrder, NameStartsWith/
    // NameLessThan, Filters, Fields) and ignores the /Items-only keys.
    final isArtistQuery = query.kind == MediaKind.artist;
    final endpoint = isArtistQuery ? '/Artists/AlbumArtists' : '/Items';
    if (isArtistQuery) {
      params.remove('IncludeItemTypes');
      params.remove('Recursive');
    }

    final response = await _http.get(endpoint, queryParameters: params, abort: abort);
    throwIfHttpError(response);
    final data = response.data;
    final items = _itemsArray(data);
    final rawTotal = data is Map<String, dynamic> ? data['TotalRecordCount'] : null;
    // /Artists/AlbumArtists reports TotalRecordCount=0 when NameStartsWith /
    // NameLessThan are set (server-side counting quirk, observed on 10.11);
    // treat that as "unknown" so the alpha-prefix filter can still page.
    final totalUnreliable = isArtistQuery && rawTotal == 0 && items.isNotEmpty;
    final total = rawTotal is int && !totalUnreliable
        ? rawTotal
        : _fallbackPageTotal(offset: query.offset, itemCount: items.length, requestedSize: query.limit);
    return LibraryPage<MediaItem>(items: _mapItems(items), totalCount: total, offset: query.offset);
  }

  /// Jellyfin's `/Items/Filters` returns Genres / OfficialRatings / Tags /
  /// Categories + values from `/Items/Filters` in a single call. The unwatched
  /// boolean is synthetic because Jellyfin exposes it as an `/Items` query
  /// filter, not a filter-listing category. Keys are translated to Plex's
  /// filter naming so the existing filter-param map round-trips through
  /// `_buildFilterParams` unchanged; the synthesised `MediaFilter.key` is
  /// prefixed `jellyfin:` so FiltersBottomSheet can recognise it as cached and
  /// skip the per-category value fetch.
  @override
  Future<LibraryFilterResult> fetchLibraryFiltersWithValues(String libraryId) async {
    final filters = <MediaFilter>[
      MediaFilter(
        filter: 'unwatched',
        filterType: 'boolean',
        key: 'jellyfin:unwatched',
        title: t.libraries.filterCategories.unwatched,
        type: 'filter',
      ),
      MediaFilter(
        filter: 'favorite',
        filterType: 'boolean',
        key: 'jellyfin:favorite',
        title: t.libraries.filterCategories.favorites,
        type: 'filter',
      ),
    ];
    final data = await _safeFetchFilterPayload(libraryId);
    if (data == null) return LibraryFilterResult(filters: filters, cachedValues: const {});
    List<String> stringList(Object? raw) {
      if (raw is! List) return const [];
      return raw.whereType<String>().where((s) => s.isNotEmpty).toList();
    }

    final raw = <String, List<String>>{
      'genre': stringList(data['Genres']),
      'contentRating': stringList(data['OfficialRatings']),
      'tag': stringList(data['Tags']),
      'year': (data['Years'] is List)
          ? (data['Years'] as List).whereType<num>().map((y) => y.toInt().toString()).toList()
          : const <String>[],
    };

    const order = ['genre', 'year', 'contentRating', 'tag'];
    final titles = {
      'genre': t.libraries.filterCategories.genre,
      'year': t.libraries.filterCategories.year,
      'contentRating': t.libraries.filterCategories.contentRating,
      'tag': t.libraries.filterCategories.tag,
    };
    final values = <String, List<MediaFilterValue>>{};
    for (final key in order) {
      final entries = raw[key];
      if (entries == null || entries.isEmpty) continue;
      filters.add(
        MediaFilter(filter: key, filterType: 'string', key: 'jellyfin:$key', title: titles[key] ?? key, type: 'filter'),
      );
      final sorted = List<String>.from(entries);
      if (key == 'year') {
        sorted.sort((a, b) => (int.tryParse(b) ?? 0).compareTo(int.tryParse(a) ?? 0));
      } else {
        sorted.sort();
      }
      values[key] = sorted.map((v) => MediaFilterValue(key: v, title: v)).toList();
    }
    return LibraryFilterResult(filters: filters, cachedValues: values);
  }

  Future<Map<String, dynamic>?> _safeFetchFilterPayload(String libraryId) async {
    try {
      final response = await _http.get(
        '/Items/Filters',
        queryParameters: {'userId': connection.userId, 'ParentId': libraryId},
        timeout: _filtersTimeout,
      );
      throwIfHttpError(response);
      final data = response.data;
      return data is Map<String, dynamic> ? data : null;
    } on MediaServerHttpException catch (e, st) {
      if (!e.isTransient) rethrow;
      appLogger.w('JellyfinClient: /Items/Filters timed out (filters disabled)', error: e, stackTrace: st);
      return null;
    }
  }

  /// Jellyfin has no `/sorts` listing endpoint, so this returns a hardcoded
  /// list based on the broad sort set Streamyfin exposes. Keys remain
  /// backend-neutral where Plezy already had saved preferences (`rating`,
  /// `lastViewedAt`, …); [JellyfinLibraryQueryTranslator] maps them to
  /// Jellyfin's `SortBy`/`SortOrder` at request time.
  @override
  Future<List<MediaSort>> fetchSortOptions(String libraryId, {String? libraryType}) async {
    final sorts = [
      MediaSort(key: 'title', descKey: 'title:desc', title: t.libraries.sortLabels.title, defaultDirection: 'asc'),
      MediaSort(
        key: 'rating',
        descKey: 'rating:desc',
        title: t.libraries.sortLabels.communityRating,
        defaultDirection: 'desc',
      ),
      MediaSort(
        key: 'criticRating',
        descKey: 'criticRating:desc',
        title: t.libraries.sortLabels.criticRating,
        defaultDirection: 'desc',
      ),
      MediaSort(
        key: 'addedAt',
        descKey: 'addedAt:desc',
        title: t.libraries.sortLabels.dateAdded,
        defaultDirection: 'desc',
      ),
      MediaSort(
        key: 'lastViewedAt',
        descKey: 'lastViewedAt:desc',
        title: t.libraries.sortLabels.datePlayed,
        defaultDirection: 'desc',
      ),
      MediaSort(
        key: 'viewCount',
        descKey: 'viewCount:desc',
        title: t.libraries.sortLabels.playCount,
        defaultDirection: 'desc',
      ),
      MediaSort(
        key: 'productionYear',
        descKey: 'productionYear:desc',
        title: t.libraries.sortLabels.productionYear,
        defaultDirection: 'desc',
      ),
      MediaSort(
        key: 'runtime',
        descKey: 'runtime:desc',
        title: t.libraries.sortLabels.runtime,
        defaultDirection: 'desc',
      ),
      MediaSort(
        key: 'officialRating',
        descKey: 'officialRating:desc',
        title: t.libraries.sortLabels.officialRating,
        defaultDirection: 'asc',
      ),
      MediaSort(
        key: 'originallyAvailableAt',
        descKey: 'originallyAvailableAt:desc',
        title: t.libraries.sortLabels.premiereDate,
        defaultDirection: 'desc',
      ),
      MediaSort(
        key: 'startDate',
        descKey: 'startDate:desc',
        title: t.libraries.sortLabels.startDate,
        defaultDirection: 'asc',
      ),
      MediaSort(
        key: 'airTime',
        descKey: 'airTime:desc',
        title: t.libraries.sortLabels.airTime,
        defaultDirection: 'asc',
      ),
      MediaSort(key: 'studio', descKey: 'studio:desc', title: t.libraries.sortLabels.studio, defaultDirection: 'asc'),
      MediaSort(key: 'random', title: t.libraries.sortLabels.random, defaultDirection: 'asc'),
    ];

    if (libraryType?.toLowerCase() == 'show') {
      sorts.insert(
        4,
        MediaSort(
          key: 'episode.addedAt',
          descKey: 'episode.addedAt:desc',
          title: t.libraries.sortLabels.lastEpisodeDateAdded,
          defaultDirection: 'desc',
        ),
      );
    }

    return sorts;
  }

  /// Jellyfin internalisation of the Plex-style filter map → [LibraryQuery]
  /// translation. Routes through [fetchLibraryContent] so the
  /// [JellyfinLibraryQueryTranslator] handles the actual `/Items` query.
  ///
  /// [libraryKind] threads through so a "Shows" library returns Series rows
  /// rather than the recursive episode expansion Jellyfin would otherwise
  /// produce.
  @override
  Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(
    String libraryId, {
    required LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  }) async {
    // [libraryKind] is only a fallback for library-default browsing. Explicit
    // grouping types on [query] (seasons/episodes) must keep priority.
    final effective = (query.kind == null && libraryKind != null && libraryKind != MediaKind.unknown)
        ? query.copyWith(kind: libraryKind)
        : query;
    return fetchLibraryContent(libraryId, effective, abort: abort);
  }

  /// Synthesised 27-letter alphabet — Jellyfin has no equivalent of Plex's
  /// `/firstCharacter` endpoint, so the UI treats the bar as a name-prefix
  /// filter instead of a scroll affordance. Each entry has `size: 1` so
  /// the alpha-jump helper renders it without trying to do offset math.
  @override
  Future<List<LibraryFirstCharacter>> fetchFirstCharacters(String libraryId, {Map<String, String>? filters}) async {
    const letters = [
      '#',
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
    ];
    return [for (final l in letters) LibraryFirstCharacter(key: l, title: l, size: 1)];
  }

  /// Queue a metadata refresh for the library. Jellyfin treats a library
  /// view as an item, so we POST to `/Items/{id}/Refresh`. `FullRefresh`
  /// re-pulls metadata from configured providers; `replaceAllMetadata=false`
  /// preserves user edits — same UX as Plex's `refresh?force=1`.
  @override
  Future<void> refreshLibraryMetadata(String libraryId) async {
    final response = await _http.post(
      '/Items/${_segment(libraryId)}/Refresh',
      queryParameters: {
        'metadataRefreshMode': 'FullRefresh',
        'imageRefreshMode': 'Default',
        'replaceAllMetadata': 'false',
        'replaceAllImages': 'false',
      },
    );
    throwIfHttpError(response);
  }

  /// Jellyfin has no single-round-trip equivalent of Plex's
  /// `?includeOnDeck=1`. We approximate it for shows by chaining a second
  /// request to `/Shows/NextUp` filtered by `seriesId`. NextUp's defaults
  /// (`enableResumable=true`, `disableFirstEpisode=false`) match Plex
  /// OnDeck semantics: returns the resume episode when one exists, or S1E1
  /// when the user hasn't started. Movies and other kinds short-circuit.
  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(String id) async {
    final item = await fetchItem(id);
    if (item == null || item.kind != MediaKind.show) {
      return (item: item, onDeckEpisode: null);
    }
    final nextUp = await _safeFetchItemsArray('/Shows/NextUp', {
      'seriesId': id,
      'userId': connection.userId,
      'Limit': '1',
      'Fields': _episodeRowFields,
      ...jellyfinImageQueryParameters,
    });
    final onDeckEpisode = nextUp.isEmpty ? null : _mapItem(nextUp.first);
    return (item: item, onDeckEpisode: onDeckEpisode);
  }

  @override
  Future<MediaItem?> fetchItem(String id) async {
    final endpoint = '/Users/${_segment(connection.userId)}/Items/${_segment(id)}';
    // Contract:
    //   - 200 with parseable Map → MediaItem
    //   - 200 with non-Map body (HTML/text proxy page, empty) → null
    //   - 404 → null (item doesn't exist server-side)
    //   - 401/403/5xx → throw [MediaServerHttpException] so the UI can
    //     surface "auth required" / "server unavailable". Falling back to
    //     a cached row here would mislead the user into thinking they're
    //     still connected — explicit cache reads belong to the offline path.
    //   - Pure transport errors (no HTTP response) → fall back to cached row
    //     when present, otherwise rethrow.
    if (isOfflineMode) {
      final cached = await cache.get(ServerId(cacheServerId), endpoint);
      if (cached is Map<String, dynamic>) return _mapItem(cached);
      return null;
    }
    try {
      final response = await _http.get(endpoint, queryParameters: {'Fields': _detailFields});
      throwIfHttpError(response);
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      try {
        await cache.put(ServerId(cacheServerId), endpoint, data);
      } catch (e, st) {
        appLogger.w('JellyfinClient.fetchItem cache write failed', error: e, stackTrace: st);
      }
      return _mapItem(data);
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    } catch (e) {
      // Transport-layer failure: socket error, DNS, TLS, etc. Try cache.
      appLogger.w('JellyfinClient.fetchItem network call failed', error: e);
      try {
        final cached = await cache.get(ServerId(cacheServerId), endpoint);
        if (cached is Map<String, dynamic>) return _mapItem(cached);
      } catch (cacheError, st) {
        appLogger.w('JellyfinClient.fetchItem cache fallback failed', error: cacheError, stackTrace: st);
      }
      rethrow;
    }
  }

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) => _fetchChildrenInternal(parentId);

  /// [fetchChildren] plus incremental delivery: [onPage] receives the
  /// accumulated items after each intermediate page of the generic
  /// direct-children query — never for single-page listings, the final page,
  /// or the single-shot seasons response.
  Future<List<MediaItem>> _fetchChildrenInternal(
    String parentId, {
    void Function(List<MediaItem> itemsSoFar)? onPage,
  }) async {
    // Cache keys include userId so two users on the same server don't share
    // per-user UserData (watched state) baked into the response.
    final seasonsKey = '/Shows/$parentId/Seasons?userId=${connection.userId}';
    final childrenKey = '/Items?ParentId=$parentId&userId=${connection.userId}';

    if (isOfflineMode) {
      final cachedSeasons = await cache.get(ServerId(cacheServerId), seasonsKey);
      if (cachedSeasons != null) {
        final items = _itemsArray(cachedSeasons);
        if (items.isNotEmpty) return _mapItems(items);
      }
      final cachedChildren = await cache.get(ServerId(cacheServerId), childrenKey);
      if (cachedChildren != null) {
        return _mapItems(_itemsArray(cachedChildren));
      }
      return const [];
    }

    // For a series, the direct children are SEASONS (not the recursive
    // episode expansion). Match Findroid: showsApi.getSeasons(seriesId)
    // → /Shows/{seriesId}/Seasons. If the parent isn't a series this
    // returns an empty list (or 404), so we fall through.
    try {
      final seasons = await _http.get(
        '/Shows/${_segment(parentId)}/Seasons',
        queryParameters: {'userId': connection.userId, 'Fields': _browseFields, ...jellyfinImageQueryParameters},
      );
      if (seasons.statusCode == 200) {
        final data = seasons.data;
        final items = _itemsArray(data);
        if (items.isNotEmpty && data is Map<String, dynamic>) {
          await cache.put(ServerId(cacheServerId), seasonsKey, data);
          return _mapItems(items);
        }
      }
    } on MediaServerHttpException {
      // Not a series — fall through to the generic ParentId query.
    }
    // Generic direct-children query: works for season → episodes,
    // collection → items, etc. Page it so large seasons/folders don't truncate
    // at Jellyfin's per-request limit.
    final allRaw = <Map<String, dynamic>>[];
    var startIndex = 0;
    int? totalRecordCount;
    while (totalRecordCount == null || startIndex < totalRecordCount) {
      final response = await _http.get(
        '/Items',
        queryParameters: {
          'userId': connection.userId,
          'ParentId': parentId,
          'Fields': _episodeRowFields,
          'StartIndex': '$startIndex',
          'Limit': '$_childrenPageSize',
          ..._episodeOrderQueryParameters,
          ...jellyfinImageQueryParameters,
        },
      );
      throwIfHttpError(response);
      final data = response.data;
      final page = _itemsArray(data);
      allRaw.addAll(page);
      if (data is Map<String, dynamic>) {
        final rawTotal = data['TotalRecordCount'];
        if (rawTotal is int) totalRecordCount = rawTotal;
      }
      if (page.isEmpty || page.length < _childrenPageSize) break;
      startIndex += page.length;
      if (onPage != null && (totalRecordCount == null || startIndex < totalRecordCount)) {
        onPage(_mapItems(allRaw));
      }
    }
    try {
      await cache.put(ServerId(cacheServerId), childrenKey, {'Items': allRaw, 'TotalRecordCount': allRaw.length});
    } catch (e, st) {
      appLogger.w('JellyfinClient.fetchChildren cache write failed', error: e, stackTrace: st);
    }
    return _mapItems(allRaw);
  }

  @override
  Future<LibraryPage<MediaItem>> fetchChildrenPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final offset = start ?? 0;
    final pageSize = size ?? _pagedListPageSize;
    final seasonsKey = '/Shows/$parentId/Seasons?userId=${connection.userId}';
    final childrenKey = '/Items?ParentId=$parentId&userId=${connection.userId}';

    if (isOfflineMode) {
      final cachedSeasons = await cache.get(ServerId(cacheServerId), seasonsKey);
      if (cachedSeasons != null) {
        final allSeasons = _mapItems(_itemsArray(cachedSeasons));
        if (allSeasons.isNotEmpty) {
          final safeOffset = offset.clamp(0, allSeasons.length).toInt();
          final end = (safeOffset + pageSize).clamp(0, allSeasons.length).toInt();
          return LibraryPage<MediaItem>(
            items: allSeasons.sublist(safeOffset, end),
            totalCount: allSeasons.length,
            offset: offset,
          );
        }
      }
      final cached = await cache.get(ServerId(cacheServerId), childrenKey);
      final all = cached == null ? const <MediaItem>[] : _mapItems(_itemsArray(cached));
      final safeOffset = offset.clamp(0, all.length).toInt();
      final end = (safeOffset + pageSize).clamp(0, all.length).toInt();
      final pageItems = all.sublist(safeOffset, end);
      return LibraryPage<MediaItem>(items: pageItems, totalCount: all.length, offset: offset);
    }

    try {
      final seasons = await _http.get(
        '/Shows/${_segment(parentId)}/Seasons',
        queryParameters: {
          'userId': connection.userId,
          'StartIndex': offset.toString(),
          'Limit': pageSize.toString(),
          'EnableTotalRecordCount': 'true',
          'Fields': _browseFields,
          ...jellyfinImageQueryParameters,
        },
        abort: abort,
      );
      if (seasons.statusCode == 200) {
        final data = seasons.data;
        final items = _itemsArray(data);
        final rawTotal = data is Map<String, dynamic> ? data['TotalRecordCount'] : null;
        if (items.isNotEmpty || (rawTotal is int && rawTotal > 0)) {
          return _pagedMediaItems(data, offset: offset, requestedSize: pageSize);
        }
      }
    } on MediaServerHttpException {
      // Not a series — fall through to the generic ParentId query.
    }

    final response = await _http.get(
      '/Items',
      queryParameters: {
        'userId': connection.userId,
        'ParentId': parentId,
        'StartIndex': offset.toString(),
        'Limit': pageSize.toString(),
        'EnableTotalRecordCount': 'true',
        'Fields': _episodeRowFields,
        ..._episodeOrderQueryParameters,
        ...jellyfinImageQueryParameters,
      },
      abort: abort,
    );
    throwIfHttpError(response);
    return _pagedMediaItems(response.data, offset: offset, requestedSize: pageSize);
  }

  Future<LibraryPage<MediaItem>> fetchSeasonEpisodesPage(
    String seriesId,
    String seasonId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    if (isOfflineMode) {
      return fetchChildrenPage(seasonId, start: start, size: size, abort: abort);
    }

    final offset = start ?? 0;
    final pageSize = size ?? _pagedListPageSize;
    final response = await _http.get(
      '/Shows/${_segment(seriesId)}/Episodes',
      queryParameters: {
        'userId': connection.userId,
        'SeasonId': seasonId,
        'StartIndex': offset.toString(),
        'Limit': pageSize.toString(),
        'EnableTotalRecordCount': 'true',
        'IsMissing': 'false',
        'IsVirtualUnaired': 'false',
        'Fields': _episodeRowFields,
        ...jellyfinImageQueryParameters,
      },
      abort: abort,
    );
    throwIfHttpError(response);
    return _pagedMediaItems(response.data, offset: offset, requestedSize: pageSize);
  }

  /// Jellyfin folder browsing mirrors Jellyfin Web/Findroid/Swiftfin: query
  /// direct children of the library/folder with `Recursive=false`. This is
  /// distinct from [fetchLibraryContent], which intentionally recurses through
  /// a library to show metadata groupings like albums, artists, shows, etc.
  @override
  Future<List<MediaItem>> fetchLibraryFolders(String libraryId, {void Function(List<MediaItem> itemsSoFar)? onPage}) =>
      _fetchFolderChildren(libraryId, onPage: onPage);

  /// Contents of a Jellyfin folder. Kept separate from [fetchChildren] so the
  /// folder tree can use direct-child semantics even for music libraries —
  /// except for show/season rows, which surface as expandable folders in the
  /// tree but whose children come from the metadata hierarchy.
  ///
  /// [onPage] surfaces the accumulated items (server order) after each
  /// intermediate page so callers can render while pagination continues; it is
  /// never called for single-page listings or the final page (the returned
  /// list covers those).
  @override
  Future<List<MediaItem>> fetchFolderChildren(
    MediaItem folder, {
    String? libraryId,
    String? libraryTitle,
    void Function(List<MediaItem> itemsSoFar)? onPage,
  }) {
    if (folder.kind == MediaKind.show || folder.kind == MediaKind.season) {
      return _fetchChildrenInternal(folder.id, onPage: onPage);
    }
    return _fetchFolderChildren(folder.id, onPage: onPage);
  }

  /// Page through `/Items?ParentId=...&Recursive=false` with the given type
  /// filter. [onRawPage] receives the accumulated rows after each intermediate
  /// page (never for single-page listings or the final page).
  Future<List<Map<String, dynamic>>> _pageFolderQuery(
    String parentId,
    Map<String, String> typeParams,
    String fields, {
    void Function(List<Map<String, dynamic>> rowsSoFar)? onRawPage,
  }) async {
    final out = <Map<String, dynamic>>[];
    var startIndex = 0;
    int? totalRecordCount;
    while (totalRecordCount == null || startIndex < totalRecordCount) {
      final response = await _http.get(
        '/Items',
        queryParameters: {
          'userId': connection.userId,
          'ParentId': parentId,
          'Recursive': 'false',
          'StartIndex': '$startIndex',
          'Limit': '$_childrenPageSize',
          'EnableTotalRecordCount': 'true',
          'SortBy': 'SortName',
          'SortOrder': 'Ascending',
          'Fields': fields,
          ...typeParams,
          ...jellyfinImageQueryParameters,
        },
      );
      throwIfHttpError(response);
      final data = response.data;
      final page = _itemsArray(data);
      out.addAll(page);
      if (data is Map<String, dynamic>) {
        final rawTotal = data['TotalRecordCount'];
        if (rawTotal is int) totalRecordCount = rawTotal;
      }
      if (page.isEmpty || page.length < _childrenPageSize) break;
      startIndex += page.length;
      if (onRawPage != null && (totalRecordCount == null || startIndex < totalRecordCount)) {
        onRawPage(out);
      }
    }
    return out;
  }

  Future<List<MediaItem>> _fetchFolderChildren(
    String parentId, {
    void Function(List<MediaItem> itemsSoFar)? onPage,
  }) async {
    final cacheKey = '/Items?ParentId=$parentId&Recursive=false&userId=${connection.userId}';
    if (isOfflineMode) {
      final cached = await cache.get(ServerId(cacheServerId), cacheKey);
      return cached == null ? const [] : _mapItems(_itemsArray(cached));
    }

    // Two parallel queries split by type: attaching UserData to a folder dto
    // makes Jellyfin compute a recursive unplayed count PER FOLDER (measured
    // ~100-200ms each on a real 10.11 server — the dominant cost of folder
    // browsing), and the tree renders no watch state on plain folder rows.
    // Media children keep UserData: leaves resolve it with a cheap lookup and
    // series need it for the unwatched badge. Folders-then-media matches the
    // folders-first ordering the final sort below produces.
    List<Map<String, dynamic>>? folderRows;
    final foldersFuture = _pageFolderQuery(parentId, {
      'IncludeItemTypes': 'Folder,CollectionFolder',
      'EnableUserData': 'false',
    }, _folderRowFields).then((rows) => folderRows = rows);

    final mediaFuture = _pageFolderQuery(
      parentId,
      {'ExcludeItemTypes': 'Folder,CollectionFolder'},
      _folderBrowseFields,
      onRawPage: onPage == null
          ? null
          : (rowsSoFar) {
              // Only emit once the (typically single, fast) folders query has
              // landed so partial snapshots never reorder later.
              final folders = folderRows;
              if (folders == null) return;
              onPage(List<MediaItem>.unmodifiable(_mapItems([...folders, ...rowsSoFar])));
            },
    );

    final results = await Future.wait([foldersFuture, mediaFuture]);
    final allRaw = <Map<String, dynamic>>[...results[0], ...results[1]];

    allRaw.sort((a, b) {
      final folderRank = (_isJellyfinFolderDto(a) ? 0 : 1).compareTo(_isJellyfinFolderDto(b) ? 0 : 1);
      if (folderRank != 0) return folderRank;
      return _jellyfinFolderSortName(a).compareTo(_jellyfinFolderSortName(b));
    });

    try {
      await cache.put(ServerId(cacheServerId), cacheKey, {'Items': allRaw, 'TotalRecordCount': allRaw.length});
    } catch (e, st) {
      appLogger.w('JellyfinClient.fetchFolderChildren cache write failed', error: e, stackTrace: st);
    }
    return _mapItems(allRaw);
  }

  /// All directly-playable descendants of [parentId] (Movies + Episodes +
  /// Audio tracks), recursively expanded. Used by the playback launcher so a
  /// collection containing a Series plays its episodes instead of the
  /// unplayable Series entry, a playlist mixing both comes through the same
  /// path, and an album/artist/audio-playlist expands to its tracks.
  /// Direct browsing keeps using [fetchChildren] / [fetchPlaylistItems]
  /// since those preserve the container shape (Series rows, PlaylistItemId).
  ///
  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async {
    final items = await _fetchAllPlayableDescendants(parentId, includeItemTypes: _playableDescendantTypes);
    if (items.isNotEmpty) return items;
    // Jellyfin links music to artists via *tags*, not the folder tree — a
    // MusicArtist is usually not its tracks' ancestor, so the recursive
    // `ParentId` query above comes back empty for tag-only artists (folder-
    // backed artists resolve on the first query and never reach this).
    // Retry once by album-artist credit, tracks only.
    return _fetchAllPlayableDescendants(parentId, includeItemTypes: 'Audio', byAlbumArtist: true);
  }

  /// Playable video descendants for a folder browse row. This includes
  /// Jellyfin's generic `Video` / `MusicVideo` kinds for home-video libraries,
  /// but deliberately excludes `Audio` so folder playback never starts music.
  Future<List<MediaItem>> fetchPlayableFolderDescendants(String parentId) {
    return _fetchAllPlayableDescendants(parentId, includeItemTypes: _playableFolderDescendantTypes);
  }

  Future<List<MediaItem>> _fetchAllPlayableDescendants(
    String parentId, {
    required String includeItemTypes,
    bool byAlbumArtist = false,
  }) async {
    final all = <MediaItem>[];
    var start = 0;
    while (true) {
      final page = await _fetchPlayableDescendantsPage(
        parentId,
        start: start,
        size: _pagedListPageSize,
        includeItemTypes: includeItemTypes,
        byAlbumArtist: byAlbumArtist,
      );
      if (page.items.isEmpty) break;
      all.addAll(page.items);
      start += page.items.length;
      if (start >= page.totalCount) break;
    }
    return all;
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPlayableDescendantsPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) {
    return _fetchPlayableDescendantsPage(
      parentId,
      start: start,
      size: size,
      abort: abort,
      includeItemTypes: _playableDescendantTypes,
    );
  }

  Future<LibraryPage<MediaItem>> _fetchPlayableDescendantsPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
    required String includeItemTypes,
    bool byAlbumArtist = false,
  }) async {
    final offset = start ?? 0;
    final pageSize = size ?? _pagedListPageSize;
    final response = await _http.get(
      '/Items',
      queryParameters: {
        'userId': connection.userId,
        // Tag-linked music artists have no folder descendants; the retry in
        // [fetchPlayableDescendants] expands them by album-artist credit.
        if (byAlbumArtist) 'AlbumArtistIds': parentId else 'ParentId': parentId,
        'Recursive': 'true',
        'IncludeItemTypes': includeItemTypes,
        'StartIndex': offset.toString(),
        'Limit': pageSize.toString(),
        'Fields': _episodeRowFields,
        ...jellyfinImageQueryParameters,
      },
      abort: abort,
    );
    throwIfHttpError(response);
    return _pagedMediaItems(response.data, offset: offset, requestedSize: pageSize);
  }

  /// All episodes of a series in the app's **aired watch order** — primarily by
  /// air date, so Specials interleave between regular episodes the way Plex's
  /// own play queue does — so the client-side next/previous queue matches
  /// streaming, downloads, and offline playback (#1416/#1414). The server sort
  /// ([_episodeOrderQueryParameters]) only keeps paging stable;
  /// [sortEpisodesByWatchOrder] then orders the assembled list, leaving a single
  /// definition of "episode order".
  ///
  /// Uses [_queueFields] (`UserData` + `PremiereDate`) instead of the full
  /// browse field set so the response stays small even for shows with thousands
  /// of episodes.
  ///
  /// Paged in [_episodeQueuePageSize] chunks so long-running shows still get
  /// a complete client-side next/previous queue without one huge response.
  @override
  Future<List<MediaItem>?> fetchClientSideEpisodeQueue(String seriesId) async {
    final all = <MediaItem>[];
    var startIndex = 0;
    int? totalRecordCount;

    while (totalRecordCount == null || startIndex < totalRecordCount) {
      final response = await _http.get(
        '/Shows/${_segment(seriesId)}/Episodes',
        queryParameters: {
          'userId': connection.userId,
          'Fields': _queueFields,
          'StartIndex': '$startIndex',
          'Limit': '$_episodeQueuePageSize',
          'IsMissing': 'false',
          'IsVirtualUnaired': 'false',
          ..._episodeOrderQueryParameters,
          ...jellyfinImageQueryParameters,
        },
      );
      throwIfHttpError(response);
      final data = response.data;
      final page = _mapItems(_itemsArray(data));
      all.addAll(page);
      if (data is Map<String, dynamic>) {
        final rawTotal = data['TotalRecordCount'];
        if (rawTotal is int) totalRecordCount = rawTotal;
      }
      if (page.length < _episodeQueuePageSize) break;
      startIndex += page.length;
    }

    // Server lists Specials first (ParentIndexNumber asc); reorder into the
    // shared aired watch order so online next/prev matches offline + downloads.
    sortEpisodesByWatchOrder(all);
    return all;
  }

  @override
  Future<List<MediaItem>> searchItems(String query, {int limit = 100}) async {
    // Artists come from the dedicated /Artists endpoint: `/Items?SearchTerm=`
    // only matches folder-derived MusicArtist rows (under folder names), so
    // tag-only artists would never appear in search. The artists leg is
    // best-effort — a music-endpoint hiccup shouldn't sink video search.
    final results = await Future.wait([
      _fetchItemsArray('/Items', {
        'userId': connection.userId,
        'SearchTerm': query,
        'Recursive': 'true',
        'Limit': limit.toString(),
        'IncludeItemTypes': 'Movie,Series,Episode,MusicAlbum,Audio',
        'Fields': _browseFields,
        ...jellyfinImageQueryParameters,
      }),
      _safeFetchItemsArray('/Artists', {
        'userId': connection.userId,
        'searchTerm': query,
        'Limit': limit.toString(),
        ...jellyfinImageQueryParameters,
      }),
    ]);
    return _mapItems([...results.first, ...results[1]]);
  }

  @override
  Future<List<MediaItem>> fetchPersonMedia(String personId) async {
    final all = <MediaItem>[];
    var start = 0;
    while (true) {
      final page = await fetchPersonMediaPage(personId, start: start, size: _pagedListPageSize);
      if (page.items.isEmpty) break;
      all.addAll(page.items);
      start += page.items.length;
      if (start >= page.totalCount) break;
    }
    return all;
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPersonMediaPage(
    String personId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final offset = start ?? 0;
    final pageSize = size ?? _pagedListPageSize;
    final response = await _http.get(
      '/Items',
      queryParameters: {
        'userId': connection.userId,
        'PersonIds': personId,
        'IncludeItemTypes': 'Movie,Series',
        'Recursive': 'true',
        'StartIndex': offset.toString(),
        'Limit': pageSize.toString(),
        'Fields': _browseFields,
        'SortBy': 'PremiereDate,ProductionYear,SortName',
        'SortOrder': 'Descending,Descending,Ascending',
        'CollapseBoxSetItems': 'false',
        ...jellyfinImageQueryParameters,
      },
      abort: abort,
    );
    throwIfHttpError(response);
    return _pagedMediaItems(response.data, offset: offset, requestedSize: pageSize);
  }

  @override
  Future<List<MediaItem>> fetchRecentlyAdded({int limit = 50}) async {
    // Matches userLibraryApi.getLatestMedia in the Jellyfin SDK.
    final response = await _http.get(
      '/Users/${_segment(connection.userId)}/Items/Latest',
      queryParameters: {
        'Limit': limit.toString(),
        'Fields': _browseFields,
        'IncludeItemTypes': 'Movie,Series,Episode',
        ...jellyfinImageQueryParameters,
      },
    );
    throwIfHttpError(response);
    final data = response.data;
    // Latest returns a bare array, not an Items wrapper.
    if (data is List) {
      return _mapItems(data.whereType<Map<String, dynamic>>());
    }
    return _mapItems(_itemsArray(data));
  }

  @override
  Future<List<MediaItem>> fetchContinueWatching({int? count = 20}) async {
    final results = await Future.wait([
      _fetchItemsArray('/UserItems/Resume', {
        'userId': connection.userId,
        'Limit': ?count?.toString(),
        'Fields': _browseFields,
        'MediaTypes': 'Video',
        'Recursive': 'true',
        'EnableTotalRecordCount': 'false',
        ...jellyfinImageQueryParameters,
      }, retry: _continueWatchingRetry),
      _safeFetchItemsArray('/Shows/NextUp', {
        'userId': connection.userId,
        'Limit': ?count?.toString(),
        'Fields': _browseFields,
        'EnableResumable': 'false',
        'EnableTotalRecordCount': 'false',
        ...jellyfinImageQueryParameters,
      }, retry: _continueWatchingRetry),
    ]);

    return _mergeContinueWatchingAndNextUp(
      resume: _mapItems(results.first),
      nextUp: await _attachSeriesLastPlayed(_mapItems(results[1])),
      limit: count,
    );
  }

  @override
  Future<List<MediaHub>> fetchGlobalHubs({int limit = defaultHubPreviewLimit, bool includePlaybackHubs = true}) async {
    // Jellyfin doesn't expose a single "hubs" endpoint, so we synthesise the
    // home rows from Latest plus optional playback rows. The richer Plex Discover surface
    // is intentionally left untranslated — see ServerCapabilities.richHubs.
    final latestFuture = _safeFetchItemsArray('/Users/${_segment(connection.userId)}/Items/Latest', {
      'Limit': limit.toString(),
      'Fields': _browseFields,
      'IncludeItemTypes': 'Movie,Series,Episode',
      ...jellyfinImageQueryParameters,
    }, retry: _homeHubRetry);

    if (!includePlaybackHubs) {
      final latest = await latestFuture;
      return [
        JellyfinMappers.syntheticHub(
          mapItem: _mapItem,
          identifier: 'home.recent',
          title: t.discover.recentlyAdded,
          type: 'mixed',
          items: latest,
          previewLimit: limit,
          serverId: serverId,
          serverName: serverName,
        ),
      ].where((h) => h.items.isNotEmpty).toList();
    }

    final results = await Future.wait([
      latestFuture,
      _safeFetchItemsArray('/UserItems/Resume', {
        'userId': connection.userId,
        'Limit': limit.toString(),
        'Fields': _browseFields,
        'MediaTypes': 'Video',
        'Recursive': 'true',
        'EnableTotalRecordCount': 'false',
        ...jellyfinImageQueryParameters,
      }, retry: _homeHubRetry),
      _safeFetchItemsArray('/Shows/NextUp', {
        'userId': connection.userId,
        'Limit': limit.toString(),
        'Fields': _browseFields,
        'EnableResumable': 'false',
        'EnableTotalRecordCount': 'false',
        ...jellyfinImageQueryParameters,
      }, retry: _homeHubRetry),
    ]);

    return [
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'home.continue',
        title: t.discover.continueWatching,
        type: 'mixed',
        items: results[1],
        previewLimit: limit,
        serverId: serverId,
        serverName: serverName,
      ),
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'home.nextup',
        title: t.discover.nextUp,
        type: 'episode',
        items: results[2],
        previewLimit: limit,
        serverId: serverId,
        serverName: serverName,
      ),
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'home.recent',
        title: t.discover.recentlyAdded,
        type: 'mixed',
        items: results.first,
        previewLimit: limit,
        serverId: serverId,
        serverName: serverName,
      ),
    ].where((h) => h.items.isNotEmpty).toList();
  }

  @override
  Future<List<MediaHub>> fetchLibraryHubs(
    String libraryId, {
    required String libraryName,
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    MediaKind? libraryKind,
  }) async {
    // Mirror the Jellyfin web client's per-library "Suggestions" tab:
    // Continue Watching + Next Up (TV libraries) + Recently Added.
    //
    // Issued in parallel so the recommended tab loads in one round-trip.
    // When the caller knows the library kind, skip NextUp for movie libraries;
    // Jellyfin can otherwise spend time scanning TV state only to return [].
    final latestFuture = _safeFetchItemsArray('/Users/${_segment(connection.userId)}/Items/Latest', {
      'Limit': limit.toString(),
      'ParentId': libraryId,
      'Fields': _browseFields,
      ...jellyfinImageQueryParameters,
    }, retry: _libraryHubRetry);

    // Music libraries get their own hub set (Latest Albums / Recently Played /
    // Most Played) — Resume and NextUp are video concepts and Jellyfin's
    // Resume endpoint is queried with MediaTypes=Video anyway. The branch
    // ignores [includePlaybackHubs]: the played rows never duplicate the
    // app-level Continue Watching shelf that flag exists to dedupe.
    if (libraryKind == MediaKind.artist) {
      return _fetchMusicLibraryHubs(libraryId, libraryName: libraryName, limit: limit, latestFuture: latestFuture);
    }

    if (!includePlaybackHubs) {
      final latest = await latestFuture;
      return [
        JellyfinMappers.syntheticHub(
          mapItem: _mapItem,
          identifier: 'library.$libraryId.recent',
          title: t.discover.recentlyAddedIn(library: libraryName),
          type: 'mixed',
          items: latest,
          previewLimit: limit,
          serverId: serverId,
          serverName: serverName,
        ),
      ].where((h) => h.items.isNotEmpty).toList();
    }

    final includeNextUp = libraryKind == null || libraryKind == MediaKind.show;
    final results = await Future.wait([
      latestFuture,
      _safeFetchItemsArray('/UserItems/Resume', {
        'userId': connection.userId,
        'ParentId': libraryId,
        'Limit': limit.toString(),
        'Fields': _browseFields,
        'MediaTypes': 'Video',
        'Recursive': 'true',
        'EnableTotalRecordCount': 'false',
        ...jellyfinImageQueryParameters,
      }, retry: _libraryHubRetry),
      includeNextUp
          ? _safeFetchItemsArray('/Shows/NextUp', {
              'userId': connection.userId,
              'ParentId': libraryId,
              'Limit': limit.toString(),
              'Fields': _browseFields,
              'EnableResumable': 'false',
              'EnableTotalRecordCount': 'false',
              ...jellyfinImageQueryParameters,
            }, retry: _libraryHubRetry)
          : Future.value(const <Map<String, dynamic>>[]),
    ]);

    return [
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'library.$libraryId.continue',
        title: t.discover.continueWatchingIn(library: libraryName),
        type: 'mixed',
        items: results[1],
        previewLimit: limit,
        serverId: serverId,
        serverName: serverName,
      ),
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'library.$libraryId.nextup',
        title: t.discover.nextUpIn(library: libraryName),
        type: 'episode',
        items: results[2],
        previewLimit: limit,
        serverId: serverId,
        serverName: serverName,
      ),
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'library.$libraryId.recent',
        title: t.discover.recentlyAddedIn(library: libraryName),
        type: 'mixed',
        items: results.first,
        previewLimit: limit,
        serverId: serverId,
        serverName: serverName,
      ),
    ].where((h) => h.items.isNotEmpty).toList();
  }

  /// Music-library hub set, mirroring the Jellyfin web client's music
  /// "Suggestions" tab. `Latest Albums` reuses the `.recent` identifier —
  /// `/Users/{userId}/Items/Latest` natively groups a music library's new
  /// items into albums, so the existing `recent` paging path in
  /// [fetchMoreHubItemsPage] is already the correct expansion. The played
  /// rows filter `IsPlayed` so unplayed tracks (PlayCount 0) never pad them.
  Future<List<MediaHub>> _fetchMusicLibraryHubs(
    String libraryId, {
    required String libraryName,
    required int limit,
    required Future<List<Map<String, dynamic>>> latestFuture,
  }) async {
    final playedParams = <String, String>{
      'userId': connection.userId,
      'ParentId': libraryId,
      'IncludeItemTypes': 'Audio',
      'Recursive': 'true',
      'Filters': 'IsPlayed',
      'SortOrder': 'Descending',
      'Limit': limit.toString(),
      'Fields': _browseFields,
      'EnableTotalRecordCount': 'false',
      ...jellyfinImageQueryParameters,
    };
    final results = await Future.wait([
      latestFuture,
      _safeFetchItemsArray('/Items', {...playedParams, 'SortBy': 'DatePlayed'}, retry: _libraryHubRetry),
      _safeFetchItemsArray('/Items', {...playedParams, 'SortBy': 'PlayCount'}, retry: _libraryHubRetry),
    ]);

    return [
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'library.$libraryId.recent',
        title: t.discover.latestAlbumsIn(library: libraryName),
        type: 'album',
        items: results.first,
        previewLimit: limit,
        serverId: serverId,
        serverName: serverName,
      ),
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'library.$libraryId.recentlyplayed',
        title: t.discover.recentlyPlayedIn(library: libraryName),
        type: 'track',
        items: results[1],
        previewLimit: limit,
        serverId: serverId,
        serverName: serverName,
      ),
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'library.$libraryId.mostplayed',
        title: t.discover.mostPlayedIn(library: libraryName),
        type: 'track',
        items: results[2],
        previewLimit: limit,
        serverId: serverId,
        serverName: serverName,
      ),
    ].where((h) => h.items.isNotEmpty).toList();
  }

  /// Re-run the synthetic hub query without the preview limit so the
  /// hub-detail screen can render the full list. Branches on the
  /// identifier emitted by [fetchGlobalHubs] / [fetchLibraryHubs]:
  /// `home.recent` / `library.{id}.recent` → Latest, `*.continue` → Resume,
  /// `*.nextup` → NextUp, `*.recentlyplayed` / `*.mostplayed` → the music
  /// played-track queries. Unknown ids return an empty list.
  @override
  Future<List<MediaItem>> fetchMoreHubItems(String hubId, {int? limit}) async {
    try {
      final page = await fetchMoreHubItemsPage(hubId, start: 0, size: limit ?? 50);
      return page.items;
    } catch (e, st) {
      // A cancelled request says nothing about the hub's contents — let it
      // propagate so the caller classifies the fetch as disrupted, not empty.
      if (e is MediaServerHttpException && e.isCancellation) rethrow;
      appLogger.w('JellyfinClient: failed to fetch hub items for $hubId (treating as empty)', error: e, stackTrace: st);
      return const [];
    }
  }

  @override
  Future<LibraryPage<MediaItem>> fetchMoreHubItemsPage(
    String hubId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final offset = start ?? 0;
    final pageSize = size ?? 50;
    final effectiveLimit = pageSize.toString();
    String? parentId;
    if (hubId.startsWith('library.')) {
      final rest = hubId.substring('library.'.length);
      final dot = rest.lastIndexOf('.');
      if (dot > 0) parentId = rest.substring(0, dot);
    }
    final tail = hubId.split('.').last;
    switch (tail) {
      case 'recent':
        // Jellyfin's Latest endpoint has a Limit but no StartIndex. Expose it
        // as one bounded page so callers don't infer endless fake pages.
        if (offset > 0) return LibraryPage<MediaItem>(items: const [], totalCount: offset, offset: offset);
        return _safeFetchMediaPage(
          '/Users/${_segment(connection.userId)}/Items/Latest',
          {
            'Limit': effectiveLimit,
            'Fields': _browseFields,
            if (parentId != null) 'ParentId': parentId else 'IncludeItemTypes': 'Movie,Series,Episode',
            ...jellyfinImageQueryParameters,
          },
          offset: offset,
          requestedSize: pageSize,
          singlePage: true,
          abort: abort,
        );
      case 'continue':
        return _safeFetchMediaPage(
          '/UserItems/Resume',
          {
            'userId': connection.userId,
            'StartIndex': offset.toString(),
            'Limit': effectiveLimit,
            'Fields': _browseFields,
            'Recursive': 'true',
            'EnableTotalRecordCount': 'true',
            if (parentId != null) 'ParentId': parentId else 'MediaTypes': 'Video',
            ...jellyfinImageQueryParameters,
          },
          offset: offset,
          requestedSize: pageSize,
          abort: abort,
        );
      case 'nextup':
        return _safeFetchMediaPage(
          '/Shows/NextUp',
          {
            'userId': connection.userId,
            'StartIndex': offset.toString(),
            'Limit': effectiveLimit,
            'Fields': _browseFields,
            'ParentId': ?parentId,
            'EnableResumable': 'false',
            'EnableTotalRecordCount': 'true',
            ...jellyfinImageQueryParameters,
          },
          offset: offset,
          requestedSize: pageSize,
          abort: abort,
        );
      case 'recentlyplayed':
      case 'mostplayed':
        return _safeFetchMediaPage(
          '/Items',
          {
            'userId': connection.userId,
            'ParentId': ?parentId,
            'IncludeItemTypes': 'Audio',
            'Recursive': 'true',
            'Filters': 'IsPlayed',
            'SortBy': tail == 'mostplayed' ? 'PlayCount' : 'DatePlayed',
            'SortOrder': 'Descending',
            'StartIndex': offset.toString(),
            'Limit': effectiveLimit,
            'Fields': _browseFields,
            'EnableTotalRecordCount': 'true',
            ...jellyfinImageQueryParameters,
          },
          offset: offset,
          requestedSize: pageSize,
          abort: abort,
        );
      default:
        return LibraryPage<MediaItem>(items: const [], totalCount: 0, offset: offset);
    }
  }

  Future<LibraryPage<MediaItem>> _safeFetchMediaPage(
    String path,
    Map<String, dynamic> queryParameters, {
    required int offset,
    required int requestedSize,
    bool singlePage = false,
    AbortController? abort,
  }) async {
    try {
      final response = await _http.get(path, queryParameters: queryParameters, abort: abort);
      throwIfHttpError(response);
      final data = response.data;
      final rawItems = data is List ? data.whereType<Map<String, dynamic>>().toList() : _itemsArray(data);
      final rawTotal = data is Map<String, dynamic> ? data['TotalRecordCount'] : null;
      final fallbackTotal = singlePage
          ? offset + rawItems.length
          : _fallbackPageTotal(offset: offset, itemCount: rawItems.length, requestedSize: requestedSize);
      return LibraryPage<MediaItem>(
        items: _mapItems(rawItems),
        totalCount: rawTotal is int ? rawTotal : fallbackTotal,
        offset: offset,
      );
    } catch (e, st) {
      appLogger.w('JellyfinClient: $path failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  LibraryPage<MediaItem> _pagedMediaItems(Object? data, {required int offset, required int requestedSize}) {
    final rawItems = _itemsArray(data);
    final rawTotal = data is Map<String, dynamic> ? data['TotalRecordCount'] : null;
    final fallbackTotal = _fallbackPageTotal(offset: offset, itemCount: rawItems.length, requestedSize: requestedSize);
    return LibraryPage<MediaItem>(
      items: _mapItems(rawItems),
      totalCount: rawTotal is int ? rawTotal : fallbackTotal,
      offset: offset,
    );
  }

  @override
  Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async {
    final response = await _http.get(
      '/Items/${_segment(id)}/Similar',
      queryParameters: {
        'userId': connection.userId,
        'Limit': count.toString(),
        'Fields': _browseFields,
        ...jellyfinImageQueryParameters,
      },
    );
    throwIfHttpError(response);
    return [
      JellyfinMappers.syntheticHub(
        mapItem: _mapItem,
        identifier: 'item.$id.similar',
        title: t.discover.moreLikeThis,
        type: 'mixed',
        items: _itemsArray(response.data),
        serverId: serverId,
        serverName: serverName,
      ),
    ].where((h) => h.items.isNotEmpty).toList();
  }

  /// Jellyfin exposes local trailers separately from special features. Combine
  /// both into Plezy's existing extras row, but keep remote/YouTube trailers
  /// out of scope because they are external URLs, not playable Jellyfin items.
  @override
  Future<List<MediaItem>> fetchExtras(String id) async {
    if (isOfflineMode) return const [];

    final results = await Future.wait([
      _safeFetchItemsArray('/Items/${_segment(id)}/LocalTrailers', {
        'userId': connection.userId,
        ...jellyfinImageQueryParameters,
      }),
      _safeFetchItemsArray('/Items/${_segment(id)}/SpecialFeatures', {
        'userId': connection.userId,
        ...jellyfinImageQueryParameters,
      }),
    ]);

    return _playableExtrasFromRaw(results.expand((items) => items));
  }

  List<MediaItem> _playableExtrasFromRaw(Iterable<Map<String, dynamic>> rawExtras) {
    final extras = <MediaItem>[];
    final seenIds = <String>{};

    for (final raw in rawExtras) {
      final item = _mapItem(raw);
      if (item == null || !item.kind.isVideo || !seenIds.add(item.id)) continue;
      extras.add(item);
    }

    return extras;
  }

  /// Jellyfin's `/Shows/NextUp` returns the *next* (unwatched) episode for each
  /// series, so those rows have no `LastPlayedDate` of their own and a Series DTO
  /// doesn't expose an aggregated one. To let the Continue Watching shelf
  /// interleave Next Up with resume items by recency, stamp each Next Up episode
  /// with its series' last-watched date, read from the most recently played
  /// episode of that series.
  Future<List<MediaItem>> _attachSeriesLastPlayed(List<MediaItem> nextUp) async {
    final pendingSeriesIds = <String>{
      for (final item in nextUp)
        if (item.kind == MediaKind.episode && item.lastViewedAt == null && item.grandparentId != null)
          item.grandparentId!,
    };
    if (pendingSeriesIds.isEmpty) return nextUp;

    // One lightweight pass over the most recently played episodes server-wide,
    // ordered DatePlayed-descending so the first time we see a series is its
    // newest play. We deliberately do NOT filter on the Played flag: Jellyfin's
    // own NextUp ranks series by MAX(LastPlayedDate) across every episode, and an
    // episode can carry a LastPlayedDate while Played==false (started but not
    // finished, or later marked unwatched). Filtering to IsPlayed would miss
    // those and leave such series un-dated. Null dates sort last, so the limit
    // still captures the genuinely-recent episodes; a series whose last play
    // falls beyond the window keeps a null date and degrades to its addedAt in
    // the sort — it would rank near the bottom anyway, being least-recent.
    final rawPlayed = await _safeFetchItemsArray('/Items', {
      'userId': connection.userId,
      'IncludeItemTypes': 'Episode',
      'Recursive': 'true',
      'SortBy': 'DatePlayed',
      'SortOrder': 'Descending',
      'Fields': _queueFields,
      'Limit': _continueWatchingSeriesLookback.toString(),
      'EnableImages': 'false',
      'EnableTotalRecordCount': 'false',
    });

    final lastPlayedBySeries = <String, int>{};
    for (final episode in _mapItems(rawPlayed)) {
      final seriesId = episode.grandparentId;
      final playedAt = episode.lastViewedAt;
      if (seriesId == null || playedAt == null) continue;
      if (!pendingSeriesIds.contains(seriesId)) continue;
      lastPlayedBySeries.putIfAbsent(seriesId, () => playedAt);
    }
    if (lastPlayedBySeries.isEmpty) return nextUp;

    return [
      for (final item in nextUp)
        if (item.lastViewedAt == null && lastPlayedBySeries[item.grandparentId] != null)
          item.copyWith(lastViewedAt: lastPlayedBySeries[item.grandparentId])
        else
          item,
    ];
  }

  /// Merge Jellyfin's two continue-watching sources into one recency-ordered
  /// shelf. Resume items are deduped first so an in-progress episode wins over
  /// the same series' Next Up entry, then the combined list is ordered by
  /// [MediaItem.recencySortKey] (matching `DataAggregationService`) before the
  /// limit is applied — so a recent Next Up episode is never starved by a long
  /// run of older resume items.
  List<MediaItem> _mergeContinueWatchingAndNextUp({
    required List<MediaItem> resume,
    required List<MediaItem> nextUp,
    required int? limit,
  }) {
    if (limit != null && limit <= 0) return const [];

    final merged = <MediaItem>[];
    final seenIds = <String>{};
    final seenSeriesIds = <String>{};

    // Resume first: first-wins dedup makes an in-progress episode beat the same
    // series' Next Up entry.
    for (final item in [...resume, ...nextUp]) {
      if (!seenIds.add(item.id)) continue;
      final seriesId = item.kind == MediaKind.episode ? item.grandparentId : null;
      if (seriesId != null && !seenSeriesIds.add(seriesId)) continue;
      merged.add(item);
    }

    // Stable sort by recency: Dart's List.sort isn't stable, so break ties on the
    // insertion index to keep ordering deterministic across refreshes.
    final ordered = [for (var i = 0; i < merged.length; i++) (item: merged[i], index: i)];
    ordered.sort((a, b) {
      final byRecency = b.item.recencySortKey.compareTo(a.item.recencySortKey);
      return byRecency != 0 ? byRecency : a.index.compareTo(b.index);
    });
    final result = [for (final entry in ordered) entry.item];

    if (limit != null && result.length > limit) return result.sublist(0, limit);
    return result;
  }

  /// GET [path], optionally under a hub-surface transport policy ([retry]):
  /// bounded transient retries with per-attempt timeouts and **no endpoint
  /// failover** — a slow hub row must not move the whole client off an
  /// otherwise working endpoint (same policy as Plex's three hub fetches;
  /// see [retryTransientMediaServerCall] / [FailoverHttpClient]).
  Future<MediaServerResponse> _getItemsResponse(
    String path,
    Map<String, dynamic> queryParameters,
    _HubRetryPolicy? retry,
  ) {
    if (retry == null) return _http.get(path, queryParameters: queryParameters);
    return retryTransientMediaServerCall(
      operation: retry.operation,
      attemptTimeouts: retry.attemptTimeouts,
      call: (timeout, abort) => _http.get(
        path,
        queryParameters: queryParameters,
        timeout: timeout,
        abort: abort,
        allowEndpointFailover: false,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchItemsArray(
    String path,
    Map<String, dynamic> queryParameters, {
    _HubRetryPolicy? retry,
  }) async {
    final response = await _getItemsResponse(path, queryParameters, retry);
    throwIfHttpError(response);
    return _itemsArray(response.data);
  }

  Future<List<Map<String, dynamic>>> _safeFetchItemsArray(
    String path,
    Map<String, dynamic> queryParameters, {
    _HubRetryPolicy? retry,
  }) async {
    try {
      final response = await _getItemsResponse(path, queryParameters, retry);
      throwIfHttpError(response);
      final data = response.data;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      return _itemsArray(data);
    } catch (e, st) {
      // A cancelled request says nothing about the endpoint's contents — let
      // it propagate so the caller classifies the fetch as disrupted, not
      // empty.
      if (e is MediaServerHttpException && e.isCancellation) rethrow;
      appLogger.w('JellyfinClient: $path failed (treating as empty)', error: e, stackTrace: st);
      return const [];
    }
  }
}
