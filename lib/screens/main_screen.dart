import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/plex_client.dart';
import '../i18n/strings.g.dart';
import '../utils/app_logger.dart';
import '../utils/provider_extensions.dart';
import '../utils/platform_detector.dart';
import '../main.dart';
import '../mixins/refreshable.dart';
import '../providers/multi_server_provider.dart';
import '../providers/server_state_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/playback_state_provider.dart';
import '../services/offline_watch_sync_service.dart';
import '../providers/offline_mode_provider.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../utils/desktop_window_padding.dart';
import '../widgets/side_navigation_rail.dart';
import 'discover_screen.dart';
import 'libraries/libraries_screen.dart';
import 'search_screen.dart';
import 'downloads/downloads_screen.dart';
import 'settings/settings_screen.dart';

/// Provides access to the main screen's focus control.
class MainScreenFocusScope extends InheritedWidget {
  final VoidCallback focusSidebar;
  final VoidCallback focusContent;
  final bool isSidebarFocused;

  const MainScreenFocusScope({
    super.key,
    required this.focusSidebar,
    required this.focusContent,
    required this.isSidebarFocused,
    required super.child,
  });

  static MainScreenFocusScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainScreenFocusScope>();
  }

  @override
  bool updateShouldNotify(MainScreenFocusScope oldWidget) {
    return isSidebarFocused != oldWidget.isSidebarFocused;
  }
}

class MainScreen extends StatefulWidget {
  final PlexClient? client;
  final bool isOfflineMode;

  const MainScreen({super.key, this.client, this.isOfflineMode = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with RouteAware {
  late int _currentIndex;
  String? _selectedLibraryGlobalKey;

  /// Whether the app is in offline mode (no server connection)
  bool _isOffline = false;

  OfflineModeProvider? _offlineModeProvider;

  late List<Widget> _screens;
  final GlobalKey<State<DiscoverScreen>> _discoverKey = GlobalKey();
  final GlobalKey<State<LibrariesScreen>> _librariesKey = GlobalKey();
  final GlobalKey<State<SearchScreen>> _searchKey = GlobalKey();
  final GlobalKey<State<DownloadsScreen>> _downloadsKey = GlobalKey();
  final GlobalKey<State<SettingsScreen>> _settingsKey = GlobalKey();
  final GlobalKey<SideNavigationRailState> _sideNavKey = GlobalKey();

  // Focus management for sidebar/content switching
  final FocusScopeNode _sidebarFocusScope = FocusScopeNode(
    debugLabel: 'Sidebar',
  );
  final FocusScopeNode _contentFocusScope = FocusScopeNode(
    debugLabel: 'Content',
  );
  bool _isSidebarFocused = false;

  @override
  void initState() {
    super.initState();
    _isOffline = widget.isOfflineMode;

    // Start on Downloads tab when in offline mode
    // In offline mode: visual index 0 = Downloads (screen 3), 1 = Settings (screen 4)
    // In online mode: indices match directly
    _currentIndex = _isOffline ? 0 : 0;

    _screens = _buildScreens(_isOffline);

    // Set up data invalidation callback for profile switching (skip in offline mode)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_isOffline) {
        // Initialize UserProfileProvider to ensure it's ready after sign-in
        final userProfileProvider = context.userProfile;
        await userProfileProvider.initialize();

        // Set up data invalidation callback for profile switching
        userProfileProvider.setDataInvalidationCallback(_invalidateAllScreens);
      }

      // Focus content initially (replaces autofocus which caused focus stealing issues)
      if (!_isSidebarFocused) {
        _contentFocusScope.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for offline/online transitions to refresh navigation & screens
    final provider = context.read<OfflineModeProvider?>();
    if (provider != null && provider != _offlineModeProvider) {
      _offlineModeProvider?.removeListener(_handleOfflineStatusChanged);
      _offlineModeProvider = provider;
      _offlineModeProvider!.addListener(_handleOfflineStatusChanged);
      _handleOfflineStatusChanged();
    }

    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _offlineModeProvider?.removeListener(_handleOfflineStatusChanged);
    _sidebarFocusScope.dispose();
    _contentFocusScope.dispose();
    super.dispose();
  }

  List<Widget> _buildScreens(bool offline) {
    // In offline mode, only show Downloads and Settings
    // In online mode, show all 5 screens
    if (offline) {
      return [
        DownloadsScreen(key: _downloadsKey),
        SettingsScreen(key: _settingsKey),
      ];
    }

    return [
      DiscoverScreen(
        key: _discoverKey,
        onBecameVisible: _onDiscoverBecameVisible,
      ),
      LibrariesScreen(
        key: _librariesKey,
        onLibraryOrderChanged: _onLibraryOrderChanged,
      ),
      SearchScreen(key: _searchKey),
      DownloadsScreen(key: _downloadsKey),
      SettingsScreen(key: _settingsKey),
    ];
  }

  int _normalizeIndexForMode(int current, bool offline) {
    if (offline) {
      // Only two tabs exist offline: 0 = Downloads, 1 = Settings
      if (current <= 0) return 0;
      if (current == 1) return 1;
      return 0;
    }

    // Map offline indices back to online equivalents when reconnecting
    if (current == 0) return 3; // Downloads tab
    if (current == 1) return 4; // Settings tab
    if (current < 0) return 0;
    if (current > 4) return 0;
    return current;
  }

  void _handleOfflineStatusChanged() {
    final newOffline = _offlineModeProvider?.isOffline ?? widget.isOfflineMode;

    if (newOffline == _isOffline) return;

    setState(() {
      _isOffline = newOffline;
      _screens = _buildScreens(_isOffline);
      _selectedLibraryGlobalKey = _isOffline ? null : _selectedLibraryGlobalKey;
      _currentIndex = _normalizeIndexForMode(_currentIndex, _isOffline);
    });

    // Refresh sidebar focus after rebuilding navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sideNavKey.currentState?.focusActiveItem();
    });

    // Ensure profile provider is initialized when coming back online
    if (!_isOffline) {
      final userProfileProvider = context.userProfile;
      userProfileProvider.initialize().then((_) {
        userProfileProvider.setDataInvalidationCallback(_invalidateAllScreens);
      });
    }
  }

  void _focusSidebar() {
    setState(() => _isSidebarFocused = true);
    _sidebarFocusScope.requestFocus();
    // Focus the active item after the focus scope has focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sideNavKey.currentState?.focusActiveItem();
    });
  }

  void _focusContent() {
    setState(() => _isSidebarFocused = false);
    _contentFocusScope.requestFocus();
    // When content regains focus while on Libraries, retry focusing the active tab
    if (_currentIndex == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final librariesState = _librariesKey.currentState;
        if (librariesState != null) {
          (librariesState as dynamic).focusActiveTabIfReady();
        }
      });
    }
  }

  KeyEventResult _handleBackKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Handle all back keys - this handler is only reached if lower widgets
    // (e.g., LibrariesScreen tab content/chips) don't handle the back key first
    final isBackKey =
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.browserBack ||
        event.logicalKey == LogicalKeyboardKey.gameButtonB;

    if (!isBackKey) return KeyEventResult.ignored;

    // Toggle focus between sidebar and content
    if (_isSidebarFocused) {
      _focusContent();
    } else {
      _focusSidebar();
    }
    return KeyEventResult.handled;
  }

  @override
  void didPush() {
    // Called when this route has been pushed (initial navigation)
    if (_currentIndex == 0 && !_isOffline) {
      _onDiscoverBecameVisible();
    }
  }

  @override
  void didPopNext() {
    // Called when returning to this route from a child route (e.g., from video player)
    if (_currentIndex == 0 && !_isOffline) {
      _onDiscoverBecameVisible();
    }
  }

  void _onDiscoverBecameVisible() {
    appLogger.d('Navigated to home');
    // Refresh content when returning to discover page
    final discoverState = _discoverKey.currentState;
    if (discoverState != null && discoverState is Refreshable) {
      (discoverState as Refreshable).refresh();
    }
  }

  void _onLibraryOrderChanged() {
    // Refresh side navigation when library order changes
    _sideNavKey.currentState?.reloadLibraries();
  }

  /// Invalidate all cached data across all screens when profile is switched
  /// Receives the list of servers with new profile tokens for reconnection
  Future<void> _invalidateAllScreens(List<PlexServer> servers) async {
    appLogger.d(
      'Invalidating all screen data due to profile switch with ${servers.length} servers',
    );

    // Get all providers
    final multiServerProvider = context.read<MultiServerProvider>();
    final serverStateProvider = context.read<ServerStateProvider>();
    final hiddenLibrariesProvider = context.read<HiddenLibrariesProvider>();
    final playbackStateProvider = context.read<PlaybackStateProvider>();

    // Reconnect to all servers with new profile tokens
    if (servers.isNotEmpty) {
      final storage = await StorageService.getInstance();
      final clientId = storage.getClientIdentifier();

      final connectedCount = await multiServerProvider.reconnectWithServers(
        servers,
        clientIdentifier: clientId,
      );
      appLogger.d(
        'Reconnected to $connectedCount/${servers.length} servers after profile switch',
      );

      // Trigger watch state sync now that servers are connected
      if (connectedCount > 0 && context.mounted) {
        context.read<OfflineWatchSyncService>().onServersConnected();
      }
    }

    // Reset other provider states
    serverStateProvider.reset();
    hiddenLibrariesProvider.refresh();
    playbackStateProvider.clearShuffle();

    appLogger.d('Cleared all provider states for profile switch');

    // Full refresh discover screen (reload all content for new profile)
    final discoverState = _discoverKey.currentState;
    if (discoverState != null) {
      (discoverState as dynamic).fullRefresh();
    }

    // Full refresh libraries screen (clear filters and reload for new profile)
    final librariesState = _librariesKey.currentState;
    if (librariesState != null) {
      (librariesState as dynamic).fullRefresh();
    }

    // Full refresh search screen (clear search for new profile)
    final searchState = _searchKey.currentState;
    if (searchState != null) {
      (searchState as dynamic).fullRefresh();
    }
  }

  void _selectTab(int index) {
    final previousIndex = _currentIndex;
    setState(() {
      _currentIndex = index;
    });

    // Skip screen-specific logic in offline mode (only Downloads and Settings available)
    if (_isOffline) return;

    // Notify discover screen when it becomes visible via tab switch
    if (index == 0) {
      _onDiscoverBecameVisible();
    }
    // Ensure the libraries screen applies focus when brought into view
    if (index == 1 && previousIndex != 1) {
      final librariesState = _librariesKey.currentState;
      if (librariesState != null) {
        (librariesState as dynamic).focusActiveTabIfReady();
      }
    }
    // Focus search input when selecting Search tab
    if (index == 2) {
      final searchState = _searchKey.currentState;
      if (searchState != null) {
        (searchState as dynamic).focusSearchInput();
      }
    }
  }

  /// Handle library selection from side navigation rail
  void _selectLibrary(String libraryGlobalKey) {
    setState(() {
      _selectedLibraryGlobalKey = libraryGlobalKey;
      _currentIndex = 1; // Switch to Libraries tab
    });
    // Tell LibrariesScreen to load this library
    final librariesState = _librariesKey.currentState;
    if (librariesState != null) {
      (librariesState as dynamic).loadLibraryByKey(libraryGlobalKey);
      (librariesState as dynamic).focusActiveTabIfReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    final useSideNav = PlatformDetector.shouldUseSideNavigation(context);

    if (useSideNav) {
      return PopScope(
        canPop: false, // Prevent system back from popping on Android TV
        onPopInvokedWithResult: (didPop, result) {
          // No-op: back key events bubble through widget tree and are handled
          // by content screens (e.g., LibrariesScreen) or MainScreen's _handleBackKey.
          // We only use PopScope to prevent the system from popping the route.
        },
        child: Focus(
          onKeyEvent: (node, event) => _handleBackKey(event),
          child: MainScreenFocusScope(
            focusSidebar: _focusSidebar,
            focusContent: _focusContent,
            isSidebarFocused: _isSidebarFocused,
            child: SideNavigationScope(
              child: Row(
                children: [
                  FocusScope(
                    node: _sidebarFocusScope,
                    child: SideNavigationRail(
                      key: _sideNavKey,
                      selectedIndex: _currentIndex,
                      selectedLibraryKey: _selectedLibraryGlobalKey,
                      isOfflineMode: _isOffline,
                      onDestinationSelected: (index) {
                        _selectTab(index);
                        _focusContent();
                      },
                      onLibrarySelected: (key) {
                        _selectLibrary(key);
                        _focusContent();
                      },
                    ),
                  ),
                  Expanded(
                    child: FocusScope(
                      node: _contentFocusScope,
                      // No autofocus - we control focus programmatically to prevent
                      // autofocus from stealing focus back after setState() rebuilds
                      child: IndexedStack(
                        index: _currentIndex,
                        children: _screens,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // In offline mode, only show Downloads and Settings
    final destinations = _isOffline
        ? [
            NavigationDestination(
              icon: const AppIcon(Symbols.download_rounded, fill: 1),
              selectedIcon: const AppIcon(Symbols.download_rounded, fill: 1),
              label: t.navigation.downloads,
            ),
            NavigationDestination(
              icon: const AppIcon(Symbols.settings_rounded, fill: 1),
              selectedIcon: const AppIcon(Symbols.settings_rounded, fill: 1),
              label: t.navigation.settings,
            ),
          ]
        : [
            NavigationDestination(
              icon: const AppIcon(Symbols.home_rounded, fill: 1),
              selectedIcon: const AppIcon(Symbols.home_rounded, fill: 1),
              label: t.navigation.home,
            ),
            NavigationDestination(
              icon: const AppIcon(Symbols.video_library_rounded, fill: 1),
              selectedIcon: const AppIcon(
                Symbols.video_library_rounded,
                fill: 1,
              ),
              label: t.navigation.libraries,
            ),
            NavigationDestination(
              icon: const AppIcon(Symbols.search_rounded, fill: 1),
              selectedIcon: const AppIcon(Symbols.search_rounded, fill: 1),
              label: t.navigation.search,
            ),
            NavigationDestination(
              icon: const AppIcon(Symbols.download_rounded, fill: 1),
              selectedIcon: const AppIcon(Symbols.download_rounded, fill: 1),
              label: t.navigation.downloads,
            ),
            NavigationDestination(
              icon: const AppIcon(Symbols.settings_rounded, fill: 1),
              selectedIcon: const AppIcon(Symbols.settings_rounded, fill: 1),
              label: t.navigation.settings,
            ),
          ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectTab,
        destinations: destinations,
      ),
    );
  }
}

/// Placeholder widget shown for network-dependent screens when offline
class _OfflinePlaceholder extends StatelessWidget {
  const _OfflinePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              Symbols.cloud_off_rounded,
              fill: 1,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              t.messages.youAreOffline,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t.messages.offlineFeatureUnavailable,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
