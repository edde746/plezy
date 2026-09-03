import 'dart:io' show HttpClient, Platform;

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:win_http/win_http.dart';

import 'app_logger.dart';
import 'happy_eyeballs.dart';
import 'managed_http_client.dart';
import 'media_server_timeouts.dart';

final Set<String> _loggedPlatformClients = <String>{};

void _logPlatformClient(String platform, String client) {
  if (!_loggedPlatformClients.add(client)) return;
  appLogger.i('Platform HTTP client', error: {'platform': platform, 'client': client});
}

/// dart:io leaves TCP connects unbounded (Darwin retries SYNs for ~75 s) and
/// `package:http` cannot abort a request whose connection is still being
/// established, so every IOClient gets an explicit connect bound and
/// permission to force-close after a failed drain (#1972).
///
/// The pool is always tuned. Every surface that matters fans out — Plex and
/// Jellyfin home loads, artwork rails, tracker and Seerr traffic all issue
/// several concurrent requests per pass — and the dart:io defaults of 6
/// connections per host and a 15 s idle timeout cost a fresh TLS handshake per
/// request on a high-RTT or CDN link. On a 60-way artwork fan-out, 12/90 s
/// measured ~4x the default's throughput on Linux and ~2x on Android, so there
/// is no case left for the opt-in the tuning used to be.
///
/// [happyEyeballsConnectionFactory] replaces dart:io's own connection setup,
/// which resolves A and AAAA separately and delays the AAAA lookup by 10 ms
/// "in order to favor IPv4" — so a dual-stack server whose IPv4 path answers
/// quickly is never tried over IPv6 at all, whatever the system resolver
/// ordered. `connectionTimeout` still bounds the whole of lookup, connect and
/// the TLS handshake, exactly as it did when the SDK owned this path.
ManagedHttpClient _createIoClient(String debugLabel) {
  final httpClient = HttpClient()
    ..connectionTimeout = MediaServerTimeouts.connect
    ..maxConnectionsPerHost = 12
    ..idleTimeout = const Duration(seconds: 90)
    ..connectionFactory = happyEyeballsConnectionFactory;
  return ManagedHttpClient(IOClient(httpClient), debugLabel: debugLabel, forceCloseOnDrainTimeout: true);
}

/// Every platform except Windows runs on the tuned dart:io client.
///
/// Windows keeps WinHTTP for the system proxy and the Schannel trust store.
/// It also brought `WINHTTP_OPTION_IPV6_FAST_FALLBACK` (Happy Eyeballs, #1128)
/// at a time when dart:io had no equivalent; [happyEyeballsConnectionFactory]
/// now supplies that on every other platform.
///
/// Cronet and NSURLSession used to serve Android and Apple here. Both were
/// measured slower than this client on the request shapes Plezy actually
/// issues — Cronet by ~10x on LAN body throughput — so neither survived; see
/// issue #2140.
http.Client createPlatformClient() {
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
