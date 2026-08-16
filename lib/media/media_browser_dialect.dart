import 'media_backend.dart';

/// Which flavour of the MediaBrowser HTTP API a server speaks.
///
/// Jellyfin forked from Emby 3.5.2, so the two still share almost their entire
/// wire contract: identical `BaseItemDto` shapes, the same `/Items` query
/// grammar, the `MediaBrowser` Authorization scheme, the `X-Emby-Token` header
/// and `api_key=` query fallback. Plezy therefore drives both through one
/// client stack ([JellyfinClient]) and keeps every delta in this one type.
///
/// Verified against Jellyfin 10.10.7/10.11 and Emby 4.9.5:
/// - Jellyfin 10.9 renamed a batch of user-scoped write routes to unprefixed
///   forms and added `/Users/Me`. Emby only has the original user-scoped
///   spellings — see [MediaBrowserPaths].
/// - Trickplay, `/MediaSegments`, `/Audio/{id}/Lyrics`, `/Items/Filters` and
///   Quick Connect do not exist on Emby. `/Audio/{id}/Lyrics` is actively
///   harmful there: Emby parses `Lyrics` as a container name and starts an
///   ffmpeg transcode.
/// - Emby tolerates unknown `Fields`/`SortBy` values, so the shared field sets
///   need no per-dialect pruning.
enum MediaBrowserDialect {
  jellyfin,
  emby;

  /// Stable wire/persistence id. Matches the [MediaBackend] ids for the
  /// same server kind.
  String get id => switch (this) {
    MediaBrowserDialect.jellyfin => 'jellyfin',
    MediaBrowserDialect.emby => 'emby',
  };

  static MediaBrowserDialect fromId(String id) => switch (id) {
    'jellyfin' => MediaBrowserDialect.jellyfin,
    'emby' => MediaBrowserDialect.emby,
    _ => throw ArgumentError('Unknown MediaBrowserDialect id: $id'),
  };

  /// Like [fromId] but tolerates legacy/missing values by defaulting to
  /// Jellyfin. Persisted connection rows written before Emby support carry no
  /// `dialect` key at all, and those are Jellyfin by construction.
  static MediaBrowserDialect fromIdOrJellyfin(Object? id) => switch (id) {
    'emby' => MediaBrowserDialect.emby,
    _ => MediaBrowserDialect.jellyfin,
  };

  MediaBackend get backend => switch (this) {
    MediaBrowserDialect.jellyfin => MediaBackend.jellyfin,
    MediaBrowserDialect.emby => MediaBackend.emby,
  };

  /// Product name, used verbatim in UI that names the backend. These are
  /// trademarks, so they are not localized.
  String get productName => switch (this) {
    MediaBrowserDialect.jellyfin => 'Jellyfin',
    MediaBrowserDialect.emby => 'Emby',
  };

  /// Placeholder host shown in the "server URL" field.
  String get exampleBaseUrl => switch (this) {
    MediaBrowserDialect.jellyfin => 'https://jellyfin.example.com',
    MediaBrowserDialect.emby => 'https://emby.example.com',
  };

  /// UDP payload the server answers on port 7359. Emby ignores Jellyfin's
  /// string and vice versa, which makes the datagram itself a reliable
  /// dialect discriminator during LAN discovery.
  String get lanDiscoveryMessage => switch (this) {
    MediaBrowserDialect.jellyfin => 'who is JellyfinServer?',
    MediaBrowserDialect.emby => 'who is EmbyServer?',
  };

  /// Ports appended when the user types a bare host, most-likely first.
  /// Both ship 8096 for HTTP; Emby's default HTTPS port is 8920.
  List<int> get httpsPortGuesses => switch (this) {
    MediaBrowserDialect.jellyfin => const [8096],
    MediaBrowserDialect.emby => const [8920, 8096],
  };

  /// `/QuickConnect/*` plus `POST /Users/AuthenticateWithQuickConnect`.
  bool get supportsQuickConnect => this == MediaBrowserDialect.jellyfin;

  /// `/Videos/{id}/Trickplay/{width}/{n}.jpg` sprite sheets and the
  /// `Trickplay` item field (Jellyfin 10.9+). Emby 404s on the route and never
  /// fills the field; its scrub previews ride a Roku-format BIF at
  /// `/Videos/{id}/index.bif` instead (see [ServerCapabilities.emby]), parsed
  /// by the shared BIF service. This flag gates only the Jellyfin manifest
  /// transport, not Emby scrub previews.
  bool get supportsTrickplay => this == MediaBrowserDialect.jellyfin;

  /// `/MediaSegments/{itemId}` intro/outro/credit markers (Jellyfin 10.10+).
  /// Emby 404s; chapter-name fallback still applies.
  bool get supportsMediaSegments => this == MediaBrowserDialect.jellyfin;

  /// `GET /Audio/{id}/Lyrics` (Jellyfin 10.9+). Never call this on Emby: the
  /// route resolves to audio streaming with `Lyrics` as the container and
  /// spawns an ffmpeg process that fails with a 500.
  bool get supportsLyrics => this == MediaBrowserDialect.jellyfin;

  /// `GET /Items/Filters`, the single call that returns a library's distinct
  /// genres, official ratings, tags and years. Emby has no aggregate route; the
  /// client reassembles the same payload from `/Genres`, `/OfficialRatings`,
  /// `/Tags` and `/Years`.
  bool get supportsAggregateItemFilters => this == MediaBrowserDialect.jellyfin;

  /// `POST /Users/{uid}/Items/{id}/HideFromResume` hides an item from Continue
  /// Watching without clearing its resume position.
  ///
  /// Emby-only, and the one capability where Emby is ahead of Jellyfin:
  /// measured 200 on Emby 4.9.5 (the row leaves `/Users/{uid}/Items/Resume`
  /// while `UserData.PlaybackPositionTicks` survives), and 404 on Jellyfin
  /// 10.11 for both that spelling and `/UserItems/{id}/HideFromResume`.
  bool get supportsContinueWatchingRemoval => this == MediaBrowserDialect.emby;

  /// `POST /Items/{id}` persists genre and tag edits from the `GenreItems` /
  /// `TagItems` name-pair arrays rather than the plain `Genres` / `Tags` string
  /// lists.
  ///
  /// Measured on Emby 4.9.5: sending `Genres: ['Action']` alone round-trips as
  /// an empty list and the `/Genres` facet stays empty, while
  /// `GenreItems: [{'Name': 'Action'}]` sticks and is immediately indexed. The
  /// sibling fields (`Studios`, `People`, `ProductionLocations`, `Taglines`,
  /// `Overview`, `OriginalTitle`) all persist from their ordinary shapes on
  /// both dialects.
  bool get metadataWritesUseNamePairLists => this == MediaBrowserDialect.emby;

  /// `GET /Shows/NextUp` answers an unscoped, library-wide query.
  ///
  /// Jellyfin-only. Measured on Emby 4.9.5 with one played episode: the
  /// unscoped query returns `TotalRecordCount: 0` under every parameter
  /// combination tried (`ParentId` on the view or the series, `SeriesId=`,
  /// `Recursive`, `GroupItems`, `EnableResumable`, `SortBy`), while the same
  /// query with `SeriesId=<series>` returns the series' 23 remaining episodes.
  /// Emby therefore only computes Next Up per series, and the library-wide
  /// shelf has to be reconstructed client-side from recently played episodes.
  bool get supportsGlobalNextUp => this == MediaBrowserDialect.jellyfin;

  /// The resume route returns only items with a saved playback position.
  ///
  /// Jellyfin-only. Measured with one in-progress movie and 30 started series:
  /// Jellyfin's `/UserItems/Resume` returned exactly the movie, while Emby's
  /// `/Users/{uid}/Items/Resume` returned 30 rows — the movie plus 29
  /// zero-position *next* episodes — and `Filters=IsResumable` did not remove
  /// them. Emby's own UI merges both into one shelf; Plezy models Continue
  /// Watching and Next Up as separate rows, so the Emby resume leg is filtered
  /// to genuine progress and the next-up rows come from the Next Up path
  /// instead. Without the filter a started series occupies both rows and can
  /// push the real in-progress item out of a limited one.
  bool get resumeReturnsOnlyStartedItems => this == MediaBrowserDialect.jellyfin;

  /// `/Sessions/Playing` and `/Sessions/Playing/Progress` reject a body with no
  /// `PlaySessionId`.
  ///
  /// Measured on Emby 4.9.5: both return HTTP 400 `Value cannot be null.
  /// (Parameter 'key')` when the field is absent, while
  /// `/Sessions/Playing/Stopped` tolerates it. Jellyfin accepts all three
  /// without one. Callers that never negotiated a PlaybackInfo session — the
  /// offline watch-progress sync is the live example — therefore need a
  /// synthesized id on Emby or their progress is silently dropped.
  bool get requiresPlaySessionId => this == MediaBrowserDialect.emby;

  /// `/Items?IncludeItemTypes=Playlist` honours a `MediaTypes` filter.
  ///
  /// Measured on Emby 4.9.5: passing *any* `MediaTypes` value makes the server
  /// discard `IncludeItemTypes` and return the whole index — 14554 rows of
  /// `Genre`/`Person`/`Studio`/`Movie` instead of the one playlist. Emby also
  /// never populates `MediaType` on a playlist DTO, not even for a playlist
  /// created with `MediaType=Audio`, so there is nothing to filter on either
  /// side and every playlist is returned regardless of the requested type.
  bool get playlistsFilterByMediaType => this == MediaBrowserDialect.jellyfin;

  /// True when the dialect only accepts the pre-10.9 `/Users/{userId}/…`
  /// spelling of the user-scoped item routes.
  bool get requiresUserScopedItemRoutes => this == MediaBrowserDialect.emby;

  /// Best-effort dialect detection from a `/System/Info/Public` body.
  ///
  /// Jellyfin reports `ProductName: "Jellyfin Server"`. Emby 4.9 omits
  /// `ProductName` entirely but is the only one of the two that returns the
  /// `RemoteAddresses` array. Returns `null` when neither signal is present so
  /// callers keep whichever dialect the user picked.
  static MediaBrowserDialect? detectFromPublicSystemInfo(Map<String, Object?> json) {
    final productName = json['ProductName'];
    if (productName is String && productName.isNotEmpty) {
      final normalized = productName.toLowerCase();
      if (normalized.contains('jellyfin')) return MediaBrowserDialect.jellyfin;
      if (normalized.contains('emby')) return MediaBrowserDialect.emby;
    }
    if (json.containsKey('RemoteAddresses')) return MediaBrowserDialect.emby;
    return null;
  }
}
