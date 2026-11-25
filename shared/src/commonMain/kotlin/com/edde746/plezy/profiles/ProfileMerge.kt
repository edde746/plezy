package com.edde746.plezy.profiles

import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.model.BackendKind
import io.ktor.http.encodeURLParameter
import kotlinx.serialization.json.JsonPrimitive

/**
 * The profiles to pick from: [locals], then a profile per cached Home user of each Plex account in [connectionIds]
 * (the users of an account that's gone are left out), most recently used first. Profiles never used follow in that
 * order. A local profile was last used at the later of its own time and its [storedLastUsed] one; a Plex Home profile
 * at its [storedLastUsed] one.
 */
fun mergeLocalWithPlexHome(
    locals: List<LocalProfile>,
    plexHomeByConnectionId: Map<String, List<PlexHomeUser>>,
    connectionIds: Set<String>,
    storedLastUsed: Map<String, Long> = emptyMap(),
): List<Profile> {
    val merged = ArrayList<Profile>()
    locals.mapTo(merged) { local ->
        val stored = storedLastUsed[local.id]
        val current = local.lastUsedAt
        local.withLastUsedAt(if (stored == null || (current != null && current >= stored)) current else stored)
    }
    for ((connectionId, users) in plexHomeByConnectionId) {
        if (connectionId !in connectionIds) continue
        users.mapTo(merged) { user ->
            PlexHomeProfile.virtualPlexHome(connectionId, user, storedLastUsed[plexHomeProfileId(connectionId, user.uuid)])
        }
    }
    return sortProfilesByLastUsed(merged)
}

/** [profiles] most recently used first, the never used last; the sort is stable. */
fun sortProfilesByLastUsed(profiles: List<Profile>): List<Profile> =
    profiles.sortedWith(compareBy<Profile, Long?>(nullsLast(reverseOrder())) { it.lastUsedAt })

/**
 * The active profile: the one of [profiles] whose id is [activeId]. None while no id is stored, and none (with the id
 * kept) while it matches no profile, as a list read early may still be missing it.
 */
fun resolveActiveProfile(profiles: List<Profile>, activeId: String?): Profile? =
    activeId?.let { id -> profiles.firstOrNull { it.id == id } }

/**
 * The bindings of [profile] to show as its connections: all of them, except a Plex Home profile's binding to its own
 * account, which only holds the user's token and isn't one the user can remove.
 */
fun visibleProfileConnections(profile: Profile, bindings: List<ProfileConnection>): List<ProfileConnection> {
    val parentId = profile.parentConnectionId
    if (profile !is PlexHomeProfile || parentId == null) return bindings
    return bindings.filter { it.connectionId != parentId }
}

/** [bindings] by profile id, each list in input order. */
fun groupConnectionsByProfile(bindings: List<ProfileConnection>): Map<String, List<ProfileConnection>> =
    bindings.groupBy { it.profileId }

/**
 * Each profile's picture URL by id, null for initials. A Plex Home profile shows its own picture or none. A local
 * profile shows the user picture of its oldest linked connection (by creation, then id; links to removed connections
 * don't count), and none when that connection has no picture: a later connection's isn't taken instead.
 */
fun resolveProfileAvatarUrls(
    profiles: List<Profile>,
    connectionsByProfile: Map<String, List<ProfileConnection>>,
    connectionsById: Map<String, StoredConnection>,
    plexHomeByConnectionId: Map<String, List<PlexHomeUser>>,
): Map<String, String?> = profiles.associate { profile ->
    profile.id to avatarFor(profile, connectionsByProfile[profile.id].orEmpty(), connectionsById, plexHomeByConnectionId)
}

private fun avatarFor(
    profile: Profile,
    links: List<ProfileConnection>,
    connectionsById: Map<String, StoredConnection>,
    plexHomeByConnectionId: Map<String, List<PlexHomeUser>>,
): String? {
    profile.avatarThumbUrl?.takeIf { it.isNotEmpty() }?.let { return it }
    if (profile is PlexHomeProfile) return null
    val first = links
        .mapNotNull { link -> connectionsById[link.connectionId]?.let { it to link } }
        .minWithOrNull(compareBy<Pair<StoredConnection, ProfileConnection>> { it.first.createdAt }.thenBy { it.first.id })
        ?: return null
    return connectionAvatarUrl(first.first, first.second, plexHomeByConnectionId)
}

/**
 * The user picture [connection] gives [link]'s profile, or null: the Jellyfin/Emby user's primary image, or the
 * picture of the Plex Home user the link is to.
 */
fun connectionAvatarUrl(
    connection: StoredConnection,
    link: ProfileConnection,
    plexHomeByConnectionId: Map<String, List<PlexHomeUser>>,
): String? = when (connection.kind) {
    BackendKind.JELLYFIN, BackendKind.EMBY -> mediaBrowserUserImageUrl(
        baseUrl = connection.configString("baseUrl").orEmpty(),
        userId = connection.configString("userId").orEmpty(),
        tag = connection.configString("primaryImageTag")?.trim(),
    )
    BackendKind.PLEX -> {
        val users = plexHomeByConnectionId[connection.id]
        if (users == null || link.userIdentifier.isEmpty()) {
            null
        } else {
            users.firstOrNull { it.uuid == link.userIdentifier }?.thumb?.ifEmpty { null }
        }
    }
}

private fun mediaBrowserUserImageUrl(baseUrl: String, userId: String, tag: String?): String? {
    if (baseUrl.isEmpty() || userId.isEmpty() || tag.isNullOrEmpty()) return null
    return "${baseUrl.removeSuffix("/")}/Users/${userId.encodeURLParameter()}/Images/Primary" +
        "?tag=${tag.encodeURLParameter()}&maxWidth=$AVATAR_SIZE&maxHeight=$AVATAR_SIZE"
}

private const val AVATAR_SIZE = 240

/** The Plex account a cloud service (Discover, Seerr, account preferences) acts as, and its Home user if any. */
data class ActivePlexIdentity(val account: StoredConnection, val userUuid: String?)

/**
 * The Plex identity of the [active] profile: a Plex Home profile's own account; else the account of [active]'s first
 * binding ([activeBindings], in [ProfileConnectionRegistry.listForProfile] order) to a Plex account, as its Home user;
 * else none. With no active profile, the first Plex account of [connections].
 */
fun resolveActivePlexIdentity(
    active: Profile?,
    activeBindings: List<ProfileConnection>,
    connections: List<StoredConnection>,
): ActivePlexIdentity? {
    val plexAccounts = connections.filter { it.kind == BackendKind.PLEX }
    if (active is PlexHomeProfile) {
        plexAccounts.firstOrNull { it.id == active.parentConnectionId }?.let { return ActivePlexIdentity(it, active.plexHomeUserUuid) }
    }
    if (active != null) {
        for (binding in activeBindings) {
            val account = plexAccounts.firstOrNull { it.id == binding.connectionId } ?: continue
            return ActivePlexIdentity(account, binding.userIdentifier.ifEmpty { null })
        }
        return null
    }
    return plexAccounts.firstOrNull()?.let { ActivePlexIdentity(it, null) }
}

/** An [ActivePlexIdentity] with the token to use for it. */
data class ActivePlexToken(val identity: ActivePlexIdentity, val token: String)

/**
 * The token for [identity]: the [active] profile's own token on the account ([activeBindings]) when it holds one,
 * else the account owner's. A Plex Home profile gets the owner's only when [allowAccountTokenForHomeUser].
 */
fun resolveActivePlexToken(
    identity: ActivePlexIdentity,
    active: Profile?,
    activeBindings: List<ProfileConnection>,
    allowAccountTokenForHomeUser: Boolean,
): ActivePlexToken? {
    if (active != null) {
        val own = activeBindings.firstOrNull { it.profileId == active.id && it.connectionId == identity.account.id }
        if (own != null && own.hasToken) return ActivePlexToken(identity, own.userToken!!)
    }
    if (!allowAccountTokenForHomeUser && active is PlexHomeProfile) return null
    return ActivePlexToken(identity, identity.account.configString("accountToken").orEmpty())
}

private fun StoredConnection.configString(field: String): String? =
    (config[field] as? JsonPrimitive)?.takeIf { it.isString }?.content
