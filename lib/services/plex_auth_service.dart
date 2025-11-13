import 'dart:async';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'storage_service.dart';
import '../client/plex_client.dart';
import '../models/plex_user_profile.dart';
import '../models/plex_home.dart';
import '../models/user_switch_response.dart';

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
    final servers = <PlexServer>[];
    final invalidServers = <Map<String, dynamic>>[];

    for (final resource in resources.where((r) => r['provides'] == 'server')) {
      try {
        final server = PlexServer.fromJson(resource as Map<String, dynamic>);
        servers.add(server);
      } catch (e) {
        // Collect invalid servers for debugging
        invalidServers.add(resource as Map<String, dynamic>);
        continue;
      }
    }

    // If we have invalid servers but some valid ones, that's okay
    // If we have no valid servers but some invalid ones, throw with debug info
    if (servers.isEmpty && invalidServers.isNotEmpty) {
      throw ServerParsingException(
        'No valid servers found. All ${invalidServers.length} server(s) have malformed data.',
        invalidServers,
      );
    }

    return servers;
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

  /// Get home users for the authenticated user
  Future<PlexHome> getHomeUsers(String authToken) async {
    final response = await _dio.get(
      '$_clientsApi/home/users',
      options: _getCommonOptions(authToken: authToken),
    );

    return PlexHome.fromJson(response.data as Map<String, dynamic>);
  }

  /// Switch to a different user in the home
  Future<UserSwitchResponse> switchToUser(
    String userUUID,
    String currentToken, {
    String? pin,
  }) async {
    final queryParams = {
      'includeSubscriptions': '1',
      'includeProviders': '1',
      'includeSettings': '1',
      'includeSharedSettings': '1',
      'X-Plex-Product': _appName,
      'X-Plex-Version': '1.1.0',
      'X-Plex-Client-Identifier': _clientIdentifier,
      'X-Plex-Platform': 'Flutter',
      'X-Plex-Platform-Version': '3.8.1',
      'X-Plex-Token': currentToken,
      'X-Plex-Language': 'en',
      if (pin != null) 'pin': pin,
    };

    final queryString = queryParams.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    final response = await _dio.post(
      '$_clientsApi/home/users/$userUUID/switch?$queryString',
      options: Options(
        headers: {'Accept': 'application/json', 'Content-Length': '0'},
      ),
    );

    return UserSwitchResponse.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Helper class to track connection candidates during testing
class _ConnectionCandidate {
  final PlexConnection connection;
  final String url;
  final bool isPlexDirectUri;

  _ConnectionCandidate(this.connection, this.url, this.isPlexDirectUri);
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
    // Validate required fields first
    if (!_isValidServerJson(json)) {
      throw FormatException(
        'Invalid server data: missing required fields (name, clientIdentifier, accessToken, or connections)',
      );
    }

    final List<dynamic> connectionsJson = json['connections'] as List<dynamic>;
    final connections = <PlexConnection>[];

    // Parse connections and generate HTTP fallbacks for HTTPS connections
    for (final c in connectionsJson) {
      try {
        final connection = PlexConnection.fromJson(c as Map<String, dynamic>);
        connections.add(connection);

        // Generate HTTP fallback for HTTPS connections
        if (connection.protocol == 'https') {
          connections.add(connection.toHttpFallback());
        }
      } catch (e) {
        // Skip invalid connections rather than failing the entire server
        continue;
      }
    }

    // If no valid connections were parsed, this server is unusable
    if (connections.isEmpty) {
      throw FormatException('Server has no valid connections');
    }

    DateTime? lastSeenAt;
    if (json['lastSeenAt'] != null) {
      try {
        lastSeenAt = DateTime.parse(json['lastSeenAt'] as String);
      } catch (e) {
        lastSeenAt = null;
      }
    }

    return PlexServer(
      name: json['name'] as String, // Safe because validated above
      clientIdentifier:
          json['clientIdentifier'] as String, // Safe because validated above
      accessToken:
          json['accessToken'] as String, // Safe because validated above
      connections: connections,
      owned: json['owned'] as bool? ?? false,
      product: json['product'] as String?,
      platform: json['platform'] as String?,
      lastSeenAt: lastSeenAt,
      presence: json['presence'] as bool? ?? false,
    );
  }

  /// Validates that server JSON contains all required fields with correct types
  static bool _isValidServerJson(Map<String, dynamic> json) {
    // Check for required string fields
    if (json['name'] is! String || (json['name'] as String).isEmpty) {
      return false;
    }
    if (json['clientIdentifier'] is! String ||
        (json['clientIdentifier'] as String).isEmpty) {
      return false;
    }
    if (json['accessToken'] is! String ||
        (json['accessToken'] as String).isEmpty) {
      return false;
    }

    // Check for connections array
    if (json['connections'] is! List || (json['connections'] as List).isEmpty) {
      return false;
    }

    return true;
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

  /// Find the best working connection by testing them
  /// Returns a Stream that emits connections progressively:
  /// 1. First emission: The first connection that responds successfully
  /// 2. Second emission (optional): The best connection after latency testing
  /// Priority: local > remote > relay, then HTTPS > HTTP, then lowest latency
  /// Tests both plex.direct URI and direct IP for each connection
  /// HTTPS connections are tested first, with HTTP as fallback
  Stream<PlexConnection> findBestWorkingConnection() async* {
    if (connections.isEmpty) return;

    // Create candidates: test both uri and directUrl for each connection
    // Separate HTTPS and HTTP candidates to prioritize HTTPS first
    final httpsCandidates = <_ConnectionCandidate>[];
    final httpCandidates = <_ConnectionCandidate>[];

    for (final connection in connections) {
      final uriCandidate = _ConnectionCandidate(
        connection,
        connection.uri,
        true,
      );
      final directCandidate = _ConnectionCandidate(
        connection,
        connection.directUrl,
        false,
      );

      if (connection.protocol == 'https') {
        httpsCandidates.add(uriCandidate);
        httpsCandidates.add(directCandidate);
      } else {
        httpCandidates.add(uriCandidate);
        httpCandidates.add(directCandidate);
      }
    }

    // Combine candidates with HTTPS first, then HTTP
    final candidates = [...httpsCandidates, ...httpCandidates];

    // Phase 1: Race to find first working connection
    final completer = Completer<_ConnectionCandidate?>();
    _ConnectionCandidate? firstCandidate;
    int completedTests = 0;

    // Start testing all candidates simultaneously
    for (final candidate in candidates) {
      PlexClient.testConnectionWithLatency(candidate.url, accessToken).then((
        result,
      ) {
        completedTests++;

        // If this is the first successful connection, emit it immediately
        if (result.success && !completer.isCompleted) {
          completer.complete(candidate);
        }

        // If all tests complete without success, complete with null
        if (completedTests == candidates.length && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    // Wait for and emit the first successful connection
    firstCandidate = await completer.future;
    if (firstCandidate == null) {
      return; // No working connections found
    }

    // Update the connection object to use the working URL
    final firstConnection = _updateConnectionUrl(
      firstCandidate.connection,
      firstCandidate.url,
    );
    yield firstConnection;

    // Phase 2: Continue testing in background to find best connection
    // Test each candidate 2-3 times and average the latency
    final candidateResults = <_ConnectionCandidate, ConnectionTestResult>{};

    await Future.wait(
      candidates.map((candidate) async {
        final result = await PlexClient.testConnectionWithAverageLatency(
          candidate.url,
          accessToken,
          attempts: 2,
        );

        if (result.success) {
          candidateResults[candidate] = result;
        }
      }),
    );

    // If no connections succeeded, we're done
    if (candidateResults.isEmpty) {
      return;
    }

    // Find the best connection considering priority, latency, and URL type
    final bestCandidate = _selectBestCandidateWithLatency(candidateResults);

    // Emit the best connection if it's different from the first one
    if (bestCandidate != null) {
      final bestConnection = _updateConnectionUrl(
        bestCandidate.connection,
        bestCandidate.url,
      );
      if (bestConnection.uri != firstConnection.uri) {
        yield bestConnection;
      }
    }
  }

  /// Update a connection's URI to use the specified URL
  PlexConnection _updateConnectionUrl(PlexConnection connection, String url) {
    // If the URL matches the original URI, return as-is
    if (url == connection.uri) {
      return connection;
    }

    // Otherwise, create a new connection with the directUrl as the uri
    return PlexConnection(
      protocol: connection.protocol,
      address: connection.address,
      port: connection.port,
      uri: url,
      local: connection.local,
      relay: connection.relay,
      ipv6: connection.ipv6,
    );
  }

  /// Select the best candidate considering priority, latency, and URL type preference
  _ConnectionCandidate? _selectBestCandidateWithLatency(
    Map<_ConnectionCandidate, ConnectionTestResult> results,
  ) {
    // Group candidates by connection type (local/remote/relay)
    final localCandidates = results.entries
        .where((e) => e.key.connection.local && !e.key.connection.relay)
        .toList();
    final remoteCandidates = results.entries
        .where((e) => !e.key.connection.local && !e.key.connection.relay)
        .toList();
    final relayCandidates = results.entries
        .where((e) => e.key.connection.relay)
        .toList();

    // Find best in each category
    return _findLowestLatencyCandidate(localCandidates) ??
        _findLowestLatencyCandidate(remoteCandidates) ??
        _findLowestLatencyCandidate(relayCandidates);
  }

  /// Find the candidate with lowest latency, preferring HTTPS and plex.direct URI on tie
  _ConnectionCandidate? _findLowestLatencyCandidate(
    List<MapEntry<_ConnectionCandidate, ConnectionTestResult>> entries,
  ) {
    if (entries.isEmpty) return null;

    // Sort by latency first, then by protocol (HTTPS > HTTP), then by URL type (prefer plex.direct)
    entries.sort((a, b) {
      final latencyCompare = a.value.latencyMs.compareTo(b.value.latencyMs);
      if (latencyCompare != 0) return latencyCompare;

      // If latencies are equal, prefer HTTPS over HTTP
      final aIsHttps = a.key.connection.protocol == 'https';
      final bIsHttps = b.key.connection.protocol == 'https';
      if (aIsHttps && !bIsHttps) return -1;
      if (!aIsHttps && bIsHttps) return 1;

      // If latencies and protocols are equal, prefer plex.direct URI (isPlexDirectUri = true)
      if (a.key.isPlexDirectUri && !b.key.isPlexDirectUri) return -1;
      if (!a.key.isPlexDirectUri && b.key.isPlexDirectUri) return 1;
      return 0;
    });

    return entries.first.key;
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
    // Validate required fields
    if (!_isValidConnectionJson(json)) {
      throw FormatException(
        'Invalid connection data: missing required fields (protocol, address, port, or uri)',
      );
    }

    return PlexConnection(
      protocol: json['protocol'] as String, // Safe because validated above
      address: json['address'] as String, // Safe because validated above
      port: json['port'] as int, // Safe because validated above
      uri: json['uri'] as String, // Safe because validated above
      local: json['local'] as bool? ?? false,
      relay: json['relay'] as bool? ?? false,
      ipv6: json['IPv6'] as bool? ?? false,
    );
  }

  /// Validates that connection JSON contains all required fields with correct types
  static bool _isValidConnectionJson(Map<String, dynamic> json) {
    // Check for required string fields
    if (json['protocol'] is! String || (json['protocol'] as String).isEmpty) {
      return false;
    }
    if (json['address'] is! String || (json['address'] as String).isEmpty) {
      return false;
    }
    if (json['uri'] is! String || (json['uri'] as String).isEmpty) {
      return false;
    }

    // Check for required port (integer)
    if (json['port'] is! int) {
      return false;
    }

    return true;
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

  /// Get the direct URL constructed from address and port
  /// This bypasses plex.direct DNS and connects directly to the IP
  String get directUrl => '$protocol://$address:$port';

  String get displayType {
    if (relay) return 'Relay';
    if (local) return 'Local';
    return 'Remote';
  }

  /// Create an HTTP fallback version of this HTTPS connection
  /// This allows testing HTTP when HTTPS is unavailable (e.g., certificate issues)
  PlexConnection toHttpFallback() {
    assert(
      protocol == 'https',
      'Can only create HTTP fallback for HTTPS connections',
    );

    return PlexConnection(
      protocol: 'http',
      address: address,
      port: port,
      uri: uri.replaceFirst('https://', 'http://'),
      local: local,
      relay: relay,
      ipv6: ipv6,
    );
  }
}

/// Custom exception for server parsing errors that includes debug data
class ServerParsingException implements Exception {
  final String message;
  final List<Map<String, dynamic>> invalidServerData;

  ServerParsingException(this.message, this.invalidServerData);

  @override
  String toString() => message;
}
