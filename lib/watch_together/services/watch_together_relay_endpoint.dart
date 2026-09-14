/// Canonical HTTP(S) base endpoint for a Watch Together relay.
///
/// A base may include a reverse-proxy path prefix. The concrete health and
/// WebSocket routes are always appended as path segments.
final class WatchTogetherRelayEndpoint {
  WatchTogetherRelayEndpoint._(this._baseUri);

  static const String defaultBaseUrl = 'https://ice.plezy.app';

  static final WatchTogetherRelayEndpoint defaultEndpoint = WatchTogetherRelayEndpoint._(Uri.parse(defaultBaseUrl));

  final Uri _baseUri;

  String get canonicalBaseUrl => _baseUri.toString();

  Uri get healthUri => _appendPathSegment('health');

  Uri get webSocketUri => _appendPathSegment('relay').replace(scheme: _baseUri.scheme == 'https' ? 'wss' : 'ws');

  static WatchTogetherRelayEndpoint resolve(String? value) {
    if (value == null || value.trim().isEmpty) return defaultEndpoint;
    final endpoint = tryParseCustom(value);
    if (endpoint == null) {
      throw FormatException('Invalid Watch Together relay base URL');
    }
    return endpoint;
  }

  static WatchTogetherRelayEndpoint? tryParseCustom(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final Uri uri;
    try {
      uri = Uri.parse(trimmed);
      if (uri.hasPort && (uri.port < 1 || uri.port > 65535)) {
        return null;
      }
    } on FormatException {
      return null;
    }

    if ((uri.scheme != 'http' && uri.scheme != 'https') ||
        !uri.isAbsolute ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }

    final normalized = uri.normalizePath();
    var path = normalized.path;
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    final hasDefaultPort =
        normalized.hasPort &&
        ((normalized.scheme == 'http' && normalized.port == 80) ||
            (normalized.scheme == 'https' && normalized.port == 443));
    final canonical = Uri(
      scheme: normalized.scheme,
      host: normalized.host,
      port: normalized.hasPort && !hasDefaultPort ? normalized.port : null,
      path: path,
    );
    return WatchTogetherRelayEndpoint._(canonical);
  }

  Uri _appendPathSegment(String segment) {
    final prefix = _baseUri.path;
    return _baseUri.replace(path: '$prefix/$segment');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WatchTogetherRelayEndpoint && other.canonicalBaseUrl == canonicalBaseUrl;

  @override
  int get hashCode => canonicalBaseUrl.hashCode;

  @override
  String toString() => canonicalBaseUrl;
}
