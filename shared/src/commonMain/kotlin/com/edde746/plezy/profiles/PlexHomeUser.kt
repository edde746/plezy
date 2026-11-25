package com.edde746.plezy.profiles

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.put

/**
 * A user of a Plex Home, as plex.tv's home users list gives it and as the per-account cache keeps it
 * ([encodePlexHomeUsers]). [protected] means Plex asks for the user's PIN on switching to it.
 */
data class PlexHomeUser(
    val id: Long,
    val uuid: String,
    val title: String,
    val username: String? = null,
    val email: String? = null,
    val friendlyName: String? = null,
    val thumb: String,
    val hasPassword: Boolean = false,
    val restricted: Boolean = false,
    val updatedAt: Long? = null,
    val admin: Boolean = false,
    val guest: Boolean = false,
    val protected: Boolean = false,
) {
    /** The friendly name, else the title; blank when both are. */
    val displayName: String
        get() = friendlyName?.takeIf { it.isNotBlank() } ?: title.takeIf { it.isNotBlank() } ?: ""

    /** The cache's JSON object of this user. */
    fun toJson(): JsonObject = buildJsonObject {
        put("id", id)
        put("uuid", uuid)
        put("title", title)
        put("username", username)
        put("email", email)
        put("friendlyName", friendlyName)
        put("thumb", thumb)
        put("hasPassword", hasPassword)
        put("restricted", restricted)
        put("updatedAt", updatedAt)
        put("admin", admin)
        put("guest", guest)
        put("protected", protected)
    }

    companion object {
        /**
         * The user in [json], read leniently as plex.tv's answers vary: numbers may come as strings, flags as `1`/`"1"`/
         * `"true"`, and a missing or unreadable field reads as empty, zero or false.
         */
        fun fromJson(json: JsonObject): PlexHomeUser = PlexHomeUser(
            id = json["id"].flexibleLong() ?: 0,
            uuid = json["uuid"].flexibleString() ?: "",
            title = json["title"].flexibleString() ?: "",
            username = json["username"].flexibleString(),
            email = json["email"].flexibleString(),
            friendlyName = json["friendlyName"].flexibleString(),
            thumb = json["thumb"].flexibleString() ?: "",
            hasPassword = json["hasPassword"].flexibleBool(),
            restricted = json["restricted"].flexibleBool(),
            updatedAt = json["updatedAt"].flexibleLong(),
            admin = json["admin"].flexibleBool(),
            guest = json["guest"].flexibleBool(),
            protected = json["protected"].flexibleBool(),
        )
    }
}

/** The cache's JSON list of [users]. */
fun encodePlexHomeUsers(users: List<PlexHomeUser>): JsonArray = buildJsonArray { users.forEach { add(it.toJson()) } }

/** The users of a cached list; entries that aren't objects are skipped. */
fun decodePlexHomeUsers(cache: JsonArray): List<PlexHomeUser> = cache.filterIsInstance<JsonObject>().map(PlexHomeUser::fromJson)

/**
 * The users of a cache's JSON text ([encodePlexHomeUsers] written out); throws IllegalArgumentException when [raw]
 * isn't JSON or isn't a list.
 */
fun decodePlexHomeUsers(raw: String): List<PlexHomeUser> {
    val decoded = Json.parseToJsonElement(raw)
    require(decoded is JsonArray) { "The Plex Home users cache is not a list" }
    return decodePlexHomeUsers(decoded)
}

private fun JsonElement?.flexibleString(): String? = when (this) {
    null, JsonNull -> null
    is JsonPrimitive -> content
    else -> toString()
}

private fun JsonElement?.flexibleLong(): Long? {
    val primitive = this as? JsonPrimitive ?: return null
    if (primitive is JsonNull) return null
    if (primitive.isString) return primitive.content.toLongOrNull()
    return primitive.longOrNull ?: primitive.doubleOrNull?.toLong()
}

private fun JsonElement?.flexibleBool(): Boolean {
    val primitive = this as? JsonPrimitive ?: return false
    if (primitive is JsonNull) return false
    if (primitive.isString) return primitive.content == "1" || primitive.content.lowercase() == "true"
    return primitive.booleanOrNull ?: (primitive.longOrNull == 1L)
}
