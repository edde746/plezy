import 'dart:async';
import 'dart:io' show InternetAddress, InternetAddressType, Platform;
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'storage_service.dart';
import 'plex_client.dart';
import '../exceptions/media_server_exceptions.dart';
import '../models/plex/plex_user_profile.dart';
import '../models/plex/plex_home.dart';
import '../models/user_switch_response.dart';
import '../utils/app_logger.dart';
import '../utils/endpoint_race.dart';
import '../utils/media_server_timeouts.dart';
import '../utils/media_server_http_client.dart';
import '../utils/poll_with_backoff.dart';

/// Redacts the middle of an IP address or hostname for safe logging.
/// E.g. `192.168.1.50` → `192.***.***.50`, `my.server.example.com` → `my.***.***. com`.
String _redactHost(String host) {
  // Strip brackets from IPv6
  final bare = host.startsWith('[') && host.endsWith(']') ? host.substring(1, host.length - 1) : host;

  // IPv6
  if (bare.contains(':')) {
    final parts = bare.split(':');
    if (parts.length > 2) {
      return '${parts.first}:***:${parts.last}';
    }
    return bare;
  }

  // IPv4
  final ipParts = bare.split('.');
  if (ipParts.length == 4 && ipParts.every((p) => int.tryParse(p) != null)) {
    return '${ipParts.first}.***.***.${ipParts.last}';
  }

  // Hostname
  final hostParts = bare.split('.');
  if (hostParts.length >= 3) {
    return '${hostParts.first}.***.${hostParts.last}';
  }

  return bare;
}

class PlexAuthService {
  static const String _appName = 'Vibe';
  static const String _plexApiBase = 'https://plex.tv/api/v2';
  static const String _clientsApi = 'https://clients.plex.tv/api/v2';

  final MediaServerHttpClient _http;
  final String _clientIdentifier;
  final String _appVersion;
  final String _platformVersion;

  PlexAuthService._(this._http, this._clientIdentifier, this._appVersion, this._platformVersion);

  @visibleForTesting
  PlexAuthService.forTesting({
    required MediaServerHttpClient http,
    String clientIdentifier = 'test-client',
    String appVersion = 'test',
    String platformVersion = 'test',
  }) : this._(http, clientIdentifier, appVersion, platformVersion);

  /// Close the underlying HTTP client. Call when the service is short-lived
  /// (created for a single API call) to avoid leaking sockets.
  void dispose() => _http.close();

  static Future<PlexAuthService> create() async {
    final storage = await StorageService.getInstance();
    final http = MediaServerHttpClient(
      connectTimeout: MediaServerTimeouts.plexTvConnect,
      receiveTimeout: MediaServerTimeouts.plexTvReceive,
    );
    final clientIdentifier = await storage.getOrCreateClientIdentifier();
    final packageInfo = await PackageInfo.fromPlatform();
    return PlexAuthService._(http, clientIdentifier, packageInfo.version, Platform.operatingSystemVersion);
  }

  String get clientIdentifier => _clientIdentifier;

  Map<String, String> _getCommonHeaders({String? authToken}) {
    final headers = {
      'Accept': 'application/json',
      'X-Plex-Product': _appName,
      'X-Plex-Client-Identifier': _clientIdentifier,
    };

    if (authToken != null) {
      headers['X-Plex-Token'] = authToken;
    }

    return headers;
  }

  Future<MediaServerResponse> _getUser(String authToken) {
    return _http.get(
      '$_plexApiBase/user',
      headers: _getCommonHeaders(authToken: authToken),
      timeout: MediaServerTimeouts.plexTvReceive,
    );
  }

  void _checkStatus(MediaServerResponse response) => throwIfHttpError(response);

  Future<MediaServerResponse> _getClientsApi(String path, {Map<String, String>? headers, Duration? timeout}) async {
    try {
      return await _http.get('$_clientsApi$path', headers: headers, timeout: timeout);
    } on MediaServerHttpException catch (e) {
      if (!e.isTransient) rethrow;
      appLogger.w('Plex clients API request failed; retrying via plex.tv', error: {'path': path, 'type': e.type.name});
      return _http.get('$_plexApiBase$path', headers: headers, timeout: timeout);
    }
  }

  /// Verify if a plex.tv token is valid
  Future<bool> verifyToken(String authToken) async {
    final response = await _getUser(authToken);
    if (response.statusCode == 200) return true;
    if (response.statusCode == 401 || response.statusCode == 403) return false;
    _checkStatus(response);
    return false;
  }

  /// Create a PIN for authentication
  Future<Map<String, dynamic>> createPin() async {
    final response = await _http.post(
      '$_plexApiBase/pins?strong=true',
      headers: _getCommonHeaders(),
      timeout: MediaServerTimeouts.plexTvReceive,
    );
    _checkStatus(response);
    return response.data as Map<String, dynamic>;
  }

  /// Construct the Auth App URL for the user to visit
  String getAuthUrl(String pinCode) {
    final params = {'clientID': _clientIdentifier, 'code': pinCode, 'context[device][product]': _appName};

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'https://app.plex.tv/auth#?$queryString';
  }

  /// Poll the PIN to check if it has been claimed
  Future<String?> checkPin(int pinId) async {
    final response = await _http.get(
      '$_plexApiBase/pins/$pinId',
      headers: _getCommonHeaders(),
      timeout: MediaServerTimeouts.plexTvReceive,
    );

    if (response.statusCode == 404 || response.statusCode == 410) {
      throw const MediaServerPinExpiredException();
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw MediaServerAuthException('Plex PIN check rejected', statusCode: response.statusCode);
    }
    _checkStatus(response);

    final data = response.data as Map<String, dynamic>;
    return data['authToken'] as String?;
  }

  /// Poll the PIN until it's claimed or timeout.
  ///
  /// Uses an exponential backoff (1s → 2s → 4s, capped at 5s) so a stalled
  /// claim doesn't hammer plex.tv every second for two minutes.
  Future<String?> pollPinUntilClaimed(
    int pinId, {
    Duration timeout = const Duration(minutes: 2),
    bool Function()? shouldCancel,
  }) {
    return pollWithBackoff<String>(
      probe: () => checkPin(pinId),
      endTime: DateTime.now().add(timeout),
      shouldCancel: shouldCancel,
    );
  }

  /// Fetch available Plex servers for the authenticated user
  Future<List<PlexServer>> fetchServers(String authToken) async {
    final response = await _getClientsApi(
      '/resources?includeHttps=1&includeRelay=1&includeIPv6=1',
      headers: _getCommonHeaders(authToken: authToken),
    );

    _checkStatus(response);

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
    _checkStatus(response);
    return response.data as Map<String, dynamic>;
  }

  /// Get user profile with preferences (audio/subtitle settings)
  Future<PlexUserProfile> getUserProfile(String authToken) async {
    final response = await _getClientsApi('/user', headers: _getCommonHeaders(authToken: authToken));
    _checkStatus(response);
    return PlexUserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get home users for the authenticated user
  Future<PlexHome> getHomeUsers(String authToken) async {
    final response = await _getClientsApi('/home/users', headers: _getCommonHeaders(authToken: authToken));
    _checkStatus(response);
    return PlexHome.fromJson(response.data as Map<String, dynamic>);
  }

  /// Switch to a different user in the home
  Future<UserSwitchResponse> switchToUser(String userUUID, String currentToken, {String? pin}) async {
    final queryParams = {
      'includeSubscriptions': '1',
      'includeProviders': '1',
      'includeSettings': '1',
      'includeSharedSettings': '1',
      'X-Plex-Product': _appName,
      'X-Plex-Version': _appVersion,
      'X-Plex-Client-Identifier': _clientIdentifier,
      'X-Plex-Platform': 'Flutter',
      'X-Plex-Platform-Version': _platformVersion,
      'X-Plex-Token': currentToken,
      'X-Plex-Language': 'en',
      'pin': ?pin,
    };

    final response = await _http.post(
      '$_clientsApi/home/users/$userUUID/switch',
      queryParameters: queryParams,
      headers: {'Accept': 'application/json', 'Content-Length': '0'},
    );

    _checkStatus(response);
    return UserSwitchResponse.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Classification of an endpoint URL by the server's published connection type.
enum PlexNetworkClass { local, remote, relay, unknown }

/// Helper class to track connection candidates during testing
class _ConnectionCandidate {
  final PlexConnection connection;
  final String url;
  final bool isPlexDirectUri;
  final bool isHttps;

  const _ConnectionCandidate(this.connection, this.url, this.isPlexDirectUri, this.isHttps);
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
      throw const FormatException(
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

        if (_allowsHttpFallback(connection)) {
          connections.add(connection.toHttpFallback());
        }
      } catch (e) {
        // Skip invalid connections rather than failing the entire server
        continue;
      }
    }

    // If no valid connections were parsed, this server is unusable
    if (connections.isEmpty) {
      throw const FormatException('Server has no valid connections');
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
      clientIdentifier: json['clientIdentifier'] as String, // Safe because validated above
      accessToken: json['accessToken'] as String, // Safe because validated above
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
    if (json['clientIdentifier'] is! String || (json['clientIdentifier'] as String).isEmpty) {
      return false;
    }
    if (json['accessToken'] is! String || (json['accessToken'] as String).isEmpty) {
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

  PlexServer withAccessToken(String token) {
    return PlexServer(
      name: name,
      clientIdentifier: clientIdentifier,
      accessToken: token,
      connections: connections,
      owned: owned,
      product: product,
      platform: platform,
      lastSeenAt: lastSeenAt,
      presence: presence,
    );
  }

  /// Check if server is online using the presence field
  bool get isOnline => presence;

  /// Find the best working connection by testing them
  /// Returns a Stream that emits connections progressively:
  /// 1. First emission: The first connection that responds successfully
  /// 2. Second emission (optional): The best connection after latency testing
  /// Priority: local > remote > relay, then HTTPS > HTTP, then lowest latency
  /// Tests both plex.direct URI and direct IP for each connection
  /// HTTPS connections are tested first, with HTTP as fallback
  Stream<PlexConnection> findBestWorkingConnection({
    String? preferredUri,
    String? clientIdentifier,
    void Function(bool)? onTranscoderCapability,
  }) async* {
    if (connections.isEmpty) {
      appLogger.w('No connections available for server discovery');
      return;
    }

    final candidates = _buildPrioritizedCandidates();
    if (candidates.isEmpty) {
      appLogger.w('No connection candidates generated for server discovery');
      return;
    }

    final totalCandidates = candidates.length;
    appLogger.d(
      'Starting server connection discovery',
      error: {'preferred': preferredUri, 'candidateCount': totalCandidates},
    );

    for (final conn in connections) {
      final redactedUri = conn.uri.replaceAll(RegExp(r'//[^:/]+'), '//${_redactHost(conn.address)}');
      appLogger.d(
        'Raw API connection',
        error: {
          'uri': redactedUri,
          'address': _redactHost(conn.address),
          'local': conn.local,
          'relay': conn.relay,
          'protocol': conn.protocol,
        },
      );
    }

    PlexConnection? firstConnection;
    await for (final selection in raceEndpointCandidates<_ConnectionCandidate, ConnectionTestResult>(
      label: 'Plex server connection',
      candidates: candidates,
      preferredUrl: preferredUri,
      candidateForUrl: _candidateForUrl,
      urlOf: (candidate) => candidate.url,
      displayTypeOf: (candidate) => candidate.connection.displayType,
      failureLogFields: (candidate, result) => {
        'https': candidate.isHttps,
        'error': result.error,
        'latencyMs': result.latencyMs,
      },
      probe: (candidate, timeout) => PlexClient.testConnectionWithLatency(
        candidate.url,
        accessToken,
        timeout: timeout,
        clientIdentifier: clientIdentifier,
      ),
      measure: (candidate) => PlexClient.testConnectionWithAverageLatency(
        candidate.url,
        accessToken,
        attempts: 2,
        clientIdentifier: clientIdentifier,
      ),
      isSuccess: (result) => result.success,
      selectBestCandidate: _selectBestCandidateWithLatency,
      onFirstSuccess: (_, result) {
        if (result.transcoderVideo != null) onTranscoderCapability?.call(result.transcoderVideo!);
      },
    )) {
      if (selection.phase == EndpointRacePhase.first) {
        final firstCandidate = selection.candidate;
        final upgradedFirstCandidate = await _upgradeCandidateToHttpsIfPossible(
          firstCandidate,
          clientIdentifier: clientIdentifier,
        );
        final emitCandidate = upgradedFirstCandidate ?? firstCandidate;

        firstConnection = _updateConnectionUrl(emitCandidate.connection, emitCandidate.url);
        yield firstConnection;
        if (upgradedFirstCandidate != null && upgradedFirstCandidate.url != firstCandidate.url) {
          appLogger.i(
            'Phase 1 winner upgraded to HTTPS',
            error: {'from': firstCandidate.url, 'to': upgradedFirstCandidate.url},
          );
        }
        appLogger.d(
          'Emitted first working connection, continuing latency tests in background',
          error: {'uri': firstConnection.uri},
        );
        continue;
      }

      final bestCandidate = selection.candidate;
      final upgradedCandidate =
          await _upgradeCandidateToHttpsIfPossible(bestCandidate, clientIdentifier: clientIdentifier) ?? bestCandidate;

      final bestConnection = _updateConnectionUrl(upgradedCandidate.connection, upgradedCandidate.url);
      if (firstConnection == null || bestConnection.uri != firstConnection.uri) {
        appLogger.i('Latency sweep selected better endpoint', error: {'uri': bestConnection.uri});
        yield bestConnection;
      } else {
        appLogger.d('Latency sweep confirmed initial endpoint is optimal', error: {'uri': bestConnection.uri});
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

  _ConnectionCandidate? _candidateForUrl(String url) {
    for (final connection in connections) {
      final httpUrl = connection.httpDirectUrl;
      if (httpUrl == url) {
        return _ConnectionCandidate(connection, httpUrl, false, false);
      }

      final uri = connection.uri;
      if (uri == url) {
        final isHttps = uri.startsWith('https://');
        final parsedHost = Uri.tryParse(uri)?.host ?? '';
        final isPlexDirect = parsedHost.toLowerCase().contains('plex.direct');
        return _ConnectionCandidate(connection, uri, isPlexDirect, isHttps);
      }
    }
    return null;
  }

  /// Classify [url] against the server's published connections. Custom public
  /// HTTPS hostnames are treated as remote so failover avoids LAN-only URLs.
  PlexNetworkClass networkClassForUrl(String url) {
    return _candidateForUrl(url)?.connection.networkClass ?? _classifyCustomPreferredUrl(url);
  }

  PlexNetworkClass _classifyCustomPreferredUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme.toLowerCase() != 'https') return PlexNetworkClass.unknown;

    final host = _normalizedHost(uri.host);
    if (host.isEmpty || _isLocalOrPrivateHost(host)) return PlexNetworkClass.unknown;

    // A manually entered HTTPS reverse-proxy hostname behaves like a remote
    // endpoint for failover: LAN candidates often cannot be reached from it.
    return PlexNetworkClass.remote;
  }

  List<_ConnectionCandidate> _buildPrioritizedCandidates({Set<String>? excludeUrls, PlexNetworkClass? restrictTo}) {
    final seen = <String>{};
    if (excludeUrls != null) {
      seen.addAll(excludeUrls);
    }

    final httpsLocal = <_ConnectionCandidate>[];
    final httpsRemote = <_ConnectionCandidate>[];
    final httpsRelay = <_ConnectionCandidate>[];
    final httpLocal = <_ConnectionCandidate>[];
    final httpRemote = <_ConnectionCandidate>[];
    final httpRelay = <_ConnectionCandidate>[];

    List<_ConnectionCandidate> bucketFor(PlexConnection connection, bool isHttps) {
      if (isHttps) {
        if (connection.relay) return httpsRelay;
        if (connection.local) return httpsLocal;
        return httpsRemote;
      } else {
        if (connection.relay) return httpRelay;
        if (connection.local) return httpLocal;
        return httpRemote;
      }
    }

    void addCandidate(PlexConnection connection, String url, bool isPlexDirectUri, bool isHttps) {
      if (url.isEmpty || seen.contains(url)) {
        return;
      }
      seen.add(url);
      bucketFor(connection, isHttps).add(_ConnectionCandidate(connection, url, isPlexDirectUri, isHttps));
    }

    for (final connection in connections) {
      // Skip endpoints that are never reachable from an external client:
      // Docker bridge addresses and IPv6 link-local / all-zeros addresses.
      if (_isUnreachableAddress(connection.address)) {
        continue;
      }

      // First, try the actual connection URI (may be HTTPS plex.direct)
      final isPlexDirect = _isPlexDirectUri(connection.uri);
      final isHttps = connection.protocol == 'https';
      addCandidate(connection, connection.uri, isPlexDirect, isHttps);

      if (_allowsHttpFallback(connection)) {
        addCandidate(connection, _httpFallbackUrl(connection), false, false);
      }
    }

    final all = [...httpsLocal, ...httpsRemote, ...httpsRelay, ...httpLocal, ...httpRemote, ...httpRelay];

    // Failover reachability filter. After discovery, failover should stay within
    // endpoint families plausible for the current session: when a remote or relay
    // endpoint is what's working, LAN-only endpoints are unreachable from off-LAN
    // clients and only pollute the retry chain (see GH #902). Reconnect /
    // reoptimization widens the search again via _reoptimizeServer. Local is kept
    // conservative — it may still be reachable over VPN/routed-LAN, but those
    // setups re-widen on the next connectivity event.
    if (restrictTo == PlexNetworkClass.remote || restrictTo == PlexNetworkClass.relay) {
      final filtered = all.where((c) => c.connection.networkClass != PlexNetworkClass.local).toList();
      if (filtered.isNotEmpty) return filtered;
    }
    return all;
  }

  List<String> prioritizedEndpointUrls({String? preferredFirst}) {
    final urls = <String>[];
    final exclude = <String>{};
    PlexNetworkClass? restrictTo;

    if (preferredFirst != null && preferredFirst.isNotEmpty) {
      urls.add(preferredFirst);
      exclude.add(preferredFirst);
      restrictTo = networkClassForUrl(preferredFirst);
    }

    final candidates = _buildPrioritizedCandidates(excludeUrls: exclude, restrictTo: restrictTo);
    urls.addAll(candidates.map((candidate) => candidate.url));
    return urls;
  }

  Future<_ConnectionCandidate?> _upgradeCandidateToHttpsIfPossible(
    _ConnectionCandidate candidate, {
    String? clientIdentifier,
  }) async {
    final currentUrl = candidate.url;
    if (currentUrl.startsWith('https://')) {
      return null;
    }

    late final String httpsUrl;
    bool resultingIsPlexDirect = candidate.isPlexDirectUri;

    if (candidate.isPlexDirectUri) {
      if (!currentUrl.startsWith('http://')) {
        return null;
      }
      httpsUrl = currentUrl.replaceFirst('http://', 'https://');
    } else {
      // Raw IP endpoints can't present HTTPS certificates, so prefer their
      // plex.direct alias. Native custom hostnames on :32400 can be probed on
      // the same host to avoid permanently downgrading to HTTP when HTTPS works.
      final originalUri = candidate.connection.uri;
      if (originalUri.isEmpty) {
        return null;
      }

      if (originalUri.startsWith('https://')) {
        httpsUrl = originalUri;
      } else if (originalUri.startsWith('http://')) {
        httpsUrl = originalUri.replaceFirst('http://', 'https://');
      } else {
        return null;
      }

      final upgradedHost = Uri.tryParse(httpsUrl)?.host;
      if (upgradedHost == null) {
        return null;
      }

      if (upgradedHost.toLowerCase().endsWith('.plex.direct')) {
        resultingIsPlexDirect = true;
      } else if (!_isNativePlexHostnameHttps(candidate.connection)) {
        appLogger.d(
          'Skipping HTTPS upgrade for HTTP candidate: no safe HTTPS target available',
          error: {'candidate': currentUrl, 'target': httpsUrl},
        );
        return null;
      }
    }

    if (httpsUrl == currentUrl) {
      return null;
    }

    appLogger.d('Attempting HTTPS upgrade for candidate endpoint', error: {'from': currentUrl, 'to': httpsUrl});

    final result = await PlexClient.testConnectionWithLatency(
      httpsUrl,
      accessToken,
      timeout: MediaServerTimeouts.connectionRace,
      clientIdentifier: clientIdentifier,
    );

    if (!result.success) {
      appLogger.w(
        'HTTPS upgrade failed, staying on HTTP candidate',
        error: {'url': currentUrl, 'reason': result.error},
      );
      return null;
    }

    appLogger.i('HTTPS upgrade succeeded for candidate endpoint', error: {'httpsUrl': httpsUrl});

    final httpsConnection = PlexConnection(
      protocol: 'https',
      address: candidate.connection.address,
      port: candidate.connection.port,
      uri: httpsUrl,
      local: candidate.connection.local,
      relay: candidate.connection.relay,
      ipv6: candidate.connection.ipv6,
    );

    return _ConnectionCandidate(httpsConnection, httpsUrl, resultingIsPlexDirect, true);
  }

  Future<PlexConnection?> upgradeConnectionToHttps(PlexConnection current) async {
    if (current.uri.startsWith('https://')) {
      return current;
    }

    final baseConnection = _findMatchingBaseConnection(current);
    if (baseConnection == null) {
      return null;
    }

    final candidate = _ConnectionCandidate(
      baseConnection,
      current.uri,
      current.uri.contains('.plex.direct'),
      current.uri.startsWith('https://'),
    );
    final upgradedCandidate = await _upgradeCandidateToHttpsIfPossible(candidate);
    if (upgradedCandidate == null) {
      return null;
    }
    return _updateConnectionUrl(upgradedCandidate.connection, upgradedCandidate.url);
  }

  PlexConnection? _findMatchingBaseConnection(PlexConnection connection) {
    for (final base in connections) {
      final sameAddress = base.address == connection.address;
      final samePort = base.port == connection.port;
      final sameLocal = base.local == connection.local;
      final sameRelay = base.relay == connection.relay;
      if (sameAddress && samePort && sameLocal && sameRelay) {
        return base;
      }
    }
    return null;
  }

  /// Select the best candidate considering priority, latency, and URL type preference
  _ConnectionCandidate? _selectBestCandidateWithLatency(Map<_ConnectionCandidate, ConnectionTestResult> results) {
    // Group candidates by connection type (local/remote/relay)
    final localCandidates = results.entries.where((e) => e.key.connection.local && !e.key.connection.relay).toList();
    final remoteCandidates = results.entries.where((e) => !e.key.connection.local && !e.key.connection.relay).toList();
    final relayCandidates = results.entries.where((e) => e.key.connection.relay).toList();

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

    // Sort by protocol first (HTTPS enables H2 multiplexing), then latency, then URL type
    entries.sort((a, b) {
      // Prefer HTTPS over HTTP
      final aIsHttps = a.key.isHttps;
      final bIsHttps = b.key.isHttps;
      if (aIsHttps && !bIsHttps) return -1;
      if (!aIsHttps && bIsHttps) return 1;

      // Within same protocol, sort by latency
      final latencyCompare = a.value.latencyMs.compareTo(b.value.latencyMs);
      if (latencyCompare != 0) return latencyCompare;

      // Prefer plex.direct URI on tie
      if (a.key.isPlexDirectUri && !b.key.isPlexDirectUri) return -1;
      if (!a.key.isPlexDirectUri && b.key.isPlexDirectUri) return 1;
      return 0;
    });

    return entries.first.key;
  }

  /// True when the address is a raw IP (no hostname → no reverse proxy → HTTP
  /// fallback on an HTTPS port is safe to try).
  static bool _isIpLiteral(String address) {
    final bare = address.startsWith('[') && address.endsWith(']') ? address.substring(1, address.length - 1) : address;
    return InternetAddress.tryParse(bare) != null;
  }

  static bool _allowsHttpFallback(PlexConnection connection) {
    if (connection.protocol != 'https') return false;
    return _isPlexDirectUri(connection.uri) ||
        _isIpLiteral(connection.address) ||
        _isNativePlexHostnameHttps(connection);
  }

  static String _httpFallbackUrl(PlexConnection connection) {
    if (_isNativePlexHostnameHttps(connection)) {
      return connection.uri.replaceFirst('https://', 'http://');
    }
    return connection.httpDirectUrl;
  }

  static bool _isPlexDirectUri(String uri) {
    final host = Uri.tryParse(uri)?.host.toLowerCase();
    return host?.endsWith('.plex.direct') ?? uri.contains('.plex.direct');
  }

  static bool _isNativePlexHostnameHttps(PlexConnection connection) {
    if (connection.protocol != 'https' || connection.port != 32400 || _isIpLiteral(connection.address)) {
      return false;
    }

    final uri = Uri.tryParse(connection.uri);
    if (uri == null || uri.scheme != 'https' || uri.hasQuery || uri.hasFragment) {
      return false;
    }
    if (uri.port != connection.port) {
      return false;
    }
    if (uri.path.isNotEmpty && uri.path != '/') {
      return false;
    }

    final address = _normalizedHost(connection.address);
    return address.isNotEmpty && uri.host.toLowerCase() == address;
  }

  static String _normalizedHost(String host) {
    final bare = host.startsWith('[') && host.endsWith(']') ? host.substring(1, host.length - 1) : host;
    return bare.toLowerCase();
  }

  static bool _isLocalOrPrivateHost(String host) {
    final address = InternetAddress.tryParse(host);
    if (address != null) return _isPrivateOrLocalAddress(address);

    if (host == 'localhost' || !host.contains('.')) return true;
    if (host.endsWith('.local') ||
        host.endsWith('.lan') ||
        host.endsWith('.home.arpa') ||
        host.endsWith('.internal') ||
        host.endsWith('.ts.net')) {
      return true;
    }

    return false;
  }

  static bool _isPrivateOrLocalAddress(InternetAddress address) {
    final bytes = address.rawAddress;
    if (address.type == InternetAddressType.IPv4 && bytes.length == 4) {
      final a = bytes.first;
      final b = bytes[1];
      return a == 0 ||
          a == 10 ||
          (a == 100 && b >= 64 && b <= 127) ||
          a == 127 ||
          (a == 169 && b == 254) ||
          (a == 172 && b >= 16 && b <= 31) ||
          (a == 192 && b == 168);
    }

    if (address.type == InternetAddressType.IPv6 && bytes.length == 16) {
      final first = bytes.first;
      final second = bytes[1];
      final isLoopback = bytes.take(15).every((b) => b == 0) && bytes[15] == 1;
      final isUnspecified = bytes.every((b) => b == 0);
      return isLoopback || isUnspecified || (first & 0xfe) == 0xfc || (first == 0xfe && (second & 0xc0) == 0x80);
    }

    return false;
  }

  /// Returns true if the address is known to be unreachable from external
  /// clients (IPv6 link-local or all-zeros).
  static bool _isUnreachableAddress(String address) {
    // IPv6 all-zeros (::) or link-local (fe80::)
    final normalized = address.replaceAll('-', ':').toLowerCase();
    if (normalized == '::' || normalized == '0000:0000:0000:0000:0000:0000:0000:0000') {
      return true;
    }
    // Condensed all-zeros variants
    if (RegExp(r'^(0+:){7}0+$').hasMatch(normalized)) {
      return true;
    }
    if (normalized.startsWith('fe80:') || normalized.startsWith('fe80::')) {
      return true;
    }

    return false;
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
      throw const FormatException('Invalid connection data: missing required fields (protocol, address, port, or uri)');
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

  /// Always return an HTTP URL that points directly at the IP/port combo.
  String get httpDirectUrl {
    final needsBrackets = address.contains(':') && !address.startsWith('[');
    final safeAddress = needsBrackets ? '[$address]' : address;
    return 'http://$safeAddress:$port';
  }

  String get displayType {
    if (relay) return 'Relay';
    if (local) return 'Local';
    return 'Remote';
  }

  PlexNetworkClass get networkClass {
    if (relay) return PlexNetworkClass.relay;
    if (local) return PlexNetworkClass.local;
    return PlexNetworkClass.remote;
  }

  /// Create an HTTP fallback version of this HTTPS connection
  /// This allows testing HTTP when HTTPS is unavailable (e.g., certificate issues)
  PlexConnection toHttpFallback() {
    assert(protocol == 'https', 'Can only create HTTP fallback for HTTPS connections');

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
