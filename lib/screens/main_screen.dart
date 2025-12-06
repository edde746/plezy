import 'package:flutter/material.dart';
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
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../utils/desktop_window_padding.dart';
import '../widgets/side_navigation_rail.dart';
import 'discover_screen.dart';
import 'libraries/libraries_screen.dart';
import 'search_screen.dart';
import 'settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final PlexClient client;

  const MainScreen({super.key, required this.client});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with RouteAware {
  int _currentIndex = 0;
  String? _selectedLibraryGlobalKey;

  late final List<Widget> _screens;
  final GlobalKey<State<DiscoverScreen>> _discoverKey = GlobalKey();
  final GlobalKey<State<LibrariesScreen>> _librariesKey = GlobalKey();
  final GlobalKey<State<SearchScreen>> _searchKey = GlobalKey();
  final GlobalKey<State<SettingsScreen>> _settingsKey = GlobalKey();
  final GlobalKey<SideNavigationRailState> _sideNavKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _screens = [
      DiscoverScreen(
        key: _discoverKey,
        onBecameVisible: _onDiscoverBecameVisible,
      ),
      LibrariesScreen(
        key: _librariesKey,
        onLibraryOrderChanged: _onLibraryOrderChanged,
      ),
      SearchScreen(key: _searchKey),
      SettingsScreen(key: _settingsKey),
    ];

    // Set up data invalidation callback for profile switching
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize UserProfileProvider to ensure it's ready after sign-in
      final userProfileProvider = context.userProfile;
      await userProfileProvider.initialize();

      // Set up data invalidation callback for profile switching
      userProfileProvider.setDataInvalidationCallback(_invalidateAllScreens);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    // Called when this route has been pushed (initial navigation)
    if (_currentIndex == 0) {
      _onDiscoverBecameVisible();
    }
  }

  @override
  void didPopNext() {
    // Called when returning to this route from a child route (e.g., from video player)
    if (_currentIndex == 0) {
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
    setState(() {
      _currentIndex = index;
    });
    // Notify discover screen when it becomes visible via tab switch
    if (index == 0) {
      _onDiscoverBecameVisible();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final useSideNav = PlatformDetector.shouldUseSideNavigation(context);

    if (useSideNav) {
      return SideNavigationScope(
        child: Row(
          children: [
            SideNavigationRail(
              key: _sideNavKey,
              selectedIndex: _currentIndex,
              selectedLibraryKey: _selectedLibraryGlobalKey,
              onDestinationSelected: _selectTab,
              onLibrarySelected: _selectLibrary,
            ),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: t.navigation.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.video_library_outlined),
            selectedIcon: const Icon(Icons.video_library),
            label: t.navigation.libraries,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            selectedIcon: const Icon(Icons.search),
            label: t.navigation.search,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: t.navigation.settings,
          ),
        ],
      ),
    );
  }
}
