import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../focus/dpad_navigator.dart';
import '../../../../services/plex_client.dart';
import '../../../models/plex_metadata.dart';
import '../../../models/plex_filter.dart';
import '../../../models/plex_sort.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/error_message_utils.dart';
import '../../../utils/grid_size_calculator.dart';
import '../../../widgets/focusable_media_card.dart';
import '../../../widgets/focusable_filter_chip.dart';
import '../../../widgets/media_grid_delegate.dart';
import '../../../mixins/library_tab_focus_mixin.dart';
import '../folder_tree_view.dart';
import '../filters_bottom_sheet.dart';
import '../sort_bottom_sheet.dart';
import '../state_messages.dart';
import '../../../services/storage_service.dart';
import '../../../services/settings_service.dart' show ViewMode, EpisodePosterMode;
import '../../../mixins/grid_focus_node_mixin.dart';
import '../../../mixins/item_updatable.dart';
import '../../../i18n/strings.g.dart';
import '../../main_screen.dart';
import 'base_library_tab.dart';

/// Browse tab for library screen
/// Shows library items with grouping, filtering, and sorting
class LibraryBrowseTab extends BaseLibraryTab<PlexMetadata> {
  const LibraryBrowseTab({
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
  State<LibraryBrowseTab> createState() => _LibraryBrowseTabState();
}

class _LibraryBrowseTabState extends BaseLibraryTabState<PlexMetadata, LibraryBrowseTab>
    with ItemUpdatable, LibraryTabFocusMixin, GridFocusNodeMixin {
  @override
  PlexClient get client => getClientForLibrary();

  @override
  String get focusNodeDebugLabel => 'browse_first_item';

  @override
  int get itemCount => items.length;

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    setState(() {
      final index = items.indexWhere((item) => item.ratingKey == ratingKey);
      if (index != -1) {
        items[index] = updatedMetadata;
      }
    });
  }

  // Browse-specific state (not in base class)
  List<PlexFilter> _filters = [];
  List<PlexSort> _sortOptions = [];
  Map<String, String> _selectedFilters = {};
  PlexSort? _selectedSort;
  bool _isSortDescending = false;
  String _selectedGrouping = 'all'; // all, seasons, episodes, folders

  // Pagination state
  int _currentPage = 0;
  bool _hasMoreItems = true;
  CancelToken? _cancelToken;
  int _requestId = 0;
  static const int _pageSize = 500;

  // Focus nodes for filter chips
  final FocusNode _groupingChipFocusNode = FocusNode(debugLabel: 'grouping_chip');
  final FocusNode _filtersChipFocusNode = FocusNode(debugLabel: 'filters_chip');
  final FocusNode _sortChipFocusNode = FocusNode(debugLabel: 'sort_chip');

  // Scroll controller for the CustomScrollView
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _cancelToken?.cancel();
    _scrollController.dispose();
    _groupingChipFocusNode.dispose();
    _filtersChipFocusNode.dispose();
    _sortChipFocusNode.dispose();
    disposeGridFocusNodes();
    super.dispose();
  }

  // Override loadData to use our custom _loadContent
  @override
  Future<List<PlexMetadata>> loadData() async {
    // This is called by base class loadItems(), but we override loadItems() entirely
    // So this just returns empty - actual loading is done in _loadContent
    return [];
  }

  // Override loadItems to use our custom loading with pagination
  @override
  Future<void> loadItems() async {
    await _loadContent();
  }

  // Required abstract implementations from base class
  @override
  IconData get emptyIcon => Symbols.folder_open_rounded;

  @override
  String get emptyMessage => t.libraries.thisLibraryIsEmpty;

  @override
  String get errorContext => t.libraries.content;

  // Override buildContent - not used since we override build()
  @override
  Widget buildContent(List<PlexMetadata> items) => const SizedBox.shrink();

  /// Focus the first item in the grid/list (for tab activation)
  @override
  void focusFirstItem() {
    if (items.isNotEmpty) {
      // Request immediately, then once more on the next frame to handle cases
      // where the grid/list attaches after the initial focus attempt.
      void request() {
        if (mounted && items.isNotEmpty && !firstItemFocusNode.hasFocus) {
          firstItemFocusNode.requestFocus();
        }
      }

      request();
      WidgetsBinding.instance.addPostFrameCallback((_) => request());
    }
  }

  /// Height of the chips bar (padding + chip + padding)
  static const double _chipsBarHeight = 48.0;

  /// Focus the chips bar (for navigating from tab bar to content).
  /// Called by libraries screen when pressing DOWN on tab bar.
  void focusChipsBar() {
    // If in folders mode, no chips to focus - go directly to folder tree
    if (_selectedGrouping == 'folders') {
      focusFirstItem();
      return;
    }

    // With Stack layout, chips are always visible on top of the grid.
    // No need to scroll - just focus the chip.
    _groupingChipFocusNode.requestFocus();
  }

  Future<void> _loadContent() async {
    // Cancel any pending request
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final currentRequestId = ++_requestId;

    // Extract context dependencies before async gap - use server-specific client
    final client = getClientForLibrary();

    setState(() {
      isLoading = true;
      errorMessage = null;
      items = [];
      _currentPage = 0;
      _hasMoreItems = true;
      // Clear filter/sort state while loading to prevent showing stale options
      _filters = [];
      _sortOptions = [];
      _selectedFilters = {};
      _selectedSort = null;
      _isSortDescending = false;
      _selectedGrouping = _getDefaultGrouping();
    });

    try {
      final storage = await StorageService.getInstance();

      // Load filters and sorts for this library
      final filters = await client.getLibraryFilters(widget.library.key);
      final sorts = await client.getLibrarySorts(widget.library.key);

      // Load saved preferences
      final savedFilters = storage.getLibraryFilters(sectionId: widget.library.globalKey);
      final savedSort = storage.getLibrarySort(widget.library.globalKey);
      final savedGrouping = storage.getLibraryGrouping(widget.library.globalKey);

      // Check if request was cancelled
      if (currentRequestId != _requestId) return;

      setState(() {
        _filters = filters;
        _sortOptions = sorts;
        _selectedFilters = Map.from(savedFilters);
        _selectedGrouping = savedGrouping ?? _getDefaultGrouping();

        // Restore sort
        if (savedSort != null) {
          final sortKey = savedSort['key'] as String?;
          if (sortKey != null) {
            final sort = sorts.where((s) => s.key == sortKey).firstOrNull;
            if (sort != null) {
              _selectedSort = sort;
              _isSortDescending = (savedSort['descending'] as bool?) ?? false;
            }
          }
        }
      });

      // Load items
      await _loadItems();
    } catch (e) {
      _handleLoadError(e, currentRequestId);
    }
  }

  Future<void> _loadItems({bool loadMore = false}) async {
    if (loadMore && isLoading) return;

    if (!loadMore) {
      _currentPage = 0;
      _hasMoreItems = true;
    }

    if (!_hasMoreItems) return;

    final currentRequestId = _requestId;
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    setState(() {
      isLoading = true;
      if (!loadMore) {
        items = [];
        // Increment content version when loading fresh content
        // This invalidates the last focused index
        gridContentVersion++;
        cleanupGridFocusNodes(items.length);
      }
    });

    try {
      // Use server-specific client for this library
      final client = getClientForLibrary();

      // Build filter params
      final filterParams = Map<String, String>.from(_selectedFilters);

      // Add grouping type filter (but not for 'all' or 'folders')
      if (_selectedGrouping != 'all' && _selectedGrouping != 'folders') {
        final typeId = _getGroupingTypeId();
        if (typeId.isNotEmpty) {
          filterParams['type'] = typeId;
        }
      }

      // Add sort
      if (_selectedSort != null) {
        filterParams['sort'] = _selectedSort!.getSortKey(descending: _isSortDescending);
      }

      // Items are automatically tagged with server info by PlexClient
      final loadedItems = await client.getLibraryContent(
        widget.library.key,
        start: _currentPage * _pageSize,
        size: _pageSize,
        filters: filterParams,
        cancelToken: _cancelToken,
      );

      if (currentRequestId != _requestId) return;

      setState(() {
        if (loadMore) {
          items.addAll(loadedItems);
        } else {
          items = loadedItems;
        }
        _hasMoreItems = loadedItems.length >= _pageSize;
        _currentPage++;
        isLoading = false;
      });

      // On initial load (not pagination), mark data as loaded and try to focus
      if (!loadMore) {
        hasLoadedData = true;
        tryFocus();

        // Notify parent
        if (widget.onDataLoaded != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onDataLoaded!();
          });
        }
      }
    } catch (e) {
      _handleLoadError(e, currentRequestId);
    }
  }

  void _handleLoadError(dynamic error, int currentRequestId) {
    if (currentRequestId != _requestId) return;

    setState(() {
      errorMessage = _getErrorMessage(error);
      isLoading = false;
    });
  }

  String _getDefaultGrouping() {
    final type = widget.library.type.toLowerCase();
    if (type == 'show') {
      return 'shows';
    } else if (type == 'movie') {
      return 'movies';
    }
    return 'all';
  }

  String _getGroupingTypeId() {
    switch (_selectedGrouping) {
      case 'movies':
        return '1';
      case 'shows':
        return '2';
      case 'seasons':
        return '3';
      case 'episodes':
        return '4';
      default:
        return '';
    }
  }

  List<String> _getGroupingOptions() {
    final type = widget.library.type.toLowerCase();
    if (type == 'show') {
      return ['shows', 'seasons', 'episodes', 'folders'];
    } else if (type == 'movie') {
      return ['movies', 'folders'];
    }
    // All library types support folder browsing
    return ['all', 'folders'];
  }

  String _getGroupingLabel(String grouping) {
    switch (grouping) {
      case 'movies':
        return t.libraries.groupings.movies;
      case 'shows':
        return t.libraries.groupings.shows;
      case 'seasons':
        return t.libraries.groupings.seasons;
      case 'episodes':
        return t.libraries.groupings.episodes;
      case 'folders':
        return t.libraries.groupings.folders;
      default:
        return t.libraries.groupings.all;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      return mapDioErrorToMessage(error, context: t.libraries.content);
    }
    return mapUnexpectedErrorToMessage(error, context: t.libraries.content);
  }

  void _showGroupingBottomSheet() {
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    var pendingGrouping = _selectedGrouping;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final options = _getGroupingOptions();
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final grouping = options[index];
                return RadioListTile<String>(
                  title: Text(_getGroupingLabel(grouping)),
                  value: grouping,
                  groupValue: pendingGrouping,
                  onChanged: (value) {
                    if (value == null) return;
                    setSheetState(() {
                      pendingGrouping = value;
                    });
                  },
                );
              },
            );
          },
        );
      },
    ).then((_) {
      if (!mounted) return;
      if (pendingGrouping == _selectedGrouping) return;
      setState(() {
        _selectedGrouping = pendingGrouping;
      });
      StorageService.getInstance().then((storage) {
        storage.saveLibraryGrouping(widget.library.globalKey, pendingGrouping);
      });
      _loadItems();
    });
  }

  void _showFiltersBottomSheet() {
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FiltersBottomSheet(
        filters: _filters,
        selectedFilters: _selectedFilters,
        serverId: widget.library.serverId!,
        onFiltersChanged: (filters) async {
          setState(() {
            _selectedFilters.clear();
            _selectedFilters.addAll(filters);
          });

          // Save filters to storage
          final storage = await StorageService.getInstance();
          await storage.saveLibraryFilters(filters, sectionId: widget.library.globalKey);

          _loadItems();
        },
      ),
    );
  }

  void _showSortBottomSheet() {
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    // Track pending state in local variables so the callbacks don't trigger
    // setState/_loadItems while the sheet is open (which would steal focus).
    PlexSort? pendingSort = _selectedSort;
    bool pendingDescending = _isSortDescending;
    bool pendingCleared = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SortBottomSheet(
        sortOptions: _sortOptions,
        selectedSort: _selectedSort,
        isSortDescending: _isSortDescending,
        onSortChanged: (sort, descending) {
          pendingSort = sort;
          pendingDescending = descending;
          pendingCleared = false;
        },
        onClear: () {
          pendingSort = null;
          pendingDescending = false;
          pendingCleared = true;
        },
      ),
    ).then((_) {
      if (!mounted) return;
      if (pendingCleared) {
        setState(() {
          _selectedSort = null;
          _isSortDescending = false;
        });
        _loadItems();
      } else if (pendingSort != null &&
          (pendingSort!.key != _selectedSort?.key || pendingDescending != _isSortDescending)) {
        setState(() {
          _selectedSort = pendingSort;
          _isSortDescending = pendingDescending;
        });
        StorageService.getInstance().then((storage) {
          storage.saveLibrarySort(widget.library.globalKey, pendingSort!.key, descending: pendingDescending);
        });
        _loadItems();
      }
    });
  }

  /// Navigate focus from chips down to the grid item.
  /// Restores focus to the previously focused item if content hasn't changed.
  void _navigateToGrid() {
    if (items.isEmpty) return;

    final targetIndex = shouldRestoreGridFocus && lastFocusedGridIndex! < items.length ? lastFocusedGridIndex! : 0;

    // Use firstItemFocusNode for index 0 (matches _buildMediaCardItem)
    if (targetIndex == 0) {
      firstItemFocusNode.requestFocus();
    } else {
      getGridItemFocusNode(targetIndex, prefix: 'browse_grid_item').requestFocus();
    }
  }

  /// Navigate focus from grid up to the grouping chip
  void _navigateToChips() {
    _groupingChipFocusNode.requestFocus();
  }

  /// Navigate focus to the sidebar
  void _navigateToSidebar() {
    MainScreenFocusScope.of(context)?.focusSidebar();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // For folders mode, use FolderTreeView instead of grid/list
    if (_selectedGrouping == 'folders') {
      return Column(
        children: [
          _buildChipsBar(),
          Expanded(
            child: FolderTreeView(
              libraryKey: widget.library.key,
              serverId: widget.library.serverId,
              onRefresh: updateItem,
            ),
          ),
        ],
      );
    }

    // For list/grid modes, use Stack with chips layered on top of grid.
    // This allows the grid to use Clip.none for focus decorations while
    // the chips bar (with background) covers any overflow at the top.
    return Stack(
      children: [
        // Grid fills the entire area, with top padding for chips bar
        Positioned.fill(child: _buildScrollableContent()),
        // Chips bar on top with solid background
        Positioned(top: 0, left: 0, right: 0, child: _buildChipsBar()),
      ],
    );
  }

  /// Builds the scrollable content (grid/list) with pagination support
  Widget _buildScrollableContent() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 300 && _hasMoreItems && !isLoading) {
          _loadItems(loadMore: true);
        }
        return false;
      },
      child: CustomScrollView(
        controller: _scrollController,
        // Allow focus decoration to render outside scroll bounds
        clipBehavior: Clip.none,
        slivers: _buildContentSlivers(),
      ),
    );
  }

  /// Whether the filters chip is visible
  bool get _isFiltersChipVisible => _filters.isNotEmpty && _selectedGrouping != 'folders';

  /// Whether the sort chip is visible
  bool get _isSortChipVisible => _sortOptions.isNotEmpty && _selectedGrouping != 'folders';

  /// Builds the chips bar widget
  Widget _buildChipsBar() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grouping chip
          FocusableFilterChip(
            focusNode: _groupingChipFocusNode,
            icon: Symbols.category_rounded,
            label: _getGroupingLabel(_selectedGrouping),
            onPressed: _showGroupingBottomSheet,
            onNavigateDown: _navigateToGrid,
            onNavigateUp: widget.onBack,
            onNavigateLeft: _navigateToSidebar,
            onNavigateRight: _isFiltersChipVisible
                ? () => _filtersChipFocusNode.requestFocus()
                : _isSortChipVisible
                ? () => _sortChipFocusNode.requestFocus()
                : null,
            onBack: widget.onBack,
          ),
          const SizedBox(width: 8),
          // Filters chip
          if (_isFiltersChipVisible)
            FocusableFilterChip(
              focusNode: _filtersChipFocusNode,
              icon: Symbols.filter_alt_rounded,
              label: _selectedFilters.isEmpty
                  ? t.libraries.filters
                  : t.libraries.filtersWithCount(count: _selectedFilters.length),
              onPressed: _showFiltersBottomSheet,
              onNavigateDown: _navigateToGrid,
              onNavigateUp: widget.onBack,
              onNavigateLeft: () => _groupingChipFocusNode.requestFocus(),
              onNavigateRight: _isSortChipVisible ? () => _sortChipFocusNode.requestFocus() : null,
              onBack: widget.onBack,
            ),
          if (_isFiltersChipVisible) const SizedBox(width: 8),
          // Sort chip
          if (_isSortChipVisible)
            FocusableFilterChip(
              focusNode: _sortChipFocusNode,
              icon: Symbols.sort_rounded,
              label: _selectedSort?.title ?? t.libraries.sort,
              onPressed: _showSortBottomSheet,
              onNavigateDown: _navigateToGrid,
              onNavigateUp: widget.onBack,
              onNavigateLeft: _isFiltersChipVisible
                  ? () => _filtersChipFocusNode.requestFocus()
                  : () => _groupingChipFocusNode.requestFocus(),
              onBack: widget.onBack,
            ),
        ],
      ),
    );
  }

  /// Builds content as slivers for the CustomScrollView
  List<Widget> _buildContentSlivers() {
    if (isLoading && items.isEmpty) {
      return [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))];
    }

    if (errorMessage != null && items.isEmpty) {
      return [
        SliverFillRemaining(
          child: ErrorStateWidget(
            message: errorMessage!,
            icon: Symbols.error_outline_rounded,
            onRetry: _loadContent,
            retryLabel: t.common.retry,
          ),
        ),
      ];
    }

    if (items.isEmpty) {
      return [
        SliverFillRemaining(
          child: EmptyStateWidget(message: t.libraries.thisLibraryIsEmpty, icon: Symbols.folder_open_rounded),
        ),
      ];
    }

    return [
      Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return _buildItemsSliver(context, settingsProvider);
        },
      ),
    ];
  }

  // Top padding for grid content = chips bar height + extra space for focus decoration
  // Chips bar is ~48px, focus ring extends ~6px beyond item bounds
  static const double _gridTopPadding = _chipsBarHeight + 12.0;

  /// Builds either a sliver list or sliver grid based on the view mode
  Widget _buildItemsSliver(BuildContext context, SettingsProvider settingsProvider) {
    final itemCount = items.length + (_hasMoreItems && isLoading ? 1 : 0);

    if (settingsProvider.viewMode == ViewMode.list) {
      // In list view, all items are in a single column (first column)
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(8, _gridTopPadding, 8, 8),
        sliver: SliverList.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) => _buildMediaCardItem(
            index,
            isFirstRow: index == 0,
            isFirstColumn: true, // List view = single column
          ),
        ),
      );
    } else {
      // In grid view, calculate columns and pass to item builder
      // Use 16:9 aspect ratio when browsing episodes with episode thumbnail mode
      final useWideRatio =
          _selectedGrouping == 'episodes' && settingsProvider.episodePosterMode == EpisodePosterMode.episodeThumbnail;
      final maxExtent = GridSizeCalculator.getMaxCrossAxisExtent(context, settingsProvider.libraryDensity);
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(8, _gridTopPadding, 8, 8),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final columnCount = GridSizeCalculator.getColumnCount(constraints.crossAxisExtent, maxExtent);
            return SliverGrid.builder(
              gridDelegate: MediaGridDelegate.createDelegate(
                context: context,
                density: settingsProvider.libraryDensity,
                useWideAspectRatio: useWideRatio,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) => _buildMediaCardItem(
                index,
                isFirstRow: GridSizeCalculator.isFirstRow(index, columnCount),
                isFirstColumn: GridSizeCalculator.isFirstColumn(index, columnCount),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildMediaCardItem(int index, {required bool isFirstRow, required bool isFirstColumn}) {
    if (index >= items.length) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final item = items[index];

    // Use firstItemFocusNode for index 0 to maintain compatibility with base class
    // All other items get managed focus nodes for restoration
    final focusNode = index == 0 ? firstItemFocusNode : getGridItemFocusNode(index, prefix: 'browse_grid_item');

    return FocusableMediaCard(
      key: Key(item.ratingKey),
      item: item,
      focusNode: focusNode,
      onRefresh: updateItem,
      onNavigateUp: isFirstRow ? _navigateToChips : null,
      onNavigateLeft: isFirstColumn ? _navigateToSidebar : null,
      onBack: widget.onBack,
      onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
      onListRefresh: _loadItems,
    );
  }
}
