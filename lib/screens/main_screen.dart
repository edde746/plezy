import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HardwareKeyboard, KeyDownEvent, KeyUpEvent, LogicalKeyboardKey, SystemNavigator;
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import '../../services/plex_client.dart';
import '../i18n/strings.g.dart';
import '../services/update_service.dart';
import '../utils/app_logger.dart';
import '../focus/focusable_button.dart';
import '../utils/dialogs.dart';
import '../utils/provider_extensions.dart';
import '../utils/platform_detector.dart';
import '../utils/video_player_navigation.dart';
import '../main.dart';
import '../mixins/refreshable.dart';
import '../widgets/overlay_sheet.dart';
import '../mixins/tab_visibility_aware.dart';
import '../navigation/navigation_tabs.dart';
import '../providers/multi_server_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/libraries_provider.dart';
import '../providers/playback_state_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/settings_service.dart';
import '../providers/offline_mode_provider.dart';
import '../services/plex_auth_service.dart';
import '../services/app_exit_playback_cleanup_service.dart';
import '../services/storage_service.dart';
import '../services/companion_remote/companion_remote_receiver.dart';
import '../providers/companion_remote_provider.dart';
import '../utils/desktop_window_padding.dart';
import '../widgets/side_navigation_rail.dart';
import '../focus/dpad_navigator.dart';
import '../focus/key_event_utils.dart';
import 'discover_screen.dart';
import 'libraries/libraries_screen.dart';
import 'livetv/live_tv_screen.dart';
import 'search_screen.dart';
import 'downloads/downloads_screen.dart';
import 'settings/settings_screen.dart';
import 'profile/profile_switch_screen.dart';
import '../services/watch_next_service.dart';
import '../watch_together/watch_together.dart';

/// Provides access to the main screen's focus control.
class MainScreenFocusScope extends InheritedWidget {
  final VoidCallback focusSidebar;
  final VoidCallback focusContent;
  final bool isSidebarFocused;
  final void Function(String libraryGlobalKey)? selectLibrary;

  const MainScreenFocusScope({
    super.key,
    required this.focusSidebar,
    required this.focusContent,
    required this.isSidebarFocused,
    this.selectLibrary,
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

class _MainScreenState extends State<MainScreen> with RouteAware, WindowListener, WidgetsBindingObserver {
  NavigationTabId _currentTab = NavigationTabId.discover;
  String? _selectedLibraryGlobalKey;

  /// Whether the app is in offline mode (no server connection)
  bool _isOffline = false;

  /// Computed index — searches the same _getVisibleTabs() that _buildScreens iterates,
  /// so _screens[_currentIndex] is always the widget for _currentTab.
  int get _currentIndex {
    final tabs = _getVisibleTabs(_isOffline);
    final idx = tabs.indexWhere((t) => t.id == _currentTab);
    return (idx >= 0 ? idx : 0).clamp(0, _screens.length - 1);
  }

  /// Last selected online tab (restored when coming back online after an offline fallback)
  NavigationTabId? _lastOnlineTabId;

  /// Whether we auto-switched to Downloads because the previous tab was unavailable offline
  bool _autoSwitchedToDownloads = false;

  OfflineModeProvider? _offlineModeProvider;
  MultiServerProvider? _multiServerProvider;
  bool _lastHasLiveTv = false;

  /// Whether a reconnection attempt is in progress
  bool _isReconnecting = false;

  /// Prevents double-pushing the profile selection screen
  bool _isShowingProfileSelection = false;

  late List<Widget> _screens;
  final GlobalKey<State<DiscoverScreen>> _discoverKey = GlobalKey();
  final GlobalKey<State<LibrariesScreen>> _librariesKey = GlobalKey();
  final GlobalKey<State<LiveTvScreen>> _liveTvKey = GlobalKey();
  final GlobalKey<State<SearchScreen>> _searchKey = GlobalKey();
  final GlobalKey<State<DownloadsScreen>> _downloadsKey = GlobalKey();
  final GlobalKey<State<SettingsScreen>> _settingsKey = GlobalKey();
  final GlobalKey<SideNavigationRailState> _sideNavKey = GlobalKey();

  // Focus management for sidebar/content switching
  final FocusScopeNode _sidebarFocusScope = FocusScopeNode(debugLabel: 'Sidebar');
  final FocusScopeNode _contentFocusScope = FocusScopeNode(debugLabel: 'Content');
  bool _isSidebarFocused = false;

  @override
  void initState() {
    super.initState();
    _isOffline = widget.isOfflineMode;

    WidgetsBinding.instance.addObserver(this);

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      windowManager.addListener(this);
      windowManager.setPreventClose(true);
    }

    _currentTab = _isOffline ? NavigationTabId.downloads : NavigationTabId.discover;
    _lastOnlineTabId = _isOffline ? null : NavigationTabId.discover;
    _autoSwitchedToDownloads = _isOffline;

    // Synchronize _lastHasLiveTv with provider before building screens
    // so _buildScreens and _hasLiveTv getter agree from the start.
    try {
      _lastHasLiveTv = context.read<MultiServerProvider>().hasLiveTv;
    } catch (_) {
      _lastHasLiveTv = false;
    }
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

        // Ensure first login (or any unset profile state) requires explicit selection.
        await _promptForInitialProfileSelection(userProfileProvider);
      }

      // Focus content initially (replaces autofocus which caused focus stealing issues)
      // Skip if profile selection is on top — it manages its own focus.
      if (!_isSidebarFocused && !_isShowingProfileSelection) {
        _contentFocusScope.requestFocus();
      }

      // Check for updates on startup
      _checkForUpdatesOnStartup();
    });
  }

  Future<void> _promptForInitialProfileSelection(UserProfileProvider userProfileProvider) async {
    if (!mounted || _isShowingProfileSelection) return;

    final needsInitial = userProfileProvider.needsInitialProfileSelection;
    final settingsService = await SettingsService.getInstance();
    if (!mounted) return;
    final requireOnOpen = settingsService.getRequireProfileSelectionOnOpen() && userProfileProvider.hasMultipleUsers;

    if (!needsInitial && !requireOnOpen) return;

    _isShowingProfileSelection = true;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfileSwitchScreen(requireSelection: true)));
    _isShowingProfileSelection = false;
  }

  Future<void> _checkForUpdatesOnStartup() async {
    // Delay slightly to allow UI to settle
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Native updater (Sparkle/WinSparkle) handles everything — skip Flutter dialog
    if (UpdateService.useNativeUpdater) {
      await UpdateService.checkForUpdatesNative(inBackground: true);
      return;
    }

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
            FocusableButton(
              autofocus: true,
              onPressed: () => Navigator.pop(dialogContext),
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: const StadiumBorder(),
                ),
                child: Text(t.common.later),
              ),
            ),
            FocusableButton(
              onPressed: () async {
                await UpdateService.skipVersion(updateInfo['latestVersion']);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: TextButton(
                onPressed: () async {
                  await UpdateService.skipVersion(updateInfo['latestVersion']);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: const StadiumBorder(),
                ),
                child: Text(t.update.skipVersion),
              ),
            ),
            FocusableButton(
              onPressed: () async {
                final url = Uri.parse(updateInfo['releaseUrl']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: FilledButton(
                onPressed: () async {
                  final url = Uri.parse(updateInfo['releaseUrl']);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: Text(t.update.viewRelease),
              ),
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
    } catch (e) {
      appLogger.w('Could not set up Watch Together callback', error: e);
    }
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
      await navigateToWatchTogetherPlayback(context, ratingKey: ratingKey, serverId: serverId);
    } catch (e) {
      appLogger.e('WatchTogether: Failed to navigate to media', error: e);
    }
  }

  bool _companionRemoteSetup = false;
  bool _isClosingApp = false;

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

    // Listen for Live TV / DVR availability changes
    final multiServer = context.read<MultiServerProvider>();
    if (multiServer != _multiServerProvider) {
      _multiServerProvider?.removeListener(_handleLiveTvChanged);
      _multiServerProvider = multiServer;
      _multiServerProvider!.addListener(_handleLiveTvChanged);
    }

    // Wire up Companion Remote command routing (host devices only, once)
    if (!_companionRemoteSetup && PlatformDetector.shouldActAsRemoteHost(context)) {
      _companionRemoteSetup = true;
      _setupCompanionRemote();
    }

    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  void _setupCompanionRemote() {
    final companionRemote = context.read<CompanionRemoteProvider>();
    companionRemote.onCommandReceived = (command) {
      if (mounted) {
        CompanionRemoteReceiver.instance.handleCommand(command, context);
      }
    };

    final receiver = CompanionRemoteReceiver.instance;

    receiver.onTabNext = () {
      final tabs = _getVisibleTabs(_isOffline);
      final idx = tabs.indexWhere((t) => t.id == _currentTab);
      if (idx >= 0) _selectTab(tabs[(idx + 1) % tabs.length].id);
    };
    receiver.onTabPrevious = () {
      final tabs = _getVisibleTabs(_isOffline);
      final idx = tabs.indexWhere((t) => t.id == _currentTab);
      if (idx >= 0) _selectTab(tabs[(idx - 1 + tabs.length) % tabs.length].id);
    };
    receiver.onTabDiscover = () => _selectTab(NavigationTabId.discover);
    receiver.onTabLibraries = () => _selectTab(NavigationTabId.libraries);
    receiver.onTabSearch = () => _selectTab(NavigationTabId.search);
    receiver.onTabDownloads = () => _selectTab(NavigationTabId.downloads);
    receiver.onTabSettings = () => _selectTab(NavigationTabId.settings);
    receiver.onHome = () => _selectTab(NavigationTabId.discover);
    receiver.onSearchAction = (query) {
      _selectTab(NavigationTabId.search);
      if (query != null && query.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_searchKey.currentState case final SearchInputFocusable searchable) {
            searchable.setSearchQuery(query);
          }
        });
      }
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      windowManager.removeListener(this);
      windowManager.setPreventClose(false);
    }
    _offlineModeProvider?.removeListener(_handleOfflineStatusChanged);
    _multiServerProvider?.removeListener(_handleLiveTvChanged);
    _sidebarFocusScope.dispose();
    _contentFocusScope.dispose();

    // Clean up companion remote callbacks
    if (_companionRemoteSetup) {
      final receiver = CompanionRemoteReceiver.instance;
      receiver.onTabNext = null;
      receiver.onTabPrevious = null;
      receiver.onTabDiscover = null;
      receiver.onTabLibraries = null;
      receiver.onTabSearch = null;
      receiver.onTabDownloads = null;
      receiver.onTabSettings = null;
      receiver.onHome = null;
      receiver.onSearchAction = null;
    }

    super.dispose();
  }

  @override
  void onWindowClose() {
    unawaited(_closeApplication());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isOffline && !_isShowingProfileSelection) {
      // Only show profile selection on resume for mobile platforms.
      // On desktop, "resumed" fires on every window focus gain (alt-tab, click),
      // which is too frequent — the initial prompt on startup is sufficient.
      if (Platform.isAndroid || Platform.isIOS) {
        _showProfileSelectionOnResume();
      }
    }
  }

  Future<void> _showProfileSelectionOnResume() async {
    final settingsService = await SettingsService.getInstance();
    if (!settingsService.getRequireProfileSelectionOnOpen()) return;
    if (!mounted) return;

    final userProfileProvider = context.read<UserProfileProvider>();
    if (!userProfileProvider.hasMultipleUsers) return;

    _isShowingProfileSelection = true;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfileSwitchScreen(requireSelection: true)));
    _isShowingProfileSelection = false;
  }

  /// IndexedStack that disables tickers for offscreen children to prevent
  /// animation controllers on non-visible tabs from scheduling frames.
  Widget _buildTickerAwareStack() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        for (var i = 0; i < _screens.length; i++)
          TickerMode(
            enabled: i == _currentIndex,
            child: _screens[i],
          ),
      ],
    );
  }

  List<Widget> _buildScreens(bool offline) {
    return [
      for (final tab in _getVisibleTabs(offline))
        switch (tab.id) {
          NavigationTabId.discover => DiscoverScreen(key: _discoverKey, onBecameVisible: _onDiscoverBecameVisible),
          NavigationTabId.libraries => LibrariesScreen(key: _librariesKey, onLibraryOrderChanged: _onLibraryOrderChanged),
          NavigationTabId.liveTv => LiveTvScreen(key: _liveTvKey),
          NavigationTabId.search => SearchScreen(key: _searchKey),
          NavigationTabId.downloads => DownloadsScreen(key: _downloadsKey),
          NavigationTabId.settings => SettingsScreen(key: _settingsKey),
        },
    ];
  }

  /// Normalize tab ID when switching between offline/online modes.
  /// Preserves the current tab if it exists in the new mode, otherwise defaults to first tab.
  NavigationTabId _normalizeTabForMode(NavigationTabId currentTab, bool isOffline) {
    final tabs = _getVisibleTabs(isOffline);
    if (tabs.any((t) => t.id == currentTab)) return currentTab;
    return tabs.first.id;
  }

  void _triggerReconnect() {
    if (_isReconnecting) return;
    setState(() => _isReconnecting = true);

    final serverManager = context.read<MultiServerProvider>().serverManager;
    serverManager.checkServerHealth();
    serverManager.reconnectOfflineServers().whenComplete(() {
      // Give a moment for status updates to propagate
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _isReconnecting = false);
      });
    });
  }

  void _handleLiveTvChanged() {
    final hasLiveTv = _multiServerProvider?.hasLiveTv ?? false;
    if (hasLiveTv == _lastHasLiveTv) return;
    _lastHasLiveTv = hasLiveTv;

    setState(() {
      _screens = _buildScreens(_isOffline);
      _currentTab = _normalizeTabForMode(_currentTab, _isOffline);
    });
  }

  void _handleOfflineStatusChanged() {
    final newOffline = _offlineModeProvider?.isOffline ?? widget.isOfflineMode;

    if (newOffline == _isOffline) return;

    final previousTab = _currentTab;
    final wasOffline = _isOffline;
    setState(() {
      _isReconnecting = false;
      _isOffline = newOffline;
      _screens = _buildScreens(_isOffline);
      _selectedLibraryGlobalKey = _isOffline ? null : _selectedLibraryGlobalKey;

      if (_isOffline) {
        // Remember the online tab so we can restore it when reconnecting.
        if (!wasOffline) {
          _lastOnlineTabId = previousTab;
        }

        final normalizedTab = _normalizeTabForMode(_currentTab, _isOffline);
        _currentTab = normalizedTab;

        // Track if we auto-switched to Downloads because the previous tab was unavailable.
        _autoSwitchedToDownloads =
            previousTab != NavigationTabId.downloads &&
            normalizedTab == NavigationTabId.downloads;
      } else {
        // Coming back online: restore the last online tab if we forced a switch to Downloads.
        if (_autoSwitchedToDownloads) {
          final restoredTab = _lastOnlineTabId ?? NavigationTabId.discover;
          _currentTab = _normalizeTabForMode(restoredTab, _isOffline);
        } else {
          _currentTab = _normalizeTabForMode(_currentTab, _isOffline);
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
    // Only programmatically focus if the scope didn't auto-restore a child.
    // This preserves the user's focus position when returning from sidebar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_contentFocusScope.focusedChild == null) {
        if (_screenKeyFor(_currentTab)?.currentState case final FocusableTab focusable) {
          focusable.focusActiveTabIfReady();
        }
      }
    });
  }

  /// Suppress stray back events after a child route pops.
  /// On Android TV the platform popRoute can arrive before the key events,
  /// so BackKeySuppressorObserver misses them and they leak into _handleBackKey.
  bool _suppressBackAfterPop = false;

  Future<void> _closeApplication() async {
    if (_isClosingApp) return;
    _isClosingApp = true;

    try {
      await AppExitPlaybackCleanupService.instance.prepareForExit();
      await Future.delayed(const Duration(milliseconds: 200));

      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        await windowManager.setPreventClose(false);
        await windowManager.close();
      } else {
        await SystemNavigator.pop();
      }
    } finally {
      _isClosingApp = false;
    }
  }

  KeyEventResult _handleBackKey(KeyEvent event) {
    if (_suppressBackAfterPop && event.logicalKey.isBackKey) {
      if (event is KeyUpEvent) _suppressBackAfterPop = false;
      return KeyEventResult.handled;
    }

    if (!_isSidebarFocused) {
      // Content focused → move to sidebar
      return handleBackKeyAction(event, _focusSidebar);
    }

    // Sidebar focused → exit app
    return handleBackKeyAction(event, () async {
      if (PlatformDetector.isTV()) {
        final settings = await SettingsService.getInstance();
        if (settings.getConfirmExitOnBack() && mounted) {
          final result = await showConfirmDialogWithCheckbox(
            context,
            title: t.common.exitConfirmTitle,
            message: t.common.exitConfirmMessage,
            confirmText: t.common.exit,
            checkboxLabel: t.common.dontAskAgain,
          );
          if (result.checked) {
            await settings.setConfirmExitOnBack(false);
          }
          if (!result.confirmed) return;
        }
      }
      await _closeApplication();
    });
  }

  /// Handle Cmd+F (macOS) / Ctrl+F (Windows/Linux) to navigate to search.
  KeyEventResult _handleSearchShortcut(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.keyF) return KeyEventResult.ignored;

    final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;
    final isControlPressed = HardwareKeyboard.instance.isControlPressed;

    final isMacShortcut = Platform.isMacOS && isMetaPressed && !isControlPressed;
    final isOtherShortcut = !Platform.isMacOS && isControlPressed && !isMetaPressed;

    if (!isMacShortcut && !isOtherShortcut) return KeyEventResult.ignored;
    if (_isOffline) return KeyEventResult.handled;

    _selectTab(NavigationTabId.search);
    if (_isSidebarFocused) _focusContent();
    // Schedule focus after the frame so the search screen is visible in the IndexedStack
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_searchKey.currentState case final SearchInputFocusable searchable) {
        searchable.focusSearchInput();
      }
    });
    return KeyEventResult.handled;
  }

  @override
  void didPush() {
    // Called when this route has been pushed (initial navigation)
    if (_currentTab == NavigationTabId.discover) {
      _onDiscoverBecameVisible();
    }
  }

  @override
  void didPushNext() {
    // Called when a child route is pushed on top (e.g., video player)
    if (_currentTab == NavigationTabId.discover) {
      if (_discoverKey.currentState case final TabVisibilityAware aware) {
        aware.onTabHidden();
      }
    }
  }

  @override
  void didPopNext() {
    // Suppress stray back key events from the pop that just returned us here
    _suppressBackAfterPop = true;
    // Auto-clear after 2 frames in case no back event arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _suppressBackAfterPop = false;
      });
    });

    // Called when returning to this route from a child route (e.g., from video player)
    if (_currentTab == NavigationTabId.discover) {
      if (_discoverKey.currentState case final TabVisibilityAware aware) {
        aware.onTabShown();
      }
      _onDiscoverBecameVisible();
    }
  }

  void _onDiscoverBecameVisible() {
    appLogger.d('Navigated to home');
    // Refresh content when returning to discover page
    if (_discoverKey.currentState case final Refreshable refreshable) {
      refreshable.refresh();
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
    hiddenLibrariesProvider.refresh();
    playbackStateProvider.clearShuffle();

    appLogger.d('Cleared all provider states for profile switch');

    // Full refresh discover screen (reload all content for new profile)
    if (_discoverKey.currentState case final FullRefreshable refreshable) {
      refreshable.fullRefresh();
    }

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

  void _selectTab(NavigationTabId tab) {
    // Guard: ignore if tab isn't available in current mode
    if (!_getVisibleTabs(_isOffline).any((t) => t.id == tab)) return;

    final previousTab = _currentTab;
    setState(() {
      _currentTab = tab;
      if (!_isOffline) {
        _lastOnlineTabId = tab;
      } else if (previousTab != tab) {
        // User made an explicit offline selection, so don't auto-restore later.
        _autoSwitchedToDownloads = false;
      }
    });

    if (previousTab != tab) {
      // Notify previous screen it's being hidden
      if (_screenKeyFor(previousTab)?.currentState case final TabVisibilityAware aware) {
        aware.onTabHidden();
      }
      // Notify and focus new screen
      final newState = _screenKeyFor(tab)?.currentState;
      if (newState case final TabVisibilityAware aware) {
        aware.onTabShown();
      }
      if (newState case final FocusableTab focusable) {
        focusable.focusActiveTabIfReady();
      }
    }

    // Discover: always refresh content (even on re-selection)
    if (!_isOffline && tab == NavigationTabId.discover) {
      _onDiscoverBecameVisible();
    }

    // Focus search input after rebuild so IndexedStack has made it visible
    if (tab == NavigationTabId.search) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_searchKey.currentState case final SearchInputFocusable searchable) {
          searchable.focusSearchInput();
        }
      });
    }
  }

  /// Handle library selection from side navigation rail
  void _selectLibrary(String libraryGlobalKey) {
    _selectedLibraryGlobalKey = libraryGlobalKey;
    _selectTab(NavigationTabId.libraries);
    // Tell LibrariesScreen to load this library after tab switch
    if (_librariesKey.currentState case final LibraryLoadable loadable) {
      loadable.loadLibraryByKey(libraryGlobalKey);
    }
    if (_librariesKey.currentState case final FocusableTab focusable) {
      focusable.focusActiveTabIfReady();
    }
  }

  /// Whether the Live TV tab is currently visible
  /// Use the synchronized value so screens list and nav bar always agree.
  /// Updated by _handleLiveTvChanged when the provider notifies.
  bool get _hasLiveTv => _lastHasLiveTv;

  /// Get navigation tabs filtered by offline mode
  List<NavigationTab> _getVisibleTabs(bool isOffline) {
    return NavigationTab.getVisibleTabs(isOffline: isOffline, hasLiveTv: _hasLiveTv);
  }

  /// Get the GlobalKey for a given tab.
  GlobalKey? _screenKeyFor(NavigationTabId tab) {
    return switch (tab) {
      NavigationTabId.discover => _discoverKey,
      NavigationTabId.libraries => _librariesKey,
      NavigationTabId.liveTv => _liveTvKey,
      NavigationTabId.search => _searchKey,
      NavigationTabId.downloads => _downloadsKey,
      NavigationTabId.settings => _settingsKey,
    };
  }

  /// Build navigation destinations for bottom navigation bar.
  List<NavigationDestination> _buildNavDestinations(bool isOffline) {
    return _getVisibleTabs(isOffline).map((tab) => tab.toDestination()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final useSideNav = PlatformDetector.shouldUseSideNavigation(context);

    return _buildContent(context, useSideNav);
  }

  Widget _buildContent(BuildContext context, bool useSideNav) {
    if (useSideNav) {
      return Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final alwaysExpanded = settingsProvider.alwaysKeepSidebarOpen;
          final contentLeftPadding = alwaysExpanded
              ? SideNavigationRailState.expandedWidth
              : SideNavigationRailState.collapsedWidth;

          return OverlaySheetHost(
            child: PopScope(
              canPop: false, // Prevent system back from popping on Android TV
              // ignore: no-empty-block - required callback, back navigation handled by _handleBackKey
              onPopInvokedWithResult: (didPop, result) {},
              child: Focus(
                onKeyEvent: (node, event) {
                  final searchResult = _handleSearchShortcut(event);
                  if (searchResult == KeyEventResult.handled) return searchResult;
                  return _handleBackKey(event);
                },
                child: MainScreenFocusScope(
                  focusSidebar: _focusSidebar,
                  focusContent: _focusContent,
                  isSidebarFocused: _isSidebarFocused,
                  selectLibrary: _selectLibrary,
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
                              child: _buildTickerAwareStack(),
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
                              selectedTab: _currentTab,
                              selectedLibraryKey: _selectedLibraryGlobalKey,
                              isOfflineMode: _isOffline,
                              isSidebarFocused: _isSidebarFocused,
                              alwaysExpanded: alwaysExpanded,
                              isReconnecting: _isReconnecting,
                              onDestinationSelected: (tab) {
                                _selectTab(tab);
                                _focusContent();
                              },
                              onLibrarySelected: (key) {
                                _selectLibrary(key);
                                _focusContent();
                              },
                              onNavigateToContent: _focusContent,
                              onReconnect: _triggerReconnect,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return OverlaySheetHost(
      child: Scaffold(
        body: _buildTickerAwareStack(),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reconnect bar when offline
            if (_isOffline)
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: InkWell(
                  onTap: _isReconnecting ? null : _triggerReconnect,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isReconnecting)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        else
                          Icon(Symbols.wifi_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          t.common.reconnect,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                final hideLabels = !settingsProvider.showNavBarLabels;
                return NavigationBarTheme(
                  data: NavigationBarTheme.of(context).copyWith(height: hideLabels ? 56 : null),
                  child: NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (i) {
                      final tabs = _getVisibleTabs(_isOffline);
                      if (i >= 0 && i < tabs.length) _selectTab(tabs[i].id);
                    },
                    labelBehavior: hideLabels
                        ? NavigationDestinationLabelBehavior.alwaysHide
                        : NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: _buildNavDestinations(_isOffline),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
