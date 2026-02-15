import 'dart:async';
import '../utils/platform_helper.dart';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/dpad_navigator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/plex_client.dart';
import '../utils/plex_image_helper.dart';
import '../models/plex_metadata.dart';
import '../utils/content_utils.dart';
import '../models/plex_hub.dart';
import '../providers/multi_server_provider.dart';
import '../providers/server_state_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/playback_state_provider.dart';
import 'profile/user_avatar_widget.dart';
import '../widgets/hub_section.dart';
import 'profile/profile_switch_screen.dart';
import '../providers/user_profile_provider.dart';
import '../providers/settings_provider.dart';
import '../mixins/refreshable.dart';
import '../mixins/tab_visibility_aware.dart';
import '../i18n/strings.g.dart';
import '../mixins/item_updatable.dart';
import '../mixins/watch_state_aware.dart';
import '../utils/watch_state_notifier.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../utils/layout_constants.dart';
import '../utils/platform_detector.dart';
import '../theme/mono_tokens.dart';
import '../services/watch_next_service.dart';
import 'auth_screen.dart';
import 'libraries/state_messages.dart';
import 'main_screen.dart';
import '../watch_together/watch_together.dart';
import '../providers/companion_remote_provider.dart';
import '../widgets/companion_remote/remote_session_dialog.dart';
import 'companion_remote/mobile_remote_screen.dart';

class DiscoverScreen extends StatefulWidget {
  final VoidCallback? onBecameVisible;

  const DiscoverScreen({super.key, this.onBecameVisible});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with Refreshable, FullRefreshable, ItemUpdatable, WatchStateAware, TabVisibilityAware, WidgetsBindingObserver {
  static const Duration _heroAutoScrollDuration = Duration(seconds: 8);
  static const Duration _indicatorUpdateInterval = Duration(milliseconds: 200);

  @override
  PlexClient get client {
    final multiServerProvider = Provider.of<MultiServerProvider>(context, listen: false);
    if (!multiServerProvider.hasConnectedServers) {
      throw Exception('No servers available');
    }
    return context.getClientForServer(multiServerProvider.onlineServerIds.first);
  }

  List<PlexMetadata> _onDeck = [];
  List<PlexHub> _hubs = [];
  bool _isLoading = true;
  bool _areHubsLoading = true;
  String? _errorMessage;
  final PageController _heroController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentHeroIndex = 0;
  Timer? _autoScrollTimer;
  Timer? _indicatorTimer;
  final ValueNotifier<double> _indicatorProgress = ValueNotifier(0.0);
  bool _isAutoScrollPaused = false;

  String _toGlobalKey(String ratingKey, String serverId) => '$serverId:$ratingKey';

  // WatchStateAware: watch on-deck items and their parent shows/seasons
  @override
  Set<String>? get watchedRatingKeys {
    final keys = <String>{};
    for (final item in _onDeck) {
      keys.add(item.ratingKey);
      if (item.parentRatingKey != null) {
        keys.add(item.parentRatingKey!);
      }
      if (item.grandparentRatingKey != null) {
        keys.add(item.grandparentRatingKey!);
      }
    }
    return keys;
  }

  @override
  Set<String>? get watchedGlobalKeys {
    final keys = <String>{};
    for (final item in _onDeck) {
      final serverId = item.serverId;
      if (serverId == null) return null;

      keys.add(_toGlobalKey(item.ratingKey, serverId));
      if (item.parentRatingKey != null) {
        keys.add(_toGlobalKey(item.parentRatingKey!, serverId));
      }
      if (item.grandparentRatingKey != null) {
        keys.add(_toGlobalKey(item.grandparentRatingKey!, serverId));
      }
    }
    return keys;
  }

  @override
  void onWatchStateChanged(WatchStateEvent event) {
    // Refresh continue watching when any relevant item changes
    _refreshContinueWatching();
  }

  // Track initial load so we can focus hero when content first appears
  bool _initialLoadComplete = false;

  // Hub navigation keys
  GlobalKey<HubSectionState>? _continueWatchingHubKey;
  final List<GlobalKey<HubSectionState>> _hubKeys = [];

  // Hero and app bar focus
  late FocusNode _heroFocusNode;
  late FocusNode _refreshButtonFocusNode;
  late FocusNode _watchTogetherButtonFocusNode;
  late FocusNode _companionRemoteButtonFocusNode;
  late FocusNode _userButtonFocusNode;
  bool _isRefreshFocused = false;
  bool _isWatchTogetherFocused = false;
  bool _isCompanionRemoteFocused = false;
  bool _isUserFocused = false;

  /// Get the correct PlexClient for an item's server
  PlexClient _getClientForItem(PlexMetadata? item) {
    // Items should always have a serverId, but if not, fall back to first available server
    final serverId = item?.serverId;
    if (serverId == null) {
      final multiServerProvider = Provider.of<MultiServerProvider>(context, listen: false);
      if (!multiServerProvider.hasConnectedServers) {
        throw Exception('No servers available');
      }
      return context.getClientForServer(multiServerProvider.onlineServerIds.first);
    }
    return context.getClientForServer(serverId);
  }

  /// Update hub keys when hubs list changes
  void _updateHubKeys() {
    _hubKeys.clear();
    for (int i = 0; i < _hubs.length; i++) {
      _hubKeys.add(GlobalKey<HubSectionState>());
    }
    // Create continue watching hub key if needed
    if (_onDeck.isNotEmpty) {
      _continueWatchingHubKey ??= GlobalKey<HubSectionState>();
    }
  }

  /// Get all hub states (continue watching + other hubs)
  List<GlobalKey<HubSectionState>> get _allHubKeys {
    final keys = <GlobalKey<HubSectionState>>[];
    if (_continueWatchingHubKey != null && _onDeck.isNotEmpty) {
      keys.add(_continueWatchingHubKey!);
    }
    keys.addAll(_hubKeys);
    return keys;
  }

  bool get _isHeroSectionVisible => _onDeck.isNotEmpty && context.read<SettingsProvider>().showHeroSection;

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void _focusTopBoundary() {
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    if (_isHeroSectionVisible) {
      _heroFocusNode.requestFocus();
    } else {
      _refreshButtonFocusNode.requestFocus();
    }
    _scrollToTop();
  }

  void _focusContentFromAppBar() {
    if (_isHeroSectionVisible) {
      _heroFocusNode.requestFocus();
      return;
    }

    final keys = _allHubKeys;
    if (keys.isNotEmpty) {
      keys.first.currentState?.requestFocusFromMemory();
    }
  }

  /// Handle vertical navigation between hubs
  /// Returns true if the navigation was handled
  bool _handleVerticalNavigation(int hubIndex, bool isUp) {
    final keys = _allHubKeys;
    if (keys.isEmpty) return false;

    // UP from first hub: navigate to hero when visible, otherwise app bar
    if (isUp && hubIndex == 0) {
      _focusTopBoundary();
      return true;
    }

    int targetIndex;
    if (isUp) {
      targetIndex = hubIndex - 1;
    } else {
      targetIndex = hubIndex + 1;
    }

    // Check if target is valid
    if (targetIndex < 0 || targetIndex >= keys.length) {
      // At boundary, block navigation (return true to consume the event)
      return true;
    }

    // Navigate to target hub, clamping to available items
    final targetState = keys[targetIndex].currentState;
    if (targetState != null) {
      targetState.requestFocusFromMemory();
      return true;
    }

    return false;
  }

  /// Navigate focus to the sidebar
  void _navigateToSidebar() {
    MainScreenFocusScope.of(context)?.focusSidebar();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _heroFocusNode = FocusNode(debugLabel: 'hero_section');
    _refreshButtonFocusNode = FocusNode(debugLabel: 'refresh_button');
    _watchTogetherButtonFocusNode = FocusNode(debugLabel: 'watch_together_button');
    _companionRemoteButtonFocusNode = FocusNode(debugLabel: 'companion_remote_button');
    _userButtonFocusNode = FocusNode(debugLabel: 'user_button');
    _refreshButtonFocusNode.addListener(_onRefreshFocusChange);
    _watchTogetherButtonFocusNode.addListener(_onWatchTogetherFocusChange);
    _companionRemoteButtonFocusNode.addListener(_onCompanionRemoteFocusChange);
    _userButtonFocusNode.addListener(_onUserFocusChange);
    _loadContent();
    _startAutoScroll();
  }

  void _onRefreshFocusChange() {
    if (mounted) {
      setState(() {
        _isRefreshFocused = _refreshButtonFocusNode.hasFocus;
      });
    }
  }

  void _onWatchTogetherFocusChange() {
    if (mounted) {
      setState(() {
        _isWatchTogetherFocused = _watchTogetherButtonFocusNode.hasFocus;
      });
    }
  }

  void _onCompanionRemoteFocusChange() {
    if (mounted) {
      setState(() {
        _isCompanionRemoteFocused = _companionRemoteButtonFocusNode.hasFocus;
      });
    }
  }

  void _onUserFocusChange() {
    if (mounted) {
      setState(() {
        _isUserFocused = _userButtonFocusNode.hasFocus;
      });
    }
  }

  /// Handle key events for the hero section
  KeyEventResult _handleHeroKeyEvent(FocusNode node, KeyEvent event) {
    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // DOWN: Move to first hub
    if (key.isDownKey) {
      final keys = _allHubKeys;
      if (keys.isNotEmpty) {
        keys.first.currentState?.requestFocusFromMemory();
      }
      return KeyEventResult.handled;
    }

    // UP: Move to app bar (refresh button)
    if (key.isUpKey) {
      _refreshButtonFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // LEFT: Navigate hero carousel to previous, or focus sidebar at index 0
    if (key.isLeftKey) {
      if (_currentHeroIndex > 0) {
        _heroController.previousPage(duration: tokens(context).slow, curve: Curves.easeInOut);
      } else {
        _navigateToSidebar();
      }
      return KeyEventResult.handled;
    }

    // RIGHT: Navigate hero carousel to next
    if (key.isRightKey) {
      if (_currentHeroIndex < _onDeck.length - 1) {
        _heroController.nextPage(duration: tokens(context).slow, curve: Curves.easeInOut);
      }
      return KeyEventResult.handled;
    }

    // SELECT: Play current hero item
    if (key.isSelectKey) {
      if (_onDeck.isNotEmpty && _currentHeroIndex < _onDeck.length) {
        navigateToVideoPlayer(context, metadata: _onDeck[_currentHeroIndex]);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Handle key events for the refresh button in app bar
  KeyEventResult _handleRefreshKeyEvent(FocusNode node, KeyEvent event) {
    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // DOWN: Return to hero/content
    if (key.isDownKey) {
      _focusContentFromAppBar();
      return KeyEventResult.handled;
    }

    // RIGHT: Move to watch together button
    if (key.isRightKey) {
      _watchTogetherButtonFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // LEFT: Navigate to sidebar
    if (key.isLeftKey) {
      _navigateToSidebar();
      return KeyEventResult.handled;
    }

    // UP: Block at boundary
    if (key.isUpKey) {
      return KeyEventResult.handled;
    }

    // SELECT: Trigger refresh
    if (key.isSelectKey) {
      _loadContent();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Handle key events for the watch together button in app bar
  KeyEventResult _handleWatchTogetherKeyEvent(FocusNode node, KeyEvent event) {
    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // DOWN: Return to hero/content
    if (key.isDownKey) {
      _focusContentFromAppBar();
      return KeyEventResult.handled;
    }

    // LEFT: Move to refresh button
    if (key.isLeftKey) {
      _refreshButtonFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // RIGHT: Move to companion remote button
    if (key.isRightKey) {
      _companionRemoteButtonFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // UP: Block at boundary
    if (key.isUpKey) {
      return KeyEventResult.handled;
    }

    // SELECT: Navigate to Watch Together screen
    if (key.isSelectKey) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchTogetherScreen()));
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Handle key events for the companion remote button in app bar
  KeyEventResult _handleCompanionRemoteKeyEvent(FocusNode node, KeyEvent event) {
    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // DOWN: Return to hero
    if (key.isDownKey) {
      _heroFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // LEFT: Move to watch together button
    if (key.isLeftKey) {
      _watchTogetherButtonFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // RIGHT: Move to user button
    if (key.isRightKey) {
      _userButtonFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // UP: Block at boundary
    if (key.isUpKey) {
      return KeyEventResult.handled;
    }

    // SELECT: Show companion remote dialog (host a remote session)
    if (key.isSelectKey) {
      RemoteSessionDialog.show(context);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Handle key events for the user button in app bar
  KeyEventResult _handleUserKeyEvent(FocusNode node, KeyEvent event) {
    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    // DOWN: Return to hero/content
    if (key.isDownKey) {
      _focusContentFromAppBar();
      return KeyEventResult.handled;
    }

    // LEFT: Move to companion remote button
    if (key.isLeftKey) {
      _companionRemoteButtonFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // RIGHT/UP: Block at boundary
    if (key.isRightKey || key.isUpKey) {
      return KeyEventResult.handled;
    }

    // SELECT: Show user menu
    if (key.isSelectKey) {
      final userProvider = context.read<UserProfileProvider>();
      _showUserMenu(context, userProvider);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _indicatorTimer?.cancel();
    _indicatorProgress.dispose();
    _heroController.dispose();
    _scrollController.dispose();
    _heroFocusNode.dispose();
    _refreshButtonFocusNode.removeListener(_onRefreshFocusChange);
    _refreshButtonFocusNode.dispose();
    _watchTogetherButtonFocusNode.removeListener(_onWatchTogetherFocusChange);
    _watchTogetherButtonFocusNode.dispose();
    _companionRemoteButtonFocusNode.removeListener(_onCompanionRemoteFocusChange);
    _companionRemoteButtonFocusNode.dispose();
    _userButtonFocusNode.removeListener(_onUserFocusChange);
    _userButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh continue watching when app resumes on mobile platforms
    // Skip on desktop to avoid excessive refreshes from window focus changes
    if (state == AppLifecycleState.resumed && (AppPlatform.isIOS || AppPlatform.isAndroid)) {
      appLogger.d('App resumed on mobile - refreshing continue watching');
      _refreshContinueWatching();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_isAutoScrollPaused) return;

    _startIndicatorProgress();
    _autoScrollTimer = Timer.periodic(_heroAutoScrollDuration, (timer) {
      if (_onDeck.isEmpty || !_heroController.hasClients || _isAutoScrollPaused) {
        return;
      }

      // Validate current index is within bounds before calculating next page
      if (_currentHeroIndex >= _onDeck.length) {
        _currentHeroIndex = 0;
      }

      final nextPage = (_currentHeroIndex + 1) % _onDeck.length;
      _heroController.animateToPage(nextPage, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      // Wait for page transition to complete before resetting progress
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isAutoScrollPaused) {
          _startIndicatorProgress();
        }
      });
    });
  }

  void _startIndicatorProgress() {
    _indicatorTimer?.cancel();
    _indicatorProgress.value = 0.0;
    final totalSteps = _heroAutoScrollDuration.inMilliseconds ~/ _indicatorUpdateInterval.inMilliseconds;
    int step = 0;
    _indicatorTimer = Timer.periodic(_indicatorUpdateInterval, (timer) {
      step++;
      _indicatorProgress.value = (step / totalSteps).clamp(0.0, 1.0);
      if (step >= totalSteps) {
        timer.cancel();
      }
    });
  }

  void _stopIndicatorProgress() {
    _indicatorTimer?.cancel();
  }

  void _resetAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _startAutoScroll();
  }

  void _pauseAutoScroll() {
    setState(() {
      _isAutoScrollPaused = true;
    });
    _autoScrollTimer?.cancel();
    _stopIndicatorProgress();
  }

  void _resumeAutoScroll() {
    setState(() {
      _isAutoScrollPaused = false;
    });
    _startAutoScroll();
  }

  @override
  void onTabHidden() {
    _autoScrollTimer?.cancel();
    _stopIndicatorProgress();
  }

  @override
  void onTabShown() {
    if (!_isAutoScrollPaused) {
      _startAutoScroll();
    }
    _focusTopBoundary();
  }

  // Helper method to calculate visible dot range (max 5 dots)
  ({int start, int end}) _getVisibleDotRange() {
    final totalDots = _onDeck.length;
    if (totalDots <= 5) {
      return (start: 0, end: totalDots - 1);
    }

    // Center the active dot when possible
    final center = _currentHeroIndex;
    int start = (center - 2).clamp(0, totalDots - 5);
    int end = start + 4; // 5 dots total (0-4 inclusive)

    return (start: start, end: end);
  }

  // Helper method to determine dot size based on position
  double _getDotSize(int dotIndex, int start, int end) {
    final totalDots = _onDeck.length;

    // If we have 5 or fewer dots, all are full size (8px)
    if (totalDots <= 5) {
      return 8.0;
    }

    // First and last visible dots are smaller if there are more items beyond them
    final isFirstVisible = dotIndex == start && start > 0;
    final isLastVisible = dotIndex == end && end < totalDots - 1;

    if (isFirstVisible || isLastVisible) {
      return 5.0; // Smaller edge dots
    }

    return 8.0; // Normal size
  }

  Future<void> _loadContent() async {
    appLogger.d('Loading discover content from all servers');
    setState(() {
      _isLoading = true;
      _areHubsLoading = true;
      _errorMessage = null;
    });

    try {
      appLogger.d('Fetching onDeck and global hubs from all Plex servers');
      final multiServerProvider = Provider.of<MultiServerProvider>(context, listen: false);

      if (!multiServerProvider.hasConnectedServers) {
        throw Exception('No servers available');
      }

      // Get hidden libraries for filtering
      final hiddenLibrariesProvider = Provider.of<HiddenLibrariesProvider>(context, listen: false);

      // Get settings for hub mode preference (ensure initialized before accessing)
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      await settingsProvider.ensureInitialized();

      // Start OnDeck and hubs fetch in parallel
      final onDeckFuture = multiServerProvider.aggregationService.getOnDeckFromAllServers(
        limit: 20,
        hiddenLibraryKeys: hiddenLibrariesProvider.hiddenLibraryKeys,
      );
      final hubsFuture = multiServerProvider.aggregationService.getHubsFromAllServers(
        hiddenLibraryKeys: hiddenLibrariesProvider.hiddenLibraryKeys,
        useGlobalHubs: settingsProvider.useGlobalHubs,
      );

      // Wait for OnDeck to complete and show it immediately
      final onDeck = await onDeckFuture;

      setState(() {
        _onDeck = onDeck;
        _isLoading = false; // Show content, but hubs still loading

        // Reset hero index to avoid sync issues
        _currentHeroIndex = 0;

        // Create continue watching hub key if needed
        if (_onDeck.isNotEmpty) {
          _continueWatchingHubKey ??= GlobalKey<HubSectionState>();
        }
      });

      // Focus hero section now that it's visible, but only if no modal route is on top
      if (onDeck.isNotEmpty && (ModalRoute.of(context)?.isCurrent ?? false)) {
        _heroFocusNode.requestFocus();
      }

      // Sync to Android TV Watch Next row
      if (AppPlatform.isAndroid) {
        _syncWatchNext(onDeck);
      }

      // Sync PageController to first page after OnDeck loads
      if (_heroController.hasClients && onDeck.isNotEmpty) {
        _heroController.jumpToPage(0);
      }

      // On initial load, focus the hero so the user starts on content (not the toolbar)
      if (!_initialLoadComplete && onDeck.isNotEmpty) {
        _initialLoadComplete = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _heroFocusNode.canRequestFocus && (ModalRoute.of(context)?.isCurrent ?? false)) {
            _heroFocusNode.requestFocus();
          }
        });
      }

      // Wait for global hubs
      final allHubs = await hubsFuture;

      if (!mounted) return;

      // Filter out Continue Watching / On Deck hubs (handled separately in hero section)
      final filteredHubs = allHubs.where((hub) {
        final hubId = hub.hubIdentifier?.toLowerCase() ?? '';
        final title = hub.title.toLowerCase();
        return !hubId.contains('ondeck') &&
            !hubId.contains('continue') &&
            !title.contains('continue watching') &&
            !title.contains('on deck');
      }).toList();

      appLogger.d('Received ${onDeck.length} on deck items and ${filteredHubs.length} global hubs from all servers');
      if (!mounted) return;
      setState(() {
        _hubs = filteredHubs;
        _areHubsLoading = false;
        _updateHubKeys();
      });

      appLogger.d('Discover content loaded successfully');
    } catch (e) {
      appLogger.e('Failed to load discover content', error: e);
      setState(() {
        _errorMessage = 'Failed to load content: $e';
        _isLoading = false;
        _areHubsLoading = false;
      });
    }
  }

  /// Refresh only the Continue Watching section in the background
  /// This is called when returning to the home screen to avoid blocking UI
  Future<void> _refreshContinueWatching() async {
    appLogger.d('Refreshing Continue Watching in background from all servers');

    try {
      final multiServerProvider = context.read<MultiServerProvider>();
      if (!multiServerProvider.hasConnectedServers) {
        appLogger.w('No servers available for background refresh');
        return;
      }

      final hiddenLibrariesProvider = context.read<HiddenLibrariesProvider>();
      final onDeck = await multiServerProvider.aggregationService.getOnDeckFromAllServers(
        limit: 20,
        hiddenLibraryKeys: hiddenLibrariesProvider.hiddenLibraryKeys,
      );

      if (mounted) {
        setState(() {
          _onDeck = onDeck;
          // Reset hero index if needed
          if (_currentHeroIndex >= onDeck.length) {
            _currentHeroIndex = 0;
            if (_heroController.hasClients && onDeck.isNotEmpty) {
              _heroController.jumpToPage(0);
            }
          }
        });

        // Sync to Android TV Watch Next row
        if (AppPlatform.isAndroid) {
          _syncWatchNext(onDeck);
        }

        appLogger.d('Continue Watching refreshed successfully');
      }
    } catch (e) {
      appLogger.w('Failed to refresh Continue Watching', error: e);
      // Silently fail - don't show error to user for background refresh
    }
  }

  /// Sync On Deck items to Android TV Watch Next row
  Future<void> _syncWatchNext(List<PlexMetadata> onDeck) async {
    try {
      await WatchNextService().syncFromOnDeck(onDeck, (serverId) => context.getClientForServer(serverId));
    } catch (e) {
      appLogger.w('Failed to sync Watch Next', error: e);
    }
  }

  // Public method to refresh content (for normal navigation)
  @override
  void refresh() {
    appLogger.d('DiscoverScreen.refresh() called');
    // Only refresh Continue Watching in background, not full screen reload
    _refreshContinueWatching();
  }

  // Public method to fully reload all content (for profile switches)
  @override
  void fullRefresh() {
    appLogger.d('DiscoverScreen.fullRefresh() called - reloading all content');
    // Reload all content including On Deck and content hubs
    _loadContent();
  }

  /// Get icon for hub based on its title
  IconData _getHubIcon(String title) {
    final lowerTitle = title.toLowerCase();

    // Trending/Popular content
    if (lowerTitle.contains('trending')) {
      return Symbols.trending_up_rounded;
    }
    if (lowerTitle.contains('popular') || lowerTitle.contains('imdb')) {
      return Symbols.whatshot_rounded;
    }

    // Seasonal/Time-based
    if (lowerTitle.contains('seasonal')) {
      return Symbols.calendar_month_rounded;
    }
    if (lowerTitle.contains('newly') || lowerTitle.contains('new release')) {
      return Symbols.new_releases_rounded;
    }
    if (lowerTitle.contains('recently released') || lowerTitle.contains('recent')) {
      return Symbols.schedule_rounded;
    }

    // Top/Rated content
    if (lowerTitle.contains('top rated') || lowerTitle.contains('highest rated')) {
      return Symbols.star_rounded;
    }
    if (lowerTitle.contains('top ')) {
      return Symbols.military_tech_rounded;
    }

    // Genre-specific
    if (lowerTitle.contains('thriller')) {
      return Symbols.warning_amber_rounded;
    }
    if (lowerTitle.contains('comedy') || lowerTitle.contains('comedier')) {
      return Symbols.mood_rounded;
    }
    if (lowerTitle.contains('action')) {
      return Symbols.flash_on_rounded;
    }
    if (lowerTitle.contains('drama')) {
      return Symbols.theater_comedy_rounded;
    }
    if (lowerTitle.contains('fantasy')) {
      return Symbols.auto_fix_high_rounded;
    }
    if (lowerTitle.contains('science') || lowerTitle.contains('sci-fi')) {
      return Symbols.rocket_launch_rounded;
    }
    if (lowerTitle.contains('horror') || lowerTitle.contains('skräck')) {
      return Symbols.nights_stay_rounded;
    }
    if (lowerTitle.contains('romance') || lowerTitle.contains('romantic')) {
      return Symbols.favorite_border_rounded;
    }
    if (lowerTitle.contains('adventure') || lowerTitle.contains('äventyr')) {
      return Symbols.explore_rounded;
    }

    // Watchlist/Playlists
    if (lowerTitle.contains('playlist') || lowerTitle.contains('watchlist')) {
      return Symbols.playlist_play_rounded;
    }
    if (lowerTitle.contains('unwatched') || lowerTitle.contains('unplayed')) {
      return Symbols.visibility_off_rounded;
    }
    if (lowerTitle.contains('watched') || lowerTitle.contains('played')) {
      return Symbols.visibility_rounded;
    }

    // Network/Studio
    if (lowerTitle.contains('network') || lowerTitle.contains('more from')) {
      return Symbols.tv_rounded;
    }

    // Actor/Director
    if (lowerTitle.contains('actor') || lowerTitle.contains('director')) {
      return Symbols.person_rounded;
    }

    // Year-based (80s, 90s, etc.)
    if (lowerTitle.contains('80') || lowerTitle.contains('90') || lowerTitle.contains('00')) {
      return Symbols.history_rounded;
    }

    // Rediscover/Start Watching
    if (lowerTitle.contains('rediscover') || lowerTitle.contains('start watching')) {
      return Symbols.play_arrow_rounded;
    }

    // Default icon for other hubs
    return Symbols.auto_awesome_rounded;
  }

  /// Get the set of hub titles that appear more than once (duplicates)
  Set<String> _getDuplicateHubTitles() {
    final titleCounts = <String, int>{};
    for (final hub in _hubs) {
      titleCounts[hub.title] = (titleCounts[hub.title] ?? 0) + 1;
    }
    return titleCounts.entries.where((e) => e.value > 1).map((e) => e.key).toSet();
  }

  @override
  void updateItemInLists(String ratingKey, PlexMetadata updatedMetadata) {
    // Check and update in _onDeck list
    final onDeckIndex = _onDeck.indexWhere((item) => item.ratingKey == ratingKey);
    if (onDeckIndex != -1) {
      _onDeck[onDeckIndex] = updatedMetadata;
    }

    // Check and update in hub items
    for (final hub in _hubs) {
      final itemIndex = hub.items.indexWhere((item) => item.ratingKey == ratingKey);
      if (itemIndex != -1) {
        hub.items[itemIndex] = updatedMetadata;
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showConfirmDialog(
      context,
      title: t.common.logout,
      message: t.messages.logoutConfirm,
      confirmText: t.common.logout,
      isDestructive: true,
    );

    if (confirm && mounted) {
      // Use comprehensive logout through UserProfileProvider
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      final multiServerProvider = context.read<MultiServerProvider>();
      final serverStateProvider = context.read<ServerStateProvider>();
      final hiddenLibrariesProvider = context.read<HiddenLibrariesProvider>();
      final playbackStateProvider = context.read<PlaybackStateProvider>();

      // Clear all user data and provider states
      await userProfileProvider.logout();
      multiServerProvider.clearAllConnections();
      serverStateProvider.reset();
      await hiddenLibrariesProvider.refresh();
      playbackStateProvider.clearShuffle();

      if (mounted) {
        Navigator.of(
          context,
        ).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const AuthScreen()), (route) => false);
      }
    }
  }

  void _handleSwitchProfile(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileSwitchScreen()));
  }

  /// Show user menu programmatically (for D-pad select)
  void _showUserMenu(BuildContext context, UserProfileProvider userProvider) {
    final RenderBox? button = _userButtonFocusNode.context?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        if (userProvider.hasMultipleUsers)
          PopupMenuItem(
            value: 'switch_profile',
            child: Row(
              children: [AppIcon(Symbols.people_rounded, fill: 1), SizedBox(width: 8), Text(t.discover.switchProfile)],
            ),
          ),
        PopupMenuItem(
          value: 'logout',
          child: Row(children: [AppIcon(Symbols.logout_rounded, fill: 1), SizedBox(width: 8), Text(t.common.logout)]),
        ),
      ],
    ).then((value) {
      if (!context.mounted) return;
      if (value == 'switch_profile') {
        _handleSwitchProfile(context);
      } else if (value == 'logout') {
        _handleLogout();
      }
    });
  }

  Widget _buildOverlaidAppBar() {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: statusBarHeight, left: 16, right: 16, bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                t.discover.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Focus(
                focusNode: _refreshButtonFocusNode,
                onKeyEvent: _handleRefreshKeyEvent,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isRefreshFocused ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const AppIcon(Symbols.refresh_rounded, fill: 1, color: Colors.white),
                    onPressed: _loadContent,
                  ),
                ),
              ),
              // Watch Together button
              Consumer<WatchTogetherProvider>(
                builder: (context, watchTogether, child) {
                  return Focus(
                    focusNode: _watchTogetherButtonFocusNode,
                    onKeyEvent: _handleWatchTogetherKeyEvent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isWatchTogetherFocused ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          IconButton(
                            icon: AppIcon(
                              Symbols.group_rounded,
                              fill: watchTogether.isInSession ? 1 : 0,
                              color: watchTogether.isInSession ? Theme.of(context).colorScheme.primary : Colors.white,
                            ),
                            onPressed: () =>
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchTogetherScreen())),
                            tooltip: 'Watch Together',
                          ),
                          // Badge showing participant count when in session
                          if (watchTogether.isInSession && watchTogether.participantCount > 1)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${watchTogether.participantCount}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Companion Remote button
              Consumer<CompanionRemoteProvider>(
                builder: (context, companionRemote, child) {
                  final isDesktop = PlatformDetector.isDesktop(context);
                  final hasDpadNav = isDesktop || PlatformDetector.isTV();

                  return Focus(
                    focusNode: hasDpadNav ? _companionRemoteButtonFocusNode : null,
                    onKeyEvent: hasDpadNav ? _handleCompanionRemoteKeyEvent : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: hasDpadNav && _isCompanionRemoteFocused
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          IconButton(
                            icon: AppIcon(
                              Symbols.phone_android_rounded,
                              fill: companionRemote.isConnected ? 1 : 0,
                              color: companionRemote.isConnected ? Theme.of(context).colorScheme.primary : Colors.white,
                            ),
                            onPressed: () {
                              if (isDesktop) {
                                RemoteSessionDialog.show(context);
                              } else {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => MobileRemoteScreen()));
                              }
                            },
                            tooltip: t.companionRemote.title,
                          ),
                          // Badge showing connection status
                          if (companionRemote.isConnected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Consumer<UserProfileProvider>(
                builder: (context, userProvider, child) {
                  return Focus(
                    focusNode: _userButtonFocusNode,
                    onKeyEvent: _handleUserKeyEvent,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _isUserFocused ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: PopupMenuButton<String>(
                        icon: userProvider.currentUser?.thumb != null
                            ? UserAvatarWidget(user: userProvider.currentUser!, size: 32, showIndicators: false)
                            : const AppIcon(Symbols.account_circle_rounded, fill: 1, size: 32, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'switch_profile') {
                            _handleSwitchProfile(context);
                          } else if (value == 'logout') {
                            _handleLogout();
                          }
                        },
                        itemBuilder: (context) => [
                          // Only show Switch Profile if multiple users available
                          if (userProvider.hasMultipleUsers)
                            PopupMenuItem(
                              value: 'switch_profile',
                              child: Row(
                                children: [
                                  AppIcon(Symbols.people_rounded, fill: 1),
                                  SizedBox(width: 8),
                                  Text(t.discover.switchProfile),
                                ],
                              ),
                            ),
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                AppIcon(Symbols.logout_rounded, fill: 1),
                                SizedBox(width: 8),
                                Text(t.common.logout),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get settings for server name display
    final showServerNameOnHubs = context.watch<SettingsProvider>().showServerNameOnHubs;
    final duplicateHubTitles = _getDuplicateHubTitles();

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Hero Section (Continue Watching) - at top of screen
                Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    if (_onDeck.isNotEmpty && settingsProvider.showHeroSection) {
                      return _buildHeroSection();
                    }
                    // Add top padding when hero is not shown
                    return SliverToBoxAdapter(
                      child: SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top + 16),
                    );
                  },
                ),
                if (_isLoading) const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                if (_errorMessage != null)
                  SliverFillRemaining(
                    child: ErrorStateWidget(
                      message: _errorMessage!,
                      icon: Symbols.error_outline_rounded,
                      onRetry: _loadContent,
                    ),
                  ),
                if (!_isLoading && _errorMessage == null) ...[
                  // On Deck / Continue Watching
                  if (_onDeck.isNotEmpty)
                    SliverToBoxAdapter(
                      child: HubSection(
                        key: _continueWatchingHubKey,
                        hub: PlexHub(
                          hubKey: 'continue_watching',
                          title: t.discover.continueWatching,
                          type: 'mixed',
                          hubIdentifier: '_continue_watching_',
                          size: _onDeck.length,
                          more: false,
                          items: _onDeck,
                        ),
                        icon: Symbols.play_circle_rounded,
                        onRefresh: updateItem,
                        onRemoveFromContinueWatching: _refreshContinueWatching,
                        isInContinueWatching: true,
                        onVerticalNavigation: (isUp) => _handleVerticalNavigation(0, isUp),
                        onNavigateUp: _focusTopBoundary,
                        onNavigateToSidebar: _navigateToSidebar,
                      ),
                    ),

                  // Recommendation Hubs (Trending, Top in Genre, etc.)
                  for (int i = 0; i < _hubs.length; i++)
                    SliverToBoxAdapter(
                      child: HubSection(
                        key: i < _hubKeys.length ? _hubKeys[i] : null,
                        hub: _hubs[i],
                        icon: _getHubIcon(_hubs[i].title),
                        showServerName: showServerNameOnHubs || duplicateHubTitles.contains(_hubs[i].title),
                        onRefresh: updateItem,
                        // Hub index is i + 1 if continue watching exists, otherwise i
                        onVerticalNavigation: (isUp) => _handleVerticalNavigation(_onDeck.isNotEmpty ? i + 1 : i, isUp),
                        onNavigateUp: (i == 0 && _onDeck.isEmpty) ? _focusTopBoundary : null,
                        onNavigateToSidebar: _navigateToSidebar,
                      ),
                    ),

                  // Show loading skeleton for hubs while they're loading
                  if (_areHubsLoading && _hubs.isEmpty)
                    for (int i = 0; i < 3; i++)
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Hub title skeleton
                              Container(
                                width: 200,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Hub items skeleton
                              SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 5,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      width: 140,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                  if (_onDeck.isEmpty && _hubs.isEmpty && !_areHubsLoading)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIcon(Symbols.movie_rounded, fill: 1, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(t.discover.noContentAvailable),
                            SizedBox(height: 8),
                            Text(t.discover.addMediaToLibraries, style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            ),
          ),
          // Overlaid app bar — excluded from default focus traversal so that
          // initial/tab-switch focus lands on content (hero/hubs), not the toolbar.
          // Toolbar buttons are still reachable via explicit UP from hero section.
          Positioned(top: 0, left: 0, right: 0, child: ExcludeFocusTraversal(child: _buildOverlaidAppBar())),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final useSideNav = PlatformDetector.shouldUseSideNavigation(context);
    final heroHeight = useSideNav ? MediaQuery.of(context).size.height * 0.75 : 500 + statusBarHeight;
    return SliverToBoxAdapter(
      child: Focus(
        focusNode: _heroFocusNode,
        onKeyEvent: _handleHeroKeyEvent,
        child: SizedBox(
          height: heroHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              PageView.builder(
                controller: _heroController,
                itemCount: _onDeck.length,
                onPageChanged: (index) {
                  // Validate index is within bounds before updating
                  if (index >= 0 && index < _onDeck.length) {
                    setState(() {
                      _currentHeroIndex = index;
                    });
                    _resetAutoScrollTimer();
                  }
                },
                itemBuilder: (context, index) {
                  return _buildHeroItem(_onDeck[index]);
                },
              ),
              // Bottom gradient that extends past hero bounds to ensure seamless blend
              Positioned(
                left: 0,
                right: 0,
                bottom: -32, // Extend 32px past the hero section bounds
                height: 80, // Tall enough to cover any gap
                child: IgnorePointer(
                  child: Builder(
                    builder: (context) {
                      final bgColor = Theme.of(context).scaffoldBackgroundColor;
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [bgColor.withValues(alpha: 0), bgColor],
                            stops: const [0.0, 0.6],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Page indicators with animated progress and pause/play button
              Positioned(
                bottom: 16,
                left: -26,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pause/Play button
                    GestureDetector(
                      onTap: () {
                        if (_isAutoScrollPaused) {
                          _resumeAutoScroll();
                        } else {
                          _pauseAutoScroll();
                        }
                      },
                      child: AppIcon(
                        _isAutoScrollPaused ? Symbols.play_arrow_rounded : Symbols.pause_rounded,
                        fill: 1,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 18,
                        semanticLabel: '${_isAutoScrollPaused ? t.common.play : t.common.pause} auto-scroll',
                      ),
                    ),
                    // Spacer to separate indicators from button
                    const SizedBox(width: 8),
                    // Page indicators (limited to 5 dots)
                    ...() {
                      final range = _getVisibleDotRange();
                      return List.generate(range.end - range.start + 1, (i) {
                        final index = range.start + i;
                        final isActive = _currentHeroIndex == index;
                        final dotSize = _getDotSize(index, range.start, range.end);

                        if (isActive) {
                          // Progress indicator for active page (~5fps via Timer)
                          return ValueListenableBuilder<double>(
                            valueListenable: _indicatorProgress,
                            builder: (context, progress, child) {
                              final maxWidth = dotSize * 3; // 24px for normal, 15px for small
                              final fillWidth = dotSize + ((maxWidth - dotSize) * progress);
                              final onSurface = Theme.of(context).colorScheme.onSurface;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: maxWidth,
                                height: dotSize,
                                decoration: BoxDecoration(
                                  color: onSurface.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(dotSize / 2),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: fillWidth,
                                    height: dotSize,
                                    decoration: BoxDecoration(
                                      color: onSurface,
                                      borderRadius: BorderRadius.circular(dotSize / 2),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          // Static indicator for inactive pages
                          return AnimatedContainer(
                            duration: tokens(context).slow,
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(dotSize / 2),
                            ),
                          );
                        }
                      });
                    }(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroItem(PlexMetadata heroItem) {
    final isEpisode = heroItem.isEpisode;
    final showName = heroItem.grandparentTitle ?? heroItem.title;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = ScreenBreakpoints.isWideTabletOrLarger(screenWidth);

    // Determine content type label for chip
    final contentTypeLabel = heroItem.isMovie ? t.discover.movie : t.discover.tvShow;

    // Build semantic label for hero item
    final heroLabel = isEpisode ? "${heroItem.grandparentTitle}, ${heroItem.title}" : heroItem.title;

    return Semantics(
      label: heroLabel,
      button: true,
      hint: t.accessibility.tapToPlay,
      child: GestureDetector(
        onTap: () {
          appLogger.d('Navigating to VideoPlayerScreen for: ${heroItem.title}');
          navigateToVideoPlayer(context, metadata: heroItem);
        },
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // Background Image with fade/zoom animation and parallax
            if (heroItem.art != null || heroItem.grandparentArt != null)
              ClipRect(
                child: AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, child) {
                    final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
                    return Transform.translate(offset: Offset(0, scrollOffset * 0.3), child: child);
                  },
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 1.0 + (0.1 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Builder(
                      builder: (context) {
                        final client = _getClientForItem(heroItem);
                        final mediaQuery = MediaQuery.of(context);
                        final dpr = PlexImageHelper.effectiveDevicePixelRatio(context);
                        final imageUrl = PlexImageHelper.getOptimizedImageUrl(
                          client: client,
                          thumbPath: heroItem.art ?? heroItem.grandparentArt,
                          maxWidth: mediaQuery.size.width,
                          maxHeight: mediaQuery.size.height * 0.7,
                          devicePixelRatio: dpr,
                          imageType: ImageType.art,
                        );

                        return CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                          errorWidget: (context, url, error) =>
                              Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                        );
                      },
                    ),
                  ),
                ),
              )
            else
              Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),

            // Gradient Overlay - blends into scaffold background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: -4, // Extend past stack bounds to ensure coverage
              child: Builder(
                builder: (context) {
                  final bgColor = Theme.of(context).scaffoldBackgroundColor;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, bgColor.withValues(alpha: 0.9), bgColor],
                        stops: const [0.5, 0.85, 1.0],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Content with responsive alignment
            Positioned(
              bottom: isLargeScreen ? 80 : 50,
              left: 0,
              right: isLargeScreen ? 200 : 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 40 : 24),
                child: Column(
                  crossAxisAlignment: isLargeScreen ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show logo or name/title
                    if (heroItem.clearLogo != null)
                      SizedBox(
                        height: 120,
                        width: 400,
                        child: Builder(
                          builder: (context) {
                            final client = _getClientForItem(heroItem);
                            final dpr = PlexImageHelper.effectiveDevicePixelRatio(context);
                            final logoUrl = PlexImageHelper.getOptimizedImageUrl(
                              client: client,
                              thumbPath: heroItem.clearLogo,
                              maxWidth: 400,
                              maxHeight: 120,
                              devicePixelRatio: dpr,
                              imageType: ImageType.logo,
                            );

                            return CachedNetworkImage(
                              imageUrl: logoUrl,
                              filterQuality: FilterQuality.medium,
                              fit: BoxFit.contain,
                              memCacheWidth: (400 * dpr).clamp(200, 800).round(),
                              alignment: isLargeScreen ? Alignment.bottomLeft : Alignment.bottomCenter,
                              placeholder: (context, url) => Align(
                                alignment: isLargeScreen ? Alignment.centerLeft : Alignment.center,
                                child: Text(
                                  showName,
                                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: isLargeScreen ? TextAlign.left : TextAlign.center,
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                // Fallback to text if logo fails to load
                                return Align(
                                  alignment: isLargeScreen ? Alignment.centerLeft : Alignment.center,
                                  child: Text(
                                    showName,
                                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: isLargeScreen ? TextAlign.left : TextAlign.center,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      )
                    else
                      Text(
                        showName,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8), blurRadius: 8),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isLargeScreen ? TextAlign.left : TextAlign.center,
                      ),

                    // Metadata as dot-separated text with content type
                    if (heroItem.year != null || heroItem.contentRating != null || heroItem.rating != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        [
                          contentTypeLabel,
                          if (heroItem.rating != null) '★ ${heroItem.rating!.toStringAsFixed(1)}',
                          if (heroItem.contentRating != null) formatContentRating(heroItem.contentRating!),
                          if (heroItem.year != null) heroItem.year.toString(),
                        ].join(' • '),
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        textAlign: isLargeScreen ? TextAlign.left : TextAlign.center,
                      ),
                    ],

                    // On small screens: show button before summary
                    if (!isLargeScreen) ...[const SizedBox(height: 20), _buildSmartPlayButton(heroItem)],

                    // Summary with episode info (Apple TV style)
                    if (heroItem.summary != null) ...[
                      const SizedBox(height: 12),
                      RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: isLargeScreen ? TextAlign.left : TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            color: isLargeScreen
                                ? Colors.white.withValues(alpha: 0.7)
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 14,
                            height: 1.4,
                          ),
                          children: [
                            if (isEpisode && heroItem.parentIndex != null && heroItem.index != null)
                              TextSpan(
                                text: 'S${heroItem.parentIndex}, E${heroItem.index}: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isLargeScreen ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            TextSpan(
                              text: heroItem.summary?.isNotEmpty == true
                                  ? heroItem.summary!
                                  : 'No description available',
                            ),
                          ],
                        ),
                      ),
                    ],

                    // On large screens: show button after summary
                    if (isLargeScreen) ...[const SizedBox(height: 20), _buildSmartPlayButton(heroItem)],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartPlayButton(PlexMetadata heroItem) {
    final hasProgress =
        heroItem.viewOffset != null && heroItem.duration != null && heroItem.viewOffset! > 0 && heroItem.duration! > 0;

    final minutesLeft = hasProgress ? ((heroItem.duration! - heroItem.viewOffset!) / 60000).round() : 0;

    final progress = hasProgress ? heroItem.viewOffset! / heroItem.duration! : 0.0;

    return InkWell(
      onTap: () {
        appLogger.d('Playing: ${heroItem.title}');
        navigateToVideoPlayer(context, metadata: heroItem);
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(Symbols.play_arrow_rounded, fill: 1, size: 20, color: Colors.black),
            const SizedBox(width: 8),
            if (hasProgress) ...[
              // Progress bar
              Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(3)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                t.discover.minutesLeft(minutes: minutesLeft),
                style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ] else
              Text(
                t.common.play,
                style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }
}
