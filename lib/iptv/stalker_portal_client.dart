import 'dart:convert';

import '../sources/source_models.dart';
import '../sources/source_transport.dart';
import '../sources/universal_media_input.dart';
import 'iptv_models.dart';
import 'iptv_playlist_parser.dart';

/// Small, defensive client for the de-facto Stalker/Ministra MAG portal API.
/// Portals vary by middleware version, so the adapter accepts the common
/// `js.data`, direct-list, and JSON-in-a-string response shapes.
class StalkerPortalClient {
  StalkerPortalClient(this.config) : _transport = SourceTransport(allowHttp: config.allowHttp);

  final IptvSourceConfiguration config;
  final SourceTransport _transport;
  String? _token;
  bool _closed = false;

  static const _userAgent =
      'Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG254 stbapp ver: 4 rev: 1812 Safari/533.3';

  Uri get loadUri {
    final input = Uri.parse(config.endpoint.trim());
    final path = input.path.replaceAll(RegExp(r'/+$'), '');
    if (path.endsWith('/server/load.php') || path.endsWith('/portal.php')) return input.replace(path: path);
    if (path.endsWith('/c')) return input.replace(path: '${path.substring(0, path.length - 2)}/server/load.php');
    if (path.endsWith('/stalker_portal')) return input.replace(path: '$path/server/load.php');
    if (path.endsWith('/stalker_portal/server')) return input.replace(path: '$path/load.php');
    if (path.isEmpty || path == '/') return input.replace(path: '/stalker_portal/server/load.php');
    if (path.endsWith('/stalker_portal/c')) {
      return input.replace(path: '${path.substring(0, path.length - 2)}/server/load.php');
    }
    return input.replace(path: '$path/stalker_portal/server/load.php');
  }

  Future<List<IptvPlaylistEntry>> channels() async {
    await _handshake();
    final genres = await _api('itv', 'get_genres').then(_rows).catchError((Object _) => <Map<String, dynamic>>[]);
    final genreNames = <String, String>{
      for (final genre in genres)
        if (_firstString(genre, const ['id', 'genre_id']).isNotEmpty &&
            _firstString(genre, const ['title', 'name']).isNotEmpty)
          _firstString(genre, const ['id', 'genre_id']): _firstString(genre, const ['title', 'name']),
    };
    // get_all_channels is the most efficient form and is implemented by the
    // common Stalker and Ministra middleware versions.
    try {
      final result = await _api('itv', 'get_all_channels');
      final rows = _rows(result);
      if (rows.isNotEmpty) return _playlistEntries(rows, genreNames);
    } on SourceException catch (error) {
      if (error.status != 404 && error.reason != SourceFailure.unsupported && error.reason != SourceFailure.invalidData) {
        rethrow;
      }
    }

    final genreIds = <String>['*', for (final genre in genres) _firstString(genre, const ['id', 'genre_id'])]
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final allRows = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final genreId in genreIds) {
      for (var page = 1; page <= 400 && allRows.length < IptvPlaylistParser.maxEntries; page++) {
        final raw = await _api('itv', 'get_ordered_list', parameters: {'genre': genreId, 'p': '$page', 'fav': '0'});
        final rows = _rows(raw);
        if (rows.isEmpty) break;
        for (final row in rows) {
          final id = _firstString(row, const ['id', 'ch_id', 'channel_id']);
          if (id.isNotEmpty && seen.add(id)) allRows.add(row);
        }
        final total = _intValue(_map(raw)?['total_items']) ?? _intValue(_map(raw)?['totalItems']);
        if (total != null && page * rows.length >= total) break;
        if (rows.length < 10) break;
      }
    }
    return _playlistEntries(allRows, genreNames);
  }

  Future<String> createLink(String command) async {
    final response = await _api('itv', 'create_link', parameters: {
      'cmd': command,
      'series': '0',
      'forced_storage': 'undefined',
      'disable_ad': '0',
      'download': '0',
    });
    final value = _findLink(response);
    if (value == null) throw const SourceException(SourceFailure.invalidData);
    final commandResult = value.replaceFirst(RegExp(r'^(?:ffmpeg|ffrt|auto)\s+', caseSensitive: false), '').trim();
    final uri = UniversalMediaAddress.parse(commandResult, allowHttp: config.allowHttp, allowMpvProtocols: true, base: loadUri);
    return uri.toString();
  }

  List<IptvPlaylistEntry> _playlistEntries(List<Map<String, dynamic>> rows, Map<String, String> genreNames) {
    final entries = <IptvPlaylistEntry>[];
    final seenIds = <String>{};
    for (final row in rows) {
      final id = _firstString(row, const ['id', 'ch_id', 'channel_id']);
      final command = _firstString(row, const ['cmd', 'command', 'stream_url', 'url']);
      final name = _firstString(row, const ['name', 'title', 'channel_name']);
      if (id.isEmpty || command.isEmpty || name.isEmpty || !seenIds.add(id)) continue;
      final genreId = _firstString(row, const ['tv_genre_id', 'genre_id', 'category_id']);
      final logo = _firstString(row, const ['logo', 'logo_url', 'image', 'icon']);
      final tvgId = _firstString(row, const ['xmltv_id', 'tvg_id', 'epg_channel_id', 'epg_id']);
      final number = _firstString(row, const ['number', 'channel_number', 'vcn']);
      final isRadio = _boolValue(row['is_radio']) || _boolValue(row['radio']);
      entries.add(IptvPlaylistEntry(
        id: id,
        title: _cleanText(name, 240),
        // The real URL is short-lived and must be created with an active
        // portal token. This opaque payload is encrypted in the catalogue.
        streamUrl: 'stalker:${jsonEncode({'cmd': command})}',
        tvgId: tvgId.isEmpty ? id : tvgId,
        number: number.isEmpty ? null : number,
        groupTitle: genreId.isEmpty
            ? _firstString(row, const ['tv_genre_name', 'genre'])
            : genreNames[genreId] ?? genreId,
        logoUrl: logo.isEmpty ? null : _safePortalArtwork(logo),
        radio: isRadio,
      ));
      if (entries.length > IptvPlaylistParser.maxEntries) throw const SourceException(SourceFailure.invalidData);
    }
    if (entries.isEmpty) throw const SourceException(SourceFailure.invalidData);
    return List.unmodifiable(entries);
  }

  Future<Object?> _api(String type, String action, {Map<String, String> parameters = const {}}) async {
    await _ensureOpen();
    if (_token == null && action != 'handshake') await _handshake();
    try {
      return await _request(type, action, parameters: parameters);
    } on SourceException catch (error) {
      if (error.reason != SourceFailure.authentication || action == 'handshake') rethrow;
      _token = null;
      await _handshake();
      return _request(type, action, parameters: parameters);
    }
  }

  Future<void> _handshake() async {
    await _ensureOpen();
    _token = null;
    final result = await _request('stb', 'handshake', parameters: const {'token': ''}, allowMissingToken: true);
    final body = _map(result);
    final token = _firstString(body ?? const {}, const ['token', 'access_token']);
    if (token.isEmpty) throw const SourceException(SourceFailure.authentication);
    _token = token;
    // Several portal versions require this identity request after handshake.
    await _request('stb', 'get_profile');
  }

  Future<Object?> _request(
    String type,
    String action, {
    Map<String, String> parameters = const {},
    bool allowMissingToken = false,
  }) async {
    final uri = loadUri.replace(queryParameters: {
      ...loadUri.queryParameters,
      'type': type,
      'action': action,
      'JsHttpRequest': '1-xml',
      if (!allowMissingToken && _token != null) 'token': _token!,
      ...parameters,
    });
    final portalPath = loadUri.path.replaceFirst(RegExp(r'/server/(?:load|api)\.php$'), '/c/').replaceFirst('/portal.php', '/c/');
    final response = await _transport.text('GET', uri, headers: {
      'Accept': 'application/json, text/javascript, */*; q=0.01',
      'User-Agent': _userAgent,
      'X-User-Agent': 'Model: MAG254; Link: WiFi',
      'Referer': loadUri.replace(path: portalPath, query: null).toString(),
      'Cookie': 'mac=${config.macAddress}; stb_lang=en; timezone=${DateTime.now().timeZoneName}',
      if (!allowMissingToken && _token != null) 'Authorization': 'Bearer $_token',
    });
    Object? decoded;
    try {
      decoded = jsonDecode(response);
    } on FormatException {
      throw const SourceException(SourceFailure.invalidData);
    }
    final envelope = _map(decoded);
    final js = envelope?['js'];
    final payload = js is String ? _decodeMaybeJson(js) : js ?? decoded;
    final resultMap = _map(payload);
    final error = _firstString(resultMap ?? const {}, const ['error', 'message', 'error_message']);
    if (error.isNotEmpty && RegExp(r'(auth|token|mac|denied|invalid)', caseSensitive: false).hasMatch(error)) {
      throw const SourceException(SourceFailure.authentication);
    }
    return payload;
  }

  Future<void> _ensureOpen() async {
    if (_closed) throw const SourceException(SourceFailure.cancelled);
  }

  static List<Map<String, dynamic>> _rows(Object? value) {
    var current = value;
    if (current is Map) {
      final map = sourceMap(current);
      for (final key in const ['data', 'items', 'channels', 'results']) {
        final candidate = map[key];
        if (candidate is List) current = candidate;
        if (current is List) break;
      }
    }
    if (current is! List) return const [];
    return [for (final item in current) if (item is Map) sourceMap(item)];
  }

  static Map<String, dynamic>? _map(Object? value) => value is Map ? sourceMap(value) : null;

  static Object? _decodeMaybeJson(String value) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return value;
    }
  }

  static String? _findLink(Object? value) {
    if (value is String) return value.trim().isEmpty ? null : value.trim();
    if (value is Map) {
      final map = sourceMap(value);
      for (final key in const ['cmd', 'url', 'link', 'stream_url', 'stream']) {
        final candidate = map[key];
        if (candidate is String && candidate.trim().isNotEmpty) return candidate.trim();
      }
      for (final key in const ['data', 'js', 'result']) {
        final found = _findLink(map[key]);
        if (found != null) return found;
      }
    }
    if (value is List) {
      for (final child in value) {
        final found = _findLink(child);
        if (found != null) return found;
      }
    }
    return null;
  }

  static String _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = '$value'.trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  static int? _intValue(Object? value) => value is num ? value.toInt() : int.tryParse('$value');

  static bool _boolValue(Object? value) => value == true || value == 1 || value == '1' || value == 'true';

  static String _cleanText(String value, int max) {
    final cleaned = value.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '').trim();
    return cleaned.substring(0, cleaned.length.clamp(0, max).toInt());
  }

  String? _safePortalArtwork(String value) {
    try {
      final uri = UniversalMediaAddress.parse(value, allowHttp: config.allowHttp, base: loadUri);
      if (uri.queryParameters.keys.any((key) => RegExp(r'(token|password|auth|secret|key)', caseSensitive: false).hasMatch(key))) {
        return null;
      }
      return uri.toString();
    } on Object {
      return null;
    }
  }

  void close() {
    _closed = true;
    _token = null;
    _transport.close();
  }
}
