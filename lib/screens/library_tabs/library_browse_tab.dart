import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../client/plex_client.dart';
import '../../models/plex_library.dart';
import '../../models/plex_metadata.dart';
import '../../models/plex_filter.dart';
import '../../models/plex_sort.dart';
import '../../providers/plex_client_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/error_message_utils.dart';
import '../../utils/grid_size_calculator.dart';
import '../../widgets/media_card.dart';
import '../../widgets/folder_tree_view.dart';
import '../../widgets/filters_bottom_sheet.dart';
import '../../widgets/sort_bottom_sheet.dart';
import '../../services/storage_service.dart';
import '../../services/settings_service.dart' show ViewMode;
import '../../mixins/item_updatable.dart';
import '../../mixins/refreshable.dart';
import '../../i18n/strings.g.dart';
import '../../utils/app_logger.dart';

/// Browse tab for library screen
/// Shows library items with grouping, filtering, and sorting
class LibraryBrowseTab extends StatefulWidget {
  final PlexLibrary library;
  final String? viewMode;
  final String? density;

  const LibraryBrowseTab({
    super.key,
    required this.library,
    this.viewMode,
    this.density,
  });

  @override
  State<LibraryBrowseTab> createState() => _LibraryBrowseTabState();
}

class _LibraryBrowseTabState extends State<LibraryBrowseTab>
    with AutomaticKeepAliveClientMixin, ItemUpdatable, Refreshable {
  @override
  bool get wantKeepAlive => true;

  @override
  PlexClient get client => context.clientSafe;

  /// Get the correct PlexClient for this library's server
  PlexClient? _getClientForLibrary(BuildContext context) {
    final serverId = widget.library.serverId;
    if (serverId == null) {
      // Fallback to legacy client if no serverId
      appLogger.w('Library ${widget.library.title} has no serverId, using legacy client');
      return context.read<PlexClientProvider>().client;
    }

    final multiServerProvider = context.read<MultiServerProvider>();
    final client = multiServerProvider.getClientForServer(serverId);

    if (client == null) {
      appLogger.w('No client found for server $serverId, using legacy client');
      return context.read<PlexClientProvider>().client;
    }

    return client;
  }

  @override
  void refresh() {
    _loadContent();
  }

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    setState(() {
      final index = _items.indexWhere((item) => item.ratingKey == ratingKey);
      if (index != -1) {
        _items[index] = updatedMetadata;
      }
    });
  }

  List<PlexMetadata> _items = [];
  List<PlexFilter> _filters = [];
  List<PlexSort> _sortOptions = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, String> _selectedFilters = {};
  PlexSort? _selectedSort;
  bool _isSortDescending = false;
  String _selectedGrouping = 'all'; // all, seasons, episodes, folders

  // Pagination state
  int _currentPage = 0;
  bool _hasMoreItems = true;
  CancelToken? _cancelToken;
  int _requestId = 0;
  static const int _pageSize = 500;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void didUpdateWidget(LibraryBrowseTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if library changed
    if (oldWidget.library.globalKey != widget.library.globalKey) {
      _loadContent();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _loadContent() async {
    // Cancel any pending request
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final currentRequestId = ++_requestId;

    // Extract context dependencies before async gap - use server-specific client
    final client = _getClientForLibrary(context);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _items = [];
      _currentPage = 0;
      _hasMoreItems = true;
    });

    try {
      if (client == null) {
        throw Exception(t.errors.noClientAvailable);
      }

      final storage = await StorageService.getInstance();

      // Load filters and sorts for this library
      final filters = await client.getLibraryFilters(widget.library.key);
      final sorts = await client.getLibrarySorts(widget.library.key);

      // Load saved preferences
      final savedFilters = storage.getLibraryFilters(
        sectionId: widget.library.globalKey,
      );
      final savedSort = storage.getLibrarySort(widget.library.globalKey);
      final savedGrouping = storage.getLibraryGrouping(widget.library.globalKey);

      // Check if request was cancelled
      if (currentRequestId != _requestId) return;

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

      // Load items
      await _loadItems();
    } catch (e) {
      if (currentRequestId != _requestId) return;

      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadItems({bool loadMore = false}) async {
    if (loadMore && _isLoading) return;

    if (!loadMore) {
      _currentPage = 0;
      _hasMoreItems = true;
    }

    if (!_hasMoreItems) return;

    final currentRequestId = _requestId;
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    setState(() {
      _isLoading = true;
      if (!loadMore) {
        _items = [];
      }
    });

    try {
      // Use server-specific client for this library
      final client = _getClientForLibrary(context);
      if (client == null) {
        throw Exception(t.errors.noClientAvailable);
      }

      // Build filter params
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
        filterParams['sort'] = _selectedSort!.getSortKey(
          descending: _isSortDescending,
        );
      }

      final items = await client.getLibraryContent(
        widget.library.key,
        start: _currentPage * _pageSize,
        size: _pageSize,
        filters: filterParams,
        cancelToken: _cancelToken,
      );

      // Tag items with server info for multi-server support
      final taggedItems = items
          .map(
            (item) => item.copyWith(
              serverId: widget.library.serverId,
              serverName: widget.library.serverName,
            ),
          )
          .toList();

      if (currentRequestId != _requestId) return;

      setState(() {
        if (loadMore) {
          _items.addAll(taggedItems);
        } else {
          _items = taggedItems;
        }
        _hasMoreItems = taggedItems.length >= _pageSize;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      if (currentRequestId != _requestId) return;

      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
    }
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
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: _getGroupingOptions().map((grouping) {
            return RadioListTile<String>(
              title: Text(_getGroupingLabel(grouping)),
              value: grouping,
              // ignore: deprecated_member_use
              groupValue: _selectedGrouping,
              // ignore: deprecated_member_use
              onChanged: (value) async {
                if (value != null) {
                  setState(() {
                    _selectedGrouping = value;
                  });

          final storage = await StorageService.getInstance();
          await storage.saveLibraryGrouping(widget.library.globalKey, value);

                  if (!mounted) return;

                  Navigator.pop(context);
                  _loadItems();
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FiltersBottomSheet(
        filters: _filters,
        selectedFilters: _selectedFilters,
        onFiltersChanged: (filters) async {
          setState(() {
            _selectedFilters.clear();
            _selectedFilters.addAll(filters);
          });

          // Save filters to storage
          final storage = await StorageService.getInstance();
          await storage.saveLibraryFilters(
            filters,
            sectionId: widget.library.globalKey,
          );

          _loadItems();
        },
      ),
    );
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

          StorageService.getInstance().then((storage) {
            storage.saveLibrarySort(
              widget.library.globalKey,
              sort.key,
              descending: descending,
            );
          });

          _loadItems();
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Column(
      children: [
        // Filter bar with chips
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grouping chip
                _buildFilterChip(
                  icon: Icons.category,
                  label: _getGroupingLabel(_selectedGrouping),
                  onPressed: _showGroupingBottomSheet,
                ),
                const SizedBox(width: 8),
                // Filters chip
                if (_filters.isNotEmpty && _selectedGrouping != 'folders')
                  _buildFilterChip(
                    icon: Icons.filter_alt,
                    label: _selectedFilters.isEmpty
                        ? t.libraries.filters
                        : t.libraries.filtersWithCount(
                            count: _selectedFilters.length,
                          ),
                    onPressed: _showFiltersBottomSheet,
                  ),
                if (_filters.isNotEmpty && _selectedGrouping != 'folders')
                  const SizedBox(width: 8),
                // Sort chip
                if (_sortOptions.isNotEmpty && _selectedGrouping != 'folders')
                  _buildFilterChip(
                    icon: Icons.sort,
                    label: _selectedSort?.title ?? t.libraries.sort,
                    onPressed: _showSortBottomSheet,
                  ),
              ],
            ),
          ),
        ),

        // Content
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    // Show folder tree view when in folders mode
    if (_selectedGrouping == 'folders') {
      return FolderTreeView(
        libraryKey: widget.library.key,
        serverId: widget.library.serverId,
        onRefresh: updateItem,
      );
    }

    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContent,
              child: Text(t.common.retry),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(t.libraries.thisLibraryIsEmpty),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 300 &&
            _hasMoreItems &&
            !_isLoading) {
          _loadItems(loadMore: true);
        }
        return false;
      },
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          if (settingsProvider.viewMode == ViewMode.list) {
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              itemCount: _items.length + (_hasMoreItems && _isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final item = _items[index];
                return MediaCard(
                  key: Key(item.ratingKey),
                  item: item,
                  onRefresh: updateItem,
                );
              },
            );
          } else {
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: GridSizeCalculator.getMaxCrossAxisExtent(
                  context,
                  settingsProvider.libraryDensity,
                ),
                childAspectRatio: 2 / 3.3,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
              ),
              itemCount: _items.length + (_hasMoreItems && _isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _items.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final item = _items[index];
                return MediaCard(
                  key: Key(item.ratingKey),
                  item: item,
                  onRefresh: updateItem,
                );
              },
            );
          }
        },
      ),
    );
  }
}
