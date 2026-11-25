package com.edde746.plezy.profiles

import com.edde746.plezy.data.Db
import com.edde746.plezy.data.Tx
import com.edde746.plezy.data.db.Profiles
import com.edde746.plezy.log.Log
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put

/**
 * The local profiles (`profiles`). Plex Home users aren't stored here: they're built from each Plex account's cached
 * Home users ([ProfileIdentity.plexHomeUsers]) and merged in ([mergeLocalWithPlexHome]).
 */
class ProfileRegistry internal constructor(private val db: Db) {
    /** The local profiles by sort order, then creation; a row whose configuration doesn't read is skipped (and logged). */
    suspend fun list(): List<LocalProfile> = db.read { profileQueries.selectLocal().executeAsList() }.mapNotNull { it.toProfile() }

    /** [list] now and after every change. */
    fun observe(): Flow<List<LocalProfile>> =
        db.observeList(db.database.profileQueries.selectLocal()).map { rows -> rows.mapNotNull { it.toProfile() } }

    /** Stores [profile], replacing every column of a stored one. */
    suspend fun upsert(profile: LocalProfile) {
        db.write { putProfile(profile) }
    }

    /**
     * Renames the local profile [id] to [displayName] trimmed, touching nothing else (a PIN changed meanwhile stays).
     * Throws IllegalArgumentException for a blank name, IllegalStateException when there's no such local profile.
     */
    suspend fun rename(id: String, displayName: String) {
        val name = displayName.trim()
        require(name.isNotEmpty()) { "A profile name is required." }
        db.write {
            q.profileQueries.renameLocal(name, id)
            check(q.profileQueries.changes().executeAsOne() == 1L) { "The editable profile is unavailable." }
        }
    }

    /**
     * Sets the local profile [id]'s PIN to [pinHash] (null: none) in its stored configuration, touching nothing else (a
     * name changed meanwhile stays). Throws IllegalStateException when there's no such local profile.
     */
    suspend fun setPinHash(id: String, pinHash: String?) {
        db.write {
            val stored = checkNotNull(q.profileQueries.selectLocalConfig(id).executeAsOneOrNull()) { "The editable profile is unavailable." }
            val config = Json.parseToJsonElement(stored).jsonObject
            q.profileQueries.setLocalConfig(JsonObject(config + ("pinHash" to JsonPrimitive(pinHash))).toString(), id)
        }
    }

    /** Records that the profile [id] was used at [at] (epoch milliseconds). */
    suspend fun markUsed(id: String, at: Long) {
        db.write { q.profileQueries.markProfileUsed(at, id) }
    }

    /** Removes the profile [id], whatever its kind. */
    suspend fun remove(id: String) {
        db.write { q.profileQueries.deleteProfile(id) }
    }

    suspend fun clear() {
        db.write { q.profileQueries.deleteAllProfiles() }
    }
}

/** Stores [profile] in this transaction, replacing every column of a stored one. */
internal fun Tx.putProfile(profile: LocalProfile) {
    q.profileQueries.upsertProfile(profile.toRow())
}

private fun Profiles.toProfile(): LocalProfile? = try {
    require(kind == ProfileKind.LOCAL.id) { "unknown profile kind $kind" }
    val config = Json.parseToJsonElement(config_json).jsonObject
    LocalProfile(
        id = id,
        displayName = display_name,
        avatarThumbUrl = avatar_thumb_url,
        pinHash = config.pinHash(),
        sortOrder = sort_order,
        createdAt = created_at,
        lastUsedAt = last_used_at,
    )
} catch (e: IllegalArgumentException) {
    // SerializationException is one too.
    Log.e(TAG, e) { "profile $id doesn't decode; it's left out" }
    null
}

private fun JsonObject.pinHash(): String? = when (val hash = this["pinHash"]) {
    null, JsonNull -> null
    is JsonPrimitive -> {
        require(hash.isString) { "pinHash is not a string" }
        hash.content
    }
    else -> throw IllegalArgumentException("pinHash is not a string")
}

/** The `profiles.config_json` of a local profile. */
private fun LocalProfile.configJson(): String = buildJsonObject { put("pinHash", pinHash) }.toString()

private fun LocalProfile.toRow() = Profiles(
    id = id,
    kind = ProfileKind.LOCAL.id,
    display_name = displayName,
    avatar_thumb_url = avatarThumbUrl,
    config_json = configJson(),
    sort_order = sortOrder,
    created_at = createdAt,
    last_used_at = lastUsedAt,
)

private const val TAG = "profiles"
