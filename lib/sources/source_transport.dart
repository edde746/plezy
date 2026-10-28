import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'source_models.dart';
import 'comic_document.dart';

bool sameSourceOrigin(Uri a, Uri b) => a.scheme == b.scheme && a.host == b.host && a.port == b.port;

class SourceTransport {
  SourceTransport({http.Client? client, this.allowHttp = false}) : _client = client ?? http.Client();
  final http.Client _client;
  final bool allowHttp;
  bool _closed = false;
  bool get isClosed => _closed;

  void validate(Uri uri) {
    if (uri.userInfo.isNotEmpty ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && !(allowHttp && uri.scheme == 'http'))) {
      throw const SourceException(SourceFailure.permission);
    }
  }

  Future<http.StreamedResponse> send(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    Object? body,
    bool redirects = false,
    Future<void>? abort,
  }) async {
    validate(uri);
    var target = uri;
    // Byte offsets/validators must describe the stored media representation,
    // not an HTTP-compressed variant silently inflated by HttpClient.
    var requestHeaders = <String, String>{'Accept-Encoding': 'identity', ...headers};
    for (var hop = 0; hop < 6; hop++) {
      if (_closed) throw const SourceException(SourceFailure.cancelled);
      final request = http.AbortableRequest(method, target, abortTrigger: abort)..followRedirects = false;
      request.headers.addAll(requestHeaders);
      if (body is String) request.body = body;
      if (body is List<int>) request.bodyBytes = body;
      if (body is Map<String, String>) request.bodyFields = body;
      final response = await _client.send(request).timeout(const Duration(seconds: 30));
      if (!redirects || !const {301, 302, 303, 307, 308}.contains(response.statusCode)) return response;
      final location = response.headers['location'];
      await response.stream.drain<void>().timeout(const Duration(seconds: 10));
      if (location == null) throw const SourceException(SourceFailure.invalidData);
      final next = target.resolve(location);
      validate(next);
      if (target.scheme == 'https' && next.scheme != 'https') throw const SourceException(SourceFailure.permission);
      if (!sameSourceOrigin(target, next)) {
        requestHeaders = Map.fromEntries(
          requestHeaders.entries.where(
            (e) => const {'range', 'accept', 'accept-encoding', 'if-range'}.contains(e.key.toLowerCase()),
          ),
        );
      }
      target = next;
    }
    throw const SourceException(SourceFailure.invalidData);
  }

  static void check(int status) {
    if (status >= 200 && status < 300) return;
    throw SourceException(switch (status) {
      401 => SourceFailure.authentication,
      403 => SourceFailure.permission,
      404 => SourceFailure.unavailable,
      409 || 412 => SourceFailure.conflict,
      _ => SourceFailure.unavailable,
    }, status: status);
  }

  Future<String> text(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    Object? body,
    int limit = 8 * 1024 * 1024,
    bool redirects = false,
  }) async {
    final response = await send(method, uri, headers: headers, body: body, redirects: redirects);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.stream.drain<void>().timeout(const Duration(seconds: 10));
      check(response.statusCode);
    }
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(const Duration(seconds: 30))) {
      if (bytes.length + chunk.length > limit) throw const SourceException(SourceFailure.invalidData);
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes);
  }

  Future<Object?> jsonValue(String method, Uri uri, {Map<String, String> headers = const {}, Object? body}) async =>
      jsonDecode(await text(method, uri, headers: headers, body: body));

  Future<Map<String, dynamic>> json(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    Object? body,
  }) async => sourceMap(await jsonValue(method, uri, headers: headers, body: body));

  void close() {
    _closed = true;
    _client.close();
  }
}

abstract class SourceAdapter {
  SourceAdapter(this.source, this.transport);
  final FileSource source;
  final SourceTransport transport;
  SourceCapabilities get capabilities;
  Future<SourcePage> browse({String? parent, String? cursor, String? query});
  Future<SourceEntry> hydrate(SourceEntry entry) async => entry;
  Future<ContentLease> resolve(PublicationFile file);
  Future<int?> contentSize(PublicationFile file) async => file.size;
  Future<SourceByteStream?> openContent(PublicationFile file, {required int offset, required int length}) async => null;
  Future<ComicPageSource?> comicPages(PublicationFile file) async => null;

  Future<ContentLease?> cover(SourceEntry entry) async => null;
  Future<List<int>?> coverBytes(SourceEntry entry) async => null;
  Future<void> refreshAuthorization() async {}
  bool supportsProgress(SourceEntry entry, PublicationProgress progress) =>
      progress.mode == PublicationMode.reading ? capabilities.readingProgress : capabilities.audioProgress;
  Future<PublicationProgress?> readProgress(SourceEntry entry, PublicationProgress local) async => null;
  Future<List<BookAnnotation>> readAnnotations(SourceEntry entry, PublicationProgress progress) async => [];
  Future<void> writeProgress(SourceEntry entry, PublicationProgress progress) async =>
      throw const SourceException(SourceFailure.unsupported);
  Future<void> writeAnnotation(SourceEntry entry, BookAnnotation annotation) async =>
      throw const SourceException(SourceFailure.unsupported);
  void close() => transport.close();
}
