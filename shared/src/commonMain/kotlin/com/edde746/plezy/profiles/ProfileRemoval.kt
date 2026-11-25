package com.edde746.plezy.profiles

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.connections.StoredConnection
import com.edde746.plezy.model.parseGlobalKey
import com.edde746.plezy.seerr.SeerrAccounts

/** The downloads a profile's removal releases. */
interface ProfileDownloads {
    /** Releases every download [profileId] owns; rows no other profile owns are deleted with their files. */
    suspend fun deleteDownloadsForProfile(profileId: String)

    /** Releases [profileId]'s downloads from [serverIds]; rows another profile owns stay for it. */
    suspend fun releaseDownloadsForProfileServers(profileId: String, serverIds: Set<String>)
}

/**
 * The user's removals of profiles, connections and accounts with what they leave outside the profile tables
 * ([ProfileTeardown]): the downloads go first, while every owner and binding is still there, so a file deletion that
 * fails stops the removal before anything else changes and a retry finds the same plan; then the identity rows; then
 * the tracker connections, queued tracker writes and Seerr sessions of the profile scopes that went ([profileUserScope]:
 * a Plex Home user's are shared by each account's profile of that user, and go with it). Without [downloads] (a platform
 * without downloads) there are none to release.
 */
class ProfileRemoval(
    private val profiles: ProfileServices,
    private val data: LocalData,
    private val downloads: ProfileDownloads?,
    private val seerr: SeerrAccounts,
) {
    private val teardown: ProfileTeardown get() = profiles.teardown

    /** Deletes the local profile [profileId] ([ProfileTeardown.deleteLocalProfile]) with its downloads and integrations. */
    suspend fun deleteLocalProfile(profileId: String) {
        downloads?.deleteDownloadsForProfile(profileId)
        teardown.deleteLocalProfile(profileId)
        forgetIntegrations(setOf(profileId))
    }

    /**
     * Unbinds [connection] from [profileId] ([ProfileTeardown.removeProfileConnection]), releasing the profile's
     * downloads from the servers it no longer reaches; one it still reaches through another binding keeps them.
     */
    suspend fun removeProfileConnection(profileId: String, connection: StoredConnection) {
        downloads?.releaseDownloadsForProfileServers(profileId, teardown.serversLostByUnlinking(profileId, connection))
        teardown.removeProfileConnection(profileId, connection)
    }

    /**
     * Whether signing out of the Plex [account] could delete downloads: one its Home profiles own, or one a profile
     * borrowing it owns from its servers. The sign-out offers the choice only then.
     */
    suspend fun plexSignOutOwnsDownloads(account: StoredConnection): Boolean {
        if (downloads == null) return false
        val removal = teardown.planPlexAccountRemoval(account.id)
        val servers = account.serverIds()
        return removal.removedVirtualProfileIds.any { data.downloadLibrary.getDownloadOwnerKeysForProfile(it).isNotEmpty() } ||
            removal.borrowerProfileIds.any { profileId ->
                data.downloadLibrary.getDownloadOwnerKeysForProfile(profileId).any { parseGlobalKey(it)?.first?.value in servers }
            }
    }

    /**
     * Signs out of the Plex [account] ([ProfileTeardown.signOutPlexAccount]) and forgets its Home users' integrations.
     * With [deleteDownloads] its Home profiles' downloads go and its borrowers' from its servers are released first;
     * otherwise they're kept with their owners, which come back when the account signs in again.
     */
    suspend fun signOutPlexAccount(account: StoredConnection, deleteDownloads: Boolean): PlexAccountRemoval {
        val removal = teardown.planPlexAccountRemoval(account.id)
        if (deleteDownloads && downloads != null) {
            for (profileId in removal.removedVirtualProfileIds) downloads.deleteDownloadsForProfile(profileId)
            val servers = account.serverIds()
            for (profileId in removal.borrowerProfileIds) downloads.releaseDownloadsForProfileServers(profileId, servers)
        }
        teardown.signOutPlexAccount(account, removal)
        forgetIntegrations(removal.removedVirtualProfileIds)
        return removal
    }

    /**
     * Logs out of everything ([ProfileServices.logOutAll]), every profile's tracker connections, queued tracker writes
     * and Seerr sessions first, so nothing below hands them to the next sign-in.
     */
    suspend fun logOutAll() {
        val scopes = buildSet {
            data.profiles.list().forEach { add(it.id) }
            profiles.plexHomeUsers.value.values.forEach { users -> users.forEach { add(it.uuid) } }
            data.trackerAccounts.connections().forEach { add(profileUserScope(it.first)) }
            profiles.profiles.value.forEach { add(profileUserScope(it.id)) }
        }
        data.trackerAccounts.clear()
        seerr.forgetScopes(scopes)
        profiles.logOutAll()
    }

    private suspend fun forgetIntegrations(profileIds: Set<String>) {
        val scopes = profileIds.mapTo(HashSet(), ::profileUserScope)
        data.trackerAccounts.forgetScopes(scopes)
        seerr.forgetScopes(scopes)
    }
}
