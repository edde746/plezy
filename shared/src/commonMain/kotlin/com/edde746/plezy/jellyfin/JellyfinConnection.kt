package com.edde746.plezy.jellyfin

import com.edde746.plezy.backend.Connection
import com.edde746.plezy.backend.net.canonicalizeBaseUrl
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaBrowserDialect
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.MediaBrowserConnection
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * One signed-in user on a Jellyfin or Emby server: row id `{serverMachineId}/{userId}`. [baseUrl] is the active
 * endpoint; [baseUrls] the ordered candidates with it first, canonicalized and deduplicated.
 */
class JellyfinConnection(
    override val id: String,
    baseUrl: String,
    baseUrls: List<String> = emptyList(),
    override val serverName: String,
    val serverMachineId: String,
    val userId: String,
    val userName: String,
    val accessToken: String,
    /** The `DeviceId` the token was issued to. */
    val deviceId: String,
    val dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN,
    /** `Policy.IsAdministrator`, gating admin-only actions; refreshed by the health check. */
    override val isAdministrator: Boolean = false,
    /** The user's `PrimaryImageTag`; null without a profile picture. */
    val primaryImageTag: String? = null,
    override val createdAt: Long,
    override val lastAuthenticatedAt: Long? = null,
) : Connection, MediaBrowserConnection {
    val baseUrl: String = canonicalizeBaseUrl(baseUrl)
    val baseUrls: List<String> = (listOf(baseUrl) + baseUrls).map(::canonicalizeBaseUrl).filter { it.isNotEmpty() }.distinct()

    /** For the server manager: the public server identity. */
    override val serverId: ServerId get() = ServerId(serverMachineId)

    override val kind: BackendKind get() = dialect.backend
    override val displayName: String get() = "$userName · $serverName"
    override val displayLabel: String get() = serverName
    override val displaySubtitle: String
        get() {
            val extra = baseUrls.size - 1
            val url = if (baseUrl.length <= 40) baseUrl else baseUrl.substring(0, 37) + "…"
            return "$userName · $url" + if (extra > 0) " +$extra" else ""
        }

    fun copy(
        id: String = this.id,
        baseUrl: String = this.baseUrl,
        baseUrls: List<String> = this.baseUrls,
        serverName: String = this.serverName,
        serverMachineId: String = this.serverMachineId,
        userId: String = this.userId,
        userName: String = this.userName,
        accessToken: String = this.accessToken,
        deviceId: String = this.deviceId,
        dialect: MediaBrowserDialect = this.dialect,
        isAdministrator: Boolean = this.isAdministrator,
        primaryImageTag: String? = this.primaryImageTag,
        createdAt: Long = this.createdAt,
        lastAuthenticatedAt: Long? = this.lastAuthenticatedAt,
    ) = JellyfinConnection(
        id, baseUrl, baseUrls, serverName, serverMachineId, userId, userName, accessToken, deviceId, dialect,
        isAdministrator, primaryImageTag, createdAt, lastAuthenticatedAt,
    )

    /** The persisted payload. The dialect is not in it: the row's `kind` column is the discriminator. */
    override fun toConfigJson(): JsonObject = buildJsonObject {
        put("baseUrl", baseUrl)
        put("baseUrls", JsonArray(baseUrls.map(::JsonPrimitive)))
        put("serverName", serverName)
        put("serverMachineId", serverMachineId)
        put("userId", userId)
        put("userName", userName)
        put("accessToken", accessToken)
        put("deviceId", deviceId)
        put("isAdministrator", isAdministrator)
        put("primaryImageTag", primaryImageTag?.let(::JsonPrimitive) ?: JsonNull)
    }

    override fun equals(other: Any?): Boolean = other is JellyfinConnection && toConfigJson() == other.toConfigJson() &&
        id == other.id && dialect == other.dialect && createdAt == other.createdAt && lastAuthenticatedAt == other.lastAuthenticatedAt

    override fun hashCode(): Int = id.hashCode() * 31 + toConfigJson().hashCode()

    companion object {
        /** Tolerant decode: missing keys get safe defaults, a legacy row's baseUrl backfills baseUrls. */
        fun fromConfigJson(
            id: String,
            json: JsonObject,
            createdAt: Long,
            lastAuthenticatedAt: Long? = null,
            dialect: MediaBrowserDialect = MediaBrowserDialect.JELLYFIN,
        ): JellyfinConnection {
            val urls = json.strings("baseUrls").orEmpty()
            val baseUrl = json.str("baseUrl")?.takeIf { it.isNotEmpty() } ?: urls.firstOrNull().orEmpty()
            return JellyfinConnection(
                id = id,
                baseUrl = baseUrl,
                baseUrls = urls,
                dialect = dialect,
                serverName = json.str("serverName") ?: dialect.productName,
                serverMachineId = json.str("serverMachineId").orEmpty(),
                userId = json.str("userId").orEmpty(),
                userName = json.str("userName").orEmpty(),
                accessToken = json.str("accessToken").orEmpty(),
                deviceId = json.str("deviceId").orEmpty(),
                isAdministrator = json.bool("isAdministrator") ?: false,
                primaryImageTag = normalizePrimaryImageTag(json["primaryImageTag"]),
                createdAt = createdAt,
                lastAuthenticatedAt = lastAuthenticatedAt,
            )
        }

        /** A user DTO's `PrimaryImageTag`, any scalar coerced, blank as null: the tag is decorative, never fatal. */
        fun readPrimaryImageTag(userDto: JsonObject): String? = normalizePrimaryImageTag(userDto["PrimaryImageTag"])

        private fun normalizePrimaryImageTag(raw: kotlinx.serialization.json.JsonElement?): String? =
            (raw as? JsonPrimitive)?.takeIf { it !is JsonNull }?.content?.trim()?.ifEmpty { null }
    }
}
