import '../utils/device_identity.dart';

/// Build the `MediaBrowser` Authorization header value the way the Jellyfin
/// SDK formats it. Used at auth time and on every authenticated request so
/// the server sees a consistent client identity.
///
/// Unsafe header characters and embedded quotes are removed. Jellyfin requires
/// non-empty client, device, and version fields when creating a session, so
/// those values use stable fallbacks. An empty device ID is omitted for
/// authenticated requests, where Jellyfin can recover it from the token;
/// unauthenticated entry points must call [requireJellyfinDeviceId].
String buildJellyfinAuthHeader({
  required String clientName,
  required String clientVersion,
  required String deviceName,
  required String deviceId,
  String? accessToken,
}) {
  String clean(String value) => (sanitizeHeaderValue(value) ?? '').replaceAll('"', '');

  final client = clean(clientName);
  final effectiveClient = client.isEmpty ? 'Plezy' : client;
  final device = clean(deviceName);
  final effectiveDevice = device.isEmpty ? effectiveClient : device;
  final id = clean(deviceId);
  final version = clean(clientVersion);
  final token = accessToken == null ? '' : clean(accessToken);
  String quoted(String value) => '"$value"';

  final parts = <String>[
    'Client=${quoted(effectiveClient)}',
    'Device=${quoted(effectiveDevice)}',
    if (id.isNotEmpty) 'DeviceId=${quoted(id)}',
    'Version=${quoted(version.isEmpty ? '1.0' : version)}',
    if (token.isNotEmpty) 'Token=${quoted(token)}',
  ];
  return 'MediaBrowser ${parts.join(', ')}';
}

/// Validates the stable device identity required by unauthenticated Jellyfin
/// session creation. Never substitute a placeholder: Jellyfin keys sessions
/// and access tokens by this value, so a shared fallback would collide across
/// installations.
String requireJellyfinDeviceId(String deviceId) {
  final sanitized = sanitizeHeaderValue(deviceId);
  if (sanitized == null || sanitized != deviceId || sanitized.contains('"')) {
    throw ArgumentError.value(deviceId, 'deviceId', 'must be a non-empty HTTP-safe value');
  }
  return sanitized;
}
