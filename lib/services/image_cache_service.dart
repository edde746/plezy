// CE's public conditional export hides the IO-only httpClientFactory parameter
// behind a narrower unsupported-platform stub.
// ignore: implementation_imports
import 'package:cached_network_image_ce/src/cache/default_cache_manager.dart' as ce_cache;
import 'package:http/http.dart' as http;

import '../utils/media_server_http_client.dart';

/// Shared cache manager for media-server image artwork. Used for both Plex and
/// Jellyfin artwork (the class name predates Jellyfin support — it's
/// backend-neutral).
///
/// Uses the platform-native HTTP client so iOS/macOS (CupertinoClient) and
/// Android (CronetClient) benefit from HTTP/2 connection multiplexing —
/// many concurrent image downloads over a single connection instead of
/// being limited to a handful of HTTP/1.1 connections.
class PlexImageCacheManager extends ce_cache.DefaultCacheManager {
  static final PlexImageCacheManager instance = PlexImageCacheManager._();

  PlexImageCacheManager._()
    : super(
        stalePeriod: const Duration(days: 14),
        maxNrOfCacheObjects: 3000,
        httpClientFactory: () => _SharedHttpClient(httpClient.inner),
      );
}

/// CE closes each factory-created client after a download. Wrap the app-wide
/// shared client so image requests reuse its platform transport without
/// transferring ownership of its lifecycle.
class _SharedHttpClient extends http.BaseClient {
  final http.Client _inner;

  _SharedHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _inner.send(request);

  @override
  void close() {}
}
