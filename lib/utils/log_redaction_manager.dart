class LogRedactionManager {
  static final Set<String> _tokens = <String>{};
  static final Set<String> _urls = <String>{};
  static final Set<String> _customValues = <String>{};
  static final RegExp _ipv4Pattern = RegExp(
    r'\b(\d{1,3})([.-])(\d{1,3})\2(\d{1,3})\2(\d{1,3})\b',
  );
  static final RegExp _ipv4HostPattern = RegExp(r'^\d{1,3}([.-]\d{1,3}){3}$');

  /// Register a server access token or Plex.tv token for redaction.
  static void registerToken(String? token) {
    final normalized = _normalize(token);
    if (normalized == null) return;

    _tokens.add(normalized);

    // Tokens often appear URL encoded in query params.
    final encoded = Uri.encodeQueryComponent(normalized);
    if (encoded != normalized) {
      _tokens.add(encoded);
    }
  }

  /// Register the server/base URL currently in use.
  static void registerServerUrl(String? url) {
    final normalized = _normalize(url);
    if (normalized == null) return;

    final uri = Uri.tryParse(normalized);
    final host = uri?.host;
    if (host != null && host.isNotEmpty && _isIpv4Like(host)) {
      // Do not register full IP-based URLs; regex redaction handles them.
      return;
    }

    if (host == null && _isIpv4Like(normalized)) {
      return;
    }

    final strippedSlash = normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;

    if (strippedSlash.isNotEmpty) {
      _urls.add(strippedSlash);
      _urls.add('$strippedSlash/'); // Include trailing slash variant.
    }

    // Capture origin and host-level strings as well to cover most cases.
    if (uri != null && uri.host.isNotEmpty) {
      final origin =
          '${uri.scheme.isEmpty ? 'https' : uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      _urls.add(origin);
      if (origin.endsWith('/')) {
        _urls.add(origin.substring(0, origin.length - 1));
      }
    }
  }

  /// Register other sensitive values that need redaction.
  static void registerCustomValue(String? value) {
    final normalized = _normalize(value);
    if (normalized == null) return;
    _customValues.add(normalized);
  }

  /// Reset any tracked sensitive values (e.g., on logout).
  static void clearTrackedValues() {
    _tokens.clear();
    _urls.clear();
    _customValues.clear();
  }

  /// Redact known sensitive values from the provided message.
  static String redact(String message) {
    var redacted = message;

    redacted = redacted.replaceAllMapped(
      _ipv4Pattern,
      (match) => _maskIpv4(match.group(1)!, match.group(2)!, match.group(5)!),
    );

    for (final url in _urls) {
      redacted = redacted.replaceAll(url, _maskUrlPreview(url));
    }

    for (final token in _tokens) {
      redacted = redacted.replaceAll(token, '[REDACTED_TOKEN]');
    }

    for (final custom in _customValues) {
      redacted = redacted.replaceAll(custom, '[REDACTED]');
    }

    return redacted;
  }

  static String? _normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  static bool _isIpv4Like(String value) {
    return _ipv4HostPattern.hasMatch(value);
  }

  static String _maskIpv4(String first, String separator, String last) {
    return '$first$separator'
        'x$separator'
        'x$separator'
        '$last';
  }

  static String _maskUrlPreview(String url) {
    const startPreviewLength = 12;
    const endPreviewLength = 8;

    if (url.isEmpty) {
      return '[REDACTED_URL]';
    }

    if (url.length <= 4) {
      return '[REDACTED_URL]';
    }

    final startLength = url.length <= startPreviewLength
        ? (url.length / 2).ceil()
        : startPreviewLength;
    final remainingForEnd = url.length - startLength;
    final endLength = remainingForEnd <= endPreviewLength
        ? remainingForEnd
        : endPreviewLength;

    final start = url.substring(0, startLength);
    if (endLength <= 0) {
      return '$start...[REDACTED_URL]';
    }

    final end = url.substring(url.length - endLength);
    return '$start...[REDACTED_URL]...$end';
  }
}
