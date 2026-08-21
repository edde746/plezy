/// Builds watch URLs for provider trailer references.
///
/// Four catalog providers return a bare YouTube video id (AniList
/// `trailer.id`, Simkl `trailer`, Seerr/TMDB `videos[].key`) and each used to
/// interpolate the same watch URL, so the host lived in four places.
///
/// The host is deliberately absent from `android/app/src/main/res/xml/
/// network_security_config.xml`: these URLs are handed to the platform browser
/// through `url_launcher` and are never fetched by the app's own HTTP stack,
/// so they are not fixed endpoints to pin. `test/android/
/// network_security_config_test.dart` enforces that distinction for the
/// services that *do* make requests.
library;

const _youTubeWatchPrefix = 'https://www.youtube.com/watch?v=';

/// Resolves a provider trailer reference to an absolute URL.
///
/// Accepts either a bare YouTube video id or an already-absolute URL, since
/// providers are inconsistent about which they send — Seerr returns a full
/// `url` on some entries and only a `key` on others. Returns null for a
/// missing or blank reference.
String? youTubeTrailerUrl(String? reference) {
  final value = reference?.trim();
  if (value == null || value.isEmpty) return null;
  if (Uri.tryParse(value)?.hasScheme == true) return value;
  return '$_youTubeWatchPrefix$value';
}
