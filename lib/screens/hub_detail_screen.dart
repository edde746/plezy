import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_sort.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';
import '../utils/grid_size_calculator.dart';
import '../utils/provider_extensions.dart';
import '../widgets/focusable_media_card.dart';
import '../widgets/media_grid_delegate.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/overlay_sheet.dart';
import '../focus/focusable_action_bar.dart';
import '../focus/key_event_utils.dart';
import '../mixins/grid_focus_node_mixin.dart';
import 'libraries/sort_bottom_sheet.dart';
import 'libraries/state_messages.dart';
import '../mixins/refreshable.dart';
import '../i18n/strings.g.dart';
import 'focusable_detail_screen_mixin.dart';

/// Screen to display full content of a recommendation hub
class HubDetailScreen extends StatefulWidget {
  final MediaHub hub;

  const HubDetailScreen({super.key, required this.hub});

  @override
  State<HubDetailScreen> createState() => _HubDetailScreenState();
}

class _HubDetailScreenState extends State<HubDetailScreen>
    with Refreshable, GridFocusNodeMixin, FocusableDetailScreenMixin {
  List<MediaItem> _items = [];
  List<MediaItem> _filteredItems = [];
  List<MediaSort> _sortOptions = [];
  MediaSort? _selectedSort;
  bool _isSortDescending = false;
  bool _isLoading = false;
  String? _errorMessage;

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
    // Start with items already loaded in the hub
    _items = widget.hub.items;
    _filteredItems = widget.hub.items;
    // Load more items if available
    if (widget.hub.more) {
      _loadMoreItems();
    }
    // Load sorts based on the library type
    _loadSorts();
    // Auto-focus first grid item in keyboard mode after first frame
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
    OverlaySheetController.of(overlayContext).show(
      builder: (context) => SortBottomSheet(
        sortOptions: _sortOptions,
        selectedSort: _selectedSort,
        isSortDescending: _isSortDescending,
        onSortChanged: (sort, descending) {
          setState(() {
            _selectedSort = sort;
            _isSortDescending = descending;
          });
          _applySort();
        },
        onClear: () {
          setState(() {
            // Reset to no sorting (original order)
            _selectedSort = null;
            _isSortDescending = false;
          });
          _applySort();
        },
      ),
    );
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading) return;

    final serverId = widget.hub.serverId;
    if (serverId == null) {
      appLogger.w('Hub has no serverId; cannot load more items for ${widget.hub.id}');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = context.tryGetMediaClientForServer(serverId);
      var items = client == null ? const <MediaItem>[] : await client.fetchMoreHubItems(widget.hub.id);

      // Filter to specific library if this hub was split from a multi-library hub
      final sectionFilter = int.tryParse(widget.hub.libraryId ?? '');
      if (sectionFilter != null) {
        items = items.where((item) => int.tryParse(item.libraryId ?? '') == sectionFilter).toList();
      }

      if (!mounted) return;
      setState(() {
        _items = items;
        _filteredItems = items;
        _isLoading = false;
      });

      _applySort();

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

  void _handleItemRefresh(String ratingKey) {
    // Refresh the specific item in the list
    setState(() {
      final index = _items.indexWhere((item) => item.id == ratingKey);
      if (index != -1) {
        // The item will be refreshed by the MediaCard itself
        appLogger.d('Item refresh requested for: $ratingKey');
      }
    });
  }

  @override
  void refresh() {
    _loadMoreItems();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (BackKeyCoordinator.consumeIfHandled()) return;
        if (didPop) return;
        final shouldPop = handleBackNavigation();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: OverlaySheetHost(
        child: Scaffold(
          key: _overlayChildKey,
          body: CustomScrollView(
            controller: scrollController,
            clipBehavior: Clip.none,
            slivers: [
              CustomAppBar(title: Text(widget.hub.title), pinned: true, actions: buildFocusableAppBarActions()),
              if (_errorMessage != null)
                SliverFillRemaining(
                  child: ErrorStateWidget(
                    message: _errorMessage!,
                    icon: Symbols.error_outline_rounded,
                    onRetry: _loadMoreItems,
                  ),
                )
              else if (_filteredItems.isEmpty && _isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (_filteredItems.isEmpty)
                SliverFillRemaining(child: Center(child: Text(t.hubDetail.noItemsFound)))
              else
                Builder(
                  builder: (context) {
                    final settings = context.watch<SettingsProvider>();
                    final isListMode = settings.viewMode == ViewMode.list;
                    final episodePosterMode = settings.episodePosterMode;

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
                            settings.libraryDensity,
                            16,
                          );
                          final columnCount = GridSizeCalculator.getColumnCount(
                            constraints.crossAxisExtent,
                            useWideLayout ? maxExtent * 1.8 : maxExtent,
                          );

                          return SliverGrid(
                            gridDelegate: MediaGridDelegate.createDelegate(
                              context: context,
                              density: settings.libraryDensity,
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
            ],
          ),
        ),
      ),
    );
  }
}
