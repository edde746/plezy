package com.edde746.plezy.importer

import com.edde746.plezy.plex.withoutProfileState
import kotlinx.serialization.json.JsonObject

// The earlier releases' schema 25 exactly as their ORM created it, and their upgrade steps from older files. Each
// step creates a table or index, or adds a column, only where it is missing (an interrupted upgrade may have done it
// already) and always with the schema-25 definition, as the ORM did; the data transforms of steps 14, 17 and 19 are
// their statements unchanged, apart from the two noted at step 17.

private val TABLES = linkedMapOf(
    "downloaded_media" to "\"id\" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \"server_id\" TEXT NOT NULL, \"client_scope_id\" TEXT NULL, \"rating_key\" TEXT NOT NULL, \"global_key\" TEXT NOT NULL UNIQUE, \"type\" TEXT NOT NULL, \"parent_rating_key\" TEXT NULL, \"grandparent_rating_key\" TEXT NULL, \"status\" INTEGER NOT NULL, \"progress\" INTEGER NOT NULL DEFAULT 0, \"total_bytes\" INTEGER NULL, \"downloaded_bytes\" INTEGER NOT NULL DEFAULT 0, \"video_file_path\" TEXT NULL, \"additional_part_paths\" TEXT NULL, \"saf_root_uri\" TEXT NULL, \"thumb_path\" TEXT NULL, \"downloaded_at\" INTEGER NULL, \"error_message\" TEXT NULL, \"retry_count\" INTEGER NOT NULL DEFAULT 0, \"bg_task_id\" TEXT NULL, \"media_index\" INTEGER NOT NULL DEFAULT 0, \"media_source_id\" TEXT NULL, \"library_id\" TEXT NULL, \"library_title\" TEXT NULL",
    "download_owners" to "\"profile_id\" TEXT NOT NULL, \"global_key\" TEXT NOT NULL, \"backend\" TEXT NULL, \"client_scope_id\" TEXT NULL, \"created_at\" INTEGER NOT NULL, PRIMARY KEY (\"profile_id\", \"global_key\")",
    "download_queue" to "\"id\" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \"media_global_key\" TEXT NOT NULL UNIQUE, \"priority\" INTEGER NOT NULL DEFAULT 0, \"added_at\" INTEGER NOT NULL, \"download_subtitles\" INTEGER NOT NULL DEFAULT 1 CHECK (\"download_subtitles\" IN (0, 1)), \"download_artwork\" INTEGER NOT NULL DEFAULT 1 CHECK (\"download_artwork\" IN (0, 1))",
    "api_cache" to "\"cache_key\" TEXT NOT NULL, \"data\" TEXT NOT NULL, \"cached_at\" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), \"pinned\" INTEGER NOT NULL DEFAULT 0 CHECK (\"pinned\" IN (0, 1)), PRIMARY KEY (\"cache_key\")",
    "offline_watch_progress" to "\"id\" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \"profile_id\" TEXT NULL, \"server_id\" TEXT NOT NULL, \"client_scope_id\" TEXT NULL, \"rating_key\" TEXT NOT NULL, \"global_key\" TEXT NOT NULL, \"action_type\" TEXT NOT NULL, \"view_offset\" INTEGER NULL, \"duration\" INTEGER NULL, \"should_mark_watched\" INTEGER NOT NULL DEFAULT 0 CHECK (\"should_mark_watched\" IN (0, 1)), \"created_at\" INTEGER NOT NULL, \"updated_at\" INTEGER NOT NULL, \"sync_attempts\" INTEGER NOT NULL DEFAULT 0, \"last_error\" TEXT NULL",
    "sync_rules" to "\"id\" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, \"profile_id\" TEXT NOT NULL DEFAULT '', \"server_id\" TEXT NOT NULL, \"rating_key\" TEXT NOT NULL, \"global_key\" TEXT NOT NULL UNIQUE, \"target_type\" TEXT NOT NULL, \"episode_count\" INTEGER NOT NULL, \"enabled\" INTEGER NOT NULL DEFAULT 1 CHECK (\"enabled\" IN (0, 1)), \"created_at\" INTEGER NOT NULL, \"last_executed_at\" INTEGER NULL, \"media_index\" INTEGER NOT NULL DEFAULT 0, \"download_filter\" TEXT NOT NULL DEFAULT 'unwatched', \"include_specials\" INTEGER NOT NULL DEFAULT 1 CHECK (\"include_specials\" IN (0, 1)), \"download_links_initialized\" INTEGER NOT NULL DEFAULT 0 CHECK (\"download_links_initialized\" IN (0, 1))",
    "sync_rule_downloads" to "\"sync_rule_id\" INTEGER NOT NULL REFERENCES sync_rules (id) ON DELETE CASCADE, \"profile_id\" TEXT NOT NULL, \"download_global_key\" TEXT NOT NULL, PRIMARY KEY (\"sync_rule_id\", \"download_global_key\")",
    "download_collections" to "\"profile_id\" TEXT NOT NULL, \"server_id\" TEXT NOT NULL, \"collection_id\" TEXT NOT NULL, \"member_ids\" TEXT NOT NULL, PRIMARY KEY (\"profile_id\", \"server_id\", \"collection_id\")",
    "download_collection_syncs" to "\"profile_id\" TEXT NOT NULL, \"server_id\" TEXT NOT NULL, \"synced_at\" INTEGER NOT NULL, \"checked_ids\" TEXT NOT NULL, PRIMARY KEY (\"profile_id\", \"server_id\")",
    "connections" to "\"id\" TEXT NOT NULL, \"kind\" TEXT NOT NULL, \"display_name\" TEXT NOT NULL, \"config_json\" TEXT NOT NULL, \"created_at\" INTEGER NOT NULL, \"last_authenticated_at\" INTEGER NULL, PRIMARY KEY (\"id\")",
    "profiles" to "\"id\" TEXT NOT NULL, \"kind\" TEXT NOT NULL, \"display_name\" TEXT NOT NULL, \"avatar_thumb_url\" TEXT NULL, \"config_json\" TEXT NOT NULL, \"sort_order\" INTEGER NOT NULL DEFAULT 0, \"created_at\" INTEGER NOT NULL, \"last_used_at\" INTEGER NULL, PRIMARY KEY (\"id\")",
    "profile_connections" to "\"profile_id\" TEXT NOT NULL, \"connection_id\" TEXT NOT NULL REFERENCES connections (id) ON DELETE CASCADE, \"user_token\" TEXT NOT NULL DEFAULT '', \"user_identifier\" TEXT NOT NULL, \"is_default\" INTEGER NOT NULL DEFAULT 0 CHECK (\"is_default\" IN (0, 1)), \"token_acquired_at\" INTEGER NULL, \"last_used_at\" INTEGER NULL, PRIMARY KEY (\"profile_id\", \"connection_id\")",
    "music_sessions" to "\"profile_id\" TEXT NOT NULL, \"queue_json\" TEXT NOT NULL, \"order_json\" TEXT NOT NULL, \"cursor\" INTEGER NOT NULL, \"shuffled\" INTEGER NOT NULL DEFAULT 0 CHECK (\"shuffled\" IN (0, 1)), \"repeat_mode\" TEXT NOT NULL DEFAULT 'off', \"context_title\" TEXT NULL, \"context_kind\" TEXT NULL, \"position_ms\" INTEGER NOT NULL DEFAULT 0, \"updated_at\" INTEGER NOT NULL, PRIMARY KEY (\"profile_id\")",
)

private val INDEXES = linkedMapOf(
    "idx_downloaded_media_status" to "downloaded_media (status)",
    "idx_downloaded_media_server" to "downloaded_media (server_id)",
    "idx_downloaded_media_parent" to "downloaded_media (parent_rating_key)",
    "idx_downloaded_media_grandparent" to "downloaded_media (grandparent_rating_key)",
    "idx_download_owners_profile" to "download_owners (profile_id)",
    "idx_download_owners_global_key" to "download_owners (global_key)",
    "idx_offline_watch_progress_server" to "offline_watch_progress (server_id)",
    "idx_offline_watch_progress_profile" to "offline_watch_progress (profile_id)",
    "idx_sync_rules_profile" to "sync_rules (profile_id)",
    "idx_sync_rule_downloads_profile_key" to "sync_rule_downloads (profile_id, download_global_key)",
    "idx_connections_kind" to "connections (kind)",
    "idx_profiles_kind" to "profiles (kind)",
    "idx_profile_connections_connection_id" to "profile_connections (connection_id)",
    "idx_profile_connections_profile_id" to "profile_connections (profile_id)",
)

/** Every schema-25 table and index, as a fresh install of the earlier releases created them. */
internal fun createEarlierReleaseSchema(db: EarlierReleaseSqlite) {
    TABLES.keys.forEach { createTable(db, it) }
    INDEXES.keys.forEach { createIndex(db, it) }
    db.execute("PRAGMA user_version = $EARLIER_RELEASE_SCHEMA_VERSION")
}

/** The earlier releases' upgrade steps from schema [from] to 25. */
internal fun upgradeEarlierReleaseDatabase(db: EarlierReleaseSqlite, from: Int) {
    db.execute("PRAGMA foreign_keys = OFF")
    if (from < 7) createTable(db, "offline_watch_progress")
    if (from < 8) addColumn(db, "downloaded_media", "bg_task_id")
    if (from < 9) addColumn(db, "downloaded_media", "media_index")
    if (from < 10) createTable(db, "sync_rules")
    if (from < 11) addColumn(db, "sync_rules", "enabled")
    if (from < 12) addColumn(db, "sync_rules", "download_filter")
    if (from < 13) {
        listOf("status", "server", "parent", "grandparent").forEach { createIndex(db, "idx_downloaded_media_$it") }
    }
    if (from < 14) upgradeTo14(db)
    if (from < 15) addColumn(db, "downloaded_media", "media_source_id")
    if (from < 16) addColumn(db, "sync_rules", "include_specials")
    if (from < 17) upgradeTo17(db)
    if (from < 18) addColumn(db, "downloaded_media", "saf_root_uri")
    if (from < 19) upgradeTo19(db)
    if (from < 20) {
        addColumn(db, "sync_rules", "download_links_initialized")
        createTable(db, "sync_rule_downloads")
        createIndex(db, "idx_sync_rule_downloads_profile_key")
    }
    if (from < 21) rebuildConnections(db)
    if (from < 22) createTable(db, "music_sessions")
    if (from < 23) {
        addColumn(db, "downloaded_media", "library_id")
        addColumn(db, "downloaded_media", "library_title")
    }
    if (from < 24) addColumn(db, "downloaded_media", "additional_part_paths")
    if (from < 25) {
        createTable(db, "download_collections")
        createTable(db, "download_collection_syncs")
    }
    db.execute("PRAGMA user_version = $EARLIER_RELEASE_SCHEMA_VERSION")
}

private fun createTable(db: EarlierReleaseSqlite, table: String) {
    db.execute("CREATE TABLE IF NOT EXISTS \"$table\" (${TABLES.getValue(table)});")
}

private fun createIndex(db: EarlierReleaseSqlite, index: String) {
    db.execute("CREATE INDEX IF NOT EXISTS $index ON ${INDEXES.getValue(index)};")
}

/** Adds [column] to [table] with its schema-25 definition, unless the table has it. */
private fun addColumn(db: EarlierReleaseSqlite, table: String, column: String) {
    if (db.query("PRAGMA table_info(\"$table\")").any { it["name"] == column }) return
    val start = TABLES.getValue(table).indexOf("\"$column\" ")
    check(start >= 0) { "$table has no column $column" }
    // The definition runs to the next comma outside parentheses (a CHECK or DEFAULT holds commas of its own).
    val body = TABLES.getValue(table)
    var depth = 0
    var end = start
    while (end < body.length && !(body[end] == ',' && depth == 0)) {
        if (body[end] == '(') depth++ else if (body[end] == ')') depth--
        end++
    }
    db.execute("ALTER TABLE \"$table\" ADD COLUMN ${body.substring(start, end)};")
}

/** Accounts, profiles and download owners arrive; existing Jellyfin rows learn their client scope. */
private fun upgradeTo14(db: EarlierReleaseSqlite) {
    createTable(db, "connections")
    createIndex(db, "idx_connections_kind")
    createTable(db, "profiles")
    createIndex(db, "idx_profiles_kind")
    createTable(db, "profile_connections")
    createIndex(db, "idx_profile_connections_connection_id")
    createIndex(db, "idx_profile_connections_profile_id")
    createTable(db, "download_owners")
    createIndex(db, "idx_download_owners_profile")
    createIndex(db, "idx_download_owners_global_key")
    addColumn(db, "downloaded_media", "client_scope_id")
    addColumn(db, "offline_watch_progress", "client_scope_id")
    addColumn(db, "sync_rules", "profile_id")
    addColumn(db, "offline_watch_progress", "profile_id")
    for (table in listOf("downloaded_media", "offline_watch_progress")) {
        db.execute(
            """
            UPDATE $table
            SET client_scope_id = (
              SELECT id FROM connections
              WHERE kind = 'jellyfin'
                AND substr(id, 1, length($table.server_id) + 1) = $table.server_id || '/'
              LIMIT 1
            )
            WHERE client_scope_id IS NULL
              AND EXISTS (
                SELECT 1 FROM connections
                WHERE kind = 'jellyfin'
                  AND substr(id, 1, length($table.server_id) + 1) = $table.server_id || '/'
              )
            """.trimIndent(),
        )
    }
    createIndex(db, "idx_offline_watch_progress_server")
    createIndex(db, "idx_sync_rules_profile")
    createIndex(db, "idx_offline_watch_progress_profile")
}

/**
 * Pinned Plex metadata moves from bare cache keys to profile-scoped ones: copied under each owner's
 * `<server>/~plex-profile/<profile>:` namespace, or, for a download no profile owns, under `<server>/~plex-transfer:`
 * with the profile-private watch fields removed. Then the bare item and children rows go.
 *
 * The earlier releases ran their bundled SQLite; these statements must also run on Android's older system SQLite, so
 * the copy is `INSERT OR REPLACE` rather than an upsert (the same result, since the upsert replaced every column) and
 * the common table expressions are inlined as subqueries.
 */
private fun upgradeTo17(db: EarlierReleaseSqlite) {
    db.execute(
        rescopePinnedPlexMetadata(
            namespace = "'/~plex-profile/' || owner.profile_id || ':'",
            ownerJoin = "JOIN download_owners AS owner ON owner.global_key = metadata.global_key",
        ),
    )
    db.execute(
        rescopePinnedPlexMetadata(
            namespace = "'/~plex-transfer:'",
            ownerFilter = "AND NOT EXISTS (SELECT 1 FROM download_owners AS owner WHERE owner.global_key = metadata.global_key)",
        ),
    )
    val transferRows = db.query(
        """
        SELECT cache_key, data
        FROM api_cache
        WHERE instr(substr(cache_key, 1, instr(cache_key, ':') - 1), '/~plex-transfer') > 0
          AND instr(cache_key, ':/library/metadata/') > 0
        """.trimIndent(),
    )
    for (row in transferRows) {
        val cacheKey = row.getValue("cache_key") as String
        val sanitized = sanitizeOwnerlessPlexMetadata(row.getValue("data") as String)
        if (sanitized != null) {
            db.execute("UPDATE api_cache SET data = ? WHERE cache_key = ?", listOf(sanitized, cacheKey))
        } else {
            db.execute("DELETE FROM api_cache WHERE cache_key = ?", listOf(cacheKey))
        }
    }
    db.execute(
        """
        UPDATE downloaded_media
        SET client_scope_id = server_id || '/~plex-transfer'
        WHERE NOT EXISTS (
            SELECT 1
            FROM download_owners AS owner
            WHERE owner.global_key = downloaded_media.global_key
          )
          AND EXISTS (
            SELECT 1
            FROM api_cache AS transfer
            WHERE transfer.cache_key =
                downloaded_media.server_id
                  || '/~plex-transfer:/library/metadata/'
                  || downloaded_media.rating_key
              AND transfer.pinned = 1
          )
        """.trimIndent(),
    )
    db.execute(
        """
        DELETE FROM api_cache
        WHERE cache_key IN (
          SELECT cache_key
          FROM (
            SELECT
              cache_key,
              substr(cache_key, instr(cache_key, ':') + 1) AS endpoint
            FROM api_cache
            WHERE instr(cache_key, ':/library/metadata/') > 0
              AND instr(substr(cache_key, 1, instr(cache_key, ':') - 1), '/~plex-profile/') = 0
              AND instr(substr(cache_key, 1, instr(cache_key, ':') - 1), '/~plex-transfer') = 0
          )
          WHERE (
            endpoint GLOB '/library/metadata/?*'
            AND endpoint NOT GLOB '/library/metadata/*/*'
          ) OR (
            endpoint GLOB '/library/metadata/?*/children'
            AND endpoint NOT GLOB '/library/metadata/*/*/*'
          )
        )
        """.trimIndent(),
    )
}

private fun rescopePinnedPlexMetadata(namespace: String, ownerJoin: String = "", ownerFilter: String = ""): String =
    """
    INSERT OR REPLACE INTO api_cache (cache_key, data, pinned, cached_at)
    SELECT DISTINCT
      metadata.server_id
        || $namespace
        || substr(source.cache_key, length(metadata.server_id) + 2),
      source.data,
      source.pinned,
      source.cached_at
    FROM (
      SELECT global_key, server_id, rating_key AS metadata_id
      FROM downloaded_media
      UNION
      SELECT global_key, server_id, parent_rating_key AS metadata_id
      FROM downloaded_media
      WHERE parent_rating_key IS NOT NULL
        AND parent_rating_key != ''
      UNION
      SELECT global_key, server_id, grandparent_rating_key AS metadata_id
      FROM downloaded_media
      WHERE grandparent_rating_key IS NOT NULL
        AND grandparent_rating_key != ''
    ) AS metadata
    $ownerJoin
    JOIN api_cache AS source
      ON source.cache_key =
          metadata.server_id || ':/library/metadata/' || metadata.metadata_id
        OR source.cache_key =
          metadata.server_id || ':/library/metadata/' || metadata.metadata_id || '/children'
    WHERE source.pinned = 1
      $ownerFilter
    """.trimIndent()

/**
 * A cached Plex response [data] without the profile-private watch fields ([withoutProfileState]), for a download no
 * profile owns yet; null if [data] isn't a JSON object (such a row was discarded).
 */
internal fun sanitizeOwnerlessPlexMetadata(data: String): String? {
    val document = runCatching { parseStrictJson(data) }.getOrNull() as? JsonObject ?: return null
    return withoutProfileState(document).toString()
}

/** Download owners get the client scope and backend of their profile's copy of the item. */
private fun upgradeTo19(db: EarlierReleaseSqlite) {
    addColumn(db, "download_owners", "backend")
    addColumn(db, "download_owners", "client_scope_id")
    db.execute(
        """
        UPDATE download_owners
        SET client_scope_id = CASE
          WHEN EXISTS (
            SELECT 1
            FROM downloaded_media
            WHERE downloaded_media.global_key = download_owners.global_key
              AND downloaded_media.client_scope_id LIKE '%/~plex-profile/%'
          ) THEN (
            SELECT downloaded_media.server_id || '/~plex-profile/' || download_owners.profile_id
            FROM downloaded_media
            WHERE downloaded_media.global_key = download_owners.global_key
          )
          WHEN EXISTS (
            SELECT 1
            FROM downloaded_media
            JOIN profile_connections
              ON profile_connections.profile_id = download_owners.profile_id
            JOIN connections
              ON connections.id = profile_connections.connection_id
            WHERE downloaded_media.global_key = download_owners.global_key
              AND connections.kind = 'jellyfin'
              AND profile_connections.user_identifier != ''
              AND (
                connections.id = downloaded_media.server_id
                OR substr(connections.id, 1, length(downloaded_media.server_id) + 1)
                  = downloaded_media.server_id || '/'
              )
          ) THEN (
            SELECT CASE
              WHEN connections.id = downloaded_media.server_id
                THEN downloaded_media.server_id || '/' || profile_connections.user_identifier
              ELSE connections.id
            END
            FROM downloaded_media
            JOIN profile_connections
              ON profile_connections.profile_id = download_owners.profile_id
            JOIN connections
              ON connections.id = profile_connections.connection_id
            WHERE downloaded_media.global_key = download_owners.global_key
              AND connections.kind = 'jellyfin'
              AND profile_connections.user_identifier != ''
              AND (
                connections.id = downloaded_media.server_id
                OR substr(connections.id, 1, length(downloaded_media.server_id) + 1)
                  = downloaded_media.server_id || '/'
              )
            ORDER BY profile_connections.is_default DESC,
              profile_connections.last_used_at DESC,
              connections.id
            LIMIT 1
          )
          ELSE NULL
        END
        WHERE client_scope_id IS NULL
        """.trimIndent(),
    )
    db.execute(
        """
        UPDATE download_owners
        SET backend = CASE
          WHEN client_scope_id LIKE '%/~plex-profile/%' THEN 'plex'
          WHEN client_scope_id IS NOT NULL AND EXISTS (
            SELECT 1
            FROM downloaded_media
            JOIN profile_connections
              ON profile_connections.profile_id = download_owners.profile_id
            JOIN connections
              ON connections.id = profile_connections.connection_id
            WHERE downloaded_media.global_key = download_owners.global_key
              AND connections.kind = 'jellyfin'
              AND (
                connections.id = downloaded_media.server_id
                OR substr(connections.id, 1, length(downloaded_media.server_id) + 1)
                  = downloaded_media.server_id || '/'
              )
          ) THEN 'jellyfin'
        END
        WHERE backend IS NULL
        """.trimIndent(),
    )
}

/** Step 21 dropped `connections.is_default` by rebuilding the table with its current columns. */
private fun rebuildConnections(db: EarlierReleaseSqlite) {
    val columns = "\"id\", \"kind\", \"display_name\", \"config_json\", \"created_at\", \"last_authenticated_at\""
    db.execute("CREATE TABLE \"tmp_for_copy_connections\" (${TABLES.getValue("connections")});")
    db.execute("INSERT INTO \"tmp_for_copy_connections\" ($columns) SELECT $columns FROM \"connections\";")
    db.execute("DROP TABLE \"connections\";")
    db.execute("ALTER TABLE \"tmp_for_copy_connections\" RENAME TO \"connections\";")
    createIndex(db, "idx_connections_kind")
}
