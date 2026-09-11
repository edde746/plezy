import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../utils/platform_http_client_io.dart'
    as platform;

/// Metadata discovered during a direct Plex server probe.
class PlexDirectServerInfo {
  final String activeUrl;
  final String serverName;
  final String serverMachineId;
  final String? version;
  final bool requiresAuth;
  final bool isAuthenticated;

  const PlexDirectServerInfo({
    required this.activeUrl,
    required this.serverName,
    required this.serverMachineId,
    this.version,
    required this.requiresAuth,
    required this.isAuthenticated,
  });
}

/// Probes a Plex Media Server at [url] to identify it and test authorization.
Future<PlexDirectServerInfo> probePlexServer({
  required String url,
  required String clientIdentifier,
  String token = '',
  http.Client? client,
}) async {
  final httpClient = client ?? platform.createPlatformClient();
  try {
    final rootUri = Uri.parse(url);
    final headers = {
      'Accept': 'application/json',
      'X-Plex-Client-Identifier': clientIdentifier,
      'X-Plex-Product': 'Plezy',
      'X-Plex-Version': '1.0',
      'X-Plex-Platform': 'Flutter',
    };
    if (token.isNotEmpty) {
      headers['X-Plex-Token'] = token;
    }

    http.Response rootResp;
    try {
      rootResp = await httpClient.get(rootUri.replace(path: '/'), headers: headers).timeout(const Duration(seconds: 5));
    } catch (_) {
      rootResp = await httpClient
          .get(rootUri.replace(path: '/identity'), headers: headers)
          .timeout(const Duration(seconds: 5));
    }

    if (rootResp.statusCode == 200) {
      final json = _tryParseJson(rootResp.body);
      final mc = json?['MediaContainer'] as Map<String, dynamic>?;

      final serverName =
          mc?['friendlyName'] as String? ??
          mc?['myPlexUsername'] as String? ??
          _extractXmlAttr(rootResp.body, 'friendlyName') ??
          'Plex Media Server';
      final machineId =
          mc?['machineIdentifier'] as String? ??
          _extractXmlAttr(rootResp.body, 'machineIdentifier') ??
          '${rootUri.host}:${rootUri.port}';
      final version = mc?['version'] as String? ?? _extractXmlAttr(rootResp.body, 'version');

      return PlexDirectServerInfo(
        activeUrl: url,
        serverName: serverName,
        serverMachineId: machineId,
        version: version,
        requiresAuth: false,
        isAuthenticated: true,
      );
    } else if (rootResp.statusCode == 401) {
      if (token.isNotEmpty) {
        throw const FormatException('Invalid Plex token. Access denied by server.');
      }

      // Query /identity without token to get machine identifier and version
      try {
        final idResp = await httpClient
            .get(rootUri.replace(path: '/identity'), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 5));

        if (idResp.statusCode == 200) {
          final json = _tryParseJson(idResp.body);
          final mc = json?['MediaContainer'] as Map<String, dynamic>?;
          final machineId =
              mc?['machineIdentifier'] as String? ??
              _extractXmlAttr(idResp.body, 'machineIdentifier') ??
              '${rootUri.host}:${rootUri.port}';
          final version = mc?['version'] as String? ?? _extractXmlAttr(idResp.body, 'version');

          return PlexDirectServerInfo(
            activeUrl: url,
            serverName: 'Plex (${rootUri.host})',
            serverMachineId: machineId,
            version: version,
            requiresAuth: true,
            isAuthenticated: false,
          );
        }
      } catch (_) {}

      return PlexDirectServerInfo(
        activeUrl: url,
        serverName: 'Plex (${rootUri.host})',
        serverMachineId: '${rootUri.host}:${rootUri.port}',
        requiresAuth: true,
        isAuthenticated: false,
      );
    } else {
      throw FormatException('Unexpected server response: HTTP ${rootResp.statusCode}');
    }
  } finally {
    if (client == null) httpClient.close();
  }
}

Map<String, dynamic>? _tryParseJson(String body) {
  try {
    return jsonDecode(body) as Map<String, dynamic>?;
  } catch (_) {
    return null;
  }
}

String? _extractXmlAttr(String xml, String attr) {
  final match = RegExp('$attr="([^"]+)"').firstMatch(xml);
  return match?.group(1);
}
