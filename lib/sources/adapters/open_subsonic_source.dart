import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../source_models.dart';
import '../source_transport.dart';
import 'webdav_source.dart';

/// OpenSubsonic and Subsonic compatible music library adapter.
///
/// Credentials are read from the encrypted source vault. API-key auth is
/// preferred; legacy installations can use per-request MD5 token auth. The
/// server remains the authority for catalog membership and stream delivery.
class OpenSubsonicSourceAdapter extends SourceAdapter {
  OpenSubsonicSourceAdapter(super.source, super.transport, this.credentials);
  final SourceCredentials credentials;
  final Map<String, List<int>> _coverCache = {};
  static const _client = 'PlezyNG';
  static const _version = '1.16.1';
  static const _maxCoverCacheBytes = 24 * 1024 * 1024;
  static final _random = Random.secure();
  bool _apiKeyRejected = false;

  Uri get _base {
    final raw = source.endpoint.endsWith('/') ? source.endpoint : '${source.endpoint}/';
    final uri = Uri.parse(raw);
    validatePublicSourceUri(uri, allowHttp: transport.allowHttp);
    if (uri.hasQuery || uri.hasFragment || uri.pathSegments.any((part) => part == '.' || part == '..')) {
      throw const SourceException(SourceFailure.permission);
    }
    final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if (segments.lastOrNull?.toLowerCase() == 'rest') segments.removeLast();
    final path = segments.isEmpty ? '/' : '/${segments.join('/')}/';
    return uri.replace(path: path);
  }

  Uri _method(String method) => _base.resolve('rest/$method.view');

  Map<String, String> _legacyAuth(Map<String, String> saved) {
    final username = saved['username']?.trim() ?? '';
    final password = saved['password'] ?? '';
    if (username.isEmpty || password.isEmpty) throw const SourceException(SourceFailure.authentication);
    final salt = List.generate(12, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    final token = md5.convert(utf8.encode('$password$salt')).toString();
    return {'u': username, 't': token, 's': salt};
  }

  List<Map<String, String>> _authModes(Map<String, String> saved) {
    final apiKey = saved['apiKey']?.trim() ?? '';
    final username = saved['username']?.trim() ?? '';
    final password = saved['password'] ?? '';
    final legacy = username.isNotEmpty && password.isNotEmpty ? _legacyAuth(saved) : null;
    if (_apiKeyRejected && legacy != null) return [legacy];
    return [if (apiKey.isNotEmpty) {'apiKey': apiKey}, if (legacy != null) legacy];
  }

  Future<Map<String, dynamic>> _request(String method, [Map<String, String> parameters = const {}]) async {
    final saved = await credentials();
    final modes = _authModes(saved);
    if (modes.isEmpty) throw const SourceException(SourceFailure.authentication);
    SourceException? authFailure;
    for (var index = 0; index < modes.length; index++) {
      final response = await transport.json(
        'POST',
        _method(method),
        headers: const {'Accept': 'application/json', 'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          ...modes[index],
          ...parameters,
          'v': _version,
          'c': _client,
          'f': 'json',
        },
      );
      final envelope = sourceMap(response['subsonic-response']);
      if (envelope['status'] == 'ok') return envelope;
      final error = sourceMap(envelope['error']);
      final code = sourceInt(error['code']);
      final failure = switch (code) {
        40 => SourceFailure.authentication,
        41 || 42 => SourceFailure.unsupported,
        44 => SourceFailure.unavailable,
        50 => SourceFailure.permission,
        _ => SourceFailure.invalidData,
      };
      authFailure = SourceException(failure, status: code);
      // OpenSubsonic API-key auth is an extension. If this server does not
      // implement it, retry with the user's separately supplied password.
      if (index + 1 >= modes.length || !const {41, 42}.contains(code)) throw authFailure;
      _apiKeyRejected = true;
    }
    throw authFailure ?? const SourceException(SourceFailure.authentication);
  }

  Uri _authenticatedUri(String method, Map<String, String> parameters, Map<String, String> saved) {
    final modes = _authModes(saved);
    if (modes.isEmpty) throw const SourceException(SourceFailure.authentication);
    // API key is preferred for stream and artwork URLs. API methods that
    // reject that extension fall back in _request; signed media requests stay
    // bound to the user's selected auth mode and are proxied through localhost.
    return _method(method).replace(
      queryParameters: {
        ...(_apiKeyRejected && modes.length > 1 ? modes.last : modes.first),
        ...parameters,
        'v': _version,
        'c': _client,
      },
    );
  }

  @override
  // Listening progress stays in PlezyNG unless a configured state source
  // (such as WebDAV) provides the user's cross-device progress store.
  SourceCapabilities get capabilities => const SourceCapabilities();

  SourceEntry _folder(
    String id,
    String title, {
    String? parent,
    String author = '',
    String? coverId,
    Map<String, String> identifiers = const {},
  }) => SourceEntry(
    sourceId: source.id,
    id: id,
    title: title,
    kind: SourceItemKind.folder,
    parentId: parent,
    author: author,
    coverId: coverId,
    identifiers: identifiers,
  );

  String _folderId(String kind, Object id) => '$kind:${Uri.encodeComponent(id.toString())}';
  bool _validId(Object? id) => id != null && id.toString().isNotEmpty && id.toString().length <= 2048;

  SourceEntry _song(Map<String, dynamic> row, {String? parent}) {
    final id = '${row['id'] ?? ''}';
    if (id.isEmpty || id.length > 2048) throw const SourceException(SourceFailure.invalidData);
    final title = '${row['title'] ?? row['name'] ?? id}'.trim();
    final rawMime = '${row['contentType'] ?? ''}'.split(';').first.trim().toLowerCase();
    final candidateSuffix = '${row['suffix'] ?? ''}'.trim().toLowerCase().replaceFirst(RegExp(r'^\.'), '');
    final suffix = RegExp(r'^[a-z0-9]{1,8}$').hasMatch(candidateSuffix) ? candidateSuffix : '';
    final mime = RegExp(r'^audio/[a-z0-9][a-z0-9!#$&^_.+-]{0,63}$').hasMatch(rawMime)
        ? rawMime
        : _mimeFor(suffix);
    final coverId = _validId(row['coverArt']) ? '${row['coverArt']}' : null;
    final extension = suffix.isNotEmpty ? '.$suffix' : _extensionFor(mime);
    final name = title.toLowerCase().endsWith(extension) ? title : '$title$extension';
    final durationValue = row['duration'];
    final duration = durationValue is num ? durationValue.toDouble() : double.tryParse('$durationValue');
    final durationMs = duration == null || !duration.isFinite || duration <= 0 || duration > 7 * 24 * 60 * 60
        ? null
        : (duration * 1000).round();
    final size = sourceInt(row['size']);
    return SourceEntry(
      sourceId: source.id,
      id: 'song:$id',
      title: title,
      kind: SourceItemKind.music,
      parentId: parent,
      coverId: coverId,
      author: '${row['artist'] ?? ''}',
      series: '${row['album'] ?? ''}',
      seriesOrder: sourceInt(row['track'])?.toDouble(),
      releaseYear: sourceInt(row['year']),
      identifiers: {
        'subsonicId': id,
        if (coverId != null) 'coverArt': coverId,
      },
      files: [
        PublicationFile(
          id: id,
          name: name,
          mimeType: mime,
          size: size == null || size < 0 ? null : size,
          durationMs: durationMs,
          revision: '${row['id']}:${row['size'] ?? ''}:${row['changed'] ?? ''}',
        ),
      ],
    );
  }

  static String _mimeFor(String suffix) => switch (suffix) {
    'mp3' => 'audio/mpeg',
    'm4a' || 'mp4' || 'aac' => 'audio/mp4',
    'flac' => 'audio/flac',
    'ogg' => 'audio/ogg',
    'opus' => 'audio/opus',
    'wav' => 'audio/wav',
    'wma' => 'audio/x-ms-wma',
    _ => 'audio/mpeg',
  };

  static String _extensionFor(String mime) => switch (mime) {
    'audio/flac' => '.flac',
    'audio/ogg' => '.ogg',
    'audio/opus' => '.opus',
    'audio/mp4' => '.m4a',
    'audio/wav' => '.wav',
    'audio/x-ms-wma' => '.wma',
    _ => '.mp3',
  };

  List<dynamic> _items(Map<String, dynamic> envelope, String key) => _asList(envelope[key]);

  List<dynamic> _asList(Object? value) => value == null ? const [] : value is List ? value : [value];

  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    final offset = int.tryParse(cursor ?? '0');
    if (offset == null || offset < 0 || offset > 1000000) throw const SourceException(SourceFailure.invalidData);
    if (query?.trim().isNotEmpty == true) {
      final result = await _request('search3', {
        'query': query!.trim(),
        'artistCount': '100',
        'artistOffset': '0',
        'albumCount': '100',
        'albumOffset': '0',
        'songCount': '100',
        'songOffset': '$offset',
      });
      final data = sourceMap(result['searchResult3']);
      final entries = <SourceEntry>[
        if (offset == 0)
          for (final row in _items(data, 'artist'))
            if (_validId(sourceMap(row)['id']))
              _folder(
                _folderId('artist', sourceMap(row)['id']),
                '${sourceMap(row)['name'] ?? ''}',
                identifiers: {'subsonicId': '${sourceMap(row)['id']}'},
              ),
        if (offset == 0)
          for (final row in _items(data, 'album'))
            if (_validId(sourceMap(row)['id']))
              _folder(
                _folderId('album', sourceMap(row)['id']),
                '${sourceMap(row)['name'] ?? ''}',
                author: '${sourceMap(row)['artist'] ?? ''}',
                coverId: _validId(sourceMap(row)['coverArt']) ? '${sourceMap(row)['coverArt']}' : null,
                identifiers: {
                  'subsonicId': '${sourceMap(row)['id']}',
                  if (sourceMap(row)['artist'] != null) 'artist': '${sourceMap(row)['artist']}',
                  if (_validId(sourceMap(row)['coverArt'])) 'coverArt': '${sourceMap(row)['coverArt']}',
                },
              ),
        for (final row in _items(data, 'song'))
          if (_validId(sourceMap(row)['id'])) _song(sourceMap(row)),
      ];
      final songs = _items(data, 'song');
      return SourcePage(entries, next: songs.length >= 100 ? '${offset + songs.length}' : null);
    }

    if (parent == null) {
      await _request('ping');
      return SourcePage([
        _folder('artists', 'Artists'),
        _folder('albums', 'Albums'),
        _folder('recent', 'Recently added'),
      ]);
    }
    if (parent == 'artists') {
      final response = await _request('getArtists');
      final indexes = _asList(sourceMap(response['artists'])['index']);
      final artists = [for (final index in indexes) ..._asList(sourceMap(index)['artist'])];
      return SourcePage([
        for (final value in artists.skip(offset).take(200))
          if (_validId(sourceMap(value)['id']))
            _folder(
              _folderId('artist', sourceMap(value)['id']),
              '${sourceMap(value)['name'] ?? ''}',
              parent: parent,
              identifiers: {'subsonicId': '${sourceMap(value)['id']}'},
            ),
      ], next: offset + 200 < artists.length ? '${offset + 200}' : null);
    }
    if (parent == 'albums' || parent == 'recent') {
      final size = 200;
      final response = await _request('getAlbumList2', {
        'type': parent == 'recent' ? 'newest' : 'alphabeticalByName',
        'size': '$size',
        'offset': '$offset',
      });
      final albums = _items(sourceMap(response['albumList2']), 'album');
      return SourcePage([
        for (final value in albums)
          if (_validId(sourceMap(value)['id']))
            _folder(
              _folderId('album', sourceMap(value)['id']),
              '${sourceMap(value)['name'] ?? ''}',
              parent: parent,
              author: '${sourceMap(value)['artist'] ?? ''}',
              coverId: _validId(sourceMap(value)['coverArt']) ? '${sourceMap(value)['coverArt']}' : null,
              identifiers: {
                'subsonicId': '${sourceMap(value)['id']}',
                if (sourceMap(value)['artist'] != null) 'artist': '${sourceMap(value)['artist']}',
                if (_validId(sourceMap(value)['coverArt'])) 'coverArt': '${sourceMap(value)['coverArt']}',
              },
            ),
      ], next: albums.length == size ? '${offset + size}' : null);
    }
    final parts = parent.split(':');
    if (parts.length != 2 || !const {'artist', 'album'}.contains(parts.first) || parts.last.isEmpty) {
      throw const SourceException(SourceFailure.invalidData);
    }
    final String itemId;
    try {
      itemId = Uri.decodeComponent(parts.last);
    } on FormatException {
      throw const SourceException(SourceFailure.invalidData);
    }
    if (itemId.isEmpty || itemId.length > 2048) throw const SourceException(SourceFailure.invalidData);
    if (parts.first == 'artist') {
      final response = await _request('getArtist', {'id': itemId});
      final artist = sourceMap(response['artist']);
      return SourcePage([
        for (final value in _items(artist, 'album'))
          if (_validId(sourceMap(value)['id']))
            _folder(
              _folderId('album', sourceMap(value)['id']),
              '${sourceMap(value)['name'] ?? ''}',
              parent: parent,
              author: '${sourceMap(value)['artist'] ?? artist['name'] ?? ''}',
              coverId: _validId(sourceMap(value)['coverArt']) ? '${sourceMap(value)['coverArt']}' : null,
              identifiers: {
                'subsonicId': '${sourceMap(value)['id']}',
                if (sourceMap(value)['artist'] != null) 'artist': '${sourceMap(value)['artist']}',
                if (_validId(sourceMap(value)['coverArt'])) 'coverArt': '${sourceMap(value)['coverArt']}',
              },
            ),
      ]);
    }
    final response = await _request('getAlbum', {'id': itemId});
    final album = sourceMap(response['album']);
    final songs = _items(album, 'song');
    return SourcePage([
      for (final value in songs)
        if (_validId(sourceMap(value)['id'])) _song(sourceMap(value), parent: parent),
    ]);
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async {
    final saved = await credentials();
    return ContentLease(
      _authenticatedUri('stream', {'id': file.id}, saved),
      size: file.size,
    );
  }

  @override
  Future<ContentLease?> cover(SourceEntry entry) async {
    final id = entry.identifiers['coverArt'];
    if (id == null || id.isEmpty) return null;
    final saved = await credentials();
    return ContentLease(_authenticatedUri('getCoverArt', {'id': id, 'size': '640'}, saved));
  }

  @override
  Future<List<int>?> coverBytes(SourceEntry entry) async {
    final id = entry.identifiers['coverArt'];
    if (id == null || id.isEmpty) return null;
    final cached = _coverCache[id];
    if (cached != null) return cached;
    final saved = await credentials();
    final response = await transport.send('GET', _authenticatedUri('getCoverArt', {'id': id, 'size': '640'}, saved));
    if (response.statusCode == 404) {
      await response.stream.drain<void>();
      return null;
    }
    SourceTransport.check(response.statusCode);
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(const Duration(seconds: 30))) {
      if (bytes.length + chunk.length > 8 * 1024 * 1024) throw const SourceException(SourceFailure.invalidData);
      bytes.addAll(chunk);
    }
    if (bytes.isEmpty) return null;
    _coverCache[id] = bytes;
    while (_coverCache.length > 32 ||
        _coverCache.values.fold<int>(0, (total, cover) => total + cover.length) > _maxCoverCacheBytes) {
      _coverCache.remove(_coverCache.keys.first);
    }
    return bytes;
  }

  @override
  void close() {
    _apiKeyRejected = false;
    _coverCache.clear();
    super.close();
  }
}
