import 'dart:io' show Platform, exit;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import '../../services/plex_client.dart';
import '../i18n/strings.g.dart';
import '../services/update_service.dart';
import '../utils/app_logger.dart';
import '../utils/provider_extensions.dart';
import '../utils/platform_detector.dart';
import '../utils/video_player_navigation.dart';
import '../main.dart';
import '../mixins/refreshable.dart';
import '../navigation/navigation_tabs.dart';
import '../providers/multi_server_provider.dart';
import '../providers/server_state_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/libraries_provider.dart';
import '../providers/playback_state_provider.dart';
import '../providers/settings_provider.dart';
import '../services/offline_watch_sync_service.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../utils/desktop_window_padding.dart';
import '../widgets/side_navigation_rail.dart';
import '../focus/key_event_utils.dart';
import 'discover_screen.dart';
import 'libraries/libraries_screen.dart';
import 'search_screen.dart';
import 'downloads/downloads_screen.dart';
import 'settings/settings_screen.dart';
import 'video_player_screen.dart';
import '../services/watch_next_service.dart';
import '../watch_together/watch_together.dart';
import '../watch_together/models/watch_invitation.dart';
import '../watch_together/widgets/invitation_banner.dart';
import '../watch_together/widgets/invitations_indicator.dart';
import '../models/plex_home_user.dart';

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

class _MainScreenState extends State<MainScreen> with RouteAware, WindowListener {
  late int _currentIndex;
  String? _selectedLibraryGlobalKey;

  /// Whether the app is in offline mode (no server connection)
  bool _isOffline = false;

  /// Last selected online tab (restored when coming back online after an offline fallback)
  NavigationTabId? _lastOnlineTabId;

  /// Whether we auto-switched to Downloads because the previous tab was unavailable offline
  bool _autoSwitchedToDownloads = false;

  OfflineModeProvider? _offlineModeProvider;

  late List<Widget> _screens;
  final GlobalKey<State<DiscoverScreen>> _discoverKey = GlobalKey();
  final GlobalKey<State<LibrariesScreen>> _librariesKey = GlobalKey();
  final GlobalKey<State<SearchScreen>> _searchKey = GlobalKey();
  final GlobalKey<State<DownloadsScreen>> _downloadsKey = GlobalKey();
  final GlobalKey<State<SettingsScreen>> _settingsKey = GlobalKey();
  final GlobalKey<SideNavigationRailState> _sideNavKey = GlobalKey();

  // Focus management for sidebar/content switching
  final FocusScopeNode _sidebarFocusScope = FocusScopeNode(debugLabel: 'Sidebar');
  final FocusScopeNode _contentFocusScope = FocusScopeNode(debugLabel: 'Content');
  bool _isSidebarFocused = false;

  // Current invitation to display as banner
  WatchInvitation? _currentInvitation;

  // Listener for UserProfileProvider (used when currentUser is not immediately available)
  VoidCallback? _userProfileListener;

  @override
  void initState() {
    super.initState();
    _isOffline = widget.isOfflineMode;

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      windowManager.addListener(this);
      windowManager.setPreventClose(true);
    }

    // Start on Downloads tab when in offline mode
    // In offline mode: visual index 0 = Downloads (screen 3), 1 = Settings (screen 4)
    // In online mode: indices match directly
    _currentIndex = _isOffline ? 0 : 0;
    _lastOnlineTabId = _isOffline ? null : NavigationTabId.discover;
    _autoSwitchedToDownloads = _isOffline;

    _screens = _buildScreens(_isOffline);

    // Set up Watch Together callbacks immediately (must be synchronous to catch early messages)
    if (!_isOffline) {
      _setupWatchTogetherCallback();
      _setupWatchNextDeepLink();
    }

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

      // Register for Watch Together invitations if online
      _registerWatchTogether();

      // Check for updates on startup
      _checkForUpdatesOnStartup();
    });
  }

  /// Helper to register the current user for Watch Together invitations
  void _registerWatchTogether() {
    appLogger.d('WatchTogether: _registerWatchTogether called, isOffline=$_isOffline');
    if (_isOffline) return;
    try {
      final userProfile = context.read<UserProfileProvider>();
      final currentUser = userProfile.currentUser;
      appLogger.d('WatchTogether: currentUser=${currentUser?.displayName ?? "null"}, uuid=${currentUser?.uuid ?? "null"}');
      if (currentUser != null) {
        _doRegisterWatchTogether(currentUser);
      } else {
        // currentUser not yet available (common on PC due to timing differences)
        // Listen for changes and register when user becomes available
        appLogger.d('WatchTogether: Waiting for currentUser...');
        _userProfileListener = _createUserProfileListener();
        userProfile.addListener(_userProfileListener!);
      }
    } catch (e) {
      appLogger.e('WatchTogether: Failed to register for invitations', error: e);
    }
  }

  /// Creates a listener that registers for Watch Together when currentUser becomes available
  VoidCallback _createUserProfileListener() {
    return () {
      final userProfile = context.read<UserProfileProvider>();
      final currentUser = userProfile.currentUser;
      if (currentUser != null) {
        // Remove listener before registering to avoid duplicate calls
        if (_userProfileListener != null) {
          userProfile.removeListener(_userProfileListener!);
          _userProfileListener = null;
        }
        _doRegisterWatchTogether(currentUser);
      }
    };
  }

  /// Performs the actual Watch Together registration
  void _doRegisterWatchTogether(PlexHomeUser user) {
    try {
      appLogger.d('WatchTogether: Calling registerForInvitations for ${user.displayName}...');
      context.read<WatchTogetherProvider>().registerForInvitations(
            userUUID: user.uuid,
            displayName: user.displayName,
          );
      appLogger.d('WatchTogether: Registered ${user.displayName}');
    } catch (e) {
      appLogger.e('WatchTogether: Registration failed', error: e);
    }
  }

  Future<void> _checkForUpdatesOnStartup() async {
    // Delay slightly to allow UI to settle
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      final updateInfo = await UpdateService.checkForUpdatesOnStartup();

      if (updateInfo != null && updateInfo['hasUpdate'] == true && mounted) {
        _showUpdateDialog(updateInfo);
      }
    } catch (e) {
      appLogger.e('Error checking for updates', error: e);
    }
  }

  void _showUpdateDialog(Map<String, dynamic> updateInfo) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(t.update.available),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.update.versionAvailable(version: updateInfo['latestVersion']),
                style: Theme.of(dialogContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                t.update.currentVersion(version: updateInfo['currentVersion']),
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.later)),
            TextButton(
              onPressed: () async {
                await UpdateService.skipVersion(updateInfo['latestVersion']);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(t.update.skipVersion),
            ),
            FilledButton(
              onPressed: () async {
                final url = Uri.parse(updateInfo['releaseUrl']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(t.update.viewRelease),
            ),
          ],
        );
      },
    );
  }

  /// Set up the Watch Together navigation callback for guests
  void _setupWatchTogetherCallback() {
    try {
      final watchTogether = context.read<WatchTogetherProvider>();
      watchTogether.onMediaSwitched = (ratingKey, serverId, mediaTitle) async {
        appLogger.d('WatchTogether: Media switch received - navigating to $mediaTitle');
        await _navigateToWatchTogetherMedia(ratingKey, serverId);
      };
      watchTogether.onHostExitedPlayer = () {
        appLogger.d('WatchTogether: Host exited player - exiting player for guest');
        // Use rootNavigator to ensure we pop the video player even if nested
        if (!mounted) return;
        final navigator = Navigator.of(context, rootNavigator: true);
        bool isVideoPlayerOnTop = false;
        navigator.popUntil((route) {
          if (route.isCurrent) {
            isVideoPlayerOnTop = route.settings.name == kVideoPlayerRouteName;
          }
          return true;
        });
        if (isVideoPlayerOnTop && navigator.canPop()) {
          navigator.pop();
        }
      };
      // Set up invitation received callback
      watchTogether.onInvitationReceived = (invitation) {
        appLogger.d('WatchTogether: Invitation received from ${invitation.hostDisplayName}');
        if (!mounted) return;
        _showInvitationBanner(invitation);
      };
    } catch (e) {
      appLogger.w('Could not set up Watch Together callback', error: e);
    }
  }

  void _showInvitationBanner(WatchInvitation invitation) {
    setState(() {
      _currentInvitation = invitation;
    });
  }

  void _dismissInvitationBanner() {
    setState(() {
      _currentInvitation = null;
    });
  }

  Future<void> _acceptInvitation() async {
    final invitation = _currentInvitation;
    if (invitation == null) return;

    _dismissInvitationBanner();
    final watchTogether = context.read<WatchTogetherProvider>();
    await watchTogether.acceptInvitation(invitation);
  }

  void _declineInvitation() {
    final invitation = _currentInvitation;
    if (invitation == null) return;

    _dismissInvitationBanner();
    final watchTogether = context.read<WatchTogetherProvider>();
    watchTogether.declineInvitation(invitation);
  }

  /// Set up Watch Next deep link handling for Android TV launcher taps
  void _setupWatchNextDeepLink() {
    if (!Platform.isAndroid) return;

    final watchNext = WatchNextService();

    // Listen for deep links when app is already running (warm start)
    watchNext.onWatchNextTap = (contentId) {
      appLogger.d('Watch Next tap: $contentId');
      _handleWatchNextContentId(contentId);
    };

    // Check for pending deep link from cold start
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final contentId = await watchNext.getInitialDeepLink();
      if (contentId != null && mounted) {
        appLogger.d('Watch Next initial deep link: $contentId');
        _handleWatchNextContentId(contentId);
      }
    });
  }

  /// Handle a Watch Next content ID by fetching metadata and starting playback
  Future<void> _handleWatchNextContentId(String contentId) async {
    if (!mounted) return;

    final parsed = WatchNextService.parseContentId(contentId);
    if (parsed == null) {
      appLogger.w('Watch Next: invalid content ID: $contentId');
      return;
    }

    final (serverId, ratingKey) = parsed;

    try {
      final multiServer = context.read<MultiServerProvider>();
      final client = multiServer.getClientForServer(serverId);

      if (client == null) {
        appLogger.w('Watch Next: server $serverId not available');
        return;
      }

      final metadata = await client.getMetadataWithImages(ratingKey);

      if (metadata == null || !mounted) return;

      navigateToVideoPlayer(context, metadata: metadata);
    } catch (e) {
      appLogger.e('Watch Next: failed to navigate to media', error: e);
    }
  }

  /// Navigate to media when host switches content in Watch Together session
  Future<void> _navigateToWatchTogetherMedia(String ratingKey, String serverId) async {
    if (!mounted) return; // Check before any context usage

    try {
      final multiServer = context.read<MultiServerProvider>();
      final client = multiServer.getClientForServer(serverId);

      if (client == null) {
        appLogger.w('WatchTogether: Server $serverId not available');
        return;
      }

      // Fetch the metadata for the new media
      final metadata = await client.getMetadataWithImages(ratingKey);

      if (metadata == null || !mounted) return;

      // Use push to preserve WatchTogetherScreen in navigation stack
      // VideoPlayerScreen handles its own replacement via onPlayerMediaSwitched
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: kVideoPlayerRouteName),
          builder: (_) => VideoPlayerScreen(metadata: metadata),
        ),
      );
    } catch (e) {
      appLogger.e('WatchTogether: Failed to navigate to media', error: e);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for offline/online transitions to refresh navigation & screens
    // Note: We don't call _handleOfflineStatusChanged() immediately because
    // widget.isOfflineMode (from SetupScreen navigation) is authoritative for
    // initial state. The provider may not yet have received the server status
    // update due to initialization timing. The listener handles runtime changes.
    final provider = context.read<OfflineModeProvider?>();
    if (provider != null && provider != _offlineModeProvider) {
      _offlineModeProvider?.removeListener(_handleOfflineStatusChanged);
      _offlineModeProvider = provider;
      _offlineModeProvider!.addListener(_handleOfflineStatusChanged);
    }

    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      windowManager.removeListener(this);
      windowManager.setPreventClose(false);
    }
    _offlineModeProvider?.removeListener(_handleOfflineStatusChanged);
    // Clean up UserProfile listener if still attached
    if (_userProfileListener != null) {
      try {
        context.read<UserProfileProvider>().removeListener(_userProfileListener!);
      } catch (_) {
        // Context may not be available during dispose
      }
      _userProfileListener = null;
    }
    _sidebarFocusScope.dispose();
    _contentFocusScope.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() {
    exit(0);
  }

  List<Widget> _buildScreens(bool offline) {
    // In offline mode, only show Downloads and Settings
    // In online mode, show all 5 screens
    if (offline) {
      return [DownloadsScreen(key: _downloadsKey), SettingsScreen(key: _settingsKey)];
    }

    return [
      DiscoverScreen(key: _discoverKey, onBecameVisible: _onDiscoverBecameVisible),
      LibrariesScreen(key: _librariesKey, onLibraryOrderChanged: _onLibraryOrderChanged),
      SearchScreen(key: _searchKey),
      DownloadsScreen(key: _downloadsKey),
      SettingsScreen(key: _settingsKey),
    ];
  }

  /// Normalize tab index when switching between offline/online modes.
  /// Preserves the current tab if it exists in the new mode, otherwise defaults to first tab.
  int _normalizeIndexForMode(int currentIndex, bool wasOffline, bool isOffline) {
    if (wasOffline == isOffline) return currentIndex;

    final oldTabs = _getVisibleTabs(wasOffline);
    final newTabs = _getVisibleTabs(isOffline);

    // Get the tab ID at the current index (or first tab if out of bounds)
    final currentTabId = currentIndex >= 0 && currentIndex < oldTabs.length
        ? oldTabs[currentIndex].id
        : oldTabs.first.id;

    // Find the same tab in the new mode's tab list
    final newIndex = newTabs.indexWhere((tab) => tab.id == currentTabId);
    return newIndex >= 0 ? newIndex : 0;
  }

  void _handleOfflineStatusChanged() {
    final newOffline = _offlineModeProvider?.isOffline ?? widget.isOfflineMode;

    if (newOffline == _isOffline) return;

    final previousTabId = _tabIdForIndex(_isOffline, _currentIndex);
    final wasOffline = _isOffline;
    setState(() {
      _isOffline = newOffline;
      _screens = _buildScreens(_isOffline);
      _selectedLibraryGlobalKey = _isOffline ? null : _selectedLibraryGlobalKey;

      if (_isOffline) {
        // Remember the online tab so we can restore it when reconnecting.
        if (!wasOffline) {
          _lastOnlineTabId = previousTabId;
        }

        _currentIndex = _normalizeIndexForMode(_currentIndex, wasOffline, _isOffline);

        // Track if we auto-switched to Downloads because the previous tab was unavailable.
        _autoSwitchedToDownloads =
            previousTabId != NavigationTabId.downloads &&
            _tabIdForIndex(true, _currentIndex) == NavigationTabId.downloads;
      } else {
        // Coming back online: restore the last online tab if we forced a switch to Downloads.
        if (_autoSwitchedToDownloads) {
          final restoredTab = _lastOnlineTabId ?? NavigationTabId.discover;
          final restoredIndex = NavigationTab.indexFor(restoredTab, isOffline: _isOffline);
          _currentIndex = restoredIndex >= 0 ? restoredIndex : 0;
        } else {
          _currentIndex = _normalizeIndexForMode(_currentIndex, wasOffline, _isOffline);
        }
        _autoSwitchedToDownloads = false;
      }
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
        _registerWatchTogether();
      });
    }
  }

  void _focusSidebar() {
    // Capture target before requestFocus() auto-focuses a sidebar descendant
    // and overwrites lastFocusedKey (e.g. to the Libraries toggle button).
    final targetKey = _sideNavKey.currentState?.lastFocusedKey;
    setState(() => _isSidebarFocused = true);
    _sidebarFocusScope.requestFocus();
    // Focus the active item after the focus scope has focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sideNavKey.currentState?.focusActiveItem(targetKey: targetKey);
    });
  }

  void _focusContent() {
    setState(() => _isSidebarFocused = false);
    _contentFocusScope.requestFocus();
    // When content regains focus while on Libraries, retry focusing the active tab
    if (_currentIndex == 1 && !_isOffline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_librariesKey.currentState case final FocusableTab focusable) {
          focusable.focusActiveTabIfReady();
        }
      });
    }
    // When content regains focus while on Settings, restore focus to last focused setting
    final settingsIndex = NavigationTab.indexFor(NavigationTabId.settings, isOffline: _isOffline);
    if (_currentIndex == settingsIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_settingsKey.currentState case final FocusableTab focusable) {
          focusable.focusActiveTabIfReady();
        }
      });
    }
  }

  KeyEventResult _handleBackKey(KeyEvent event) {
    if (!_isSidebarFocused) {
      // Content focused → move to sidebar
      return handleBackKeyAction(event, _focusSidebar);
    }

    // Sidebar focused → exit app
    return handleBackKeyAction(event, () => SystemNavigator.pop());
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
    appLogger.d('Invalidating all screen data due to profile switch with ${servers.length} servers');

    // Get all providers
    final multiServerProvider = context.read<MultiServerProvider>();
    final serverStateProvider = context.read<ServerStateProvider>();
    final hiddenLibrariesProvider = context.read<HiddenLibrariesProvider>();
    final librariesProvider = context.read<LibrariesProvider>();
    final playbackStateProvider = context.read<PlaybackStateProvider>();

    // Clear libraries provider state before reconnecting
    librariesProvider.clear();

    // Reconnect to all servers with new profile tokens
    if (servers.isNotEmpty) {
      final storage = await StorageService.getInstance();
      final clientId = storage.getClientIdentifier();

      final connectedCount = await multiServerProvider.reconnectWithServers(servers, clientIdentifier: clientId);
      appLogger.d('Reconnected to $connectedCount/${servers.length} servers after profile switch');

      // Trigger watch state sync now that servers are connected
      if (connectedCount > 0) {
        if (!mounted) return;
        context.read<OfflineWatchSyncService>().onServersConnected();

        // Reload libraries after reconnection
        librariesProvider.initialize(multiServerProvider.aggregationService);
        await librariesProvider.refresh();
      }
    }

    // Reset other provider states
    serverStateProvider.reset();
    hiddenLibrariesProvider.refresh();
    playbackStateProvider.clearShuffle();

    appLogger.d('Cleared all provider states for profile switch');

    // Full refresh discover screen (reload all content for new profile)
    if (_discoverKey.currentState case final FullRefreshable refreshable) {
      refreshable.fullRefresh();
    }

    // Re-register for Watch Together with the new profile data
    _registerWatchTogether();

    // Full refresh libraries screen (clear filters and reload for new profile)
    if (_librariesKey.currentState case final FullRefreshable refreshable) {
      refreshable.fullRefresh();
    }

    // Full refresh search screen (clear search for new profile)
    if (_searchKey.currentState case final FullRefreshable refreshable) {
      refreshable.fullRefresh();
    }

    // Sidebar automatically updates since it watches LibrariesProvider
  }

  void _selectTab(int index) {
    final previousIndex = _currentIndex;
    setState(() {
      _currentIndex = index;
      if (!_isOffline) {
        _lastOnlineTabId = _tabIdForIndex(false, index);
      } else if (previousIndex != index) {
        // User made an explicit offline selection, so don't auto-restore later.
        _autoSwitchedToDownloads = false;
      }
    });

    // Handle screen-specific logic
    final settingsIndex = NavigationTab.indexFor(NavigationTabId.settings, isOffline: _isOffline);

    // Skip online-only screen logic in offline mode
    if (!_isOffline) {
      // Notify discover screen when it becomes visible via tab switch
      if (index == 0) {
        _onDiscoverBecameVisible();
      }
      // Ensure the libraries screen applies focus when brought into view
      if (index == 1 && previousIndex != 1) {
        if (_librariesKey.currentState case final FocusableTab focusable) {
          focusable.focusActiveTabIfReady();
        }
      }
      // Focus search input when selecting Search tab
      if (index == 2) {
        if (_searchKey.currentState case final SearchInputFocusable searchable) {
          searchable.focusSearchInput();
        }
      }
    }

    // Restore focus when switching to Settings tab (works in both online and offline mode)
    if (index == settingsIndex && previousIndex != settingsIndex) {
      if (_settingsKey.currentState case final FocusableTab focusable) {
        focusable.focusActiveTabIfReady();
      }
    }
  }

  /// Handle library selection from side navigation rail
  void _selectLibrary(String libraryGlobalKey) {
    setState(() {
      _selectedLibraryGlobalKey = libraryGlobalKey;
      _currentIndex = 1; // Switch to Libraries tab
      if (!_isOffline) {
        _lastOnlineTabId = NavigationTabId.libraries;
      }
    });
    // Tell LibrariesScreen to load this library
    if (_librariesKey.currentState case final LibraryLoadable loadable) {
      loadable.loadLibraryByKey(libraryGlobalKey);
    }
    if (_librariesKey.currentState case final FocusableTab focusable) {
      focusable.focusActiveTabIfReady();
    }
  }

  /// Get navigation tabs filtered by offline mode
  List<NavigationTab> _getVisibleTabs(bool isOffline) {
    return NavigationTab.getVisibleTabs(isOffline: isOffline);
  }

  /// Get the tab ID for a given index, clamping to the available range.
  NavigationTabId _tabIdForIndex(bool isOffline, int index) {
    final tabs = _getVisibleTabs(isOffline);
    if (tabs.isEmpty) return NavigationTabId.discover;
    final safeIndex = index.clamp(0, tabs.length - 1).toInt();
    return tabs[safeIndex].id;
  }

  /// Build navigation destinations for bottom navigation bar.
  List<NavigationDestination> _buildNavDestinations(bool isOffline) {
    return _getVisibleTabs(isOffline).map((tab) => tab.toDestination()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final useSideNav = PlatformDetector.shouldUseSideNavigation(context);

    if (useSideNav) {
      return Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final alwaysExpanded = settingsProvider.alwaysKeepSidebarOpen;
          final contentLeftPadding = alwaysExpanded
              ? SideNavigationRailState.expandedWidth
              : SideNavigationRailState.collapsedWidth;

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
                  child: Stack(
                    children: [
                      // Content with animated left padding based on sidebar state
                      Positioned.fill(
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.only(left: contentLeftPadding),
                          child: FocusScope(
                            node: _contentFocusScope,
                            // No autofocus - we control focus programmatically to prevent
                            // autofocus from stealing focus back after setState() rebuilds
                            child: IndexedStack(index: _currentIndex, children: _screens),
                          ),
                        ),
                      ),
                      // Sidebar overlays content when expanded (unless always expanded)
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        child: FocusScope(
                          node: _sidebarFocusScope,
                          child: SideNavigationRail(
                            key: _sideNavKey,
                            selectedIndex: _currentIndex,
                            selectedLibraryKey: _selectedLibraryGlobalKey,
                            isOfflineMode: _isOffline,
                            isSidebarFocused: _isSidebarFocused,
                            alwaysExpanded: alwaysExpanded,
                            onDestinationSelected: (index) {
                              _selectTab(index);
                              _focusContent();
                            },
                            onLibrarySelected: (key) {
                              _selectLibrary(key);
                              _focusContent();
                            },
                            onNavigateToContent: _focusContent,
                          ),
                        ),
                      ),
                      // Invitation banner overlay
                      if (_currentInvitation != null)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 16,
                          left: contentLeftPadding + 16,
                          right: 16,
                          child: AnimatedInvitationBanner(
                            invitation: _currentInvitation!,
                            onAccept: _acceptInvitation,
                            onDecline: _declineInvitation,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          // Invitation banner overlay for mobile
          if (_currentInvitation != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: AnimatedInvitationBanner(
                invitation: _currentInvitation!,
                onAccept: _acceptInvitation,
                onDecline: _declineInvitation,
              ),
            ),
          // Pending invitations badge for mobile (navigate to Watch Together)
          if (!_isOffline)
            Positioned(
              bottom: 80, // Above bottom navigation
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WatchTogetherScreen()),
                  );
                },
                child: const PendingInvitationsBadge(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectTab,
        destinations: _buildNavDestinations(_isOffline),
      ),
    );
  }
}
