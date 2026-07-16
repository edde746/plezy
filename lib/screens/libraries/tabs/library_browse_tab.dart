import 'dart:async';
import '../../../media/ids.dart';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../media/library_first_character.dart';
import '../../../media/library_query.dart';
import '../../../media/media_backend.dart';
import '../../../media/media_item.dart';
import '../../../media/media_kind.dart';
import '../../../providers/multi_server_provider.dart';
import '../../../utils/media_server_http_client.dart';
import '../../../focus/dpad_navigator.dart';
import '../../../focus/input_mode_tracker.dart';
import '../../../media/media_filter.dart';
import '../../../media/media_sort.dart';
import '../../../widgets/settings_builder.dart';
import '../../../services/library_query_translator.dart';
import '../../../services/plex_constants.dart';
import '../../../utils/error_message_utils.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/grid_size_calculator.dart';
import '../../../utils/layout_constants.dart';
import '../../../utils/media_image_helper.dart';
import '../../../utils/provider_extensions.dart';
import '../alpha_jump_bar.dart';
import '../alpha_jump_helper.dart';
import '../alpha_scroll_handle.dart';
import '../library_browse_grouping.dart';
import '../library_alpha_bar_strategy.dart';
import '../library_alpha_scroll_metrics.dart';
import '../library_filter_sort_loader.dart';
import '../../../widgets/focusable_media_card.dart';
import '../../../widgets/focusable_filter_chip.dart';
import '../../../widgets/listenable_selector.dart';
import '../../../widgets/loading_indicator_box.dart';
import '../../../widgets/media_card_sliver_layout.dart';
import '../../../widgets/media_card_list_layout.dart';
import '../../../widgets/bottom_sheet_page_scaffold.dart';
import '../../../widgets/overlay_sheet.dart';
import '../../../mixins/library_tab_focus_mixin.dart';
import '../../../services/plex_client.dart';
import '../folder_tree_view.dart';
import '../filters_bottom_sheet.dart';
import '../sort_bottom_sheet.dart';
import '../../../widgets/app_icon.dart';
import '../../../widgets/focusable_list_tile.dart';
import '../content_state_builder.dart';
import '../../../services/storage_service.dart';
import '../../../services/settings_service.dart';
import '../../../mixins/grid_focus_node_mixin.dart';
import '../../../mixins/item_updatable.dart';
import '../../../mixins/watch_state_aware.dart';
import '../../../mixins/deletion_aware.dart';
import '../../../mixins/paginated_item_loader.dart';
import '../../../widgets/card_inflation_budget.dart';
import '../../../widgets/skeleton_media_card.dart';
import '../../../widgets/sliver_child_memo.dart';
import '../../../utils/deletion_notifier.dart';
import '../../../utils/global_key_utils.dart';
import '../../../utils/watch_state_notifier.dart';
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

  /// Notifies the parent when the active-filter state changes so the app
  /// bar can badge the Library options action on mobile.
  final ValueChanged<bool>? onFiltersActiveChanged;
  final bool canGroupByFolders;

  const LibraryBrowseTab({
    super.key,
    required super.library,
    required this.canGroupByFolders,
    super.viewMode,
    super.density,
    super.onDataLoaded,
    super.isActive,
    super.suppressAutoFocus,
    super.onBack,
    this.onResetScroll,
    this.onFiltersActiveChanged,
  });

  @override
  State<LibraryBrowseTab> createState() => _LibraryBrowseTabState();
}

class _LibraryBrowseTabState extends BaseLibraryTabState<MediaItem, LibraryBrowseTab>
    with
        ItemUpdatable,
        LibraryTabFocusMixin,
        GridFocusNodeMixin,
        WatchStateAware,
        DeletionAware,
        PaginatedItemLoader<MediaItem, LibraryBrowseTab>,
        SkeletonUpgradeScheduler {
  String _toGlobalKey(String ratingKey, {required ServerId serverId}) => buildGlobalKey(serverId, ratingKey);

  @override
  String? get deletionServerId => widget.library.serverId;

  @override
  String? get watchStateServerId => widget.library.serverId;

  @override
  Set<String>? get watchedIds => loadedItems.values.map((e) => e.id).toSet();

  @override
  Set<String>? get watchedGlobalKeys {
    if (loadedItems.isEmpty) return <String>{};

    final keys = <String>{};
    for (final item in loadedItems.values) {
      final serverId = serverIdOrNull(item.serverId ?? widget.library.serverId);
      if (serverId == null) return null;
      keys.add(_toGlobalKey(item.id, serverId: serverId));
    }
    return keys;
  }

  @override
  Set<String>? get deletionIds => loadedItems.values.map((e) => e.id).toSet();

  @override
  Set<String>? get deletionGlobalKeys {
    if (loadedItems.isEmpty) return <String>{};

    final keys = <String>{};
    for (final item in loadedItems.values) {
      final serverId = serverIdOrNull(item.serverId ?? widget.library.serverId);
      if (serverId == null) return null;
      keys.add(_toGlobalKey(item.id, serverId: serverId));
    }
    return keys;
  }

  @override
  void onWatchStateChanged(WatchStateEvent event) {
    if (event.changeType == WatchStateChangeType.progressUpdate ||
        event.changeType == WatchStateChangeType.removedFromContinueWatching) {
      return;
    }

    final affectedIds = {event.itemId, ...event.parentChain};
    for (final item in loadedItems.values) {
      if (affectedIds.contains(item.id)) {
        unawaited(updateItem(item));
      }
    }
  }

  @override
  void onDeletionEvent(DeletionEvent event) {
    // Browse is online-only (the Libraries tab is hidden when offline), so it
    // always reflects server-side content. A download-only deletion removes
    // local files but leaves the item on the server, so it must not affect the
    // browse grid. Without this guard, deleting every downloaded episode of a
    // show drives its leafCount to zero and evicts the show from browse.
    if (event.isDownloadOnly) return;

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
  void updateItemInLists(String sourceGlobalKey, MediaItem updatedMetadata) {
    for (final entry in loadedItems.entries) {
      if (entry.value.globalKey == sourceGlobalKey) {
        loadedItems[entry.key] = updatedMetadata;
        break;
      }
    }
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
  late LibraryAlphaBarStrategy _alphaStrategy = _createAlphaStrategy();

  /// On Jellyfin libraries the alpha bar acts as a filter (matches the
  /// JF web client's UX). Holds the active letter (`#`, `A`–`Z`) or null
  /// when no filter is applied.
  String? _jellyfinAlphaPrefix;

  /// Pre-fetched filter values for Jellyfin libraries — populated by
  /// `_loadContent` and consumed by the FiltersBottomSheet so the sheet
  /// doesn't need to call back into a Plex client for value listings.
  Map<String, List<MediaFilterValue>> _jellyfinFilterValues = const {};
  final ValueNotifier<int> _currentFirstVisibleIndex = ValueNotifier<int>(0);
  LibraryAlphaScrollMetrics _scrollMetrics = LibraryAlphaScrollMetrics.empty;

  /// Reuses card widgets across delegate swaps so tab-level setStates
  /// (pagination, watch state, deletions) don't rebuild every realized card
  /// inside grid layout.
  final SliverChildMemo<MediaItem> _cardMemo = SliverChildMemo<MediaItem>();

  /// Shared by focus-node eviction and card-memo pruning so the memo can
  /// never outlive the focus nodes its cached cards capture.
  static const int _focusNodeKeepCount = 200;
  double _effectiveTopPadding = _gridTopPadding;
  final GlobalKey _firstListItemKey = GlobalKey(debugLabel: 'first_library_list_item');
  double? _measuredListRowHeight;
  int? _listMetricsDensity;
  bool? _listMetricsUsesWideRatio;
  CardShape? _listMetricsShape;
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
  static const int _jellyfinFetchSize = 72;
  Timer? _scrollIdleTimer;
  bool _rangeLoadScheduled = false;
  bool _topScrollResetScheduled = false;

  LibraryAlphaBarStrategy _createAlphaStrategy() {
    final library = widget.library;
    return LibraryAlphaBarStrategy.forBackend(
      library.backend,
      // Resolved on demand and only invoked by [PlexAlphaBarStrategy], which is
      // only constructed when the library's backend is Plex — the bang is safe.
      plexClientProvider: () {
        final manager = context.read<MultiServerProvider>().serverManager;
        final serverId = serverIdOrNull(library.serverId);
        if (serverId == null) throw StateError('Plex library ${library.id} is missing a serverId');
        return manager.getPlexClient(serverId)!;
      },
      libraryKey: library.id,
      isShared: library.isShared,
    );
  }

  @override
  void didUpdateWidget(covariant LibraryBrowseTab oldWidget) {
    // BaseLibraryTabState reloads during super.didUpdateWidget; refresh this
    // first so first-character requests target the new backend/library.
    if (oldWidget.library.globalKey != widget.library.globalKey ||
        oldWidget.library.id != widget.library.id ||
        oldWidget.library.backend != widget.library.backend ||
        oldWidget.library.serverId != widget.library.serverId ||
        oldWidget.library.isShared != widget.library.isShared) {
      _alphaStrategy = _createAlphaStrategy();
    }
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canGroupByFolders != widget.canGroupByFolders) {
      final normalized = _normalizeGrouping(_selectedGrouping);
      if (normalized != _selectedGrouping) {
        _selectedGrouping = normalized;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(_loadItems());
          unawaited(_loadFirstCharacters());
        });
      }
    }
  }

  bool get _isJellyfinLibrary => widget.library.backend == MediaBackend.jellyfin;
  int get _activeFetchSize => _isJellyfinLibrary ? _jellyfinFetchSize : _fetchSize;

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
    if (widget.isActive && hasLoadedData && !hasFocused) {
      hasFocused = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) focusContentOrChrome();
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

  bool get _hasFocusableStateAction =>
      (errorMessage != null && loadedItems.isEmpty) || (totalSize == 0 && !isLoading && _selectedFilters.isNotEmpty);

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

    if (loadedItems.isNotEmpty || _hasFocusableStateAction) {
      // Request immediately, then once more on the next frame to handle cases
      // where the grid/list attaches after the initial focus attempt.
      void request() {
        if (mounted && (loadedItems.isNotEmpty || _hasFocusableStateAction) && !firstItemFocusNode.hasFocus) {
          firstItemFocusNode.requestFocus();
        }
      }

      request();
      WidgetsBinding.instance.addPostFrameCallback((_) => request());
    }
  }

  @override
  bool get hasFocusableContent => _selectedGrouping == 'folders' || loadedItems.isNotEmpty || _hasFocusableStateAction;

  @override
  void focusContentOrChrome() {
    if (hasFocusableContent) {
      focusFirstItem();
    } else {
      focusChipsBar();
    }
  }

  /// Height of the chips bar (padding + chip + padding)
  static const double _chipsBarHeight = 32.0;

  /// Focus the chips bar (for navigating from tab bar to content).
  /// Called by libraries screen when pressing DOWN on tab bar.
  void focusChipsBar() {
    if (_usesMobileBrowseOptions) {
      focusFirstItem();
      return;
    }
    lastFocusedGridIndex = null;
    _groupingChipFocusNode.requestFocus();
  }

  /// Show the mobile browse options sheet from the parent app bar.
  void showBrowseOptionsSheet() {
    if (!mounted) return;
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    final controller = OverlaySheetController.of(context);
    controller.show(showDragHandle: true, builder: (sheetContext) => _buildBrowseOptionsSheet(sheetContext));
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
    _measuredListRowHeight = null;

    // The browse tab state is kept alive across libraries, so ensure this
    // tab's scroll resets to 0 (other tabs keep their own positions). Defer
    // the jump because library changes call this from didUpdateWidget; jumping
    // there dispatches scroll notifications while the AppBar is building.
    _scheduleTopScrollReset();
  }

  void _scheduleTopScrollReset() {
    if (_topScrollResetScheduled) return;
    _topScrollResetScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _topScrollResetScheduled = false;
      if (!mounted) return;

      final pos = _innerPosition;
      if (pos != null && pos.hasPixels && pos.pixels != 0) {
        pos.jumpTo(0);
      }

      // Inner-only resets bypass NestedScrollView's natural delta surrender,
      // leaving the outer floating header in its prior partially-hidden state.
      widget.onResetScroll?.call();
    });
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
    final client = context.getMediaClientForLibrary(widget.library);
    final loader = LibraryFilterSortLoader(clientFor: (_) => client);

    try {
      final storage = await StorageService.getInstance();
      final savedFilters = storage.getLibraryFilters(sectionId: widget.library.globalKey);
      final savedSort = storage.getLibrarySort(widget.library.globalKey);
      final savedGrouping = storage.getLibraryGrouping(widget.library.globalKey);
      // Resolve the restored grouping before the sort fetch — music groupings
      // (albums/tracks) request their own per-type sort list.
      final restoredGrouping = _normalizeGrouping(savedGrouping);
      final sortLibraryType = _sortOptionsLibraryType(restoredGrouping);

      final LoadedFiltersAndSorts loaded;
      if (_isJellyfinLibrary) {
        // `/Items/Filters` can be much slower than the paged `/Items` browse
        // request on large Jellyfin libraries. Load only the local sort list
        // before page 1, then fill filter values in the background.
        final sorts = await client.fetchSortOptions(widget.library.id, libraryType: sortLibraryType);
        loaded = LoadedFiltersAndSorts(filters: const [], sorts: sorts);
      } else {
        // Plex filters+sorts must resolve before items so saved-sort restoration
        // can match a saved key against the just-loaded sort list, and so the
        // first item fetch already includes the restored sort param.
        loaded = await loader.load(widget.library, sortLibraryType: sortLibraryType);
      }

      if (generation != _contentRequestId || !mounted) return;
      setState(() {
        _filters = loaded.filters;
        _sortOptions = loaded.sorts;
        // Plex returns no cached values (filters fetched lazily per-category);
        // assigning the empty map is a no-op for Plex and a real payload for Jellyfin.
        _jellyfinFilterValues = loaded.cachedValues;
        _selectedFilters = Map.from(savedFilters);
        _selectedGrouping = restoredGrouping;

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
      _notifyFiltersActive();

      if (_isJellyfinLibrary) {
        _loadJellyfinFiltersInBackground(generation);
      }

      // Load items and first characters in parallel
      // _loadItems manages its own requestId internally
      await Future.wait([_loadItems(), _loadFirstCharacters(requestId: firstCharactersGeneration)]);
    } catch (e, stackTrace) {
      if (!mounted) return;
      final message = localizedLoadErrorMessage(e, stackTrace, context: t.libraries.content);
      setState(() {
        errorMessage = message;
        isLoading = false;
      });
    }
  }

  void _loadJellyfinFiltersInBackground(int generation) {
    final client = context.getMediaClientForLibrary(widget.library);
    unawaited(
      client
          .fetchLibraryFiltersWithValues(widget.library.id, libraryKind: widget.library.kind)
          .then((result) {
            if (generation != _contentRequestId || !mounted) return;
            setState(() {
              _filters = result.filters;
              _jellyfinFilterValues = result.cachedValues;
            });
          })
          .catchError((Object e, StackTrace st) {
            appLogger.w('Jellyfin library filters failed; browse content remains available', error: e, stackTrace: st);
          }),
    );
  }

  /// Reports `_selectedFilters.isNotEmpty` to the parent post-frame, since
  /// filter state also mutates during load paths driven by initState /
  /// didUpdateWidget where a synchronous parent setState would throw.
  void _notifyFiltersActive() {
    final cb = widget.onFiltersActiveChanged;
    if (cb == null) return;
    final active = _selectedFilters.isNotEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) cb(active);
    });
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
      _jellyfinFilterValues = const {};
      _jellyfinAlphaPrefix = null;
      _selectedFilters = {};
      _selectedSort = null;
      _isSortDescending = false;
      _selectedGrouping = _getDefaultGrouping();
      _firstCharacters = [];
      _alphaHelper = AlphaJumpHelper(const []);
      _scrollMetrics = LibraryAlphaScrollMetrics.empty;
      _measuredListRowHeight = null;
    });
    _notifyFiltersActive();
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

  Future<void> _loadItems({bool preserveFocus = false}) async {
    final generation = _contentRequestId;
    setState(() {
      isLoading = true;
      items = [];
      resetPaginationState();
      // Increment content version when loading fresh content
      // This invalidates the last focused index
      gridContentVersion++;
      cleanupGridFocusNodes(0);
      // All focus nodes were just disposed; cached cards captured them.
      _cardMemo.clear();
    });

    try {
      final initialPage = await loadInitialPageWithStatus(_calculateInitialFetchSize());

      if (!initialPage.applied || generation != _contentRequestId || !mounted) return;
      setState(() {
        isLoading = false;
      });

      hasLoadedData = true;
      if (!preserveFocus) {
        tryFocus();
      }

      // Notify parent
      if (!preserveFocus && widget.onDataLoaded != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onDataLoaded!();
        });
      }
    } catch (e, stackTrace) {
      if (generation != _contentRequestId || !mounted) return;
      final message = localizedLoadErrorMessage(e, stackTrace, context: t.libraries.content);
      setState(() {
        errorMessage = message;
        isLoading = false;
      });
    }
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPage(int start, int size, AbortController? abort) async {
    final client = context.getMediaClientForLibrary(widget.library);
    final filterParams = _buildFilterParams();
    final query = libraryQueryFromPlexMap(
      map: filterParams,
      libraryKind: filterParams.containsKey('type') ? null : widget.library.kind,
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
    return defaultLibraryBrowseGrouping(widget.library, canGroupByFolders: widget.canGroupByFolders);
  }

  String _normalizeGrouping(String? grouping) {
    return normalizeLibraryBrowseGrouping(widget.library, grouping, canGroupByFolders: widget.canGroupByFolders);
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
      case 'artists':
        return '8';
      case 'albums':
        return '9';
      case 'tracks':
        return '10';
      default:
        return '';
    }
  }

  /// `libraryType` for sort-option fetches. Plex music sections serve a
  /// distinct sort list per type (`?type=9|10` for albums/tracks), so the
  /// active grouping picks the type; every other grouping shares the
  /// library's own list.
  String _sortOptionsLibraryType(String grouping) {
    return switch (grouping) {
      browseGroupingAlbums => MediaKind.album.id,
      browseGroupingTracks => MediaKind.track.id,
      _ => widget.library.kind.id,
    };
  }

  List<String> _getGroupingOptions() {
    return libraryBrowseGroupingOptions(widget.library, canGroupByFolders: widget.canGroupByFolders);
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
      case 'artists':
        return t.libraries.groupings.artists;
      case 'albums':
        return t.libraries.groupings.albums;
      case 'tracks':
        return t.libraries.groupings.tracks;
      case 'folders':
        return t.libraries.groupings.folders;
      default:
        return t.libraries.groupings.all;
    }
  }

  Widget _buildBrowseOptionsSheet(BuildContext sheetContext) {
    final controller = OverlaySheetController.of(sheetContext);
    return BottomSheetPageScaffold(
      title: t.libraries.libraryOptions,
      icon: Symbols.tune_rounded,
      shrinkWrap: true,
      child: ListView(
        primary: false,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          FocusableListTile(
            leading: const AppIcon(Symbols.category_rounded, fill: 1),
            title: Text(t.libraries.groupings.title),
            subtitle: Text(_getGroupingLabel(_selectedGrouping)),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showGroupingOptionsPage(controller),
          ),
          if (_isFiltersChipVisible)
            FocusableListTile(
              leading: const AppIcon(Symbols.filter_alt_rounded, fill: 1),
              title: Text(
                _selectedFilters.isEmpty
                    ? t.libraries.filters
                    : t.libraries.filtersWithCount(count: _selectedFilters.length),
              ),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () => _showFiltersOptionsPage(controller),
            ),
          if (_isSortChipVisible)
            FocusableListTile(
              leading: const AppIcon(Symbols.sort_rounded, fill: 1),
              title: Text(t.libraries.sort),
              subtitle: _selectedSort == null ? null : Text(_selectedSort!.title),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () => _showSortOptionsPage(controller),
            ),
        ],
      ),
    );
  }

  void _showGroupingBottomSheet() {
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    final controller = OverlaySheetController.of(context);
    controller
        .show<String>(
          showDragHandle: true,
          builder: (sheetContext) => Column(
            mainAxisSize: .min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  t.libraries.groupings.title,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: .min, children: _buildGroupingTiles((value) => controller.close(value))),
                ),
              ),
            ],
          ),
        )
        .then(_handleGroupingSelection);
  }

  void _showGroupingOptionsPage(OverlaySheetController controller) {
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    controller
        .push<String>(
          builder: (_) =>
              _buildGroupingBottomSheet(onBack: () => controller.pop(), onSelected: (value) => controller.close(value)),
        )
        .then(_handleGroupingSelection);
  }

  Widget _buildGroupingBottomSheet({required ValueChanged<String> onSelected, VoidCallback? onBack}) {
    return BottomSheetPageScaffold(
      title: t.libraries.groupings.title,
      icon: Symbols.category_rounded,
      onBack: onBack,
      shrinkWrap: true,
      child: ListView(
        primary: false,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _buildGroupingTiles(onSelected),
      ),
    );
  }

  List<Widget> _buildGroupingTiles(ValueChanged<String> onSelected) {
    final options = _getGroupingOptions();
    return options.map((grouping) {
      final isSelected = _selectedGrouping == grouping;
      return FocusableListTile(
        key: ValueKey(grouping),
        dense: true,
        leading: AppIcon(
          isSelected ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
          fill: 1,
        ),
        title: Text(_getGroupingLabel(grouping)),
        onTap: () => onSelected(grouping),
      );
    }).toList();
  }

  void _handleGroupingSelection(String? value) {
    if (!mounted || value == null || value == _selectedGrouping || !_getGroupingOptions().contains(value)) return;
    final sortTypeChanged = _sortOptionsLibraryType(value) != _sortOptionsLibraryType(_selectedGrouping);
    setState(() {
      _selectedGrouping = value;
    });
    StorageService.getInstance().then((storage) {
      storage.saveLibraryGrouping(widget.library.globalKey, value);
    });
    if (sortTypeChanged) {
      // Music groupings serve per-type sort lists; refresh the options (and
      // drop a selected sort the new list doesn't offer) before fetching
      // items so the first page can't carry a sort key of the wrong type.
      unawaited(_reloadSortOptionsForGrouping());
      return;
    }
    _loadItems();
    _loadFirstCharacters();
  }

  /// Re-fetch the sort options for the just-selected grouping's type, then
  /// load items. Only called when the grouping switch changed the sort type
  /// (artist/album/track on music libraries).
  Future<void> _reloadSortOptionsForGrouping() async {
    final generation = _contentRequestId;
    final grouping = _selectedGrouping;
    var sorts = const <MediaSort>[];
    try {
      final client = context.getMediaClientForLibrary(widget.library);
      sorts = await client.fetchSortOptions(widget.library.id, libraryType: _sortOptionsLibraryType(grouping));
    } catch (e, st) {
      appLogger.w('Failed to load sort options for grouping $grouping', error: e, stackTrace: st);
    }
    if (!mounted || generation != _contentRequestId || grouping != _selectedGrouping) return;
    setState(() {
      _sortOptions = sorts;
      if (_selectedSort != null && sorts.every((s) => s.key != _selectedSort!.key)) {
        _selectedSort = null;
        _isSortDescending = false;
      }
    });
    unawaited(_loadItems());
    unawaited(_loadFirstCharacters());
  }

  void _showFiltersBottomSheet() {
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    OverlaySheetController.of(context).show(builder: (_) => _buildFiltersBottomSheet());
  }

  void _showFiltersOptionsPage(OverlaySheetController controller) {
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    controller.push(builder: (_) => _buildFiltersBottomSheet(onBack: () => controller.pop()));
  }

  Widget _buildFiltersBottomSheet({VoidCallback? onBack}) {
    return FiltersBottomSheet(
      filters: _filters,
      selectedFilters: _selectedFilters,
      serverId: widget.library.serverId!,
      libraryKey: widget.library.globalKey,
      loadFilterValues: _loadFilterValues,
      onBack: onBack,
      // Pre-populated values arrive only from backends that bundle them
      // with the category listing (Jellyfin's `/Items/Filters`). The empty
      // map for Plex libraries falls through to lazy `getFilterValues`.
      cachedValues: _jellyfinFilterValues.isEmpty ? null : _jellyfinFilterValues,
      onFiltersChanged: _applyFilters,
    );
  }

  Future<void> _applyFilters(Map<String, String> filters) async {
    setState(() {
      _selectedFilters.clear();
      _selectedFilters.addAll(filters);
    });
    _notifyFiltersActive();

    // Save filters to storage
    final storage = await StorageService.getInstance();
    await storage.saveLibraryFilters(filters, sectionId: widget.library.globalKey);

    unawaited(_loadItems());
    unawaited(_loadFirstCharacters());
  }

  void _resetFilters() => unawaited(_applyFilters(const {}));

  Future<List<MediaFilterValue>> _loadFilterValues(MediaFilter filter) async {
    if (!mounted) return const [];

    final client = context.tryGetMediaClientForServer(serverIdOrNull(widget.library.serverId));
    if (client is PlexClient) return client.getFilterValues(filter.key);

    // Jellyfin's canonical filter values come from the cached `/Items/Filters`
    // payload. If that payload missed a category, there is no neutral endpoint
    // to query yet, so return an empty list instead of routing to a Plex-only API.
    return const [];
  }

  void _showSortBottomSheet() {
    final controller = OverlaySheetController.of(context);
    _openSortBottomSheet((builder) => controller.show(builder: builder));
  }

  void _showSortOptionsPage(OverlaySheetController controller) {
    _openSortBottomSheet((builder) => controller.push(builder: builder), onBack: () => controller.pop());
  }

  void _openSortBottomSheet(Future<dynamic> Function(WidgetBuilder builder) open, {VoidCallback? onBack}) {
    SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
    // Track pending state in local variables so the callbacks don't trigger
    // setState/_loadItems while the sheet is open (which would steal focus).
    MediaSort? pendingSort = _selectedSort;
    bool pendingDescending = _isSortDescending;
    bool pendingCleared = false;
    open(
      (context) => SortBottomSheet(
        sortOptions: _sortOptions,
        selectedSort: _selectedSort,
        isSortDescending: _isSortDescending,
        onBack: onBack,
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
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

    if (totalSize == 0 && !_hasFocusableStateAction) return;

    final targetIndex = totalSize == 0
        ? 0
        : shouldRestoreGridFocus && lastFocusedGridIndex! < totalSize && loadedItems.containsKey(lastFocusedGridIndex!)
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
    final columnCount = _scrollMetrics.columnCount;
    if (totalSize == 0 || columnCount < 1) return;

    final row = _currentFirstVisibleIndex.value ~/ columnCount;
    var targetIndex = ((row + 1) * columnCount - 1).clamp(0, totalSize - 1);

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

  /// Navigate focus from grid up to the chips bar, or the tab bar on mobile.
  void _navigateToChips() {
    if (_usesMobileBrowseOptions) {
      widget.onBack?.call();
      return;
    }
    _groupingChipFocusNode.requestFocus();
  }

  /// Navigate focus to the sidebar
  void _navigateToSidebar() {
    MainScreenFocusScope.focusSidebarOf(context);
  }

  /// Navigate focus to the alpha jump bar
  void _navigateToAlphaJumpBar() {
    _alphaJumpBarFocusNode.requestFocus();
  }

  /// Whether the device is a phone (not tablet/desktop/TV).
  bool _isPhone(BuildContext context) => PlatformDetector.isPhone(context);

  /// Mobile uses a top-bar options action instead of inline browse chips.
  bool get _usesMobileBrowseOptions => PlatformDetector.isMobile(context);

  /// The letter currently visible at the top of the grid, determined by
  /// how many items we've scrolled past relative to the API's cumulative
  /// firstCharacter counts.
  String _alphaLetterFor(int index) =>
      _alphaStrategy.currentLetter(index, _alphaHelper, jellyfinAlphaPrefix: _jellyfinAlphaPrefix);

  /// Whether the alpha jump bar should be shown.
  /// Only shown when sorting by title (titleSort) and not in folders mode.
  bool get _isTitleSortDescending {
    if (!_isSortDescending) return false;
    final key = _selectedSort?.key.toLowerCase();
    if (key == null || key.isEmpty) return false;
    return key == 'title' || key == 'name' || key == 'sortname' || key.startsWith('titlesort');
  }

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
        descending: _isTitleSortDescending,
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
        ensureRangeLoaded(range.firstIndex, range.visibleCount, buffer: _activeFetchSize ~/ 2);
        evictDistantItems(range.firstIndex, maxKeep: 500, threshold: 600);
        evictDistantFocusNodes(range.firstIndex, keepCount: _focusNodeKeepCount);
        // Cached card widgets capture their focus node — drop them in lockstep
        // with node eviction so a cache hit can't resurrect a disposed node.
        _cardMemo.removeOutsideRange(range.firstIndex, halfWindow: _focusNodeKeepCount ~/ 2);
      }
    });

    // Eager prefetch: fetch data before scroll stops
    final range = _computeVisibleRange();
    if (range != null) {
      prefetchAhead(range.firstIndex, range.visibleCount, pageSize: _activeFetchSize);
    }

    if (!_shouldShowAlphaJumpBar || !_scrollMetrics.isUsable) return;

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
    final lastInRow = (firstInRow + _scrollMetrics.columnCount - 1).clamp(0, maxIndex);
    if (lastInRow != _currentFirstVisibleIndex.value) {
      _currentFirstVisibleIndex.value = lastInRow;
    }
  }

  /// Compute the first visible item index from a scroll offset.
  /// The inline chips bar, when present, is followed by the grid's own top
  /// padding before the first row.
  int _itemIndexFromScrollOffset(double offset) {
    return _scrollMetrics.itemIndexFromScrollOffset(
      offset,
      contentStartOffset: _contentStartScrollOffset,
      totalSize: totalSize,
    );
  }

  double get _contentStartScrollOffset => (_usesMobileBrowseOptions ? 0.0 : _chipsBarHeight) + _effectiveTopPadding;

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

  /// Scroll the current layout so the item at [targetIndex] becomes the first visible
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
    _scheduleTopScrollReset();
    _loadItems(preserveFocus: _alphaJumpBarFocusNode.hasFocus && nextPrefix != null);
  }

  /// Scroll the current layout so that [index] is visible just below the chrome.
  void _scrollToItemIndex(int index) {
    final pos = _innerPosition;
    if (!_scrollMetrics.isUsable || pos == null) {
      _isJumpScrolling = false;
      return;
    }

    // Position the target row at the top of the viewport. Inline chips, when
    // present, and grid top padding both precede items in scroll coordinates.
    final offset = _scrollMetrics.scrollOffsetForItemIndex(index, contentStartOffset: _contentStartScrollOffset);

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

    // The alpha jump bar is the only overlay; we offset it by the typical app
    // bar height so it isn't obscured by the floating outer header. Using
    // MediaQuery (not the absorber handle) avoids rebuilding during layout —
    // listening to the handle from a builder fires notifyListeners during the
    // build phase and triggers a setState-in-build assertion.
    final overlayTopPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Stack(
      children: [
        Positioned.fill(child: _buildScrollableContent()),
        if (_shouldShowAlphaJumpBar)
          Positioned(
            top: overlayTopPadding,
            right: 0,
            bottom: 0,
            // Select the derived letter rather than listening to the raw
            // index: the index changes every scrolled row, but the bar only
            // needs a rebuild when the letter itself flips.
            child: _isPhone(context)
                ? ListenableSelector<String>(
                    listenable: _currentFirstVisibleIndex,
                    selector: () => _alphaLetterFor(_currentFirstVisibleIndex.value),
                    builder: (context, currentLetter, _) => ValueListenableBuilder<bool>(
                      valueListenable: _isScrollActive,
                      builder: (context, scrolling, _) => AlphaScrollHandle(
                        firstCharacters: _firstCharacters,
                        onJump: _jumpToIndex,
                        currentLetter: currentLetter,
                        descending: _isTitleSortDescending,
                        isScrolling: scrolling,
                      ),
                    ),
                  )
                : ListenableSelector<String>(
                    listenable: _currentFirstVisibleIndex,
                    selector: () => _alphaLetterFor(_currentFirstVisibleIndex.value),
                    builder: (context, currentLetter, _) => AlphaJumpBar(
                      firstCharacters: _firstCharacters,
                      onJump: _jumpToIndex,
                      currentLetter: currentLetter,
                      descending: _isTitleSortDescending,
                      focusNode: _alphaJumpBarFocusNode,
                      onNavigateLeft: _navigateToGridNearScroll,
                      onBack: _navigateToGridNearScroll,
                    ),
                  ),
          ),
      ],
    );
  }

  /// Builds the scrollable content with optional chips, then folder tree or grid/list.
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
            if (!_usesMobileBrowseOptions)
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
        ensureRangeLoaded(range.firstIndex, range.visibleCount, buffer: _activeFetchSize ~/ 2);
      }
    });
  }

  /// Returns the first-visible index and visible count from the scroll
  /// position + layout metrics, or null if the viewport isn't measured yet.
  ({int firstIndex, int visibleCount})? _computeVisibleRange() {
    final pos = _innerPosition;
    if (!_scrollMetrics.isUsable || pos == null) return null;
    final offset = pos.pixels;
    final viewportHeight = pos.viewportDimension;
    if (!viewportHeight.isFinite) return null;

    final visibleCount = _scrollMetrics.visibleItemCount(viewportHeight);
    if (visibleCount <= 0) return null;
    return (firstIndex: _itemIndexFromScrollOffset(offset), visibleCount: visibleCount);
  }

  /// Compute initial fetch size based on viewport dimensions.
  int _calculateInitialFetchSize() {
    try {
      final screenSize = MediaQuery.sizeOf(context);
      final density = context.settingsRead(SettingsService.libraryDensity);
      final maxExtent = GridSizeCalculator.getMaxCrossAxisExtent(context, density);
      final columnCount = GridSizeCalculator.getColumnCount(screenSize.width, maxExtent);
      final itemWidth = screenSize.width / columnCount;
      final itemHeight = itemWidth / GridLayoutConstants.posterAspectRatio;
      final rowHeight = itemHeight + GridLayoutConstants.mainAxisSpacing;
      if (rowHeight <= 0) return _activeFetchSize;
      final visibleRows = (screenSize.height / rowHeight).ceil() + 1;
      final visibleCount = visibleRows * columnCount;
      if (_isJellyfinLibrary) {
        return (visibleCount * 2).clamp(36, _jellyfinFetchSize).toInt();
      }
      return (visibleCount * 3).clamp(100, 500).toInt();
    } catch (_) {
      return _activeFetchSize;
    }
  }

  /// Prefetch images for items near the viewport to reduce pop-in.
  void _prefetchImages(int startIndex, List<MediaItem> items) {
    final pos = _innerPosition;
    if (pos == null || !_scrollMetrics.isUsable) return;

    final offset = pos.pixels;
    final viewportHeight = pos.viewportDimension;
    if (!viewportHeight.isFinite) return;
    final firstVisible = _itemIndexFromScrollOffset(offset);
    final itemWidth = _scrollMetrics.itemWidth;
    final itemHeight = _scrollMetrics.itemHeight;
    if (itemWidth <= 0 || itemHeight <= 0) return;

    final visibleEnd = firstVisible + _scrollMetrics.visibleItemCount(viewportHeight);
    // Prefetch 2 rows beyond visible area
    final prefetchEnd = visibleEnd + 2 * _scrollMetrics.columnCount;

    final client = getMediaClientForLibrary();
    final devicePixelRatio = MediaImageHelper.effectiveDevicePixelRatio(context);
    final episodePosterMode = context.settingsRead(SettingsService.episodePosterMode);

    for (var i = 0; i < items.length; i++) {
      final index = startIndex + i;
      if (index < firstVisible || index > prefetchEnd) continue;

      final item = items[i];
      final thumb = item.posterThumb(mode: episodePosterMode);
      if (thumb == null || thumb.isEmpty) continue;
      final imageType = MediaImageHelper.cardImageType(item, episodePosterMode);

      final imageUrl = MediaImageHelper.getOptimizedImageUrl(
        client: client,
        thumbPath: thumb,
        maxWidth: itemWidth,
        maxHeight: itemHeight,
        devicePixelRatio: devicePixelRatio,
        imageType: imageType,
      );
      if (imageUrl.isEmpty) continue;

      final scaledWidth = itemWidth * devicePixelRatio;
      final scaledHeight = itemHeight * devicePixelRatio;
      final (memWidth, memHeight) = MediaImageHelper.getMemCacheDimensions(
        displayWidth: scaledWidth.isFinite && scaledWidth > 0 ? scaledWidth.round() : 0,
        displayHeight: scaledHeight.isFinite && scaledHeight > 0 ? scaledHeight.round() : 0,
        imageType: imageType,
      );

      precacheImage(
        MediaImageHelper.serverArtworkProvider(imageUrl: imageUrl, memWidth: memWidth, memHeight: memHeight),
        context,
      ).ignore();
    }
  }

  /// Whether the filters chip is visible
  bool get _isFiltersChipVisible =>
      (_filters.isNotEmpty || _selectedFilters.isNotEmpty) && _selectedGrouping != 'folders';

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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: .centerLeft,
      child: Row(
        mainAxisSize: .min,
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
          libraryKind: widget.library.kind,
          onRefresh: updateItem,
          firstItemFocusNode: firstItemFocusNode,
          onNavigateUp: _navigateToChips,
          onNavigateLeft: _navigateToSidebar,
          onBack: widget.onBack,
        ),
      ];
    }

    if (isLoading && totalSize == 0 && loadedItems.isEmpty) {
      return [LoadingIndicatorBox.sliver];
    }

    if (errorMessage != null && loadedItems.isEmpty) {
      return [
        SliverErrorState(
          message: errorMessage!,
          onRetry: _loadContent,
          actionFocusNode: firstItemFocusNode,
          onActionNavigateUp: _navigateToChips,
          onActionNavigateLeft: _navigateToSidebar,
          onActionBack: widget.onBack,
        ),
      ];
    }

    if (totalSize == 0 && !isLoading) {
      if (_selectedFilters.isNotEmpty) {
        return [
          SliverEmptyState(
            message: t.libraries.noItemsMatchFilters,
            icon: Symbols.filter_alt_off_rounded,
            onAction: _resetFilters,
            actionLabel: t.libraries.resetFilters,
            actionIcon: Symbols.clear_all_rounded,
            actionFocusNode: firstItemFocusNode,
            onActionNavigateUp: _navigateToChips,
            onActionNavigateLeft: _navigateToSidebar,
            onActionBack: widget.onBack,
          ),
        ];
      }
      return [SliverEmptyState(message: t.libraries.thisLibraryIsEmpty, icon: Symbols.folder_open_rounded)];
    }

    return [
      SettingsBuilder(
        prefs: const [
          SettingsService.viewMode,
          SettingsService.libraryDensity,
          SettingsService.episodePosterMode,
          SettingsService.tvFullCardLayout,
        ],
        builder: (context) => _buildItemsSliver(context),
      ),
    ];
  }

  // Top padding for grid content. Chips are inline above the grid now, so this
  // is purely focus-decoration clearance on desktop. Phone has no D-pad
  // focus ring so no extra clearance is needed.
  static const double _gridTopPadding = 6.0;
  static const double _gridTopPaddingPhone = 0.0;

  /// Width of the alpha jump bar widget
  static const double _alphaJumpBarWidth = 20.0;

  void _setListScrollMetrics({required int density, required bool usesWideAspectRatio, CardShape? shape}) {
    if (_listMetricsDensity != density ||
        _listMetricsUsesWideRatio != usesWideAspectRatio ||
        _listMetricsShape != shape) {
      _measuredListRowHeight = null;
      _listMetricsDensity = density;
      _listMetricsUsesWideRatio = usesWideAspectRatio;
      _listMetricsShape = shape;
    }

    final itemWidth = MediaCardListLayout.posterWidth(
      density: density,
      usesWideAspectRatio: usesWideAspectRatio,
      shape: shape,
    );
    final itemHeight = MediaCardListLayout.posterHeight(
      density: density,
      usesWideAspectRatio: usesWideAspectRatio,
      shape: shape,
    );
    final rowHeight =
        _measuredListRowHeight ??
        MediaCardListLayout.estimatedRowHeight(
          density: density,
          usesWideAspectRatio: usesWideAspectRatio,
          shape: shape,
        );
    _scrollMetrics = LibraryAlphaScrollMetrics(
      columnCount: 1,
      rowHeight: rowHeight,
      itemWidth: itemWidth,
      itemHeight: itemHeight,
    );
  }

  Widget _buildMeasuredFirstListItem(Widget child) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureFirstListRowHeight());
    return KeyedSubtree(key: _firstListItemKey, child: child);
  }

  void _measureFirstListRowHeight() {
    if (!mounted) return;
    if (SettingsService.instanceOrNull?.read(SettingsService.viewMode) != ViewMode.list) return;
    final height = (_firstListItemKey.currentContext?.findRenderObject() as RenderBox?)?.size.height;
    if (height == null || height <= 0) return;
    if ((_measuredListRowHeight ?? 0) == height) return;
    _measuredListRowHeight = height;
    _scrollMetrics = _scrollMetrics.copyWith(rowHeight: height);
    _updateVisibleIndex();
  }

  /// Builds either a sliver list or sliver grid based on the view mode
  Widget _buildItemsSliver(BuildContext context) {
    final svc = SettingsService.instance;
    final viewMode = svc.read(SettingsService.viewMode);
    final libraryDensity = svc.read(SettingsService.libraryDensity);
    final episodePosterMode = svc.read(SettingsService.episodePosterMode);
    final fullCardLayout = PlatformDetector.isTV() && svc.read(SettingsService.tvFullCardLayout);
    final itemCount = totalSize;
    final isPhone = _isPhone(context);
    final topPadding = isPhone ? _gridTopPaddingPhone : _gridTopPadding;
    _effectiveTopPadding = topPadding;
    final rightPadding = _shouldShowAlphaJumpBar && !isPhone ? _alphaJumpBarWidth : 8.0;

    final useWideRatio = _selectedGrouping == 'episodes' && episodePosterMode == EpisodePosterMode.episodeThumbnail;
    // Music groupings are homogeneous, so the whole grid shares the square
    // cell shape (artists render circular inside the square cell).
    final isMusicGrouping =
        _selectedGrouping == browseGroupingArtists ||
        _selectedGrouping == browseGroupingAlbums ||
        _selectedGrouping == browseGroupingTracks;
    final browseShape = isMusicGrouping ? CardShape.square : null;
    // Full-bleed TV cards intentionally hide captions. Music artwork alone
    // is not a reliable identity, so artist/album/track grids always keep the
    // standard captioned card while preserving their circular/square artwork.
    final useFullCardLayout = fullCardLayout && !isMusicGrouping;

    if (viewMode == ViewMode.list) {
      _setListScrollMetrics(density: libraryDensity, usesWideAspectRatio: useWideRatio, shape: browseShape);
    }

    final hasAlphaBarReservation = rightPadding > 8.0;
    return MediaCardSliverLayout(
      viewMode: viewMode,
      itemCount: itemCount,
      density: libraryDensity,
      padding: EdgeInsets.fromLTRB(8, topPadding, rightPadding, 8),
      useWideAspectRatio: useWideRatio,
      shape: browseShape,
      fullBleedImage: useFullCardLayout,
      crossAxisExtentForColumnCount: hasAlphaBarReservation
          ? (crossAxisExtent) => crossAxisExtent + (rightPadding - 8.0)
          : null,
      onGridGeometry: (geometry) {
        _scrollMetrics = LibraryAlphaScrollMetrics(
          columnCount: geometry.columnCount,
          rowHeight: geometry.itemHeight + geometry.spacing,
          itemWidth: geometry.itemWidth,
          itemHeight: geometry.itemHeight,
        );
      },
      listEpoch: (ViewMode.list, itemCount, libraryDensity, useWideRatio, _shouldShowAlphaJumpBar, isPhone),
      gridEpochBuilder: (geometry) => (
        ViewMode.grid,
        geometry.columnCount,
        itemCount,
        useFullCardLayout,
        useWideRatio,
        browseShape,
        libraryDensity,
        _shouldShowAlphaJumpBar,
        isPhone,
      ),
      itemBuilder: (context, position) {
        final index = position.index;
        final item = loadedItems[index];
        if (item == null) {
          _scheduleRangeLoad();
          return const SkeletonMediaCard();
        }

        if (!position.isGrid) {
          final child = _cardMemo.widgetFor(
            index,
            item,
            epoch: position.layoutEpoch!,
            build: () => _buildMediaCardItem(
              index,
              isFirstRow: position.isFirstRow,
              isFirstColumn: true,
              isLastColumn: true,
              disableScale: true,
              columnCount: 1,
              itemCount: itemCount,
            ),
          );
          return index == 0 ? _buildMeasuredFirstListItem(child) : child;
        }

        final cached = _cardMemo.tryGet(index, item, epoch: position.layoutEpoch!);
        if (cached != null) return cached;
        if (CardInflationBudget.isScrollingContext(context) &&
            !InputModeTracker.isKeyboardMode(context) &&
            !CardInflationBudget.tryTake()) {
          scheduleSkeletonUpgrade();
          return const SkeletonMediaCard();
        }
        return _cardMemo.widgetFor(
          index,
          item,
          epoch: position.layoutEpoch!,
          build: () => _buildMediaCardItem(
            index,
            isFirstRow: position.isFirstRow,
            isFirstColumn: position.isFirstColumn,
            isLastColumn: position.isLastColumn,
            columnCount: position.columnCount,
            itemCount: itemCount,
            fullBleedImage: useFullCardLayout,
          ),
        );
      },
    );
  }

  Widget _buildMediaCardItem(
    int index, {
    required bool isFirstRow,
    required bool isFirstColumn,
    bool isLastColumn = false,
    bool disableScale = false,
    bool fullBleedImage = false,
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
      fullBleedImage: fullBleedImage,
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
