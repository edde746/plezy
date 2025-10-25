import 'dart:async';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'storage_service.dart';
import '../client/plex_client.dart';
import '../models/plex_user_profile.dart';

class PlexAuthService {
  static const String _appName = 'Plezy';
  static const String _plexApiBase = 'https://plex.tv/api/v2';
  static const String _clientsApi = 'https://clients.plex.tv/api/v2';

  final Dio _dio;
  late final String _clientIdentifier;

  PlexAuthService._(this._dio, this._clientIdentifier);

  static Future<PlexAuthService> create() async {
    final storage = await StorageService.getInstance();
    final dio = Dio();

    // Get or create client identifier
    String? clientId = storage.getClientIdentifier();
    if (clientId == null) {
      clientId = const Uuid().v4();
      await storage.saveClientIdentifier(clientId);
    }

    return PlexAuthService._(dio, clientId);
  }

  String get clientIdentifier => _clientIdentifier;

  /// Verify if a plex.tv token is valid
  Future<bool> verifyToken(String token) async {
    try {
      final response = await _dio.get(
        '$_plexApiBase/user',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'X-Plex-Product': _appName,
            'X-Plex-Client-Identifier': _clientIdentifier,
            'X-Plex-Token': token,
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Create a PIN for authentication
  Future<Map<String, dynamic>> createPin() async {
    final response = await _dio.post(
      '$_plexApiBase/pins?strong=true',
      options: Options(
        headers: {
          'Accept': 'application/json',
          'X-Plex-Product': _appName,
          'X-Plex-Client-Identifier': _clientIdentifier,
        },
      ),
    );

    return response.data as Map<String, dynamic>;
  }

  /// Construct the Auth App URL for the user to visit
  String getAuthUrl(String pinCode) {
    final params = {
      'clientID': _clientIdentifier,
      'code': pinCode,
      'context[device][product]': _appName,
    };

    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return 'https://app.plex.tv/auth#?$queryString';
  }

  /// Poll the PIN to check if it has been claimed
  Future<String?> checkPin(int pinId) async {
    try {
      final response = await _dio.get(
        '$_plexApiBase/pins/$pinId',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'X-Plex-Client-Identifier': _clientIdentifier,
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      return data['authToken'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Poll the PIN until it's claimed or timeout
  Future<String?> pollPinUntilClaimed(
    int pinId, {
    Duration timeout = const Duration(minutes: 2),
    bool Function()? shouldCancel,
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      // Check if polling should be cancelled
      if (shouldCancel != null && shouldCancel()) {
        return null;
      }

      final token = await checkPin(pinId);
      if (token != null) {
        return token;
      }

      // Wait 1 second before polling again
      await Future.delayed(const Duration(seconds: 1));
    }

    return null; // Timeout
  }

  /// Fetch available Plex servers for the authenticated user
  Future<List<PlexServer>> fetchServers(String plexToken) async {
    final response = await _dio.get(
      '$_clientsApi/resources?includeHttps=1&includeRelay=1&includeIPv6=1',
      options: Options(
        headers: {
          'Accept': 'application/json',
          'X-Plex-Product': _appName,
          'X-Plex-Client-Identifier': _clientIdentifier,
          'X-Plex-Token': plexToken,
        },
      ),
    );

    final List<dynamic> resources = response.data as List<dynamic>;

    // Filter for server resources and map to PlexServer objects
    return resources
        .where((r) => r['provides'] == 'server')
        .map((r) => PlexServer.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Get user information
  Future<Map<String, dynamic>> getUserInfo(String token) async {
    final response = await _dio.get(
      '$_plexApiBase/user',
      options: Options(
        headers: {
          'Accept': 'application/json',
          'X-Plex-Product': _appName,
          'X-Plex-Client-Identifier': _clientIdentifier,
          'X-Plex-Token': token,
        },
      ),
    );

    return response.data as Map<String, dynamic>;
  }

  /// Get user profile with preferences (audio/subtitle settings)
  Future<PlexUserProfile> getUserProfile(String token) async {
    final response = await _dio.get(
      '$_clientsApi/user',
      options: Options(
        headers: {
          'Accept': 'application/json',
          'X-Plex-Product': _appName,
          'X-Plex-Client-Identifier': _clientIdentifier,
          'X-Plex-Token': token,
        },
      ),
    );

    return PlexUserProfile.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Represents a Plex Media Server
class PlexServer {
  final String name;
  final String clientIdentifier;
  final String accessToken;
  final List<PlexConnection> connections;
  final bool owned;
  final String? product;
  final String? platform;
  final DateTime? lastSeenAt;
  final bool presence;

  PlexServer({
    required this.name,
    required this.clientIdentifier,
    required this.accessToken,
    required this.connections,
    required this.owned,
    this.product,
    this.platform,
    this.lastSeenAt,
    this.presence = false,
  });

  factory PlexServer.fromJson(Map<String, dynamic> json) {
    final List<dynamic> connectionsJson = json['connections'] as List<dynamic>;
    final connections = connectionsJson
        .map((c) => PlexConnection.fromJson(c as Map<String, dynamic>))
        .toList();

    DateTime? lastSeenAt;
    if (json['lastSeenAt'] != null) {
      try {
        lastSeenAt = DateTime.parse(json['lastSeenAt'] as String);
      } catch (e) {
        lastSeenAt = null;
      }
    }

    return PlexServer(
      name: json['name'] as String,
      clientIdentifier: json['clientIdentifier'] as String,
      accessToken: json['accessToken'] as String,
      connections: connections,
      owned: json['owned'] as bool? ?? false,
      product: json['product'] as String?,
      platform: json['platform'] as String?,
      lastSeenAt: lastSeenAt,
      presence: json['presence'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'clientIdentifier': clientIdentifier,
      'accessToken': accessToken,
      'connections': connections.map((c) => c.toJson()).toList(),
      'owned': owned,
      'product': product,
      'platform': platform,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'presence': presence,
    };
  }

  /// Check if server is online using the presence field
  bool get isOnline => presence;

  /// Get the best connection URL
  /// Priority: local > remote > relay
  PlexConnection? getBestConnection() {
    if (connections.isEmpty) return null;

    // Try to find local connection first
    final local = connections.where((c) => c.local && !c.relay).toList();
    if (local.isNotEmpty) return local.first;

    // Try remote (non-relay) connection
    final remote = connections.where((c) => !c.local && !c.relay).toList();
    if (remote.isNotEmpty) return remote.first;

    // Fall back to relay as last resort
    final relay = connections.where((c) => c.relay).toList();
    if (relay.isNotEmpty) return relay.first;

    // Return any connection
    return connections.first;
  }

  /// Find the best working connection by testing them
  /// Tests ALL connections simultaneously and returns the best working one
  /// Priority: local > remote > relay (from successful connections)
  Future<PlexConnection?> findBestWorkingConnection() async {
    if (connections.isEmpty) return null;

    // Test all connections simultaneously
    final results = await Future.wait(
      connections.map((connection) async {
        final works = await PlexClient.testConnectionUrl(
          connection.uri,
          accessToken,
        );
        return works ? connection : null;
      }),
    );

    // Filter out failed connections
    final workingConnections = results
        .where((c) => c != null)
        .cast<PlexConnection>()
        .toList();

    if (workingConnections.isEmpty) return null;

    // From working connections, prefer local > remote > relay
    final localWorking = workingConnections
        .where((c) => c.local && !c.relay)
        .toList();
    if (localWorking.isNotEmpty) return localWorking.first;

    final remoteWorking = workingConnections
        .where((c) => !c.local && !c.relay)
        .toList();
    if (remoteWorking.isNotEmpty) return remoteWorking.first;

    final relayWorking = workingConnections.where((c) => c.relay).toList();
    if (relayWorking.isNotEmpty) return relayWorking.first;

    // Fallback to any working connection
    return workingConnections.first;
  }
}

/// Represents a connection to a Plex server
class PlexConnection {
  final String protocol;
  final String address;
  final int port;
  final String uri;
  final bool local;
  final bool relay;
  final bool ipv6;

  PlexConnection({
    required this.protocol,
    required this.address,
    required this.port,
    required this.uri,
    required this.local,
    required this.relay,
    required this.ipv6,
  });

  factory PlexConnection.fromJson(Map<String, dynamic> json) {
    return PlexConnection(
      protocol: json['protocol'] as String,
      address: json['address'] as String,
      port: json['port'] as int,
      uri: json['uri'] as String,
      local: json['local'] as bool? ?? false,
      relay: json['relay'] as bool? ?? false,
      ipv6: json['IPv6'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protocol': protocol,
      'address': address,
      'port': port,
      'uri': uri,
      'local': local,
      'relay': relay,
      'IPv6': ipv6,
    };
  }

  String get displayType {
    if (relay) return 'Relay';
    if (local) return 'Local';
    return 'Remote';
  }
}
