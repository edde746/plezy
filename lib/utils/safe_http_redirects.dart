import 'dart:async';

import 'package:http/http.dart' as http;

import 'managed_http_client.dart';

/// Also protects direct streaming users of MediaServerHttpClient.inner.
class SafeRedirectClient extends http.BaseClient implements GracefulHttpClient {
  SafeRedirectClient(this._inner);
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => sendWithSafeRedirects(_inner, request);

  @override
  void close() => _inner.close();

  @override
  Future<void> closeGracefully({Duration drainTimeout = const Duration(seconds: 2)}) async {
    if (_inner case final GracefulHttpClient graceful) {
      await graceful.closeGracefully(drainTimeout: drainTimeout);
    } else {
      _inner.close();
    }
  }
}

/// Follows redirects before handing the final response body to the caller.
///
/// The transport never follows a hop itself. Authentication remains on the
/// original origin; a CDN hop receives only representation/range headers.
/// Once stripped, credentials are not restored by a redirect back home.
/// The caller owns the deadline and the request's shared abort trigger.
Future<http.StreamedResponse> sendWithSafeRedirects(
  http.Client client,
  http.BaseRequest request, {
  bool allowCrossOrigin = true,
}) async {
  final follow = request.followRedirects;
  final maxRedirects = request.maxRedirects;
  final abort = request is http.Abortable ? request.abortTrigger : null;
  var current = request;
  var hops = 0;
  var cancelled = false;
  unawaited(abort?.then((_) => cancelled = true));

  while (true) {
    if (cancelled) throw http.RequestAbortedException(current.url);
    current.followRedirects = false;
    final response = await client.send(current);
    final status = response.statusCode;
    final canRedirect =
        const {301, 302, 303, 307, 308}.contains(status) &&
        (current.method == 'GET' || current.method == 'HEAD' || (current.method == 'POST' && status == 303));
    final location = response.headers['location'];
    if (!follow || !canRedirect || location == null) {
      final effectiveUrl = switch (response) {
        http.BaseResponseWithUrl(:final url) => url,
        _ => current.url,
      };
      return _ResponseWithUrl(response, effectiveUrl);
    }

    // Cancel instead of draining an untrusted, potentially infinite 3xx body.
    // This also releases ManagedHttpClient's request tracking before a new hop.
    await response.stream.listen(null).cancel();
    if (cancelled) throw http.RequestAbortedException(current.url);
    if (hops++ >= maxRedirects) throw const UnsafeRedirectException('Too many HTTP redirects');

    final Uri next;
    try {
      next = current.url.resolve(location);
    } on FormatException {
      throw const UnsafeRedirectException('Invalid HTTP redirect');
    }
    if (next.host.isEmpty || next.userInfo.isNotEmpty || !const {'http', 'https'}.contains(next.scheme)) {
      throw const UnsafeRedirectException('Invalid HTTP redirect destination');
    }
    if (current.url.scheme == 'https' && next.scheme != 'https') {
      throw const UnsafeRedirectException('HTTPS downgrade rejected');
    }
    final sameOrigin = _sameOrigin(current.url, next);
    if (!sameOrigin && !allowCrossOrigin) {
      throw const UnsafeRedirectException('Cross-origin redirect rejected');
    }
    final nextRequest = http.AbortableRequest(
      current.method == 'POST' ? 'GET' : current.method,
      next,
      abortTrigger: abort,
    )..persistentConnection = current.persistentConnection;
    nextRequest.headers.addEntries(
      current.headers.entries.where((entry) {
        final name = entry.key.toLowerCase();
        // Redirected requests have no body, matching dart:io redirect semantics.
        if (const {'host', 'content-length', 'content-type', 'transfer-encoding'}.contains(name)) return false;
        return sameOrigin || _publicHeaders.contains(name);
      }),
    );
    current = nextRequest;
  }
}

bool _sameOrigin(Uri a, Uri b) => a.scheme == b.scheme && a.host == b.host && a.port == b.port;

const _publicHeaders = {
  'accept',
  'accept-encoding',
  'accept-language',
  'range',
  'if-range',
  'if-none-match',
  'if-modified-since',
  'cache-control',
};

/// A policy failure is not a transport outage and must not trigger failover.
class UnsafeRedirectException implements Exception {
  const UnsafeRedirectException(this.message);
  final String message;
  @override
  String toString() => message;
}

class _ResponseWithUrl extends http.StreamedResponse implements http.BaseResponseWithUrl {
  _ResponseWithUrl(http.StreamedResponse response, this.url)
    : super(
        response.stream,
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
  @override
  final Uri url;
}
