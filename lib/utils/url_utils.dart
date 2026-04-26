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
