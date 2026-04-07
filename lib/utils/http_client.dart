import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';

import 'app_logger.dart';

/// Shared HTTP/2 connection pool. All Dio instances that go through
/// [createHttp2Adapter] reuse the same pool, so connections to the same
/// host are multiplexed instead of duplicated.
final _connectionManager = ConnectionManager(idleTimeout: const Duration(seconds: 15));
final _http1Fallback = IOHttpClientAdapter();

/// Returns an [HttpClientAdapter] that tries HTTP/2 first and falls back
/// to HTTP/1.1 when the server rejects h2 ALPN negotiation.
HttpClientAdapter createHttp2Adapter() => _Http2WithFallbackAdapter(Http2Adapter(_connectionManager));

/// Shared [Dio] instance for ad-hoc HTTP requests that don't go through
/// [PlexClient]. Reuses the global HTTP/2 connection pool.
final httpClient = Dio()..httpClientAdapter = createHttp2Adapter();

class _Http2WithFallbackAdapter implements HttpClientAdapter {
  _Http2WithFallbackAdapter(this._h2);

  final Http2Adapter _h2;

  static final _http1Hosts = <String>{'plex.tv'};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_http1Hosts.contains(options.uri.host)) {
      return _http1Fallback.fetch(options, requestStream, cancelFuture);
    }
    try {
      return await _h2.fetch(options, requestStream, cancelFuture);
    } on HandshakeException {
      appLogger.d('H2 handshake failed for ${options.uri.host}, falling back to HTTP/1.1');
      _http1Hosts.add(options.uri.host);
      return _http1Fallback.fetch(options, requestStream, cancelFuture);
    }
  }

  @override
  void close({bool force = false}) {
    _h2.close(force: force);
  }
}
