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

/// Builds a [LibraryPage] from an `/Items`-shaped response: the `Items` array
/// run through [map], plus the server's `TotalRecordCount` when it reports one.
/// Responses that omit it (or return a non-int) fall back to
/// [fallbackPageTotal], whose full-page sentinel keeps pagination enabled;
/// [singlePage] endpoints return everything at once, so a full page there means
/// the end of the list, not "there may be more".
LibraryPage<T> _pagedItems<T>(
  Object? data, {
  required int offset,
  required List<T> Function(List<Map<String, dynamic>>) map,
  int? requestedSize,
  bool singlePage = false,
}) {
  final rawItems = _itemsArray(data);
  final rawTotal = data is Map<String, dynamic> ? data['TotalRecordCount'] : null;
  final fallbackTotal = singlePage
      ? offset + rawItems.length
      : fallbackPageTotal(offset: offset, itemCount: rawItems.length, requestedSize: requestedSize);
  return LibraryPage<T>(items: map(rawItems), totalCount: rawTotal is int ? rawTotal : fallbackTotal, offset: offset);
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

/// Latest Albums hub row. `/Users/{id}/Items/Latest` on a music library
/// returns MusicAlbum FOLDER dtos, so [_browseFields] would trigger the same
/// per-folder recursive COUNT queries described on [_folderBrowseFields] —
/// with music libraries in the home fan-out that load helped peg small remote
/// servers (#1552). The album card renders artwork + title + album artist
/// (`AlbumArtist`/`AlbumArtists` are unconditional dto properties), so no
/// count fields are needed; queried with `EnableUserData=false` like the
/// filesystem folder rows. Trade-off: fully played albums lose the watched
/// checkmark on this row (Jellyfin web's latest-albums row shows no play
/// state either).
const _musicAlbumRowFields = 'PremiereDate,OriginalTitle,SortName';

/// Played-track hub rows (Recently Played / Most Played): Audio LEAF dtos.
/// Keeps `UserData` — a cheap direct lookup on leaves that drives the
/// play-state overlay — and drops the folder count fields (meaningless on
/// Audio) and `Overview` (never rendered on track cards).
const _musicTrackRowFields = 'UserData,PremiereDate,OriginalTitle,SortName';

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

/// How many pending series [_attachSeriesLastPlayed] resolves at once. Each
/// lookup returns a single row, so the batch exists only to keep a long Next Up
/// shelf from opening one request per series at the same instant; measured
/// against a 12.0-rc3 server, 4 is where the wall time for 21 series stops
/// improving (0.65s at 3, 0.56s at both 4 and 6).
const _seriesLastPlayedConcurrency = 4;

/// Ceiling on how many series [_attachSeriesLastPlayed] dates in one call. Sits
/// just above `DiscoverProvider`'s 21-row continue-watching probe so the home
/// shelf is always fully dated, and caps the uncapped `count: null` shelf, whose
/// Next Up half is limited only by how many series the user has started.
const _seriesLastPlayedLookupLimit = 24;

/// Per-phase budget for one [_fetchSeriesLastPlayed] lookup.
/// [MediaServerHttpClient] applies a per-call `timeout` to connect and receive
/// independently, so this bounds a single lookup at twice this value — the
/// shared [_seriesLastPlayedBudget] is what bounds the pass. A `ParentId`-scoped
/// `Limit=1` row answered in well under half a second even on the pathological
/// 12.0-rc3 sort, so reaching this means the endpoint is in trouble and the
/// shelf is better off unstamped than waiting on the 10s/120s shared defaults.
const _seriesLastPlayedRequestTimeout = Duration(seconds: 3);

/// Hard ceiling on [_attachSeriesLastPlayed]. On expiry it aborts the in-flight
/// batch, so it bounds the whole pass regardless of how many batches remain or
/// which request phase a lookup is stuck in. Two orders of magnitude under the
/// 10s-connect/120s-receive defaults the single unscoped scan ran with, so a
/// stalled endpoint cannot make the scoped form slower than the query it fixes.
const _seriesLastPlayedBudget = Duration(seconds: 4);

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

mixin _JellyfinBrowseMethods on _JellyfinClientInternals {
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
    final fields = switch (query.kind) {
      MediaKind.album => _musicAlbumRowFields,
      MediaKind.track => _musicTrackRowFields,
      _ => _browseFields,
    };
    final translator = JellyfinLibraryQueryTranslator(userId: connection.userId, parentId: libraryId, fields: fields);
    final params = translator.toQueryParameters(query);
    // MusicAlbum is a folder-like DTO. Asking for UserData makes Jellyfin
    // compute recursive play state for every album, which is prohibitively
    // expensive on large music libraries. The IsUnplayed query filter still
    // works server-side when result DTO user data is disabled.
    if (query.kind == MediaKind.album) {
      params['EnableUserData'] = 'false';
    }

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
        : fallbackPageTotal(offset: query.offset, itemCount: items.length, requestedSize: query.limit);
    return LibraryPage<MediaItem>(items: _mapItems(items), totalCount: total, offset: query.offset);
  }

  /// Jellyfin's `/Items/Filters` returns Genres / OfficialRatings / Tags /
  /// Categories + values from `/Items/Filters` in a single call. The
  /// unwatched/unplayed boolean is synthetic because Jellyfin exposes it as
  /// an `/Items` query filter, not a filter-listing category. Keys are
  /// translated to Plex's filter naming so the existing filter-param map
  /// round-trips through `_buildFilterParams` unchanged; the synthesised
  /// `MediaFilter.key` is prefixed `jellyfin:` so FiltersBottomSheet can
  /// recognise it as cached and skip the per-category value fetch.
  @override
  Future<LibraryFilterResult> fetchLibraryFiltersWithValues(String libraryId, {MediaKind? libraryKind}) async {
    final filters = <MediaFilter>[
      MediaFilter(
        filter: 'unwatched',
        filterType: 'boolean',
        key: 'jellyfin:unwatched',
        title: libraryKind?.isMusic == true
            ? t.libraries.filterCategories.unplayed
            : t.libraries.filterCategories.unwatched,
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
    final effective =
        (query.kind == null && query.includeKinds.isEmpty && libraryKind != null && libraryKind != MediaKind.unknown)
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
          return _pagedItems(data, offset: offset, requestedSize: pageSize, map: _mapItems);
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
    return _pagedItems(response.data, offset: offset, requestedSize: pageSize, map: _mapItems);
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
    return _pagedItems(response.data, offset: offset, requestedSize: pageSize, map: _mapItems);
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
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId, {AbortController? abort}) async {
    final items = await _fetchAllPlayableDescendants(
      parentId,
      includeItemTypes: _playableDescendantTypes,
      abort: abort,
    );
    abort?.throwIfAborted();
    if (items.isNotEmpty) return items;
    // Jellyfin links music to artists via *tags*, not the folder tree — a
    // MusicArtist is usually not its tracks' ancestor, so the recursive
    // `ParentId` query above comes back empty for tag-only artists (folder-
    // backed artists resolve on the first query and never reach this).
    // Retry once by album-artist credit, tracks only.
    return _fetchAllPlayableDescendants(parentId, includeItemTypes: 'Audio', byAlbumArtist: true, abort: abort);
  }

  /// Playable video descendants for a folder browse row. This includes
  /// Jellyfin's generic `Video` / `MusicVideo` kinds for home-video libraries,
  /// but deliberately excludes `Audio` so folder playback never starts music.
  Future<List<MediaItem>> fetchPlayableFolderDescendants(String parentId, {AbortController? abort}) {
    return _fetchAllPlayableDescendants(parentId, includeItemTypes: _playableFolderDescendantTypes, abort: abort);
  }

  Future<List<MediaItem>> _fetchAllPlayableDescendants(
    String parentId, {
    required String includeItemTypes,
    bool byAlbumArtist = false,
    AbortController? abort,
  }) {
    return drainPages<MediaItem>(
      (start, size) => _fetchPlayableDescendantsPage(
        parentId,
        start: start,
        size: size,
        abort: abort,
        includeItemTypes: includeItemTypes,
        byAlbumArtist: byAlbumArtist,
      ),
      pageSize: _pagedListPageSize,
      abort: abort,
    );
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
    return _pagedItems(response.data, offset: offset, requestedSize: pageSize, map: _mapItems);
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
  Future<List<MediaItem>?> fetchClientSideEpisodeQueue(String seriesId, {AbortController? abort}) async {
    final all = <MediaItem>[];
    var startIndex = 0;
    int? totalRecordCount;

    while (totalRecordCount == null || startIndex < totalRecordCount) {
      abort?.throwIfAborted();
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
        abort: abort,
      );
      abort?.throwIfAborted();
      throwIfHttpError(response);
      final data = response.data;
      final page = _mapItems(_itemsArray(data));
      abort?.throwIfAborted();
      all.addAll(page);
      if (data is Map<String, dynamic>) {
        final rawTotal = data['TotalRecordCount'];
        if (rawTotal is int) totalRecordCount = rawTotal;
      }
      if (page.length < _episodeQueuePageSize) break;
      startIndex += page.length;
    }

    abort?.throwIfAborted();
    // Server lists Specials first (ParentIndexNumber asc); reorder into the
    // shared aired watch order so online next/prev matches offline + downloads.
    sortEpisodesByWatchOrder(all);
    return all;
  }

  @override
  Future<List<MediaItem>> searchItems(String query, {int limit = 100, AbortController? abort}) async {
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
      }, abort: abort),
      _safeFetchItemsArray('/Artists', {
        'userId': connection.userId,
        'searchTerm': query,
        'Limit': limit.toString(),
        ...jellyfinImageQueryParameters,
      }, abort: abort),
    ]);
    abort?.throwIfAborted();
    return _mapItems([...results.first, ...results[1]]);
  }

  /// Jellyfin removed `anyProviderIdEquals` (silently ignored on 10.11.10, so
  /// it returns the unfiltered page), leaving a title search verified against
  /// each candidate's inline `ProviderIds`. [plexGuid] is a Plex-only hint and
  /// has no meaning in Jellyfin's provider-id model, so it is ignored.
  ///
  /// Every id-verified candidate of the first matching title is returned, not
  /// just the first: one movie can sit in both a 4K library and an HD library
  /// as two separate items, and the caller shows the user each copy (#1754).
  ///
  /// Jellyfin cannot report season ordering to a non-admin: on 10.11.10,
  /// `/Library/VirtualFolders` returns 403 and Series items omit
  /// `DisplayOrder`. Resolve against an unknown provider rather than guessing
  /// from `ProviderIds`, so only seasons on which TVDB and TMDB agree are gated.
  @override
  Future<List<MediaItem>> findByExternalIds(
    ExternalIds ids, {
    required MediaKind kind,
    List<String> titles = const [],
    int? year,
    String? plexGuid,
    ExternalSeasonRef? season,
  }) async {
    final itemType = switch (kind) {
      MediaKind.movie => 'Movie',
      MediaKind.show => 'Series',
      _ => null,
    };
    if (itemType == null || !ids.hasAny || titles.isEmpty) return const [];

    final seasonIndex = season?.agreedSeason;
    final shouldGateSeason = kind == MediaKind.show && seasonIndex != null && seasonIndex > 1;
    // Not `seasonIndex`: when the two providers disagree the season number is
    // unusable but the entry is still a sequel, and the ±1 window around a
    // sequel's own year excludes the parent show (its year is season one's).
    final skipYearWindow = season?.isSequel ?? false;

    for (var index = 0; index < titles.length; index++) {
      final isFirstCandidate = index == 0;
      final years = isFirstCandidate && year != null && !skipYearWindow ? '${year - 1},$year,${year + 1}' : null;
      final candidates = await _fetchItemsArray('/Items', {
        'userId': connection.userId,
        'SearchTerm': titles[index],
        'Recursive': 'true',
        'Limit': isFirstCandidate ? '20' : '50',
        'IncludeItemTypes': itemType,
        'Fields': 'ProviderIds,$_browseFields',
        'years': ?years,
        ...jellyfinImageQueryParameters,
      });
      final matches = _mapItems(ExternalIds.jellyfinCandidatesMatching(candidates, ids));
      if (matches.isEmpty) continue;

      final kept = shouldGateSeason ? await _keepMatchesWithSeason(matches, seasonIndex) : matches;
      // A title that verified but has no season-gated survivor is a definitive
      // "this server has the show, just not that season"; broader title forms
      // would only reach other shows.
      if (kept.isEmpty) return const [];
      return Future.wait([for (final item in kept) _withLibraryFromAncestors(item)]);
    }
    return const [];
  }

  /// Keep only the series that actually have [seasonIndex]. One
  /// `fetchChildren` per candidate, issued concurrently because the match list
  /// is deliberately never truncated (see
  /// [MediaServerClient.findByExternalIds]).
  Future<List<MediaItem>> _keepMatchesWithSeason(List<MediaItem> items, int seasonIndex) async {
    final kept = await Future.wait([
      for (final item in items)
        fetchChildren(
          item.id,
        ).then((children) => children.any((child) => child.kind == MediaKind.season && child.index == seasonIndex)),
    ]);
    return [
      for (var index = 0; index < items.length; index++)
        if (kept[index]) items[index],
    ];
  }

  /// Best-effort library stamp for items found outside a library context
  /// (the search-based reverse lookup): `/Items/{id}/Ancestors` names the
  /// owning CollectionFolder. One extra request per match (memoized with the
  /// match by the session-level matcher cache); failures return the item
  /// unstamped.
  Future<MediaItem> _withLibraryFromAncestors(MediaItem item) async {
    try {
      final response = await _http.get(
        '/Items/${_segment(item.id)}/Ancestors',
        queryParameters: {'userId': connection.userId},
      );
      throwIfHttpError(response);
      final data = response.data;
      if (data is! List) return item;
      for (final ancestor in data.whereType<Map<String, dynamic>>()) {
        if (ancestor['Type'] == 'CollectionFolder') {
          return item.copyWith(libraryId: ancestor['Id'] as String?, libraryTitle: ancestor['Name'] as String?);
        }
      }
    } catch (e) {
      appLogger.d('Jellyfin ancestors lookup failed for ${item.id}', error: e);
    }
    return item;
  }

  @override
  Future<List<MediaItem>> fetchPersonMedia(String personId) => drainPages<MediaItem>(
    (start, size) => fetchPersonMediaPage(personId, start: start, size: size),
    pageSize: _pagedListPageSize,
  );

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
    return _pagedItems(response.data, offset: offset, requestedSize: pageSize, map: _mapItems);
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
    return _playbackHubSet(
      idPrefix: 'home',
      limit: limit,
      includePlaybackHubs: includePlaybackHubs,
      includeNextUp: true,
      retry: _homeHubRetry,
      latestItemTypes: 'Movie,Series,Episode',
      continueTitle: t.discover.continueWatching,
      nextUpTitle: t.discover.nextUp,
      recentTitle: t.discover.recentlyAdded,
    );
  }

  @override
  Future<List<MediaHub>> fetchLibraryHubs(
    String libraryId, {
    required String libraryName,
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    MediaKind? libraryKind,
  }) async {
    // Music libraries get their own hub set. Home passes
    // includePlaybackHubs=false because it already renders the app-level
    // playback shelf; in that mode only fetch Latest Albums. Recently Played
    // and Most Played remain available on the library's Recommended tab.
    // Branched before the Latest request below fires (futures are eager):
    // music needs the slim [_musicAlbumRowFields], not [_browseFields].
    if (libraryKind == MediaKind.artist) {
      return _fetchMusicLibraryHubs(
        libraryId,
        libraryName: libraryName,
        limit: limit,
        includePlaybackHubs: includePlaybackHubs,
      );
    }

    // Mirror the Jellyfin web client's per-library "Suggestions" tab:
    // Continue Watching + Next Up (TV libraries) + Recently Added.
    //
    // Issued in parallel so the recommended tab loads in one round-trip.
    // When the caller knows the library kind, skip NextUp for movie libraries;
    // Jellyfin can otherwise spend time scanning TV state only to return [].
    return _playbackHubSet(
      parentId: libraryId,
      idPrefix: 'library.$libraryId',
      limit: limit,
      includePlaybackHubs: includePlaybackHubs,
      includeNextUp: libraryKind == null || libraryKind == MediaKind.show,
      retry: _libraryHubRetry,
      continueTitle: t.discover.continueWatchingIn(library: libraryName),
      nextUpTitle: t.discover.nextUpIn(library: libraryName),
      recentTitle: t.discover.recentlyAddedIn(library: libraryName),
    );
  }

  /// Latest + Continue Watching + Next Up row set shared by the home and
  /// per-library surfaces. Both scopes issue the same three requests in the
  /// same order and synthesise the same three rows; they differ only in
  /// [parentId], the row identifier prefix, the titles, and the transport
  /// policy. The Latest request fires before the [includePlaybackHubs]
  /// short-circuit so callers that only want Recently Added still get it in
  /// one round-trip.
  Future<List<MediaHub>> _playbackHubSet({
    required String idPrefix,
    required int limit,
    required bool includePlaybackHubs,
    required bool includeNextUp,
    required _HubRetryPolicy retry,
    required String continueTitle,
    required String nextUpTitle,
    required String recentTitle,
    String? parentId,
    String? latestItemTypes,
  }) async {
    final latestFuture = _safeFetchItemsArray('/Users/${_segment(connection.userId)}/Items/Latest', {
      'Limit': limit.toString(),
      'ParentId': ?parentId,
      'Fields': _browseFields,
      'IncludeItemTypes': ?latestItemTypes,
      ...jellyfinImageQueryParameters,
    }, retry: retry);

    MediaHub hub(String suffix, String title, String type, List<Map<String, dynamic>> items) =>
        JellyfinMappers.syntheticHub(
          mapItem: _mapItem,
          identifier: '$idPrefix.$suffix',
          title: title,
          type: type,
          items: items,
          previewLimit: limit,
          serverId: serverId,
          serverName: serverName,
        );

    if (!includePlaybackHubs) {
      final latest = await latestFuture;
      return [hub('recent', recentTitle, 'mixed', latest)].where((h) => h.items.isNotEmpty).toList();
    }

    final results = await Future.wait([
      latestFuture,
      _safeFetchItemsArray('/UserItems/Resume', {
        'userId': connection.userId,
        'ParentId': ?parentId,
        'Limit': limit.toString(),
        'Fields': _browseFields,
        'MediaTypes': 'Video',
        'Recursive': 'true',
        'EnableTotalRecordCount': 'false',
        ...jellyfinImageQueryParameters,
      }, retry: retry),
      includeNextUp
          ? _safeFetchItemsArray('/Shows/NextUp', {
              'userId': connection.userId,
              'ParentId': ?parentId,
              'Limit': limit.toString(),
              'Fields': _browseFields,
              'EnableResumable': 'false',
              'EnableTotalRecordCount': 'false',
              ...jellyfinImageQueryParameters,
            }, retry: retry)
          : Future.value(const <Map<String, dynamic>>[]),
    ]);

    return [
      hub('continue', continueTitle, 'mixed', results[1]),
      hub('nextup', nextUpTitle, 'episode', results[2]),
      hub('recent', recentTitle, 'mixed', results.first),
    ].where((h) => h.items.isNotEmpty).toList();
  }

  /// Music-library hub set, mirroring the Jellyfin web client's music
  /// "Suggestions" tab. `/Users/{userId}/Items/Latest` natively groups a
  /// music library's new items into albums; the row carries the
  /// `latestalbums` identifier so [fetchMoreHubItemsPage] expands it with
  /// the same slim album fields. The played rows filter `IsPlayed` so
  /// unplayed tracks (PlayCount 0) never pad them.
  Future<List<MediaHub>> _fetchMusicLibraryHubs(
    String libraryId, {
    required String libraryName,
    required int limit,
    required bool includePlaybackHubs,
  }) async {
    final latestFuture = _safeFetchItemsArray('/Users/${_segment(connection.userId)}/Items/Latest', {
      'Limit': limit.toString(),
      'ParentId': libraryId,
      'Fields': _musicAlbumRowFields,
      'EnableUserData': 'false',
      ...jellyfinImageQueryParameters,
    }, retry: _libraryHubRetry);

    MediaHub latestAlbumsHub(List<Map<String, dynamic>> items) => JellyfinMappers.syntheticHub(
      mapItem: _mapItem,
      identifier: 'library.$libraryId.latestalbums',
      title: t.discover.latestAlbumsIn(library: libraryName),
      type: 'album',
      items: items,
      previewLimit: limit,
      serverId: serverId,
      serverName: serverName,
    );

    if (!includePlaybackHubs) {
      return [latestAlbumsHub(await latestFuture)].where((hub) => hub.items.isNotEmpty).toList();
    }
    final playedParams = <String, String>{
      'userId': connection.userId,
      'ParentId': libraryId,
      'IncludeItemTypes': 'Audio',
      'Recursive': 'true',
      'Filters': 'IsPlayed',
      'SortOrder': 'Descending',
      'Limit': limit.toString(),
      'Fields': _musicTrackRowFields,
      'EnableTotalRecordCount': 'false',
      ...jellyfinImageQueryParameters,
    };
    final results = await Future.wait([
      latestFuture,
      _safeFetchItemsArray('/Items', {...playedParams, 'SortBy': 'DatePlayed'}, retry: _libraryHubRetry),
      _safeFetchItemsArray('/Items', {...playedParams, 'SortBy': 'PlayCount'}, retry: _libraryHubRetry),
    ]);

    return [
      latestAlbumsHub(results.first),
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

  /// Expand a synthetic hub so the detail screen can render beyond its
  /// preview. Recently Added uses the pageable Items endpoint with the same
  /// date-created ordering and media types as Jellyfin's Latest query.
  /// Latest Albums retains the grouped, single-page Latest endpoint.
  /// Continue Watching, Next Up, Recently Played, and Most Played use their
  /// native pageable endpoints. Unknown ids return an empty list.
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
        return _safeFetchMediaPage(
          '/Items',
          {
            'userId': connection.userId,
            'ParentId': ?parentId,
            'Recursive': 'true',
            'StartIndex': offset.toString(),
            'Limit': effectiveLimit,
            'EnableTotalRecordCount': 'true',
            'IncludeItemTypes': 'Movie,Series,Episode,Video,MusicVideo,Photo',
            'SortBy': 'DateCreated,SortName,ProductionYear',
            'SortOrder': 'Descending,Descending,Descending',
            'Fields': _browseFields,
            ...jellyfinImageQueryParameters,
          },
          offset: offset,
          requestedSize: pageSize,
          abort: abort,
        );
      case 'latestalbums':
        // Latest groups music into albums but does not expose StartIndex.
        if (offset > 0) return LibraryPage<MediaItem>(items: const [], totalCount: offset, offset: offset);
        return _safeFetchMediaPage(
          '/Users/${_segment(connection.userId)}/Items/Latest',
          {
            'Limit': effectiveLimit,
            'Fields': _musicAlbumRowFields,
            'EnableUserData': 'false',
            'ParentId': ?parentId,
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
            'Fields': _musicTrackRowFields,
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
      return _pagedItems(
        response.data,
        offset: offset,
        requestedSize: requestedSize,
        singlePage: singlePage,
        map: _mapItems,
      );
    } catch (e, st) {
      appLogger.w('JellyfinClient: $path failed', error: e, stackTrace: st);
      rethrow;
    }
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
  ///
  /// One `ParentId`-scoped lookup per pending series, not a single server-wide
  /// DatePlayed scan. Jellyfin 12.0-rc3 builds that sort key by OR-ing an item's
  /// own progress with its alternate versions' (`ItemId == e.Id ||
  /// Item.PrimaryVersionId == e.Id`, jellyfin/jellyfin#17044), which no index can
  /// serve, so the user's entire UserData table is scanned per sorted row: an
  /// unscoped episode sort measured 5.8s on a 6k-episode rc3 library against
  /// 25ms on 10.10.7, pegging a core for its whole duration. That blew this
  /// call's request budget and starved every other client of the server (#1699).
  /// `ParentId` bounds the sort input to one series' episodes — 21 series resolve
  /// in ~0.6s against the same rc3 server. Upstream fixed the order mapper after
  /// rc3 (jellyfin/jellyfin#17422); scoping keeps the cost flat on servers that
  /// still carry the regression.
  ///
  /// At most [_seriesLastPlayedLookupLimit] series are enriched. `/Shows/NextUp`
  /// already returns series in last-played-descending order, so the cap keeps the
  /// rows whose dates decide the top of the shelf while bounding total work for
  /// an uncapped `count: null` shelf, which can carry far more series than the
  /// home preview. Rows past the cap keep a null date and degrade to their
  /// `addedAt` in the sort — the same degradation the previous 200-row lookback
  /// window applied to a series whose last play fell outside it.
  ///
  /// The batches are sequential and [MediaServerHttpClient] applies a per-call
  /// `timeout` to the connect and receive phases *separately*, so a per-request
  /// budget alone would still let a stalled endpoint hold this best-effort
  /// enrichment for batches × 2 × [_seriesLastPlayedRequestTimeout]. The whole
  /// pass therefore shares one [_seriesLastPlayedBudget] deadline that aborts
  /// in-flight lookups rather than merely gating the next batch: whatever phase a
  /// lookup is stuck in — silent connect, delayed headers, stalled body — the
  /// pass is done within the budget.
  Future<List<MediaItem>> _attachSeriesLastPlayed(List<MediaItem> nextUp) async {
    // Set literal over `nextUp` order: insertion-ordered, so `take` below keeps
    // the most recently played series.
    final pendingSeriesIds = <String>{
      for (final item in nextUp)
        if (item.kind == MediaKind.episode && item.lastViewedAt == null && item.grandparentId != null)
          item.grandparentId!,
    };
    if (pendingSeriesIds.isEmpty) return nextUp;

    final seriesIds = pendingSeriesIds.take(_seriesLastPlayedLookupLimit).toList(growable: false);
    final lastPlayedBySeries = <String, int>{};
    // A timer, not a Stopwatch: fake_async virtualises timers, and the deadline
    // has to fire *into* the in-flight batch, not just before the next one.
    final budgetAbort = AbortController();
    final deadline = Timer(_seriesLastPlayedBudget, budgetAbort.abort);
    try {
      for (var start = 0; start < seriesIds.length; start += _seriesLastPlayedConcurrency) {
        if (budgetAbort.isAborted) break;
        final batch = seriesIds.skip(start).take(_seriesLastPlayedConcurrency);
        final lookups = Future.wait(batch.map((id) => _fetchSeriesLastPlayed(id, budgetAbort)));
        // Aborting only asks the transport to stop, and not every client honours
        // `abortTrigger`. Racing the same deadline here makes the ceiling ours
        // rather than the transport's.
        final played = await Future.any([lookups, budgetAbort.trigger.then((_) => const <(String, int?)>[])]);
        // No-op once `lookups` has won; suppresses the loser's late completion.
        lookups.ignore();
        for (final (seriesId, playedAt) in played) {
          if (playedAt != null) lastPlayedBySeries[seriesId] = playedAt;
        }
      }
    } finally {
      deadline.cancel();
      // Releases any lookup still waiting on the trigger and tells the transport
      // to drop the socket instead of finishing a response nobody reads.
      budgetAbort.abort();
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

  /// Newest `LastPlayedDate` across [seriesId]'s episodes, or null when the
  /// series has never been played — or when the lookup failed, in which case the
  /// row keeps a null date and degrades to its `addedAt` in the shelf sort.
  ///
  /// Deliberately no `Filters=IsPlayed`: Jellyfin's own NextUp ranks series by
  /// MAX(LastPlayedDate) across every episode, and an episode can carry a
  /// LastPlayedDate while Played==false (started but not finished, or later
  /// marked unwatched). Filtering to IsPlayed would leave those series un-dated.
  /// Null dates sort last under `Descending`, so the single row returned is the
  /// series' newest play whenever it has one. Endpoint failover stays off: a slow
  /// enrichment row must not move the whole client off a working endpoint.
  ///
  /// [budgetAbort] fires when the shared deadline expires. `_safeFetchItemsArray`
  /// rethrows cancellation so paged callers can tell "disrupted" from "empty";
  /// here disrupted *is* undated, which is the intended degradation, so it is
  /// swallowed with every other failure instead of sinking the shelf.
  Future<(String, int?)> _fetchSeriesLastPlayed(String seriesId, AbortController budgetAbort) async {
    try {
      final raw = await _safeFetchItemsArray(
        '/Items',
        {
          'userId': connection.userId,
          'ParentId': seriesId,
          'IncludeItemTypes': 'Episode',
          'Recursive': 'true',
          'SortBy': 'DatePlayed',
          'SortOrder': 'Descending',
          // Only `UserData.LastPlayedDate` is read off the row.
          'Fields': 'UserData',
          'Limit': '1',
          'EnableImages': 'false',
          'EnableTotalRecordCount': 'false',
        },
        abort: budgetAbort,
        timeout: _seriesLastPlayedRequestTimeout,
        allowEndpointFailover: false,
      );
      return (seriesId, _mapItems(raw).firstOrNull?.lastViewedAt);
    } on MediaServerHttpException {
      return (seriesId, null);
    }
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
  ///
  /// [timeout] and [allowEndpointFailover] configure the un-retried path only; a
  /// [retry] policy carries its own per-attempt timeouts and always disables
  /// failover.
  Future<MediaServerResponse> _getItemsResponse(
    String path,
    Map<String, dynamic> queryParameters,
    _HubRetryPolicy? retry, {
    AbortController? abort,
    Duration? timeout,
    bool allowEndpointFailover = true,
  }) {
    if (retry == null) {
      return _http.get(
        path,
        queryParameters: queryParameters,
        abort: abort,
        timeout: timeout,
        allowEndpointFailover: allowEndpointFailover,
      );
    }
    abort?.throwIfAborted();
    return retryTransientMediaServerCall(
      operation: retry.operation,
      attemptTimeouts: retry.attemptTimeouts,
      call: (timeout, attemptAbort) => _http.get(
        path,
        queryParameters: queryParameters,
        timeout: timeout,
        abort: attemptAbort,
        allowEndpointFailover: false,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchItemsArray(
    String path,
    Map<String, dynamic> queryParameters, {
    _HubRetryPolicy? retry,
    AbortController? abort,
  }) async {
    final response = await _getItemsResponse(path, queryParameters, retry, abort: abort);
    abort?.throwIfAborted();
    throwIfHttpError(response);
    return _itemsArray(response.data);
  }

  Future<List<Map<String, dynamic>>> _safeFetchItemsArray(
    String path,
    Map<String, dynamic> queryParameters, {
    _HubRetryPolicy? retry,
    AbortController? abort,
    Duration? timeout,
    bool allowEndpointFailover = true,
  }) async {
    try {
      final response = await _getItemsResponse(
        path,
        queryParameters,
        retry,
        abort: abort,
        timeout: timeout,
        allowEndpointFailover: allowEndpointFailover,
      );
      abort?.throwIfAborted();
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
