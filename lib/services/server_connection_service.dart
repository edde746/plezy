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
    PlexConnection? firstConnection;
    final storage = await StorageService.getInstance();

    try {
      // Listen to the connection stream for progressive connection testing
      await for (final connection in server.findBestWorkingConnection()) {
        if (firstConnection == null) {
          // First emission - use this connection immediately
          firstConnection = connection;

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
          final config = await PlexConfig.create(
            baseUrl: connection.uri,
            token: server.accessToken,
            clientIdentifier: clientIdentifier,
          );
          final client = PlexClient(config);

          // Verify server is accessible if requested
          if (verifyServer) {
            try {
              await client.getServerIdentity();
            } catch (e) {
              appLogger.w('Server identity verification failed', error: e);
              await storage.clearCredentials();
              return ServerConnectionResult(
                error: 'Server is not accessible: $e',
              );
            }
          }

          // Fetch user profile if requested
          PlexUserProfile? userProfile;
          if (fetchUserProfile && plexToken != null) {
            userProfile = await _fetchUserProfile(plexToken);
          }

          // Return success result
          // Note: Stream continues in background to find better connection
          return ServerConnectionResult(
            client: client,
            userProfile: userProfile,
          );
        } else {
          // Second emission - better connection found
          // Update stored connection seamlessly for future app launches
          await storage.saveServerUrl(connection.uri);
          appLogger.d(
            'Switched to better connection: ${connection.displayType} (${connection.uri})',
          );
        }
      }

      // Handle case where no connections were found
      if (firstConnection == null) {
        return ServerConnectionResult(
          error: 'No working connections found for this server',
        );
      }

      // Should never reach here due to return in the stream loop
      return ServerConnectionResult(
        error: 'Unexpected error in connection flow',
      );
    } catch (e) {
      appLogger.e('Error connecting to server', error: e);
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
}
