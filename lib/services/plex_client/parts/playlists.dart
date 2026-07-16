part of '../../plex_client.dart';

mixin _PlexPlaylistMethods on MediaServerCacheMixin {
  static const int _playlistPageSize = 200;
  static const int _defaultPlaylistContainerSize = 100;

  FailoverHttpClient get _http;
  @override
  ServerId get serverId;
  @override
  String? get serverName;

  Future<MediaServerResponse> _getWithFailover(
    String path, {
    Map<String, dynamic>? queryParameters,
    // ignore: unused_element_parameter
    Map<String, String>? headers,
    // ignore: unused_element_parameter
    Duration? timeout,
    AbortController? abort,
    // ignore: unused_element_parameter
    bool allowEndpointFailover = true,
  });

  Map<String, dynamic>? _getMediaContainer(MediaServerResponse response);
  Map<String, dynamic> _buildPaginationParams(int? start, int? size);

  Future<_LibraryContentResult> _fetchPaginatedList(String path, {int? start, int? size, AbortController? abort});

  ({List<PlexPlaylistDto> items, int totalSize}) _extractPlaylistListResult(
    MediaServerResponse response, {
    int? start,
    int? size,
  });

  Future<bool> _wrapBoolApiCall(Future<MediaServerResponse> Function() apiCall, String errorMessage);

  Future<String> buildMetadataUri(String ratingKey);

  Future<_LibraryContentResult> _getPlaylist(String playlistId, {int? start, int? size, AbortController? abort}) =>
      _fetchPaginatedList('/playlists/$playlistId/items', start: start, size: size, abort: abort);

  Future<List<PlexPlaylistDto>> _getPlaylists({String playlistType = 'video', bool? smart}) async {
    try {
      final all = <PlexPlaylistDto>[];
      var start = 0;
      while (true) {
        final page = await _getPlaylistsPage(
          playlistType: playlistType,
          smart: smart,
          start: start,
          size: _playlistPageSize,
        );
        if (page.items.isEmpty) break;
        all.addAll(page.items);
        start += page.items.length;
        if (start >= page.totalSize) break;
      }
      return all;
    } catch (e, st) {
      appLogger.e('Failed to get playlists', error: e, stackTrace: st);
      return [];
    }
  }

  Future<({List<PlexPlaylistDto> items, int totalSize})> _getPlaylistsPage({
    String playlistType = 'video',
    bool? smart,
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final pageSize = size ?? _defaultPlaylistContainerSize;
    final queryParams = <String, dynamic>{
      if (playlistType.isNotEmpty) 'playlistType': playlistType,
      ..._buildPaginationParams(start, pageSize),
    };
    if (smart != null) queryParams['smart'] = smart ? '1' : '0';

    final response = await _getWithFailover('/playlists', queryParameters: queryParams, abort: abort);
    return _extractPlaylistListResult(response, start: start, size: pageSize);
  }

  Future<PlexPlaylistDto?> _getPlaylistMetadata(String playlistId) async {
    try {
      final response = await _getWithFailover('/playlists/$playlistId');
      final container = _getMediaContainer(response);
      final metadata = container?['Metadata'];
      if (metadata is! List || metadata.isEmpty) return null;
      return PlexPlaylistDto.fromJson(metadata.first as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Failed to get playlist metadata: $e');
      return null;
    }
  }

  @override
  Future<List<MediaPlaylist>> fetchPlaylists({String playlistType = 'video', bool? smart}) async {
    final playlists = await _getPlaylists(playlistType: playlistType, smart: smart);
    return playlists.map(PlexMappers.mediaPlaylist).toList();
  }

  @override
  Future<LibraryPage<MediaPlaylist>> fetchPlaylistsPage({
    String playlistType = 'video',
    bool? smart,
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final result = await _getPlaylistsPage(
      playlistType: playlistType,
      smart: smart,
      start: start,
      size: size,
      abort: abort,
    );
    return LibraryPage<MediaPlaylist>(
      items: result.items.map(PlexMappers.mediaPlaylist).toList(),
      totalCount: result.totalSize,
      offset: start ?? 0,
    );
  }

  @override
  Future<MediaPlaylist?> fetchPlaylistMetadata(String id) async {
    final playlist = await _getPlaylistMetadata(id);
    return playlist == null ? null : PlexMappers.mediaPlaylist(playlist);
  }

  @override
  Future<List<MediaItem>> fetchPlaylistItems(String id, {int offset = 0, int limit = 100}) async {
    final page = await fetchPlaylistPage(id, start: offset, size: limit);
    return page.items;
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPlaylistPage(
    String playlistId, {
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    final result = await _getPlaylist(playlistId, start: start, size: size, abort: abort);
    return LibraryPage<MediaItem>(
      items: result.items.map(PlexMappers.mediaItem).toList(),
      totalCount: result.totalSize,
      offset: start ?? 0,
    );
  }

  @override
  Future<MediaPlaylist?> createPlaylist({required String title, required List<MediaItem> items}) async {
    if (items.isEmpty) return createPlaylistFromUri(title: title);
    final uri = await buildMetadataUri(items.map((item) => item.id).join(','));
    return createPlaylistFromUri(title: title, uri: uri, type: items.first.kind.isMusic ? 'audio' : 'video');
  }

  Future<MediaPlaylist?> createPlaylistFromUri({
    required String title,
    String? uri,
    int? playQueueId,
    String type = 'video',
  }) async {
    final queryParameters = <String, dynamic>{
      'type': type,
      'title': title,
      'smart': '0',
      'uri': ?uri,
      'playQueueID': ?playQueueId?.toString(),
    };
    final response = await _http.post('/playlists', queryParameters: queryParameters);
    throwIfHttpError(response);
    final metadata = _getMediaContainer(response)?['Metadata'];
    if (metadata is! List || metadata.isEmpty) return null;

    final dto = PlexPlaylistDto.fromJson(
      metadata.first as Map<String, dynamic>,
    ).copyWith(serverId: serverId, serverName: serverName);
    return PlexMappers.mediaPlaylist(dto);
  }

  @override
  Future<bool> deletePlaylist(MediaPlaylist playlist) {
    return _wrapBoolApiCall(() => _http.delete('/playlists/${playlist.id}'), 'Failed to delete playlist');
  }

  @override
  Future<bool> addToPlaylist({required String playlistId, required List<MediaItem> items}) async {
    if (items.isEmpty) return true;
    final uri = await buildMetadataUri(items.map((item) => item.id).join(','));
    return addItemsToPlaylistByUri(playlistId: playlistId, uri: uri);
  }

  Future<bool> addItemsToPlaylistByUri({required String playlistId, required String uri}) async {
    appLogger.d(
      'Adding to playlist $playlistId with URI: '
      '${uri.substring(0, uri.length > 100 ? 100 : uri.length)}'
      '${uri.length > 100 ? "..." : ""}',
    );
    final result = await _wrapBoolApiCall(
      () => _http.put('/playlists/$playlistId/items', queryParameters: {'uri': uri}),
      'Failed to add to playlist',
    );
    if (result) appLogger.d('Add to playlist response status: 200');
    return result;
  }

  @override
  Future<bool> removeFromPlaylist({required String playlistId, required MediaItem item}) {
    if (item is! PlexMediaItem || item.playlistItemId == null) {
      return Future.value(false);
    }
    return _wrapBoolApiCall(
      () => _http.delete('/playlists/$playlistId/items/${item.playlistItemId}'),
      'Failed to remove from playlist',
    );
  }

  @override
  Future<bool> movePlaylistItem({
    required String playlistId,
    required MediaItem item,
    required int newIndex,
    required MediaItem? afterItem,
  }) async {
    if (item is! PlexMediaItem || item.playlistItemId == null) return false;
    final int after;
    if (newIndex == 0) {
      after = 0;
    } else if (afterItem is PlexMediaItem && afterItem.playlistItemId != null) {
      after = afterItem.playlistItemId!;
    } else {
      return false;
    }
    appLogger.d(
      'Moving playlist item ${item.playlistItemId} after $after in playlist '
      '$playlistId',
    );
    return _wrapBoolApiCall(
      () => _http.put('/playlists/$playlistId/items/${item.playlistItemId}/move', queryParameters: {'after': after}),
      'Failed to move playlist item',
    );
  }
}
