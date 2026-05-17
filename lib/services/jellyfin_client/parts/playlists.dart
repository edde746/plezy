part of '../../jellyfin_client.dart';

mixin _JellyfinPlaylistMethods on MediaServerCacheMixin {
  JellyfinConnection get connection;
  MediaServerHttpClient get _http;
  String? _absolutizeImagePath(String? path);
  List<MediaItem> _mapItems(Iterable<Map<String, dynamic>> items);

  static const int _playlistsPageSize = 200;

  @override
  Future<List<MediaPlaylist>> fetchPlaylists({String playlistType = 'video', bool? smart}) async {
    final all = <MediaPlaylist>[];
    var start = 0;
    while (true) {
      final page = await fetchPlaylistsPage(
        playlistType: playlistType,
        smart: smart,
        start: start,
        size: _playlistsPageSize,
      );
      if (page.items.isEmpty) break;
      all.addAll(page.items);
      start += page.items.length;
      if (start >= page.totalCount) break;
    }
    return all;
  }

  @override
  Future<LibraryPage<MediaPlaylist>> fetchPlaylistsPage({
    String playlistType = 'video',
    bool? smart,
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    if (smart == true) {
      return LibraryPage<MediaPlaylist>(items: const [], totalCount: 0, offset: start ?? 0);
    }

    final offset = start ?? 0;
    final pageSize = size ?? _playlistsPageSize;
    final requestedType = playlistType.toLowerCase();
    final items = <MediaPlaylist>[];
    var rawOffset = 0;
    var filteredSeen = 0;
    int? rawTotal;
    var rawFinished = false;

    while (items.length < pageSize && !rawFinished) {
      final response = await _http.get(
        '/Items',
        queryParameters: {
          'userId': connection.userId,
          'IncludeItemTypes': 'Playlist',
          'Recursive': 'true',
          'StartIndex': rawOffset.toString(),
          'Limit': pageSize.toString(),
          'Fields': 'Overview,DateCreated,DateLastSaved,ChildCount,Tags',
          ...jellyfinImageQueryParameters,
        },
        abort: abort,
      );
      throwIfHttpError(response);
      final rawItems = _itemsArray(response.data);
      final rawTotalValue = response.data is Map<String, dynamic>
          ? (response.data as Map<String, dynamic>)['TotalRecordCount']
          : null;
      if (rawTotalValue is int) rawTotal = rawTotalValue;

      for (final item in rawItems.map(_playlistFromJson)) {
        if (!_matchesPlaylistFilters(item, requestedType: requestedType, smart: smart)) continue;
        if (filteredSeen >= offset && items.length < pageSize) {
          items.add(item);
        }
        filteredSeen++;
      }

      rawOffset += rawItems.length;
      rawFinished = rawItems.isEmpty || rawItems.length < pageSize || (rawTotal != null && rawOffset >= rawTotal);
    }

    final fallbackTotal = rawFinished
        ? filteredSeen
        : _fallbackPageTotal(offset: offset, itemCount: items.length, requestedSize: pageSize);
    return LibraryPage<MediaPlaylist>(items: items, totalCount: fallbackTotal, offset: offset);
  }

  @override
  Future<MediaPlaylist?> fetchPlaylistMetadata(String id) async {
    final item = await fetchItem(id);
    if (item == null) return null;
    return MediaPlaylist(
      id: item.id,
      backend: MediaBackend.jellyfin,
      title: item.title ?? 'Playlist',
      summary: item.summary,
      smart: false,
      playlistType: _playlistMediaType(item),
      durationMs: item.durationMs,
      leafCount: item.leafCount,
      thumbPath: item.thumbPath,
      addedAt: item.addedAt,
      updatedAt: item.updatedAt,
      serverId: serverId,
      serverName: serverName,
    );
  }

  @override
  Future<List<MediaItem>> fetchPlaylistItems(String id, {int offset = 0, int limit = 100}) async {
    final page = await fetchPlaylistPage(id, start: offset, size: limit);
    return page.items;
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPlaylistPage(String id, {int? start, int? size, AbortController? abort}) async {
    final offset = start ?? 0;
    final pageSize = size ?? 100;
    final response = await _http.get(
      '/Playlists/${_segment(id)}/Items',
      queryParameters: {
        'userId': connection.userId,
        'StartIndex': offset.toString(),
        'Limit': pageSize.toString(),
        'Fields': _browseFields,
        ...jellyfinImageQueryParameters,
      },
      abort: abort,
    );
    throwIfHttpError(response);
    final items = _itemsArray(response.data);
    final rawTotal = response.data is Map<String, dynamic>
        ? (response.data as Map<String, dynamic>)['TotalRecordCount']
        : null;
    final fallbackTotal = _fallbackPageTotal(offset: offset, itemCount: items.length, requestedSize: pageSize);
    return LibraryPage<MediaItem>(
      items: _mapItems(items),
      totalCount: rawTotal is int ? rawTotal : fallbackTotal,
      offset: offset,
    );
  }

  @override
  Future<MediaPlaylist?> createPlaylist({required String title, required List<MediaItem> items}) async {
    final response = await _http.post(
      '/Playlists',
      queryParameters: {
        'Name': title,
        'Ids': items.map((i) => i.id).join(','),
        'UserId': connection.userId,
        'MediaType': 'Video',
      },
    );
    throwIfHttpError(response);
    final data = response.data;
    final newId = data is Map<String, dynamic> ? data['Id'] as String? : null;
    if (newId == null || newId.isEmpty) return null;
    return fetchPlaylistMetadata(newId);
  }

  @override
  Future<bool> addToPlaylist({required String playlistId, required List<MediaItem> items}) async {
    if (items.isEmpty) return true;
    final response = await _http.post(
      '/Playlists/${_segment(playlistId)}/Items',
      queryParameters: {'Ids': items.map((i) => i.id).join(','), 'UserId': connection.userId},
    );
    throwIfHttpError(response);
    return true;
  }

  @override
  Future<bool> deletePlaylist(MediaPlaylist playlist) async {
    // Jellyfin treats playlists as items — same delete endpoint.
    final response = await _http.delete('/Items/${_segment(playlist.id)}');
    throwIfHttpError(response);
    return true;
  }

  /// Jellyfin's move endpoint takes an absolute index, so [afterItem] is
  /// ignored — its sibling Plex impl needs it for `?after=`. The "wrong
  /// backend" / "missing playlistItemId" branches still return `false`
  /// (business not-applicable, not a network error) so callers can revert
  /// optimistic UI changes; an HTTP error throws like the rest of the
  /// write surface.
  @override
  Future<bool> movePlaylistItem({
    required String playlistId,
    required MediaItem item,
    required int newIndex,
    required MediaItem? afterItem,
  }) async {
    if (item is! JellyfinMediaItem) {
      appLogger.e('movePlaylistItem: expected JellyfinMediaItem, got ${item.runtimeType} (id=${item.id})');
      return false;
    }
    if (item.playlistItemId == null) {
      appLogger.e('movePlaylistItem: item ${item.id} ("${item.title}") has no playlistItemId');
      return false;
    }
    final response = await _http.post(
      '/Playlists/${_segment(playlistId)}/Items/${_segment(item.playlistItemId!)}/Move/$newIndex',
    );
    throwIfHttpError(response);
    return true;
  }

  @override
  Future<bool> removeFromPlaylist({required String playlistId, required MediaItem item}) async {
    if (item is! JellyfinMediaItem) {
      appLogger.e('removeFromPlaylist: expected JellyfinMediaItem, got ${item.runtimeType} (id=${item.id})');
      return false;
    }
    if (item.playlistItemId == null) {
      appLogger.e('removeFromPlaylist: item ${item.id} ("${item.title}") has no playlistItemId');
      return false;
    }
    final response = await _http.delete(
      '/Playlists/${_segment(playlistId)}/Items',
      queryParameters: {'entryIds': item.playlistItemId},
    );
    throwIfHttpError(response);
    return true;
  }

  MediaPlaylist _playlistFromJson(Map<String, dynamic> json) {
    final id = json['Id'] as String? ?? '';
    return MediaPlaylist(
      id: id,
      backend: MediaBackend.jellyfin,
      title: json['Name'] as String? ?? 'Playlist',
      summary: json['Overview'] as String?,
      smart: false,
      playlistType: (json['MediaType'] as String?)?.toLowerCase() ?? 'video',
      leafCount: json['ChildCount'] as int?,
      addedAt: _epochSecondsFromJson(json['DateCreated'] as String?),
      updatedAt: _epochSecondsFromJson(json['DateLastSaved'] as String?),
      thumbPath: _absolutizeImagePath(_imageTagPath(id, json['ImageTags'])),
      serverId: serverId,
      serverName: serverName,
    );
  }

  String _playlistMediaType(MediaItem item) {
    if (item.kind == MediaKind.track || item.kind == MediaKind.album) return 'audio';
    if (item.kind == MediaKind.photo) return 'photo';
    return 'video';
  }

  bool _matchesPlaylistFilters(MediaPlaylist playlist, {required String requestedType, required bool? smart}) {
    if (requestedType.isNotEmpty && playlist.playlistType.toLowerCase() != requestedType) return false;
    if (smart != null && playlist.smart != smart) return false;
    return true;
  }

  int? _epochSecondsFromJson(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    return dt == null ? null : dt.millisecondsSinceEpoch ~/ 1000;
  }

  String? _imageTagPath(String id, Object? tags) {
    if (tags is! Map<String, dynamic>) return null;
    final tag = tags['Primary'];
    if (tag is! String) return null;
    return '/Items/${_segment(id)}/Images/Primary?tag=${Uri.encodeComponent(tag)}';
  }
}
