String buildJellyfinDirectStreamUrl({
  required String baseUrl,
  required String accessToken,
  required String deviceId,
  required String itemId,
  String? container,
  String? mediaSourceId,
}) {
  final params = <String, String>{
    'Static': 'true',
    'api_key': accessToken,
    'DeviceId': deviceId,
    'Container': ?container,
    'MediaSourceId': ?mediaSourceId,
  };
  final encodedItem = Uri.encodeComponent(itemId);
  return '$baseUrl/Videos/$encodedItem/stream?${_encodeQuery(params)}';
}

String buildJellyfinTrickplayTileUrl({
  required String baseUrl,
  required String accessToken,
  required String deviceId,
  required String itemId,
  required int width,
  required int sheetIndex,
  String? mediaSourceId,
}) {
  final params = <String, String>{'api_key': accessToken, 'DeviceId': deviceId, 'MediaSourceId': ?mediaSourceId};
  final encodedItem = Uri.encodeComponent(itemId);
  return '$baseUrl/Videos/$encodedItem/Trickplay/$width/$sheetIndex.jpg?${_encodeQuery(params)}';
}

String buildJellyfinHlsStreamUrl({
  required String baseUrl,
  required String accessToken,
  required String deviceId,
  required String itemId,
  required String mediaSourceId,
  int? videoBitrate,
  int? audioStreamIndex,
  int? subtitleStreamIndex,
  String? playSessionId,
}) {
  final params = <String, String>{
    'DeviceId': deviceId,
    'MediaSourceId': mediaSourceId,
    'api_key': accessToken,
    'VideoBitrate': ?videoBitrate?.toString(),
    'AudioStreamIndex': ?audioStreamIndex?.toString(),
    'SubtitleStreamIndex': ?subtitleStreamIndex?.toString(),
    'PlaySessionId': ?playSessionId,
  };
  final encodedItem = Uri.encodeComponent(itemId);
  return '$baseUrl/Videos/$encodedItem/master.m3u8?${_encodeQuery(params)}';
}

String _encodeQuery(Map<String, String> params) =>
    params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
