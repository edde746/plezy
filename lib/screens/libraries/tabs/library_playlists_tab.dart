import 'package:flutter/material.dart';
import '../../../models/plex_playlist.dart';
import '../../../utils/library_refresh_notifier.dart';
import '../../../mixins/library_tab_focus_mixin.dart';
import '../../../widgets/focusable_media_card.dart';
import '../../../i18n/strings.g.dart';
import '../adaptive_media_grid.dart';
import 'base_library_tab.dart';

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
    extends BaseLibraryTabState<PlexPlaylist, LibraryPlaylistsTab>
    with LibraryTabFocusMixin {
  @override
  String get focusNodeDebugLabel => 'playlists_first_item';

  @override
  int get itemCount => items.length;

  @override
  IconData get emptyIcon => Icons.playlist_play;

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
  Widget buildContent(List<PlexPlaylist> items) {
    return AdaptiveMediaGrid<PlexPlaylist>(
      items: items,
      itemBuilder: (context, playlist, index) {
        return FocusableMediaCard(
          key: Key(playlist.ratingKey),
          item: playlist,
          focusNode: index == 0 ? firstItemFocusNode : null,
          onListRefresh: loadItems,
          onBack: widget.onBack,
        );
      },
      onRefresh: loadItems,
      firstItemFocusNode: firstItemFocusNode,
      onBack: widget.onBack,
    );
  }
}
