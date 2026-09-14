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

/// Encode query params with `%20` for spaces (not `+`).
/// Null values are omitted and iterable values are emitted as repeated keys.
///
/// Used instead of `Uri.queryParameters` (which emits `+` for spaces) wherever
/// the server rejects `+` — Plex's transcode endpoints and Seerr's TMDB-backed
/// `/search` proxy both do.
String encodeQueryParameters(Map<String, Object?>? params) {
  if (params == null || params.isEmpty) return '';
  final parts = <String>[];

  void add(String key, Object? value) {
    if (value == null) return;
    if (value is Iterable) {
      for (final item in value) {
        add(key, item);
      }
      return;
    }
    parts.add(
      '${Uri.encodeComponent(key)}='
      '${Uri.encodeComponent(value.toString())}',
    );
  }

  for (final entry in params.entries) {
    add(entry.key, entry.value);
  }
  return parts.join('&');
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

/// One guess applied to schemeless user input: a scheme plus the port to try
/// when the user typed none. A null [port] means the scheme's default port.
typedef BaseUrlGuess = ({String scheme, int? port});

/// Whether [input] already carries an explicit `scheme://`.
bool hasUrlScheme(String input) => _schemePattern.hasMatch(input);

/// Expands a user-typed server address into ordered, de-duplicated probe
/// candidates.
///
/// An explicit scheme is authoritative and comes back alone — the user told us
/// where the server is. Otherwise every entry of [guesses] is applied in
/// order, with a port the user typed always beating the guess's port, so
/// `host:8096` collapses to one candidate per scheme while a bare `host` also
/// picks up the guessed install ports. Query and fragment are dropped; a
/// sub-path is preserved on every candidate.
///
/// Candidates are guesses for discovery only: persist the one that answered,
/// never the whole list. Blank input and input with no host (`/seerr`) return
/// empty — no candidate built from those could reach anything.
List<String> expandBaseUrlCandidates(String input, {required List<BaseUrlGuess> guesses}) {
  final trimmed = canonicalizeBaseUrl(input);
  if (trimmed.isEmpty) return const [];
  if (hasUrlScheme(trimmed)) return List.unmodifiable([trimmed]);

  final parsed = Uri.tryParse('http://$trimmed');
  if (parsed == null || parsed.host.isEmpty) return const [];

  final candidates = <String>[];
  final seen = <String>{};
  for (final guess in guesses) {
    // Built field by field rather than with `replace`, which treats a null
    // query/fragment as "keep mine" — and a base URL carrying either can't
    // have request paths appended to it.
    final candidate = Uri(
      scheme: guess.scheme,
      userInfo: parsed.userInfo,
      host: parsed.host,
      // A port the user typed is authoritative; null leaves the scheme's own.
      port: parsed.hasPort ? parsed.port : guess.port,
      path: parsed.path,
    );
    final normalized = stripTrailingSlash(candidate.toString());
    if (normalized.isEmpty || !seen.add(normalized)) continue;
    candidates.add(normalized);
  }
  return List.unmodifiable(candidates);
}
