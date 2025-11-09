import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'dart:io' show Platform;
import '../client/plex_client.dart';
import '../utils/app_logger.dart';
import '../utils/provider_extensions.dart';
import '../main.dart';
import '../mixins/refreshable.dart';
import 'discover_screen.dart';
import 'libraries_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

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

  @override
  void initState() {
    super.initState();

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

  /// Invalidate all cached data across all screens when profile is switched
  void _invalidateAllScreens() {
    appLogger.d('Invalidating all screen data due to profile switch');

    // Refresh discover screen
    final discoverState = _discoverKey.currentState;
    if (discoverState != null && discoverState is Refreshable) {
      (discoverState as Refreshable).refresh();
    }

    // Refresh libraries screen
    final librariesState = _librariesKey.currentState;
    if (librariesState != null && librariesState is Refreshable) {
      (librariesState as Refreshable).refresh();
    }

    // Refresh search screen
    final searchState = _searchKey.currentState;
    if (searchState != null && searchState is Refreshable) {
      (searchState as Refreshable).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: AdaptiveBottomNavigationBar(
        selectedIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Notify discover screen when it becomes visible via tab switch
          if (index == 0) {
            _onDiscoverBecameVisible();
          }
        },
        items: [
          AdaptiveNavigationDestination(
            icon: Platform.isIOS ? 'house.fill' : Icons.home_outlined,
            selectedIcon: Platform.isIOS ? 'house.fill' : Icons.home,
            label: 'Home',
          ),
          AdaptiveNavigationDestination(
            icon: Platform.isIOS ? 'video.fill' : Icons.video_library_outlined,
            selectedIcon: Platform.isIOS ? 'video.fill' : Icons.video_library,
            label: 'Libraries',
          ),
          AdaptiveNavigationDestination(
            icon: Platform.isIOS ? 'magnifyingglass' : Icons.search,
            selectedIcon: Platform.isIOS ? 'magnifyingglass' : Icons.search,
            label: 'Search',
            isSearch: true,
          ),
          AdaptiveNavigationDestination(
            icon: Platform.isIOS ? 'gearshape.fill' : Icons.settings_outlined,
            selectedIcon: Platform.isIOS ? 'gearshape.fill' : Icons.settings,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
