/// How the alpha-jump bar behaves for libraries on this backend.
enum AlphaBarMode {
  /// No alpha bar — hide entirely.
  none,

  /// Plex: server reports per-letter cumulative offsets via `/firstCharacter`,
  /// taps scroll the grid to the offset.
  scrollSnap,

  /// Jellyfin: bar acts as a filter button — taps set `NameStartsWith` query
  /// param, results re-fetch.
  nameStartsWithFilter,
}

/// Static capability flags advertised by a [MediaServerClient]. UI consults
/// these to gate feature affordances per server (e.g. hide Live TV when no
/// connected server supports it).
///
/// These describe what the *backend kind* supports in this app's current
/// implementation — not necessarily what the wire protocol can do. As more
/// Jellyfin features are wired in over time, the corresponding flags flip
/// without changing call sites.
class ServerCapabilities {
  /// Server-side `PlayQueue` resource (Plex `/playQueues`) — enables shared
  /// queue state across devices and Watch Together coordination.
  final bool serverSidePlayQueue;

  /// Server-side editable playlists (Plex `/playlists`, Jellyfin
  /// `/Playlists`).
  final bool serverSidePlaylists;

  /// This backend kind has a Live TV / DVR API the app can talk to. Whether
  /// a *specific* server has Live TV configured is a runtime concern —
  /// [MultiServerProvider.checkLiveTvAvailability] probes each server and
  /// only those with channels surface in [MultiServerProvider.liveTvServers].
  final bool liveTv;

  /// Server has DVR/recording lineups (Plex `/livetv/dvrs`). Channel listing
  /// is gated by [liveTv]; this flag enables the additional recordings/scheduling
  /// UI. Jellyfin's DVR API isn't wired in this app yet, so it stays false even
  /// when [liveTv] is true.
  final bool liveTvDvr;

  /// Server proxies subtitle search (e.g. OpenSubtitles).
  final bool subtitleSearch;

  /// Server can transcode video.
  final bool videoTranscoding;

  /// Server supports server-side downloads / "sync" (the queued-from-server
  /// model). Both Plex and Jellyfin support client-driven downloads, which
  /// is a separate concept.
  final bool serverSideSync;

  /// Server provides curated recommendation hubs (Plex Discover). Jellyfin
  /// returns synthesized hubs but with sparser categorisation.
  final bool richHubs;

  /// Numeric ratings (Plex 0–10 via [Item.userRating]). Jellyfin offers
  /// only a binary like/dislike, so star sliders should be hidden.
  final bool numericUserRating;

  /// External subtitle search/marketplace (Plex `/library/metadata/{id}/subtitles`).
  /// Hides the "Search subtitles" affordance when false.
  final bool externalSubtitleSearch;

  /// Persisting per-track audio/subtitle preferences server-side. Plex uses
  /// `/library/metadata/{id}/prefs` + `selectStream`; Jellyfin saves selected
  /// stream indexes from `/Sessions/Playing/Progress` when the user's Jellyfin
  /// remember-selection settings are enabled. When false, in-player switching
  /// still works but choices don't follow the user across devices.
  final bool trackPreferencePersistence;

  /// Multi-endpoint connection model with relay/local/remote racing
  /// (Plex `findBestWorkingConnection`). Jellyfin servers expose a single
  /// URL, so this is false there.
  final bool endpointFailover;

  /// Watch progress can be queued offline and replayed when reconnected
  /// ([OfflineWatchSyncService]). Jellyfin reports inline only today.
  final bool offlineWatchQueue;

  /// Discord rich-presence integration. Plex-only because the RPC payload
  /// uses Plex-shaped session/metadata.
  final bool discordRpc;

  /// Server exposes a metadata edit endpoint (Plex
  /// `/library/metadata/{id}` PUT). Hides the "Manage" affordances when
  /// false.
  final bool richMetadataEdit;

  /// How the alpha-jump bar should behave for this backend's libraries.
  final AlphaBarMode alphaBar;

  /// Server can supply thumbnails for the player's seek-bar scrub preview.
  /// Plex serves them as a `.bif` asset; Jellyfin uses `/Trickplay` sprite
  /// sheets. Both backends are wired through [ScrubPreviewSource]; the flag
  /// gates whether the player attempts the load at all.
  final bool scrubThumbnails;

  /// Library section exposes a folder hierarchy (Plex
  /// `/library/sections/{id}/folders`). Jellyfin has no equivalent endpoint,
  /// so the "Folders" grouping option is hidden when this is false.
  final bool folderGrouping;

  const ServerCapabilities({
    this.serverSidePlayQueue = false,
    this.serverSidePlaylists = false,
    this.liveTv = false,
    this.liveTvDvr = false,
    this.subtitleSearch = false,
    this.videoTranscoding = true,
    this.serverSideSync = false,
    this.richHubs = false,
    this.numericUserRating = false,
    this.externalSubtitleSearch = false,
    this.trackPreferencePersistence = false,
    this.endpointFailover = false,
    this.offlineWatchQueue = false,
    this.discordRpc = false,
    this.richMetadataEdit = false,
    this.alphaBar = AlphaBarMode.none,
    this.scrubThumbnails = false,
    this.folderGrouping = false,
  });

  /// Defaults for a fully-featured Plex server.
  static const ServerCapabilities plex = ServerCapabilities(
    serverSidePlayQueue: true,
    serverSidePlaylists: true,
    liveTv: true,
    liveTvDvr: true,
    subtitleSearch: true,
    videoTranscoding: true,
    serverSideSync: true,
    richHubs: true,
    numericUserRating: true,
    externalSubtitleSearch: true,
    trackPreferencePersistence: true,
    endpointFailover: true,
    offlineWatchQueue: true,
    discordRpc: true,
    richMetadataEdit: true,
    alphaBar: AlphaBarMode.scrollSnap,
    scrubThumbnails: true,
    folderGrouping: true,
  );

  /// Defaults for a Jellyfin server.
  ///
  /// `videoTranscoding` is `true` — `JellyfinClient.getPlaybackInitialization`
  /// negotiates via `POST /Items/{id}/PlaybackInfo` and uses the server's
  /// `TranscodingUrl` when a non-original quality preset is selected.
  ///
  /// `liveTv` is `true` because Jellyfin exposes `/LiveTv/Channels` and
  /// `/LiveTv/Programs`. Detection + channel listing are wired today;
  /// EPG and tuning are follow-ups.
  static const ServerCapabilities jellyfin = ServerCapabilities(
    serverSidePlayQueue: false,
    serverSidePlaylists: true,
    liveTv: true,
    liveTvDvr: false,
    subtitleSearch: false,
    videoTranscoding: true,
    serverSideSync: false,
    richHubs: false,
    numericUserRating: false,
    externalSubtitleSearch: false,
    trackPreferencePersistence: true,
    endpointFailover: false,
    offlineWatchQueue: false,
    discordRpc: false,
    richMetadataEdit: false,
    alphaBar: AlphaBarMode.nameStartsWithFilter,
    scrubThumbnails: true,
  );

  ServerCapabilities copyWith({
    bool? serverSidePlayQueue,
    bool? serverSidePlaylists,
    bool? liveTv,
    bool? liveTvDvr,
    bool? subtitleSearch,
    bool? videoTranscoding,
    bool? serverSideSync,
    bool? richHubs,
    bool? numericUserRating,
    bool? externalSubtitleSearch,
    bool? trackPreferencePersistence,
    bool? endpointFailover,
    bool? offlineWatchQueue,
    bool? discordRpc,
    bool? richMetadataEdit,
    AlphaBarMode? alphaBar,
    bool? scrubThumbnails,
    bool? folderGrouping,
  }) {
    return ServerCapabilities(
      serverSidePlayQueue: serverSidePlayQueue ?? this.serverSidePlayQueue,
      serverSidePlaylists: serverSidePlaylists ?? this.serverSidePlaylists,
      liveTv: liveTv ?? this.liveTv,
      liveTvDvr: liveTvDvr ?? this.liveTvDvr,
      subtitleSearch: subtitleSearch ?? this.subtitleSearch,
      videoTranscoding: videoTranscoding ?? this.videoTranscoding,
      serverSideSync: serverSideSync ?? this.serverSideSync,
      richHubs: richHubs ?? this.richHubs,
      numericUserRating: numericUserRating ?? this.numericUserRating,
      externalSubtitleSearch: externalSubtitleSearch ?? this.externalSubtitleSearch,
      trackPreferencePersistence: trackPreferencePersistence ?? this.trackPreferencePersistence,
      endpointFailover: endpointFailover ?? this.endpointFailover,
      offlineWatchQueue: offlineWatchQueue ?? this.offlineWatchQueue,
      discordRpc: discordRpc ?? this.discordRpc,
      richMetadataEdit: richMetadataEdit ?? this.richMetadataEdit,
      alphaBar: alphaBar ?? this.alphaBar,
      scrubThumbnails: scrubThumbnails ?? this.scrubThumbnails,
      folderGrouping: folderGrouping ?? this.folderGrouping,
    );
  }
}
