package com.edde746.plezy.importer

// The rows of `plezy_downloads.db` at its last schema (25), one class per table, one property per column (the
// table's snake_case column names in camelCase). Timestamps are epoch milliseconds unless noted; tokens are as stored,
// `enc:v1:` or plaintext (EarlierReleaseCredentialVault decrypts them).

/** `downloaded_media`: one downloaded (or queued) item. [status] is the download state's ordinal. */
data class EarlierReleaseDownloadedMediaRow(
    val id: Long,
    val serverId: String,
    val clientScopeId: String?,
    val ratingKey: String,
    val globalKey: String,
    val type: String,
    val parentRatingKey: String?,
    val grandparentRatingKey: String?,
    val status: Long,
    val progress: Long,
    val totalBytes: Long?,
    val downloadedBytes: Long,
    /** Relative to the base directory, absolute for a custom folder, or a `content://` URI. */
    val videoFilePath: String?,
    /** JSON array of the later parts' paths, in playback order, `null` for a part not stored yet. */
    val additionalPartPaths: String?,
    val safRootUri: String?,
    /** The server-side artwork path or URL, not a local file. */
    val thumbPath: String?,
    val downloadedAt: Long?,
    val errorMessage: String?,
    val retryCount: Long,
    val bgTaskId: String?,
    val mediaIndex: Long,
    val mediaSourceId: String?,
    val libraryId: String?,
    val libraryTitle: String?,
)

/** `download_owners`: a profile's claim on a downloaded item. */
data class EarlierReleaseDownloadOwnerRow(
    val profileId: String,
    val globalKey: String,
    val backend: String?,
    val clientScopeId: String?,
    val createdAt: Long,
)

/** `download_queue`. */
data class EarlierReleaseDownloadQueueRow(
    val id: Long,
    val mediaGlobalKey: String,
    val priority: Long,
    val addedAt: Long,
    val downloadSubtitles: Boolean,
    val downloadArtwork: Boolean,
)

/** A pinned `api_cache` row: the cached metadata of a download. */
data class EarlierReleaseApiCacheRow(
    val cacheKey: String,
    val data: String,
    /** Epoch **seconds**. */
    val cachedAt: Long,
)

/** `offline_watch_progress`: a watch action waiting to be sent. */
data class EarlierReleaseOfflineWatchProgressRow(
    val id: Long,
    val profileId: String?,
    val serverId: String,
    val clientScopeId: String?,
    val ratingKey: String,
    val globalKey: String,
    val actionType: String,
    val viewOffset: Long?,
    val duration: Long?,
    val shouldMarkWatched: Boolean,
    val createdAt: Long,
    val updatedAt: Long,
    val syncAttempts: Long,
    val lastError: String?,
)

/** `sync_rules`. */
data class EarlierReleaseSyncRuleRow(
    val id: Long,
    val profileId: String,
    val serverId: String,
    val ratingKey: String,
    val globalKey: String,
    val targetType: String,
    val episodeCount: Long,
    val enabled: Boolean,
    val createdAt: Long,
    val lastExecutedAt: Long?,
    val mediaIndex: Long,
    val downloadFilter: String,
    val includeSpecials: Boolean,
    val downloadLinksInitialized: Boolean,
)

/** `sync_rule_downloads`. */
data class EarlierReleaseSyncRuleDownloadRow(val syncRuleId: Long, val profileId: String, val downloadGlobalKey: String)

/** `download_collections`; [memberIds] is a JSON array. */
data class EarlierReleaseDownloadCollectionRow(val profileId: String, val serverId: String, val collectionId: String, val memberIds: String)

/** `download_collection_syncs`; [checkedIds] is a JSON array. */
data class EarlierReleaseDownloadCollectionSyncRow(val profileId: String, val serverId: String, val syncedAt: Long, val checkedIds: String)

/** `connections`: a signed-in account; [configJson] holds its tokens. */
data class EarlierReleaseConnectionRow(
    val id: String,
    val kind: String,
    val displayName: String,
    val configJson: String,
    val createdAt: Long,
    val lastAuthenticatedAt: Long?,
)

/** `profiles`: [kind] `local` (`plex_home` rows are a retired kind). */
data class EarlierReleaseProfileRow(
    val id: String,
    val kind: String,
    val displayName: String,
    val avatarThumbUrl: String?,
    val configJson: String,
    val sortOrder: Long,
    val createdAt: Long,
    val lastUsedAt: Long?,
)

/** `profile_connections`: a profile's binding to a connection; an empty [userToken] is fetched when needed. */
data class EarlierReleaseProfileConnectionRow(
    val profileId: String,
    val connectionId: String,
    val userToken: String,
    val userIdentifier: String,
    val isDefault: Boolean,
    val tokenAcquiredAt: Long?,
    val lastUsedAt: Long?,
)

/** `music_sessions`: a profile's last music queue. */
data class EarlierReleaseMusicSessionRow(
    val profileId: String,
    val queueJson: String,
    val orderJson: String,
    val cursor: Long,
    val shuffled: Boolean,
    val repeatMode: String,
    val contextTitle: String?,
    val contextKind: String?,
    val positionMs: Long,
    val updatedAt: Long,
)

/** The rows of a `plezy_downloads.db` this app keeps, brought to schema 25: every table's, of `api_cache` the pinned ones. */
data class EarlierReleaseDatabaseSnapshot(
    /** The schema version the file had before the upgrade steps. */
    val schemaVersion: Int,
    val downloadedMedia: List<EarlierReleaseDownloadedMediaRow>,
    val downloadOwners: List<EarlierReleaseDownloadOwnerRow>,
    val downloadQueue: List<EarlierReleaseDownloadQueueRow>,
    /** Only the pinned rows: the others are a cache, and one can be larger than Android's cursor window reads. */
    val pinnedApiCache: List<EarlierReleaseApiCacheRow>,
    val offlineWatchProgress: List<EarlierReleaseOfflineWatchProgressRow>,
    val syncRules: List<EarlierReleaseSyncRuleRow>,
    val syncRuleDownloads: List<EarlierReleaseSyncRuleDownloadRow>,
    val downloadCollections: List<EarlierReleaseDownloadCollectionRow>,
    val downloadCollectionSyncs: List<EarlierReleaseDownloadCollectionSyncRow>,
    val connections: List<EarlierReleaseConnectionRow>,
    val profiles: List<EarlierReleaseProfileRow>,
    val profileConnections: List<EarlierReleaseProfileConnectionRow>,
    val musicSessions: List<EarlierReleaseMusicSessionRow>,
)
