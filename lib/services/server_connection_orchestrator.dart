import '../providers/libraries_provider.dart';
import '../providers/multi_server_provider.dart';
import '../utils/app_logger.dart';
import '../utils/connection_constants.dart';
import 'offline_watch_sync_service.dart';
import 'plex_auth_service.dart';
import 'plex_client.dart';

/// Result of a connection attempt to one or more servers.
class ConnectionResult {
  final int connectedCount;

  /// The first client that connected successfully, or null if none did.
  final PlexClient? firstClient;

  ConnectionResult({required this.connectedCount, this.firstClient});

  bool get hasConnections => connectedCount > 0;
}

/// Shared logic for connecting to saved servers, initializing libraries,
/// and triggering offline-watch sync.
///
/// Both [SetupScreen] and [AuthScreen] delegate to this helper so the
/// sequence isn't duplicated.  Navigation and error UI remain the caller's
/// responsibility.
class ServerConnectionOrchestrator {
  /// Connect to [servers], initialize libraries, and kick off sync.
  ///
  /// Returns a [ConnectionResult] so the caller can decide what to show.
  /// Throws only on unexpected errors; individual server failures are
  /// handled internally (logged + counted).
  static Future<ConnectionResult> connectAndInitialize({
    required List<PlexServer> servers,
    required MultiServerProvider multiServerProvider,
    required LibrariesProvider librariesProvider,
    required OfflineWatchSyncService syncService,
    String? clientIdentifier,
    Duration timeout = ConnectionTimeouts.connectAll,
  }) async {
    appLogger.i('Connecting to ${servers.length} servers...');

    final connectedCount = await multiServerProvider.serverManager.connectToAllServers(
      servers,
      clientIdentifier: clientIdentifier,
      timeout: timeout,
    );

    PlexClient? firstClient;

    if (connectedCount > 0) {
      appLogger.i('Successfully connected to $connectedCount servers');

      // Initialize and load libraries
      librariesProvider.initialize(multiServerProvider.aggregationService);
      try {
        await librariesProvider.loadLibraries();
      } catch (e) {
        appLogger.w('Failed to load libraries during connection', error: e);
        // Continue anyway — MainScreen will retry
      }

      // Trigger initial watch sync
      syncService.onServersConnected();

      // Grab first online client for backward-compat navigation
      final onlineClients = multiServerProvider.serverManager.onlineClients;
      if (onlineClients.isNotEmpty) {
        firstClient = onlineClients.values.first;
      }
    } else {
      appLogger.w('Failed to connect to any servers');
    }

    return ConnectionResult(connectedCount: connectedCount, firstClient: firstClient);
  }
}
