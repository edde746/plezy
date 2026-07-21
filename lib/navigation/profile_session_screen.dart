import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connection/connection_registry.dart';
import '../focus/key_event_utils.dart';
import '../media/ids.dart';
import '../media/media_server_client.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/plex_home_service.dart';
import '../profiles/profile_connection_registry.dart';
import '../providers/catalog_sources_provider.dart';
import '../providers/companion_remote_provider.dart';
import '../providers/discover_provider.dart';
import '../providers/explore_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/libraries_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/playback_state_provider.dart';
import '../providers/trakt_account_provider.dart';
import '../providers/seerr_account_provider.dart';
import '../providers/trackers_provider.dart';
import '../providers/watch_state_store.dart';
import '../database/app_database.dart';
import '../screens/main_screen.dart';
import '../services/api_cache.dart';
import '../services/catalog/catalog_library_matcher.dart';
import '../services/music/music_playback_service.dart';
import '../services/music/music_playback_service_impl.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import '../watch_together/providers/watch_together_provider.dart';
import '../widgets/music/mini_player.dart';
import 'profile_navigation_scope.dart';

CatalogSourcesProvider _createCatalogSourcesProvider(BuildContext context) {
  return CatalogSourcesProvider(
    plexSessionSupplier: () => resolvePlexDiscoverSession(
      activeProfile: context.read<ActiveProfileProvider>(),
      connections: context.read<ConnectionRegistry>(),
      profileConnections: context.read<ProfileConnectionRegistry>(),
    ),
  );
}

/// Root route for an active profile session.
///
/// The root app navigator owns setup/auth/profile-picking. This route owns the
/// profile-scoped provider tree and a nested navigator for all content routes.
/// Changing the active profile changes the keyed boundary below, disposing the
/// old nested navigator, MainScreen, tab state, and profile-scoped providers.
///
/// Keep profile-owned routes, dialogs, sheets, and virtual keyboards on the
/// nearest navigator from this subtree. Keep setup/auth/PIN/profile-picker flows
/// on the root navigator so they survive this subtree being replaced.
class ProfileSessionScreen extends StatefulWidget {
  const ProfileSessionScreen({super.key, this.isOfflineMode = false, this.initialPromptHandled = false})
    : profileShellBuilder = null;

  @visibleForTesting
  const ProfileSessionScreen.forTesting({
    super.key,
    this.isOfflineMode = false,
    this.initialPromptHandled = false,
    required this.profileShellBuilder,
  });

  final bool isOfflineMode;
  final bool initialPromptHandled;
  final WidgetBuilder? profileShellBuilder;

  @override
  State<ProfileSessionScreen> createState() => _ProfileSessionScreenState();
}

class _ProfileSessionScreenState extends State<ProfileSessionScreen> {
  // Profile changes remount the inner session, but the root route survives.
  // Treat the initial launch/profile prompt as handled after the first session
  // frame so switching profiles from the root picker does not immediately open
  // another required-selection picker underneath it. Flipped via a post-frame
  // callback rather than during build to avoid mutating state mid-build.
  bool _hasBuiltSession = false;

  bool _seenFirstActiveId = false;
  String? _lastSessionActiveId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hasBuiltSession = true;
    });
  }

  /// The keyed remount below recreates every session-scoped provider on a
  /// profile switch, but [ApiCache] is app-global and its Plex rows are
  /// keyed by server only — one home user's cached responses would serve
  /// the next user's session. Clear the volatile rows at the seam itself;
  /// doing it from inside MainScreen can't work, the remount unmounts it
  /// before any settle-await completes.
  void _onSessionProfileChanged(String? activeId) {
    if (!_seenFirstActiveId) {
      _seenFirstActiveId = true;
      _lastSessionActiveId = activeId;
      return;
    }
    if (_lastSessionActiveId == activeId) return;
    _lastSessionActiveId = activeId;
    unawaited(ApiCache.clearRegisteredVolatile());
  }

  @override
  Widget build(BuildContext context) {
    return Selector<ActiveProfileProvider, String?>(
      selector: (_, activeProfile) => activeProfile.activeId,
      builder: (context, activeId, _) {
        _onSessionProfileChanged(activeId);
        final initialPromptHandled = widget.initialPromptHandled || _hasBuiltSession;
        return KeyedSubtree(
          key: ValueKey<String?>('profile-session:$activeId'),
          child: MultiProvider(
            providers: [
              ChangeNotifierProxyProvider<MultiServerProvider, WatchStateStore>(
                create: (_) => WatchStateStore(),
                update: (_, multiServer, previous) {
                  final provider = previous ?? WatchStateStore();
                  provider.setActiveProfileId(activeId);
                  provider.setActiveClientScopesByServer({
                    for (final serverId in multiServer.serverManager.serverIds)
                      serverId: multiServer.serverManager.getClient(ServerId(serverId))?.cacheServerId,
                  });
                  return provider;
                },
              ),
              ChangeNotifierProvider(
                create: (context) {
                  final provider = TraktAccountProvider();
                  unawaited(
                    provider.onActiveProfileChanged(activeId).catchError((Object e, StackTrace s) {
                      appLogger.w('Trakt profile hydrate failed', error: e, stackTrace: s);
                    }),
                  );
                  return provider;
                },
              ),
              ChangeNotifierProvider(
                create: (context) {
                  final provider = TrackersProvider();
                  unawaited(
                    provider.onActiveProfileChanged(activeId).catchError((Object e, StackTrace s) {
                      appLogger.w('Trackers profile hydrate failed', error: e, stackTrace: s);
                    }),
                  );
                  return provider;
                },
              ),
              ChangeNotifierProvider(
                create: (context) {
                  final provider = SeerrAccountProvider();
                  provider.bindPlexTokenSupplier(
                    buildSeerrPlexTokenSupplier(
                      activeProfile: context.read<ActiveProfileProvider>(),
                      connections: context.read<ConnectionRegistry>(),
                      profileConnections: context.read<ProfileConnectionRegistry>(),
                    ),
                  );
                  unawaited(
                    provider.onActiveProfileChanged(activeId).catchError((Object e, StackTrace s) {
                      appLogger.w('Seerr profile hydrate failed', error: e, stackTrace: s);
                    }),
                  );
                  return provider;
                },
              ),
              ChangeNotifierProxyProvider4<
                TraktAccountProvider,
                TrackersProvider,
                SeerrAccountProvider,
                ActiveProfileProvider,
                CatalogSourcesProvider
              >(
                create: (context) {
                  final provider = _createCatalogSourcesProvider(context);
                  unawaited(
                    provider.onActiveProfileChanged(activeId).catchError((Object e, StackTrace s) {
                      appLogger.w('Catalog sources profile hydrate failed', error: e, stackTrace: s);
                    }),
                  );
                  return provider;
                },
                update: (context, trakt, trackers, seerr, activeProfile, previous) {
                  final provider = previous ?? _createCatalogSourcesProvider(context);
                  provider.update(trakt, trackers, seerr);
                  unawaited(provider.onProfileBindingStateChanged(activeProfile.isBinding));
                  return provider;
                },
              ),
              ChangeNotifierProvider(
                create: (context) => ExploreProvider(context.read<CatalogSourcesProvider>()),
                lazy: true,
              ),
              Provider(create: (context) => CatalogLibraryMatcher(context.read<MultiServerProvider>()), lazy: true),
              ChangeNotifierProvider(
                create: (context) =>
                    HiddenLibrariesProvider(storageService: context.read<StorageService>(), profileId: activeId),
                lazy: true,
              ),
              ChangeNotifierProvider(
                create: (context) {
                  final activeProfile = context.read<ActiveProfileProvider>();
                  return LibrariesProvider(
                    storageService: context.read<StorageService>(),
                    multiServer: context.read<MultiServerProvider>(),
                    isProfileBinding: () => activeProfile.isBinding,
                  );
                },
              ),
              ChangeNotifierProvider(
                create: (context) {
                  final activeProfile = context.read<ActiveProfileProvider>();
                  return DiscoverProvider(
                    context.read<MultiServerProvider>(),
                    context.read<HiddenLibrariesProvider>(),
                    context.read<LibrariesProvider>(),
                    isProfileBinding: () => activeProfile.isBinding,
                  );
                },
              ),
              ChangeNotifierProvider(create: (context) => PlaybackStateProvider()),
              // Profile-session scope so a profile switch tears the music
              // session down (dispose stops playback + releases the audio
              // core).
              ChangeNotifierProvider<MusicPlaybackService>(
                create: (context) => MusicPlaybackServiceImpl(
                  serverManager: context.read<MultiServerProvider>().serverManager,
                  database: context.read<AppDatabase>(),
                  offlineWatchService: context.read<OfflineWatchSyncService>(),
                ),
              ),
              ChangeNotifierProvider(create: (context) => WatchTogetherProvider()),
              ChangeNotifierProvider(
                create: (context) {
                  final provider = CompanionRemoteProvider();
                  // Keep a running host's crypto identity live: a home user
                  // removed or a borrowed connection revoked mid-session must
                  // stop controlling the broadcast.
                  provider.bindProfileServices(
                    connections: context.read<ConnectionRegistry>(),
                    activeProfile: context.read<ActiveProfileProvider>(),
                    profileConnections: context.read<ProfileConnectionRegistry>(),
                    plexHome: context.read<PlexHomeService>(),
                  );
                  return provider;
                },
              ),
            ],
            child: _ProfileSessionNavigator(
              isOfflineMode: widget.isOfflineMode,
              initialPromptHandled: initialPromptHandled,
              profileShellBuilder: widget.profileShellBuilder,
            ),
          ),
        );
      },
    );
  }
}

class _ProfileSessionNavigator extends StatefulWidget {
  const _ProfileSessionNavigator({
    required this.isOfflineMode,
    required this.initialPromptHandled,
    required this.profileShellBuilder,
  });

  final bool isOfflineMode;
  final bool initialPromptHandled;
  final WidgetBuilder? profileShellBuilder;

  @override
  State<_ProfileSessionNavigator> createState() => _ProfileSessionNavigatorState();
}

class _ProfileSessionNavigatorState extends State<_ProfileSessionNavigator> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _mainScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _routeObserver = RouteObserver<PageRoute<dynamic>>();

  // Music mini-player wiring: the route observer hides the overlay while the
  // video player / now-playing screen is up; the inset controller lets
  // MainScreen report its bottom-bar height so the overlay floats above it.
  final _musicRouteObserver = MusicUiRouteObserver();
  final _miniPlayerInsets = MiniPlayerInsetController();

  @override
  void initState() {
    super.initState();
    profileNavigationRegistry.attachNavigator(_navigatorKey);
    profileNavigationRegistry.attachMainScaffoldMessenger(_mainScaffoldMessengerKey);
  }

  @override
  void dispose() {
    profileNavigationRegistry.detachNavigator(_navigatorKey);
    profileNavigationRegistry.detachMainScaffoldMessenger(_mainScaffoldMessengerKey);
    _miniPlayerInsets.dispose();
    _musicRouteObserver.suppress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileNavigationScope(
      navigatorKey: _navigatorKey,
      routeObserver: _routeObserver,
      mainScaffoldMessengerKey: _mainScaffoldMessengerKey,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          unawaited(_navigatorKey.currentState?.maybePop());
        },
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<MiniPlayerInsetController>.value(value: _miniPlayerInsets),
            Provider<MusicUiRouteObserver>.value(value: _musicRouteObserver),
          ],
          // The mini-player mounts ABOVE the nested navigator so it persists
          // across content routes (but inside the profile provider scope so
          // it dies with the session).
          child: Stack(
            children: [
              Navigator(
                key: _navigatorKey,
                observers: [_routeObserver, _musicRouteObserver, BackKeySuppressorObserver()],
                onGenerateRoute: _onGenerateRoute,
              ),
              const Positioned.fill(child: MusicMiniPlayerOverlay()),
            ],
          ),
        ),
      ),
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    // This navigator's initial route is the profile shell. Content routes are
    // pushed imperatively from inside the shell, so named routes belong to the
    // root navigator unless this method is expanded intentionally.
    final routeName = settings.name;
    if (routeName != null && routeName != Navigator.defaultRouteName) {
      throw FlutterError('ProfileSessionNavigator does not handle named route "$routeName".');
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) =>
          widget.profileShellBuilder?.call(context) ??
          MainScreen(isOfflineMode: widget.isOfflineMode, initialPromptHandled: widget.initialPromptHandled),
    );
  }
}
