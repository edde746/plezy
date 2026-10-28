import 'dart:convert';

import 'package:xml/xml.dart';

import '../source_models.dart';
import '../source_transport.dart';
import 'webdav_source.dart';

class PodcastRssSourceAdapter extends SourceAdapter {
  PodcastRssSourceAdapter(super.source, super.transport, this.credentials);
  final SourceCredentials credentials;
  final Map<String, Uri> _enclosures = {};
  final Map<String, Uri> _covers = {};
  final Set<String> _coverChecked = {};
  _PodcastFeed? _feedCache;
  Future<_PodcastFeed>? _feedLoading;
  bool _closed = false;

  Uri _feedUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.toString().length > 8192 ||
        (uri.scheme != 'https' && !(transport.allowHttp && uri.scheme == 'http'))) {
      throw const SourceException(SourceFailure.permission);
    }
    transport.validate(uri);
    return uri;
  }

  Future<Map<String, String>> _credentials() => credentials();

  Future<Map<String, String>> _headers(Uri target) async {
    final saved = await _credentials();
    final origin = Uri.parse(source.endpoint);
    final username = saved['username'] ?? '';
    final password = saved['password'] ?? '';
    if (!sameSourceOrigin(origin, target) || (username.isEmpty && password.isEmpty)) return const {};
    return {
      'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
      'Accept': 'application/rss+xml, application/atom+xml, application/xml, text/xml',
    };
  }

  Future<_PodcastFeed> _loadFeed({bool refresh = false}) {
    if (_closed) throw const SourceException(SourceFailure.cancelled);
    final cached = _feedCache;
    if (!refresh && cached != null) return Future.value(cached);
    final pending = _feedLoading;
    if (pending != null) return pending;
    late final Future<_PodcastFeed> request;
    request = _fetchFeed()
        .then((feed) {
          if (!_closed) _feedCache = feed;
          return feed;
        })
        .whenComplete(() {
          if (identical(_feedLoading, request)) _feedLoading = null;
        });
    _feedLoading = request;
    return request;
  }

  Future<_PodcastFeed> _fetchFeed() async {
    final saved = await _credentials();
    final feedUri = _feedUri(saved['feedUrl'] ?? '');
    final response = await transport.text(
      'GET',
      feedUri,
      headers: {
        'Accept': 'application/rss+xml, application/atom+xml, application/xml, text/xml',
        ...await _headers(feedUri),
      },
      limit: 6 * 1024 * 1024,
      redirects: true,
    );
    if (_closed) throw const SourceException(SourceFailure.cancelled);
    final document = XmlDocument.parse(response);
    final root = document.rootElement;
    final rssChannel = root.name.local == 'rss'
        ? root.childElements.where((e) => e.name.local == 'channel').firstOrNull
        : root.name.local == 'channel'
        ? root
        : null;
    final atom = root.name.local == 'feed' ? root : null;
    if (rssChannel == null && atom == null) throw const SourceException(SourceFailure.invalidData);

    String childText(XmlElement parent, String name) =>
        parent.childElements.where((e) => e.name.local == name).firstOrNull?.innerText.trim() ?? '';
    String title = childText(rssChannel ?? atom!, 'title');
    String author = childText(rssChannel ?? atom!, 'author');
    Uri? artwork;
    if (rssChannel != null) {
      final standardImage = rssChannel.childElements.where((e) => e.name.local == 'image').firstOrNull;
      final imageUrl = standardImage == null ? '' : childText(standardImage, 'url');
      final itunesImage = rssChannel.childElements
          .where((e) => e.name.local == 'image' && e.getAttribute('href') != null)
          .firstOrNull
          ?.getAttribute('href');
      final rawImage = itunesImage ?? imageUrl;
      if (rawImage.isNotEmpty) artwork = _safeResolve(feedUri, rawImage);
    } else {
      final logo = childText(atom!, 'logo').isNotEmpty ? childText(atom, 'logo') : childText(atom, 'icon');
      if (logo.isNotEmpty) artwork = _safeResolve(feedUri, logo);
      author =
          atom.childElements
              .where((e) => e.name.local == 'author')
              .firstOrNull
              ?.childElements
              .where((e) => e.name.local == 'name')
              .firstOrNull
              ?.innerText
              .trim() ??
          author;
    }
    if (title.isEmpty) title = source.name;
    final feedIdentity = _urlIdentity(feedUri);
    final nodes = rssChannel != null
        ? rssChannel.childElements.where((e) => e.name.local == 'item')
        : atom!.childElements.where((e) => e.name.local == 'entry');
    final episodes = <_PodcastEpisode>[];
    _enclosures.clear();
    _covers.clear();
    _coverChecked
      ..clear()
      ..add('podcast:episodes');
    if (artwork != null) _covers['podcast:episodes'] = artwork;
    for (final node in nodes.take(1000)) {
      final episodeTitle = childText(node, 'title');
      if (episodeTitle.isEmpty) continue;
      final links = node.childElements.toList(growable: false);
      XmlElement? enclosure;
      if (rssChannel != null) {
        enclosure = links.where((e) => e.name.local == 'enclosure').firstOrNull;
      } else {
        enclosure = links.where((e) => e.name.local == 'link' && e.getAttribute('rel') == 'enclosure').firstOrNull;
      }
      final rawUrl = enclosure?.getAttribute(rssChannel != null ? 'url' : 'href');
      if (rawUrl == null || rawUrl.isEmpty) continue;
      final audioUri = _safeResolve(feedUri, rawUrl);
      if (audioUri == null) continue;
      final declaredMime = (enclosure?.getAttribute('type') ?? '').split(';').first.trim().toLowerCase();
      final mime = declaredMime.startsWith('audio/') ? declaredMime : _audioMime(audioUri, declaredMime);
      if (!mime.startsWith('audio/')) continue;

      final guid = rssChannel != null ? childText(node, 'guid') : childText(node, 'id');
      final published = rssChannel != null
          ? (childText(node, 'pubDate').isNotEmpty ? childText(node, 'pubDate') : childText(node, 'date'))
          : (childText(node, 'published').isNotEmpty ? childText(node, 'published') : childText(node, 'updated'));
      final identity = guid.isNotEmpty ? guid : '$episodeTitle\u0000$published\u0000${_urlIdentity(audioUri)}';
      final scopedIdentity = '$feedIdentity\u0000$identity';
      final id = 'episode:${sourceDigest(scopedIdentity)}';
      final rawLength = sourceInt(enclosure?.getAttribute('length'));
      final length = rawLength == null || rawLength < 0 ? null : rawLength;
      final durationText = links.where((e) => e.name.local == 'duration').firstOrNull?.innerText.trim() ?? '';
      final durationMs = _duration(durationText);
      final description = rssChannel != null
          ? (childText(node, 'encoded').isNotEmpty ? childText(node, 'encoded') : childText(node, 'description'))
          : (childText(node, 'summary').isNotEmpty ? childText(node, 'summary') : childText(node, 'content'));
      final episodeAuthor = rssChannel != null
          ? (childText(node, 'creator').isNotEmpty ? childText(node, 'creator') : childText(node, 'author'))
          : node.childElements
                    .where((e) => e.name.local == 'author')
                    .firstOrNull
                    ?.childElements
                    .where((e) => e.name.local == 'name')
                    .firstOrNull
                    ?.innerText
                    .trim() ??
                '';
      final enclosureImage = links
          .where((e) => e.name.local == 'image' && e.getAttribute('href') != null)
          .firstOrNull
          ?.getAttribute('href');
      final cover = enclosureImage == null ? artwork : _safeResolve(feedUri, enclosureImage) ?? artwork;
      final fileName = _filename(episodeTitle, audioUri, mime);
      final entry = SourceEntry(
        sourceId: source.id,
        id: id,
        title: episodeTitle,
        kind: SourceItemKind.music,
        parentId: 'podcast:episodes',
        author: episodeAuthor.isEmpty ? author : episodeAuthor,
        series: title,
        description: _plainText(description),
        coverId: cover == null ? null : sourceDigest(_urlIdentity(cover)),
        releaseYear: DateTime.tryParse(published)?.year,
        identifiers: {
          'feed': source.id,
          'guid': sourceDigest(scopedIdentity),
          if (published.isNotEmpty) 'published': published,
        },
        files: [
          PublicationFile(
            id: id,
            name: fileName,
            mimeType: mime,
            size: length,
            durationMs: durationMs,
            revision: sourceDigest(jsonEncode([_urlIdentity(audioUri), mime, length, published])),
          ),
        ],
      );
      _enclosures[id] = audioUri;
      _coverChecked.add(id);
      if (cover != null) _covers[id] = cover;
      episodes.add(_PodcastEpisode(entry));
    }
    return _PodcastFeed(title: title, author: author, episodes: episodes);
  }

  Uri _resolve(Uri base, String value) {
    final uri = base.resolve(value.trim());
    if (uri.userInfo.isNotEmpty || uri.hasFragment || uri.host.isEmpty || uri.toString().length > 8192) {
      throw const SourceException(SourceFailure.permission);
    }
    transport.validate(uri);
    return uri;
  }

  Uri? _safeResolve(Uri base, String value) {
    try {
      return _resolve(base, value);
    } on Object {
      return null;
    }
  }

  String _urlIdentity(Uri uri) {
    final query = <String, String>{
      for (final entry in uri.queryParameters.entries)
        if (!sourceCredentialParameter.hasMatch(entry.key)) entry.key: entry.value,
    };
    return uri.replace(queryParameters: query, fragment: '').toString();
  }

  static String _audioMime(Uri uri, String declared) {
    if (RegExp(r'^audio/[a-z0-9][a-z0-9!#$&^_.+-]{0,63}$').hasMatch(declared)) {
      return switch (declared) {
        'audio/mp3' || 'audio/x-mp3' => 'audio/mpeg',
        'audio/x-m4a' => 'audio/mp4',
        'audio/x-wav' || 'audio/wave' => 'audio/wav',
        _ => declared,
      };
    }
    final suffix = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last.split('.').last.toLowerCase();
    return switch (suffix) {
      'mp3' => 'audio/mpeg',
      'm4a' || 'm4b' || 'mp4' => 'audio/mp4',
      'aac' => 'audio/aac',
      'ogg' => 'audio/ogg',
      'opus' => 'audio/opus',
      'flac' => 'audio/flac',
      'wav' => 'audio/wav',
      'aif' || 'aiff' => 'audio/aiff',
      _ => declared,
    };
  }

  static String _filename(String title, Uri uri, String mime) {
    final raw = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final candidate = raw.contains('.') ? raw.split('.').last.toLowerCase() : '';
    final fallback = switch (mime) {
      'audio/mpeg' => '.mp3',
      'audio/mp4' => '.m4a',
      'audio/aac' => '.aac',
      'audio/ogg' => '.ogg',
      'audio/opus' => '.opus',
      'audio/flac' => '.flac',
      'audio/wav' => '.wav',
      'audio/aiff' => '.aiff',
      'audio/x-m4a' => '.m4a',
      'audio/x-wav' || 'audio/wave' => '.wav',
      'audio/mp3' || 'audio/x-mp3' => '.mp3',
      _ => '.mp3',
    };
    final extension = RegExp(r'^[a-z0-9]{1,8}$').hasMatch(candidate) ? '.$candidate' : fallback;
    return title.toLowerCase().endsWith(extension.toLowerCase()) ? title : '$title$extension';
  }

  static int? _duration(String value) {
    if (value.isEmpty) return null;
    final numbers = value.split(':').map((part) => int.tryParse(part.trim())).toList();
    if (numbers.any((part) => part == null)) {
      final seconds = double.tryParse(value);
      return seconds == null || !seconds.isFinite || seconds <= 0 || seconds > 7 * 24 * 60 * 60
          ? null
          : (seconds * 1000).round();
    }
    var seconds = 0;
    for (final part in numbers) {
      seconds = seconds * 60 + part!;
    }
    return seconds <= 0 || seconds > 7 * 24 * 60 * 60 ? null : seconds * 1000;
  }

  static String _plainText(String value) {
    final text = value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAllMapped(RegExp(r'\s+([,.;:!?])'), (match) => match.group(1)!);
    return text.length > 8000 ? text.substring(0, 8000) : text;
  }

  @override
  // Episode resume state stays in PlezyNG; RSS has no shared progress-write API.
  SourceCapabilities get capabilities => const SourceCapabilities();

  @override
  Future<SourcePage> browse({String? parent, String? cursor, String? query}) async {
    if (cursor != null && cursor != 'episodes') throw const SourceException(SourceFailure.invalidData);
    final feed = await _loadFeed(refresh: query?.trim().isNotEmpty != true);
    if (parent == 'podcast:episodes' || (parent == null && query?.trim().isNotEmpty == true)) {
      final episodes = feed.episodes.map((episode) => episode.entry).toList();
      final normalized = query?.trim().toLowerCase();
      return SourcePage(
        normalized == null || normalized.isEmpty
            ? episodes
            : episodes
                  .where(
                    (e) => '${e.title} ${e.author} ${e.series} ${e.description}'.toLowerCase().contains(normalized),
                  )
                  .toList(),
        title: feed.title,
      );
    }
    if (parent != null) throw const SourceException(SourceFailure.invalidData);
    return SourcePage([
      SourceEntry(
        sourceId: source.id,
        id: 'podcast:episodes',
        title: feed.title,
        kind: SourceItemKind.folder,
        author: feed.author,
        description: '${feed.episodes.length} episodes',
        coverId: _covers['podcast:episodes'] == null ? null : sourceDigest(_urlIdentity(_covers['podcast:episodes']!)),
      ),
    ], title: feed.title);
  }

  @override
  Future<SourceEntry> hydrate(SourceEntry entry) async {
    if (entry.id == 'podcast:episodes') {
      final feed = await _loadFeed();
      return entry.copyWith(title: feed.title, description: '${feed.episodes.length} episodes');
    }
    final feed = await _loadFeed();
    return feed.episodes.map((episode) => episode.entry).where((e) => e.id == entry.id).firstOrNull ??
        (throw const SourceException(SourceFailure.unavailable));
  }

  @override
  Future<ContentLease> resolve(PublicationFile file) async {
    final current = await _loadFeed(refresh: true);
    final uri = _enclosures[file.id];
    final episode = current.episodes.where((episode) => episode.entry.id == file.id).firstOrNull;
    if (uri == null || episode == null) {
      throw const SourceException(SourceFailure.unavailable);
    }
    return ContentLease(uri, headers: await _headers(uri), size: episode.entry.files.firstOrNull?.size ?? file.size);
  }

  @override
  Future<ContentLease?> cover(SourceEntry entry) async {
    if (!_coverChecked.contains(entry.id)) await _loadFeed();
    final uri = _covers[entry.id];
    return uri == null ? null : ContentLease(uri, headers: await _headers(uri));
  }

  @override
  Future<List<int>?> coverBytes(SourceEntry entry) async {
    if (!_coverChecked.contains(entry.id)) await _loadFeed();
    final uri = _covers[entry.id];
    if (uri == null) return null;
    final response = await transport.send('GET', uri, headers: await _headers(uri), redirects: true);
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
    return bytes.isEmpty ? null : bytes;
  }

  @override
  void close() {
    _closed = true;
    _feedCache = null;
    _feedLoading = null;
    _enclosures.clear();
    _covers.clear();
    _coverChecked.clear();
    super.close();
  }
}

class _PodcastEpisode {
  const _PodcastEpisode(this.entry);
  final SourceEntry entry;
}

class _PodcastFeed {
  const _PodcastFeed({required this.title, required this.author, required this.episodes});
  final String title;
  final String author;
  final List<_PodcastEpisode> episodes;
}
