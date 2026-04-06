import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';

/// Shared HTTP/2 connection pool. All Dio instances that go through
/// [createHttp2Adapter] reuse the same pool, so connections to the same
/// host are multiplexed instead of duplicated.
final _connectionManager = ConnectionManager(idleTimeout: const Duration(seconds: 15));

/// Returns an [Http2Adapter] backed by the shared connection pool.
HttpClientAdapter createHttp2Adapter() => Http2Adapter(_connectionManager);

/// Shared [Dio] instance for ad-hoc HTTP requests that don't go through
/// [PlexClient]. Reuses the global HTTP/2 connection pool.
final httpClient = Dio()..httpClientAdapter = createHttp2Adapter();
