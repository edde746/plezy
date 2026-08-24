/// Static capability flags advertised by a [MediaServerClient]. UI consults
/// these to gate feature affordances per server (e.g. hide Live TV when no
/// connected server supports it).
///
/// These describe what the *backend kind* supports in this app's current
/// implementation — not necessarily what the wire protocol can do. As more
/// Jellyfin features are wired in over time, the corresponding flags flip
/// without changing call sites.
class ServerCapabilities {
  /// This backend kind has a Live TV / DVR API the app can talk to. Whether
  /// a *specific* server has Live TV configured is a runtime concern —
  /// [MultiServerProvider.checkLiveTvAvailability] probes each server and
  /// only those with channels surface in [MultiServerProvider.liveTvServers].
  final bool liveTv;

  /// Backend has a recording/DVR API wired in this app. Channel listing is
  /// gated by [liveTv]; this flag enables the additional recordings/scheduling
  /// UI. Plex serves `/media/subscriptions`; Jellyfin and Emby adapt
  /// `/LiveTv/Timers` + `/LiveTv/SeriesTimers`.
  final bool liveTvDvr;

  /// Server can transcode video.
  final bool videoTranscoding;

  /// Server provides curated recommendation hubs (Plex Discover). Jellyfin
  /// returns synthesized hubs but with sparser categorisation.
  final bool richHubs;

  /// Numeric ratings (Plex 0–10 via [Item.userRating]). Jellyfin has no
  /// numeric user rating, so star sliders should be hidden.
  final bool numericUserRating;

  /// Per-user favorite flag ("heart") on media items. Jellyfin exposes it via
  /// `/UserFavoriteItems/{itemId}?userId=...`; Plex has no equivalent.
  final bool userFavorites;

  /// Hide an item from Continue Watching without changing watch state or
  /// playback progress. Plex exposes this directly; Jellyfin does not.
  final bool continueWatchingRemoval;

  /// External subtitle search/marketplace (Plex `/library/metadata/{id}/subtitles`).
  /// Hides the "Search subtitles" affordance when false.
  final bool externalSubtitleSearch;

  /// Server exposes metadata edit endpoints. Hides edit affordances when false.
  final bool richMetadataEdit;

  /// Server can supply thumbnails for the player's seek-bar scrub preview.
  /// Plex serves them as a `.bif` asset; Jellyfin uses `/Trickplay` sprite
  /// sheets. Both backends are wired through [ScrubPreviewSource]; the flag
  /// gates whether the player attempts the load at all.
  final bool scrubThumbnails;

  /// Library section exposes a folder hierarchy. Plex uses
  /// `/library/sections/{id}/folders`; Jellyfin uses direct-child
  /// `/Items?ParentId=...&Recursive=false` queries.
  final bool folderGrouping;

  /// Server can build an "instant mix" / radio track list from a seed item.
  /// Jellyfin: `/Items/{id}/InstantMix`; Plex: station play queues
  /// (`POST /playQueues?type=audio&uri=...station...`).
  final bool instantMix;

  const ServerCapabilities({
    this.liveTv = false,
    this.liveTvDvr = false,
    this.videoTranscoding = true,
    this.richHubs = false,
    this.numericUserRating = false,
    this.userFavorites = false,
    this.continueWatchingRemoval = false,
    this.externalSubtitleSearch = false,
    this.richMetadataEdit = false,
    this.scrubThumbnails = false,
    this.folderGrouping = false,
    this.instantMix = false,
  });

  /// Defaults for a fully-featured Plex server.
  static const ServerCapabilities plex = ServerCapabilities(
    liveTv: true,
    liveTvDvr: true,
    videoTranscoding: true,
    richHubs: true,
    numericUserRating: true,
    userFavorites: false,
    continueWatchingRemoval: true,
    externalSubtitleSearch: true,
    richMetadataEdit: true,
    scrubThumbnails: true,
    folderGrouping: true,
    instantMix: true,
  );

  /// Defaults for a Jellyfin server.
  ///
  /// `videoTranscoding` is `true` — `JellyfinClient.getPlaybackInitialization`
  /// negotiates via `POST /Items/{id}/PlaybackInfo` and uses the server's
  /// `TranscodingUrl` when a non-original quality preset is selected.
  ///
  /// `liveTv` is `true` because Jellyfin exposes `/LiveTv/Channels` and
  /// `/LiveTv/Programs`; `liveTvDvr` rides the timer APIs
  /// (`/LiveTv/Timers`, `/LiveTv/SeriesTimers`).
  static const ServerCapabilities jellyfin = ServerCapabilities(
    liveTv: true,
    liveTvDvr: true,
    videoTranscoding: true,
    richHubs: false,
    numericUserRating: false,
    userFavorites: true,
    externalSubtitleSearch: false,
    richMetadataEdit: true,
    scrubThumbnails: true,
    folderGrouping: true,
    instantMix: true,
  );

  /// Defaults for an Emby server.
  ///
  /// `continueWatchingRemoval` is the one flag where Emby is ahead of Jellyfin:
  /// `POST /Users/{uid}/Items/{id}/HideFromResume` drops an item from Continue
  /// Watching while keeping its resume position, and Jellyfin 10.11 has no
  /// equivalent route.
  ///
  /// Scrub thumbnails take a different transport than Jellyfin's: Emby has no
  /// `Trickplay` item field or sprite-sheet route, so the player loads a
  /// Roku-format BIF from `/Videos/{id}/index.bif` instead — the same wire
  /// format Plex serves, parsed by the same `BifThumbnailService`. Emby only
  /// fills the endpoint once its own preview-extraction task has run; a server
  /// that has not generated frames answers with a header-only BIF, which
  /// parses to zero frames and keeps the seek-bar tooltip suppressed.
  static const ServerCapabilities emby = ServerCapabilities(
    liveTv: true,
    liveTvDvr: true,
    videoTranscoding: true,
    richHubs: false,
    numericUserRating: false,
    userFavorites: true,
    continueWatchingRemoval: true,
    externalSubtitleSearch: false,
    richMetadataEdit: true,
    scrubThumbnails: true,
    folderGrouping: true,
    instantMix: true,
  );

  /// Every flag here is fixed per backend *kind* except [videoTranscoding],
  /// which Plex probes per server (`PlexClient.capabilities`) — so that is the
  /// only override this type needs. Widen the parameter list if another flag
  /// ever becomes a runtime probe.
  ServerCapabilities copyWith({bool? videoTranscoding}) {
    return ServerCapabilities(
      liveTv: liveTv,
      liveTvDvr: liveTvDvr,
      videoTranscoding: videoTranscoding ?? this.videoTranscoding,
      richHubs: richHubs,
      numericUserRating: numericUserRating,
      userFavorites: userFavorites,
      continueWatchingRemoval: continueWatchingRemoval,
      externalSubtitleSearch: externalSubtitleSearch,
      richMetadataEdit: richMetadataEdit,
      scrubThumbnails: scrubThumbnails,
      folderGrouping: folderGrouping,
      instantMix: instantMix,
    );
  }
}
