/// Centralized HTTP timeout constants for both backends. The same
/// [MediaServerHttpClient] wrapper is used by Plex and Jellyfin clients —
/// timeouts are kept here so the budgets per phase are visible at a
/// glance.
class MediaServerTimeouts {
  static const connect = Duration(seconds: 10);

  static const receive = Duration(seconds: 120);

  /// Retry budget for home `/hubs` startup calls. These endpoints can be slow
  /// while Plex wakes idle disks, but should not block forever.
  static const homeHubAttemptTimeouts = [Duration(seconds: 10), Duration(seconds: 5), Duration(milliseconds: 2500)];

  /// Retry budget for per-library home hub rows (`/hubs/sections/{id}`). These
  /// can be slower than the top-level home hub call on remote Plex servers.
  static const libraryHubAttemptTimeouts = [Duration(seconds: 10), Duration(seconds: 8), Duration(seconds: 5)];

  /// Timeout for probing a cached/preferred endpoint (used in
  /// [PlexServer.findBestWorkingConnection]).
  static const preferredEndpointProbe = Duration(milliseconds: 1500);

  /// How long the cached/preferred endpoint probe gets to answer before the
  /// full candidate race starts alongside it. A healthy cached endpoint
  /// answers well inside this window and wins deterministically; a stale one
  /// (e.g. a cached LAN address probed from outside the LAN) only delays
  /// discovery by this much instead of the full [preferredEndpointProbe].
  static const preferredEndpointHeadStart = Duration(milliseconds: 300);

  /// Timeout for the connection race where all candidates are tested in
  /// parallel (used in [PlexServer.findBestWorkingConnection]).
  static const connectionRace = Duration(seconds: 2);

  /// Per-server connection watchdog ceiling. The discovery path is no longer
  /// strictly serial (cached probe overlaps the race; the HTTPS upgrade runs
  /// off the critical path), so this is a generous upper bound rather than a
  /// sum of phases.
  static const perServerConnect = Duration(milliseconds: 6500);

  /// HTTP timeout for the live-TV tune POST. Matches Plex web's value — the
  /// default 10s connect budget is too tight on Fire-TV cold starts.
  static const tune = Duration(seconds: 30);

  static const plexTvConnect = Duration(seconds: 15);

  static const plexTvReceive = Duration(seconds: 10);

  /// Probe + token-validate timeout — Jellyfin servers respond fast on
  /// `/System/Info/Public` and `/Users/Me`.
  static const jellyfinProbe = Duration(seconds: 8);

  /// Best-effort `/Sessions/Logout` timeout — short because the call is
  /// fire-and-forget; the token is removed locally regardless.
  static const jellyfinSignOut = Duration(seconds: 5);
}
