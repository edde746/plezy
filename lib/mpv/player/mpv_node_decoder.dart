import 'dart:convert';

/// Decodes an mpv node delivered either as a platform-channel value or JSON.
abstract final class MpvNodeDecoder {
  static List<Object?>? decodeList(Object? value) {
    final decoded = _decode(value);
    return decoded is List<Object?> ? decoded : null;
  }

  static Map<Object?, Object?>? decodeMap(Object? value) {
    final decoded = _decode(value);
    return decoded is Map<Object?, Object?> ? decoded : null;
  }

  static Object? _decode(Object? value) {
    if (value is List || value is Map) return value;
    if (value is! String || value.isEmpty) return null;

    try {
      return jsonDecode(value);
    } on FormatException {
      return null;
    }
  }
}
