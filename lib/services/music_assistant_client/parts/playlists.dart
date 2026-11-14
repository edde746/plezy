part of '../../music_assistant_client.dart';

/// Playlist reads. Writes are refused — see `unsupported.dart`.
///
/// Layered on the browse methods so playlist tracks share their child-list memo
/// and page slicer: `playlist_tracks` returns the whole playlist and takes no
/// offset, which is the same shape (and the same per-page re-download hazard)
/// as album tracks and artist albums.
mixin _MusicAssistantPlaylistMethods on _MusicAssistantClientInternals, _MusicAssistantBrowseMethods {
  @override
  Future<LibraryPage<MediaPlaylist>> fetchPlaylistsPage({
    String playlistType = 'video',
    bool? smart,
    int? start,
    int? size,
    AbortController? abort,
  }) async {
    abort?.throwIfAborted();
    if (playlistType != 'audio') return const LibraryPage(items: [], totalCount: 0);
    final offset = start ?? 0;
    final limit = size ?? MusicAssistantLibrary.defaultPageSize;
    final rows = await guard(() => music.getPage(MaLibraryType.playlists, limit: limit, offset: offset));
    abort?.throwIfAborted();
    return LibraryPage(
      items: [
        for (final row in rows)
          ?MusicAssistantMappers.playlist(row, serverId: serverId, serverName: serverName, images: images),
      ],
      totalCount: await guard(() => music.getCount(MaLibraryType.playlists)),
      offset: offset,
    );
  }

  @override
  Future<MediaPlaylist?> fetchPlaylistMetadata(String id) async {
    final raw = await rawItem(id);
    if (raw == null) return null;
    return MusicAssistantMappers.playlist(raw, serverId: serverId, serverName: serverName, images: images);
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPlaylistPage(String id, {int? start, int? size, AbortController? abort}) async {
    abort?.throwIfAborted();
    final all = await _playlistTracks(id);
    abort?.throwIfAborted();
    return _MusicAssistantBrowseMethods.slicePage(all, start: start, size: size);
  }

  Future<List<MediaItem>> _playlistTracks(String id) async {
    final playlist = maRefFromUri(id) ?? await rawItem(id);
    if (playlist == null) return const [];
    return childList('playlist_tracks', playlist, () => music.getPlaylistTracks(playlist));
  }
}
