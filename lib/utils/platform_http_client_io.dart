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
Future<void>? _cronetWarmUp;

const String _androidCronetLabel = 'CronetClient';
const String _androidIoLabel = 'IOClient (Android fallback)';

const bool _tvosBuild = bool.fromEnvironment('TVOS_BUILD');

final Set<String> _loggedPlatformClients = <String>{};

void _logPlatformClient(String platform, String client) {
  if (!_loggedPlatformClients.add(client)) return;
  appLogger.i('Platform HTTP client', error: {'platform': platform, 'client': client});
}

/// Builds the shared Cronet engine, off the cold-start critical path.
///
/// [CronetEngine.build] goes straight to `org.chromium.net.CronetEngine.Builder`,
/// which enumerates every registered `CronetProvider` and calls `isEnabled()` on
/// each one. `play-services-cronet` — pulled in transitively by
/// `media3-datasource-cronet` — answers that call by installing the Play services
/// Dynamite module and resolving GMS HTTP flags. `package:cronet_http` exposes no
/// way to pick a provider, so the only lever left in Dart is *when* that cost is
/// paid. Call this once the first screen is up.
///
/// Never throws: a failed build latches Android onto the tuned IOClient.
Future<void> warmUpPlatformHttpClient() => _cronetWarmUp ??= _buildSharedCronetEngine();

Future<void> _buildSharedCronetEngine() async {
  if (!Platform.isAndroid || _cronetBroken || _sharedEngine != null) return;
  // Yield first: callers warm up from a post-frame callback, and the build is
  // synchronous JNI work that must not land inside that frame.
  await Future<void>.delayed(Duration.zero);
  try {
    _sharedEngine = CronetEngine.build(
      cacheMode: CacheMode.memory,
      cacheMaxSize: 2 * 1024 * 1024,
      enableBrotli: true,
      enableHttp2: true,
    );
  } catch (e, st) {
    _cronetBroken = true;
    _sharedEngine = null;
    appLogger.w('CronetEngine build failed, staying on IOClient', error: e, stackTrace: st);
  }
}

/// Android client that starts on the tuned IOClient and swaps to Cronet as soon
/// as [warmUpPlatformHttpClient] has built the shared engine.
///
/// Clients here are long-lived (one `MediaServerHttpClient` per server, created
/// in a constructor initializer), so resolving a delegate once at construction
/// would pin the primary media-server traffic to HTTP/1.1 forever. The delegate
/// is therefore resolved per request. Each delegate is a [ManagedHttpClient] in
/// its own right, keeping the existing shutdown semantics, and neither is
/// constructed until a request actually needs it.
class AndroidPlatformHttpClient extends http.BaseClient implements GracefulHttpClient {
  ManagedHttpClient? _cronet;
  ManagedHttpClient? _io;
  bool _closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (_closed) {
      throw http.ClientException('HTTP client is closing', request.url);
    }
    return _delegate().send(request);
  }

  ManagedHttpClient _delegate() {
    final engine = _sharedEngine;
    if (engine != null) {
      final cronet = _cronet;
      if (cronet != null) return cronet;
      _logPlatformClient('android', _androidCronetLabel);
      return _cronet = ManagedHttpClient(CronetClient.fromCronetEngine(engine), debugLabel: _androidCronetLabel);
    }
    final io = _io;
    if (io != null) return io;
    _logPlatformClient('android', _androidIoLabel);
    return _io = _createIoClient(_androidIoLabel, tuned: true);
  }

  @override
  void close() {
    _closed = true;
    _cronet?.close();
    _io?.close();
  }

  @override
  Future<void> closeGracefully({Duration drainTimeout = const Duration(seconds: 2)}) async {
    _closed = true;
    await Future.wait([
      if (_cronet case final cronet?) cronet.closeGracefully(drainTimeout: drainTimeout),
      if (_io case final io?) io.closeGracefully(drainTimeout: drainTimeout),
    ], eagerError: false);
  }
}

/// dart:io leaves TCP connects unbounded (Darwin retries SYNs for ~75 s) and
/// `package:http` cannot abort a request whose connection is still being
/// established, so every IOClient gets an explicit connect bound and
/// permission to force-close after a failed drain (#1972).
ManagedHttpClient _createIoClient(String debugLabel, {bool tuned = false}) {
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
    return AndroidPlatformHttpClient();
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
