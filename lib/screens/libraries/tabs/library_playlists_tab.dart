import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../focus/input_mode_tracker.dart';
import '../../../media/library_query.dart';
import '../../../media/media_kind.dart';
import '../../../media/media_playlist.dart';
import '../../../mixins/library_tab_focus_mixin.dart';
import '../../../mixins/paginated_item_loader.dart';
import '../../../services/settings_service.dart';
import '../../../utils/error_message_utils.dart';
import '../../../utils/layout_constants.dart';
import '../../../utils/library_refresh_notifier.dart';
import '../../../utils/media_server_http_client.dart';
import '../../../utils/platform_detector.dart';
import '../../../widgets/card_inflation_budget.dart';
import '../../../widgets/focusable_media_card.dart';
import '../../../widgets/media_card_sliver_layout.dart';
import '../../../widgets/settings_builder.dart';
import '../../../widgets/skeleton_media_card.dart';
import '../../../widgets/sliver_child_memo.dart';
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
    with
        LibraryTabFocusMixin<LibraryPlaylistsTab>,
        PaginatedItemLoader<MediaPlaylist, LibraryPlaylistsTab>,
        SkeletonUpgradeScheduler {
  static const int _pageSize = 200;

  /// Reuses card widgets across delegate swaps so tab-level setStates
  /// (pagination, refreshes) don't rebuild every realized card inside layout.
  final SliverChildMemo<MediaPlaylist> _cardMemo = SliverChildMemo<MediaPlaylist>();

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
    // neither Plex nor Jellyfin's API filters playlists by section. Music
    // libraries surface audio playlists; everything else keeps video.
    final client = getMediaClientForLibrary();
    final playlistType = widget.library.kind == MediaKind.artist ? 'audio' : 'video';
    return client.fetchPlaylistsPage(playlistType: playlistType, start: start, size: size, abort: abort);
  }

  @override
  Future<void> loadItems() async {
    String? loadErrorMessage;
    await loadInitialPaginatedItems(
      pageSize: _pageSize,
      resetViewState: () {
        isLoading = true;
        errorMessage = null;
        items = [];
      },
      applyLoadedItems: (loaded) {
        items = loaded;
        isLoading = false;
      },
      applyError: (error, stackTrace) {
        errorMessage = loadErrorMessage ?? t.errors.unableToLoad(context: errorContext);
        isLoading = false;
      },
      onLoaded: (_, _) {
        hasLoadedData = true;
        tryFocus();
        if (widget.onDataLoaded != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onDataLoaded!();
          });
        }
      },
      onError: (error, stackTrace) {
        loadErrorMessage = localizedLoadErrorMessage(error, stackTrace, context: errorContext);
      },
    );
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
            _buildItemsSliver(viewMode, density, fullCardLayout: fullCardLayout),
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

  Widget _buildItemsSliver(ViewMode viewMode, int density, {required bool fullCardLayout}) {
    return MediaCardSliverLayout(
      viewMode: viewMode,
      itemCount: totalSize,
      density: density,
      padding: _effectivePadding,
      fullBleedImage: fullCardLayout,
      listEpoch: (ViewMode.list, totalSize, density),
      gridEpochBuilder: (geometry) => (ViewMode.grid, geometry.columnCount, totalSize, fullCardLayout, density),
      itemBuilder: (context, position) {
        final index = position.index;
        final playlist = loadedItems[index];
        if (playlist == null) {
          ensureIndexLoaded(index, pageSize: _pageSize);
          return const SkeletonMediaCard();
        }
        if (!position.isGrid) {
          return _cardMemo.widgetFor(
            index,
            playlist,
            epoch: position.layoutEpoch!,
            build: () =>
                _buildPlaylistCard(index, isFirstRow: position.isFirstRow, isFirstColumn: true, disableScale: true),
          );
        }

        final cached = _cardMemo.tryGet(index, playlist, epoch: position.layoutEpoch!);
        if (cached != null) return cached;
        if (CardInflationBudget.isScrollingContext(context) &&
            !InputModeTracker.isKeyboardMode(context) &&
            !CardInflationBudget.tryTake()) {
          scheduleSkeletonUpgrade();
          return const SkeletonMediaCard();
        }
        return _cardMemo.widgetFor(
          index,
          playlist,
          epoch: position.layoutEpoch!,
          build: () => _buildPlaylistCard(
            index,
            isFirstRow: position.isFirstRow,
            isFirstColumn: position.isFirstColumn,
            fullBleedImage: fullCardLayout,
          ),
        );
      },
    );
  }

  Widget _buildPlaylistCard(
    int index, {
    required bool isFirstRow,
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
      onNavigateUp: isFirstRow ? widget.onBack : null,
      onBack: widget.onBack,
      onNavigateLeft: isFirstColumn ? _navigateToSidebar : null,
    );
  }

  void _navigateToSidebar() {
    MainScreenFocusScope.focusSidebarOf(context);
  }

  @override
  void dispose() {
    disposePagination();
    super.dispose();
  }
}
