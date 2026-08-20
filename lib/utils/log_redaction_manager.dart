import 'url_utils.dart';

class LogRedactionManager {
  // Size limits for bounded sets (FIFO eviction when exceeded)
  static const int _maxTokens = 50;
  // Each server registers up to 8 literals (slash/origin/mpv-escaped
  // variants), so keep headroom for several servers before FIFO eviction.
  static const int _maxUrls = 40;
  static const int _maxCustomValues = 50;

  // Use LinkedHashSet for FIFO ordering
  static final Set<String> _tokens = <String>{};
  static final Set<String> _urls = <String>{};
  static final Set<String> _customValues = <String>{};

  static final RegExp _ipv4Pattern = RegExp(r'\b(\d{1,3})([.-])(\d{1,3})\2(\d{1,3})\2(\d{1,3})\b');
  static final RegExp _ipv4HostPattern = RegExp(r'^\d{1,3}([.-]\d{1,3}){3}$');

  /// Pattern-based catch-all for the `Authorization: MediaBrowser ... Token="..."`
  /// header that Jellyfin's SDK and Findroid both send.
  static final RegExp _mediaBrowserTokenHeader = RegExp(r'Token="[^"]+"', caseSensitive: false);

  /// Field names whose values are credentials in header, query, JSON, and
  /// Dart-map renderings. Requiring an exact key plus separator leaves prose
  /// and diagnostic fields such as `token_count` intact.
  static final RegExp _sensitiveFieldPattern = RegExp(
    r'''(^|[\s?&{},;\[(])(["']?)(authorization|proxy-authorization|cookie|set-cookie|x-auth-token|x-plex-token|x-emby-token|x-api-key|api[-_]?key|auth[-_]?token|access[-_]?token|refresh[-_]?token|id[-_]?token|client[-_]?secret|password|passwd|secret|pin|token)(["']?)([ \t]*[:=][ \t]*)''',
    caseSensitive: false,
    multiLine: true,
  );

  static final RegExp _authorizationSchemePattern = RegExp(r'(?:Bearer|Basic)[ \t]+', caseSensitive: false);

  /// Credentials embedded before the host in an absolute URL.
  static final RegExp _urlUserInfoPattern = RegExp(r'\b([a-z][a-z0-9+.-]*://)([^/@\s]+)@', caseSensitive: false);

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

    final strippedSlash = stripTrailingSlash(normalized);

    if (strippedSlash.isNotEmpty) {
      _addUrl(strippedSlash);
      _addUrl('$strippedSlash/');
    }

    // Capture origin and host-level strings as well to cover most cases.
    if (uri != null && uri.host.isNotEmpty) {
      final origin = '${uri.scheme.isEmpty ? 'https' : uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      _addUrl(origin);
      if (origin.endsWith('/')) {
        _addUrl(origin.substring(0, origin.length - 1));
      }
    }

    _rebuildCombinedPattern();
  }

  /// Registers a URL literal plus the form mpv uses when echoing list-option
  /// values (`:` escaped as `\:`, e.g. `sub-files=https\://host/...`), which
  /// would otherwise slip past the literal match and leak the host.
  static void _addUrl(String url) {
    _addWithLimit(_urls, url, _maxUrls);
    final escaped = url.replaceAll(':', r'\:');
    if (escaped != url) {
      _addWithLimit(_urls, escaped, _maxUrls);
    }
  }

  /// Convenience: register a server's URL and access token together.
  /// Call this before any HTTP traffic so the very first probe URL doesn't
  /// leak credentials verbatim.
  static void registerServer(String? url, String? token) {
    registerServerUrl(url);
    registerToken(token);
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

  /// Redact sensitive fields and known sensitive values from a log string.
  static String redact(String message) {
    var redacted = message.replaceAllMapped(
      _ipv4Pattern,
      (match) => _maskIpv4(match.group(1)!, match.group(2)!, match.group(5)!),
    );

    redacted = redacted.replaceAll(_mediaBrowserTokenHeader, 'Token="[REDACTED]"');
    redacted = _redactSensitiveFields(redacted);

    if (_combinedPattern != null) {
      redacted = redacted.replaceAllMapped(_combinedPattern!, (match) {
        final value = match.group(0)!;
        if (_tokens.contains(value)) return '[REDACTED_TOKEN]';
        if (_urls.contains(value)) return '[REDACTED_URL]';
        return '[REDACTED]';
      });
    }

    return redacted.replaceAllMapped(_urlUserInfoPattern, (match) => '${match.group(1)}[REDACTED]@');
  }

  static String _redactSensitiveFields(String message) {
    final result = StringBuffer();
    var cursor = 0;
    var structureCursor = 0;
    var braceDepth = 0;
    var bracketDepth = 0;
    var quotedBraceDepth = 0;
    var quotedBracketDepth = 0;
    var quote = 0;
    var escaped = false;

    for (final match in _sensitiveFieldPattern.allMatches(message)) {
      if (match.start < cursor || match.end >= message.length) continue;

      final key = match.group(3)!.toLowerCase();
      final valueStart = match.end;
      if (message.startsWith('[REDACTED]', valueStart)) continue;

      while (structureCursor < valueStart) {
        final character = message.codeUnitAt(structureCursor);
        if (quote != 0) {
          if (!escaped && character == quote) {
            quote = 0;
            quotedBraceDepth = 0;
            quotedBracketDepth = 0;
          } else if (!escaped && character == 0x7B) {
            quotedBraceDepth++;
          } else if (!escaped && character == 0x5B) {
            quotedBracketDepth++;
          } else if (!escaped && character == 0x7D && quotedBraceDepth > 0) {
            quotedBraceDepth--;
          } else if (!escaped && character == 0x5D && quotedBracketDepth > 0) {
            quotedBracketDepth--;
          }
          if (!escaped && character == 0x5C) {
            escaped = true;
          } else {
            escaped = false;
          }
          structureCursor++;
          continue;
        }

        final opensQuote =
            character == 0x22 ||
            (character == 0x27 &&
                (structureCursor == 0 ||
                    _isWhitespace(message.codeUnitAt(structureCursor - 1)) ||
                    _isStructuralQuoteBoundary(message.codeUnitAt(structureCursor - 1))));
        if (opensQuote) {
          quote = character;
        } else if (character == 0x7B) {
          braceDepth++;
        } else if (character == 0x5B) {
          bracketDepth++;
        } else if (character == 0x7D && braceDepth > 0) {
          braceDepth--;
        } else if (character == 0x5D && bracketDepth > 0) {
          bracketDepth--;
        }
        structureCursor++;
      }

      final valueQuote = message.codeUnitAt(valueStart);
      final isQuoted = valueQuote == 0x22 || valueQuote == 0x27;
      if (!isQuoted && key == 'authorization' && _startsWithMediaBrowser(message, valueStart)) {
        continue;
      }

      final leadingSeparator = match.group(1)!;
      final isStructured = switch (leadingSeparator) {
        '?' || '&' => false,
        '{' || '[' => true,
        _ when quote != 0 => quotedBraceDepth > 0 || quotedBracketDepth > 0,
        _ => braceDepth > 0 || bracketDepth > 0,
      };
      final contentStart = isQuoted ? valueStart + 1 : valueStart;
      final valueEnd = isQuoted
          ? _quotedValueEnd(message, contentStart, valueQuote)
          : _unquotedValueEnd(
              message,
              contentStart,
              key,
              isStructured: isStructured,
              hashTerminates: match.group(5)!.contains('='),
            );
      if (valueEnd <= contentStart) continue;

      result.write(message.substring(cursor, contentStart));
      result.write('[REDACTED]');
      cursor = valueEnd;
    }

    if (cursor == 0) return message;
    result.write(message.substring(cursor));
    return result.toString();
  }

  static bool _startsWithMediaBrowser(String message, int start) {
    const value = 'mediabrowser';
    if (start + value.length > message.length) return false;
    return message.substring(start, start + value.length).toLowerCase() == value;
  }

  static int _quotedValueEnd(String message, int start, int quote) {
    var escaped = false;
    for (var index = start; index < message.length; index++) {
      final character = message.codeUnitAt(index);
      if (character == 0x0A || character == 0x0D) return index;
      if (!escaped && character == quote) return index;
      if (!escaped && character == 0x5C) {
        escaped = true;
      } else {
        escaped = false;
      }
    }
    return message.length;
  }

  static int _unquotedValueEnd(
    String message,
    int start,
    String key, {
    required bool isStructured,
    required bool hashTerminates,
  }) {
    if (isStructured) return _structuredValueEnd(message, start);

    var index = start;
    if (key == 'authorization' || key == 'proxy-authorization') {
      final scheme = _authorizationSchemePattern.matchAsPrefix(message, start);
      if (scheme != null) index = scheme.end;
    }

    final isCookieHeader = key == 'cookie' || key == 'set-cookie';
    while (index < message.length) {
      final character = message.codeUnitAt(index);
      final isTerminator = isCookieHeader
          ? _isCookieValueTerminator(character)
          : _isUnquotedValueTerminator(character, hashTerminates: hashTerminates);
      if (isTerminator) break;
      index++;
    }
    return index;
  }

  static bool _isWhitespace(int character) {
    return character == 0x20 || character == 0x09 || character == 0x0A || character == 0x0D;
  }

  static bool _isStructuralQuoteBoundary(int character) {
    return character == 0x28 ||
        character == 0x2C ||
        character == 0x3A ||
        character == 0x3B ||
        character == 0x3D ||
        character == 0x5B ||
        character == 0x7B;
  }

  static int _structuredValueEnd(String message, int start) {
    var braceDepth = 0;
    var bracketDepth = 0;
    var parenthesisDepth = 0;
    var quote = 0;
    var escaped = false;
    final first = message.codeUnitAt(start);
    final isNested = first == 0x7B || first == 0x5B || first == 0x28;

    for (var index = start; index < message.length; index++) {
      final character = message.codeUnitAt(index);
      if (isNested && quote != 0) {
        if (!escaped && character == quote) {
          quote = 0;
        }
        if (!escaped && character == 0x5C) {
          escaped = true;
        } else {
          escaped = false;
        }
        continue;
      }

      if (isNested && (character == 0x22 || character == 0x27)) {
        quote = character;
        continue;
      }

      final atValueLevel = braceDepth == 0 && bracketDepth == 0 && parenthesisDepth == 0;
      if (atValueLevel &&
          (character == 0x0A ||
              character == 0x0D ||
              character == 0x29 ||
              character == 0x2C ||
              character == 0x3B ||
              character == 0x5D ||
              character == 0x7D)) {
        return index;
      }

      if (!isNested) continue;
      if (character == 0x7B) {
        braceDepth++;
      } else if (character == 0x5B) {
        bracketDepth++;
      } else if (character == 0x28) {
        parenthesisDepth++;
      } else if (character == 0x7D && braceDepth > 0) {
        braceDepth--;
      } else if (character == 0x5D && bracketDepth > 0) {
        bracketDepth--;
      } else if (character == 0x29 && parenthesisDepth > 0) {
        parenthesisDepth--;
      }
    }

    return message.length;
  }

  static bool _isUnquotedValueTerminator(int character, {required bool hashTerminates}) {
    return character == 0x20 ||
        character == 0x09 ||
        character == 0x0A ||
        character == 0x0D ||
        character == 0x22 ||
        character == 0x27 ||
        character == 0x26 ||
        (hashTerminates && character == 0x23) ||
        character == 0x29 ||
        character == 0x2C ||
        character == 0x3B ||
        character == 0x5D ||
        character == 0x7D;
  }

  static bool _isCookieValueTerminator(int character) {
    return character == 0x0A ||
        character == 0x0D ||
        character == 0x29 ||
        character == 0x2C ||
        character == 0x5D ||
        character == 0x7D;
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
    if (set.contains(value)) return;

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
}
