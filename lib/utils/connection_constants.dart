/// Centralized connection timeout constants used across the app.
class ConnectionTimeouts {
  /// Timeout for probing a cached/preferred endpoint before falling back to
  /// the full candidate race (used in [PlexServer.findBestWorkingConnection]).
  static const preferredEndpointProbe = Duration(milliseconds: 1500);

  /// Timeout for the connection race where all candidates are tested in
  /// parallel (used in [PlexServer.findBestWorkingConnection]).
  static const connectionRace = Duration(seconds: 2);

  /// HTTP connect timeout for individual HTTP requests to a Plex server.
  static const connect = Duration(seconds: 10);

  /// Per-server connection budget: preferred probe + race + HTTPS upgrade attempt + 1s buffer.
  static const perServerConnect = Duration(milliseconds: 1500 + 2000 + 2000 + 1000);

  /// HTTP receive timeout for streaming/large responses from a Plex server.
  static const receive = Duration(seconds: 120);

  /// HTTP connect timeout for plex.tv / clients.plex.tv API requests.
  static const plexTvConnect = Duration(seconds: 5);

  /// HTTP receive timeout for plex.tv / clients.plex.tv API responses.
  static const plexTvReceive = Duration(seconds: 10);
}
