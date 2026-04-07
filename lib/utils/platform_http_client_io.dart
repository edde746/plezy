import 'dart:io' show Platform;

import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:win_http/win_http.dart';

/// Shared Cronet engine so all clients reuse the same connection pool.
CronetEngine? _sharedEngine;

http.Client createPlatformClient() {
  if (Platform.isAndroid) {
    _sharedEngine ??= CronetEngine.build(
      cacheMode: CacheMode.memory,
      cacheMaxSize: 2 * 1024 * 1024,
      enableBrotli: true,
      enableHttp2: true,
    );
    return CronetClient.fromCronetEngine(_sharedEngine!);
  }
  if (Platform.isIOS || Platform.isMacOS) {
    return CupertinoClient.defaultSessionConfiguration();
  }
  if (Platform.isWindows) {
    return WinHttpClient.defaultConfiguration();
  }
  return IOClient();
}
