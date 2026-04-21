/// Parse a value that may be [int], [num], or [String] to [int].
/// Used as `@JsonKey(fromJson: flexibleInt)` and in manual `fromJson` factories
/// to handle Plex API responses where numeric fields may arrive as strings
/// (XML-to-JSON conversion).
int? flexibleInt(Object? v) => switch (v) {
  num n => n.toInt(),
  String s => int.tryParse(s),
  _ => null,
};

/// Parse a value that may be [bool], [int] (0/1), or [String] ('1') to [bool].
/// Returns `false` for `null` or unrecognised values.
/// Handles Plex API responses where boolean fields may arrive as integers.
bool flexibleBool(Object? v) => switch (v) {
  bool b => b,
  int n => n == 1,
  String s => s == '1',
  _ => false,
};

/// Parse a value that may be [double], [num], or [String] to [double].
double? flexibleDouble(Object? v) => switch (v) {
  num n => n.toDouble(),
  String s => double.tryParse(s),
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
  List l => l,
  _ => <dynamic>[v],
};
