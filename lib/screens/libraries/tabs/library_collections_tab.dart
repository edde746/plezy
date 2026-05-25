import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../media/library_query.dart';
import '../../../media/media_item.dart';
import '../../../mixins/library_tab_focus_mixin.dart';
import '../../../mixins/paginated_item_loader.dart';
import '../../../services/settings_service.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/grid_size_calculator.dart';
import '../../../utils/layout_constants.dart';
import '../../../utils/library_refresh_notifier.dart';
import '../../../utils/media_server_http_client.dart';
import '../../../widgets/focusable_media_card.dart';
import '../../../widgets/media_grid_delegate.dart';
import '../../../widgets/settings_builder.dart';
import '../../../widgets/skeleton_media_card.dart';
import '../../../i18n/strings.g.dart';
import '../../main_screen.dart';
import 'base_library_tab.dart';

/// Collections tab for library screen.
/// Plex scopes collections to the library; Jellyfin exposes a shared BoxSets root.
class LibraryCollectionsTab extends BaseLibraryTab<MediaItem> {
  const LibraryCollectionsTab({
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
  State<LibraryCollectionsTab> createState() => _LibraryCollectionsTabState();
}

class _LibraryCollectionsTabState extends BaseLibraryTabState<MediaItem, LibraryCollectionsTab>
    with LibraryTabFocusMixin<LibraryCollectionsTab>, PaginatedItemLoader<MediaItem, LibraryCollectionsTab> {
  static const int _pageSize = 36;

  @override
  String get focusNodeDebugLabel => 'collections_first_item';

  @override
  int get itemCount => totalSize;

  @override
  IconData get emptyIcon => Symbols.collections_rounded;

  @override
  String get emptyMessage => t.libraries.noCollections;

  @override
  String get errorContext => t.collections.title;

  @override
  Stream<void>? getRefreshStream() => LibraryRefreshNotifier().collectionsStream;

  @override
  Future<List<MediaItem>> loadData() async => const [];

  @override
  Future<LibraryPage<MediaItem>> fetchPage(int start, int size, AbortController? abort) {
    final client = getMediaClientForLibrary();
    return client.fetchCollectionsPage(widget.library.id, start: start, size: size, abort: abort);
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
  Widget buildContent(List<MediaItem> items) {
    return SettingsBuilder(
      prefs: const [SettingsService.viewMode, SettingsService.libraryDensity],
      builder: (context) {
        final settings = SettingsService.instanceOrNull!;
        final viewMode = settings.read(SettingsService.viewMode);
        final density = settings.read(SettingsService.libraryDensity);
        return CustomScrollView(
          clipBehavior: Clip.none,
          slivers: [
            SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            if (viewMode == ViewMode.list) _buildListSliver(density) else _buildGridSliver(density),
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
        itemBuilder: (context, index) => _buildMediaCardItem(index, isFirstColumn: true, disableScale: true),
      ),
    );
  }

  Widget _buildGridSliver(int density) {
    return SliverPadding(
      padding: _effectivePadding,
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final maxCrossAxisExtent = GridSizeCalculator.getMaxCrossAxisExtent(context, density);
          final columnCount = GridSizeCalculator.getColumnCount(constraints.crossAxisExtent, maxCrossAxisExtent);
          return SliverGrid.builder(
            gridDelegate: MediaGridDelegate.createDelegate(context: context, density: density),
            itemCount: totalSize,
            itemBuilder: (context, index) =>
                _buildMediaCardItem(index, isFirstColumn: GridSizeCalculator.isFirstColumn(index, columnCount)),
          );
        },
      ),
    );
  }

  Widget _buildMediaCardItem(int index, {required bool isFirstColumn, bool disableScale = false}) {
    final item = loadedItems[index];
    if (item == null) {
      ensureIndexLoaded(index, pageSize: _pageSize);
      return const SkeletonMediaCard();
    }

    return FocusableMediaCard(
      key: Key(item.id),
      item: item,
      focusNode: index == 0 ? firstItemFocusNode : null,
      disableScale: disableScale,
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
