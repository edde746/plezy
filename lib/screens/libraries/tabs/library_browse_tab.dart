import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../focus/dpad_navigator.dart';
import '../../../../services/plex_client.dart';
import '../../../models/plex_metadata.dart';
import '../../../models/plex_filter.dart';
import '../../../models/plex_first_character.dart';
import '../../../models/plex_sort.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/error_message_utils.dart';
import '../../../utils/grid_size_calculator.dart';
import '../../../utils/layout_constants.dart';
import '../../../widgets/alpha_jump_bar.dart';
import '../../../widgets/alpha_jump_helper.dart';
import '../../../widgets/alpha_scroll_handle.dart';
import '../../../widgets/focusable_media_card.dart';
import '../../../widgets/media_card.dart';
import '../../../widgets/focusable_filter_chip.dart';
import '../../../widgets/media_grid_delegate.dart';
import '../../../widgets/overlay_sheet.dart';
import '../../../mixins/library_tab_focus_mixin.dart';
import '../folder_tree_view.dart';
import '../filters_bottom_sheet.dart';
import '../sort_bottom_sheet.dart';
import '../state_messages.dart';
import '../../../services/storage_service.dart';
import '../../../services/settings_service.dart' show ViewMode, EpisodePosterMode;
import '../../../mixins/grid_focus_node_mixin.dart';
import '../../../mixins/item_updatable.dart';
import '../../../mixins/deletion_aware.dart';
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
    with ItemUpdatable, LibraryTabFocusMixin, GridFocusNodeMixin, DeletionAware {
  @override
  PlexClient get client => getClientForLibrary();

  String _toGlobalKey(String ratingKey, {String? serverId}) =>
      buildGlobalKey(serverId ?? widget.library.serverId ?? '', ratingKey);

  @override
  String? get deletionServerId => widget.library.serverId;

  @override
  Set<String>? get deletionRatingKeys => _loadedItems.values.map((e) => e.ratingKey).toSet();

  @override
  Set<String>? get deletionGlobalKeys {
    if (_loadedItems.isEmpty) return <String>{};

    final keys = <String>{};
    for (final item in _loadedItems.values) {
      final serverId = item.serverId ?? widget.library.serverId;
      if (serverId == null) return null;
      keys.add(_toGlobalKey(item.ratingKey, serverId: serverId));
    }
    return keys;
  }

  @override
  void onDeletionEvent(DeletionEvent event) {
    // If we have an item that matches the rating key exactly, remove it and rebuild indices
    final matchEntry = _loadedItems.entries.where((e) => e.value.ratingKey == event.ratingKey).firstOrNull;
    if (matchEntry != null) {
      setState(() {
        _removeLoadedItemAndShift(matchEntry.key);
      });
      return;
    }

    // If a child item was deleted, update our item to reflect that.
    // If all children were deleted, remove our item.
    // Otherwise, just update the counts.
    for (final parentKey in event.parentChain) {
      final parentEntry = _loadedItems.entries.where((e) => e.value.ratingKey == parentKey).firstOrNull;
      if (parentEntry != null) {
        final item = parentEntry.value;
        final newLeafCount = (item.leafCount ?? 1) - event.leafCount;
        if (newLeafCount <= 0) {
          setState(() {
            _removeLoadedItemAndShift(parentEntry.key);
          });
        } else {
          setState(() {
            _loadedItems[parentEntry.key] = item.copyWith(leafCount: newLeafCount);
          });
        }
        return;
      }
    }
  }

  /// Remove an item at [index] and shift all higher indices down by 1
  void _removeLoadedItemAndShift(int index) {
    _loadedItems.remove(index);
    // Rebuild map with shifted indices for items above the removed one
    final shifted = <int, PlexMetadata>{};
    for (final entry in _loadedItems.entries) {
      if (entry.key < index) {
        shifted[entry.key] = entry.value;
      } else {
        shifted[entry.key - 1] = entry.value;
      }
    }
    _loadedItems.clear();
    _loadedItems.addAll(shifted);
    _totalSize = (_totalSize - 1).clamp(0, _totalSize);
  }

  @override
  String get focusNodeDebugLabel => 'browse_first_item';

  @override
  int get itemCount => _totalSize;

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    setState(() {
      for (final entry in _loadedItems.entries) {
        if (entry.value.ratingKey == ratingKey) {
          _loadedItems[entry.key] = updatedMetadata;
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
  int _currentFirstVisibleIndex = 0;
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

  // Scroll activity tracking (for phone scroll handle)
  bool _isScrollActive = false;
  Timer? _scrollActivityTimer;

  // Pagination state
  int _totalSize = 0;
  final Map<int, PlexMetadata> _loadedItems = {};
  final Set<int> _loadingRanges = {};
  CancelToken? _cancelToken;
  int _requestId = 0;
  static const int _fetchSize = 200;
  Timer? _scrollIdleTimer;

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
    _cancelToken?.cancel();
    _scrollActivityTimer?.cancel();
    _scrollIdleTimer?.cancel();
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    _groupingChipFocusNode.dispose();
    _filtersChipFocusNode.dispose();
    _sortChipFocusNode.dispose();
    _alphaJumpBarFocusNode.dispose();
    disposeGridFocusNodes();
    super.dispose();
  }

  // Override tryFocus to use _loadedItems instead of base class items list
  @override
  void tryFocus() {
    if (widget.suppressAutoFocus) return;
    if (widget.isActive && hasLoadedData && !hasFocused && _loadedItems.isNotEmpty) {
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

    if (_loadedItems.isNotEmpty) {
      // Request immediately, then once more on the next frame to handle cases
      // where the grid/list attaches after the initial focus attempt.
      void request() {
        if (mounted && _loadedItems.isNotEmpty && !firstItemFocusNode.hasFocus) {
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
    // Grouping chip is always visible (including in folder mode)
    _groupingChipFocusNode.requestFocus();
  }

  Future<void> _loadContent() async {
    // Cancel any pending request
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    // Use a generation counter for the filter/sort loading phase
    final generation = ++_requestId;

    // Extract context dependencies before async gap - use server-specific client
    final client = getClientForLibrary();

    setState(() {
      isLoading = true;
      errorMessage = null;
      items = [];
      _totalSize = 0;
      _loadedItems.clear();
      _loadingRanges.clear();
      // Clear filter/sort state while loading to prevent showing stale options
      _filters = [];
      _sortOptions = [];
      _selectedFilters = {};
      _selectedSort = null;
      _isSortDescending = false;
      _selectedGrouping = _getDefaultGrouping();
      _firstCharacters = [];
      _alphaHelper = AlphaJumpHelper(const []);
      _currentFirstVisibleIndex = 0;
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

      // Check if request was superseded
      if (generation != _requestId) return;

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
      await Future.wait([_loadItems(), _loadFirstCharacters()]);
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
    }

    // Add sort
    if (_selectedSort != null) {
      filterParams['sort'] = _selectedSort!.getSortKey(descending: _isSortDescending);
    }

    return filterParams;
  }

  Future<void> _loadItems() async {
    final currentRequestId = ++_requestId;
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    setState(() {
      isLoading = true;
      items = [];
      _totalSize = 0;
      _loadedItems.clear();
      _loadingRanges.clear();
      // Increment content version when loading fresh content
      // This invalidates the last focused index
      gridContentVersion++;
      cleanupGridFocusNodes(0);
    });

    try {
      // Use server-specific client for this library
      final client = getClientForLibrary();
      final filterParams = _buildFilterParams();

      // Items are automatically tagged with server info by PlexClient
      final result = await client.getLibraryContent(
        widget.library.key,
        start: 0,
        size: _fetchSize,
        filters: filterParams,
        cancelToken: _cancelToken,
      );

      if (currentRequestId != _requestId) return;

      if (!mounted) return;
      setState(() {
        _totalSize = result.totalSize;
        for (var i = 0; i < result.items.length; i++) {
          _loadedItems[i] = result.items[i];
        }
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
      _handleLoadError(e, currentRequestId);
    }
  }

  /// Fetch a range of items from the API and store them in the sparse map.
  /// After a successful fetch, re-checks for remaining gaps in the visible range.
  Future<void> _fetchRange(int start, int size) async {
    // Clamp to totalSize
    if (start >= _totalSize) return;
    final clampedSize = size.clamp(0, _totalSize - start);
    if (clampedSize == 0) return;

    // Deduplicate: track every index in-flight to prevent overlapping fetches
    final indices = List.generate(clampedSize, (i) => start + i);
    if (indices.every((i) => _loadingRanges.contains(i) || _loadedItems.containsKey(i))) return;
    _loadingRanges.addAll(indices);

    final currentRequestId = _requestId;

    try {
      final client = getClientForLibrary();
      final filterParams = _buildFilterParams();

      final result = await client.getLibraryContent(
        widget.library.key,
        start: start,
        size: clampedSize,
        filters: filterParams,
        cancelToken: _cancelToken,
      );

      if (currentRequestId != _requestId || !mounted) return;

      setState(() {
        for (var i = 0; i < result.items.length; i++) {
          _loadedItems[start + i] = result.items[i];
        }
        // Update totalSize in case it changed (e.g., items added/removed on server)
        if (result.totalSize != _totalSize) {
          _totalSize = result.totalSize;
        }
      });

      // Re-check for remaining gaps in the visible range after this fetch
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && currentRequestId == _requestId) {
          _loadVisibleRange();
        }
      });
    } catch (e) {
      // Silently ignore fetch errors for background range loads
      // (the initial load handles errors with UI feedback)
      if (e is DioException && e.type == DioExceptionType.cancel) return;
    } finally {
      _loadingRanges.removeAll(indices);
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
    OverlaySheetController.of(context)
        .show(
          builder: (sheetContext) {
            final options = _getGroupingOptions();
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return RadioGroup<String>(
                  groupValue: pendingGrouping,
                  onChanged: (value) {
                    if (value == null) return;
                    setSheetState(() {
                      pendingGrouping = value;
                    });
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
          },
        )
        .then((_) {
          if (!mounted) return;
          if (pendingGrouping == _selectedGrouping) return;
          setState(() {
            _selectedGrouping = pendingGrouping;
          });
          StorageService.getInstance().then((storage) {
            storage.saveLibraryGrouping(widget.library.globalKey, pendingGrouping);
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

    if (_totalSize == 0) return;

    final targetIndex = shouldRestoreGridFocus && lastFocusedGridIndex! < _totalSize && _loadedItems.containsKey(lastFocusedGridIndex!) ? lastFocusedGridIndex! : 0;

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
    if (_totalSize == 0 || _currentColumnCount < 1) return;

    final row = _currentFirstVisibleIndex ~/ _currentColumnCount;
    var targetIndex = ((row + 1) * _currentColumnCount - 1).clamp(0, _totalSize - 1);

    // Find nearest loaded item — skeleton cards have no FocusNode
    if (!_loadedItems.containsKey(targetIndex)) {
      // Search backwards first (items above are more likely visible)
      int? found;
      for (var i = targetIndex - 1; i >= 0; i--) {
        if (_loadedItems.containsKey(i)) {
          found = i;
          break;
        }
      }
      // Then search forwards
      if (found == null) {
        for (var i = targetIndex + 1; i < _totalSize; i++) {
          if (_loadedItems.containsKey(i)) {
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

  /// Navigate focus from grid up to the grouping chip
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
  String get _currentAlphaLetter {
    return _alphaHelper.currentLetter(_currentFirstVisibleIndex);
  }

  /// Whether the alpha jump bar should be shown.
  /// Only shown when sorting by title (titleSort) and not in folders mode.
  bool get _shouldShowAlphaJumpBar {
    if (_selectedGrouping == 'folders') return false;
    if (_firstCharacters.isEmpty) return false;
    // Show when no sort is selected (default is titleSort) or when explicitly sorting by title
    final sortKey = _selectedSort?.key ?? '';
    return sortKey.isEmpty || sortKey.startsWith('titleSort');
  }

  /// Fetch first characters for the current library/filter state
  Future<void> _loadFirstCharacters() async {
    final client = getClientForLibrary();
    final filterParams = Map<String, String>.from(_selectedFilters);
    final typeId = _getGroupingTypeId();

    try {
      final chars = await client.getFirstCharacters(
        widget.library.key,
        type: typeId.isNotEmpty ? int.tryParse(typeId) : null,
        filters: filterParams.isNotEmpty ? filterParams : null,
      );
      if (mounted) {
        setState(() {
          _firstCharacters = chars;
          _alphaHelper = AlphaJumpHelper(chars);
        });
      }
    } catch (_) {
      // Non-critical — hide the bar on failure
      if (mounted) {
        setState(() {
          _firstCharacters = [];
          _alphaHelper = AlphaJumpHelper(const []);
        });
      }
    }
  }

  /// Track scroll position and trigger debounced range loading.
  void _onScrollChanged() {
    // Debounced scroll-idle handler: load visible range when scrolling settles
    _scrollIdleTimer?.cancel();
    _scrollIdleTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) _loadVisibleRange();
    });

    if (!_shouldShowAlphaJumpBar || _currentColumnCount < 1) return;

    // During a jump animation, skip alpha bar processing to avoid flashing.
    if (_isJumpScrolling) return;

    // If pinned from a completed jump, the next scroll event must be
    // user-initiated (touch drag, mouse wheel, etc.) — clear the pin
    // and resume normal tracking.
    if (_hasJumpPin) {
      _hasJumpPin = false;
    }

    _updateVisibleIndex();
  }

  /// Recompute the first-visible-index from the current scroll offset.
  void _updateVisibleIndex() {
    final offset = _scrollController.offset;
    final firstInRow = _itemIndexFromScrollOffset(offset);
    // Use the last item in the first visible row so the highlighted letter
    // updates as soon as items with a new letter appear in that row.
    final maxIndex = _totalSize > 0 ? _totalSize - 1 : 0;
    final lastInRow = (firstInRow + _currentColumnCount - 1).clamp(0, maxIndex);
    if (lastInRow != _currentFirstVisibleIndex) {
      setState(() => _currentFirstVisibleIndex = lastInRow);
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
    final maxIndex = _totalSize > 0 ? _totalSize - 1 : 0;
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
    final clamped = targetIndex.clamp(0, _totalSize > 0 ? _totalSize - 1 : 0);
    setState(() => _currentFirstVisibleIndex = clamped);

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
    final clampedOffset = offset.clamp(0.0, _scrollController.position.maxScrollExtent);

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
              onNavigateUp: () => _groupingChipFocusNode.requestFocus(),
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
                ? AlphaScrollHandle(
                    firstCharacters: _firstCharacters,
                    onJump: _jumpToIndex,
                    currentLetter: _currentAlphaLetter,
                    isScrolling: _isScrollActive,
                  )
                : AlphaJumpBar(
                    firstCharacters: _firstCharacters,
                    onJump: _jumpToIndex,
                    currentLetter: _currentAlphaLetter,
                    focusNode: _alphaJumpBarFocusNode,
                    onNavigateLeft: _navigateToGridNearScroll,
                    onBack: _navigateToGridNearScroll,
                  ),
          ),
      ],
    );
  }

  /// Builds the scrollable content (grid/list) with scroll-idle loading
  Widget _buildScrollableContent() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Track scroll activity for phone scroll handle
        if (notification is ScrollStartNotification) {
          if (!_isScrollActive) setState(() => _isScrollActive = true);
          _scrollActivityTimer?.cancel();
        } else if (notification is ScrollEndNotification) {
          _scrollActivityTimer?.cancel();
          _scrollActivityTimer = Timer(const Duration(milliseconds: 100), () {
            if (mounted) setState(() => _isScrollActive = false);
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

  /// Determine the visible range and fetch any unloaded items within it.
  /// Covers the full visible area plus a buffer of _fetchSize/2 on each side,
  /// then finds the first unloaded contiguous block and fetches it.
  void _loadVisibleRange() {
    if (_totalSize == 0 || _currentColumnCount < 1 || !_scrollController.hasClients) return;
    if (_lastCrossAxisExtent <= 0) return;

    final offset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;
    final firstIndex = _itemIndexFromScrollOffset(offset);

    // Calculate how many items fit in the viewport
    final itemWidth = _lastCrossAxisExtent / _currentColumnCount;
    final itemHeight = itemWidth / GridLayoutConstants.posterAspectRatio;
    final rowHeight = itemHeight + GridLayoutConstants.mainAxisSpacing;
    if (rowHeight <= 0) return;

    final visibleRows = (viewportHeight / rowHeight).ceil() + 1;
    final visibleCount = visibleRows * _currentColumnCount;

    // Expand the visible range by a buffer on each side
    final buffer = _fetchSize ~/ 2;
    final rangeStart = (firstIndex - buffer).clamp(0, _totalSize);
    final rangeEnd = (firstIndex + visibleCount + buffer).clamp(0, _totalSize);

    // Find the first and last unloaded indices in the range
    int? fetchStart;
    int? fetchEnd;
    for (var i = rangeStart; i < rangeEnd; i++) {
      if (!_loadedItems.containsKey(i) && !_loadingRanges.contains(i)) {
        fetchStart ??= i;
        fetchEnd = i + 1;
      }
    }
    if (fetchStart == null || fetchEnd == null) return;

    final fetchSize = fetchEnd - fetchStart;
    if (fetchSize <= 0) return;

    _fetchRange(fetchStart, fetchSize);
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
    if (isLoading && _totalSize == 0 && _loadedItems.isEmpty) {
      return [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))];
    }

    if (errorMessage != null && _loadedItems.isEmpty) {
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

    if (_totalSize == 0 && !isLoading) {
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
  static const double _alphaJumpBarWidth = 28.0;

  /// Builds either a sliver list or sliver grid based on the view mode
  Widget _buildItemsSliver(BuildContext context, SettingsProvider settingsProvider) {
    final itemCount = _totalSize;
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
        padding: EdgeInsets.fromLTRB(8, topPadding, rightPadding, 8),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final columnCount = GridSizeCalculator.getColumnCount(constraints.crossAxisExtent, maxExtent);
            // Cache grid metrics for alpha jump bar scroll calculations
            _lastCrossAxisExtent = constraints.crossAxisExtent;
            _currentColumnCount = columnCount;
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
  }) {
    final item = _loadedItems[index];

    // Show skeleton placeholder for unloaded items
    if (item == null) {
      return const _SkeletonCard();
    }

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
      onNavigateRight: isLastColumn && _shouldShowAlphaJumpBar && !_isPhone(context) ? _navigateToAlphaJumpBar : null,
      onBack: widget.onBack,
      onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
      onListRefresh: _loadItems,
    );
  }
}

/// Skeleton placeholder card that matches the poster + title layout of a real media card.
/// Not focusable — dpad focus skips over these.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster area — matches the Expanded poster in _buildGridCard
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const SkeletonLoader(child: SizedBox.expand()),
            ),
          ),
          const SizedBox(height: 4),
          // Title bar
          SkeletonLoader(
            borderRadius: BorderRadius.circular(4),
            child: const SizedBox(height: 13, width: double.infinity),
          ),
          const SizedBox(height: 3),
          // Subtitle bar
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.6,
            child: SkeletonLoader(
              borderRadius: BorderRadius.circular(4),
              child: const SizedBox(height: 11),
            ),
          ),
        ],
      ),
    );
  }
}
