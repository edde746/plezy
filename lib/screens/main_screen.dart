import 'dart:async';
import '../media/ids.dart';
import '../media/media_server_client.dart';
import '../navigation/main_screen_scope.dart';
import 'dart:io' show Platform, exit;

export '../navigation/main_screen_scope.dart'
    show MainScreenFocusScope, MainScreenScopeAspect, SideNavigationBleedBuilder;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, KeyRepeatEvent, KeyUpEvent, LogicalKeyboardKey;
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../i18n/strings.g.dart';
import '../services/app_exit_service.dart';
import '../services/tvos_system_navigation_service.dart';
import '../services/update_service.dart';
import '../utils/app_logger.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/app_icon.dart';
import '../utils/provider_extensions.dart';
import '../utils/platform_detector.dart';
import '../utils/snackbar_helper.dart';
import '../utils/update_dialog.dart';
import '../utils/video_player_navigation.dart';
import '../mixins/mounted_set_state_mixin.dart';
import '../mixins/refreshable.dart';
import '../widgets/overlay_sheet.dart';
import '../mixins/tab_visibility_aware.dart';
import '../navigation/navigation_tabs.dart';
import '../navigation/profile_navigation_scope.dart';
import '../profiles/active_profile_binder.dart';
import '../connection/connection_registry.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/plex_home_service.dart';
import '../profiles/profile_selection_policy.dart';
import '../providers/catalog_sources_provider.dart';
import '../providers/download_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/libraries_provider.dart';
import '../providers/playback_state_provider.dart';
import '../widgets/settings_builder.dart';
import '../widgets/tv_virtual_keyboard.dart';
import '../services/api_cache.dart';
import '../services/multi_server_manager.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/settings_service.dart';
import '../providers/offline_mode_provider.dart';
import '../services/companion_remote/companion_remote_host_controller.dart';
import '../services/companion_remote/companion_remote_receiver.dart';
import '../services/fullscreen_state_manager.dart';
import '../providers/companion_remote_provider.dart';
import '../utils/desktop_window_padding.dart';
import '../widgets/music/mini_player.dart';
import '../widgets/side_navigation_rail.dart';
import '../focus/dpad_navigator.dart';
import '../focus/key_event_utils.dart';
import 'discover_screen.dart';
import 'explore_screen.dart';
import 'libraries/library_quick_picker_sheet.dart';
import 'libraries/libraries_screen.dart';
import 'livetv/live_tv_screen.dart';
import 'search_screen.dart';
import 'downloads/downloads_screen.dart';
import 'settings/settings_screen.dart';
import 'profile/profile_switch_screen.dart';
import 'video_player_screen.dart';
import 'profile/profile_teardown.dart';
import '../services/system_shelf_service.dart';
import '../watch_together/watch_together.dart';

/// Provides access to the main screen's focus control.
// MainScreenFocusScope and SideNavigationBleedBuilder live in
// navigation/main_screen_scope.dart (re-exported above) so widgets like the
// browse rail can import the scope without an import cycle through this file.

@visibleForTesting
bool shouldHandleDesktopRootEscape({
  required bool isDesktop,
  required bool isPhysicalKeyboardEvent,
  required LogicalKeyboardKey logicalKey,
  required bool isCurrentRoute,
  required bool isHomeTab,
}) {
  return isDesktop && isPhysicalKeyboardEvent && logicalKey == LogicalKeyboardKey.escape && isCurrentRoute && isHomeTab;
}

/// Whether a lifecycle resume should raise the "ask for a profile on open"
/// picker.
///
/// Mobile-only: on desktop `resumed` fires on every window focus gain
/// (alt-tab, click), which is far too frequent — the startup prompt is
/// sufficient there. Never during active video playback: waking the device
/// mid-stream must resume the stream, not stack the root-navigator picker
/// over the live player route, whose focus self-heal fights the picker for
/// the remote (#2034) — the playback session already belongs to the profile
/// that started it.
@visibleForTesting
bool shouldShowProfileSelectionOnResume({
  required bool resumedFromBackground,
  required bool isOffline,
  required bool alreadyShowingProfileSelection,
  required bool isMobilePlatform,
  required bool hasActiveVideoPlayback,
}) {
  return resumedFromBackground &&
      !isOffline &&
      !alreadyShowingProfileSelection &&
      isMobilePlatform &&
      !hasActiveVideoPlayback;
}

/// Latches whether the app has genuinely left the foreground since the last
/// `resumed`, and consumes that fact on the next resume so the "ask for a
/// profile on open" rule can re-apply exactly once per backgrounding.
///
/// System overlays (Fire TV Alexa, notification shade, Control Center) only
/// produce `inactive -> resumed` — the app never left the foreground — so
/// they must not prompt (#1990). iOS returns from the background as
/// `hidden -> inactive -> resumed`, so inspecting only the immediately
/// previous state would miss a real return; latching the deepest state seen
/// handles both. The startup flow owns the cold open, so a first `resumed`
/// with no prior backgrounding does not prompt.
@visibleForTesting
class ProfileSelectionResumeGate {
  bool _wasBackgrounded = false;

  /// Whether a genuine backgrounding has been observed since the last resume.
  bool get wasBackgrounded => _wasBackgrounded;

  /// Feeds one lifecycle transition through the gate. Returns true exactly
  /// once per backgrounding: on the first `resumed` after the sequence
  /// reached `hidden`/`paused`/`detached`. Consuming resets the latch.
  bool consumePromptOn(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        final shouldPrompt = _wasBackgrounded;
        _wasBackgrounded = false;
        return shouldPrompt;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _wasBackgrounded = true;
        return false;
      case AppLifecycleState.inactive:
        return false;
    }
  }
}

@visibleForTesting
({double left, double width}) mainScreenSideNavigationContentLayout({
  required double viewportWidth,
  required double currentSideNavigationWidth,
  required double reservedSideNavigationWidth,
}) {
  return (
    left: currentSideNavigationWidth,
    width: (viewportWidth - reservedSideNavigationWidth).clamp(0.0, double.infinity).toDouble(),
  );
}

@visibleForTesting
bool shouldRetryActiveProfileBindAfterReconnect({
  required bool hasActiveProfile,
  required bool hasVisibleConnectedServers,
  required bool hasManagerOnlineServers,
  required bool hasKnownOfflineServers,
}) {
  return hasActiveProfile && !hasVisibleConnectedServers && (hasManagerOnlineServers || !hasKnownOfflineServers);
}

@visibleForTesting
bool shouldRenderMainScreenOffline({
  required bool providerOffline,
  required bool startupOfflineUntilConnected,
  required bool hasVisibleConnectedServers,
}) {
  return providerOffline || (startupOfflineUntilConnected && !hasVisibleConnectedServers);
}

@visibleForTesting
List<NavigationTab> mainScreenBottomNavigationTabs({
  required List<NavigationTab> visibleTabs,
  required bool isMobile,
  required bool isOffline,
  required NavigationTabId currentTab,
}) {
  if (!isMobile) return visibleTabs;
  return visibleTabs.where((tab) {
    if (tab.id != NavigationTabId.settings) return true;
    return isOffline || currentTab == NavigationTabId.settings;
  }).toList();
}

@visibleForTesting
bool shouldPassTvosMenuToSystem({
  required bool isAppleTV,
  required bool isShowingProfileSelection,
  required bool isOverlaySheetOpen,
  required bool isRouteCurrent,
  required bool isSidebarFocused,
  required bool hasVisibleTabs,
  required bool isCurrentTabRoot,
}) {
  return isAppleTV &&
      isSidebarFocused &&
      !isShowingProfileSelection &&
      !isOverlaySheetOpen &&
      isRouteCurrent &&
      hasVisibleTabs &&
      isCurrentTabRoot;
}

@visibleForTesting
enum ProfileInvalidationAction { none, invalidateNow }

@visibleForTesting
ProfileInvalidationAction profileInvalidationAction({
  required String? previousProfileId,
  required String? currentProfileId,
  required bool wasBindingPreviously,
  required bool isBindingNow,
}) {
  // An active-id change remounts the whole session subtree
  // ([ProfileSessionScreen] keys on the id), recreating this screen and
  // every session-scoped provider — nothing to invalidate from here. The
  // app-global pieces (ApiCache volatile rows) are cleared at that remount
  // seam, where the unmount can't outrun the work.
  if (currentProfileId != previousProfileId) {
    return ProfileInvalidationAction.none;
  }
  if (wasBindingPreviously && !isBindingNow) {
    return ProfileInvalidationAction.invalidateNow;
  }
  return ProfileInvalidationAction.none;
}

class MainScreen extends StatefulWidget {
  final bool isOfflineMode;

  /// When `true`, the previous screen (typically [SetupScreen]) already
  /// resolved the launch profile prompt — skip the postFrame prompt that
  /// would otherwise re-fire it.
  final bool initialPromptHandled;

  const MainScreen({super.key, this.isOfflineMode = false, this.initialPromptHandled = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with RouteAware, WindowListener, WidgetsBindingObserver, MountedSetStateMixin {
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

  /// A preferred startup section (e.g. Live TV) that wasn't visible yet at cold
  /// start because servers bind asynchronously. Applied once it becomes
  /// available (see [_handleLiveTvChanged]); cleared on any explicit selection.
  NavigationTabId? _pendingStartupTab;

  /// Whether we auto-switched to Downloads because the previous tab was unavailable offline
  bool _autoSwitchedToDownloads = false;

  OfflineModeProvider? _offlineModeProvider;
  MultiServerProvider? _multiServerProvider;
  CatalogSourcesProvider? _catalogSourcesProvider;
  ValueListenable<bool>? _showExploreTabListenable;
  RouteObserver<PageRoute<dynamic>>? _profileRouteObserver;
  bool _lastHasLiveTv = false;
  bool _lastHasExplore = false;

  /// Whether a reconnection attempt is in progress
  bool _isReconnecting = false;

  /// Startup routed here explicitly offline. Keep the offline shell until a
  /// visible server actually connects; provider warmup can be optimistic when
  /// failed Plex servers have no live client yet.
  bool _offlineUntilConnected = false;

  /// Prevents double-pushing the profile selection screen
  bool _isShowingProfileSelection = false;

  /// Latches a genuine backgrounding so "ask for a profile on open" fires
  /// exactly once on the next resume, while transient focus losses
  /// (`inactive`, e.g. the Fire TV Alexa overlay) never prompt.
  final _profileSelectionResumeGate = ProfileSelectionResumeGate();

  late List<Widget> _screens;

  /// One [GlobalKey] per tab, so a tab's live [State] can be reached from
  /// anywhere in this class via [_onScreen]. Deliberately untyped: every
  /// consumer discards the concrete `State<X>` type and pattern-matches on a
  /// capability mixin (Refreshable, FocusableTab, …) instead.
  final Map<NavigationTabId, GlobalKey> _screenKeys = {for (final id in NavigationTabId.values) id: GlobalKey()};
  final GlobalKey<SideNavigationRailState> _sideNavKey = GlobalKey();

  /// Measures the mobile bottom navigation area for the music mini-player.
  final GlobalKey _bottomBarKey = GlobalKey();
  MiniPlayerInsetController? _miniPlayerInsets;

  // Focus management for sidebar/content switching
  final FocusScopeNode _sidebarFocusScope = FocusScopeNode(debugLabel: 'Sidebar');
  final FocusScopeNode _contentFocusScope = FocusScopeNode(debugLabel: 'Content');
  bool _isSidebarFocused = false;
  // Hover/touch rail expansion is an M3E modal overlay: the rail draws over
  // the content, so this only drives the scrim behind it — never the
  // content offset.
  bool _isSidebarInteractionExpanded = false;
  bool _isOverlaySheetOpen = false;

  /// The binder is now owned by a top-level [Provider] (see main.dart) so
  /// the splash can await its first settle before navigating here. We just
  /// observe its [ActiveProfileProvider.isBinding] state for the once-only
  /// priming below.
  PlexHomeService? _plexHomeService;
  ActiveProfileProvider? _activeProfileForListener;
  String? _lastSeenProfileId;
  // Tracks ActiveProfileProvider.isBinding from the previous notification
  // so we can detect a binding-just-settled transition for the *same*
  // active profile id (e.g. after a borrow/remove rebind). Without this
  // we only invalidate on id change and the libraries sidebar keeps
  // stale entries until the user switches profiles.
  bool _wasBindingPrev = false;
  bool _hadProfiles = false;

  /// Subscription to MultiServerManager status changes. Used to resume any
  /// queued downloads as soon as a Plex client comes online for the first
  /// time after launch (legacy main.dart used to do this from SetupScreen
  /// before navigating).
  StreamSubscription<Map<String, bool>>? _serverStatusSub;
  bool _downloadResumeFired = false;

  /// Listener that fires when [ActiveProfileBinder] settles (Plex *and*
  /// Jellyfin both bound). Drives the once-per-launch priming of
  /// LibrariesProvider + watch sync + tab fullRefresh — wiring this off
  /// the first online-server emission instead would prime before
  /// Jellyfin gets added, leaving its libraries out of the navbar.
  VoidCallback? _bindingSettleListener;
  bool _startupServicesPrimed = false;
  Timer? _startupSettleTimeout;

  /// Hard ceiling on how long we wait for [ActiveProfileBinder] to settle
  /// before priming the UI anyway. The binder always calls
  /// `markBindingFinished` in its `finally`, but this is a defence in depth:
  /// if a transient bug or hung HTTP path keeps `isBinding` true, the user
  /// would otherwise see an empty Discover screen forever. After the
  /// fallback fires the screens render their normal "no servers" state and
  /// the user can pull-to-refresh / open settings.
  static const _startupSettleFallback = Duration(seconds: 15);
  static const _backExitWindow = Duration(seconds: 3);
  DateTime? _lastBackPressAt;

  @override
  void initState() {
    super.initState();
    _isOffline = widget.isOfflineMode;
    _offlineUntilConnected = widget.isOfflineMode;

    WidgetsBinding.instance.addObserver(this);
    _contentFocusScope.addListener(_syncSidebarFocusWithContent);

    if (PlatformDetector.isDesktopOS()) {
      windowManager.addListener(this);
      windowManager.setPreventClose(true);
    }

    // Synchronize _lastHasLiveTv with provider before building screens
    // so _buildScreens and _hasLiveTv getter agree from the start.
    try {
      _lastHasLiveTv = context.read<MultiServerProvider>().hasLiveTv;
    } catch (_) {
      _lastHasLiveTv = false;
    }
    try {
      _lastHasExplore = context.read<CatalogSourcesProvider>().hasAnySource && _showExploreTabSetting;
    } catch (_) {
      _lastHasExplore = false;
    }
    // Re-evaluate Explore tab visibility when the appearance toggle flips
    // mid-session; the catalog-sources listener covers source changes.
    _showExploreTabListenable = SettingsService.instanceOrNull?.listenable(SettingsService.showExploreTab);
    _showExploreTabListenable?.addListener(_handleCatalogSourcesChanged);
    _currentTab = _defaultTabForMode(_isOffline);
    _lastOnlineTabId = _isOffline ? null : NavigationTabId.discover;
    _autoSwitchedToDownloads = _isOffline && _currentTab == NavigationTabId.downloads;
    // If the preferred startup section isn't visible yet (e.g. Live TV before
    // servers finish binding), remember it and switch once it becomes available.
    final preferredStartup = SettingsService.instanceOrNull?.read(SettingsService.startupSection);
    _pendingStartupTab = (!_isOffline && preferredStartup != null && preferredStartup != _currentTab)
        ? preferredStartup
        : null;
    _screens = _buildScreens(_isOffline);

    // Warm the TV keyboard's text-layout caches off the first real open
    // (measured ~315ms first-open frame on low-end boxes, mostly cold font
    // shaping). Delayed past the startup burst; no-op off TV.
    if (PlatformDetector.isTV()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) warmUpTvVirtualKeyboardText(context);
        });
      });
    }

    // Set up Watch Together callbacks immediately (must be synchronous to catch early messages)
    if (!_isOffline) {
      _setupWatchTogetherCallback();
      _setupSystemShelfDeepLink();
    }

    // Wire profile binder + tracker bootstrap (skip in offline mode)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final activeProfile = context.read<ActiveProfileProvider>();
      _activeProfileForListener = activeProfile;
      _lastSeenProfileId = activeProfile.activeId;
      activeProfile.addListener(_onActiveProfileChanged);
      _plexHomeService = context.read<PlexHomeService>();
      unawaited(_plexHomeService!.start());
      final manager = context.read<MultiServerProvider>().serverManager;
      // Read the binder so the Provider's `lazy: false` create has fired
      // for sure; start only in online mode so explicit startup offline does
      // not immediately kick off the same connection attempts it skipped.
      final binder = context.read<ActiveProfileBinder>();
      if (!_isOffline) binder.start();
      _runStartupOnFirstOnlineServer(manager);

      if (!_isOffline) {
        // Settings-only initialization — profile identity is managed by
        // ActiveProfileProvider + ActiveProfileBinder.
        final userProfileProvider = context.userProfile;
        await userProfileProvider.initialize();
        if (!mounted) return;

        // Ensure first login (or any unset profile state) requires explicit selection.
        await _promptForInitialProfileSelection();
        if (!mounted) return;

        // Auto-start companion remote server once the active profile is known.
        if (_companionRemoteSetup) {
          unawaited(_autoStartCompanionRemoteServer());
        }
      }

      // Focus content initially (replaces autofocus which caused focus stealing issues)
      // Skip if profile selection is on top — it manages its own focus.
      if (!_isSidebarFocused && !_isShowingProfileSelection) {
        _contentFocusScope.requestFocus();
      }

      _updateTvosMenuPassthrough();

      // Check for updates on startup
      unawaited(_checkForUpdatesOnStartup());
    });
  }

  /// Run startup tasks that depend on having at least one online server:
  /// initialize and load the libraries provider, kick off the initial
  /// watch-state sync, and (for Plex) resume any queued downloads. The
  /// legacy [SetupScreen] path used to do all this before navigating to
  /// MainScreen; with the binder taking over for the connect, we hook
  /// into [ActiveProfileProvider.isBinding] (for the once-only priming,
  /// which must wait for *all* connections — Plex *and* Jellyfin — to
  /// land so the navbar shows libraries from both backends) and
  /// [MultiServerManager.statusStream] (for download resume, which only
  /// cares about the first online Plex client). Fires at most once per
  /// MainScreen lifetime.
  void _runStartupOnFirstOnlineServer(MultiServerManager manager) {
    if (_isOffline || _downloadResumeFired) return;

    final activeProfile = context.read<ActiveProfileProvider>();

    void primeServicesOnBindingSettle({bool fromTimeout = false}) {
      if (_startupServicesPrimed || !mounted) return;
      // Wait for the binder to finish — `_rebind` only flips `isBinding`
      // false after both `_bindPlexHome` AND `_bindJoinRows` (where
      // Jellyfin gets added) complete. Priming on the first Plex status
      // emit instead would load libraries before Jellyfin is registered.
      //
      // The `fromTimeout` escape hatch lets the [_startupSettleTimeout]
      // bypass this gate if the binder has somehow not flipped the flag
      // within [_startupSettleFallback]. Logs a warning so the silent
      // path is still surfaced in diagnostics.
      if (activeProfile.isBinding && !fromTimeout) return;
      if (fromTimeout) {
        appLogger.w(
          'ActiveProfileBinder still binding after ${_startupSettleFallback.inSeconds}s '
          '— priming UI anyway so the user is not stuck on an empty screen.',
        );
      }
      // Set the guard before the await so re-entrant listener fires can't
      // race a second prime.
      _startupServicesPrimed = true;
      _startupSettleTimeout?.cancel();
      _startupSettleTimeout = null;

      unawaited(_primeOnlineServices(manager));
    }

    void tryDownloadResume() {
      // Wait for any online client before firing the resume — the download
      // pipeline is backend-neutral (resumeQueuedDownloads accepts a
      // MediaServerClient and per-item resolution picks up the right
      // backend), so a Jellyfin-only setup can resume too.
      _resumeQueuedDownloadsOnce(manager.onlineClients.values.firstOrNull);
    }

    // Listen for binding-settle so the once-only priming runs after both
    // Plex and Jellyfin are wired up.
    _bindingSettleListener = () => primeServicesOnBindingSettle();
    activeProfile.addListener(_bindingSettleListener!);

    // Defence in depth: bypass the binder gate after a hard ceiling so a
    // hung bind path can't strand the user on an empty screen.
    _startupSettleTimeout?.cancel();
    _startupSettleTimeout = Timer(_startupSettleFallback, () {
      primeServicesOnBindingSettle(fromTimeout: true);
    });

    // Fast paths: binder may have already settled / first Plex server may
    // already be online (binder finished before this microtask).
    primeServicesOnBindingSettle();
    tryDownloadResume();
    if (_downloadResumeFired) return;

    _serverStatusSub = manager.statusStream.listen((_) => tryDownloadResume());
  }

  /// Shared online-entry hook for cold startup and reconnect-from-offline.
  /// It mirrors `_invalidateAllScreens`: libraries load before tab refreshes
  /// so screens don't initialize against an empty provider and remain blank.
  Future<void> _primeOnlineServices(MultiServerManager manager) async {
    if (manager.onlineServerIds.isNotEmpty) {
      if (!mounted) return;
      final mp = context.read<MultiServerProvider>();
      if (mp.hasConnectedServers) {
        final lp = context.read<LibrariesProvider>();
        lp.initialize(mp.aggregationService);
        await lp.loadLibraries();
        if (!mounted) return;
        context.read<OfflineWatchSyncService>().onServersConnected();
        unawaited(context.read<DownloadProvider>().refreshMetadataFromCache());
        _resumeQueuedDownloadsOnce(
          mp.onlineServerIds.map((id) => mp.getClientForServer(ServerId(id))).nonNulls.firstOrNull,
        );
      }
    }

    if (!mounted) return;
    _primeContentTabs();
  }

  /// Single-shot "resume queued downloads once any client is online" rule,
  /// shared by the startup status-stream path and [_primeOnlineServices] —
  /// each caller resolves its own candidate client (unfiltered manager view
  /// vs the visibility-filtered provider) and hands it here. No-op once the
  /// resume has fired, or while no client is online yet.
  void _resumeQueuedDownloadsOnce(MediaServerClient? onlineClient) {
    if (_downloadResumeFired || !mounted) return;
    if (onlineClient == null) return;
    _downloadResumeFired = true;
    // The status subscription exists only to drive this one-shot.
    _serverStatusSub?.cancel();
    _serverStatusSub = null;
    final downloadProvider = context.read<DownloadProvider>();
    unawaited(
      downloadProvider.ensureInitialized().then((_) {
        if (!mounted) return;
        downloadProvider.resumeQueuedDownloads(onlineClient);
      }),
    );
  }

  void _onActiveProfileChanged() {
    final activeProfile = _activeProfileForListener;
    if (activeProfile == null) return;
    final id = activeProfile.activeId;
    final isBindingNow = activeProfile.isBinding;
    final action = profileInvalidationAction(
      previousProfileId: _lastSeenProfileId,
      currentProfileId: id,
      wasBindingPreviously: _wasBindingPrev,
      isBindingNow: isBindingNow,
    );
    _lastSeenProfileId = id;
    _wasBindingPrev = isBindingNow;

    // Re-arm the initial-profile prompt when profiles arrive late (e.g. a
    // slow home-user fetch landing after the empty first snapshot) while
    // nothing is active — otherwise the one-shot post-frame prompt has
    // already passed and the user is stuck in a session with no picker.
    final hasProfilesNow = activeProfile.profiles.isNotEmpty;
    if (!_hadProfiles && hasProfilesNow && id == null && !_isShowingProfileSelection) {
      unawaited(_promptForInitialProfileSelection());
    }
    _hadProfiles = hasProfilesNow;

    // Same active id, but a rebind cycle for that profile just settled
    // (true → false transition). Fires after borrow / connection-removal
    // flows trigger ActiveProfileBinder.rebindIfActive, so the libraries
    // sidebar reflects the new server set without an app restart.
    if (action == ProfileInvalidationAction.invalidateNow) {
      unawaited(_invalidateAllScreens());
    }
  }

  Future<void> _promptForInitialProfileSelection() async {
    if (!mounted || _isShowingProfileSelection) return;
    if (widget.initialPromptHandled) return;

    final activeProfile = context.read<ActiveProfileProvider>();
    final connections = context.read<ConnectionRegistry>();
    // The provider's initialize() is fire-and-forget from MultiProvider —
    // wait for it to settle so `active` and `profiles` reflect storage
    // before we decide whether to prompt.
    await activeProfile.initialize();
    if (!mounted) return;

    final settingsService = await SettingsService.getInstance();
    if (!mounted) return;

    // Connections but ZERO resolvable profiles (e.g. the home-user fetch
    // failed at sign-in): a session with nothing to select and no picker is
    // a dead end. Mirror the boot guard — prune orphans and route to auth
    // when nothing selectable remains.
    if (activeProfile.active == null && activeProfile.profiles.isEmpty) {
      // Offline, "unresolvable" may just be an unreachable plex.tv — don't
      // kick the user to auth over it.
      if (!widget.isOfflineMode && (await connections.list()).isNotEmpty && mounted) {
        appLogger.w('MainScreen: connections exist but no profiles resolved — settling session');
        await settleSessionAfterRemoval(SessionTeardownScope.of(context));
      }
      return;
    }

    // Always prompt when there's no active profile but profiles exist
    // (fresh sign-in with multiple Plex Home users): otherwise the binder
    // has no profile to bind, and the user lands on an empty screen with
    // no way back to the picker.
    final hasNoActive = activeProfile.active == null && activeProfile.profiles.isNotEmpty;

    if (!hasNoActive && !activeProfile.requiresSelectionOnOpen(settingsService)) return;

    await _pushProfileSelection();
  }

  /// Push the picker in "must choose" mode, suppressing the tvOS menu-button
  /// passthrough for as long as it is up.
  Future<void> _pushProfileSelection() async {
    _isShowingProfileSelection = true;
    _setTvosMenuPassthrough(false);
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (context) => const ProfileSwitchScreen(requireSelection: true)));
    if (!mounted) return;
    _isShowingProfileSelection = false;
    _updateTvosMenuPassthrough();
  }

  Future<void> _checkForUpdatesOnStartup() async {
    if (!mounted) return;

    final settingsService = await SettingsService.getInstance();
    if (!settingsService.read(SettingsService.autoCheckUpdatesOnStartup)) return;

    // Native updater (Sparkle/WinSparkle) handles everything — skip Flutter dialog
    if (UpdateService.useNativeUpdater) {
      await UpdateService.checkForUpdatesNative(inBackground: true);
      return;
    }

    try {
      final updateInfo = await UpdateService.checkForUpdatesOnStartup();

      if (updateInfo != null && updateInfo['hasUpdate'] == true && mounted) {
        await _showUpdateDialog(updateInfo);
      }
    } catch (e) {
      appLogger.e('Error checking for updates', error: e);
    }
  }

  Future<void> _showUpdateDialog(Map<String, dynamic> updateInfo) => showUpdateAvailableDialog(
    context,
    updateInfo,
    title: t.update.available,
    dismissLabel: t.common.later,
    showSkipVersion: true,
  );

  /// Set up the Watch Together navigation callback for guests
  void _setupWatchTogetherCallback() {
    try {
      final watchTogether = context.read<WatchTogetherProvider>();
      watchTogether.onMediaSwitched = (ratingKey, serverId, mediaTitle) {
        appLogger.d('WatchTogether: Media switch received - navigating to $mediaTitle');
        return _navigateToWatchTogetherMedia(ratingKey, serverId);
      };
      watchTogether.onHostExitedPlayer = () {
        appLogger.d('WatchTogether: Host exited player - exiting player for guest');
        // Watch Together playback lives in the profile navigator; root-level
        // dialogs/profile picker must not be affected.
        if (!mounted) return;
        final navigator = Navigator.of(context);
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

  /// Set up launcher shelf deep link handling for Android TV and tvOS taps.
  void _setupSystemShelfDeepLink() {
    if (!Platform.isAndroid && !PlatformDetector.isAppleTV()) return;

    final systemShelf = SystemShelfService();

    // Listen for deep links when app is already running (warm start)
    systemShelf.onShelfItemTap = (contentId) {
      appLogger.d('System shelf tap: $contentId');
      _handleShelfContentId(contentId);
    };
    _systemShelfTapCallback = systemShelf.onShelfItemTap;

    // Check for pending deep link from cold start
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final contentId = await systemShelf.getInitialDeepLink();
      if (contentId != null && mounted) {
        appLogger.d('System shelf initial deep link: $contentId');
        unawaited(_handleShelfContentId(contentId));
      }
    });
  }

  /// Handle a launcher shelf content ID by fetching metadata and starting playback.
  Future<void> _handleShelfContentId(String contentId) async {
    if (!mounted) return;

    final parsed = SystemShelfService.parseContentId(contentId);
    if (parsed == null) {
      appLogger.w('System shelf: invalid content ID: $contentId');
      return;
    }

    final (serverId, ratingKey) = parsed;

    try {
      final multiServer = context.read<MultiServerProvider>();
      final client = multiServer.getClientForServer(serverId);

      if (client == null) {
        appLogger.w('System shelf: server $serverId not available');
        return;
      }

      final metadata = await client.fetchItem(ratingKey);

      if (metadata == null || !mounted) return;

      unawaited(navigateToVideoPlayer(context, metadata: metadata));
    } catch (e) {
      appLogger.e('System shelf: failed to navigate to media', error: e);
    }
  }

  /// Navigate to media when host switches content in Watch Together session.
  /// Returns whether navigation was initiated; failures are re-dispatched on
  /// the host's next state heartbeat.
  Future<bool> _navigateToWatchTogetherMedia(String ratingKey, ServerId serverId) async {
    if (!mounted) return false; // Check before any context usage

    try {
      return await navigateToWatchTogetherPlayback(context, ratingKey: ratingKey, serverId: serverId);
    } catch (e) {
      appLogger.e('WatchTogether: Failed to navigate to media', error: e);
      return false;
    }
  }

  bool _companionRemoteSetup = false;
  ValueChanged<String>? _systemShelfTapCallback;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for offline/online transitions to refresh navigation & screens.
    // If the provider already observed a failed bind before this listener
    // attached, mirror that missed state after build.
    final provider = context.read<OfflineModeProvider?>();
    if (provider != null && provider != _offlineModeProvider) {
      _offlineModeProvider?.removeListener(_handleOfflineStatusChanged);
      _offlineModeProvider = provider;
      _offlineModeProvider!.addListener(_handleOfflineStatusChanged);
      if (!widget.isOfflineMode && !_isOffline && provider.isOffline) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _handleOfflineStatusChanged();
        });
      }
    }

    // Listen for Live TV / DVR availability changes
    final multiServer = context.read<MultiServerProvider>();
    if (multiServer != _multiServerProvider) {
      _multiServerProvider?.removeListener(_handleLiveTvChanged);
      _multiServerProvider = multiServer;
      _multiServerProvider!.addListener(_handleLiveTvChanged);
    }

    // Listen for catalog sources (Explore tab) appearing/disappearing when a
    // provider like Trakt is connected or disconnected mid-session.
    final catalogSources = context.read<CatalogSourcesProvider>();
    if (catalogSources != _catalogSourcesProvider) {
      _catalogSourcesProvider?.removeListener(_handleCatalogSourcesChanged);
      _catalogSourcesProvider = catalogSources;
      _catalogSourcesProvider!.addListener(_handleCatalogSourcesChanged);
    }

    // Wire up Companion Remote command routing (host devices only, once)
    if (!_companionRemoteSetup && PlatformDetector.shouldActAsRemoteHost(context)) {
      _companionRemoteSetup = true;
      _setupCompanionRemote();
    }

    _miniPlayerInsets = context.read<MiniPlayerInsetController?>();

    final scopedRouteObserver = ProfileNavigationScope.of(context).routeObserver;
    if (scopedRouteObserver != _profileRouteObserver) {
      _profileRouteObserver?.unsubscribe(this);
      _profileRouteObserver = scopedRouteObserver;
      final route = ModalRoute.of(context);
      if (route is PageRoute<dynamic>) {
        scopedRouteObserver.subscribe(this, route);
      }
    }
  }

  void _setupCompanionRemote() {
    final companionRemote = context.read<CompanionRemoteProvider>();
    companionRemote.onCommandReceived = (command) {
      if (mounted) {
        CompanionRemoteReceiver.instance.handleCommand(command, context);
      }
    };

    final receiver = CompanionRemoteReceiver.instance;
    receiver.navigationOwner = this;
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
    receiver.onHome = () {
      final tabs = _getVisibleTabs(_isOffline);
      if (tabs.isEmpty) return;
      _selectTab(tabs.first.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sideNavKey.currentState?.focusHomeItem();
      });
    };
    receiver.onSearchAction = (query) {
      final trimmed = query?.trim() ?? '';
      final hasQuery = trimmed.isNotEmpty;
      // With a query, don't focus the input (which would auto-open the TV
      // keyboard); submitSearchQuery runs the search and focuses results.
      _selectTab(NavigationTabId.search, focusSearchInput: !hasQuery);
      if (hasQuery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onScreen<SearchInputFocusable>(NavigationTabId.search, (screen) => screen.submitSearchQuery(trimmed));
        });
      }
    };
  }

  Future<void> _autoStartCompanionRemoteServer() async {
    try {
      final settings = await SettingsService.getInstance();
      if (!settings.read(SettingsService.enableCompanionRemoteServer)) return;
      if (!mounted) return;
      await startCompanionRemoteHost(context);
    } catch (e) {
      appLogger.e('CompanionRemote: Failed to auto-start server', error: e);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _profileRouteObserver?.unsubscribe(this);
    if (PlatformDetector.isDesktopOS()) {
      windowManager.removeListener(this);
      windowManager.setPreventClose(false);
    }
    _offlineModeProvider?.removeListener(_handleOfflineStatusChanged);
    _multiServerProvider?.removeListener(_handleLiveTvChanged);
    _catalogSourcesProvider?.removeListener(_handleCatalogSourcesChanged);
    _showExploreTabListenable?.removeListener(_handleCatalogSourcesChanged);
    if (_bindingSettleListener != null) {
      _activeProfileForListener?.removeListener(_bindingSettleListener!);
    }
    _activeProfileForListener?.removeListener(_onActiveProfileChanged);
    _serverStatusSub?.cancel();
    _startupSettleTimeout?.cancel();
    _startupSettleTimeout = null;
    _sidebarFocusScope.dispose();
    _contentFocusScope.removeListener(_syncSidebarFocusWithContent);
    _contentFocusScope.dispose();
    _setTvosMenuPassthrough(false);

    // Clean up only callbacks still owned by this screen. A replacement
    // MainScreen may already have installed its callbacks this frame.
    if (_companionRemoteSetup) {
      final receiver = CompanionRemoteReceiver.instance;
      if (identical(receiver.navigationOwner, this)) {
        receiver.onTabNext = null;
        receiver.onTabPrevious = null;
        receiver.onTabDiscover = null;
        receiver.onTabLibraries = null;
        receiver.onTabSearch = null;
        receiver.onTabDownloads = null;
        receiver.onTabSettings = null;
        receiver.onHome = null;
        receiver.onSearchAction = null;
        receiver.navigationOwner = null;
      }
    }
    final shelfCallback = _systemShelfTapCallback;
    final systemShelf = SystemShelfService();
    if (shelfCallback != null && identical(systemShelf.onShelfItemTap, shelfCallback)) {
      systemShelf.onShelfItemTap = null;
    }

    super.dispose();
  }

  @override
  void onWindowClose() {
    unawaited(_exitOnWindowClose());
  }

  /// `setPreventClose(true)` hands the window's close button to us, so the app
  /// has to shut itself down. A bare `exit(0)` killed the process before the
  /// app-level teardown could run — including the terminal playback report that
  /// trackers owning their own watched semantics depend on.
  Future<void> _exitOnWindowClose() async {
    try {
      await AppExitService.requestGracefulExit().timeout(const Duration(seconds: 5));
    } catch (e, st) {
      appLogger.w('Graceful window close failed; exiting immediately', error: e, stackTrace: st);
    }
    exit(0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Always consume: the gate latches backgrounding on every lifecycle event.
    final resumedFromBackground = _profileSelectionResumeGate.consumePromptOn(state);
    if (shouldShowProfileSelectionOnResume(
      resumedFromBackground: resumedFromBackground,
      isOffline: _isOffline,
      alreadyShowingProfileSelection: _isShowingProfileSelection,
      isMobilePlatform: Platform.isAndroid || Platform.isIOS,
      hasActiveVideoPlayback: VideoPlayerScreenState.activeGlobalKey != null,
    )) {
      _showProfileSelectionOnResume();
    }
  }

  Future<void> _showProfileSelectionOnResume() async {
    final settingsService = await SettingsService.getInstance();
    if (!mounted) return;

    if (!context.read<ActiveProfileProvider>().requiresSelectionOnOpen(settingsService)) return;

    await _pushProfileSelection();
  }

  /// IndexedStack that disables tickers for offscreen children to prevent
  /// animation controllers on non-visible tabs from scheduling frames.
  Widget _buildTickerAwareStack() {
    return Column(
      children: [
        const AuthErrorBanner(),
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < _screens.length; i++) TickerMode(enabled: i == _currentIndex, child: _screens[i]),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildScreens(bool offline) {
    return [
      for (final tab in _getVisibleTabs(offline))
        switch (tab.id) {
          NavigationTabId.discover => DiscoverScreen(key: _screenKeys[tab.id]),
          NavigationTabId.explore => ExploreScreen(key: _screenKeys[tab.id]),
          NavigationTabId.libraries => LibrariesScreen(
            key: _screenKeys[tab.id],
            onLibraryOrderChanged: _onLibraryOrderChanged,
            onLibrarySelected: _handleLibrariesScreenSelected,
          ),
          NavigationTabId.liveTv => LiveTvScreen(key: _screenKeys[tab.id]),
          NavigationTabId.search => SearchScreen(key: _screenKeys[tab.id]),
          NavigationTabId.downloads => DownloadsScreen(key: _screenKeys[tab.id]),
          NavigationTabId.settings => SettingsScreen(key: _screenKeys[tab.id]),
        },
    ];
  }

  /// Normalize tab ID when switching between offline/online modes.
  /// Preserves the current tab if it exists in the new mode, otherwise defaults to first tab.
  NavigationTabId _normalizeTabForMode(NavigationTabId currentTab, bool isOffline) {
    final tabs = _getVisibleTabs(isOffline);
    if (tabs.any((t) => t.id == currentTab)) return currentTab;
    return _defaultTabForMode(isOffline);
  }

  NavigationTabId _defaultTabForMode(bool isOffline) => NavigationTab.resolveDefaultTab(
    isOffline: isOffline,
    hasLiveTv: _hasLiveTv,
    hasExplore: _lastHasExplore,
    preferredStartup: SettingsService.instanceOrNull?.read(SettingsService.startupSection),
  );

  void _triggerReconnect() {
    if (_isReconnecting) return;
    setState(() => _isReconnecting = true);

    final multiServerProvider = context.read<MultiServerProvider>();
    final serverManager = multiServerProvider.serverManager;
    final activeProfile = context.read<ActiveProfileProvider>();
    final binder = context.read<ActiveProfileBinder>();
    unawaited(() async {
      try {
        binder.start();
        // Health check first so stale "online" servers get marked offline before
        // we snapshot the offline list for reconnection.
        await serverManager.checkServerHealth();
        await serverManager.reconnectOfflineServers(forceRediscovery: true);
        if (!mounted) return;
        if (shouldRetryActiveProfileBindAfterReconnect(
          hasActiveProfile: activeProfile.active != null,
          hasVisibleConnectedServers: multiServerProvider.hasConnectedServers,
          hasManagerOnlineServers: serverManager.onlineServerIds.isNotEmpty,
          hasKnownOfflineServers: serverManager.offlineServerIds.isNotEmpty,
        )) {
          await binder.rebindActive();
        }
        if (!mounted) return;
        if (multiServerProvider.hasConnectedServers) {
          _offlineUntilConnected = false;
          _handleOfflineStatusChanged();
        }
      } finally {
        setStateIfMounted(() => _isReconnecting = false);
      }
    }());
  }

  /// Rebuilds navigation after a tab's availability flipped: _currentTab may
  /// need normalizing, and passthrough depends on it being the first tab.
  void _handleTabAvailabilityChanged() {
    setState(() {
      _screens = _buildScreens(_isOffline);
      _currentTab = _normalizeTabForMode(_currentTab, _isOffline);
    });
    _updateTvosMenuPassthrough();
  }

  void _handleLiveTvChanged() {
    final hasLiveTv = _multiServerProvider?.hasLiveTv ?? false;
    if (hasLiveTv == _lastHasLiveTv) return;
    _lastHasLiveTv = hasLiveTv;

    _handleTabAvailabilityChanged();

    // A preferred startup section (only Live TV can be deferred) just became
    // available — switch to it via _selectTab so it gets the usual visibility
    // and focus handling. _selectTab clears _pendingStartupTab.
    final pending = _pendingStartupTab;
    if (pending != null && _getVisibleTabs(_isOffline).any((t) => t.id == pending)) {
      _selectTab(pending);
    }
  }

  bool get _showExploreTabSetting => SettingsService.instanceOrNull?.read(SettingsService.showExploreTab) ?? true;

  void _handleCatalogSourcesChanged() {
    final hasExplore = (_catalogSourcesProvider?.hasAnySource ?? false) && _showExploreTabSetting;
    if (hasExplore == _lastHasExplore) return;
    _lastHasExplore = hasExplore;

    _handleTabAvailabilityChanged();
  }

  void _handleOfflineStatusChanged() {
    final hasVisibleConnectedServers = context.read<MultiServerProvider>().hasConnectedServers;
    if (hasVisibleConnectedServers) _offlineUntilConnected = false;
    final providerOffline = _offlineModeProvider?.isOffline ?? false;
    final newOffline = shouldRenderMainScreenOffline(
      providerOffline: providerOffline,
      startupOfflineUntilConnected: _offlineUntilConnected,
      hasVisibleConnectedServers: hasVisibleConnectedServers,
    );

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
            previousTab != NavigationTabId.downloads && normalizedTab == NavigationTabId.downloads;
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
    _updateTvosMenuPassthrough();

    // Refresh sidebar focus after rebuilding navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sideNavKey.currentState?.focusActiveItem();
    });

    // Ensure profile settings are warmed when coming back online
    if (!_isOffline) {
      unawaited(() async {
        final mp = context.read<MultiServerProvider>();
        final binder = context.read<ActiveProfileBinder>();
        binder.start();
        if (!mp.hasConnectedServers && context.read<ActiveProfileProvider>().active != null) {
          await binder.rebindActive();
          if (!mounted) return;
        }
        await context.userProfile.initialize();
        if (!mounted) return;
        await _primeOnlineServices(mp.serverManager);
      }());
    }
  }

  void _focusSidebar() {
    // Capture target before requestFocus() auto-focuses a sidebar descendant
    // and overwrites lastFocusedKey (e.g. to the Libraries toggle button).
    final targetKey = _sideNavKey.currentState?.lastFocusedKey;
    setState(() => _isSidebarFocused = true);
    _updateTvosMenuPassthrough();
    _sidebarFocusScope.requestFocus();
    // Focus the active item after the focus scope has focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sideNavKey.currentState?.focusActiveItem(targetKey: targetKey);
    });
  }

  void _focusContent({bool restorePreviousFocus = true}) {
    setState(() => _isSidebarFocused = false);
    _updateTvosMenuPassthrough();
    if (restorePreviousFocus) {
      _contentFocusScope.requestFocus();
    }
    // Only programmatically focus if the scope didn't auto-restore a child.
    // This preserves the user's focus position when returning from sidebar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (restorePreviousFocus && _contentFocusScope.focusedChild != null) return;
      _onScreen<FocusableTab>(_currentTab, (screen) => screen.focusActiveTabIfReady());
    });
  }

  /// _isSidebarFocused is hand-toggled; if anything moves real focus into the
  /// content scope without going through _focusContent (e.g. a deferred
  /// focusActiveTabIfReady), collapse the rail to match reality (#1411).
  void _syncSidebarFocusWithContent() {
    if (!mounted || !_isSidebarFocused || !_contentFocusScope.hasFocus) return;
    setState(() => _isSidebarFocused = false);
    _updateTvosMenuPassthrough();
  }

  void _handleOverlaySheetOpenChanged(bool open) {
    if (_isOverlaySheetOpen == open) return;
    _isOverlaySheetOpen = open;
    _updateTvosMenuPassthrough();
  }

  double _sideNavigationWidth(BuildContext context, {required bool alwaysExpanded}) {
    final isExpanded = alwaysExpanded || _isSidebarFocused;
    return isExpanded
        ? SideNavigationRailState.expandedWidth
        : SideNavigationRailState.collapsedWidthForContext(context);
  }

  bool get _shouldPassTvosMenuToSystem {
    final tabs = _getVisibleTabs(_isOffline);
    return shouldPassTvosMenuToSystem(
      isAppleTV: PlatformDetector.isAppleTV(),
      isShowingProfileSelection: _isShowingProfileSelection,
      isOverlaySheetOpen: _isOverlaySheetOpen,
      isRouteCurrent: ModalRoute.of(context)?.isCurrent == true,
      isSidebarFocused: _isSidebarFocused,
      hasVisibleTabs: tabs.isNotEmpty,
      isCurrentTabRoot: tabs.isNotEmpty && _currentTab == tabs.first.id,
    );
  }

  void _setTvosMenuPassthrough(bool enabled) {
    if (!PlatformDetector.isAppleTV()) return;
    unawaited(TvosSystemNavigationService.setMenuPassthroughEnabled(enabled));
  }

  void _updateTvosMenuPassthrough() {
    if (!mounted) return;
    _setTvosMenuPassthrough(_shouldPassTvosMenuToSystem);
  }

  /// Suppress stray back events after a child route pops.
  /// On Android TV the platform popRoute can arrive before the key events,
  /// so BackKeySuppressorObserver misses them and they leak into _handleBackKey.
  bool _suppressBackAfterPop = false;

  KeyEventResult _handleMainBack() {
    final tabs = _getVisibleTabs(_isOffline);
    if (tabs.isEmpty) return KeyEventResult.handled;

    final homeTab = tabs.first.id;
    if (_currentTab != homeTab) {
      _selectTab(homeTab);
      // Keep the focus ring in step with the new selection; the sidebar scope
      // already has focus, so no post-frame deferral is needed.
      _sideNavKey.currentState?.focusHomeItem();
      _lastBackPressAt = null;
      return KeyEventResult.handled;
    }

    // The tvOS engine normally passes root Menu presses through to UIKit. If a
    // stale event still reaches Flutter, avoid showing an exit prompt that
    // cannot be honored app-side.
    if (PlatformDetector.isAppleTV()) {
      _lastBackPressAt = null;
      return KeyEventResult.handled;
    }

    final now = DateTime.now();
    final lastBackPressAt = _lastBackPressAt;
    if (lastBackPressAt != null && now.difference(lastBackPressAt) < _backExitWindow) {
      _lastBackPressAt = null;
      unawaited(AppExitService.requestExit());
      return KeyEventResult.handled;
    }

    _lastBackPressAt = now;
    showMainSnackBar(t.common.pressBackAgainToExit, duration: _backExitWindow);
    return KeyEventResult.handled;
  }

  KeyEventResult _handleMainBackKeyAction(KeyEvent event) {
    if (!event.logicalKey.isBackKey) return KeyEventResult.ignored;

    if (BackKeyUpSuppressor.consumeIfSuppressed(event)) {
      return KeyEventResult.handled;
    }

    // AppleTV: KeyDown does the work, KeyUp is consumed silently. See the
    // matching comment in handleBackKeyAction for why the suppressor pattern
    // doesn't fit here.
    if (PlatformDetector.isAppleTV() && event is KeyDownEvent) {
      final result = _handleMainBack();
      if (result == KeyEventResult.handled) {
        BackKeyCoordinator.markHandled();
      }
      return result;
    }
    if (PlatformDetector.isAppleTV() && event is KeyUpEvent) {
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      final result = _handleMainBack();
      if (result == KeyEventResult.handled) {
        BackKeyCoordinator.markHandled();
      }
      return result;
    }
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleBackKey(KeyEvent event) {
    if (ModalRoute.of(context)?.isCurrent != true) {
      return KeyEventResult.ignored;
    }

    if (_suppressBackAfterPop && event.logicalKey.isBackKey) {
      if (event is KeyUpEvent) _suppressBackAfterPop = false;
      return KeyEventResult.handled;
    }

    if (!_isSidebarFocused) {
      // Content focused → move to sidebar
      return handleBackKeyAction(event, _focusSidebar);
    }

    return _handleMainBackKeyAction(event);
  }

  /// F11 toggles OS fullscreen from anywhere in the main UI. The in-player
  /// hotkey (default `f`) only works while the player is mounted; this is
  /// the escape hatch when fullscreen persists after the player closes.
  KeyEventResult _handleFullscreenShortcut(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.f11) return KeyEventResult.ignored;
    if (!PlatformDetector.isDesktopOS()) return KeyEventResult.ignored;

    unawaited(FullscreenStateManager().toggleFullscreen());
    return KeyEventResult.handled;
  }

  /// Desktop physical-keyboard Escape at root Home is reserved for leaving
  /// window fullscreen; it never arms the press-back-again quit, so an Escape
  /// aimed at fullscreen can't close the app (#1748). Remotes, gamepad B, and
  /// system back keep the double-press exit path. On macOS this also keeps
  /// player Escape away from native fullscreen, which is window state shared
  /// by every route.
  KeyEventResult _handleDesktopRootEscape(KeyEvent event) {
    final tabs = _getVisibleTabs(_isOffline);
    final shouldHandle = shouldHandleDesktopRootEscape(
      isDesktop: PlatformDetector.isDesktopOS(),
      isPhysicalKeyboardEvent: event.isPhysicalKeyboardEvent,
      logicalKey: event.logicalKey,
      isCurrentRoute: ModalRoute.of(context)?.isCurrent == true,
      isHomeTab: tabs.isNotEmpty && _currentTab == tabs.first.id,
    );
    if (!shouldHandle) return KeyEventResult.ignored;

    if (event is KeyUpEvent) {
      BackKeyCoordinator.markHandled();
      unawaited(FullscreenStateManager().exitFullscreenIfActive());
    }
    return event is KeyDownEvent || event is KeyRepeatEvent || event is KeyUpEvent
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
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
      _onScreen<SearchInputFocusable>(NavigationTabId.search, (screen) => screen.focusSearchInput());
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
    _setTvosMenuPassthrough(false);
    // A pushed detail route covers the bottom bar — drop the mini-player to
    // the true (safe-area) bottom while it's hidden.
    _miniPlayerInsets?.setNavBarSuspended(true);
    // Called when a child route is pushed on top (e.g., video player)
    if (_currentTab == NavigationTabId.discover) {
      _onScreen<TabVisibilityAware>(NavigationTabId.discover, (screen) => screen.onTabHidden());
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
    _updateTvosMenuPassthrough();
    _miniPlayerInsets?.setNavBarSuspended(false);
    if (_currentTab == NavigationTabId.discover) {
      _onScreen<TabVisibilityAware>(NavigationTabId.discover, (screen) => screen.onTabShown());
      _onDiscoverBecameVisible();
    }
  }

  void _onDiscoverBecameVisible() {
    appLogger.d('Navigated to home');
    // Refresh content when returning to discover page
    _onScreen<Refreshable>(NavigationTabId.discover, (screen) => screen.refresh());
  }

  void _onLibraryOrderChanged() {
    // Refresh side navigation when library order changes
    _sideNavKey.currentState?.reloadLibraries();
  }

  /// Invalidate cached data across screens after a profile switch.
  /// The [ActiveProfileBinder] has already pushed fresh per-server tokens
  /// into [MultiServerManager], so this just clears UI caches and refreshes
  /// the visible screens.
  Future<void> _invalidateAllScreens() async {
    appLogger.d('Invalidating screen data after profile switch');

    final multiServerProvider = context.read<MultiServerProvider>();
    final hiddenLibrariesProvider = context.read<HiddenLibrariesProvider>();
    final librariesProvider = context.read<LibrariesProvider>();
    final playbackStateProvider = context.read<PlaybackStateProvider>();

    // Drop volatile API cache rows before screens kick off their refetch.
    // Pinned rows back offline downloads and must survive profile switches.
    try {
      await ApiCache.clearRegisteredVolatile();
    } catch (e, st) {
      appLogger.w('Failed to clear ApiCache on profile switch', error: e, stackTrace: st);
    }

    await hiddenLibrariesProvider.refresh();
    if (!mounted) return;

    librariesProvider.clear();

    if (multiServerProvider.serverManager.serverIds.isNotEmpty) {
      if (!mounted) return;
      context.read<OfflineWatchSyncService>().onServersConnected();
      // Profile switches re-bind connections — give DownloadProvider a chance
      // to repopulate metadata that the per-backend caches now resolve.
      unawaited(context.read<DownloadProvider>().refreshMetadataFromCache());
      librariesProvider.initialize(multiServerProvider.aggregationService);
      await librariesProvider.refresh();
    }

    playbackStateProvider.clearShuffle();

    _fullRefreshContentTabs();

    // Refresh user-level settings (audio/sub defaults) for the new identity.
    if (mounted) {
      unawaited(context.userProfile.refreshProfileSettings());
    }
  }

  void _selectTab(NavigationTabId tab, {bool focusSearchInput = true}) {
    // Guard: ignore if tab isn't available in current mode
    if (!_getVisibleTabs(_isOffline).any((t) => t.id == tab)) return;

    final previousTab = _currentTab;
    setState(() {
      _currentTab = tab;
      // An explicit selection cancels any deferred startup-section switch.
      _pendingStartupTab = null;
      if (!_isOffline) {
        _lastOnlineTabId = tab;
      } else if (previousTab != tab) {
        // User made an explicit offline selection, so don't auto-restore later.
        _autoSwitchedToDownloads = false;
      }
    });
    _updateTvosMenuPassthrough();

    if (previousTab != tab) {
      // Notify previous screen it's being hidden
      _onScreen<TabVisibilityAware>(previousTab, (screen) => screen.onTabHidden());
      // Notify and focus new screen
      _onScreen<TabVisibilityAware>(tab, (screen) => screen.onTabShown());
      // Back-to-home keeps the sidebar focused (chain: content → sidebar →
      // home → exit); stealing focus here left _isSidebarFocused stuck true
      // while real focus sat on a content card (#1411).
      // A companion-remote search (focusSearchInput: false) must NOT focus the
      // search input, since focusing it auto-opens the on-screen keyboard; the
      // query submit focuses results instead.
      if (!_isSidebarFocused && (tab != NavigationTabId.search || focusSearchInput)) {
        _onScreen<FocusableTab>(tab, (screen) => screen.focusActiveTabIfReady());
      }
    }

    // Discover: always refresh content (even on re-selection)
    if (!_isOffline && tab == NavigationTabId.discover) {
      _onDiscoverBecameVisible();
    }

    // Focus search input after rebuild so IndexedStack has made it visible.
    // Skipped for a companion-remote search (focusSearchInput: false), whose
    // submit runs the search and focuses results without opening the keyboard.
    if (tab == NavigationTabId.search && focusSearchInput) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onScreen<SearchInputFocusable>(NavigationTabId.search, (screen) => screen.focusSearchInput());
      });
    }
  }

  /// Handle library selection from side navigation rail
  void _selectLibrary(String libraryGlobalKey) {
    _selectedLibraryGlobalKey = libraryGlobalKey;
    _selectTab(NavigationTabId.libraries);
    // Tell LibrariesScreen to load this library after tab switch
    _onScreen<LibraryLoadable>(NavigationTabId.libraries, (screen) => screen.loadLibraryByKey(libraryGlobalKey));
    _onScreen<FocusableTab>(NavigationTabId.libraries, (screen) => screen.focusActiveTabIfReady());
  }

  void _openSettings() {
    if (PlatformDetector.shouldUseSideNavigation(context)) {
      _selectTab(NavigationTabId.settings);
      _focusContent(restorePreviousFocus: false);
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  void _handleLibrariesScreenSelected(String libraryGlobalKey) {
    if (_selectedLibraryGlobalKey == libraryGlobalKey) return;
    setState(() => _selectedLibraryGlobalKey = libraryGlobalKey);
  }

  void _showLibraryQuickPicker(BuildContext context) {
    if (_isOffline) return;

    final controller = OverlaySheetController.of(context);
    final groupByServer = SettingsService.instanceOrNull?.read(SettingsService.groupLibrariesByServer) ?? false;

    controller
        .show<String>(
          showDragHandle: true,
          builder: (sheetContext) {
            return Consumer2<LibrariesProvider, HiddenLibrariesProvider>(
              builder: (context, librariesProvider, hiddenLibrariesProvider, _) {
                if (!hiddenLibrariesProvider.isInitialized) {
                  return LibraryQuickPickerSheet(
                    libraries: const [],
                    selectedLibraryKey: _selectedLibraryGlobalKey,
                    isLoading: true,
                    groupByServer: groupByServer,
                    emptyMessage: t.libraries.noLibrariesFound,
                    onSelected: (libraryGlobalKey) => controller.close(libraryGlobalKey),
                  );
                }

                final allLibraries = librariesProvider.libraries;
                final hiddenKeys = hiddenLibrariesProvider.hiddenLibraryKeys;
                final visibleLibraries = allLibraries
                    .where((library) => !hiddenKeys.contains(library.globalKey))
                    .toList();
                final emptyMessage = allLibraries.isEmpty
                    ? t.libraries.noLibrariesFound
                    : t.libraries.allLibrariesHidden;

                return LibraryQuickPickerSheet(
                  libraries: visibleLibraries,
                  selectedLibraryKey: _selectedLibraryGlobalKey,
                  isLoading: librariesProvider.isLoading,
                  groupByServer: groupByServer,
                  emptyMessage: emptyMessage,
                  onSelected: (libraryGlobalKey) => controller.close(libraryGlobalKey),
                );
              },
            );
          },
        )
        .then((libraryGlobalKey) {
          if (!mounted || libraryGlobalKey == null) return;
          _selectLibrary(libraryGlobalKey);
        });
  }

  /// Whether the Live TV tab is currently visible
  /// Use the synchronized value so screens list and nav bar always agree.
  /// Updated by _handleLiveTvChanged when the provider notifies.
  bool get _hasLiveTv => _lastHasLiveTv;

  /// Get navigation tabs filtered by offline mode
  List<NavigationTab> _getVisibleTabs(bool isOffline) {
    return NavigationTab.getVisibleTabs(isOffline: isOffline, hasLiveTv: _hasLiveTv, hasExplore: _lastHasExplore);
  }

  List<NavigationTab> _getBottomNavigationTabs(BuildContext context) {
    return mainScreenBottomNavigationTabs(
      visibleTabs: _getVisibleTabs(_isOffline),
      isMobile: PlatformDetector.isMobile(context),
      isOffline: _isOffline,
      currentTab: _currentTab,
    );
  }

  /// Invoke [fn] on the tab's current [State] when it exists and implements
  /// the capability [T]. Screens are only built for visible tabs and mount a
  /// frame later, so a missing key or a non-matching state is a no-op.
  void _onScreen<T>(NavigationTabId tab, void Function(T state) fn) {
    if (_screenKeys[tab]?.currentState case final T state) fn(state);
  }

  /// Full-refresh the primary content tabs. Used by the profile-switch
  /// invalidation ([_invalidateAllScreens]), which must refetch everything for
  /// the new identity.
  void _fullRefreshContentTabs() {
    for (final tab in _contentTabs) {
      _onScreen<FullRefreshable>(tab, (screen) => screen.fullRefresh());
    }
  }

  /// Online-entry variant used by [_primeOnlineServices] on cold start and on
  /// reconnect-from-offline. Screens that already started their own load skip
  /// it; see [FullRefreshable.primeRefresh].
  void _primeContentTabs() {
    for (final tab in _contentTabs) {
      _onScreen<FullRefreshable>(tab, (screen) => screen.primeRefresh());
    }
  }

  static const _contentTabs = [NavigationTabId.discover, NavigationTabId.libraries, NavigationTabId.search];

  Widget _buildBottomNavigationBar(BuildContext context, {required bool hideLabels}) {
    final tabs = _getBottomNavigationTabs(context);
    final selectedIndex = tabs.indexWhere((tab) => tab.id == _currentTab);
    final navigationBar = NavigationBar(
      selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
      onDestinationSelected: (i) {
        if (i >= 0 && i < tabs.length) _selectTab(tabs[i].id);
      },
      labelBehavior: hideLabels
          ? NavigationDestinationLabelBehavior.alwaysHide
          : NavigationDestinationLabelBehavior.alwaysShow,
      destinations: tabs.map((tab) => tab.toDestination()).toList(),
    );

    final librariesIndex = tabs.indexWhere((tab) => tab.id == NavigationTabId.libraries);
    if (librariesIndex < 0 || tabs.isEmpty) return navigationBar;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return navigationBar;

        final itemWidth = constraints.maxWidth / tabs.length;
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final left = isRtl ? constraints.maxWidth - (itemWidth * (librariesIndex + 1)) : itemWidth * librariesIndex;

        return Stack(
          children: [
            navigationBar,
            Positioned(
              left: left,
              top: 0,
              bottom: 0,
              width: itemWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                excludeFromSemantics: true,
                onLongPress: () {
                  Feedback.forLongPress(context);
                  _showLibraryQuickPicker(context);
                },
                child: const SizedBox.expand(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Report the mobile bottom bar's rendered height to the mini-player inset
  /// controller after this frame (the bar mixes NavigationBar, optional
  /// offline banner, and label modes — measuring beats re-deriving).
  void _scheduleBottomBarMeasure() {
    final controller = _miniPlayerInsets;
    if (controller == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _bottomBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) controller.setNavBarInset(box.size.height);
    });
  }

  @override
  Widget build(BuildContext context) {
    final useSideNav = PlatformDetector.shouldUseSideNavigation(context);

    return _buildContent(context, useSideNav);
  }

  Widget _buildContent(BuildContext context, bool useSideNav) {
    if (useSideNav) {
      return SettingValueBuilder<bool>(
        pref: SettingsService.alwaysKeepSidebarOpen,
        builder: (context, alwaysExpanded, _) {
          final targetContentOffset = _sideNavigationWidth(context, alwaysExpanded: alwaysExpanded);
          final reservedContentOffset = alwaysExpanded
              ? SideNavigationRailState.expandedWidth
              : SideNavigationRailState.collapsedWidthForContext(context);

          return OverlaySheetHost(
            onOpenChanged: _handleOverlaySheetOpenChanged,
            // canPop:false blocks the system route-pop (matching the old inert
            // PopScope). The dpad/key back chain (content → top tabs → sidebar →
            // home) is owned entirely by the key path below; there is NO
            // onSystemBack because a pure popRoute must not short-circuit that
            // chain to home. The host still closes an open sheet on system back.
            canPop: false,
            child: Focus(
              onKeyEvent: (node, event) {
                final rootEscapeResult = _handleDesktopRootEscape(event);
                if (rootEscapeResult == KeyEventResult.handled) return rootEscapeResult;
                final fullscreenResult = _handleFullscreenShortcut(event);
                if (fullscreenResult == KeyEventResult.handled) return fullscreenResult;
                final searchResult = _handleSearchShortcut(event);
                if (searchResult == KeyEventResult.handled) return searchResult;
                return _handleBackKey(event);
              },
              child: TweenAnimationBuilder<double>(
                duration: SideNavigationRailState.expandDuration,
                curve: SideNavigationRailState.expandCurve,
                tween: Tween<double>(end: targetContentOffset),
                child: FocusScope(
                  node: _contentFocusScope,
                  // No autofocus - we control focus programmatically to prevent
                  // autofocus from stealing focus back after setState() rebuilds
                  child: _buildTickerAwareStack(),
                ),
                builder: (context, contentLeftPadding, contentChild) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final viewportWidth = constraints.maxWidth;
                      // Layout from the tween END value: deriving it from the
                      // animated value changed MainScreenFocusScope every tick
                      // of the sidebar expansion, rebuilding every dependent
                      // (the whole TV content tree) per frame. The slide is a
                      // paint-only translate on the content below instead.
                      final contentLayout = mainScreenSideNavigationContentLayout(
                        viewportWidth: viewportWidth,
                        currentSideNavigationWidth: targetContentOffset,
                        reservedSideNavigationWidth: reservedContentOffset,
                      );
                      return MainScreenFocusScope(
                        focusSidebar: _focusSidebar,
                        sideNavigationWidth: targetContentOffset,
                        reservedSideNavigationWidth: reservedContentOffset,
                        foregroundLeft: contentLayout.left,
                        foregroundWidth: contentLayout.width,
                        viewportWidth: viewportWidth,
                        selectLibrary: _selectLibrary,
                        openSettings: _openSettings,
                        child: SideNavigationScope(
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              Positioned.fill(child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor)),
                              Positioned(
                                top: 0,
                                bottom: 0,
                                left: contentLayout.left,
                                width: contentLayout.width,
                                // Duration/curve of this tween must stay in
                                // sync with SideNavigationBleedBuilder, which
                                // counter-animates viewport-pinned overlays.
                                child: Transform.translate(
                                  offset: Offset(contentLeftPadding - targetContentOffset, 0),
                                  child: contentChild!,
                                ),
                              ),
                              // Scrim behind the modal (hover/touch) rail
                              // overlay; purely visual so content stays
                              // interactive and hover-out still collapses.
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: AnimatedOpacity(
                                    opacity: _isSidebarInteractionExpanded ? 1.0 : 0.0,
                                    duration: SideNavigationRailState.expandDuration,
                                    curve: SideNavigationRailState.expandCurve,
                                    child: const ColoredBox(color: Color(0x66000000)),
                                  ),
                                ),
                              ),
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
                                      final restorePreviousFocus = tab == _currentTab;
                                      _selectTab(tab);
                                      _focusContent(restorePreviousFocus: restorePreviousFocus);
                                    },
                                    onLibrarySelected: (key) {
                                      _selectLibrary(key);
                                      _focusContent(restorePreviousFocus: false);
                                    },
                                    onNavigateToContent: _focusContent,
                                    onInteractionExpandedChanged: (expanded) {
                                      if (_isSidebarInteractionExpanded == expanded) return;
                                      setState(() => _isSidebarInteractionExpanded = expanded);
                                    },
                                    onReconnect: _triggerReconnect,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    }

    return OverlaySheetHost(
      onOpenChanged: _handleOverlaySheetOpenChanged,
      // Host owns sheet + system back; onSystemBack mirrors the old PopScope
      // (go to home tab, then press-back-twice to exit).
      canPop: false,
      onSystemBack: () {
        if (BackKeyCoordinator.consumeIfHandled()) return;
        _handleMainBack();
      },
      child: ScaffoldMessenger(
        key: ProfileNavigationScope.of(context).mainScaffoldMessengerKey,
        child: Scaffold(
          body: _buildTickerAwareStack(),
          bottomNavigationBar: Column(
            key: _bottomBarKey,
            mainAxisSize: .min,
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
                        mainAxisAlignment: .center,
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
                            AppIcon(Symbols.wifi_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            t.common.reconnect,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: .w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SettingValueBuilder<bool>(
                pref: SettingsService.showNavBarLabels,
                builder: (context, showNavBarLabels, _) {
                  final hideLabels = !showNavBarLabels;
                  // Re-measure whenever the bar's composition can change:
                  // this builder reruns on label toggles AND on every
                  // MainScreen rebuild (offline bar appearing/disappearing).
                  _scheduleBottomBarMeasure();
                  return NavigationBarTheme(
                    data: NavigationBarTheme.of(context).copyWith(height: hideLabels ? 56 : null),
                    child: _buildBottomNavigationBar(context, hideLabels: hideLabels),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
