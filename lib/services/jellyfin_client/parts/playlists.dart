part of '../../jellyfin_client.dart';

mixin _JellyfinPlaylistMethods on _JellyfinClientInternals {
  static const int _playlistsPageSize = 200;

  @override
  Future<List<MediaPlaylist>> fetchPlaylists({String playlistType = 'video', bool? smart}) => drainPages<MediaPlaylist>(
    (start, size) => fetchPlaylistsPage(playlistType: playlistType, smart: smart, start: start, size: size),
    pageSize: _playlistsPageSize,
  );

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
    final mediaType = switch (requestedType) {
      '' => null,
      'video' => 'Video',
      'audio' => 'Audio',
      'photo' => 'Photo',
      'book' => 'Book',
      'unknown' => 'Unknown',
      _ => '',
    };
    if (mediaType == '') {
      return LibraryPage<MediaPlaylist>(items: const [], totalCount: 0, offset: offset);
    }

    final response = await _http.get(
      '/Items',
      queryParameters: {
        'userId': connection.userId,
        'IncludeItemTypes': 'Playlist',
        'Recursive': 'true',
        'MediaTypes': ?mediaType,
        'StartIndex': offset.toString(),
        'Limit': pageSize.toString(),
        'Fields': 'Overview,DateCreated,DateLastSaved,ChildCount,Tags',
        ...jellyfinImageQueryParameters,
      },
      abort: abort,
    );
    throwIfHttpError(response);
    return _pagedItems(
      response.data,
      offset: offset,
      requestedSize: pageSize,
      map: (raw) => raw.map(_playlistFromJson).toList(),
    );
  }

  @override
  Future<MediaPlaylist?> fetchPlaylistMetadata(String id) async {
    final item = await fetchItem(id);
    if (item == null) return null;
    return MediaPlaylist(
      id: item.id,
      backend: MediaBackend.jellyfin,
      title: item.title ?? t.playlists.playlist,
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
    return _pagedItems(response.data, offset: offset, requestedSize: pageSize, map: _mapItems);
  }

  @override
  Future<MediaPlaylist?> createPlaylist({required String title, required List<MediaItem> items}) async {
    // MediaType stamps the playlist's kind server-side; derive it from the
    // seed items so music selections create Audio playlists (which is what
    // fetchPlaylistsPage filters on). Empty seeds keep the Video default.
    final isMusic = items.isNotEmpty && items.first.kind.isMusic;
    final response = await _http.post(
      '/Playlists',
      queryParameters: {
        'Name': title,
        'Ids': items.map((i) => i.id).join(','),
        'UserId': connection.userId,
        'MediaType': isMusic ? 'Audio' : 'Video',
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
      appLogger.e('Jellyfin movePlaylistItem failed: missing playlist entry ID');
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
      appLogger.e('Jellyfin removeFromPlaylist failed: missing playlist entry ID');
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
      title: json['Name'] as String? ?? t.playlists.playlist,
      summary: json['Overview'] as String?,
      smart: false,
      playlistType: (json['MediaType'] as String?)?.toLowerCase() ?? 'video',
      leafCount: json['ChildCount'] as int?,
      addedAt: jellyfinIsoToEpochSeconds(json['DateCreated'] as String?),
      updatedAt: jellyfinIsoToEpochSeconds(json['DateLastSaved'] as String?),
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

  String? _imageTagPath(String id, Object? tags) {
    if (tags is! Map<String, dynamic>) return null;
    final tag = tags['Primary'];
    if (tag is! String) return null;
    return '/Items/${_segment(id)}/Images/Primary?tag=${Uri.encodeComponent(tag)}';
  }
}
