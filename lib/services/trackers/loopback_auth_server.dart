import 'dart:async';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_logger.dart';

/// One-shot HTTP server on `127.0.0.1:[port]` that captures an OAuth redirect
/// (RFC 8252 Loopback Interface Redirection).
///
/// Replaces the custom `plezy://` URL scheme used by `flutter_web_auth_2` —
/// no platform manifest registration needed.
///
/// **iOS caveat**: when the app opens an external browser, iOS may suspend
/// the app after ~30 seconds, which silently kills this server. Users who
/// linger in 2FA / password managers may see "localhost refused to connect"
/// on the redirect. If this turns out to be common, fall back to the
/// custom-scheme approach on mobile only.
class LoopbackAuthServer {
  /// Fixed port — must be registered as the redirect URI with each OAuth
  /// provider. AniList requires exact URI match, so we can't pick dynamically.
  static const int port = 53682;
  static const String host = '127.0.0.1';

  /// Listen for one request at `http://$host:$port$path` and return the
  /// captured URI.
  ///
  /// Handles both query-param redirects (RFC 6749 authorization_code grant)
  /// and fragment redirects (implicit grant): fragments stay client-side, so
  /// we serve a tiny HTML page that rewrites `location.hash` into query
  /// params and reloads — the second request is then captured normally.
  static Future<Uri> listenOnce({
    required String path,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final HttpServer server;
    try {
      server = await HttpServer.bind(host, port);
    } on SocketException catch (e) {
      throw LoopbackBindException('Could not bind $host:$port: ${e.message}');
    }

    final completer = Completer<Uri>();

    late StreamSubscription<HttpRequest> sub;
    sub = server.listen((req) async {
      if (req.uri.path != path) {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      // Flush the response BEFORE completing the completer — the caller's
      // `finally` block forcibly tears down the socket, which would
      // otherwise truncate the response body and leave the browser showing
      // a broken page despite auth succeeding.
      await _respondHtml(req.response, _pageHtml);
      if (req.uri.queryParameters.isNotEmpty && !completer.isCompleted) {
        completer.complete(req.uri);
      }
    });

    try {
      return await completer.future.timeout(timeout);
    } finally {
      await sub.cancel();
      await server.close(force: true);
    }
  }

  /// Build the redirect URI callers should register with the OAuth provider.
  static String redirectUri(String path) => 'http://$host:$port$path';

  /// Open [authorizeUri] in the external browser and wait for the OAuth
  /// provider's redirect to hit the loopback server. Returns `null` if the
  /// redirect doesn't arrive within [timeout] (usually because the user
  /// closed the browser).
  ///
  /// Starts the listener BEFORE launching the browser so a fast redirect
  /// can't race the bind.
  static Future<Uri?> launchAndWait(
    Uri authorizeUri, {
    required String path,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final callbackFuture = listenOnce(path: path, timeout: timeout);
    await launchUrl(authorizeUri, mode: LaunchMode.externalApplication);
    try {
      return await callbackFuture;
    } on TimeoutException {
      return null;
    }
  }

  static Future<void> _respondHtml(HttpResponse res, String html) async {
    try {
      res
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(html);
      await res.close();
    } catch (e) {
      appLogger.d('LoopbackAuthServer: response write failed', error: e);
    }
  }

  /// One page for all three flows. Code-grant and polling flows (MAL, Simkl)
  /// render it as a plain success page. Implicit-grant flows (AniList) put
  /// the access token in the URL fragment — the inline script in `<head>`
  /// rewrites that into a query string and redirects before the body paints,
  /// so users never see a success page flash before the real capture.
  static const String _pageHtml = '<!doctype html>'
      '<meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width,initial-scale=1">'
      '<title>Signed in</title>'
      '<script>'
      'if(location.hash&&location.hash.length>1){'
      'location.replace(location.pathname+"?"+location.hash.substring(1));'
      '}'
      '</script>'
      '<style>'
      'html,body{margin:0;height:100%}'
      'body{display:flex;flex-direction:column;align-items:center;justify-content:center;'
      'font-family:-apple-system,system-ui,sans-serif;background:#fff;color:#1a1a1a;text-align:center;padding:1em;box-sizing:border-box}'
      '@media(prefers-color-scheme:dark){body{background:#0f0f0f;color:#f5f5f5}}'
      '.check{width:72px;height:72px;margin-bottom:20px}'
      'h2{margin:0 0 8px;font-weight:600;font-size:1.25rem}'
      'p{margin:0;opacity:.7;font-size:.95rem}'
      '</style>'
      '<body>'
      '<svg class="check" viewBox="0 0 24 24">'
      '<circle cx="12" cy="12" r="10" fill="#22c55e"/>'
      '<path d="M7 12.5l3 3 7-7" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
      '</svg>'
      '<h2>Signed in to Plezy</h2>'
      '<p>You can close this tab and return to the app.</p>'
      '</body>';
}

class LoopbackBindException implements Exception {
  final String message;
  const LoopbackBindException(this.message);
  @override
  String toString() => 'LoopbackBindException: $message';
}
