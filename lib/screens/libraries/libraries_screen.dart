import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../focus/dpad_navigator.dart';
import '../../focus/input_mode_tracker.dart';
import '../../services/gamepad_service.dart';
import '../../../services/plex_client.dart';
import '../../models/plex_library.dart';
import '../../models/plex_metadata.dart';
import '../../models/plex_sort.dart';
import '../../providers/hidden_libraries_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_detector.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/content_utils.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../widgets/focusable_tab_chip.dart';
import '../main_screen.dart';
import '../../services/storage_service.dart';
import '../../mixins/refreshable.dart';
import '../../mixins/item_updatable.dart';
import '../../i18n/strings.g.dart';
import '../../utils/error_message_utils.dart';
import 'state_messages.dart';
import 'tabs/library_browse_tab.dart';
import 'tabs/library_recommended_tab.dart';
import 'tabs/library_collections_tab.dart';
import 'tabs/library_playlists_tab.dart';

/// A menu action item for context menus
class ContextMenuItem {
  final String value;
  final IconData icon;
  final String label;
  final bool requiresConfirmation;
  final String? confirmationTitle;
  final String? confirmationMessage;
  final bool isDestructive;

  const ContextMenuItem({
    required this.value,
    required this.icon,
    required this.label,
    this.requiresConfirmation = false,
    this.confirmationTitle,
    this.confirmationMessage,
    this.isDestructive = false,
  });
}

class LibrariesScreen extends StatefulWidget {
  final VoidCallback? onLibraryOrderChanged;

  const LibrariesScreen({super.key, this.onLibraryOrderChanged});

  @override
  State<LibrariesScreen> createState() => _LibrariesScreenState();
}

class _LibrariesScreenState extends State<LibrariesScreen>
    with Refreshable, FullRefreshable, FocusableTab, LibraryLoadable, ItemUpdatable, SingleTickerProviderStateMixin {
  @override
  PlexClient get client {
    final multiServerProvider = Provider.of<MultiServerProvider>(context, listen: false);
    if (!multiServerProvider.hasConnectedServers) {
      throw Exception(t.errors.noClientAvailable);
    }
    return context.getClientForServer(multiServerProvider.onlineServerIds.first);
  }

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

  /// When true, suppress auto-focus in tabs (used when navigating via tab bar)
  bool _suppressAutoFocus = false;

  Map<String, String> _selectedFilters = {};
  PlexSort? _selectedSort;
  bool _isSortDescending = false;
  List<PlexMetadata> _items = [];
  int _currentPage = 0;
  bool _hasMoreItems = true;
  CancelToken? _cancelToken;
  int _requestId = 0;
  static const int _pageSize = 1000;

  /// Flag to prevent _onTabChanged from focusing when we're programmatically changing tabs
  bool _isRestoringTab = false;

  /// Track which tabs have loaded data (used to trigger focus after tab restore)
  final Set<int> _loadedTabs = {};

  /// Key for the library dropdown popup menu button
  final _libraryDropdownKey = GlobalKey<PopupMenuButtonState<String>>();

  // Focus nodes for tab chips
  final _recommendedTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_recommended');
  final _browseTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_browse');
  final _collectionsTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_collections');
  final _playlistsTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_playlists');

  /// When true, the next library load should force the tab to Recommended (index 0).
  /// This is set when navigating to a library from the side navigation rail so
  /// users always land on the Recommended tab regardless of previous tab memory.
  bool _forceRecommendedTabOnNextLoad = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadLibraries();

    // Register L1/R1 callbacks for tab navigation
    GamepadService.onL1Pressed = _goToPreviousTab;
    GamepadService.onR1Pressed = _goToNextTab;
  }

  void _goToPreviousTab() {
    if (_tabController.index > 0) {
      setState(() {
        _suppressAutoFocus = true;
        _tabController.index = _tabController.index - 1;
      });
      _getTabChipFocusNode(_tabController.index).requestFocus();
    }
  }

  void _goToNextTab() {
    if (_tabController.index < _tabController.length - 1) {
      setState(() {
        _suppressAutoFocus = true;
        _tabController.index = _tabController.index + 1;
      });
      _getTabChipFocusNode(_tabController.index).requestFocus();
    }
  }

  void _onTabChanged() {
    // Save tab index when changed (but not when restoring from storage)
    if (_selectedLibraryGlobalKey != null && !_tabController.indexIsChanging) {
      // Only save if this was a user-initiated tab change, not a restore
      if (!_isRestoringTab) {
        StorageService.getInstance().then((storage) {
          storage.saveLibraryTab(_selectedLibraryGlobalKey!, _tabController.index);
        });

        // Focus first item in the current tab (only for user-initiated changes)
        // But not when navigating via tab bar (suppressAutoFocus is true)
        if (!_suppressAutoFocus) {
          _focusCurrentTab();
        }
      }
    }
    // Rebuild to update chip selection state
    setState(() {});
  }

  /// Focus the first item in the currently active tab
  void _focusCurrentTab() {
    // Don't focus during tab animations - wait for animation to complete
    // This prevents race conditions during focus restoration
    if (_tabController.indexIsChanging) {
      return;
    }

    // Re-enable auto-focus since user is navigating into tab content
    // Only call setState if the value actually changes to avoid unnecessary rebuilds
    if (_suppressAutoFocus) {
      setState(() {
        _suppressAutoFocus = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      State? tabState;
      switch (_tabController.index) {
        case 0:
          tabState = _recommendedTabKey.currentState;
          break;
        case 1:
          tabState = _browseTabKey.currentState;
          break;
        case 2:
          tabState = _collectionsTabKey.currentState;
          break;
        case 3:
          tabState = _playlistsTabKey.currentState;
          break;
      }

      if (tabState != null) {
        (tabState as dynamic).focusFirstItem();
      } else {
        // State not available yet, retry after another frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _focusCurrentTabImmediate();
        });
      }
    });
  }

  /// Focus without additional frame delay (used for retry)
  void _focusCurrentTabImmediate() {
    State? tabState;
    switch (_tabController.index) {
      case 0:
        tabState = _recommendedTabKey.currentState;
        break;
      case 1:
        tabState = _browseTabKey.currentState;
        break;
      case 2:
        tabState = _collectionsTabKey.currentState;
        break;
      case 3:
        tabState = _playlistsTabKey.currentState;
        break;
    }

    if (tabState != null) {
      (tabState as dynamic).focusFirstItem();
    }
  }

  /// Handle when a tab's data has finished loading
  void _handleTabDataLoaded(int tabIndex) {
    // Track that this tab has loaded
    _loadedTabs.add(tabIndex);

    // Don't auto-focus if suppressed (e.g., when navigating via tab bar)
    if (_suppressAutoFocus) return;

    // Only focus if this is the currently active tab
    if (_tabController.index == tabIndex && mounted) {
      // Use post-frame callback to ensure the widget tree is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController.index == tabIndex && !_suppressAutoFocus) {
          _focusCurrentTab();
        }
      });
    }
  }

  /// Called by parent when the Libraries screen becomes visible.
  /// If the active tab has already loaded data (often the case after preloading
  /// while on another main tab), re-request focus so the first item is focused
  /// once the screen is actually shown.
  @override
  void focusActiveTabIfReady() {
    if (_selectedLibraryGlobalKey == null) return;
    _focusCurrentTab();
  }

  /// Focus the currently selected tab chip in the tab bar.
  /// Called when BACK is pressed in tab content.
  void focusTabBar() {
    setState(() {
      _suppressAutoFocus = true;
    });
    final focusNode = _getTabChipFocusNode(_tabController.index);
    focusNode.requestFocus();
  }

  /// Get the focus node for a tab chip by index
  FocusNode _getTabChipFocusNode(int index) {
    switch (index) {
      case 0:
        return _recommendedTabChipFocusNode;
      case 1:
        return _browseTabChipFocusNode;
      case 2:
        return _collectionsTabChipFocusNode;
      case 3:
        return _playlistsTabChipFocusNode;
      default:
        return _recommendedTabChipFocusNode;
    }
  }

  /// Handle BACK from tab bar - navigate to sidenav
  void _onTabBarBack() {
    final focusScope = MainScreenFocusScope.of(context);
    focusScope?.focusSidebar();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _cancelToken?.cancel();
    _recommendedTabChipFocusNode.dispose();
    _browseTabChipFocusNode.dispose();
    _collectionsTabChipFocusNode.dispose();
    _playlistsTabChipFocusNode.dispose();
    // Clear L1/R1 callbacks
    GamepadService.onL1Pressed = null;
    GamepadService.onR1Pressed = null;
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
    final uniqueServerIds = _allLibraries.where((lib) => lib.serverId != null).map((lib) => lib.serverId).toSet();
    return uniqueServerIds.length > 1;
  }

  Future<void> _loadLibraries() async {
    // Extract context dependencies before async gap
    final multiServerProvider = Provider.of<MultiServerProvider>(context, listen: false);
    final hiddenLibrariesProvider = Provider.of<HiddenLibrariesProvider>(context, listen: false);

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
      final allLibraries = await multiServerProvider.aggregationService.getLibrariesFromAllServers();

      // Filter out music libraries (type: 'artist') since music playback is not yet supported
      // Only show movie and TV show libraries
      final filteredLibraries = allLibraries.where((lib) => !ContentTypeHelper.isMusicLibrary(lib)).toList();

      // Load saved library order and apply it
      final savedOrder = storage.getLibraryOrder();
      final orderedLibraries = _applyLibraryOrder(filteredLibraries, savedOrder);

      _updateState(() {
        _allLibraries = orderedLibraries; // Store all libraries with ordering applied
        _isLoadingLibraries = false;
      });

      if (allLibraries.isNotEmpty) {
        // Compute visible libraries for initial load
        final hiddenKeys = hiddenLibrariesProvider.hiddenLibraryKeys;
        final visibleLibraries = allLibraries.where((lib) => !hiddenKeys.contains(lib.globalKey)).toList();

        // Load saved preferences
        final savedLibraryKey = storage.getSelectedLibraryKey();

        // Find the library by key in visible libraries
        String? libraryGlobalKeyToLoad;
        if (savedLibraryKey != null) {
          // Check if saved library exists and is visible
          final libraryExists = visibleLibraries.any((lib) => lib.globalKey == savedLibraryKey);
          if (libraryExists) {
            libraryGlobalKeyToLoad = savedLibraryKey;
          }
        }

        // Fallback to first visible library if saved key not found
        if (libraryGlobalKeyToLoad == null && visibleLibraries.isNotEmpty) {
          libraryGlobalKeyToLoad = visibleLibraries.first.globalKey;
        }

        if (libraryGlobalKeyToLoad != null && mounted) {
          final savedFilters = storage.getLibraryFilters(sectionId: libraryGlobalKeyToLoad);
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

  List<PlexLibrary> _applyLibraryOrder(List<PlexLibrary> libraries, List<String>? savedOrder) {
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
    widget.onLibraryOrderChanged?.call();
  }

  /// Public method to load a library by key (called from MainScreen side nav)
  @override
  void loadLibraryByKey(String libraryGlobalKey) {
    // User explicitly selected a library from the side nav – default to Recommended
    _forceRecommendedTabOnNextLoad = true;
    _loadLibraryContent(libraryGlobalKey);
  }

  Future<void> _loadLibraryContent(String libraryGlobalKey) async {
    // Compute visible libraries based on current provider state
    final hiddenLibrariesProvider = Provider.of<HiddenLibrariesProvider>(context, listen: false);
    final hiddenKeys = hiddenLibrariesProvider.hiddenLibraryKeys;
    final visibleLibraries = _allLibraries.where((lib) => !hiddenKeys.contains(lib.globalKey)).toList();

    // Find the library by key
    final libraryIndex = visibleLibraries.indexWhere((lib) => lib.globalKey == libraryGlobalKey);
    if (libraryIndex == -1) return; // Library not found or hidden

    final library = visibleLibraries[libraryIndex];

    final isChangingLibrary = !_isInitialLoad && _selectedLibraryGlobalKey != libraryGlobalKey;

    // Get the correct client for this library's server
    final client = context.getClientForLibrary(library);

    _updateState(() {
      _selectedLibraryGlobalKey = libraryGlobalKey;
      _errorMessage = null;
      // Clear loaded tabs tracking for new library
      _loadedTabs.clear();
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

    // Determine which tab should be active
    int? tabToActivate;
    if (_forceRecommendedTabOnNextLoad) {
      // Force Recommended when coming from side nav
      tabToActivate = 0;
    } else {
      // Otherwise restore saved tab for this library
      final savedTabIndex = storage.getLibraryTab(libraryGlobalKey);
      if (savedTabIndex != null && savedTabIndex >= 0 && savedTabIndex < 4) {
        tabToActivate = savedTabIndex;
      }
    }

    if (tabToActivate != null) {
      // Set flag to prevent _onTabChanged from triggering focus
      _isRestoringTab = true;
      _tabController.animateTo(tabToActivate, duration: Duration.zero);
      _isRestoringTab = false;
      // Persist the tab choice if we forced it (keeps behavior consistent next open)
      if (_forceRecommendedTabOnNextLoad) {
        await storage.saveLibraryTab(libraryGlobalKey, tabToActivate);
      }
    }

    // Reset the force flag after applying
    _forceRecommendedTabOnNextLoad = false;

    // Focus is handled by onDataLoaded callbacks from each tab.
    // However, on first load the tab might finish loading before the tab index
    // is restored. Check if the current tab has already loaded and focus if so.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedLibraryGlobalKey == libraryGlobalKey && _loadedTabs.contains(_tabController.index)) {
        _focusCurrentTab();
      }
    });

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
      await _loadAllPagesSequentially(library, filtersWithSort, currentRequestId, client);
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
            .map((item) => item.copyWith(serverId: library.serverId, serverName: library.serverName))
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
          savedSort = sortOptions.firstWhere((s) => s.key == sortKey, orElse: () => sortOptions.first);
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
      filtersWithSort['sort'] = _selectedSort!.getSortKey(descending: _isSortDescending);
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
  @override
  void fullRefresh() {
    appLogger.d('LibrariesScreen.fullRefresh() called - reloading all content');
    // Reload libraries and clear any selected library/filters
    _selectedLibraryGlobalKey = null;
    _selectedFilters.clear();
    _items.clear();
    _loadLibraries();
  }

  Future<void> _toggleLibraryVisibility(PlexLibrary library) async {
    final hiddenLibrariesProvider = Provider.of<HiddenLibrariesProvider>(context, listen: false);
    final isHidden = hiddenLibrariesProvider.hiddenLibraryKeys.contains(library.globalKey);

    if (isHidden) {
      await hiddenLibrariesProvider.unhideLibrary(library.globalKey);
    } else {
      // Check if we're hiding the currently selected library
      final isCurrentlySelected = _selectedLibraryGlobalKey == library.globalKey;

      await hiddenLibrariesProvider.hideLibrary(library.globalKey);

      // If we just hid the selected library, select the first visible one
      if (isCurrentlySelected) {
        // Compute visible libraries after hiding
        final visibleLibraries = _allLibraries
            .where((lib) => !hiddenLibrariesProvider.hiddenLibraryKeys.contains(lib.globalKey))
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
        icon: Symbols.refresh_rounded,
        label: t.libraries.scanLibraryFiles,
        requiresConfirmation: true,
        confirmationTitle: t.libraries.scanLibrary,
        confirmationMessage: t.libraries.scanLibraryConfirm(title: library.title),
      ),
      ContextMenuItem(
        value: 'analyze',
        icon: Symbols.analytics_rounded,
        label: t.libraries.analyze,
        requiresConfirmation: true,
        confirmationTitle: t.libraries.analyzeLibrary,
        confirmationMessage: t.libraries.analyzeLibraryConfirm(title: library.title),
      ),
      ContextMenuItem(
        value: 'refresh',
        icon: Symbols.sync_rounded,
        label: t.libraries.refreshMetadata,
        requiresConfirmation: true,
        confirmationTitle: t.libraries.refreshMetadata,
        confirmationMessage: t.libraries.refreshMetadataConfirm(title: library.title),
        isDestructive: true,
      ),
      ContextMenuItem(
        value: 'empty_trash',
        icon: Symbols.delete_outline_rounded,
        label: t.libraries.emptyTrash,
        requiresConfirmation: true,
        confirmationTitle: t.libraries.emptyTrash,
        confirmationMessage: t.libraries.emptyTrashConfirm(title: library.title),
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
    final hiddenLibrariesProvider = Provider.of<HiddenLibrariesProvider>(context, listen: false);

    if (PlatformDetector.isTV()) {
      showDialog(
        context: context,
        builder: (context) => _LibraryManagementSheet(
          isDialog: true,
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
    } else {
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
        showAppSnackBar(context, progressMessage, duration: const Duration(seconds: 2));
      }

      await action(client);

      if (mounted) {
        showSuccessSnackBar(context, successMessage);
      }
    } catch (e) {
      appLogger.e('Library action failed', error: e);
      if (mounted) {
        showErrorSnackBar(context, failureMessage(e));
      }
    }
  }

  Future<void> _scanLibrary(PlexLibrary library) async {
    return _performLibraryAction(
      library: library,
      action: (client) => client.scanLibrary(library.key),
      progressMessage: t.messages.libraryScanning(title: library.title),
      successMessage: t.messages.libraryScanStarted(title: library.title),
      failureMessage: (error) => t.messages.libraryScanFailed(error: error.toString()),
    );
  }

  Future<void> _refreshLibraryMetadata(PlexLibrary library) async {
    return _performLibraryAction(
      library: library,
      action: (client) => client.refreshLibraryMetadata(library.key),
      progressMessage: t.messages.metadataRefreshing(title: library.title),
      successMessage: t.messages.metadataRefreshStarted(title: library.title),
      failureMessage: (error) => t.messages.metadataRefreshFailed(error: error.toString()),
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

  /// Get set of library names that appear more than once (not globally unique)
  Set<String> _getNonUniqueLibraryNames(List<PlexLibrary> libraries) {
    final nameCounts = <String, int>{};
    for (final lib in libraries) {
      nameCounts[lib.title] = (nameCounts[lib.title] ?? 0) + 1;
    }
    return nameCounts.entries.where((e) => e.value > 1).map((e) => e.key).toSet();
  }

  /// Build dropdown menu items with server subtitle for non-unique names
  List<PopupMenuEntry<String>> _buildGroupedLibraryMenuItems(List<PlexLibrary> visibleLibraries) {
    // Find which library names are not unique
    final nonUniqueNames = _getNonUniqueLibraryNames(visibleLibraries);

    return visibleLibraries.map((library) {
      final isSelected = library.globalKey == _selectedLibraryGlobalKey;
      final showServerName = nonUniqueNames.contains(library.title) && library.serverName != null;

      return PopupMenuItem<String>(
        value: library.globalKey,
        child: Row(
          children: [
            AppIcon(
              ContentTypeHelper.getLibraryIcon(library.type),
              fill: 1,
              size: 20,
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    library.title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  if (showServerName)
                    Text(
                      library.serverName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTabChip(String label, int index) {
    final isSelected = _tabController.index == index;
    const tabCount = 4; // Recommended, Browse, Collections, Playlists

    return FocusableTabChip(
      label: label,
      isSelected: isSelected,
      focusNode: _getTabChipFocusNode(index),
      onSelect: () {
        if (isSelected) {
          // Already selected - navigate to tab content
          _focusCurrentTab();
        } else {
          // Switch to this tab
          setState(() {
            _tabController.index = index;
          });
        }
      },
      onNavigateLeft: index > 0
          ? () {
              final newIndex = index - 1;
              setState(() {
                _suppressAutoFocus = true;
                _tabController.index = newIndex;
              });
              _getTabChipFocusNode(newIndex).requestFocus();
            }
          : null,
      onNavigateRight: index < tabCount - 1
          ? () {
              final newIndex = index + 1;
              setState(() {
                _suppressAutoFocus = true;
                _tabController.index = newIndex;
              });
              _getTabChipFocusNode(newIndex).requestFocus();
            }
          : null,
      onNavigateDown: _focusCurrentTab,
      onBack: _onTabBarBack,
    );
  }

  /// Build the app bar title - either dropdown on mobile or simple title on desktop
  Widget _buildAppBarTitle(List<PlexLibrary> visibleLibraries) {
    // No libraries or no selection
    if (visibleLibraries.isEmpty || _selectedLibraryGlobalKey == null) {
      return Text(t.libraries.title);
    }

    // On desktop/TV with side nav, show tabs in app bar (library name is in side nav)
    if (PlatformDetector.shouldUseSideNavigation(context)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabChip(t.libraries.tabs.recommended, 0),
          const SizedBox(width: 8),
          _buildTabChip(t.libraries.tabs.browse, 1),
          const SizedBox(width: 8),
          _buildTabChip(t.libraries.tabs.collections, 2),
          const SizedBox(width: 8),
          _buildTabChip(t.libraries.tabs.playlists, 3),
        ],
      );
    }

    // On mobile, show the dropdown
    return _buildLibraryDropdownTitle(visibleLibraries);
  }

  Widget _buildLibraryDropdownTitle(List<PlexLibrary> visibleLibraries) {
    final selectedLibrary = visibleLibraries.firstWhere(
      (lib) => lib.globalKey == _selectedLibraryGlobalKey,
      orElse: () => visibleLibraries.first,
    );

    return PopupMenuButton<String>(
      key: _libraryDropdownKey,
      offset: const Offset(0, 48),
      tooltip: t.libraries.selectLibrary,
      onSelected: (libraryGlobalKey) {
        _loadLibraryContent(libraryGlobalKey);
      },
      itemBuilder: (context) => _buildGroupedLibraryMenuItems(visibleLibraries),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(ContentTypeHelper.getLibraryIcon(selectedLibrary.type), fill: 1, size: 20),
            const SizedBox(width: 8),
            if (_hasMultipleServers && selectedLibrary.serverName != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(selectedLibrary.title, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    selectedLibrary.serverName!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              )
            else
              Text(selectedLibrary.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 4),
            const AppIcon(Symbols.arrow_drop_down_rounded, fill: 1, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch for hidden libraries changes to trigger rebuild
    final hiddenLibrariesProvider = context.watch<HiddenLibrariesProvider>();
    final hiddenKeys = hiddenLibrariesProvider.hiddenLibraryKeys;

    // Compute visible libraries (filtered from all libraries)
    final visibleLibraries = _allLibraries.where((lib) => !hiddenKeys.contains(lib.globalKey)).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          DesktopSliverAppBar(
            title: _buildAppBarTitle(visibleLibraries),
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            scrolledUnderElevation: 0,
            actions: [
              if (_allLibraries.isNotEmpty)
                IconButton(
                  icon: const AppIcon(Symbols.edit_rounded, fill: 1),
                  tooltip: t.libraries.manageLibraries,
                  onPressed: _showLibraryManagementSheet,
                ),
              IconButton(
                icon: const AppIcon(Symbols.refresh_rounded, fill: 1),
                tooltip: t.common.refresh,
                onPressed: _refreshCurrentTab,
              ),
            ],
          ),
          if (_isLoadingLibraries)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null && visibleLibraries.isEmpty)
            SliverFillRemaining(
              child: ErrorStateWidget(
                message: _errorMessage!,
                icon: Symbols.error_outline_rounded,
                onRetry: _loadLibraries,
              ),
            )
          else if (visibleLibraries.isEmpty)
            SliverFillRemaining(
              child: EmptyStateWidget(message: t.libraries.noLibrariesFound, icon: Symbols.video_library_rounded),
            )
          else ...[
            // Tab selector chips (only on mobile - desktop has them in app bar)
            if (_selectedLibraryGlobalKey != null && !PlatformDetector.shouldUseSideNavigation(context))
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  key: ValueKey(_selectedLibraryGlobalKey),
                  controller: _tabController,
                  // Disable swipe on desktop - trackpad scrolling triggers accidental tab switches
                  // See: https://github.com/flutter/flutter/issues/11132
                  physics: PlatformDetector.isDesktop(context)
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  children: [
                    LibraryRecommendedTab(
                      key: _recommendedTabKey,
                      library: _allLibraries.firstWhere((lib) => lib.globalKey == _selectedLibraryGlobalKey),
                      isActive: _tabController.index == 0,
                      suppressAutoFocus: _suppressAutoFocus,
                      onDataLoaded: () => _handleTabDataLoaded(0),
                      onBack: focusTabBar,
                    ),
                    LibraryBrowseTab(
                      key: _browseTabKey,
                      library: _allLibraries.firstWhere((lib) => lib.globalKey == _selectedLibraryGlobalKey),
                      isActive: _tabController.index == 1,
                      suppressAutoFocus: _suppressAutoFocus,
                      onDataLoaded: () => _handleTabDataLoaded(1),
                      onBack: focusTabBar,
                    ),
                    LibraryCollectionsTab(
                      key: _collectionsTabKey,
                      library: _allLibraries.firstWhere((lib) => lib.globalKey == _selectedLibraryGlobalKey),
                      isActive: _tabController.index == 2,
                      suppressAutoFocus: _suppressAutoFocus,
                      onDataLoaded: () => _handleTabDataLoaded(2),
                      onBack: focusTabBar,
                    ),
                    LibraryPlaylistsTab(
                      key: _playlistsTabKey,
                      library: _allLibraries.firstWhere((lib) => lib.globalKey == _selectedLibraryGlobalKey),
                      isActive: _tabController.index == 3,
                      suppressAutoFocus: _suppressAutoFocus,
                      onDataLoaded: () => _handleTabDataLoaded(3),
                      onBack: focusTabBar,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LibraryManagementSheet extends StatefulWidget {
  final bool isDialog;
  final List<PlexLibrary> allLibraries;
  final Set<String> hiddenLibraryKeys;
  final Function(List<PlexLibrary>) onReorder;
  final Function(PlexLibrary) onToggleVisibility;
  final List<ContextMenuItem> Function(PlexLibrary) getLibraryMenuItems;
  final void Function(String action, PlexLibrary library) onLibraryMenuAction;

  const _LibraryManagementSheet({
    this.isDialog = false,
    required this.allLibraries,
    required this.hiddenLibraryKeys,
    required this.onReorder,
    required this.onToggleVisibility,
    required this.getLibraryMenuItems,
    required this.onLibraryMenuAction,
  });

  @override
  State<_LibraryManagementSheet> createState() => _LibraryManagementSheetState();
}

class _LibraryManagementSheetState extends State<_LibraryManagementSheet> {
  late List<PlexLibrary> _tempLibraries;

  // Keyboard navigation state
  int _focusedIndex = 0;
  int _focusedColumn = 0; // 0 = row, 1 = visibility button, 2 = options button
  int? _movingIndex; // Non-null when in move mode
  int? _originalIndex; // Original position before move (for cancel)
  List<PlexLibrary>? _originalOrder; // Original order before move (for cancel)
  final FocusNode _listFocusNode = FocusNode();
  final Map<int, GlobalKey> _tileKeys = {}; // For dialog mode scroll-into-view

  @override
  void initState() {
    super.initState();
    _tempLibraries = List.from(widget.allLibraries);
  }

  @override
  void dispose() {
    _listFocusNode.dispose();
    super.dispose();
  }

  void _ensureFocusedVisible() {
    if (!widget.isDialog) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _tileKeys[_focusedIndex];
      final context = key?.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.25,
          duration: const Duration(milliseconds: 200),
        );
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (_movingIndex != null) {
      // Move mode - arrows reorder the item
      if (key.isUpKey && _movingIndex! > 0) {
        setState(() {
          final item = _tempLibraries.removeAt(_movingIndex!);
          _tempLibraries.insert(_movingIndex! - 1, item);
          _movingIndex = _movingIndex! - 1;
          _focusedIndex = _movingIndex!;
        });
        return KeyEventResult.handled;
      }
      if (key.isDownKey && _movingIndex! < _tempLibraries.length - 1) {
        setState(() {
          final item = _tempLibraries.removeAt(_movingIndex!);
          _tempLibraries.insert(_movingIndex! + 1, item);
          _movingIndex = _movingIndex! + 1;
          _focusedIndex = _movingIndex!;
        });
        return KeyEventResult.handled;
      }
      if (key.isSelectKey) {
        // Confirm move - apply the reorder
        widget.onReorder(_tempLibraries);
        setState(() {
          _movingIndex = null;
          _originalIndex = null;
          _originalOrder = null;
        });
        return KeyEventResult.handled;
      }
      if (key.isBackKey) {
        // Cancel move - restore original position
        setState(() {
          if (_originalOrder != null) {
            _tempLibraries = List.from(_originalOrder!);
          }
          _focusedIndex = _originalIndex ?? 0;
          _movingIndex = null;
          _originalIndex = null;
          _originalOrder = null;
        });
        return KeyEventResult.handled;
      }
    } else {
      // Navigation mode
      if (key.isUpKey && _focusedIndex > 0) {
        setState(() {
          _focusedIndex--;
          _focusedColumn = 0; // Reset to row when changing rows
        });
        _ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isDownKey && _focusedIndex < _tempLibraries.length - 1) {
        setState(() {
          _focusedIndex++;
          _focusedColumn = 0; // Reset to row when changing rows
        });
        _ensureFocusedVisible();
        return KeyEventResult.handled;
      }
      if (key.isLeftKey && _focusedColumn > 0) {
        setState(() => _focusedColumn--);
        return KeyEventResult.handled;
      }
      if (key.isRightKey && _focusedColumn < 2) {
        setState(() => _focusedColumn++);
        return KeyEventResult.handled;
      }
      if (key.isSelectKey) {
        if (_focusedColumn == 0) {
          // Enter move mode
          setState(() {
            _movingIndex = _focusedIndex;
            _originalIndex = _focusedIndex;
            _originalOrder = List.from(_tempLibraries);
          });
        } else if (_focusedColumn == 1) {
          // Toggle visibility
          final library = _tempLibraries[_focusedIndex];
          widget.onToggleVisibility(library);
        } else if (_focusedColumn == 2) {
          // Show options menu
          final library = _tempLibraries[_focusedIndex];
          _showLibraryMenuBottomSheet(context, library);
        }
        return KeyEventResult.handled;
      }
      if (key.isBackKey) {
        Navigator.pop(context);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _reorderLibraries(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final library = _tempLibraries.removeAt(oldIndex);
      _tempLibraries.insert(newIndex, library);
      if (widget.isDialog) {
        _tileKeys.clear();
      }
    });
    // Apply immediately
    widget.onReorder(_tempLibraries);
  }

  Future<void> _showLibraryMenuBottomSheet(BuildContext outerContext, PlexLibrary library) async {
    final menuItems = widget.getLibraryMenuItems(library);
    final selected = await showModalBottomSheet<String>(
      context: outerContext,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(library.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ...menuItems.indexed.map(
              (entry) => ListTile(
                leading: AppIcon(entry.$2.icon, fill: 1),
                title: Text(entry.$2.label),
                onTap: () => Navigator.pop(context, entry.$2.value),
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      // Find the selected item to check if confirmation is needed
      final selectedItem = menuItems.firstWhere((item) => item.value == selected);

      if (selectedItem.requiresConfirmation) {
        if (!mounted || !context.mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(selectedItem.confirmationTitle ?? t.dialog.confirmAction),
            content: Text(selectedItem.confirmationMessage ?? t.libraries.confirmActionMessage),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.common.cancel)),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: selectedItem.isDestructive ? TextButton.styleFrom(foregroundColor: Colors.red) : null,
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

  /// Get set of library names that appear more than once (not globally unique)
  Set<String> _getNonUniqueLibraryNames() {
    final nameCounts = <String, int>{};
    for (final lib in _tempLibraries) {
      nameCounts[lib.title] = (nameCounts[lib.title] ?? 0) + 1;
    }
    return nameCounts.entries.where((e) => e.value > 1).map((e) => e.key).toSet();
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider to rebuild when hidden libraries change
    final hiddenLibrariesProvider = context.watch<HiddenLibrariesProvider>();
    final hiddenLibraryKeys = hiddenLibrariesProvider.hiddenLibraryKeys;

    if (widget.isDialog) {
      return Dialog(
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const AppIcon(Symbols.edit_rounded, fill: 1),
                const SizedBox(width: 12),
                Text(t.libraries.manageLibraries),
              ],
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const AppIcon(Symbols.close_rounded, fill: 1),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: Focus(
            focusNode: _listFocusNode,
            autofocus: InputModeTracker.isKeyboardMode(context),
            onKeyEvent: _handleKeyEvent,
            child: _buildFlatLibraryListDialog(hiddenLibraryKeys),
          ),
        ),
      );
    }

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
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                children: [
                  const AppIcon(Symbols.edit_rounded, fill: 1),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.libraries.manageLibraries,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const AppIcon(Symbols.close_rounded, fill: 1),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Library list (grouped by server if multiple servers)
            Expanded(
              child: Focus(
                focusNode: _listFocusNode,
                autofocus: InputModeTracker.isKeyboardMode(context),
                onKeyEvent: _handleKeyEvent,
                child: _buildFlatLibraryList(scrollController, hiddenLibraryKeys),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build library list for dialog (TV) using ListView with scroll-into-view support
  Widget _buildFlatLibraryListDialog(Set<String> hiddenLibraryKeys) {
    final nonUniqueNames = _getNonUniqueLibraryNames();
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);

    return ReorderableListView.builder(
      onReorder: _reorderLibraries,
      itemCount: _tempLibraries.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final library = _tempLibraries[index];
        final showServerName = nonUniqueNames.contains(library.title) && library.serverName != null;
        final isFocused = isKeyboardMode && index == _focusedIndex;
        final isMoving = index == _movingIndex;

        _tileKeys.putIfAbsent(index, () => GlobalKey());

        return _buildLibraryTile(
          library,
          index,
          hiddenLibraryKeys,
          showServerName: showServerName,
          isFocused: isFocused,
          isMoving: isMoving,
          focusedColumn: isFocused ? _focusedColumn : null,
          tileKey: _tileKeys[index],
        );
      },
    );
  }

  /// Build flat library list with server subtitle for non-unique names
  Widget _buildFlatLibraryList(ScrollController scrollController, Set<String> hiddenLibraryKeys) {
    final nonUniqueNames = _getNonUniqueLibraryNames();
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);

    return ReorderableListView.builder(
      scrollController: scrollController,
      onReorder: _reorderLibraries,
      itemCount: _tempLibraries.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final library = _tempLibraries[index];
        final showServerName = nonUniqueNames.contains(library.title) && library.serverName != null;
        final isFocused = isKeyboardMode && index == _focusedIndex;
        final isMoving = index == _movingIndex;
        return _buildLibraryTile(
          library,
          index,
          hiddenLibraryKeys,
          showServerName: showServerName,
          isFocused: isFocused,
          isMoving: isMoving,
          focusedColumn: isFocused ? _focusedColumn : null,
        );
      },
    );
  }

  /// Build a single library tile
  Widget _buildLibraryTile(
    PlexLibrary library,
    int index,
    Set<String> hiddenLibraryKeys, {
    bool showServerName = false,
    bool isFocused = false,
    bool isMoving = false,
    int? focusedColumn,
    Key? tileKey,
  }) {
    final isHidden = hiddenLibraryKeys.contains(library.globalKey);
    final colorScheme = Theme.of(context).colorScheme;

    // Determine background color based on state
    Color? tileColor;
    if (isMoving) {
      tileColor = colorScheme.primaryContainer;
    } else if (isFocused && focusedColumn == 0) {
      // Only highlight row when row itself is focused (column 0)
      tileColor = colorScheme.surfaceContainerHighest;
    }

    // Button focus states
    final isVisibilityButtonFocused = isFocused && focusedColumn == 1;
    final isOptionsButtonFocused = isFocused && focusedColumn == 2;

    return Opacity(
      key: tileKey ?? ValueKey(library.globalKey),
      opacity: isHidden ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(color: tileColor),
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReorderableDragStartListener(
                index: index,
                child: AppIcon(
                  isMoving ? Symbols.swap_vert_rounded : Symbols.drag_indicator_rounded,
                  fill: 1,
                  color: isMoving ? colorScheme.primary : IconTheme.of(context).color?.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              AppIcon(ContentTypeHelper.getLibraryIcon(library.type), fill: 1),
            ],
          ),
          title: Text(library.title),
          subtitle: showServerName
              ? Text(
                  library.serverName!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: isVisibilityButtonFocused
                    ? BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20))
                    : null,
                child: IconButton(
                  icon: AppIcon(isHidden ? Symbols.visibility_off_rounded : Symbols.visibility_rounded, fill: 1),
                  tooltip: isHidden ? t.libraries.showLibrary : t.libraries.hideLibrary,
                  onPressed: () => widget.onToggleVisibility(library),
                ),
              ),
              Container(
                decoration: isOptionsButtonFocused
                    ? BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20))
                    : null,
                child: IconButton(
                  icon: const AppIcon(Symbols.more_vert_rounded, fill: 1),
                  tooltip: t.libraries.libraryOptions,
                  onPressed: () => _showLibraryMenuBottomSheet(context, library),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
