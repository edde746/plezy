import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'plex_auth_service.dart';
import 'storage_service.dart';
import '../client/plex_client.dart';
import '../config/plex_config.dart';
import '../models/plex_user_profile.dart';
import '../utils/app_logger.dart';

/// Result of a server connection attempt
class ServerConnectionResult {
  final PlexClient? client;
  final PlexUserProfile? userProfile;
  final String? error;

  ServerConnectionResult({this.client, this.userProfile, this.error});

  bool get isSuccess => client != null;
}

/// Service for handling optimized server connections
/// Implements fast-first connection with background optimization
class ServerConnectionService {
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;
  static Future<void>? _activeOptimization;
  static PlexServer? _activeServer;
  static PlexClient? _activeClient;

  /// Connect to a Plex server with optimized connection testing
  ///
  /// Returns immediately with first working connection, then continues
  /// testing in background to find the optimal connection.
  ///
  /// Parameters:
  /// - [server]: The PlexServer to connect to
  /// - [clientIdentifier]: Client identifier for the PlexClient
  /// - [plexToken]: Optional plex.tv token to save to storage
  /// - [verifyServer]: Whether to verify server is accessible before returning
  /// - [fetchUserProfile]: Whether to fetch and cache user profile
  /// - [onProgress]: Callback for progress updates (e.g., show/hide loading)
  static Future<ServerConnectionResult> connectToServer(
    PlexServer server, {
    required String clientIdentifier,
    String? plexToken,
    bool verifyServer = false,
    bool fetchUserProfile = false,
    void Function(String message)? onProgress,
  }) async {
    final storage = await StorageService.getInstance();

    final connectionStream = server
        .findBestWorkingConnection()
        .asBroadcastStream();
    PlexClient? client;

    final optimizationSubscription = connectionStream
        .skip(1)
        .listen(
          (connection) async {
            await _handleOptimizedConnection(
              connection: connection,
              storage: storage,
              server: server,
              client: client,
              reason: 'initial_latency_sweep',
            );
          },
          onError: (error, stackTrace) {
            appLogger.w(
              'Background connection optimization error',
              error: error,
              stackTrace: stackTrace,
            );
          },
        );

    try {
      final connection = await connectionStream.first;

      if (onProgress != null) {
        onProgress('Connected to ${connection.displayType} endpoint');
      }

      // Save server information to storage
      await storage.saveServerData(server.toJson());
      await storage.saveServerUrl(connection.uri);
      await storage.saveServerAccessToken(server.accessToken);

      // Save plex token if provided
      if (plexToken != null) {
        await storage.savePlexToken(plexToken);
      }

      // Create client with working connection
      final prioritizedEndpoints = server.prioritizedEndpointUrls(
        preferredFirst: connection.uri,
      );
      final config = await PlexConfig.create(
        baseUrl: connection.uri,
        token: server.accessToken,
        clientIdentifier: clientIdentifier,
      );
      client = PlexClient(
        config,
        prioritizedEndpoints: prioritizedEndpoints,
        onEndpointChanged: (newUrl) async {
          await storage.saveServerUrl(newUrl);
          appLogger.i(
            'Updated stored server URL after failover',
            error: newUrl,
          );
        },
      );

      // Fetch machine identifier and cache it in config
      try {
        final machineId = await client.getMachineIdentifier();
        if (machineId != null) {
          client.config = config.copyWith(machineIdentifier: machineId);
          appLogger.d('Cached machine identifier: $machineId');
        }
      } catch (e) {
        appLogger.w('Failed to fetch machine identifier', error: e);
        // Continue without it - buildMetadataUri will fallback to fetching it
      }

      // Verify server is accessible if requested
      if (verifyServer) {
        try {
          await client.getServerIdentity();
        } catch (e) {
          await optimizationSubscription.cancel();
          appLogger.w('Server identity verification failed', error: e);
          await storage.clearCredentials();
          return ServerConnectionResult(error: 'Server is not accessible: $e');
        }
      }

      // Fetch user profile if requested
      PlexUserProfile? userProfile;
      if (fetchUserProfile && plexToken != null) {
        userProfile = await _fetchUserProfile(plexToken);
      }

      // Return success result while optimization continues in background
      _activeServer = server;
      _activeClient = client;
      _startConnectivityMonitoring(server);

      return ServerConnectionResult(client: client, userProfile: userProfile);
    } on StateError catch (e, stackTrace) {
      await optimizationSubscription.cancel();
      appLogger.e(
        'No working connections found for this server',
        error: e,
        stackTrace: stackTrace,
      );
      return ServerConnectionResult(
        error: 'No working connections found for this server',
      );
    } catch (e, stackTrace) {
      await optimizationSubscription.cancel();
      appLogger.e(
        'Error connecting to server',
        error: e,
        stackTrace: stackTrace,
      );
      return ServerConnectionResult(error: 'Connection failed: $e');
    }
  }

  /// Fetch user profile from Plex API
  static Future<PlexUserProfile?> _fetchUserProfile(String plexToken) async {
    appLogger.d('Fetching user profile from Plex API');
    try {
      final authService = await PlexAuthService.create();
      final profile = await authService.getUserProfile(plexToken);

      appLogger.i(
        'Successfully fetched user profile from API',
        error: {
          'autoSelectAudio': profile.autoSelectAudio,
          'defaultAudioLanguage': profile.defaultAudioLanguage ?? 'not set',
          'autoSelectSubtitle': profile.autoSelectSubtitle,
          'defaultSubtitleLanguage':
              profile.defaultSubtitleLanguage ?? 'not set',
          'defaultSubtitleForced': profile.defaultSubtitleForced,
        },
      );

      return profile;
    } catch (e) {
      appLogger.w('Failed to fetch user profile from API', error: e);
      return null;
    }
  }

  static void _startConnectivityMonitoring(PlexServer server) {
    _connectivitySubscription?.cancel();
    final connectivity = Connectivity();
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      (results) {
        final status = results.isNotEmpty
            ? results.first
            : ConnectivityResult.none;
        if (status == ConnectivityResult.none) {
          appLogger.w(
            'Connectivity lost, pausing optimization until network returns',
          );
          return;
        }
        appLogger.d(
          'Connectivity change detected, triggering endpoint optimization',
          error: {
            'status': status.name,
            'interfaces': results.map((r) => r.name).toList(),
          },
        );
        _activeServer = server;
        _triggerReoptimization(reason: 'connectivity:${status.name}');
      },
      onError: (error, stackTrace) {
        appLogger.w(
          'Connectivity listener error',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  static void _triggerReoptimization({required String reason}) {
    if (_activeServer == null) {
      appLogger.d(
        'Optimization trigger ignored because there is no active server',
        error: {'reason': reason},
      );
      return;
    }

    if (_activeOptimization != null) {
      appLogger.d(
        'Optimization already running, skipping new trigger',
        error: {'reason': reason},
      );
      return;
    }

    _activeOptimization =
        _runOptimization(
          server: _activeServer!,
          client: _activeClient,
          reason: reason,
        ).whenComplete(() {
          _activeOptimization = null;
        });
  }

  static Future<void> _runOptimization({
    required PlexServer server,
    required PlexClient? client,
    required String reason,
  }) async {
    final storage = await StorageService.getInstance();
    try {
      appLogger.d(
        'Starting background connection optimization run',
        error: {'reason': reason},
      );
      await for (final connection in server.findBestWorkingConnection()) {
        await _handleOptimizedConnection(
          connection: connection,
          storage: storage,
          server: server,
          client: client,
          reason: reason,
        );
      }
    } catch (e, stackTrace) {
      appLogger.w(
        'Background connection optimization failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> _handleOptimizedConnection({
    required PlexConnection connection,
    required StorageService storage,
    required PlexServer server,
    required PlexClient? client,
    required String reason,
  }) async {
    final previousUrl = storage.getServerUrl();
    final isNewEndpoint = previousUrl != connection.uri;

    await storage.saveServerUrl(connection.uri);
    appLogger.d(
      'Evaluated optimized endpoint candidate',
      error: {
        'uri': connection.uri,
        'displayType': connection.displayType,
        'reason': reason,
        'isNewEndpoint': isNewEndpoint,
      },
    );

    if (client != null) {
      final prioritizedEndpoints = server.prioritizedEndpointUrls(
        preferredFirst: connection.uri,
      );
      await client.updateEndpointPreferences(
        prioritizedEndpoints,
        switchToFirst: isNewEndpoint,
      );
      if (isNewEndpoint) {
        appLogger.i(
          'Active client switched to optimized endpoint',
          error: {'uri': connection.uri, 'reason': reason},
        );
      }
    } else if (isNewEndpoint) {
      appLogger.i(
        'Stored optimized endpoint for future sessions',
        error: {'uri': connection.uri, 'reason': reason},
      );
    }

    if (isNewEndpoint && !connection.uri.startsWith('https://')) {
      final upgraded = await server.upgradeConnectionToHttps(connection);
      if (upgraded != null && upgraded.uri != connection.uri) {
        await _handleOptimizedConnection(
          connection: upgraded,
          storage: storage,
          server: server,
          client: client,
          reason: '$reason:https-upgrade',
        );
      }
    }
  }
}
