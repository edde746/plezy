/// Parse a value that may be [int], [num], or [String] to [int].
/// Used as `@JsonKey(fromJson: flexibleInt)` and in manual `fromJson` factories
/// to handle Plex API responses where numeric fields may arrive as strings
/// (XML-to-JSON conversion).
int? flexibleInt(Object? v) => switch (v) {
  final num n => n.toInt(),
  final String s => int.tryParse(s),
  _ => null,
};

int flexibleIntOrZero(Object? v) => flexibleInt(v) ?? 0;

String stringOrEmpty(Object? v) => (v ?? '').toString();

/// Parse a value that may be [bool], [int] (0/1), or [String] ('1'/'true'/'false') to [bool].
/// Returns `false` for `null` or unrecognised values.
/// Handles Plex API responses where boolean fields may arrive as integers.
bool flexibleBool(Object? v) => switch (v) {
  final bool b => b,
  final int n => n == 1,
  final String s => s == '1' || s.toLowerCase() == 'true',
  _ => false,
};

/// Parse a value that may be [bool], [int] (0/1), or [String] ('1'/'true'/'false') to [bool].
/// Returns `null` for `null` or unsupported non-string values; legacy string
/// values other than `'1'`/`'true'` map to `false`.
bool? flexibleBoolNullable(Object? v) => switch (v) {
  final bool b => b,
  final int n => n == 1,
  final String s => s == '1' || s.toLowerCase() == 'true',
  _ => null,
};

/// Parse a value that may be [double], [num], or [String] to [double].
double? flexibleDouble(Object? v) => switch (v) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s),
  _ => null,
};

/// `@JsonKey(readValue:)` adapter — coerces the named field to a String via
/// `toString()` before the generated cast. Use for required `String` fields
/// that Plex may return as int in some endpoints.
Object? readStringField(Map json, String key) => json[key]?.toString();

/// Coerce a value that may be a single Map or a List of Maps into a `List<dynamic>`.
/// Plex often returns `{"Part": {...}}` for single-part media and
/// `{"Part": [{...}, {...}]}` for multi-part — this normalises both shapes.
/// Returns `null` when the value is `null`.
List<dynamic>? flexibleList(Object? v) => switch (v) {
  null => null,
  final List l => l,
  _ => <dynamic>[v],
};

/// Return only JSON object entries from a value that may be one object, a
/// heterogeneous list, or null.
List<Map<String, dynamic>> flexibleMapList(Object? value) {
  return [
    for (final item in flexibleList(value) ?? const <dynamic>[])
      if (item is Map<String, dynamic>) item,
  ];
}

/// Return the first JSON object from a single object or heterogeneous list.
Map<String, dynamic>? firstFlexibleMap(Object? value) {
  for (final item in flexibleList(value) ?? const <dynamic>[]) {
    if (item is Map<String, dynamic>) return item;
  }
  return null;
}

/// Parse every valid JSON object independently, dropping malformed entries
/// instead of letting one row discard an otherwise usable response.
List<T> parseFlexibleJsonList<T>(Object? value, T Function(Map<String, dynamic> json) parse) {
  final result = <T>[];
  for (final json in flexibleMapList(value)) {
    try {
      result.add(parse(json));
    } catch (_) {
      // A malformed row does not invalidate its siblings.
    }
  }
  return result;
}

/// Parse the first JSON object, returning null for missing or malformed data.
T? parseFlexibleJsonObject<T>(Object? value, T Function(Map<String, dynamic> json) parse) {
  final json = firstFlexibleMap(value);
  if (json == null) return null;
  try {
    return parse(json);
  } catch (_) {
    return null;
  }
}

/// Coerce a single String, a List of Strings, or null into `List<String>?`.
/// Non-string elements are dropped; an empty result (or null input) yields
/// `null`. Typed sibling of [flexibleList] — a bare String is wrapped into a
/// single-element list, so callers tolerate both single-value and list shapes.
List<String>? flexibleStringList(Object? v) {
  final list = flexibleList(v);
  if (list == null) return null;
  final result = [
    for (final e in list)
      if (e is String) e,
  ];
  return result.isEmpty ? null : result;
}

/// Coerce a comma-separated String ("en,sv"), a bare String, a List of
/// Strings, or null into `List<String>?`. Since ~July 2026 the Plex account
/// API (clients.plex.tv `/api/v2/user` and `/home/users/{uuid}/switch`)
/// returns the profile language-list fields as CSV strings instead of arrays
/// (#1488) — this tolerates both shapes. Parts are trimmed and empties
/// dropped; an empty result (or null input) yields `null`. CSV-splitting
/// sibling of [flexibleStringList], kept separate so that caller's strings
/// (Fribb IMDb ids) stay verbatim.
List<String>? flexibleCsvStringList(Object? v) {
  final strings = flexibleStringList(v);
  if (strings == null) return null;
  final result = [
    for (final s in strings)
      for (final part in s.split(','))
        if (part.trim().isNotEmpty) part.trim(),
  ];
  return result.isEmpty ? null : result;
}

List<String>? stringListFromRaw(Object? raw, {String? mapKey, bool stringify = false, bool nullIfEmpty = false}) {
  if (raw is! List) return null;
  final result = <String>[];
  for (final value in raw) {
    final source = mapKey != null && value is Map ? value[mapKey] : value;
    final string = stringify
        ? source?.toString()
        : source is String
        ? source
        : null;
    if (string != null) result.add(string);
  }
  if (result.isEmpty && nullIfEmpty) return null;
  return result;
}

List<T>? nullIfEmptyList<T>(List<T> values) => values.isEmpty ? null : values;
