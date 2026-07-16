/// Backend-neutral URL helpers.
library;

/// Removes a single trailing `/` from [input] so subsequent path joins
/// don't produce double slashes (`http://host//Items` → `http://host/Items`).
/// Trims whitespace first; returns the input unchanged if it has no trailing
/// slash. Empty input returns empty.
String stripTrailingSlash(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.endsWith('/')) {
    return trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

final RegExp _schemePattern = RegExp(r'^[A-Za-z][A-Za-z\d+.-]*://');

/// Canonicalizes a server base URL: trims, strips one trailing `/`, and
/// lowercases the scheme (`Https://host` → `https://host`). Dart's `Uri`
/// normalizes scheme case for API requests, but URLs handed to the player as
/// raw strings don't get that treatment, and FFmpeg's protocol lookup is
/// case-sensitive — a mixed-case scheme fails with "Protocol not found".
/// Everything after `://` is left untouched.
String canonicalizeBaseUrl(String input) {
  final stripped = stripTrailingSlash(input);
  final match = _schemePattern.firstMatch(stripped);
  if (match == null) return stripped;
  return stripped.replaceRange(0, match.end, match.group(0)!.toLowerCase());
}
