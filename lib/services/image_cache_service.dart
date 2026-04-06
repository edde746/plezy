import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../utils/http_client.dart';

/// Custom cache manager for Plex image transcoding with HTTP/2 multiplexing.
///
/// Uses Dio with [Http2Adapter] so all platforms benefit from HTTP/2 connection
/// multiplexing — many concurrent image downloads over a single connection
/// instead of being limited to a handful of HTTP/1.1 connections.
class PlexImageCacheManager extends CacheManager with ImageCacheManager {
  static const _key = 'plexImageCache';

  static final PlexImageCacheManager instance = PlexImageCacheManager._();

  PlexImageCacheManager._()
      : super(
          Config(
            _key,
            stalePeriod: const Duration(days: 14),
            maxNrOfCacheObjects: 3000,
            fileService: _DioFileService(
              Dio()..httpClientAdapter = createHttp2Adapter(),
            ),
          ),
        );
}

class _DioFileService extends FileService {
  final Dio _dio;

  _DioFileService(this._dio);

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final response = await _dio.get<ResponseBody>(
      url,
      options: Options(
        headers: headers,
        responseType: ResponseType.stream,
      ),
    );
    return _DioGetResponse(response);
  }
}

class _DioGetResponse implements FileServiceResponse {
  final Response<ResponseBody> _response;
  final DateTime _receivedTime = DateTime.now();

  _DioGetResponse(this._response);

  @override
  Stream<List<int>> get content => _response.data!.stream;

  @override
  int? get contentLength {
    final value = _header(HttpHeaders.contentLengthHeader);
    return value != null ? int.tryParse(value) : null;
  }

  @override
  int get statusCode => _response.statusCode ?? 200;

  @override
  DateTime get validTill {
    var ageDuration = const Duration(days: 7);
    final controlHeader = _header(HttpHeaders.cacheControlHeader);
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
  String? get eTag => _header(HttpHeaders.etagHeader);

  @override
  String get fileExtension {
    final contentTypeHeader = _header(HttpHeaders.contentTypeHeader);
    if (contentTypeHeader != null) {
      final ct = ContentType.parse(contentTypeHeader);
      return '.${ct.subType}';
    }
    return '';
  }

  String? _header(String name) => _response.headers.value(name);
}
