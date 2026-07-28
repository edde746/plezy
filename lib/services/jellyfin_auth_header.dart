import '../utils/device_identity.dart';

/// Build the `MediaBrowser` Authorization header value the way the official
/// Jellyfin SDK formats it: every field value is percent-encoded, and the
/// server reverses that with `WebUtility.UrlDecode` while parsing the header.
/// Used at auth time and on every authenticated request so the server sees a
/// consistent client identity.
///
/// Encoding is what keeps the header sendable at all. A device name like
/// `Bjørn PC` cannot travel verbatim: `dart:io` rejects header values above
/// 0x7F outright, and CFNetwork puts the raw code unit on the wire as a
/// Latin-1 byte, which Kestrel — the HTTP server hosting Jellyfin — refuses
/// as a malformed header with 400 before the request is ever routed. It also
/// removes the grammar hazards the header has no escape for: quotes, commas,
/// and `=` inside a value.
///
/// Jellyfin requires non-empty client, device, and version fields when
/// creating a session, so those values use stable fallbacks. An empty device
/// ID is omitted for authenticated requests, where Jellyfin can recover it
/// from the token; unauthenticated entry points must call
/// [requireJellyfinDeviceId].
String buildJellyfinAuthHeader({
  required String clientName,
  required String clientVersion,
  required String deviceName,
  required String deviceId,
  String? accessToken,
}) {
  String field(String name, String value) => '$name="${Uri.encodeComponent(value)}"';

  final client = _meaningful(clientName);
  final effectiveClient = client.isEmpty ? 'Plezy' : client;
  final device = _meaningful(deviceName);
  final version = _meaningful(clientVersion);
  final id = _meaningful(deviceId);
  final token = _meaningful(accessToken ?? '');

  final parts = <String>[
    field('Client', effectiveClient),
    field('Device', device.isEmpty ? effectiveClient : device),
    if (id.isNotEmpty) field('DeviceId', id),
    field('Version', version.isEmpty ? '1.0' : version),
    if (token.isNotEmpty) field('Token', token),
  ];
  return 'MediaBrowser ${parts.join(', ')}';
}

final RegExp _controlCharacters = RegExp(r'[\x00-\x1f\x7f-\x9f]');

/// Percent-encoding makes any byte transportable, so the only values worth
/// filtering are the ones that carry no identity at all — a name of control
/// characters would otherwise reach Jellyfin's device list as `%00` noise
/// instead of falling back to a readable label.
String _meaningful(String value) => value.replaceAll(_controlCharacters, '').trim();

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
