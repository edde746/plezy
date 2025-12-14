import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
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
import '../empty_state_widget.dart';
import '../error_state_widget.dart';
import '../../../services/storage_service.dart';
import '../../../services/settings_service.dart' show ViewMode;
import '../../../mixins/item_updatable.dart';
import '../../../i18n/strings.g.dart';
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

class _LibraryBrowseTabState
    extends BaseLibraryTabState<PlexMetadata, LibraryBrowseTab>
    with ItemUpdatable, LibraryTabFocusMixin {
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
  final FocusNode _groupingChipFocusNode = FocusNode(
    debugLabel: 'grouping_chip',
  );
  final FocusNode _filtersChipFocusNode = FocusNode(debugLabel: 'filters_chip');
  final FocusNode _sortChipFocusNode = FocusNode(debugLabel: 'sort_chip');

  @override
  void dispose() {
    _cancelToken?.cancel();
    _groupingChipFocusNode.dispose();
    _filtersChipFocusNode.dispose();
    _sortChipFocusNode.dispose();
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
      final savedFilters = storage.getLibraryFilters(
        sectionId: widget.library.globalKey,
      );
      final savedSort = storage.getLibrarySort(widget.library.globalKey);
      final savedGrouping = storage.getLibraryGrouping(
        widget.library.globalKey,
      );

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
        filterParams['sort'] = _selectedSort!.getSortKey(
          descending: _isSortDescending,
        );
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
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final options = _getGroupingOptions();
        return RadioGroup<String>(
          groupValue: _selectedGrouping,
          onChanged: (value) async {
            if (value == null) return;
            setState(() {
              _selectedGrouping = value;
            });

            final storage = await StorageService.getInstance();
            await storage.saveLibraryGrouping(
              widget.library.globalKey,
              value,
            );

            if (!sheetContext.mounted || !mounted) return;

            Navigator.pop(sheetContext);
            _loadItems();
          },
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final grouping = options[index];
              return RadioListTile<String>(
                title: Text(_getGroupingLabel(grouping)),
                value: grouping,
              );
            },
          ),
        );
      },
    );
  }

  void _showFiltersBottomSheet() {
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
          await storage.saveLibraryFilters(
            filters,
            sectionId: widget.library.globalKey,
          );

          _loadItems();
        },
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SortBottomSheet(
        sortOptions: _sortOptions,
        selectedSort: _selectedSort,
        isSortDescending: _isSortDescending,
        onSortChanged: (sort, descending) {
          setState(() {
            _selectedSort = sort;
            _isSortDescending = descending;
          });

          StorageService.getInstance().then((storage) {
            storage.saveLibrarySort(
              widget.library.globalKey,
              sort.key,
              descending: descending,
            );
          });

          _loadItems();
        },
      ),
    );
  }

  /// Navigate focus from chips down to the first grid item
  void _navigateToGrid() {
    if (items.isNotEmpty) {
      firstItemFocusNode.requestFocus();
    }
  }

  /// Navigate focus from grid up to the grouping chip
  void _navigateToChips() {
    _groupingChipFocusNode.requestFocus();
  }

  /// Calculate the number of columns in the current grid based on screen width
  int _getGridColumnCount(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    final screenWidth =
        MediaQuery.of(context).size.width - 16; // Subtract padding
    final maxCrossAxisExtent = GridSizeCalculator.getMaxCrossAxisExtent(
      context,
      settingsProvider.libraryDensity,
    );
    return (screenWidth / maxCrossAxisExtent).floor().clamp(1, 100);
  }

  /// Check if the given index is in the first row of the grid
  bool _isFirstRow(int index, int columnCount) {
    return index < columnCount;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Column(
      children: [
        // Filter bar with chips
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
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
                  onBack: widget.onBack,
                ),
                const SizedBox(width: 8),
                // Filters chip
                if (_filters.isNotEmpty && _selectedGrouping != 'folders')
                  FocusableFilterChip(
                    focusNode: _filtersChipFocusNode,
                    icon: Symbols.filter_alt_rounded,
                    label: _selectedFilters.isEmpty
                        ? t.libraries.filters
                        : t.libraries.filtersWithCount(
                            count: _selectedFilters.length,
                          ),
                    onPressed: _showFiltersBottomSheet,
                    onNavigateDown: _navigateToGrid,
                    onNavigateUp: widget.onBack,
                    onBack: widget.onBack,
                  ),
                if (_filters.isNotEmpty && _selectedGrouping != 'folders')
                  const SizedBox(width: 8),
                // Sort chip
                if (_sortOptions.isNotEmpty && _selectedGrouping != 'folders')
                  FocusableFilterChip(
                    focusNode: _sortChipFocusNode,
                    icon: Symbols.sort_rounded,
                    label: _selectedSort?.title ?? t.libraries.sort,
                    onPressed: _showSortBottomSheet,
                    onNavigateDown: _navigateToGrid,
                    onNavigateUp: widget.onBack,
                    onBack: widget.onBack,
                  ),
              ],
            ),
          ),
        ),

        // Content
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    // Show folder tree view when in folders mode
    if (_selectedGrouping == 'folders') {
      return FolderTreeView(
        libraryKey: widget.library.key,
        serverId: widget.library.serverId,
        onRefresh: updateItem,
      );
    }

    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && items.isEmpty) {
      return ErrorStateWidget(
        message: errorMessage!,
        icon: Symbols.error_outline_rounded,
        onRetry: _loadContent,
        retryLabel: t.common.retry,
      );
    }

    if (items.isEmpty) {
      return EmptyStateWidget(
        message: t.libraries.thisLibraryIsEmpty,
        icon: Symbols.folder_open_rounded,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 300 &&
            _hasMoreItems &&
            !isLoading) {
          _loadItems(loadMore: true);
        }
        return false;
      },
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return _buildItemsView(context, settingsProvider);
        },
      ),
    );
  }

  /// Builds either a list or grid view based on the view mode
  Widget _buildItemsView(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    final itemCount = items.length + (_hasMoreItems && isLoading ? 1 : 0);

    if (settingsProvider.viewMode == ViewMode.list) {
      // In list view, only the first item can navigate up to chips
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: itemCount,
        itemBuilder: (context, index) =>
            _buildMediaCardItem(index, isFirstRow: index == 0),
      );
    } else {
      // In grid view, calculate columns and pass to item builder
      final columnCount = _getGridColumnCount(context, settingsProvider);
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: MediaGridDelegate.createDelegate(
          context: context,
          density: settingsProvider.libraryDensity,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => _buildMediaCardItem(
          index,
          isFirstRow: _isFirstRow(index, columnCount),
        ),
      );
    }
  }

  Widget _buildMediaCardItem(int index, {required bool isFirstRow}) {
    if (index >= items.length) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final item = items[index];
    return FocusableMediaCard(
      key: Key(item.ratingKey),
      item: item,
      focusNode: index == 0 ? firstItemFocusNode : null,
      onRefresh: updateItem,
      onNavigateUp: isFirstRow ? _navigateToChips : null,
      onBack: widget.onBack,
    );
  }
}
