import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../media/library_first_character.dart';
import '../../../media/library_query.dart';
import '../../../media/media_item.dart';
import '../../../providers/multi_server_provider.dart';
import '../../../utils/media_server_http_client.dart';
import '../../../exceptions/media_server_exceptions.dart';
import '../../../focus/dpad_navigator.dart';
import '../../../focus/input_mode_tracker.dart';
import '../../../media/media_filter.dart';
import '../../../media/media_sort.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/image_cache_service.dart';
import '../../../services/library_query_translator.dart';
import '../../../services/plex_constants.dart';
import '../../../utils/error_message_utils.dart';
import '../../../utils/grid_size_calculator.dart';
import '../../../utils/layout_constants.dart';
import '../../../utils/media_image_helper.dart';
import '../../../utils/provider_extensions.dart';
import '../alpha_jump_bar.dart';
import '../alpha_jump_helper.dart';
import '../alpha_scroll_handle.dart';
import '../library_alpha_bar_strategy.dart';
import '../library_filter_sort_loader.dart';
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
class LibraryBrowseTab extends BaseLibraryTab<MediaItem> {
  /// Invoked whenever the tab resets its inner scroll position to the top
  /// (filter/sort change, library reload, etc.). Lets the parent resync the
  /// outer floating header — see `_resetOuterScroll` in libraries_screen.
  final VoidCallback? onResetScroll;

  const LibraryBrowseTab({
    super.key,
    required super.library,
    super.viewMode,
    super.density,
    super.onDataLoaded,
    super.isActive,
    super.suppressAutoFocus,
    super.onBack,
    this.onResetScroll,
  });

  @override
  State<LibraryBrowseTab> createState() => _LibraryBrowseTabState();
}

class _LibraryBrowseTabState extends BaseLibraryTabState<MediaItem, LibraryBrowseTab>
    with ItemUpdatable, LibraryTabFocusMixin, GridFocusNodeMixin, DeletionAware, PaginatedItemLoader<LibraryBrowseTab> {
  @override
  String? get itemServerId => widget.library.serverId;

  String _toGlobalKey(String ratingKey, {String? serverId}) =>
      buildGlobalKey(serverId ?? widget.library.serverId ?? '', ratingKey);

  @override
  String? get deletionServerId => widget.library.serverId;

  @override
  Set<String>? get deletionIds => loadedItems.values.map((e) => e.id).toSet();

  @override
  Set<String>? get deletionGlobalKeys {
    if (loadedItems.isEmpty) return <String>{};

    final keys = <String>{};
    for (final item in loadedItems.values) {
      final serverId = item.serverId ?? widget.library.serverId;
      if (serverId == null) return null;
      keys.add(_toGlobalKey(item.id, serverId: serverId));
    }
    return keys;
  }

  @override
  void onDeletionEvent(DeletionEvent event) {
    // If we have an item that matches the rating key exactly, remove it and rebuild indices
    final matchEntry = loadedItems.entries.where((e) => e.value.id == event.itemId).firstOrNull;
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
      final parentEntry = loadedItems.entries.where((e) => e.value.id == parentKey).firstOrNull;
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
    // deletionGlobalKeys/deletionIds, so this point is unreachable.
    // The grid self-corrects when the next page fetch updates totalSize from
    // the server response on the next scroll.
  }

  @override
  String get focusNodeDebugLabel => 'browse_first_item';

  @override
  int get itemCount => totalSize;

  @override
  void updateItemInLists(String itemId, MediaItem updatedMetadata) {
    setState(() {
      for (final entry in loadedItems.entries) {
        if (entry.value.id == itemId) {
          loadedItems[entry.key] = updatedMetadata;
          break;
        }
      }
    });
  }

  // Browse-specific state (not in base class)
  List<MediaFilter> _filters = [];
  List<MediaSort> _sortOptions = [];
  Map<String, String> _selectedFilters = {};
  MediaSort? _selectedSort;
  bool _isSortDescending = false;
  String _selectedGrouping = 'all'; // all, seasons, episodes, folders

  // Alpha jump bar state
  List<LibraryFirstCharacter> _firstCharacters = [];
  AlphaJumpHelper _alphaHelper = AlphaJumpHelper(const []);
  late final LibraryAlphaBarStrategy _alphaStrategy = LibraryAlphaBarStrategy.forBackend(
    widget.library.backend,
    // Resolved on demand and only invoked by [PlexAlphaBarStrategy], which is
    // only constructed when the library's backend is Plex — the bang is safe.
    plexClientProvider: () {
      final manager = context.read<MultiServerProvider>().serverManager;
      return manager.getPlexClient(widget.library.serverId ?? '')!;
    },
    libraryKey: widget.library.id,
    isShared: widget.library.isShared,
  );

  /// On Jellyfin libraries the alpha bar acts as a filter (matches the
  /// JF web client's UX). Holds the active letter (`#`, `A`–`Z`) or null
  /// when no filter is applied.
  String? _jellyfinAlphaPrefix;

  /// Pre-fetched filter values for Jellyfin libraries — populated by
  /// `_loadContent` and consumed by the FiltersBottomSheet so the sheet
  /// doesn't need to call back into a Plex client for value listings.
  Map<String, List<MediaFilterValue>> _jellyfinFilterValues = const {};
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

  // The inner CustomScrollView attaches its position to NestedScrollView's
  // shared inner controller (via PrimaryScrollController), which has one
  // position per kept-alive tab — making `controller.position` ambiguous and
  // throw an assertion. We capture this tab's specific [ScrollPosition] from
  // a Builder placed inside the slivers list, and address it directly for
  // reads, listener attachment, and programmatic jumpTo/animateTo.
  ScrollPosition? _innerPosition;

  // Lets us trigger pull-to-refresh on the folder tree, which now lives as a
  // sliver inside the same CustomScrollView (no longer self-owning RefreshIndicator).
  final GlobalKey<FolderTreeViewState> _folderTreeKey = GlobalKey<FolderTreeViewState>();

  void _bindInnerPosition(ScrollPosition? position) {
    if (position == _innerPosition) return;
    _innerPosition?.removeListener(_onScrollChanged);
    _innerPosition = position;
    _innerPosition?.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    disposePagination();
    _scrollActivityTimer?.cancel();
    _scrollIdleTimer?.cancel();
    _alphaUpdateTimer?.cancel();
    _innerPosition?.removeListener(_onScrollChanged);
    // _innerPosition is owned by the inner CustomScrollView's Scrollable.
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
  Future<List<MediaItem>> loadData() async {
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
  Widget buildContent(List<MediaItem> items) => const SizedBox.shrink();

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

    // The browse tab state is kept alive across libraries, so ensure this
    // tab's scroll resets to 0 (other tabs keep their own positions).
    final pos = _innerPosition;
    if (pos != null) {
      pos.jumpTo(0);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _innerPosition?.jumpTo(0);
      });
    }

    // Inner-only resets bypass NestedScrollView's natural delta surrender,
    // leaving the outer floating header in its prior partially-hidden state.
    widget.onResetScroll?.call();
  }

  Future<void> _loadContent() async {
    final generation = ++_contentRequestId;
    final firstCharactersGeneration = ++_firstCharactersRequestId;

    _resetForFullReload();

    _resetTopOfPageState();
    _currentFirstVisibleIndex.value = 0;

    // Plex returns categories from `/library/sections/{id}/filters` +
    // `/sorts`; Jellyfin maps `/Items/Filters` into the same shape with
    // values pre-cached and a hardcoded client-side sort list. Both flow
    // through the unified [MediaServerClient.fetchLibraryFiltersWithValues].
    final loader = LibraryFilterSortLoader(clientFor: context.getMediaClientForLibrary);

    try {
      // Filters+sorts must resolve before items so the saved-sort restoration
      // can match a saved key against the just-loaded sort list, and so the
      // first item fetch already includes the restored sort param.
      final loaded = await loader.load(widget.library);
      final storage = await StorageService.getInstance();
      final savedFilters = storage.getLibraryFilters(sectionId: widget.library.globalKey);
      final savedSort = storage.getLibrarySort(widget.library.globalKey);
      final savedGrouping = storage.getLibraryGrouping(widget.library.globalKey);

      if (generation != _contentRequestId || !mounted) return;
      setState(() {
        _filters = loaded.filters;
        _sortOptions = loaded.sorts;
        // Plex returns no cached values (filters fetched lazily per-category);
        // assigning the empty map is a no-op for Plex and a real payload for Jellyfin.
        _jellyfinFilterValues = loaded.cachedValues;
        _selectedFilters = Map.from(savedFilters);
        _selectedGrouping = savedGrouping ?? _getDefaultGrouping();

        // Restore sort
        if (savedSort != null) {
          final sortKey = savedSort['key'] as String?;
          if (sortKey != null) {
            final sort = loaded.sorts.where((s) => s.key == sortKey).firstOrNull;
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

  /// Initial UI state both Plex and Jellyfin paths need before fetching:
  /// loading flag set, lists cleared, filter/sort caches reset.
  void _resetTopOfPageState() {
    setState(() {
      isLoading = true;
      errorMessage = null;
      items = [];
      resetPaginationState();
      _filters = [];
      _sortOptions = [];
      _selectedFilters = {};
      _selectedSort = null;
      _isSortDescending = false;
      _selectedGrouping = _getDefaultGrouping();
      _firstCharacters = [];
      _alphaHelper = AlphaJumpHelper(const []);
    });
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
      filterParams['type'] = PlexMetadataType.videoCsv;
    }

    // Add sort
    if (_selectedSort != null) {
      filterParams['sort'] = _selectedSort!.getSortKey(descending: _isSortDescending);
    }

    filterParams['includeCollections'] = '1';

    // Jellyfin alpha-bar filter — picked up by DataAggregationService and
    // converted to NameStartsWith / NameLessThan on the wire.
    if (_jellyfinAlphaPrefix != null) {
      filterParams['alphaPrefix'] = _jellyfinAlphaPrefix!;
    }

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
  Future<LibraryPage<MediaItem>> fetchPage(int start, int size, AbortController? abort) async {
    final client = context.getMediaClientForLibrary(widget.library);
    final query = libraryQueryFromPlexMap(
      map: _buildFilterParams(),
      libraryKind: widget.library.kind,
      offset: start,
      limit: size,
    );
    return client.fetchLibraryPagedContent(
      widget.library.id,
      query: query,
      libraryKind: widget.library.kind,
      abort: abort,
    );
  }

  @override
  void onPageLoaded(int start, List<MediaItem> pageItems) {
    _prefetchImages(start, pageItems);
  }

  String _getDefaultGrouping() {
    final type = widget.library.kind.id.toLowerCase();
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
    final type = widget.library.kind.id.toLowerCase();
    // Folder browsing relies on a section folder API
    // (Plex `/library/sections/{id}/folders`); gated by capability so any
    // future backend that exposes the same can opt in without touching
    // this method.
    final canFolder = context.tryGetMediaClientForServer(widget.library.serverId)?.capabilities.folderGrouping ?? false;
    if (type == 'show') {
      return ['shows', 'seasons', 'episodes', if (canFolder) 'folders'];
    } else if (type == 'movie') {
      return ['movies', if (canFolder) 'folders'];
    } else if (type == 'mixed') {
      // Shared libraries: all video content types, no folders
      return ['all', 'movies', 'shows', 'seasons', 'episodes'];
    }
    return ['all', if (canFolder) 'folders'];
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
    if (error is MediaServerHttpException) {
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
        // Pre-populated values arrive only from backends that bundle them
        // with the category listing (Jellyfin's `/Items/Filters`). The empty
        // map for Plex libraries falls through to lazy `getFilterValues`.
        cachedValues: _jellyfinFilterValues.isEmpty ? null : _jellyfinFilterValues,
        onFiltersChanged: (filters) async {
          setState(() {
            _selectedFilters.clear();
            _selectedFilters.addAll(filters);
          });

          // Save filters to storage
          final storage = await StorageService.getInstance();
          await storage.saveLibraryFilters(filters, sectionId: widget.library.globalKey);

          unawaited(_loadItems());
          unawaited(_loadFirstCharacters());
        },
      ),
    );
  }

  void _showSortBottomSheet() {
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    // Track pending state in local variables so the callbacks don't trigger
    // setState/_loadItems while the sheet is open (which would steal focus).
    MediaSort? pendingSort = _selectedSort;
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

    // Drop the chip's focus first so the targeted grid item's request isn't
    // racing against the chip's still-held primary focus state. Without this,
    // dpad DOWN from a chip occasionally fails to move focus to the grid.
    if (FocusManager.instance.primaryFocus == _groupingChipFocusNode ||
        FocusManager.instance.primaryFocus == _filtersChipFocusNode ||
        FocusManager.instance.primaryFocus == _sortChipFocusNode) {
      FocusManager.instance.primaryFocus?.unfocus();
    }

    // Use firstItemFocusNode for index 0 (matches _buildMediaCardItem)
    final target = targetIndex == 0
        ? firstItemFocusNode
        : getGridItemFocusNode(targetIndex, prefix: 'browse_grid_item');

    // Defer to a post-frame so the focus node has a chance to attach if the
    // grid item is being built/rebuilt in the same frame.
    if (target.context != null) {
      target.requestFocus();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) target.requestFocus();
      });
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
  String _alphaLetterFor(int index) =>
      _alphaStrategy.currentLetter(index, _alphaHelper, jellyfinAlphaPrefix: _jellyfinAlphaPrefix);

  /// Whether the alpha jump bar should be shown.
  /// Only shown when sorting by title (titleSort) and not in folders mode.
  bool get _shouldShowAlphaJumpBar => _alphaStrategy.shouldShow(
    totalItemCount: totalSize,
    loadedCharacterCount: _firstCharacters.length,
    sortKey: _selectedSort?.key,
    isFolderGrouping: _selectedGrouping == 'folders',
    jellyfinAlphaPrefix: _jellyfinAlphaPrefix,
    isPhone: _isPhone(context),
  );

  /// Fetch first characters for the current library/filter state
  Future<void> _loadFirstCharacters({int? requestId}) async {
    final currentRequestId = requestId ?? ++_firstCharactersRequestId;
    final filterParams = Map<String, String>.from(_selectedFilters);
    final typeId = _getGroupingTypeId();

    try {
      final result = await _alphaStrategy.loadCharacters(
        filters: filterParams,
        typeId: typeId.isNotEmpty ? int.tryParse(typeId) : null,
      );
      if (!mounted || currentRequestId != _firstCharactersRequestId) return;
      setState(() {
        _firstCharacters = result.chars;
        _alphaHelper = result.helper;
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
    // The inner controller (PrimaryScrollController) is shared across tabs.
    // Skip if this tab isn't active so we don't react to a sibling tab's
    // scroll events.
    if (!widget.isActive) return;

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
    final pos = _innerPosition;
    if (pos == null) return;
    final offset = pos.pixels;
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
  /// Chips bar is the first sliver (height = _chipsBarHeight) followed by the
  /// grid's own top padding before the first row.
  int _itemIndexFromScrollOffset(double offset) {
    if (_lastCrossAxisExtent <= 0 || _currentColumnCount < 1) return 0;

    final itemWidth = _lastCrossAxisExtent / _currentColumnCount;
    final itemHeight = itemWidth / GridLayoutConstants.posterAspectRatio;
    final rowHeight = itemHeight + GridLayoutConstants.mainAxisSpacing;
    if (rowHeight <= 0) return 0;

    // Items start at `_chipsBarHeight + _effectiveTopPadding` in scroll coords.
    final contentOffset = (offset - _chipsBarHeight - _effectiveTopPadding).clamp(0.0, double.infinity);
    final row = (contentOffset / rowHeight).floor();
    final maxIndex = totalSize > 0 ? totalSize - 1 : 0;
    return (row * _currentColumnCount).clamp(0, maxIndex);
  }

  /// Handle a tap on the letter at [targetIndex] in the alpha bar. The
  /// active [LibraryAlphaBarStrategy] owns the per-backend behaviour and
  /// invokes one of the two callbacks — Plex scrolls the grid to the
  /// cumulative item offset, Jellyfin toggles a `NameStartsWith` filter
  /// (matches the JF web client UX).
  void _jumpToIndex(int targetIndex) {
    _alphaStrategy.onLetterPressed(
      targetIndex,
      _alphaHelper,
      currentJellyfinPrefix: _jellyfinAlphaPrefix,
      onPlexJump: _scrollGridToIndex,
      onJellyfinPrefixChange: _applyJellyfinAlphaPrefix,
    );
  }

  /// Scroll the grid so the item at [targetIndex] becomes the first visible
  /// row. Used by [PlexAlphaBarStrategy] via [_jumpToIndex].
  void _scrollGridToIndex(int targetIndex) {
    _jumpScrollGeneration++;
    _isJumpScrolling = true;

    _hasJumpPin = true;
    final clamped = targetIndex.clamp(0, totalSize > 0 ? totalSize - 1 : 0);
    _currentFirstVisibleIndex.value = clamped;

    _scrollToItemIndex(clamped);
  }

  /// Apply the new Jellyfin `NameStartsWith` prefix from the alpha bar and
  /// refetch from the top of the now-filtered dataset. Used by
  /// [JellyfinAlphaBarStrategy] via [_jumpToIndex].
  void _applyJellyfinAlphaPrefix(String? nextPrefix) {
    setState(() {
      _jellyfinAlphaPrefix = nextPrefix;
      // Clear loaded items + total so the grid blanks while the new filtered
      // page loads. PaginatedItemLoader internals will repopulate from
      // offset 0 once the next fetchPage call returns.
      resetPaginationState();
      isLoading = true;
    });
    _innerPosition?.jumpTo(0);
    _loadItems();
  }

  /// Scroll the grid so that [index] is visible just below the chips bar
  void _scrollToItemIndex(int index) {
    final pos = _innerPosition;
    if (_currentColumnCount < 1 || _lastCrossAxisExtent <= 0 || pos == null) {
      _isJumpScrolling = false;
      return;
    }

    final itemWidth = _lastCrossAxisExtent / _currentColumnCount;
    final itemHeight = itemWidth / GridLayoutConstants.posterAspectRatio;
    final rowHeight = itemHeight + GridLayoutConstants.mainAxisSpacing;
    final targetRow = index ~/ _currentColumnCount;
    // Position the target row at the top of the viewport. Chips and the grid's
    // top padding both precede the items in scroll coordinates.
    final offset = _chipsBarHeight + _effectiveTopPadding + targetRow * rowHeight;

    final gen = _jumpScrollGeneration;
    final maxExtent = pos.maxScrollExtent;
    if (!maxExtent.isFinite) {
      _isJumpScrolling = false;
      return;
    }
    final clampedOffset = offset.clamp(0.0, maxExtent);

    // If a newer jump already superseded this one, skip the animation
    // entirely — the next call will handle the final position.
    if (gen != _jumpScrollGeneration) {
      pos.jumpTo(clampedOffset);
      return;
    }

    pos.animateTo(clampedOffset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut).then((_) {
      // Only clear the flag if no newer jump has started.
      if (mounted && gen == _jumpScrollGeneration) {
        _isJumpScrolling = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Chips are inline as a floating sliver in the inner scroll. The alpha
    // jump bar is the only overlay; we offset it by the typical app bar height
    // so it isn't obscured by the floating outer header. Using MediaQuery
    // (not the absorber handle) avoids rebuilding during layout — listening to
    // the handle from a builder fires notifyListeners during the build phase
    // and triggers a setState-in-build assertion.
    final media = MediaQuery.of(context);
    final overlayTopPadding = media.padding.top + kToolbarHeight;

    return Stack(
      children: [
        Positioned.fill(child: _buildScrollableContent()),
        if (_shouldShowAlphaJumpBar)
          Positioned(
            top: overlayTopPadding,
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

  /// Builds the scrollable content with chips, then either folder tree or grid/list.
  Widget _buildScrollableContent() {
    final isFolders = _selectedGrouping == 'folders';

    Widget scrollView = NotificationListener<ScrollNotification>(
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
      child: Builder(
        builder: (context) => CustomScrollView(
          // No explicit controller: this picks up NestedScrollView's
          // PrimaryScrollController, which is what wires inner scroll deltas
          // through to the outer floating header.
          // Allow focus decoration to render outside scroll bounds.
          clipBehavior: Clip.none,
          slivers: [
            SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            // Capture-only sliver: an invisible Builder whose context lives
            // inside this CustomScrollView, used to grab the per-tab
            // ScrollPosition. NSV's shared inner controller has one position
            // per kept-alive tab; we need this tab's specific one.
            SliverToBoxAdapter(
              child: Builder(
                builder: (innerCtx) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _bindInnerPosition(Scrollable.maybeOf(innerCtx)?.position);
                    }
                  });
                  return const SizedBox.shrink();
                },
              ),
            ),
            // Floating chips: scroll off with content but snap back into view
            // on upward direction reversal, matching the outer floating
            // SliverAppBar's behavior.
            SliverPersistentHeader(
              floating: true,
              pinned: false,
              delegate: _ChipsBarDelegate(builder: (_) => _buildChipsBar(), height: _chipsBarHeight),
            ),
            ..._buildContentSlivers(),
          ],
        ),
      ),
    );

    // Folders mode previously had its own RefreshIndicator inside FolderTreeView;
    // it now lives at this level since FolderTreeView is a sliver.
    if (isFolders) {
      scrollView = RefreshIndicator(
        onRefresh: () async {
          await _folderTreeKey.currentState?.refresh();
        },
        child: scrollView,
      );
    }

    return scrollView;
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
  /// position + grid metrics, or null if the viewport isn't measured yet.
  ({int firstIndex, int visibleCount})? _computeVisibleRange() {
    final pos = _innerPosition;
    if (_currentColumnCount < 1 || pos == null || _lastCrossAxisExtent <= 0) return null;
    final offset = pos.pixels;
    final viewportHeight = pos.viewportDimension;
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
  void _prefetchImages(int startIndex, List<MediaItem> items) {
    final pos = _innerPosition;
    if (pos == null || _lastCrossAxisExtent <= 0 || _currentColumnCount < 1) return;

    final offset = pos.pixels;
    final viewportHeight = pos.viewportDimension;
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

    final client = getMediaClientForLibrary();
    final devicePixelRatio = MediaImageHelper.effectiveDevicePixelRatio(context);

    for (var i = 0; i < items.length; i++) {
      final index = startIndex + i;
      if (index < firstVisible || index > prefetchEnd) continue;

      final thumb = items[i].thumbPath;
      if (thumb == null || thumb.isEmpty) continue;

      final imageUrl = MediaImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: thumb,
        maxWidth: itemWidth,
        maxHeight: itemHeight,
        devicePixelRatio: devicePixelRatio,
        enableTranscoding: MediaImageHelper.shouldTranscode(thumb),
        imageType: ImageType.poster,
      );
      if (imageUrl.isEmpty) continue;

      final scaledWidth = itemWidth * devicePixelRatio;
      final scaledHeight = itemHeight * devicePixelRatio;
      final (_, memHeight) = MediaImageHelper.getMemCacheDimensions(
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
    // Folders mode: hand off to the FolderTreeView sliver, which owns its own
    // loading/empty/error states.
    if (_selectedGrouping == 'folders') {
      return [
        FolderTreeView(
          key: _folderTreeKey,
          libraryKey: widget.library.id,
          serverId: widget.library.serverId,
          onRefresh: updateItem,
          firstItemFocusNode: firstItemFocusNode,
          onNavigateUp: _navigateToChips,
        ),
      ];
    }

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

  // Top padding for grid content. Chips are inline above the grid now, so this
  // is purely focus-decoration clearance (~6px) on desktop. Phone has no D-pad
  // focus ring so no extra clearance is needed.
  static const double _gridTopPadding = 12.0;
  static const double _gridTopPaddingPhone = 0.0;

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
            columnCount: 1,
            itemCount: itemCount,
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
                columnCount: columnCount,
                itemCount: itemCount,
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
    int columnCount = 1,
    int itemCount = 0,
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

    // Explicit row navigation. Default directional focus traversal becomes
    // unreliable while items are mounting/unmounting under fast scrolling and
    // can spuriously jump to overlay widgets like the floating chips header.
    VoidCallback? navigateUp;
    if (isFirstRow) {
      navigateUp = _navigateToChips;
    } else if (columnCount > 0 && index >= columnCount) {
      navigateUp = () => _focusGridItem(index - columnCount);
    }

    VoidCallback? navigateDown;
    if (columnCount > 0 && index + columnCount < itemCount) {
      navigateDown = () => _focusGridItem(index + columnCount);
    }

    VoidCallback? navigateLeft;
    if (isFirstColumn) {
      navigateLeft = _navigateToSidebar;
    } else if (index > 0) {
      navigateLeft = () => _focusGridItem(index - 1);
    }

    VoidCallback? navigateRight;
    if (isLastColumn && _shouldShowAlphaJumpBar && !_isPhone(context)) {
      navigateRight = _navigateToAlphaJumpBar;
    } else if (!isLastColumn && index + 1 < itemCount) {
      navigateRight = () => _focusGridItem(index + 1);
    }

    return FocusableMediaCard(
      key: Key(item.id),
      item: item,
      focusNode: focusNode,
      disableScale: disableScale,
      onRefresh: updateItem,
      onNavigateUp: navigateUp,
      onNavigateDown: navigateDown,
      onNavigateLeft: navigateLeft,
      onNavigateRight: navigateRight,
      onBack: widget.onBack,
      onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
      onListRefresh: _loadItems,
    );
  }

  /// Move focus to the grid item at [targetIndex] (or its skeleton's row).
  /// Used by the explicit dpad navigation handlers.
  void _focusGridItem(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= totalSize) return;
    final node = targetIndex == 0 ? firstItemFocusNode : getGridItemFocusNode(targetIndex, prefix: 'browse_grid_item');
    if (node.context != null) {
      node.requestFocus();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) node.requestFocus();
      });
    }
  }
}

/// SliverPersistentHeader delegate for the chips bar. Fixed-height floating
/// header that snaps in on scroll direction reversal.
class _ChipsBarDelegate extends SliverPersistentHeaderDelegate {
  final WidgetBuilder builder;
  final double height;

  const _ChipsBarDelegate({required this.builder, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(height: height, child: builder(context));
  }

  @override
  bool shouldRebuild(covariant _ChipsBarDelegate oldDelegate) =>
      builder != oldDelegate.builder || height != oldDelegate.height;
}
