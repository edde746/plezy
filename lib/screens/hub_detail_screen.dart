import 'dart:async';
import '../media/catalog_item_ref.dart';
import '../media/ids.dart';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../media/library_query.dart';
import '../media/media_backend.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../media/media_sort.dart';
import '../services/settings_service.dart';
import '../widgets/settings_builder.dart';
import '../utils/app_logger.dart';
import '../utils/continuation_pagination_coordinator.dart';
import '../utils/error_message_utils.dart';
import '../utils/platform_detector.dart';
import '../utils/plex_library_section_utils.dart';
import '../utils/provider_extensions.dart';
import '../widgets/focusable_media_card.dart';
import '../widgets/media_card_sliver_layout.dart';
import '../widgets/ios_status_bar_tap_scroll_to_top.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/loading_indicator_box.dart';
import '../widgets/overlay_sheet.dart';
import '../focus/focusable_action_bar.dart';
import '../focus/focusable_button.dart';
import '../focus/key_event_utils.dart';
import '../mixins/grid_focus_node_mixin.dart';
import 'libraries/sort_bottom_sheet.dart';
import 'libraries/content_state_builder.dart';
import '../mixins/refreshable.dart';
import '../i18n/strings.g.dart';
import 'focusable_detail_screen_mixin.dart';

/// Screen to display full content of a recommendation hub
class HubDetailScreen extends StatefulWidget {
  final MediaHub hub;
  final Future<List<MediaItem>> Function()? loadItems;
  final bool isInContinueWatching;
  final bool usesContinueWatchingAction;
  final VoidCallback? onRemoveFromContinueWatching;

  const HubDetailScreen({
    super.key,
    required this.hub,
    this.loadItems,
    this.isInContinueWatching = false,
    bool? usesContinueWatchingAction,
    this.onRemoveFromContinueWatching,
  }) : usesContinueWatchingAction = usesContinueWatchingAction ?? isInContinueWatching;

  @override
  State<HubDetailScreen> createState() => _HubDetailScreenState();
}

class _HubDetailScreenState extends State<HubDetailScreen>
    with Refreshable, GridFocusNodeMixin, FocusableDetailScreenMixin {
  static const int _pageSize = 200;

  List<MediaItem> _items = [];
  List<MediaItem> _filteredItems = [];
  List<MediaSort> _sortOptions = [];
  MediaSort? _selectedSort;
  bool _isSortDescending = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _replaceContinuationItems = false;

  late final ContinuationPaginationCoordinator<MediaItem> _continuation = ContinuationPaginationCoordinator<MediaItem>(
    loadPage: _fetchContinuationPage,
    onPage: _applyContinuationPage,
    onStateChanged: _handleContinuationStateChanged,
    onError: (error, stackTrace) =>
        appLogger.w('Failed to finish loading hub content', error: error, stackTrace: stackTrace),
  );

  /// Key for getting a context below OverlaySheetHost
  final GlobalKey _overlayChildKey = GlobalKey();
  final FocusNode _continuationRetryFocusNode = FocusNode(debugLabel: 'hub_continuation_retry');

  @override
  bool get hasItems => _filteredItems.isNotEmpty;

  @override
  List<FocusableAction> getAppBarActions() {
    return [
      FocusableAction(icon: Symbols.swap_vert_rounded, tooltip: t.libraries.sort, onPressed: _showSortBottomSheet),
    ];
  }

  /// Override to add bounds check for filtered items (sorting can change item order)
  @override
  void navigateToGrid() {
    if (!hasItems) return;

    final targetIndex = shouldRestoreGridFocus && lastFocusedGridIndex! < _filteredItems.length
        ? lastFocusedGridIndex!
        : 0;

    setState(() {
      isAppBarFocused = false;
    });

    _focusNodeForIndex(targetIndex).requestFocus();
  }

  FocusNode _focusNodeForIndex(int index) => focusNodeForIndex(index, firstItemFocusNode, prefix: 'hub_detail_item');

  @override
  void initState() {
    super.initState();
    _items = widget.hub.items;
    _filteredItems = widget.hub.items;
    if (widget.hub.more) {
      _loadMoreItems();
    }
    _loadSorts();
    autoFocusFirstItemAfterLoad();
  }

  @override
  void dispose() {
    _continuation.dispose();
    _continuationRetryFocusNode.dispose();
    disposeFocusResources();
    super.dispose();
  }

  Future<void> _loadSorts() async {
    try {
      final serverId = widget.hub.serverId;
      if (serverId == null) {
        appLogger.w('Hub has no serverId; using default sort options');
        if (!mounted) return;
        setState(() {
          _sortOptions = _getDefaultSortOptions();
        });
        return;
      }

      // Hub ids can have various formats:
      // - /hubs/sections/1/... (Plex)
      // - /library/sections/1/all?... (Plex)
      // - /hubs/home/recentlyAdded?type=2&sectionID=1 (Plex home hubs — id in query)
      // - home.recent / library.<id>.continue (Jellyfin synthesized)
      final hubKey = widget.hub.id;
      appLogger.d('Hub key: $hubKey');

      final sectionId = plexLibrarySectionIdFromString(hubKey);

      if (sectionId != null) {
        appLogger.d('Loading sorts for section: $sectionId');

        final client = context.tryGetMediaClientForServer(ServerId(serverId));
        final sorts = client == null ? const <MediaSort>[] : await client.fetchSortOptions('$sectionId');

        appLogger.d('Loaded ${sorts.length} sorts');

        if (!mounted) return;
        setState(() {
          _sortOptions = sorts.isNotEmpty ? sorts : _getDefaultSortOptions();
        });
      } else {
        appLogger.w('Could not extract section ID from hub key: $hubKey');
        if (!mounted) return;
        setState(() {
          _sortOptions = _getDefaultSortOptions();
        });
      }
    } catch (e) {
      appLogger.e('Failed to load sorts', error: e);
      if (!mounted) return;
      setState(() {
        _sortOptions = _getDefaultSortOptions();
      });
    }
  }

  /// Catalog hubs (Explore View All) hold synthesized items with no library
  /// timestamps, so a Date Added sort would silently no-op — offer only the
  /// fields those items carry.
  bool get _isCatalogHub => widget.hub.items.firstOrNull?.isCatalogItem ?? false;

  List<MediaSort> _getDefaultSortOptions() {
    return [
      MediaSort(key: 'titleSort', title: t.hubDetail.title, defaultDirection: 'asc'),
      MediaSort(key: 'year', descKey: 'year:desc', title: t.hubDetail.releaseYear, defaultDirection: 'desc'),
      if (!_isCatalogHub)
        MediaSort(key: 'addedAt', descKey: 'addedAt:desc', title: t.hubDetail.dateAdded, defaultDirection: 'desc'),
      MediaSort(key: 'rating', descKey: 'rating:desc', title: t.hubDetail.rating, defaultDirection: 'desc'),
    ];
  }

  void _applySort() {
    setState(() {
      _filteredItems = List.from(_items);

      // Apply sorting
      if (_selectedSort != null) {
        final sortKey = _selectedSort!.key;
        _filteredItems.sort((a, b) {
          int comparison = 0;

          switch (sortKey) {
            case 'titleSort':
            case 'title':
              comparison = (a.title ?? '').compareTo(b.title ?? '');
              break;
            case 'addedAt':
              comparison = (a.addedAt ?? 0).compareTo(b.addedAt ?? 0);
              break;
            case 'originallyAvailableAt':
            case 'year':
              comparison = (a.year ?? 0).compareTo(b.year ?? 0);
              break;
            case 'rating':
              comparison = (a.rating ?? 0).compareTo(b.rating ?? 0);
              break;
            default:
              comparison = (a.title ?? '').compareTo(b.title ?? '');
          }

          return _isSortDescending ? -comparison : comparison;
        });
      }
    });
  }

  void _showSortBottomSheet() {
    final overlayContext = _overlayChildKey.currentContext ?? context;
    MediaSort? pendingSort = _selectedSort;
    bool pendingDescending = _isSortDescending;
    bool pendingCleared = false;
    OverlaySheetController.of(overlayContext)
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (pendingCleared) {
              _selectedSort = null;
              _isSortDescending = false;
              _applySort();
            } else if (pendingSort != null &&
                (pendingSort!.key != _selectedSort?.key || pendingDescending != _isSortDescending)) {
              _selectedSort = pendingSort;
              _isSortDescending = pendingDescending;
              _applySort();
            }
          });
        });
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading) return;

    final serverId = widget.hub.serverId;
    if (widget.loadItems == null && serverId == null) {
      appLogger.w('Hub has no serverId; cannot load more items for ${widget.hub.id}');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<MediaItem> items = const [];
      var totalCount = 0;
      var loadedCount = 0;
      var usesCustomLoader = false;
      MediaServerClient? client;
      final applied = await _continuation.runNewGeneration(() async {
        final loader = widget.loadItems;
        usesCustomLoader = loader != null;
        client = serverId == null ? null : context.tryGetMediaClientForServer(ServerId(serverId));
        if (loader == null) {
          final page = client == null
              ? const LibraryPage<MediaItem>(items: [], totalCount: 0)
              : await client!.fetchMoreHubItemsPage(widget.hub.id, start: 0, size: _pageSize);
          items = _applySectionFilter(page.items);
          totalCount = page.totalCount;
          loadedCount = page.items.length;
        } else {
          items = _applySectionFilter(await loader());
          totalCount = items.length;
          loadedCount = items.length;
        }
      });

      if (!mounted || !applied) return;
      setState(() {
        _items = List.of(items);
        _filteredItems = List.of(items);
        _isLoading = false;
      });

      _applySort();
      if (!usesCustomLoader && client != null && loadedCount < totalCount) {
        _replaceContinuationItems = client!.backend == MediaBackend.plex;
        if (_replaceContinuationItems) {
          _continuation.setContinuation(startIndex: 0, totalCount: 1);
        } else {
          _continuation.setContinuation(startIndex: loadedCount, totalCount: totalCount);
        }
        unawaited(_continuation.loadRemaining());
      }

      appLogger.d('Loaded ${items.length} items for hub: ${widget.hub.title}');
    } catch (e, stackTrace) {
      final message = localizedLoadErrorMessage(e, stackTrace, context: widget.hub.title);
      if (!mounted) return;
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Future<ContinuationPage<MediaItem>> _fetchContinuationPage(int startIndex) async {
    final serverId = widget.hub.serverId;
    final client = serverId == null ? null : context.tryGetMediaClientForServer(ServerId(serverId));
    if (client == null) throw StateError('No media client available for hub continuation');

    if (_replaceContinuationItems) {
      final items = _applySectionFilter(await client.fetchMoreHubItems(widget.hub.id));
      if (items.isEmpty && _items.isNotEmpty) {
        throw StateError('Hub continuation returned no items');
      }
      return ContinuationPage(items: items, totalCount: 1, consumedCount: 1);
    }

    final page = await client.fetchMoreHubItemsPage(widget.hub.id, start: startIndex, size: _pageSize);
    return ContinuationPage(
      items: _applySectionFilter(page.items),
      totalCount: page.totalCount,
      consumedCount: page.items.length,
    );
  }

  void _applyContinuationPage(ContinuationPage<MediaItem> page) {
    if (!mounted) return;
    setState(() {
      if (_replaceContinuationItems) {
        _items = List.of(page.items);
      } else {
        _items = List.of(_items)..addAll(page.items);
      }
      _filteredItems = List.of(_items);
    });
    _applySort();
  }

  void _handleContinuationStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _retryHubContinuation() => unawaited(_continuation.retry());

  List<MediaItem> _applySectionFilter(List<MediaItem> items) {
    final sectionFilter = int.tryParse(widget.hub.libraryId ?? '');
    if (sectionFilter == null) return items;
    return items.where((item) => int.tryParse(item.libraryId ?? '') == sectionFilter).toList();
  }

  Future<void> _handleItemRefresh(MediaItem source) async {
    final serverId = source.serverId;
    if (serverId == null) return;

    try {
      final updated = await context.tryGetMediaClientForServer(ServerId(serverId))?.fetchItem(source.id);
      if (updated == null || !mounted) return;
      setState(() {
        final currentItemIndex = _items.indexWhere((item) => item.globalKey == source.globalKey);
        if (currentItemIndex != -1) _items[currentItemIndex] = updated;
        final currentFilteredIndex = _filteredItems.indexWhere((item) => item.globalKey == source.globalKey);
        if (currentFilteredIndex != -1) _filteredItems[currentFilteredIndex] = updated;
      });
      if (_selectedSort != null) _applySort();
    } catch (e) {
      appLogger.d('Item refresh skipped for: ${source.globalKey}', error: e);
    }
  }

  void _handleRemoveFromContinueWatching() {
    widget.onRemoveFromContinueWatching?.call();
    unawaited(_loadMoreItems());
  }

  Widget _buildContinuationStatusSliver() {
    final exception = _continuation.error;
    final error = exception == null ? null : t.messages.errorLoading(error: exception.toString());
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: error == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: .min,
                  children: [
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    FocusableButton(
                      focusNode: _continuationRetryFocusNode,
                      onPressed: _retryHubContinuation,
                      onNavigateUp: () => _focusNodeForIndex(_filteredItems.length - 1).requestFocus(),
                      onBack: handleBackFromContent,
                      child: TextButton(onPressed: _retryHubContinuation, child: Text(t.common.retry)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  void refresh() {
    _loadMoreItems();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: scrollController,
      child: IosStatusBarTapScrollToTop(
        controller: scrollController,
        child: OverlaySheetHost(
          // Host owns sheet + system back: a back with a sheet open closes it;
          // otherwise focus the app bar first, then pop (handleBackNavigation).
          // canPop preserves the iOS interactive swipe-back.
          canPop: PlatformDetector.isHandheldIOS(context),
          onSystemBack: () {
            if (BackKeyCoordinator.consumeIfHandled()) return;
            if (handleBackNavigation() && mounted) Navigator.pop(context);
          },
          child: Scaffold(
            key: _overlayChildKey,
            body: CustomScrollView(
              primary: true,
              clipBehavior: Clip.none,
              slivers: [
                CustomAppBar(title: Text(widget.hub.title), pinned: true, actions: buildFocusableAppBarActions()),
                if (_errorMessage != null)
                  SliverErrorState(message: _errorMessage!, onRetry: _loadMoreItems)
                else if (_filteredItems.isEmpty && _isLoading)
                  LoadingIndicatorBox.sliver
                else if (_filteredItems.isEmpty)
                  SliverFillRemaining(child: Center(child: Text(t.hubDetail.noItemsFound)))
                else
                  SettingsBuilder(
                    prefs: const [
                      SettingsService.viewMode,
                      SettingsService.episodePosterMode,
                      SettingsService.libraryDensity,
                      SettingsService.tvFullCardLayout,
                    ],
                    builder: (context) {
                      final svc = SettingsService.instance;
                      final viewMode = svc.read(SettingsService.viewMode);
                      final episodePosterMode = svc.read(SettingsService.episodePosterMode);
                      final libraryDensity = svc.read(SettingsService.libraryDensity);
                      final fullCardLayout = PlatformDetector.isTV() && svc.read(SettingsService.tvFullCardLayout);

                      // Determine hub content type for layout decisions
                      final hasEpisodes = _filteredItems.any((item) => item.usesWideAspectRatio(episodePosterMode));
                      final hasNonEpisodes = _filteredItems.any((item) => !item.usesWideAspectRatio(episodePosterMode));

                      // Mixed hub = has both episodes AND non-episodes
                      final isMixedHub = hasEpisodes && hasNonEpisodes;

                      // Episode-only = all items are episodes with thumbnails
                      final isEpisodeOnlyHub = hasEpisodes && !hasNonEpisodes;

                      // Use 16:9 for episode-only hubs OR mixed hubs (with episode thumbnail mode)
                      final useWideLayout =
                          episodePosterMode == EpisodePosterMode.episodeThumbnail && (isEpisodeOnlyHub || isMixedHub);

                      // Music hubs render square album/artist artwork
                      final isSquareHub =
                          _filteredItems.isNotEmpty &&
                          _filteredItems.every((item) => item.cardShape(episodePosterMode) == CardShape.square);

                      return MediaCardSliverLayout(
                        viewMode: viewMode,
                        itemCount: _filteredItems.length,
                        density: libraryDensity,
                        padding: const EdgeInsets.all(8),
                        usePaddingAware: true,
                        horizontalPadding: 16,
                        useWideAspectRatio: useWideLayout,
                        fullBleedImage: fullCardLayout,
                        shape: isSquareHub ? CardShape.square : null,
                        itemBuilder: (context, position) {
                          final index = position.index;
                          final item = _filteredItems[index];
                          final focusNode = _focusNodeForIndex(index);

                          return FocusableMediaCard(
                            focusNode: focusNode,
                            item: item,
                            disableScale: position.disableScale,
                            onRefresh: _handleItemRefresh,
                            onRemoveFromContinueWatching: widget.isInContinueWatching
                                ? _handleRemoveFromContinueWatching
                                : null,
                            isInContinueWatching: widget.isInContinueWatching,
                            usesContinueWatchingAction: widget.usesContinueWatchingAction,
                            onNavigateUp: position.isFirstRow ? navigateToAppBar : null,
                            onNavigateDown:
                                _continuation.error != null &&
                                    position.index >= position.itemCount - position.columnCount
                                ? _continuationRetryFocusNode.requestFocus
                                : null,
                            onNavigateLeft: position.isGrid && position.isFirstColumn ? () {} : null,
                            onBack: handleBackFromContent,
                            onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
                            mixedHubContext: isMixedHub,
                            fullBleedImage: fullCardLayout && position.isGrid,
                          );
                        },
                      );
                    },
                  ),
                if (_filteredItems.isNotEmpty && (_continuation.isLoading || _continuation.error != null))
                  _buildContinuationStatusSliver(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
