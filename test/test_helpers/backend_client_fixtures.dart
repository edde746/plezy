import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_browser_dialect.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/utils/active_client_scope.dart';

/// A MediaBrowser-family connection fixture. Defaults to the Jellyfin dialect;
/// pass `dialect: MediaBrowserDialect.emby` (or use [testEmbyConnection]) to
/// exercise the Emby routes.
JellyfinConnection testJellyfinConnection({
  String machineId = 'srv-1',
  String userId = 'user-1',
  String? id,
  String baseUrl = 'https://jf.example.com',
  List<String>? baseUrls,
  String serverName = 'Home',
  String userName = 'User',
  String accessToken = 'token',
  String deviceId = 'device-1',
  bool isAdministrator = false,
  DateTime? createdAt,
  DateTime? lastAuthenticatedAt,
  MediaBrowserDialect dialect = MediaBrowserDialect.jellyfin,
}) {
  return JellyfinConnection(
    id: id ?? '$machineId/$userId',
    baseUrl: baseUrl,
    baseUrls: baseUrls,
    serverName: serverName,
    serverMachineId: machineId,
    userId: userId,
    userName: userName,
    accessToken: accessToken,
    deviceId: deviceId,
    dialect: dialect,
    isAdministrator: isAdministrator,
    createdAt: createdAt ?? DateTime.utc(2024),
    lastAuthenticatedAt: lastAuthenticatedAt,
  );
}

/// Emby-dialect twin of [testJellyfinConnection]. Same field defaults so a
/// suite can be parameterized over both dialects and assert only the route
/// differences.
JellyfinConnection testEmbyConnection({
  String machineId = 'srv-1',
  String userId = 'user-1',
  String? id,
  String baseUrl = 'https://emby.example.com',
  List<String>? baseUrls,
  String serverName = 'Home',
  String userName = 'User',
  String accessToken = 'token',
  String deviceId = 'device-1',
  bool isAdministrator = false,
  DateTime? createdAt,
  DateTime? lastAuthenticatedAt,
}) {
  return testJellyfinConnection(
    machineId: machineId,
    userId: userId,
    id: id,
    baseUrl: baseUrl,
    baseUrls: baseUrls,
    serverName: serverName,
    userName: userName,
    accessToken: accessToken,
    deviceId: deviceId,
    isAdministrator: isAdministrator,
    createdAt: createdAt,
    lastAuthenticatedAt: lastAuthenticatedAt,
    dialect: MediaBrowserDialect.emby,
  );
}

PlexConfig testPlexConfig({
  String baseUrl = 'https://plex.example.com',
  String? token = 'token',
  String clientIdentifier = 'test-client',
  String product = 'Plezy Test',
  String version = '1.0.0',
  String platform = 'Flutter Test',
  String? device,
  String? deviceName,
  bool acceptJson = true,
  String? machineIdentifier,
  String? languageCode,
}) {
  return PlexConfig(
    baseUrl: baseUrl,
    token: token,
    clientIdentifier: clientIdentifier,
    product: product,
    version: version,
    platform: platform,
    device: device,
    deviceName: deviceName,
    acceptJson: acceptJson,
    machineIdentifier: machineIdentifier,
    languageCode: languageCode,
  );
}

JellyfinClient testJellyfinClient({
  JellyfinConnection? connection,
  http.Client? httpClient,
  Future<http.Response> Function(http.Request request)? handler,
  void Function()? onAllEndpointsExhausted,
}) {
  assert(httpClient == null || handler == null, 'Provide either httpClient or handler, not both');
  return JellyfinClient.forTesting(
    connection: connection ?? testJellyfinConnection(),
    httpClient: httpClient ?? MockClient(handler ?? _defaultResponse),
    onAllEndpointsExhausted: onAllEndpointsExhausted,
  );
}

/// Emby-dialect twin of [testJellyfinClient] — same `JellyfinClient` class, an
/// Emby connection underneath.
JellyfinClient testEmbyClient({
  JellyfinConnection? connection,
  http.Client? httpClient,
  Future<http.Response> Function(http.Request request)? handler,
  void Function()? onAllEndpointsExhausted,
}) {
  return testJellyfinClient(
    connection: connection ?? testEmbyConnection(),
    httpClient: httpClient,
    handler: handler,
    onAllEndpointsExhausted: onAllEndpointsExhausted,
  );
}

PlexClient testPlexClient({
  PlexConfig? config,
  String baseUrl = 'https://plex.example.com',
  String? token = 'token',
  ServerId? serverId,
  PlexProfileScopeId? profileScopeId,
  String? serverName = 'Server',
  http.Client? httpClient,
  Future<http.Response> Function(http.Request request)? handler,
  List<String>? prioritizedEndpoints,
  http.Client Function()? endpointProbeHttpClientFactory,
  void Function()? onAllEndpointsExhausted,
  List<PlexEpgProvider> epgProviders = const [],
  String? homeHubKey,
  String? promotedHubKey,
  String? continueWatchingHubKey,
}) {
  assert(httpClient == null || handler == null, 'Provide either httpClient or handler, not both');
  final resolvedServerId = serverId ?? ServerId('server-1');
  return PlexClient.forTesting(
    config: config ?? testPlexConfig(baseUrl: baseUrl, token: token),
    serverId: resolvedServerId,
    profileScopeId: profileScopeId ?? buildPlexProfileScopeId(serverId: resolvedServerId, profileId: 'test-profile'),
    serverName: serverName,
    httpClient: httpClient ?? MockClient(handler ?? _defaultResponse),
    prioritizedEndpoints: prioritizedEndpoints,
    endpointProbeHttpClientFactory: endpointProbeHttpClientFactory,
    onAllEndpointsExhausted: onAllEndpointsExhausted,
    epgProviders: epgProviders,
    homeHubKey: homeHubKey,
    promotedHubKey: promotedHubKey,
    continueWatchingHubKey: continueWatchingHubKey,
  );
}

Future<http.Response> _defaultResponse(http.Request request) async {
  return http.Response('{}', 200, headers: const {'content-type': 'application/json'});
}
