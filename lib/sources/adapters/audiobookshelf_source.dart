import 'dart:convert';

import '../source_models.dart';
import '../source_transport.dart';
import 'webdav_source.dart';

class AudiobookshelfSourceAdapter extends SourceAdapter {
  AudiobookshelfSourceAdapter(super.source, super.transport, this.credentials, {this.persistCredentials});
  final SourceCredentials credentials;
  final Future<void> Function(Map<String, String> credentials)? persistCredentials;
  Map<String, String>? _memoryCredentials;
  Future<Map<String, String>>? _loginInFlight;
  Future<Map<String, String>>? _refreshInFlight;

  Uri url(String path, [Map<String, String>? query]) {
    final base = Uri.parse(source.endpoint.endsWith('/') ? source.endpoint : '${source.endpoint}/');
    return base.resolve(path.replaceFirst(RegExp(r'^/'), '')).replace(queryParameters: query);
  }

  Uri _authUrl(String path) => url(path);

  Future<Map<String, String>> _savedCredentials() async => _memoryCredentials ?? await credentials();

  String? _accessToken(Map<String, String> saved) {
    final access = saved['accessToken']?.trim();
    if (access?.isNotEmpty == true) return access;
    final legacy = saved['token']?.trim();
    return legacy?.isNotEmpty == true ? legacy : null;
  }

  bool _hasLoginCredentials(Map<String, String> saved) =>
      saved['username']?.trim().isNotEmpty == true && saved['password']?.isNotEmpty == true;

  bool _expiresSoon(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = sourceMap(jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))));
      final expiry = sourceInt(payload['exp']);
      return expiry != null && expiry * 1000 <= DateTime.now().add(const Duration(minutes: 1)).millisecondsSinceEpoch;
    } on Object {
      return false;
    }
  }

  Future<Map<String, String>> _saveSession(
    Map<String, String> saved,
    Map<String, dynamic> response,
  ) async {
    final user = sourceMap(response['user']);
    final access = '${user['accessToken'] ?? response['accessToken'] ?? user['token'] ?? response['token'] ?? ''}'.trim();
    final refresh = '${user['refreshToken'] ?? response['refreshToken'] ?? ''}'.trim();
    if (access.isEmpty) throw const SourceException(SourceFailure.authentication);
    final next = Map<String, String>.from(saved);
    if (user['accessToken'] != null || response['accessToken'] != null) {
      next['accessToken'] = access;
      next['authMode'] = 'jwt';
      next.remove('token');
    } else {
      // Audiobookshelf <2.26 returns a single long-lived bearer token.
      next['token'] = access;
      next['authMode'] = 'legacyLogin';
      next.remove('accessToken');
    }
    if (refresh.isEmpty) {
      next.remove('refreshToken');
    } else {
      next['refreshToken'] = refresh;
    }
    if (persistCredentials != null) await persistCredentials!(next);
    _memoryCredentials = next;
    return next;
  }

  Future<Map<String, String>> _login(Map<String, String> saved) {
    final pending = _loginInFlight;
    if (pending != null) return pending;
    late final Future<Map<String, String>> request;
    request = _performLogin(saved).whenComplete(() {
      if (identical(_loginInFlight, request)) _loginInFlight = null;
    });
    _loginInFlight = request;
    return request;
  }

  Future<Map<String, String>> _performLogin(Map<String, String> saved) async {
    final username = saved['username']?.trim() ?? '';
    final password = saved['password'] ?? '';
    if (username.isEmpty || password.isEmpty) throw const SourceException(SourceFailure.authentication);
    final response = await transport.json(
      'POST',
      _authUrl('login'),
      headers: const {'Content-Type': 'application/json', 'x-return-tokens': 'true'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return _saveSession(saved, response);
  }

  Future<Map<String, String>> _refresh(Map<String, String> saved) {
    final current = _memoryCredentials;
    if (current != null && current['refreshToken'] != saved['refreshToken']) return Future.value(current);
    final pending = _refreshInFlight;
    if (pending != null) return pending;
    late final Future<Map<String, String>> request;
    request = _performRefresh(saved).whenComplete(() {
      if (identical(_refreshInFlight, request)) _refreshInFlight = null;
    });
    _refreshInFlight = request;
    return request;
  }

  Future<Map<String, String>> _performRefresh(Map<String, String> saved) async {
    final refreshToken = saved['refreshToken']?.trim() ?? '';
    if (refreshToken.isEmpty) return _login(saved);
    final response = await transport.json(
      'POST',
      _authUrl('auth/refresh'),
      headers: {'x-refresh-token': refreshToken},
    );
    return _saveSession(saved, response);
  }

  Future<Map<String, String>> _renew(Map<String, String> saved) async {
    if (saved['refreshToken']?.isNotEmpty == true) {
      try {
        return await _refresh(saved);
      } on SourceException catch (error) {
        if (error.status != 401 || !_hasLoginCredentials(saved)) rethrow;
      }
    }
    if (_hasLoginCredentials(saved)) return _login(saved);
    throw const SourceException(SourceFailure.authentication);
  }

  Future<Map<String, String>> _authorizedCredentials({bool forceRefresh = false}) async {
    var saved = await _savedCredentials();
    final access = _accessToken(saved);
    if (forceRefresh) return _renew(saved);
    if (_hasLoginCredentials(saved) && saved['authMode'] == null && saved['refreshToken'] == null) {
      return _login(saved);
    }
    if (access == null) {
      if (_hasLoginCredentials(saved) && saved['authMode'] != 'legacyLogin') return _login(saved);
      return _renew(saved);
    }
    if (saved['refreshToken']?.isNotEmpty == true && _expiresSoon(access)) {
      saved = await _renew(saved);
    }
    return saved;
  }

  Future<Map<String, String>> headers() async {
    final saved = await _authorizedCredentials();
    final access = _accessToken(saved);
    if (access == null) throw const SourceException(SourceFailure.authentication);
    return {'Authorization': 'Bearer $access'};
  }

  Future<String> _requestText(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    Object? body,
  }) async {
    var saved = await _authorizedCredentials();
    Future<String> request(Map<String, String> auth) => transport.text(
      method,
      uri,
      headers: {...auth, ...headers},
      body: body,
    );
    try {
      return await request(await headersFor(saved));
    } on SourceException catch (error) {
      if (error.status != 401) rethrow;
      saved = await _renew(saved);
      return request(await headersFor(saved));
    }
  }

  Future<Map<String, String>> headersFor(Map<String, String> saved) async {
    final access = _accessToken(saved);
    if (access == null) throw const SourceException(SourceFailure.authentication);
    return {'Authorization': 'Bearer $access'};
  }

  Future<Map<String, dynamic>> api(String method, String path, {Map<String, String>? query, Object? body}) async {
    final raw = await _requestText(
      method,
      url(path, query),
      headers: body != null ? const {'Content-Type': 'application/json'} : const {},
      body: body == null ? null : jsonEncode(body),
    );
    return sourceMap(jsonDecode(raw));
  }

  @override
  Future<void> refreshAuthorization() async {
    final saved = await _savedCredentials();
    if (saved['refreshToken']?.isNotEmpty == true || _accessToken(saved) == null) await _renew(saved);
  }
  @override
  SourceCapabilities get capabilities =>
      const SourceCapabilities(audioProgress: true, readingProgress: true, annotations: true);
  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    final library = parent ?? source.root;
    if (library.isEmpty) {
      final data = await api('GET', 'api/libraries');
      return SourcePage(
        sourceList(data['libraries']).map((value) {
          final j = sourceMap(value);
          return SourceEntry(
            sourceId: source.id,
            id: j['id'] as String,
            title: j['name'] as String? ?? '',
            kind: SourceItemKind.folder,
          );
        }).toList(),
      );
    }
    final page = int.tryParse(cursor ?? '') ?? 0;
    final data = await api(
      'GET',
      'api/libraries/$library/items',
      query: {'limit': '100', 'page': '$page', 'expanded': '1'},
    );
    final entries = sourceList(data['results'])
        .map((j) => _entry(sourceMap(j), library))
        .where((e) => query == null || '${e.title} ${e.author} ${e.series}'.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final total = sourceInt(data['total']) ?? 0;
    return SourcePage(entries, next: (page + 1) * 100 < total ? '${page + 1}' : null);
  }

  SourceEntry _entry(Map<String, dynamic> j, String? parent) {
    final media = sourceMap(j['media']), meta = sourceMap(sourceMap(j['media'])['metadata']);
    final id = j['id'] as String;
    final files = <PublicationFile>[];
    final audio = sourceList(media['audioFiles']).map(sourceMap).toList()
      ..sort((a, b) => (sourceInt(a['index']) ?? 0).compareTo(sourceInt(b['index']) ?? 0));
    for (final file in audio) {
      final metadata = sourceMap(file['metadata']);
      files.add(
        PublicationFile(
          id: jsonEncode({'item': id, 'ino': file['ino']}),
          name: metadata['filename'] as String? ?? '${file['ino']}.mp3',
          mimeType: file['mimeType'] as String? ?? 'audio/mpeg',
          size: sourceInt(metadata['size']),
          durationMs: ((file['duration'] as num? ?? 0) * 1000).round(),
          revision: metadata['mtimeMs']?.toString(),
        ),
      );
    }
    final primary = sourceMap(media['ebookFile']);
    final primaryIno = primary['ino'];
    final allFiles = sourceList(j['libraryFiles']).map(sourceMap).toList();
    if (primary.isNotEmpty && !allFiles.any((f) => f['ino'] == primaryIno)) allFiles.add(primary);
    for (final file in allFiles) {
      final metadata = sourceMap(file['metadata']);
      final name = metadata['filename'] as String? ?? '';
      if (classifySourceFile(name) != SourceItemKind.ebook) continue;
      files.add(
        PublicationFile(
          id: jsonEncode({'item': id, 'ino': file['ino']}),
          name: name,
          mimeType: file['mimeType'] as String? ?? '',
          size: sourceInt(metadata['size']),
          revision: metadata['mtimeMs']?.toString(),
          primary: file['ino'] == primaryIno,
        ),
      );
    }
    String names(Object? value) =>
        value is String ? value : sourceList(value).map((v) => v is String ? v : sourceMap(v)['name'] ?? '').join(', ');
    final series = sourceList(meta['series']).map(sourceMap).firstOrNull;
    return SourceEntry(
      sourceId: source.id,
      id: id,
      title: meta['title'] as String? ?? '',
      kind: audio.isEmpty ? SourceItemKind.ebook : SourceItemKind.audiobook,
      parentId: parent,
      author: names(meta['authors'] ?? meta['authorName']),
      narrator: names(meta['narrators'] ?? meta['narratorName']),
      series: series?['name'] as String? ?? '',
      seriesOrder: double.tryParse('${series?['sequence']}'),
      description: meta['description'] as String? ?? '',
      language: meta['language'] as String? ?? '',
      coverId: id,
      files: files,
      chapters: sourceList(media['chapters']).map((v) {
        final c = sourceMap(v);
        return BookChapter(
          title: c['title'] as String? ?? '',
          startMs: ((c['start'] as num? ?? 0) * 1000).round(),
          endMs: ((c['end'] as num? ?? 0) * 1000).round(),
        );
      }).toList(),
    );
  }

  @override
  Future<SourceEntry> hydrate(SourceEntry entry) async =>
      _entry(await api('GET', 'api/items/${entry.id}', query: {'expanded': '1'}), entry.parentId);
  @override
  Future<ContentLease?> cover(SourceEntry entry) async =>
      ContentLease(url('api/items/${entry.id}/cover'), headers: await headers());
  @override
  bool supportsProgress(SourceEntry entry, PublicationProgress progress) {
    if (progress.mode == PublicationMode.reading) {
      return entry.ebooks.any(
        (f) => f.primary && f.fingerprint == progress.edition && f.name.toLowerCase().endsWith('.epub'),
      );
    }
    return progress.edition == sourceDigest(jsonEncode(entry.audio.map((f) => f.fingerprint).toList()));
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async {
    final ref = sourceMap(jsonDecode(file.id));
    return ContentLease(url('api/items/${ref['item']}/file/${ref['ino']}'), headers: await headers(), size: file.size);
  }

  @override
  Future<PublicationProgress?> readProgress(SourceEntry entry, PublicationProgress local) async {
    final j = await api('GET', 'api/me/progress/${entry.id}');
    if (j.isEmpty) return null;
    return local.copyWith(
      positionMs: ((j['currentTime'] as num? ?? 0) * 1000).round(),
      fraction: (j[local.mode == PublicationMode.reading ? 'ebookProgress' : 'progress'] as num?)?.toDouble() ?? 0,
      locator: local.mode == PublicationMode.reading && j['ebookLocation'] is String
          ? ReadingLocator(href: '', cfi: j['ebookLocation'] as String)
          : null,
      finished: local.mode == PublicationMode.reading
          ? ((j['ebookProgress'] as num? ?? 0) >= 1)
          : j['isFinished'] as bool? ?? false,
      updatedAt: sourceInt(j['lastUpdate']) ?? 0,
      session: 'audiobookshelf',
    );
  }

  @override
  Future<void> writeProgress(SourceEntry entry, PublicationProgress progress) async {
    final reading = progress.mode == PublicationMode.reading;
    if (reading && !entry.ebooks.any((f) => f.primary && f.fingerprint == progress.edition)) {
      throw const SourceException(SourceFailure.unsupported);
    }
    final body = <String, dynamic>{
      if (reading) ...{
        'ebookLocation': progress.locator?.cfi,
        'ebookProgress': progress.fraction,
      } else ...{
        'currentTime': progress.positionMs / 1000,
        'progress': progress.fraction,
        'isFinished': progress.finished,
      },
    };
    await _requestText(
      'PATCH',
      url('api/me/progress/${entry.id}'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  @override
  Future<void> writeAnnotation(SourceEntry entry, BookAnnotation annotation) async {
    if (annotation.mode != PublicationMode.listening || annotation.positionMs == null) {
      throw const SourceException(SourceFailure.unsupported);
    }
    final time = (annotation.positionMs! / 1000).floor();
    var method = annotation.deleted ? 'DELETE' : 'POST';
    if (!annotation.deleted) {
      final existing = await api('GET', 'api/me/bookmarks/${entry.id}');
      if (sourceList(existing['bookmarks']).any((b) => sourceInt(sourceMap(b)['time']) == time)) method = 'PATCH';
    }
    try {
      await _requestText(
        method,
        url('api/me/item/${entry.id}/bookmark${annotation.deleted ? '/$time' : ''}'),
        headers: const {'Content-Type': 'application/json'},
        body: annotation.deleted ? null : jsonEncode({'time': time, 'title': annotation.note}),
      );
    } on SourceException catch (e) {
      if (!annotation.deleted || e.status != 404) rethrow;
    }
  }

  @override
  Future<List<BookAnnotation>> readAnnotations(SourceEntry entry, PublicationProgress progress) async {
    if (progress.mode != PublicationMode.listening) return [];
    final data = await api('GET', 'api/me/bookmarks/${entry.id}');
    return sourceList(data['bookmarks'])
        .map(sourceMap)
        .map(
          (j) => BookAnnotation(
            id: 'abs:${sourceDigest('${entry.key}:${j['time']}')}',
            entryKey: entry.key,
            edition: progress.edition,
            mode: PublicationMode.listening,
            positionMs: (sourceInt(j['time']) ?? 0) * 1000,
            note: j['title'] as String? ?? '',
            updatedAt: sourceInt(j['updatedAt']) ?? 0,
          ),
        )
        .toList();
  }
}
