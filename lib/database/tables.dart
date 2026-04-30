import 'package:drift/drift.dart';

/// Key-value cache table for media-server API responses (Plex, Jellyfin).
/// Used for offline support - stores raw JSON responses.
class ApiCache extends Table {
  /// Composite key: serverId:endpoint (e.g., "abc123:/library/metadata/12345"
  /// for Plex, "abc123:/Users/.../Items/..." for Jellyfin)
  TextColumn get cacheKey => text()();

  /// JSON response data
  TextColumn get data => text()();

  /// Whether this item is pinned for offline access
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();

  /// Timestamp for cache invalidation (optional future use)
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

@DataClassName('DownloadQueueItem')
class DownloadQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get mediaGlobalKey => text().unique()();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  IntColumn get addedAt => integer()();
  BoolColumn get downloadSubtitles => boolean().withDefault(const Constant(true))();
  BoolColumn get downloadArtwork => boolean().withDefault(const Constant(true))();
}

@DataClassName('DownloadedMediaItem')
@TableIndex(name: 'idx_downloaded_media_status', columns: {#status})
@TableIndex(name: 'idx_downloaded_media_server', columns: {#serverId})
@TableIndex(name: 'idx_downloaded_media_parent', columns: {#parentRatingKey})
@TableIndex(name: 'idx_downloaded_media_grandparent', columns: {#grandparentRatingKey})
class DownloadedMedia extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text()();
  // Downloads are intentionally app-wide/shared, keyed by the public
  // serverId:ratingKey globalKey below. For Jellyfin, clientScopeId records
  // which scoped client produced the cached metadata/download request; it is
  // not part of download ownership and must not be used to hide or duplicate
  // the physical downloaded item per user/profile.
  TextColumn get clientScopeId => text().nullable()();
  TextColumn get ratingKey => text()();
  TextColumn get globalKey => text().unique()();
  TextColumn get type => text()();
  TextColumn get parentRatingKey => text().nullable()();
  TextColumn get grandparentRatingKey => text().nullable()();
  IntColumn get status => integer()();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().nullable()();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();
  TextColumn get videoFilePath => text().nullable()();
  TextColumn get thumbPath => text().nullable()();
  IntColumn get downloadedAt => integer().nullable()();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get bgTaskId => text().nullable()();
  IntColumn get mediaIndex => integer().withDefault(const Constant(0))();
}

/// Profile ownership for shared physical downloads.
///
/// [DownloadedMedia] stores one physical row per public serverId:ratingKey so
/// files are deduped across profiles. This table controls which active profile
/// can see/use that shared row.
@DataClassName('DownloadOwnerItem')
@TableIndex(name: 'idx_download_owners_profile', columns: {#profileId})
@TableIndex(name: 'idx_download_owners_global_key', columns: {#globalKey})
class DownloadOwners extends Table {
  TextColumn get profileId => text()();
  TextColumn get globalKey => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {profileId, globalKey};
}

/// Persistent sync rules for auto-downloading unwatched episodes.
///
/// Each rule keeps a rolling window of N unwatched episodes for a show/season,
/// or mirrors the current contents of a collection/playlist.
/// Rules are owned by the active top-level profile. Downloads remain app-wide
/// and shared by public serverId:ratingKey identity, but rule ownership must not
/// cross users because Jellyfin permissions and watch state are user-scoped.
@DataClassName('SyncRuleItem')
@TableIndex(name: 'idx_sync_rules_profile', columns: {#profileId})
class SyncRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get profileId => text().withDefault(const Constant(''))();
  TextColumn get serverId => text()();
  TextColumn get ratingKey => text()();
  TextColumn get globalKey => text().unique()();
  TextColumn get targetType => text()(); // 'show', 'season', 'collection', 'playlist'
  IntColumn get episodeCount => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
  IntColumn get lastExecutedAt => integer().nullable()();
  IntColumn get mediaIndex => integer().withDefault(const Constant(0))();
  TextColumn get downloadFilter => text().withDefault(const Constant('unwatched'))();
}

/// Persisted media-server connections.
///
/// One row per "connection" the user has added — a Plex account (with its
/// discovered servers and active Home profile) or a single Jellyfin server.
/// The [configJson] payload is backend-specific and parsed by the
/// [Connection] sealed class.
@DataClassName('ConnectionRow')
@TableIndex(name: 'idx_connections_kind', columns: {#kind})
class Connections extends Table {
  /// Stable identifier for the connection. For Plex it's a generated UUID
  /// (one per account); for Jellyfin it's the server's machineId.
  TextColumn get id => text()();

  /// Backend kind: `'plex'` or `'jellyfin'`.
  TextColumn get kind => text()();

  /// User-visible label (account email, server name).
  TextColumn get displayName => text()();

  /// Backend-specific config payload (token, baseUrl, profile id, …).
  TextColumn get configJson => text()();

  /// Whether this is the default connection used at app launch when only
  /// one connection is present.
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// Timestamp this connection was added (milliseconds since epoch).
  IntColumn get createdAt => integer()();

  /// Timestamp of the most-recent successful auth refresh (milliseconds
  /// since epoch). Null until the first successful auth.
  IntColumn get lastAuthenticatedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Top-level profiles — see [Profile].
///
/// A profile is the user-facing identity. Plex Home users auto-surface as
/// `kind='plex_home'` rows when their parent Plex account is added; users
/// can also create `kind='local'` rows manually. Each profile owns one or
/// more connections via [ProfileConnections].
@DataClassName('ProfileRow')
@TableIndex(name: 'idx_profiles_kind', columns: {#kind})
class Profiles extends Table {
  /// Stable identifier. For Plex Home profiles: `plex-home-{accountId}-{homeUserUuid}`
  /// (deterministic so re-discovery is idempotent). For locals: `local-{uuid}`.
  TextColumn get id => text()();

  /// `'local'` | `'plex_home'`.
  TextColumn get kind => text()();

  TextColumn get displayName => text()();

  /// Plex Home users have a thumb URL; locals fall back to initials/colour.
  TextColumn get avatarThumbUrl => text().nullable()();

  /// Per-kind config:
  /// - `local`: `{ "pinHash": "..." }`
  /// - `plex_home`: `{ "restricted": bool, "admin": bool, "hasPassword": bool, "parentConnectionId": "..." }`
  TextColumn get configJson => text()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get lastUsedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Many-to-many join between [Profiles] and [Connections], carrying the
/// per-profile user-level token used when the profile is active.
///
/// For Plex: `userToken` is a Home-user token from `/home/users/{uuid}/switch`,
/// `userIdentifier` is the Plex Home user UUID. An empty `userToken` is a
/// lazy-fetch sentinel — the binder calls `/switch` on first activation.
/// The Dart-side [ProfileConnection] model surfaces empty as `null`; the
/// column stays non-nullable here to avoid a schema migration.
///
/// For Jellyfin: `userToken` mirrors the Connection's accessToken (one user
/// per Jellyfin connection) and `userIdentifier` is the Jellyfin user id.
@DataClassName('ProfileConnectionRow')
@TableIndex(name: 'idx_profile_connections_connection_id', columns: {#connectionId})
@TableIndex(name: 'idx_profile_connections_profile_id', columns: {#profileId})
class ProfileConnections extends Table {
  // No FK on profile_id: Plex Home profiles are virtual (built by
  // Profile.virtualPlexHome from PlexHomeService's live cache, never
  // persisted in `profiles`), so an FK here would reject every join row
  // they need. The two profile-delete sites clean up join rows manually
  // via ProfileConnectionRegistry.removeAllForProfile before calling
  // ProfileRegistry.remove.
  TextColumn get profileId => text()();
  TextColumn get connectionId => text().references(Connections, #id, onDelete: KeyAction.cascade)();
  TextColumn get userToken => text().withDefault(const Constant(''))();
  TextColumn get userIdentifier => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get tokenAcquiredAt => integer().nullable()();
  IntColumn get lastUsedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {profileId, connectionId};
}

/// Queue for offline watch progress and manual watch actions.
///
/// Stores watch progress updates and manual watch/unwatch actions
/// that need to be synced to the originating media server when back online.
@DataClassName('OfflineWatchProgressItem')
@TableIndex(name: 'idx_offline_watch_progress_server', columns: {#serverId})
@TableIndex(name: 'idx_offline_watch_progress_profile', columns: {#profileId})
class OfflineWatchProgress extends Table {
  /// Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();

  /// Active Plezy profile that owns this queued action.
  TextColumn get profileId => text().nullable()();

  /// Server ID this media belongs to
  TextColumn get serverId => text()();

  /// Optional user-scoped client/cache id for backends where [serverId] is
  /// shared by multiple users on the same server.
  TextColumn get clientScopeId => text().nullable()();

  /// Rating key of the media item
  TextColumn get ratingKey => text()();

  /// Global key (serverId:ratingKey) for easy lookup
  TextColumn get globalKey => text()();

  /// Type of action: 'progress', 'watched', 'unwatched'
  TextColumn get actionType => text()();

  /// Current playback position in milliseconds (for 'progress' actions)
  IntColumn get viewOffset => integer().nullable()();

  /// Duration of the media in milliseconds (for calculating percentage)
  IntColumn get duration => integer().nullable()();

  /// Whether this item should be marked as watched (for progress sync)
  /// Auto-set to true when viewOffset >= 90% of duration
  BoolColumn get shouldMarkWatched => boolean().withDefault(const Constant(false))();

  /// Timestamp when this action was recorded (milliseconds since epoch)
  IntColumn get createdAt => integer()();

  /// Timestamp when this action was last updated (for merging progress updates)
  IntColumn get updatedAt => integer()();

  /// Number of sync attempts (for retry logic)
  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();

  /// Last sync error message
  TextColumn get lastError => text().nullable()();
}
