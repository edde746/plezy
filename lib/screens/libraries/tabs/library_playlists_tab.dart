import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../media/library_query.dart';
import '../../../media/media_playlist.dart';
import '../../../mixins/library_tab_focus_mixin.dart';
import '../../../mixins/paginated_item_loader.dart';
import '../../../services/settings_service.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/grid_size_calculator.dart';
import '../../../utils/layout_constants.dart';
import '../../../utils/library_refresh_notifier.dart';
import '../../../utils/media_server_http_client.dart';
import '../../../utils/platform_detector.dart';
import '../../../widgets/focusable_media_card.dart';
import '../../../widgets/media_grid_delegate.dart';
import '../../../widgets/settings_builder.dart';
import '../../../widgets/skeleton_media_card.dart';
import '../../../widgets/sliver_cross_axis_layout_builder.dart';
import '../../../i18n/strings.g.dart';
import '../../main_screen.dart';
import 'base_library_tab.dart';

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

class _LibraryPlaylistsTabState extends BaseLibraryTabState<MediaPlaylist, LibraryPlaylistsTab>
    with LibraryTabFocusMixin<LibraryPlaylistsTab>, PaginatedItemLoader<MediaPlaylist, LibraryPlaylistsTab> {
  static const int _pageSize = 200;

  @override
  String get focusNodeDebugLabel => 'playlists_first_item';

  @override
  int get itemCount => totalSize;

  @override
  IconData get emptyIcon => Symbols.playlist_play_rounded;

  @override
  String get emptyMessage => t.playlists.noPlaylists;

  @override
  String get errorContext => t.playlists.title;

  @override
  Stream<void>? getRefreshStream() => LibraryRefreshNotifier().playlistsStream;

  @override
  Future<List<MediaPlaylist>> loadData() async => const [];

  @override
  Future<LibraryPage<MediaPlaylist>> fetchPage(int start, int size, AbortController? abort) {
    // Both backends return playlists scoped to the server (not the library) —
    // neither Plex nor Jellyfin's API filters playlists by section.
    final client = getMediaClientForLibrary();
    return client.fetchPlaylistsPage(playlistType: 'video', start: start, size: size, abort: abort);
  }

  @override
  Future<void> loadItems() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      items = [];
      resetPaginationState();
    });

    try {
      final initialPage = await loadInitialPageWithStatus(_pageSize);
      if (!initialPage.applied || !mounted) return;

      setState(() {
        items = loadedItems.values.toList();
        isLoading = false;
      });

      hasLoadedData = true;
      tryFocus();

      if (widget.onDataLoaded != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onDataLoaded!();
        });
      }
    } catch (e, st) {
      appLogger.e('Error loading $errorContext', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load $errorContext: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget buildContent(List<MediaPlaylist> items) {
    return SettingsBuilder(
      prefs: const [SettingsService.viewMode, SettingsService.libraryDensity, SettingsService.tvFullCardLayout],
      builder: (context) {
        final settings = SettingsService.instance;
        final viewMode = settings.read(SettingsService.viewMode);
        final density = settings.read(SettingsService.libraryDensity);
        final fullCardLayout = PlatformDetector.isTV() && settings.read(SettingsService.tvFullCardLayout);
        return CustomScrollView(
          clipBehavior: Clip.none,
          slivers: [
            SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            if (viewMode == ViewMode.list)
              _buildListSliver(density)
            else
              _buildGridSliver(density, fullCardLayout: fullCardLayout),
          ],
        );
      },
    );
  }

  static const double _focusDecorationPadding = 3.0;

  EdgeInsets get _effectivePadding {
    final base = GridLayoutConstants.gridPadding;
    return base.copyWith(top: base.top + _focusDecorationPadding);
  }

  Widget _buildListSliver(int density) {
    return SliverPadding(
      padding: _effectivePadding,
      sliver: SliverList.builder(
        itemCount: totalSize,
        itemBuilder: (context, index) => _buildPlaylistCard(index, isFirstColumn: true, disableScale: true),
      ),
    );
  }

  Widget _buildGridSliver(int density, {required bool fullCardLayout}) {
    return SliverPadding(
      padding: _effectivePadding,
      sliver: SliverCrossAxisLayoutBuilder(
        builder: (context, crossAxisExtent) {
          final geometry = MediaGridGeometry.resolve(
            context: context,
            crossAxisExtent: crossAxisExtent,
            density: density,
            fullBleedImage: fullCardLayout,
          );
          return SliverGrid.builder(
            gridDelegate: geometry.delegate,
            itemCount: totalSize,
            itemBuilder: (context, index) => _buildPlaylistCard(
              index,
              isFirstColumn: GridSizeCalculator.isFirstColumn(index, geometry.columnCount),
              fullBleedImage: fullCardLayout,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistCard(
    int index, {
    required bool isFirstColumn,
    bool disableScale = false,
    bool fullBleedImage = false,
  }) {
    final playlist = loadedItems[index];
    if (playlist == null) {
      ensureIndexLoaded(index, pageSize: _pageSize);
      return const SkeletonMediaCard();
    }

    return FocusableMediaCard(
      key: Key(playlist.id),
      item: playlist,
      focusNode: index == 0 ? firstItemFocusNode : null,
      disableScale: disableScale,
      fullBleedImage: fullBleedImage,
      onListRefresh: loadItems,
      onBack: widget.onBack,
      onNavigateLeft: isFirstColumn ? _navigateToSidebar : null,
    );
  }

  void _navigateToSidebar() {
    MainScreenFocusScope.of(context, listen: false)?.focusSidebar();
  }

  @override
  void dispose() {
    disposePagination();
    super.dispose();
  }
}
