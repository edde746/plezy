package com.edde746.plezy.profiles

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.connections.ConnectionStore
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ServerSettings
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * The profiles a Plex account's sign-out touches: [removedVirtualProfileIds], its Plex Home profiles, which go with it,
 * and [borrowerProfileIds], the other profiles bound to it, which stay.
 */
data class PlexAccountRemoval(val removedVirtualProfileIds: Set<String>, val borrowerProfileIds: Set<String>)

/** Where the session goes after a removal ([ProfileTeardown.settleAfterRemoval]). */
sealed interface PostRemovalOutcome {
    /** No connection or no profile is left: back to sign-in, with no active profile. */
    data object SignedOut : PostRemovalOutcome

    /** The active profile is still there. */
    data class KeepActive(val profile: Profile) : PostRemovalOutcome

    /** The active profile is gone: activate [profile], the most recently used one without a PIN. */
    data class Activate(val profile: Profile) : PostRemovalOutcome

    /** Every profile left has a PIN: the active profile is cleared and the picker asks for one. */
    data object PickProfile : PostRemovalOutcome
}

/**
 * Removing profiles, their connections and accounts from the device's data, and everything they leave behind:
 * bindings, connections no profile uses any more, per-profile settings and rows, library preferences of servers the
 * profile no longer reaches. Downloads and integrations aren't touched here: the user's removals go through
 * [ProfileRemoval], which releases the downloads first.
 */
class ProfileTeardown(
    private val localData: LocalData,
    private val connections: ConnectionStore,
    private val profileConnections: ProfileConnectionRegistry,
) {
    private val identity = ProfileIdentity(localData)

    /**
     * Deletes the local profile [profileId] and what it owns: its sync rules, download collections, queued watch
     * actions, music session, bindings (and the Jellyfin/Emby connections only it used), recency and settings.
     */
    suspend fun deleteLocalProfile(profileId: String) {
        localData.syncRules.deleteForProfile(profileId)
        localData.downloadCollections.deleteForProfile(profileId)
        localData.offlineWatch.deleteForProfile(profileId)
        localData.musicSessions.deleteForProfile(profileId)
        removeAllProfileConnections(profileId)
        localData.profiles.remove(profileId)
        identity.clearProfileLastUsed(profileId)
        localData.profileSettings.removeScope(profileUserScope(profileId))
    }

    /**
     * Unbinds [connection] from [profileId]. The profile's library preferences of servers it no longer reaches go; a
     * Jellyfin/Emby server no profile reaches any more loses them everywhere, and a Jellyfin/Emby connection no profile
     * uses is removed. A Plex account stays: its Home profiles use it without a binding.
     */
    suspend fun removeProfileConnection(profileId: String, connection: StoredConnection) {
        val removedServerIds = connection.serverIds()
        profileConnections.remove(profileId, connection.id)
        val mediaBrowser = connection.kind.usesMediaBrowserApi
        if (removedServerIds.isNotEmpty()) {
            val remaining = serverIdsForProfile(profileId)
            val activeProfileId = identity.activeProfileId()
            for (serverId in removedServerIds) {
                if (serverId in remaining) continue
                if (!mediaBrowser || isServerReferenced(serverId)) {
                    localData.libraryPrefs.clearForServer(serverId, profileId, includeLegacy = activeProfileId == profileId)
                } else {
                    localData.libraryPrefs.clearForServerEverywhere(serverId)
                }
            }
        }
        if (mediaBrowser && profileConnections.listForConnection(connection.id).isEmpty()) removeMediaBrowserConnection(connection)
    }

    /**
     * The servers [profileId] stops reaching when [connection] is unbound from it: [connection]'s, less those its other
     * bindings reach and, for a Plex Home profile, its own account's. Changes nothing.
     */
    suspend fun serversLostByUnlinking(profileId: String, connection: StoredConnection): Set<String> {
        val byId = connections.list().associateBy { it.id }
        val retained = profileConnections.listForProfile(profileId)
            .filter { it.connectionId != connection.id }
            .flatMapTo(HashSet()) { byId[it.connectionId]?.serverIds().orEmpty() }
        val parentId = parsePlexHomeProfileId(profileId)?.accountConnectionId
        if (parentId != null && parentId != connection.id) retained += byId[parentId]?.serverIds().orEmpty()
        return connection.serverIds() - retained
    }

    /** Unbinds every connection of [profileId] ([removeProfileConnection]). */
    suspend fun removeAllProfileConnections(profileId: String) {
        val rows = profileConnections.listForProfile(profileId)
        if (rows.isEmpty()) return
        val byId = connections.list().associateBy { it.id }
        for (row in rows) {
            val connection = byId[row.connectionId]
            if (connection == null) profileConnections.remove(profileId, row.connectionId) else removeProfileConnection(profileId, connection)
        }
    }

    /** What signing out of the Plex account [accountId] would remove; changes nothing. */
    suspend fun planPlexAccountRemoval(accountId: String): PlexAccountRemoval {
        val rows = profileConnections.listAll()
        val virtual = rows.map { it.profileId }.filter { parsePlexHomeProfileId(it)?.accountConnectionId == accountId }.toSet()
        val borrowers = rows.filter { it.connectionId == accountId && it.profileId !in virtual }.map { it.profileId }.toSet()
        return PlexAccountRemoval(virtual, borrowers)
    }

    /**
     * Signs out of the Plex account [account]: its bindings, the account, its cached Home users, and its Home profiles
     * with their bindings (and the Jellyfin/Emby connections only they used), recency, settings, sync rules, download
     * collections, queued watch actions and music sessions. Downloads keep their owners: a Home profile's id comes back
     * with the same account and user. [planned] is a plan made before the caller's own cleanup.
     */
    suspend fun signOutPlexAccount(account: StoredConnection, planned: PlexAccountRemoval? = null): PlexAccountRemoval {
        val removal = removePlexAccountConnection(account, planned)
        for (profileId in removal.removedVirtualProfileIds) {
            localData.syncRules.deleteForProfile(profileId)
            localData.downloadCollections.deleteForProfile(profileId)
            localData.offlineWatch.deleteForProfile(profileId)
            localData.musicSessions.deleteForProfile(profileId)
        }
        return removal
    }

    /** The bindings, connection and profile part of [signOutPlexAccount]. */
    suspend fun removePlexAccountConnection(account: StoredConnection, planned: PlexAccountRemoval? = null): PlexAccountRemoval {
        val removal = planned ?: planPlexAccountRemoval(account.id)
        for (row in profileConnections.listForConnection(account.id)) removeProfileConnection(row.profileId, account)
        connections.remove(account.id)
        identity.clearPlexHomeUsers(account.id)
        for (profileId in removal.removedVirtualProfileIds) {
            removeAllProfileConnections(profileId)
            identity.clearProfileLastUsed(profileId)
            localData.profileSettings.removeScope(profileUserScope(profileId))
        }
        return removal
    }

    /**
     * Logs out of everything: the client identifier and library preferences, download owners (the downloads stay for
     * the next profile), every binding, profile, connection, cached Home user list, the active profile, recency, every
     * profile's settings, queued watch actions, sync rules, download collections, every server's remembered endpoint,
     * the earlier releases' server order and the cached server answers that aren't pinned for downloads. The device's
     * other settings stay.
     */
    suspend fun logOutAll() {
        identity.clearClientIdentifier()
        localData.libraryPrefs.clearAll()
        localData.downloadLibrary.detachDownloadsForLogout()
        profileConnections.clear()
        localData.profiles.clear()
        connections.clear()
        identity.clearAllPlexHomeUsers()
        identity.clearActiveProfileId()
        identity.clearAllProfileLastUsed()
        localData.profileSettings.removeAllScopes()
        localData.offlineWatch.clearAll()
        localData.syncRules.clearAll()
        localData.downloadCollections.clearAll()
        localData.apiCache.clearVolatile()
        localData.serverSettings.resetEverywhere(ServerSettings.serverEndpoint)
        localData.deviceSettings.reset(AppSettings.serverOrder)
    }

    /**
     * Where the session goes after a removal, the Jellyfin/Emby connections no profile uses pruned first ([plexHomeUsers]
     * are the cached Home users by account). Clears the active profile when the session signs out or only PIN-protected
     * profiles are left; activating the profile of [PostRemovalOutcome.Activate] is the caller's.
     */
    suspend fun settleAfterRemoval(plexHomeUsers: Map<String, List<PlexHomeUser>>): PostRemovalOutcome {
        val profiles = resolvePostRemovalState(plexHomeUsers)
        if (profiles == null) {
            identity.clearActiveProfileId()
            return PostRemovalOutcome.SignedOut
        }
        resolveActiveProfile(profiles, identity.activeProfileId())?.let { return PostRemovalOutcome.KeepActive(it) }
        val next = profiles.firstOrNull { !it.isPinProtected }
        if (next != null) return PostRemovalOutcome.Activate(next)
        identity.clearActiveProfileId()
        return PostRemovalOutcome.PickProfile
    }

    /**
     * Prunes the Jellyfin/Emby connections no profile uses, then gives the profiles left to pick from (most recently
     * used first), or null when no connection or no profile is left and the session signs out.
     */
    suspend fun resolvePostRemovalState(plexHomeUsers: Map<String, List<PlexHomeUser>>): List<Profile>? {
        pruneUnreferencedJellyfinConnections()
        val all = connections.list()
        if (all.isEmpty()) return null
        val locals = localData.profiles.list()
        val ids = locals.map { it.id } + plexHomeUsers.flatMap { (connectionId, users) -> users.map { plexHomeProfileId(connectionId, it.uuid) } }
        val merged = mergeLocalWithPlexHome(locals, plexHomeUsers, all.map { it.id }.toSet(), identity.profilesLastUsed(ids))
        return merged.ifEmpty { null }
    }

    /** Removes the Jellyfin and Emby connections no profile is bound to; returns how many. */
    suspend fun pruneUnreferencedJellyfinConnections(): Int {
        val referenced = profileConnections.listAll().map { it.connectionId }.toSet()
        val orphans = connections.list().filter { it.kind.usesMediaBrowserApi && it.id !in referenced }
        orphans.forEach { removeMediaBrowserConnection(it) }
        return orphans.size
    }

    private suspend fun removeMediaBrowserConnection(connection: StoredConnection) {
        connections.remove(connection.id)
        for (serverId in connection.serverIds()) {
            if (!isServerReferenced(serverId)) localData.libraryPrefs.clearForServerEverywhere(serverId)
        }
    }

    /** The servers [profileId] reaches through its bindings (not a Plex Home profile's implicit account). */
    private suspend fun serverIdsForProfile(profileId: String): Set<String> {
        val rows = profileConnections.listForProfile(profileId)
        if (rows.isEmpty()) return emptySet()
        val byId = connections.list().associateBy { it.id }
        return rows.flatMap { byId[it.connectionId]?.serverIds().orEmpty() }.toSet()
    }

    private suspend fun isServerReferenced(serverId: String): Boolean {
        val rows = profileConnections.listAll()
        if (rows.isEmpty()) return false
        val byId = connections.list().associateBy { it.id }
        return rows.any { row -> byId[row.connectionId]?.serverIds()?.contains(serverId) == true }
    }
}

/** The ids of the servers [this] reaches: a Plex account's servers, a Jellyfin/Emby connection's server. */
internal fun StoredConnection.serverIds(): Set<String> = when (kind) {
    BackendKind.PLEX -> (config["servers"] as? JsonArray).orEmpty()
        .mapNotNull { (it as? JsonObject)?.nonBlankString("clientIdentifier") }
        .toSet()
    BackendKind.JELLYFIN, BackendKind.EMBY -> setOfNotNull(config.nonBlankString("serverMachineId"))
}

private fun JsonObject.nonBlankString(field: String): String? =
    (this[field] as? JsonPrimitive)?.takeIf { it.isString && it.content.isNotBlank() }?.content
