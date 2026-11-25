package com.edde746.plezy.plex.tv

import com.edde746.plezy.backend.Connection
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.plex.PlexHomeUser
import com.edde746.plezy.plex.PlexServer
import com.edde746.plezy.plex.objectList
import com.edde746.plezy.plex.stringOrNull
import com.edde746.plezy.servers.PlexAccountServers
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/**
 * A signed-in Plex account: its plex.tv token (long-lived), this device's client identifier (stable, so plex.tv doesn't
 * see a new device each launch), the Home user switched into ([activeProfile], null for the account itself) and the
 * account's servers as last discovered.
 */
data class PlexAccountConnection(
    override val id: String,
    override val accountToken: String,
    override val clientIdentifier: String,
    /** Username, else email, else "Plex". */
    val accountLabel: String = "Plex",
    val activeProfile: PlexHomeUser? = null,
    override val servers: List<PlexServer> = emptyList(),
    override val createdAt: Long,
    override val lastAuthenticatedAt: Long? = null,
) : Connection, PlexAccountServers {
    override val kind: BackendKind get() = BackendKind.PLEX

    override val accountId: String get() = id

    /** `<profile title> · <account label>` while a Home user with a title is active, else the account label. */
    override val displayName: String
        get() = activeProfile?.title?.takeIf { it.isNotEmpty() }?.let { "$it · $accountLabel" } ?: accountLabel

    override val displayLabel: String get() = displayName

    override val displaySubtitle: String
        get() = if (servers.size == 1) "1 Plex server" else "${servers.size} Plex servers"

    override fun toConfigJson(): JsonObject = buildJsonObject {
        put("accountToken", accountToken)
        put("clientIdentifier", clientIdentifier)
        put("accountLabel", accountLabel)
        put("activeProfile", activeProfile?.toJson() ?: JsonNull)
        put("servers", JsonArray(servers.map { it.toJson() }))
    }

    companion object {
        /**
         * The connection stored as [json] by [toConfigJson]. Missing or mistyped fields read as defaults (empty token
         * and client identifier, label "Plex", no profile, no servers); server entries that are not objects are
         * skipped.
         */
        fun fromConfigJson(id: String, json: JsonObject, createdAt: Long, lastAuthenticatedAt: Long? = null) =
            PlexAccountConnection(
                id = id,
                accountToken = json["accountToken"].stringOrNull().orEmpty(),
                clientIdentifier = json["clientIdentifier"].stringOrNull().orEmpty(),
                accountLabel = json["accountLabel"].stringOrNull() ?: "Plex",
                activeProfile = (json["activeProfile"] as? JsonObject)?.let(PlexHomeUser::fromJson),
                servers = (json["servers"] as? JsonArray).objectList().map(PlexServer::fromJson),
                createdAt = createdAt,
                lastAuthenticatedAt = lastAuthenticatedAt,
            )
    }
}

/** A freshly built account connection and the plex.tv identity it was built from (empty when unknown). */
data class PlexAccountBuild(
    val connection: PlexAccountConnection,
    val username: String,
    val email: String,
    val accountUuid: String,
)

/** What plex.tv's `/user` says of an account; empty where it says nothing. */
internal class PlexUserIdentity(val uuid: String, val username: String, val email: String) {
    /** The account's label: the username, else the email, else "Plex". */
    val label: String get() = username.ifEmpty { email.ifEmpty { "Plex" } }

    companion object {
        val UNKNOWN = PlexUserIdentity("", "", "")

        fun of(info: JsonObject) = PlexUserIdentity(
            uuid = info["uuid"].stringOrNull()?.trim().orEmpty(),
            username = info["username"].stringOrNull().orEmpty(),
            email = info["email"].stringOrNull().orEmpty(),
        )
    }
}

/**
 * The connection for a fresh plex.tv [token]: identity from [fetchUserInfo] (plex.tv `/user`), servers from
 * [fetchServers], stamped [now] (epoch ms).
 *
 * The id is `plex.<account uuid>`: the client identifier is the same for every account on this device, so only the
 * uuid tells two accounts apart. It is `plex.<clientIdentifier>` when the uuid is unknown or [keyByAccountUuid] is
 * false. The label is the username, else the email, else "Plex". A failed identity lookup leaves the identity empty
 * unless [tolerateUserInfoFailure] is false; a failed server fetch always throws.
 */
suspend fun buildPlexAccountConnection(
    token: String,
    clientIdentifier: String,
    now: Long,
    fetchUserInfo: suspend (token: String) -> JsonObject,
    fetchServers: suspend (token: String) -> List<PlexServer>,
    keyByAccountUuid: Boolean = true,
    tolerateUserInfoFailure: Boolean = true,
): PlexAccountBuild {
    val user = try {
        PlexUserIdentity.of(fetchUserInfo(token))
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        if (!tolerateUserInfoFailure) throw e
        Log.d(TAG, e) { "Plex user-info lookup failed, keying the account by client identifier" }
        PlexUserIdentity.UNKNOWN
    }
    val servers = fetchServers(token)
    val connection = PlexAccountConnection(
        id = "plex.${if (keyByAccountUuid && user.uuid.isNotEmpty()) user.uuid else clientIdentifier}",
        accountToken = token,
        clientIdentifier = clientIdentifier,
        accountLabel = user.label,
        servers = servers,
        createdAt = now,
        lastAuthenticatedAt = now,
    )
    return PlexAccountBuild(connection, user.username, user.email, user.uuid)
}

private const val TAG = "PlexAccount"
