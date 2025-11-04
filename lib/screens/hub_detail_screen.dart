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
import '../mixins/refreshable.dart';

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
      
      RegExpMatch? match;
      
      // Try different patterns
      match = RegExp(r'/hubs/sections/(\d+)').firstMatch(hubKey);
      if (match == null) {
        match = RegExp(r'/library/sections/(\d+)').firstMatch(hubKey);
      }
      if (match == null) {
        match = RegExp(r'sections/(\d+)').firstMatch(hubKey);
      }
      
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
        title: 'Title',
        defaultDirection: 'asc',
      ),
      PlexSort(
        key: 'year',
        descKey: 'year:desc',
        title: 'Release Year',
        defaultDirection: 'desc',
      ),
      PlexSort(
        key: 'addedAt',
        descKey: 'addedAt:desc',
        title: 'Date Added',
        defaultDirection: 'desc',
      ),
      PlexSort(
        key: 'rating',
        descKey: 'rating:desc',
        title: 'Rating',
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
      builder: (context) => _SortBottomSheet(
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

      appLogger.d('Loaded ${response.length} items for hub: ${widget.hub.title}');
    } catch (e) {
      appLogger.e('Failed to load hub content', error: e);
      setState(() {
        _errorMessage = 'Failed to load content: $e';
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
          DesktopSliverAppBar(
            title: Text(widget.hub.title),
            floating: true,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.swap_vert, semanticLabel: 'Sort'),
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
                      child: const Text('Retry'),
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
            const SliverFillRemaining(
              child: Center(
                child: Text('No items found'),
              ),
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
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return MediaCard(
                      item: _filteredItems[index],
                      onRefresh: _handleItemRefresh,
                    );
                  },
                  childCount: _filteredItems.length,
                ),
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

// Bottom sheet for sorting
class _SortBottomSheet extends StatefulWidget {
  final List<PlexSort> sortOptions;
  final PlexSort? selectedSort;
  final bool isSortDescending;
  final Function(PlexSort, bool) onSortChanged;
  final VoidCallback onClear;

  const _SortBottomSheet({
    required this.sortOptions,
    required this.selectedSort,
    required this.isSortDescending,
    required this.onSortChanged,
    required this.onClear,
  });

  @override
  State<_SortBottomSheet> createState() => _SortBottomSheetState();
}

class _SortBottomSheetState extends State<_SortBottomSheet> {
  late PlexSort? _currentSort;
  late bool _currentDescending;

  @override
  void initState() {
    super.initState();
    _currentSort = widget.selectedSort;
    _currentDescending = widget.isSortDescending;
  }

  void _handleSortChange(PlexSort sort, bool descending) {
    setState(() {
      _currentSort = sort;
      _currentDescending = descending;
    });
    widget.onSortChanged(sort, descending);
  }

  void _handleClear() {
    setState(() {
      _currentSort = null;
      _currentDescending = false;
    });
    widget.onClear();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _handleClear,
                    child: const Text('Clear'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.sortOptions.length,
                itemBuilder: (context, index) {
                  final sort = widget.sortOptions[index];
                  final isSelected = _currentSort?.key == sort.key;

                  return ListTile(
                    title: Text(sort.title),
                    trailing: isSelected
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SegmentedButton<bool>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                    value: false,
                                    icon: Icon(Icons.arrow_upward, size: 16),
                                  ),
                                  ButtonSegment(
                                    value: true,
                                    icon: Icon(Icons.arrow_downward, size: 16),
                                  ),
                                ],
                                selected: {_currentDescending},
                                onSelectionChanged: (Set<bool> newSelection) {
                                  _handleSortChange(sort, newSelection.first);
                                },
                              ),
                            ],
                          )
                        : null,
                    leading: Radio<PlexSort>(
                      value: sort,
                      groupValue: _currentSort,
                      onChanged: (PlexSort? value) {
                        if (value != null) {
                          _handleSortChange(
                            value,
                            value.defaultDirection == 'desc',
                          );
                        }
                      },
                    ),
                    onTap: () {
                      _handleSortChange(
                        sort,
                        sort.defaultDirection == 'desc',
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
