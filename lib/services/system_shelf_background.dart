import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../connection/connection_registry.dart';
import '../database/app_database.dart';
import '../media/ids.dart';
import '../media/media_item.dart';
import '../media/media_server_client.dart';
import '../profiles/active_profile_binder.dart';
import '../profiles/active_profile_provider.dart';
import '../profiles/plex_home_service.dart';
import '../profiles/profile_connection_registry.dart';
import '../profiles/profile_registry.dart';
import '../providers/multi_server_provider.dart';
import '../utils/app_logger.dart';
import 'data_aggregation_service.dart';
import 'jellyfin_api_cache.dart';
import 'multi_server_manager.dart';
import 'plex_api_cache.dart';
import 'settings_service.dart';
import 'storage_service.dart';
import 'system_shelf_service.dart';

const MethodChannel _watchNextChannel = MethodChannel('com.plezy/watch_next');

/// Matches DiscoverProvider.continueWatchingPreviewLimit — the shelf mirrors
/// the Continue Watching preview row.
const int _shelfItemLimit = 20;

/// Android Watch Next background refresh entrypoint.
///
/// `ShelfRefreshWorker` runs this on a headless FlutterEngine via
/// `DartEntrypoint` while no UI engine is alive, so the launcher row keeps
/// tracking Continue Watching without the app in the foreground. The worker
/// resolves its result from the terminal `backgroundSyncComplete` call this
/// isolate always makes, and destroys the engine afterwards.
@pragma('vm:entry-point')
Future<void> systemShelfBackgroundMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await runSystemShelfBackgroundSync(
    readActiveProfileId: () async => (await StorageService.getInstance()).getActiveProfileId(),
    openSession: openProductionSystemShelfSession,
    reportCompletion: _reportCompletion,
  );
}

/// Everything the background sync needs from the app's cold-start stack once
/// the active profile is bound. Production wiring lives in
/// [openProductionSystemShelfSession]; tests inject handwritten fakes.
class SystemShelfBackgroundSession {
  SystemShelfBackgroundSession({
    required this.profileId,
    required this.fetchContinueWatching,
    required this.clientForServer,
    required this.hideSpoilers,
    required this.dispose,
  });

  /// Resolved owner id for the shelf session. May differ from the raw stored
  /// id when [ActiveProfileProvider] falls back during resolution; the shelf
  /// owner must match what the foreground app would publish under.
  final String profileId;
  final Future<List<MediaItem>> Function() fetchContinueWatching;
  final MediaServerClient? Function(ServerId serverId) clientForServer;
  final bool hideSpoilers;
  final Future<void> Function() dispose;
}

/// Core of the background refresh, seamed for tests.
///
/// Always calls [reportCompletion] exactly once — the native worker blocks on
/// that callback — and always disposes an opened session, success or not.
/// Returns the reported success value.
@visibleForTesting
Future<bool> runSystemShelfBackgroundSync({
  required Future<String?> Function() readActiveProfileId,
  required Future<SystemShelfBackgroundSession?> Function(String profileId) openSession,
  required Future<void> Function(bool success) reportCompletion,
  SystemShelfService? shelfService,
}) async {
  var success = false;
  SystemShelfBackgroundSession? session;
  try {
    final profileId = await readActiveProfileId();
    if (profileId == null || profileId.isEmpty) {
      appLogger.i('System shelf background sync skipped: no active profile');
      return false;
    }
    session = await openSession(profileId);
    if (session == null) return false;
    final openedSession = session;

    final items = await openedSession.fetchContinueWatching();
    final syncable = items
        .where((item) {
          final serverId = item.serverId;
          return serverId != null && openedSession.clientForServer(ServerId(serverId)) != null;
        })
        .toList(growable: false);

    final shelf = shelfService ?? SystemShelfService();
    shelf.beginProfileSession(openedSession.profileId);
    success = await shelf.syncFromContinueWatching(openedSession.profileId, syncable, (serverId) {
      final client = openedSession.clientForServer(serverId);
      if (client == null) throw StateError('No owning client available for $serverId');
      return client;
    }, hideSpoilers: openedSession.hideSpoilers);
  } catch (e, st) {
    appLogger.e('System shelf background sync failed', error: e, stackTrace: st);
    success = false;
  } finally {
    try {
      await session?.dispose();
    } catch (e, st) {
      appLogger.w('System shelf background session teardown failed', error: e, stackTrace: st);
    }
    await reportCompletion(success);
  }
  return success;
}

/// Builds the same stack `main.dart` assembles on cold start, minus UI:
/// database + registries, [MultiServerManager]/[MultiServerProvider],
/// [ActiveProfileProvider], and an [ActiveProfileBinder] whose PIN prompt
/// always declines — a background isolate must never prompt, so a protected
/// Plex Home profile simply fails its bind and this run completes false.
///
/// Returns null (after tearing down whatever was opened) when the device is
/// offline, no connections are stored, no profile resolves, or the bind fails.
Future<SystemShelfBackgroundSession?> openProductionSystemShelfSession(String profileId) async {
  // Mirror SetupScreen's offline fast path: with no network the binder would
  // only burn the worker's budget failing every connect. A probe failure is
  // treated as online, exactly like startup.
  try {
    final connectivity = await Connectivity().checkConnectivity().timeout(
      const Duration(seconds: 3),
      onTimeout: () => [ConnectivityResult.other],
    );
    if (connectivity.contains(ConnectivityResult.none)) {
      appLogger.i('System shelf background sync skipped: device is offline');
      return null;
    }
  } catch (_) {
    // connectivity_plus can throw on platforms without a network manager.
  }

  final storage = await StorageService.getInstance();
  final settings = await SettingsService.getInstance();
  final bootstrap = await AppDatabase.open();
  final database = bootstrap.database;

  MultiServerManager? serverManager;
  MultiServerProvider? multiServerProvider;
  ActiveProfileProvider? activeProfile;
  ActiveProfileBinder? binder;
  PlexHomeService? plexHome;

  Future<void> tearDown() async {
    binder?.dispose();
    multiServerProvider?.dispose();
    final manager = serverManager;
    if (manager != null) {
      await manager.disconnectAllGracefully();
      manager.dispose();
    }
    activeProfile?.dispose();
    await plexHome?.dispose();
    await database.close();
  }

  try {
    final connections = ConnectionRegistry(database);
    if ((await connections.list()).isEmpty) {
      appLogger.i('System shelf background sync skipped: no stored connections');
      await tearDown();
      return null;
    }

    PlexApiCache.initialize(database);
    JellyfinApiCache.initialize(database);

    final profileConnections = ProfileConnectionRegistry(database);
    final profileRegistry = ProfileRegistry(database);
    plexHome = PlexHomeService(connections: connections, profileConnections: profileConnections, storage: storage);
    await plexHome.start();

    activeProfile = ActiveProfileProvider(
      registry: profileRegistry,
      plexHome: plexHome,
      connections: connections,
      profileConnections: profileConnections,
      storage: storage,
    );
    await activeProfile.initialize();
    final resolvedProfileId = activeProfile.activeId;
    if (resolvedProfileId == null) {
      appLogger.i('System shelf background sync skipped: stored profile id did not resolve');
      await tearDown();
      return null;
    }

    serverManager = MultiServerManager();
    serverManager.onJellyfinConnectionUpdated = connections.upsert;
    final aggregation = DataAggregationService(serverManager);
    multiServerProvider = MultiServerProvider(serverManager, aggregation);

    binder = ActiveProfileBinder(
      activeProfile: activeProfile,
      connections: connections,
      profileConnections: profileConnections,
      serverManager: serverManager,
      multiServerProvider: multiServerProvider,
      pinPrompt: (profile, {errorMessage}) async => null,
    );
    binder.start();
    final bound = await activeProfile.awaitBindingSettle();
    if (!bound) {
      appLogger.w('System shelf background sync skipped: profile bind failed');
      await tearDown();
      return null;
    }
    final manager = serverManager;

    return SystemShelfBackgroundSession(
      profileId: resolvedProfileId,
      // Hidden-library filtering is deliberately skipped: it lives in the
      // profile-scoped HiddenLibrariesProvider subtree that only exists with
      // a UI session, and the foreground app re-syncs the shelf with the
      // filter applied on next launch, correcting any transient difference.
      fetchContinueWatching: () async => (await aggregation.getOnDeckFromAllServers(limit: _shelfItemLimit)).items,
      clientForServer: manager.getClient,
      hideSpoilers: settings.read(SettingsService.hideSpoilers),
      dispose: tearDown,
    );
  } catch (e) {
    await tearDown();
    rethrow;
  }
}

Future<void> _reportCompletion(bool success) async {
  try {
    await _watchNextChannel.invokeMethod<void>('backgroundSyncComplete', success);
  } catch (e) {
    appLogger.w('Failed to report background shelf sync completion', error: e);
  }
}
