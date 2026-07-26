import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../media/library_query.dart';
import '../../../media/media_kind.dart';
import '../../../media/media_playlist.dart';
import '../../../utils/library_refresh_notifier.dart';
import '../../../utils/media_server_http_client.dart';
import '../../../i18n/strings.g.dart';
import 'base_library_tab.dart';
import 'paginated_card_grid_tab.dart';

/// Playlists tab for library screen
/// Shows playlists that contain items from the current library
class LibraryPlaylistsTab extends BaseLibraryTab<MediaPlaylist> {
  const LibraryPlaylistsTab({
    super.key,
    required super.library,
    super.viewMode,
    super.density,
    super.onDataLoaded,
    super.isActive,
    super.suppressAutoFocus,
    super.onBack,
  });

  @override
  State<LibraryPlaylistsTab> createState() => _LibraryPlaylistsTabState();
}

class _LibraryPlaylistsTabState extends PaginatedCardGridTabState<MediaPlaylist, LibraryPlaylistsTab> {
  @override
  int get pageSize => 200;

  @override
  String get focusNodeDebugLabel => 'playlists_first_item';

  @override
  IconData get emptyIcon => Symbols.playlist_play_rounded;

  @override
  String get emptyMessage => t.playlists.noPlaylists;

  @override
  String get errorContext => t.playlists.title;

  @override
  Stream<void>? getRefreshStream() => LibraryRefreshNotifier().playlistsStream;

  @override
  String idOf(MediaPlaylist playlist) => playlist.id;

  @override
  Future<LibraryPage<MediaPlaylist>> fetchPage(int start, int size, AbortController? abort) {
    // Both backends return playlists scoped to the server (not the library) —
    // neither Plex nor Jellyfin's API filters playlists by section. Music
    // libraries surface audio playlists; everything else keeps video.
    final client = getMediaClientForLibrary();
    final playlistType = widget.library.kind == MediaKind.artist ? 'audio' : 'video';
    return client.fetchPlaylistsPage(playlistType: playlistType, start: start, size: size, abort: abort);
  }

  @override
  bool get usesSquareCards => widget.library.kind.isMusic;
}
