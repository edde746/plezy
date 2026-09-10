import 'dart:async';
import '../media/ids.dart';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import '../widgets/server_activities_button.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/focusable_action_bar.dart';
import '../focus/hub_vertical_navigation.dart';
import '../focus/locked_hub_controller.dart';

import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../media/media_hub.dart';
import '../utils/media_image_helper.dart';
import '../widgets/toolbar_scrim.dart';
import '../widgets/system_clock.dart';
import '../providers/discover_provider.dart';
import '../providers/multi_server_provider.dart';
import '../widgets/hub_section.dart';
import '../widgets/hero_hub_section.dart';
import '../widgets/app_menu.dart';
import '../widgets/loading_indicator_box.dart';
import '../widgets/profile_switching_overlay.dart';
import 'profile/profile_switch_screen.dart';
import 'profile/profile_teardown.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/profile.dart';
import '../profiles/profile_activation.dart';
import '../profiles/profile_avatar.dart';
import '../services/settings_service.dart';
import '../widgets/settings_builder.dart';
import '../widgets/tv_browse_rail.dart';
import '../widgets/tv_spotlight_scaffold.dart';
import '../mixins/refreshable.dart';
import '../mixins/tab_visibility_aware.dart';
import '../i18n/strings.g.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/hub_icons.dart';
import '../utils/provider_extensions.dart';
import '../utils/snackbar_helper.dart';
import '../utils/platform_detector.dart';
import '../theme/mono_tokens.dart';
import 'libraries/content_state_builder.dart';
import 'libraries/state_messages.dart';
import 'main_screen.dart';
import '../navigation/settings_shortcut.dart';
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
  String? get _errorMessage => _discover.errorMessage == null ? null : t.errors.unableToLoad(context: t.discover.title);

  bool _switchingProfile = false;
  final PageController _heroController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentHeroIndex = 0;
  final ValueNotifier<int> _heroIndex = ValueNotifier<int>(0);
  Timer? _autoScrollTimer;
  Timer? _indicatorTimer;
  final ValueNotifier<double> _indicatorProgress = ValueNotifier(0.0);
  bool _isAutoScrollPaused = false;
  bool _heroFocusPausedAutoScroll = false;
  final TvSpotlightController _spotlight = TvSpotlightController();
  bool _isTabVisible = true;

  bool _initialLoadComplete = false;
  bool _pendingTvBrowseRailFocus = false;

  final Map<String, GlobalKey<HubSectionState>> _hubKeysByIdentity = {};
  List<GlobalKey<HubSectionState>> _orderedHubKeys = const [];
  final _tvBrowseRailKey = GlobalKey<TvBrowseRailState>();
  final _hubFocusMemory = HubFocusMemory();

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
  }

  // Continue Watching is a normal, removable/reorderable Organizer row now
  // (see home_layout_settings_screen.dart) folded into `_hubs` at its real
  // position by buildConfiguredHomeSections, rather than a screen-level
  // fixture — so `_orderedHubKeys` already covers it and needs no special
  // prepending here. This getter still gates the legacy top hero banner
  // below, which remains Continue-Watching-only until per-row hero
  // rendering replaces it.
  bool get _continueWatchingEnabled => context.settingsRead(SettingsService.continueWatchingOnHome);

  List<GlobalKey<HubSectionState>> get _allHubKeys => _orderedHubKeys;

  bool get _isHeroSectionVisible =>
      _onDeck.isNotEmpty && _continueWatchingEnabled && context.settingsRead(SettingsService.showHeroSection);

  // Memoized on provider list identity (the provider always replaces _onDeck/
  // _hubs with fresh instances on change, never mutates in place) so unrelated
  // rebuilds hand TvBrowseRail the same hubs list and its didUpdateWidget
  // fast path — and the cached rail widget below — kick in. Continue
  // Watching arrives already folded into `_hubs` (see DiscoverProvider), so
  // this no longer needs to prepend it separately.
  List<MediaHub>? _tvBrowseHubsCache;
  List<MediaHub>? _tvBrowseHubsCacheKey;

  List<MediaHub> get _tvBrowseHubs {
    if (_tvBrowseHubsCache != null && _hubs == _tvBrowseHubsCacheKey) return _tvBrowseHubsCache!;
    final hubs = _hubs.where((hub) => hub.items.isNotEmpty).toList();
    _tvBrowseHubsCache = hubs;
    _tvBrowseHubsCacheKey = _hubs;
    return hubs;
  }

  void _setSpotlightItem(MediaItem item) => _spotlight.select(item);

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
    });
  }

  void _applyPendingTvBrowseRailFocus() {
    if (_pendingTvBrowseRailFocus) _focusTvBrowseRailWhenReady();
  }

  /// Handle vertical navigation between hubs
  /// Returns true if the navigation was handled
  bool _handleVerticalNavigation(int hubIndex, bool isUp) {
    final keys = _allHubKeys;
    return navigateVerticalHubRows(
      hubCount: keys.length,
      hubIndex: hubIndex,
      isUp: isUp,
      onTopBoundary: _focusTopBoundary,
      requestFocus: (targetIndex) {
        keys[targetIndex].currentState?.requestFocusFromMemory();
      },
    );
  }

  /// Navigate focus to the sidebar
  void _navigateToSidebar() {
    MainScreenFocusScope.focusSidebarOf(context);
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
  /// Everything the build reads from the provider (list identities — the
  /// provider replaces lists on change — plus the scalar flags). Notifies
  /// that leave this unchanged (e.g. a watch-state-driven Continue Watching
  /// refresh that found nothing new) skip the setState so the whole screen —
  /// TV rail included — is not rebuilt for nothing.
  (List<MediaItem>, List<MediaHub>, bool, bool, bool, String?) get _renderSignature =>
      (_onDeck, _hubs, _hasMoreContinueWatching, _isLoading, _areHubsLoading, _discover.errorMessage);

  (List<MediaItem>, List<MediaHub>, bool, bool, bool, String?)? _seenRenderSignature;

  void _onDiscoverChanged() {
    if (!mounted) return;
    final generation = _discover.loadGeneration;
    final isNewLoad = generation != _seenLoadGeneration;
    _seenLoadGeneration = generation;
    final heroOutOfBounds = _currentHeroIndex >= _onDeck.length;
    final signature = _renderSignature;
    final renderChanged = isNewLoad || heroOutOfBounds || signature != _seenRenderSignature;
    _seenRenderSignature = signature;

    if (renderChanged) {
      setState(() {
        if (isNewLoad || heroOutOfBounds) {
          _currentHeroIndex = 0;
          _heroIndex.value = 0;
        }
        _updateHubKeys();
      });
    }
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

  @override
  void dispose() {
    _discover.removeListener(_onDiscoverChanged);
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _indicatorTimer?.cancel();
    _spotlight.dispose();
    _indicatorProgress.dispose();
    _heroIndex.dispose();
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
        _heroIndex.value = 0;
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

  @override
  void primeRefresh() {
    // `initState` already fired `load()`. On cold start that pass is still
    // running when the online-entry hook primes the tab, and asking again only
    // queues an identical trailing pass — the whole home fan-out twice (#1784).
    // When nothing is in flight (reconnect-from-offline, or a first pass that
    // gave up because no server was online yet) a real refresh is still owed.
    if (_discover.isLoadInFlight) return;
    fullRefresh();
  }

  /// Whether the loaded hubs span more than one connected server.
  bool _hubsSpanMultipleServers() {
    final serverIds = _hubs.where((hub) => hub.serverId != null).map((hub) => hub.serverId).toSet();
    return serverIds.length > 1;
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
      await logoutAllProfiles(context);
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

    Navigator.push(context, buildSettingsRoute());
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
            ? ProfileAvatar(profile: active, size: 32, avatarUrl: activeProvider.avatarUrlFor(active.id))
            : const AppIcon(Symbols.account_circle_rounded, fill: 1, size: 32, color: Colors.white),
        tooltip: t.profiles.sectionTitle,
        adaptiveSheet: true,
        anchorAlignment: AppMenuAnchorAlignment.end,
        onSelected: (value) => unawaited(_handleUserMenuAction(context, value)),
        entriesBuilder: (context) =>
            _userMenuItems(context, activeProfile: active, profiles: profiles, activeProvider: activeProvider),
      ),
    );
  }

  List<AppMenuEntry<String>> _userMenuItems(
    BuildContext context, {
    required Profile? activeProfile,
    required List<Profile> profiles,
    required ActiveProfileProvider activeProvider,
  }) {
    final theme = Theme.of(context);
    final switchable = profiles.where((p) => p.id != activeProfile?.id).toList();

    return [
      for (final p in switchable)
        AppMenuItem<String>(
          value: 'profile:${p.id}',
          leading: ProfileAvatar(profile: p, size: 24, avatarUrl: activeProvider.avatarUrlFor(p.id)),
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
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = colorScheme.onSurface;
    return ToolbarScrim(
      child: Row(
        children: [
          if (!PlatformDetector.isTV())
            Text(
              t.discover.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: foregroundColor, fontWeight: .bold),
            ),
          const Spacer(),
          // TV only: a fullscreen leanback app hides the system clock, while a
          // phone status bar and a desktop menu bar already show one.
          if (PlatformDetector.isTV()) ...[
            SystemClock(
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: foregroundColor, fontWeight: .w500),
            ),
            const SizedBox(width: 12),
          ],
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
                    onPressed: () async {
                      final outcome = await _discover.refreshNow();
                      if (!context.mounted) return;
                      switch (outcome) {
                        case DiscoverRefreshOutcome.failed:
                          showErrorSnackBar(context, t.errors.unableToLoad(context: t.discover.title));
                        case DiscoverRefreshOutcome.degraded:
                          appLogger.w('Discover refresh completed with partial server failures');
                        case DiscoverRefreshOutcome.cancelled:
                        case DiscoverRefreshOutcome.refreshed:
                          break;
                      }
                    },
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
                          onPressed: () =>
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchTogetherScreen())),
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
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MobileRemoteScreen()));
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsBuilder(
      prefs: const [
        SettingsService.showServerNameOnHubs,
        SettingsService.showHeroSection,
        SettingsService.continueWatchingOnHome,
        SettingsService.hideSpoilers,
        SettingsService.libraryDensity,
        SettingsService.episodePosterMode,
      ],
      builder: (context) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final svc = SettingsService.instance;

    if (PlatformDetector.isTV()) {
      return _buildTvContent(context);
    }

    final showServerNameOnHubs = svc.read(SettingsService.showServerNameOnHubs);
    final hubsSpanMultipleServers = _hubsSpanMultipleServers();

    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Top padding — there is no more fixed screen-level hero slot.
              // Hero rendering is now per-row (see the loop below): whichever
              // row(s) have heroStyle on render as a HeroHubSection wherever
              // home_row_order places them, same as any other row.
              SliverToBoxAdapter(
                child: SizedBox(height: kToolbarHeight + MediaQuery.paddingOf(context).top + 16),
              ),
              if (_isLoading) LoadingIndicatorBox.sliver,
              if (_errorMessage != null) SliverErrorState(message: _errorMessage!, onRetry: _discover.load),
              if (!_isLoading && _errorMessage == null) ...[
                // Home rows — Continue Watching, Plex-managed rows, and custom
                // rows all arrive here pre-ordered by DiscoverProvider (see
                // buildConfiguredHomeSections), so this loop treats every row
                // uniformly rather than special-casing Continue Watching's
                // position or navigation index.
                for (int i = 0; i < _hubs.length; i++)
                  SliverToBoxAdapter(
                    child: _hubs[i].heroStyle && _hubs[i].items.isNotEmpty
                        ? HeroHubSection(
                            key: ValueKey('hero:${_hubIdentity(_hubs[i])}'),
                            hub: _hubs[i],
                            onVerticalNavigation: (isUp) => _handleVerticalNavigation(i, isUp),
                            onNavigateUp: i == 0 ? _focusTopBoundary : null,
                            onNavigateToSidebar: _navigateToSidebar,
                          )
                        : HubSection(
                      key: i < _orderedHubKeys.length ? _orderedHubKeys[i] : null,
                      hub: _hubs[i],
                      focusMemory: _hubFocusMemory,
                      icon: hubIconFor(_hubs[i]),
                      showServerName: showServerNameOnHubs || hubsSpanMultipleServers,
                      onRefresh: _discover.updateItem,
                      onRemoveFromContinueWatching: _hubs[i].isContinueWatchingHub
                          ? _discover.refreshContinueWatching
                          : null,
                      isInContinueWatching: _hubs[i].isContinueWatchingHub,
                      loadMoreItems: _hubs[i].isContinueWatchingHub ? _discover.loadAllContinueWatching : null,
                      onVerticalNavigation: (isUp) => _handleVerticalNavigation(i, isUp),
                      onNavigateUp: i == 0 ? _focusTopBoundary : null,
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
                  SliverEmptyState(
                    message: t.discover.noContentAvailable,
                    subtitle: t.discover.addMediaToLibraries,
                    icon: Symbols.movie_rounded,
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

  // Cached so unrelated _buildTvContent rebuilds (loading flags, spotlight
  // geometry) hand Element.updateChild the identical widget instance and the
  // whole rail subtree is skipped. Rebuilt only when its actual inputs change.
  TvBrowseRail? _tvBrowseRailWidget;
  (List<MediaHub>, bool)? _tvBrowseRailWidgetKey;

  Widget _cachedTvBrowseRail(List<MediaHub> browseHubs, {required bool showServerName}) {
    final key = (browseHubs, showServerName);
    if (_tvBrowseRailWidget != null && key == _tvBrowseRailWidgetKey) return _tvBrowseRailWidget!;
    _tvBrowseRailWidgetKey = key;
    return _tvBrowseRailWidget = TvBrowseRail(
      key: _tvBrowseRailKey,
      hubs: browseHubs,
      initialHubId: 'continue_watching',
      focusMemory: _hubFocusMemory,
      showServerName: showServerName,
      iconForHub: (hub, _) => hubIconFor(hub),
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
    );
  }

  Widget _buildTvContent(BuildContext context) {
    final svc = SettingsService.instance;
    final hideSpoilers = svc.read(SettingsService.hideSpoilers);
    final showServerNameOnHubs = svc.read(SettingsService.showServerNameOnHubs);
    final hubsSpanMultipleServers = _hubsSpanMultipleServers();
    final browseHubs = _tvBrowseHubs;

    return TvSpotlightScaffold(
      hubs: browseHubs,
      spotlightListenable: _spotlight,
      resolveSpotlight: () => _spotlight.resolve(browseHubs),
      resolveClient: _getMediaClientForItem,
      hideSpoilers: hideSpoilers,
      foreground: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          if (_isLoading || (_areHubsLoading && browseHubs.isEmpty)) const Center(child: CircularProgressIndicator()),
          if (_errorMessage != null)
            ErrorStateWidget(
              message: _errorMessage!,
              icon: Symbols.error_outline_rounded,
              onRetry: _discover.load,
              actionAutofocus: true,
              actionUseBackgroundFocus: true,
            ),
          if (!_isLoading && _errorMessage == null && browseHubs.isEmpty && !_areHubsLoading)
            EmptyStateWidget(
              message: t.discover.noContentAvailable,
              subtitle: t.discover.addMediaToLibraries,
              icon: Symbols.movie_rounded,
            ),
          if (browseHubs.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _cachedTvBrowseRail(browseHubs, showServerName: showServerNameOnHubs || hubsSpanMultipleServers),
            ),
          TvToolbarOverlay(child: _buildOverlaidAppBar()),
          if (_switchingProfile) const ProfileSwitchingOverlay(),
        ],
      ),
    );
  }

}
