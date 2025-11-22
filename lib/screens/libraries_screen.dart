import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../client/plex_client.dart';
import '../models/plex_library.dart';
import '../models/plex_metadata.dart';
import '../models/plex_sort.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/multi_server_provider.dart';
import '../utils/app_logger.dart';
import '../utils/provider_extensions.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/context_menu_wrapper.dart';
import '../widgets/server_badge.dart';
import '../services/storage_service.dart';
import '../mixins/refreshable.dart';
import '../mixins/item_updatable.dart';
import '../theme/theme_helper.dart';
import '../i18n/strings.g.dart';
import '../utils/error_message_utils.dart';
import 'library_tabs/library_browse_tab.dart';
import 'library_tabs/library_recommended_tab.dart';
import 'library_tabs/library_collections_tab.dart';
import 'library_tabs/library_playlists_tab.dart';

class LibrariesScreen extends StatefulWidget {
  const LibrariesScreen({super.key});

  @override
  State<LibrariesScreen> createState() => _LibrariesScreenState();
}

class _LibrariesScreenState extends State<LibrariesScreen>
    with Refreshable, ItemUpdatable, SingleTickerProviderStateMixin {
  @override
  PlexClient get client => context.getClientForServer(null);

  late TabController _tabController;

  // GlobalKeys for tabs to enable refresh
  final _recommendedTabKey = GlobalKey<State<LibraryRecommendedTab>>();
  final _browseTabKey = GlobalKey<State<LibraryBrowseTab>>();
  final _collectionsTabKey = GlobalKey<State<LibraryCollectionsTab>>();
  final _playlistsTabKey = GlobalKey<State<LibraryPlaylistsTab>>();

  List<PlexLibrary> _allLibraries = []; // All libraries from API (unfiltered)
  bool _isLoadingLibraries = true;
  String? _errorMessage;
  String? _selectedLibraryGlobalKey;
  bool _isInitialLoad = true;
  List<String>? _serverOrder; // Cached server order from storage

  Map<String, String> _selectedFilters = {};
  PlexSort? _selectedSort;
  bool _isSortDescending = false;
  List<PlexMetadata> _items = [];
  int _currentPage = 0;
  bool _hasMoreItems = true;
  CancelToken? _cancelToken;
  int _requestId = 0;
  static const int _pageSize = 1000;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadLibraries();
  }

  void _onTabChanged() {
    // Save tab index when changed
    if (_selectedLibraryGlobalKey != null && !_tabController.indexIsChanging) {
      StorageService.getInstance().then((storage) {
        storage.saveLibraryTab(
          _selectedLibraryGlobalKey!,
          _tabController.index,
        );
      });
    }
    // Rebuild to update chip selection state
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _cancelToken?.cancel();
    super.dispose();
  }

  void _updateState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  /// Helper method to get user-friendly error message from exception
  String _getErrorMessage(dynamic error, String context) {
    if (error is DioException) {
      return mapDioErrorToMessage(error, context: context);
    }

    return mapUnexpectedErrorToMessage(error, context: context);
  }

  /// Check if libraries come from multiple servers
  bool get _hasMultipleServers {
    final uniqueServerIds = _allLibraries
        .where((lib) => lib.serverId != null)
        .map((lib) => lib.serverId)
        .toSet();
    return uniqueServerIds.length > 1;
  }

  /// Get ordered list of server IDs from libraries
  List<String> _getOrderedServerIds(List<PlexLibrary> libraries) {
    // Get unique server IDs from libraries
    final serverIds = libraries
        .where((lib) => lib.serverId != null)
        .map((lib) => lib.serverId!)
        .toSet()
        .toList();

    if (_serverOrder == null || _serverOrder!.isEmpty) {
      return serverIds;
    }

    // Apply saved order, but include any new servers not in the saved order
    final ordered = <String>[];
    for (final id in _serverOrder!) {
      if (serverIds.contains(id)) {
        ordered.add(id);
      }
    }

    // Add any servers not in saved order
    for (final id in serverIds) {
      if (!ordered.contains(id)) {
        ordered.add(id);
      }
    }

    return ordered;
  }

  Future<void> _loadLibraries() async {
    // Extract context dependencies before async gap
    final multiServerProvider = Provider.of<MultiServerProvider>(
      context,
      listen: false,
    );
    final hiddenLibrariesProvider = Provider.of<HiddenLibrariesProvider>(
      context,
      listen: false,
    );

    setState(() {
      _isLoadingLibraries = true;
      _errorMessage = null;
    });

    try {
      // Check if we have any connected servers
      if (!multiServerProvider.hasConnectedServers) {
        throw Exception(t.errors.noClientAvailable);
      }

      final storage = await StorageService.getInstance();

      // Fetch libraries from all servers
      final allLibraries = await multiServerProvider.aggregationService
          .getLibrariesFromAllServers();

      // Filter out music libraries (type: 'artist') since music playback is not yet supported
      // Only show movie and TV show libraries
      final filteredLibraries = allLibraries
          .where((lib) => lib.type.toLowerCase() != 'artist')
          .toList();

      // Load saved library order and apply it
      final savedOrder = storage.getLibraryOrder();
      final orderedLibraries = _applyLibraryOrder(
        filteredLibraries,
        savedOrder,
      );

      // Load saved server order
      final savedServerOrder = storage.getServerOrder();

      _updateState(() {
        _allLibraries =
            orderedLibraries; // Store all libraries with ordering applied
        _serverOrder = savedServerOrder;
        _isLoadingLibraries = false;
      });

      if (allLibraries.isNotEmpty) {
        // Compute visible libraries for initial load
        final hiddenKeys = hiddenLibrariesProvider.hiddenLibraryKeys;
        final visibleLibraries = allLibraries
            .where((lib) => !hiddenKeys.contains(lib.globalKey))
            .toList();

        // Load saved preferences
        final savedLibraryKey = storage.getSelectedLibraryKey();

        // Find the library by key in visible libraries
        String? libraryGlobalKeyToLoad;
        if (savedLibraryKey != null) {
          // Check if saved library exists and is visible
          final libraryExists = visibleLibraries.any(
            (lib) => lib.globalKey == savedLibraryKey,
          );
          if (libraryExists) {
            libraryGlobalKeyToLoad = savedLibraryKey;
          }
        }

        // Fallback to first visible library if saved key not found
        if (libraryGlobalKeyToLoad == null && visibleLibraries.isNotEmpty) {
          libraryGlobalKeyToLoad = visibleLibraries.first.globalKey;
        }

        if (libraryGlobalKeyToLoad != null && mounted) {
          final savedFilters = storage.getLibraryFilters(
            sectionId: libraryGlobalKeyToLoad,
          );
          if (savedFilters.isNotEmpty) {
            _selectedFilters = Map.from(savedFilters);
          }
          _loadLibraryContent(libraryGlobalKeyToLoad);
        }
      }
    } catch (e) {
      _updateState(() {
        _errorMessage = _getErrorMessage(e, 'libraries');
        _isLoadingLibraries = false;
      });
    }
  }

  List<PlexLibrary> _applyLibraryOrder(
    List<PlexLibrary> libraries,
    List<String>? savedOrder,
  ) {
    if (savedOrder == null || savedOrder.isEmpty) {
      return libraries;
    }

    // Create a map for quick lookup
    final libraryMap = {for (var lib in libraries) lib.globalKey: lib};

    // Build ordered list based on saved order
    final orderedLibraries = <PlexLibrary>[];
    final addedKeys = <String>{};

    // Add libraries in saved order
    for (final key in savedOrder) {
      if (libraryMap.containsKey(key)) {
        orderedLibraries.add(libraryMap[key]!);
        addedKeys.add(key);
      }
    }

    // Add any new libraries that weren't in the saved order
    for (final library in libraries) {
      if (!addedKeys.contains(library.globalKey)) {
        orderedLibraries.add(library);
      }
    }

    return orderedLibraries;
  }

  Future<void> _saveLibraryOrder() async {
    final storage = await StorageService.getInstance();
    final libraryKeys = _allLibraries.map((lib) => lib.globalKey).toList();
    await storage.saveLibraryOrder(libraryKeys);
  }

  Future<void> _loadLibraryContent(String libraryGlobalKey) async {
    // Compute visible libraries based on current provider state
    final hiddenLibrariesProvider = Provider.of<HiddenLibrariesProvider>(
      context,
      listen: false,
    );
    final hiddenKeys = hiddenLibrariesProvider.hiddenLibraryKeys;
    final visibleLibraries = _allLibraries
        .where((lib) => !hiddenKeys.contains(lib.globalKey))
        .toList();

    // Find the library by key
    final libraryIndex = visibleLibraries.indexWhere(
      (lib) => lib.globalKey == libraryGlobalKey,
    );
    if (libraryIndex == -1) return; // Library not found or hidden

    final library = visibleLibraries[libraryIndex];

    final isChangingLibrary =
        !_isInitialLoad && _selectedLibraryGlobalKey != libraryGlobalKey;

    // Get the correct client for this library's server
    final client = context.getClientForLibrary(library);

    _updateState(() {
      _selectedLibraryGlobalKey = libraryGlobalKey;
      _errorMessage = null;
      // Only clear filters when explicitly changing library (not on initial load)
      if (isChangingLibrary) {
        _selectedFilters.clear();
      }
    });

    // Mark that initial load is complete
    if (_isInitialLoad) {
      _isInitialLoad = false;
    }

    // Save selected library key and restore saved tab
    final storage = await StorageService.getInstance();
    await storage.saveSelectedLibraryKey(libraryGlobalKey);

    // Restore saved tab index for this library
    final savedTabIndex = storage.getLibraryTab(libraryGlobalKey);
    if (savedTabIndex != null && savedTabIndex >= 0 && savedTabIndex < 4) {
      _updateState(() {
        _tabController.index = savedTabIndex;
      });
    }

    // Clear filters in storage when changing library
    if (isChangingLibrary) {
      await storage.saveLibraryFilters({}, sectionId: libraryGlobalKey);
    }

    // Cancel any existing requests
    _cancelToken?.cancel();
    _cancelToken = CancelToken();
    final currentRequestId = ++_requestId;

    // Reset pagination state
    _updateState(() {
      _currentPage = 0;
      _hasMoreItems = true;
      _items = [];
    });

    try {
      // Load sort options for the new library
      await _loadSortOptions(library);

      final filtersWithSort = _buildFiltersWithSort();

      // Load pages sequentially
      await _loadAllPagesSequentially(
        library,
        filtersWithSort,
        currentRequestId,
        client,
      );
    } catch (e) {
      // Ignore cancellation errors
      if (e is DioException && e.type == DioExceptionType.cancel) {
        return;
      }

      _updateState(() {
        _errorMessage = _getErrorMessage(e, 'library content');
      });
    }
  }

  /// Load all pages sequentially until all items are fetched
  Future<void> _loadAllPagesSequentially(
    PlexLibrary library,
    Map<String, String> filtersWithSort,
    int requestId,
    PlexClient client,
  ) async {
    while (_hasMoreItems && requestId == _requestId) {
      try {
        final items = await client.getLibraryContent(
          library.key,
          start: _currentPage * _pageSize,
          size: _pageSize,
          filters: filtersWithSort,
          cancelToken: _cancelToken,
        );

        // Tag items with server info for multi-server support
        final taggedItems = items
            .map(
              (item) => item.copyWith(
                serverId: library.serverId,
                serverName: library.serverName,
              ),
            )
            .toList();

        // Check if request is still valid
        if (requestId != _requestId) {
          return; // Request was superseded
        }

        _updateState(() {
          _items.addAll(taggedItems);
          _currentPage++;
          _hasMoreItems = taggedItems.length >= _pageSize;
        });
      } catch (e) {
        // Check if it's a cancellation
        if (e is DioException && e.type == DioExceptionType.cancel) {
          return;
        }

        // For other errors, update state and rethrow
        _updateState(() {
          _hasMoreItems = false;
        });
        rethrow;
      }
    }
  }

  Future<void> _loadSortOptions(PlexLibrary library) async {
    try {
      final client = context.getClientForLibrary(library);

      final sortOptions = await client.getLibrarySorts(library.key);

      // Load saved sort preference for this library
      final storage = await StorageService.getInstance();
      final savedSortData = storage.getLibrarySort(library.globalKey);

      // Find the saved sort in the options
      PlexSort? savedSort;
      bool descending = false;

      if (savedSortData != null) {
        final sortKey = savedSortData['key'] as String?;
        if (sortKey != null) {
          savedSort = sortOptions.firstWhere(
            (s) => s.key == sortKey,
            orElse: () => sortOptions.first,
          );
          descending = (savedSortData['descending'] as bool?) ?? false;
        } else {
          savedSort = sortOptions.first;
        }
      } else {
        savedSort = sortOptions.first;
      }

      _updateState(() {
        _selectedSort = savedSort;
        _isSortDescending = descending;
      });
    } catch (e) {
      _updateState(() {
        _selectedSort = null;
        _isSortDescending = false;
      });
    }
  }

  Map<String, String> _buildFiltersWithSort() {
    final filtersWithSort = Map<String, String>.from(_selectedFilters);
    if (_selectedSort != null) {
      filtersWithSort['sort'] = _selectedSort!.getSortKey(
        descending: _isSortDescending,
      );
    }
    return filtersWithSort;
  }

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    final index = _items.indexWhere((item) => item.ratingKey == ratingKey);
    if (index != -1) {
      _items[index] = updatedMetadata;
    }
  }

  // Public method to refresh content (for normal navigation)
  @override
  void refresh() {
    _loadLibraries();
  }

  // Refresh the currently active tab
  void _refreshCurrentTab() {
    switch (_tabController.index) {
      case 0: // Recommended tab
        final refreshable = _recommendedTabKey.currentState;
        if (refreshable is Refreshable) {
          (refreshable as Refreshable).refresh();
        }
        break;
      case 1: // Browse tab
        final refreshable = _browseTabKey.currentState;
        if (refreshable is Refreshable) {
          (refreshable as Refreshable).refresh();
        }
        break;
      case 2: // Collections tab
        final refreshable = _collectionsTabKey.currentState;
        if (refreshable is Refreshable) {
          (refreshable as Refreshable).refresh();
        }
        break;
      case 3: // Playlists tab
        final refreshable = _playlistsTabKey.currentState;
        if (refreshable is Refreshable) {
          (refreshable as Refreshable).refresh();
        }
        break;
    }
  }

  // Public method to fully reload all content (for profile switches)
  void fullRefresh() {
    appLogger.d('LibrariesScreen.fullRefresh() called - reloading all content');
    // Reload libraries and clear any selected library/filters
    _selectedLibraryGlobalKey = null;
    _selectedFilters.clear();
    _items.clear();
    _loadLibraries();
  }

  Future<void> _toggleLibraryVisibility(PlexLibrary library) async {
    final hiddenLibrariesProvider = Provider.of<HiddenLibrariesProvider>(
      context,
      listen: false,
    );
    final isHidden = hiddenLibrariesProvider.hiddenLibraryKeys.contains(
      library.globalKey,
    );

    if (isHidden) {
      await hiddenLibrariesProvider.unhideLibrary(library.globalKey);
    } else {
      // Check if we're hiding the currently selected library
      final isCurrentlySelected =
          _selectedLibraryGlobalKey == library.globalKey;

      await hiddenLibrariesProvider.hideLibrary(library.globalKey);

      // If we just hid the selected library, select the first visible one
      if (isCurrentlySelected) {
        // Compute visible libraries after hiding
        final visibleLibraries = _allLibraries
            .where(
              (lib) => !hiddenLibrariesProvider.hiddenLibraryKeys.contains(
                lib.globalKey,
              ),
            )
            .toList();

        if (visibleLibraries.isNotEmpty) {
          _loadLibraryContent(visibleLibraries.first.globalKey);
        }
      }
    }
  }

  List<ContextMenuItem> _getLibraryMenuItems(PlexLibrary library) {
    return [
      ContextMenuItem(
        value: 'scan',
        icon: Icons.refresh,
        label: t.libraries.scanLibraryFiles,
        requiresConfirmation: true,
        confirmationTitle: t.libraries.scanLibrary,
        confirmationMessage: t.libraries.scanLibraryConfirm(
          title: library.title,
        ),
      ),
      ContextMenuItem(
        value: 'analyze',
        icon: Icons.analytics_outlined,
        label: t.libraries.analyze,
        requiresConfirmation: true,
        confirmationTitle: t.libraries.analyzeLibrary,
        confirmationMessage: t.libraries.analyzeLibraryConfirm(
          title: library.title,
        ),
      ),
      ContextMenuItem(
        value: 'refresh',
        icon: Icons.sync,
        label: t.libraries.refreshMetadata,
        requiresConfirmation: true,
        confirmationTitle: t.libraries.refreshMetadata,
        confirmationMessage: t.libraries.refreshMetadataConfirm(
          title: library.title,
        ),
        isDestructive: true,
      ),
      ContextMenuItem(
        value: 'empty_trash',
        icon: Icons.delete_outline,
        label: t.libraries.emptyTrash,
        requiresConfirmation: true,
        confirmationTitle: t.libraries.emptyTrash,
        confirmationMessage: t.libraries.emptyTrashConfirm(
          title: library.title,
        ),
        isDestructive: true,
      ),
    ];
  }

  void _handleLibraryMenuAction(String action, PlexLibrary library) {
    switch (action) {
      case 'scan':
        _scanLibrary(library);
        break;
      case 'analyze':
        _analyzeLibrary(library);
        break;
      case 'refresh':
        _refreshLibraryMetadata(library);
        break;
      case 'empty_trash':
        _emptyLibraryTrash(library);
        break;
    }
  }

  void _showLibraryManagementSheet() {
    final hiddenLibrariesProvider = Provider.of<HiddenLibrariesProvider>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LibraryManagementSheet(
        allLibraries: List.from(_allLibraries),
        hiddenLibraryKeys: hiddenLibrariesProvider.hiddenLibraryKeys,
        onReorder: (reorderedLibraries) {
          setState(() {
            _allLibraries = reorderedLibraries;
          });
          _saveLibraryOrder();
        },
        onToggleVisibility: _toggleLibraryVisibility,
        getLibraryMenuItems: _getLibraryMenuItems,
        onLibraryMenuAction: _handleLibraryMenuAction,
      ),
    );
  }

  Future<void> _performLibraryAction({
    required PlexLibrary library,
    required Future<void> Function(PlexClient client) action,
    required String progressMessage,
    required String successMessage,
    required String Function(Object error) failureMessage,
  }) async {
    try {
      final client = context.getClientForLibrary(library);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(progressMessage),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await action(client);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      appLogger.e('Library action failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failureMessage(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _scanLibrary(PlexLibrary library) async {
    return _performLibraryAction(
      library: library,
      action: (client) => client.scanLibrary(library.key),
      progressMessage: t.messages.libraryScanning(title: library.title),
      successMessage: t.messages.libraryScanStarted(title: library.title),
      failureMessage: (error) =>
          t.messages.libraryScanFailed(error: error.toString()),
    );
  }

  Future<void> _refreshLibraryMetadata(PlexLibrary library) async {
    return _performLibraryAction(
      library: library,
      action: (client) => client.refreshLibraryMetadata(library.key),
      progressMessage: t.messages.metadataRefreshing(title: library.title),
      successMessage: t.messages.metadataRefreshStarted(title: library.title),
      failureMessage: (error) =>
          t.messages.metadataRefreshFailed(error: error.toString()),
    );
  }

  Future<void> _emptyLibraryTrash(PlexLibrary library) async {
    return _performLibraryAction(
      library: library,
      action: (client) => client.emptyLibraryTrash(library.key),
      progressMessage: t.libraries.emptyingTrash(title: library.title),
      successMessage: t.libraries.trashEmptied(title: library.title),
      failureMessage: (error) => t.libraries.failedToEmptyTrash(error: error),
    );
  }

  Future<void> _analyzeLibrary(PlexLibrary library) async {
    return _performLibraryAction(
      library: library,
      action: (client) => client.analyzeLibrary(library.key),
      progressMessage: t.libraries.analyzing(title: library.title),
      successMessage: t.libraries.analysisStarted(title: library.title),
      failureMessage: (error) => t.libraries.failedToAnalyze(error: error),
    );
  }

  /// Build grouped dropdown menu items with server sections
  List<PopupMenuEntry<String>> _buildGroupedLibraryMenuItems(
    List<PlexLibrary> visibleLibraries,
  ) {
    final List<PopupMenuEntry<String>> menuItems = [];

    if (!_hasMultipleServers) {
      // Single server: flat list
      return visibleLibraries.map((library) {
        final isSelected = library.globalKey == _selectedLibraryGlobalKey;
        return PopupMenuItem<String>(
          value: library.globalKey,
          child: Row(
            children: [
              Icon(
                _getLibraryIcon(library.type),
                size: 20,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                library.title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ],
          ),
        );
      }).toList();
    }

    // Multiple servers: group by server
    final Map<String, List<PlexLibrary>> groupedLibraries = {};
    for (final library in visibleLibraries) {
      final serverKey = library.serverId ?? 'unknown';
      groupedLibraries.putIfAbsent(serverKey, () => []).add(library);
    }

    // Use ordered server keys
    final serverKeys = _getOrderedServerIds(visibleLibraries);
    for (int i = 0; i < serverKeys.length; i++) {
      final serverKey = serverKeys[i];
      final libraries = groupedLibraries[serverKey]!;
      final serverName = libraries.first.serverName ?? 'Unknown Server';

      // Add server header
      menuItems.add(
        PopupMenuItem<String>(
          enabled: false,
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            serverName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );

      // Add libraries for this server
      for (final library in libraries) {
        final isSelected = library.globalKey == _selectedLibraryGlobalKey;
        menuItems.add(
          PopupMenuItem<String>(
            value: library.globalKey,
            child: Row(
              children: [
                const SizedBox(width: 12), // Indent library items
                Icon(
                  _getLibraryIcon(library.type),
                  size: 20,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  library.title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Add divider between server groups (except after last)
      if (i < serverKeys.length - 1) {
        menuItems.add(const PopupMenuDivider());
      }
    }

    return menuItems;
  }

  Widget _buildTabChip(String label, int index) {
    final isSelected = _tabController.index == index;
    final t = tokens(context);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _tabController.index = index;
          });
        }
      },
      backgroundColor: t.surface,
      selectedColor: t.text,
      side: BorderSide(color: t.outline),
      labelStyle: TextStyle(
        color: isSelected ? t.bg : t.text,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      showCheckmark: false,
    );
  }

  Widget _buildLibraryDropdownTitle(List<PlexLibrary> visibleLibraries) {
    final selectedLibrary = visibleLibraries.firstWhere(
      (lib) => lib.globalKey == _selectedLibraryGlobalKey,
      orElse: () => visibleLibraries.first,
    );

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      tooltip: t.libraries.selectLibrary,
      onSelected: (libraryGlobalKey) {
        _loadLibraryContent(libraryGlobalKey);
      },
      itemBuilder: (context) => _buildGroupedLibraryMenuItems(visibleLibraries),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getLibraryIcon(selectedLibrary.type), size: 20),
          const SizedBox(width: 8),
          if (_hasMultipleServers && selectedLibrary.serverName != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedLibrary.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  selectedLibrary.serverName!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ],
            )
          else
            Text(
              selectedLibrary.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch for hidden libraries changes to trigger rebuild
    final hiddenLibrariesProvider = context.watch<HiddenLibrariesProvider>();
    final hiddenKeys = hiddenLibrariesProvider.hiddenLibraryKeys;

    // Compute visible libraries (filtered from all libraries)
    final visibleLibraries = _allLibraries
        .where((lib) => !hiddenKeys.contains(lib.globalKey))
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          DesktopSliverAppBar(
            title:
                visibleLibraries.isNotEmpty && _selectedLibraryGlobalKey != null
                ? _buildLibraryDropdownTitle(visibleLibraries)
                : Text(t.libraries.title),
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            scrolledUnderElevation: 0,
            actions: [
              if (_allLibraries.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    semanticLabel: t.libraries.manageLibraries,
                  ),
                  onPressed: _showLibraryManagementSheet,
                ),
              IconButton(
                icon: Icon(Icons.refresh, semanticLabel: t.common.refresh),
                onPressed: _refreshCurrentTab,
              ),
            ],
          ),
          if (_isLoadingLibraries)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null && visibleLibraries.isEmpty)
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
                      onPressed: _loadLibraries,
                      child: Text(t.common.retry),
                    ),
                  ],
                ),
              ),
            )
          else if (visibleLibraries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.video_library_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(t.libraries.noLibrariesFound),
                  ],
                ),
              ),
            )
          else ...[
            // Tab selector chips
            if (_selectedLibraryGlobalKey != null)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTabChip(t.libraries.tabs.recommended, 0),
                        const SizedBox(width: 8),
                        _buildTabChip(t.libraries.tabs.browse, 1),
                        const SizedBox(width: 8),
                        _buildTabChip(t.libraries.tabs.collections, 2),
                        const SizedBox(width: 8),
                        _buildTabChip(t.libraries.tabs.playlists, 3),
                      ],
                    ),
                  ),
                ),
              ),

            // Tab content
            if (_selectedLibraryGlobalKey != null)
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    LibraryRecommendedTab(
                      key: _recommendedTabKey,
                      library: _allLibraries.firstWhere(
                        (lib) => lib.globalKey == _selectedLibraryGlobalKey,
                      ),
                    ),
                    LibraryBrowseTab(
                      key: _browseTabKey,
                      library: _allLibraries.firstWhere(
                        (lib) => lib.globalKey == _selectedLibraryGlobalKey,
                      ),
                    ),
                    LibraryCollectionsTab(
                      key: _collectionsTabKey,
                      library: _allLibraries.firstWhere(
                        (lib) => lib.globalKey == _selectedLibraryGlobalKey,
                      ),
                    ),
                    LibraryPlaylistsTab(
                      key: _playlistsTabKey,
                      library: _allLibraries.firstWhere(
                        (lib) => lib.globalKey == _selectedLibraryGlobalKey,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  IconData _getLibraryIcon(String type) {
    switch (type.toLowerCase()) {
      case 'movie':
        return Icons.movie;
      case 'show':
        return Icons.tv;
      case 'artist':
        return Icons.music_note;
      case 'photo':
        return Icons.photo;
      default:
        return Icons.folder;
    }
  }
}

class _LibraryManagementSheet extends StatefulWidget {
  final List<PlexLibrary> allLibraries;
  final Set<String> hiddenLibraryKeys;
  final Function(List<PlexLibrary>) onReorder;
  final Function(PlexLibrary) onToggleVisibility;
  final List<ContextMenuItem> Function(PlexLibrary) getLibraryMenuItems;
  final void Function(String action, PlexLibrary library) onLibraryMenuAction;

  const _LibraryManagementSheet({
    required this.allLibraries,
    required this.hiddenLibraryKeys,
    required this.onReorder,
    required this.onToggleVisibility,
    required this.getLibraryMenuItems,
    required this.onLibraryMenuAction,
  });

  @override
  State<_LibraryManagementSheet> createState() =>
      _LibraryManagementSheetState();
}

class _LibraryManagementSheetState extends State<_LibraryManagementSheet> {
  late List<PlexLibrary> _tempLibraries;
  List<String>? _serverOrder;

  @override
  void initState() {
    super.initState();
    _tempLibraries = List.from(widget.allLibraries);
    _loadServerOrder();
  }

  /// Load server order from storage
  Future<void> _loadServerOrder() async {
    final storage = await StorageService.getInstance();
    final savedOrder = storage.getServerOrder();

    if (mounted) {
      setState(() {
        _serverOrder = savedOrder;
      });
    }
  }

  /// Save server order to storage
  Future<void> _saveServerOrder(List<String> serverIds) async {
    final storage = await StorageService.getInstance();
    await storage.saveServerOrder(serverIds);

    if (mounted) {
      setState(() {
        _serverOrder = serverIds;
      });
    }
  }

  /// Get ordered list of server IDs
  List<String> _getOrderedServerIds() {
    // Get unique server IDs from libraries
    final serverIds = _tempLibraries
        .where((lib) => lib.serverId != null)
        .map((lib) => lib.serverId!)
        .toSet()
        .toList();

    if (_serverOrder == null || _serverOrder!.isEmpty) {
      return serverIds;
    }

    // Apply saved order, but include any new servers not in the saved order
    final ordered = <String>[];
    for (final id in _serverOrder!) {
      if (serverIds.contains(id)) {
        ordered.add(id);
      }
    }

    // Add any servers not in saved order
    for (final id in serverIds) {
      if (!ordered.contains(id)) {
        ordered.add(id);
      }
    }

    return ordered;
  }

  /// Check if libraries come from multiple servers
  bool get _hasMultipleServers {
    final uniqueServerIds = _tempLibraries
        .where((lib) => lib.serverId != null)
        .map((lib) => lib.serverId)
        .toSet();
    return uniqueServerIds.length > 1;
  }

  void _reorderLibraries(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final library = _tempLibraries.removeAt(oldIndex);
      _tempLibraries.insert(newIndex, library);
    });
    // Apply immediately
    widget.onReorder(_tempLibraries);
  }

  Future<void> _showLibraryMenuBottomSheet(
    BuildContext context,
    PlexLibrary library,
  ) async {
    final menuItems = widget.getLibraryMenuItems(library);
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                library.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...menuItems.map(
              (item) => ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                onTap: () => Navigator.pop(context, item.value),
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      // Find the selected item to check if confirmation is needed
      final selectedItem = menuItems.firstWhere(
        (item) => item.value == selected,
      );

      if (selectedItem.requiresConfirmation) {
        if (!mounted || !context.mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              selectedItem.confirmationTitle ?? t.dialog.confirmAction,
            ),
            content: Text(
              selectedItem.confirmationMessage ??
                  t.libraries.confirmActionMessage,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t.common.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: selectedItem.isDestructive
                    ? TextButton.styleFrom(foregroundColor: Colors.red)
                    : null,
                child: Text(t.common.confirm),
              ),
            ],
          ),
        );

        if (confirmed != true) return;
      }

      widget.onLibraryMenuAction(selected, library);
    }
  }

  IconData _getLibraryIcon(String type) {
    switch (type.toLowerCase()) {
      case 'movie':
        return Icons.movie;
      case 'show':
        return Icons.tv;
      case 'artist':
        return Icons.music_note;
      case 'photo':
        return Icons.photo;
      default:
        return Icons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider to rebuild when hidden libraries change
    final hiddenLibrariesProvider = context.watch<HiddenLibrariesProvider>();
    final hiddenLibraryKeys = hiddenLibrariesProvider.hiddenLibraryKeys;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.libraries.manageLibraries,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Library list (grouped by server if multiple servers)
            Expanded(
              child: _hasMultipleServers
                  ? _buildGroupedLibraryList(
                      scrollController,
                      hiddenLibraryKeys,
                    )
                  : _buildFlatLibraryList(scrollController, hiddenLibraryKeys),
            ),
          ],
        );
      },
    );
  }

  /// Build flat library list (single server)
  Widget _buildFlatLibraryList(
    ScrollController scrollController,
    Set<String> hiddenLibraryKeys,
  ) {
    return ReorderableListView.builder(
      scrollController: scrollController,
      onReorder: _reorderLibraries,
      itemCount: _tempLibraries.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final library = _tempLibraries[index];
        return _buildLibraryTile(library, index, hiddenLibraryKeys);
      },
    );
  }

  /// Build grouped library list (multiple servers)
  Widget _buildGroupedLibraryList(
    ScrollController scrollController,
    Set<String> hiddenLibraryKeys,
  ) {
    // Group libraries by server
    final Map<String, List<PlexLibrary>> groupedLibraries = {};
    for (final library in _tempLibraries) {
      final serverKey = library.serverId ?? 'unknown';
      groupedLibraries.putIfAbsent(serverKey, () => []).add(library);
    }

    // Use ordered server keys
    final serverKeys = _getOrderedServerIds();

    return ReorderableListView.builder(
      scrollController: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        // Reorder servers
        final reorderedServerIds = List<String>.from(serverKeys);
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final serverId = reorderedServerIds.removeAt(oldIndex);
        reorderedServerIds.insert(newIndex, serverId);
        _saveServerOrder(reorderedServerIds);
      },
      itemCount: serverKeys.length,
      itemBuilder: (context, serverIndex) {
        final serverKey = serverKeys[serverIndex];
        final libraries = groupedLibraries[serverKey]!;
        final serverName = libraries.first.serverName ?? 'Unknown Server';

        return Column(
          key: ValueKey(serverKey),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Server header with drag handle
            ListTile(
              leading: ReorderableDragStartListener(
                index: serverIndex,
                child: Icon(
                  Icons.drag_indicator,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                ),
              ),
              title: Text(
                serverName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // Libraries for this server (reorderable within server)
            ...libraries.asMap().entries.map((entry) {
              final index = entry.key;
              final library = entry.value;
              return _buildLibraryTile(
                library,
                index,
                hiddenLibraryKeys,
                showServerBadge: false,
                enableDrag: false, // Disable drag for individual libraries
              );
            }),
          ],
        );
      },
    );
  }

  /// Build a single library tile
  Widget _buildLibraryTile(
    PlexLibrary library,
    int index,
    Set<String> hiddenLibraryKeys, {
    bool showServerBadge = true,
    bool enableDrag = true,
  }) {
    final isHidden = hiddenLibraryKeys.contains(library.globalKey);

    return Opacity(
      key: ValueKey(library.globalKey),
      opacity: isHidden ? 0.5 : 1.0,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (enableDrag)
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.drag_indicator,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                  ),
                ),
              ),
            if (enableDrag) const SizedBox(width: 8),
            if (!enableDrag) const SizedBox(width: 12),
            Icon(_getLibraryIcon(library.type)),
          ],
        ),
        title: Row(
          children: [
            Expanded(child: Text(library.title)),
            if (showServerBadge &&
                _hasMultipleServers &&
                library.serverName != null)
              ServerBadge(serverName: library.serverName, showFullName: true),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility),
              onPressed: () => widget.onToggleVisibility(library),
              tooltip: isHidden
                  ? t.libraries.showLibrary
                  : t.libraries.hideLibrary,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showLibraryMenuBottomSheet(context, library),
              tooltip: t.libraries.libraryOptions,
            ),
          ],
        ),
      ),
    );
  }
}
