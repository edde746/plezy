import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'diagnostics.dart';

const String plexProduct = 'Plezy GKUI';
const String plexVersion = '1.0.0';

class PlexPin {
  const PlexPin({required this.id, required this.code});
  final int id;
  final String code;

  String authUrl(String clientIdentifier) {
    final query = <String, String>{
      'clientID': clientIdentifier,
      'code': code,
      'context[device][product]': plexProduct,
    };
    return Uri.https('app.plex.tv', '/auth', query)
        .toString()
        .replaceFirst('?', '#?');
  }
}

class PlexSession {
  const PlexSession({
    required this.accountToken,
    required this.serverToken,
    required this.serverName,
    required this.serverId,
    required this.baseUrl,
  });

  final String accountToken;
  final String serverToken;
  final String serverName;
  final String serverId;
  final String baseUrl;

  Map<String, String> toStorage() => <String, String>{
        'accountToken': accountToken,
        'serverToken': serverToken,
        'serverName': serverName,
        'serverId': serverId,
        'baseUrl': baseUrl,
      };

  static PlexSession? fromStorage(Map<String, String?> values) {
    if (values.values.any((value) => value == null || value.isEmpty))
      return null;
    return PlexSession(
      accountToken: values['accountToken']!,
      serverToken: values['serverToken']!,
      serverName: values['serverName']!,
      serverId: values['serverId']!,
      baseUrl: values['baseUrl']!,
    );
  }
}

class PlexServerResource {
  const PlexServerResource({
    required this.name,
    required this.id,
    required this.token,
    required this.connections,
  });

  final String name;
  final String id;
  final String token;
  final List<PlexConnection> connections;
}

class PlexConnection {
  const PlexConnection(
      {required this.uri, required this.local, required this.relay});
  final String uri;
  final bool local;
  final bool relay;
}

class PlexSection {
  const PlexSection(
      {required this.key, required this.title, required this.type});
  final String key;
  final String title;
  final String type;
}

class PlexMedia {
  const PlexMedia({
    required this.ratingKey,
    required this.key,
    required this.type,
    required this.title,
    this.subtitle,
    this.summary,
    this.thumb,
    this.art,
    this.durationMs = 0,
    this.viewOffsetMs = 0,
    this.year,
    this.children = false,
    this.directPartKey,
  });

  final String ratingKey;
  final String key;
  final String type;
  final String title;
  final String? subtitle;
  final String? summary;
  final String? thumb;
  final String? art;
  final int durationMs;
  final int viewOffsetMs;
  final int? year;
  final bool children;
  final String? directPartKey;

  bool get playable =>
      type == 'movie' || type == 'episode' || directPartKey != null;
}

class PlexShelf {
  const PlexShelf({required this.title, required this.items});
  final String title;
  final List<PlexMedia> items;
}

class PlaybackRequest {
  const PlaybackRequest({
    required this.url,
    required this.headers,
    required this.sessionId,
    required this.transcoding,
  });
  final String url;
  final Map<String, String> headers;
  final String sessionId;
  final bool transcoding;
}

class PlexApi {
  PlexApi._(this._prefs, this.logs, this.clientIdentifier)
      : _accountDio = Dio(_options()),
        _serverDio = Dio(_options());

  final SharedPreferences _prefs;
  final RedactingLogStore logs;
  final String clientIdentifier;
  final Dio _accountDio;
  final Dio _serverDio;
  PlexSession? session;

  static Future<void> installLegacyTrust() async {
    final data = await rootBundle.load('assets/ca/legacy-roots.pem');
    final context = SecurityContext(withTrustedRoots: true);
    context.setTrustedCertificatesBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    HttpOverrides.global = _LegacyTrustOverrides(context);
  }

  static BaseOptions _options() => BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 12),
        responseType: ResponseType.json,
        headers: const <String, String>{'Accept': 'application/json'},
      );

  static Future<PlexApi> create(RedactingLogStore logs) async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('gkui.clientIdentifier');
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString('gkui.clientIdentifier', id);
    }
    final api = PlexApi._(prefs, logs, id);
    api.session = PlexSession.fromStorage(<String, String?>{
      'accountToken': prefs.getString('gkui.accountToken'),
      'serverToken': prefs.getString('gkui.serverToken'),
      'serverName': prefs.getString('gkui.serverName'),
      'serverId': prefs.getString('gkui.serverId'),
      'baseUrl': prefs.getString('gkui.baseUrl'),
    });
    return api;
  }

  Map<String, String> headers([String? token]) => <String, String>{
        'Accept': 'application/json',
        'X-Plex-Product': plexProduct,
        'X-Plex-Version': plexVersion,
        'X-Plex-Client-Identifier': clientIdentifier,
        'X-Plex-Platform': 'Android',
        'X-Plex-Device': 'GKUI',
        if (token != null) 'X-Plex-Token': token,
      };

  Future<PlexPin> createPin() async {
    logs.add('Requesting a Plex sign-in PIN.');
    final response = await _accountDio.post<Map<String, dynamic>>(
      'https://plex.tv/api/v2/pins',
      queryParameters: const <String, dynamic>{'strong': true},
      options: Options(headers: headers()),
    );
    final data = response.data!;
    return PlexPin(
        id: (data['id'] as num).toInt(), code: data['code'] as String);
  }

  Future<String?> checkPin(PlexPin pin) async {
    final response = await _accountDio.get<Map<String, dynamic>>(
      'https://plex.tv/api/v2/pins/${pin.id}',
      options: Options(headers: headers()),
    );
    return response.data?['authToken'] as String?;
  }

  Future<List<PlexServerResource>> fetchServers(String accountToken) async {
    logs.add('Loading Plex Media Server resources.');
    final response = await _accountDio.get<List<dynamic>>(
      'https://clients.plex.tv/api/v2/resources',
      queryParameters: const <String, dynamic>{
        'includeHttps': 1,
        'includeRelay': 1,
        'includeIPv6': 0,
      },
      options: Options(headers: headers(accountToken)),
    );
    final servers = <PlexServerResource>[];
    for (final raw in response.data ?? const <dynamic>[]) {
      final map = raw as Map<String, dynamic>;
      if (!(map['provides']?.toString().split(',').contains('server') ?? false))
        continue;
      final connections = <PlexConnection>[];
      for (final value
          in (map['connections'] as List<dynamic>? ?? const <dynamic>[])) {
        final connection = value as Map<String, dynamic>;
        final uri = connection['uri']?.toString() ?? '';
        if (!uri.toLowerCase().startsWith('https://')) continue;
        connections.add(PlexConnection(
          uri: uri.replaceAll(RegExp(r'/+$'), ''),
          local: connection['local'] == true,
          relay: connection['relay'] == true,
        ));
      }
      final token = map['accessToken']?.toString() ?? '';
      final id = map['clientIdentifier']?.toString() ?? '';
      if (token.isNotEmpty && id.isNotEmpty && connections.isNotEmpty) {
        servers.add(PlexServerResource(
          name: map['name']?.toString() ?? 'Plex Server',
          id: id,
          token: token,
          connections: connections,
        ));
      }
    }
    return servers;
  }

  Future<PlexSession> connect(
      String accountToken, PlexServerResource server) async {
    final candidates = List<PlexConnection>.from(server.connections)
      ..sort((a, b) {
        final aScore = (a.local ? 0 : 2) + (a.relay ? 2 : 0);
        final bScore = (b.local ? 0 : 2) + (b.relay ? 2 : 0);
        return aScore.compareTo(bScore);
      });
    Object? lastError;
    for (final candidate in candidates) {
      try {
        logs.add('Testing secure endpoint ${_safeHost(candidate.uri)}.');
        final response = await _serverDio.get<dynamic>(
          '${candidate.uri}/identity',
          options: Options(
            headers: headers(server.token),
            receiveTimeout: const Duration(seconds: 7),
          ),
        );
        if (response.statusCode == 200) {
          final connected = PlexSession(
            accountToken: accountToken,
            serverToken: server.token,
            serverName: server.name,
            serverId: server.id,
            baseUrl: candidate.uri,
          );
          await _saveSession(connected);
          session = connected;
          logs.add('Connected securely to ${server.name}.');
          return connected;
        }
      } catch (error) {
        lastError = error;
        logs.add('Endpoint ${_safeHost(candidate.uri)} did not respond.');
      }
    }
    throw StateError(
        'No secure endpoint reached ${server.name}: ${_briefError(lastError)}');
  }

  Future<void> _saveSession(PlexSession value) async {
    for (final entry in value.toStorage().entries) {
      await _prefs.setString('gkui.${entry.key}', entry.value);
    }
  }

  Future<void> signOut() async {
    for (final key in <String>[
      'accountToken',
      'serverToken',
      'serverName',
      'serverId',
      'baseUrl'
    ]) {
      await _prefs.remove('gkui.$key');
    }
    session = null;
    logs.add('Signed out; stored Plex tokens removed.');
  }

  Future<List<PlexShelf>> loadHome() async {
    final value = _requireSession();
    final response = await _serverDio.get<Map<String, dynamic>>(
      '${value.baseUrl}/hubs',
      queryParameters: const <String, dynamic>{
        'count': 12,
        'includeGuids': 1,
        'includeMeta': 1,
      },
      options: Options(headers: headers(value.serverToken)),
    );
    final container = _container(response.data);
    final shelves = <PlexShelf>[];
    for (final raw
        in (container['Hub'] as List<dynamic>? ?? const <dynamic>[])) {
      final hub = raw as Map<String, dynamic>;
      final items = _parseItems(hub['Metadata']);
      if (items.isNotEmpty) {
        shelves.add(
            PlexShelf(title: hub['title']?.toString() ?? 'Plex', items: items));
      }
    }
    logs.add('Loaded ${shelves.length} home shelves.');
    return shelves;
  }

  Future<List<PlexSection>> loadSections() async {
    final value = _requireSession();
    final response = await _serverDio.get<Map<String, dynamic>>(
      '${value.baseUrl}/library/sections',
      options: Options(headers: headers(value.serverToken)),
    );
    final container = _container(response.data);
    return (container['Directory'] as List<dynamic>? ?? const <dynamic>[])
        .map((raw) => raw as Map<String, dynamic>)
        .where((map) => map['key'] != null)
        .map((map) => PlexSection(
              key: map['key'].toString(),
              title: map['title']?.toString() ?? 'Library',
              type: map['type']?.toString() ?? '',
            ))
        .toList();
  }

  Future<List<PlexMedia>> loadSection(String sectionKey,
      {int start = 0}) async {
    final value = _requireSession();
    final response = await _serverDio.get<Map<String, dynamic>>(
      '${value.baseUrl}/library/sections/$sectionKey/all',
      queryParameters: <String, dynamic>{
        'X-Plex-Container-Start': start,
        'X-Plex-Container-Size': 60,
        'includeGuids': 1,
      },
      options: Options(headers: headers(value.serverToken)),
    );
    return _parseItems(_container(response.data)['Metadata']);
  }

  Future<List<PlexMedia>> loadChildren(PlexMedia item) async {
    final value = _requireSession();
    final path = item.key.endsWith('/children')
        ? item.key
        : '/library/metadata/${item.ratingKey}/children';
    final response = await _serverDio.get<Map<String, dynamic>>(
      '${value.baseUrl}$path',
      options: Options(headers: headers(value.serverToken)),
    );
    final container = _container(response.data);
    return _parseItems(container['Metadata'] ?? container['Directory']);
  }

  Future<PlexMedia> loadMetadata(String ratingKey) async {
    final value = _requireSession();
    final response = await _serverDio.get<Map<String, dynamic>>(
      '${value.baseUrl}/library/metadata/$ratingKey',
      queryParameters: const <String, dynamic>{'includeGuids': 1},
      options: Options(headers: headers(value.serverToken)),
    );
    final items = _parseItems(_container(response.data)['Metadata']);
    if (items.isEmpty)
      throw StateError('Plex returned no metadata for this title.');
    return items.first;
  }

  List<PlexMedia> _parseItems(dynamic rawList) {
    final items = <PlexMedia>[];
    for (final raw in (rawList as List<dynamic>? ?? const <dynamic>[])) {
      final map = raw as Map<String, dynamic>;
      String? directPartKey;
      final media = map['Media'] as List<dynamic>?;
      if (media != null && media.isNotEmpty) {
        final parts =
            (media.first as Map<String, dynamic>)['Part'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          directPartKey =
              (parts.first as Map<String, dynamic>)['key']?.toString();
        }
      }
      final type = map['type']?.toString() ?? '';
      items.add(PlexMedia(
        ratingKey: map['ratingKey']?.toString() ?? '',
        key: map['key']?.toString() ?? '',
        type: type,
        title: map['title']?.toString() ?? 'Untitled',
        subtitle: map['grandparentTitle']?.toString() ??
            map['parentTitle']?.toString(),
        summary: map['summary']?.toString(),
        thumb: map['thumb']?.toString(),
        art: map['art']?.toString(),
        durationMs: (map['duration'] as num?)?.toInt() ?? 0,
        viewOffsetMs: (map['viewOffset'] as num?)?.toInt() ?? 0,
        year: (map['year'] as num?)?.toInt(),
        children: type == 'show' || type == 'season' || type == 'album',
        directPartKey: directPartKey,
      ));
    }
    return items;
  }

  String? imageUrl(String? path, {int width = 300, int height = 450}) {
    final value = session;
    if (value == null || path == null || path.isEmpty) return null;
    final uri = Uri.parse('${value.baseUrl}/photo/:/transcode')
        .replace(queryParameters: <String, String>{
      'url': path,
      'width': '$width',
      'height': '$height',
      'minSize': '1',
      'upscale': '1',
    });
    return uri.toString();
  }

  Map<String, String> get imageHeaders {
    final value = _requireSession();
    return headers(value.serverToken);
  }

  PlaybackRequest playback(PlexMedia item,
      {required bool transcode, int bitrate = 3000}) {
    final value = _requireSession();
    final sessionId = const Uuid().v4();
    if (!transcode && item.directPartKey != null) {
      return PlaybackRequest(
        url: '${value.baseUrl}${item.directPartKey}',
        headers: headers(value.serverToken),
        sessionId: sessionId,
        transcoding: false,
      );
    }
    final resolution = bitrate <= 1500 ? '720x480' : '1280x720';
    final uri =
        Uri.parse('${value.baseUrl}/video/:/transcode/universal/start.m3u8')
            .replace(
      queryParameters: <String, String>{
        'path': '/library/metadata/${item.ratingKey}',
        'mediaIndex': '0',
        'partIndex': '0',
        'protocol': 'hls',
        'directPlay': '0',
        'directStream': '1',
        'videoQuality': bitrate <= 1500 ? '40' : '60',
        'videoResolution': resolution,
        'maxVideoBitrate': '$bitrate',
        'audioBoost': '100',
        'fastSeek': '1',
        'copyts': '1',
        'session': sessionId,
        'X-Plex-Client-Identifier': clientIdentifier,
      },
    );
    return PlaybackRequest(
      url: uri.toString(),
      headers: headers(value.serverToken),
      sessionId: sessionId,
      transcoding: true,
    );
  }

  Future<void> reportProgress(
      PlexMedia item, int positionMs, String state) async {
    final value = _requireSession();
    try {
      await _serverDio.get<dynamic>(
        '${value.baseUrl}/:/timeline',
        queryParameters: <String, dynamic>{
          'ratingKey': item.ratingKey,
          'key': '/library/metadata/${item.ratingKey}',
          'state': state,
          'time': positionMs,
          'duration': item.durationMs,
        },
        options: Options(headers: headers(value.serverToken)),
      );
    } catch (error) {
      logs.add('Progress update failed: ${_briefError(error)}');
    }
  }

  PlexSession _requireSession() {
    final value = session;
    if (value == null) throw StateError('Not signed in to Plex.');
    return value;
  }

  static Map<String, dynamic> _container(Map<String, dynamic>? data) {
    return data?['MediaContainer'] as Map<String, dynamic>? ??
        <String, dynamic>{};
  }

  static String _safeHost(String url) => Uri.tryParse(url)?.host ?? 'endpoint';

  static String _briefError(Object? error) {
    if (error is DioException) {
      if (error.response?.statusCode != null)
        return 'HTTP ${error.response!.statusCode}';
      return error.type.name;
    }
    return error?.runtimeType.toString() ?? 'unknown error';
  }
}

class _LegacyTrustOverrides extends HttpOverrides {
  _LegacyTrustOverrides(this.context);
  final SecurityContext context;

  @override
  HttpClient createHttpClient(SecurityContext? securityContext) =>
      super.createHttpClient(context);
}
