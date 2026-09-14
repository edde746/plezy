import 'dart:convert';

/// Decodes an mpv node delivered either as a platform-channel value or JSON.
///
/// Native payloads are bounded before traversal so a malformed backend cannot
/// turn a property update into unbounded allocation or recursion on the UI
/// isolate.
abstract final class MpvNodeDecoder {
  static const _maximumDepth = 32;
  static const _maximumEntries = 16384;
  static const _maximumStringBytes = 16 * 1024 * 1024;

  static List<Object?>? decodeList(Object? value) {
    final decoded = _decode(value);
    return decoded is List<Object?> ? decoded : null;
  }

  static Map<Object?, Object?>? decodeMap(Object? value) {
    final decoded = _decode(value);
    return decoded is Map<Object?, Object?> ? decoded : null;
  }

  static Object? _decode(Object? value) {
    if (value is List || value is Map) {
      return _isBoundedStructure(value) ? value : null;
    }
    if (value is! String || value.isEmpty || !_isPlausiblyBoundedJson(value)) return null;

    try {
      final decoded = jsonDecode(value);
      return _isBoundedStructure(decoded) ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static bool _isPlausiblyBoundedJson(String value) {
    if (value.length > _maximumStringBytes) return false;

    var depth = 0;
    var separators = 0;
    var inString = false;
    var escaped = false;
    for (var i = 0; i < value.length; i++) {
      final codeUnit = value.codeUnitAt(i);
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (codeUnit == 0x5c) {
          escaped = true;
        } else if (codeUnit == 0x22) {
          inString = false;
        }
        continue;
      }
      if (codeUnit == 0x22) {
        inString = true;
      } else if (codeUnit == 0x5b || codeUnit == 0x7b) {
        depth++;
        if (depth > _maximumDepth) return false;
      } else if (codeUnit == 0x5d || codeUnit == 0x7d) {
        depth--;
        if (depth < 0) return false;
      } else if (codeUnit == 0x2c) {
        separators++;
        if (separators >= _maximumEntries) return false;
      }
    }
    return !inString && depth == 0;
  }

  static bool _isBoundedStructure(Object? root) {
    var remainingEntries = _maximumEntries;
    var remainingStringBytes = _maximumStringBytes;
    final pending = <(Object?, int)>[(root, 0)];

    while (pending.isNotEmpty) {
      final (value, depth) = pending.removeLast();
      if (remainingEntries == 0 || depth >= _maximumDepth) return false;
      remainingEntries--;

      if (value is String) {
        final byteLength = _utf8LengthAtMost(value, remainingStringBytes);
        if (byteLength == null) return false;
        remainingStringBytes -= byteLength;
      } else if (value is num) {
        if (value is double && !value.isFinite) return false;
      } else if (value is List) {
        if (value.length > remainingEntries) return false;
        for (var i = value.length - 1; i >= 0; i--) {
          pending.add((value[i], depth + 1));
        }
      } else if (value is Map) {
        if (value.length > remainingEntries) return false;
        for (final entry in value.entries) {
          final key = entry.key;
          if (key is! String) return false;
          final byteLength = _utf8LengthAtMost(key, remainingStringBytes);
          if (byteLength == null) return false;
          remainingStringBytes -= byteLength;
          pending.add((entry.value, depth + 1));
        }
      } else if (value != null && value is! bool) {
        return false;
      }
    }
    return true;
  }

  static int? _utf8LengthAtMost(String value, int limit) {
    var length = 0;
    for (var i = 0; i < value.length; i++) {
      final codeUnit = value.codeUnitAt(i);
      if (codeUnit <= 0x7f) {
        length++;
      } else if (codeUnit <= 0x7ff) {
        length += 2;
      } else if (codeUnit >= 0xd800 &&
          codeUnit <= 0xdbff &&
          i + 1 < value.length &&
          value.codeUnitAt(i + 1) >= 0xdc00 &&
          value.codeUnitAt(i + 1) <= 0xdfff) {
        length += 4;
        i++;
      } else {
        length += 3;
      }
      if (length > limit) return null;
    }
    return length;
  }
}
