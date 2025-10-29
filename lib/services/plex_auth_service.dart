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
  final String _clientIdentifier;

  PlexAuthService._(this._dio, this._clientIdentifier);

  static Future<PlexAuthService> create() async {
    final storage = await StorageService.getInstance();
    final dio = Dio();

    // Get or create client identifier
    String? clientIdentifier = storage.getClientIdentifier();
    if (clientIdentifier == null) {
      clientIdentifier = const Uuid().v4();
      await storage.saveClientIdentifier(clientIdentifier);
    }

    return PlexAuthService._(dio, clientIdentifier);
  }

  String get clientIdentifier => _clientIdentifier;

  Options _getCommonOptions({String? authToken}) {
    final headers = {
      'Accept': 'application/json',
      'X-Plex-Product': _appName,
      'X-Plex-Client-Identifier': _clientIdentifier,
    };

    if (authToken != null) {
      headers['X-Plex-Token'] = authToken;
    }

    return Options(headers: headers);
  }

  Future<Response> _getUser(String authToken) {
    return _dio.get(
      '$_plexApiBase/user',
      options: _getCommonOptions(authToken: authToken),
    );
  }

  /// Verify if a plex.tv token is valid
  Future<bool> verifyToken(String authToken) async {
    try {
      await _getUser(authToken);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Create a PIN for authentication
  Future<Map<String, dynamic>> createPin() async {
    final response = await _dio.post(
      '$_plexApiBase/pins?strong=true',
      options: _getCommonOptions(),
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
        options: _getCommonOptions(),
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
  Future<List<PlexServer>> fetchServers(String authToken) async {
    final response = await _dio.get(
      '$_clientsApi/resources?includeHttps=1&includeRelay=1&includeIPv6=1',
      options: _getCommonOptions(authToken: authToken),
    );

    final List<dynamic> resources = response.data as List<dynamic>;

    // Filter for server resources and map to PlexServer objects
    return resources
        .where((r) => r['provides'] == 'server')
        .map((r) => PlexServer.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Get user information
  Future<Map<String, dynamic>> getUserInfo(String authToken) async {
    final response = await _getUser(authToken);

    return response.data as Map<String, dynamic>;
  }

  /// Get user profile with preferences (audio/subtitle settings)
  Future<PlexUserProfile> getUserProfile(String authToken) async {
    final response = await _dio.get(
      '$_clientsApi/user',
      options: _getCommonOptions(authToken: authToken),
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

  PlexConnection? _selectBest(Iterable<PlexConnection> candidates) {
    final local = candidates.where((c) => c.local && !c.relay).toList();
    if (local.isNotEmpty) return local.first;

    final remote = candidates.where((c) => !c.local && !c.relay).toList();
    if (remote.isNotEmpty) return remote.first;

    final relay = candidates.where((c) => c.relay).toList();
    if (relay.isNotEmpty) return relay.first;

    if (candidates.isNotEmpty) return candidates.first;
    return null;
  }

  /// Get the best connection URL
  /// Priority: local > remote > relay
  PlexConnection? getBestConnection() {
    return _selectBest(connections);
  }

  PlexConnection? _findLowestLatency(
    List<MapEntry<PlexConnection, ConnectionTestResult>> entries,
  ) {
    if (entries.isEmpty) return null;
    final bestEntry = entries.reduce(
      (a, b) => a.value.latencyMs < b.value.latencyMs ? a : b,
    );
    return bestEntry.key;
  }

  PlexConnection? _selectBestWithLatency(
    Map<PlexConnection, ConnectionTestResult> results,
  ) {
    final localEntries = results.entries
        .where((e) => e.key.local && !e.key.relay)
        .toList();
    final remoteEntries = results.entries
        .where((e) => !e.key.local && !e.key.relay)
        .toList();
    final relayEntries = results.entries.where((e) => e.key.relay).toList();

    return _findLowestLatency(localEntries) ??
        _findLowestLatency(remoteEntries) ??
        _findLowestLatency(relayEntries);
  }

  /// Find the best working connection by testing them
  /// Returns a Stream that emits connections progressively:
  /// 1. First emission: The first connection that responds successfully
  /// 2. Second emission (optional): The best connection after latency testing
  /// Priority: local > remote > relay (from successful connections)
  Stream<PlexConnection> findBestWorkingConnection() async* {
    if (connections.isEmpty) return;

    // Phase 1: Race to find first working connection
    final completer = Completer<PlexConnection?>();
    PlexConnection? firstConnection;
    int completedTests = 0;

    // Start testing all connections simultaneously
    for (final connection in connections) {
      PlexClient.testConnectionWithLatency(connection.uri, accessToken).then((
        result,
      ) {
        completedTests++;

        // If this is the first successful connection, emit it immediately
        if (result.success && !completer.isCompleted) {
          completer.complete(connection);
        }

        // If all tests complete without success, complete with null
        if (completedTests == connections.length && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    // Wait for and emit the first successful connection
    firstConnection = await completer.future;
    if (firstConnection == null) {
      return; // No working connections found
    }

    yield firstConnection;

    // Phase 2: Continue testing in background to find best connection
    // Test each connection 2-3 times and average the latency
    final connectionResults = <PlexConnection, ConnectionTestResult>{};

    await Future.wait(
      connections.map((connection) async {
        final result = await PlexClient.testConnectionWithAverageLatency(
          connection.uri,
          accessToken,
          attempts: 2,
        );

        if (result.success) {
          connectionResults[connection] = result;
        }
      }),
    );

    // If no connections succeeded, we're done
    if (connectionResults.isEmpty) {
      return;
    }

    // Find the best connection considering both priority and latency
    final bestConnection = _selectBestWithLatency(connectionResults);

    // Emit the best connection if it's different from the first one
    if (bestConnection != null && bestConnection.uri != firstConnection.uri) {
      yield bestConnection;
    }
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
