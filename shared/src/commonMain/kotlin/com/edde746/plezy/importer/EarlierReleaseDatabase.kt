package com.edde746.plezy.importer

import kotlinx.io.buffered
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem

/** File name of the earlier releases' database. */
const val EARLIER_RELEASE_DATABASE_FILE_NAME = "plezy_downloads.db"

/** The last schema version Plezy's earlier releases wrote. */
const val EARLIER_RELEASE_SCHEMA_VERSION = 25

/** The oldest schema version those releases could still upgrade. */
const val EARLIER_RELEASE_OLDEST_SCHEMA_VERSION = 6

/** `plezy_downloads.db` has a schema version this reader can't bring to [EARLIER_RELEASE_SCHEMA_VERSION]. */
class EarlierReleaseDatabaseVersionException(val version: Int) : IllegalStateException(
    if (version > EARLIER_RELEASE_SCHEMA_VERSION) {
        "$EARLIER_RELEASE_DATABASE_FILE_NAME has schema $version, newer than $EARLIER_RELEASE_SCHEMA_VERSION"
    } else {
        "$EARLIER_RELEASE_DATABASE_FILE_NAME has schema $version, older than $EARLIER_RELEASE_OLDEST_SCHEMA_VERSION"
    },
)

/**
 * Reads the rows of the earlier releases' `plezy_downloads.db` at [path] that this app keeps
 * ([EarlierReleaseDatabaseSnapshot]). Blocking: call it off the main thread.
 *
 * The file is copied with its `-wal` and `-shm` sidecars into a new directory only this user can open, and read there, so
 * rows still in the write-ahead log are included and the original stays exactly as it was (a reinstalled earlier release
 * keeps working). A file at an older schema (from [EARLIER_RELEASE_OLDEST_SCHEMA_VERSION]) gets the earlier releases' upgrade
 * steps on the copy first; a newer one than [EARLIER_RELEASE_SCHEMA_VERSION] throws [EarlierReleaseDatabaseVersionException].
 */
fun readEarlierReleaseDatabase(path: String): EarlierReleaseDatabaseSnapshot {
    require(SystemFileSystem.exists(Path(path))) { "No database at $path" }
    val directory = Path(createPrivateDirectory())
    try {
        val copy = Path(directory, EARLIER_RELEASE_DATABASE_FILE_NAME)
        for (suffix in listOf("", "-wal", "-shm")) {
            val source = Path(path + suffix)
            if (!SystemFileSystem.exists(source)) continue
            SystemFileSystem.source(source).buffered().use { input ->
                SystemFileSystem.sink(Path("$copy$suffix")).buffered().use { input.transferTo(it) }
            }
        }
        return openEarlierReleaseSqlite(copy.toString()).use { db ->
            val version = (db.query("PRAGMA user_version").single().values.single() as Long).toInt()
            when {
                version > EARLIER_RELEASE_SCHEMA_VERSION -> throw EarlierReleaseDatabaseVersionException(version)
                // A file the earlier releases never set up: they created the schema over it, so it holds nothing.
                version == 0 && db.query("SELECT name FROM sqlite_master").isEmpty() -> createEarlierReleaseSchema(db)
                version < EARLIER_RELEASE_OLDEST_SCHEMA_VERSION -> throw EarlierReleaseDatabaseVersionException(version)
                version < EARLIER_RELEASE_SCHEMA_VERSION -> upgradeEarlierReleaseDatabase(db, version)
            }
            readSnapshot(db, version)
        }
    } finally {
        SystemFileSystem.list(directory).forEach { SystemFileSystem.delete(it) }
        SystemFileSystem.delete(directory)
    }
}

private fun readSnapshot(db: EarlierReleaseSqlite, version: Int): EarlierReleaseDatabaseSnapshot {
    fun rows(table: String, orderBy: String) = db.query("SELECT * FROM \"$table\" ORDER BY $orderBy").map(::SqlRow)
    return EarlierReleaseDatabaseSnapshot(
        schemaVersion = version,
        downloadedMedia = rows("downloaded_media", "id").map {
            EarlierReleaseDownloadedMediaRow(
                id = it.long("id"),
                serverId = it.string("server_id"),
                clientScopeId = it.stringOrNull("client_scope_id"),
                ratingKey = it.string("rating_key"),
                globalKey = it.string("global_key"),
                type = it.string("type"),
                parentRatingKey = it.stringOrNull("parent_rating_key"),
                grandparentRatingKey = it.stringOrNull("grandparent_rating_key"),
                status = it.long("status"),
                progress = it.long("progress"),
                totalBytes = it.longOrNull("total_bytes"),
                downloadedBytes = it.long("downloaded_bytes"),
                videoFilePath = it.stringOrNull("video_file_path"),
                additionalPartPaths = it.stringOrNull("additional_part_paths"),
                safRootUri = it.stringOrNull("saf_root_uri"),
                thumbPath = it.stringOrNull("thumb_path"),
                downloadedAt = it.longOrNull("downloaded_at"),
                errorMessage = it.stringOrNull("error_message"),
                retryCount = it.long("retry_count"),
                bgTaskId = it.stringOrNull("bg_task_id"),
                mediaIndex = it.long("media_index"),
                mediaSourceId = it.stringOrNull("media_source_id"),
                libraryId = it.stringOrNull("library_id"),
                libraryTitle = it.stringOrNull("library_title"),
            )
        },
        downloadOwners = rows("download_owners", "profile_id, global_key").map {
            EarlierReleaseDownloadOwnerRow(
                profileId = it.string("profile_id"),
                globalKey = it.string("global_key"),
                backend = it.stringOrNull("backend"),
                clientScopeId = it.stringOrNull("client_scope_id"),
                createdAt = it.long("created_at"),
            )
        },
        downloadQueue = rows("download_queue", "id").map {
            EarlierReleaseDownloadQueueRow(
                id = it.long("id"),
                mediaGlobalKey = it.string("media_global_key"),
                priority = it.long("priority"),
                addedAt = it.long("added_at"),
                downloadSubtitles = it.bool("download_subtitles"),
                downloadArtwork = it.bool("download_artwork"),
            )
        },
        pinnedApiCache = db.query("SELECT * FROM \"api_cache\" WHERE pinned != 0 ORDER BY cache_key").map(::SqlRow).map {
            EarlierReleaseApiCacheRow(cacheKey = it.string("cache_key"), data = it.string("data"), cachedAt = it.long("cached_at"))
        },
        offlineWatchProgress = rows("offline_watch_progress", "id").map {
            EarlierReleaseOfflineWatchProgressRow(
                id = it.long("id"),
                profileId = it.stringOrNull("profile_id"),
                serverId = it.string("server_id"),
                clientScopeId = it.stringOrNull("client_scope_id"),
                ratingKey = it.string("rating_key"),
                globalKey = it.string("global_key"),
                actionType = it.string("action_type"),
                viewOffset = it.longOrNull("view_offset"),
                duration = it.longOrNull("duration"),
                shouldMarkWatched = it.bool("should_mark_watched"),
                createdAt = it.long("created_at"),
                updatedAt = it.long("updated_at"),
                syncAttempts = it.long("sync_attempts"),
                lastError = it.stringOrNull("last_error"),
            )
        },
        syncRules = rows("sync_rules", "id").map {
            EarlierReleaseSyncRuleRow(
                id = it.long("id"),
                profileId = it.string("profile_id"),
                serverId = it.string("server_id"),
                ratingKey = it.string("rating_key"),
                globalKey = it.string("global_key"),
                targetType = it.string("target_type"),
                episodeCount = it.long("episode_count"),
                enabled = it.bool("enabled"),
                createdAt = it.long("created_at"),
                lastExecutedAt = it.longOrNull("last_executed_at"),
                mediaIndex = it.long("media_index"),
                downloadFilter = it.string("download_filter"),
                includeSpecials = it.bool("include_specials"),
                downloadLinksInitialized = it.bool("download_links_initialized"),
            )
        },
        syncRuleDownloads = rows("sync_rule_downloads", "sync_rule_id, download_global_key").map {
            EarlierReleaseSyncRuleDownloadRow(
                syncRuleId = it.long("sync_rule_id"),
                profileId = it.string("profile_id"),
                downloadGlobalKey = it.string("download_global_key"),
            )
        },
        downloadCollections = rows("download_collections", "profile_id, server_id, collection_id").map {
            EarlierReleaseDownloadCollectionRow(
                profileId = it.string("profile_id"),
                serverId = it.string("server_id"),
                collectionId = it.string("collection_id"),
                memberIds = it.string("member_ids"),
            )
        },
        downloadCollectionSyncs = rows("download_collection_syncs", "profile_id, server_id").map {
            EarlierReleaseDownloadCollectionSyncRow(
                profileId = it.string("profile_id"),
                serverId = it.string("server_id"),
                syncedAt = it.long("synced_at"),
                checkedIds = it.string("checked_ids"),
            )
        },
        connections = rows("connections", "id").map {
            EarlierReleaseConnectionRow(
                id = it.string("id"),
                kind = it.string("kind"),
                displayName = it.string("display_name"),
                configJson = it.string("config_json"),
                createdAt = it.long("created_at"),
                lastAuthenticatedAt = it.longOrNull("last_authenticated_at"),
            )
        },
        profiles = rows("profiles", "id").map {
            EarlierReleaseProfileRow(
                id = it.string("id"),
                kind = it.string("kind"),
                displayName = it.string("display_name"),
                avatarThumbUrl = it.stringOrNull("avatar_thumb_url"),
                configJson = it.string("config_json"),
                sortOrder = it.long("sort_order"),
                createdAt = it.long("created_at"),
                lastUsedAt = it.longOrNull("last_used_at"),
            )
        },
        profileConnections = rows("profile_connections", "profile_id, connection_id").map {
            EarlierReleaseProfileConnectionRow(
                profileId = it.string("profile_id"),
                connectionId = it.string("connection_id"),
                userToken = it.string("user_token"),
                userIdentifier = it.string("user_identifier"),
                isDefault = it.bool("is_default"),
                tokenAcquiredAt = it.longOrNull("token_acquired_at"),
                lastUsedAt = it.longOrNull("last_used_at"),
            )
        },
        musicSessions = rows("music_sessions", "profile_id").map {
            EarlierReleaseMusicSessionRow(
                profileId = it.string("profile_id"),
                queueJson = it.string("queue_json"),
                orderJson = it.string("order_json"),
                cursor = it.long("cursor"),
                shuffled = it.bool("shuffled"),
                repeatMode = it.string("repeat_mode"),
                contextTitle = it.stringOrNull("context_title"),
                contextKind = it.stringOrNull("context_kind"),
                positionMs = it.long("position_ms"),
                updatedAt = it.long("updated_at"),
            )
        },
    )
}

/** One result row; a missing column or a value of another type fails loudly. */
private class SqlRow(private val values: Map<String, Any?>) {
    fun string(column: String): String = values.getValue(column) as String
    fun stringOrNull(column: String): String? = values.getValue(column) as String?
    fun long(column: String): Long = values.getValue(column) as Long
    fun longOrNull(column: String): Long? = values.getValue(column) as Long?
    fun bool(column: String): Boolean = long(column) != 0L
}
