import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../focus/key_event_utils.dart';
import '../media/ids.dart';
import '../media/media_server_client.dart';
import '../profiles/active_profile_provider.dart';
import '../providers/companion_remote_provider.dart';
import '../providers/discover_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/libraries_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/playback_state_provider.dart';
import '../providers/trakt_account_provider.dart';
import '../providers/trackers_provider.dart';
import '../providers/watch_state_store.dart';
import '../screens/main_screen.dart';
import '../services/storage_service.dart';
import '../utils/app_logger.dart';
import '../watch_together/providers/watch_together_provider.dart';
import 'profile_navigation_scope.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hasBuiltSession = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveProfileProvider>(
      builder: (context, activeProfile, _) {
        final activeId = activeProfile.activeId;
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
                create: (context) =>
                    HiddenLibrariesProvider(storageService: context.read<StorageService>(), profileId: activeId),
                lazy: true,
              ),
              ChangeNotifierProvider(
                create: (context) => LibrariesProvider(
                  storageService: context.read<StorageService>(),
                  multiServer: context.read<MultiServerProvider>(),
                ),
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
              ChangeNotifierProvider(create: (context) => WatchTogetherProvider()),
              ChangeNotifierProvider(create: (context) => CompanionRemoteProvider()),
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
        child: Navigator(
          key: _navigatorKey,
          observers: [_routeObserver, BackKeySuppressorObserver()],
          onGenerateRoute: _onGenerateRoute,
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
