package com.edde746.plezy.plex

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * A Plex Home member. plex.tv's account API drifts (numbers as strings, booleans as 0/1, fields missing), so every
 * field parses on its own and falls back to a default instead of failing the list.
 */
data class PlexHomeUser(
    val id: Int,
    val uuid: String,
    val title: String,
    val username: String? = null,
    val email: String? = null,
    val friendlyName: String? = null,
    val thumb: String = "",
    val hasPassword: Boolean = false,
    val restricted: Boolean = false,
    val updatedAt: Long? = null,
    val admin: Boolean = false,
    val guest: Boolean = false,
    val protected: Boolean = false,
) {
    /** Friendly name, else title (both when not blank), else null (the UI says "Unknown"). */
    val displayName: String?
        get() = friendlyName?.takeIf { it.isNotBlank() } ?: title.takeIf { it.isNotBlank() }

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
        fun fromJson(json: JsonObject): PlexHomeUser = PlexHomeUser(
            id = json["id"].flexInt() ?: 0,
            uuid = json["uuid"].scalarString().orEmpty(),
            title = json["title"].scalarString().orEmpty(),
            username = json["username"].scalarString(),
            email = json["email"].scalarString(),
            friendlyName = json["friendlyName"].scalarString(),
            thumb = json["thumb"].scalarString().orEmpty(),
            hasPassword = json["hasPassword"].flexBool(),
            restricted = json["restricted"].flexBool(),
            updatedAt = json["updatedAt"].flexLong(),
            admin = json["admin"].flexBool(),
            guest = json["guest"].flexBool(),
            protected = json["protected"].flexBool(),
        )
    }
}

/** A Plex Home: its id and members (missing `users` reads as none). */
data class PlexHome(val id: Int, val users: List<PlexHomeUser>) {
    fun toJson(): JsonObject = buildJsonObject {
        put("id", id)
        put("users", JsonArray(users.map { it.toJson() }))
    }

    companion object {
        fun fromJson(json: JsonObject): PlexHome =
            PlexHome(id = json["id"].flexInt() ?: 0, users = json["users"].objectList().map(PlexHomeUser::fromJson))
    }
}

/**
 * The token of a `/home/users/{uuid}/switch` answer. Only `authToken` is read (the rest of the body drifts); it must be
 * a non-empty string.
 */
fun parsePlexSwitchAuthToken(json: JsonObject): String {
    val token = json["authToken"].stringOrNull()
    if (token.isNullOrEmpty()) throw IllegalArgumentException("Plex /switch response has no usable authToken")
    return token
}
