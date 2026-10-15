import 'dart:async';

import '../../connection/connection.dart';
import '../../exceptions/media_server_exceptions.dart';
import '../../media/artist_discography.dart';
import '../../media/download_resolution.dart';
import '../../media/ids.dart';
import '../../media/library_filter_result.dart';
import '../../media/library_query.dart';
import '../../media/live_tv_support.dart';
import '../../media/lyrics.dart';
import '../../media/media_backend.dart';
import '../../media/media_file_info.dart';
import '../../media/media_hub.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_library.dart';
import '../../media/media_person.dart';
import '../../media/media_playlist.dart';
import '../../media/media_server_client.dart';
import '../../media/media_sort.dart';
import '../../media/media_source_info.dart';
import '../../media/media_version.dart';
import '../../media/playback_report_metadata.dart';
import '../../media/server_capabilities.dart';
import '../../models/livetv_channel.dart';
import '../../models/livetv_program.dart';
import '../../models/transcode_quality_preset.dart';
import '../../utils/app_logger.dart';
import '../../utils/external_ids.dart';
import '../../utils/media_server_http_client.dart' show AbortController;
import '../api_cache.dart';
import '../playback_initialization_types.dart';
import '../scrub_preview_source.dart';
import 'silo_api.dart';
import 'silo_api_cache.dart';
import 'silo_json.dart';
import 'silo_mappers.dart';
import 'silo_playback.dart';

/// [MediaServerClient] for a Silo server, speaking its native `/api/v2`
/// contract directly (no Jellyfin-compatibility layer).
///
/// One client serves one [SiloConnection]: one server, one signed-in account,
/// one household profile. Everything it reports (progress, watched state)
/// is therefore scoped to that profile, and its cache namespace is the
/// connection id `{serverId}/{profileId}`.
///
/// Scope of this first version: movie and TV libraries, home rows and
/// Continue Watching, search, series/season/episode browsing, playback with
/// the server's direct-play/remux/transcode negotiation, audio and subtitle
/// tracks, progress/stop reporting and watched state. Music, playlists,
/// collections editing, live TV, downloads and metadata editing report as
/// unsupported.
class SiloClient with MediaServerCacheMixin implements MediaServerClient, ScopedMediaServerClient {
  SiloClient._(this._connection, this._api, this.appVersion, this.platform)
    : _mappers = SiloMappers(
        serverId: ServerId(_connection.serverId),
        serverName: _connection.serverName,
        resolveUrl: _api.resolveServerUrl,
      ),
      _reporter = SiloPlaybackReporter(_api);

  /// Build a client for [connection]. [onConnectionUpdated] receives the
  /// connection with rotated tokens after every refresh so it can be
  /// persisted; [onSessionEnded] fires when the server refuses the session.
  factory SiloClient.create(
    SiloConnection connection, {
    required SiloClientIdentity identity,
    FutureOr<void> Function(SiloConnection updated)? onConnectionUpdated,
    void Function()? onSessionEnded,
  }) {
    final api = SiloApi(
      baseUrl: connection.baseUrl,
      identity: identity,
      tokens: SiloTokens(
        accessToken: connection.accessToken,
        refreshToken: connection.refreshToken,
        expiresAt: connection.accessTokenExpiresAt,
      ),
      profileId: connection.profileId,
      profileToken: connection.profileToken,
    );
    final client = SiloClient._(connection, api, identity.appVersion, identity.platform);
    api.onTokensChanged = (tokens) async {
      client._connection = client._connection.copyWith(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        accessTokenExpiresAt: tokens.expiresAt,
        lastAuthenticatedAt: DateTime.now(),
      );
      client._sessionIdentity = Object();
      await onConnectionUpdated?.call(client._connection);
    };
    api.onSessionEnded = onSessionEnded;
    return client;
  }

  SiloConnection _connection;
  final SiloApi _api;
  final SiloMappers _mappers;
  final SiloPlaybackReporter _reporter;
  final String appVersion;
  final String platform;
  Object _sessionIdentity = Object();
  bool _offline = false;

  Map<String, dynamic>? _playbackCapabilities;
  DateTime? _playbackCapabilitiesAt;

  SiloConnection get connection => _connection;
  SiloApi get api => _api;

  @override
  ServerId get serverId => ServerId(_connection.serverId);

  @override
  String get scopedServerId => _connection.id;

  @override
  String? get serverName => _connection.serverName;

  @override
  MediaBackend get backend => MediaBackend.silo;

  @override
  ServerCapabilities get capabilities => siloCapabilities;

  static const siloCapabilities = ServerCapabilities(
    liveTv: false,
    liveTvDvr: false,
    videoTranscoding: true,
    richHubs: true,
    numericUserRating: false,
    userFavorites: false,
    continueWatchingRemoval: false,
    externalSubtitleSearch: false,
    richMetadataEdit: false,
    scrubThumbnails: false,
    folderGrouping: false,
    instantMix: false,
    libraryChangeEvents: false,
  );

  @override
  Object get authenticationSessionId => _sessionIdentity;

  @override
  void close() {
    unawaited(_reporter.stopAll().whenComplete(_api.close));
  }

  @override
  bool get isOfflineMode => _offline;

  @override
  void setOfflineMode(bool offline) => _offline = offline;

  @override
  ApiCache get cache => SiloApiCache.instance;

  ServerId get _cacheScope => ServerId(cacheServerId);

  void _cacheItems(Iterable<MediaItem> items) {
    for (final item in items) {
      unawaited(SiloApiCache.instance.putItem(_cacheScope, item));
    }
  }

  // ----------------------------------------------------------------- health

  @override
  Future<HealthStatus> checkHealth() async {
    try {
      // A profile-scoped read: proves the bearer, the profile, and (for a
      // PIN-locked profile) that its PIN proof is still accepted.
      await _api.userLibraries();
      return HealthStatus.online;
    } on MediaServerAuthException {
      return HealthStatus.authError;
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 401) return HealthStatus.authError;
      if (e.statusCode == 403) return HealthStatus.accessDenied;
      return HealthStatus.offline;
    } catch (_) {
      return HealthStatus.offline;
    }
  }

  @override
  Future<String?> getMachineIdentifier() async {
    try {
      return strOrNull((await _api.serverIdentity())['server_id']);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------- libraries

  @override
  Future<List<MediaLibrary>> fetchLibraries() async {
    final rows = await _api.userLibraries();
    return [
      for (final row in rows)
        if (SiloMappers.isVideoLibrary(row['type'])) ?_mappers.library(row),
    ];
  }

  static String? _siloSort(LibrarySort? sort) {
    if (sort == null) return null;
    final field = switch (sort.field) {
      'title' || 'titleSort' => 'title',
      'addedAt' => 'added_at',
      'year' => 'year',
      'originallyAvailableAt' || 'releaseDate' => 'release_date',
      'rating' || 'audienceRating' => 'rating',
      'duration' || 'runtime' => 'runtime',
      _ => null,
    };
    if (field == null) return null;
    return sort.direction == LibrarySortDirection.descending ? '-$field' : field;
  }

  static String _siloType(LibraryQuery query, MediaKind? libraryKind) {
    final kinds = query.includeKinds.isNotEmpty ? query.includeKinds : [?(query.kind ?? libraryKind)];
    final wantsMovies = kinds.contains(MediaKind.movie);
    final wantsShows = kinds.contains(MediaKind.show);
    if (wantsMovies && !wantsShows) return 'movie';
    if (wantsShows && !wantsMovies) return 'series';
    return 'video';
  }

  @override
  Future<LibraryPage<MediaItem>> fetchLibraryPagedContent(
    String libraryId, {
    required LibraryQuery query,
    MediaKind? libraryKind,
    AbortController? abort,
  }) async {
    final limit = query.limit.clamp(1, 200);
    final prefix = query.nameStartsWith;
    final response = await _api.catalog({
      'library_id': libraryId,
      'type': _siloType(query, libraryKind),
      'limit': '$limit',
      if (query.offset > 0) 'seek': '${query.offset}',
      if (_siloSort(query.sort) case final sort?) 'sort': sort,
      if (query.search != null && query.search!.trim().isNotEmpty) 'q': query.search!.trim(),
      // `#` is Plezy's "non-alphabetic" sentinel; Silo has no equivalent
      // filter, so it is not sent.
      if (prefix != null && prefix.isNotEmpty && prefix != '#') 'name_prefix': prefix,
    }, abort: abort);
    final items = [
      for (final row in mapList(response['items'])) ?_mappers.item(row, libraryId: libraryId),
    ];
    _cacheItems(items);
    final total = intOrNull(response['total']);
    return LibraryPage(
      items: items,
      offset: query.offset,
      totalCount: total ?? fallbackPageTotal(offset: query.offset, itemCount: items.length, requestedSize: limit),
    );
  }

  @override
  Future<LibraryFilterResult> fetchLibraryFiltersWithValues(String libraryId, {MediaKind? libraryKind}) async =>
      LibraryFilterResult.empty;

  @override
  Future<List<MediaSort>> fetchSortOptions(String libraryId, {String? libraryType}) async => const [
    MediaSort(key: 'title', descKey: 'title:desc', title: 'Title', defaultDirection: 'asc'),
    MediaSort(key: 'addedAt', descKey: 'addedAt:desc', title: 'Date added', defaultDirection: 'desc'),
    MediaSort(
      key: 'originallyAvailableAt',
      descKey: 'originallyAvailableAt:desc',
      title: 'Release date',
      defaultDirection: 'desc',
    ),
    MediaSort(key: 'rating', descKey: 'rating:desc', title: 'Rating', defaultDirection: 'desc'),
    MediaSort(key: 'duration', descKey: 'duration:desc', title: 'Runtime', defaultDirection: 'desc'),
  ];

  @override
  Future<void> refreshLibraryMetadata(String libraryId) async {
    throw UnsupportedError('Refreshing library metadata is done from the Silo web app');
  }

  // ------------------------------------------------------------------ items

  @override
  Future<MediaItem?> fetchItem(String id) async {
    if (_offline) return SiloApiCache.instance.getMetadata(_cacheScope, id);
    final season = parseSiloSeasonId(id);
    if (season != null) return _fetchSeason(season.seriesId, season.seasonNumber);
    try {
      final json = await _api.catalogItem(id);
      final item = _mappers.item(json);
      if (item != null) _cacheItems([item]);
      return item;
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 404) return null;
      if (e.isTransient) return SiloApiCache.instance.getMetadata(_cacheScope, id);
      rethrow;
    }
  }

  Future<MediaItem?> _fetchSeason(String seriesId, int number) async {
    final seasons = await _seasons(seriesId);
    return seasons.where((s) => s.index == number).firstOrNull;
  }

  @override
  Future<({MediaItem? item, MediaItem? onDeckEpisode})> fetchItemWithOnDeck(
    String id, {
    void Function(MediaItem item)? onItemReady,
  }) async {
    final item = await fetchItem(id);
    if (item == null || item.kind != MediaKind.show) return (item: item, onDeckEpisode: null);
    onItemReady?.call(item);
    final playId = strOrNull(item.raw?['play_content_id']);
    if (playId == null || playId == id) return (item: item, onDeckEpisode: null);
    try {
      return (item: item, onDeckEpisode: await fetchItem(playId));
    } catch (e) {
      appLogger.w('Silo: next-episode lookup failed', error: e);
      return (item: item, onDeckEpisode: null);
    }
  }

  Future<List<MediaItem>> _seasons(String seriesId) async {
    final response = await _api.seriesSeasons(seriesId);
    MediaItem? series;
    try {
      series = await SiloApiCache.instance.getMetadata(_cacheScope, seriesId);
    } catch (_) {}
    final seasons = [
      for (final row in mapList(response['items']))
        ?_mappers.season(row, seriesId: seriesId, seriesTitle: series?.title, seriesPoster: series?.thumbPath),
    ];
    // Regular seasons first, specials last, as Silo's own clients show them.
    seasons.sort((a, b) {
      final ai = a.index ?? 0, bi = b.index ?? 0;
      if (ai == 0 && bi != 0) return 1;
      if (bi == 0 && ai != 0) return -1;
      return ai.compareTo(bi);
    });
    _cacheItems(seasons);
    return seasons;
  }

  Future<List<MediaItem>> _episodes(String seriesId, int seasonNumber) async {
    final response = await _api.seasonEpisodes(seriesId, seasonNumber);
    MediaItem? series;
    try {
      series = await SiloApiCache.instance.getMetadata(_cacheScope, seriesId);
    } catch (_) {}
    final episodes = [
      for (final row in mapList(response['items']))
        ?_mappers.episode(
          row,
          seriesId: seriesId,
          seriesTitle: series?.title,
          seriesPoster: series?.thumbPath,
          seriesBackdrop: series?.artPath,
        ),
    ];
    _cacheItems(episodes);
    return episodes;
  }

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async {
    final season = parseSiloSeasonId(parentId);
    if (season != null) return _episodes(season.seriesId, season.seasonNumber);
    final parent = await fetchItem(parentId);
    if (parent?.kind == MediaKind.show) return _seasons(parentId);
    return const [];
  }

  @override
  Future<List<MediaItem>> fetchLibraryFolders(
    String libraryId, {
    void Function(List<MediaItem> itemsSoFar)? onPage,
  }) async => const [];

  @override
  Future<List<MediaItem>> fetchFolderChildren(
    MediaItem folder, {
    String? libraryId,
    String? libraryTitle,
    void Function(List<MediaItem> itemsSoFar)? onPage,
  }) => fetchChildren(folder.id);

  LibraryPage<MediaItem> _slice(List<MediaItem> all, int? start, int? size) {
    final from = (start ?? 0).clamp(0, all.length);
    final to = size == null ? all.length : (from + size).clamp(from, all.length);
    return LibraryPage(items: all.sublist(from, to), totalCount: all.length, offset: from);
  }

  @override
  Future<LibraryPage<MediaItem>> fetchChildrenPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async => _slice(await fetchChildren(parentId), start, size);

  @override
  Future<LibraryPage<MediaItem>> fetchPlayableDescendantsPage(
    String parentId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async => _slice(await fetchPlayableDescendants(parentId), start, size);

  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async {
    final season = parseSiloSeasonId(parentId);
    if (season != null) return _episodes(season.seriesId, season.seasonNumber);
    final parent = await fetchItem(parentId);
    switch (parent?.kind) {
      case MediaKind.show:
        final seasons = await _seasons(parentId);
        final out = <MediaItem>[];
        for (final s in seasons) {
          final number = s.index;
          if (number == null) continue;
          out.addAll(await _episodes(parentId, number));
        }
        return out;
      case MediaKind.movie || MediaKind.episode:
        return [parent!];
      default:
        return const [];
    }
  }

  @override
  Future<List<MediaItem>?> fetchClientSideEpisodeQueue(String seriesId) async {
    final seasons = await _seasons(seriesId);
    final out = <MediaItem>[];
    for (final s in seasons) {
      final number = s.index;
      if (number == null || number == 0) continue;
      out.addAll(await _episodes(seriesId, number));
    }
    return out;
  }

  // ------------------------------------------------------------------ music

  @override
  Future<List<MediaItem>> fetchArtistAlbums(MediaItem artist) async => const [];

  @override
  Future<List<ArtistDiscographyGroup>> fetchArtistDiscography(MediaItem artist) async => const [];

  @override
  Future<List<MediaItem>> fetchAlbumTracks(String albumId) async => const [];

  @override
  Future<List<MediaItem>> fetchInstantMix(String itemId, {int limit = 100}) async => const [];

  @override
  Future<Lyrics?> fetchLyrics(MediaItem track) async => null;

  // ----------------------------------------------------------------- search

  @override
  Future<List<MediaItem>> searchItems(
    String query, {
    int limit = 100,
    AbortController? abort,
    Set<String> excludedLibraryIds = const {},
  }) async {
    final text = query.trim();
    if (text.isEmpty) return const [];
    final response = await _api.catalog({'q': text, 'type': 'video', 'limit': '${limit.clamp(1, 200)}'}, abort: abort);
    final items = [
      for (final row in mapList(response['items'])) ?_mappers.item(row),
    ];
    _cacheItems(items);
    return items;
  }

  @override
  Future<List<MediaPerson>> searchPeople(
    String query, {
    int limit = defaultPeopleSearchLimit,
    AbortController? abort,
    Set<String> excludedLibraryIds = const {},
  }) async => const [];

  // ------------------------------------------------------------------- home

  Future<List<Map<String, dynamic>>> _homeSections() => _api.homeSections();

  @override
  Future<List<MediaItem>> fetchContinueWatching({
    int? count = 20,
    Set<String> excludedLibraryIds = const {},
  }) async {
    final sections = await _homeSections();
    final section = sections.where((s) => str(s['section_type']) == siloContinueWatchingSection).firstOrNull;
    if (section == null) return const [];
    var rows = mapList(section['items']);
    final total = intOrNull(section['total_count']) ?? rows.length;
    if ((count == null || count > rows.length) && total > rows.length) {
      try {
        rows = mapList((await _api.homeSectionItems(str(section['id'])))['items']);
      } catch (e) {
        appLogger.w('Silo: full Continue Watching list unavailable', error: e);
      }
    }
    final items = [
      for (final row in rows) ?_mappers.item(row),
    ];
    _cacheItems(items);
    return count == null ? items : items.take(count).toList();
  }

  @override
  Future<List<MediaHub>> fetchGlobalHubs({
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    HubFetchDiagnostics? diagnostics,
  }) async {
    try {
      final sections = await _homeSections();
      final hubs = <MediaHub>[];
      for (final section in sections) {
        if (!includePlaybackHubs && str(section['section_type']) == siloContinueWatchingSection) continue;
        final hub = _mappers.hub(section);
        if (hub == null) continue;
        _cacheItems(hub.items);
        hubs.add(hub.items.length > limit ? hub.copyWith(items: hub.items.take(limit).toList()) : hub);
      }
      return hubs;
    } catch (e) {
      diagnostics?.recordFailure(e);
      appLogger.w('Silo: home sections unavailable', error: e);
      return const [];
    }
  }

  @override
  Future<List<MediaHub>> fetchLibraryHubs(
    String libraryId, {
    required String libraryName,
    int limit = defaultHubPreviewLimit,
    bool includePlaybackHubs = true,
    MediaKind? libraryKind,
    HubFetchDiagnostics? diagnostics,
  }) async {
    try {
      final response = await _api.catalog({
        'library_id': libraryId,
        'type': libraryKind == MediaKind.movie
            ? 'movie'
            : libraryKind == MediaKind.show
            ? 'series'
            : 'video',
        'sort': '-added_at',
        'limit': '$limit',
        'skip_total': 'true',
      });
      final items = [
        for (final row in mapList(response['items'])) ?_mappers.item(row, libraryId: libraryId),
      ];
      if (items.isEmpty) return const [];
      _cacheItems(items);
      return [
        MediaHub(
          id: 'silo-recent:$libraryId',
          identifier: 'silo.recently_added',
          title: 'Recently added in $libraryName',
          type: libraryKind == MediaKind.show ? 'show' : 'movie',
          items: items,
          size: items.length,
          more: false,
          libraryId: libraryId,
          serverId: serverId,
          serverName: serverName,
        ),
      ];
    } catch (e) {
      diagnostics?.recordFailure(e);
      return const [];
    }
  }

  @override
  Future<List<MediaHub>> fetchRelatedHubs(String id, {int count = 10}) async => const [];

  @override
  Future<List<MediaItem>> fetchExtras(String id) async => const [];

  @override
  Future<LibraryPage<MediaItem>> fetchPersonMediaPage(
    String personId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final limit = (size ?? 50).clamp(1, 200);
    final response = await _api.catalog({
      'source': 'person',
      'person_id': personId,
      'type': 'video',
      'limit': '$limit',
      if ((start ?? 0) > 0) 'seek': '$start',
    }, abort: abort);
    final items = [
      for (final row in mapList(response['items'])) ?_mappers.item(row),
    ];
    return LibraryPage(
      items: items,
      offset: start ?? 0,
      totalCount: intOrNull(response['total']) ??
          fallbackPageTotal(offset: start ?? 0, itemCount: items.length, requestedSize: limit),
    );
  }

  @override
  Future<List<MediaItem>> fetchMoreHubItems(String hubId, {int? limit}) async {
    final sectionId = parseSiloHubId(hubId);
    if (sectionId == null) return const [];
    final section = await _api.homeSectionItems(sectionId);
    final items = [
      for (final row in mapList(section['items'])) ?_mappers.item(row),
    ];
    _cacheItems(items);
    return limit == null ? items : items.take(limit).toList();
  }

  @override
  Future<LibraryPage<MediaItem>> fetchMoreHubItemsPage(
    String hubId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async => _slice(await fetchMoreHubItems(hubId), start, size);

  // ----------------------------------------------------------- watch state

  @override
  Future<void> markWatched(MediaItem item) => _setWatched(item, true);

  @override
  Future<void> markUnwatched(MediaItem item) => _setWatched(item, false);

  Future<void> _setWatched(MediaItem item, bool watched) async {
    // A season is addressed by series + number; Silo marks its episodes.
    final season = parseSiloSeasonId(item.id);
    final ids = season != null ? [for (final e in await _episodes(season.seriesId, season.seasonNumber)) e.id] : [item.id];
    for (final id in ids) {
      if (watched) {
        await _api.markWatched(id);
      } else {
        await _api.unmarkWatched(id);
      }
    }
  }

  @override
  Future<void> removeFromContinueWatching(MediaItem item) =>
      Future.error(UnsupportedError('Silo has no hide-from-Continue-Watching operation'));

  @override
  Future<void> rate(MediaItem item, double rating) =>
      Future.error(UnsupportedError('Rating is not supported for Silo yet'));

  @override
  Future<void> setFavorite(MediaItem item, bool isFavorite) =>
      Future.error(UnsupportedError('Favorites are not supported for Silo yet'));

  // ------------------------------------------------------ playlists etc.

  @override
  Future<LibraryPage<MediaPlaylist>> fetchPlaylistsPage({
    String playlistType = 'video',
    bool? smart,
    int? start,
    int? size,
    AbortController? abort,
  }) async => const LibraryPage(items: [], totalCount: 0);

  @override
  Future<MediaPlaylist?> fetchPlaylistMetadata(String id) async => null;

  @override
  Future<LibraryPage<MediaItem>> fetchPlaylistPage(
    String id, {
    int? start,
    int? size,
    AbortController? abort,
  }) async => const LibraryPage(items: [], totalCount: 0);

  @override
  Future<MediaPlaylist?> createPlaylist({required String title, required List<MediaItem> items}) =>
      Future.error(UnsupportedError('Playlists are not supported for Silo yet'));

  @override
  Future<bool> addToPlaylist({required String playlistId, required List<MediaItem> items}) async => false;

  @override
  Future<bool> deletePlaylist(MediaPlaylist playlist) async => false;

  @override
  Future<bool> movePlaylistItem({
    required String playlistId,
    required MediaItem item,
    required int newIndex,
    required MediaItem? afterItem,
  }) async => false;

  @override
  Future<bool> removeFromPlaylist({required String playlistId, required MediaItem item}) async => false;

  @override
  Future<LibraryPage<MediaItem>> fetchCollectionsPage(
    String libraryId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async => const LibraryPage(items: [], totalCount: 0);

  @override
  Future<LibraryPage<MediaItem>> fetchCollectionPage(
    String collectionId, {
    int? start,
    int? size,
    AbortController? abort,
    String? libraryId,
    String? libraryTitle,
  }) async => const LibraryPage(items: [], totalCount: 0);

  @override
  Future<List<CollectionMembership>> fetchCollectionMemberships(Set<String> itemIds, {AbortController? abort}) async =>
      const [];

  @override
  Future<String?> createCollection({
    required String libraryId,
    required String title,
    required List<MediaItem> items,
    MediaKind? itemKind,
  }) => Future.error(UnsupportedError('Collections are managed in the Silo web app'));

  @override
  Future<bool> addToCollection({required String collectionId, required List<MediaItem> items}) async => false;

  @override
  Future<bool> removeFromCollection({required String collectionId, required MediaItem item}) async => false;

  @override
  Future<bool> deleteCollection(MediaItem collection) async => false;

  @override
  Future<bool> deleteMediaItem(MediaItem item) async => false;

  @override
  Future<MediaFileInfo?> getFileInfo(MediaItem item) async => null;

  // ---------------------------------------------------------------- images

  @override
  String thumbnailUrl(String? path, {int? width, int? height, bool cover = true}) {
    // Silo artwork URLs are presigned for the size the request named
    // (`image_size`); they authenticate themselves, so no token is added.
    if (path == null || path.isEmpty) return '';
    return _api.resolveServerUrl(path);
  }

  @override
  String externalImageUrl(String url, {int? width, int? height, bool cover = true}) => url;

  @override
  Map<String, String> get streamHeaders => _api.mediaHeaders;

  // ------------------------------------------------------------ external

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async {
    final json = await _api.catalogItem(itemId);
    return ExternalIds(
      imdb: strOrNull(json['imdb_id']),
      tmdb: intOrNull(json['tmdb_id']),
      tvdb: intOrNull(json['tvdb_id']),
    );
  }

  @override
  Future<List<MediaItem>?> findByExternalIds(
    ExternalIds ids, {
    required MediaKind kind,
    List<String> titles = const [],
    int? year,
    String? plexGuid,
    ExternalSeasonRef? season,
  }) async => null;

  // ---------------------------------------------------------- playback data

  @override
  Future<PlaybackExtras> fetchPlaybackExtras(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
    bool forceRefresh = false,
  }) async {
    final watch = await _api.watchState(itemId);
    final version = _pickVersion(watch, null);
    return _extrasFor(
      version,
      introPattern: introPattern,
      creditsPattern: creditsPattern,
      forceChapterFallback: forceChapterFallback,
    );
  }

  PlaybackExtras _extrasFor(
    Map<String, dynamic>? version, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
  }) {
    final chapters = <MediaChapter>[];
    final markers = <MediaMarker>[];
    if (version != null) {
      final rows = mapList(version['chapters']);
      for (var i = 0; i < rows.length; i++) {
        chapters.add(
          MediaChapter(
            id: i,
            index: i,
            startTimeOffset: secondsToMs(rows[i]['start_seconds']),
            endTimeOffset: secondsToMs(rows[i]['end_seconds']),
            title: strOrNull(rows[i]['title']),
            thumb: strOrNull(rows[i]['thumbnail_url']),
          ),
        );
      }
      final segments = mapList(version['marker_segments']);
      for (var i = 0; i < segments.length; i++) {
        final kind = str(segments[i]['kind']);
        final start = secondsToMs(segments[i]['start_seconds']);
        final end = secondsToMs(segments[i]['end_seconds']);
        if (start == null || end == null || end <= start) continue;
        // Plezy acts on intro and credits markers; recap and preview are
        // kept under their own names.
        markers.add(MediaMarker(id: i, type: kind, startTimeOffset: start, endTimeOffset: end));
      }
    }
    return PlaybackExtras.withChapterFallback(
      chapters: chapters,
      markers: markers,
      introPatternStr: introPattern,
      creditsPatternStr: creditsPattern,
      forceChapterFallback: forceChapterFallback,
    );
  }

  @override
  Future<PlaybackExtras?> fetchPlaybackExtrasFromCacheOnly(
    String itemId, {
    String? introPattern,
    String? creditsPattern,
    bool forceChapterFallback = false,
  }) async => null;

  @override
  Future<MediaSourceInfo?> fetchCachedMediaSourceInfo(
    String itemId, {
    int mediaIndex = 0,
    String? mediaSourceId,
    String? preferredVersionSignature,
  }) async => null;

  @override
  Future<ScrubPreviewSource?> createScrubPreviewSource({
    required MediaItem item,
    required MediaSourceInfo mediaSource,
  }) async => null;

  /// Silo decides completion itself when it applies progress and stop
  /// (administrator setting, 90 % by default).
  @override
  double get watchedThreshold => 0.9;

  @override
  bool get marksWatchedOnPlaybackStopped => true;

  // ----------------------------------------------------------- reporting

  @override
  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) => _reporter.progress(contentId: itemId, sessionId: playSessionId, playerPosition: position, isPaused: false);

  @override
  Future<void> reportPlaybackProgress({
    required String itemId,
    required Duration position,
    required Duration duration,
    bool isPaused = false,
    String? playSessionId,
    String? playMethod,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) => _reporter.progress(contentId: itemId, sessionId: playSessionId, playerPosition: position, isPaused: isPaused);

  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? liveStreamId,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    PlaybackReportMetadata report = const PlaybackReportMetadata.live(),
  }) => _reporter.stop(contentId: itemId, sessionId: playSessionId, playerPosition: position, duration: duration);

  // ----------------------------------------------------------- negotiation

  Map<String, dynamic>? _pickVersion(
    Map<String, dynamic> watch,
    PlaybackInitializationOptions? options, {
    List<MediaVersion>? available,
  }) {
    final versions = mapList(watch['versions']);
    if (versions.isEmpty) return null;
    Map<String, dynamic>? byId(String? id) =>
        id == null || id.isEmpty ? null : versions.where((v) => str(v['file_id']) == id).firstOrNull;
    if (options != null) {
      final explicit = byId(options.selectedMediaSourceId);
      if (explicit != null) return explicit;
      final signature = options.preferredVersionSignature;
      if (signature != null && available != null) {
        final index = MediaVersion.findMatchingIndex(available, {signature});
        if (index != null && index < versions.length) return versions[index];
      }
      if (options.selectedMediaIndex > 0 && options.selectedMediaIndex < versions.length) {
        return versions[options.selectedMediaIndex];
      }
    }
    return byId(strOrNull(asMap(watch['user_data'])['last_file_id'])) ?? versions.first;
  }

  Future<Map<String, dynamic>> _capabilities({bool force = false}) async {
    final cached = _playbackCapabilities;
    final at = _playbackCapabilitiesAt;
    if (!force && cached != null && at != null && DateTime.now().difference(at) < const Duration(minutes: 10)) {
      return cached;
    }
    final caps = await _api.playbackCapabilities();
    _playbackCapabilities = caps;
    _playbackCapabilitiesAt = DateTime.now();
    return caps;
  }

  @override
  Future<PlaybackInitializationResult> getPlaybackInitialization(PlaybackInitializationOptions options) async {
    final metadata = options.metadata;
    try {
      // The player keeps these headers for the whole title, so make sure
      // the access token outlives a long film.
      await _api.ensureFreshFor(const Duration(hours: 4));

      final watch = await _api.watchState(metadata.id);
      final versions = [
        for (final v in mapList(watch['versions'])) _versionFor(v),
      ];
      final version = _pickVersion(watch, options, available: versions);
      if (version == null) {
        throw PlaybackException('This title has no playable file on the server.', reason: PlaybackFailureReason.noPlayableSource);
      }
      final fileId = str(version['file_id']);
      final versionIndex = mapList(watch['versions']).indexWhere((v) => str(v['file_id']) == fileId);

      var caps = await _capabilities();
      if (str(caps['state']) != 'available' || caps['allowed'] == false) {
        throw PlaybackException(
          'Playback is not available on this Silo server right now.',
          reason: PlaybackFailureReason.serverUnavailable,
        );
      }

      // Audio: an explicit pick from the menu (ordinal-based ids), else the
      // carried track matched on this file, else the server's choice.
      final audioRows = siloAudioTracks(version);
      int? audioOrdinal = siloAudioOrdinalForTrackId(options.selectedAudioStreamId);
      if (audioOrdinal == null && options.preferredAudioTrack != null) {
        final carried = options.preferredAudioTrack!;
        final match = audioRows.where(
          (t) =>
              (t.language ?? '').toLowerCase() == (carried.language ?? '').toLowerCase() &&
              (carried.codec == null || (t.codec ?? '').toLowerCase() == carried.codec!.toLowerCase()),
        );
        audioOrdinal = match.firstOrNull?.index;
      }
      if (audioOrdinal != null && (audioOrdinal < 0 || audioOrdinal >= audioRows.length)) audioOrdinal = null;

      // Start where Plezy will start, so a packaged route is cut there.
      final startSeconds = options.startPosition == null ? 0.0 : options.startPosition!.inMilliseconds / 1000;

      Map<String, dynamic>? decision;
      String? attemptId;
      for (var round = 0; round < 2; round++) {
        attemptId = newSiloAttemptId();
        final snapshot = buildSiloCapabilitySnapshot(
          serverFeatures: strList(caps['features']).toSet(),
          appVersion: appVersion,
          platform: platform,
        );
        final body = buildSiloStartBody(
          installationId: str(caps['installation_id']),
          attemptId: attemptId,
          fileId: fileId,
          profileId: _connection.profileId,
          qualityPreference: siloQualityPreference(options.qualityPreset),
          snapshot: snapshot,
          startPosition: startSeconds,
          audioTrackId: audioOrdinal == null ? null : 'file:$fileId:audio:$audioOrdinal',
          audioTrackIndex: audioOrdinal,
        );
        try {
          decision = await _api.startPlayback(body);
          break;
        } on MediaServerHttpException catch (e) {
          // The server's playback installation changed: re-read capabilities
          // and start a new attempt (protocol §2.2).
          if (siloProblemIdOf(e) == 'installation_changed' && round == 0) {
            caps = await _capabilities(force: true);
            continue;
          }
          rethrow;
        }
      }
      if (decision == null || attemptId == null) {
        throw PlaybackException('The server kept changing its playback setup; try again.');
      }
      final plan = SiloPlan.fromDecision(
        decision,
        installationId: str(caps['installation_id']),
        attemptId: attemptId,
      );
      if (plan == null) throw siloTerminalDecision(decision);
      _reporter.register(plan, contentId: metadata.id);

      final selectedAudioOrdinal = intOrNull(plan.selectedAudio['index']) ?? audioOrdinal;
      final subtitles = siloSubtitles(plan, resolveUrl: _api.resolveServerUrl);
      final extras = _extrasFor(version);
      final videoTrack = mapList(version['video_tracks']).firstOrNull;
      final width = intOrNull(videoTrack?['width']);
      final height = intOrNull(videoTrack?['height']);
      final streamUrl = _api.resolveServerUrl(plan.streamUrl);
      if (!_api.isSameOrigin(streamUrl)) {
        // Auth headers are only ever sent to the server's own origin.
        throw PlaybackException(
          'The server returned a stream on another address, which this app does not support yet.',
          reason: PlaybackFailureReason.invalidPlaybackData,
        );
      }

      final mediaInfo = MediaSourceInfo(
        videoUrl: streamUrl,
        audioTracks: siloAudioTracks(version, selectedOrdinal: selectedAudioOrdinal),
        subtitleTracks: subtitles.tracks,
        chapters: extras.chapters,
        mediaSourceId: fileId,
        mediaIndex: versionIndex < 0 ? 0 : versionIndex,
        defaultAudioStreamIndex: selectedAudioOrdinal,
        videoAspectRatio: width != null && height != null && height > 0 ? width / height : null,
      );

      return PlaybackInitializationResult(
        availableVersions: versions,
        videoUrl: streamUrl,
        mediaInfo: mediaInfo,
        subtitleSidecars: subtitles.sidecars,
        isTranscoding: plan.isTranscode,
        fallbackReason: !options.qualityPreset.isOriginal && plan.isOriginal ? TranscodeFallbackReason.directPlayOnly : null,
        activeAudioStreamId: selectedAudioOrdinal == null ? null : selectedAudioOrdinal + 1,
        playSessionId: plan.sessionId,
        playMethod: plan.playMethod,
        selectedMediaIndex: versionIndex < 0 ? 0 : versionIndex,
      );
    } on PlaybackException {
      rethrow;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(classifyPlaybackFailure(error), stackTrace);
    }
  }

  MediaVersion _versionFor(Map<String, dynamic> v) {
    final item = _mappers.item({
      'content_id': 'v',
      'type': 'movie',
      'versions': [v],
    });
    return item!.mediaVersions!.first;
  }

  @override
  LiveTvSupport get liveTv => const _SiloNoLiveTv();

  @override
  Future<DownloadResolution> resolveDownload(MediaItem item, {int mediaIndex = 0, String? mediaSourceId}) async =>
      const DownloadResolution(videoUrl: null);

  @override
  Future<MediaItem> stampLibrary(MediaItem item) async => item;

  @override
  List<DownloadArtworkSpec> resolveDownloadArtwork(MediaItem item) => const [];

  /// External players cannot send the auth headers Silo media requires, and
  /// putting the bearer in a URL handed to another app would leak it.
  @override
  Future<ExternalPlaybackTarget?> resolveExternalPlayback(
    MediaItem item, {
    int mediaIndex = 0,
    String? mediaSourceId,
    Duration? position,
  }) async => null;
}

class _SiloNoLiveTv implements LiveTvSupport {
  const _SiloNoLiveTv();

  @override
  LiveTvDvrSupport? get dvr => null;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<List<LiveTvChannel>> fetchChannels({String? lineup}) async => const [];

  @override
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to}) async => const [];

  @override
  Future<LiveTvPlaybackSession?> startPlayback(
    String channelKey, {
    String? dvrKey,
    TranscodeQualityPreset quality = TranscodeQualityPreset.original,
  }) async => null;

  @override
  Future<String> buildFavoriteChannelSource({String? lineup}) async => '';

  @override
  String get favoriteStoreKey => 'silo';

  @override
  FavoriteChannelPersistenceMode get favoritePersistenceMode => FavoriteChannelPersistenceMode.serverSlice;

  @override
  Future<List<FavoriteChannel>> fetchFavoriteChannels({bool migrate = true, void Function()? checkCurrent}) async =>
      const [];

  @override
  Future<void> setFavoriteChannels(List<FavoriteChannel> channels, {void Function()? checkCurrent}) async {}
}
