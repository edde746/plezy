package com.edde746.plezy.settings

import com.edde746.plezy.data.Db
import com.edde746.plezy.data.Tx
import com.edde746.plezy.data.db.Profile_setting
import com.edde746.plezy.data.settings.decodeStored
import com.edde746.plezy.data.settings.settingsJson
import com.edde746.plezy.profiles.profileUserScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.nullable
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject

/**
 * A setting each profile keeps for itself under [baseKey], [default] while unset; [normalize] runs on every value
 * stored and read back. Stored per profile scope ([profileUserScope]): a Plex Home profile's is its home user's uuid,
 * so the same home user on two accounts shares one.
 */
class ProfileSetting<T>(
    val baseKey: String,
    val default: T,
    internal val serializer: KSerializer<T>,
    normalize: (T) -> T = { it },
) {
    private val normalizeValue = normalize

    fun normalize(value: T): T = normalizeValue(value)

    internal fun decode(json: String?): T {
        val decoded = json?.let { decodeStored(baseKey, it, serializer) } ?: return default
        return normalize(decoded.value)
    }

    override fun toString(): String = "ProfileSetting($baseKey)"
}

/**
 * The profile settings Plezy keeps beside the library choices ([LibraryPrefs] reads and writes those). Tracker and
 * Seerr sessions are credentials and live in the secret store, never here.
 */
object ProfileSettings {
    /** The library last opened (`{serverId}:{libraryId}`). */
    val selectedLibraryKey = ProfileSetting<String?>(LibraryPrefs.SELECTED_LIBRARY_KEY, null, String.serializer().nullable)

    /** The Explore tab's source (`plex`, `trakt`, `mal`, `anilist`, `simkl`, `seerr`, `mdblist`); null for the first connected. */
    val catalogActiveSource = ProfileSetting<String?>("catalog_active_source", null, String.serializer().nullable)

    /** Watch-together rooms joined or created: `{code, relayScope, name?, lastUsed}`, at most 20. */
    val watchTogetherRecentRooms = ProfileSetting<JsonArray?>("watch_together_recent_rooms", null, JsonArray.serializer().nullable)

    /** Tags typed in metadata edits: `{serverId: {field: [tag, …]}}`, most recent first, at most 20 per field. */
    val metadataRecentTags = ProfileSetting<JsonObject?>("metadata_recent_tags", null, JsonObject.serializer().nullable)

    /** Tracker writes waiting for the network, and a queue that didn't decode, kept aside. */
    val trackerWriteQueue = ProfileSetting<JsonElement?>("tracker_write_queue", null, JsonElement.serializer().nullable)
    val trackerWriteQueueCorrupt = ProfileSetting<JsonElement?>("tracker_write_queue_corrupt", null, JsonElement.serializer().nullable)

    /** Trakt's queue of Plezy's earlier releases. */
    val traktSyncQueue = ProfileSetting<JsonElement?>("trakt_sync_queue", null, JsonElement.serializer().nullable)
}

/** Each profile's own settings ([ProfileSetting]), by profile scope ([profileUserScope]). */
class ProfileSettingsRepository internal constructor(private val db: Db) {
    suspend fun <T> value(scope: String, setting: ProfileSetting<T>): T =
        setting.decode(db.read { deviceSettingQueries.selectProfileSetting(scope, setting.baseKey).executeAsOneOrNull() })

    fun <T> observe(scope: String, setting: ProfileSetting<T>): Flow<T> =
        db.observeOneOrNull(db.database.deviceSettingQueries.selectProfileSetting(scope, setting.baseKey)).map { setting.decode(it) }

    /** Stores [value] for [scope]; a nullable setting set to `null` is removed, as unset. */
    suspend fun <T> set(scope: String, setting: ProfileSetting<T>, value: T) {
        val next = setting.normalize(value)
        db.write {
            if (next == null) {
                q.deviceSettingQueries.deleteProfileSetting(scope, setting.baseKey)
            } else {
                q.deviceSettingQueries.upsertProfileSetting(
                    Profile_setting(scope, setting.baseKey, settingsJson.encodeToString(setting.serializer, next)),
                )
            }
        }
    }

    suspend fun reset(scope: String, setting: ProfileSetting<*>) {
        db.write { q.deviceSettingQueries.deleteProfileSetting(scope, setting.baseKey) }
    }

    /** Removes every setting of [scope]: its profile was deleted, or its account signed out. */
    suspend fun removeScope(scope: String) {
        db.write { q.deviceSettingQueries.deleteProfileScope(scope) }
    }

    /** Removes every profile's settings (signing out of everything). */
    suspend fun removeAllScopes() {
        db.write { q.deviceSettingQueries.deleteAllProfileSettings() }
    }

    /**
     * Moves settings kept under a Plex Home profile's full id (`plex-home-{connectionId}-{uuid}`) to its home user's
     * scope ([profileUserScope]), replacing what that scope had: Plezy's earlier releases wrote some under the full id,
     * and those are the newer. A scope that doesn't parse as a Plex Home id stays as it is.
     */
    suspend fun rehomePlexHomeScopes() {
        db.write { this.rehomePlexHomeScopes() }
    }
}

/** [ProfileSettingsRepository.rehomePlexHomeScopes] in a transaction of the caller's. */
internal fun Tx.rehomePlexHomeScopes() {
    val rows = q.deviceSettingQueries.selectAllProfileSettings().executeAsList()
    for (row in rows) {
        if (!row.profile_scope.startsWith(PLEX_HOME_PREFIX)) continue
        val scope = profileUserScope(row.profile_scope)
        if (scope == row.profile_scope) continue
        q.deviceSettingQueries.upsertProfileSetting(Profile_setting(scope, row.setting_key, row.value_json))
        q.deviceSettingQueries.deleteProfileSetting(row.profile_scope, row.setting_key)
    }
}

private const val PLEX_HOME_PREFIX = "plex-home-"
