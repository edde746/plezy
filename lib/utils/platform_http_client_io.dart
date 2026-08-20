import 'dart:io' show HttpClient, Platform;

import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:win_http/win_http.dart';

import 'app_logger.dart';
import 'managed_http_client.dart';
import 'media_server_timeouts.dart';

/// Shared Cronet engine so all clients reuse the same connection pool.
CronetEngine? _sharedEngine;
bool _cronetBroken = false;

const bool _tvosBuild = bool.fromEnvironment('TVOS_BUILD');

bool _loggedPlatformClient = false;

void _logPlatformClient(String platform, String client) {
  if (_loggedPlatformClient) return;
  _loggedPlatformClient = true;
  appLogger.i('Platform HTTP client', error: {'platform': platform, 'client': client});
}

/// dart:io leaves TCP connects unbounded (Darwin retries SYNs for ~75 s) and
/// `package:http` cannot abort a request whose connection is still being
/// established, so every IOClient gets an explicit connect bound and
/// permission to force-close after a failed drain (#1972).
http.Client _createIoClient(String debugLabel, {bool tuned = false}) {
  final httpClient = HttpClient()..connectionTimeout = MediaServerTimeouts.connect;
  if (tuned) {
    // Plex home loads fan out many HTTP/1.1 calls; keep connections warm.
    httpClient
      ..maxConnectionsPerHost = 12
      ..idleTimeout = const Duration(seconds: 90);
  }
  return ManagedHttpClient(IOClient(httpClient), debugLabel: debugLabel, forceCloseOnDrainTimeout: true);
}

http.Client createPlatformClient() {
  if (Platform.isAndroid) {
    if (!_cronetBroken) {
      try {
        _sharedEngine ??= CronetEngine.build(
          cacheMode: CacheMode.memory,
          cacheMaxSize: 2 * 1024 * 1024,
          enableBrotli: true,
          enableHttp2: true,
        );
        _logPlatformClient('android', 'CronetClient');
        return ManagedHttpClient(CronetClient.fromCronetEngine(_sharedEngine!), debugLabel: 'CronetClient');
      } catch (e, st) {
        _cronetBroken = true;
        _sharedEngine = null;
        appLogger.w('CronetClient init failed, falling back to IOClient', error: e, stackTrace: st);
      }
    }
    _logPlatformClient('android', 'IOClient (Android fallback)');
    return _createIoClient('IOClient (Android fallback)', tuned: true);
  }
  if (Platform.isIOS && _tvosBuild) {
    _logPlatformClient('tvos', 'IOClient (tvOS tuned)');
    return _createIoClient('IOClient (tvOS tuned)', tuned: true);
  }
  if (Platform.isIOS || Platform.isMacOS) {
    try {
      final client = CupertinoClient.defaultSessionConfiguration();
      _logPlatformClient(Platform.isIOS ? 'ios' : 'macos', 'CupertinoClient');
      return ManagedHttpClient(client, debugLabel: 'CupertinoClient');
    } catch (e, st) {
      appLogger.w('CupertinoClient init failed, falling back to IOClient', error: e, stackTrace: st);
      _logPlatformClient(Platform.isIOS ? 'ios' : 'macos', 'IOClient (fallback)');
      return _createIoClient('IOClient (fallback)');
    }
  }
  if (Platform.isWindows) {
    try {
      final client = WinHttpClient.defaultConfiguration();
      _logPlatformClient('windows', 'WinHttpClient');
      return ManagedHttpClient(client, debugLabel: 'WinHttpClient');
    } catch (e, st) {
      appLogger.w('WinHttpClient init failed, falling back to IOClient', error: e, stackTrace: st);
      _logPlatformClient('windows', 'IOClient (fallback)');
      return _createIoClient('IOClient (fallback)');
    }
  }
  _logPlatformClient(Platform.operatingSystem, 'IOClient');
  return _createIoClient('IOClient');
}

http.Client createPlexApiClient() {
  if (Platform.isLinux) {
    _logPlatformClient('linux', 'IOClient (Plex API tuned)');
    return _createIoClient('IOClient (Plex API tuned)', tuned: true);
  }
  return createPlatformClient();
}
