import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/plex_client.dart';
import '../i18n/strings.g.dart';
import '../utils/app_logger.dart';
import '../utils/keyboard_utils.dart';
import '../utils/provider_extensions.dart';
import '../main.dart';
import '../mixins/refreshable.dart';
import '../providers/multi_server_provider.dart';
import '../providers/server_state_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/playback_state_provider.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import 'discover_screen.dart';
import 'libraries/libraries_screen.dart';
import 'search_screen.dart';
import 'settings/settings_screen.dart';

/// InheritedWidget that provides back navigation functionality to child screens
class BackNavigationScope extends InheritedWidget {
  final VoidCallback focusBottomNav;

  const BackNavigationScope({
    super.key,
    required this.focusBottomNav,
    required super.child,
  });

  static BackNavigationScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BackNavigationScope>();
  }

  static BackNavigationScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<BackNavigationScope>();
  }

  @override
  bool updateShouldNotify(BackNavigationScope oldWidget) {
    return focusBottomNav != oldWidget.focusBottomNav;
  }
}

class MainScreen extends StatefulWidget {
  final PlexClient client;

  const MainScreen({super.key, required this.client});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with RouteAware {
  int _currentIndex = 0;

  late final List<Widget> _screens;
  final GlobalKey<State<DiscoverScreen>> _discoverKey = GlobalKey();
  final GlobalKey<State<LibrariesScreen>> _librariesKey = GlobalKey();
  final GlobalKey<State<SearchScreen>> _searchKey = GlobalKey();
  final GlobalKey<State<SettingsScreen>> _settingsKey = GlobalKey();

  /// Focus scope node for the bottom navigation bar
  /// Using FocusScopeNode so requestFocus() focuses the first child
  late final FocusScopeNode _bottomNavFocusScopeNode;

  /// Focus scope node for the main content area
  late final FocusScopeNode _contentFocusScopeNode;

  @override
  void initState() {
    super.initState();
    _bottomNavFocusScopeNode = FocusScopeNode(debugLabel: 'BottomNavigation');
    _contentFocusScopeNode = FocusScopeNode(debugLabel: 'MainContent');

    _screens = [
      DiscoverScreen(
        key: _discoverKey,
        onBecameVisible: _onDiscoverBecameVisible,
      ),
      LibrariesScreen(key: _librariesKey),
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
    _bottomNavFocusScopeNode.dispose();
    _contentFocusScopeNode.dispose();
    super.dispose();
  }

  /// Focus the bottom navigation bar (called by child screens on back press)
  void _focusBottomNav() {
    // Request focus on the scope, then navigate to the currently selected tab
    _bottomNavFocusScopeNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Move to first item, then advance to current index
      _bottomNavFocusScopeNode.nextFocus();
      for (int i = 0; i < _currentIndex; i++) {
        _bottomNavFocusScopeNode.nextFocus();
      }
    });
  }

  /// Focus the content area (called when back is pressed in navbar)
  void _focusContent() {
    _contentFocusScopeNode.requestFocus();
  }

  /// Handle back key in navbar - focus content area
  KeyEventResult _handleNavBarBackKey(FocusNode node, KeyEvent event) {
    if (isBackKeyEvent(event)) {
      _focusContent();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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
    // Check if selection came from keyboard/d-pad (bottom nav has focus)
    final isKeyboardNavigation = _bottomNavFocusScopeNode.hasFocus;

    setState(() {
      _currentIndex = index;
    });
    // Notify discover screen when it becomes visible via tab switch
    if (index == 0) {
      _onDiscoverBecameVisible();
      // Focus hero when selecting Home tab via keyboard/d-pad
      if (isKeyboardNavigation) {
        final discoverState = _discoverKey.currentState;
        if (discoverState != null) {
          (discoverState as dynamic).focusHero();
        }
      }
    }
    // Focus first content item when selecting Libraries tab via keyboard/d-pad
    if (index == 1 && isKeyboardNavigation) {
      final librariesState = _librariesKey.currentState;
      if (librariesState != null) {
        (librariesState as dynamic).focusFirstContentItem();
      }
    }
    // Focus search input when selecting Search tab (for both click/tap and keyboard)
    if (index == 2) {
      final searchState = _searchKey.currentState;
      if (searchState != null) {
        (searchState as dynamic).focusSearchInput();
      }
    }
    // Move focus to the content area when selecting a tab via keyboard
    if (isKeyboardNavigation) {
      _contentFocusScopeNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        // Number keys 1-4 for quick tab switching
        const SingleActivator(LogicalKeyboardKey.digit1): _TabIntent(0),
        const SingleActivator(LogicalKeyboardKey.digit2): _TabIntent(1),
        const SingleActivator(LogicalKeyboardKey.digit3): _TabIntent(2),
        const SingleActivator(LogicalKeyboardKey.digit4): _TabIntent(3),
      },
      child: Actions(
        actions: {
          _TabIntent: CallbackAction<_TabIntent>(
            onInvoke: (intent) {
              _selectTab(intent.tabIndex);
              return null;
            },
          ),
        },
        child: Scaffold(
          body: BackNavigationScope(
            focusBottomNav: _focusBottomNav,
            child: FocusScope(
              node: _contentFocusScopeNode,
              child: FocusTraversalGroup(
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),
            ),
          ),
          bottomNavigationBar: FocusScope(
            node: _bottomNavFocusScopeNode,
            onKeyEvent: _handleNavBarBackKey,
            child: NavigationBar(
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
          ),
        ),
      ),
    );
  }
}

/// Intent for switching tabs via keyboard shortcuts
class _TabIntent extends Intent {
  final int tabIndex;
  const _TabIntent(this.tabIndex);
}
