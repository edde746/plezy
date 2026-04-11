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
