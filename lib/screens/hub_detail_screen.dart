import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../services/plex_client.dart';
import '../models/plex_hub.dart';
import '../models/plex_metadata.dart';
import '../models/plex_sort.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../utils/provider_extensions.dart';
import '../utils/app_logger.dart';
import '../utils/grid_size_calculator.dart';
import '../widgets/focusable_media_card.dart';
import '../widgets/media_grid_delegate.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/overlay_sheet.dart';
import 'package:flutter/services.dart';
import '../focus/dpad_navigator.dart';
import '../focus/focus_theme.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import '../mixins/grid_focus_node_mixin.dart';
import 'libraries/sort_bottom_sheet.dart';
import 'libraries/state_messages.dart';
import '../mixins/refreshable.dart';
import '../i18n/strings.g.dart';

/// Screen to display full content of a recommendation hub
class HubDetailScreen extends StatefulWidget {
  final PlexHub hub;

  const HubDetailScreen({super.key, required this.hub});

  @override
  State<HubDetailScreen> createState() => _HubDetailScreenState();
}

class _HubDetailScreenState extends State<HubDetailScreen> with Refreshable, GridFocusNodeMixin {
  PlexClient get client => _getClientForHub();

  List<PlexMetadata> _items = [];
  List<PlexMetadata> _filteredItems = [];
  List<PlexSort> _sortOptions = [];
  PlexSort? _selectedSort;
  bool _isSortDescending = false;
  bool _isLoading = false;
  String? _errorMessage;

  late final FocusNode _firstItemFocusNode = FocusNode(debugLabel: 'hub_detail_first_item');
  late final FocusNode _sortButtonFocusNode = FocusNode(debugLabel: 'hub_detail_sort');
  bool _isAppBarFocused = false;
  bool _backHandledByKeyEvent = false;

  /// Key for getting a context below OverlaySheetHost
  final GlobalKey _overlayChildKey = GlobalKey();

  /// Get the correct PlexClient for this hub's server
  PlexClient _getClientForHub() {
    return context.getClientForServer(widget.hub.serverId!);
  }

  @override
  void initState() {
    super.initState();
    _sortButtonFocusNode.addListener(_onSortButtonFocusChange);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (InputModeTracker.isKeyboardMode(context) && _filteredItems.isNotEmpty) {
        _firstItemFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _sortButtonFocusNode.removeListener(_onSortButtonFocusChange);
    _firstItemFocusNode.dispose();
    _sortButtonFocusNode.dispose();
    disposeGridFocusNodes();
    super.dispose();
  }

  void _onSortButtonFocusChange() {
    if (!mounted) return;
    final hasFocus = _sortButtonFocusNode.hasFocus;
    if (hasFocus && !_isAppBarFocused) {
      setState(() => _isAppBarFocused = true);
    } else if (!hasFocus && _isAppBarFocused) {
      setState(() => _isAppBarFocused = false);
    }
  }

  void _focusGrid() {
    if (_filteredItems.isEmpty) return;
    final targetIndex =
        shouldRestoreGridFocus && lastFocusedGridIndex! < _filteredItems.length ? lastFocusedGridIndex! : 0;
    if (targetIndex == 0) {
      _firstItemFocusNode.requestFocus();
    } else {
      getGridItemFocusNode(targetIndex, prefix: 'hub_detail_item').requestFocus();
    }
  }

  void _navigateToAppBar() {
    setState(() => _isAppBarFocused = true);
    _sortButtonFocusNode.requestFocus();
  }

  void _handleBackFromContent() {
    _backHandledByKeyEvent = true;
    _navigateToAppBar();
  }

  KeyEventResult _handleSortButtonKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    final backResult = handleBackKeyAction(event, () => Navigator.pop(context));
    if (backResult != KeyEventResult.ignored) return backResult;

    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (key.isDownKey) {
      _focusGrid();
      return KeyEventResult.handled;
    }
    if (key.isSelectKey) {
      _showSortBottomSheet();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _loadSorts() async {
    try {
      final client = _getClientForHub();

      // Get the library key from the hub key
      // Hub keys can have various formats:
      // - /hubs/sections/1/...
      // - /library/sections/1/all?...
      final hubKey = widget.hub.hubKey;
      appLogger.d('Hub key: $hubKey');

      // Try different patterns
      RegExpMatch? match = RegExp(r'/hubs/sections/(\d+)').firstMatch(hubKey);
      match ??= RegExp(r'/library/sections/(\d+)').firstMatch(hubKey);
      match ??= RegExp(r'sections/(\d+)').firstMatch(hubKey);

      if (match != null) {
        final sectionId = match.group(1)!;
        appLogger.d('Loading sorts for section: $sectionId');

        // Load sorts for this library
        final sorts = await client.getLibrarySorts(sectionId);

        appLogger.d('Loaded ${sorts.length} sorts');

        if (!mounted) return;
        setState(() {
          _sortOptions = sorts.isNotEmpty ? sorts : _getDefaultSortOptions();
          // Don't set a default sort - let items stay in original order
        });
      } else {
        appLogger.w('Could not extract section ID from hub key: $hubKey');
        // Provide default sort options even if we can't get library-specific ones
        if (!mounted) return;
        setState(() {
          _sortOptions = _getDefaultSortOptions();
          // Don't set a default sort - let items stay in original order
        });
      }
    } catch (e) {
      appLogger.e('Failed to load sorts', error: e);
      // Provide default sort options on error
      if (!mounted) return;
      setState(() {
        _sortOptions = _getDefaultSortOptions();
        // Don't set a default sort - let items stay in original order
      });
    }
  }

  List<PlexSort> _getDefaultSortOptions() {
    return [
      PlexSort(key: 'titleSort', title: t.hubDetail.title, defaultDirection: 'asc'),
      PlexSort(key: 'year', descKey: 'year:desc', title: t.hubDetail.releaseYear, defaultDirection: 'desc'),
      PlexSort(key: 'addedAt', descKey: 'addedAt:desc', title: t.hubDetail.dateAdded, defaultDirection: 'desc'),
      PlexSort(key: 'rating', descKey: 'rating:desc', title: t.hubDetail.rating, defaultDirection: 'desc'),
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
              comparison = a.title.compareTo(b.title);
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
              comparison = a.title.compareTo(b.title);
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = _getClientForHub();

      // Fetch items from the hub, tagged with server info at the source
      final items = await client.getHubContent(widget.hub.hubKey);

      if (!mounted) return;
      setState(() {
        _items = items;
        _filteredItems = items;
        _isLoading = false;
      });

      // Apply any existing sort
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
      final index = _items.indexWhere((item) => item.ratingKey == ratingKey);
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
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);
    final sortButtonFocused = isKeyboardMode && _isAppBarFocused;

    return PopScope(
      canPop: !isKeyboardMode || _isAppBarFocused,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _backHandledByKeyEvent) {
          _backHandledByKeyEvent = false;
          return;
        }
        _navigateToAppBar();
      },
      child: OverlaySheetHost(
        child: Scaffold(
          key: _overlayChildKey,
          body: CustomScrollView(
            clipBehavior: Clip.none,
            slivers: [
              CustomAppBar(
                title: Text(widget.hub.title),
                pinned: true,
                actions: [
                  Focus(
                    focusNode: _sortButtonFocusNode,
                    onKeyEvent: _handleSortButtonKeyEvent,
                    child: Container(
                      decoration: FocusTheme.focusBackgroundDecoration(isFocused: sortButtonFocused, borderRadius: 20),
                      child: IconButton(
                        icon: AppIcon(Symbols.swap_vert_rounded, fill: 1, semanticLabel: t.libraries.sort),
                        onPressed: _showSortBottomSheet,
                      ),
                    ),
                  ),
                ],
              ),
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

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
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
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = _filteredItems[index];
                                final focusNode = index == 0
                                    ? _firstItemFocusNode
                                    : getGridItemFocusNode(index, prefix: 'hub_detail_item');
                                final isFirstRow = GridSizeCalculator.isFirstRow(index, columnCount);
                                final isFirstColumn = GridSizeCalculator.isFirstColumn(index, columnCount);

                                return FocusableMediaCard(
                                  focusNode: focusNode,
                                  item: item,
                                  onRefresh: _handleItemRefresh,
                                  onNavigateUp: isFirstRow ? _navigateToAppBar : null,
                                  onNavigateLeft: isFirstColumn ? () {} : null,
                                  onBack: _handleBackFromContent,
                                  onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
                                  mixedHubContext: isMixedHub,
                                );
                              },
                              childCount: _filteredItems.length,
                            ),
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
