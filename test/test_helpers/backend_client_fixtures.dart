import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/plex_client.dart';

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
  ConnectionStatus status = ConnectionStatus.unknown,
  DateTime? createdAt,
  DateTime? lastAuthenticatedAt,
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
    isAdministrator: isAdministrator,
    status: status,
    createdAt: createdAt ?? DateTime.utc(2024),
    lastAuthenticatedAt: lastAuthenticatedAt,
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

PlexClient testPlexClient({
  PlexConfig? config,
  String baseUrl = 'https://plex.example.com',
  String? token = 'token',
  ServerId? serverId,
  String? serverName = 'Server',
  http.Client? httpClient,
  Future<http.Response> Function(http.Request request)? handler,
  List<String>? prioritizedEndpoints,
  List<({String identifier, String gridEndpoint})> epgProviders = const [],
  String? homeHubKey,
  String? promotedHubKey,
  String? continueWatchingHubKey,
}) {
  assert(httpClient == null || handler == null, 'Provide either httpClient or handler, not both');
  return PlexClient.forTesting(
    config: config ?? testPlexConfig(baseUrl: baseUrl, token: token),
    serverId: serverId ?? ServerId('server-1'),
    serverName: serverName,
    httpClient: httpClient ?? MockClient(handler ?? _defaultResponse),
    prioritizedEndpoints: prioritizedEndpoints,
    epgProviders: epgProviders,
    homeHubKey: homeHubKey,
    promotedHubKey: promotedHubKey,
    continueWatchingHubKey: continueWatchingHubKey,
  );
}

Future<http.Response> _defaultResponse(http.Request request) async {
  return http.Response('{}', 200, headers: const {'content-type': 'application/json'});
}
