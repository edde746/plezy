import '../models/plex/plex_config.dart';
import '../models/transcode_quality_preset.dart';
import '../utils/media_server_http_client.dart';
import '../utils/url_utils.dart';

enum PlexDownloadQueueStatus { deciding, waiting, processing, available, error, expired }

/// The server's preparation progress is separate from the file transfer.
class PlexDownloadQueueItem {
  final String id;
  final String queueId;
  final String key;
  final PlexDownloadQueueStatus status;
  final double? progress;
  final String? error;

  const PlexDownloadQueueItem({
    required this.id,
    required this.queueId,
    required this.key,
    required this.status,
    this.progress,
    this.error,
  });
}

/// A decision that has been checked against the requested offline format.
class PlexDownloadDecision {
  final String container;
  final String videoCodec;
  final String audioCodec;

  const PlexDownloadDecision({required this.container, required this.videoCodec, required this.audioCodec});
}

/// Plex's file-download API (PMS 1.41.9+, API version 1.0.0).
///
/// One instance captures the user and client identity for a preparation job.
/// The caller persists queue/item IDs, polls, and owns cancellation/cleanup.
/// Requests reuse the Plex client's transport, including endpoint failover.
/// See https://developer.plex.tv/pms/#tag/Download-Queue.
class PlexDownloadQueueService {
  static const _apiVersion = '1.0.0';
  static const _profile =
      'add-transcode-target(type=videoProfile&context=streaming'
      '&protocol=http&container=mp4&videoCodec=h264&audioCodec=aac&replace=true)';

  final MediaServerHttpClient _http;
  final Map<String, String> _headers;

  PlexDownloadQueueService(this._http, {required PlexConfig config})
    : _headers = Map.unmodifiable({
        ...config.headers,
        // Override any later change in the shared transport's profile headers.
        'X-Plex-Token': config.token ?? '',
        'X-Plex-Pms-Api-Version': _apiVersion,
        'X-Plex-Client-Profile-Name': 'generic',
      });

  Future<String> create() async {
    final response = await _http.post('/downloadQueue', headers: _headers);
    final queues = _elements(response, 'DownloadQueue');
    if (queues.length != 1) throw const FormatException('Plex did not return a download queue');
    return _id(queues.single['id']);
  }

  Future<String> add(
    String queueId, {
    required String ratingKey,
    required int mediaIndex,
    required TranscodeQualityPreset quality,
  }) async {
    if (quality.isOriginal) throw ArgumentError.value(quality, 'quality', 'Use a direct download for Original');
    if (mediaIndex < 0) throw ArgumentError.value(mediaIndex, 'mediaIndex', 'A selected source is required');
    if (ratingKey.isEmpty) throw ArgumentError.value(ratingKey, 'ratingKey');
    final key = '/library/metadata/${Uri.encodeComponent(ratingKey)}';
    final response = await _http.post(
      '/downloadQueue/${_id(queueId)}/add',
      headers: _headers,
      queryParameters: {
        'keys': key,
        'mediaIndex': mediaIndex,
        // Download the complete title, including joined multipart media.
        'partIndex': -1,
        'videoBitrate': quality.videoBitrateKbps,
        'videoResolution': quality.videoResolution,
        'directPlay': 0,
        'directStream': 0,
        'directStreamAudio': 0,
        'protocol': 'http',
        'subtitles': 'none',
        'X-Plex-Client-Profile-Extra': _profile,
      },
    );
    final items = _elements(response, 'AddedQueueItems').where((item) => item['key'] == key).toList();
    if (items.length != 1) throw const FormatException('Plex did not queue the requested video');
    return _id(items.single['id']);
  }

  Future<PlexDownloadQueueItem> getItem(String queueId, String itemId) async {
    final response = await _http.get(_itemsPath(queueId, itemId), headers: _headers);
    final items = _elements(
      response,
      'DownloadQueueItem',
    ).where((item) => _id(item['id']) == _id(itemId) && _id(item['queueId']) == _id(queueId)).toList();
    if (items.length != 1) throw const FormatException('Plex download queue item is missing');
    final item = items.single;
    final statuses = PlexDownloadQueueStatus.values.where((status) => status.name == item['status']);
    if (statuses.isEmpty) throw const FormatException('Plex returned an unknown download preparation status');
    final status = statuses.single;
    final key = item['key'];
    if (key is! String || key.isEmpty) throw const FormatException('Plex download queue item has no media key');
    final session = item['TranscodeSession'];
    double? progress;
    if (session is Map && session['progress'] != null) {
      final rawProgress = session['progress'];
      final percentage = rawProgress is num ? rawProgress.toDouble() : double.tryParse(rawProgress.toString());
      if (percentage == null || !percentage.isFinite || percentage < 0 || percentage > 100) {
        throw const FormatException('Plex returned invalid download preparation progress');
      }
      progress = percentage / 100;
    }
    final decision = item['DecisionResult'];
    return PlexDownloadQueueItem(
      id: _id(item['id']),
      queueId: _id(item['queueId']),
      key: key,
      status: status,
      progress: status == PlexDownloadQueueStatus.available ? 1 : progress,
      error: item['error'] is String
          ? item['error'] as String
          : status == PlexDownloadQueueStatus.error && decision is Map
          ? (decision['transcodeDecisionText'] ?? decision['generalDecisionText']) as String?
          : null,
    );
  }

  /// Refuse a playlist, unsupported container, or unconverted original before
  /// the download manager assigns an MP4 filename to the prepared file.
  Future<PlexDownloadDecision> getDecision(String queueId, String itemId) async {
    final response = await _http.get('${_itemPath(queueId, itemId)}/decision', headers: _headers);
    final metadata = _elements(response, 'Metadata');
    if (metadata.length != 1) throw const FormatException('Plex download decision has no unique video');
    final mediaEntries = _maps(metadata.single['Media']);
    final selectedMedia = mediaEntries.where((media) => _selected(media['selected'])).toList();
    final candidates = selectedMedia.isEmpty ? mediaEntries : selectedMedia;
    if (candidates.length != 1) throw const FormatException('Plex download decision has no unique media source');
    final media = candidates.single;
    final parts = _maps(media['Part']);
    if (parts.length != 1) throw const FormatException('Plex did not prepare a single download file');
    final part = parts.single;
    final streams = _maps(part['Stream']);
    final video = streams.where((stream) => stream['streamType'].toString() == '1').toList();
    final audio = streams.where((stream) => stream['streamType'].toString() == '2').toList();
    final container = part['container'] ?? media['container'];
    final videoCodec = video.length == 1 ? video.single['codec'] : media['videoCodec'];
    final audioCodec = audio.length == 1 ? audio.single['codec'] : media['audioCodec'];
    if (container != 'mp4' ||
        (media['container'] != null && media['container'] != 'mp4') ||
        videoCodec != 'h264' ||
        audioCodec != 'aac' ||
        (media['videoCodec'] != null && media['videoCodec'] != 'h264') ||
        (media['audioCodec'] != null && media['audioCodec'] != 'aac') ||
        video.any((stream) => stream['codec'] != 'h264') ||
        audio.any((stream) => stream['codec'] != 'aac') ||
        (media['protocol'] != null && media['protocol'] != 'http') ||
        (part['protocol'] != null && part['protocol'] != 'http') ||
        part['decision'] != 'transcode') {
      throw const FormatException('Plex could not prepare an MP4 download with H.264 video and AAC audio');
    }
    return const PlexDownloadDecision(container: 'mp4', videoCodec: 'h264', audioCodec: 'aac');
  }

  Future<void> remove(String queueId, String itemId) async {
    final response = await _http.delete(_itemsPath(queueId, itemId), headers: _headers);
    // A removed/expired item already satisfies cleanup; don't mask a local
    // cancellation or successful download with a stale server queue entry.
    if (response.statusCode != 404) throwIfHttpError(response);
  }

  /// Native background downloaders receive the same captured identity and
  /// profile in the URL, since they do not use the shared HTTP transport.
  String mediaUrl(String queueId, String itemId) {
    final parameters = {
      for (final entry in _headers.entries)
        if (entry.key.startsWith('X-Plex-')) entry.key: entry.value,
      'X-Plex-Client-Profile-Extra': _profile,
    };
    return '${stripTrailingSlash(_http.baseUrl)}${_itemPath(queueId, itemId)}/media?${encodeQueryParameters(parameters)}';
  }

  static String _itemsPath(String queueId, String itemId) => '/downloadQueue/${_id(queueId)}/items/${_id(itemId)}';

  static String _itemPath(String queueId, String itemId) => '/downloadQueue/${_id(queueId)}/item/${_id(itemId)}';

  static String _id(Object? value) {
    final id = value?.toString();
    if (id == null || !RegExp(r'^\d+$').hasMatch(id)) throw const FormatException('Invalid Plex download queue ID');
    return id;
  }

  static bool _selected(Object? value) => value == true || value == 1 || value == '1';

  static List<Map<String, dynamic>> _elements(MediaServerResponse response, String name) {
    throwIfHttpError(response);
    final body = response.data;
    final container = body is Map ? body['MediaContainer'] : null;
    if (container is! Map) throw const FormatException('Plex returned an invalid download queue response');
    return _maps(container[name]);
  }

  static List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! List || value.any((item) => item is! Map<String, dynamic>)) {
      throw const FormatException('Plex returned an invalid download queue response');
    }
    return value.cast<Map<String, dynamic>>();
  }
}
