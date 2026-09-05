/// Centralized HTTP timeout constants for both backends. The same
/// [MediaServerHttpClient] wrapper is used by Plex and Jellyfin clients —
/// timeouts are kept here so the budgets per phase are visible at a
/// glance.
class MediaServerTimeouts {
  static const connect = Duration(seconds: 10);

  static const receive = Duration(seconds: 120);

  /// Whole-request deadline for home `/hubs` startup calls. These endpoints can
  /// be slow while Plex wakes idle disks or a CDN-fronted Jellyfin runs a cold
  /// query, but should not block forever.
  ///
  /// Deliberately a *single* budget rather than a retry ladder. `Client.send`
  /// resolves when response headers arrive, so this budget covers the server's
  /// think time, not just the socket connect — a slow-but-alive query trips it.
  /// Replaying that request makes the server re-run the same expensive query
  /// from scratch, so the old `[10s, 5s, 2.5s]` ladder turned an 11s answer
  /// into a 17.5s empty row (#1784). See [retryTransientMediaServerCall].
  static const homeHubDeadline = Duration(seconds: 15);

  /// Whole-request deadline for per-library home hub rows
  /// (`/hubs/sections/{id}`, Jellyfin `/Items/Latest`). These can be slower
  /// than the top-level home hub call on remote servers. Same single-budget
  /// rationale as [homeHubDeadline] — it replaced `[10s, 8s, 5s]`, whose 23s
  /// worst case was the dominant cold-start stall in #1784.
  static const libraryHubDeadline = Duration(seconds: 20);

  /// Whole-request deadline for the Explore reverse library lookup
  /// (`findByExternalIds`: Plex `/hubs/search` and `/library/all?guid=`,
  /// Jellyfin `/Items?SearchTerm=`). It runs behind an in-page progress row
  /// after a tap, so it can afford the same budget as a library hub row. Used
  /// with endpoint failover off: a large library that answers slowly is not a
  /// dead endpoint, and treating the timeout as one used to cascade the whole
  /// client through its stale LAN candidates (#2098).
  static const libraryLookup = Duration(seconds: 20);

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

  /// Authenticated health probe timeout. Health sweeps await every server, so
  /// a stale Plex endpoint must not hold the whole sweep for [receive].
  static const plexProbe = Duration(seconds: 8);

  /// Probe + token-validate timeout — Jellyfin servers respond fast on
  /// `/System/Info/Public` and `/Users/Me`.
  static const jellyfinProbe = Duration(seconds: 8);

  /// Per-item delete-permission probe. Shorter than [jellyfinProbe] because it
  /// blocks a context menu from opening: a server that is nominally online but
  /// hung must not hold the menu for a health-sweep budget. Unlike the other
  /// values here it is also applied as a whole-request deadline by the caller
  /// (the per-request budget covers the connect and receive phases
  /// individually), and expiry fails closed — no delete entry — so the ceiling
  /// only ever costs an entry, never safety.
  static const jellyfinDeletePermission = Duration(seconds: 3);

  /// Whole-probe deadline for establishing what a server-side delete will
  /// destroy (see `resolveDeleteImpact`). Generous compared to
  /// [jellyfinDeletePermission] for two reasons: it runs behind a modal
  /// spinner *after* the user asked to delete, not while a menu is opening,
  /// and it may fan out one detail request per sibling episode when browse
  /// rows omit file paths.
  ///
  /// Unlike the permission probe, expiry cannot fail closed — Plex never
  /// sends file paths to restricted users, so refusing the delete would
  /// permanently remove a feature the server itself authorizes. Expiry
  /// instead downgrades the confirmation to its explicit "scope unverified"
  /// form.
  static const deleteImpactProbe = Duration(seconds: 10);
}
