/// Lenient JSON readers for Silo responses.
///
/// Silo's native clients are expected to be forward compatible: unknown
/// fields are ignored, enum-like values stay strings, and a missing member
/// reads as absent rather than failing the whole response.
library;

Map<String, dynamic> asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> mapList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final entry in value)
      if (entry is Map) asMap(entry),
  ];
}

String str(Object? value) => value is String ? value : (value == null ? '' : value.toString());

String? strOrNull(Object? value) {
  if (value == null) return null;
  final s = value is String ? value : value.toString();
  return s.isEmpty ? null : s;
}

int? intOrNull(Object? value) => switch (value) {
  int v => v,
  double v when v.isFinite => v.round(),
  String v => int.tryParse(v) ?? double.tryParse(v)?.round(),
  _ => null,
};

double? doubleOrNull(Object? value) => switch (value) {
  double v when v.isFinite => v,
  int v => v.toDouble(),
  String v => double.tryParse(v),
  _ => null,
};

bool boolOr(Object? value, [bool fallback = false]) => value is bool ? value : fallback;

bool? boolOrNull(Object? value) => value is bool ? value : null;

List<String> strList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final entry in value)
      if (entry is String && entry.isNotEmpty) entry,
  ];
}

/// Seconds (possibly fractional) → whole milliseconds.
int? secondsToMs(Object? seconds) {
  final s = doubleOrNull(seconds);
  return s == null ? null : (s * 1000).round();
}

/// RFC 3339 → milliseconds since epoch.
int? isoToEpochMs(Object? value) {
  final s = strOrNull(value);
  if (s == null) return null;
  return DateTime.tryParse(s)?.millisecondsSinceEpoch;
}

/// RFC 3339 → seconds since epoch (the unit Plezy's `addedAt`/`lastViewedAt`
/// carry).
int? isoToEpochSeconds(Object? value) {
  final ms = isoToEpochMs(value);
  return ms == null ? null : ms ~/ 1000;
}
