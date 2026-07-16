/// Build the `MediaBrowser` Authorization header value the way the Jellyfin
/// SDK formats it. Used at auth time and on every authenticated request so
/// the server sees a consistent client identity.
///
/// Values are quote-stripped: the header grammar has no escape for `"`, so a
/// device name like `My "cool" TV` would otherwise corrupt every field after
/// it.
String buildJellyfinAuthHeader({
  required String clientName,
  required String clientVersion,
  required String deviceName,
  required String deviceId,
  String? accessToken,
}) {
  String quoted(String value) => '"${value.replaceAll('"', '')}"';
  final parts = <String>[
    'Client=${quoted(clientName)}',
    'Device=${quoted(deviceName)}',
    'DeviceId=${quoted(deviceId)}',
    'Version=${quoted(clientVersion)}',
    if (accessToken != null && accessToken.isNotEmpty) 'Token=${quoted(accessToken)}',
  ];
  return 'MediaBrowser ${parts.join(', ')}';
}
