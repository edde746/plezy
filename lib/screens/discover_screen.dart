import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:vibe_stream/widgets/app_icon.dart';
import '../widgets/server_activities_button.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/focusable_action_bar.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import '../utils/global_key_utils.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';

import '../services/image_cache_service.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../media/media_hub.dart';
import '../utils/media_image_helper.dart';
import '../utils/content_utils.dart';
import '../widgets/optimized_media_image.dart' show blurArtwork;
import '../providers/multi_server_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/libraries_provider.dart';
import '../providers/playback_state_provider.dart';
import '../widgets/hub_section.dart';
import '../widgets/clickable_cursor.dart';
import '../widgets/loading_indicator_box.dart';
import '../widgets/profile_switching_overlay.dart';
import 'profile/profile_switch_screen.dart';
import '../connection/connection_registry.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/plex_home_service.dart';
import '../profiles/profile.dart';
import '../profiles/profile_activation.dart';
import '../profiles/profile_avatar.dart';
import '../profiles/profile_connection_registry.dart';
import '../profiles/profile_registry.dart';
import '../providers/user_profile_provider.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../widgets/settings_builder.dart';
import '../widgets/tv_browse_rail.dart';
import '../widgets/tv_spotlight_background.dart';
import '../mixins/refreshable.dart';
import '../mixins/tab_visibility_aware.dart';
import '../i18n/strings.g.dart';
import '../mixins/item_updatable.dart';
import '../mixins/watch_state_aware.dart';
import '../utils/watch_state_notifier.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../utils/media_hub_ordering.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../utils/layout_constants.dart';
import '../utils/platform_detector.dart';
import '../theme/mono_tokens.dart';
import '../services/watch_next_service.dart';
import 'auth_screen.dart';
import 'libraries/content_state_builder.dart';
import 'main_screen.dart';
import '../watch_together/watch_together.dart';
import '../providers/companion_remote_provider.dart';
import '../widgets/companion_remote/remote_session_dialog.dart';
import 'companion_remote/mobile_remote_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with
        Refreshable,
        FullRefreshable,
        ItemUpdatable,
        WatchStateAware,
        TabVisibilityAware,
        FocusableTab,
        WidgetsBindingObserver {
  static const Duration _heroAutoScrollDuration = Duration(seconds: 8);
  static const Duration _indicatorUpdateInterval = Duration(milliseconds: 200);
  static const int _continueWatchingPreviewLimit = 20;
  static const int _continueWatchingProbeLimit = _continueWatchingPreviewLimit + 1;

  /// Items in [_onDeck] and [_hubs] can come from any registered server
  /// (Plex or Jellyfin), so resolve the server per-item rather than via the
  /// mixin's single-server [itemServerId] hook.
  @override
  Future<void> updateItem(String itemId) async {
    try {
      final serverId = _serverIdForItem(itemId);
      if (serverId == null) return;
      final updated = await context.tryGetMediaClientForServer(serverId)?.fetchItem(itemId);
      if (updated == null || !mounted) return;
      setState(() {
        updateItemInLists(itemId, updated);
      });
    } catch (_) {
      // Silently fail — the item will refresh on the next full reload.
    }
  }

  /// Locate the server that owns [itemId] by scanning the visible lists.
  String? _serverIdForItem(String itemId) {
    for (final item in _onDeck) {
      if (item.id == itemId) return item.serverId;
    }
    for (final hub in _hubs) {
      for (final item in hub.items) {
        if (item.id == itemId) return item.serverId;
      }
    }
    return null;
  }

  List<MediaItem> _onDeck = [];
  List<MediaHub> _hubs = [];
  bool _hasMoreContinueWatching = false;
  bool _isLoading = true;
  bool _areHubsLoading = true;
  bool _switchingProfile = false;
  String? _errorMessage;
  final PageController _heroController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentHeroIndex = 0;
  Timer? _autoScrollTimer;
  Timer? _indicatorTimer;
  final ValueNotifier<double> _indicatorProgress = ValueNotifier(0.0);
  bool _isAutoScrollPaused = false;
  bool _heroFocusPausedAutoScroll = false;
  MediaItem? _spotlightItem;
  bool _isTabVisible = true;
  HiddenLibrariesProvider? _hiddenLibrariesProvider;
  LibrariesProvider? _librariesProvider;
  Set<String> _lastSeenHiddenKeys = {};
  List<String> _lastSeenLibraryOrderKeys = const [];

  // WatchStateAware: watch on-deck items and their parent shows/seasons
  @override
  Set<String>? get watchedIds {
    final keys = <String>{};
    for (final item in _onDeck) {
      keys.add(item.id);
      if (item.parentId != null) {
        keys.add(item.parentId!);
      }
      if (item.grandparentId != null) {
        keys.add(item.grandparentId!);
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

      keys.add(buildGlobalKey(serverId, item.id));
      if (item.parentId != null) {
        keys.add(buildGlobalKey(serverId, item.parentId!));
      }
      if (item.grandparentId != null) {
        keys.add(buildGlobalKey(serverId, item.grandparentId!));
      }
    }
    return keys;
  }

  @override
  void onWatchStateChanged(WatchStateEvent event) {
    if (event.changeType == WatchStateChangeType.removedFromContinueWatching) {
      _removeContinueWatchingItem(event.itemId);
      unawaited(_refreshContinueWatching());
      return;
    }

    // Refresh continue watching when any relevant item changes
    unawaited(_refreshContinueWatching());
  }

  void _removeContinueWatchingItem(String itemId) {
    setState(() {
      _onDeck.removeWhere((item) => item.id == itemId);
    });
  }

  // Track initial load so we can focus hero when content first appears
  bool _initialLoadComplete = false;

  // Hub navigation keys
  GlobalKey<HubSectionState>? _continueWatchingHubKey;
  final List<GlobalKey<HubSectionState>> _hubKeys = [];
  final _tvBrowseRailKey = GlobalKey<TvBrowseRailState>();

  // Hero and app bar focus
  late FocusNode _heroFocusNode;
  final _actionBarKey = GlobalKey<FocusableActionBarState>();

  /// Backend-neutral hero client lookup. Returns the actual
  /// [MediaServerClient] for the item's server (Plex or Jellyfin) so
  /// [MediaImageHelper] uses the right transcoder for sized URLs.
  MediaServerClient? _getMediaClientForItem(MediaItem? item) {
    final serverId = item?.serverId;
    if (serverId == null) {
      return context.tryGetMediaClientForServer(null);
    }
    return context.tryGetMediaClientForServer(serverId);
  }

  /// Update hub keys when hubs list changes — reuse existing keys to avoid
  /// mass deep unmounts (ARM32 stack overflow during finalizeTree).
  void _updateHubKeys() {
    while (_hubKeys.length < _hubs.length) {
      _hubKeys.add(GlobalKey<HubSectionState>());
    }
    if (_hubKeys.length > _hubs.length) {
      _hubKeys.removeRange(_hubs.length, _hubKeys.length);
    }
    _continueWatchingHubKey ??= GlobalKey<HubSectionState>();
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

  bool get _isHeroSectionVisible => _onDeck.isNotEmpty && context.settingsRead(SettingsService.showHeroSection);

  MediaItem? get _defaultSpotlightItem {
    if (_onDeck.isNotEmpty) return _onDeck.first;
    for (final hub in _hubs) {
      if (hub.items.isNotEmpty) return hub.items.first;
    }
    return null;
  }

  List<MediaHub> get _tvBrowseHubs {
    final hubs = <MediaHub>[];
    if (_onDeck.isNotEmpty) {
      hubs.add(
        MediaHub(
          id: 'continue_watching',
          title: t.discover.continueWatching,
          type: 'mixed',
          identifier: '_continue_watching_',
          size: _onDeck.length + (_hasMoreContinueWatching ? 1 : 0),
          more: _hasMoreContinueWatching,
          items: _onDeck,
        ),
      );
    }
    hubs.addAll(_hubs.where((hub) => hub.items.isNotEmpty));
    return hubs;
  }

  MediaItem? get _effectiveSpotlightItem {
    final current = _spotlightItem;
    if (current == null) return _defaultSpotlightItem;
    if (_onDeck.any((item) => item.globalKey == current.globalKey)) return current;
    for (final hub in _hubs) {
      if (hub.items.any((item) => item.globalKey == current.globalKey)) return current;
    }
    return _defaultSpotlightItem;
  }

  void _setSpotlightItem(MediaItem item) {
    if (_spotlightItem?.globalKey == item.globalKey) return;
    setState(() => _spotlightItem = item);
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void _focusTopActions() {
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    final actionBar = _actionBarKey.currentState;
    if (actionBar != null) {
      actionBar.requestFocusOnFirst();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
      _actionBarKey.currentState?.requestFocusOnFirst();
    });
  }

  void _focusTopBoundary() {
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    if (PlatformDetector.isTV()) {
      _focusTopActions();
    } else if (_isHeroSectionVisible) {
      _heroFocusNode.requestFocus();
    } else {
      _focusTopActions();
    }
    _scrollToTop();
  }

  void _focusContentFromAppBar() {
    if (PlatformDetector.isTV()) {
      _tvBrowseRailKey.currentState?.requestFocus();
      return;
    }

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
      if (PlatformDetector.isTV()) {
        _focusTopActions();
        return true;
      }
      _focusTopBoundary();
      return true;
    }

    final targetIndex = isUp ? hubIndex - 1 : hubIndex + 1;

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
    _heroFocusNode.addListener(_onHeroFocusChanged);
    _loadContent();
    _startAutoScroll();
  }

  void _onHeroFocusChanged() {
    if (!PlatformDetector.isTV()) return;

    if (_heroFocusNode.hasFocus) {
      _heroFocusPausedAutoScroll = true;
      _autoScrollTimer?.cancel();
      _stopIndicatorProgress();
      return;
    }

    if (_heroFocusPausedAutoScroll) {
      _heroFocusPausedAutoScroll = false;
      if (_isTabVisible && !_isAutoScrollPaused) _startAutoScroll();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<HiddenLibrariesProvider>();
    if (provider != _hiddenLibrariesProvider) {
      _hiddenLibrariesProvider?.removeListener(_onHiddenLibrariesChanged);
      _hiddenLibrariesProvider = provider;
      _hiddenLibrariesProvider!.addListener(_onHiddenLibrariesChanged);
    }
    final librariesProvider = context.read<LibrariesProvider>();
    if (librariesProvider != _librariesProvider) {
      _librariesProvider?.removeListener(_onLibrariesChanged);
      _librariesProvider = librariesProvider;
      _lastSeenLibraryOrderKeys = _libraryOrderKeys(librariesProvider);
      _librariesProvider!.addListener(_onLibrariesChanged);
    }
  }

  void _onHiddenLibrariesChanged() {
    final currentKeys = _hiddenLibrariesProvider?.hiddenLibraryKeys ?? {};
    if (currentKeys.length == _lastSeenHiddenKeys.length && currentKeys.containsAll(_lastSeenHiddenKeys)) {
      return; // No actual change
    }
    _lastSeenHiddenKeys = Set.of(currentKeys);
    _loadContent();
  }

  void _onLibrariesChanged() {
    final provider = _librariesProvider;
    if (provider == null) return;
    final currentKeys = _libraryOrderKeys(provider);
    if (_sameStringList(currentKeys, _lastSeenLibraryOrderKeys)) return;
    _lastSeenLibraryOrderKeys = currentKeys;
    if (_hubs.isEmpty || !mounted) return;

    final sortedHubs = List<MediaHub>.from(_hubs);
    if (!sortMediaHubsByLibraryOrder(sortedHubs, provider.libraries)) return;
    setState(() {
      _hubs = sortedHubs;
      _updateHubKeys();
    });
  }

  List<String> _libraryOrderKeys(LibrariesProvider provider) {
    return [for (final library in provider.libraries) library.globalKey];
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Handle key events for the hero section.
  KeyEventResult _handleHeroKeyEvent(FocusNode node, KeyEvent event) {
    final backResult = handleBackKeyAction(event, _navigateToSidebar);
    if (backResult != KeyEventResult.ignored) return backResult;

    return dpadKeyHandler(
      onDown: () {
        final keys = _allHubKeys;
        if (keys.isNotEmpty) keys.first.currentState?.requestFocusFromMemory();
      },
      onUp: _focusTopActions,
      onLeft: () {
        if (_currentHeroIndex > 0) {
          _heroController.previousPage(duration: tokens(context).slow, curve: Curves.easeInOut);
        } else {
          _navigateToSidebar();
        }
      },
      onRight: () {
        if (_currentHeroIndex < _onDeck.length - 1) {
          _heroController.nextPage(duration: tokens(context).slow, curve: Curves.easeInOut);
        }
      },
      onSelect: () {
        if (_onDeck.isNotEmpty && _currentHeroIndex < _onDeck.length) {
          navigateToVideoPlayer(context, metadata: _onDeck[_currentHeroIndex]);
        }
      },
    )(node, event);
  }

  @override
  void dispose() {
    _hiddenLibrariesProvider?.removeListener(_onHiddenLibrariesChanged);
    _librariesProvider?.removeListener(_onLibrariesChanged);
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _indicatorTimer?.cancel();
    _indicatorProgress.dispose();
    _heroController.dispose();
    _scrollController.dispose();
    _heroFocusNode.removeListener(_onHeroFocusChanged);
    _heroFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Restart auto-scroll only if discover tab is visible
      if (_isTabVisible && !_isAutoScrollPaused) _startAutoScroll();
      // Refresh continue watching on mobile only
      // (on desktop, "resumed" fires on every window focus gain)
      if (Platform.isIOS || Platform.isAndroid) {
        _refreshContinueWatching();
      }
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      // Stop animations to prevent scroll state corruption while backgrounded
      _autoScrollTimer?.cancel();
      _stopIndicatorProgress();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (PlatformDetector.isTV()) return;
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
        if (mounted && !_isAutoScrollPaused) {
          _startIndicatorProgress();
        }
      });
    });
  }

  void _startIndicatorProgress() {
    if (!mounted) return;
    _indicatorTimer?.cancel();
    _indicatorProgress.value = 0.0;
    final totalSteps = _heroAutoScrollDuration.inMilliseconds ~/ _indicatorUpdateInterval.inMilliseconds;
    int step = 0;
    _indicatorTimer = Timer.periodic(_indicatorUpdateInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
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
    _isTabVisible = false;
    _autoScrollTimer?.cancel();
    _stopIndicatorProgress();
  }

  @override
  void onTabShown() {
    _isTabVisible = true;
    if (!_isAutoScrollPaused) {
      _startAutoScroll();
    }
  }

  @override
  void focusActiveTabIfReady() {
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
    final int start = (center - 2).clamp(0, totalDots - 5);
    final int end = start + 4; // 5 dots total (0-4 inclusive)

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
        // Stay in the loading state set above (no error, no spinner replacement)
        // when the binder hasn't finished wiring servers yet — main_screen
        // calls fullRefresh() once binding settles. Surfacing the throw here
        // would briefly flash an error during cold start.
        final activeProfile = Provider.of<ActiveProfileProvider>(context, listen: false);
        if (activeProfile.isBinding) return;
        throw Exception('No servers available');
      }

      // Get hidden libraries for filtering
      final hiddenLibrariesProvider = Provider.of<HiddenLibrariesProvider>(context, listen: false);
      await hiddenLibrariesProvider.ensureInitialized();
      if (!mounted) return;
      _lastSeenHiddenKeys = Set.of(hiddenLibrariesProvider.hiddenLibraryKeys);

      // Let aggregation service fetch libraries internally; the LibrariesProvider
      // stores neutral MediaLibrary objects.

      // Start OnDeck and hubs fetch in parallel
      final useGlobalHubs = context.settingsRead(SettingsService.useGlobalHubs);
      final onDeckFuture = multiServerProvider.aggregationService.getOnDeckFromAllServers(
        limit: _continueWatchingProbeLimit,
        hiddenLibraryKeys: hiddenLibrariesProvider.hiddenLibraryKeys,
      );
      final hubsFuture = multiServerProvider.aggregationService.getHubsFromAllServers(
        hiddenLibraryKeys: hiddenLibrariesProvider.hiddenLibraryKeys,
        useGlobalHubs: useGlobalHubs,
        includePlaybackHubs: false,
      );

      // Wait for OnDeck to complete and show it immediately
      final fetchedOnDeck = await onDeckFuture;
      final hasMoreContinueWatching = fetchedOnDeck.length > _continueWatchingPreviewLimit;
      final onDeck = hasMoreContinueWatching
          ? fetchedOnDeck.take(_continueWatchingPreviewLimit).toList()
          : fetchedOnDeck;

      if (!mounted) return;
      setState(() {
        _onDeck = onDeck;
        _hasMoreContinueWatching = hasMoreContinueWatching;
        _isLoading = false; // Show content, but hubs still loading

        // Reset hero index to avoid sync issues
        _currentHeroIndex = 0;

        // Create continue watching hub key if needed
        if (_onDeck.isNotEmpty) {
          _continueWatchingHubKey ??= GlobalKey<HubSectionState>();
        }
      });

      // Focus hero section now that it's visible, but only if no modal route is on top
      if (!PlatformDetector.isTV() && onDeck.isNotEmpty && (ModalRoute.of(context)?.isCurrent ?? false)) {
        _heroFocusNode.requestFocus();
      }

      // Sync to Android TV Watch Next row
      if (Platform.isAndroid) {
        unawaited(_syncWatchNext(onDeck));
      }

      // Sync PageController to first page after OnDeck loads
      if (_heroController.hasClients && onDeck.isNotEmpty) {
        _heroController.jumpToPage(0);
      }

      // On initial load, focus the hero so the user starts on content (not the toolbar)
      if (!_initialLoadComplete && onDeck.isNotEmpty) {
        _initialLoadComplete = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
          if (PlatformDetector.isTV()) {
            _tvBrowseRailKey.currentState?.requestFocus();
          } else if (_heroFocusNode.canRequestFocus) {
            _heroFocusNode.requestFocus();
          }
        });
      }

      // Wait for global hubs
      final allHubs = await hubsFuture;

      if (!mounted) return;

      // Filter out playback-progress hubs handled by the top Continue Watching row.
      final filteredHubs = allHubs.where((hub) {
        final hubId = hub.identifier?.toLowerCase() ?? '';
        final title = hub.title.toLowerCase();
        return !hubId.contains('ondeck') &&
            !hubId.contains('continue') &&
            !hubId.contains('nextup') &&
            !title.contains('continue watching') &&
            !title.contains('on deck') &&
            !title.contains('next up');
      }).toList();

      final libraryOrder = context.read<LibrariesProvider>().libraries;
      sortMediaHubsByLibraryOrder(filteredHubs, libraryOrder);

      appLogger.d('Received ${onDeck.length} on deck items and ${filteredHubs.length} global hubs from all servers');
      if (!mounted) return;
      setState(() {
        _hubs = filteredHubs;
        _areHubsLoading = false;
        _updateHubKeys();
      });

      if (PlatformDetector.isTV() && !_initialLoadComplete && filteredHubs.isNotEmpty) {
        _initialLoadComplete = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
            _tvBrowseRailKey.currentState?.requestFocus();
          }
        });
      }

      appLogger.d('Discover content loaded successfully');
    } catch (e) {
      appLogger.e('Failed to load discover content', error: e);
      if (!mounted) return;
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
      final fetchedOnDeck = await multiServerProvider.aggregationService.getOnDeckFromAllServers(
        limit: _continueWatchingProbeLimit,
        hiddenLibraryKeys: hiddenLibrariesProvider.hiddenLibraryKeys,
      );
      final hasMoreContinueWatching = fetchedOnDeck.length > _continueWatchingPreviewLimit;
      final onDeck = hasMoreContinueWatching
          ? fetchedOnDeck.take(_continueWatchingPreviewLimit).toList()
          : fetchedOnDeck;

      if (mounted) {
        setState(() {
          _onDeck = onDeck;
          _hasMoreContinueWatching = hasMoreContinueWatching;
          // Reset hero index if needed
          if (_currentHeroIndex >= onDeck.length) {
            _currentHeroIndex = 0;
            if (_heroController.hasClients && onDeck.isNotEmpty) {
              _heroController.jumpToPage(0);
            }
          }
        });

        // Sync to Android TV Watch Next row
        if (Platform.isAndroid) {
          unawaited(_syncWatchNext(onDeck));
        }

        appLogger.d('Continue Watching refreshed successfully');
      }
    } catch (e) {
      appLogger.w('Failed to refresh Continue Watching', error: e);
      // Silently fail - don't show error to user for background refresh
    }
  }

  Future<List<MediaItem>> _loadAllContinueWatchingItems() async {
    final multiServerProvider = context.read<MultiServerProvider>();
    if (!multiServerProvider.hasConnectedServers) return const [];

    final hiddenLibrariesProvider = context.read<HiddenLibrariesProvider>();
    await hiddenLibrariesProvider.ensureInitialized();
    if (!mounted) return const [];

    return multiServerProvider.aggregationService.getOnDeckFromAllServers(
      hiddenLibraryKeys: hiddenLibrariesProvider.hiddenLibraryKeys,
    );
  }

  /// Sync On Deck items to Android TV Watch Next row.
  Future<void> _syncWatchNext(List<MediaItem> onDeck) async {
    try {
      await WatchNextService().syncFromOnDeck(
        onDeck,
        (serverId) => context.getMediaClientWithFallback(serverId),
        hideSpoilers: context.settingsRead(SettingsService.hideSpoilers),
      );
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
  void updateItemInLists(String itemId, MediaItem updatedItem) {
    // Check and update in _onDeck list
    final onDeckIndex = _onDeck.indexWhere((item) => item.id == itemId);
    if (onDeckIndex != -1) {
      _onDeck[onDeckIndex] = updatedItem;
    }

    // Check and update in hub items. [MediaHub.items] is immutable list view;
    // rebuild the hub when one of its items needs to change.
    for (var i = 0; i < _hubs.length; i++) {
      final hub = _hubs[i];
      final itemIndex = hub.items.indexWhere((item) => item.id == itemId);
      if (itemIndex != -1) {
        final newItems = List<MediaItem>.from(hub.items);
        newItems[itemIndex] = updatedItem;
        _hubs[i] = hub.copyWith(items: newItems);
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
      final navigator = Navigator.of(context, rootNavigator: true);
      // Use comprehensive logout through UserProfileProvider
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      final multiServerProvider = context.read<MultiServerProvider>();
      final hiddenLibrariesProvider = context.read<HiddenLibrariesProvider>();
      final playbackStateProvider = context.read<PlaybackStateProvider>();
      final connectionRegistry = context.read<ConnectionRegistry>();
      final profileRegistry = context.read<ProfileRegistry>();
      final profileConnReg = context.read<ProfileConnectionRegistry>();
      final plexHome = context.read<PlexHomeService>();
      final companionRemote = context.read<CompanionRemoteProvider>();

      // Clear all user data and provider states
      await companionRemote.resetForLogout();
      await userProfileProvider.logout();
      multiServerProvider.clearAllConnections();
      // Drop the profile/connection rows so the next sign-in starts clean
      // and doesn't bind to stale tokens or orphaned profile rows.
      await profileConnReg.clear();
      await profileRegistry.clear();
      await connectionRegistry.clear();
      await plexHome.clearAll();
      final storage = await StorageService.getInstance();
      await storage.clearActiveProfileId();
      await storage.clearAllProfileLastUsed();
      await hiddenLibrariesProvider.refresh();
      playbackStateProvider.clearShuffle();

      if (navigator.mounted) {
        unawaited(
          navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const AuthScreen()), (route) => false),
        );
      }
    }
  }

  void _handleSwitchProfile(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileSwitchScreen()));
  }

  /// Build the [FocusableAction] wrapping the user-menu PopupMenuButton.
  /// Pulls live state from [ActiveProfileProvider]; the menu reuses
  /// [_userMenuItems] for the menu contents so d-pad and tap paths
  /// stay in sync.
  FocusableAction _buildUserMenuAction(BuildContext context) {
    final activeProvider = context.watch<ActiveProfileProvider>();
    final active = activeProvider.active;
    final profiles = activeProvider.profiles;

    return FocusableAction(
      onPressed: _switchingProfile ? null : () => _showUserMenu(context),
      child: PopupMenuButton<String>(
        enabled: !_switchingProfile,
        icon: active != null
            ? ProfileAvatar(profile: active, size: 32)
            : const AppIcon(Symbols.account_circle_rounded, fill: 1, size: 32, color: Colors.white),
        itemBuilder: (context) => _userMenuItems(context, activeProfile: active, profiles: profiles),
      ),
    );
  }

  List<PopupMenuEntry<String>> _userMenuItems(
    BuildContext context, {
    required Profile? activeProfile,
    required List<Profile> profiles,
  }) {
    final theme = Theme.of(context);
    final switchable = profiles.where((p) => p.id != activeProfile?.id).toList();
    void deferAction(String value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _handleUserMenuAction(context, value);
      });
    }

    return [
      for (final p in switchable)
        PopupMenuItem<String>(
          value: 'profile:${p.id}',
          onTap: () => deferAction('profile:${p.id}'),
          child: Row(
            children: [
              ProfileAvatar(profile: p, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text(p.displayName, overflow: TextOverflow.ellipsis)),
              if (p.isPinProtected) ...[
                const SizedBox(width: 8),
                AppIcon(Symbols.lock_rounded, fill: 1, size: 14, color: theme.colorScheme.onSurfaceVariant),
              ],
            ],
          ),
        ),
      if (switchable.isNotEmpty) const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'manage_profiles',
        onTap: () => deferAction('manage_profiles'),
        child: const Row(children: [AppIcon(Symbols.group_rounded, fill: 1), SizedBox(width: 8), Text('Profiles')]),
      ),
      PopupMenuItem<String>(
        value: 'logout',
        onTap: () => deferAction('logout'),
        child: Row(
          children: [const AppIcon(Symbols.logout_rounded, fill: 1), const SizedBox(width: 8), Text(t.common.logout)],
        ),
      ),
    ];
  }

  Future<void> _handleUserMenuAction(BuildContext context, String value) async {
    if (_switchingProfile) return;
    if (value == 'logout') {
      unawaited(_handleLogout());
      return;
    }
    if (value == 'manage_profiles') {
      _handleSwitchProfile(context);
      return;
    }
    if (value.startsWith('profile:')) {
      final id = value.substring('profile:'.length);
      final active = context.read<ActiveProfileProvider>();
      final target = active.profiles.where((p) => p.id == id).firstOrNull;
      if (target == null) return;
      await _switchProfileFromMenu(target);
    }
  }

  Future<void> _switchProfileFromMenu(Profile profile) async {
    if (_switchingProfile) return;
    setState(() => _switchingProfile = true);
    try {
      await switchProfileFromUi(context, profile);
    } finally {
      if (mounted) {
        setState(() => _switchingProfile = false);
      }
    }
  }

  /// Show user menu programmatically (for D-pad select)
  void _showUserMenu(BuildContext context) {
    if (_switchingProfile) return;
    final actionBar = _actionBarKey.currentState;
    if (actionBar == null) return;
    final lastNode = actionBar.getFocusNode(actionBar.widget.actions.length - 1);
    final RenderBox? button = lastNode?.context?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final activeProvider = context.read<ActiveProfileProvider>();
    unawaited(
      showMenu<String>(
        context: context,
        position: position,
        items: _userMenuItems(context, activeProfile: activeProvider.active, profiles: activeProvider.profiles),
      ),
    );
  }

  Widget _buildOverlaidAppBar() {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    return DecoratedBox(
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
              if (!PlatformDetector.isTV())
                Text(
                  t.discover.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              const Spacer(),
              Consumer2<WatchTogetherProvider, CompanionRemoteProvider>(
                builder: (context, watchTogether, companionRemote, _) {
                  final isDesktop = PlatformDetector.shouldActAsRemoteHost(context);
                  final colorScheme = Theme.of(context).colorScheme;

                  return FocusableActionBar(
                    key: _actionBarKey,
                    onNavigateLeft: _navigateToSidebar,
                    onNavigateDown: _focusContentFromAppBar,
                    actions: [
                      FocusableAction(icon: Symbols.refresh_rounded, iconColor: Colors.white, onPressed: _loadContent),
                      // Watch Together
                      FocusableAction(
                        onPressed: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchTogetherScreen())),
                        child: Stack(
                          children: [
                            IconButton(
                              icon: AppIcon(
                                Symbols.group_rounded,
                                fill: watchTogether.isInSession ? 1 : 0,
                                color: watchTogether.isInSession ? colorScheme.primary : Colors.white,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const WatchTogetherScreen()),
                              ),
                              tooltip: 'Watch Together',
                            ),
                            if (watchTogether.isInSession && watchTogether.participantCount > 1)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                                  ),
                                  child: Text(
                                    '${watchTogether.participantCount}',
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Companion Remote
                      FocusableAction(
                        onPressed: () {
                          if (isDesktop) {
                            RemoteSessionDialog.show(context);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MobileRemoteScreen()),
                            );
                          }
                        },
                        child: Stack(
                          children: [
                            IconButton(
                              icon: AppIcon(
                                Symbols.phone_android_rounded,
                                fill: companionRemote.isConnected ? 1 : 0,
                                color: companionRemote.isConnected ? colorScheme.primary : Colors.white,
                              ),
                              onPressed: () {
                                if (isDesktop) {
                                  RemoteSessionDialog.show(context);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const MobileRemoteScreen()),
                                  );
                                }
                              },
                              tooltip: t.companionRemote.title,
                            ),
                            if (companionRemote.isConnected)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Server Tasks — Plex-only (`/activities` API has no
                      // Jellyfin equivalent), hide the button entirely on
                      // Jellyfin-only profiles so the chrome doesn't show
                      // a permanently empty popover.
                      if (PlatformDetector.isDesktop(context) &&
                          context.select<MultiServerProvider, bool>((p) => p.hasOnlinePlexServers))
                        const FocusableAction(child: ServerActivitiesButton()),
                      // User menu — profiles + sign out
                      _buildUserMenuAction(context),
                    ],
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
    return SettingsBuilder(
      prefs: const [
        SettingsService.showServerNameOnHubs,
        SettingsService.showHeroSection,
        SettingsService.hideSpoilers,
        SettingsService.libraryDensity,
        SettingsService.episodePosterMode,
      ],
      builder: (context) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final svc = SettingsService.instanceOrNull!;
    final showHeroSection = svc.read(SettingsService.showHeroSection);

    if (PlatformDetector.isTV()) {
      return _buildTvContent(context);
    }

    final showServerNameOnHubs = svc.read(SettingsService.showServerNameOnHubs);
    final duplicateHubTitles = _getDuplicateHubTitles();

    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero Section (Continue Watching) - at top of screen
              Builder(
                builder: (context) {
                  if (_onDeck.isNotEmpty && showHeroSection) {
                    return _buildHeroSection();
                  }
                  // Add top padding when hero is not shown
                  return SliverToBoxAdapter(
                    child: SizedBox(height: kToolbarHeight + MediaQuery.paddingOf(context).top + 16),
                  );
                },
              ),
              if (_isLoading) LoadingIndicatorBox.sliver,
              if (_errorMessage != null) SliverErrorState(message: _errorMessage!, onRetry: _loadContent),
              if (!_isLoading && _errorMessage == null) ...[
                // On Deck / Continue Watching
                if (_onDeck.isNotEmpty)
                  SliverToBoxAdapter(
                    child: HubSection(
                      key: _continueWatchingHubKey,
                      hub: MediaHub(
                        id: 'continue_watching',
                        title: t.discover.continueWatching,
                        type: 'mixed',
                        identifier: '_continue_watching_',
                        size: _onDeck.length + (_hasMoreContinueWatching ? 1 : 0),
                        more: _hasMoreContinueWatching,
                        items: _onDeck,
                      ),
                      icon: Symbols.play_circle_rounded,
                      onRefresh: updateItem,
                      onRemoveFromContinueWatching: _refreshContinueWatching,
                      isInContinueWatching: true,
                      loadMoreItems: _loadAllContinueWatchingItems,
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
                            Container(
                              width: 200,
                              height: 24,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: const BorderRadius.all(Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(height: 16),
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
                          const AppIcon(Symbols.movie_rounded, fill: 1, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(t.discover.noContentAvailable),
                          const SizedBox(height: 8),
                          Text(t.discover.addMediaToLibraries, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: 24 + bottomPadding)),
              ],
            ],
          ),
          // Overlaid app bar — excluded from default focus traversal so that
          // initial/tab-switch focus lands on content (hero/hubs), not the toolbar.
          // Toolbar buttons are still reachable via explicit UP from hero section.
          Positioned(top: 0, left: 0, right: 0, child: ExcludeFocusTraversal(child: _buildOverlaidAppBar())),
          if (_switchingProfile) const ProfileSwitchingOverlay(),
        ],
      ),
    );
  }

  Widget _buildTvContent(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final spotlight = _effectiveSpotlightItem;
    final svc = SettingsService.instanceOrNull!;
    final hideSpoilers = svc.read(SettingsService.hideSpoilers);
    final browseHubs = _tvBrowseHubs;
    final scale = TvLayoutConstants.scaleForSize(size);
    final railHeight = browseHubs.isEmpty
        ? 0.0
        : TvBrowseRailLayout.estimateHeight(
            size: size,
            hubs: browseHubs,
            density: svc.read(SettingsService.libraryDensity),
            episodePosterMode: svc.read(SettingsService.episodePosterMode),
            tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
          );
    final spotlightTop = (size.height * 0.075).clamp(64.0 * scale, 120.0 * scale).toDouble();
    final minimumSpotlightBottom = railHeight + (16 * scale);
    final baseSpotlightBottom = (size.height * 0.53).clamp(180.0, 900.0).toDouble();
    final desiredSpotlightBottom = minimumSpotlightBottom > baseSpotlightBottom
        ? minimumSpotlightBottom
        : baseSpotlightBottom;
    final maxSpotlightBottom = (size.height - spotlightTop - (96 * scale)).clamp(0.0, double.infinity).toDouble();
    final spotlightBottom = desiredSpotlightBottom > maxSpotlightBottom ? maxSpotlightBottom : desiredSpotlightBottom;
    final spotlightLeft = (24 * scale).clamp(18.0, 40.0).toDouble();

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        children: [
          TvSpotlightBackground(
            item: spotlight,
            client: _getMediaClientForItem(spotlight),
            hideSpoilers: hideSpoilers,
            contentTop: spotlightTop,
            contentBottom: spotlightBottom,
            contentLeft: spotlightLeft,
            compact: true,
            showPrimaryAction: false,
          ),
          if (_isLoading || (_areHubsLoading && browseHubs.isEmpty)) const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIcon(Symbols.error_outline_rounded, fill: 1, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _loadContent, child: Text(t.common.retry)),
                ],
              ),
            ),
          if (!_isLoading && _errorMessage == null && browseHubs.isEmpty && !_areHubsLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppIcon(Symbols.movie_rounded, fill: 1, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(t.discover.noContentAvailable),
                  const SizedBox(height: 8),
                  Text(t.discover.addMediaToLibraries, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          if (browseHubs.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: TvBrowseRail(
                key: _tvBrowseRailKey,
                hubs: browseHubs,
                iconForHub: (hub, _) =>
                    hub.id == 'continue_watching' ? Symbols.play_circle_rounded : _getHubIcon(hub.title),
                onFocusedItemChanged: _setSpotlightItem,
                onRefresh: updateItem,
                onRemoveFromContinueWatching: _refreshContinueWatching,
                isContinueWatchingHub: (hub) => hub.id == 'continue_watching',
                loadMoreItems: (hub) =>
                    hub.id == 'continue_watching' ? _loadAllContinueWatchingItems() : Future.value(hub.items),
                onNavigateUp: _focusTopActions,
                onNavigateToSidebar: _navigateToSidebar,
                tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
              ),
            ),
          Positioned(top: 0, left: 0, right: 0, child: ExcludeFocusTraversal(child: _buildOverlaidAppBar())),
          if (_switchingProfile) const ProfileSwitchingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final useSideNav = PlatformDetector.shouldUseSideNavigation(context);
    final isTv = PlatformDetector.isTV();
    final heroHeight = isTv
        ? MediaQuery.sizeOf(context).height * 0.82
        : useSideNav
        ? MediaQuery.sizeOf(context).height * 0.75
        : 500 + statusBarHeight;
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
                  return _buildHeroItem(_onDeck[index], heroHeight);
                },
              ),
              // Page indicators with animated progress and pause/play button
              if (!InputModeTracker.isKeyboardMode(context))
                Positioned(
                  bottom: 16,
                  left: -26,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pause/Play button
                      ClickableCursor(
                        child: GestureDetector(
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
                      ),
                      const SizedBox(width: 8),
                      ...() {
                        final range = _getVisibleDotRange();
                        return List.generate(range.end - range.start + 1, (i) {
                          final index = range.start + i;
                          final isActive = _currentHeroIndex == index;
                          final dotSize = _getDotSize(index, range.start, range.end);

                          return isActive
                              // Progress indicator for active page (~5fps via Timer)
                              ? ValueListenableBuilder<double>(
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
                                )
                              // Static indicator for inactive pages
                              : AnimatedContainer(
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

  Widget _buildHeroItem(MediaItem heroItem, double heroHeight) {
    final heroClient = _getMediaClientForItem(heroItem);
    final isEpisode = heroItem.isEpisode;
    final showName = heroItem.grandparentTitle ?? heroItem.displayTitle;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLargeScreen = ScreenBreakpoints.isWideTabletOrLarger(screenWidth);
    final isTv = PlatformDetector.isTV();
    final alignLeft = isTv || isLargeScreen;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine content type label for chip
    final contentTypeLabel = heroItem.isMovie ? t.discover.movie : t.discover.tvShow;

    // Spoiler protection
    final hideSpoilers = SettingsService.instanceOrNull!.read(SettingsService.hideSpoilers);
    final shouldHideSpoiler = hideSpoilers && heroItem.shouldHideSpoiler;

    // Build semantic label for hero item
    final heroLabel = isEpisode ? "${heroItem.grandparentTitle}, ${heroItem.title}" : heroItem.title;

    return Semantics(
      label: heroLabel,
      button: true,
      hint: t.accessibility.tapToPlay,
      child: ClickableCursor(
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
              if (heroItem.artPath != null ||
                  heroItem.backgroundSquarePath != null ||
                  heroItem.grandparentArtPath != null)
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
                          // heroClient resolves to the actual server's client
                          // (Plex or Jellyfin) so each backend's transcoder
                          // builds sized URLs.
                          final size = MediaQuery.sizeOf(context);
                          final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
                          final containerAspect = screenWidth / heroHeight;
                          final imageUrl = MediaImageHelper.getOptimizedImageUrl(
                            client: heroClient,
                            thumbPath:
                                heroItem.heroArt(containerAspectRatio: containerAspect) ?? heroItem.grandparentArtPath,
                            maxWidth: size.width,
                            maxHeight: size.height * 0.7,
                            devicePixelRatio: dpr,
                            imageType: ImageType.art,
                          );

                          final (_, memHeight) = MediaImageHelper.getMemCacheDimensions(
                            displayWidth: (screenWidth * dpr).round(),
                            displayHeight: (heroHeight * dpr).round(),
                            imageType: ImageType.art,
                          );

                          return blurArtwork(
                            CachedNetworkImage(
                              imageUrl: imageUrl,
                              cacheManager: PlexImageCacheManager.instance,
                              fit: BoxFit.cover,
                              memCacheHeight: memHeight,
                              placeholder: (context, url) =>
                                  ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                              errorBuilder: (context, error, stackTrace) =>
                                  ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                )
              else
                ColoredBox(color: colorScheme.surfaceContainerHighest),

              // Gradient Overlay - blends into scaffold background
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: -4, // Extend past stack bounds to ensure coverage
                child: IgnorePointer(
                  child: Builder(
                    builder: (context) {
                      final bgColor = Theme.of(context).scaffoldBackgroundColor;
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, bgColor.withValues(alpha: 0.9), bgColor],
                            stops: isTv ? const [0.25, 0.78, 1.0] : const [0.5, 0.85, 1.0],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Content with responsive alignment
              Positioned(
                bottom: isTv
                    ? 88
                    : isLargeScreen
                    ? 80
                    : 50,
                left: 0,
                right: isTv
                    ? screenWidth * 0.36
                    : isLargeScreen
                    ? 200
                    : 0,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTv
                        ? TvLayoutConstants.horizontalInset
                        : isLargeScreen
                        ? 40
                        : 24,
                  ),
                  child: Align(
                    alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTv ? TvLayoutConstants.heroContentMaxWidth : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Show logo or name/title
                          if (heroItem.clearLogoPath != null)
                            SizedBox(
                              height: isTv ? TvLayoutConstants.heroLogoHeight : 120,
                              width: isTv ? TvLayoutConstants.heroLogoWidth : 400,
                              child: Builder(
                                builder: (context) {
                                  final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
                                  final logoUrl = MediaImageHelper.getOptimizedImageUrl(
                                    client: heroClient,
                                    thumbPath: heroItem.clearLogoPath,
                                    maxWidth: isTv ? TvLayoutConstants.heroLogoWidth : 400,
                                    maxHeight: isTv ? TvLayoutConstants.heroLogoHeight : 120,
                                    devicePixelRatio: dpr,
                                    imageType: ImageType.logo,
                                  );

                                  return blurArtwork(
                                    CachedNetworkImage(
                                      imageUrl: logoUrl,
                                      cacheManager: PlexImageCacheManager.instance,
                                      filterQuality: FilterQuality.medium,
                                      fit: BoxFit.contain,
                                      memCacheWidth: ((isTv ? TvLayoutConstants.heroLogoWidth : 400) * dpr)
                                          .clamp(200, isTv ? 1000 : 800)
                                          .round(),
                                      alignment: alignLeft ? Alignment.bottomLeft : Alignment.bottomCenter,
                                      placeholder: (context, url) => const SizedBox.shrink(),
                                      errorBuilder: (context, error, stackTrace) {
                                        // Fallback to text if logo fails to load
                                        final theme = Theme.of(context);
                                        final colorScheme = theme.colorScheme;
                                        return Align(
                                          alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
                                          child: Text(
                                            showName,
                                            style: theme.textTheme.displaySmall?.copyWith(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.bold,
                                              fontSize: isTv ? 52 : null,
                                              shadows: [
                                                Shadow(
                                                  color: colorScheme.surface.withValues(alpha: 0.8),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: alignLeft ? TextAlign.left : TextAlign.center,
                                          ),
                                        );
                                      },
                                    ),
                                    sigma: 10,
                                    clip: false,
                                  );
                                },
                              ),
                            )
                          else
                            Text(
                              showName,
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: isTv ? 52 : null,
                                shadows: [Shadow(color: colorScheme.surface.withValues(alpha: 0.8), blurRadius: 8)],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: alignLeft ? TextAlign.left : TextAlign.center,
                            ),

                          // Metadata as dot-separated text with content type
                          if (heroItem.year != null || heroItem.contentRating != null || heroItem.rating != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              [
                                contentTypeLabel,
                                if (heroItem.rating != null) '★ ${formatRating(heroItem.rating!)}',
                                if (heroItem.contentRating != null) formatContentRating(heroItem.contentRating!),
                                if (heroItem.year != null) heroItem.year.toString(),
                              ].join(' • '),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTv ? 18 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: alignLeft ? TextAlign.left : TextAlign.center,
                            ),
                          ],

                          // On small screens: show button before summary
                          if (!alignLeft) ...[const SizedBox(height: 20), _buildSmartPlayButton(heroItem)],

                          // Summary with episode info (Apple TV style)
                          if (heroItem.summary != null && !shouldHideSpoiler) ...[
                            const SizedBox(height: 12),
                            RichText(
                              maxLines: isTv ? 3 : 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: alignLeft ? TextAlign.left : TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  color: alignLeft
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: isTv ? 18 : 14,
                                  height: isTv ? 1.45 : 1.4,
                                ),
                                children: [
                                  if (isEpisode && heroItem.parentIndex != null && heroItem.index != null)
                                    TextSpan(
                                      text: 'S${heroItem.parentIndex}, E${heroItem.index}: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: alignLeft ? Colors.white : colorScheme.onSurface,
                                      ),
                                    ),
                                  TextSpan(
                                    text: heroItem.summary?.isNotEmpty == true
                                        ? heroItem.summary!
                                        : t.messages.noDescriptionAvailable,
                                  ),
                                ],
                              ),
                            ),
                          ] else if (shouldHideSpoiler &&
                              isEpisode &&
                              heroItem.parentIndex != null &&
                              heroItem.index != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'S${heroItem.parentIndex}, E${heroItem.index}: ${heroItem.title}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: alignLeft ? TextAlign.left : TextAlign.center,
                              style: TextStyle(
                                color: alignLeft
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: isTv ? 18 : 14,
                                height: isTv ? 1.45 : 1.4,
                              ),
                            ),
                          ],

                          // On large screens: show button after summary
                          if (alignLeft) ...[SizedBox(height: isTv ? 28 : 20), _buildSmartPlayButton(heroItem)],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartPlayButton(MediaItem heroItem) {
    final hasProgress = heroItem.hasActiveProgress;
    final isTv = PlatformDetector.isTV();

    final minutesLeft = hasProgress ? ((heroItem.durationMs! - heroItem.viewOffsetMs!) / 60000).round() : 0;

    final progress = hasProgress ? heroItem.viewOffsetMs! / heroItem.durationMs! : 0.0;

    return ListenableBuilder(
      listenable: _heroFocusNode,
      builder: (context, _) {
        final showFocus = isTv && _heroFocusNode.hasFocus && InputModeTracker.isKeyboardMode(context);
        final colorScheme = Theme.of(context).colorScheme;
        final backgroundColor = showFocus ? colorScheme.primary : Colors.white;
        final foregroundColor = showFocus ? colorScheme.onPrimary : Colors.black;
        return InkWell(
          onTap: () {
            appLogger.d('Playing: ${heroItem.title}');
            navigateToVideoPlayer(context, metadata: heroItem);
          },
          borderRadius: BorderRadius.all(Radius.circular(isTv ? 32 : 24)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: isTv ? 34 : 24, vertical: isTv ? 16 : 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.all(Radius.circular(isTv ? 32 : 24)),
              boxShadow: showFocus
                  ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.35), blurRadius: 28, spreadRadius: 4)]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(Symbols.play_arrow_rounded, fill: 1, size: isTv ? 28 : 20, color: foregroundColor),
                SizedBox(width: isTv ? 12 : 8),
                if (hasProgress) ...[
                  // Progress bar
                  Container(
                    width: isTv ? 56 : 40,
                    height: isTv ? 8 : 6,
                    decoration: BoxDecoration(
                      color: foregroundColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.all(Radius.circular(isTv ? 4 : 3)),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: foregroundColor,
                          borderRadius: BorderRadius.all(Radius.circular(isTv ? 3 : 2)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isTv ? 12 : 8),
                  Text(
                    t.discover.minutesLeft(minutes: minutesLeft),
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: isTv ? 18 : 14,
                      fontWeight: isTv ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ] else
                  Text(
                    t.common.play,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: isTv ? 18 : 14,
                      fontWeight: isTv ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
