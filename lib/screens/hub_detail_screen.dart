import 'dart:async';

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
import '../utils/grid_size_calculator.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import '../widgets/focusable_media_card.dart';
import '../widgets/ios_status_bar_tap_scroll_to_top.dart';
import '../widgets/media_grid_delegate.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/loading_indicator_box.dart';
import '../widgets/overlay_sheet.dart';
import '../focus/focusable_action_bar.dart';
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
  final VoidCallback? onRemoveFromContinueWatching;

  const HubDetailScreen({
    super.key,
    required this.hub,
    this.loadItems,
    this.isInContinueWatching = false,
    this.onRemoveFromContinueWatching,
  });

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
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _continuationErrorMessage;
  int? _continuationOffset;
  int? _continuationTotal;
  int _loadGeneration = 0;

  /// Key for getting a context below OverlaySheetHost
  final GlobalKey _overlayChildKey = GlobalKey();

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
      // - home.recent / library.<id>.continue (Jellyfin synthesized)
      final hubKey = widget.hub.id;
      appLogger.d('Hub key: $hubKey');

      RegExpMatch? match = RegExp(r'/hubs/sections/(\d+)').firstMatch(hubKey);
      match ??= RegExp(r'/library/sections/(\d+)').firstMatch(hubKey);
      match ??= RegExp(r'sections/(\d+)').firstMatch(hubKey);

      if (match != null) {
        final sectionId = match.group(1)!;
        appLogger.d('Loading sorts for section: $sectionId');

        final client = context.tryGetMediaClientForServer(serverId);
        final sorts = client == null ? const <MediaSort>[] : await client.fetchSortOptions(sectionId);

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

  List<MediaSort> _getDefaultSortOptions() {
    return [
      MediaSort(key: 'titleSort', title: t.hubDetail.title, defaultDirection: 'asc'),
      MediaSort(key: 'year', descKey: 'year:desc', title: t.hubDetail.releaseYear, defaultDirection: 'desc'),
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
    final generation = ++_loadGeneration;

    final serverId = widget.hub.serverId;
    if (widget.loadItems == null && serverId == null) {
      appLogger.w('Hub has no serverId; cannot load more items for ${widget.hub.id}');
      return;
    }

    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _errorMessage = null;
      _continuationErrorMessage = null;
      _continuationOffset = null;
      _continuationTotal = null;
    });

    try {
      final loader = widget.loadItems;
      final client = serverId == null ? null : context.tryGetMediaClientForServer(serverId);
      final List<MediaItem> items;
      int totalCount;
      int loadedCount;
      if (loader == null) {
        final page = client == null
            ? const LibraryPage<MediaItem>(items: [], totalCount: 0)
            : await client.fetchMoreHubItemsPage(widget.hub.id, start: 0, size: _pageSize);
        items = _applySectionFilter(page.items);
        totalCount = page.totalCount;
        loadedCount = page.items.length;
      } else {
        items = _applySectionFilter(await loader());
        totalCount = items.length;
        loadedCount = items.length;
      }

      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _items = items;
        _filteredItems = items;
        _isLoading = false;
      });

      _applySort();
      if (loader == null && client != null && loadedCount < totalCount) {
        if (client.backend == MediaBackend.plex) {
          unawaited(_loadFullHubContent(client, generation));
        } else {
          unawaited(_loadRemainingHubPages(client, generation, loadedCount, totalCount));
        }
      }

      appLogger.d('Loaded ${items.length} items for hub: ${widget.hub.title}');
    } catch (e) {
      appLogger.e('Failed to load hub content', error: e);
      if (!mounted) return;
      setState(() {
        _errorMessage = t.messages.errorLoading(error: e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFullHubContent(MediaServerClient client, int generation) async {
    if (mounted && generation == _loadGeneration) {
      setState(() {
        _isLoadingMore = true;
        _continuationErrorMessage = null;
      });
    }

    try {
      final items = _applySectionFilter(await client.fetchMoreHubItems(widget.hub.id));
      if (!mounted || generation != _loadGeneration) return;
      if (items.isEmpty && _items.isNotEmpty) {
        throw StateError('Hub continuation returned no items');
      }
      setState(() {
        _items = items;
        _filteredItems = items;
        _isLoadingMore = false;
        _continuationErrorMessage = null;
        _continuationOffset = null;
        _continuationTotal = null;
      });
      _applySort();
    } catch (e, st) {
      appLogger.w('Failed to finish loading hub content', error: e, stackTrace: st);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoadingMore = false;
        _continuationErrorMessage = t.messages.errorLoading(error: e.toString());
      });
    }
  }

  Future<void> _loadRemainingHubPages(MediaServerClient client, int generation, int startOffset, int totalCount) async {
    var offset = startOffset;
    var total = totalCount;
    if (mounted && generation == _loadGeneration) {
      setState(() {
        _isLoadingMore = true;
        _continuationErrorMessage = null;
        _continuationOffset = offset;
        _continuationTotal = total;
      });
    }
    try {
      while (offset < total) {
        final page = await client.fetchMoreHubItemsPage(widget.hub.id, start: offset, size: _pageSize);
        if (!mounted || generation != _loadGeneration) return;
        if (page.items.isEmpty) break;
        final items = _applySectionFilter(page.items);
        setState(() {
          _items.addAll(items);
          _filteredItems = List.of(_items);
        });
        _applySort();
        offset += page.items.length;
        total = page.totalCount;
        _continuationOffset = offset;
        _continuationTotal = total;
      }
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoadingMore = false;
        _continuationErrorMessage = null;
        _continuationOffset = null;
        _continuationTotal = null;
      });
    } catch (e, st) {
      appLogger.w('Failed to finish loading hub content', error: e, stackTrace: st);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _isLoadingMore = false;
        _continuationErrorMessage = t.messages.errorLoading(error: e.toString());
        _continuationOffset = offset;
        _continuationTotal = total;
      });
    }
  }

  void _retryHubContinuation() {
    final serverId = widget.hub.serverId;
    final client = serverId == null ? null : context.tryGetMediaClientForServer(serverId);
    if (client == null || _isLoadingMore) return;
    final generation = _loadGeneration;
    if (client.backend == MediaBackend.plex) {
      unawaited(_loadFullHubContent(client, generation));
      return;
    }
    final offset = _continuationOffset;
    final total = _continuationTotal;
    if (offset == null || total == null) return;
    unawaited(_loadRemainingHubPages(client, generation, offset, total));
  }

  List<MediaItem> _applySectionFilter(List<MediaItem> items) {
    final sectionFilter = int.tryParse(widget.hub.libraryId ?? '');
    if (sectionFilter == null) return items;
    return items.where((item) => int.tryParse(item.libraryId ?? '') == sectionFilter).toList();
  }

  Future<void> _handleItemRefresh(String ratingKey) async {
    final itemIndex = _items.indexWhere((item) => item.id == ratingKey);
    final filteredIndex = _filteredItems.indexWhere((item) => item.id == ratingKey);
    final existing = itemIndex != -1
        ? _items[itemIndex]
        : filteredIndex != -1
        ? _filteredItems[filteredIndex]
        : null;
    if (existing == null) return;
    final serverId = existing.serverId ?? widget.hub.serverId;
    if (serverId == null) return;

    try {
      final updated = await context.tryGetMediaClientForServer(serverId)?.fetchItem(ratingKey);
      if (updated == null || !mounted) return;
      setState(() {
        final currentItemIndex = _items.indexWhere((item) => item.id == ratingKey);
        if (currentItemIndex != -1) _items[currentItemIndex] = updated;
        final currentFilteredIndex = _filteredItems.indexWhere((item) => item.id == ratingKey);
        if (currentFilteredIndex != -1) _filteredItems[currentFilteredIndex] = updated;
      });
      if (_selectedSort != null) _applySort();
    } catch (e) {
      appLogger.d('Item refresh skipped for: $ratingKey', error: e);
    }
  }

  void _handleRemoveFromContinueWatching() {
    widget.onRemoveFromContinueWatching?.call();
    unawaited(_loadMoreItems());
  }

  Widget _buildContinuationStatusSliver() {
    final error = _continuationErrorMessage;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: error == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _retryHubContinuation, child: Text(t.common.retry)),
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
    return PopScope(
      canPop: PlatformDetector.isHandheldIOS(context),
      onPopInvokedWithResult: (didPop, _) {
        if (BackKeyCoordinator.consumeIfHandled()) return;
        if (didPop) return;
        final shouldPop = handleBackNavigation();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: PrimaryScrollController(
        controller: scrollController,
        child: IosStatusBarTapScrollToTop(
          controller: scrollController,
          child: OverlaySheetHost(
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
                      ],
                      builder: (context) {
                        final svc = SettingsService.instanceOrNull!;
                        final isListMode = svc.read(SettingsService.viewMode) == ViewMode.list;
                        final episodePosterMode = svc.read(SettingsService.episodePosterMode);
                        final libraryDensity = svc.read(SettingsService.libraryDensity);

                        // Determine hub content type for layout decisions
                        final hasEpisodes = _filteredItems.any((item) => item.usesWideAspectRatio(episodePosterMode));
                        final hasNonEpisodes = _filteredItems.any(
                          (item) => !item.usesWideAspectRatio(episodePosterMode),
                        );

                        // Mixed hub = has both episodes AND non-episodes
                        final isMixedHub = hasEpisodes && hasNonEpisodes;

                        // Episode-only = all items are episodes with thumbnails
                        final isEpisodeOnlyHub = hasEpisodes && !hasNonEpisodes;

                        // Use 16:9 for episode-only hubs OR mixed hubs (with episode thumbnail mode)
                        final useWideLayout =
                            episodePosterMode == EpisodePosterMode.episodeThumbnail && (isEpisodeOnlyHub || isMixedHub);

                        if (isListMode) {
                          return SliverPadding(
                            padding: const EdgeInsets.all(8),
                            sliver: SliverList.builder(
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                final focusNode = _focusNodeForIndex(index);

                                return FocusableMediaCard(
                                  focusNode: focusNode,
                                  item: item,
                                  disableScale: true,
                                  onRefresh: _handleItemRefresh,
                                  onRemoveFromContinueWatching: widget.isInContinueWatching
                                      ? _handleRemoveFromContinueWatching
                                      : null,
                                  isInContinueWatching: widget.isInContinueWatching,
                                  onNavigateUp: index == 0 ? navigateToAppBar : null,
                                  onBack: handleBackFromContent,
                                  onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
                                  mixedHubContext: isMixedHub,
                                );
                              },
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.all(8),
                          sliver: SliverLayoutBuilder(
                            builder: (context, constraints) {
                              final maxExtent = GridSizeCalculator.getMaxCrossAxisExtentWithPadding(
                                context,
                                libraryDensity,
                                16,
                              );
                              final columnCount = GridSizeCalculator.getColumnCount(
                                constraints.crossAxisExtent,
                                useWideLayout ? maxExtent * 1.8 : maxExtent,
                              );

                              return SliverGrid(
                                gridDelegate: MediaGridDelegate.createDelegate(
                                  context: context,
                                  density: libraryDensity,
                                  usePaddingAware: true,
                                  horizontalPadding: 16,
                                  useWideAspectRatio: useWideLayout,
                                ),
                                delegate: SliverChildBuilderDelegate((context, index) {
                                  final item = _filteredItems[index];
                                  final focusNode = _focusNodeForIndex(index);
                                  final isFirstRow = GridSizeCalculator.isFirstRow(index, columnCount);
                                  final isFirstColumn = GridSizeCalculator.isFirstColumn(index, columnCount);

                                  return FocusableMediaCard(
                                    focusNode: focusNode,
                                    item: item,
                                    onRefresh: _handleItemRefresh,
                                    onRemoveFromContinueWatching: widget.isInContinueWatching
                                        ? _handleRemoveFromContinueWatching
                                        : null,
                                    isInContinueWatching: widget.isInContinueWatching,
                                    onNavigateUp: isFirstRow ? navigateToAppBar : null,
                                    onNavigateLeft: isFirstColumn ? () {} : null,
                                    onBack: handleBackFromContent,
                                    onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
                                    mixedHubContext: isMixedHub,
                                  );
                                }, childCount: _filteredItems.length),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  if (_filteredItems.isNotEmpty && (_isLoadingMore || _continuationErrorMessage != null))
                    _buildContinuationStatusSliver(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
