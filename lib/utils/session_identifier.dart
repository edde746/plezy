import 'dart:math';

/// 24-character random alphanumeric identifier used for transient session
/// handles (Plex `X-Plex-Session-Identifier`, Jellyfin `PlaySessionId`).
///
/// Backend-neutral: the format matches Plex's official client because the
/// Plex transcoder accepts that shape, and Jellyfin treats `PlaySessionId`
/// as opaque so any unique string works. Lifted out of `PlexClient` so
/// Jellyfin code paths don't have to import the Plex client just to mint a
/// session id.
String generateSessionIdentifier() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rand = Random();
  return List.generate(24, (_) => chars[rand.nextInt(chars.length)]).join();
}
