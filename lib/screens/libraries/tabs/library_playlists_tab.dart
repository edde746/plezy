import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/plex_playlist.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/library_refresh_notifier.dart';
import '../../../services/settings_service.dart' show ViewMode;
import '../../../utils/grid_size_calculator.dart';
import '../../../widgets/focusable_media_card.dart';
import '../../../i18n/strings.g.dart';
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
    extends BaseLibraryTabState<PlexPlaylist, LibraryPlaylistsTab> {
  // Focus node for the first item (for programmatic focus)
  final FocusNode _firstItemFocusNode = FocusNode(debugLabel: 'playlists_first_item');

  @override
  void dispose() {
    _firstItemFocusNode.dispose();
    super.dispose();
  }

  /// Focus the first item in the grid/list (for tab activation)
  @override
  void focusFirstItem() {
    if (items.isNotEmpty) {
      _firstItemFocusNode.requestFocus();
    }
  }

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
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        if (settingsProvider.viewMode == ViewMode.list) {
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _buildPlaylistItem(items[index], index),
          );
        } else {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: GridSizeCalculator.getMaxCrossAxisExtent(
                context,
                settingsProvider.libraryDensity,
              ),
              childAspectRatio: 2 / 3.3,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _buildPlaylistItem(items[index], index),
          );
        }
      },
    );
  }

  Widget _buildPlaylistItem(PlexPlaylist playlist, int index) {
    return FocusableMediaCard(
      key: Key(playlist.ratingKey),
      item: playlist,
      focusNode: index == 0 ? _firstItemFocusNode : null,
      onListRefresh: loadItems,
      onBack: widget.onBack,
    );
  }
}
