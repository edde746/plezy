/// Centralized connection timeout constants used across the app.
class ConnectionTimeouts {
  /// Timeout for probing a cached/preferred endpoint before falling back to
  /// the full candidate race (used in [PlexServer.findBestWorkingConnection]).
  static const preferredEndpointProbe = Duration(seconds: 2);

  /// Timeout for the connection race where all candidates are tested in
  /// parallel (used in [PlexServer.findBestWorkingConnection]).
  static const connectionRace = Duration(seconds: 4);

  /// Dio connect timeout for individual HTTP requests to a Plex server.
  static const connect = Duration(seconds: 10);

  /// Timeout for [MultiServerManager.connectToAllServers] — the maximum time
  /// to wait for each server's connection future.
  static const connectAll = Duration(seconds: 10);

  /// Dio receive timeout for streaming/large responses from a Plex server.
  static const receive = Duration(seconds: 120);
}
