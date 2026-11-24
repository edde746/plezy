/// Builds watch URLs for provider trailer references.
///
/// Four catalog providers return a bare YouTube video id (AniList
/// `trailer.id`, Simkl `trailer`, Seerr/TMDB `videos[].key`) and each used to
/// interpolate the same watch URL, so the host lived in four places.
///
/// The host is deliberately absent from `android/app/src/main/res/xml/
/// network_security_config.xml`: these URLs are handed to the platform browser
/// (or, on tvOS, the YouTube app) and are never fetched by the app's own HTTP stack,
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

final _youTubeVideoIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// The video id of a YouTube watch, short, embed or youtu.be [url]; null for
/// anything else.
String? youTubeVideoId(String? url) {
  final uri = Uri.tryParse(url?.trim() ?? '');
  if (uri == null || !uri.hasScheme) return null;
  final host = uri.host.toLowerCase();
  final segments = uri.pathSegments;
  final String? id;
  if (host == 'youtu.be') {
    id = segments.firstOrNull;
  } else if (host == 'youtube.com' || host.endsWith('.youtube.com')) {
    id = switch (segments) {
      ['watch', ...] => uri.queryParameters['v'],
      ['embed' || 'shorts' || 'live' || 'v', final videoId, ...] => videoId,
      _ => null,
    };
  } else {
    id = null;
  }
  return id != null && _youTubeVideoIdPattern.hasMatch(id) ? id : null;
}

/// A link the YouTube app opens straight on the video of a YouTube [url].
///
/// tvOS has no browser, so a provider trailer can only play through the
/// YouTube app. Its scheme takes the web watch URL with the id as `v`: a bare
/// `youtube://<id>` opens the app on its home screen and plays nothing.
Uri? youTubeAppUrl(String? url) {
  final id = youTubeVideoId(url);
  if (id == null) return null;
  return Uri(scheme: 'youtube', host: 'www.youtube.com', path: '/watch', queryParameters: {'v': id});
}
