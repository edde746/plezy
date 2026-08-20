import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:http/http.dart' as http;

import '../../utils/abortable_http_request.dart';
import '../../utils/app_logger.dart';
import '../../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../../utils/platform_http_client_io.dart'
    as platform;
import '../../watch_together/services/watch_together_relay_endpoint.dart';
import 'tracker_constants.dart';

/// Client for the Plezy relay's `/auth/*` OAuth proxy.
///
/// The proxy drives the full authorization-code flow server-side: device calls
/// [start] to get a QR URL, user scans on a phone to complete auth, device
/// long-polls [poll] until tokens arrive. No local HTTP listener or custom URL
/// scheme is required — works identically on TVs without a browser.
class OAuthProxyClient {
  /// Public base URL of the Plezy relay; colocated with Watch Together.
  static String get baseUrl => WatchTogetherRelayEndpoint.defaultEndpoint.canonicalBaseUrl;

  final http.Client _http;

  OAuthProxyClient({http.Client? httpClient}) : _http = httpClient ?? platform.createPlatformClient();

  void dispose() => _http.close();

  /// POST /auth/start — register a new session. Returns a handle including the
  /// URL to display as a QR code for the phone scan.
  Future<OAuthProxyStart> start(String service) async {
    final res = await sendAbortableHttpRequest(
      _http,
      'POST',
      Uri.parse('$baseUrl/auth/start'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'service': service}),
      timeout: TrackerConstants.authRequestTimeout,
      operation: 'OAuth proxy start',
    );
    if (res.statusCode != 200) {
      throw OAuthProxyException('OAuth proxy start failed: HTTP ${res.statusCode}');
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    return OAuthProxyStart(session: body['session'] as String, url: body['url'] as String);
  }

  /// Long-poll /auth/result?session=X until a completion event arrives.
  ///
  /// Returns null if [shouldCancel] flips true between iterations or [onCancel]
  /// completes mid-request. Throws [OAuthProxyException] on unrecoverable errors
  /// (session gone, upstream failure). The server holds each request for up to
  /// 50 s; 204 responses are retried transparently, and 429 responses are
  /// retried until the session's own lifetime expires.
  Future<OAuthProxyResult?> poll(String session, {bool Function()? shouldCancel, Future<void>? onCancel}) async {
    final uri = Uri.parse('$baseUrl/auth/result').replace(queryParameters: {'session': session});
    final deadline = clock.now().add(TrackerConstants.oauthProxySessionTimeout);
    final cancelSentinel = Object();
    // Subscribe to onCancel once; reusing this derived future avoids
    // accumulating a fresh listener per loop iteration.
    final cancelFuture = onCancel?.then((_) => cancelSentinel);
    while (true) {
      if (shouldCancel?.call() ?? false) return null;

      final Object? raced;
      try {
        raced = await Future.any<Object?>([
          sendAbortableHttpRequest(
            _http,
            'GET',
            uri,
            timeout: TrackerConstants.oauthProxyPollTimeout,
            abortTrigger: onCancel,
            operation: 'OAuth proxy poll',
          ),
          ?cancelFuture,
        ]);
      } on TimeoutException {
        continue;
      } catch (e) {
        appLogger.d('oauth proxy: poll transient error', error: e);
        await Future<void>.delayed(TrackerConstants.oauthProxyRetryDelay);
        continue;
      }

      if (identical(raced, cancelSentinel)) return null;
      final res = raced as http.Response;

      if (res.statusCode == 204) continue; // server-side timeout, retry
      if (res.statusCode == 410) {
        throw const OAuthProxyException('Session expired or already used');
      }
      if (res.statusCode == 429 && clock.now().isBefore(deadline)) {
        // Rate limiting is transient while the relay session is alive: honor
        // the server's suggested pause when present, otherwise resume on the
        // normal retry tick. Past the deadline the 429 falls through below.
        final retryAfter = int.tryParse(res.headers['retry-after'] ?? '');
        final delay = retryAfter != null && retryAfter > 0
            ? Duration(seconds: retryAfter)
            : TrackerConstants.oauthProxyRetryDelay;
        await Future.any<Object?>([Future<void>.delayed(delay), ?cancelFuture]);
        continue;
      }
      if (res.statusCode != 200) {
        throw OAuthProxyException('OAuth proxy poll failed: HTTP ${res.statusCode}');
      }
      final body = json.decode(res.body) as Map<String, dynamic>;
      if (body['error'] != null) {
        final err = body['error'];
        if (err == 'access_denied') return null; // user cancelled in browser
        final category = switch (err) {
          'missing_code' => 'missing authorization code',
          'exchange_failed' => 'token exchange failed',
          _ => 'upstream authorization failed',
        };
        throw OAuthProxyException('OAuth proxy failed: $category');
      }
      return OAuthProxyResult(
        accessToken: body['accessToken'] as String,
        refreshToken: body['refreshToken'] as String?,
        expiresIn: (body['expiresIn'] as num?)?.toInt(),
      );
    }
  }
}

class OAuthProxyStart {
  /// Opaque session token. Include in subsequent polls.
  final String session;

  /// URL to render as a QR code and open in a browser. The phone scans it,
  /// triggering the upstream OAuth flow.
  final String url;

  const OAuthProxyStart({required this.session, required this.url});
}

class OAuthProxyResult {
  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;

  const OAuthProxyResult({required this.accessToken, this.refreshToken, this.expiresIn});
}

class OAuthProxyException implements Exception {
  final String message;
  const OAuthProxyException(this.message);
  @override
  String toString() => 'OAuthProxyException: $message';
}
