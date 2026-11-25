package com.edde746.plezy.servers

import com.edde746.plezy.model.ServerId
import com.edde746.plezy.net.UriComponent
import kotlin.jvm.JvmInline

private const val PLEX_PROFILE_SCOPE_MARKER = "/~plex-profile/"
private const val PLEX_TRANSFER_SCOPE_SUFFIX = "/~plex-transfer"

/**
 * The private cache namespace of one Plezy profile on a public Plex server:
 * `"{serverId}/~plex-profile/{encodeURIComponent(profileId)}"`. Never a public media identity.
 */
@JvmInline
value class PlexProfileScopeId private constructor(val value: String) {
    val publicServerId: ServerId get() = ServerId(value.substring(0, value.indexOf(PLEX_PROFILE_SCOPE_MARKER)))

    val profileId: String
        get() = decodeStrict(value.substring(value.indexOf(PLEX_PROFILE_SCOPE_MARKER) + PLEX_PROFILE_SCOPE_MARKER.length))!!

    override fun toString(): String = value

    companion object {
        /** Throws [IllegalArgumentException] for an empty [profileId]. */
        fun of(serverId: ServerId, profileId: String): PlexProfileScopeId {
            require(profileId.isNotEmpty()) { "profileId must not be empty" }
            return PlexProfileScopeId("$serverId$PLEX_PROFILE_SCOPE_MARKER${UriComponent.encode(profileId)}")
        }

        /**
         * The scope [value] spells, or null when its server prefix is missing or blank, or its profile id is empty,
         * contains `/`, or is not valid percent-encoded UTF-8.
         */
        fun tryParse(value: String): PlexProfileScopeId? {
            val markerIndex = value.indexOf(PLEX_PROFILE_SCOPE_MARKER)
            if (markerIndex <= 0) return null
            ServerId.tryParse(value.substring(0, markerIndex)) ?: return null
            val encodedProfileId = value.substring(markerIndex + PLEX_PROFILE_SCOPE_MARKER.length)
            if (encodedProfileId.isEmpty() || '/' in encodedProfileId) return null
            if (decodeStrict(encodedProfileId).isNullOrEmpty()) return null
            return PlexProfileScopeId(value)
        }
    }
}

/**
 * The device-local namespace `"{serverId}/~plex-transfer"`, used only while a full logout leaves a download with no
 * profile owner. The next profile that adopts the download moves it into its own [PlexProfileScopeId].
 */
@JvmInline
value class PlexTransferScopeId private constructor(val value: String) {
    val publicServerId: ServerId get() = ServerId(value.substring(0, value.length - PLEX_TRANSFER_SCOPE_SUFFIX.length))

    override fun toString(): String = value

    companion object {
        fun of(serverId: ServerId): PlexTransferScopeId = PlexTransferScopeId("$serverId$PLEX_TRANSFER_SCOPE_SUFFIX")

        fun tryParse(value: String): PlexTransferScopeId? {
            if (!value.endsWith(PLEX_TRANSFER_SCOPE_SUFFIX)) return null
            ServerId.tryParse(value.substring(0, value.length - PLEX_TRANSFER_SCOPE_SUFFIX.length)) ?: return null
            return PlexTransferScopeId(value)
        }
    }
}

/** A Jellyfin or Emby user's scope `"{machineId}/{userId}"`: its connection id and cache namespace. */
fun mediaBrowserScopeId(machineId: ServerId, userId: String): String = "$machineId/$userId"

/** The public server of a Plex profile scope; null for anything else. */
fun publicPlexServerIdFromScope(cacheServerId: String): ServerId? = PlexProfileScopeId.tryParse(cacheServerId)?.publicServerId

/** The public server of a Plex profile or transfer scope; null for anything else. */
fun publicPlexServerIdFromCacheScope(cacheServerId: String): ServerId? =
    publicPlexServerIdFromScope(cacheServerId) ?: PlexTransferScopeId.tryParse(cacheServerId)?.publicServerId

fun isPlexProfileScopeId(cacheServerId: String): Boolean = PlexProfileScopeId.tryParse(cacheServerId) != null

/**
 * Whether [cacheServerId] is a Jellyfin or Emby user scope `"{machineId}/{userId}"` on [serverId]. The reserved Plex
 * namespaces are excluded so the backends cannot alias.
 */
fun isJellyfinUserScopeId(serverId: ServerId, cacheServerId: String): Boolean {
    val userPrefix = "$serverId/"
    return cacheServerId.startsWith(userPrefix) &&
        cacheServerId.length > userPrefix.length &&
        !isPlexProfileScopeId(cacheServerId) &&
        PlexTransferScopeId.tryParse(cacheServerId) == null
}

/**
 * The user-specific scope of [serverId]'s active client ([cacheServerId] is its
 * [com.edde746.plezy.backend.MediaBackend.cacheServerId]), or null when there is no client, it only exposes the public
 * server namespace, a transfer scope, or a scope of another server.
 */
fun resolveActiveClientScopeId(serverId: ServerId, cacheServerId: String?): String? {
    if (cacheServerId == null) return null
    val plexScope = PlexProfileScopeId.tryParse(cacheServerId)
    if (plexScope != null) return if (plexScope.publicServerId == serverId) plexScope.value else null
    if (PlexTransferScopeId.tryParse(cacheServerId) != null) return null
    return if (isJellyfinUserScopeId(serverId, cacheServerId)) cacheServerId else null
}

// Percent-decoding that rejects what `decodeURIComponent` rejects: an escape without two hex digits after it, or
// bytes that are not UTF-8. Null then.
private fun decodeStrict(value: String): String? {
    if ('%' !in value) return value
    val bytes = value.encodeToByteArray()
    val out = ByteArray(bytes.size)
    var i = 0
    var n = 0
    while (i < bytes.size) {
        val b = bytes[i]
        if (b == '%'.code.toByte()) {
            if (i + 2 >= bytes.size) return null
            val hi = bytes[i + 1].toInt().toChar().digitToIntOrNull(16) ?: return null
            val lo = bytes[i + 2].toInt().toChar().digitToIntOrNull(16) ?: return null
            out[n++] = ((hi shl 4) or lo).toByte()
            i += 3
        } else {
            out[n++] = b
            i++
        }
    }
    return try {
        out.decodeToString(0, n, throwOnInvalidSequence = true)
    } catch (e: CharacterCodingException) {
        null
    }
}
