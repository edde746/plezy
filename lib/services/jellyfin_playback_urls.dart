/// [mediaSegment] selects the endpoint family: Jellyfin serves the identical
/// static-stream contract under `/Videos/{id}/stream` and `/Audio/{id}/stream`
/// — music track playback passes `'Audio'`.
String buildJellyfinDirectStreamUrl({
  required String baseUrl,
  required String accessToken,
  required String tokenQueryParam,
  required String deviceId,
  required String itemId,
  String mediaSegment = 'Videos',
  String? container,
  String? mediaSourceId,
  String? playSessionId,
  String? liveStreamId,
  int? audioStreamIndex,
  bool containerExtension = false,
}) {
  final params = <String, String>{
    'Static': 'true',
    tokenQueryParam: accessToken,
    'DeviceId': deviceId,
    'Container': ?container,
    'MediaSourceId': ?mediaSourceId,
    'PlaySessionId': ?playSessionId,
    'LiveStreamId': ?liveStreamId,
    'AudioStreamIndex': ?audioStreamIndex?.toString(),
  };
  final encodedItem = Uri.encodeComponent(itemId);
  // `stream.{container}` is the canonical direct-play shape Jellyfin's own
  // clients hand external players: the extension is the only hint a player
  // gets about the payload (a bare `stream` path gives it nothing to sniff
  // for, which is fatal for disc images like ISO). Restricted to callers that
  // opt in via [containerExtension]; the extension is sanitized to a plain
  // alphanumeric suffix so a malformed Container can't inject path segments.
  final extension = containerExtension ? _safeContainerExtension(container) : null;
  final streamPath = extension == null ? 'stream' : 'stream.$extension';
  return '$baseUrl/$mediaSegment/$encodedItem/$streamPath?${_encodeQuery(params)}';
}

String? _safeContainerExtension(String? container) {
  final value = container?.trim();
  if (value == null || value.isEmpty) return null;
  // Lowercased to match jellyfin-web's `stream.{container}` construction.
  return RegExp(r'^[A-Za-z0-9]+$').hasMatch(value) ? value.toLowerCase() : null;
}

String buildJellyfinTrickplayTileUrl({
  required String baseUrl,
  required String accessToken,
  required String tokenQueryParam,
  required String deviceId,
  required String itemId,
  required int width,
  required int sheetIndex,
  String? mediaSourceId,
}) {
  final params = <String, String>{tokenQueryParam: accessToken, 'DeviceId': deviceId, 'MediaSourceId': ?mediaSourceId};
  final encodedItem = Uri.encodeComponent(itemId);
  return '$baseUrl/Videos/$encodedItem/Trickplay/$width/$sheetIndex.jpg?${_encodeQuery(params)}';
}

String _encodeQuery(Map<String, String> params) =>
    params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
