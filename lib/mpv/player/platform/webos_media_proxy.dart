import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// A loopback-only, per-player bridge for LG's webOS media pipeline.
///
/// LG's native video plugin does not forward HTTP headers. This proxy keeps
/// server credentials in the Dart process, forwards byte ranges, and rewrites
/// HLS children through short-lived opaque local URLs. Only the exact source
/// origin is reachable through a proxy resource, so playlist contents cannot
/// turn the TV into an arbitrary network proxy.
class WebOSMediaProxy {
  WebOSMediaProxy._(this._server) {
    _server.listen(_handle, onError: (_) {});
  }

  static const int _maxResources = 12000;
  static const int _maxPlaylistBytes = 4 * 1024 * 1024;
  static const int _maxRedirects = 4;
  static final RegExp _headerName = RegExp(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$");
  static final RegExp _range = RegExp(r'^bytes=\d*-\d*(?:,\d*-\d*)*$');
  static final RegExp _uriAttribute = RegExp(r'URI="([^"]+)"');

  final HttpServer _server;
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..idleTimeout = const Duration(seconds: 15)
    ..autoUncompress = false;
  final Random _random = Random.secure();
  final Map<String, _ProxyResource> _resources = {};
  final Map<String, String> _resourceKeys = {};
  bool _closed = false;

  static Future<WebOSMediaProxy> bind() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0, shared: false);
    return WebOSMediaProxy._(server);
  }

  int get port => _server.port;

  /// Registers a server URL and returns an opaque loopback URL for NDL media.
  Uri register(Uri source, {Map<String, String>? headers}) {
    if (_closed) throw StateError('The webOS media proxy is closed');
    final normalized = _normalizeSource(source, headers ?? const {});
    final uri = normalized.uri;
    if (!_isHttp(uri)) throw const FormatException('Media URL must use HTTP or HTTPS');

    final cacheKey = _cacheKey(uri, normalized.headers);
    final key = _resourceKeys.putIfAbsent(cacheKey, () {
      if (_resources.length >= _maxResources) {
        throw StateError('The webOS media playlist contains too many resources');
      }
      final newKey = _randomToken();
      _resources[newKey] = _ProxyResource(uri, normalized.headers, uri.origin);
      return newKey;
    });
    return Uri(scheme: 'http', host: InternetAddress.loopbackIPv4.address, port: port, pathSegments: ['r', key]);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _resources.clear();
    _resourceKeys.clear();
    _client.close(force: true);
    await _server.close(force: true);
  }

  String _randomToken() {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256), growable: false);
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _cacheKey(Uri uri, Map<String, String> headers) {
    final stableHeaders = headers.entries.toList()..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return '${uri.toString()}\n${stableHeaders.map((entry) => '${entry.key.toLowerCase()}:${entry.value}').join('\n')}';
  }

  Future<void> _handle(HttpRequest request) async {
    if (request.method != 'GET' && request.method != 'HEAD') {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      request.response.headers.set(HttpHeaders.allowHeader, 'GET, HEAD');
      await request.response.close();
      return;
    }

    final parts = request.uri.pathSegments;
    final resource = parts.length == 2 && parts.first == 'r' && request.uri.query.isEmpty ? _resources[parts[1]] : null;
    if (resource == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    try {
      await _serve(request, resource);
    } catch (_) {
      try {
        request.response.statusCode = HttpStatus.badGateway;
        request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
        await request.response.close();
      } on HttpException {
        // Headers may already have been sent while streaming a media body.
      } on IOException {
        // The media pipeline may close an interrupted range request itself.
      } on StateError {
        // The response may already be closed after an upstream pipe failure.
      }
    }
  }

  Future<void> _serve(HttpRequest downstream, _ProxyResource resource) async {
    final method = downstream.method;
    var current = resource.uri;
    HttpClientResponse? upstream;

    for (var redirect = 0; redirect <= _maxRedirects; redirect++) {
      if (!_isHttp(current) || current.origin != resource.origin) {
        throw const FormatException('Media redirect left the authenticated source origin');
      }
      final upstreamRequest = await _client.openUrl(method, current);
      upstreamRequest.followRedirects = false;
      upstreamRequest.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      for (final entry in resource.headers.entries) {
        upstreamRequest.headers.set(entry.key, entry.value);
      }
      _copyRequestHeader(downstream, upstreamRequest, HttpHeaders.rangeHeader, _range);
      _copyRequestHeader(downstream, upstreamRequest, HttpHeaders.ifRangeHeader, null);
      _copyRequestHeader(downstream, upstreamRequest, HttpHeaders.ifNoneMatchHeader, null);

      upstream = await upstreamRequest.close();
      final location = upstream.headers.value(HttpHeaders.locationHeader);
      if (upstream.statusCode < 300 || upstream.statusCode >= 400 || location == null) break;
      if (redirect == _maxRedirects) throw const HttpException('Media redirect limit exceeded');
      final next = current.resolve(location);
      if (!_isHttp(next) || next.origin != resource.origin) {
        throw const FormatException('Media redirect left the authenticated source origin');
      }
      current = next;
      await upstream.drain<void>();
    }

    if (upstream == null) throw const HttpException('Media request did not complete');
    final response = downstream.response;
    final contentType = upstream.headers.value(HttpHeaders.contentTypeHeader) ?? '';
    final isPlaylist =
        method == 'GET' &&
        upstream.statusCode >= 200 &&
        upstream.statusCode < 300 &&
        (current.path.toLowerCase().endsWith('.m3u8') || contentType.toLowerCase().contains('mpegurl'));

    if (isPlaylist) {
      final bytes = await _readBounded(upstream, _maxPlaylistBytes);
      final text = utf8.decode(bytes, allowMalformed: false);
      final rewritten = _rewritePlaylist(text, current, resource);
      final output = utf8.encode(rewritten);
      response.statusCode = upstream.statusCode;
      _copyResponseHeaders(upstream, response, omitLength: true);
      response.headers.contentLength = output.length;
      response.add(output);
      await response.close();
      return;
    }

    response.statusCode = upstream.statusCode;
    _copyResponseHeaders(upstream, response);
    if (method == 'HEAD') {
      await upstream.drain<void>();
      await response.close();
      return;
    }
    await upstream.pipe(response);
  }

  void _copyRequestHeader(HttpRequest source, HttpClientRequest destination, String name, RegExp? allow) {
    final value = source.headers.value(name);
    if (value == null || value.length > 1024 || (allow != null && !allow.hasMatch(value))) return;
    destination.headers.set(name, value);
  }

  void _copyResponseHeaders(HttpClientResponse source, HttpResponse destination, {bool omitLength = false}) {
    const allowed = {
      'accept-ranges',
      'cache-control',
      'content-disposition',
      'content-encoding',
      'content-language',
      'content-range',
      'content-type',
      'etag',
      'expires',
      'last-modified',
    };
    for (final name in allowed) {
      if (omitLength && name == HttpHeaders.contentLengthHeader) continue;
      for (final value in source.headers[name] ?? const <String>[]) {
        destination.headers.add(name, value);
      }
    }
    if (!omitLength && source.contentLength >= 0) {
      destination.contentLength = source.contentLength;
    }
    destination.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
  }

  Future<List<int>> _readBounded(HttpClientResponse response, int maximumBytes) async {
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > maximumBytes) {
        throw const HttpException('Media playlist exceeds the size limit');
      }
      bytes.addAll(chunk);
    }
    return bytes;
  }

  String _rewritePlaylist(String playlist, Uri playlistUri, _ProxyResource parent) {
    final lines = playlist.split('\n');
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final cr = line.endsWith('\r') ? '\r' : '';
      final content = cr.isEmpty ? line : line.substring(0, line.length - 1);
      if (content.trim().isEmpty) continue;

      if (content.startsWith('#')) {
        lines[index] =
            content.replaceAllMapped(_uriAttribute, (match) {
              final source = playlistUri.resolve(match.group(1)!);
              return 'URI="${_childUri(source, parent)}"';
            }) +
            cr;
      } else {
        final source = playlistUri.resolve(content.trim());
        lines[index] = _childUri(source, parent) + cr;
      }
    }
    return lines.join('\n');
  }

  String _childUri(Uri source, _ProxyResource parent) {
    if (!_isHttp(source) || source.origin != parent.origin) {
      throw const FormatException('HLS playlist references a different origin');
    }
    return register(source, headers: parent.headers).toString();
  }

  bool _isHttp(Uri uri) => (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;

  _NormalizedSource _normalizeSource(Uri source, Map<String, String> inputHeaders) {
    final headers = <String, String>{};
    for (final entry in inputHeaders.entries) {
      final name = entry.key.trim();
      final value = entry.value;
      if (!_headerName.hasMatch(name) || value.contains('\r') || value.contains('\n') || value.contains('\u0000')) {
        continue;
      }
      switch (name.toLowerCase()) {
        case 'host':
        case 'content-length':
        case 'transfer-encoding':
        case 'connection':
        case 'proxy-authorization':
        case 'proxy-authenticate':
        case 'range':
        case 'if-range':
        case 'if-none-match':
        case 'accept-encoding':
          continue;
      }
      headers[name] = value;
    }

    final remaining = <String, List<String>>{};
    for (final entry in source.queryParametersAll.entries) {
      final key = entry.key.toLowerCase();
      final targetHeader = switch (key) {
        'x-plex-token' => 'X-Plex-Token',
        'api_key' || 'apikey' => 'X-Emby-Token',
        'x-emby-token' => 'X-Emby-Token',
        'x-mediabrowser-token' => 'X-MediaBrowser-Token',
        _ => null,
      };
      if (targetHeader == null) {
        remaining[entry.key] = entry.value;
      } else if (!headers.keys.any((name) => name.toLowerCase() == targetHeader.toLowerCase()) &&
          entry.value.isNotEmpty) {
        headers[targetHeader] = entry.value.last;
      }
    }

    return _NormalizedSource(source.replace(queryParameters: remaining), Map<String, String>.unmodifiable(headers));
  }
}

class _NormalizedSource {
  const _NormalizedSource(this.uri, this.headers);
  final Uri uri;
  final Map<String, String> headers;
}

class _ProxyResource {
  const _ProxyResource(this.uri, this.headers, this.origin);
  final Uri uri;
  final Map<String, String> headers;
  final String origin;
}
