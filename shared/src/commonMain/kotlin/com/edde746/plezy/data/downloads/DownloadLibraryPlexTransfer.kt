package com.edde746.plezy.data.downloads

import com.edde746.plezy.plex.withoutProfileState
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject

/**
 * A cached Plex metadata response [data] without its profile-private fields ([withoutProfileState]), safe to keep while
 * a download has no owner; null when [data] isn't a JSON object, so nothing unreadable reaches the scope any profile can
 * adopt.
 */
internal fun sanitizePlexMetadataForOwnerlessTransfer(data: String): String? {
    val decoded = try {
        Json.parseToJsonElement(data)
    } catch (e: SerializationException) {
        // An unreadable payload is left behind rather than moved into the shared scope.
        return null
    }
    if (decoded !is JsonObject) return null
    return withoutProfileState(decoded).toString()
}
