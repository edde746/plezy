import 'dart:async';
import '../media/ids.dart';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HardwareKeyboard, LogicalKeyboardKey;
import 'package:plezy/widgets/app_icon.dart';
import '../widgets/server_activities_button.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/focusable_action_bar.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';

import '../services/apple_tv_remote_touch_service.dart';
import '../services/image_cache_service.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../media/media_hub.dart';
import '../utils/media_image_helper.dart';
import '../utils/content_utils.dart';
import '../widgets/optimized_media_image.dart' show blurArtwork;
import '../providers/discover_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/playback_state_provider.dart';
import '../providers/watch_state_store.dart';
import '../widgets/hub_section.dart';
import '../widgets/app_menu.dart';
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
import '../widgets/fitting_title_text.dart';
import '../widgets/tv_browse_rail.dart';
import '../widgets/tv_spotlight_background.dart';
import '../mixins/refreshable.dart';
import '../mixins/tab_visibility_aware.dart';
import '../i18n/strings.g.dart';
import '../utils/app_logger.dart';
import '../utils/debouncer.dart';
import '../utils/dialogs.dart';
import '../utils/formatters.dart';
import '../utils/media_navigation_helper.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../utils/layout_constants.dart';
import '../utils/platform_detector.dart';
import '../theme/mono_tokens.dart';
import 'auth_screen.dart';
import 'libraries/content_state_builder.dart';
import 'main_screen.dart';
import 'settings/settings_screen.dart';
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
    with Refreshable, FullRefreshable, TabVisibilityAware, FocusableTab, WidgetsBindingObserver {
  static const Duration _heroAutoScrollDuration = Duration(seconds: 8);
  static const Duration _indicatorUpdateInterval = Duration(milliseconds: 200);

  /// Data + refresh policy live in [DiscoverProvider]; this state keeps only
  /// UI concerns (hero carousel, focus, spotlight). The proxy getters keep
  /// the build code reading naturally.
  late final DiscoverProvider _discover;
  int _seenLoadGeneration = 0;

  List<MediaItem> get _onDeck => _discover.onDeck;
  List<MediaHub> get _hubs => _discover.hubs;
  bool get _hasMoreContinueWatching => _discover.hasMoreContinueWatching;
  bool get _isLoading => _discover.isLoading;
  bool get _areHubsLoading => _discover.areHubsLoading;
  String? get _errorMessage {
    final raw = _discover.errorMessage;
    return raw == null ? null : t.errors.failedToLoad(context: t.discover.title, error: raw);
  }

  bool _switchingProfile = false;
  final PageController _heroController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentHeroIndex = 0;
  Timer? _autoScrollTimer;
  Timer? _indicatorTimer;
  final ValueNotifier<double> _indicatorProgress = ValueNotifier(0.0);
  bool _isAutoScrollPaused = false;
  bool _heroFocusPausedAutoScroll = false;
  // ValueNotifier (not setState) so a spotlight swap rebuilds only the
  // TvSpotlightBackground subtree, never the rail/rows.
  final ValueNotifier<MediaItem?> _spotlightItem = ValueNotifier(null);
  // Settle delay so d-pad scrubbing across a row doesn't fetch/decode a
  // full-screen backdrop for every intermediate item.
  final Debouncer _spotlightDebouncer = Debouncer(const Duration(milliseconds: 150));
  bool _isTabVisible = true;

  // Track initial load so we can focus hero when content first appears
  bool _initialLoadComplete = false;
  bool _pendingTvBrowseRailFocus = false;

  // Hub navigation keys
  GlobalKey<HubSectionState>? _continueWatchingHubKey;
  final Map<String, GlobalKey<HubSectionState>> _hubKeysByIdentity = {};
  List<GlobalKey<HubSectionState>> _orderedHubKeys = const [];
  final _tvBrowseRailKey = GlobalKey<TvBrowseRailState>();

  // Hero and app bar focus
  late FocusNode _heroFocusNode;
  final _actionBarKey = GlobalKey<FocusableActionBarState>();
  final _serverActivitiesButtonKey = GlobalKey<ServerActivitiesButtonState>();
  final _userMenuKey = GlobalKey<AppMenuButtonState<String>>();

  /// Backend-neutral hero client lookup. Returns the actual
  /// [MediaServerClient] for the item's server (Plex or Jellyfin) so
  /// [MediaImageHelper] uses the right transcoder for sized URLs.
  MediaServerClient? _getMediaClientForItem(MediaItem? item) {
    final serverId = item?.serverId;
    if (serverId == null) {
      return context.tryGetMediaClientForServer(null);
    }
    return context.tryGetMediaClientForServer(ServerId(serverId));
  }

  String _hubIdentity(MediaHub hub) => '${hub.serverId ?? ''}:${hub.identifier ?? hub.id}';

  /// Rebuild the per-hub focus keys, keyed by hub *identity* rather than
  /// list position so a row's focus memory follows it when the provider
  /// re-sorts hubs (library-order change). Existing keys are reused to avoid
  /// mass deep unmounts (ARM32 stack overflow during finalizeTree);
  /// duplicate identities get positional suffixes so two rows can never
  /// share a GlobalKey.
  void _updateHubKeys() {
    final occurrences = <String, int>{};
    final liveIdentities = <String>{};
    final ordered = <GlobalKey<HubSectionState>>[];
    for (final hub in _hubs) {
      var identity = _hubIdentity(hub);
      final occurrence = occurrences.update(identity, (n) => n + 1, ifAbsent: () => 0);
      if (occurrence > 0) identity = '$identity#$occurrence';
      liveIdentities.add(identity);
      ordered.add(_hubKeysByIdentity.putIfAbsent(identity, GlobalKey<HubSectionState>.new));
    }
    _hubKeysByIdentity.removeWhere((identity, _) => !liveIdentities.contains(identity));
    _orderedHubKeys = ordered;
    _continueWatchingHubKey ??= GlobalKey<HubSectionState>();
  }

  /// Get all hub states (continue watching + other hubs)
  List<GlobalKey<HubSectionState>> get _allHubKeys {
    final keys = <GlobalKey<HubSectionState>>[];
    if (_continueWatchingHubKey != null && _onDeck.isNotEmpty) {
      keys.add(_continueWatchingHubKey!);
    }
    keys.addAll(_orderedHubKeys);
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
    final current = _spotlightItem.value;
    if (current == null) return _defaultSpotlightItem;
    if (_onDeck.any((item) => item.globalKey == current.globalKey)) return current;
    for (final hub in _hubs) {
      if (hub.items.any((item) => item.globalKey == current.globalKey)) return current;
    }
    return _defaultSpotlightItem;
  }

  void _setSpotlightItem(MediaItem item) {
    // Same-key check lives inside the callback: an A→B→A scrub must cancel
    // the pending B, not early-return and let it fire.
    _spotlightDebouncer.run(() {
      if (!mounted) return;
      if (_spotlightItem.value?.globalKey == item.globalKey) return;
      _spotlightItem.value = item;
    });
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
      _focusTvBrowseRailWhenReady(immediate: true);
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

  void _focusTvBrowseRailWhenReady({bool immediate = false}) {
    if (!PlatformDetector.isTV()) return;
    final suppressSelectUntilKeyUp = _isSelectKeyPressed;
    if (!_isTabVisible || !(ModalRoute.of(context)?.isCurrent ?? false)) {
      _pendingTvBrowseRailFocus = false;
      return;
    }

    _pendingTvBrowseRailFocus = true;
    if (immediate && _tvBrowseHubs.isNotEmpty) {
      final rail = _tvBrowseRailKey.currentState;
      if (rail != null) {
        _pendingTvBrowseRailFocus = false;
        rail.requestFocus();
        if (suppressSelectUntilKeyUp) rail.suppressSelectUntilKeyUp();
        return;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_isTabVisible || !(ModalRoute.of(context)?.isCurrent ?? false)) {
        _pendingTvBrowseRailFocus = false;
        return;
      }
      if (_tvBrowseHubs.isEmpty) return;
      final rail = _tvBrowseRailKey.currentState;
      if (rail == null) return;
      _pendingTvBrowseRailFocus = false;
      rail.requestFocus();
      if (suppressSelectUntilKeyUp) rail.suppressSelectUntilKeyUp();
    });
  }

  bool get _isSelectKeyPressed {
    return HardwareKeyboard.instance.logicalKeysPressed.any(
      (key) =>
          key == LogicalKeyboardKey.enter ||
          key.keyId == 0x0d ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.gameButtonA,
    );
  }

  void _applyPendingTvBrowseRailFocus() {
    if (_pendingTvBrowseRailFocus) _focusTvBrowseRailWhenReady();
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
    MainScreenFocusScope.of(context, listen: false)?.focusSidebar();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _heroFocusNode = FocusNode(debugLabel: 'hero_section');
    _heroFocusNode.addListener(_onHeroFocusChanged);
    _discover = context.read<DiscoverProvider>();
    _seenLoadGeneration = _discover.loadGeneration;
    _discover.addListener(_onDiscoverChanged);
    _updateHubKeys();
    unawaited(_discover.load());
    _startAutoScroll();
  }

  /// Mirror provider changes into this state's UI concerns: rebuild, apply
  /// pending TV-rail focus, and keep the hero carousel index in sync — a
  /// fresh [DiscoverProvider.load] resets it, a background Continue Watching
  /// refresh only clamps it.
  void _onDiscoverChanged() {
    if (!mounted) return;
    final generation = _discover.loadGeneration;
    final isNewLoad = generation != _seenLoadGeneration;
    _seenLoadGeneration = generation;
    final heroOutOfBounds = _currentHeroIndex >= _onDeck.length;

    setState(() {
      if (isNewLoad || heroOutOfBounds) {
        _currentHeroIndex = 0;
      }
      _updateHubKeys();
    });
    _applyPendingTvBrowseRailFocus();

    if ((isNewLoad || heroOutOfBounds) && _heroController.hasClients && _onDeck.isNotEmpty) {
      _heroController.jumpToPage(0);
    }
    // Focus hero when fresh content lands, but only if no modal route is on top
    if (isNewLoad && !PlatformDetector.isTV() && _onDeck.isNotEmpty && (ModalRoute.of(context)?.isCurrent ?? false)) {
      _heroFocusNode.requestFocus();
    }

    // On initial load, focus content so the user doesn't start on the toolbar
    if (!_initialLoadComplete) {
      if (PlatformDetector.isTV() && (_onDeck.isNotEmpty || _hubs.isNotEmpty)) {
        _initialLoadComplete = true;
        _focusTvBrowseRailWhenReady();
      } else if (!PlatformDetector.isTV() && _onDeck.isNotEmpty) {
        _initialLoadComplete = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
          if (_heroFocusNode.canRequestFocus) {
            _heroFocusNode.requestFocus();
          }
        });
      }
    }
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
          navigateToMediaItem(context, _onDeck[_currentHeroIndex], playDirectly: true);
        }
      },
    )(node, event);
  }

  @override
  void dispose() {
    _discover.removeListener(_onDiscoverChanged);
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _indicatorTimer?.cancel();
    _spotlightDebouncer.dispose();
    _spotlightItem.dispose();
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
        unawaited(_discover.refreshContinueWatching());
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
    _pendingTvBrowseRailFocus = false;
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
    if (PlatformDetector.isTV()) {
      _focusTvBrowseRailWhenReady();
      return;
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

  // Public method to refresh content (for normal navigation)
  @override
  void refresh() {
    // Only refresh Continue Watching in background, not full screen reload
    unawaited(_discover.refreshContinueWatching());
  }

  // Public method to fully reload all content (for profile switches)
  @override
  void fullRefresh() {
    unawaited(_discover.load());
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
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (context) => const ProfileSwitchScreen()));
  }

  void _handleOpenSettings(BuildContext context) {
    final mainScope = MainScreenFocusScope.of(context, listen: false);
    if (mainScope != null) {
      mainScope.openSettings?.call();
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  /// Build the [FocusableAction] wrapping the user menu.
  /// Pulls live state from [ActiveProfileProvider]; the menu reuses
  /// [_userMenuItems] for the menu contents so d-pad and tap paths
  /// stay in sync.
  FocusableAction _buildUserMenuAction(BuildContext context) {
    final activeProvider = context.watch<ActiveProfileProvider>();
    final active = activeProvider.active;
    final profiles = activeProvider.profiles;

    return FocusableAction(
      onPressed: _switchingProfile ? null : () => _userMenuKey.currentState?.showButtonMenu(focusFirstItem: true),
      child: AppMenuButton<String>(
        key: _userMenuKey,
        enabled: !_switchingProfile,
        icon: active != null
            ? ProfileAvatar(profile: active, size: 32)
            : const AppIcon(Symbols.account_circle_rounded, fill: 1, size: 32, color: Colors.white),
        tooltip: t.profiles.sectionTitle,
        anchorAlignment: AppMenuAnchorAlignment.end,
        onSelected: (value) => unawaited(_handleUserMenuAction(context, value)),
        entriesBuilder: (context) => _userMenuItems(context, activeProfile: active, profiles: profiles),
      ),
    );
  }

  List<AppMenuEntry<String>> _userMenuItems(
    BuildContext context, {
    required Profile? activeProfile,
    required List<Profile> profiles,
  }) {
    final theme = Theme.of(context);
    final switchable = profiles.where((p) => p.id != activeProfile?.id).toList();

    return [
      for (final p in switchable)
        AppMenuItem<String>(
          value: 'profile:${p.id}',
          leading: ProfileAvatar(profile: p, size: 24),
          label: p.displayName,
          trailing: p.isPinProtected
              ? AppIcon(Symbols.lock_rounded, fill: 1, size: 14, color: theme.colorScheme.onSurfaceVariant)
              : null,
        ),
      if (switchable.isNotEmpty) const AppMenuDivider(),
      AppMenuItem<String>(value: 'manage_profiles', icon: Symbols.group_rounded, label: t.profiles.sectionTitle),
      AppMenuItem<String>(value: 'settings', icon: Symbols.settings_rounded, label: t.common.settings),
      AppMenuItem<String>(value: 'logout', icon: Symbols.logout_rounded, label: t.common.logout),
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
    if (value == 'settings') {
      _handleOpenSettings(context);
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

  Widget _buildOverlaidAppBar() {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final colorScheme = Theme.of(context).colorScheme;
    final overlayColor = colorScheme.brightness == Brightness.dark ? Colors.black : colorScheme.surface;
    final foregroundColor = colorScheme.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            overlayColor.withValues(alpha: 0.7),
            overlayColor.withValues(alpha: 0.5),
            overlayColor.withValues(alpha: 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: Padding(
        padding: .only(top: statusBarHeight, left: 16, right: 16, bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              if (!PlatformDetector.isTV())
                Text(
                  t.discover.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: foregroundColor, fontWeight: .bold),
                ),
              const Spacer(),
              Consumer2<WatchTogetherProvider, CompanionRemoteProvider>(
                builder: (context, watchTogether, companionRemote, _) {
                  final isDesktop = PlatformDetector.shouldActAsRemoteHost(context);

                  return FocusableActionBar(
                    key: _actionBarKey,
                    onNavigateLeft: _navigateToSidebar,
                    onNavigateDown: _focusContentFromAppBar,
                    actions: [
                      FocusableAction(
                        icon: Symbols.refresh_rounded,
                        iconColor: foregroundColor,
                        onPressed: _discover.load,
                      ),
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
                                color: watchTogether.isInSession ? colorScheme.primary : foregroundColor,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const WatchTogetherScreen()),
                              ),
                              tooltip: t.watchTogether.title,
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
                                    style: TextStyle(color: colorScheme.onPrimary, fontSize: 10, fontWeight: .bold),
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
                                color: companionRemote.isConnected ? colorScheme.primary : foregroundColor,
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
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.fromBorderSide(BorderSide(color: foregroundColor, width: 1)),
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
                        FocusableAction(
                          onPressed: () => _serverActivitiesButtonKey.currentState?.togglePanel(),
                          child: ServerActivitiesButton(key: _serverActivitiesButtonKey),
                        ),
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
    final svc = SettingsService.instance;
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
              if (_errorMessage != null) SliverErrorState(message: _errorMessage!, onRetry: _discover.load),
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
                      onRefresh: _discover.updateItem,
                      onRemoveFromContinueWatching: _discover.refreshContinueWatching,
                      isInContinueWatching: true,
                      loadMoreItems: _discover.loadAllContinueWatching,
                      onVerticalNavigation: (isUp) => _handleVerticalNavigation(0, isUp),
                      onNavigateUp: _focusTopBoundary,
                      onNavigateToSidebar: _navigateToSidebar,
                    ),
                  ),

                // Recommendation Hubs (Trending, Top in Genre, etc.)
                for (int i = 0; i < _hubs.length; i++)
                  SliverToBoxAdapter(
                    child: HubSection(
                      key: i < _orderedHubKeys.length ? _orderedHubKeys[i] : null,
                      hub: _hubs[i],
                      icon: _getHubIcon(_hubs[i].title),
                      showServerName: showServerNameOnHubs || duplicateHubTitles.contains(_hubs[i].title),
                      onRefresh: _discover.updateItem,
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
                          crossAxisAlignment: .start,
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
                        mainAxisAlignment: .center,
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
    final svc = SettingsService.instance;
    final hideSpoilers = svc.read(SettingsService.hideSpoilers);
    final browseHubs = _tvBrowseHubs;
    final scale = TvLayoutConstants.scaleForSize(size);
    // Only layout-aspect (flip-stable) scope values may be read here: an
    // offset-aspect read at this level would rebuild the whole screen on
    // every sidebar focus flip. Offset values are read in small Builders
    // around the widgets that position against them.
    final railSize = MainScreenFocusScope.foregroundSizeOf(context);
    final fullBleedWidth = MainScreenFocusScope.fullBleedWidthOf(context);
    final railHeight = browseHubs.isEmpty
        ? 0.0
        : TvBrowseRailLayout.estimateHeight(
            size: railSize,
            hubs: browseHubs,
            density: svc.read(SettingsService.libraryDensity),
            episodePosterMode: svc.read(SettingsService.episodePosterMode),
            fullCardLayout: svc.read(SettingsService.tvFullCardLayout),
            tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
          );
    final spotlightTop = (size.height * 0.075).clamp(64.0 * scale, 120.0 * scale).toDouble();
    final minimumSpotlightBottom = railHeight + (8 * scale);
    final baseSpotlightBottom = (size.height * 0.48).clamp(160.0, 820.0).toDouble();
    final desiredSpotlightBottom = minimumSpotlightBottom > baseSpotlightBottom
        ? minimumSpotlightBottom
        : baseSpotlightBottom;
    final maxSpotlightBottom = (size.height - spotlightTop - (96 * scale)).clamp(0.0, double.infinity).toDouble();
    final spotlightBottom = desiredSpotlightBottom > maxSpotlightBottom ? maxSpotlightBottom : desiredSpotlightBottom;
    final spotlightLeft = (24 * scale).clamp(18.0, 40.0).toDouble();

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The animated -bleed mirrors the content-slide tween in MainScreen,
          // keeping the full-bleed background viewport-pinned while the
          // content box slides during sidebar expansion. The Builder scopes
          // the offset-aspect dependency to just this subtree.
          Builder(
            builder: (context) {
              final foregroundLeft = MainScreenFocusScope.foregroundLeftOf(context);
              return SideNavigationBleedBuilder(
                targetBleed: foregroundLeft,
                child: ValueListenableBuilder<MediaItem?>(
                  valueListenable: _spotlightItem,
                  builder: (context, _, _) {
                    final spotlight = _effectiveSpotlightItem;
                    return TvSpotlightBackground(
                      item: spotlight,
                      client: _getMediaClientForItem(spotlight),
                      hideSpoilers: hideSpoilers,
                      contentTop: spotlightTop,
                      contentBottom: spotlightBottom,
                      contentLeft: spotlightLeft + foregroundLeft,
                      compact: true,
                      showPrimaryAction: false,
                    );
                  },
                ),
                builder: (context, animatedBleed, child) =>
                    Positioned(top: 0, bottom: 0, left: -animatedBleed, width: fullBleedWidth, child: child!),
              );
            },
          ),
          if (_isLoading || (_areHubsLoading && browseHubs.isEmpty)) const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisSize: .min,
                children: [
                  const AppIcon(Symbols.error_outline_rounded, fill: 1, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _discover.load, child: Text(t.common.retry)),
                ],
              ),
            ),
          if (!_isLoading && _errorMessage == null && browseHubs.isEmpty && !_areHubsLoading)
            Center(
              child: Column(
                mainAxisAlignment: .center,
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
                onRefresh: _discover.updateItem,
                onRemoveFromContinueWatching: _discover.refreshContinueWatching,
                isContinueWatchingHub: (hub) => hub.isContinueWatchingHub,
                usesContinueWatchingAction: (hub) => hub.usesContinueWatchingAction,
                loadMoreItems: (hub) =>
                    hub.id == 'continue_watching' ? _discover.loadAllContinueWatching() : Future.value(hub.items),
                onNavigateUp: _focusTopActions,
                onNavigateToSidebar: _navigateToSidebar,
                tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
                selectSuppressionGestureSignal: PlatformDetector.isAppleTV()
                    ? AppleTvRemoteTouchService.instance.touchActiveListenable
                    : null,
              ),
            ),
          Builder(
            builder: (context) => SideNavigationBleedBuilder(
              targetBleed: MainScreenFocusScope.sideNavigationBleedOf(context),
              child: ExcludeFocusTraversal(child: _buildOverlaidAppBar()),
              builder: (context, animatedBleed, child) =>
                  Positioned(top: 0, left: -animatedBleed, width: fullBleedWidth, child: child!),
            ),
          ),
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
                    mainAxisAlignment: .center,
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
                                        alignment: .centerLeft,
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
    final heroLogoWidth = isTv ? TvLayoutConstants.heroLogoWidth : 400.0;
    final heroLogoHeight = isTv ? TvLayoutConstants.heroLogoHeight : 120.0;
    final heroTitleStyle = theme.textTheme.displaySmall?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: .bold,
      fontSize: isTv ? 52 : null,
      shadows: [Shadow(color: colorScheme.surface.withValues(alpha: 0.8), blurRadius: 8)],
    );

    // Determine content type label for chip
    final contentTypeLabel = heroItem.isMovie ? t.discover.movie : t.discover.tvShow;

    // Spoiler protection
    final hideSpoilers = SettingsService.instance.read(SettingsService.hideSpoilers);
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
            appLogger.d('Activating hero item: ${heroItem.title}');
            navigateToMediaItem(context, heroItem, playDirectly: true);
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
                  padding: .symmetric(
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
                        mainAxisSize: .min,
                        children: [
                          // Show logo or name/title
                          if (heroItem.clearLogoPath != null)
                            SizedBox(
                              height: heroLogoHeight,
                              width: heroLogoWidth,
                              child: Builder(
                                builder: (context) {
                                  final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
                                  final logoUrl = MediaImageHelper.getOptimizedImageUrl(
                                    client: heroClient,
                                    thumbPath: heroItem.clearLogoPath,
                                    maxWidth: heroLogoWidth,
                                    maxHeight: heroLogoHeight,
                                    devicePixelRatio: dpr,
                                    imageType: ImageType.logo,
                                  );

                                  return blurArtwork(
                                    CachedNetworkImage(
                                      imageUrl: logoUrl,
                                      cacheManager: PlexImageCacheManager.instance,
                                      filterQuality: FilterQuality.medium,
                                      fit: BoxFit.contain,
                                      memCacheWidth: (heroLogoWidth * dpr).clamp(200, isTv ? 1000 : 800).round(),
                                      alignment: alignLeft ? Alignment.bottomLeft : Alignment.bottomCenter,
                                      placeholder: (context, url) => const SizedBox.shrink(),
                                      errorBuilder: (context, error, stackTrace) {
                                        // Fallback to text if logo fails to load
                                        return FittingTitleText(
                                          showName,
                                          style: heroTitleStyle,
                                          textAlign: alignLeft ? TextAlign.left : TextAlign.center,
                                          alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
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
                            SizedBox(
                              height: heroLogoHeight,
                              width: heroLogoWidth,
                              child: FittingTitleText(
                                showName,
                                style: heroTitleStyle,
                                textAlign: alignLeft ? TextAlign.left : TextAlign.center,
                                alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
                              ),
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
                                color: colorScheme.onSurface,
                                fontSize: isTv ? 18 : 14,
                                fontWeight: .w600,
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
                              overflow: .ellipsis,
                              textAlign: alignLeft ? TextAlign.left : TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                  fontSize: isTv ? 18 : 14,
                                  height: isTv ? 1.45 : 1.4,
                                ),
                                children: [
                                  if (isEpisode && heroItem.parentIndex != null && heroItem.index != null)
                                    TextSpan(
                                      text: 'S${heroItem.parentIndex}, E${heroItem.index}: ',
                                      style: TextStyle(fontWeight: .bold, color: colorScheme.onSurface),
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
                              overflow: .ellipsis,
                              textAlign: alignLeft ? TextAlign.left : TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
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

  Widget _buildSmartPlayButton(MediaItem rawHeroItem) {
    return Builder(
      builder: (context) {
        // The on-deck snapshot refetches shortly after a watch event; the store
        // patch bridges the gap so "minutes left" never lags.
        final heroItem = context.withFreshWatchState(rawHeroItem);
        final hasProgress = heroItem.hasActiveProgress;
        final isTv = PlatformDetector.isTV();

        final minutesLeft = hasProgress ? ((heroItem.durationMs! - heroItem.viewOffsetMs!) / 60_000).round() : 0;

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
                padding: .symmetric(horizontal: isTv ? 34 : 24, vertical: isTv ? 16 : 12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(isTv ? 32 : 24)),
                  boxShadow: showFocus
                      ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.35), blurRadius: 28, spreadRadius: 4)]
                      : null,
                ),
                child: Row(
                  mainAxisSize: .min,
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
                          alignment: .centerLeft,
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
      },
    );
  }
}
