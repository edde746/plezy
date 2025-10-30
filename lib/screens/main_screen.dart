import 'package:flutter/material.dart';
import '../client/plex_client.dart';
import '../models/plex_user_profile.dart';
import '../utils/app_logger.dart';
import '../utils/provider_extensions.dart';
import '../main.dart';
import '../mixins/refreshable.dart';
import 'discover_screen.dart';
import 'libraries_screen.dart';
import 'search_screen.dart';

class MainScreen extends StatefulWidget {
  final PlexClient client;
  final PlexUserProfile? userProfile;

  const MainScreen({super.key, required this.client, this.userProfile});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with RouteAware {
  int _currentIndex = 0;

  late final List<Widget> _screens;
  final GlobalKey<State<DiscoverScreen>> _discoverKey = GlobalKey();
  final GlobalKey<State<LibrariesScreen>> _librariesKey = GlobalKey();
  final GlobalKey<State<SearchScreen>> _searchKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _screens = [
      DiscoverScreen(
        key: _discoverKey,
        userProfile: widget.userProfile,
        onBecameVisible: _onDiscoverBecameVisible,
      ),
      LibrariesScreen(key: _librariesKey, userProfile: widget.userProfile),
      SearchScreen(key: _searchKey, userProfile: widget.userProfile),
    ];

    // Set up data invalidation callback for profile switching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.userProfile.setDataInvalidationCallback(_invalidateAllScreens);

      // Set the client in the provider so profile switching can update its token
      context.plexClient.setClient(widget.client);
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
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Notify discover screen when it becomes visible via tab switch
          if (index == 0) {
            _onDiscoverBecameVisible();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library),
            label: 'Libraries',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }
}
