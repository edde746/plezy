import 'dart:async';
import '../media/ids.dart';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import '../widgets/server_activities_button.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/focusable_action_bar.dart';
import '../focus/hub_vertical_navigation.dart';
import '../focus/locked_hub_controller.dart';
import '../focus/key_event_utils.dart';
import '../focus/back_press.dart';
import '../focus/input_mode_tracker.dart';

import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../media/media_hub.dart';
import '../providers/watch_state_store.dart';
import '../utils/content_utils.dart';
import '../widgets/cycling_media_backdrop.dart';
import '../widgets/hero_carousel_backdrop.dart';
import '../utils/formatters.dart';
import '../utils/layout_constants.dart';
import '../utils/media_image_helper.dart';
import '../utils/video_player_navigation.dart';
import '../widgets/clickable_cursor.dart';
import '../widgets/fitting_title_text.dart';
import '../widgets/optimized_media_image.dart' show ClearLogoImage, blurArtwork;
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
import '../utils/media_navigation_helper.dart';
import '../utils/provider_extensions.dart';
import '../utils/snackbar_helper.dart';
import '../utils/platform_detector.dart';
import '../utils/tone_mapped_logo_image.dart';
import '../theme/mono_tokens.dart';
import 'libraries/content_state_builder.dart';
import 'libraries/state_messages.dart';
import 'main_screen.dart';
import 'discovery/find_next_screen.dart';
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
    with Refreshable, ManualRefreshable, FullRefreshable, TabVisibilityAware, FocusableTab, WidgetsBindingObserver {
  static const Duration _heroAutoScrollDuration = Duration(seconds: 8);
  static const Duration _indicatorUpdateInterval = Duration(milliseconds: 200);
  final _backGate = BackPressGate();

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

  /// Primary focus when the rail claim was armed; see [_railClaimAbandoned].
  FocusNode? _railClaimFocusOrigin;

  final Map<String, GlobalKey<HubSectionState>> _hubKeysByIdentity = {};
  List<GlobalKey<HubSectionState>> _orderedHubKeys = const [];
  // Index-aligned with _hubs/_orderedHubKeys, null for a non-hero row at
  // that position — HeroHubSection needs its own key type
  // (GlobalKey<HeroHubSectionState>, not HubSectionState), so it can't
  // share _orderedHubKeys directly the way the render loop's HubSection
  // branch does.
  final Map<String, GlobalKey<HeroHubSectionState>> _heroHubKeysByIdentity = {};
  List<GlobalKey<HeroHubSectionState>?> _orderedHeroHubKeys = const [];
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
    final orderedHero = <GlobalKey<HeroHubSectionState>?>[];
    for (final hub in _hubs) {
      var identity = _hubIdentity(hub);
      final occurrence = occurrences.update(identity, (n) => n + 1, ifAbsent: () => 0);
      if (occurrence > 0) identity = '$identity#$occurrence';
      liveIdentities.add(identity);
      ordered.add(_hubKeysByIdentity.putIfAbsent(identity, GlobalKey<HubSectionState>.new));
      orderedHero.add(
        hub.heroStyle && hub.items.isNotEmpty
            ? _heroHubKeysByIdentity.putIfAbsent(identity, GlobalKey<HeroHubSectionState>.new)
            : null,
      );
    }
    _hubKeysByIdentity.removeWhere((identity, _) => !liveIdentities.contains(identity));
    _heroHubKeysByIdentity.removeWhere((identity, _) => !liveIdentities.contains(identity));
    _orderedHubKeys = ordered;
    _orderedHeroHubKeys = orderedHero;
  }

  /// Unified focus target for hub index [index] — routes to whichever key
  /// type is actually attached there (HeroHubSectionState for a hero row,
  /// HubSectionState otherwise). Replaces the old screen-level
  /// _heroFocusNode, which pointed at nothing once hero rendering moved
  /// per-row (see _isHeroSectionVisible's own comment).
  void _requestFocusForHubIndex(int index) {
    if (index < 0 || index >= _hubs.length) return;
    final heroKey = index < _orderedHeroHubKeys.length ? _orderedHeroHubKeys[index] : null;
    if (heroKey != null) {
      heroKey.currentState?.requestFocusFromMemory();
      return;
    }
    if (index < _orderedHubKeys.length) {
      _orderedHubKeys[index].currentState?.requestFocusFromMemory();
    }
  }

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

  void _setSpotlightItem(MediaHub hub, MediaItem item) => _spotlight.select(item, hub: hub);

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
    // Always the toolbar/action bar — regardless of platform or whether
    // row 0 happens to be a hero row. The old branch here checked
    // _isHeroSectionVisible and tried to focus _heroFocusNode, a FocusNode
    // never actually attached to anything once hero rendering moved
    // per-row (see _isHeroSectionVisible's own comment) — a silent no-op
    // that just left "up" from row 0 doing nothing.
    _focusTopActions();
    _scrollToTop();
  }

  void _focusContentFromAppBar() {
    if (PlatformDetector.usesTvHomeLayout()) {
      _focusTvBrowseRailWhenReady(immediate: true);
      return;
    }
    if (_hubs.isNotEmpty) {
      _requestFocusForHubIndex(0);
    }
  }

  void _focusTvBrowseRailWhenReady({bool immediate = false}) {
    if (!PlatformDetector.isTV()) return;
    if (!_isTabVisible || !(ModalRoute.of(context)?.isCurrent ?? false)) {
      _pendingTvBrowseRailFocus = false;
      return;
    }

    _pendingTvBrowseRailFocus = true;
    _railClaimFocusOrigin = FocusManager.instance.primaryFocus;
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

  /// A rail-focus request stays armed while the rail has no hubs to focus
  /// (empty first load), so hubs landing later still receive it. It must not
  /// outlive the user's own navigation: hubs arriving minutes later would
  /// yank the remote off a sidebar item the user has since moved to.
  ///
  /// Where focus *sits* cannot tell those apart — MainScreen hands a tab over
  /// while focus is still on the sidebar item that selected it, and that
  /// request is as live as one made from a bare scope. What distinguishes a
  /// stale claim is that focus *moved* after the request was armed and now
  /// rests on a control off this screen. A bare scope — MainScreen's content
  /// scope before any child has focus — is "nowhere yet", not a destination.
  bool get _railClaimAbandoned {
    final node = FocusManager.instance.primaryFocus;
    if (identical(node, _railClaimFocusOrigin)) return false;
    final focusContext = node?.context;
    if (node == null || node is FocusScopeNode || focusContext == null) return false;
    return !identical(focusContext.findAncestorStateOfType<_DiscoverScreenState>(), this);
  }

  void _applyPendingTvBrowseRailFocus() {
    if (!_pendingTvBrowseRailFocus) return;
    if (_railClaimAbandoned) {
      _pendingTvBrowseRailFocus = false;
      return;
    }
    _focusTvBrowseRailWhenReady();
  }

  /// Handle vertical navigation between hubs
  /// Returns true if the navigation was handled
  bool _handleVerticalNavigation(int hubIndex, bool isUp) {
    // Not keys[targetIndex].currentState?.requestFocusFromMemory() directly
    // — keys (_allHubKeys) is typed GlobalKey<HubSectionState>, which is
    // never actually attached at a hero row's position (HeroHubSection
    // needs its own GlobalKey<HeroHubSectionState>; see
    // _requestFocusForHubIndex), so that silently no-op'd landing on one.
    return navigateVerticalHubRows(
      hubCount: _hubs.length,
      hubIndex: hubIndex,
      isUp: isUp,
      onTopBoundary: _focusTopBoundary,
      requestFocus: _requestFocusForHubIndex,
    );
  }

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

  bool _disableAnimations = false;
  bool _accessibleNavigation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    if (_disableAnimations != media.disableAnimations || _accessibleNavigation != media.accessibleNavigation) {
      _disableAnimations = media.disableAnimations;
      _accessibleNavigation = media.accessibleNavigation;
      _startAutoScroll();
    }
  }

  void _pageHero(int delta) {
    if (!_heroController.hasClients) return;
    final target = (_heroIndex.value + delta).clamp(0, _onDeck.length - 1);
    final duration = tokens(context).slow;
    if (_disableAnimations || duration == Duration.zero) {
      _heroController.jumpToPage(target);
    } else {
      _heroController.animateToPage(target, duration: duration, curve: Curves.easeInOut);
    }
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
    final heroOutOfBounds = _heroIndex.value >= _onDeck.length;
    final signature = _renderSignature;
    final renderChanged = isNewLoad || heroOutOfBounds || signature != _seenRenderSignature;
    _seenRenderSignature = signature;

    if (renderChanged) {
      setState(() {
        if (isNewLoad || heroOutOfBounds) _heroIndex.value = 0;
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
        if (PlatformDetector.usesTvHomeLayout()) {
          _focusTvBrowseRailWhenReady();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
            _requestFocusForHubIndex(0);
          });
        }
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
    final backResult = _backGate.handle(event, _navigateToSidebar);
    if (backResult != KeyEventResult.ignored) return backResult;

    return dpadKeyHandler(
      // Routes into a hero row too (its own key type), see _requestFocusForHubIndex.
      onDown: () => _requestFocusForHubIndex(0),
      onUp: _focusTopActions,
      onLeft: () {
        if (_heroIndex.value > 0) {
          _pageHero(-1);
        } else {
          _navigateToSidebar();
        }
      },
      onRight: () {
        if (_heroIndex.value < _onDeck.length - 1) {
          _pageHero(1);
        }
      },
      onSelect: () {
        final heroIndex = _heroIndex.value;
        if (_onDeck.isNotEmpty && heroIndex < _onDeck.length) {
          navigateToMediaItem(context, _onDeck[heroIndex], playDirectly: true);
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
    _spotlight.dispose();
    _indicatorProgress.dispose();
    _heroIndex.dispose();
    _heroController.dispose();
    _scrollController.dispose();
    _heroFocusNode.removeListener(_onHeroFocusChanged);
    _heroFocusNode.dispose();
    // Not disposed here — app-wide singleton, see its field doc comment.
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Restart auto-scroll only if discover tab is visible
      if (_isTabVisible && !_isAutoScrollPaused) _startAutoScroll();
      // Stale hubs refetch on every resume — cheap timestamp check, and a
      // desktop window-focus gain after hours away should refresh too (#1646).
      final startedFullPass = _discover.refreshIfStale();
      // Refresh continue watching on mobile only
      // (on desktop, "resumed" fires on every window focus gain)
      if (!startedFullPass && (Platform.isIOS || Platform.isAndroid)) {
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
    if (_disableAnimations || _accessibleNavigation) {
      _stopIndicatorProgress();
      return;
    }
    if (PlatformDetector.isTV()) return;
    if (_isAutoScrollPaused) return;

    _startIndicatorProgress();
    _autoScrollTimer = Timer.periodic(_heroAutoScrollDuration, (timer) {
      if (_onDeck.isEmpty || !_heroController.hasClients || _isAutoScrollPaused) {
        return;
      }

      // Validate current index is within bounds before calculating next page
      if (_heroIndex.value >= _onDeck.length) _heroIndex.value = 0;

      final nextPage = (_heroIndex.value + 1) % _onDeck.length;
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
    if (!mounted || _disableAnimations || _accessibleNavigation) return;
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

  // --- Legacy single-hero-carousel (restored 2026-09-12 for "reset to
  // default" — see showLegacyHero in _buildContent) ---

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
    _discover.refreshIfStale();
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
    final center = _heroIndex.value;
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

  @override
  void manualRefresh() => unawaited(_refreshFromToolbar());

  Future<void> _refreshFromToolbar() async {
    final outcome = await _discover.refreshNow();
    if (!mounted) return;
    switch (outcome) {
      case DiscoverRefreshOutcome.failed:
        showErrorSnackBar(context, t.errors.unableToLoad(context: t.discover.title));
      case DiscoverRefreshOutcome.degraded:
        appLogger.w('Discover refresh completed with partial server failures');
      case DiscoverRefreshOutcome.cancelled:
      case DiscoverRefreshOutcome.refreshed:
        break;
    }
  }

  // Public method to refresh content (for normal navigation)
  @override
  void refresh() {
    // A stale-resume refresh must also refetch the home hubs; otherwise new
    // server-side media never appears until a restart (#1646). When fresh,
    // only Continue Watching refetches — one on-deck call, zero hub calls.
    if (_discover.refreshIfStale()) return;
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
    // When nothing is in flight (reconnect-from-offline, a first pass that
    // gave up because no server was online yet, or one skipped because the
    // profile was still binding) a real refresh is still owed.
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
              void openWatchTogether() =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchTogetherScreen()));
              void openCompanionRemote() {
                if (isDesktop) {
                  RemoteSessionDialog.show(context);
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MobileRemoteScreen()));
                }
              }

              return FocusableActionBar(
                key: _actionBarKey,
                onNavigateLeft: _navigateToSidebar,
                onNavigateDown: _focusContentFromAppBar,
                actions: [
                  FocusableAction(
                    icon: Symbols.auto_awesome_rounded,
                    iconColor: foregroundColor,
                    tooltip: t.discover.findNext.open,
                    onPressed: () => Navigator.of(
                      context,
                    ).push<void>(MaterialPageRoute<void>(builder: (_) => const FindNextScreen())),
                  ),
                  FocusableAction(icon: Symbols.refresh_rounded, iconColor: foregroundColor, onPressed: manualRefresh),
                  // Watch Together
                  FocusableAction(
                    onPressed: openWatchTogether,
                    child: Stack(
                      children: [
                        IconButton(
                          icon: AppIcon(
                            Symbols.group_rounded,
                            fill: watchTogether.isInSession ? 1 : 0,
                            color: watchTogether.isInSession ? colorScheme.primary : foregroundColor,
                          ),
                          onPressed: openWatchTogether,
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
                    onPressed: openCompanionRemote,
                    child: Stack(
                      children: [
                        IconButton(
                          icon: AppIcon(
                            Symbols.phone_android_rounded,
                            fill: companionRemote.isConnected ? 1 : 0,
                            color: companionRemote.isConnected ? colorScheme.primary : foregroundColor,
                          ),
                          onPressed: openCompanionRemote,
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
        SettingsService.showHomeBackdrop,
        SettingsService.continueWatchingOnHome,
        SettingsService.hideSpoilers,
        SettingsService.libraryDensity,
        SettingsService.episodePosterMode,
      ],
      builder: (context) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // TV uses stock Plezy's spotlight layout again (2026-10-11 user request:
    // match the native app — the highlighted card's art fills the background
    // behind plain rows). Hero rows live inside that same layout: the rail
    // collapses them to their header and TvSpotlightScaffold renders the
    // focused hero row as a banner (title, chevrons, d-pad paging).
    if (PlatformDetector.usesTvHomeLayout()) return _buildTvContent(context);

    final svc = SettingsService.instance;

    // TV used to build a completely separate screen here (TvBrowseRail +
    // TvSpotlightScaffold) — per user request 2026-09-10 ("make it look
    // like the browser version, just with a remote instead of a mouse"),
    // it now runs through the exact same per-row loop PC does. HubSection
    // and HeroHubSection both already branch on PlatformDetector.isTV()
    // internally for their own sizing/styling, and HubSection's TV
    // key-handling is already proven elsewhere (media_detail_screen.dart,
    // catalog_item_detail_screen.dart use it on TV today) — HeroHubSection
    // just gained the same real d-pad handling this same session. The old
    // TV-only path (_buildTvContent and everything it alone used) is left
    // in place below, unused, rather than torn out in the same pass as
    // this switch.

    final showServerNameOnHubs = svc.read(SettingsService.showServerNameOnHubs);
    final hubsSpanMultipleServers = _hubsSpanMultipleServers();

    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final theme = Theme.of(context);
    // Same base value PC always used (kToolbarHeight + status bar + 16px),
    // plus real extra headroom on TV specifically. That base was cutting it
    // close enough already that a hero row could render with its own top
    // edge nearly flush against the toolbar — on TV, where the toolbar also
    // carries the clock, invisible by a few px is enough to clip baked-in
    // title text right at a row's own top edge (2026-09-11 bug report:
    // "Future Man" only ever showing "Man", unmoved by two separate fixes
    // to how the backdrop image itself was cropped — the image was never
    // the problem, the row's on-screen position was).
    final isTv = PlatformDetector.isTV();
    // The +56 TV bonus here used to compensate for a since-fixed bug (the
    // hero row's own Scrollable.ensureVisible was double-reserving toolbar
    // clearance on top of this boundary — see HeroHubSection._scrollIntoView).
    // With that fixed, the extra 56 is just excess gap between the toolbar
    // and the row (2026-09-11 report: "sits too low, about an inch, needs to
    // touch the header without overlapping") — back to the same small margin
    // PC uses.
    final topSpacerHeight = kToolbarHeight + MediaQuery.paddingOf(context).top + 16.0;
    // TV: a real Positioned constraint on the scroll viewport itself, not a
    // scrollable spacer sliver inside it. A spacer sliver can be scrolled
    // past — Scrollable.ensureVisible's alignment (0.3, see
    // HeroHubSection._scrollIntoView) has no room to honor for a card this
    // tall (heroHeight is 0.6 of screen height), so it just pins the card's
    // leading edge to the very top of the viewport regardless of how big
    // the spacer sliver is (confirmed 2026-09-11: doubling the spacer did
    // nothing — the scroll position bypassed it entirely). A viewport whose
    // own bounds start below the toolbar can't have this problem no matter
    // where anything scrolls to. PC is untouched — its translucent toolbar
    // is meant to have content scroll under it.
    // "Reset to default" (home_layout_settings_screen.dart) restores this
    // legacy screen-level slot instead of any row's own heroStyle — the
    // original stock single-hero-carousel this add-on's per-row rendering
    // replaced, brought back verbatim from origin/main (2026-09-12, user
    // request: "reset it to original plezy like if my pr wasnt there except
    // the order part"). Enabled on TV too (2026-09-12 follow-up) — the
    // restored code is upstream's own, unmodified, and already has full TV
    // handling built in (see the isTv branches throughout _buildHeroSection/
    // _buildHeroItem/_buildSmartPlayButton); it just wasn't being reached
    // before. Every row's own heroStyle still resets to off regardless of
    // platform (home_layout_settings_screen.dart's _resetHeroToStock), so
    // this never coexists with a per-row HeroHubSection for the same reason
    // it doesn't on PC.
    //
    // Suppressed whenever any row is its own hero: the legacy slot is stock
    // Plezy's fixed Continue Watching carousel (always auto-rotates, no
    // arrows, ignores per-row Auto-slide), and showHeroSection defaults to
    // true, so leaving it on alongside per-row heroes stacked a second
    // Continue Watching banner on top of Home (2026-10-11 bug report).
    final anyRowIsHero = _hubs.any((hub) => hub.heroStyle && hub.items.isNotEmpty);
    final showLegacyHero =
        !anyRowIsHero && SettingsService.instance.read(SettingsService.showHeroSection) && _onDeck.isNotEmpty;
    final scrollView = CustomScrollView(
      controller: _scrollController,
      slivers: [
        if (!isTv) SliverToBoxAdapter(child: SizedBox(height: topSpacerHeight)),
        if (showLegacyHero) _buildHeroSection(),
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
                      key: i < _orderedHeroHubKeys.length ? _orderedHeroHubKeys[i] : null,
                      hub: _hubs[i],
                      showBackdrop: SettingsService.instance.read(SettingsService.showHomeBackdrop),
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
                      loadMoreItems: _hubs[i].isContinueWatchingHub
                          ? _discover.loadAllContinueWatching
                          : _hubs[i].isNextUpHub
                          ? _discover.loadAllNextUp
                          : null,
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
    );
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        children: [
          if (isTv) Positioned(top: topSpacerHeight, left: 0, right: 0, bottom: 0, child: scrollView) else scrollView,
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
      onFocusedHubItemChanged: _setSpotlightItem,
      onRefresh: _discover.updateItem,
      onRemoveFromContinueWatching: _discover.refreshContinueWatching,
      isContinueWatchingHub: (hub) => hub.isContinueWatchingHub,
      usesContinueWatchingAction: (hub) => hub.usesContinueWatchingAction,
      // Every other hub pages from its server in View All, as on phones; handing
      // it the preview items only showed that preview again.
      loadMoreItems: (hub) => hub.isContinueWatchingHub
          ? _discover.loadAllContinueWatching
          : hub.isNextUpHub
          ? _discover.loadAllNextUp
          : null,
      onNavigateUp: _focusTopActions,
      onNavigateToSidebar: _navigateToSidebar,
      tallPosterScale: TvBrowseRailLayout.compactTallPosterScale,
      widePosterScale: TvBrowseRailLayout.compactEpisodeThumbnailScale,
      onActivateItem: _handleTvHeroActivate,
    );
  }

  // Cached for the same reason: every provider notification (Continue
  // Watching refreshes on return from Detail or the player) rebuilds this
  // screen, and the toolbar was most of that rebuild. Its own content reads
  // only the theme, translations and _switchingProfile; the providers and
  // clock inside it rebuild themselves.
  Widget? _tvToolbarOverlayWidget;
  (ThemeData, Translations, bool)? _tvToolbarOverlayWidgetKey;

  Widget _cachedTvToolbarOverlay() {
    final key = (Theme.of(context), t, _switchingProfile);
    if (_tvToolbarOverlayWidget != null && key == _tvToolbarOverlayWidgetKey) return _tvToolbarOverlayWidget!;
    _tvToolbarOverlayWidgetKey = key;
    return _tvToolbarOverlayWidget = TvToolbarOverlay(child: _buildOverlaidAppBar());
  }

  /// Selecting a Hero row's item on TV — "clicking the banner" — mirrors PC's
  /// hero card tap exactly (same Organizer-configured
  /// heroCardTapAction setting). Plain rows
  /// return false so TvBrowseRail's own default activation (open details, or
  /// play directly for Continue Watching) still applies unchanged.
  Future<bool> _handleTvHeroActivate(MediaHub hub, MediaItem item) async {
    if (!hub.heroStyle) return false;
    final tapAction = SettingsService.instance.read(SettingsService.heroCardTapAction);
    unawaited(
      navigateToMediaItem(
        context,
        item,
        onRefresh: _discover.updateItem,
        playDirectly: tapAction == HeroCardTapAction.play,
      ),
    );
    return true;
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
          _cachedTvToolbarOverlay(),
          if (_switchingProfile) const ProfileSwitchingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final useSideNav = PlatformDetector.shouldUseSideNavigation(context);
    final isTv = PlatformDetector.isTV();
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    // Mobile keeps its fixed hero, except where that would swamp the screen.
    // A landscape phone is shorter than the hero itself: fill the viewport
    // and let the item compact. A short portrait viewport (iPhone Duo, compact
    // phones) caps it at about two thirds so the first hub row still shows.
    final heroHeight = isTv
        ? viewportHeight * 0.82
        : useSideNav
        ? viewportHeight * 0.75
        : isLandscape
        ? math.min(500 + statusBarHeight, viewportHeight)
        : math.min(500 + statusBarHeight, viewportHeight * 0.65);
    return SliverToBoxAdapter(
      child: Focus(
        focusNode: _heroFocusNode,
        onKeyEvent: _handleHeroKeyEvent,
        child: SizedBox(
          height: heroHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: _buildHeroBackdrop(heroHeight)),
              PageView.builder(
                controller: _heroController,
                itemCount: _onDeck.length,
                onPageChanged: (index) {
                  if (index >= 0 && index < _onDeck.length) {
                    _heroIndex.value = index;
                    _resetAutoScrollTimer();
                  }
                },
                itemBuilder: (context, index) {
                  return _buildHeroItem(_onDeck[index], heroHeight);
                },
              ),
              // Page indicators with animated progress and pause/play button.
              // Hidden on TV only (issue #600: pointer-only control unreachable
              // via d-pad) — never gated on transient input mode, which back-key
              // events, BT keyboards, and gamepads can flip on phones/desktop.
              if (!isTv)
                Positioned(
                  bottom: 16,
                  left: -26,
                  right: 0,
                  // Centered on the same safe width as the hero item above it.
                  child: SafeArea(
                    top: false,
                    bottom: false,
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
                              semanticLabel: _isAutoScrollPaused
                                  ? t.accessibility.autoScrollPlay
                                  : t.accessibility.autoScrollPause,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ValueListenableBuilder<int>(
                          valueListenable: _heroIndex,
                          builder: (context, heroIndex, _) {
                            final range = _getVisibleDotRange();
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(range.end - range.start + 1, (i) {
                                final index = range.start + i;
                                final isActive = heroIndex == index;
                                final dotSize = _getDotSize(index, range.start, range.end);

                                return isActive
                                    ? ValueListenableBuilder<double>(
                                        valueListenable: _indicatorProgress,
                                        builder: (context, progress, child) {
                                          final maxWidth = dotSize * 3;
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
                              }),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Artwork and scrim behind the hero pages. One shared layer instead of
  /// per-page artwork, so a swipe crossfades between backdrops rather than
  /// sliding two images past each other with a hard seam (#2660).
  Widget _buildHeroBackdrop(double heroHeight) {
    if (!SettingsService.instance.read(SettingsService.showHomeBackdrop)) {
      return ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
    }
    final isTv = PlatformDetector.isTV();
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          // Vertical-scroll parallax plus a fade/zoom when the hero first shows.
          ClipRect(
            child: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
                return Transform.translate(
                  offset: Offset(0, _disableAnimations ? 0 : scrollOffset * 0.3),
                  child: child,
                );
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: _disableAnimations ? Duration.zero : const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 1.0 + (0.1 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: ValueListenableBuilder<int>(
                  valueListenable: _heroIndex,
                  builder: (context, heroIndex, _) => HeroCarouselBackdrop(
                    controller: _heroController,
                    currentIndex: heroIndex,
                    itemCount: _onDeck.length,
                    backdropBuilder: (context, index, active, artSize) =>
                        _buildHeroArtwork(_onDeck[index], heroHeight, artSize: artSize, active: active),
                  ),
                ),
              ),
            ),
          ),
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
                      // Reach full bg before the bottom edge so the hero
                      // blends seamlessly into the content below and the
                      // page dots sit on a solid band.
                      colors: [Colors.transparent, bgColor.withValues(alpha: 0.9), bgColor, bgColor],
                      stops: isTv ? const [0.25, 0.78, 0.94, 1.0] : const [0.5, 0.85, 0.94, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroArtwork(MediaItem heroItem, double heroHeight, {required Size artSize, required bool active}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroAspectRatio = screenWidth / heroHeight;
    final heroArtPaths = heroItem.heroArtCandidates(containerAspectRatio: heroAspectRatio);
    final fallbackColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    if (heroArtPaths.isEmpty) return ColoredBox(color: fallbackColor);
    // heroClient resolves to the actual server's client (Plex or Jellyfin) so
    // each backend's transcoder builds sized URLs. Size the request to the
    // drift box, which is wider than the hero, so the art stays sharp.
    return blurArtwork(
      CyclingMediaBackdrop(
        mediaKey: heroItem.globalKey,
        imagePaths: heroItem.heroRotationPaths(containerAspectRatio: heroAspectRatio),
        fallbackImagePaths: heroArtPaths,
        client: _getMediaClientForItem(heroItem),
        active: active && _isTabVisible,
        width: artSize.width,
        height: artSize.height,
        fallbackColor: fallbackColor,
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
    // A landscape phone hands the hero its whole ~400dp viewport, and a short
    // portrait one its capped height; the usual logo and bottom offset would
    // push the content up into the top bar.
    final compact = !isTv && heroHeight < 450;
    final heroLogoWidth = isTv ? TvLayoutConstants.heroLogoWidth : 400.0;
    final heroLogoHeight = isTv
        ? TvLayoutConstants.heroLogoHeight
        : compact
        ? 80.0
        : 120.0;
    final heroTitleStyle = theme.textTheme.displaySmall?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: .bold,
      fontSize: isTv ? 52 : null,
      shadows: [Shadow(color: colorScheme.surface.withValues(alpha: 0.8), blurRadius: 8)],
    );

    final contentTypeLabel = heroItem.isMovie ? t.discover.movie : t.discover.tvShow;

    final hideSpoilers = SettingsService.instance.read(SettingsService.hideSpoilers);
    final shouldHideSpoiler = hideSpoilers && heroItem.shouldHideSpoiler;

    final heroLabel = isEpisode ? "${heroItem.grandparentTitle}, ${heroItem.title}" : heroItem.title;

    return Semantics(
      label: heroLabel,
      button: true,
      hint: t.accessibility.tapToPlay,
      child: ClickableCursor(
        child: GestureDetector(
          // The artwork lives in the shared backdrop below the PageView, so
          // the page itself must claim taps on its empty area.
          behavior: HitTestBehavior.opaque,
          onTap: () {
            appLogger.d('Activating hero item: ${heroItem.title}');
            navigateToMediaItem(context, heroItem, playDirectly: true);
          },
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              // Content with responsive alignment. Compact trims the offset
              // but still clears the page indicator row (bottom 16, ~18 tall)
              // that sits over every handheld hero.
              Positioned(
                bottom: isTv
                    ? 88
                    : compact
                    ? 44
                    : isLargeScreen
                    ? 80
                    : 50,
                left: 0,
                right: isTv
                    ? screenWidth * 0.36
                    : isLargeScreen
                    ? 200
                    : 0,
                // Horizontal-only SafeArea: the PageView artwork behind stays
                // full-bleed; the foreground text/buttons clear the landscape
                // notch. Vertical placement is handled by `bottom` above.
                child: SafeArea(
                  top: false,
                  bottom: false,
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
                            // Show logo, falling back to the name/title. The
                            // logo keeps its slot; the title gets a wider one.
                            LayoutBuilder(
                              builder: (context, constraints) => ClearLogoImage(
                                client: heroClient,
                                logoPath: heroItem.clearLogoPath,
                                width: math.min(heroLogoWidth, constraints.maxWidth),
                                height: heroLogoHeight,
                                fallbackWidth: ClearLogoImage.fallbackWidthFor(
                                  logoWidth: heroLogoWidth,
                                  available: constraints.maxWidth,
                                ),
                                alignment: alignLeft ? Alignment.bottomLeft : Alignment.bottomCenter,
                                // The hero scrim washes artwork toward the scaffold
                                // background; light themes recolor light-toned logos.
                                logoToneTarget: logoToneTargetFor(
                                  surface: theme.scaffoldBackgroundColor,
                                  foreground: colorScheme.onSurface,
                                ),
                                fallbackBuilder: (context) => FittingTitleText(
                                  showName,
                                  style: heroTitleStyle,
                                  textAlign: alignLeft ? TextAlign.left : TextAlign.center,
                                  alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
                                ),
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

                            if (!alignLeft) ...[const SizedBox(height: 20), _buildSmartPlayButton(heroItem)],

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

                            if (alignLeft) ...[SizedBox(height: isTv ? 28 : 20), _buildSmartPlayButton(heroItem)],
                          ],
                        ),
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
