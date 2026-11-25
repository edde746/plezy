package com.edde746.plezy.profiles

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.settings.AppSettings
import kotlin.uuid.Uuid

/**
 * The device's profile bookkeeping in the global settings: the active profile, when each profile was last used, each
 * Plex account's cached Home users, and the device's client identifier.
 */
class ProfileIdentity(localData: LocalData) {
    private val settings = localData.deviceSettings

    /** The active profile's id (a local or a Plex Home profile's), or null when none is chosen. */
    suspend fun activeProfileId(): String? = settings.value(AppSettings.activeAppProfileId)

    suspend fun setActiveProfileId(id: String) {
        settings.set(AppSettings.activeAppProfileId, id)
    }

    suspend fun clearActiveProfileId() {
        settings.reset(AppSettings.activeAppProfileId)
    }

    /** Records that the profile [profileId] (local or Plex Home) was used at [at], epoch milliseconds. */
    suspend fun markProfileUsed(profileId: String, at: Long) {
        settings.set(AppSettings.profileLastUsed(profileId), at)
    }

    /** When the profile [profileId] was last used (epoch milliseconds), or null when never. */
    suspend fun profileLastUsed(profileId: String): Long? = settings.value(AppSettings.profileLastUsed(profileId))

    /** [profileLastUsed] of each of [profileIds] that was used. */
    suspend fun profilesLastUsed(profileIds: Collection<String>): Map<String, Long> =
        profileIds.mapNotNull { id -> profileLastUsed(id)?.let { id to it } }.toMap()

    suspend fun clearProfileLastUsed(profileId: String) {
        settings.reset(AppSettings.profileLastUsed(profileId))
    }

    suspend fun clearAllProfileLastUsed() {
        settings.removeWithPrefix(PROFILE_LAST_USED_PREFIX)
    }

    /**
     * The device's client identifier (Plex's `X-Plex-Client-Identifier`, Jellyfin's and Emby's `DeviceId`): a lowercase
     * UUID v4 made and kept the first time it's asked for, and made again when the stored one is empty.
     */
    suspend fun getOrCreateClientIdentifier(): String {
        settings.value(AppSettings.clientIdentifier)?.takeIf { it.isNotEmpty() }?.let { return it }
        val fresh = Uuid.random().toString()
        settings.update(AppSettings.clientIdentifier) { stored -> stored?.takeIf { it.isNotEmpty() } ?: fresh }
        return checkNotNull(settings.value(AppSettings.clientIdentifier))
    }

    /** Forgets the client identifier, so the next sign-in makes a new one. */
    suspend fun clearClientIdentifier() {
        settings.reset(AppSettings.clientIdentifier)
    }

    /** Keeps [users] as the Plex account [connectionId]'s Home users. */
    suspend fun savePlexHomeUsers(connectionId: String, users: List<PlexHomeUser>) {
        settings.set(AppSettings.plexHomeUsers(connectionId), encodePlexHomeUsers(users))
    }

    /** The Plex account [connectionId]'s cached Home users, or null when none are (or they don't read). */
    suspend fun plexHomeUsers(connectionId: String): List<PlexHomeUser>? =
        settings.value(AppSettings.plexHomeUsers(connectionId))?.let(::decodePlexHomeUsers)

    suspend fun clearPlexHomeUsers(connectionId: String) {
        settings.reset(AppSettings.plexHomeUsers(connectionId))
    }

    suspend fun clearAllPlexHomeUsers() {
        settings.removeWithPrefix(PLEX_HOME_USERS_PREFIX)
    }

    private companion object {
        const val PROFILE_LAST_USED_PREFIX = "profile_last_used_"
        const val PLEX_HOME_USERS_PREFIX = "plex_home_users_"
    }
}
