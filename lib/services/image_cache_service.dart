import 'dart:async';
import 'dart:collection';

import 'package:cached_network_image_ce/cached_network_image.dart' show FileResponse;
// CE's public conditional export hides the IO-only httpClientFactory parameter
// behind a narrower unsupported-platform stub.
// ignore: implementation_imports
import 'package:cached_network_image_ce/src/cache/default_cache_manager.dart' as ce_cache;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../utils/media_server_http_client.dart';

final _artworkHttpClient = MediaServerHttpClient(usePlexApiClient: true);
final _artworkRequestLimiter = _RequestLimiter(6);

Future<void> closeArtworkHttpClientGracefully({Duration drainTimeout = const Duration(seconds: 5)}) {
  return _artworkHttpClient.closeGracefully(drainTimeout: drainTimeout);
}

/// Shared cache manager for media-server image artwork. Used for both Plex and
/// Jellyfin artwork (the class name predates Jellyfin support — it's
/// backend-neutral).
///
/// Uses the platform-native HTTP client so iOS/macOS (CupertinoClient) and
/// Android (CronetClient) benefit from HTTP/2, while the wrapper below keeps
/// image fan-out bounded so weak TV devices don't decode a whole rail at once.
/// On Linux this uses the same finite-connection tuning as Plex API traffic.
class PlexImageCacheManager extends ce_cache.DefaultCacheManager {
  static final PlexImageCacheManager instance = PlexImageCacheManager._();

  PlexImageCacheManager._()
    : super(
        stalePeriod: const Duration(days: 14),
        maxNrOfCacheObjects: 3000,
        httpClientFactory: () => _SharedHttpClient(_artworkHttpClient.inner),
        cacheDirectoryProvider: getApplicationCacheDirectory,
      );

  @override
  Stream<FileResponse> getImageFile(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
    int? maxHeight,
    int? maxWidth,
  }) {
    // Plezy already requests server-sized artwork URLs. Avoid CE's disk-resize
    // path, which decodes downloaded images before writing resized PNG copies.
    return getFileStream(url, key: key, headers: headers, withProgress: withProgress);
  }
}

/// CE closes each factory-created client after a download. Wrap the app-wide
/// shared client so image requests reuse its platform transport without
/// transferring ownership of its lifecycle, and cap artwork fan-out globally.
class _SharedHttpClient extends http.BaseClient {
  final http.Client _inner;

  _SharedHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final permit = await _artworkRequestLimiter.acquire();
    var released = false;

    void release() {
      if (released) return;
      released = true;
      permit.release();
    }

    try {
      final response = await _inner.send(request);
      return http.StreamedResponse(
        _releaseWhenDone(response.stream, release),
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (_) {
      release();
      rethrow;
    }
  }

  @override
  void close() {}
}

Stream<List<int>> _releaseWhenDone(Stream<List<int>> stream, void Function() release) async* {
  try {
    await for (final chunk in stream) {
      yield chunk;
    }
  } finally {
    release();
  }
}

class _RequestLimiter {
  final int maxConcurrent;
  final Queue<Completer<_RequestPermit>> _queue = Queue<Completer<_RequestPermit>>();
  int _active = 0;

  _RequestLimiter(this.maxConcurrent);

  Future<_RequestPermit> acquire() {
    if (_active < maxConcurrent) {
      _active++;
      return Future.value(_RequestPermit(this));
    }

    final completer = Completer<_RequestPermit>();
    _queue.add(completer);
    return completer.future;
  }

  void _release() {
    if (_queue.isNotEmpty) {
      _queue.removeFirst().complete(_RequestPermit(this));
      return;
    }
    if (_active > 0) _active--;
  }
}

class _RequestPermit {
  final _RequestLimiter _limiter;
  bool _released = false;

  _RequestPermit(this._limiter);

  void release() {
    if (_released) return;
    _released = true;
    _limiter._release();
  }
}
