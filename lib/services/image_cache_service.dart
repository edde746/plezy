import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

import '../utils/platform_detector.dart';
import '../utils/plex_http_client.dart';

/// Custom cache manager for Plex image transcoding with HTTP/2 multiplexing.
///
/// Uses the platform-native HTTP client so iOS/macOS (CupertinoClient) and
/// Android (CronetClient) benefit from HTTP/2 connection multiplexing —
/// many concurrent image downloads over a single connection instead of
/// being limited to a handful of HTTP/1.1 connections.
class PlexImageCacheManager extends CacheManager with ImageCacheManager {
  static const _key = 'plexImageCache';

  static final PlexImageCacheManager instance = PlexImageCacheManager._();

  PlexImageCacheManager._() : super(_buildConfig());

  static Config _buildConfig() {
    final fileService = _HttpFileService(httpClient.inner);
    // tvOS has no sqflite plugin, so force the JSON cache-info repo there.
    // On other platforms we let flutter_cache_manager pick its default repo.
    if (PlatformDetector.isAppleTV()) {
      return Config(
        _key,
        stalePeriod: const Duration(days: 14),
        maxNrOfCacheObjects: 3000,
        fileService: fileService,
        repo: JsonCacheInfoRepository(databaseName: _key),
      );
    }
    return Config(_key, stalePeriod: const Duration(days: 14), maxNrOfCacheObjects: 3000, fileService: fileService);
  }
}

class _HttpFileService extends FileService {
  final http.Client _client;

  _HttpFileService(this._client);

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    final request = http.Request('GET', Uri.parse(url));
    if (headers != null) request.headers.addAll(headers);
    final response = await _client.send(request);
    return _HttpGetResponse(response);
  }
}

class _HttpGetResponse implements FileServiceResponse {
  final http.StreamedResponse _response;
  final DateTime _receivedTime = DateTime.now();

  _HttpGetResponse(this._response);

  @override
  Stream<List<int>> get content => _response.stream;

  @override
  int? get contentLength {
    final value = _response.headers[HttpHeaders.contentLengthHeader];
    return value != null ? int.tryParse(value) : null;
  }

  @override
  int get statusCode => _response.statusCode;

  @override
  DateTime get validTill {
    var ageDuration = const Duration(days: 7);
    final controlHeader = _response.headers[HttpHeaders.cacheControlHeader];
    if (controlHeader != null) {
      for (final setting in controlHeader.split(',')) {
        final s = setting.trim().toLowerCase();
        if (s == 'no-cache') ageDuration = Duration.zero;
        if (s.startsWith('max-age=')) {
          final secs = int.tryParse(s.split('=')[1]) ?? 0;
          if (secs > 0) ageDuration = Duration(seconds: secs);
        }
      }
    }
    return _receivedTime.add(ageDuration);
  }

  @override
  String? get eTag => _response.headers[HttpHeaders.etagHeader];

  @override
  String get fileExtension {
    final contentTypeHeader = _response.headers[HttpHeaders.contentTypeHeader];
    if (contentTypeHeader != null) {
      final ct = ContentType.parse(contentTypeHeader);
      return '.${ct.subType}';
    }
    return '';
  }
}
