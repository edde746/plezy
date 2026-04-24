import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../utils/plex_http_client.dart';
import '../../../utils/plex_http_exception.dart';
import '../../../focus/dpad_navigator.dart';
import '../../../focus/input_mode_tracker.dart';
import '../../../../services/plex_client.dart';
import '../../../models/plex_metadata.dart';
import '../../../models/plex_filter.dart';
import '../../../models/plex_first_character.dart';
import '../../../models/plex_sort.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/image_cache_service.dart';
import '../../../utils/error_message_utils.dart';
import '../../../utils/grid_size_calculator.dart';
import '../../../utils/layout_constants.dart';
import '../../../utils/plex_image_helper.dart';
import '../alpha_jump_bar.dart';
import '../alpha_jump_helper.dart';
import '../alpha_scroll_handle.dart';
import '../../../widgets/focusable_media_card.dart';
import '../../../widgets/focusable_filter_chip.dart';
import '../../../widgets/media_grid_delegate.dart';
import '../../../widgets/overlay_sheet.dart';
import '../../../mixins/library_tab_focus_mixin.dart';
import '../folder_tree_view.dart';
import '../filters_bottom_sheet.dart';
import '../sort_bottom_sheet.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../state_messages.dart';
import '../../../services/storage_service.dart';
import '../../../services/settings_service.dart' show ViewMode, EpisodePosterMode;
import '../../../mixins/grid_focus_node_mixin.dart';
import '../../../mixins/item_updatable.dart';
import '../../../mixins/deletion_aware.dart';
import '../../../mixins/paginated_item_loader.dart';
import '../../../widgets/skeleton_media_card.dart';
import '../../../utils/deletion_notifier.dart';
import '../../../utils/global_key_utils.dart';
import '../../../utils/platform_detector.dart';
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
    with ItemUpdatable, LibraryTabFocusMixin, GridFocusNodeMixin, DeletionAware, PaginatedItemLoader<LibraryBrowseTab> {
  @override
  PlexClient get client => getClientForLibrary();

  String _toGlobalKey(String ratingKey, {String? serverId}) =>
      buildGlobalKey(serverId ?? widget.library.serverId ?? '', ratingKey);

  @override
  String? get deletionServerId => widget.library.serverId;

  @override
  Set<String>? get deletionRatingKeys => loadedItems.values.map((e) => e.ratingKey).toSet();

  @override
  Set<String>? get deletionGlobalKeys {
    if (loadedItems.isEmpty) return <String>{};

    final keys = <String>{};
    for (final item in loadedItems.values) {
      final serverId = item.serverId ?? widget.library.serverId;
      if (serverId == null) return null;
      keys.add(_toGlobalKey(item.ratingKey, serverId: serverId));
    }
    return keys;
  }

  @override
  void onDeletionEvent(DeletionEvent event) {
    // If we have an item that matches the rating key exactly, remove it and rebuild indices
    final matchEntry = loadedItems.entries.where((e) => e.value.ratingKey == event.ratingKey).firstOrNull;
    if (matchEntry != null) {
      setState(() {
        removeLoadedItemAndShift(matchEntry.key);
      });
      return;
    }

    // If a child item was deleted, update our item to reflect that.
    // If all children were deleted, remove our item.
    // Otherwise, just update the counts.
    for (final parentKey in event.parentChain) {
      final parentEntry = loadedItems.entries.where((e) => e.value.ratingKey == parentKey).firstOrNull;
      if (parentEntry != null) {
        final item = parentEntry.value;
        final newLeafCount = (item.leafCount ?? 1) - event.leafCount;
        if (newLeafCount <= 0) {
          setState(() {
            removeLoadedItemAndShift(parentEntry.key);
          });
        } else {
          setState(() {
            loadedItems[parentEntry.key] = item.copyWith(leafCount: newLeafCount);
          });
        }
        return;
      }
    }

    // If neither the item nor its parents are loaded (evicted), the event
    // was already filtered by DeletionAware's upstream check against
    // deletionGlobalKeys/deletionRatingKeys, so this point is unreachable.
    // The grid self-corrects when the next page fetch updates totalSize from
    // the server response on the next scroll.
  }

  @override
  String get focusNodeDebugLabel => 'browse_first_item';

  @override
  int get itemCount => totalSize;

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    setState(() {
      for (final entry in loadedItems.entries) {
        if (entry.value.ratingKey == ratingKey) {
          loadedItems[entry.key] = updatedMetadata;
          break;
        }
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

  // Alpha jump bar state
  List<PlexFirstCharacter> _firstCharacters = [];
  AlphaJumpHelper _alphaHelper = AlphaJumpHelper(const []);
  final ValueNotifier<int> _currentFirstVisibleIndex = ValueNotifier<int>(0);
  int _currentColumnCount = 1;
  double _lastCrossAxisExtent = 0;
  double _effectiveTopPadding = _gridTopPadding;
  final FocusNode _alphaJumpBarFocusNode = FocusNode(debugLabel: 'alpha_jump_bar');
  // When the user taps a letter, pin the highlight so scroll-based recalculation
  // doesn't immediately override it (e.g. when the letter has fewer items than a full row).
  bool _hasJumpPin = false;
  // True while a jump-triggered animateTo is in progress — suppresses all
  // scroll-based letter recalculation to prevent flashing.
  bool _isJumpScrolling = false;
  // Incremented on each jump so that overlapping animations don't clobber each other.
  int _jumpScrollGeneration = 0;

  // Scroll activity tracking (for phone scroll handle and range-load gating)
  final ValueNotifier<bool> _isScrollActive = ValueNotifier<bool>(false);
  Timer? _scrollActivityTimer;

  // Alpha bar update: throttle (leading edge) + trailing timer (ensures final position)
  DateTime? _lastAlphaUpdate;
  Timer? _alphaUpdateTimer;

  /// Generation counter for the filter/sort loading phase of [_loadContent].
  /// Separate from the mixin's pagination generation so a filter reload can
  /// invalidate in-flight filter/sort fetches without touching item pagination.
  int _contentRequestId = 0;
  int _firstCharactersRequestId = 0;
  static const int _fetchSize = 200;
  Timer? _scrollIdleTimer;
  bool _rangeLoadScheduled = false;

  // Focus nodes for filter chips
  final FocusNode _groupingChipFocusNode = FocusNode(debugLabel: 'grouping_chip');
  final FocusNode _filtersChipFocusNode = FocusNode(debugLabel: 'filters_chip');
  final FocusNode _sortChipFocusNode = FocusNode(debugLabel: 'sort_chip');

  // Scroll controller for the CustomScrollView
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    disposePagination();
    _scrollActivityTimer?.cancel();
    _scrollIdleTimer?.cancel();
    _alphaUpdateTimer?.cancel();
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    _groupingChipFocusNode.dispose();
    _filtersChipFocusNode.dispose();
    _sortChipFocusNode.dispose();
    _alphaJumpBarFocusNode.dispose();
    _currentFirstVisibleIndex.dispose();
    _isScrollActive.dispose();
    disposeGridFocusNodes();
    super.dispose();
  }

  // Override tryFocus to use loadedItems instead of base class items list
  @override
  void tryFocus() {
    if (widget.suppressAutoFocus) return;
    // On mobile (touch mode), skip auto-focus to prevent ensureVisible()
    // from interfering with TabBarView page animations
    if (!InputModeTracker.isKeyboardMode(context)) return;
    if (widget.isActive && hasLoadedData && !hasFocused && loadedItems.isNotEmpty) {
      hasFocused = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) focusFirstItem();
      });
    }
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

  /// Focus the first item in the grid/list/folder tree (for tab activation)
  @override
  void focusFirstItem() {
    // In folder mode, items list is empty — focus the first folder tree item directly
    if (_selectedGrouping == 'folders') {
      void request() {
        if (mounted && !firstItemFocusNode.hasFocus) {
          firstItemFocusNode.requestFocus();
        }
      }

      request();
      WidgetsBinding.instance.addPostFrameCallback((_) => request());
      return;
    }

    if (loadedItems.isNotEmpty) {
      // Request immediately, then once more on the next frame to handle cases
      // where the grid/list attaches after the initial focus attempt.
      void request() {
        if (mounted && loadedItems.isNotEmpty && !firstItemFocusNode.hasFocus) {
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
    _groupingChipFocusNode.requestFocus();
  }

  /// Reset transient browse state before loading a different library.
  void _resetForFullReload() {
    _scrollActivityTimer?.cancel();
    _scrollIdleTimer?.cancel();
    _isScrollActive.value = false;
    _hasJumpPin = false;
    _isJumpScrolling = false;
    _jumpScrollGeneration++;
    _currentFirstVisibleIndex.value = 0;

    // The browse tab state is kept alive across libraries, so ensure each
    // library starts from top instead of inheriting the previous offset.
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  Future<void> _loadContent() async {
    final generation = ++_contentRequestId;
    final firstCharactersGeneration = ++_firstCharactersRequestId;

    _resetForFullReload();

    // Extract context dependencies before async gap - use server-specific client
    final client = getClientForLibrary();

    setState(() {
      isLoading = true;
      errorMessage = null;
      items = [];
      resetPaginationState();
      // Clear filter/sort state while loading to prevent showing stale options
      _filters = [];
      _sortOptions = [];
      _selectedFilters = {};
      _selectedSort = null;
      _isSortDescending = false;
      _selectedGrouping = _getDefaultGrouping();
      _firstCharacters = [];
      _alphaHelper = AlphaJumpHelper(const []);
    });
    _currentFirstVisibleIndex.value = 0;

    try {
      final storage = await StorageService.getInstance();

      // Load filters and sorts for this library
      final filters = await client.getLibraryFilters(widget.library.key);
      final sorts = await client.getLibrarySorts(widget.library.key);

      // Load saved preferences
      final savedFilters = storage.getLibraryFilters(sectionId: widget.library.globalKey);
      final savedSort = storage.getLibrarySort(widget.library.globalKey);
      final savedGrouping = storage.getLibraryGrouping(widget.library.globalKey);

      // Check if request was superseded
      if (generation != _contentRequestId) return;

      if (!mounted) return;
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

      // Load items and first characters in parallel
      // _loadItems manages its own requestId internally
      await Future.wait([_loadItems(), _loadFirstCharacters(requestId: firstCharactersGeneration)]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = _getErrorMessage(e);
        isLoading = false;
      });
    }
  }

  /// Build the filter params map for API calls
  Map<String, String> _buildFilterParams() {
    final filterParams = Map<String, String>.from(_selectedFilters);

    // Add grouping type filter (but not for 'all' or 'folders')
    if (_selectedGrouping != 'all' && _selectedGrouping != 'folders') {
      final typeId = _getGroupingTypeId();
      if (typeId.isNotEmpty) {
        filterParams['type'] = typeId;
      }
    } else if (_selectedGrouping == 'all' && widget.library.isShared) {
      // Shared libraries: filter to video content only (exclude library section entries)
      filterParams['type'] = '1,2,3,4';
    }

    // Add sort
    if (_selectedSort != null) {
      filterParams['sort'] = _selectedSort!.getSortKey(descending: _isSortDescending);
    }

    filterParams['includeCollections'] = '1';

    return filterParams;
  }

  Future<void> _loadItems() async {
    final generation = _contentRequestId;
    setState(() {
      isLoading = true;
      items = [];
      resetPaginationState();
      // Increment content version when loading fresh content
      // This invalidates the last focused index
      gridContentVersion++;
      cleanupGridFocusNodes(0);
    });

    try {
      await loadInitialPage(_calculateInitialFetchSize());

      if (generation != _contentRequestId || !mounted) return;
      setState(() {
        isLoading = false;
      });

      hasLoadedData = true;
      tryFocus();

      // Notify parent
      if (widget.onDataLoaded != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onDataLoaded!();
        });
      }
    } catch (e) {
      if (generation != _contentRequestId || !mounted) return;
      setState(() {
        errorMessage = _getErrorMessage(e);
        isLoading = false;
      });
    }
  }

  @override
  Future<LibraryContentResult> fetchPage(int start, int size, AbortController? abort) {
    return getClientForLibrary().getLibraryContent(
      widget.library.key,
      start: start,
      size: size,
      filters: _buildFilterParams(),
      abort: abort,
    );
  }

  @override
  void onPageLoaded(int start, List<PlexMetadata> pageItems) {
    _prefetchImages(start, pageItems);
  }

  String _getDefaultGrouping() {
    final type = widget.library.type.toLowerCase();
    if (type == 'show') return 'shows';
    if (type == 'movie') return 'movies';
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
    } else if (type == 'mixed') {
      // Shared libraries: all video content types, no folders
      return ['all', 'movies', 'shows', 'seasons', 'episodes'];
    }
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
    if (error is PlexHttpException) {
      return mapHttpErrorToMessage(error, context: t.libraries.content);
    }
    return mapUnexpectedErrorToMessage(error, context: t.libraries.content);
  }

  void _showGroupingBottomSheet() {
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    final options = _getGroupingOptions();
    final controller = OverlaySheetController.of(context);
    controller
        .show<String>(
          showDragHandle: true,
          builder: (sheetContext) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  t.libraries.groupings.title,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map((grouping) {
                      final isSelected = _selectedGrouping == grouping;
                      return FocusableListTile(
                        dense: true,
                        leading: AppIcon(
                          isSelected ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
                          fill: 1,
                        ),
                        title: Text(_getGroupingLabel(grouping)),
                        onTap: () => controller.close(grouping),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        )
        .then((value) {
          if (!mounted || value == null || value == _selectedGrouping) return;
          setState(() {
            _selectedGrouping = value;
          });
          StorageService.getInstance().then((storage) {
            storage.saveLibraryGrouping(widget.library.globalKey, value);
          });
          _loadItems();
          _loadFirstCharacters();
        });
  }

  void _showFiltersBottomSheet() {
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    OverlaySheetController.of(context).show(
      builder: (context) => FiltersBottomSheet(
        filters: _filters,
        selectedFilters: _selectedFilters,
        serverId: widget.library.serverId!,
        libraryKey: widget.library.globalKey,
        onFiltersChanged: (filters) async {
          setState(() {
            _selectedFilters.clear();
            _selectedFilters.addAll(filters);
          });

          // Save filters to storage
          final storage = await StorageService.getInstance();
          await storage.saveLibraryFilters(filters, sectionId: widget.library.globalKey);

          _loadItems();
          _loadFirstCharacters();
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
    OverlaySheetController.of(context)
        .show(
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
        )
        .then((_) {
          if (!mounted) return;
          if (pendingCleared) {
            setState(() {
              _selectedSort = null;
              _isSortDescending = false;
            });
            _loadItems();
            _loadFirstCharacters();
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
            _loadFirstCharacters();
          }
        });
  }

  /// Navigate focus from chips down to the grid item.
  /// Restores focus to the previously focused item if content hasn't changed.
  void _navigateToGrid() {
    // In folder mode, firstItemFocusNode is attached to the first folder tree item
    if (_selectedGrouping == 'folders') {
      firstItemFocusNode.requestFocus();
      return;
    }

    if (totalSize == 0) return;

    final targetIndex =
        shouldRestoreGridFocus && lastFocusedGridIndex! < totalSize && loadedItems.containsKey(lastFocusedGridIndex!)
        ? lastFocusedGridIndex!
        : 0;

    // Use firstItemFocusNode for index 0 (matches _buildMediaCardItem)
    if (targetIndex == 0) {
      firstItemFocusNode.requestFocus();
    } else {
      getGridItemFocusNode(targetIndex, prefix: 'browse_grid_item').requestFocus();
    }
  }

  /// Navigate from the alpha jump bar to the nearest visible grid item.
  /// After a jump-scroll the previously focused item is off-screen (and its
  /// FocusNode detached), so we target the last-column item in the first
  /// visible row — the grid cell closest to the alpha bar.
  void _navigateToGridNearScroll() {
    if (totalSize == 0 || _currentColumnCount < 1) return;

    final row = _currentFirstVisibleIndex.value ~/ _currentColumnCount;
    var targetIndex = ((row + 1) * _currentColumnCount - 1).clamp(0, totalSize - 1);

    // Find nearest loaded item — skeleton cards have no FocusNode
    if (!loadedItems.containsKey(targetIndex)) {
      // Search backwards first (items above are more likely visible)
      int? found;
      for (var i = targetIndex - 1; i >= 0; i--) {
        if (loadedItems.containsKey(i)) {
          found = i;
          break;
        }
      }
      // Then search forwards
      if (found == null) {
        for (var i = targetIndex + 1; i < totalSize; i++) {
          if (loadedItems.containsKey(i)) {
            found = i;
            break;
          }
        }
      }
      if (found == null) return;
      targetIndex = found;
    }

    if (targetIndex == 0) {
      firstItemFocusNode.requestFocus();
    } else {
      getGridItemFocusNode(targetIndex, prefix: 'browse_grid_item').requestFocus();
    }
  }

  /// Navigate focus from grid up to the chips bar
  void _navigateToChips() {
    _groupingChipFocusNode.requestFocus();
  }

  /// Navigate focus to the sidebar
  void _navigateToSidebar() {
    MainScreenFocusScope.of(context)?.focusSidebar();
  }

  /// Navigate focus to the alpha jump bar
  void _navigateToAlphaJumpBar() {
    _alphaJumpBarFocusNode.requestFocus();
  }

  /// Whether the device is a phone (not tablet/desktop/TV).
  bool _isPhone(BuildContext context) => PlatformDetector.isPhone(context);

  /// The letter currently visible at the top of the grid, determined by
  /// how many items we've scrolled past relative to the API's cumulative
  /// firstCharacter counts.
  String _alphaLetterFor(int index) => _alphaHelper.currentLetter(index);

  /// Whether the alpha jump bar should be shown.
  /// Only shown when sorting by title (titleSort) and not in folders mode.
  bool get _shouldShowAlphaJumpBar {
    if (_selectedGrouping == 'folders') return false;
    if (_firstCharacters.isEmpty) return false;
    if (_firstCharacters.length < 6 || _alphaHelper.totalItemCount < 80) return false;
    // Show when no sort is selected (default is titleSort) or when explicitly sorting by title
    final sortKey = _selectedSort?.key ?? '';
    return sortKey.isEmpty || sortKey.startsWith('titleSort');
  }

  /// Fetch first characters for the current library/filter state
  Future<void> _loadFirstCharacters({int? requestId}) async {
    // Shared libraries don't support first characters
    if (widget.library.isShared) return;
    final currentRequestId = requestId ?? ++_firstCharactersRequestId;
    final client = getClientForLibrary();
    final filterParams = Map<String, String>.from(_selectedFilters);
    final typeId = _getGroupingTypeId();

    filterParams['includeCollections'] = '1';

    try {
      final chars = await client.getFirstCharacters(
        widget.library.key,
        type: typeId.isNotEmpty ? int.tryParse(typeId) : null,
        filters: filterParams.isNotEmpty ? filterParams : null,
      );
      if (!mounted || currentRequestId != _firstCharactersRequestId) return;

      setState(() {
        _firstCharacters = chars;
        _alphaHelper = AlphaJumpHelper(chars);
      });
    } catch (_) {
      // Non-critical — hide the bar on failure
      if (!mounted || currentRequestId != _firstCharactersRequestId) return;

      setState(() {
        _firstCharacters = [];
        _alphaHelper = AlphaJumpHelper(const []);
      });
    }
  }

  /// Track scroll position and trigger debounced range loading.
  void _onScrollChanged() {
    // Debounced scroll-idle handler: load visible range when scrolling settles
    _scrollIdleTimer?.cancel();
    _scrollIdleTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      // Discard stale in-flight tracking from eager prefetch during scroll so
      // ensureRangeLoaded sees the full gap at the settled position.
      clearPendingRanges();
      final range = _computeVisibleRange();
      if (range != null) {
        ensureRangeLoaded(range.firstIndex, range.visibleCount, buffer: _fetchSize ~/ 2);
        evictDistantItems(range.firstIndex, maxKeep: 500, threshold: 600);
        evictDistantFocusNodes(range.firstIndex);
      }
    });

    // Eager prefetch: fetch data before scroll stops
    final range = _computeVisibleRange();
    if (range != null) {
      prefetchAhead(range.firstIndex, range.visibleCount, pageSize: _fetchSize);
    }

    if (!_shouldShowAlphaJumpBar || _currentColumnCount < 1) return;

    // During a jump animation, skip alpha bar processing to avoid flashing.
    if (_isJumpScrolling) return;

    // If pinned from a completed jump, the next scroll event must be
    // user-initiated (touch drag, mouse wheel, etc.) — clear the pin
    // and resume normal tracking.
    if (_hasJumpPin) {
      _hasJumpPin = false;
    }

    // Throttle alpha bar updates to ~50fps, with a trailing-edge timer
    // so the final scroll position always gets an update
    final now = DateTime.now();
    if (_lastAlphaUpdate == null || now.difference(_lastAlphaUpdate!) >= const Duration(milliseconds: 20)) {
      _lastAlphaUpdate = now;
      _updateVisibleIndex();
    }
    _alphaUpdateTimer?.cancel();
    _alphaUpdateTimer = Timer(const Duration(milliseconds: 20), () {
      if (mounted) _updateVisibleIndex();
    });
  }

  /// Recompute the first-visible-index from the current scroll offset.
  void _updateVisibleIndex() {
    final offset = _scrollController.offset;
    final firstInRow = _itemIndexFromScrollOffset(offset);
    // Use the last item in the first visible row so the highlighted letter
    // updates as soon as items with a new letter appear in that row.
    final maxIndex = totalSize > 0 ? totalSize - 1 : 0;
    final lastInRow = (firstInRow + _currentColumnCount - 1).clamp(0, maxIndex);
    if (lastInRow != _currentFirstVisibleIndex.value) {
      _currentFirstVisibleIndex.value = lastInRow;
    }
  }

  /// Compute the first visible item index from a scroll offset.
  /// The visible area starts below the chips bar, so we offset accordingly.
  int _itemIndexFromScrollOffset(double offset) {
    if (_lastCrossAxisExtent <= 0 || _currentColumnCount < 1) return 0;

    final itemWidth = _lastCrossAxisExtent / _currentColumnCount;
    final itemHeight = itemWidth / GridLayoutConstants.posterAspectRatio;
    final rowHeight = itemHeight + GridLayoutConstants.mainAxisSpacing;
    if (rowHeight <= 0) return 0;

    // The visible area starts at _chipsBarHeight from the viewport top.
    // Grid content starts at _effectiveTopPadding in scroll coordinates.
    // First visible row = (offset + chipsBarHeight - effectiveTopPadding) / rowHeight
    final contentOffset = (offset + _chipsBarHeight - _effectiveTopPadding).clamp(0.0, double.infinity);
    final row = (contentOffset / rowHeight).floor();
    final maxIndex = totalSize > 0 ? totalSize - 1 : 0;
    return (row * _currentColumnCount).clamp(0, maxIndex);
  }

  /// Scroll to the item at [targetIndex], loading more pages if necessary.
  /// The target index is a cumulative offset from the API's firstCharacter
  /// counts — the same model used by [_currentAlphaLetter] so highlight
  /// and jump always agree.
  void _jumpToIndex(int targetIndex) {
    _jumpScrollGeneration++;
    _isJumpScrolling = true;

    _hasJumpPin = true;
    final clamped = targetIndex.clamp(0, totalSize > 0 ? totalSize - 1 : 0);
    _currentFirstVisibleIndex.value = clamped;

    _scrollToItemIndex(clamped);
  }

  /// Scroll the grid so that [index] is visible just below the chips bar
  void _scrollToItemIndex(int index) {
    if (_currentColumnCount < 1 || _lastCrossAxisExtent <= 0 || !_scrollController.hasClients) {
      _isJumpScrolling = false;
      return;
    }

    final itemWidth = _lastCrossAxisExtent / _currentColumnCount;
    final itemHeight = itemWidth / GridLayoutConstants.posterAspectRatio;
    final rowHeight = itemHeight + GridLayoutConstants.mainAxisSpacing;
    final targetRow = index ~/ _currentColumnCount;
    // Position the target row right below the chips bar
    final offset = _effectiveTopPadding + targetRow * rowHeight - _chipsBarHeight;

    final gen = _jumpScrollGeneration;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (!maxExtent.isFinite) {
      _isJumpScrolling = false;
      return;
    }
    final clampedOffset = offset.clamp(0.0, maxExtent);

    // If a newer jump already superseded this one, skip the animation
    // entirely — the next call will handle the final position.
    if (gen != _jumpScrollGeneration) {
      _scrollController.jumpTo(clampedOffset);
      return;
    }

    _scrollController
        .animateTo(clampedOffset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
        .then((_) {
          // Only clear the flag if no newer jump has started.
          if (mounted && gen == _jumpScrollGeneration) {
            _isJumpScrolling = false;
          }
        });
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
              firstItemFocusNode: firstItemFocusNode,
              onNavigateUp: _navigateToChips,
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
        // Alpha jump bar / scroll handle on the right edge
        if (_shouldShowAlphaJumpBar)
          Positioned(
            top: _chipsBarHeight,
            right: 0,
            bottom: 0,
            child: _isPhone(context)
                ? ValueListenableBuilder<int>(
                    valueListenable: _currentFirstVisibleIndex,
                    builder: (context, visibleIndex, _) => ValueListenableBuilder<bool>(
                      valueListenable: _isScrollActive,
                      builder: (context, scrolling, _) => AlphaScrollHandle(
                        firstCharacters: _firstCharacters,
                        onJump: _jumpToIndex,
                        currentLetter: _alphaLetterFor(visibleIndex),
                        isScrolling: scrolling,
                      ),
                    ),
                  )
                : ValueListenableBuilder<int>(
                    valueListenable: _currentFirstVisibleIndex,
                    builder: (context, visibleIndex, _) => AlphaJumpBar(
                      firstCharacters: _firstCharacters,
                      onJump: _jumpToIndex,
                      currentLetter: _alphaLetterFor(visibleIndex),
                      focusNode: _alphaJumpBarFocusNode,
                      onNavigateLeft: _navigateToGridNearScroll,
                      onBack: _navigateToGridNearScroll,
                    ),
                  ),
          ),
      ],
    );
  }

  /// Builds the scrollable content (grid/list) with scroll-idle loading
  Widget _buildScrollableContent() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Track scroll activity for phone scroll handle and range-load gating
        if (notification is ScrollStartNotification) {
          _isScrollActive.value = true;
          _scrollActivityTimer?.cancel();
        } else if (notification is ScrollEndNotification) {
          _scrollActivityTimer?.cancel();
          _scrollActivityTimer = Timer(const Duration(milliseconds: 100), () {
            if (mounted) _isScrollActive.value = false;
          });
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

  /// Self-healing: when a skeleton is rendered after scrolling stops,
  /// ensure the visible range gets loaded even if the scroll-idle path missed it.
  void _scheduleRangeLoad() {
    if (_rangeLoadScheduled || _isScrollActive.value) return;
    _rangeLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rangeLoadScheduled = false;
      if (!mounted) return;
      final range = _computeVisibleRange();
      if (range != null) {
        ensureRangeLoaded(range.firstIndex, range.visibleCount, buffer: _fetchSize ~/ 2);
      }
    });
  }

  /// Returns the first-visible index and visible count from the scroll
  /// controller + grid metrics, or null if the viewport isn't measured yet.
  ({int firstIndex, int visibleCount})? _computeVisibleRange() {
    if (_currentColumnCount < 1 || !_scrollController.hasClients || _lastCrossAxisExtent <= 0) return null;
    final offset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    if (!viewportHeight.isFinite) return null;

    final itemWidth = _lastCrossAxisExtent / _currentColumnCount;
    final itemHeight = itemWidth / GridLayoutConstants.posterAspectRatio;
    final rowHeight = itemHeight + GridLayoutConstants.mainAxisSpacing;
    if (rowHeight <= 0) return null;

    final visibleRows = (viewportHeight / rowHeight).ceil() + 1;
    return (firstIndex: _itemIndexFromScrollOffset(offset), visibleCount: visibleRows * _currentColumnCount);
  }

  /// Compute initial fetch size based on viewport dimensions.
  int _calculateInitialFetchSize() {
    try {
      final screenSize = MediaQuery.sizeOf(context);
      final settingsProvider = context.read<SettingsProvider>();
      final maxExtent = GridSizeCalculator.getMaxCrossAxisExtent(context, settingsProvider.libraryDensity);
      final crossAxisSpacing = GridLayoutConstants.crossAxisSpacing;
      final columnCount = ((screenSize.width + crossAxisSpacing) / (maxExtent + crossAxisSpacing)).ceil().clamp(1, 100);
      final itemWidth = screenSize.width / columnCount;
      final itemHeight = itemWidth / GridLayoutConstants.posterAspectRatio;
      final rowHeight = itemHeight + GridLayoutConstants.mainAxisSpacing;
      if (rowHeight <= 0) return _fetchSize;
      final visibleRows = (screenSize.height / rowHeight).ceil() + 1;
      final visibleCount = visibleRows * columnCount;
      return (visibleCount * 3).clamp(100, 500);
    } catch (_) {
      return _fetchSize;
    }
  }

  /// Prefetch images for items near the viewport to reduce pop-in.
  void _prefetchImages(int startIndex, List<PlexMetadata> items) {
    if (!_scrollController.hasClients || _lastCrossAxisExtent <= 0 || _currentColumnCount < 1) return;

    final offset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    if (!viewportHeight.isFinite) return;
    final firstVisible = _itemIndexFromScrollOffset(offset);
    final itemWidth = _lastCrossAxisExtent / _currentColumnCount;
    final itemHeight = itemWidth / GridLayoutConstants.posterAspectRatio;
    final rowHeight = itemHeight + GridLayoutConstants.mainAxisSpacing;
    if (rowHeight <= 0) return;

    final visibleRows = (viewportHeight / rowHeight).ceil() + 1;
    final visibleEnd = firstVisible + visibleRows * _currentColumnCount;
    // Prefetch 2 rows beyond visible area
    final prefetchEnd = visibleEnd + 2 * _currentColumnCount;

    final client = getClientForLibrary();
    final devicePixelRatio = PlexImageHelper.effectiveDevicePixelRatio(context);

    for (var i = 0; i < items.length; i++) {
      final index = startIndex + i;
      if (index < firstVisible || index > prefetchEnd) continue;

      final thumb = items[i].thumb;
      if (thumb == null || thumb.isEmpty) continue;

      final imageUrl = PlexImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: thumb,
        maxWidth: itemWidth,
        maxHeight: itemHeight,
        devicePixelRatio: devicePixelRatio,
        enableTranscoding: PlexImageHelper.shouldTranscode(thumb),
        imageType: ImageType.poster,
      );
      if (imageUrl.isEmpty) continue;

      final scaledWidth = itemWidth * devicePixelRatio;
      final scaledHeight = itemHeight * devicePixelRatio;
      final (_, memHeight) = PlexImageHelper.getMemCacheDimensions(
        displayWidth: scaledWidth.isFinite && scaledWidth > 0 ? scaledWidth.round() : 0,
        displayHeight: scaledHeight.isFinite && scaledHeight > 0 ? scaledHeight.round() : 0,
        imageType: ImageType.poster,
      );

      precacheImage(
        CachedNetworkImageProvider(
          imageUrl,
          cacheManager: PlexImageCacheManager.instance,
          headers: const {'User-Agent': 'Plezy'},
          maxHeight: memHeight,
        ),
        context,
      ).ignore();
    }
  }

  /// Whether the filters chip is visible
  bool get _isFiltersChipVisible => _filters.isNotEmpty && _selectedGrouping != 'folders';

  /// Whether the sort chip is visible
  bool get _isSortChipVisible => _sortOptions.isNotEmpty && _selectedGrouping != 'folders';

  /// Builds the chips bar widget
  Widget _buildChipsBar() {
    VoidCallback? groupingNavigateRight;
    if (_isFiltersChipVisible) {
      groupingNavigateRight = () => _filtersChipFocusNode.requestFocus();
    } else if (_isSortChipVisible) {
      groupingNavigateRight = () => _sortChipFocusNode.requestFocus();
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            onNavigateRight: groupingNavigateRight,
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
    if (isLoading && totalSize == 0 && loadedItems.isEmpty) {
      return [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))];
    }

    if (errorMessage != null && loadedItems.isEmpty) {
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

    if (totalSize == 0 && !isLoading) {
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

  // Top padding for grid content = chips bar height + extra space for focus decoration.
  // Chips bar is ~48px, focus ring extends ~6px beyond item bounds.
  // On phone there's no D-pad focus decoration so extra clearance is unnecessary.
  static const double _gridTopPadding = _chipsBarHeight + 12.0;
  static const double _gridTopPaddingPhone = _chipsBarHeight;

  /// Width of the alpha jump bar widget
  static const double _alphaJumpBarWidth = 20.0;

  /// Builds either a sliver list or sliver grid based on the view mode
  Widget _buildItemsSliver(BuildContext context, SettingsProvider settingsProvider) {
    final itemCount = totalSize;
    final isPhone = _isPhone(context);
    final topPadding = isPhone ? _gridTopPaddingPhone : _gridTopPadding;
    _effectiveTopPadding = topPadding;
    final rightPadding = _shouldShowAlphaJumpBar && !isPhone ? _alphaJumpBarWidth : 8.0;

    if (settingsProvider.viewMode == ViewMode.list) {
      // In list view, all items are in a single column (first column)
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(8, topPadding, rightPadding, 8),
        sliver: SliverList.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) => _buildMediaCardItem(
            index,
            isFirstRow: index == 0,
            isFirstColumn: true, // List view = single column
            disableScale: true,
          ),
        ),
      );
    } else {
      // In grid view, calculate columns and pass to item builder
      // Use 16:9 aspect ratio when browsing episodes with episode thumbnail mode
      final useWideRatio =
          _selectedGrouping == 'episodes' && settingsProvider.episodePosterMode == EpisodePosterMode.episodeThumbnail;
      final baseMaxExtent = GridSizeCalculator.getMaxCrossAxisExtent(context, settingsProvider.libraryDensity);
      final effectiveMaxExtent = useWideRatio ? baseMaxExtent * 1.8 : baseMaxExtent;
      final hasAlphaBarReservation = rightPadding > 8.0;
      return SliverPadding(
        padding: EdgeInsets.fromLTRB(8, topPadding, rightPadding, 8),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            // Compute column count from the width the grid would have without the alpha
            // bar's reservation, so toggling the bar doesn't repack the grid into one
            // fewer column and blow up poster size.
            final baselineWidth = constraints.crossAxisExtent + (rightPadding - 8.0);
            final columnCount = GridSizeCalculator.getColumnCount(baselineWidth, effectiveMaxExtent);
            // Cache grid metrics for alpha jump bar scroll calculations
            _lastCrossAxisExtent = constraints.crossAxisExtent;
            _currentColumnCount = columnCount;
            return SliverGrid.builder(
              gridDelegate: MediaGridDelegate.createDelegate(
                context: context,
                density: settingsProvider.libraryDensity,
                useWideAspectRatio: useWideRatio,
                maxCrossAxisExtentOverride: hasAlphaBarReservation ? constraints.crossAxisExtent / columnCount : null,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) => _buildMediaCardItem(
                index,
                isFirstRow: GridSizeCalculator.isFirstRow(index, columnCount),
                isFirstColumn: GridSizeCalculator.isFirstColumn(index, columnCount),
                isLastColumn: (index % columnCount) == (columnCount - 1),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildMediaCardItem(
    int index, {
    required bool isFirstRow,
    required bool isFirstColumn,
    bool isLastColumn = false,
    bool disableScale = false,
  }) {
    final item = loadedItems[index];

    // Show skeleton placeholder for unloaded items
    if (item == null) {
      _scheduleRangeLoad();
      return const SkeletonMediaCard();
    }

    // Use firstItemFocusNode for index 0 to maintain compatibility with base class
    // All other items get managed focus nodes for restoration
    final focusNode = index == 0 ? firstItemFocusNode : getGridItemFocusNode(index, prefix: 'browse_grid_item');

    return FocusableMediaCard(
      key: Key(item.ratingKey),
      item: item,
      focusNode: focusNode,
      disableScale: disableScale,
      onRefresh: updateItem,
      onNavigateUp: isFirstRow ? _navigateToChips : null,
      onNavigateLeft: isFirstColumn ? _navigateToSidebar : null,
      onNavigateRight: isLastColumn && _shouldShowAlphaJumpBar && !_isPhone(context) ? _navigateToAlphaJumpBar : null,
      onBack: widget.onBack,
      onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
      onListRefresh: _loadItems,
    );
  }
}
