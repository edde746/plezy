import 'dart:io' show Platform, HttpClient;

import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:win_http/win_http.dart';

import 'app_logger.dart';

/// Shared Cronet engine so all clients reuse the same connection pool.
CronetEngine? _sharedEngine;

bool _loggedPlatformClient = false;

HttpClient? _linuxSingleton;

HttpClient _getLinuxSingleton() {
  return _linuxSingleton ??= HttpClient()
    ..maxConnectionsPerHost = 12
    ..idleTimeout = const Duration(seconds: 90);
}

void _logPlatformClient(String platform, String client) {
  if (_loggedPlatformClient) return;
  _loggedPlatformClient = true;
  appLogger.i('Platform HTTP client', error: {'platform': platform, 'client': client});
}

http.Client createPlatformClient() {
  if (Platform.isAndroid) {
    _sharedEngine ??= CronetEngine.build(
      cacheMode: CacheMode.memory,
      cacheMaxSize: 2 * 1024 * 1024,
      enableBrotli: true,
      enableHttp2: true,
    );
    _logPlatformClient('android', 'CronetClient');
    return CronetClient.fromCronetEngine(_sharedEngine!);
  }
  if (Platform.isIOS || Platform.isMacOS) {
    // cupertino_http relies on the objective_c FFI dylib, which isn't
    // available on tvOS. Fall back to IOClient if the init fails.
    try {
      final client = CupertinoClient.defaultSessionConfiguration();
      _logPlatformClient(Platform.isIOS ? 'ios' : 'macos', 'CupertinoClient');
      return client;
    } catch (e, st) {
      appLogger.w('CupertinoClient init failed, falling back to IOClient', error: e, stackTrace: st);
      _logPlatformClient(Platform.isIOS ? 'ios' : 'macos', 'IOClient (fallback)');
      return IOClient();
    }
  }
  if (Platform.isWindows) {
    try {
      final client = WinHttpClient.defaultConfiguration();
      _logPlatformClient('windows', 'WinHttpClient');
      return client;
    } catch (e, st) {
      appLogger.w('WinHttpClient init failed, falling back to IOClient', error: e, stackTrace: st);
      _logPlatformClient('windows', 'IOClient (fallback)');
      return IOClient();
    }
  }
  // Explicit Linux singleton — HTTP/2 unavailable on Linux (dart-lang/http#1385),
  // so we hold a persistent pool to avoid repeated TLS handshakes.
  if (Platform.isLinux) {
    _logPlatformClient('linux', 'IOClient (singleton)');
    return IOClient(_getLinuxSingleton());
  }
  // Unknown/future platform — plain disposable IOClient.
  _logPlatformClient(Platform.operatingSystem, 'IOClient');
  return IOClient();
}

/// No-op on Linux — singleton must never be destroyed.
void closePlexClient(http.Client client) {
  if (Platform.isLinux) return;
  client.close();
}

/// Fresh throwaway client for probes and connection tests.
http.Client createProbeClient() => IOClient();
