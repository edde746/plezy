class LogRedactionManager {
  // Size limits for bounded sets (FIFO eviction when exceeded)
  static const int _maxTokens = 50;
  static const int _maxUrls = 20;
  static const int _maxCustomValues = 50;

  // Use LinkedHashSet for FIFO ordering
  static final Set<String> _tokens = <String>{};
  static final Set<String> _urls = <String>{};
  static final Set<String> _customValues = <String>{};

  static final RegExp _ipv4Pattern = RegExp(r'\b(\d{1,3})([.-])(\d{1,3})\2(\d{1,3})\2(\d{1,3})\b');
  static final RegExp _ipv4HostPattern = RegExp(r'^\d{1,3}([.-]\d{1,3}){3}$');

  // Combined regex for single-pass redaction (rebuilt on set changes)
  static RegExp? _combinedPattern;

  /// Register a server access token or Plex.tv token for redaction.
  static void registerToken(String? token) {
    final normalized = _normalize(token);
    if (normalized == null) return;

    _addWithLimit(_tokens, normalized, _maxTokens);

    // Tokens often appear URL encoded in query params.
    final encoded = Uri.encodeQueryComponent(normalized);
    if (encoded != normalized) {
      _addWithLimit(_tokens, encoded, _maxTokens);
    }

    _rebuildCombinedPattern();
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

    final strippedSlash = normalized.endsWith('/') ? normalized.substring(0, normalized.length - 1) : normalized;

    if (strippedSlash.isNotEmpty) {
      _addWithLimit(_urls, strippedSlash, _maxUrls);
      _addWithLimit(_urls, '$strippedSlash/', _maxUrls);
    }

    // Capture origin and host-level strings as well to cover most cases.
    if (uri != null && uri.host.isNotEmpty) {
      final origin = '${uri.scheme.isEmpty ? 'https' : uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      _addWithLimit(_urls, origin, _maxUrls);
      if (origin.endsWith('/')) {
        _addWithLimit(_urls, origin.substring(0, origin.length - 1), _maxUrls);
      }
    }

    _rebuildCombinedPattern();
  }

  /// Register other sensitive values that need redaction.
  static void registerCustomValue(String? value) {
    final normalized = _normalize(value);
    if (normalized == null) return;
    _addWithLimit(_customValues, normalized, _maxCustomValues);
    _rebuildCombinedPattern();
  }

  /// Reset any tracked sensitive values (e.g., on logout).
  static void clearTrackedValues() {
    _tokens.clear();
    _urls.clear();
    _customValues.clear();
    _combinedPattern = null;
  }

  /// Redact known sensitive values from the provided message.
  static String redact(String message) {
    // Pass 1: IPv4 addresses (regex pattern)
    var redacted = message.replaceAllMapped(
      _ipv4Pattern,
      (match) => _maskIpv4(match.group(1)!, match.group(2)!, match.group(5)!),
    );

    // Pass 2: All tracked values in single pass
    if (_combinedPattern != null) {
      redacted = redacted.replaceAllMapped(_combinedPattern!, (match) {
        final value = match.group(0)!;
        if (_tokens.contains(value)) return '[REDACTED_TOKEN]';
        if (_urls.contains(value)) return _maskUrlPreview(value);
        return '[REDACTED]';
      });
    }

    return redacted;
  }

  /// Rebuild the combined regex pattern from all tracked values.
  static void _rebuildCombinedPattern() {
    final allLiterals = [
      ..._tokens.map(RegExp.escape),
      ..._urls.map(RegExp.escape),
      ..._customValues.map(RegExp.escape),
    ];

    if (allLiterals.isEmpty) {
      _combinedPattern = null;
      return;
    }

    // Sort by length descending so longer matches are preferred
    allLiterals.sort((a, b) => b.length.compareTo(a.length));
    _combinedPattern = RegExp(allLiterals.join('|'));
  }

  /// Add value to set with FIFO eviction if limit exceeded.
  static void _addWithLimit(Set<String> set, String value, int maxSize) {
    if (set.contains(value)) return; // Already tracked

    // Evict oldest entries if at capacity
    while (set.length >= maxSize) {
      set.remove(set.first);
    }
    set.add(value);
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

    final startLength = url.length <= startPreviewLength ? (url.length / 2).ceil() : startPreviewLength;
    final remainingForEnd = url.length - startLength;
    final endLength = remainingForEnd <= endPreviewLength ? remainingForEnd : endPreviewLength;

    final start = url.substring(0, startLength);
    if (endLength <= 0) {
      return '$start...[REDACTED_URL]';
    }

    final end = url.substring(url.length - endLength);
    return '$start...[REDACTED_URL]...$end';
  }
}
