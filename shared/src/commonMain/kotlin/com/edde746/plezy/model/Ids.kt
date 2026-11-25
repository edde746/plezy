package com.edde746.plezy.model

import kotlin.jvm.JvmInline

/**
 * A media server's public identity: Plex's `machineIdentifier`, a Jellyfin or Emby server's `Id`. Never blank. Compares,
 * hashes and prints as the raw string.
 */
@JvmInline
value class ServerId(val value: String) {
    init {
        require(value.isNotBlank()) { "ServerId cannot be empty or blank" }
    }

    override fun toString(): String = value

    companion object {
        /** The id, or null for a null or blank [value]. */
        fun tryParse(value: String?): ServerId? = if (value.isNullOrBlank()) null else ServerId(value)
    }
}

/** `"{serverId}:{id}"`: an item, library or playlist's key across every server. */
fun buildGlobalKey(serverId: ServerId, id: String): String = "$serverId:$id"

/** A global key's server id and backend id, split at the first `:`; null when there is none or it leads. */
fun parseGlobalKey(globalKey: String): Pair<ServerId, String>? {
    val colon = globalKey.indexOf(':')
    if (colon <= 0) return null
    val serverId = ServerId.tryParse(globalKey.substring(0, colon)) ?: return null
    return serverId to globalKey.substring(colon + 1)
}

/** `"{profileId}|{serverId}:{id}"`: a global key scoped to one local profile. */
fun buildProfileScopedKey(profileId: String, serverId: ServerId, id: String): String =
    "$profileId|${buildGlobalKey(serverId, id)}"
