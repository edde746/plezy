import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../client/plex_client.dart';
import '../models/plex_hub.dart';
import '../models/plex_metadata.dart';
import '../models/plex_sort.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../utils/provider_extensions.dart';
import '../utils/app_logger.dart';
import '../widgets/media_card.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/sort_bottom_sheet.dart';
import '../mixins/refreshable.dart';
import '../i18n/strings.g.dart';

/// Screen to display full content of a recommendation hub
class HubDetailScreen extends StatefulWidget {
  final PlexHub hub;

  const HubDetailScreen({super.key, required this.hub});

  @override
  State<HubDetailScreen> createState() => _HubDetailScreenState();
}

class _HubDetailScreenState extends State<HubDetailScreen> with Refreshable {
  PlexClient get client => context.clientSafe;

  List<PlexMetadata> _items = [];
  List<PlexMetadata> _filteredItems = [];
  List<PlexSort> _sortOptions = [];
  PlexSort? _selectedSort;
  bool _isSortDescending = false;
  bool _isLoading = false;
  String? _errorMessage;

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
  }

  Future<void> _loadSorts() async {
    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) return;

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

        setState(() {
          _sortOptions = sorts.isNotEmpty ? sorts : _getDefaultSortOptions();
          // Don't set a default sort - let items stay in original order
        });
      } else {
        appLogger.w('Could not extract section ID from hub key: $hubKey');
        // Provide default sort options even if we can't get library-specific ones
        setState(() {
          _sortOptions = _getDefaultSortOptions();
          // Don't set a default sort - let items stay in original order
        });
      }
    } catch (e) {
      appLogger.e('Failed to load sorts', error: e);
      // Provide default sort options on error
      setState(() {
        _sortOptions = _getDefaultSortOptions();
        // Don't set a default sort - let items stay in original order
      });
    }
  }

  List<PlexSort> _getDefaultSortOptions() {
    return [
      PlexSort(
        key: 'titleSort',
        title: t.hubDetail.title,
        defaultDirection: 'asc',
      ),
      PlexSort(
        key: 'year',
        descKey: 'year:desc',
        title: t.hubDetail.releaseYear,
        defaultDirection: 'desc',
      ),
      PlexSort(
        key: 'addedAt',
        descKey: 'addedAt:desc',
        title: t.hubDetail.dateAdded,
        defaultDirection: 'desc',
      ),
      PlexSort(
        key: 'rating',
        descKey: 'rating:desc',
        title: t.hubDetail.rating,
        defaultDirection: 'desc',
      ),
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
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        throw Exception('No client available');
      }

      // Fetch more items from the hub using the hubKey
      final response = await client.getHubContent(widget.hub.hubKey);

      setState(() {
        _items = response;
        _filteredItems = response;
        _isLoading = false;
      });

      // Apply any existing sort
      _applySort();

      appLogger.d(
        'Loaded ${response.length} items for hub: ${widget.hub.title}',
      );
    } catch (e) {
      appLogger.e('Failed to load hub content', error: e);
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: Text(widget.hub.title),
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(Icons.swap_vert, semanticLabel: t.libraries.sort),
                onPressed: _showSortBottomSheet,
              ),
            ],
          ),
          if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(_errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadMoreItems,
                      child: Text(t.common.retry),
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredItems.isEmpty && _isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredItems.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text(t.hubDetail.noItemsFound)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: _getMaxCrossAxisExtent(
                    context,
                    context.watch<SettingsProvider>().libraryDensity,
                  ),
                  childAspectRatio: 2 / 3.3,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return MediaCard(
                    item: _filteredItems[index],
                    onRefresh: _handleItemRefresh,
                  );
                }, childCount: _filteredItems.length),
              ),
            ),
        ],
      ),
    );
  }

  double _getMaxCrossAxisExtent(BuildContext context, LibraryDensity density) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 16.0; // 8px left + 8px right
    final availableWidth = screenWidth - padding;

    if (screenWidth >= 900) {
      // Wide screens (desktop/large tablet landscape): Responsive division
      double divisor;
      double maxItemWidth;

      switch (density) {
        case LibraryDensity.comfortable:
          divisor = 6.5;
          maxItemWidth = 280;
          break;
        case LibraryDensity.normal:
          divisor = 8.0;
          maxItemWidth = 200;
          break;
        case LibraryDensity.compact:
          divisor = 10.0;
          maxItemWidth = 160;
          break;
      }

      return (availableWidth / divisor).clamp(0, maxItemWidth);
    } else if (screenWidth >= 600) {
      // Medium screens (tablets): Fixed 4-5-6 items
      int targetItemCount = switch (density) {
        LibraryDensity.comfortable => 4,
        LibraryDensity.normal => 5,
        LibraryDensity.compact => 6,
      };
      return availableWidth / targetItemCount;
    } else {
      // Small screens (phones): Fixed 2-3-4 items
      int targetItemCount = switch (density) {
        LibraryDensity.comfortable => 2,
        LibraryDensity.normal => 3,
        LibraryDensity.compact => 4,
      };
      return availableWidth / targetItemCount;
    }
  }
}
