import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../focus/focusable_action_bar.dart';
import '../../focus/dpad_navigator.dart';
import '../../focus/input_mode_tracker.dart';
import '../../mixins/tab_navigation_mixin.dart';
import '../../media/ids.dart';
import '../../media/media_item.dart';
import '../../media/media_library.dart';
import '../../providers/hidden_libraries_provider.dart';
import '../../providers/libraries_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings_builder.dart';
import '../../utils/app_logger.dart';
import '../../utils/library_grouping.dart';
import '../../utils/platform_detector.dart';
import '../../utils/content_utils.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/backend_badge.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../widgets/focusable_tab_chip.dart';
import '../../widgets/library_management_sheet.dart';
import '../../services/storage_service.dart';
import '../../mixins/refreshable.dart';
import '../../mixins/item_updatable.dart';
import '../../i18n/strings.g.dart';
import 'state_messages.dart';
import 'tabs/library_browse_tab.dart';
import 'tabs/library_recommended_tab.dart';
import 'tabs/library_collections_tab.dart';
import 'tabs/library_playlists_tab.dart';

enum LibraryTabType { recommended, browse, collections, playlists }

List<LibraryTabType> _getVisibleTabs(MediaLibrary library) {
  if (library.isShared) return [LibraryTabType.browse, LibraryTabType.playlists];
  return LibraryTabType.values;
}

class LibrariesScreen extends StatefulWidget {
  final VoidCallback? onLibraryOrderChanged;
  final ValueChanged<String>? onLibrarySelected;

  const LibrariesScreen({super.key, this.onLibraryOrderChanged, this.onLibrarySelected});

  @override
  State<LibrariesScreen> createState() => _LibrariesScreenState();
}

class _LibrariesScreenState extends State<LibrariesScreen>
    with
        Refreshable,
        FullRefreshable,
        FocusableTab,
        LibraryLoadable,
        ItemUpdatable,
        TickerProviderStateMixin,
        TabNavigationMixin {
  // GlobalKeys for tabs to enable refresh
  final _recommendedTabKey = GlobalKey();
  final _browseTabKey = GlobalKey();
  final _collectionsTabKey = GlobalKey();
  final _playlistsTabKey = GlobalKey();

  String? _errorMessage;
  String? _selectedLibraryGlobalKey;
  bool _isInitialLoad = true;

  /// Flag to prevent onTabChanged from focusing when we're programmatically changing tabs
  bool _isRestoringTab = false;

  /// Track which tabs have loaded data (used to trigger focus after tab restore)
  final Set<int> _loadedTabs = {};

  /// Whether the browse tab has active filters (badges the Library options icon)
  bool _browseFiltersActive = false;

  /// Key for the library dropdown menu button.
  final _libraryDropdownKey = GlobalKey<AppMenuButtonState<String>>();

  // Dynamic visible tabs and their focus nodes
  List<LibraryTabType> _visibleTabs = LibraryTabType.values;
  List<FocusNode> _tabFocusNodes = List.generate(
    LibraryTabType.values.length,
    (i) => FocusNode(debugLabel: 'tab_chip_${LibraryTabType.values[i].name}'),
  );

  @override
  List<FocusNode> get tabChipFocusNodes => _tabFocusNodes;

  // App bar action bar
  final _actionBarKey = GlobalKey<FocusableActionBarState>();

  // Scroll controller for the outer CustomScrollView
  final ScrollController _outerScrollController = ScrollController();

  /// Reveal the floating header by jumping the outer NestedScrollView back
  /// to offset 0. The outer position is preserved across content changes
  /// (library switch, library reload, filter/sort change), so any time the
  /// inner is reset to the top we must explicitly resync the outer — the
  /// natural delta-surrender coordination only fires on user scroll gestures.
  ///
  /// Iterates `positions` rather than reading `offset` because the controller
  /// is shared between the simple CustomScrollView (loading/empty/error) and
  /// the NestedScrollView (selected library), and during the transition both
  /// can briefly be attached — `offset` would throw on `_positions.single`.
  void _resetOuterScroll() {
    if (!_outerScrollController.hasClients) return;
    for (final position in _outerScrollController.positions) {
      if (position.pixels > 0) {
        position.jumpTo(0);
      }
    }
  }

  /// Override the mixin's [focusTabBar] so we reveal the floating header
  /// (which contains the tab chips) before requesting focus. Programmatic
  /// requestFocus alone does not snap a floating SliverAppBar back into view.
  @override
  void focusTabBar() {
    _resetOuterScroll();
    super.focusTabBar();
  }

  @override
  void initState() {
    super.initState();
    initTabNavigation();

    // Initialize with libraries from the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeWithLibraries();
    });
  }

  /// Initialize the screen with libraries from the provider.
  /// This handles initial library selection and content loading.
  Future<void> _initializeWithLibraries() async {
    final librariesProvider = context.read<LibrariesProvider>();
    final hiddenLibrariesProvider = context.read<HiddenLibrariesProvider>();
    await hiddenLibrariesProvider.ensureInitialized();
    final allLibraries = librariesProvider.libraries;

    if (allLibraries.isEmpty) {
      // No libraries available yet
      return;
    }

    // Compute visible libraries for initial load
    final hiddenKeys = hiddenLibrariesProvider.hiddenLibraryKeys;
    final visibleLibraries = allLibraries.where((lib) => !hiddenKeys.contains(lib.globalKey)).toList();

    // Load saved preferences
    final storage = await StorageService.getInstance();
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
      unawaited(_loadLibraryContent(libraryGlobalKeyToLoad));
    }
  }

  @override
  void onTabChanged() {
    // Save tab name when changed (but not when restoring from storage)
    if (_selectedLibraryGlobalKey != null && !tabController.indexIsChanging) {
      // Only save if this was a user-initiated tab change, not a restore
      if (!_isRestoringTab) {
        StorageService.getInstance().then((storage) {
          storage.saveLibraryTab(_selectedLibraryGlobalKey!, _visibleTabs[tabController.index].name);
        });

        // Focus first item in the current tab (only for user-initiated changes)
        // But not when navigating via tab bar (suppressAutoFocus is true)
        if (!suppressAutoFocus) {
          _focusCurrentTab();
        }
      }
    }
    // Rebuild to update chip selection state
    super.onTabChanged();
  }

  /// Focus the first item in the currently active tab.
  /// Used for initial load and tab switching - focuses the grid content directly.
  void _focusCurrentTab() {
    // Don't focus during tab animations - wait for animation to complete
    // This prevents race conditions during focus restoration
    if (tabController.indexIsChanging) {
      return;
    }
    // On mobile (touch mode), skip auto-focus to prevent ensureVisible()
    // from interfering with TabBarView page animations
    if (!InputModeTracker.isKeyboardMode(context)) return;

    // Re-enable auto-focus since user is navigating into tab content
    // Only call setState if the value actually changes to avoid unnecessary rebuilds
    if (suppressAutoFocus) {
      setState(() {
        suppressAutoFocus = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final tabState = _getTabState(tabController.index);
      if (tabState != null) {
        (tabState as dynamic).focusContentOrChrome();
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
    final tabState = _getTabState(tabController.index);
    if (tabState != null) {
      (tabState as dynamic).focusContentOrChrome();
    }
  }

  /// Focus tab content when navigating DOWN from the tab bar.
  /// For browse tab, this focuses the chips bar first so DOWN navigates to grid.
  /// For other tabs, focuses the first item directly.
  void _focusCurrentTabFromTabBar() {
    if (tabController.indexIsChanging) {
      return;
    }

    if (suppressAutoFocus) {
      setState(() {
        suppressAutoFocus = false;
      });
    }

    // Scroll outer view to top to ensure tab content (including chips bar) is visible
    _resetOuterScroll();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final tabState = _getTabState(tabController.index);
      if (tabState != null) {
        // Browse tab has a chips bar - focus that first so DOWN navigates to grid
        if (_visibleTabs[tabController.index] == LibraryTabType.browse) {
          (tabState as dynamic).focusChipsBar();
        } else {
          (tabState as dynamic).focusContentOrChrome();
        }
      }
    });
  }

  /// Get the state for a tab by index
  State? _getTabState(int index) {
    if (index < 0 || index >= _visibleTabs.length) return null;
    return switch (_visibleTabs[index]) {
      LibraryTabType.recommended => _recommendedTabKey.currentState,
      LibraryTabType.browse => _browseTabKey.currentState,
      LibraryTabType.collections => _collectionsTabKey.currentState,
      LibraryTabType.playlists => _playlistsTabKey.currentState,
    };
  }

  void _showBrowseOptionsForCurrentTab() {
    if (_visibleTabs.isEmpty) return;
    final index = tabController.index.clamp(0, _visibleTabs.length - 1).toInt();
    if (_visibleTabs[index] != LibraryTabType.browse) return;
    final tabState = _browseTabKey.currentState;
    if (tabState == null) return;
    (tabState as dynamic).showBrowseOptionsSheet();
  }

  /// Handle when the browse tab's active-filter state changes
  void _handleBrowseFiltersActiveChanged(bool active) {
    if (_browseFiltersActive == active) return;
    setState(() => _browseFiltersActive = active);
  }

  /// Handle when a tab's data has finished loading
  void _handleTabDataLoaded(int tabIndex) {
    // Track that this tab has loaded
    _loadedTabs.add(tabIndex);

    // Don't auto-focus if suppressed (e.g., when navigating via tab bar)
    if (suppressAutoFocus) return;

    // Only focus if this is the currently active tab
    if (tabController.index == tabIndex && mounted) {
      // Use post-frame callback to ensure the widget tree is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && tabController.index == tabIndex && !suppressAutoFocus) {
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

  @override
  void dispose() {
    _outerScrollController.dispose();
    for (final node in _tabFocusNodes) {
      node.dispose();
    }
    disposeTabNavigation();
    super.dispose();
  }

  void _updateState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  /// Rebuild tab infrastructure when the visible tab set changes.
  void _updateVisibleTabs(List<LibraryTabType> newTabs) {
    if (listEquals(_visibleTabs, newTabs)) return;

    // Save current tab type before changing
    final currentTabType = _visibleTabs.length > tabController.index ? _visibleTabs[tabController.index] : null;

    // Dispose old focus nodes and controller
    for (final node in _tabFocusNodes) {
      node.dispose();
    }
    disposeTabNavigation();

    // Build new
    _visibleTabs = newTabs;
    _tabFocusNodes = List.generate(newTabs.length, (i) => FocusNode(debugLabel: 'tab_chip_${newTabs[i].name}'));
    initTabNavigation();

    // Restore tab position: find current tab type in new set, default to first
    final newIndex = currentTabType != null ? newTabs.indexOf(currentTabType) : -1;
    if (newIndex > 0) {
      tabController.index = newIndex;
    }
  }

  String _getTabLabel(LibraryTabType type) => switch (type) {
    LibraryTabType.recommended => t.libraries.tabs.recommended,
    LibraryTabType.browse => t.libraries.tabs.browse,
    LibraryTabType.collections => t.libraries.tabs.collections,
    LibraryTabType.playlists => t.libraries.tabs.playlists,
  };

  Widget _buildTabContent(
    LibraryTabType type, {
    required MediaLibrary library,
    required bool canGroupByFolders,
    required bool isActive,
    required int tabIndex,
  }) {
    return switch (type) {
      LibraryTabType.recommended => LibraryRecommendedTab(
        key: _recommendedTabKey,
        library: library,
        isActive: isActive,
        suppressAutoFocus: suppressAutoFocus,
        onDataLoaded: () => _handleTabDataLoaded(tabIndex),
        onBack: focusTabBar,
        onNavigateToChrome: focusTabBar,
      ),
      LibraryTabType.browse => LibraryBrowseTab(
        key: _browseTabKey,
        library: library,
        canGroupByFolders: canGroupByFolders,
        isActive: isActive,
        suppressAutoFocus: suppressAutoFocus,
        onDataLoaded: () => _handleTabDataLoaded(tabIndex),
        onBack: focusTabBar,
        onResetScroll: _resetOuterScroll,
        onFiltersActiveChanged: _handleBrowseFiltersActiveChanged,
      ),
      LibraryTabType.collections => LibraryCollectionsTab(
        key: _collectionsTabKey,
        library: library,
        isActive: isActive,
        suppressAutoFocus: suppressAutoFocus,
        onDataLoaded: () => _handleTabDataLoaded(tabIndex),
        onBack: focusTabBar,
      ),
      LibraryTabType.playlists => LibraryPlaylistsTab(
        key: _playlistsTabKey,
        library: library,
        isActive: isActive,
        suppressAutoFocus: suppressAutoFocus,
        onDataLoaded: () => _handleTabDataLoaded(tabIndex),
        onBack: focusTabBar,
      ),
    };
  }

  /// Check if libraries come from multiple servers
  bool _hasMultipleServers(List<MediaLibrary> libraries) {
    final uniqueServerIds = libraries.where((lib) => lib.serverId != null).map((lib) => lib.serverId).toSet();
    return uniqueServerIds.length > 1;
  }

  /// Notify parent that library order changed
  void _notifyLibraryOrderChanged() {
    widget.onLibraryOrderChanged?.call();
  }

  /// Public method to load a library by key (called from MainScreen side nav)
  @override
  void loadLibraryByKey(String libraryGlobalKey) {
    _loadLibraryContent(libraryGlobalKey);
  }

  Future<void> _loadLibraryContent(String libraryGlobalKey) async {
    final librariesProvider = context.read<LibrariesProvider>();
    final allLibraries = librariesProvider.libraries;

    // Resolve from allLibraries — hidden libraries are still navigable from the
    // sidebar's "Hidden libraries" section.
    final selectedLibrary = allLibraries.where((lib) => lib.globalKey == libraryGlobalKey).firstOrNull;
    if (selectedLibrary == null) return;

    final isLibraryChange = _selectedLibraryGlobalKey != libraryGlobalKey;

    // Update visible tabs and state in the same synchronous block so no
    // intermediate rebuild can see a mismatched controller/key pair.
    _updateVisibleTabs(_getVisibleTabs(selectedLibrary));

    _updateState(() {
      _selectedLibraryGlobalKey = libraryGlobalKey;
      _errorMessage = null;
      // Clear loaded tabs tracking for new library
      _loadedTabs.clear();
    });
    widget.onLibrarySelected?.call(libraryGlobalKey);

    // The new TabBarView mounts with fresh inner positions at offset 0;
    // bring the floating header back too. Also covers the case where the
    // newly-active tab is not browse (which would otherwise have no inner
    // jumpTo to catch via the browse-tab callback).
    if (isLibraryChange) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _resetOuterScroll();
      });
    }

    // Mark that initial load is complete
    if (_isInitialLoad) {
      _isInitialLoad = false;
    }

    // Save selected library key and restore saved tab (async — safe after state is consistent)
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    await storage.saveSelectedLibraryKey(libraryGlobalKey);

    // Restore saved tab by name
    final savedTabName = storage.getLibraryTab(libraryGlobalKey);
    final savedType = LibraryTabType.values.where((t) => t.name == savedTabName).firstOrNull;
    final targetTabIndex = savedType != null ? _visibleTabs.indexOf(savedType) : -1;
    if (targetTabIndex > 0) {
      // Set flag to prevent _onTabChanged from triggering focus
      _isRestoringTab = true;
      // Use animateTo with zero duration for instant switch without animation race conditions
      tabController.animateTo(targetTabIndex, duration: Duration.zero);
      // Clear flag synchronously - animateTo with zero duration completes immediately
      _isRestoringTab = false;
    }

    // Focus is handled by onDataLoaded callbacks from each tab.
    // However, on first load the tab might finish loading before the tab index
    // is restored. Check if the current tab has already loaded and focus if so.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedLibraryGlobalKey == libraryGlobalKey && _loadedTabs.contains(tabController.index)) {
        _focusCurrentTab();
      }
    });
  }

  @override
  void updateItemInLists(String sourceGlobalKey, MediaItem updatedItem) {
    // Delegate to the active tab — parent doesn't maintain its own item list
  }

  // Public method to refresh content (for normal navigation)
  @override
  void refresh() {
    // Reinitialize with current libraries
    _initializeWithLibraries();
  }

  // Refresh every loaded tab for the selected library.
  void _refreshSelectedLibraryTabs() {
    for (var i = 0; i < _visibleTabs.length; i++) {
      final Object? tabState = _getTabState(i);
      if (tabState is Refreshable) {
        tabState.refresh();
      }
    }
  }

  // Public method to fully reload all content (for profile switches)
  @override
  void fullRefresh() {
    appLogger.d('LibrariesScreen.fullRefresh() called - reloading all content');
    setState(() {
      _selectedLibraryGlobalKey = null;
      _errorMessage = null;
    });

    // Reinitialize with current libraries from provider
    _initializeWithLibraries();
  }

  Future<void> _toggleLibraryVisibility(MediaLibrary library) async {
    if (!mounted) return;
    final librariesProvider = context.read<LibrariesProvider>();
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
        final allLibraries = librariesProvider.libraries;
        final visibleLibraries = allLibraries
            .where((lib) => !hiddenLibrariesProvider.hiddenLibraryKeys.contains(lib.globalKey))
            .toList();

        if (visibleLibraries.isNotEmpty) {
          unawaited(_loadLibraryContent(visibleLibraries.first.globalKey));
        }
      }
    }
  }

  void _showLibraryManagementSheet() {
    showLibraryManagementSheet(
      context,
      onOrderChanged: _notifyLibraryOrderChanged,
      onToggleVisibility: _toggleLibraryVisibility,
    );
  }

  Widget _buildLibraryServerLabel(
    MediaLibrary library,
    TextStyle? style, {
    double badgeSize = 11,
    bool constrainText = false,
    String? fallbackServerName,
  }) {
    final serverName = library.serverName ?? fallbackServerName;
    if (serverName == null || serverName.isEmpty) return const SizedBox.shrink();

    final text = Text(serverName, style: style, overflow: .ellipsis);
    return Row(
      mainAxisSize: .min,
      children: [
        BackendBadge(backend: library.backend, size: badgeSize, color: style?.color),
        const SizedBox(width: 4),
        if (constrainText) Flexible(child: text) else text,
      ],
    );
  }

  AppMenuHeader<String> _buildLibraryServerHeaderMenuItem(MediaLibrary library, String serverKey) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: .w600,
      letterSpacing: 0.4,
      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.65),
    );
    return AppMenuHeader<String>(
      child: _buildLibraryServerLabel(
        library,
        style,
        badgeSize: 12,
        constrainText: true,
        fallbackServerName: serverKey,
      ),
    );
  }

  AppMenuItem<String> _buildLibraryMenuItem(MediaLibrary library, {required bool showServerName}) {
    final isSelected = library.globalKey == _selectedLibraryGlobalKey;
    return AppMenuItem<String>(
      value: library.globalKey,
      icon: ContentTypeHelper.getLibraryIcon(library.kind.id),
      label: library.title,
      selected: isSelected,
      subtitleWidget: showServerName
          ? _buildLibraryServerLabel(
              library,
              TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
              badgeSize: 10,
              constrainText: true,
            )
          : null,
    );
  }

  /// Build dropdown menu items with server subtitle when needed for clarity.
  List<AppMenuEntry<String>> _buildGroupedLibraryMenuItems(
    List<MediaLibrary> visibleLibraries, {
    required bool showServerHeaders,
  }) {
    if (!showServerHeaders) {
      // With multiple servers connected (but not grouped under headers), show the
      // server name on every library so its origin is always clear — not only when
      // two libraries happen to share a title.
      final showServerNames = _hasMultipleServers(visibleLibraries);
      return visibleLibraries.map((library) {
        final showServerName = library.serverName != null && showServerNames;
        return _buildLibraryMenuItem(library, showServerName: showServerName);
      }).toList();
    }

    final grouped = groupLibrariesByFirstAppearance(visibleLibraries);
    final menuItems = <AppMenuEntry<String>>[];
    for (final serverKey in grouped.serverOrder) {
      final bucket = grouped.byServer[serverKey]!;
      if (serverKey.isNotEmpty) {
        menuItems.add(_buildLibraryServerHeaderMenuItem(bucket.first, serverKey));
      }
      for (final library in bucket) {
        menuItems.add(_buildLibraryMenuItem(library, showServerName: false));
      }
    }
    return menuItems;
  }

  /// Build the app bar title - either dropdown on mobile or simple title on desktop
  Widget _buildAppBarTitle(
    List<MediaLibrary> visibleLibraries,
    MediaLibrary? selectedLibrary, {
    required bool groupByServer,
  }) {
    // No selection at all, or visible list is empty AND we're not browsing a hidden library
    if (_selectedLibraryGlobalKey == null || (visibleLibraries.isEmpty && selectedLibrary == null)) {
      return Text(t.libraries.title);
    }

    // On desktop/TV with side nav, show tabs in app bar (library name is in side nav)
    if (PlatformDetector.shouldUseSideNavigation(context)) {
      return TabChipStrip(
        children: [
          for (int i = 0; i < _visibleTabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            buildTabChip(
              _getTabLabel(_visibleTabs[i]),
              i,
              onSelectWhenActive: _focusCurrentTab,
              onNavigateDown: _focusCurrentTabFromTabBar,
              onNavigateToActions: () => _actionBarKey.currentState?.requestFocusOnFirst(),
            ),
          ],
        ],
      );
    }

    // On mobile, show the dropdown
    return _buildLibraryDropdownTitle(visibleLibraries, groupByServer: groupByServer);
  }

  Widget _buildLibraryDropdownTitle(List<MediaLibrary> visibleLibraries, {required bool groupByServer}) {
    final selectedLibrary =
        visibleLibraries.where((lib) => lib.globalKey == _selectedLibraryGlobalKey).firstOrNull ??
        visibleLibraries.firstOrNull;
    if (selectedLibrary == null) return Text(t.libraries.title);
    final showServerHeaders = _hasMultipleServers(visibleLibraries) && groupByServer;

    return AppMenuButton<String>(
      key: _libraryDropdownKey,
      tooltip: t.libraries.selectLibrary,
      onSelected: (libraryGlobalKey) {
        _loadLibraryContent(libraryGlobalKey);
      },
      entriesBuilder: (context) =>
          _buildGroupedLibraryMenuItems(visibleLibraries, showServerHeaders: showServerHeaders),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: .min,
          children: [
            AppIcon(ContentTypeHelper.getLibraryIcon(selectedLibrary.kind.id), fill: 1, size: 20),
            const SizedBox(width: 8),
            if (_hasMultipleServers(visibleLibraries) && selectedLibrary.serverName != null)
              Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Text(selectedLibrary.title, style: Theme.of(context).textTheme.titleMedium),
                  _buildLibraryServerLabel(
                    selectedLibrary,
                    Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                    badgeSize: 10,
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
    return SettingValueBuilder<bool>(
      pref: SettingsService.groupLibrariesByServer,
      builder: (context, groupByServerSetting, _) => _buildContent(context, groupByServerSetting),
    );
  }

  Widget _buildContent(BuildContext context, bool groupByServerSetting) {
    // Watch libraries provider for updates
    final librariesProvider = context.watch<LibrariesProvider>();
    final allLibraries = librariesProvider.libraries;
    final isLoadingLibraries = librariesProvider.isLoading;

    // Watch for hidden libraries changes to trigger rebuild
    final hiddenLibrariesProvider = context.watch<HiddenLibrariesProvider>();
    final hiddenKeys = hiddenLibrariesProvider.hiddenLibraryKeys;

    // Compute visible libraries (filtered from all libraries)
    final visibleLibraries = allLibraries.where((lib) => !hiddenKeys.contains(lib.globalKey)).toList();

    // Resolve selected library defensively — may be null if server temporarily dropped during refresh
    final selectedLibrary = _selectedLibraryGlobalKey != null
        ? allLibraries.where((lib) => lib.globalKey == _selectedLibraryGlobalKey).firstOrNull
        : null;

    final useSideNavigation = PlatformDetector.shouldUseSideNavigation(context);
    final showMobileTabsRow = selectedLibrary != null && !useSideNavigation;
    final currentTabIndex = _visibleTabs.isEmpty ? 0 : tabController.index.clamp(0, _visibleTabs.length - 1).toInt();
    final currentTabType = _visibleTabs.isEmpty ? null : _visibleTabs[currentTabIndex];
    final useTvRecommendedBackdrop = PlatformDetector.isTV() && currentTabType == LibraryTabType.recommended;
    final showBrowseOptionsAction =
        selectedLibrary != null && PlatformDetector.isMobile(context) && currentTabType == LibraryTabType.browse;
    final canSelectedLibraryGroupByFolders = context.select<MultiServerProvider, bool>((provider) {
      if (selectedLibrary == null || selectedLibrary.isShared) return false;
      final serverId = serverIdOrNull(selectedLibrary.serverId);
      if (serverId == null) return false;
      return provider.getClientForServer(serverId)?.capabilities.folderGrouping ?? false;
    });

    List<FocusableAction> appBarActions() => [
      if (allLibraries.isNotEmpty)
        FocusableAction(
          icon: Symbols.edit_rounded,
          tooltip: t.libraries.manageLibraries,
          onPressed: _showLibraryManagementSheet,
        ),
      if (showBrowseOptionsAction)
        FocusableAction(
          icon: Symbols.tune_rounded,
          tooltip: t.libraries.libraryOptions,
          onPressed: _showBrowseOptionsForCurrentTab,
          // Badge the icon with a dot while the browse tab has active filters
          // (issue #1470). A null child keeps the default rendering.
          child: _browseFiltersActive
              ? IconButton(
                  tooltip: t.libraries.libraryOptions,
                  onPressed: _showBrowseOptionsForCurrentTab,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const AppIcon(Symbols.tune_rounded, fill: 1),
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      FocusableAction(icon: Symbols.refresh_rounded, tooltip: t.common.refresh, onPressed: _refreshSelectedLibraryTabs),
    ];

    Widget appBar({required bool floating}) => DesktopSliverAppBar(
      title: _buildAppBarTitle(visibleLibraries, selectedLibrary, groupByServer: groupByServerSetting),
      // When showing the tab content, let the app bar float away with the
      // content. Otherwise (loading / empty / error states) keep it pinned so
      // it stays visible over the centered state widget.
      pinned: !floating,
      floating: floating,
      snap: floating,
      backgroundColor: useTvRecommendedBackdrop ? Colors.transparent : Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
      actions: [
        FocusableActionBar(
          key: _actionBarKey,
          onNavigateLeft: () => getTabChipFocusNode(_visibleTabs.length - 1).requestFocus(),
          onNavigateDown: _focusCurrentTab,
          actions: appBarActions(),
        ),
      ],
    );

    Widget buildSimpleScroll({required Widget body}) {
      return CustomScrollView(
        controller: _outerScrollController,
        slivers: [
          appBar(floating: false),
          SliverFillRemaining(child: body),
        ],
      );
    }

    Widget buildTransparentTvTopBar() {
      return SafeArea(
        bottom: false,
        child: AppBar(
          primary: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: _buildAppBarTitle(visibleLibraries, selectedLibrary, groupByServer: groupByServerSetting),
          actions: [
            FocusableActionBar(
              key: _actionBarKey,
              onNavigateLeft: () => getTabChipFocusNode(_visibleTabs.length - 1).requestFocus(),
              onNavigateDown: _focusCurrentTab,
              actions: appBarActions(),
            ),
          ],
        ),
      );
    }

    Widget body;
    if (isLoadingLibraries) {
      body = buildSimpleScroll(body: const Center(child: CircularProgressIndicator()));
    } else if (_errorMessage != null && visibleLibraries.isEmpty && selectedLibrary == null) {
      body = buildSimpleScroll(
        body: ErrorStateWidget(
          message: _errorMessage!,
          icon: Symbols.error_outline_rounded,
          onRetry: () {
            final librariesProvider = context.read<LibrariesProvider>();
            librariesProvider.refresh();
          },
        ),
      );
    } else if (visibleLibraries.isEmpty && selectedLibrary == null) {
      body = buildSimpleScroll(
        body: allLibraries.isEmpty
            ? EmptyStateWidget(message: t.libraries.noLibrariesFound, icon: Symbols.video_library_rounded)
            : EmptyStateWidget(
                message: t.libraries.allLibrariesHidden,
                icon: Symbols.visibility_off_rounded,
                onAction: _showLibraryManagementSheet,
                actionLabel: t.libraries.manageLibraries,
                actionIcon: Symbols.edit_rounded,
              ),
      );
    } else if (selectedLibrary != null) {
      Widget buildTab(int index) {
        final tabContent = _buildTabContent(
          _visibleTabs[index],
          library: selectedLibrary,
          canGroupByFolders: canSelectedLibraryGroupByFolders,
          isActive: tabController.index == index,
          tabIndex: index,
        );
        if (useTvRecommendedBackdrop) return tabContent;

        return ClipRect(child: tabContent);
      }

      Widget buildTabs({bool activeOnly = false}) {
        if (activeOnly) return buildTab(currentTabIndex);

        final children = [for (int i = 0; i < _visibleTabs.length; i++) buildTab(i)];

        return TabBarView(
          key: ValueKey(_selectedLibraryGlobalKey),
          controller: tabController,
          // Disable swipe on desktop/TV - trackpad and d-pad scroll actions can trigger accidental tab switches.
          // See: https://github.com/flutter/flutter/issues/11132
          physics: useSideNavigation ? const NeverScrollableScrollPhysics() : null,
          // Wrap each tab in ClipRect so horizontal overflow (e.g. hub rows
          // with Clip.none) doesn't bleed into adjacent tabs during swipe transitions.
          children: children,
        );
      }

      if (useTvRecommendedBackdrop) {
        body = Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: (_, event) => event.logicalKey.isDpadDirection ? KeyEventResult.handled : KeyEventResult.ignored,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              buildTabs(activeOnly: true),
              Positioned(top: 0, left: 0, right: 0, child: ExcludeFocusTraversal(child: buildTransparentTvTopBar())),
            ],
          ),
        );
      } else {
        body = NestedScrollView(
          controller: _outerScrollController,
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: appBar(floating: true),
            ),
            if (showMobileTabsRow)
              SliverToBoxAdapter(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 0; i < _visibleTabs.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          buildTabChip(
                            _getTabLabel(_visibleTabs[i]),
                            i,
                            onSelectWhenActive: _focusCurrentTab,
                            onNavigateDown: _focusCurrentTabFromTabBar,
                            onNavigateToActions: () => _actionBarKey.currentState?.requestFocusOnFirst(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
          body: buildTabs(),
        );
      }
    } else {
      body = buildSimpleScroll(body: const SizedBox.shrink());
    }

    final scrollBody = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: body,
    );

    return Scaffold(body: scrollBody);
  }
}
