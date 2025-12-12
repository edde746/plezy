import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../models/plex_playlist.dart';
import '../../../utils/library_refresh_notifier.dart';
import '../../../widgets/focusable_media_card.dart';
import '../../../i18n/strings.g.dart';
import 'base_library_tab.dart';
import 'library_grid_tab_state.dart';

/// Playlists tab for library screen
/// Shows playlists that contain items from the current library
class LibraryPlaylistsTab extends BaseLibraryTab<PlexPlaylist> {
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

class _LibraryPlaylistsTabState
    extends LibraryGridTabState<PlexPlaylist, LibraryPlaylistsTab> {
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
  Future<List<PlexPlaylist>> loadData() async {
    // Use server-specific client for this library
    final client = getClientForLibrary();

    // Playlists are automatically tagged with server info by PlexClient
    return await client.getLibraryPlaylists(
      sectionId: widget.library.key,
      playlistType: 'video',
    );
  }

  @override
  Widget buildGridItem(BuildContext context, PlexPlaylist playlist, int index) {
    return FocusableMediaCard(
      key: Key(playlist.ratingKey),
      item: playlist,
      focusNode: index == 0 ? firstItemFocusNode : null,
      onListRefresh: loadItems,
      onBack: widget.onBack,
    );
  }
}
