import 'dart:convert';

import '../models/livetv_channel.dart';
import '../models/livetv_program.dart';
import '../sources/source_models.dart';
import '../sources/source_transport.dart';
import 'iptv_models.dart';

/// Optional Dispatcharr DVR adapter. It uses the server's documented REST API
/// and keeps all recording bytes on the Dispatcharr host.
class DispatcharrDvrClient {
  DispatcharrDvrClient(this.config) : _transport = SourceTransport(allowHttp: config.allowHttp);

  final IptvSourceConfiguration config;
  final SourceTransport _transport;
  String _authScheme = 'ApiKey';

  Future<List<IptvDispatcharrRecording>> recordings() async {
    final response = await _requestWithFallback('GET', const [
      '/api/channels/recordings/',
      '/api/dvr/recordings/',
    ]);
    return [
      for (final row in _rows(response))
        IptvDispatcharrRecording.fromJson(sourceMap(row), config.id, config.displayName),
    ];
  }

  Future<List<IptvDispatcharrRule>> rules() async {
    final result = <IptvDispatcharrRule>[];
    for (final endpoint in const [
      ('series', ['/api/channels/series-rules/', '/api/dvr/series-rules/']),
      ('recurring', ['/api/channels/recurring-rules/', '/api/dvr/recurring-rules/']),
    ]) {
      try {
        final response = await _requestWithFallback('GET', endpoint.$2);
        for (final row in _rows(response)) {
          result.add(IptvDispatcharrRule.fromJson(sourceMap(row), config.id, endpoint.$1));
        }
      } on SourceException catch (error) {
        if (error.status != 404) rethrow;
      }
    }
    return result;
  }

  Future<void> stopRecording(String recordingId) async {
    final id = Uri.encodeComponent(recordingId);
    await _requestWithFallback('POST', [
      '/api/channels/recordings/$id/stop/',
      '/api/dvr/recordings/$id/stop/',
    ], body: '{}');
  }

  Future<void> deleteRecording(String recordingId) async {
    final id = Uri.encodeComponent(recordingId);
    await _requestWithFallback('DELETE', [
      '/api/channels/recordings/$id/',
      '/api/dvr/recordings/$id/',
    ]);
  }

  Uri recordingFileUri(String recordingId) => _uri('/api/channels/recordings/${Uri.encodeComponent(recordingId)}/file/');

  Future<void> deleteRule(IptvDispatcharrRule rule) async {
    final id = Uri.encodeComponent(rule.id);
    final paths = rule.kind == 'series'
        ? ['/api/channels/series-rules/$id/', '/api/dvr/series-rules/$id/']
        : ['/api/channels/recurring-rules/$id/', '/api/dvr/recurring-rules/$id/'];
    await _requestWithFallback('DELETE', paths);
  }

  Future<IptvDispatcharrRecording> schedule({
    required LiveTvChannel channel,
    required LiveTvProgram program,
  }) async {
    final tvgId = channel.identifier?.trim();
    if (tvgId == null || tvgId.isEmpty || program.beginsAt == null || program.endsAt == null) {
      throw const SourceException(SourceFailure.unsupported);
    }
    final channels = _rows(await _requestWithFallback('GET', const [
      '/api/channels/channels/',
      '/api/channels/',
    ]));
    final matches = <Map<String, dynamic>>[];
    for (final value in channels) {
      final row = sourceMap(value);
      final epg = sourceMap(row['epg_channel']);
      final ids = <String?>[
        _string(row['tvg_id']),
        _string(row['tvgId']),
        _string(row['epg_tvg_id']),
        _string(row['epg_channel_id']),
        _string(epg['tvg_id']),
        _string(epg['tvgId']),
      ];
      if (ids.any((id) => id == tvgId)) matches.add(row);
    }
    if (matches.length != 1) throw const SourceException(SourceFailure.unsupported);
    final remoteChannelId = matches.single['id'];
    if (remoteChannelId == null) throw const SourceException(SourceFailure.invalidData);
    final start = DateTime.fromMillisecondsSinceEpoch(program.beginsAt! * 1000, isUtc: true).toIso8601String();
    final end = DateTime.fromMillisecondsSinceEpoch(program.endsAt! * 1000, isUtc: true).toIso8601String();
    final body = jsonEncode({
      'channel': remoteChannelId,
      'start_time': start,
      'end_time': end,
      'title': program.displayTitle,
    });
    final created = sourceMap(await _requestWithFallback('POST', const [
      '/api/channels/recordings/',
      '/api/dvr/recordings/',
    ], body: body));
    return IptvDispatcharrRecording.fromJson(created, config.id, config.displayName);
  }

  Future<Object?> _requestWithFallback(String method, List<String> paths, {String? body}) async {
    SourceException? last;
    for (final path in paths) {
      try {
        return await _request(method, path, body: body);
      } on SourceException catch (error) {
        last = error;
        if (error.status != 404) rethrow;
      }
    }
    throw last ?? const SourceException(SourceFailure.unavailable);
  }

  Future<Object?> _request(String method, String path, {String? body}) async {
    final uri = _uri(path);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': '$_authScheme ${config.dispatcharrApiKey.trim()}',
      if (body != null) 'Content-Type': 'application/json',
    };
    try {
      final text = await _transport.text(
        method,
        uri,
        headers: headers,
        body: body,
        redirects: false,
        limit: 16 * 1024 * 1024,
      );
      if (text.trim().isEmpty) return const <String, dynamic>{};
      return jsonDecode(text);
    } on SourceException catch (error) {
      if (error.reason != SourceFailure.authentication || _authScheme == 'Bearer') rethrow;
      _authScheme = 'Bearer';
      return _request(method, path, body: body);
    } on FormatException {
      throw const SourceException(SourceFailure.invalidData);
    }
  }

  Uri _uri(String apiPath) {
    final raw = Uri.parse(config.dispatcharrApiEndpoint.trim());
    var prefix = raw.path.replaceFirst(RegExp(r'/+$'), '');
    if (prefix.endsWith('/swagger') || prefix.endsWith('/docs') || prefix.endsWith('/redoc')) {
      prefix = prefix.substring(0, prefix.lastIndexOf('/'));
    }
    if (prefix.endsWith('/api')) prefix = prefix.substring(0, prefix.length - 4);
    return raw.replace(path: '$prefix$apiPath', query: null, fragment: null);
  }

  static List<dynamic> _rows(Object? value) {
    if (value is List) return value;
    if (value is Map) {
      final row = sourceMap(value);
      for (final key in const ['results', 'data', 'items', 'recordings', 'channels', 'rules', 'series_rules', 'recurring_rules']) {
        if (row[key] is List) return row[key] as List;
      }
      if (row.isEmpty) return const [];
    }
    throw const SourceException(SourceFailure.invalidData);
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    final result = '$value'.trim();
    return result.isEmpty || result.toLowerCase() == 'null' ? null : result;
  }

  void close() => _transport.close();
}

class IptvDispatcharrRecording {
  const IptvDispatcharrRecording({
    required this.id,
    required this.sourceId,
    required this.sourceName,
    required this.title,
    required this.state,
    this.channelName,
    this.startedAt,
    this.endsAt,
    this.filePath,
  });

  final String id;
  final String sourceId;
  final String sourceName;
  final String title;
  final String state;
  final String? channelName;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final String? filePath;

  bool get isRecording => const {'recording', 'in_progress', 'grabbing', 'running'}.contains(state.toLowerCase());
  bool get isComplete => const {'complete', 'completed', 'finished', 'done'}.contains(state.toLowerCase());

  factory IptvDispatcharrRecording.fromJson(Map<String, dynamic> row, String sourceId, String sourceName) {
    DateTime? date(List<String> keys) {
      for (final key in keys) {
        final value = row[key];
        if (value is String) {
          final parsed = DateTime.tryParse(value);
          if (parsed != null) return parsed.toLocal();
        }
        if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000).toLocal();
      }
      return null;
    }

    final channel = sourceMap(row['channel']);
    return IptvDispatcharrRecording(
      id: '${row['id'] ?? row['pk'] ?? ''}',
      sourceId: sourceId,
      sourceName: sourceName,
      title: '${row['title'] ?? row['name'] ?? row['program_title'] ?? 'Recording'}',
      state: '${row['status'] ?? row['state'] ?? row['recording_status'] ?? 'scheduled'}',
      channelName: '${channel['name'] ?? row['channel_name'] ?? ''}'.trim().isEmpty
          ? null
          : '${channel['name'] ?? row['channel_name']}',
      startedAt: date(const ['start_time', 'started_at', 'start', 'scheduled_start']),
      endsAt: date(const ['end_time', 'ended_at', 'end', 'scheduled_end']),
      filePath: '${row['file_path'] ?? row['path'] ?? ''}'.trim().isEmpty ? null : '${row['file_path'] ?? row['path']}',
    );
  }
}

class IptvDispatcharrRule {
  const IptvDispatcharrRule({required this.id, required this.sourceId, required this.title, required this.kind});
  final String id;
  final String sourceId;
  final String title;
  final String kind;

  factory IptvDispatcharrRule.fromJson(Map<String, dynamic> row, String sourceId, String kind) => IptvDispatcharrRule(
    id: '${row['tvg_id'] ?? row['id'] ?? row['pk'] ?? ''}',
    sourceId: sourceId,
    title: '${row['title'] ?? row['name'] ?? row['series_name'] ?? 'Recording rule'}',
    kind: kind,
  );
}
